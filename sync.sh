#!/usr/bin/env bash

# shellcheck disable=SC2016
# Synchronize repository scripts to local environment or perform installation

if [ -n "${ZSH_VERSION:-}" ]; then
  emulate -L sh
  set -e
  set -u
  set -o pipefail
else
  set -euo pipefail
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

load_env() {
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

sync_repo() {
  mkdir -p "$DEST"
  rsync -av --delete --exclude '.git/' "$REPO_DIR"/ "$DEST"/
  load_env
  configure_profiles
}

configure_profiles() {
  PROFILES=("$HOME/.bashrc" "$HOME/.zshrc")
  ALIASES_SNIPPET='[ -f "$HOME/.local/share/dotfiles/aliases/git.sh" ] && source "$HOME/.local/share/dotfiles/aliases/git.sh"'
  HELPERS_SNIPPET='[ -f "$HOME/.local/share/dotfiles/helpers.sh" ] && source "$HOME/.local/share/dotfiles/helpers.sh"'

  for PROFILE in "${PROFILES[@]}"; do
    touch "$PROFILE"
    if ! grep -Fqx "$ALIASES_SNIPPET" "$PROFILE"; then
      printf '\n%s\n' "$ALIASES_SNIPPET" >> "$PROFILE"
    fi
    if ! grep -Fqx "$HELPERS_SNIPPET" "$PROFILE"; then
      printf '\n%s\n' "$HELPERS_SNIPPET" >> "$PROFILE"
    fi
  done
}

install_repo() {
  git -C "$REPO_DIR" config core.hooksPath hooks
  sync_repo
}

case "${1:-}" in
  --install)
    install_repo
    ;;
  *)
    sync_repo "$@"
    ;;
esac
