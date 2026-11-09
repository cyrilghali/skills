#!/usr/bin/env bash
# PostToolUse(Bash): after a PR is opened or a branch pushed, tell the agent to start babysit.
# Fires on the tool's output, not the command text alone: a command that only mentions
# `gh pr create` (an echo, a test fixture) opens no PR and pushes nothing.
# A push whose commits are trivial (prose files only, or :atom names such as feature flags renamed everywhere)
# gets a CI-only message; anything else, and every PR creation, gets the Cubic retag.
set -euo pipefail
export LC_ALL=C

input=$(cat)
command=$(jq -r '.tool_input.command // ""' <<<"$input")
output=$(jq -r '[.tool_response.stdout // "", .tool_response.stderr // ""] | join("\n")' <<<"$input")

start='(^|[;&|(]|&&|\|\|)[[:space:]]*'
opened_pr=false
pushed=false
[[ "$command" =~ ${start}gh[[:space:]]+(pr[[:space:]]+create|stack[[:space:]]+(push|submit)) ]] &&
  [[ "$output" =~ github\.com/[^[:space:]]+/pull/[0-9]+ ]] && opened_pr=true
[[ "$command" =~ ${start}git[[:space:]]+push ]] &&
  ! [[ "$output" =~ (Everything\ up-to-date|\[rejected\]|error:|fatal:) ]] && pushed=true
$opened_pr || $pushed || exit 0

prose='(\.(md|rst|adoc)$|^docs/)'
ident='^[A-Za-z_][A-Za-z0-9_]*[A-Za-z_][A-Za-z0-9_]*$'
atom_start='(^|[[:space:]([{,]):$'

# Trivial: every changed file is a regular file edited in place, and each is prose or differs
# only by renames of snake_case atoms that keep their first two segments (:a_b_small -> :a_b_lateral),
# where the old name is gone from the new tree and the new name was absent from the old one.
# ponytail: an atom named outside the repo (an API key, a stored flag's state) reads as trivial;
# variables, functions and strings always get Cubic.
trivial_range() {
  local old=$1 new=$2 meta path line code=()
  git cat-file -e "$old^{commit}" 2>/dev/null && git cat-file -e "$new^{commit}" 2>/dev/null || return 1
  while IFS= read -r -d '' meta && IFS= read -r -d '' path; do
    [[ "$meta" =~ ^:(100644|100755)\ (100644|100755)\ [0-9a-f]+\ [0-9a-f]+\ M$ ]] || return 1
    [[ "${BASH_REMATCH[1]}" == "${BASH_REMATCH[2]}" ]] || return 1
    [[ "$path" =~ $prose ]] || code+=("$path")
  done < <(git diff --no-renames --raw -z "$old" "$new")
  ((${#code[@]})) || return 0

  local g=(git --literal-pathspecs diff --word-diff=porcelain
    --word-diff-regex='[A-Za-z0-9_]+|[^[:space:]]|[[:space:]]+' "$old" "$new" --)
  # Binary and `-diff` files print no hunk, so a file without one is not proven trivial.
  [[ "$("${g[@]}" "${code[@]}" | awk '/^diff --git/ {f++} /^@@/ && !seen[f]++ {h++} END {print h+0}')" == "${#code[@]}" ]] || return 1

  local map=$'\n' removed="" prev=""
  while IFS= read -r line; do
    case "$line" in
      -*) [[ -z "$removed" && "$prev" =~ $atom_start ]] || return 1; removed=${line:1} ;;
      +*)
        local from=$removed to=${line:1}
        [[ -n "$from" && "$from" =~ $ident && "$to" =~ $ident ]] || return 1
        [[ "$from" =~ ^([A-Za-z0-9]+_[A-Za-z0-9]+_) && "$to" == "${BASH_REMATCH[1]}"?* ]] || return 1
        if [[ "$map" != *$'\n'"$from=$to"$'\n'* ]]; then
          [[ "$map" != *$'\n'"$from="* && "$map" != *"=$to"$'\n'* ]] || return 1
          ! git grep -qw -e "$from" "$new" -- && ! git grep -qw -e "$to" "$old" -- || return 1
          map+="$from=$to"$'\n'
        fi
        removed=""
        ;;
      *) [ -z "$removed" ] || return 1 ;;
    esac
    prev=$line
  done < <("${g[@]}" "${code[@]}" | awk '/^diff --git/ {body=0} /^@@/ {body=1; next} body')
  [ -z "$removed" ]
}

trivial=false
if $pushed && ! $opened_pr && ! [[ "$output" =~ \[new\ branch\] ]]; then
  ranges=$(awk '/^To / {on=1; next} on' <<<"$output" |
    grep -oE '^ [ +] [0-9a-f]{7,40}\.\.\.?[0-9a-f]{7,40} ' | grep -oE '[0-9a-f]{7,40}\.\.\.?[0-9a-f]{7,40}' || true)
  if [ -n "$ranges" ]; then
    trivial=true
    while read -r range; do
      old=${range%%.*} new=${range##*.}
      trivial_range "$old" "$new" || { trivial=false; break; }
    done <<<"$ranges"
  fi
fi

if $trivial; then
  jq -n '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: "A trivial change was just pushed to a pull request (prose files only, or an :atom such as a feature flag renamed everywhere it appears). Start the babysit skill on it in check mode for CI only: do not run scripts/cubic-review.sh for this push. Cubic still has to review the final head before `gh pr ready`, so run scripts/cubic-review.sh once when the PR is about to leave draft."}}'
else
  jq -n '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: "A pull request was just opened or pushed. Start the babysit skill on it in drive mode now (for a stack still being built, keep building and babysit once every PR exists, starting at the merge frontier): run scripts/cubic-review.sh in the background so Cubic is tagged and awaited, then triage its review and CI."}}'
fi
