# torture-test trigger queries

Run each query three times in a fresh headless session; a query passes when
the majority of its runs match the Should trigger column. Tune the
description on the open queries only.

| # | Query (as a user would type it) | Should trigger | Held out |
|---|---|---|---|
| 1 | torture test the pagination cursor module before we expose it publicly | yes | no |
| 2 | try to break debit_wallet before the one-click payment launch | yes | no |
| 3 | harden the tests on lib/payouts.ex, real money goes out to merchants from it | yes | yes |
| 4 | do a QA pass on this branch before release and hunt for inputs that break it | yes | no |
| 5 | throw hostile inputs at the slugify function and tell me what breaks | yes | no |
| 6 | stress this retry logic for me: double submits, timeouts, events out of order | yes | no |
| 7 | break my CSV parser please, weird encodings, huge files, whatever makes it fall over | yes | yes |
| 8 | adversarial testing pass on the refund module, what fails under retries and partial writes? | yes | no |
| 9 | before I ship this backfill script, attack it: crash it halfway, rerun it, see what state it leaves | yes | yes |
| 10 | find the bugs in this date range helper by attacking it, don't just pile on tests | yes | yes |
| 11 | run mutation testing on this branch and tell me which mutants survive | no | no |
| 12 | write unit tests for the new invoice formatter | no | no |
| 13 | test_tax is failing on main, fix it | no | no |
| 14 | review this PR diff for bugs before I merge | no | yes |
| 15 | set up a k6 load test for our checkout API | no | no |
| 16 | explain how the retry logic in the job queue works | no | yes |
| 17 | do a security review of the auth middleware | no | no |
| 18 | add hypothesis to the project dependencies and configure a profile for CI | no | yes |
| 19 | our CI is flaky, find which test is nondeterministic | no | yes |
| 20 | refactor the wallet module to use a repository pattern | no | no |

## Results

Each query ran three times in a headless session limited to three turns, in a
repository that holds the code each query names. All 10 should-trigger queries
fired on a majority of runs (28 of 29 valid runs), the four held-out ones
included. Near-miss queries 11 to 15 never fired there (14 valid runs);
queries 16 to 20 hit a usage limit in that repository. In two earlier runs of
the same description, without the named code present, none of the 10
near-miss queries fired on a majority of runs (one stray fire on query 18).

Without the named code in the repository, the session spends its three turns
searching for it and rarely reaches the skill. That measures the turn limit,
not the description.
