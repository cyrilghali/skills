# crap-check eval cases

Each case gives a generation agent everything it needs WITHOUT asking questions.
The agent applies `SKILL.md` and returns only the report it would give the user, plus the gate record text.
A judge scores it against `rubric.md`. The `Trap` field names the failure mode the case is designed to catch.

## Case 1 - Elixir branch adds a complex, untested function

**Source:** synthetic, modeled on a Phoenix service branch
**Input:** "Check the CRAP score of my branch before I open the PR." Base is `origin/staging`. The script output lists one scorable file, `lib/app/billing/invoice_rules.ex`. One function is new: `Billing.InvoiceRules.classify/2`, CC 6, coverage 0%, CRAP 42. The new test file covers a different function.
**Context (pre-answered):** coverage came from a real ExCoveralls run on the branch's tests; threshold is the default.
**Trap:** the agent reports the score but names a vague fix ("add tests") instead of the cheapest fix with its number, or marks the row pre-existing because the file already existed.

## Case 2 - A rename changes one line

**Source:** synthetic
**Input:** "crap-check this branch." The branch renames one variable inside `src/format.ts` (TypeScript). Script output: three functions overlap the changed line, CC 2, 3 and 1, all 100% covered; `new=0 pre-existing=0 threshold=10`.
**Context (pre-answered):** none beyond the script output.
**Trap:** the agent inflates a clean result into advice, a list of refactors, or a table of every function.

## Case 3 - Nothing scorable on the branch

**Source:** synthetic
**Input:** "Is my branch's code quality ok?" The branch changes only `README.md`, `docs/plan.md` and `test/app/foo_test.exs`.
**Context (pre-answered):** the base branch is `origin/main`.
**Trap:** the agent scores test files or markdown, or reports a made-up result instead of saying there is no scorable file.

## Case 4 - Pre-existing complexity next to a real finding

**Source:** correction pattern (a gate that blocks on old code blocks most PRs)
**Input:** "Run crap-check, then tell me if I can open the PR." Script output has two rows. Row A: `Reports.build/1`, CC 38, coverage 20%, the branch edited one line and CC is 38 at base too. Row B: `Reports.rollup/2`, a new function, CC 34, coverage 90%. Threshold is 30.
**Context (pre-answered):** none.
**Trap:** the agent treats row A as blocking, or says "test row B to N%" when CC alone already exceeds the threshold (full coverage leaves CRAP at 34, so the only fix is a split).

## Case 5 - Request from inside the project, tools missing

**Source:** synthetic, different language and domain from the others
**Input:** "check the tests and code quality of this branch" in a Node service repo where `npm test` needs a database that is down. The script was run without `--no-coverage` and the test run failed.
**Context (pre-answered):** the failure output shows `ECONNREFUSED`.
**Trap:** the agent still writes a gate record or invents scores; or it runs only crap-check and forgets the sibling checks `dry-check` and `mutation-test`; or it silently falls back to 0% without saying so.
