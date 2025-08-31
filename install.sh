#!/usr/bin/env bash
set -euo pipefail

# Synchronize repository files and configure shell aliases
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Mirror repository files to the local share directory
"$REPO_DIR/sync.sh"

PROFILES=("$HOME/.bashrc" "$HOME/.zshrc")
ALIASES_FILE="$HOME/.local/share/dotfiles/aliases/git.sh"
# shellcheck disable=SC2016
ALIASES_SNIPPET='[ -f "$HOME/.local/share/dotfiles/aliases/git.sh" ] && source "$HOME/.local/share/dotfiles/aliases/git.sh"'

for PROFILE in "${PROFILES[@]}"; do
  touch "$PROFILE"
  if ! grep -Fqx "$ALIASES_SNIPPET" "$PROFILE"; then
    printf '\n%s\n' "$ALIASES_SNIPPET" >> "$PROFILE"
  fi
done

# Load aliases immediately for local use
if [ -f "$ALIASES_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ALIASES_FILE"
fi
