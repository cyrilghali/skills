#!/usr/bin/env bash
# Clean the Cubic noise from a PR's discussion. The viewer's own @cubic-dev-ai pings are
# deleted; Cubic's "started the review" acknowledgements and its comments on resolved
# threads are hidden (minimized as OUTDATED), since only their author can delete them.
set -euo pipefail

if [[ $# -lt 1 || ! "$1" =~ ^[0-9]+$ ]]; then
  echo "usage: $(basename "$0") <pull-request-number>" >&2
  exit 64
fi

pr="$1"
bot="cubic-dev-ai"
read -r owner repo < <(gh repo view --json owner,name --jq '"\(.owner.login) \(.name)"')
me=$(gh api user --jq .login)

state=$(gh api graphql -F owner="$owner" -F repo="$repo" -F pr="$pr" -f query='
query($owner:String!, $repo:String!, $pr:Int!) {
  repository(owner:$owner, name:$repo) { pullRequest(number:$pr) {
    comments(last:100) { nodes { id databaseId body isMinimized author { login } } }
    reviewThreads(last:100) { nodes { isResolved comments(first:50) { nodes { id isMinimized author { login } } } } }
  } }
}')

own_pings=$(jq -r --arg me "$me" '
  .data.repository.pullRequest.comments.nodes[]
  | select(.author.login == $me and (.body | test("^@cubic-dev-ai"))) | .databaseId' <<<"$state")

ids=$(jq -r --arg bot "$bot" --arg me "$me" '
  .data.repository.pullRequest as $pr
  | ($pr.comments.nodes[] | select(.author.login != $bot and .author.login != $me and (.body | test("^@cubic-dev-ai")))),
    ($pr.comments.nodes[] | select(.author.login == $bot and (.body | test("started the AI code review")))),
    ($pr.reviewThreads.nodes[] | select(.isResolved) | .comments.nodes[] | select(.author.login == $bot))
  | select(.isMinimized | not) | .id' <<<"$state")

deleted=0
for id in $own_pings; do
  gh api -X DELETE "repos/$owner/$repo/issues/comments/$id" >/dev/null
  deleted=$((deleted + 1))
done

hidden=0
for id in $ids; do
  gh api graphql -f id="$id" -f query='
    mutation($id:ID!) { minimizeComment(input:{subjectId:$id, classifier:OUTDATED}) { minimizedComment { isMinimized } } }' >/dev/null
  hidden=$((hidden + 1))
done

echo "cubic noise: deleted $deleted ping(s), hid $hidden comment(s) on PR $pr"
