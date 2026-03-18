---
name: fill-gaps
description: Find undocumented features and generate stub outlines for each. Bridges strategy and outline at scale — produces multiple outlines at once. Triggers on "fill doc gaps", "generate doc stubs", "what's undocumented", "create missing docs", "stub out documentation".
argument-hint: "[directory or strategy file]"
---

# Fill Documentation Gaps

Find undocumented features and generate stub outlines for each.

## Step 1: Identify Gaps

**If a strategy file was provided** (from `/docs:strategy`):
- Read it and extract all items marked as gaps (undocumented topics).

**If a directory was provided:**
- Scan source files for public modules, functions, API endpoints, config files
- Cross-reference against existing docs in the same area
- List what has no corresponding documentation

**If nothing was provided:**
- Ask: "Which area should I check for documentation gaps? Or provide a strategy file from `/docs:strategy`."

## Step 2: Classify Each Gap

For each undocumented item, determine:
- **Page type:** how-to, explanation, reference, or tutorial
- **Priority:** high (public API, onboarding), medium (internal workflow), low (edge case)
- **Effort:** based on complexity of the source code

## Step 3: Generate Stub Outlines

For each gap, create a stub outline in `docs/outlines/`:

```markdown
---
type: [determined type]
audience: [inferred from context]
output_path: [suggested location]
status: stub
priority: [high|medium|low]
---

# Outline: [Topic]

## Sections

1. [Section from skeleton for this type]
2. [Section from skeleton]
3. ...

## Source Files

- [relevant source files found during gap analysis]

## Notes

[Auto-generated stub from /docs:fill-gaps. Needs human review before /docs:write.]
```

## Step 4: Report

```markdown
# Gap Fill Report

**Area:** [what was analyzed]
**Gaps found:** [count]
**Stubs created:** [count]

| Stub | Type | Priority | Path |
|------|------|----------|------|
| [topic] | how-to | high | docs/outlines/YYYY-MM-DD-topic.md |
| ... | ... | ... | ... |
```

## Step 5: Handoff

Ask: "Stubs created. Run `/docs:write [outline-path]` to turn any stub into a full page. Start with the high-priority ones."
