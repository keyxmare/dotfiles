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

REQUIRED_CMDS=(nvim)
# Map commands to package names when they differ
declare -A PKG_MAP=([nvim]=neovim)

info "Checking required commands: ${REQUIRED_CMDS[*]}"
missing=()
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    pkg="${PKG_MAP[$cmd]:-$cmd}"
    missing+=("$pkg")
  fi
done

if [ ${#missing[@]} -eq 0 ]; then
  success "All required packages are installed."
  exit 0
fi

warn "Missing packages: ${missing[*]}"
SUDO=""
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

if command -v apt >/dev/null 2>&1; then
  info "Installing with apt-get: ${missing[*]}"
  $SUDO apt-get update
  $SUDO apt-get install -y "${missing[@]}"
elif command -v brew >/dev/null 2>&1; then
  info "Installing with brew: ${missing[*]}"
  $SUDO brew install "${missing[@]}"
elif command -v dnf >/dev/null 2>&1; then
  info "Installing with dnf: ${missing[*]}"
  $SUDO dnf install -y "${missing[@]}"
elif command -v pacman >/dev/null 2>&1; then
  info "Installing with pacman: ${missing[*]}"
  $SUDO pacman -Syu --noconfirm "${missing[@]}"
else
  error "No supported package manager found. Please install: ${missing[*]}"
  exit 1
fi
success "Package installation complete."
