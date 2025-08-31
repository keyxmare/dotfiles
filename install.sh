#!/usr/bin/env bash
set -euo pipefail

# Synchronize repository files and configure shell aliases
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Mirror repository files to the local share directory
"$REPO_DIR/sync.sh"

PROFILE="$HOME/.bashrc"
# shellcheck disable=SC2016
ALIASES_SNIPPET='[ -f "$HOME/.local/share/dotfiles/aliases/git.sh" ] && source "$HOME/.local/share/dotfiles/aliases/git.sh"'

touch "$PROFILE"
if ! grep -Fqx "$ALIASES_SNIPPET" "$PROFILE"; then
  echo "$ALIASES_SNIPPET" >> "$PROFILE"
fi
