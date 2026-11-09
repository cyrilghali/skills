---
name: mutation-test
description: Tests a branch's tests by planting small bugs (mutants) in its new code, one at a time, and reporting each one no test catches with the assertion that would. Use when the user says "mutation testing", "are the tests strong enough", "nos tests sont-ils solides", after opening a draft PR with risky lib/ logic (SQL, seams, jobs, calculations), or when another skill delegates its mutation axis. Also fires on "prove each new test catches its bug" or "plant a bug per check", and right before claiming new tests are mutation-proven (a claim like "a planted bug made each fail" needs one mutant per test, each seen failing).
metadata:
  category: verify
---

# Mutation testing a branch

Break the new code on purpose, one small change at a time, and rerun the branch's tests. If a test fails, the mutant is killed. If every test stays green, the mutant survived, and the tests have a gap. Report each gap with the assertion that would close it. No mutation library is needed.

Run this before merging a PR with risky logic, when someone asks whether the tests are solid, or after a large multi-PR effort, with one pass per PR in parallel.

When asked to check a branch's tests and code quality, also run the `crap-check` and `dry-check` skills on the same diff.

## Set up one agent per branch

Give each branch its own agent, or one agent per module when the branch is large. Launch them all in one parallel batch, as `general-purpose` with `model: "sonnet"`. Give each agent its own worktree or fork, so one agent's revert never undoes another's edit.

Tell each agent its target and its tests. The target is the production files (`lib/` or `src/`) in the branch's diff. The tests are the test files in the same diff. Get both with:

```sh
git diff --name-only $(git merge-base origin/<base> HEAD)..HEAD
```

## Give each agent this contract

1. **Start from a clean worktree.** Check that `git status --porcelain` prints nothing. If it prints files, copy each one to the scratchpad now and copy it back at the end. Do not use `git checkout .`, `git stash` or `git reset`: they wipe work in progress.
2. **Prove the tests are green before mutating.** Run the branch's tests in the foreground with a long timeout. If any fail, stop and report, because a mutant on red code proves nothing.
3. **Plant 8 to 15 mutants in the new code only**, riskiest logic first. Pick from these changes, which find real gaps:
   - flip a comparison (`>=` to `>`, `==` to `!=`) or a boundary (off-by-one, sign);
   - delete a `where` clause, a filter or a guard; invert a negation;
   - swap domain values, such as event or actor atoms and metadata strings;
   - in SQL, change `PARTITION BY` columns, `ASC` to `DESC`, `NOT EXISTS` to `EXISTS`, `IS NOT DISTINCT FROM` to `=`, a median to a mean, or an interval;
   - skip a write or an event, or apply it to the first list item only.

   Choose mutants that compile; SQL strings are ideal. A mutant the compiler rejects says nothing about the tests.
4. **Test one mutant at a time.** Apply it. Run the branch's tests to the end, past the first failure, so every failing test is recorded. If a test fails, record the mutant as killed by a PR test, with each failing test as `file:line`. Revert with `git checkout -- <file>` or the backup copy, and check the worktree is clean before the next mutant.
5. **Check a survivor against the tests that already exist.** A mutant no PR test catches is not a gap yet, because an unchanged test elsewhere may already kill it. Find every test that exercises the mutated module (grep the test tree for the module name, and take its neighboring test directory) and run those once. If one fails, record the mutant as killed by an existing test. If none fails, record it as a survivor of every covering test. Revert as in step 4.
6. **Report to the main session.** Send a table `id | file:line | mutation | result`, where the result says killed by a PR test, killed by an existing test, or survived every covering test. Add one line per survivor naming the gap and the assertion that would close it, and the final `git status --porcelain` as proof the worktree is clean.

Edit only the target files. Never commit or push.

## Close the gaps, only after the user approves

Sort the survivors first. Only a mutant that survived every covering test is a gap. A real survivor would hide a production bug. A cosmetic survivor would not, such as write order inside one transaction, a log counter or fixture aliasing. For the real survivors, run one agent per branch with this contract:

1. Add the suggested tests. Leave production code as it is. If you suspect a production bug, report it instead of fixing it in this pass.
2. Prove each new test kills its mutant: reapply the mutant and watch the test fail, then revert and watch the suite pass. Reject a test that does not kill its mutant.
3. Run the repo's formatter and linter. Commit the tests alone on the PR's branch. Do not push.

## Write the report for the user

Make the final message of the session the report. Give it to the user only, and ask before posting it anywhere else, such as a PR comment. If `MUTATION_TEST_REPORTS_DIR` is set, also save the same text to `$MUTATION_TEST_REPORTS_DIR/<repo>-pr<N>.md`, creating the folder if needed, for a cold read later.

Keep the agent tables in the session. Open the report with one sentence on what mutation testing did and the score. List only the real survivors, each as what survives and the assertion that would kill it, at `file:line`. Give the cosmetic survivors as a count. Use prose and bullets, with no table, emoji or empty section. With no real survivor, write two lines. Record the run with `skill-record mutation-test mutants=N killed=K/N real_survivors=R cosmetic_survivors=C tests_added=T`, once, only when the run finished; a dry run or an aborted run records nothing. Here tests_added is the number of tests committed in the close-the-gaps pass, 0 when that pass did not run.

```markdown
**Mutation testing**: I changed this PR's new code in N places (deleted
filters, flipped comparisons, swapped mappings) to check that a test fails
each time. Score: K/N killed.

M survivors would hide a real bug:

- `file.ex:LINE`: <the mutation in one clause> makes no test fail.
  Assertion to add: <the concrete test that would kill it>.

Cosmetic survivors ignored: C.
```

## Combine the results in the main session

Score each branch (killed out of total) and all branches together. Split real survivors from cosmetic ones, and name the production bug each real one would hide. When a survivor exposes a bug already in production, such as a genuine off-by-one, report it as a finding. Do not add a test that kills that mutant, because it would lock the bug in.
