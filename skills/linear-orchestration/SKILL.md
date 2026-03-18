---
name: linear-orchestration
description: Convert a reviewed implementation plan into Linear tickets with blocking dependencies and team assignments. Reads the plan's execution DAG, proposes tickets, and creates them after explicit approval. Triggers on "create tickets from plan", "orchestrate plan", "plan to Linear", "convert plan to tickets", "create Linear issues from plan".
disable-model-invocation: true
argument-hint: "<plan-file-path>"
allowed-tools: Read, Grep, Glob
---

# Linear Orchestration

Convert an implementation plan into a set of Linear tickets with proper dependencies, assignments, and execution order.

## Arguments

- **Plan file path** (required): path to an implementation plan document. Supports any structured plan with an execution section (DAG, phases, ordered steps).

## Phase 1: Parse Plan

1. Read the plan file.
2. Extract the execution structure. Look for:
   - **Execution DAG:** nodes with dependencies (e.g., "Step B depends on Step A")
   - **Phases/stages:** sequential groups of parallel tasks
   - **Ordered steps:** numbered or bulleted sequences
3. For each task/step, extract:
   - **Title:** short name of the work item
   - **Description:** what needs to be done, any specs or constraints
   - **Dependencies:** which other tasks must complete first
   - **Team/assignee hints:** if the plan mentions who should do what
   - **Estimate hints:** if the plan mentions time or complexity
4. Build an internal dependency graph. Validate:
   - No circular dependencies
   - All dependency references resolve to real tasks
   - Leaf nodes (no dependents) are identified as final deliverables

## Phase 2: Propose Tickets

Present the proposed ticket set as a table:

```
## Proposed Tickets

### Phase 1 — Foundation (parallel)
| # | Title | Description | Depends On | Team | Estimate |
|---|-------|-------------|------------|------|----------|
| 1 | Set up database schema | Create tables for auth module | — | Backend | M |
| 2 | Configure CI pipeline | Add test + lint stages | — | Platform | S |

### Phase 2 — Core (after Phase 1)
| # | Title | Description | Depends On | Team | Estimate |
|---|-------|-------------|------------|------|----------|
| 3 | Implement auth API | REST endpoints for login/signup | 1 | Backend | L |
| 4 | Build auth UI | Login and signup forms | 1 | Frontend | L |

### Phase 3 — Integration (after Phase 2)
| # | Title | Description | Depends On | Team | Estimate |
|---|-------|-------------|------------|------|----------|
| 5 | E2E auth tests | Full flow tests | 3, 4 | QA | M |

Total: 5 tickets across 3 phases
Critical path: 1 → 3 → 5
```

Ask: "Does this look right? Adjust any tickets before creating?"

Accept edits: the user can add, remove, rename, re-order, change assignments, or modify dependencies. Re-display the table after changes.

## Phase 3: Configure Destination

Before creating, confirm:

1. **Project:** which Linear project to create issues in. List available projects via `list_projects` and let the user pick.
2. **Team:** which Linear team. List via `list_teams` if not specified in the plan.
3. **Labels:** propose labels based on plan content (e.g., `backend`, `frontend`, `infra`). Verify they exist via `list_issue_labels`.
4. **Parent issue:** optionally nest all tickets under a parent epic/issue.

## Phase 4: Create Tickets

**Only proceed after explicit user approval.**

For each ticket in dependency order (leaves first):

1. Create the issue via Linear MCP `save_issue`:
   - Set title, description, team, project, labels, estimate, priority
2. Once created, record the issue ID.
3. Add blocking relations: for each dependency, create a relation between the blocker and the blocked issue.
4. If a parent issue was specified, set the parent relation.

Report progress as tickets are created:

```
Created 5/5 tickets:
- PROJ-201: Set up database schema
- PROJ-202: Configure CI pipeline
- PROJ-203: Implement auth API (blocked by PROJ-201)
- PROJ-204: Build auth UI (blocked by PROJ-201)
- PROJ-205: E2E auth tests (blocked by PROJ-203, PROJ-204)
```

## Phase 5: Summary

Print a final summary:

```
## Orchestration Complete

5 tickets created in project <name>
3 phases | Critical path: PROJ-201 → PROJ-203 → PROJ-205
All blocking relations set.

View in Linear: <project URL>
```

**Done when:** All tickets are created with dependencies, and the summary with Linear links is printed.
