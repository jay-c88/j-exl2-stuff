# pip install huggingface_hub tqdm requests
from huggingface_hub import hf_hub_url
import huggingface_hub
import sys
import os
import requests
from tqdm import tqdm
#from concurrent.futures import ThreadPoolExecutor
from tqdm.contrib.concurrent import thread_map

dl_folder = ""
files=[]
common_prefix = ""

def get_files():
    url = input("Enter HuggingFace URL/Repo: ")
    global dl_folder
    global files
    
    if url.startswith("https://huggingface.co/"):
        repo = url[len("https://huggingface.co/"):]
    elif url.startswith("https://") or url.startswith("http://"):
        print("Error: Input should be a Huggingface URL or Repo")
        sys.exit()
    else:
        repo = url
    
    if not "/" in repo:
        print("Invalid Huggingface URL/Repo??")
        sys.exit()

    if ":" in repo:
        rev_set = True
        repo, rev = repo.split(":", 1)
    else:
        rev = ""
        rev_set = False
    
    author, model = repo.split("/", 1)
    if "exl2" in repo:
        if rev_set:
            dl_folder = f"{model}_{rev}_{author}"
        else:
            dl_folder = f"{model}_{author}"
    else:
        dl_folder = f"{model}_RAW_{author}"
    
    print("Repo:", repo)
    print("Rev:", rev)
    print("Download Folder Name:", dl_folder)
    
    try:
        if(rev_set):
            files = huggingface_hub.list_repo_files(repo_id=repo, revision=rev)
        else:
            files = huggingface_hub.list_repo_files(repo_id=repo)
    except:
        print("Invalid Huggingface URL/Repo??")
        sys.exit()

    files.remove('.gitattributes')
    
    # Sort .safetensors files to the bottom of the list
    files = sorted(files, key=lambda x: x.endswith('.safetensors'))
    
    # remove subfolders
    # files = [f for f in files if "/" not in f]
    
    # ask to download subfolders?
    if (any("/" in item for item in files)):
        dl_subfolders = input("Download subfolders? [y/n](default=y): ").lower()
        if dl_subfolders == "n":
            files = [f for f in files if "/" not in f]

    if(rev_set):
        files_url = [hf_hub_url(repo_id=repo, filename=f, revision=rev) for f in files]
    else:
        files_url = [hf_hub_url(repo_id=repo, filename=f) for f in files]
    
    print("List of files:")
    print("\n".join(files_url))
    return files_url

def download_file(filename):
    url = os.path.join(common_prefix, filename)
    full_path = os.path.join(dl_folder, filename)  # Construct full path
    r = requests.head(url)
    file_size = int(r.headers.get('content-length', 0))
    
    resume_byte_pos = None
    
    # Check if lfs
    if 'Location' in r.headers:
        r_temp = requests.head(r.headers.get('Location'))
        file_size = int(r_temp.headers.get('content-length', 0))
       
    # Check if file partially downloaded
    if os.path.exists(full_path):        
        file_size_offline = os.path.getsize(full_path)
        if file_size != file_size_offline:
            #print(f"File {full_path} is incomplete. Resuming download.")
            resume_byte_pos = file_size_offline
        else:
            # TODO: Validate file and give error if corrupt
            return
    
    resume_header = ({'Range': f'bytes={resume_byte_pos}-'} if resume_byte_pos else None)
    response = requests.get(url, stream=True, headers=resume_header)

    if "/" in filename:
        subfolder = os.path.join(dl_folder, filename.split("/")[0])
        if not os.path.exists(subfolder):
            os.makedirs(subfolder)

    #config
    block_size = 1024 * 1024
    initial_pos = resume_byte_pos if resume_byte_pos else 0
    mode = 'ab' if resume_byte_pos else 'wb'  # Append if file already exists  otherwise write
    file_name = filename.split("/")[-1]

    with open(full_path, mode) as file, tqdm(
        desc=file_name,
        total=file_size,
        unit='iB',
        unit_scale=True,
        #unit_divisor=1024,
        initial=initial_pos,
        #bar_format='{l_bar}{bar}| {n_fmt}/{total_fmt} [{elapsed}<{remaining}, ' '{rate_fmt}]',
    ) as bar:
        for chunk in response.iter_content(block_size):
            bar.update(len(chunk))
            file.write(chunk)

def download_files(files_urls):
    if not os.path.exists(dl_folder):
        os.makedirs(dl_folder)
        
    # find common prefix URL
    global common_prefix
    common_prefix = os.path.commonprefix(files_urls)
    
    thread_map(lambda file_name: download_file(file_name), files, max_workers=4, disable=True)
    #thread_map(lambda file_name: download_file(file_name), files)
    
    # with ThreadPoolExecutor(max_workers=len(urls)) as executor:
    #     for url in urls:
    #         filename = url[len(common_prefix):]
    #         executor.submit(download_file, url, filename)

if __name__ == "__main__":
    try:
        files_url = get_files()
        download_files(files_url)
    except:
        input("Something went wrong. Press Enter to exit.")
        sys.exit()
    
    input("Done. Press Enter to exit.")
    sys.exit()