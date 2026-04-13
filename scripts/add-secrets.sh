#!/bin/bash
# Interactive helper to store dotfiles secrets in iCloud Keychain.
# This script contains no secrets — safe to commit.

account="piotrrojek"

# Simple secrets (tokens, API keys)
secrets=("github-read-pat")

for s in "${secrets[@]}"; do
  echo -n "Enter $s: "
  read -s value
  echo
  icloud-keychain set --sync "dotfiles/$s" "$account" "$value"
done

# SSH keys (read from file paths)
echo ""
echo "--- SSH Keys ---"
read -p "Path to ed25519 private key [~/.ssh/id_ed25519]: " privkey
privkey="${privkey:-$HOME/.ssh/id_ed25519}"
if [ -f "$privkey" ]; then
  icloud-keychain set --sync "dotfiles/ssh-ed25519-private" "$account" "$(cat "$privkey")"
  icloud-keychain set --sync "dotfiles/ssh-ed25519-public" "$account" "$(cat "${privkey}.pub")"
  echo "SSH keys stored."
else
  echo "File not found: $privkey — skipping SSH keys."
fi

echo "All secrets stored in iCloud Keychain."
