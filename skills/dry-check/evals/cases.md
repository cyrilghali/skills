# dry-check eval cases

Each case gives a generation agent everything it needs WITHOUT asking questions.
The agent applies `SKILL.md` and returns only the artifact: the report it would show, plus the gate record text it would write. A judge scores it against `rubric.md`.
Each case's Context stands for what the skill's script printed when it ran on the user's branch: treat it as that run's output, as the user would paste it.
The `Trap` field names the failure mode the case is designed to catch.

## Case 1 — Copied function in an Elixir branch

**Source:** real use (a Phoenix branch that added a changeset helper by pasting an existing one)
**Input:** "Check my branch for copy-paste before I open the PR. It is an Elixir/Phoenix repo, base is origin/staging."
**Context (pre-answered):** The user already ran the skill's script on the committed branch, it exited 0, and they paste what its output showed: The branch adds `MyApp.Billing.Export.format_rows/1` (14 lines, mass 61) to an already-changed file. Its body equals `MyApp.Reports.Table.format_rows/1` in another file, character for character. Credo reports the pair twice, once per side. The same changed file also holds an older duplicate pair (`parse_header/1` twice) that the branch did not touch.
**Trap:** listing the pair twice (one row per Credo issue), reporting the older `parse_header/1` pair because its file is in the diff, or giving the fix as "extract a function" without naming a module both sides can reach.

## Case 2 — A short similar helper

**Source:** synthetic
**Input:** "dry check on this branch, TypeScript repo, base main."
**Context (pre-answered):** The user already ran the skill's script on the committed branch, it exited 0, and they paste what its output showed: The branch adds a 4-line `toLabel(user)` that looks like an existing `toLabel(team)`. Dryer scores the pair 0.95 but both spans are 4 lines. Defaults apply.
**Trap:** reporting the 4-line pair, or lowering the minimum line count to make the report non-empty.

## Case 3 — Nothing to report

**Source:** synthetic
**Input:** "Run the duplication check on my branch (Elixir, base origin/main)."
**Context (pre-answered):** The user already ran the skill's script on the committed branch, it exited 0, and they paste what its output showed: The branch touches only test files and one config file. The tree holds forty old duplicate pairs in `lib/`. None of them touches an added line.
**Trap:** passing a path to Credo (which returns zero for a whole-tree check and so looks like success for the wrong reason), or listing the forty old pairs. The honest report is an empty table with `new=0`, and the gate record still gets written.

## Case 4 — Renamed locals in TypeScript, committed work, repo must stay clean

**Source:** real use (a service module copied between two API modules, locals renamed)
**Input:** "I committed everything on this branch already. Find near-duplicates against base main in the TS repo and tell me how to remove them."
**Context (pre-answered):** The user already ran the skill's script on the committed branch, it exited 0, and they paste what its output showed: `src/orders/refund.ts` (added on the branch) holds an 18-line function that matches `src/payments/credit.ts:40-58` with different local names; dryer scores it 0.93. The working tree is clean. The repo has no `.metrics/` folder.
**Trap:** running dryer with `--changed` (it reads uncommitted work and finds nothing here), pointing it at the changed files only (the old side is never compared), or leaving `.metrics/` in the repo. A score under 1.0 must be reported as a score, not rounded to an exact match.

## Case 5 — Request from inside the project, other language

**Source:** synthetic, different codebase
**Input:** "check the tests and code quality of this branch" in a Python repo with a `src/` tree and a `tests/` tree, base origin/develop.
**Context (pre-answered):** The user already ran the skill's script on the committed branch, it exited 0, and they paste what its output showed: The branch adds `src/ingest/csv_loader.py`, which repeats a 12-line loop from `src/ingest/json_loader.py` (score 0.91). `crap-check` and `mutation-test` skills exist next to this one.
**Trap:** running only the duplication check and calling the branch checked, or treating the old file `json_loader.py` as the one to fix instead of proposing a shared helper both loaders import.
