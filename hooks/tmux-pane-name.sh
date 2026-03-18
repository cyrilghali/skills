#!/usr/bin/env bash
# Pick a random name for this Claude instance's tmux pane

NAMES=(
  # Military Division
  "Special Opus Forces"
  "The Sonnet Squad"
  "Opus Division"
  # Pop Culture
  "The Claudetroopers"
  "The Clone Wars"
  "The Claudeminions"
)

NAME="${NAMES[$((RANDOM % ${#NAMES[@]}))]}"

# Set tmux pane title if we're inside tmux
if [ -n "$TMUX" ]; then
  tmux select-pane -T "$NAME"
fi
