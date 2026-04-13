#!/bin/bash
# Install Claude Code via official installer (runs once per machine).

set -euo pipefail

if command -v claude &>/dev/null; then
  echo "Claude Code already installed, skipping."
  exit 0
fi

echo "Installing Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash
