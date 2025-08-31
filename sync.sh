#!/usr/bin/env bash

# Synchronize repository scripts to local environment
sync_repo() {
  if [ -n "${ZSH_VERSION:-}" ]; then
    emulate -L sh
    set -e
    set -u
    set -o pipefail
  else
    set -e
    set -u
    set -o pipefail
  fi

  # Determine the directory containing this script for Bash and Zsh
  if [ -n "${BASH_SOURCE[0]:-}" ]; then
    SCRIPT_PATH="${BASH_SOURCE[0]}"
  else
    # shellcheck disable=SC2296  # zsh-specific parameter expansion
    SCRIPT_PATH="${(%):-%x}"
  fi
  REPO_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
  DEST="${HOME}/.local/share/dotfiles"

  mkdir -p "$DEST"
  rsync -av --delete --exclude '.git/' "$REPO_DIR"/ "$DEST"/

  ALIASES_FILE="$DEST/aliases/git.sh"
  HELPERS_FILE="$DEST/helpers.sh"
  if [ -f "$ALIASES_FILE" ]; then
    # shellcheck disable=SC1090
    source "$ALIASES_FILE"
  fi
  if [ -f "$HELPERS_FILE" ]; then
    # shellcheck disable=SC1090
    source "$HELPERS_FILE"
  fi
}

sync_repo "$@"
