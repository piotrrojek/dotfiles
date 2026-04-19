#!/bin/bash
# Ensure /etc/hosts resolves the Garage website-bucket subdomains to the
# Headscale tailnet IP. Needed so Obsidian can render the images that
# scripts/rotate-trading-charts.py (secondbrain repo) archives to Garage.
#
# Idempotent, maintains its own marker-bounded block so chezmoi can update
# the entries by simply editing the HOSTS_BLOCK below and reapplying.
# Re-runs automatically whenever the block content changes (run_onchange).

set -euo pipefail

BEGIN_MARKER="# BEGIN chezmoi: secondbrain garage buckets"
END_MARKER="# END chezmoi: secondbrain garage buckets"

# Any hostname added here must also exist as a Garage bucket alias (see
# 30-RESOURCES/R-networking/Cluster-Longhorn-Tiered-Storage-Runbook.md for
# the bucket inventory).
HOSTS_BLOCK=$(cat <<'EOF'
100.64.0.1 secondbrain-archive.web.garage.local
100.64.0.1 secondbrain-private.web.garage.local
EOF
)

DESIRED=$(printf '%s\n%s\n%s\n' "$BEGIN_MARKER" "$HOSTS_BLOCK" "$END_MARKER")

# Extract the current block, if any. macOS sed doesn't support -z; use awk.
CURRENT=$(awk -v b="$BEGIN_MARKER" -v e="$END_MARKER" '
  $0 == b { inblock = 1 }
  inblock { print }
  $0 == e { inblock = 0 }
' /etc/hosts)

if [[ "$CURRENT" == "$DESIRED" ]]; then
  echo "etc-hosts: garage bucket entries already in place, nothing to do."
  exit 0
fi

echo "etc-hosts: updating garage bucket entries in /etc/hosts (sudo required)..."

# Build the new file contents in a temp file, then install it atomically.
TMP=$(mktemp /tmp/hosts.new.XXXXXX)
trap 'rm -f "$TMP"' EXIT

# Strip any existing managed block, then append the fresh one.
awk -v b="$BEGIN_MARKER" -v e="$END_MARKER" '
  $0 == b { inblock = 1; next }
  $0 == e { inblock = 0; next }
  !inblock { print }
' /etc/hosts > "$TMP"

# Ensure trailing newline, then append the managed block.
if [[ -s "$TMP" && $(tail -c1 "$TMP") != "" ]]; then
  echo "" >> "$TMP"
fi
printf '%s\n' "$DESIRED" >> "$TMP"

# Install atomically; -p preserves perms/owner of the original.
sudo install -m 644 -o root -g wheel "$TMP" /etc/hosts

echo "etc-hosts: updated. Flushing DNS cache..."
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder 2>/dev/null || true

echo "etc-hosts: done."
