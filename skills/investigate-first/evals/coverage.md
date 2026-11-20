# Coverage of the diagnosing-bugs ideas

Source: `skills/engineering/diagnosing-bugs/SKILL.md` in github.com/mattpocock/skills (MIT), read in full. Cross-check: `systematic-debugging` in obra/superpowers. No idea came from the cross-check, so it is not credited in Sources.

| Idea | Disposition | Where or why |
|---|---|---|
| Redact secrets in shown output | Adopted | Report line |
| Read the glossary and ADRs | Cut | Not every repo has them; when one does, an ADR is an explicit source and the Direct tier already accepts it |
| A repro command already run, shown with its output | Adopted | Repro section, report line |
| Ordered list of seams | Adopted in part, counted as adopted | Five seams plus bisection; the headless-browser script, fuzz loop, differential loop and human-in-the-loop script are cut to keep the list short, since the agent picks the cheapest seam first |
| Tighten the loop: fast, sharp, deterministic | Adopted | First repro bullet |
| Raise the failure rate for intermittent failures | Adopted | Second repro bullet |
| Stop and ask for an artifact when no loop exists | Adopted | Last repro bullet |
| The repro shows the user's own symptom | Adopted | "fails on the user's own symptom" |
| Shrink until every part is load-bearing | Adopted | Shrink bullet |
| Three to five falsifiable hypotheses | Adopted, changed | "At least two"; a fixed count padded short answers in the evals |
| Show the ranked list to the user | Cut | The skill reports once, at the end, and the ranked list goes in that report |
| Each probe maps to a prediction, one variable at a time | Adopted | Hypotheses bullet |
| Debugger before logs | Adopted, changed | A one-off call that prints the value, which an agent can run without a terminal session |
| Tagged debug logs | Adopted | Debug-log bullet |
| Performance: baseline, then bisect | Adopted | First repro bullet |
| Missing regression-test seam is a finding | Cut | The skill proposes no fix, so it writes no regression test |
| Cleanup: rerun, grep the tag, delete prototypes, state the hypothesis that held | Adopted | Debug-log bullet, report line |
| Read the error carefully (superpowers) | Already present | "Trace ... failure output" |
| Check recent changes (superpowers) | Cut | No eval showed the agent skipping history |
| Diff against a working example (superpowers) | Cut | No eval needs it; adds a step to every failure |
| Trace data flow across components (superpowers) | Already present | "trace inputs, state transitions, ownership boundaries", now after the repro fails |
| No-root-cause outcome that records what was tried (superpowers) | Already present | "stop and say so: what you tried" |

Coverage: 17 of 22 adopted or already present (77%), counting the partial seams row as adopted.

These ideas were added after the eval runs and have no eval yet: redaction, bisection and baseline timing, debugger before logs, deleting throwaway scripts, the done state on the failure-rate step, and the round-4 flaky-failure lines (green means zero failures over the same loop; the report carries the failure rate). The hypothesis done state ran in the round-2 reruns (see `baseline.md`).
