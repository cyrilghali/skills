---
name: compound
description: Capture a documentation pattern or lesson learned into the style guide. Use after writing or reviewing docs when you discover a reusable pattern, edge case, or new rule. Triggers on "compound this doc pattern", "add this to the style guide", "I learned something about writing docs", "update the style guide".
argument-hint: "[description of what you learned]"
---

# Compound a Documentation Pattern

Capture a reusable documentation pattern or lesson into the style guide so future docs benefit.

## Step 1: Identify What Was Learned

If a description was provided, use it. Otherwise, ask: "What documentation pattern or lesson did you discover?"

Look for:
- A new skeleton-specific rule (e.g., "reference pages for webhooks need a payload example section")
- A new anti-pattern discovered in practice
- A writing rule edge case (e.g., "how to handle multi-language code blocks")
- A new banned word or phrase discovered during review
- A structural pattern that worked well and should be reused

## Step 2: Determine Where It Belongs

| Pattern type | Where to add |
|---|---|
| New writing rule | `docs/style-guide.md` Section 3 |
| New banned word | `docs/style-guide.md` Section 4 |
| New checklist item | `docs/style-guide.md` Section 5 |
| Skeleton refinement | `docs/style-guide-mechanics.md` skeleton-specific rules |
| Formatting edge case | `docs/style-guide-mechanics.md` relevant section |
| Reusable page pattern | `docs/patterns/` as a new file |

## Step 3: Draft the Addition

Write the new rule/pattern following the same format as existing entries:
- Writing rules: numbered, bold keyword, one sentence
- Banned words: table row with "Instead of" and "Use"
- Checklist items: `- [ ]` yes/no question
- Skeleton rules: bullet point with constraint
- Patterns: short markdown file with the pattern name and example

## Step 4: Apply

Present the addition to the user. On approval, edit the target file to add the new entry.

Report: "Added [pattern] to [file]. This will apply to all future `/docs:write` and `/docs:review` runs."
