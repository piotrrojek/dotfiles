#!/bin/bash
# Install vllm-mlx and pre-download the Gemma 4 26B A4B 4bit model.
# Apple Silicon Macs only — the whole stack relies on MLX/Metal.
# Runs after the Brewfile so `uv` and `hf` are guaranteed available.

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "vllm-mlx: not an Apple Silicon Mac, skipping."
  exit 0
fi

if ! command -v uv &>/dev/null; then
  echo "vllm-mlx: uv not found — expected it from the Brewfile. Skipping."
  exit 0
fi

if command -v vllm-mlx &>/dev/null; then
  echo "vllm-mlx already installed, skipping install."
else
  echo "Installing vllm-mlx via uv tool..."
  uv tool install git+https://github.com/waybarrios/vllm-mlx.git
fi

MODEL="mlx-community/gemma-4-26b-a4b-it-4bit"
MODEL_DIR="$HOME/.cache/huggingface/hub/models--${MODEL//\//--}"

if [ -d "$MODEL_DIR" ]; then
  echo "Model $MODEL already cached, skipping download."
elif command -v hf &>/dev/null; then
  echo "Downloading $MODEL (~14 GB, this will take a while)..."
  hf download "$MODEL"
else
  echo "vllm-mlx: hf CLI not found — skipping model pre-download."
  echo "          Run 'hf download $MODEL' manually, or vllm-mlx will fetch on first serve."
fi

echo "vllm-mlx setup complete. Start the server with: vllm-gemma4"
