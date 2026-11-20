---
name: pr-lesson
description: Writes a lesson on the code a pull request touches, as that code was before the change - a map of the whole feature, what a person sees, one action followed line by line, what each action writes, then a guess and the change itself - as a record that a fixed template draws, and files it by product area so the next lesson of an area teaches only what is new. Use when asked to "write the lesson for PR 123", "teach me the code behind this pull request", "prepare me to review this PR", "what do I need to understand before reading this diff", or to run lessons for a team's open pull requests.
metadata:
  category: research
---

# Write the lesson for one pull request

The reader will review this pull request and does not know the code. Teach them how the feature works at the commit the pull request started from. Show the change only at the end, behind a guess.

## Write the lesson in this order

1. **Prepare.** Run `scripts/prepare.sh <owner/repo> <number> --home <store> --repo <owner/repo>=<checkout>`, with one more `--repo` for each other repo the action crosses (a front end). It prints the pull request, the `base` and `head` commits, the changed files, the ticket key, the areas the store holds and the path of the record to write. Done when you hold that JSON.

2. **Decide whether a lesson exists.** A pull request that changes no behaviour and no code path a reader could follow (documentation, CI, a dependency bump, a revert, tests only) gets none: run `scripts/render.py <prepare.json> --home <store> --skip "<reason in 4 to 12 plain words>"` and stop. Done when you chose.

3. **Read the need.** Read the pull request's description and, when it names a ticket, the ticket's context paragraph. Stop before the ticket's rules or acceptance criteria: they state the change and give away the guess. Done when you can say in one sentence what a person could not do or see.

4. **Read the code before the change.** Read every file with `git -C <checkout> show "<base>:<path>"`, never from the working tree. Pick the one action whose path runs through the lines the pull request changes: a person's click, an API call, or one run of a job. Follow it hop by hop, opening each function it calls down to the query and the write: the entry point, the validation, the save and its transaction, each event or job it starts and what receives it, the query that picks the rows, and the line that decides what the person sees. At a branch, follow the case that shows the gap. Done when the path reaches what the person sees and you read every line you will cite.

5. **Place it in an area.** An area is one feature of the product, as a person would name it. When `prepare.sh` lists `area_ids`, use the id that fits and read its note in the `area_notes` folder; when none fits, name the area yourself. When the store holds the area, read its file: its map is the lesson's first figure, and `lessons` lists the steps earlier lessons taught. When it does not, write the area file first, as `RECORD.md` describes: read enough of the area at `base` to cite every node. Draw the area from its own code; another area's map is never a model. Done when the marker names the node this pull request changes.

6. **Write the record** at the path `prepare.sh` gave, following `RECORD.md`. Done when `scripts/check-record.py <record> --home <store> --repo <owner/repo>=<checkout>` exits 0 and each line it prints shows what its step says.

7. **Render.** Run `scripts/render.py <record> --home <store>`. Done when it prints the row's path.

8. **Have it fact-checked.** Hand `FACTCHECK.md` to a fresh agent with the record's path, unless the caller says a separate session does it. A lesson is finished only when its record holds `factcheck`. Reply with the row's path and one sentence on what the lesson teaches.

## Hold every lesson to these rules

- **Before, then after.** Every figure shows the code at `base` and says so in its `when`. The map holds only parts that exist at `base`: when the pull request adds a part, mark the existing part it will join. Only `guess.answer` shows the change, citing lines with `"at": "head"`.
- **Open with a statement.** The headline says what is different after this pull request alone, as the diff shows it. The introduction says what the pull request touches and which parts of the code the reader needs. A question comes only in the guess.
- **Write literal English.** The reader's first language is not English. Use short sentences, about 20 words. Say what happens in plain words: "the second answer waits until the first one is saved", not a figure of speech. Give each internal term one plain gloss the first time it appears.
- **Use one name per part.** An actor that is a part of the map carries that part's id as `node`, and its label uses the map's words.
- **Name things as a person sees them.** Labels and step texts say what happens to a person or their data. Function and module names go in `code` fields and citations.
- **Teach only what is new.** A step an earlier lesson of the area taught keeps its place in the path, with `known` set to that pull request's number and a shorter text. Never redraw a map the area already has.
- **Ask a guess the figures can answer.** A question points at something the figures show (a field, a step, a case) and asks what the reader would change or test. The answer then says what the pull request does, which rules or cases it leaves out, and what to check in the review.
- **Leave history out.** Say why code is shaped as it is only when the reader cannot understand a changed line without it, and then in the step that needs it.
- **Mark where it goes wrong.** When the pull request fixes a gap, set `lost` on the first step where the outcome stops matching what the person expects. A pull request that adds a new ability has no `lost` step: show today's nearest path and where the new one will branch off.
- **No screen, no invented screen.** When no person sees the change, write `no_screen` with the reason and keep the path and the table.
