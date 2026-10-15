# intent-pr trigger queries

Each query runs three times in a fresh headless session inside a small git repo with one feature branch; the result column holds the majority. Fired means a Skill call naming intent-pr, or a Read, Bash, Glob or Grep of its folder. Other installed skills competed for every query.

| # | Query (as a user would type it) | Should trigger | Held out | Result |
|---|---|---|---|---|
| 1 | Write an intent-based PR description for this branch | yes | no | fired 3/3 |
| 2 | Draft the PR body for my changes, keep it short and tell reviewers why it exists | yes | no | fired 3/3 |
| 3 | Certify this PR before I send it to the team | yes | no | fired 3/3 |
| 4 | The PR description is just a list of files, rewrite it so review goes faster | yes | no | fired 3/3 |
| 5 | Open a pull request for this branch with a proper description | yes | no | fired 3/3 |
| 6 | Write the PR so it directs the reviewer to what matters | yes | no | fired 3/3 |
| 7 | Help me write the description for PR 214, the reviewers keep asking what it is for | yes | yes | fired 3/3 |
| 8 | Can you write up the pull request text for the timeout fix? | yes | yes | fired 3/3 |
| 9 | gh pr create for this branch, write the why section | yes | yes | fired 3/3 |
| 10 | Turn this diff summary into a PR description a reviewer can approve from | yes | yes | fired 3/3 |
| 11 | Write a commit message for the staged changes | no | no | not fired 0/3 |
| 12 | Review PR 214 and leave comments on the risky parts | no | no | not fired 0/3 |
| 13 | What could this branch break outside the files it touches? | no | no | not fired 0/3 |
| 14 | Write release notes for version 2.3 from the merged PRs | no | no | not fired 0/3 |
| 15 | Split this branch into a stack of smaller PRs | no | no | not fired 0/3 |
| 16 | Summarize what changed in the last ten commits on main | no | no | not fired 0/3 |
| 17 | Fix the failing CI check on my pull request | no | yes | not fired 0/3 |
| 18 | Reword my last three commit messages so they read better | no | yes | not fired 0/3 |
| 19 | Write a design doc explaining why we moved from flags to columns | no | yes | not fired 0/3 |
| 20 | Reply to the reviewer's comment on my PR about the migration | no | yes | not fired 0/3 |
