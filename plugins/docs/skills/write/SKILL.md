---
name: write
description: Write a documentation page following the project style guide. Picks up outlines from /docs:outline if they exist. Handles scoping, skeleton selection, and writing. Triggers on "write docs", "document this", "create a how-to", "write an explanation", "write a reference page", "write a tutorial".
argument-hint: "[topic, file path, or outline path]"
---

# Write Documentation

Write a documentation page following the style guide. Three phases: scope, write, review.

## Phase 1: Scope

**If an outline exists** (check `docs/outlines/` for recent files matching the topic):
- Read it. Extract type, audience, sections, source files.
- Announce: "Found outline from [date]. Using it."

**If a file path was provided:** This is a rewrite — use `/docs:rewrite` instead.

**If a topic was provided without outline:**
- Determine page type (how-to, explanation, reference, tutorial). Ask if unclear.
- Identify source files to reference.

Then read the style guide:
- `docs/style-guide.md` — principles, skeletons, writing rules, banned words, checklist
- `docs/style-guide-mechanics.md` — formatting rules, skeleton-specific constraints

## Phase 2: Write

1. Start from the skeleton (style guide Section 2). No added sections, no skipped sections.
2. Fill each section. Research source files for accurate details.
3. Apply the 10 writing rules (style guide Section 3).
4. Remove all banned words (style guide Section 4).
5. Write the file to the path from the outline, or suggest a path.

**Skeleton constraints:**
- How-to: max 7 steps, 3-5 prerequisites, verify with command+output
- Explanation: 800-1,500 words, one diagram for core concept
- Reference: one-sentence intro, definition lists for nested params, two examples (happy+error)
- Tutorial: 5-9 steps, 15-30 min, every step has visible output, "we" voice

## Phase 3: Quick Review

Run the checklist (style guide Section 5) against the page. Auto-fix violations. Present the result.

Ask: "Want a deeper review? Run `/docs:review`."
