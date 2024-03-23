#!/bin/bash

# Input original FP16 model folder path
read -e -p "Enter path to raw model folder: " MODEL_FOLDER

# Parse model name
MODEL_NAME=$(basename "$MODEL_FOLDER")
if [[ "$MODEL_NAME" == *"_RAW"* ]]; then
    MODEL_NAME=$(echo "$MODEL_NAME" | sed 's/_RAW.*//')
fi
TEMP_DIR="temp"

# Input Calibration File (blank -> use exllamav2's default calibration dataset)
read -e -p "Enter path to calibration dataset file (blank=default calibration): " CAL_FILE
CAL_FILE=${CAL_FILE:-""}

# Input model suffix (e.g. to emphasize calibration data name)
read -p "Enter Model name suffix (e.g. calbration dataset. default=blank): " MODEL_SUFFIX
MODEL_SUFFIX=${MODEL_SUFFIX:-""}

# Input params
read -p "Enter --quantization-- calibration length (default=2048): " CAL_LENGTH
CAL_LENGTH=${CAL_LENGTH:-2048}
read -p "Enter --quantization-- calibration rows/batch (default=16): " CAL_ROWS
CAL_ROWS=${CAL_ROWS:-100}
read -p "Enter --measurement-- calibration length (default=2048): " MCAL_LENGTH
MCAL_LENGTH=${MCAL_LENGTH:-2048}
read -p "Enter --measurement-- calibration rows/batch (default=16): " MCAL_ROWS
MCAL_ROWS=${MCAL_ROWS:-100}

# Add suffix
if [[ "$MODEL_SUFFIX" == "" ]]; then
    MEASUREMENT_FILE="measurements/${MODEL_NAME}.json"
else
    MEASUREMENT_FILE="measurements/${MODEL_NAME}-${MODEL_SUFFIX}.json"
fi

# If measurement file already exists, ask for another name. If left blank exit script.
if [ -e "$MEASUREMENT_FILE" ]; then
    echo "Measurement file already exists. Cancelling..."
    exit 1
fi

if [ ! -d "measurements" ]; then
    mkdir measurements
fi

if [ ! -d "converted" ]; then
    mkdir converted
fi

if [ -d "$TEMP_DIR" ]; then
    rmdir -r $TEMP_DIR
fi
mkdir $TEMP_DIR

echo "Model path: $MODEL_FOLDER"
echo "Model name: $MODEL_NAME"
echo "Measurement output file: $MEASUREMENT_FILE"
echo "Calibration dataset file used: $CAL_FILE"
echo "Calibration(quantization) length: $CAL_LENGTH"
echo "Calibration(quantization) rows/batch: $CAL_ROWS"
echo "Calibration(measurement) length: $MCAL_LENGTH"
echo "Calibration(measurement) rows/batch: $MCAL_ROWS"

echo "$(date) - Starting time."

if [[ "$CAL_FILE" == "" ]]; then
	echo No calibration dataset chosen. Quantizing with standard calibration...
	python exllamav2/convert.py -i "$MODEL_DIR" -o "$TEMP_DIR" -nr -om "$MEASUREMENT_FILE" -ml "$MCAL_LENGTH" -mr "$MCAL_ROWS" -l "$CAL_LENGTH" -r "$CAL_ROWS"
else
    if [ ! -e "$CAL_FILE" ]; then
        echo "Calibration dataset doesn't exist. Cancelling..."
        exit 1
    fi
    echo "Quantizing with custom calibration $CAL_FILE..."
    python exllamav2/convert.py -i "$MODEL_DIR" -o "$TEMP_DIR" -nr -m "$MEASUREMENT_FILE" -ml "$MCAL_LENGTH" -mr "$MCAL_ROWS" -c "$CAL_FILE" -l "$CAL_LENGTH" -r "$CAL_ROWS"
fi

echo "$(date) - Finishing time."