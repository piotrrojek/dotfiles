#!/bin/bash
# Download whisper.cpp models from Hugging Face (runs once per machine).

set -euo pipefail

MODELS_DIR="$HOME/whisper-models"
BASE_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main"
MODELS=("ggml-large-v3-turbo.bin" "ggml-tiny.bin")

mkdir -p "$MODELS_DIR"

for model in "${MODELS[@]}"; do
  if [ ! -f "$MODELS_DIR/$model" ]; then
    echo "Downloading $model..."
    curl -L --progress-bar -o "$MODELS_DIR/$model" "$BASE_URL/$model"
  else
    echo "$model already exists, skipping."
  fi
done

echo "Whisper models ready at $MODELS_DIR"
