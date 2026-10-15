# torture-test baseline (no skill)

One run per case: a fresh agent got the fixture and the request with no skill
loaded, and a fresh strict judge scored it against `rubric.md`.

| Case | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | Total | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 cursor round trip | 2 | 1 | 1 | 0 | 0 | 2 | 0 | 1 | 2 | 9/18 | FAIL |
| 2 is_weekend | 2 | 0 | 1 | 0 | 0 | 0 | 2 | 1 | 2 | 8/18 | FAIL |
| 3 slugify | 2 | 1 | 1 | 0 | 0 | 1 | 2 | 1 | 2 | 10/18 | FAIL |
| 4 wallet | 1 | 1 | 1 | 0 | 0 | 1 | 0 | 1 | 2 | 7/18 | FAIL |
| 5 payouts | 1 | 1 | 1 | 0 | 0 | 1 | 0 | 1 | 2 | 7/18 | FAIL |
| 6 branch | 2 | 1 | 1 | 2 | 2 | 1 | 2 | 0 | 2 | 13/18 | FAIL |

What the model gets right alone: it finds most seeded bugs (dimension 1) and
respects the no-commit and no-fix constraints (dimension 9).

Where it falls short, and what the skill must close:

- It writes tests that pass on the buggy code, asserting today's wrong value
  so the suite stays green (cases 1, 4, 5: dimension 4 at 0).
- Every probe becomes a test, including probes that pass, even on a
  one-line function (cases 2 and 3: dimension 5 at 0).
- It replaces properties with fixed examples, or writes no property where the
  library is present (cases 1, 4, 5: dimension 7 at 0).
- It names no beneficiary per attack and mixes findings, tests and passed
  probes in one report (dimensions 3 and 8 at 1 or 0).
- On a branch with a red module, it reports the red test but attacks the
  module anyway and keeps no list of what went untested (case 6).

## With the skill

Three runs per case, each scored by a fresh strict judge; one run per case
also got a second judge. Cases 3 and 6 ran on the final skill text. Cases 1,
2, 4 and 5 ran on the text before its last sentence (on invariants without a
property library), which leaves cases 1 and 5 untouched, since both declare
StreamData. The skill was revised after these cases were read, so none of
them is a clean held-out case. Baseline case 4 was scored before the rubric
named the retry double debit.

| Case | Baseline | Run a | Run b | Run c | Passes |
|---|---|---|---|---|---|
| 1 cursor round trip | 9 | 17 | 18 | 18 | 3/3 |
| 2 is_weekend | 8 | 18 | 18 | 17 | 3/3 |
| 3 slugify | 10 | 18 | 17 | 16 (FAIL) | 2/3 |
| 4 wallet | 7 | 17 | 18 | 18 | 3/3 |
| 5 payouts | 7 | 18 | 17 | 18 | 3/3 |
| 6 branch | 13 | 18 | 18 | 18 | 3/3 |

The one failure scored 0 on dimension 7. With no property library declared,
the run checked idempotence on a few chosen inputs and listed it as a passed
attack, not under axes not covered. The last sentence of the skill targets
exactly this, and it has not closed the gap: two runs of three pass. The two judges agreed on the verdict on
every double-judged run and never differed by more than one point.
