#!/usr/bin/env bash
set -euo pipefail

# Silence all non-echo output
exec 3>&1 4>&2
exec 1>/dev/null
exec 2>/dev/null

REQUIRED_CMDS=(nvim)
# Map commands to package names when they differ
declare -A PKG_MAP=([nvim]=neovim)

echo "Checking required commands: ${REQUIRED_CMDS[*]}" >&3
missing=()
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    pkg="${PKG_MAP[$cmd]:-$cmd}"
    missing+=("$pkg")
  fi
done

if [ ${#missing[@]} -eq 0 ]; then
  echo "All required packages are installed." >&3
  exit 0
fi

echo "Missing packages: ${missing[*]}" >&3
SUDO=""
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

if command -v apt >/dev/null 2>&1; then
  echo "Installing with apt-get: ${missing[*]}" >&3
  $SUDO apt-get update
  $SUDO apt-get install -y "${missing[@]}"
elif command -v brew >/dev/null 2>&1; then
  echo "Installing with brew: ${missing[*]}" >&3
  $SUDO brew install "${missing[@]}"
elif command -v dnf >/dev/null 2>&1; then
  echo "Installing with dnf: ${missing[*]}" >&3
  $SUDO dnf install -y "${missing[@]}"
elif command -v pacman >/dev/null 2>&1; then
  echo "Installing with pacman: ${missing[*]}" >&3
  $SUDO pacman -Syu --noconfirm "${missing[@]}"
else
  echo "No supported package manager found. Please install: ${missing[*]}" >&4
  exit 1
fi
echo "Package installation complete." >&3
