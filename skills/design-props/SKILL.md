---
name: design-props
description: Produces N compared technical design proposals grounded in the real code, with imposed philosophies, adversarial critique, a comparison matrix and a phased trajectory. Use when the user asks for "plusieurs propositions de design", "compare des approches/architectures", multiple technical design propositions, a comparative architecture study, or an explicit N-approaches comparison. Not for a single design spec or direct recommendation.
metadata:
  category: plan
---

# Compared design proposals

Make the decision almost mechanical. The reader must see the real choice, what each option costs, and what each option mortgages.

## Check feasibility before any design

1. Map the real system: the data model and its migrations if any, the existing APIs, the runtime and platform constraints, and the write points (seams), each with file:line. Delegate the mapping to read-only exploration subagents (Explore type), but verify the structuring assumption yourself, because an error in it would invalidate every proposal. A typical one is "is this table overwritten on every cycle, or reconciled by diff?"
2. Cross each product requirement with what the real system provides (persisted data, existing APIs, runtime or platform constraints). Give each one a verdict with its reason: 🟢 feasible, 🟠 degraded, 🔴 impossible.
3. Look for the argument that settles it. A future product requirement that makes a migration mandatory anyway turns the question from "whether" into "when".

## Design N distinct philosophies

- Derive the comparison grid before you launch the authors: 3-6 concrete, scorable criteria (for example sprint 1 cost, migration risk, coverage of requirement X). They feed the synthesis matrix directly. Without a grid set in advance, each author optimizes for their own criteria and the final comparison gets rewritten after the fact.
- Impose 3-5 philosophies (for example pure event log, stateful entity, hybrid, pre-aggregated). Include the minimal contender "change nothing on the write paths", because it forces the others to be honest.
- Give each author (an agent) one philosophy to push to its best. Forbid drifting toward the others, because the comparison happens elsewhere.
- Spread the authors over different models, and over another model family when a CLI allows it (for example `codex exec`), because agreement between models weighs more than agreement between copies of the same one.
- Impose one common template, filled in section by section for each philosophy, because proposals without a common template cannot be compared. The template's sections, in order:
  1. a usage sketch from the caller's side, then the public signatures that follow from it;
  2. the data model, with DDL when the design persists data;
  3. the write paths;
  4. coverage, requirement by requirement;
  5. usage per audience;
  6. extensibility;
  7. migration;
  8. costs as orders of magnitude: person-days, volumes, euros per month.
- Score extensibility point by point against the real product roadmap, one verdict per axis (native, simple extension, or rework), never as a vague score.
- When an author produces nothing usable, continue with N-1 and note the drop in the synthesis instead of relaunching the whole phase.

## Critique each proposal adversarially, then let its author revise

- Run 3 lenses per proposal, each trying to refute it:
  1. codebase reality, by opening the cited files;
  2. product extensibility, by asking whether the roadmap breaks the design;
  3. correctness and performance in the design's own terms: queries and volumes for a data design (such as point-in-time denominators quietly approximated), latency, concurrency or runtime cost otherwise.

  When the proposal exposes an API, add a 4th lens, interface depth, which checks that the call sketch stays short while the module hides the complexity.
- Have the author revise: fix the founded critiques, dismiss the unfounded ones with a stated reason, and add an "Accepted limits" section listing what their philosophy will never solve well.
- Borrow between philosophies, mechanism by mechanism. After revision, each author reads the competing proposals once and notes whether one precise mechanism (never the whole philosophy) deserves borrowing, for example "borrowed from philosophy C: its idempotency key on writes". A borrow does not make the philosophies converge: each stays distinct and is still compared on substance in the synthesis. When N philosophies converge on the same mechanism without coordination, write it down, because it is a robust decision whatever the final choice.

## Synthesize

- Build the comparison matrix (coverage, sprint 1 cost, roadmap, migration risk, reversibility) on the criteria grid set before the authors started.
- Write the cross-reading. Say where the proposals converge, because those are robust decisions whatever the choice (for example "all of them instrument the same seams"). Name the real choice: the options that truly compete, in the number the matrix supports, and why the others are complements or extensions, if there are any. Say whether one option leaves the others open, or whether none does.
- Get an independent reading before naming the real choice. Have an agent that took no part in the design and critique phases, on a different model from the authors, reread the matrix and the revised proposals with one instruction only: name the real choice and its reason. Agreement with your own reading confirms the choice. Disagreement is never settled in silence: it becomes one of the open questions handed to the reader.
- Settle any open question that a run can answer (latency, behavior, output) with a throwaway prototype (the `prototype` skill, empirical branch) before writing it down. Leave only product or preference questions to the reader.
- End with a phased trajectory with explicit switch triggers, then the decisions to take, written as questions.

## Implement against the chosen sketch, when implementation follows

- Replace the bodies of the chosen sketch with the real logic without changing the signatures in silence. Report an unplanned parameter or state as a deviation from the sketch.
- Treat the design as wrong when the same workaround shows up in unrelated calls, or when the types demand escape hatches (`any`, forced casts). Then throw the implementation away and go back to designing the philosophies with that finding, rather than patching.

## Learn from the reference study

One complete study validated the method on an analytics project with four philosophies (pure event log, stateful entity, hybrid, pre-aggregated rollups). Its narrative deliverable and per-philosophy specs are kept locally, outside this skill folder.

## Avoid these workflow pitfalls

- Make every agent Write its deliverable to a file and return a short synthesis in its reply. The long deliverable goes in the file, because an agent that pastes it into its reply dies on the output limit (32k tokens).
- Use the Workflow tool's journals (`journal.jsonl`, resume via `resumeFromRunId`) as checkpoints, so finished agents are never paid for twice. Also snapshot the deliverables to a durable folder in the home directory after each phase, because session scratchpads can be purged.
- Write the final delivered document with the `doc-pedagogique` skill.

Sources : l'emprunt ciblé entre philosophies et la lecture indépendante du
« vrai choix » adaptent la skill `arena` de pstack par poteto ; l'esquisse
d'appel, les auteurs multi-modèles et la Phase 4 adaptent sa skill `architect`
(github.com/cursor/plugins/tree/main/pstack, MIT, Lauren Tan).
