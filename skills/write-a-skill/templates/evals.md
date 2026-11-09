# Eval harness template

Four files under `evals/`, written before `SKILL.md`: `cases.md` and `rubric.md` test what the skill produces, `triggers.md` tests whether its description fires, and `baseline.md` records how the model scores with no skill. Generation and judging use fresh subagents so the skill, not the session, does the work.

## cases.md

```markdown
# <skill> eval cases

Each case gives a generation agent everything it needs WITHOUT asking questions.
The agent applies `SKILL.md` and returns only the artifact. A judge scores it against `rubric.md`.
The `Trap` field names the failure mode the case is designed to catch.

## Case 1 — <the canonical case>

**Source:** <transcript | correction | synthetic>
**Input:** <what the agent receives>
**Context (pre-answered):** <what a user would have said>
**Trap:** <the specific way a weak skill fails here>

## Case 2 — <a trivial input the skill must not inflate>
## Case 3 — <an input where the honest answer is "nothing to do">
## Case 4 — <a high-stakes input where the skill must be exhaustive>
## Case 5 — <an input written from inside the project, curse of knowledge>
```

## rubric.md

```markdown
# <skill> scoring rubric

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail
(pass = total >= 14 of 18 AND no dimension at 0), one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | <what the skill promises first> | absent | partial | complete |
| ... | | | | |
| 9 | Nothing the input decided was lost | a fact missing | a minor fact dropped | all survive |

## Case-specific must-checks
- **Case 2:** dimension X = 0 if the output grew a structure the input did not warrant.
- **Case 5:** dimension Y = 0 if two or more terms stay undefined or get an invented definition.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ ... 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
```

## triggers.md

```markdown
# <skill> trigger queries

| # | Query (as a user would type it) | Should trigger | Held out |
|---|---|---|---|
| 1 | <a request that needs the skill, in the user's own words> | yes | no |
| 11 | <a near miss: same words, different job> | no | yes |
```

Twenty queries: ten that need the skill, phrased several ways, and ten near misses that share its words but need something else, such as a neighbouring skill's job. Mark eight of them, four of each kind, as held out: they are never read while tuning the description.

## Where cases come from

Take cases from real use first: a request that reached the skill (or should have) in a past session transcript, then a correction the user made to its output, then a synthetic case only for a slot the first two leave empty. Choose each case for the job it represents, never because today's model fails it: a case picked for its failure captures that model's blind spot, not the skill's. For a skill meant to travel, take at least one case from a different codebase, language or domain than the rest, synthetic if real use has none.

## Running

1. Generation: one `general-purpose` subagent per case, in parallel, on the model and effort that run the skill in real use and on each other model its readers run, told to read `SKILL.md` and the case, forbidden to read the rubric, returning the artifact alone (written to a scratch file when a script must run on it). Run every case three times.
2. Baseline: run every case once more with no skill loaded: the same request, a fresh subagent, no skill folder. Judge it like the others and record the scores in `evals/baseline.md`. A case the baseline passes shows no uplift; replace it with a harder one from real use. When most cases pass without the skill, the skill is not needed.
3. Judging: one strict, adversarial subagent per artifact, in parallel, told to read the rubric and the case, returning the output format alone. A second judge scores one artifact per case independently; when the two verdicts differ, rewrite the rubric line they read differently before trusting any score.
4. Read the spread: a case whose three runs split PASS and FAIL, or whose totals differ by more than 2 points, is noisy. Clarify its input or its rubric line before refining the skill against it. For a skill that outputs counts, compare the counts across the three runs of each case and set any threshold in the skill or rubric above that spread: a threshold inside it (a top repeat of 12 in one run and 14 in the next, against a "3 or more" cutoff) decides on noise.
5. Check the headroom: when every run of every case scores full marks, the cases cannot show an edit helping. Add a harder case from real use before any refinement round.
6. Refine: before the first edit, hold out two cases whose findings you never read while editing. Make one change per round from findings that recur across the other cases or runs, then rerun every case, the held-out ones included. Revert a change that raises the other cases while the held-out ones stay flat or drop. Never paste a case's input or expected output into the skill.
7. Audit each round for leaks: the agent that edited the skill never judges its own edit. A fresh subagent reads the round's skill diff and `cases.md`, and answers one question per changed line: does it restate a case's input, mechanism or expected answer, including as an example? Revert every line it names, then rerun. A skill edit with no leak audit, or one checked only on the cases that prompted it, is not a pass. When the audit flags a line that real use needs (for example a scheduled run depends on that fact), do not revert it to prose: move the fact into the skill's script output so the run gets it from the script and `SKILL.md` no longer restates it.

8. Triggers: install the skill, then run each query in `triggers.md` three times in a fresh headless session that stops after three turns, and record whether the skill fired. In Claude Code: `command claude -p "<query>" --output-format stream-json --verbose --max-turns 3 --permission-mode plan --disallowedTools Agent --strict-mcp-config --settings '{"disableAllHooks":true}'` (`command` skips a shell alias that adds permission flags; `--strict-mcp-config` skips MCP server startup, which halves each run's CPU time; `disableAllHooks` stops reply-gate and similar hooks from rewriting the output you keep; a run that exits on `error_max_turns` has finished). Any `claude -p` run whose output you keep starts from a scratch directory, returns its result instead of writing a file, and compares `git status` of the nearby repo before and after, because a run started in a live checkout can change it. Run at most two at a time: every run is a full session, and eight in parallel pushed the machine's load average past 150. A run fired when a tool call targets the skill: a `Skill` call naming it, or a Read, Bash or Glob of its folder, since a model often opens the folder instead of calling the tool. A query passes when the majority of its runs match its Should trigger column. Tune the description on the twelve open queries only, and keep a change only when the held-out queries pass too.

For many refinement rounds, `/claude-api hillclimb` runs this same loop (held-out split, one change per round, revert on overfit) when the host offers it; `/claude-api build-eval` drafts cases and graders from production transcripts.

## Blinding the generation subagent

The generation subagent must not know it is being scored — a subagent that knows it's in an eval performs differently than one doing a real task. Hand it only the case's **Input**, reworded as an organic request if it reads like a test fixture, plus whatever context a real user would have given. Never pass it the case's own title, its **Trap** field, or the rubric: each names the failure mode and tells the subagent what to perform around. Point it at a copy of the skill folder without `evals/`, so neither the prompt nor the files it can open mention scoring. Don't ask it to list which rules or steps of the skill it applied — grade that from the artifact's shape, not from a self-report.
