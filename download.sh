#!/usr/bin/env zsh

# Copyright (c) Meta Platforms, Inc. and affiliates.
# This software may be used and distributed according to the terms of the Llama 2 Community License Agreement.

set -e

echo -n "Enter the URL from email: "
read -r PRESIGNED_URL

echo ""
echo -n "Enter the list of models to download without spaces (8B,8B-instruct,70B,70B-instruct), or press Enter for all: "
read -r MODEL_SIZE
TARGET_FOLDER="." # where all files should end up
mkdir -p "$TARGET_FOLDER"

if [[ -z "$MODEL_SIZE" ]]; then
    MODEL_SIZE="8B,8B-instruct,70B,70B-instruct"
fi

# Custom user agent to mimic wget
USER_AGENT="wget/1.20.3 (linux-gnu)"

echo "Downloading LICENSE and Acceptable Usage Policy"
curl -C - --user-agent "$USER_AGENT" --output "$TARGET_FOLDER/LICENSE" "${PRESIGNED_URL/'*'/"LICENSE"}"
curl -C - --user-agent "$USER_AGENT" --output "$TARGET_FOLDER/USE_POLICY" "${PRESIGNED_URL/'*'/"USE_POLICY"}"

for m in ${MODEL_SIZE//,/ }
do
    if [[ "$m" == "8B" ]] || [[ "$m" == "8b" ]]; then
        SHARD=0
        MODEL_FOLDER_PATH="Meta-Llama-3-8B"
        MODEL_PATH="8b_pre_trained"
    elif [[ "$m" == "8B-instruct" ]] || [[ "$m" == "8b-instruct" ]]; then
        SHARD=0
        MODEL_FOLDER_PATH="Meta-Llama-3-8B-Instruct"
        MODEL_PATH="8b_instruction_tuned"
    elif [[ "$m" == "70B" ]] || [[ "$m" == "70b" ]]; then
        SHARD=7
        MODEL_FOLDER_PATH="Meta-Llama-3-70B"
        MODEL_PATH="70b_pre_trained"
    elif [[ "$m" == "70B-instruct" ]] || [[ "$m" == "70b-instruct" ]]; then
        SHARD=7
        MODEL_FOLDER_PATH="Meta-Llama-3-70B-Instruct"
        MODEL_PATH="70b_instruction_tuned"
    fi

    echo "Downloading $MODEL_PATH"
    mkdir -p "$TARGET_FOLDER/$MODEL_FOLDER_PATH"

    for s in $(seq -f "0%g" 0 $SHARD)
    do
        curl -C - --user-agent "$USER_AGENT" --output "$TARGET_FOLDER/$MODEL_FOLDER_PATH/consolidated.${s}.pth" "${PRESIGNED_URL/'*'/"$MODEL_PATH/consolidated.${s}.pth"}"
    done

    curl -C - --user-agent "$USER_AGENT" --output "$TARGET_FOLDER/$MODEL_FOLDER_PATH/params.json" "${PRESIGNED_URL/'*'/"$MODEL_PATH/params.json"}"
    curl -C - --user-agent "$USER_AGENT" --output "$TARGET_FOLDER/$MODEL_FOLDER_PATH/tokenizer.model" "${PRESIGNED_URL/'*'/"$MODEL_PATH/tokenizer.model"}"
    curl -C - --user-agent "$USER_AGENT" --output "$TARGET_FOLDER/$MODEL_FOLDER_PATH/checklist.chk" "${PRESIGNED_URL/'*'/"$MODEL_PATH/checklist.chk"}"

    echo "Checking checksums"
    if [[ "$(uname -m)" == "arm64" ]]; then
        (cd "$TARGET_FOLDER/$MODEL_FOLDER_PATH" && md5 checklist.chk)
    else
        (cd "$TARGET_FOLDER/$MODEL_FOLDER_PATH" && md5sum -c checklist.chk)
    fi
done
