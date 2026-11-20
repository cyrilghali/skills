# investigate-first trigger queries

| # | Query (as a user would type it) | Should trigger | Held out |
|---|---|---|---|
| 1 | the nightly export job sometimes drops rows and nobody knows why, can you dig in before we touch anything | yes | no |
| 2 | this test passes locally but fails on CI maybe 1 time in 5, figure out what's going on | yes | no |
| 3 | how does the caching layer in this repo work? | yes | no |
| 4 | why was the retry logic built as a separate worker instead of inline? | yes | no |
| 5 | where should a new rate-limit check live, the controller or the service? | yes | no |
| 6 | the dashboard got 3x slower since last week's deploy, find the cause | yes | no |
| 7 | restate this bug report in plain words, I don't get what the customer is complaining about | yes | yes |
| 8 | why did you pick a queue here and not a cron job? | yes | yes |
| 9 | users say login fails "sometimes" after the upgrade, I have no idea where to start | yes | yes |
| 10 | which module owns the invoice numbering? before I change it I want to know who depends on it | yes | yes |
| 11 | fix the typo in the README heading | no | no |
| 12 | what happens when someone clicks "export" on the reports page, trace it front to back | no | no |
| 13 | review my diff for bugs before I push | no | no |
| 14 | add a test for the parse_date function | no | no |
| 15 | write a PR description for this branch | no | no |
| 16 | rename the `usr` variable to `user` everywhere in this file | no | no |
| 17 | are my tests strong enough? plant some bugs and see | no | yes |
| 18 | research the best open-source job queue libraries for Python and compare them | no | yes |
| 19 | the build fails with "module not found: lodash", just install it and rerun | no | yes |
| 20 | follow the request from the signup button to the database and give me the call chain | no | yes |

## Results

Each query ran three times in a fresh headless session (three turns, plan mode) inside a small sample project. "Fired" means the skill was called or its folder was read.

| Description | Should-fire runs that fired | Queries passing (open / held out) | False fires |
|---|---|---|---|
| Previous, imperative "Diagnose ambiguous failures..." | 4 of 30 | 6 of 12 / 5 of 8 | 0 |
| "Investigates before any code changes..." (rejected) | 0 of 30 | 6 of 12 / 4 of 8 | 0 |
| Current, "Diagnoses bugs, flaky tests and slowdowns..." | 6 of 30 | 7 of 12 / 5 of 8 | 0 |

The current description fires most and never on a near miss, so it stays. The gain is small. Explanation questions (how it works, why it was built, where code belongs) never fired with any wording: the model reads the code and answers directly. Only failure reports fire, and only some of the time.
