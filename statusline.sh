#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // empty')
DIR_NAME="${DIR##*/}"
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
WORKTREE=$(echo "$input" | jq -r '.worktree.name // empty')
INPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUTPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# Git branch (fast, no network)
BRANCH=""
if [ -n "$DIR" ] && [ -d "$DIR" ]; then
  BRANCH=$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# Duration formatting
DURATION_S=$((DURATION_MS / 1000))
if [ "$DURATION_S" -ge 3600 ]; then
  DURATION="$((DURATION_S / 3600))h$((DURATION_S % 3600 / 60))m"
elif [ "$DURATION_S" -ge 60 ]; then
  DURATION="$((DURATION_S / 60))m$((DURATION_S % 60))s"
else
  DURATION="${DURATION_S}s"
fi

# Colors
RESET="\033[0m"
DIM="\033[2m"
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
MAGENTA="\033[35m"

# 2x off-peak indicator (valid until end of March 2026)
TWOX=""
NOW_EPOCH=$(date +%s)
EXPIRY_EPOCH=$(date -j -f "%Y-%m-%d" "2026-04-01" +%s 2>/dev/null || date -d "2026-04-01" +%s 2>/dev/null)
if [ "$NOW_EPOCH" -lt "$EXPIRY_EPOCH" ]; then
  # Day of week in PT (1=Mon..7=Sun) and hour in PT (0-23)
  PT_DOW=$(TZ="America/Los_Angeles" date +%u)
  PT_HOUR=$(TZ="America/Los_Angeles" date +%H | sed 's/^0//')
  [ -z "$PT_HOUR" ] && PT_HOUR=0
  IS_WEEKEND=0
  [ "$PT_DOW" -ge 6 ] && IS_WEEKEND=1
  IS_OFFPEAK=0
  if [ "$IS_WEEKEND" -eq 1 ]; then
    IS_OFFPEAK=1
  elif [ "$PT_HOUR" -lt 5 ] || [ "$PT_HOUR" -ge 11 ]; then
    IS_OFFPEAK=1
  fi
  if [ "$IS_OFFPEAK" -eq 1 ]; then
    TWOX=" \033[1;33m2x\033[0m"
  fi
fi

# Line 1: model, dir, branch, worktree
LINE1="${DIM}[${RESET}${BOLD}${MODEL}${RESET}${DIM}]${RESET}"
[ -n "$DIR_NAME" ] && LINE1="$LINE1 ${CYAN}${DIR_NAME}${RESET}"
[ -n "$BRANCH" ] && LINE1="$LINE1 ${DIM}on${RESET} ${MAGENTA}${BRANCH}${RESET}"
[ -n "$WORKTREE" ] && LINE1="$LINE1 ${DIM}(wt:${WORKTREE})${RESET}"
[ -n "$TWOX" ] && LINE1="$LINE1${TWOX}"

# Line 2: context bar + stats
if [ "$PCT" -ge 80 ]; then
  BAR_COLOR="$RED"
elif [ "$PCT" -ge 50 ]; then
  BAR_COLOR="$YELLOW"
else
  BAR_COLOR="$GREEN"
fi

# Progress bar (20 chars wide)
FILLED=$((PCT / 5))
EMPTY=$((20 - FILLED))
BAR=""
for ((i=0; i<FILLED; i++)); do BAR="${BAR}█"; done
for ((i=0; i<EMPTY; i++)); do BAR="${BAR}░"; done

LINE2="${BAR_COLOR}${BAR} ${PCT}%${RESET} ${DIM}|${RESET} ${GREEN}+${ADDED}${RESET}/${RED}-${REMOVED}${RESET} ${DIM}|${RESET} ${DURATION}"

# Real cost from Claude Code (API-equivalent USD)
REAL_COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
COST_DISPLAY=$(awk "BEGIN { printf \"%.2f\", $REAL_COST }")

# Format token counts (e.g. 125432 -> 125k)
fmt_tokens() {
  local t=$1
  if [ "$t" -ge 1000000 ]; then
    awk "BEGIN { printf \"%.1fM\", $t / 1000000 }"
  elif [ "$t" -ge 1000 ]; then
    awk "BEGIN { printf \"%.0fk\", $t / 1000 }"
  else
    echo "$t"
  fi
}
IN_FMT=$(fmt_tokens "$INPUT_TOKENS")
OUT_FMT=$(fmt_tokens "$OUTPUT_TOKENS")

# Commentary tiers based on real cost
COST_CENTS=$(awk "BEGIN { printf \"%d\", $REAL_COST * 100 }")
if [ "$COST_CENTS" -ge 500 ]; then
  QUIP="shareholders are weeping"
elif [ "$COST_CENTS" -ge 100 ]; then
  QUIP="Anthropic finance dept stirring"
elif [ "$COST_CENTS" -ge 10 ]; then
  QUIP="tokens flowing nicely"
else
  QUIP="warming up"
fi

LINE3="${DIM}tokens${RESET} ${CYAN}↓${IN_FMT}${RESET} ${MAGENTA}↑${OUT_FMT}${RESET} ${DIM}|${RESET} \$${COST_DISPLAY} ${DIM}— ${QUIP}${RESET}"

echo -e "$LINE1"
echo -e "$LINE2"
echo -e "$LINE3"
