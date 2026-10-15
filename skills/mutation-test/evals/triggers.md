# mutation-test trigger queries

| # | Query (as a user would type it) | Should trigger | Held out | Fired (last run) |
|---|---|---|---|---|
| 1 | run mutation testing on this branch | yes | no | 3/3 |
| 2 | are the tests on my PR actually strong enough to catch a regression? | yes | no | 0/3 |
| 3 | mutate the new code in this diff and tell me which mutants survive | yes | no | 2/3 |
| 4 | how good are the tests on feature/billing really? flip some conditions and see if they fail | yes | no | 0/3 |
| 5 | I just opened a draft PR with a tricky SQL query, check the tests would catch a broken filter | yes | no | 0/3 |
| 6 | do a mutation pass on PR 42 and add tests for the survivors | yes | no | 2/3 |
| 7 | would my test suite notice if someone changed >= to > in this pricing code? | yes | yes | 0/3 |
| 8 | measure the mutation score of the changes on this branch | yes | yes | 3/3 |
| 9 | before I merge, check whether these tests kill mutants or just pass on anything | yes | yes | 0/3 |
| 10 | test my tests on this branch | yes | yes | 3/3 |
| 11 | write unit tests for the new pricing function | no | no | 0/3 |
| 12 | why is this test failing on CI? | no | no | 0/3 |
| 13 | try to break this parser with hostile inputs and race conditions | no | no | 0/3 |
| 14 | what's our test coverage percentage on this repo? | no | no | 0/3 |
| 15 | review this PR for bugs | no | no | 0/3 |
| 16 | the useReducer state mutation isn't re-rendering my component, help | no | no | 0/3 |
| 17 | set up Stryker in our CI pipeline | no | yes | 0/3 |
| 18 | this GraphQL mutation returns null, why? | no | yes | 0/3 |
| 19 | refactor these tests so they're less flaky | no | yes | 0/3 |
| 20 | add property-based tests for the date parser | no | yes | 0/3 |

Last run: three headless sessions per query, three turns each, in plan mode, from a small Python repository with the skill installed at project scope. A run fired when it called the skill or read its folder. Every near miss stayed silent. The yes-queries that missed spent their three turns reading the diff and planning a mutation pass without loading the skill, so the three-turn cap undercounts them.
