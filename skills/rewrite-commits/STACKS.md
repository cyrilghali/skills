# Rewriting a stack

A branch managed by `gh stack` is rewritten with the whole stack, bottom branch first, in one pass. Rewriting one branch alone breaks the stack: the next `gh stack rebase` replays that branch's old commits into the branch above and stops on conflicts.

`scripts/stack.sh` does the mechanical part; the commit grouping stays with you. Run it from any branch of the stack. It needs `gh stack` and `jq` (see INSTALL.md).

## 1. Snapshot

```bash
scripts/stack.sh snapshot
```

It refuses a dirty tree, a stack that needs `gh stack rebase` first, and a branch checked out in another worktree. Then it backs up every open branch under `refs/rewrite-backup/` and prints each branch's base with its commit count. The base is the parent branch, or the fork point with the trunk for the bottom branch.

Done when every open branch is listed.

## 2. Plan every branch, then dispatch

For each branch, read its own diff (`git diff <base>...<branch> --stat`, base from the snapshot) and plan one to three commits as in SKILL.md step 3.

A change on one branch that completes another branch's unit is dispatched: it moves to the branch that owns it. The usual case is a fix on an upper branch for code a lower branch introduced. Dispatch by hunk, not by file: when the upper branch's version of a file also holds changes that stay up, only the fix moves down. List each dispatch as `<path>: <from branch> -> <to branch>`, naming the hunk when the file is split.

Show the whole plan, commits and dispatches together, with the side effects from SKILL.md step 5, and wait for approval.

Done when every change in the stack has exactly one owning commit.

## 3. Rewrite bottom-up

For each branch, bottom first:

```bash
git switch <branch>                  # only for the bottom branch; replay switches to the others itself
scripts/stack.sh replay <branch>     # every branch except the bottom one
git reset --soft <base>              # the parent branch, or the snapshot's fork point for the bottom
git restore --staged .
```

Then bring in the changes dispatched to this branch. Edit each file to the state this branch should hold; the upper version is `git show refs/rewrite-backup/<from>:<path>`. Take the whole file with `git checkout refs/rewrite-backup/<from> -- <path>` only when every upper change to that file moves down. Stage and commit per the plan.

`replay` carries each dispatched change up through the branches above, so their own diffs drop it with no extra work. If a replay stops on a conflict in a dispatched hunk, resolve the file to `git show refs/rewrite-backup/<branch>:<path>`, adding the dispatched change if that version lacks it, so both sides survive and the change appears once. Then:

```bash
git add <path>
GIT_EDITOR=true git rebase --continue
```

Done when the top branch is committed.

## 4. Check and push

```bash
scripts/stack.sh check
gh stack push
```

`check` fails unless the top branch's tree is identical to its snapshot: the rewrite moved changes between commits and branches, never the end result. It then refreshes the stack's metadata and prints each branch's new log. `gh stack push` force-pushes every branch with `--force-with-lease`, atomically, so no branch moves without the others.

If anything goes wrong before the push, `scripts/stack.sh restore` puts every branch back to its snapshot, even in the middle of a stopped replay. It discards uncommitted work in the current checkout.

Done when `check` prints OK and the push succeeded. Show the user each branch's new log.
