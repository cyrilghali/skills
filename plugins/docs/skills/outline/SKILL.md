---
name: outline
description: Plan a documentation page before writing it. Determines page type, audience, sections, and source material. Outputs a structured outline file that /docs:write can pick up. Triggers on "outline docs", "plan a page", "outline a how-to", "what should this doc cover".
argument-hint: "[topic]"
---

# Outline a Documentation Page

Plan what to write before writing it. Produces a structured outline that `/docs:write` uses.

## Step 1: Understand the Topic

If a topic was provided, search for existing docs to avoid duplication and gather context. If not, ask: "What do you want to document?"

## Step 2: Determine Page Type

Decide which Diataxis quadrant fits:

| Type | The reader wants to... |
|------|------------------------|
| **How-to** | Accomplish a specific task ("How do I...?") |
| **Explanation** | Understand a concept ("What is...? Why...?") |
| **Reference** | Look up parameters, config, API details |
| **Tutorial** | Learn from scratch by building something |

If unclear, ask: "Is the reader trying to **do** something or **understand** something?"

## Step 3: Identify Source Material

Search the codebase for files relevant to the topic. List them in the outline so `/docs:write` knows what to read.

## Step 4: Write the Outline

Write to `docs/outlines/YYYY-MM-DD-<topic>.md`:

```markdown
---
type: [how-to|explanation|reference|tutorial]
audience: [who reads this]
output_path: [where the final doc should go]
---

# Outline: [Topic]

## Sections

1. [Section from skeleton]
2. [Section from skeleton]
3. ...

## Source Files

- [path/to/relevant/file.ext]
- [path/to/another/file.ext]

## Notes

[Any context, constraints, or decisions about scope]
```

## Step 5: Handoff

Present the outline and ask: "Ready to write? Run `/docs:write` to turn this into a full page."
