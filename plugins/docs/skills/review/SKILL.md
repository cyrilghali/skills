---
name: review
description: Review documentation against the style guide checklist. Scores each item, auto-fixes violations, and reports results. Triggers on "review docs", "check this page", "does this follow the style guide", "review my documentation".
argument-hint: "[file path]"
---

# Review Documentation

Review a doc page against the style guide. Score, fix, report.

## Step 1: Read

If a file path was provided, read it. Otherwise, ask which file to review.

Also read `docs/style-guide.md` for the checklist and rules.

## Step 2: Identify Page Type

Determine if the page is a how-to, explanation, reference, or tutorial based on its content and structure.

## Step 3: Run the Checklist

For each of the 15 items in the style guide checklist (Section 5), score pass/fail:

```
- [x] or [ ] Title starts with a verb or describes a goal
- [x] or [ ] First 2 sentences explain what and when
- [x] or [ ] Code examples run as-is
- [x] or [ ] Code blocks appear before explanatory prose
- [x] or [ ] Error responses shown alongside happy path
- [x] or [ ] Page follows the skeleton for its type
- [x] or [ ] No paragraph longer than 3 sentences
- [x] or [ ] No banned words or phrases
- [x] or [ ] Headings use sentence case
- [x] or [ ] All list items follow parallel structure
- [x] or [ ] Procedures have 7 steps or fewer
- [x] or [ ] Links use descriptive text
- [x] or [ ] Conditions stated before instructions
- [x] or [ ] Links to related pages (no dead ends)
- [x] or [ ] Readable in under 2 minutes
```

## Step 4: Check Skeleton Compliance

Compare the page structure against the expected skeleton for its type. Note missing, extra, or misordered sections.

Also check type-specific constraints from `docs/style-guide-mechanics.md`:
- How-to: prerequisites count, step count, verify section
- Explanation: word count, diagram presence
- Reference: intro length, example count, error docs
- Tutorial: step count, visible output per step

## Step 5: Report and Fix

Present the scorecard. For each failing item:
1. Explain what's wrong (one sentence)
2. Auto-fix it

Present the fixed version. Report: "X/15 passed before fixes, 15/15 after."

Ask if the user wants to see the diff or make further changes.
