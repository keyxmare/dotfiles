#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Installing required packages..."
"$REPO_DIR/install-packages.sh"
echo "Synchronizing dotfiles..."
"$REPO_DIR/sync.sh" --install "$@"
