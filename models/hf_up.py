import argparse
import subprocess
import sys

parser = argparse.ArgumentParser()

def parseargs():
    parser.add_argument('-i', help='Path to either folder or file to upload', type=str)
    parser.add_argument('-t', '--token', type=str, help='Huggingface login token.')
    parser.add_argument('-r', '--repo', type=str, help='Huggingface repo to upload to')
    parser.add_argument('-p', '--path-repo', type=str, help='Path in Huggingface repo')
    return parser.parse_args()

if __name__ == "__main__":
    args = parseargs()
    
    upload_command = ['huggingface-cli', 'upload']
    
    repo = args.repo
    while repo is None or repo.strip() == "":
        repo = input("Please specify a repo: ")
    upload_command.append(repo)

    f_input = args.i
    while f_input is None:
        f_input = input("Enter a file/folder to upload. (Leave empty to upload current folder): ")
    if f_input != "":
        upload_command.append(f_input)
    
    if args.path_repo is not None:
        upload_command.append(args.path_repo)
    
    upload_command.append('--private') # if repo doesn't exist, create a private repo instead of public
    
    if args.token is not None:
        upload_command.extend(['--token', args.token])
    
    print(upload_command)
    subprocess.run(['echo'] + upload_command, shell=True)
    subprocess.run(upload_command, shell=True)
    
    input("Done. Press Enter to exit.")
    sys.exit()