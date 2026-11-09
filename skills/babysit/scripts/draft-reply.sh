#!/usr/bin/env bash
# Answers a review thread. A bot's thread gets the reply posted and is resolved; a person's thread
# gets the reply in the viewer's pending review, unsent, and stays open for its author.
set -euo pipefail

if [[ $# -ne 3 || ! "$1" =~ ^[0-9]+$ || -z "$3" ]]; then
  echo "usage: $(basename "$0") <pull-request-number> <review-thread-node-id> <reply-body>" >&2
  exit 64
fi

for command in gh jq; do
  command -v "$command" >/dev/null || {
    echo "missing required command: $command" >&2
    exit 69
  }
done

pr="$1"
thread="$2"
body="$3"
owner=$(gh repo view --json owner -q .owner.login)
repo=$(gh repo view --json name -q .name)

state=$(gh api graphql -F owner="$owner" -F repo="$repo" -F pr="$pr" -F thread="$thread" -f query='
query($owner:String!, $repo:String!, $pr:Int!, $thread:ID!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$pr) {
      id
      reviews(states:PENDING, first:20) { nodes { id viewerDidAuthor } }
    }
  }
  node(id:$thread) {
    ... on PullRequestReviewThread {
      isResolved
      comments(first:1) { nodes { id author { __typename login } } }
    }
  }
}')

pr_id=$(jq -r '.data.repository.pullRequest.id' <<<"$state")
review_id=$(jq -r '[.data.repository.pullRequest.reviews.nodes[] | select(.viewerDidAuthor)][0].id // empty' <<<"$state")
first_comment=$(jq -r '.data.node.comments.nodes[0].id // empty' <<<"$state")
opener_type=$(jq -r '.data.node.comments.nodes[0].author.__typename // empty' <<<"$state")
opener=$(jq -r '.data.node.comments.nodes[0].author.login // empty' <<<"$state")

[[ -n "$first_comment" ]] || {
  echo "thread $thread not found on PR #$pr" >&2
  exit 66
}

is_resolved=$(jq -r '.data.node.isResolved' <<<"$state")

if [[ "$opener_type" == "Bot" ]]; then
  # GitHub files any new review comment into the viewer's pending review, so posting would leave it unsent.
  [[ -z "$review_id" ]] || {
    echo "pending review $review_id exists on PR #$pr: submit or delete it before posting to bot thread $thread" >&2
    exit 65
  }
  gh api graphql -F thread="$thread" -f body="$body" -f query='
    mutation($thread:ID!, $body:String!) {
      addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$thread, body:$body}) { comment { id } }
    }' >/dev/null
  echo "posted reply on bot thread $thread (opened by $opener)"
  if [[ "$is_resolved" != "true" ]]; then
    gh api graphql -F thread="$thread" -f query='
      mutation($thread:ID!) { resolveReviewThread(input:{threadId:$thread}) { thread { isResolved } } }' >/dev/null
    echo "resolved bot thread $thread"
  fi
  exit 0
fi

if [[ -z "$review_id" ]]; then
  review_id=$(gh api graphql -F pr="$pr_id" -f query='
    mutation($pr:ID!) { addPullRequestReview(input:{pullRequestId:$pr}) { pullRequestReview { id } } }' \
    -q .data.addPullRequestReview.pullRequestReview.id)
fi

gh api graphql -F review="$review_id" -F reply_to="$first_comment" -f body="$body" -f query='
  mutation($review:ID!, $reply_to:ID!, $body:String!) {
    addPullRequestReviewComment(input:{pullRequestReviewId:$review, inReplyTo:$reply_to, body:$body}) { comment { id } }
  }' >/dev/null
echo "drafted reply in pending review $review_id (thread opened by $opener)"
