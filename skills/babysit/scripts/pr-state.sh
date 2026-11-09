#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ! "$1" =~ ^[0-9]+$ ]]; then
  echo "usage: $(basename "$0") <pull-request-number>" >&2
  exit 64
fi

for command in gh jq; do
  command -v "$command" >/dev/null || {
    echo "missing required command: $command" >&2
    exit 69
  }
done

pr="$1"
gh pr view "$pr" --json number,title,url,state,isDraft,headRefName,headRefOid,baseRefName,mergeStateStatus,reviewDecision,statusCheckRollup \
  | jq '{number, title, url, state, isDraft, head: .headRefName, head_sha: .headRefOid, base: .baseRefName, merge_state: .mergeStateStatus, review_decision: .reviewDecision, checks: [.statusCheckRollup[]? | {name, status, conclusion, detailsUrl}]}'
