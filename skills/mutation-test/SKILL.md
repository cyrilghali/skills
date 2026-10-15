---
name: mutation-test
description: Measures how well a branch's tests catch regressions by mutation testing. It plants one small fault at a time in the code the branch added (a flipped comparison, a dropped filter, a swapped value), reruns the tests, and reports every mutant the tests let survive with the assertion that would kill it. Works in any language with no mutation tool installed. Use when the user says "mutation test this branch", "are the tests strong enough", "test my tests", "mutation score", or before merging risky logic such as queries, money or boundaries; torture-test calls it for its mutation axis. Not for writing tests for new code, coverage numbers, debugging a failing test, installing a mutation tool in CI, or hostile-input and concurrency attacks (torture-test).
metadata:
  category: verify
---

# Mutation-test a branch

A mutant is a small deliberate fault in production code. If a test fails, the mutant is killed and a test guards that line. If every test still passes, the mutant survived: that is a concrete test gap, and the report names the assertion that closes it. The method needs only an editor, the test command and git, so it works in any language.

## Scope

- The target is the non-test files the branch changed, `git diff --name-only $(git merge-base <base> HEAD)..HEAD`, and within them only the lines the branch added or changed (`git diff -U0 <merge-base>..HEAD`). Code that existed before the branch, and uncommitted edits in the tree, are out of scope.
- A diff that changes no behavior has nothing to mutate: say so and stop.
- Several branches get one subagent each, launched in parallel, each in its own worktree or clone. Two agents never share a working tree. For one branch, do the work yourself.

## Measure

1. **Preflight.** Save the starting `git status --porcelain`. Copy each target file to a backup folder outside the repository, and restore only from these copies: git restores the committed version and would discard anything the user had not committed. Done when every target file has a backup.
2. **Baseline.** Run the tests that cover the target in the foreground, with a long timeout. A red suite ends the run here and becomes the report, since a verdict measured against failing tests means nothing. Done when the suite is green and its result is noted.
3. **Design mutants.** Write 8 to 15 mutants for a normal diff, fewer for a small one, riskiest logic first. Pick operators from [OPERATORS.md](OPERATORS.md). Prefer mutants that still compile or parse: a compile error proves nothing about the tests. Done when each mutant has an id, a `file:line` and a before and after.
4. **Run one at a time.** Apply one mutant, run the suite without stopping at the first failure, and record KILLED with every failing test, or SURVIVED. Restore the file from its backup and check that `git status --porcelain` matches the starting status before the next mutant. A cache keyed on file modification time (Python bytecode, incremental builds) can run the previous code after a quick edit, so turn it off for these runs. Done when every mutant has a verdict and the tree matches the start.
5. **Widen once per survivor.** Run the wider suite (the whole project, or the test folder next to the target) with the survivor applied, to tell "survives the branch's tests" from "survives every test". Restore afterwards.
6. **Triage.** Sort survivors into real (it would let a production bug ship) and cosmetic (an equivalent mutant, or a change no caller can observe). When the mutated code looks more correct than the original, the survivor has found a production bug: report it as a finding, and never write a test that pins the questionable behavior.
7. **Report** to the user in the format in [OPERATORS.md](OPERATORS.md#report). Done when the report ends with the final `git status --porcelain`, identical to the start.

Measuring never commits, pushes, or edits a file outside the target.

## Harden (only when the user asks)

1. **Write the killing tests** for the real survivors, in test files only. A production bug found on the way is reported, not fixed and not asserted.
2. **Kill-check each new test.** Re-apply its mutant: the new test must fail. Restore, then run the full suite: it must pass. A test that does not kill its mutant is rewritten or dropped.
3. **Commit tests only.** Run the repository's formatter and linter, commit the test files on the branch, and never push. Done when `git show --stat HEAD` lists test files only and the report shows each kill-check.
