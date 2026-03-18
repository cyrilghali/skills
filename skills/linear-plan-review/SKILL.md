---
name: linear-plan-review
description: Transform an implementation plan into a 3-part digest — Product Specs, Tech Specs, and Execution DAG — for team review. Saves locally for validation, then optionally publishes to Linear. Triggers on "review plan", "plan digest", "plan to specs", "create plan review", "prepare plan for review", "publish plan".
disable-model-invocation: true
argument-hint: "<plan-file-path>"
allowed-tools: Read, Grep, Glob, Write
---

# Linear Plan Review

Transform an implementation plan into a structured 3-part digest for team review. Save locally first for validation, then publish to Linear as a document.

## Arguments

- **Plan file path** (required): path to an implementation plan. Can be any format — markdown, text, or structured document.

## Phase 1: Read and Analyze Plan

1. Read the plan file completely.
2. Identify the key components:
   - **Goals and requirements** — what the plan aims to achieve
   - **Technical decisions** — architecture, tech choices, trade-offs
   - **Implementation steps** — ordered work items with dependencies
   - **Open questions** — unresolved decisions or risks
3. Note any gaps: missing acceptance criteria, unclear ownership, undefined scope boundaries.

## Phase 2: Generate the 3-Part Digest

Transform the plan into three distinct sections:

### Part 1: Product Specs

Extract and organize the user-facing perspective:

```markdown
## Product Specs

### Goal
One sentence: what user problem does this solve.

### Requirements
- Functional requirements (what it does)
- Non-functional requirements (performance, security, accessibility)

### User Stories
- As a <role>, I want <action>, so that <benefit>

### Acceptance Criteria
- [ ] Testable conditions that define "done"

### Out of Scope
- Explicitly excluded items
```

### Part 2: Tech Specs

Extract and organize the engineering perspective:

```markdown
## Tech Specs

### Architecture
High-level design: components, data flow, integrations.

### Key Decisions
| Decision | Choice | Rationale | Alternatives Considered |
|----------|--------|-----------|------------------------|

### API Changes
New or modified endpoints, schemas, contracts.

### Data Model Changes
New tables, columns, migrations.

### Dependencies
External services, libraries, infrastructure changes.

### Risks and Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
```

### Part 3: Execution DAG

Extract and organize the implementation sequence:

```markdown
## Execution DAG

### Phases
Visual representation of the execution order:

Phase 1 (parallel): [Task A] [Task B]
         ↓              ↓
Phase 2 (parallel): [Task C] [Task D]
         ↓
Phase 3:            [Task E]

### Task Breakdown
| Phase | Task | Owner | Estimate | Depends On | Deliverable |
|-------|------|-------|----------|------------|-------------|

### Critical Path
Longest dependency chain: Task A → Task C → Task E (~X days)

### Open Questions
- [ ] Unresolved items that block execution
```

## Phase 3: Save Locally

Write the digest to a local file for review:

- Default path: `plan-review-YYYY-MM-DD.md` in the current directory
- Combine all three parts into one document with a header:

```markdown
# Plan Review: <plan title>
Generated: YYYY-MM-DD
Source: <original plan path>

---

<Part 1: Product Specs>

---

<Part 2: Tech Specs>

---

<Part 3: Execution DAG>
```

Tell the user: "Digest saved to <path>. Review it, then say 'publish' to send to Linear."

## Phase 4: Publish to Linear (Optional)

When the user says "publish" or "send to Linear":

1. Confirm which Linear project or team to publish to.
2. Create a Linear document via `create_document`:
   - Title: `Plan Review: <plan title>`
   - Content: the full 3-part digest
3. Optionally create a companion issue for tracking review:
   - Title: `Review: <plan title>`
   - Description: link to the document, list of reviewers, deadline
   - Status: "In Review" or equivalent
4. Report the document URL and issue ID.

**Done when:** The 3-part digest is saved locally and optionally published to Linear.
