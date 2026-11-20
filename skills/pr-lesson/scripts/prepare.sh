#!/usr/bin/env bash
# prepare.sh <owner/repo> <pr number> --home <store> --repo <owner/repo>=<checkout> [--repo ...]
#
# Prints one JSON object with what a lesson needs before any code is read: the pull request, the commit
# it started from (`base`, the merge-base) and its last commit (`head`) for every repo given, the changed
# files, the ticket key when the branch or the title names one, the areas the store already holds, and,
# when PR_LESSON_AREAS names a folder of area notes, the area ids that folder lists (`area_ids`).
# It fetches both commits into the checkout of the pull request's repo, so `git show <sha>:<path>` works.
# The first --repo must be the pull request's repo; the others are repos the lesson may cite (a front end).
# Exit 1: the pull request or a checkout cannot be read. Exit 2: bad arguments. Needs gh, git, jq.
set -euo pipefail
die() { echo "error: $1" >&2; [ -n "${2:-}" ] && echo "  next: $2" >&2; exit "${3:-1}"; }
[ $# -ge 2 ] || die "usage: prepare.sh <owner/repo> <pr number> --home <store> --repo <owner/repo>=<checkout>" "" 2
repo=$1 pr=$2; shift 2
home="" repos=()
while [ $# -gt 0 ]; do
  case $1 in
    --home) home=${2:?}; shift 2 ;;
    --repo) repos+=("${2:?}"); shift 2 ;;
    *) die "unknown argument $1" "run with no argument to see the usage" 2 ;;
  esac
done
[ -n "$home" ] || die "--home <store> is missing" "pass the folder that holds areas/ and records/" 2
[ ${#repos[@]} -gt 0 ] && [ "${repos[0]%%=*}" = "$repo" ] || die "the first --repo must be $repo=<its checkout>" "" 2
for tool in gh git jq; do command -v "$tool" >/dev/null || die "$tool is not installed" "install $tool"; done
dir=${repos[0]#*=}
git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || die "$dir is not a git checkout of $repo" "clone $repo there, or fix --repo"

meta=$(gh pr view "$pr" -R "$repo" --json number,title,author,isDraft,state,url,baseRefName,headRefName,headRefOid,body) ||
  die "cannot read pull request $pr of $repo" "check the number and run gh auth status"
head=$(jq -r .headRefOid <<<"$meta") base_ref=$(jq -r .baseRefName <<<"$meta")
base=$(gh api "repos/$repo/compare/$base_ref...$head" --jq .merge_base_commit.sha) || die "cannot compute the merge-base of $pr" "retry; GitHub may be slow"
git -C "$dir" fetch --quiet origin "$head" "$base" 2>/dev/null || git -C "$dir" fetch --quiet origin "pull/$pr/head" "$base_ref" ||
  die "cannot fetch the commits of $pr into $dir" "run git -C $dir fetch origin by hand and read its error"
git -C "$dir" cat-file -e "$base^{commit}" && git -C "$dir" cat-file -e "$head^{commit}" || die "the commits of $pr are not in $dir after the fetch"

shas=$(jq -n --arg r "$repo" --arg b "$base" --arg h "$head" '{($r): {base: $b, head: $h}}')
for extra in "${repos[@]:1}"; do
  r=${extra%%=*} d=${extra#*=}
  git -C "$d" fetch --quiet origin 2>/dev/null || true
  tip=$(git -C "$d" rev-parse --verify --quiet "origin/HEAD^{commit}" || git -C "$d" rev-parse "HEAD^{commit}") || die "$d is not a git checkout of $r"
  shas=$(jq --arg r "$r" --arg t "$tip" '. + {($r): {base: $t, head: $t}}' <<<"$shas")
done
files=$(gh api --paginate "repos/$repo/pulls/$pr/files?per_page=100" --jq '.[] | {path: .filename, status, additions, deletions}' | jq -sc .)
ticket=$(jq -r '[.headRefName, .title, .body] | join(" ")' <<<"$meta" | grep -oiE '\b[A-Z]{2,6}-[0-9]{2,6}\b' | head -1 | tr '[:lower:]' '[:upper:]' || true)
areas='[]'
for f in "$home"/areas/*.json; do
  [ -e "$f" ] || continue
  areas=$(jq --slurpfile a "$f" --arg f "$f" '. + [$a[0] | {area, name, title, file: $f, lessons: [(.lessons // [])[] | {pr, marker, steps: (.steps | length)}]}]' <<<"$areas")
done
area_ids='[]'
[ -d "${PR_LESSON_AREAS:-}" ] && area_ids=$(for f in "$PR_LESSON_AREAS"/*; do n=$(basename "$f"); n=${n%.*}; case $n in README|readme|index) ;; *) echo "$n" ;; esac; done | jq -Rsc 'split("\n") | map(select(. != ""))')
slug="${repo##*/}-$pr"
mkdir -p "$home/work" "$home/areas"
jq -n --argjson m "$meta" --argjson shas "$shas" --argjson files "$files" --arg ticket "$ticket" --argjson areas "$areas" --argjson ids "$area_ids" --arg hints "${PR_LESSON_AREAS:-}" \
  --arg repo "$repo" --arg work "$home/work/$slug.json" --arg today "$(date +%F)" '{
  pr: {repo: $repo, number: $m.number, title: $m.title, author: $m.author.login, draft: $m.isDraft, state: $m.state, url: $m.url},
  shas: $shas, written: $today, ticket: (if $ticket == "" then null else $ticket end),
  description: ($m.body // "" | .[0:3000]), files: $files, areas: $areas, area_ids: $ids, area_notes: (if $hints == "" then null else $hints end), record: $work}'
