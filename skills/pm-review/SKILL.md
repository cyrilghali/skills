---
name: pm-review
description: Review a batch of Linear issues for completeness, consistency, and alignment with project goals. Flags missing fields, unclear acceptance criteria, and scope creep. Triggers on "review issues", "PM review", "audit tickets", "check my Linear issues", "issue quality check".
disable-model-invocation: true
argument-hint: "[project or team slug] [filter]"
allowed-tools: Read, Grep, Glob
---

# PM Review

Review Linear issues in batch for quality, completeness, and consistency. Surface problems before they hit the sprint.

## Arguments

- **No args:** prompt for a project or team to review.
- **Project/team slug:** review all open issues in that project or team.
- **Filter:** optional filter like `cycle:current`, `priority:urgent`, `label:needs-review`.

## Phase 1: Fetch Issues

1. Determine scope from arguments.
2. Fetch issues via Linear MCP:
   - `list_issues` with appropriate filters (project, team, state = active/backlog/in-progress)
   - For each issue, `get_issue` to fetch full details including description, comments, sub-issues
3. If more than 50 issues, ask the user to narrow the filter.

## Phase 2: Quality Checks

For each issue, evaluate against these criteria:

### Required Fields

| Check | Condition | Severity |
|-------|-----------|----------|
| **Title clarity** | Title is actionable and specific (not "Fix bug" or "Update thing") | warning |
| **Description present** | Description is non-empty and longer than one sentence | error |
| **Acceptance criteria** | Description contains a "Done when", "Acceptance criteria", or checklist section | error |
| **Priority set** | Priority is not "No priority" | warning |
| **Estimate present** | Story points or estimate is set | info |
| **Assignee set** | Has at least one assignee | info |
| **Labels present** | Has at least one label | info |

### Consistency Checks

| Check | Condition | Severity |
|-------|-----------|----------|
| **Scope creep** | Description mentions 3+ distinct features or has "also" / "and while we're at it" patterns | warning |
| **Duplicate detection** | Title or description is very similar to another open issue | warning |
| **Blocked but active** | Status is "In Progress" but has a blocking relation that is unresolved | error |
| **Stale in progress** | Status is "In Progress" but no activity in 7+ days | warning |
| **Missing parent** | Sub-issue without a parent issue or project | info |

## Phase 3: Report

Print a summary grouped by severity:

```
## PM Review: <project/team>

### Summary
X issues reviewed
Errors: A | Warnings: B | Info: C

### Errors
- **PROJ-123** "Fix auth flow" — No acceptance criteria in description
- **PROJ-145** "Update API" — In Progress but blocked by PROJ-140

### Warnings
- **PROJ-128** "Refactor and add caching and update docs" — Scope creep: 3 distinct concerns
- **PROJ-130** "Fix bug" — Title is not specific enough

### Info
- **PROJ-135** "Add telemetry" — No estimate set
- 12 issues have no labels

### Stats
- Average description length: X words
- Issues with acceptance criteria: Y/Z (A%)
- Priority distribution: N urgent, N high, N medium, N low, N unset
```

## Phase 4: Interactive Fixes

After the report, ask: "Want me to fix any of these?"

For fixable issues (via Linear MCP `save_issue`):
- **Missing priority:** propose a priority based on context
- **Vague title:** propose a rewritten title
- **Scope creep:** propose splitting into multiple issues
- **Missing acceptance criteria:** draft acceptance criteria from the description

Show each proposed change for approval before applying.

**Done when:** Report is printed and fixes are applied or declined.
