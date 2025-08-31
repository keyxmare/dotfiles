#!/usr/bin/env bash
# General shell helper functions

# Print formatted text overwriting the current line.
# Usage: print_over FORMAT [ARGS...]
print_over() {
  local fmt=$1
  shift
  # shellcheck disable=SC2059
  printf "\r$fmt\033[K" "$@"
}

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
