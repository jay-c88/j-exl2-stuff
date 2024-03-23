#!/bin/bash

# Input original FP16 model folder path
read -e -p "Enter path to raw model folder: " MODEL_FOLDER

# Parse model name
MODEL_NAME=$(basename "$MODEL_FOLDER")
if [[ "$MODEL_NAME" == *"_RAW"* ]]; then
    MODEL_NAME=$(echo "$MODEL_NAME" | sed 's/_RAW.*//')
fi
TEMP_DIR="temp"

# Input Measurement File (blank -> looks for .json with same name as model name)
read -e -p "Enter path to measurement file (blank=auto): " MEASUREMENT_FILE
MEASUREMENT_FILE=${MEASUREMENT_FILE:-"measurements/${MODEL_NAME}.json"}

if [ ! -e "$MEASUREMENT_FILE" ]; then
    echo "Measurement file does not exist. Run the measurement script first. Cancelling..."
    exit 1
fi

# Input Calibration File (blank -> use exllamav2's default calibration dataset)
read -e -p "Enter path to calibration dataset file (blank=default dataset): " CAL_FILE
CAL_FILE=${CAL_FILE:-""}

# Input model suffix (e.g. to emphasize calibration data name)
read -p "Enter Model name suffix (e.g. calbration dataset. default=blank): " MODEL_SUFFIX
MODEL_SUFFIX=${MODEL_SUFFIX:-""}

# Input params
read -p "Enter calibration length (default=2048): " CAL_LENGTH
CAL_LENGTH=${CAL_LENGTH:-2048}
read -p "Enter calibration rows/batch (default=100): " CAL_ROWS
CAL_ROWS=${CAL_ROWS:-100}
read -p "Enter bpw bits: (default=8): " BPW
BPW=${BPW:-8}
read -p "Enter head bits (default=6): " HB
HB=${HB:-6}

# Add suffix
if [[ "$MODEL_SUFFIX" == "" ]]; then
    CONVERTED_FOLDER="converted/${MODEL_NAME}-${BPW}bpw-h${HB}-exl2_JayhC"
else
    CONVERTED_FOLDER="converted/${MODEL_NAME}-${BPW}bpw-h${HB}-exl2-${MODEL_SUFFIX}_JayhC"
fi

if [ -d "$CONVERTED_FOLDER" ]; then
    echo "Folder ${CONVERTED_FOLDER} already exists! Cancelling..."
    exit 1
fi

if [ ! -d "converted" ]; then
    mkdir converted
fi

if [ -d "$TEMP_DIR" ]; then
    rmdir -r $TEMP_DIR
fi
mkdir $TEMP_DIR

echo "Model name: $MODEL_NAME"
echo "Model path: $MODEL_FOLDER"
echo "Measurement: $MEASUREMENT_FILE"
echo "Converted folder: $CONVERTED_FOLDER"
echo "Calibration dataset: $CAL_FILE"
echo "Calibration length: $CAL_LENGTH"
echo "Calibration rows/batch: $CAL_ROWS"
echo "bpw: $BPW"
echo "Head bits: $HB"

echo "$(date) - Starting time."
SECONDS=0

if [[ "$CAL_FILE" == "" ]]; then
	echo No calibration dataset chosen. Quantizing with standard calibration...
	python exllamav2/convert.py -i "$MODEL_FOLDER" -o "$TEMP_DIR" -nr -m "$MEASUREMENT_FILE" -cf "$CONVERTED_FOLDER" -b "$BPW" -hb "$HB" -l "$CAL_LENGTH" -r "$CAL_ROWS"
else
    if [ ! -e "$CAL_FILE" ]; then
        echo "Calibration dataset doesn't exist. Cancelling..."
        exit 1
    fi
    echo "Quantizing with custom calibration $CAL_FILE..."
    python exllamav2/convert.py -i "$MODEL_FOLDER" -o "$TEMP_DIR" -nr -m "$MEASUREMENT_FILE" -cf "$CONVERTED_FOLDER" -b "$BPW" -hb "$HB" -l "$CAL_LENGTH" -r "$CAL_ROWS" -c "$CAL_FILE"
fi

echo "$(date) - Finishing time."
duration=`date -d@$SECONDS -u +%H:%M:%S`
echo "Time took: $duration"


read -p "Upload to Huggingface? (y/N): " UPLOAD_HF

if [[ "$UPLOAD_HF" == "y"]]; then
    if [[ $HUGGINGFACE_TOKEN ]]; then
        huggingface-cli login --token $HUGGINGFACE_TOKEN --add-to-git-credential
    else
        huggingface-cli login --add-to-git-credential
    fi
    foo="JayhC/${CONVERTED_FOLDER##converted/}"
    huggingface-cli upload --private "${foo%%"_JayhC"}" "${CONVERTED_FOLDER}"
fi
