# skill-telemetry eval cases

Each case gives a generation agent everything it needs without asking questions.
The agent applies `SKILL.md` and returns only the artifact. A judge scores it against `rubric.md`.
The `Trap` field names the failure mode the case is designed to catch.

Every case runs with `SKILL_TELEMETRY_DIR` set to a fresh scratch folder, so no run touches a real log.

## Case 1 — Record a run whose value holds a quote and a space

**Source:** synthetic (the recorder's hardest input)
**Input:** "A mutation-test run just finished on this branch: 12 mutants, 10 killed out of 12, 1 real survivor. Record it, with the note `it's a "b" test`. Then show me the line that landed in the log."
**Context (pre-answered):** the agent is inside a git checkout with a GitHub remote; `SKILL_TELEMETRY_DIR` points to an empty folder.
**Trap:** quoting. A weak answer builds the JSON by string concatenation and either breaks on the apostrophe and the double quotes or stores `killed` as the string `"10/12"` instead of two numbers.

## Case 2 — Report on an empty log

**Source:** synthetic
**Input:** "Give me the skill report for mutation-test."
**Context (pre-answered):** `SKILL_TELEMETRY_DIR` points to a folder whose `runs.jsonl` is empty (zero bytes).
**Trap:** inflating nothing. A weak answer crashes on the empty file, prints a median of an empty list, or invents a trend. The honest output is one block saying zero runs and the compliance line.

## Case 3 — Add telemetry to a skill's last step

**Source:** the brief (the owner's stated use)
**Input:** "Add telemetry to the torture-test skill. Here is its last step: `Write the triage for the user`. Show me the sentence you would append and say when it must not run."
**Context (pre-answered):** the agent may read `METRICS.md`; the target skill is not to be edited in this case, only the sentence is returned.
**Trap:** recording at the wrong moment. A weak answer records at the start of the skill, records on a dry run, records twice when the skill retries, or invents metric names that are not in the registry.

## Case 4 — Read a trend and say what it means

**Source:** synthetic (a log with a clear move)
**Input:** "Here is my telemetry log. Is mutation-test getting better or worse, and is it worth keeping?"
**Context (pre-answered):** `runs.jsonl` holds eight mutation-test runs over 60 days: `killed_of` steady at 12, `killed` moving from 7 to 11 across the window, `real_survivors` moving from 4 to 1. Two torture-test runs sit in the same file. Transcripts in the window invoked mutation-test 10 times.
**Trap:** reading the wrong direction or the wrong skill. A weak answer counts the torture-test rows, calls fewer survivors "worse", or declares the skill worthless because 8 of 10 invocations recorded.

## Case 5 — SKILL_TELEMETRY_DIR is unset

**Source:** the brief
**Input:** "Record this roast run: 3 rounds, 7 findings total." No environment variable is set.
**Context (pre-answered):** `HOME` points to a fresh scratch folder with no `.local/share` inside it.
**Trap:** asking or stopping. A weak answer asks the user where to store the line, refuses because the folder does not exist, or writes to the current directory. The right answer creates the default folder under `HOME` and appends there without a question.
