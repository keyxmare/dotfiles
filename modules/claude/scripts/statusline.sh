#!/bin/bash
input=$(cat)

# Model & version
MODEL=$(echo "$input" | jq -r '.model.display_name // "unknown"')
VERSION=$(echo "$input" | jq -r '.version // "?"')

# Context window
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
INPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUTPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# Cost
COST=$(LC_NUMERIC=C printf "%.5f" "$(echo "$input" | jq -r '.cost.total_cost_usd // 0')")

# Duration
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
HOURS=$((DURATION_MS / 3600000))
MINS=$(((DURATION_MS % 3600000) / 60000))
SECS=$(((DURATION_MS % 60000) / 1000))
if [ "$HOURS" -gt 0 ]; then
  DURATION="${HOURS}h${MINS}m"
elif [ "$MINS" -gt 0 ]; then
  DURATION="${MINS}m${SECS}s"
else
  DURATION="${SECS}s"
fi

# Lines changed
LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# Progress bar for context usage
BAR_WIDTH=20
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))

if [ "$PCT" -lt 50 ]; then
  COLOR="\033[32m" # green
elif [ "$PCT" -lt 80 ]; then
  COLOR="\033[33m" # yellow
else
  COLOR="\033[31m" # red
fi
RESET="\033[0m"

BAR="${COLOR}"
for ((i=0; i<FILLED; i++)); do BAR+="█"; done
for ((i=0; i<EMPTY; i++)); do BAR+="░"; done
BAR+="${RESET}"

printf "%b %s v%s | %b %s%% (%s↓ %s↑) | 💲%s | ⏱ %s | +%s -%s" \
  "🤖" "$MODEL" "$VERSION" \
  "$BAR" "$PCT" "$INPUT_TOKENS" "$OUTPUT_TOKENS" \
  "$COST" \
  "$DURATION" \
  "$LINES_ADDED" "$LINES_REMOVED"
