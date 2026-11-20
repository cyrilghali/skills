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

## For a failure: a red command before any theory

When the task is a failure (an error, a wrong output, a slowdown, a flaky test) and you can run code, get one command that goes red on it before you read code to build a theory.

- The command drives the real code path and asserts the reported symptom itself, not "it ran". It gives the same verdict every run, finishes in seconds, and runs unattended. Try the cheapest seam first: a failing test, a script or curl against the running app, a CLI call on a fixture input, a replayed captured input, a throwaway harness.
- For a failure that comes and goes, loop the trigger and count the failure rate. Make the verdict repeatable where you can: pin the clock, seed random numbers, isolate the filesystem, freeze the network. Otherwise raise the failure rate until it is high enough to debug.
- Shrink the repro: cut inputs, steps and config one at a time, rerunning after each cut, until removing any one part makes it pass.
- Done when you have run the command, watched it fail on the reported symptom, and kept the command and its output for the report.
- When no such command can be built, stop and say so: what you tried, and the access or artifact that would let you (an environment that shows the failure, a redacted log or captured request). When the evidence came to you as text with nothing to run, reason from it and say that nothing was run. Never present output you did not produce.

## Hypotheses and probes

- While the cause is open, rank at least two hypotheses by evidence, using `references/evidence-tiers.md` to grade each claim, incidental ones included. List only what the evidence leaves open. Each states the prediction that would prove it wrong: "if X is the cause, changing Y makes the failure go away". Test the cheapest one first, changing one thing at a time.
- Temporary debug logs are allowed while investigating. Give each one a unique tag, such as `[DEBUG-a4f2]`. Before reporting, grep the tag to prove they are gone, confirm the code is back to its starting state, and rerun the repro command.

## Explaining code and choices

- For an architecture or placement question ("how does X work", "which layer owns this"), structure the answer as: what it is, the key abstractions, the flow step by step, where the code lives, and any gotcha. Read the code yourself; don't guess from names. Say what the code does; a reason no source records is a guess and reads as one. Fit the answer's length and structure to the size of what was asked. When the subsystem spans several directories or services, give each area its own read-only explorer subagent, all in parallel, then check yourself the claim the answer rests on.
- For "why did you do X and not Y" about your own work, name what each option gives up. Include the gap your chosen option still leaves: walk its failure path step by step and say where it breaks. Back each side with a `file:line` or a run. Push the fact the choice rests on down the proof ladder.

## Stop and report

- Do not edit product code, beyond tagged debug logs, until one credible mechanism explains the evidence.
- Stop exploring when the evidence is enough to name the cause or the exact blocker.

Report the cause and its proof: the repro command and its output, the smallest input that still fails, the hypothesis that held, and `file:line` citations. Propose no fix and no plan unless the task asks for one.

Sources: the evidence tiers and the architecture-question structure adapt the `why` and `how` skills from pstack by poteto (MIT). The red-command gate, the shrinking step, falsifiable hypotheses and tagged debug logs adapt `diagnosing-bugs` from github.com/mattpocock/skills (MIT).

Originally from github.com/JuliusBrussee/caveman (forked 25/09/2026; no longer tracked upstream).
