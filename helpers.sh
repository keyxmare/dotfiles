#!/usr/bin/env bash
# General shell helper functions

# Print formatted text overwriting previous output.
# Optionally move up multiple lines before printing.
# Usage: print_over [LINES] FORMAT [ARGS...]
print_over() {
  local lines=0 fmt
  if [[ $1 =~ ^[0-9]+$ ]]; then
    lines=$1
    shift
  fi
  fmt=$1
  shift
  if (( lines > 0 )); then
    printf '\033[%dF' "$lines"
  else
    printf '\r'
  fi
  printf '\033[J'
  if [[ $# -gt 0 ]]; then
    # shellcheck disable=SC2059
    printf "$fmt" "$@"
  else
    printf '%b' "$fmt"
  fi
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
