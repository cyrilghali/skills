# rewrite-commits trigger queries

| # | Query (as a user would type it) | Should trigger | Held out | Fired, first description | Fired, final description |
|---|---|---|---|---|---|
| 1 | clean up the commit history on my draft PR before review | yes | no | 2/3 | 1/3 |
| 2 | squash these 12 wip commits into a couple of atomic ones | yes | no | 0/3 | 1/3 |
| 3 | my PR's git log reads like a stream of consciousness, collapse it into 2-3 real commits | yes | no | 2/3 | 3/3 |
| 4 | rewrite the commits on this branch so each one is a logical unit | yes | no | 0/3 | 1/3 |
| 5 | tidy the commits on every branch of my gh stack before I mark them ready | yes | no | 2/3 | 3/3 |
| 6 | turn the fixup and "address feedback" commits on my branch into proper commits | yes | no | 2/3 | 2/3 |
| 7 | the bottom PR of my stack has a fix that landed in the PR above it, move it down and clean both histories | yes | yes | 2/3 | 3/3 |
| 8 | collapse my branch's noisy commits, then force push it safely | yes | yes | 0/3 | 1/3 |
| 9 | before I flip this draft to ready, make the history reviewable commit by commit | yes | yes | 2/3 | 2/3 |
| 10 | regroup the 9 commits on feat/export into one commit per concern | yes | yes | 3/3 | 2/3 |
| 11 | write the PR description for my branch | no | no | 0/3 | 0/3 |
| 12 | split this big branch into a stack of smaller PRs | no | no | 0/3 | 0/3 |
| 13 | rebase my branch onto the latest main | no | no | 0/3 | 0/3 |
| 14 | reword the message of my last commit | no | no | 0/3 | 0/3 |
| 15 | amend my last commit to include the file I forgot | no | no | 0/3 | 0/3 |
| 16 | enable squash merging on this GitHub repo | no | no | 0/3 | 0/3 |
| 17 | review the commits on my teammate's PR | no | yes | 0/3 | 0/3 |
| 18 | undo my last three commits but keep the changes | no | yes | 0/3 | 0/3 |
| 19 | write a good commit message for these staged changes | no | yes | 0/3 | 0/3 |
| 20 | find which commit introduced this regression with git bisect | no | yes | 0/3 | 0/3 |

Each query ran three times in a fresh headless session (`claude -p ... --max-turns 3 --permission-mode plan --disallowedTools Agent`) from an empty git repo holding the skill at project scope, with every other installed skill competing. A run fired when a tool call named the skill (`Skill`) or read its folder (`Read`, `Bash`, `Glob`, `Grep`).

| Description | Should-fire queries passing (majority) | Fires on should-fire queries | Near-miss false fires | Held-out passing |
|---|---|---|---|---|
| First | 7/10 | 15/30 | 0/10 | 7/8 |
| Final | 6/10 | 19/30 | 0/10 | 7/8 |

The near misses never fire. The should-fire queries fire in about half to two thirds of runs: in plan mode, with an empty repo and three turns, the model often inspects the repo first and runs out of turns before it loads a skill.

A second run used a realistic repo: a feature branch with noisy iteration commits and the skill untracked under `.claude/skills/`. With the final description, all 20 queries passed. The should-fire queries fired in 29 of 30 runs, the near misses in 0 of 30, and all 8 held-out queries passed. The empty-repo numbers above mostly measure the turn limit.
