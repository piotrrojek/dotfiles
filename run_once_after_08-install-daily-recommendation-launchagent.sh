#!/bin/bash
# Bootstrap the daily-recommendation LaunchAgent (idempotent; chezmoi apply).
#
# The plist itself is managed by chezmoi at:
#   ~/Library/LaunchAgents/com.piotrrojek.daily-recommendation.plist
# This script just registers it with launchd and ensures the log dir exists.

set -euo pipefail

LABEL="com.piotrrojek.daily-recommendation"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
DOMAIN="gui/$(id -u)"
LOG_DIR="$HOME/Desktop/secondbrain/scripts/.daily-rec-logs"

if [[ ! -f "$PLIST" ]]; then
    echo "[daily-recommendation-launchagent] plist missing at $PLIST — chezmoi should have placed it. Skipping."
    exit 0
fi

mkdir -p "$LOG_DIR"

if launchctl print "${DOMAIN}/${LABEL}" >/dev/null 2>&1; then
    echo "[daily-recommendation-launchagent] ${LABEL} already loaded — bootout + bootstrap to pick up plist changes."
    launchctl bootout "${DOMAIN}/${LABEL}" 2>/dev/null || true
fi

launchctl bootstrap "$DOMAIN" "$PLIST"
echo "[daily-recommendation-launchagent] bootstrapped ${LABEL} (daily 00:20 local, weekends self-skip)."
