#!/usr/bin/env bash
set -euo pipefail

REQUIRED_CMDS=(nvim)
# Map commands to package names when they differ
declare -A PKG_MAP=([nvim]=neovim)

echo "Checking required commands: ${REQUIRED_CMDS[*]}"
missing=()
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    pkg="${PKG_MAP[$cmd]:-$cmd}"
    missing+=("$pkg")
  fi
done

if [ ${#missing[@]} -eq 0 ]; then
  echo "All required packages are installed."
  exit 0
fi

echo "Missing packages: ${missing[*]}"
SUDO=""
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

if command -v apt >/dev/null 2>&1; then
  echo "Installing with apt-get: ${missing[*]}"
  $SUDO apt-get update
  $SUDO apt-get install -y "${missing[@]}"
elif command -v brew >/dev/null 2>&1; then
  echo "Installing with brew: ${missing[*]}"
  $SUDO brew install "${missing[@]}"
elif command -v dnf >/dev/null 2>&1; then
  echo "Installing with dnf: ${missing[*]}"
  $SUDO dnf install -y "${missing[@]}"
elif command -v pacman >/dev/null 2>&1; then
  echo "Installing with pacman: ${missing[*]}"
  $SUDO pacman -Syu --noconfirm "${missing[@]}"
else
  echo "No supported package manager found. Please install: ${missing[*]}" >&2
  exit 1
fi
echo "Package installation complete."
