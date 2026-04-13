#!/bin/bash
# Install icloud-keychain helper (runs once, before file templates are rendered).

set -euo pipefail

if command -v icloud-keychain &>/dev/null; then
  echo "icloud-keychain already installed, skipping."
  exit 0
fi

echo "Installing icloud-keychain..."
PKG_URL="https://piotrrojek.io/icloud-keychain-1.0.0-macos-universal.pkg"
TMP_PKG="$(mktemp /tmp/icloud-keychain-XXXXXX.pkg)"

curl -fsSL -o "$TMP_PKG" "$PKG_URL"
sudo installer -pkg "$TMP_PKG" -target /
rm -f "$TMP_PKG"

echo "icloud-keychain installed."
