---
name: design-props
description: Produces several competing technical design proposals grounded in the real system and compares them, so the decision becomes almost mechanical. It checks each requirement against what the system really provides, imposes distinct philosophies filled into one shared template, attacks and revises each one, then names the real choice, a phased path with switch triggers and the decisions left as questions. Use when the user asks for "several design options", "compare approaches", "competing proposals", "N architectures compared", "a design study", or "lay out the alternatives before we pick". Not for a single design spec, a quick direct recommendation, settling module boundaries for one feature before coding, stress-testing a plan already chosen, reviewing a diff, or several attempts at the same code merged into one.
metadata:
  category: plan
---

# Design proposals, compared

The reader should finish seeing the real choice, what each option costs, and what each option closes off. Every phase below exists to keep the options honest and comparable.

## Phase 0: what does the system really allow?

1. **Map the real system.** Data model and migrations if any, existing APIs, runtime and platform constraints, write paths, each with `file:line` (or the fact the request states, when there is no repository). Read-only explorer subagents can gather this.
2. **Check the load-bearing assumption yourself.** It is the one fact that, if wrong, sinks every option. Check it in the code or the given facts, not in the documentation or the request's wording.
3. **Give each requirement a verdict:** feasible, degraded or impossible, with the fact behind it. A data design checks what is persisted; a client or runtime design checks what the platform keeps and what the APIs guarantee.
4. **Look for the deciding argument.** A future requirement that forces a migration anyway turns "whether" into "when".

Done when every requirement has a verdict and the load-bearing assumption is stated as checked or refuted.

## Phase 1: what distinct philosophies are worth building?

1. **Set the comparison criteria before any author starts:** three to six concrete, scorable criteria (first-sprint cost, migration risk, coverage of requirement X). Without them each author optimizes for their own and the comparison gets rewritten afterwards.
2. **Impose three to five philosophies** that differ in strategy, not in shape: for a data design, pure event log, stateful entity, hybrid, pre-aggregated rollups. Always include the minimal contender: every write path stays exactly as it is today, and it works only from what already exists. It keeps the others honest. A mix of two options is not a philosophy; it belongs in the synthesis.
3. **One author per philosophy pushes it to its best** and never drifts toward another; comparison happens later. Spread authors across different models, and another model family when a CLI allows it: agreement between models weighs more than agreement between copies.
4. **Fill the shared template** in [REFERENCE.md](REFERENCE.md), section by section, for every philosophy, in its own words. It starts from a caller sketch and the public signatures it implies; "same as A" leaves a section empty.
5. **Check extensibility against the real roadmap,** item by item, with exactly one class per cell: native, simple extension, or rewrite, and the fact behind it.
6. If an author produces nothing usable, continue with the rest and record the drop in the synthesis.

Done when every philosophy fills every template section and every roadmap item has a verdict per philosophy.

## Phase 2: what breaks each proposal?

1. **Attack each proposal through the critique lenses** in [REFERENCE.md](REFERENCE.md). Each lens tries to refute, in the design's own terms: queries and volumes for a data design; latency, concurrency or runtime cost otherwise.
2. **The author revises:** fixes the valid critiques, rejects the unfounded ones with a reason, and adds an "accepted limits" section listing what this philosophy will never do well.
3. **Borrow mechanisms, not philosophies.** Each author reads the rival proposals once and may borrow one precise mechanism ("borrowed from C: its idempotency key on writes"). When several philosophies reach the same mechanism on their own, record it: that decision holds whatever the final choice.

Done when every proposal has its revisions and its accepted limits.

## Phase 3: what is the real choice?

1. **Build the comparison matrix** on the criteria set in Phase 1.
2. **Read across:** where the proposals converge (robust decisions whatever the choice), which options truly compete and why the others are complements or extensions, and which option keeps the others open, or that none does.
3. **Get an independent reading.** An agent that took no part in Phases 1 and 2, on a different model, reads the matrix and the revised proposals and names the real choice and its reason. Agreement confirms it; disagreement becomes an open question for the reader.
4. **Settle by running what a run can settle.** An open question about latency, throughput, behavior or output gets a throwaway prototype or benchmark on a scratch branch before the synthesis is written. When no run is possible where you work, the exact protocol becomes the first step of the path, and later steps depend on its result. Only product and preference questions go to the reader.
5. **Write a phased path** with explicit switch triggers, each a measurable threshold that moves the team to the next option, then the remaining decisions as questions.

Done when the real choice is named with its reason and every open question is either measured or a product or preference question.

## Phase 4: does the implementation still match the sketch?

When implementation follows, replace the sketch's bodies with real logic without changing signatures silently: an unplanned parameter or state is reported as a departure from the sketch.

The design is wrong when the same workaround appears in unrelated callers, or when the types need escape hatches (`any`, forced casts). Then throw the implementation away and return to Phase 1 with that finding and the concept the sketch missed, rather than patching.

## Delivering

Each author and critic writes to its own file and replies with a short summary; long output pasted in a reply gets cut off. Copy deliverables to a durable folder after each phase. The final document is written for a reader who was not in the room: the real choice first, then the path, then the questions.

## Sources

The targeted borrowing between philosophies and the independent reading of the real choice adapt the `arena` skill of the pstack plugin; the caller sketch, the multi-model authors and Phase 4 adapt its `architect` skill (github.com/cursor/plugins, MIT).
