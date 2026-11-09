#!/usr/bin/env bash
# Finds the Claude Code sessions behind a pull request and prints their conversation.
#
#   sessions.sh list <pr-url>     candidate sessions, the ones that built the PR first
#   sessions.sh dump <session>    the owner's messages and the assistant's prose, in order
#
# Transcripts are read from $PR_BREAKDOWN_TRANSCRIPTS, default: Claude Code's projects directory.
set -euo pipefail

root="${PR_BREAKDOWN_TRANSCRIPTS:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects}"
max="${PR_BREAKDOWN_MAX_CHARS:-1500}"

# ripgrep reads the gigabytes of transcripts in seconds where BSD grep takes minutes.
search_files() {
  if command -v rg >/dev/null; then rg -uu -lF "${@/#/--regexp=}" -g '*.jsonl' "$root"
  else grep -rlF "${@/#/-e}" --include='*.jsonl' "$root"; fi
}

usage() { sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

list() {
  local url="$1"
  [[ "$url" =~ github\.com/([^/]+/[^/]+)/pull/([0-9]+) ]] || { echo "error: not a GitHub pull request URL: $url" >&2; exit 2; }
  local repo="${BASH_REMATCH[1]}" number="${BASH_REMATCH[2]}"
  local branch
  branch=$(gh pr view "$number" -R "$repo" --json headRefName --jq .headRefName) \
    || { echo "error: gh could not read $repo#$number" >&2; exit 1; }
  [ -d "$root" ] || { echo "error: no transcripts directory at $root (set PR_BREAKDOWN_TRANSCRIPTS)" >&2; exit 1; }

  local files
  files=$(search_files "$repo/pull/$number" "$branch" 2>/dev/null || true)
  if [ -z "$files" ]; then
    echo "none: no session mentions $repo#$number or its branch $branch"
    return
  fi

  printf 'role\thits\tmodified\tsession\n'
  while IFS= read -r file; do
    local hits role=mentions
    hits=$(grep -cF -e "$repo/pull/$number" -e "$branch" "$file" || true)
    # The session that pushed the branch or opened the PR wrote it; others only discuss it.
    grep -qE "(git push|gh stack push|gh pr create)[^\"]*$branch" "$file" && role=built
    printf '%s\t%s\t%s\t%s\n' "$role" "$hits" "$(date -r "$file" '+%Y-%m-%d %H:%M')" "$file"
  done <<< "$files" | sort -t$'\t' -k1,1 -k2,2nr
}

dump() {
  local file="$1"
  [ -f "$file" ] || { echo "error: no such session file: $file" >&2; exit 2; }
  # Answers to the question prompt arrive as tool results, not as typed messages; they are decisions too.
  jq -r --argjson max "$max" '
    def clip: if length > $max then .[0:$max] + " […]" else . end;
    def at: "[" + ((.timestamp // "")[0:16] | sub("T"; " ")) + "] ";
    def typed:
      if (.message.content | type) == "string" then .message.content
      else [.message.content[]? | select(.type == "text") | .text] | join("\n") end;
    if .type == "user" then
      at as $at
      | ((typed
          | select(. != "" and (startswith("<") | not) and (startswith("Stop hook feedback") | not))
          | "\n" + $at + ">>> OWNER: " + clip),
         (.message.content | arrays | .[] | select(.type == "tool_result")
          | (.content | if type == "array" then map(.text? // "") | join("") else tostring end)
          | select(startswith("Your questions have been answered") or startswith("User has answered"))
          | "\n" + $at + ">>> OWNER ANSWERED: " + clip))
    elif .type == "assistant" then
      at as $at
      | .message.content[]?
      | if .type == "text" then $at + "ASSISTANT: " + (.text | clip)
        elif .type == "tool_use" and .name == "AskUserQuestion" then
          $at + "ASSISTANT ASKED: "
          + ([.input.questions[]? | .question + " Options: " + ([.options[]?.label] | join(" | "))] | join(" / ") | clip)
        else empty end
    else empty end
  ' "$file"
}

case "${1:-}" in
  list) [ $# -eq 2 ] || usage; list "$2" ;;
  dump) [ $# -eq 2 ] || usage; dump "$2" ;;
  *) usage ;;
esac
