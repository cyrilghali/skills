# newcomer-doc trigger queries

Ten queries need the skill and ten are near misses that share its words but need another job.
Eight are held out (four of each kind) and are never read while tuning the description.

| # | Query (as a user would type it) | Should trigger | Held out |
|---|---|---|---|
| 1 | Write a design doc comparing the three cache invalidation options for the team, two of them are new to the system | yes | no |
| 2 | Turn these research agent notes into a document a newcomer can read in one go | yes | no |
| 3 | This draft is unreadable, it reads like a scorecard. Rewrite it so someone new to the project gets it | yes | no |
| 4 | Write up the four storage options for the analytics project so the wider team can follow and decide | yes | yes |
| 5 | Explain to our product manager in a short doc why the admin counters lag and what the two fixes are | yes | no |
| 6 | I need an architecture note that walks a new hire through how payments flow, with one example followed end to end | yes | no |
| 7 | Draft a comparison document of build vs buy for invoice processing, for leadership who don't know the current process | yes | yes |
| 8 | Make an onboarding document explaining how refund requests move from intake to payout | yes | yes |
| 9 | Write a decision document for the team: event log vs stateful entity, with a recommendation and the open questions | yes | no |
| 10 | Can you write the study comparing our search indexing options so people outside the team can follow it | yes | yes |
| 11 | Polish this paragraph so it doesn't sound like AI | no | no |
| 12 | Give me three design options for the settings page that I can pick from | no | no |
| 13 | Write the PR description for this branch | no | yes |
| 14 | Help me understand how this PR works, walk me through it | no | no |
| 15 | Make a narrated explainer video on how caching works | no | no |
| 16 | Write a README for this repo | no | yes |
| 17 | Write a PRD from this conversation | no | yes |
| 18 | Split this feature into a plan of stacked PRs | no | no |
| 19 | Write a short Slack message telling the team the deploy is done | no | no |
| 20 | Review my design doc and tell me what's weak in it | no | yes |

## Results

Each query ran 3 times in a fresh headless session that stops after 3 turns, with hooks off. The skill sits in the repository's `.claude/skills/`, and the session runs from a subfolder that holds a README. A run fired when it called the skill or read its `SKILL.md`; listing the folder while exploring does not count.

| # | First description | Final description | Majority, final |
|---|---|---|---|
| 1 | 2/3 | 3/3 | yes (correct) |
| 2 | 1/3 | 3/3 | yes (correct) |
| 3 | 1/3 | 3/3 | yes (correct) |
| 4 | 0/3 | 3/3 | yes (correct, held out) |
| 5 | 0/3 | 1/3 | no (miss) |
| 6 | 3/3 | 3/3 | yes (correct) |
| 7 | 3/3 | 3/3 | yes (correct, held out) |
| 8 | 0/3 | 3/3 | yes (correct, held out) |
| 9 | 2/3 | 2/3 | yes (correct) |
| 10 | 0/3 | 3/3 | yes (correct, held out) |
| 11-20 | 0/3 each | 0/3 each | no (correct; 13, 16, 17 and 20 held out) |

The final description fires on 9 of 10 yes-queries and on none of the 10 near misses. All 8 held-out queries match. The tuning used the twelve open queries only; the held-out ones ran once, after the last change.

When the first description missed, the model spent its 3 turns exploring the repository for the material and stopped before loading the skill. The final description asks for the skill to load before gathering material.
