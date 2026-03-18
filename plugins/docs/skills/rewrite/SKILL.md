---
name: rewrite
description: Rewrite an existing documentation page to comply with the style guide. Preserves accurate content while fixing structure, style, and completeness. Triggers on "rewrite this page", "improve these docs", "bring this doc up to standard", "fix this documentation".
argument-hint: "[file path]"
---

# Rewrite Documentation

Take an existing page and bring it into compliance with the style guide.

## Step 1: Read and Assess

Read the target file. Also read `docs/style-guide.md` and `docs/style-guide-mechanics.md`.

Identify:
- Current page type (how-to, explanation, reference, tutorial, or mixed/unclear)
- What's accurate and should be preserved
- What's structurally wrong (missing sections, wrong order, mixed types)
- Style violations (banned words, passive voice, hedging, long paragraphs)

## Step 2: Plan the Rewrite

If the page mixes types (e.g., a how-to with embedded explanation), decide whether to:
- Split into separate pages (preferred if both halves are substantial)
- Pick the dominant type and move the other content elsewhere

Present the plan to the user before rewriting.

## Step 3: Rewrite

1. Restructure to match the skeleton for the chosen page type
2. Preserve all accurate technical content
3. Rewrite prose to follow writing rules (imperative mood, short sentences, code-first)
4. Remove banned words
5. Add missing sections from the skeleton (e.g., missing Verify section in a how-to)
6. Remove sections not in the skeleton

## Step 4: Diff and Confirm

Show a summary of what changed (sections added/removed/reordered, style fixes applied). Apply the changes only after user confirms.

Then suggest: "Run `/docs:review` to verify the rewrite passes all checks."
