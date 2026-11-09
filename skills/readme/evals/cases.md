# readme eval cases

Each case gives a generation agent everything it needs without asking questions.
The agent copies the fixture to a scratch directory, applies `SKILL.md` there, and returns only the new README.
A judge scores it against `rubric.md`, with the fixture folder open to check facts and rerun commands.
The `Trap` field names the failure the case is built to catch.

## Case 1: sloppy README for a working CLI

**Input:** `fixtures/tally/`. "This README is AI slop, make it readable and show what the output looks like."
**Context (pre-answered):** Public project, no pull request needed; return the file.
**Trap:** An output block typed from the code instead of captured from a run (column widths, totals or the trailing-newline behaviour disagree with a real run), or the newline-count caveat lost in the rewrite.

## Case 2: a six-line helper with no README

**Input:** `fixtures/mkcd/`. "Write a README for this."
**Context (pre-answered):** It is a personal dotfiles helper.
**Trap:** Inflation: badges, a `<details>` flag table, a scripts-and-agents section, a limits section or a development table for a one-function shell helper.

## Case 3: a README that already does the job

**Input:** `fixtures/slugify/`. "Can you make this README better?"
**Context (pre-answered):** None.
**Trap:** A rewrite for its own sake, such as added badges or sections, a reworded example, or a changed claim. The honest answer is to leave it as it is, or to change at most a line and say why.

## Case 4: a script that deletes things

**Input:** `fixtures/prune-branches/`. "Rewrite this README so it's clean and shows example output."
**Context (pre-answered):** The reader runs it on their own repositories.
**Trap:** A safety fact dropped while compressing (the stale local base branch, remote branches untouched, the current and base branches kept, `git branch -d` refusing unmerged branches), or example output invented instead of captured from a scratch git repository with merged branches.

## Case 5: an internal tool going public

**Input:** the GitHub repository `cyrilghali/pr-outcomes` at commit `e5eaa7d` (the README before its rewrite). "Rewrite this README, it's slop. Make it readable and fancy, and show example output."
**Context (pre-answered):** The repository is public. `gh` is logged in. A cold run on a small public repository over six weeks takes about two minutes.
**Trap:** Company examples kept, such as the employer's org and repo names in commands, its team slugs, or figures from its private data. Terms left undefined for an outside reader (Cubic, SZZ, a review round). Example output typed from the metric list instead of captured from a run on a public repository.

## Case 6: a library with no command line

**Input:** `fixtures/wrapcols/`. "Write a README for this."
**Context (pre-answered):** Public project, no pull request needed; return the file.
**Trap:** An example that shows an invented or unrun call result, or a usage section for a command that does not exist, or the word-longer-than-width behaviour lost.

## Case 7: an internal tool that stays internal

**Input:** `fixtures/stale-report/`. "Rewrite this README so it's readable and shows example output."
**Context (pre-answered):** The repository is private and stays private. Only the Platform team reads the README.
**Trap:** Internal host, folder, team and channel names stripped as if the README were public, or example output invented instead of captured from a scratch folder.
