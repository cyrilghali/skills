# The lesson record and the area file

A lesson is one JSON record. `scripts/render.py` draws every figure from it, so no field holds HTML or SVG. `scripts/check-record.py` enforces every limit below; when a label is too long, shorten the label.

Every `cite` is `{"repo": "owner/name", "path": "lib/x.ex", "line": 42, "has": "def save"}`. `has` is a piece of that line, at least 3 characters, copied from `git show`. The line is read at the repo's `base` commit. Add `"at": "head"` to read it at the pull request's last commit (only the answer does that). Add `"sha": "<full sha>"` to pin another commit.

## The record

Start from the output of `scripts/prepare.sh`: copy its `pr`, `shas` and `written`, then add the rest.

| Field | What it holds |
|---|---|
| `pr` | `repo`, `number`, `title`, `author`, and `links`: `[{"label": "Ticket ABC-12", "url": "…"}]` for the ticket. The pull request link is added by the renderer. |
| `shas` | per repo, `base` (the commit the pull request started from) and `head`. A cited second repo has both set to the commit that was read. |
| `written` | today's date, `YYYY-MM-DD`. |
| `area`, `marker` | the area id, and the id of the map node this lesson is about. |
| `headline` | at most 90 characters: what is different after this pull request alone, in plain words, as a statement true of the diff. It is the lesson's title on the page; the pull request's own title is shown under it. |
| `intro` | at most 90 words: what the pull request touches, then which parts of the code the reader needs for it. A statement, never a question. |
| `screen` | what a person sees. `when` ("before the PR"), `title`, `caption`, and 1 or 2 `cases`: `{"label": "Lea has no manager", "lines": [{"text", "note"?, "state"?}]}`. `state` is `shown` (default), `missing` (it happened and the screen does not show it), `later` (appears after a delay), or `added` (only in the answer's screen). |
| `no_screen` | instead of `screen`, when no person sees the change: one sentence that says why (a background job, a query made faster). |
| `path` | one action followed through the code. `when`, `title`, `caption`, 2 to 6 `actors` `{"id", "label" (12 characters), "code" (40), "node"}`, and 3 to 12 `steps`. `node` is optional: the id of the map part this actor is, so the map shows the actor's label on that part. Give it to every actor that is a part of the map, one actor per part. |
| `path.steps[]` | `from`, `to` (actor ids; the same id twice for work done inside one actor), `label` (18 characters, on the arrow), `text` (at most 45 words), `cite`. Optional: `phase` (starts a named band), `lost: true` on the one step where the outcome stops matching what the person expects, `known: <pr number>` when an earlier lesson of the area taught this step. |
| `state` | optional table of what each action writes. `when`, `title`, `header` (name of the first column), `caption`, 2 to 4 `columns` `{"label", "cite"}`, and `rows` `{"name", "highlight"?, "cells": [...]}` with one cell per column: `{"mark": "dot" or "none"}` or `{"text": "closed"}`, each with an optional `note`. |
| `guess.questions` | 1 or 2 questions the reader can answer from the figures alone, before opening the diff. |
| `guess.answer` | `text` (paragraphs), `changes` `[{"step": 7, "text", "cite" with "at": "head"}]` (what the pull request changes at a numbered step), optional `screen` (`when`: "after the PR"), and `check`: what to look at in the review. |

## The area file

`<store>/areas/<area>.json` holds the map every lesson of the area opens with. Write it once, with the first lesson of the area; later lessons reuse it and only move the marker.

```json
{"area": "billing", "name": "Billing", "title": "An order becomes an invoice, and every screen reads that one invoice",
 "shas": {"owner/name": {"base": "<the commit the map was read at>"}},
 "map": {
  "top":    {"id": "plan", "label": "The plan", "sub": "what sets the price", "code": "Plan", "note": "decides the amount", "cite": {}},
  "left":   {"title": "What writes the invoice", "nodes": [{"id": "checkout", "label": "Checkout", "sub": ["a customer pays", "an order"], "code": "Orders.pay", "cite": {}}]},
  "center": {"id": "invoice", "title": "The invoice: one row", "code": "invoices (Invoice)", "cite": {},
             "stages": [{"label": "draft", "code": "draft"}, {"label": "sent", "code": "sent"}, {"label": "paid", "code": "paid"}]},
  "right":  {"title": "What reads the invoice", "nodes": [{"id": "pdf", "label": "PDF download", "sub": ["built at each request"], "code": "InvoicePdf", "cite": {}}]},
  "caption": "Two or three sentences on how the thing in the centre moves through its stages.",
  "claims": [{"text": "paid invoices lock after 30 days", "cite": {}}]},
 "lessons": []}
```

- `name` is a label of at most 28 characters. `title` is one sentence that says what the area does for a person.
- The centre is the one record, queue or pipeline the area turns around, with its 2 to 6 stages in order. Left: 1 to 4 things that write it or start it. Right: 1 to 4 things that read it or use its result. `top` is optional: what configures the area.
- Limits: node `label` 30 characters, each of at most 2 `sub` lines 40, `code` 38; stage `label` 20, `code` 24; centre `code` 30; top `label` 40, `sub` 100, `note` 60.
- Every node, the centre and every number in the caption (through `claims`) cites the line that proves it.
- When the pull request's code sits in no node, add one node for it (a side holds at most 4) and pin its cite with `"sha"`. Change nothing else on a map that earlier lessons used.
- `lessons` is written by `render.py`: for each lesson, the steps it taught. Read it before writing a path.

Every sentence of a record has at most 30 words; the checker names the ones to cut in two.

`factcheck` `{"sentences", "corrected"}` is written by the fact-check (`FACTCHECK.md`), never by the agent that wrote the record. The page says how many sentences were checked and corrected.

A `code` that is a module, function or table name is written in full, as it stands in the code: the reader searches the repo for it, and the figure shortens a long one by itself. The map's three column titles hold 28 characters on the sides and 30 in the centre.
