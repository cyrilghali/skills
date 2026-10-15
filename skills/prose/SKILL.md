---
name: prose
description: Load before rewriting, tightening or editing any text a person will read, even a single sentence - a paragraph, doc section, ticket, status update, email or reply. It holds a register the default style does not produce - the answer first, a question heading that carries its stake, one why, parallel details in a table, no proof trail, no AI tells, every term defined for a cold reader. Use when the user asks to rewrite, shorten, simplify or clarify a text, calls it wordy, verbose, unclear, jargon-heavy or AI-sounding, or wants it readable for a newcomer or a customer. Not for translation, typo or grammar fixes, summaries of long documents, code comments or docstrings, pull request descriptions (intent-pr), commit messages (rewrite-commits), or a newcomer explainer written from scratch (newcomer-doc).
metadata:
  category: write
---

# Prose

Four passes, four questions. Each pass has one home in this folder.

| Pass | Question | Home |
| -- | -- | -- |
| Register | Is the decision first, the why single, the detail in a table, the trail gone? | this file |
| Cold read | Does a reader new to the subject follow every term and every why? | this file, process step 4 |
| Voice | Would a human have written this sentence? | `VOICE.md` |
| Brevity | Is the decision on the page in as few words as it takes? | `VOICE.md`, last section |

`hooks/prose-gate.sh` runs the mechanical half (banned words, em dashes, long sentences) as an optional hook; `INSTALL.md` sets it up. The judgement calls below stay with the agent.

A document records what is decided and what it changes, never how the author got convinced. The reader is the audience the request names. When none is named, assume a colleague who knows the field but not this subject. For text that leaves the team, assume the reader does not know the company either.

## The reference

Before:

> **Which copy does the backup job read?**
> The replica. Database docs, verbatim: "Queries on a standby see data as of the last replayed transaction." Two corroborations in our own code: the job's connection string points at port 5433, which only the replica listens on; and the job already tolerates a minute of lag, which would make no sense on the primary. Consequence: "backed up" means "as of the replica's last replay", exactly the product definition, with no stall caused by a lock on the primary.

After:

> **Does the backup job read the primary or the replica?**
> The replica. "Backed up" therefore means "as of the replica's last replay", the product definition, and a lock on the primary never stalls the job.

Same decision, 75 words to 30, and the reader knows the stake before the answer.

## Rules

1. **The heading is a question that carries its own alternatives.** A cold reader knows what they will learn before reading the answer. "Which copy?" fails; "the primary or the replica?" passes. The alternative named is the one the source rejects, never a neighbour it only mentions. Interrogative word first.
2. **Answer first.** The decision is the first sentence, often a few words: "No." "The replica." "The shared engine."
3. **One why, standing on a fact the section states.** One sentence with the reason that changes how the reader implements or reads. A resemblance to something outside the section is not a why (rule 11). The trail (quotes, supporting evidence, "verified in the code", the facts that convinced the author) stays in the reply to the requester.
4. **Details go in a table or nowhere.** Fields, settings, statuses, transitions, costs: three columns at most, one row per item.
5. **Plain words carry the weight.** The consequence leads instead of trailing; emphasis and scaffolding words go (`VOICE.md` lists them).
6. **Every referent is introduced, never invented.** A term used before it is defined goes into the document's intro glossary table (Term, Meaning). In a single section, the answer still leads and the terms follow it. A definition comes from the source text, the project glossary or the code; when none gives it, keep the term and write `[to define: term]` for the author. A rewrite that reads well with a wrong definition is worse than the original. A file or function is named only to say where to look.
7. **Budget.** An answer is at most four sentences; a section at most 120 words outside tables. A paragraph that needs more is two questions.
8. **Keep** what changes implementation or reading, and the rejected alternative in one sentence when it is the obvious one. Mark open questions "Undecided" with a leaning and one reason. When the source asks the reader to choose, keep every option with its outcome and cost.
9. **Strip** session bookkeeping (dates of discussion, who said what), tables of superseded documents, process narrative, hedges.
10. **Same language as the input.** The rules apply in any language; a Spanish text stays Spanish.
11. **No implicit context.** The author writes with the whole project loaded; the reader has only the text. Replace each of three tells by the fact stated in full. The first is a phrase coined while working, put in quotation marks as if it were an established term. The second is an image the reader must translate into what actually happens. The third is a comparison to something the section never defines. Quotation marks hold a real quote only: UI text, a user's words, a document.

## Process

1. Read the whole input once and list every term a cold reader meets before its definition. Done when each term has a source for its meaning or a `[to define]` marker.
2. When the text is a multi-section document and step 1 found undefined terms, write a short intro saying what the subject is and does, then the glossary table. Otherwise skip this step.
3. Rewrite section by section. Done when every section opens on a question, answers in its first sentence, carries one why, and holds its parallel facts in a table.
4. Cold read, when the text is longer than about 300 words: hand it to a fresh subagent with no context (a mid-size model is enough), told it is a colleague new to the subject. Ask it to restate each answer in one sentence of its own words, and to list what blocks it: a heading without stake, an undefined term, a missing why, implicit context, filler, a contradiction. A section it cannot restate without guessing is a blocker. Done when every real blocker is fixed.
5. Voice pass with `VOICE.md`. Done when its checklist returns nothing.
6. When the gate is installed, or the output is a file, run it: `printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' FILE | hooks/prose-gate.sh doc`. Done when it prints nothing.
7. Return the rewritten text alone, or the before and after when the user asked to see what moved.

## Scope

The shape follows the text, not the rules above.

| Text | Shape |
| -- | -- |
| A design doc, ticket or appendix section | The full register: question heading, answer, one why, table |
| A short note (three lines or fewer) | Stays short: no heading, no table; only the voice pass applies |
| A chat reply reporting work | A paragraph or two in the first person, no heading, no table: what I checked, ending on where the reader should look or what they should decide |
| A message to someone outside the team | Every internal term replaced or defined in place; no glossary table |
| A text already in register | Returned unchanged, or with one line fixed |
| A newcomer explainer | Keeps its own structure (context before jargon, a running example) with this register inside it |
