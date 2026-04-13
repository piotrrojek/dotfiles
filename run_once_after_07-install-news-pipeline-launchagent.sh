#!/bin/bash
# Bootstrap the daily news-pipeline LaunchAgent (idempotent; chezmoi apply).
#
# The plist itself is managed by chezmoi at:
#   ~/Library/LaunchAgents/com.piotrrojek.news-pipeline.plist
# This script just registers it with launchd and ensures the log dir exists.

set -euo pipefail

LABEL="com.piotrrojek.news-pipeline"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
DOMAIN="gui/$(id -u)"
LOG_DIR="$HOME/Desktop/secondbrain/scripts/.news-logs"

if [[ ! -f "$PLIST" ]]; then
    echo "[news-pipeline-launchagent] plist missing at $PLIST — chezmoi should have placed it. Skipping."
    exit 0
fi

mkdir -p "$LOG_DIR"

if launchctl print "${DOMAIN}/${LABEL}" >/dev/null 2>&1; then
    echo "[news-pipeline-launchagent] ${LABEL} already loaded — bootout + bootstrap to pick up plist changes."
    launchctl bootout "${DOMAIN}/${LABEL}" 2>/dev/null || true
fi

launchctl bootstrap "$DOMAIN" "$PLIST"
echo "[news-pipeline-launchagent] bootstrapped ${LABEL} (daily 00:05 local)."
