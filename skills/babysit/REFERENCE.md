# Babysit reference

## Run these commands

```sh
scripts/pr-state.sh 123
gh api repos/OWNER/REPO/pulls/123/comments --paginate
gh pr checks 123 --watch --fail-fast
gh run view RUN_ID --log-failed
git log -S '<symbol>' <base> -- <file>
git log --merges --ancestry-path <sha>..<base> --first-parent | tail -1
```

The last two commands map a symbol to the PR that merged it: the first finds the commit that added it, the second finds the merge that brought that commit into base. Name a PR in a report only from that output, never from a commit subject.

The state script needs `gh`, `jq` and an authenticated GitHub CLI. It reports facts only and changes nothing on GitHub or in the checkout.

## Hold to these review rules

- Inspect the current head SHA before accepting a comment, because a later commit may already fix it.
- Count a finding as valid only when its claimed path is reachable in production and the proposed behaviour matches the product decision.
- Read the CI logs before any retry or source change. Retry a flaky check once, with clear evidence that the cause is transient or infrastructure. Treat a second failure of the same check as real: report the flake evidence and move to diagnosis.
- When you measure a regression (query count, latency, size), run it on the exact SHA that failed, and first reproduce the known failing number there. A run that misses that number shows a setup problem, such as a worktree tip that already holds the fix, and counts as no evidence either way: never report it as "theory unconfirmed".
- For a check that is not a GitHub Actions run, follow the check's link to the failing command or service before trying a fix.
- When a failure has nothing to do with this PR's diff, look for someone else's fix before diagnosing, proposing a fix or saying the base is "still red". First confirm the base is red from its own CI on the PR's base SHA. Then fetch the base again and search just-merged and open PRs that touch the failing test. If the fix is already on base, report that a rebase onto base is needed instead of chasing it here. Babysit never rebases.
- For a stack, repair from base to tip, because a child PR can look broken only because its base is stale.
- Before a push, check that the worktree holds no unrelated edits and that its upstream is the PR head branch.
- Push without `--no-verify`, always.

## Report in this shape

Give the PR link; head and base; fixes pushed; Cubic findings resolved and deferred; local checks; GitHub checks; merge and conflict state; and one concrete next action when blocked.

## Sort each bot thread before acting on it

Cubic and similar review bots catch real bugs and also file non-issues and nitpicks. Put every thread in one of three classes before touching code, and change no code only to quiet a bot.

- `fix`: a plausible correctness, security, privacy, data-loss, auth, billing, migration, idempotency, race or shipped-behaviour issue. Fix it in the lowest PR that owns the code and answer the thread with the commit SHA (SKILL.md, "Judge each finding with evidence", step 4).
- `dismiss`: the thread matches one of the low-risk patterns below, and the current code shows the concern needs no change. Answer the thread with the concrete reason (same step).
- `ask`: the finding is novel, high-severity, about security, privacy or data, or ambiguous. Ask the user instead of guessing.

Skip none of these on your own: security, privacy, auth, billing, data-retention or permission-boundary findings; high-severity findings; migration, schema, idempotency, concurrency or cross-system behaviour findings. Treat a human's past dismissal of a security or data-flow comment as that owner's judgment call, not a team-wide skip rule.

Dismiss on one of these low-risk patterns. Add a pattern here when one recurs, with its skip and do-not-skip conditions and an example signal:

- **Upstack usage the bot can't see.** A symbol flagged unused is used by a later PR in the same stack (`gh stack log` or the upper diffs confirm it). Don't skip when the PR isn't in a stack or the symbol is public API.
- **Temporary duplication during a parallel implementation.** A small intentional duplication keeps a new path parallel to an old one being deleted. Don't skip when the duplicate touches security, billing or data access.
- **Existing invariant already covers the warning.** A shared module, a type or a database constraint visible in the diff already guarantees the concern. Don't skip when the invariant is assumed but not enforced, or crosses an async or replica boundary where values can diverge.
- **Owner-declared follow-up.** The PR author explicitly defers it as a known follow-up that doesn't worsen current behaviour. Don't skip when acting without owner input, or when the issue is medium or high severity.
- **Self-withdrawn or explicit false positive.** The bot's own later comment says the finding is withdrawn or compliant, and you can verify the rule locally.
- **Stale finding already fixed later in the same PR.** The bot ran before a later hardening commit added the exact guard it asks for. Confirm the guard runs before the side effect it protects, for the right principal.
- **A claimed contract-test drift is cheap to verify.** Run the test first instead of reasoning about it. A red run confirms the claim; a green run is the concrete disproof for the dismissal reply.
- **Widening a deliberately narrow error condition would mask the real error.** When the narrowness (a specific error code gating a fallback) encodes a real distinction, keep it even though the bot asked. Don't skip when the narrow condition misses a case in the same category or the retry isn't idempotent.

From the third Cubic pass on the same PR onward, lean toward dismissing documented patterns, but keep escalating anything that touches security, auth, billing, data or migrations. After a run, offer any new team-useful dismissal pattern as a candidate entry here, in its own PR, never left only in private memory.

## Land a verified stack only on an explicit ask

Run this section only when the user asks to land, ship or merge. Reaching merge-ready under `drive` never starts it.

1. **Verify each PR on its own.** Green CI is not a verdict, and an approving bot review is not a verdict. Run `/code-review --high` (or `--ultra` for a deep pass) against each PR's diff, or drive the real surface with the **run** skill, **agent-browser** or **playwright-cli** against parent versus head. Give each PR `PASS`, `PASS+NOTES` or `FAIL`.
2. **Land only the unbroken verified run from the bottom.** Walk up from the lowest unmerged PR and stop at the first one without a passing verdict. Report that ceiling PR and what breaks the chain.
3. **Check that each verdict still describes its patch before landing.** A rebase or retarget rewrites SHAs and can invalidate a verdict without touching a check. Compare the verdict's base-to-head `git patch-id` with the current one. If they differ only in tests, docs or lint config, keep the code verdict, but re-run mergeability and CI at the current head regardless. Any other difference needs a fresh verdict.
4. **Prepare and land one PR at a time.** Rebase the lowest verified branch onto current trunk, push, retarget with `gh pr edit <pr> --base <trunk>`, repeat step 3, then `gh pr merge <pr> --squash` (never `--merge`; always rebase, never merge, per standing convention). Wait for it to merge before touching the next.
   - **Resolve conflicts during that rebase this way.** Regenerate lockfiles with the package manager instead of hand-editing them. Keep both sides when safe; otherwise keep the side that compiles and preserves public behaviour. Leave no conflict marker in any file. Run compile, lint and the focused tests before continuing, then list each resolution in the report. During a rebase, `ours` and `theirs` name the opposite sides from a merge: `ours` is the branch being rebased onto, `theirs` is the commit being replayed. In a worktree, confirm the rebase is in progress with `test -d "$(git rev-parse --git-path rebase-merge)"`.
5. **Recompute after every merge.** Fetch trunk, confirm the merged SHA landed, drop that PR from the list, re-run `gh stack log`, and repeat from step 3 for the new bottom PR.
6. **Stop at the ceiling.** Report what landed, which PR is the next unverified one, and what verifying it would take.
