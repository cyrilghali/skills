#!/usr/bin/env bash
# PostToolUse hook: run shellcheck on .sh files after Write/Edit
# Advisory only — always exits 0

command -v shellcheck > /dev/null 2>&1 || exit 0

# Read the file path from stdin (Claude Code passes JSON context)
input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // empty')

[[ -z "$file" ]] && exit 0
[[ "$file" != *.sh ]] && exit 0
[[ "$file" == *node_modules* ]] && exit 0
[[ "$file" == *worktrees* ]] && exit 0
[[ ! -f "$file" ]] && exit 0

output=$(shellcheck --format=gcc "$file" 2>&1)
if [[ -n "$output" ]]; then
  echo "shellcheck warnings:" >&2
  echo "$output" >&2
fi

exit 0
