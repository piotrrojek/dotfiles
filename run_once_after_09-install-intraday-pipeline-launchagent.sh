#!/bin/bash
# Bootstrap the intraday-pipeline LaunchAgent (idempotent; chezmoi apply).
#
# The plist itself is managed by chezmoi at:
#   ~/Library/LaunchAgents/com.piotrrojek.intraday-pipeline.plist
# This script just registers it with launchd and ensures the log dir exists.

set -euo pipefail

LABEL="com.piotrrojek.intraday-pipeline"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
DOMAIN="gui/$(id -u)"
LOG_DIR="$HOME/Desktop/secondbrain/scripts/.intraday-logs"

if [[ ! -f "$PLIST" ]]; then
    echo "[intraday-pipeline-launchagent] plist missing at $PLIST — chezmoi should have placed it. Skipping."
    exit 0
fi

mkdir -p "$LOG_DIR"

if launchctl print "${DOMAIN}/${LABEL}" >/dev/null 2>&1; then
    echo "[intraday-pipeline-launchagent] ${LABEL} already loaded — bootout + bootstrap to pick up plist changes."
    launchctl bootout "${DOMAIN}/${LABEL}" 2>/dev/null || true
fi

launchctl bootstrap "$DOMAIN" "$PLIST"
echo "[intraday-pipeline-launchagent] bootstrapped ${LABEL} (hourly at :05)."
