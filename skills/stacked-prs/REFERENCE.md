# Stacked PRs reference

## Validate a split last

- A mechanical split whose final tree matches the original PR head can use the original PR's passing CI as evidence for the combined behaviour. CI checks each new layer on its own. Don't build or run the full suite locally for every layer by default.
- Run a focused local test before publishing when the split changes behaviour, when a middle layer has a real compile or contract risk, or when CI cannot cover that risk.
- Report bugs inherited from the original PR separately. Fixing them is a new request, not part of a mechanical split.
- Run the repository's formatter right before pushing and stage what it changes.
- Record review-gate quota or service failures as they happened. A review that was attempted is not a review that completed.
- Keep the original PR open until the replacement stack is linked and the user authorizes closing it.

## Rebuild a layer

A layer's content is a delta on a base that keeps moving. Copying a saved snapshot of its files brings back an old moment and wipes out what the base gained since. CI can stay green through that loss.

```sh
git checkout -B <layer> <new-parent>
git cherry-pick <old-layer-commits>
git diff --stat <new-parent>..<layer>   # read every line with deletions
```

If an old layer commit is itself damaged, take the parent's version of each file and re-apply the layer's edits as edits.

**Squashing a layer:** pin the base first with `MB=$(git merge-base origin/<parent> HEAD)`, then `git reset --soft "$MB"`. If the parent moved since the last rebase, rebase onto it before squashing. To prove it worked, compare diffs against the parent, not tree hashes: `git diff <old-parent> <old-head>` must equal `git diff <new-parent> <new-head>`.

## One owner per stack

When several sessions or people work on one stack, exactly one of them moves and pushes its branches. The others commit on a scratch branch and hand over SHAs. Every push leases against the SHA read just before it:

```sh
git push --force-with-lease=<branch>:<sha-read-before> origin <branch>
```

If a lease is rejected, diff the remote tip against the expected SHA before doing anything else, because someone else has restacked.

## Append from outside the stack

A worktree without gh-stack's local tracking can still add a PR through the remote-only path:

1. Push the branch and run `gh pr create --draft --base <parent-branch>`.
2. Check membership: `gh stack link` with the PRs you believe are members prints "already in stack" for each one and adds nothing.
3. Run `gh stack link <stack-number> <every member PR, bottom to top> <new PR>`. The stack number is shown in GitHub's stack UI. Listing every member always works; a partial list without the stack number is refused ("would remove #..."), and a PR from another stack fails with "PRs belong to multiple stacks".
4. Print every base: `gh pr view <n> --json baseRefName`.

Gotchas:
- `link` rewrites bases PR by PR *before* it validates the chain. A wrong list can move a base and then fail. Restore it with `gh pr edit <n> --base <branch>`.
- A warning that it could not set the bottom PR's base to the trunk (HTTP 422) is a rejected no-op. The bases stay where they were.

## Before a restack

| Check | Command | Why |
|---|---|---|
| Full history | `git rev-parse --is-shallow-repository` prints `false`; if not, `git fetch --unshallow origin` once | A shallow clone hides the merge base, so the rebase replays the whole history instead of the layer's own commits. |
| Every branch moves together | `git config rebase.updateRefs true`, or `git rebase --update-refs` | Branches stacked on the rebased one follow it instead of staying on the old commits. |
| Structural conflicts resolve themselves | [mergiraf](https://mergiraf.org/) as git's merge driver (see `INSTALL.md`) | Edits to different parts of the same function or module that git reports as line clashes merge cleanly; edits to the same logic still stop for a person. |
| No stale replayed resolution | `git rerere forget <path>` when a resolved file comes back with markers | A resolution recorded during an aborted rebase replays silently into the next one. |

A layer that carries older copies of commits its base already has in a newer form conflicts on every copy. Resolve by keeping the base's version, then read `git diff --stat <parent>..<layer>`: what remains is the layer's own work.

## When a layer lands or closes

A layer above a merged or closed one still carries that layer's commits. Until it is rebased, its PR shows those commits again (an unwanted diff), and a closed layer's code would ship inside the next one.

**Order.** Work bottom to top: rebase the lowest affected layer first, then each layer onto its parent's new tip. On a draft PR, change the base only after its rebased branch is pushed; changing it first puts the dropped commits back in the diff. On a ready PR, follow "On a ready PR" below. When a merged layer's branch is deleted, GitHub moves its children's base to the trunk by itself, so rebase right after a merge.

**A layer merged.** A squash or rebase merge gives the trunk new commits, so the next layer's copies of the old ones no longer match. With local tracking, `gh stack sync` fetches, rebases each layer onto its updated parent and pushes with a lease. Without it:

```sh
git rebase --onto origin/<trunk> <merged-layer-old-tip> <next-layer>
```

Then rebase each layer above onto the new tip of the one below.

**A layer closed without merging.** Cut its commits out and take it out of the stack:

1. `git rebase --onto <closed-layer-parent> <closed-layer-tip> <next-layer>`, then rebase each layer above onto the one below.
2. Push every rebased branch with a lease, in one push.
3. `gh pr edit <next-PR> --base <closed-layer-parent-branch>`. On a ready PR, steps 2 and 3 run in the order "On a ready PR" picks.
4. `gh stack link` never removes a PR, so rebuild the stack object: `gh stack unstack <stack-number>`, then `gh stack link <open PRs, bottom to top>`. With local tracking, `gh stack modify` drops the branch (interactive), and then `gh stack submit` updates the PRs and the stack.
5. Renumber the `[n/N]` titles, the stack summary and the tracker, if any.

**Proof.** For every rebased layer, `git range-diff <old-parent>..<old-layer> <new-parent>..<layer>` shows each commit unchanged (`=`), and `git diff --stat <new-parent>..<layer>` lists only that layer's own files.

## On a ready PR

On a PR that is not a draft, GitHub requests review from every code owner whose files newly appear in the PR's diff, and it recomputes that diff after each push and each base change. A restack that moves the head and the base in two steps leaves the PR diffed against the wrong base in between, and that diff can reach far beyond the layer.

- Push all layers at once, with `gh stack push` or `git push --atomic --force-with-lease=<layer>:<sha> ... origin <layer-1> ... <layer-N>`. `gh stack push` is one push but not atomic: if one layer's lease is rejected, the others still land, so check that every layer moved. GitHub computes each PR's diff only after the whole push lands: in a test, a child pushed in the same atomic push as its parent listed only its own file, while the same child pushed first also listed its parent's and the trunk's new files. A child pushed alone is diffed against its parent's old tip, and a parent pushed alone leaves its child's old head diffed against the parent's new tip.
- A base change cannot join a push, so it runs before or after it. Take the order whose in-between diff adds no file owned in `CODEOWNERS` that the PR does not already change:

  | Order | In-between diff to check |
  |---|---|
  | Retarget first, old head still in place | `git diff --name-only origin/<new-base>...origin/<layer>` |
  | Push first, old base still in place | `git diff --name-only origin/<old-base>...<rebased-layer>` |

- If both orders add owned files, stop and ask the PR's author to convert it to draft for the surgery. Marking it ready again is the author's call, and GitHub then requests only the owners of the final diff.
- Where the codeowner-ping PreToolUse gate is installed, it runs this check before a forced `git push` (the pushed PR and the PRs stacked on it), before `gh pr edit --base` on a ready PR, and before `gh stack submit` (which pushes one layer at a time, bottom up, and retargets a base that changed), and blocks the unsafe step. On a ready stack whose PR bases already match the stack, run `gh stack push` before submit; when a base must change, follow the order table above first. `gh stack push` and `sync` move every active branch in one push and never retarget a PR, so the gate leaves them alone; `gh stack link` also retargets PRs and is not checked. `OWNER_PING_OK=1` lets a deliberate case through.

## Stack summary block

Layer 1's description carries this summary, updated whenever a layer is added or lands:

```markdown
## Stack
| # | PR | After this merges | Status |
|---|---|---|---|
| 1/3 | <link> | exports can be stored | this PR |
| 2/3 | <link> | a batch renders to CSV | draft |
| 3/3 | <link> | clients can request an export, flag off | draft |
Next stack (milestone 2): email delivery, flag rollout.
```
