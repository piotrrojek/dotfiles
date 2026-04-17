#!/bin/bash
# Install vllm-mlx and pre-download the MLX-quantized chat models we serve locally.
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

# (model repo id, approx size for log message)
MODELS=(
  "mlx-community/gemma-4-26b-a4b-it-4bit|~14 GB"
  "mlx-community/Qwen3.6-35B-A3B-4bit|~19 GB"
)

for entry in "${MODELS[@]}"; do
  MODEL="${entry%%|*}"
  SIZE="${entry##*|}"
  MODEL_DIR="$HOME/.cache/huggingface/hub/models--${MODEL//\//--}"

  if [ -d "$MODEL_DIR" ]; then
    echo "Model $MODEL already cached, skipping download."
  elif command -v hf &>/dev/null; then
    echo "Downloading $MODEL ($SIZE, this will take a while)..."
    hf download "$MODEL"
  else
    echo "vllm-mlx: hf CLI not found — skipping model pre-download."
    echo "          Run 'hf download $MODEL' manually, or vllm-mlx will fetch on first serve."
  fi
done

echo "vllm-mlx setup complete. Start servers with: vllm-gemma4 (port 8001) or vllm-qwen3 (port 8002)"
