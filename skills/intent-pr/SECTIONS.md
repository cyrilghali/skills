# Sections beyond the Why

The Why is the whole body by default. Two kinds of PR earn one extra section each, and only when the author has the real material for it: plans they ran, log lines they found. Without that material, leave the section out and say in the certification what is missing. Any other section is added only when the author asks, after it climbs the cut ladder.

## A PR that changes a database query: `## Query`

- One plain sentence on what the query is for.
- Whether the change returns the same rows, and the check behind that (for example, row ids compared for a sample of inputs).
- The plan before and after (for Postgres, `EXPLAIN (ANALYZE, BUFFERS)`), ids masked. Put each in a collapsed `diff` block: the costly lines of the before plan as `-`, the after lines that replaced them as `+`.

## A PR that fixes a bug seen in production: `## What the logs show`

- One sentence that links the log explorer to the failures the PR fixes, with their count and time window. Before linking, check that the query returns those failures in the log tier the reviewer's browser reads, filtered to the code path the PR fixes.
- One real log line in a code block: timestamp, error, and the stack frame the PR changes.

Causes the PR leaves alone stay on the ticket.

## The cut ladder

Bodies grow over their life: review deltas, stack maps, status notes. Climb this ladder before adding anything, and stop at the first rung that holds.

1. **Does the diff already show it?** Delete it. The body states intent; it never narrates changes.
2. **Does it leave the reviewer's reading of the diff unchanged?** Delete it. Status goes in comments.
3. **Can a link replace it?** Link the ticket, doc or other PR.
4. **Is it a re-review delta** ("since your last review")? Three lines at most: what moved, why, and where to look again.
5. **Is it shared boilerplate** (a stack map, a project banner)? Generate it with a script, one screen at most, the same in every PR.

A body the reviewer has to scroll has failed.
