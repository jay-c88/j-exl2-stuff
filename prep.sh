#!/bin/bash

chmod +x converter.sh converter_measurements-only.sh

git clone https://github.com/turboderp/exllamav2
pip install --no-cache-dir --no-input -r exllamav2/requirements.txt
pip install exllamav2/