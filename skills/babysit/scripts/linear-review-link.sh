#!/usr/bin/env bash
# Print the Linear review deep link of a GitHub PR, from the Linear bot's linear-review-link comment.
# Exit 1: that comment is not on the PR yet (Linear has not opened the review).
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $(basename "$0") <pull-request-number | pull-request-url>" >&2
  exit 64
fi

for command in gh jq; do
  command -v "$command" >/dev/null || {
    echo "missing required command: $command" >&2
    exit 69
  }
done

if [[ "$1" =~ ^https://github\.com/([^/]+/[^/]+)/pull/([0-9]+) ]]; then
  repo="${BASH_REMATCH[1]}"
  pr="${BASH_REMATCH[2]}"
elif [[ "$1" =~ ^[0-9]+$ ]]; then
  pr="$1"
  repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
else
  echo "usage: $(basename "$0") <pull-request-number | pull-request-url>" >&2
  exit 64
fi

slug=$(gh api "repos/$repo/issues/$pr/comments" --paginate \
  --jq '.[] | select(.body | contains("<!-- linear-review-link -->")) | .body | split("<!-- linear-review-link -->")[1]' |
  grep -oE 'https://linear\.app/[^/"]+/review/[A-Za-z0-9-]+' | head -1 || true)

if [[ -z "$slug" ]]; then
  echo "no Linear review link on $repo#$pr yet (the bot posts it seconds after the PR opens; retry)" >&2
  exit 1
fi

echo "linear://${slug#https://linear.app/}"
