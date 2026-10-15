# prose trigger queries

Each query runs three times in a fresh headless session. Fired = a `Skill` call naming `prose`,
or a read of its folder. A query passes when the majority of its runs match the Should trigger
column. Held-out queries were never read while tuning the description.

| # | Query (as a user would type it) | Should trigger | Held out |
|---|---|---|---|
| 1 | Rewrite this paragraph, it's way too wordy: "It is worth noting that the cache is essentially invalidated on every deploy, which basically means that the first request after a deploy is clearly slower." | yes | no |
| 2 | This section of our design doc is unclear. Can you tighten it up? "Storage: we went back and forth on this a lot, and after checking with the team we decided to keep everything in one table." | yes | no |
| 3 | Can you restate this in plain language with no jargon for our support team: "The idempotency key dedupes retries at the ingress layer before fan-out." | yes | no |
| 4 | this ticket description is a wall of text, clean it up so an engineer can implement from it: "When the import finishes it checks the batch and if it's valid it commits and if it's not it rolls back and if it times out it retries twice and then alerts." | yes | no |
| 5 | Edit this reply to a customer so someone outside the company understands it: "Your order is in the hold window so the credit gets released once QA clears it." | yes | no |
| 6 | Is this paragraph clear? Give me a better version. "Going forward, the team will leverage the new pipeline to facilitate a more seamless deployment experience." | yes | no |
| 7 | Too verbose. Rewrite the summary paragraph of my incident note: "So basically what happened is that at around 3pm we noticed that, and this is important, the queue had stopped draining." | yes | yes |
| 8 | Make this decision record readable for someone who joins the project next month: "After a long discussion on 12/03 with the platform folks, and having verified it in the code, we concluded Redis was not the right fit." | yes | yes |
| 9 | Review the prose in this doc section and fix anything a cold reader would trip on: "The sidecar handles the usual stuff, so the gate stays thin." | yes | yes |
| 10 | Rewrite this status update so the answer comes first: "We looked into several options over the week, compared costs, and talked to two vendors. In the end we'll stay on the current provider." | yes | yes |
| 11 | Translate this paragraph into German: "The cache is invalidated on every deploy, so the first request after a deploy is slower." | no | no |
| 12 | Fix the typos in this sentence: "Teh deploy pipline runs evry night at midnigth." | no | no |
| 13 | Summarize this RFC in five bullet points for the weekly meeting. | no | no |
| 14 | Write the pull request description for the branch I just pushed. | no | no |
| 15 | Rewrite the commit messages on this branch so each one says what changed. | no | no |
| 16 | Add docstrings to every public function in the billing module. | no | no |
| 17 | Rename the variables in this function so they're clearer. | no | yes |
| 18 | Write an onboarding explainer from scratch for engineers new to our billing system. | no | yes |
| 19 | Check this Spanish paragraph for grammar mistakes: "Los datos se guarda en la tabla principal." | no | yes |
| 20 | Align the columns of this markdown table: "a|b\n---|---\nlong value|x" | no | yes |

## Results

Each query ran three times in a fresh headless session, from a scratch project holding this folder under `.claude/skills/prose/`. A run counts as fired when it calls the Skill tool with `prose`, or opens `SKILL.md` or `VOICE.md`. A model that only lists the project files and greps the hook script did not fire. The first description is the one before tuning; the final description is the one in `SKILL.md`.

| # | Should trigger | Held out | First description | Final description | Final result |
| -- | -- | -- | -- | -- | -- |
| 1 | yes | no | 0/3 | 2/3 | pass |
| 2 | yes | no | 0/3 | 2/3 | pass |
| 3 | yes | no | 0/3 | 3/3 | pass |
| 4 | yes | no | 0/3 | 1/3 | fail |
| 5 | yes | no | 2/3 | 1/3 | fail |
| 6 | yes | no | 2/3 | 3/3 | pass |
| 7 | yes | yes | 0/3 | 1/3 | fail |
| 8 | yes | yes | 2/3 | 3/3 | pass |
| 9 | yes | yes | 3/3 | 3/3 | pass |
| 10 | yes | yes | 0/3 | 1/3 | fail |
| 11 | no | no | 0/3 | 0/3 | pass |
| 12 | no | no | 0/3 | 0/3 | pass |
| 13 | no | no | 0/3 | 0/3 | pass |
| 14 | no | no | 0/3 | 0/3 | pass |
| 15 | no | no | 0/3 | 0/3 | pass |
| 16 | no | no | 0/3 | 0/3 | pass |
| 17 | no | yes | 0/3 | 0/3 | pass |
| 18 | no | yes | 0/3 | 0/3 | pass |
| 19 | no | yes | 0/3 | 0/3 | pass |
| 20 | no | yes | 0/3 | 0/3 | pass |

| Measure | First description | Final description |
| -- | -- | -- |
| Should-trigger queries that pass | 4/10 | 6/10 |
| Should-trigger runs that fired | 9/30 | 20/30 |
| Near misses that fired | 0/10 | 0/10 |
| Held-out should-trigger queries that pass | 2/4 | 2/4 |
| Held-out near misses that fired | 0/4 | 0/4 |

A third description, which named "cleaning up" and "a single sentence pasted in the request", scored 3/6 on the open queries and was reverted. The misses are short texts pasted inline: the model rewrites them directly instead of loading the skill.
