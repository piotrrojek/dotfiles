#!/bin/bash
# Add SSH key to agent (runs once per machine, after key files are written).

set -euo pipefail

eval "$(ssh-agent -s)" 2>/dev/null || true
ssh-add ~/.ssh/id_ed25519

echo "SSH key added to agent."
