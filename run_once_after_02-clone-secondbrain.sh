#!/bin/bash
# Clone secondbrain vault to Desktop (runs once per machine, after SSH is set up).

set -euo pipefail

TARGET="$HOME/Desktop/secondbrain"

if [ -d "$TARGET" ]; then
  echo "secondbrain already exists at $TARGET, skipping."
  exit 0
fi

echo "Cloning secondbrain..."
git clone git@github.com:piotrrojek/secondbrain.git "$TARGET"
echo "secondbrain cloned to $TARGET"
