#!/bin/bash

REPO="JayhC/measurements"

read -e -p "Measurement file to download: " MFILE

huggingface-cli download --local-dir measurements/ --local-dir-use-symlinks False --token $HUGGINGFACE_TOKEN "$REPO" "$MFILE"