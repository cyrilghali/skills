---
name: audit
description: Audit a directory of documentation against the style guide. Scores each page, produces a gap report with priorities. Triggers on "audit docs", "score our documentation", "docs quality report", "how good are our docs".
argument-hint: "[directory path]"
---

# Audit Documentation

Score a directory of docs against the style guide and produce a gap report.

## Step 1: Discover Pages

If a directory was provided, find all `.md` files in it. Otherwise, ask which directory to audit (suggest `docs/`, `guides/`).

Read `docs/style-guide.md` for the checklist.

## Step 2: Score Each Page

For each page, run the 15-item checklist silently. Record:
- Page path
- Detected page type (how-to, explanation, reference, tutorial, unknown)
- Score (X/15)
- Top 3 failing items

## Step 3: Produce the Report

Output a summary table sorted by score (worst first):

```markdown
# Documentation Audit Report

**Directory:** [path]
**Pages audited:** [count]
**Average score:** [X]/15

## Results

| Page | Type | Score | Top Issues |
|------|------|-------|------------|
| path/to/worst.md | how-to | 6/15 | No verify section, banned words, passive voice |
| path/to/ok.md | reference | 10/15 | Missing error examples, long paragraphs |
| path/to/good.md | explanation | 14/15 | One heading in title case |

## Priority Fixes

1. **[worst page]** — [what to fix first and why]
2. **[second worst]** — [what to fix]
3. **[third worst]** — [what to fix]

## Patterns

- [Common issue across multiple pages]
- [Systemic gap, e.g., "No page has error examples"]
```

## Step 4: Suggest Next Steps

Ask: "Want to fix these? Run `/docs:rewrite [path]` on any page, or `/docs:review [path]` for a detailed check."
