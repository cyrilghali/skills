---
name: scan-code-quality
description: >-
  Scans a codebase for structural quality issues (architecture incoherence,
  design-principle violations, dead code, excessive complexity, unclear naming, hidden
  state, comment and lint-suppression rot) and produces an evidence-backed, severity-ranked report with concrete,
  non-breaking refactor suggestions. Runs each review aspect as its own reviewer (the
  find phase, on a capable model) and verifies and ranks every finding with a separate
  checker (the check phase, on a cheaper one); both are overridable via --find-model and
  --check-model. Use whenever the user asks for a code review, code audit, code quality
  assessment, tech-debt analysis, refactoring preparation, code-smell detection,
  maintainability review, or architecture review — including casual phrasings like "look
  over my repo", "where's the worst code in this codebase", "is this code any good",
  "what should I clean up first", "review this for code smells", or "check this module
  before I ship it". Applies to any language or framework.
metadata:
  category: verify
---

# Scan code quality

Act as the **orchestrator** of a senior code-review team. You don't read every file yourself — you scope the work, fan it out to specialist reviewers (one per quality aspect), then route their findings through a cheaper checker that verifies and ranks each one. You assemble the survivors into a single evidence-backed report.

Splitting the review this way keeps each reviewer focused on one lens, runs the lenses in parallel, and spends the expensive model only on *finding*; verifying a concrete claim and scoring its priority is well within a small, fast model's reach.

**Parallelism is an optimisation, not a requirement.** If this agent can dispatch sub-agents, give each reviewer and each checker its own. If it cannot, work the same list yourself — one category at a time, writing each category's findings to a file before starting the next, then a separate verification pass over the collected findings. Never drop a category, and never merge the find and check passes into one read: the check exists to be an independent look at the cited code.

## When to use

- Code review or quality audit
- Tech debt assessment or refactoring preparation
- Onboarding review to understand codebase health
- Code smell detection before a release

## Options

Read these from the invocation (e.g. `--find-model <mid-tier> --check-model <cheap> --depth thorough src/`). If absent, use the default and state the resolved value at the top of the report.

| Option | Default | Meaning |
| --- | --- | --- |
| `--find-model` | mid-tier: a strong general model, not the largest one available | Model for the per-aspect reviewers (the find phase). |
| `--check-model` | cheapest: the smallest, fastest model available | Model for the verification and ranking pass (the check phase). |
| `--depth` | `thorough` | `quick` = top findings only, one checker batch; `thorough` = full catalog, per-finding verification. |
| `--focus` | all categories | Comma-separated subset of the detection categories below — only those reviewers run. |
| target paths | repo root | Positional args: directories/files to scan. |
| `--exclude` | vendor, generated, build outputs, lockfiles | Paths to skip. |

Model values pass through verbatim to whatever model selector this agent exposes. If it exposes none, ignore both flags and say so in the report's config line; the phases still run, just on one model. The orchestrator itself always runs on the session model. Tiers matter more than names: finding needs reasoning, checking a concrete claim against cited code does not — don't send both to the same large model.

The full orchestrator architecture diagram is in [reference.md](reference.md) Part 3.

## Workflow

1. **Scope.** Resolve target paths; identify languages, frameworks, layering, and project conventions from config files and directory layout. Apply exclusions. Capture this once as a short **context brief** (languages, frameworks, target paths, exclusions, notable layering) — hand the same brief to every find subagent so none has to re-derive it.

2. **Find phase — dispatch one reviewer subagent per in-scope category, all in a single parallel batch**, each with `model = --find-model`. Give each subagent: the context brief, the name of its single category, instructions to read *only its own section* of [reference.md](reference.md) for the detection signals/thresholds/recipes, and the **find output contract** in reference.md Part 3's find prompt template. A reviewer that goes wide and shallow defeats the purpose — each one owns exactly one lens.

3. **Collect.** Gather every reviewer's JSON output, concatenate, and assign each finding a stable `id` (e.g. `arch-1`, `complexity-3`). Drop exact duplicates (same location + pattern).

4. **Check phase — verify and rank every finding** with `model = --check-model`. Dispatch checker subagents in parallel using the check prompt template in [reference.md](reference.md) Part 3. Each checker independently re-reads the cited code, applies the counter-signals, adjusts severity, and assigns a 0–100 priority score. In `thorough` depth give each finding (or a small batch) its own checker; in `quick` depth batch all findings of a category into one checker. Discard `refuted` findings (surface them in "considered but not flagged"); keep `confirmed` and flag `uncertain`.

5. **Report.** Sort surviving findings by `priority_score` descending (ties broken by severity). Use the report template in [reference.md](reference.md) Part 3. Lead with the resolved config (target, depth, focus, find-model, check-model) so the run is reproducible. Each detailed finding uses 7 fields: category, pattern, location, evidence, impact, refactor direction, severity & priority.

## Detection Categories

Priority order; pass exactly one to each find subagent. Detection signals, thresholds, and refactor recipes for each are in [reference.md](reference.md) Part 1 — each find subagent reads only its matching section, not the whole catalog.

1. Architecture coherence
2. Design principle adherence
3. Dead code and unused artifacts
4. Appropriate complexity
5. Code clarity
6. State management
7. Comment and suppression discipline

The severity rubric (High/Medium/Low criteria) both phases apply is in [reference.md](reference.md) Part 3.

## Constraints

- **Evidence required.** Findings without concrete evidence (file, symbol, metric, construct) are dropped — first by the reviewer, then again by the checker. Unsubstantiated flags erode trust.
- **Verification is independent.** The checker must re-read the cited code rather than trust the reviewer's claim; that second look is the whole point of the check phase and the reason it can run on a smaller model.
- **Respect existing conventions.** Match the project's naming, layering, and idioms in refactor suggestions — imposed style changes create friction.
- **Non-breaking refactors only.** Each refactor direction must preserve current behavior. Flag sweeping rewrites as a separate, explicit recommendation rather than embedding them as a "refactor direction".

Bibliography (Clean Code, Refactoring, AHA Programming, McCabe complexity, and others) is in [reference.md](reference.md).

Sources: the comment-and-suppression category adapts the `no-comments` skill and `Comment Sicko` agent; the check-phase filtering judgment adapts the `interrogate` skill's lead-judgment framework and code-quality lens; both from pstack by poteto (github.com/cursor/plugins/tree/main/pstack, MIT, Lauren Tan).

Originally from github.com/Ephasme/agent-skills (forked 25/09/2026; no longer tracked upstream).
