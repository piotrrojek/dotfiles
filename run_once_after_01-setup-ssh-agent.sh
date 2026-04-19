#!/bin/bash
# Prepare ~/.ssh: create ControlMaster socket dir, add keys to agent
# (runs once per machine, after key files are written).

set -euo pipefail

# ControlMaster socket dir (referenced by `ControlPath` in ssh config)
mkdir -p ~/.ssh/cm
chmod 700 ~/.ssh/cm

eval "$(ssh-agent -s)" 2>/dev/null || true

# --apple-use-keychain pairs with `UseKeychain yes` in ssh config — the
# passphrase is read from/stored in macOS Keychain so we don't re-prompt.
for key in ~/.ssh/id_ed25519 ~/.ssh/id_ed25519_edge ~/.ssh/id_rsa; do
  [ -f "$key" ] && ssh-add --apple-use-keychain "$key" || true
done

echo "SSH keys added to agent."
