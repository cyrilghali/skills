# skill-telemetry baseline

Each case ran once with no skill loaded (the agent knew only the convention "one JSON line per run in `$SKILL_TELEMETRY_DIR/runs.jsonl`") and once with `SKILL.md` and its siblings, evals excluded. Two judges scored every artifact independently against `rubric.md`; their verdicts agreed on all ten.

| Case | No skill (judge 1 / judge 2) | With skill (judge 1 / judge 2) |
|---|---|---|
| 1 Record a value with a quote and a space | 13 FAIL / 13 FAIL: repo, pr, session missing; `10/12` not split; invented field name | 18 PASS / 18 PASS |
| 2 Report on an empty log | 18 PASS / 18 PASS | 18 PASS / 18 PASS |
| 3 Add telemetry to a skill's last step | 17 PASS / 17 PASS: told the skill to skip when the variable is unset | 18 PASS / 18 PASS |
| 4 Read a trend | 16 PASS / 17 PASS: raw value lists instead of the report block; miscounted the other skill's rows | 18 PASS / 18 PASS |
| 5 Variable unset | 15 FAIL / 14 FAIL: chose its own default folder; moved into the user's real checkout for git context; invented field name | 18 PASS / 18 PASS |

What the skill closes: the record format (base fields, ratio split, registry names), the default folder, and the report block. Cases 2, 3 and 4 pass without the skill, so they show no uplift on their own. They stay as regression guards for the scripts. Harder cases from real use should replace them once the first eligible skills record runs.

Both judges noted that the with-skill agent on case 1 stored a value derived from the others (`cosmetic_survivors=1` from 12-10-1); step 4 of `SKILL.md` was tightened afterwards to leave a metric out rather than derive it.

Not run in this pass: three generations per case, the held-out refinement loop, the leak audit by a fresh agent, and the `triggers.md` queries through headless sessions.
