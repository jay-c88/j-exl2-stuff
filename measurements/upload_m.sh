#!/bin/bash

REPO="JayhC/measurements"

read -e -p "Measurement file to upload: " MFILE

huggingface-cli upload --private --token $HUGGINGFACE_TOKEN "$REPO" "$MFILE"