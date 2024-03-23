#!/bin/bash

chmod +x converter.sh converter_measurements-only.sh

apt-get update
apt-get install --yes --no-install-recommends tmux nano git-lfs python-is-python3
apt-get clean
rm -rf /var/lib/apt/lists/*

git clone https://github.com/turboderp/exllamav2

pip uninstall --no-input exllamav2
pip install --no-cache-dir --no-input huggingface_hub huggingface_hub[cli] tqdm pandas ninja fastparquet safetensors sentencepiece websockets regex
pip install -U --no-cache-dir --no-input torch torchvision torchaudio
pip install --no-input exllamav2/