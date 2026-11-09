---
name: stacked-prs
description: Plans, sizes, creates and maintains stacked pull requests with the `gh stack` GitHub CLI extension. It turns a feature or an oversized PR into a layer plan with estimated sizes, builds and submits the stack, restacks it after a lower layer changes, appends a PR to an existing stack, and keeps the whole project visible through numbered titles, a stack summary and a tracker. Use when the user says "stack", "stacked PR", "stacked diffs", "gh stack", "split this PR", "chain these PRs", "restack", "rebase the stack", "add a PR to the stack", asks "how big should this PR be", or says "plan the PRs" or "open a PR for" a feature, and before coding any change with more than one purpose. A single-purpose change stays one PR.
metadata:
  category: ship
---

# Stacked pull requests

A stack is a chain of pull requests. Each one targets the branch of the one below it. Build every stack with `gh stack`, because it records the order that GitHub and stack-aware tools read, and it rebases every layer above a change in one command. A chain built by hand with `gh pr create --base` has neither. Read `gh stack <command> --help` for the flags and `REFERENCE.md` for the gotchas `--help` leaves out.

## Cut the work into layers of one purpose

A layer is one pull request with one purpose. It leaves the trunk green, and a reviewer can review, merge and revert it on its own. Make its commits as small as you like, because a layer is not a commit.

| Rule | Target |
|---|---|
| One purpose | One decision the reviewer can make. The title completes "after this merges, ___ is true" with something that matters on its own. If judging layer N means opening layer N+1, the purpose was split: merge the two layers. |
| Size | About 100 to 400 changed lines, 500 at most. Leave generated files and lockfiles out of the count and name them in the plan. |
| Order | Dependency order: schema and migration, then domain logic, then API, then wiring and feature flag, then cleanup. |
| Open at once | At most five layers in review. This limits review load and rebase churn, not project size. Turn a bigger project into several stacks in sequence, one milestone slice each, and open the next stack as the previous one lands. |
| Tests | Each layer carries the tests for the behaviour it adds. |

A small layer is allowed when its purpose stands alone. Count decisions, not files: one decision is one layer, however many files it touches.

## Pick where to start

| The user has | Start at |
|---|---|
| A feature not yet written, or a question about PR size | Plan the layers |
| An oversized PR | Plan the layers, then split the PR |
| Planned layers ready to publish | Create the stack |
| A lower layer that changed, merged or was closed | Restack |
| A new PR that depends on a layer already in a stack | Append |

## Plan the layers

Read the change before you touch a branch: the spec, or the PR's `git diff --stat <merge-base> <head>`. When the change is already one layer (one purpose, 500 lines or fewer), answer with a one-sentence verdict that gives its size and purpose, with no table and no stack. Say what every verdict rests on: the measured diff, or the user's own numbers plus the command that confirms them. For anything larger, write the layer plan:

| # | Title | After this merges | Est. lines | Depends on | Reverts alone |
|---|---|---|---|---|---|
| 1/4 | Add invoice exports table | exports can be stored | ~120 | trunk | yes |

Estimate each layer from the files it touches, and number every layer. Ship purposes with no dependency between them as separate PRs off the trunk, not as a stack. When the plan has more than five layers, cut it into milestone slices, mark the slice that ships first, and number titles within that slice. Treat a follow-up that must wait for a deploy as a layer too: open it now as a draft and put the wait in its description.

The plan is done when every layer has a purpose that passes the "after this merges" test, an estimate of 500 lines or fewer, a dependency and a yes under "Reverts alone". Name any layer that breaks a rule in the plan, with the reason.

## Split an existing PR

Change only the review boundaries; keep the design as it is. Build the layers in an isolated worktree from the PR's merge base, one branch per layer. Leave the original PR and its branch alone until the stack replaces it. Then run:

```sh
scripts/layer-sizes.sh <merge-base> <layer-1> ... <layer-N> [-- <pathspec excludes>]
git diff --quiet <original-head> <layer-N>
git diff --check <merge-base> <layer-N>
```

The split is done when the tree comparison passes and `layer-sizes.sh` exits 0, or the report names the layer that goes over the limit and why. Follow `REFERENCE.md` "Validate a split last" for testing.

## Create the stack

- For new branches, run `gh stack init` on the trunk. Commit layer 1, then for each next layer run `gh stack add <branch>` and commit.
- For existing branches, run `gh stack init <layer-1> ... <layer-N>`, which adopts them in that order.
- Check the sizes with `scripts/layer-sizes.sh <trunk> <layer-1> ... <layer-N>` before anything is published, so the written layers match the plan.
- Publish with `gh stack submit`, as drafts when the repository expects drafts. Publish only when the user has authorized it, and first run any review gate the repository requires before a PR opens.
- Make the stack visible:
  - Title each PR `[n/N] <imperative summary>`.
  - Put the stack summary in layer 1's description: the plan table with PR links. In every other layer's description, say its own purpose and which layer it builds on.
  - When the project has a tracker (an issue-tracker project or milestone, a GitHub milestone), list every layer there with its PR link.

The stack is created when `gh stack view` lists every layer in plan order, every title carries its `[n/N]`, and the tracker, if any, lists every PR.

## Restack after a lower layer changes

Let one session own a stack's branches; only that session rebases or pushes them. When a layer merged or was closed, follow `REFERENCE.md` "When a layer lands or closes" first. After a lower layer is amended, run `gh stack rebase --upstack` (or `git rebase --update-refs` outside `gh stack`), then `gh stack push`, which pushes every layer in one push. Set up the checkout and conflict handling as `REFERENCE.md` "Before a restack" says. On a PR that is not a draft, push the layers together and change a base only in the order `REFERENCE.md` "On a ready PR" gives, so GitHub never requests code owners for files the PR does not change. Always rebase; never merge the trunk into a layer. Before each push, read `git diff --stat <parent>..<layer>` for every layer. A deletion in a file that the layer only extends means the base's newer work was lost; rebuild that layer as `REFERENCE.md` "Rebuild a layer" describes.

The restack is done when `git merge-base --is-ancestor <parent> <layer>` holds for every link, no stat shows a deletion the layer did not intend, and each PR's diff on GitHub lists only its own layer's files.

## Append a PR to an existing stack

When the stack is tracked locally, check out the top layer and run `gh stack add <branch>`. From a worktree without local tracking, follow `REFERENCE.md` "Append from outside the stack". Then update N in the titles, the summary and the tracker, if any.

The append is done when `gh pr view <n> --json baseRefName` shows each PR's base is the layer below it.

## Shape the plan like this example

"How big should the invoice-export PR be?" gets this plan, not one 1,400-line PR:

| # | Title | After this merges | Est. lines |
|---|---|---|---|
| 1/4 | Add invoice exports table | exports can be stored | ~120 |
| 2/4 | Build CSV export of an invoice batch | a batch renders to CSV, tested | ~350 |
| 3/4 | Expose POST /exports behind a flag | clients can request an export, flag off | ~280 |
| 4/4 | Email the export link and enable the flag | users receive their export | ~200 |

## End with a report for the user

End with the plan or stack table, the PR links if the stack was published, the result of `layer-sizes.sh` or the estimates, and what was verified. Merge a stack only when the user asks for it.
