#!/bin/bash
# Bootstrap the weekly COT LaunchAgent (idempotent; chezmoi apply).
#
# The plist itself is managed by chezmoi at:
#   ~/Library/LaunchAgents/com.piotrrojek.cot-weekly.plist
# This script just registers it with launchd.

set -euo pipefail

LABEL="com.piotrrojek.cot-weekly"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
DOMAIN="gui/$(id -u)"

if [[ ! -f "$PLIST" ]]; then
    echo "[cot-launchagent] plist missing at $PLIST — chezmoi should have placed it. Skipping."
    exit 0
fi

if launchctl print "${DOMAIN}/${LABEL}" >/dev/null 2>&1; then
    echo "[cot-launchagent] ${LABEL} already loaded — bootout + bootstrap to pick up plist changes."
    launchctl bootout "${DOMAIN}/${LABEL}" 2>/dev/null || true
fi

launchctl bootstrap "$DOMAIN" "$PLIST"
echo "[cot-launchagent] bootstrapped ${LABEL} (Friday 23:00 local)."
