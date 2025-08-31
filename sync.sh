#!/usr/bin/env bash
set -euo pipefail

# Synchronize repository scripts to local environment
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${HOME}/.local/share/dotfiles"

mkdir -p "$DEST"
rsync -av --delete --exclude '.git/' "$REPO_DIR"/ "$DEST"/
