#!/bin/bash
# Install kubectl krew plugins (runs once per machine, after Brewfile so krew/kubectl exist).

set -euo pipefail

if ! command -v kubectl &>/dev/null; then
  echo "krew-plugins: kubectl not found — skipping."
  exit 0
fi

if ! command -v krew &>/dev/null && [ ! -x "$HOME/.krew/bin/kubectl-krew" ]; then
  echo "krew-plugins: krew not found — run brew bundle first. Skipping."
  exit 0
fi

# krew needs ~/.krew/bin on PATH to call `kubectl krew …`
export PATH="$PATH:$HOME/.krew/bin"

PLUGINS=(neat tree view-secret)

# kubectl krew install is idempotent (exits 0 if already installed) but noisy;
# filter to only missing plugins for cleaner logs.
INSTALLED=$(kubectl krew list 2>/dev/null | tail -n +2 | awk '{print $1}' || true)

for plugin in "${PLUGINS[@]}"; do
  if echo "$INSTALLED" | grep -qx "$plugin"; then
    echo "krew: $plugin already installed, skipping."
  else
    echo "krew: installing $plugin..."
    kubectl krew install "$plugin"
  fi
done

echo "krew plugins ready: $(kubectl krew list | tail -n +2 | awk '{print $1}' | tr '\n' ' ')"
