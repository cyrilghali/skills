---
name: rewrite-commits
description: Collapse a draft PR's noisy iteration commits into 1-3 atomic commits before review.
disable-model-invocation: true
metadata:
  category: ship
---

# Rewriting a draft PR's commits

Iteration with an LLM, and your own changing decisions, leaves a branch with 5-15 small commits such as "rename X", "tighten threshold", "drop Y", "trim tests", "restore Y". Collapse that noise into 1-3 atomic commits, one per logical unit of change, so reviewers see the result of the thinking and not the thinking itself.

## Run it only on a draft that nobody has reviewed

Run it after heavy back-and-forth on a draft PR, before flipping it ready for review, or when the draft's `git log` reads like a running commentary instead of a feature.

Leave the branch alone in these cases:

- The PR has reviews, because a force-push loses the review-thread anchors and surprises reviewers.
- The branch is `main`, `staging`, `master` or any shared protected branch.
- The PR is open as non-draft and reviewers have been able to see it for a while.
- The user asked to keep the commit-by-commit history.

## Run the pre-checks first, and refuse if any fails

1. **Check the branch is ahead of its base.** `git rev-list --count <pr-base>..HEAD` returns 2 or more.
2. **Check the branch is the user's own.** The current branch is not `main`, `staging` or `master`.
3. **Check the working tree is clean.** `git status --porcelain` prints nothing.
4. **Check the PR is a draft, or has no reviews.** `gh pr view --json isDraft,reviews` shows `isDraft: true` or `reviews: []`. A non-draft PR with no reviews gets a warning, then goes ahead.
5. **Find the PR base.** If `gh stack view --json` succeeds, the branch is part of a stack: follow [STACKS.md](STACKS.md) for the whole stack instead of the steps below. Otherwise the base is `<remote>/<base-ref>`, with the ref from `gh pr view --json baseRefName`.

## List the noise

```bash
git log --oneline <pr-base>..HEAD
```

Show the user how many commits are about to be collapsed.

## Group the commits into atomic units and get approval

Most PRs collapse into 1-3 commits along these lines:

- one commit for plumbing and data flow (migrations, schema changes, threading values through job args);
- one commit for the behavior, the user-facing or system-facing effect (alerts, UI, an API change);
- one commit for tests, only when they are pure test additions to existing code.

Walk the diff with `git diff <pr-base>...HEAD --stat` and propose the commit structure to the user, with subjects. Get approval before executing, even in auto mode, because the structure is a judgment call only the user can make.

## Rewrite with reset and selective staging

```bash
# 1. All current changes become staged against the PR base
git reset --soft <pr-base>

# 2. Unstage everything so we can re-stage selectively
git restore --staged .
```

For each planned commit:

```bash
# 3a. Stage the files belonging to this commit
git add <file1> <file2> ...

# 3b. For partial-file commits (file split across two commits):
#     Edit the file to its commit-N state via Edit tool,
#     stage it, commit, then Edit forward to commit-(N+1) state for the next round.
#     Never use `git add -p` (interactive flag, blocked).

# 3c. Commit
git commit -m "<subject>" -m "<body>"
```

Use `git reset --soft`, selective `git add` and Edit-based file shaping for partial-file commits. Never use `git rebase -i` or `git add -p`, because interactive flags are blocked.

## Force-push with a lease

```bash
git push --force-with-lease
```

Use `--force-with-lease`, never `--force`, so a concurrent push from elsewhere is not silently overwritten. The PR keeps its number, description and labels; only the commit list changes.

## Report the new log

Show the user the new `git log --oneline <pr-base>..HEAD` so they can confirm the result. Record the run with `skill-record rewrite-commits commits_before=B commits_after=A`, once, only when the force-push went through; a dry run or an aborted run records nothing. B is the count from "List the noise", A the count in this new log.

## Keep these rules throughout

- Never rewrite history on a shared branch (`main`, `staging`, `master`); the pre-checks enforce this.
- Always confirm the commit structure with the user before force-pushing, even in auto mode.
- Keep the PR description intact; only the commits change. If the PR description references commit SHAs or counts, flag that to the user before force-pushing.
