#!/bin/bash
# Install TimescaleDB 2.23.1 for Postgres 18 on Postgres.app (idempotent).
#
# Postgres.app doesn't expose TimescaleDB via brew, so we fetch the official
# .pkg from postgresapp.com's extensions repo and run the installer. Then we
# append `shared_preload_libraries = 'timescaledb'` to the PG 18 postgresql.conf
# if missing and bounce Postgres.app so the change takes effect.

set -euo pipefail

VERSION="2.23.1"
PKG_URL="https://github.com/PostgresApp/Extensions/releases/download/timescaledb-${VERSION}/timescaledb-pg18-${VERSION}.pkg"
PKG_FILE="/tmp/timescaledb-pg18-${VERSION}.pkg"
EXT_DIR="$HOME/Library/Application Support/Postgres/Extensions/18"
CONF_FILE="$HOME/Library/Application Support/Postgres/var-18/postgresql.conf"
REQUIRED_LINE="shared_preload_libraries = 'timescaledb'"

tag() { echo "[timescaledb] $*"; }

# Bail politely if Postgres.app / PG 18 isn't installed yet; user can re-run.
if [[ ! -d "/Applications/Postgres.app" ]]; then
    tag "Postgres.app not installed — skipping. Install it first (brew bundle), then re-run chezmoi apply."
    exit 0
fi
if [[ ! -d "$HOME/Library/Application Support/Postgres/var-18" ]]; then
    tag "PG 18 data dir missing — create the cluster in Postgres.app first, then re-run chezmoi apply."
    exit 0
fi

NEEDS_RESTART=0

# 1. Install the extension pkg if not already present.
if compgen -G "$EXT_DIR/timescaledb*" > /dev/null; then
    tag "extension files already present in $EXT_DIR — skipping download/install."
else
    tag "downloading $PKG_URL"
    curl -fsSL -o "$PKG_FILE" "$PKG_URL"
    tag "installing $PKG_FILE (requires sudo)"
    sudo installer -pkg "$PKG_FILE" -target /
    rm -f "$PKG_FILE"
    NEEDS_RESTART=1
fi

# 2. Disable Postgres.app's "Ask for permission when apps connect without
#    password" feature. When enabled, Postgres.app injects
#    `-c shared_preload_libraries=auth_permission_dialog` on the server command
#    line, which overrides postgresql.conf and prevents timescaledb from loading.
#    This is equivalent to unchecking the box in Postgres.app → Settings.
CURRENT_PREF=$(defaults read com.postgresapp.Postgres2 PermissionDialogForTrustAuth 2>/dev/null || echo "unset")
if [[ "$CURRENT_PREF" == "0" ]]; then
    tag "PermissionDialogForTrustAuth already disabled."
else
    tag "disabling Postgres.app permission dialog (was: $CURRENT_PREF) — required for shared_preload_libraries to apply."
    defaults write com.postgresapp.Postgres2 PermissionDialogForTrustAuth -bool false
    NEEDS_RESTART=1
fi

# 3. Ensure postgresql.conf loads timescaledb.
if [[ -f "$CONF_FILE" ]]; then
    if grep -q "^shared_preload_libraries.*timescaledb" "$CONF_FILE"; then
        tag "postgresql.conf already loads timescaledb."
    else
        tag "setting '$REQUIRED_LINE' in postgresql.conf"
        cp "$CONF_FILE" "${CONF_FILE}.bak-timescaledb"
        # Comment out any existing uncommented shared_preload_libraries line.
        sed -i '' -E "s|^(shared_preload_libraries[[:space:]]*=)|# \1|" "$CONF_FILE"
        printf "\n# Added by chezmoi run_once_after_05-install-timescaledb-pg18.sh\n%s\n" \
               "$REQUIRED_LINE" >> "$CONF_FILE"
        NEEDS_RESTART=1
    fi
else
    tag "WARNING: $CONF_FILE not found — you'll need to enable shared_preload_libraries manually."
fi

# 4. If anything changed, the PG 18 server needs a full restart to pick up the
#    new shared_preload_libraries. Postgres.app keeps the daemon running in the
#    background even when the GUI is quit, and there's no scriptable way to
#    cycle the server daemon without breaking the CLI flags Postgres.app passes
#    (extension_control_path, dynamic_library_path). So we stop here and tell
#    the user to click Stop/Start in the sidebar — a one-time action per machine.
if (( NEEDS_RESTART )); then
    tag "================================================================"
    tag "ACTION REQUIRED: open Postgres.app, click 'PostgreSQL 18' in the"
    tag "  sidebar, then click Stop followed by Start. After that, run:"
    tag "    createdb trading"
    tag "    psql trading -c 'CREATE EXTENSION IF NOT EXISTS timescaledb;'"
    tag "================================================================"
else
    tag "no changes — nothing to restart."
fi
