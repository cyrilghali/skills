#!/usr/bin/env bash
# The mechanical half of a stack rewrite; the commit grouping stays with the agent.
#   stack.sh snapshot        back up every branch, print each one's base and commit count
#   stack.sh replay <branch> replay <branch>'s own commits onto its rewritten parent
#   stack.sh check           prove the stack's final tree is unchanged, refresh gh stack
#   stack.sh restore         put every branch back to its snapshot, even mid-conflict
set -euo pipefail

# The snapshot keeps the stack's shape, because gh stack view fails on the detached HEAD of a stopped rebase.
SAVED="$(git rev-parse --git-dir)/rewrite-stack.json"

if [ "${1:-}" = snapshot ]; then
  STACK=$(gh stack view --json) || { echo "not on a gh stack branch" >&2; exit 1; }
else
  [ -f "$SAVED" ] || { echo "no snapshot: run stack.sh snapshot first" >&2; exit 1; }
  STACK=$(cat "$SAVED")
fi
TRUNK=$(jq -r '.trunk' <<<"$STACK")
BRANCHES=()
while IFS= read -r b; do BRANCHES+=("$b"); done < <(jq -r '.branches[] | select(.isMerged | not) | .name' <<<"$STACK")
[ "${#BRANCHES[@]}" -gt 0 ] || { echo "every branch of this stack is merged" >&2; exit 1; }
TOP=${BRANCHES[${#BRANCHES[@]}-1]}

backup() { echo "refs/rewrite-backup/$1"; }
parent_of() {
  local prev="" b
  for b in "${BRANCHES[@]}"; do
    if [ "$b" = "$1" ]; then
      if [ -n "$prev" ]; then echo "$prev"; else
        git merge-base "$(git rev-parse --verify --quiet "origin/$TRUNK" || echo "$TRUNK")" "$b"
      fi
      return
    fi
    prev=$b
  done
  echo "$1 is not an open branch of this stack" >&2; exit 1
}

case "${1:-}" in
  snapshot)
    [ -z "$(git status --porcelain)" ] || { echo "working tree not clean" >&2; exit 1; }
    stale=$(jq -r '.branches[] | select((.isMerged | not) and .needsRebase) | .name' <<<"$STACK")
    [ -z "$stale" ] || { echo "run gh stack rebase first; these branches need it: $stale" >&2; exit 1; }
    here=$(git rev-parse --show-toplevel)
    for b in "${BRANCHES[@]}"; do
      elsewhere=$(git worktree list --porcelain | awk -v ref="branch refs/heads/$b" -v here="$here" '/^worktree /{wt=substr($0,10)} $0==ref && wt!=here {print wt}')
      [ -z "$elsewhere" ] || { echo "$b is checked out in $elsewhere; switch it away first" >&2; exit 1; }
    done
    printf '%s\n' "$STACK" > "$SAVED"
    for b in "${BRANCHES[@]}"; do
      git update-ref "$(backup "$b")" "$b"
      p=$(parent_of "$b")
      printf '%s\tbase %s\t%s commits\n' "$b" "$p" "$(git rev-list --count "$p..$b")"
    done ;;
  replay)
    b=${2:?usage: stack.sh replay <branch>}
    p=$(parent_of "$b")
    [ "$b" != "${BRANCHES[0]}" ] || { echo "the bottom branch has nothing to replay" >&2; exit 1; }
    git switch -q "$b"
    # --no-update-refs: a global rebase.updateRefs would drag other refs along.
    git rebase --no-update-refs --onto "$p" "$(backup "$p")" "$b" ;;
  check)
    if [ "$(git rev-parse "$TOP^{tree}")" != "$(git rev-parse "$(backup "$TOP")^{tree}")" ]; then
      echo "FAIL: the stack's final tree changed:" >&2
      git diff --stat "$(backup "$TOP")" "$TOP" >&2
      exit 1
    fi
    out=$(gh stack rebase --no-trunk 2>&1) || { echo "$out" >&2; exit 1; }
    for b in "${BRANCHES[@]}"; do echo "== $b"; git log --oneline "$(parent_of "$b")..$b"; done
    echo "OK: final tree unchanged. Push with: gh stack push" ;;
  restore)
    if [ -d "$(git rev-parse --git-path rebase-merge)" ] || [ -d "$(git rev-parse --git-path rebase-apply)" ]; then
      git rebase --abort
    fi
    git reset -q --hard
    git switch -q --detach
    for b in "${BRANCHES[@]}"; do git branch -f "$b" "$(backup "$b")"; done
    git switch -q -f "$TOP"
    echo "every branch is back at its snapshot" ;;
  *) sed -n '2,6p' "$0" >&2; exit 2 ;;
esac
