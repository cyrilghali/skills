---
name: strategy
description: Analyze a codebase or product area and decide what documentation is needed and in what priority. The "what should we document?" question. Produces a prioritized documentation plan. Triggers on "docs strategy", "what should we document", "documentation plan", "what docs are missing", "prioritize documentation".
argument-hint: "[module, feature, or directory]"
---

# Documentation Strategy

Analyze a codebase area and produce a prioritized documentation plan.

## Step 1: Scope the Area

If a module/directory was provided, explore it. Otherwise ask: "Which part of the codebase do you want a documentation strategy for?"

Explore the area:
- Read the source files to understand what exists
- Check for existing docs (guides/, docs/, README files)
- Identify public APIs, key concepts, common workflows, and configuration

## Step 2: Map What Exists vs. What's Needed

For each discoverable feature/concept/workflow, classify:

| Status | Meaning |
|--------|---------|
| **Documented** | A doc page exists and covers this |
| **Partial** | A doc exists but is incomplete or outdated |
| **Undocumented** | No doc exists — this is a gap |
| **Over-documented** | Multiple overlapping pages, needs consolidation |

## Step 3: Prioritize

Score each gap by **impact x effort**:

- **Impact**: How many people need this? How often do they get stuck without it?
  - High: onboarding blocker, frequently asked, public API
  - Medium: internal workflow, occasional need
  - Low: edge case, rarely encountered

- **Effort**: How hard is it to write?
  - Low: simple how-to, well-understood topic
  - Medium: explanation needing research, multi-step how-to
  - High: complex tutorial, requires deep investigation

Prioritize: high impact + low effort first.

## Step 4: Produce the Strategy

Output a documentation plan:

```markdown
# Documentation Strategy: [Area]

**Date:** YYYY-MM-DD
**Scope:** [what was analyzed]
**Existing docs:** [count]
**Gaps found:** [count]

## Priority 1: Quick Wins (high impact, low effort)

| Topic | Type | Why it matters |
|-------|------|----------------|
| ... | how-to | Onboarding blocker — asked weekly in Slack |

## Priority 2: Important (high impact, higher effort)

| Topic | Type | Why it matters |
|-------|------|----------------|

## Priority 3: Nice to Have (lower impact)

| Topic | Type | Why it matters |
|-------|------|----------------|

## Existing Docs to Fix

| Page | Issue |
|------|-------|
| path/to/page.md | Outdated — references removed feature |

## Recommended Order

1. [First doc to write] — `/docs:outline [topic]`
2. [Second doc to write]
3. ...
```

## Step 5: Handoff

Ask: "Want to start? Run `/docs:fill-gaps` to generate stubs for all gaps, or `/docs:outline [topic]` to plan a specific page."
