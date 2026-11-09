#!/usr/bin/env bash
# Ask Cubic to review the PR's current head (once per head) and wait for that review.
# A third argument asks again on a head Cubic already reviewed (after a finding is
# answered or the ticket changed), with that text as the message, and waits for the new review.
# Exit 0: review on the current head is in. Exit 75: timed out waiting.
set -euo pipefail

if [[ $# -lt 1 || ! "$1" =~ ^[0-9]+$ ]]; then
  echo "usage: $(basename "$0") <pull-request-number> [timeout-seconds, default 1800] [message to ask again]" >&2
  exit 64
fi

pr="$1"
timeout="${2:-1800}"
again="${3:-}"
bot="cubic-dev-ai[bot]"
interval=55

repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
hide_noise="$(dirname "$0")/hide-cubic-noise.sh"
head_sha=$(gh pr view "$pr" --json headRefOid --jq .headRefOid)
head_date=$(gh api "repos/$repo/commits/$head_sha" --jq .commit.committer.date)

since=""
reviewed_head() {
  gh api "repos/$repo/pulls/$pr/reviews" --paginate \
    --jq "[.[] | select(.user.login == \"$bot\" and .commit_id == \"$head_sha\" and .submitted_at >= \"$since\")] | length"
}

tagged_since_head() {
  gh api "repos/$repo/issues/$pr/comments" --paginate \
    --jq "[.[] | select((.body | test(\"@cubic-dev-ai\")) and .user.login != \"$bot\" and .created_at >= \"$head_date\")] | length"
}

if [[ -n "$again" ]]; then
  "$hide_noise" "$pr"
  since=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  gh pr comment "$pr" --body "@cubic-dev-ai $again" >/dev/null
  echo "cubic: asked again on head ${head_sha:0:7}"
elif [[ "$(reviewed_head)" -gt 0 ]]; then
  echo "cubic: already reviewed head ${head_sha:0:7}"
  "$hide_noise" "$pr"
  exit 0
fi

[[ -z "$again" ]] && "$hide_noise" "$pr"

if [[ -n "$again" ]]; then
  :
elif [[ "$(tagged_since_head)" -eq 0 ]]; then
  gh pr comment "$pr" --body "@cubic-dev-ai please review this draft PR." >/dev/null
  echo "cubic: tagged on head ${head_sha:0:7}"
else
  echo "cubic: already tagged on head ${head_sha:0:7}"
fi

deadline=$(( $(date +%s) + timeout ))
while (( $(date +%s) < deadline )); do
  sleep "$interval"
  current=$(gh pr view "$pr" --json headRefOid --jq .headRefOid)
  if [[ "$current" != "$head_sha" ]]; then
    echo "cubic: head moved to ${current:0:7}; rerun for the new head"
    exit 75
  fi
  if [[ "$(reviewed_head)" -gt 0 ]]; then
    echo "cubic: review in on head ${head_sha:0:7}"
    "$hide_noise" "$pr"
    exit 0
  fi
done

echo "cubic: no review on head ${head_sha:0:7} after ${timeout}s"
exit 75
