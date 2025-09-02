#!/usr/bin/env bash
# General shell helper functions

# ----- Styled output -------------------------------------------------------
# These functions provide colorized, symbol-prefixed messages to make script
# output clearer and more professional. They default to standard stdout/stderr
# but respect INFO_FD and ERROR_FD when set by the caller.
COLOR_RESET=$'\033[0m'
COLOR_INFO=$'\033[1;34m'
COLOR_SUCCESS=$'\033[1;32m'
COLOR_WARN=$'\033[1;33m'
COLOR_ERROR=$'\033[1;31m'

info() {
  local fd=${INFO_FD:-1}
  printf "%sℹ %s%s\n" "$COLOR_INFO" "$*" "$COLOR_RESET" >&"$fd"
}

success() {
  local fd=${INFO_FD:-1}
  printf "%s✔ %s%s\n" "$COLOR_SUCCESS" "$*" "$COLOR_RESET" >&"$fd"
}

warn() {
  local fd=${INFO_FD:-1}
  printf "%s⚠ %s%s\n" "$COLOR_WARN" "$*" "$COLOR_RESET" >&"$fd"
}

error() {
  local fd=${ERROR_FD:-2}
  printf "%s✖ %s%s\n" "$COLOR_ERROR" "$*" "$COLOR_RESET" >&"$fd"
}

# ----- Progress Bar --------------------------------------------------------
# Display a simple progress bar.
# Usage: load_bar CURRENT TOTAL [WIDTH]
# WIDTH defaults to 50 when not provided.
load_bar() {
  local current=$1
  local total=$2
  local width=${3:-50}

  (( total <= 0 )) && return 1

  local i progress
  progress=$(( current * width / total ))

  printf '\r['
  for ((i = 0; i < progress; i++)); do
    printf '#'
  done
  for ((i = progress; i < width; i++)); do
    printf '-'
  done
  printf '] %d/%d' "$current" "$total"

  if (( current >= total )); then
    printf '\n'
  fi
}
