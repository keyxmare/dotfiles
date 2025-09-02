#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=helpers.sh
source "$REPO_DIR/helpers.sh"

# Silence all non-echo output
exec 3>&1 4>&2
exec 1>/dev/null
exec 2>/dev/null
INFO_FD=3
ERROR_FD=4

info "Installing required packages..."
"$REPO_DIR/install-packages.sh" 1>&3 2>&4
info "Synchronizing dotfiles..."
"$REPO_DIR/sync.sh" --install "$@" 1>&3 2>&4
