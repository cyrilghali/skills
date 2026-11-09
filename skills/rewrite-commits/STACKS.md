# Rewriting a stack

Rewrite a branch managed by `gh stack` together with the whole stack, bottom-up, in one pass. Rewriting one branch alone breaks the stack: `gh stack rebase` then replays that branch's old commits into the branch above and stops on conflicts.

Let `scripts/stack.sh` do the mechanical half. Run it from any branch of the stack.

## Snapshot every branch

```bash
scripts/stack.sh snapshot
```

The script refuses a dirty tree, a stack that needs `gh stack rebase` first, and a branch checked out in another worktree. Then it backs up every open branch under `refs/rewrite-backup/`, and prints each branch's base (its parent branch, or the merge-base with the trunk for the bottom one) with its commit count. Done when every branch is listed.

## Plan every branch, then dispatch

For each branch, read its own diff (`git diff <base>...<branch> --stat`, base from the snapshot) and propose 1-3 commits, as in the single-branch process.

Dispatch a change made on one branch that completes another branch's unit: move it to the branch that owns it. The usual case is a fix on an upper branch for code a lower branch introduced. List each dispatched change as `<path>: <from branch> -> <to branch>`.

Get approval for the whole plan, commits and dispatches together. Done when every change in the stack has exactly one owning commit.

## Rewrite bottom-up

For each branch, bottom first:

```bash
git switch <branch>                  # the bottom branch; replay switches to the others itself
scripts/stack.sh replay <branch>     # every branch except the bottom one
git reset --soft <base>              # the parent branch, or the snapshot's merge-base for the bottom
git restore --staged .
```

Then bring in the changes dispatched to this branch. Edit each file to the state this branch should hold; the upper version is `git show refs/rewrite-backup/<from>:<path>`. Take it whole with `git checkout refs/rewrite-backup/<from> -- <path>` only when every upper change to that file moves down. Stage and commit per the plan.

`replay` carries every dispatched change up through the branches in between, so each upper branch's own diff drops it without extra work. If a replay stops on a conflict in a dispatched hunk, resolve the file to `git show refs/rewrite-backup/<branch>:<path>`, adding the dispatched change if that version lacks it, so both sides survive and the change appears once. Then `git add` it and `git rebase --continue`.

Done when the top branch is committed.

## Check and push

```bash
scripts/stack.sh check
gh stack push
```

`check` fails unless the top branch's tree is identical to its snapshot, because the rewrite moved changes between commits and never changed the end result. It then refreshes the stack's metadata and prints each branch's new log. `gh stack push` force-pushes every branch with `--force-with-lease`, atomically.

If anything goes wrong before the push, run `scripts/stack.sh restore`: it puts every branch back, including in the middle of a stopped replay, and discards uncommitted work in the current checkout.

Done when `check` prints OK and the push succeeded.
