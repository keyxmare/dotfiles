#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Silence all non-echo output
exec 3>&1 4>&2
exec 1>/dev/null
exec 2>/dev/null

echo "Installing required packages..." >&3
"$REPO_DIR/install-packages.sh" 1>&3 2>&4
echo "Synchronizing dotfiles..." >&3
"$REPO_DIR/sync.sh" --install "$@" 1>&3 2>&4
