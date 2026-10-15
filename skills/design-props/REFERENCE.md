# design-props reference

## Shared template

Every philosophy fills these sections in this order. A section that does not apply says why in one line, so the gap is visible in the comparison.

| Section | What it holds |
|---|---|
| Caller sketch | The call site first: how a caller uses the design, in a few lines of real code. |
| Public signatures | The functions, endpoints or messages the sketch implies, with their types. |
| State or data model | Tables with DDL when the design persists data; otherwise the state shape and where it lives (memory, local storage, server). |
| Write paths | Every place that changes the state, and what each write costs. |
| Coverage | Each requirement in turn: how this philosophy meets it, and the Phase 0 verdict it changes, if any. |
| Use per audience | What each consumer (product screen, API client, analyst, operator) reads and how. |
| Extensibility | Each roadmap item: native, simple extension, or rewrite. |
| Migration | From today's system to this one: steps, backfill, reversibility. |
| Costs | Order of magnitude: person-days, volumes, cost per month. |
| Accepted limits | Added in Phase 2: what this philosophy will never do well. |

## Critique lenses

Each lens tries to refute the proposal, not to improve it.

| Lens | Question it asks |
|---|---|
| Codebase reality | Do the cited files, tables and APIs say what the proposal claims? Open them. |
| Product extensibility | Does the roadmap break this design, item by item? |
| Correctness and performance | In the design's own terms. Data design: are point-in-time denominators approximated quietly, are volumes and query costs real? Client or runtime design: what happens under concurrency, offline, restart, or a conflicting write? |
| Interface depth | Only when the proposal exposes an API. Does the caller sketch stay short while the module hides the complexity? |
