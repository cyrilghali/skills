---
name: torture-test
description: Attacks code and its test suite to find what breaks and who would see it - hostile inputs, properties for real invariants, retries and concurrency, resource ceilings, interrupted state - and returns a triage of bugs, killer tests, passed attacks and axes not covered. It adds a test only for a bug it has reported, and never fixes the code or adds a dependency. Use when the user says "torture test this", "try to break X", "harden the tests", "QA pass before release", "adversarial testing", "hunt for inputs that break it", "throw hostile inputs at", "what fails under retries or a crash halfway", or before shipping risky logic (money, retries, parsers, migrations). Not for scoring a suite with mutants (mutation-test), reviewing a diff, writing unit tests for new code, fixing a failing test, or load-testing infrastructure.
metadata:
  category: verify
---

# Torture test

This skill tries to break code before its users do. It keeps only tests that
catch a real bug: a test on healthy code costs upkeep and catches nothing.

## What it does to your code

- **Source code, existing tests and dependency files stay as they are.** The
  pass reports bugs; the fix belongs to whoever reads the report.
- **Attacks run in scratch files or a throwaway test**, and each one that
  passes is deleted. `git status` after the pass shows only killer tests.
- **A killer test is added only for a bug already reported**, and only after
  it is proven to fail on the current code and pass on a fix.
- **Nothing is committed or pushed.**

## 1. Check the baseline

Run the existing suite before any attack. A red suite makes every result
unreadable, so a module with a failing test is **BLOCKED**: report the failing
test as found, attack nothing there, and list its axes under axes not covered.
Done when each module in scope is green or BLOCKED.

## 2. Name the beneficiary of each attack

Before an attack runs, write one line: "<who> sees <which wrong value or
state>". The who is a person in a situation (a reader shown a stale page, the
on-call engineer paged at night), never a bare role like "users". An attack
with no such line does not run. Budget about ten attacks per pass.

## 3. Pick the axes where this code can fail

Choose by reading the code, never all by default. Each axis left out gets
one line saying why the code cannot fail there.

| Axis | What to try |
|---|---|
| Mutation | How well the suite catches changes to the code. Delegate it to the mutation-test skill. |
| Hostile inputs | Empty, huge, Unicode and emoji, NUL, negative, bounds plus or minus one, broken encoding, injection in free-text fields. |
| Invariants | Round trip, retry idempotence, conserved sum, stable sort, monotonicity. Only an invariant the domain really has; a property that restates the implementation proves nothing. See step 4. |
| Concurrency and repetition | Double submit, retry after a timeout (did the first call happen?), events out of order, two workers on one resource. |
| Resources | N x 100 to find the ceiling (measure, never guess), a slow or dead dependency, a full disk, bounded memory. |
| Interrupted state | A crash between two writes, the replay of a half-done job, a partial migration, a cache out of step with its source. |

Each attack checks an expected value or state, and that value comes from
what the code promises (its docs, types, spec or callers), never from what
the tester would prefer; "it did not crash" is an oracle only for a pure
robustness attack. Behavior that a docstring states or an existing test
asserts is the promise itself: when it hurts someone, report it as a
product gap, never as a bug, and add no test for it. Done when each axis is
chosen with a beneficiary and an oracle, or dropped with a reason.

## 4. Write invariant attacks as properties

Use the property library the project declares (StreamData, Hypothesis,
fast-check), never a few fixed examples. The generator must reach the inputs
the code branches on; check what it actually produces before trusting a pass.
A property that finds a bug stays in the suite,
generator included, as its killer test. A library the project does not
declare stays unused, in scratch runs too: list each invariant under axes
not covered, never as a passed attack checked on a few chosen inputs, and
give a bug found by hand one killer test on its minimal repro.

## 5. Report, then test

1. Report each bug first: minimal repro, who sees what, severity.
2. Then write its killer test. Prove it fails on the current code on every
   run (force a race with a barrier, never a sleep), then apply a fix in a
   scratch copy or temporarily, prove it passes, and revert.
3. An attack that passes produces one confidence line and no code.

## Scale to a wide branch

One module runs in the session. A wide branch fans out to parallel agents,
one per module or axis, each under this contract: a clean tree
(`git status --porcelain` empty), a green baseline before any attack, every
change reverted and the revert proven, no commit or push. Each agent returns
`PASS` (attacks passed, confidence lines), `ISSUES` (bugs with repro and
beneficiary) or `BLOCKED` (dirty tree or red baseline), never prose alone.
Relaunch an agent that fails once; a second failure is an axis not covered.

## Triage: the deliverable

1. **Bugs found**: minimal repro, who sees what, severity. Product gaps
   follow, each labeled as one, with no test.
2. **Real gaps**: killer tests added, each with its beneficiary line and its
   kill-check result.
3. **Passed attacks**: one line each, naming who it protects, no code added.
4. **Axes not covered**: BLOCKED modules, a missing property library, an agent
   that failed twice. A named gap is never counted as a passed attack.

## Sources

The PASS / ISSUES / BLOCKED contract and the relaunch rule adapt the `swarm` skill of pstack by Lauren Tan (github.com/cursor/plugins/tree/main/pstack, MIT).
