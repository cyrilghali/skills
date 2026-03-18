---
name: babysit-pr
description: Monitor your open PRs, surface blockers, auto-rebase stale branches, and offer interactive fixes. Triggers on "babysit my PRs", "check my PRs", "PR status", "shepherd PRs", "rebase my PRs", "what PRs need attention".
disable-model-invocation: true
argument-hint: "[quiet] [stale:Xh] [repo:owner/name]"
allowed-tools: Bash, Read, Grep, Glob
---

# Babysit PRs

Monitor open pull requests, classify their health, auto-rebase stale branches, and offer interactive actions to unblock them.

## Arguments

- **No args:** scan all repos where the authenticated user has open PRs.
- **`repo:owner/name`**: limit scan to a specific repository.
- **`stale:Xh`**: override the stale threshold (default: 24h since last push).
- **`quiet`**: suppress interactive prompts — output summary only. Useful for `/loop` automation.

## Phase 1: Preflight

1. Confirm `gh` CLI is authenticated:
   ```
   gh auth status
   ```
2. Determine target repos:
   - If `repo:owner/name` argument provided, use that repo only.
   - If inside a git repo, detect from `git remote get-url origin` and include it.
   - Otherwise, query all repos with the user's open PRs:
     ```
     gh search prs --author=@me --state=open --json repository --jq '.[].repository.nameWithOwner' | sort -u
     ```
3. Parse stale threshold from `stale:Xh` argument or default to 24h.

## Phase 2: Scan

For each target repo, fetch open PRs authored by the current user:

```
gh pr list --repo <repo> --author @me --state open --json number,title,baseRefName,headRefName,isDraft,reviewDecision,statusCheckRollup,mergeable,updatedAt,labels,commits
```

For each PR, classify health into exactly one category (first match wins):

| Priority | Status | Condition |
|----------|--------|-----------|
| 1 | **draft** | `isDraft` is true |
| 2 | **blocked-by-parent** | Base branch is another feature branch (not `main`/`master`/`develop`/`release/*`) and that base PR is still open |
| 3 | **ci-failing** | Any required status check is failing or errored |
| 4 | **conflicting** | `mergeable` is `CONFLICTED` |
| 5 | **changes-requested** | `reviewDecision` is `CHANGES_REQUESTED` |
| 6 | **needs-review** | `reviewDecision` is `REVIEW_REQUIRED` or no reviews yet |
| 7 | **stale** | Last push older than the stale threshold |
| 8 | **healthy** | None of the above |

### Stack Detection

Detect PR stacks: if a PR's base branch is not a default branch, look up the PR targeting that same base. Mark it as part of a stack and note the parent PR number.

## Phase 3: Auto-Rebase

For each PR classified as **stale** or behind its base:

1. **If the repo is checked out locally and the branch exists:**
   ```
   git fetch origin
   git rebase origin/<base> <head>
   git push --force-with-lease origin <head>
   ```
2. **If remote-only:**
   ```
   gh pr update-branch <number> --repo <repo>
   ```
3. Record success or failure for the summary.

Skip auto-rebase for **conflicting** PRs — flag them for manual resolution instead.

## Phase 4: Summary

Print a grouped table:

```
## PR Health Report

### <repo> (X open)

| # | Title | Status | Details |
|---|-------|--------|---------|
| 42 | Add auth flow | ci-failing | 2 checks failed: lint, test-e2e |
| 38 | Refactor DB | stale | rebased automatically |
| 35 | Update deps | healthy | 2 approvals, CI green |

Stack: #42 → #38 → #35 (base)
```

End with a one-line summary:
```
X PRs across Y repos: A healthy, B need attention, C auto-rebased
```

## Phase 5: Interactive Actions

**Skip this phase entirely if `quiet` argument is set.**

For each non-healthy PR, offer relevant actions:

- **ci-failing**: "Re-run failed checks?" → `gh pr checks <number> --repo <repo> --watch` then `gh api repos/<repo>/actions/runs/<id>/rerun-failed-jobs -X POST`
- **needs-review**: "Nudge reviewers?" → list current reviewers, offer to add a comment requesting review.
- **changes-requested**: "View review comments?" → `gh pr view <number> --repo <repo> --comments`. Then offer: "Attempt to auto-fix review comments?"
- **conflicting**: "This PR has merge conflicts. Resolve manually."
- **blocked-by-parent**: "Parent PR #X is still open. No action needed until it merges."
- **stale**: "Branch was rebased. No further action needed."

### Auto-Fix Review Comments

When the user accepts auto-fix for review comments:

1. Fetch review comments: `gh api repos/<repo>/pulls/<number>/reviews`
2. Fetch inline comments: `gh api repos/<repo>/pulls/<number>/comments`
3. For each unresolved comment requesting changes:
   - Read the referenced file and lines
   - Apply the requested change
   - Stage and commit with message: `fix(review): address <reviewer> feedback on <file>`
4. Push with `--force-with-lease`
5. Report what was fixed and what needs manual attention.

**Done when:** Summary is printed and all interactive actions are resolved (or skipped in quiet mode).
