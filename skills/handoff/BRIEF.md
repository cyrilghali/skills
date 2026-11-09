# Brief template

Five headings, in this order. The launch script refuses a brief missing one. Write for a stranger: full names, full paths, ids, and where each fact came from.

```markdown
# Handoff: <imperative task title>

## Task
One paragraph: what to produce and for whom. The reviewer by name or role. The house rules the session must follow (branching, PR state, how to report), as a pointer to the file that holds them rather than a copy.

## Context
What is known, each fact with its source, starting state first; anything the task depends on but the conversation never established is marked "unknown here". Use the items that apply, for example for a bug:
- the symptom (issue id, link, count, first and last seen), who hit it as the reporter identified them (name, account or workspace), and which rows the cause was read from; when the report names no one, write "unknown here", never the author's own staging account
- the call path or the data path, with file paths and line numbers
- the cause, with the commit or the query that proves it
- the blast radius (who is affected, who is not, how that was checked)
Terms coined during the investigation are written out; nothing is called "the thing we saw". A step whose mechanism the conversation never established (how a job is enqueued, where a console lives) is marked "unknown here, find it in <place>", never guessed.

## Deliverable
Numbered list of what to produce (changes with their file and expected behaviour, or findings with the evidence that settles them). For a code change, tests to add with the existing test file they join. End with these two literal lines (the launch script searches for these exact words):
- Do not touch: <paths or systems>
- Out of scope: <items>

## Verification
The commands that prove the Deliverable, as they will be typed, one per line, in order (for a code change: the targeted test file first, the full gate last). A sentence describing a command is not a command. A command the conversation never established keeps its slot in the order, as `<targeted test: copy from <file>>`, so the new session runs two ordered steps instead of a search. Traps the source session already hit: a wrong column name, an env file to generate, a database that lives elsewhere.

## Ask the user for
What the session cannot get alone (a login, a secret, a decision) and when to ask for it. Where the reviewer should look first (the riskiest spots).
```

Slug: lowercase, hyphens, the ticket id when there is one (`abc-123.md`, `rotate-api-keys.md`).
