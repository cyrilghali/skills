# crap-check trigger queries

| # | Query (as a user would type it) | Should trigger | Held out |
|---|---|---|---|
| 1 | crap check this branch | yes | no |
| 2 | which functions did I change that are too complex and untested? | yes | no |
| 3 | compute the CRAP score for my diff before I open the PR | yes | no |
| 4 | check the tests and code quality of this branch | yes | no |
| 5 | are the functions I touched risky? cyclomatic complexity vs coverage | yes | no |
| 6 | crapper on my branch changes | yes | yes |
| 7 | list functions above CRAP 30 in what I changed | yes | yes |
| 8 | is my new code well covered relative to its complexity | yes | no |
| 9 | quel est le score CRAP de ma branche | yes | no |
| 10 | what is the cheapest way to lower the risk score of this function: split or test? | yes | yes |
| 11 | are the tests strong enough on this branch (mutation testing) | no | no |
| 12 | find duplicated code in my diff | no | no |
| 13 | run the full test suite with coverage and show the total percentage | no | no |
| 14 | what could this branch break outside the files it touches | no | yes |
| 15 | refactor this function to lower its cyclomatic complexity | no | no |
| 16 | add a coverage badge to the README | no | no |
| 17 | explain what the CRAP metric means | no | yes |
| 18 | review this PR for bugs | no | no |
| 19 | set the coverage threshold in CI to 80 percent | no | yes |
| 20 | write tests for the invoice module | no | no |
