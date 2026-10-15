---
name: rewrite-commits
description: Squashes and regroups the commits on a pull request branch into one to three atomic commits, each a logical unit, proves the final code is unchanged, and force-pushes with a lease; rewrites a whole gh stack bottom-up and moves a fix to the branch that owns it. Use when the user asks to squash, clean up, collapse, tidy, rewrite or regroup the commits of a branch or draft PR (wip, fixup or iteration noise), to make its history reviewable commit by commit, or to do that across a stack of PRs. Not for writing the PR description (intent-pr), splitting one branch into several PRs, rebasing onto the latest base, amending or rewording one commit, or reviewing someone else's commits.
metadata:
  category: ship
---

# Rewrite commits

Work with an agent leaves a branch with commits like "rename X", "drop Y", "restore Y". Reviewers need the result, not the path to it. This skill regroups the branch into one to three commits, each a logical unit, while the code at the tip stays byte for byte the same.

Every command here runs without an editor, so an agent can drive it. Interactive commands (`git rebase -i`, `git add -p`) wait on a person and are replaced below by a soft reset, selective staging and file edits.

## 1. Decide whether to rewrite

Gather the facts first:

```bash
git status --porcelain
git branch --show-current
gh pr view --json isDraft,reviews,baseRefName,body
gh stack view --json          # succeeds only on a branch of a gh stack
```

| Finding | Action |
|---|---|
| Uncommitted changes | Stop. Ask the user to commit or stash them first. |
| The branch is the default branch or another shared branch | Stop. Other people build on it. |
| One commit ahead of the base, or none | Stop. Say there is nothing to regroup and run nothing. |
| The PR has any review, or is out of draft and others have read it | Stop. A force-push detaches reviewers' inline comments from their lines and makes them re-read everything. Offer a squash merge at merge time instead, or a rewrite once the review is closed. Go on only if the user insists after hearing this. |
| `gh stack view --json` succeeds | Follow [STACKS.md](STACKS.md) for the whole stack instead of steps 2 to 5. |

Done when you have said go or stop, with the row that decided it.

## 2. Find the fork point

The base is the PR's `baseRefName`, which can differ from the default branch; regroup only the commits after the fork point with that base.

```bash
git fetch origin <baseRefName>
FORK=$(git merge-base origin/<baseRefName> HEAD)
git log --format='%h %an %s' "$FORK"..HEAD
git diff --stat "$FORK" HEAD
```

Reset to the fork point, not to the base branch's tip. If the base moved since the branch started, a soft reset to its tip commits a silent revert of everything merged into it since. Rebasing onto the newer base is a separate job that changes the code under review; leave it out unless the user asks.

Done when the commit list holds only the user's own commits.

## 3. Plan the commits

Read the diff and group it into one to three commits per branch, each with a subject line. Most branches split into plumbing (schema, migrations, data flow), then behavior (what users or callers see); tests get their own commit only when they cover existing code. Every changed file, and every hunk of a file split across commits, belongs to exactly one commit. Name each split file and which part goes where.

Show the plan to the user with the side effects from step 5, then wait for approval. An approval the user already gave in the request counts; say you are using it.

Done when the user has approved a plan in which every change has one owning commit.

## 4. Rewrite

```bash
git branch -f rewrite-backup/<branch> HEAD     # the old tip, for the proof and for undo
git reset --soft "$FORK"
git restore --staged .
```

For each planned commit, in order:

```bash
git add <files of this commit>
git commit -m "<subject>" -m "<body>"
```

For a file split across two commits: edit it down to the state the first commit should hold, stage it and commit. Then bring back the final version with `git checkout rewrite-backup/<branch> -- <path>` and commit it with the second unit.

Prove the code did not change:

```bash
git diff --stat rewrite-backup/<branch> HEAD   # must print nothing
git status --porcelain                         # must print nothing
```

Done when both commands print nothing. If either prints anything, fix the commits or undo with `git reset --hard rewrite-backup/<branch>`, and do not push.

## 5. Push and report

Before the push, tell the user what changes for others:

- Every commit hash on the branch changes. Quote any hash or commit count in the PR body or comments; it goes stale. Offer to fix the body with `gh pr edit --body-file`.
- Anyone with the branch checked out has to reset to the new tip.

```bash
git push --force-with-lease origin <branch>
git log --oneline "$FORK"..HEAD
```

The lease refuses the push if someone else pushed to the branch since your last fetch.

Done when the push succeeded and the user has seen the new log. Delete `rewrite-backup/<branch>` once they confirm the result.
