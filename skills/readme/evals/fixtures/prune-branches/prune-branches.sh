#!/bin/bash
# Lists local branches already merged into the base branch; deletes them only with --delete.
set -eu
base=main delete=0
for arg in "$@"; do
  case $arg in
    --delete) delete=1 ;;
    --base=*) base=${arg#--base=} ;;
    *) echo "usage: prune-branches.sh [--base=BRANCH] [--delete]" >&2; exit 2 ;;
  esac
done
current=$(git branch --show-current)
merged=$(git branch --merged "$base" --format='%(refname:short)' | grep -vx -e "$base" -e "$current" || true)
[ -z "$merged" ] && { echo "nothing to prune"; exit 0; }
if [ $delete = 1 ]; then
  echo "$merged" | xargs git branch -d
else
  echo "would delete:"; echo "$merged" | sed 's/^/  /'
  echo "rerun with --delete to delete them"
fi
