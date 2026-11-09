# write-a-skill eval cases

Each case gives a generation agent everything it needs WITHOUT asking questions.
The agent applies `SKILL.md` and returns only the artifact: the absolute path of the folder it wrote (or the diff it would apply), followed by every file's content. A judge scores it against `rubric.md` and may list the folder with modification times.
The `Trap` field names the failure mode the case is designed to catch.

## Case 1: a recurring correction that deserves a new skill

**Source:** synthetic (phrased like real requests; written by the skill author)
**Input:** "I keep correcting you the same way on commit messages; turn that into a reusable skill for me."
**Context (pre-answered):** The corrections, each made more than once: "subject line is one imperative sentence, no period", "no Co-Authored-By or Generated-with footer", "the body says why, never lists the files you touched". No installed skill covers commit messages. Use the category `ship`. Write the folder in your scratchpad. Run the baseline once; skip the three-run eval loop, I will run it later.
**Trap:** writes SKILL.md first and evals after, or skips the trigger queries and the baseline because the rules feel obvious.

## Case 2: a one-line rule for an existing skill

**Source:** correction (the "Editing from a recurring correction" path)
**Input:** "Add to my prose skill: never write 'leverage' as a verb. I've corrected that three times this month."
**Context (pre-answered):** The prose skill is installed among your skills, with a SKILL.md of rules. Return the diff you would apply to its SKILL.md; do not edit the real file.
**Trap:** runs the full process for a one-line bullet: new folder, new evals, a section where one bullet was enough.

## Case 3: a one-off that is too thin to encode

**Source:** synthetic
**Input:** "You used spaces instead of a tab in a Makefile once today. Make a skill so it never happens again."
**Context (pre-answered):** It happened once, in one session; there is no other instance.
**Trap:** produces a skill or a rule from one instance instead of saying the evidence is weak and stopping.

## Case 4: a shareable skill that needs a private tool

**Source:** synthetic, shaped on real requests for weekly database checks
**Input:** "Make a skill that checks every Monday which Postgres tables grew more than 20% in a week, using my `pgq` CLI (pgq <source> "<sql>"). My teammates will install it too, and they don't have pgq."
**Context (pre-answered):** Category `observe`. Teammates use their own SQL client. Write the folder in your scratchpad. Run the baseline once; skip the three-run eval loop.
**Trap:** hard-codes `pgq` or a home path, leaving teammates with a skill that fails; or puts the size query in prose instead of a script.

## Case 5: a request an installed skill already covers

**Source:** transcript (a warm-build skill was requested after one already existed)
**Input:** "Make me a skill that gets a warm _build and deps into a new app worktree instead of recompiling everything."
**Context (pre-answered):** Check the installed skills before writing anything.
**Trap:** writes a second skill for a job an installed one already does.

## Case 6: a fix the user expected to go through this skill

**Source:** transcript 90b29842-104f-4860-82c1-a20ad4289bf5.jsonl, 2026-09-26
**Input:** "ok pls fix the collect skill or memory the the gaps that remain"
**Context (pre-answered):** The session just ran a weekly product lookback. Two gaps remained: the Sentry search by the word "billing" missed issues that carry a team tag, and the Datadog lookback query returned nothing. The user has a rule that skill edits go through the skill-authoring skill. The assistant had already found a working Datadog query and a working Sentry tag filter during the session. The skill that holds the lookback query exists (`product-lookback`, file `REFERENCE.md`).
**Trap:** The assistant saved the working queries to memory only and reported "there's no collect skill to change yet". It did not edit the skill that holds the broken query, and it did not invoke the skill-authoring skill. Correction: "I didn't change it, because editing a skill has to go through /write-a-skill this is so stupid, why dont u use write a skill then?" Then, after the fix: "never tell me u cant do somethin because u have to use a skill, use the skill". Failure: resolving "the collect skill" to nothing, patching only memory, and treating the required workflow as a blocker instead of running it. Also note the one-line fix was later applied without evals and the skill was not re-run.

## Case 7: "make this a skill" after a drafting conversation

**Source:** transcript 82b154b8-39e4-4eee-972c-9bab4801da5f.jsonl, 2026-10-02
**Input:** "make this a skill"
**Context (pre-answered):** The conversation was about writing a pull request description for a product change (a new outcome after a failed payment). The assistant had produced an English draft in the user's voice, the user asked for French, and the assistant gave a French version. "This" followed that draft. The user had earlier asked for descriptions that a cold reader follows. The user interrupted the first attempt and wrote: "but wait before doing it, i dk why you are using implicit context from this conversation 'aka le code est plus rout' '3/4 pr' second, i prefer english, and saying tests for saying tests were added is an empty info". Skills already installed include a PR-description skill, a prose skill with a cold-read pass, and a clarity gate memory.
**Trap:** Two. First, "this" is ambiguous (the PR description, the rewrite-for-cold-reader process, or the style of the draft); the skill author must pin the job and its trigger phrases rather than copy the draft. Second, duplicating what exists. The user's correction after the retry: "Never ever use implicit context of discussion, we already talked and made a cold reader skill". A good result checks installed skills first, extends the existing cold-read or PR skill instead of making a third one, and writes rules that do not depend on the conversation (no "shorter", "3/4", no empty claims like "tests added").

## Case 8: a skill tuned to its own evals

**Source:** transcript 9e232563-7d90-4341-a9a9-7ffcd1a6d368.jsonl, 2026-10-04
**Input:** "my domain review skill will be bad if it nudges to specific examples that we find in evals", then, after the assistant's first reply: "what i dont want to see in evals and skills is modifying the skill to validate the specific subset of evals"
**Context (pre-answered):** The user owns a review skill (`domain-review`) with reviewer charter files under `references/` and an eval set of numbered cases with a run script. In this session the assistant had added or reworded examples in reviewer charters while fixing eval cases, and was re-running cases 25 and 26 three times each. The assistant's first answer admitted four charter sentences that restate an eval case's answer, so earlier passes on cases 12, 18 and 20 overstated quality.
**Trap:** Tuning the skill to its own evals. Failure to avoid: swapping one specific example for another, or keeping examples that restate a case's answer, then counting the eval pass as proof. The user corrected twice (the quotes above). A good result rewrites the charters with general rules, tests with fresh held-out cases the skill was not edited against, and routes the edit through the skill-authoring workflow (the assistant did invoke it only after the second correction).
