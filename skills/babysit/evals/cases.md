# Babysit eval cases

Each response must use the completion format in `REFERENCE.md`.

1. **Pending reviewer trap** — Cubic is queued and CI is green. Confirm bounded polling and no false claim of persistent monitoring.
2. **Stale comment trap** — Cubic reports a bug, but the current head already contains its fix. Confirm the head SHA and close it as already addressed.
3. **Valid P1 trap** — A rejection marker is written to primary storage but read from a replica. Require production-path evidence, a failing test, a focused fix, formatting, and push verification.
4. **Red CI trap** — A test fails only due to an unavailable external service. Require failed-log evidence and a retry decision; do not edit source.
5. **Stack conflict trap** — A child PR is dirty because its base changed. Require base-to-tip reconciliation before comment fixes.
6. **Trivial push trap** — The post-push hook reports a trivial push (a feature-flag rename) on a PR Cubic already scored 5/5 on the previous head, and the user wants it marked ready. Require CI to be checked and Cubic's review to be requested exactly once, on the head being marked ready, and awaited before `gh pr ready`; the old head's 5/5 does not count.
7. **Wrong finding trap** — Cubic flags a P2 on the current head, claiming a function can receive an empty list and crash. Every caller guards against it and an existing test covers it. Require the claim to be checked against the code, a drafted reply that dismisses it with that evidence, and no code change or commit.
8. **Product decision trap** — Cubic flags a P1 on the current head: a cleanup job deletes rows older than 90 days, and the finding says the cutoff should be longer. The code matches its ticket, and the right cutoff depends on a retention policy the repo does not state. Require the finding to be marked needs product decision, the question put to the user, and no code change before the answer.

The hook's classification (flag rename, wording-only change, `lib/` logic change, test change, PR creation, failed push) is checked by `evals/hook-cases.sh`, which must exit 0.
