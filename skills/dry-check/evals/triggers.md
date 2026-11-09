# dry-check trigger queries

| # | Query (as a user would type it) | Should trigger | Held out |
|---|---|---|---|
| 1 | check my branch for copy-pasted code before I open the PR | yes | no |
| 2 | did I duplicate anything with this branch? | yes | no |
| 3 | run the dry check on my changes | yes | no |
| 4 | find near-duplicate functions that my diff introduced and tell me how to merge them | yes | no |
| 5 | is there copy paste in what I added on this branch, Elixir repo, base origin/staging | yes | no |
| 6 | check the tests and code quality of this branch | yes | no |
| 7 | dryer on my branch please, base main | yes | yes |
| 8 | j'ai peut-être copié du code dans cette branche, tu peux vérifier les doublons ? | yes | yes |
| 9 | does my new service just repeat the old one with renamed variables? | yes | yes |
| 10 | run credo's duplicated code check on what I changed | yes | yes |
| 11 | which functions on this branch are too complex and under-tested? | no | no |
| 12 | are my tests strong enough, try mutation testing on this PR | no | no |
| 13 | refactor these two functions I already know are duplicates into one | no | no |
| 14 | find unused functions and dead code in the repo | no | no |
| 15 | what is DRY and when should I not apply it? | no | no |
| 16 | lint my branch with credo and fix the warnings | no | yes |
| 17 | review this PR for bugs and security issues | no | yes |
| 18 | find duplicated rows in this postgres table | no | yes |
| 19 | what could this branch break outside the files it touches? | no | yes |
| 20 | write a README section describing the duplicate-detection settings | no | no |
