---
name: investigate-first
description: Diagnose ambiguous failures before editing, explain how a subsystem works, or answer placement/ownership questions before changing it. Use for unknown causes, intermittent behavior, performance regressions, "restate this issue", "how does X work", "why was this built this way", "why did you do X and not Y", "where should this live", or investigations needing evidence-ranked hypotheses.
metadata:
  category: build
---

# Investigate first

Gather evidence before changing product code.

- Restate the problem first, in your own plain words: the observed symptom, who sees it, and what fixed looks like. Name each cause someone in the report guessed, and weigh it against the evidence as a guess, not a finding. When the request asks only for the restatement, end there: no fix, no next step.
- Trace inputs, state transitions, ownership boundaries, and failure output.
- Reproduce the failure yourself on the real surface (running app, test, curl) before asking the user to. Ask only with a stated, specific reason the surface can't reach the target, and only after driving it as far as it goes.
- Rank hypotheses by evidence, using `references/evidence-tiers.md` to grade each claim, incidental ones included, and pick the cheapest step that would falsify it.
- For an architecture or placement question ("how does X work", "which layer owns this"), structure the answer as: what it is, the key abstractions, the flow step by step, where the code lives, and any gotcha. Read the code yourself; don't guess from names. Say what the code does; a reason no source records is a guess and reads as one. Fit the answer's length and structure to the size of what was asked. When the subsystem spans several directories or services, give each area its own read-only explorer subagent, all in parallel, then check yourself the claim the answer rests on.
- For "why did you do X and not Y" about your own work, name what each option gives up. Include the gap your chosen option still leaves: walk its failure path step by step and say where it breaks. Back each side with a `file:line` or a run. Push the fact the choice rests on down the proof ladder.
- Do not edit until one credible mechanism explains evidence.
- Stop exploration when evidence is sufficient to name cause or exact blocker.

Report cause and proof, citing file:line. Propose no fix and no plan unless the task asks for one.

Sources: the evidence tiers and the architecture-question structure adapt the `why` and `how` skills from pstack by poteto (MIT).

Originally from github.com/JuliusBrussee/caveman (forked 25/09/2026; no longer tracked upstream).
