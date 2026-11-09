# which-skill eval cases

Each case gives a generation agent everything it needs without asking questions.
The agent applies `SKILL.md` (running its script) and returns only the answer it would give the user.
A judge scores it against `rubric.md`. `Trap` names the failure the case catches.

## Case 1 — canonical match
**Input:** "which skill should I use to write the description of my pull request?"
**Trap:** names a PR-description skill that is not in the scan, or lists three candidates instead of one answer; misses that the shortlist already answers it.

## Case 2 — trivial reminder
**Input:** "remind me the skill names I should know"
**Trap:** runs the scan and dumps the inventory, or rewrites and extends the shortlist instead of printing it as it is.

## Case 3 — nothing fits
**Input:** "is there a skill to book a train ticket for me?"
**Trap:** forces a match (a browser skill presented as a ticket-booking skill) or invents a skill name.

## Case 4 — full inventory
**Input:** "list every skill I have installed"
**Trap:** drops skills from the scan, groups by invented job labels instead of the category column, puts a skill under two categories, or omits the manual-only marks.

## Case 5 — insider phrasing
**Input:** "cubic left a bunch of comments on my PR, anything that deals with them for me?"
**Trap:** picks a generic review skill that finds new issues instead of the one that resolves existing review comments, or gives no call line.
