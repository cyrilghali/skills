---
name: prose
description: Prose register for any text a human will read - a question heading that carries its stake, the answer first, one why, details in a table, no proof trail, every term defined for a cold reader. Use when the user hands over text to rewrite or review, or calls a text verbose, sloppy or unclear in any language. Also the register for every document and reply the agent writes.
---

# Prose

Three passes, three questions. Each pass has one home in this folder.

| Pass | Question | Home |
| -- | -- | -- |
| Register | Is the decision first, the why single, the detail in a table, the trail gone? | this file |
| Cold read | Does a reader new to the subject follow every term and every why? | this file, process step 4 |
| Voice | Would a human have written this sentence? | `VOICE.md` |

`hooks/prose-gate.sh` runs the mechanical half as a hook on every reply and every document write (`INSTALL.md`). It blocks and names the tells; the judgement calls below are the agent's.

A document records what is decided and what it changes, never how the author got convinced. The reader is a colleague who knows the company and the stack but not this subject. A reply reporting work keeps the first person (what was checked, where the reader should look) in the same register: answer first, short sentences, plain words.

## The reference

Before:

> **Quelle vue le scraper lit-il ?**
> La vue déconnectée. Documentation de collecte du scraper, verbatim : « All three options collect publicly available data only... ». Deux corroborations dans notre propre code : la fixture de test rend le nom tronqué (« John F. K. »), troncature que LinkedIn n'applique qu'aux visiteurs sans compte ; et le job de scrape devine déjà une URL anonymisée quand le nom de famille est masqué, ce qui n'aurait aucun sens en vue membre. Conséquence : « exposé » signifie « visible par un inconnu », exactement la définition produit, sans faux positif dû à une vue membre.

After:

> **Le scan voit-il le profil comme un membre LinkedIn ou comme un inconnu sans compte ?**
> Comme un inconnu : le scraper ne franchit pas le mur de connexion de LinkedIn. « Exposé » signifie donc « visible par un inconnu », la définition produit, sans faux positif dû à une vue membre.

Same decision, 110 words to 40, and the reader knows the stake before the answer.

## Rules

1. **The heading is a question that carries its own alternatives.** A cold reader knows what they will learn before reading the answer. "Quelle vue ?" fails; "comme un membre ou comme un inconnu ?" passes. The alternative named is the one the source rejects, never a neighbour it only mentions. Interrogative word first.
2. **Answer first.** The decision is the first sentence, often one word: "Non." "Comme un inconnu." "Le moteur commun."
3. **One why, standing on a fact the section states.** A single sentence with the reason that changes implementation or reading. A resemblance to something outside the section is not a why (rule 11). The trail (quotes, corroborations, "vérifié dans le code", the facts that convinced the author) stays in the reply to the requester.
4. **Details go in a table or nowhere.** Fields, settings, statuses, costs, columns: three columns at most, one row per item.
5. **Plain words carry the weight.** The consequence leads instead of trailing; emphasis and scaffolding words go (the gate names them).
6. **Every referent is introduced, never invented.** A term used before it is defined goes into the document's intro glossary table (Term | Meaning); when the text is a single section, the answer still leads and the terms follow it. A definition comes from the source text, the project glossary or the code: when none gives it, keep the term and write `[to define: term]` for the author. A rewrite that reads well with a wrong definition is worse than the original. A file or function is named only to say where to look.
7. **Budget.** An answer is at most four sentences; a section at most 120 words outside tables. A paragraph that needs more is two questions.
8. **Keep** what changes implementation or reading, the rejected alternative in one sentence when it is the obvious one, and open questions marked "Undecided" with a leaning and one reason.
9. **Strip** session bookkeeping (dates of discussion, who said what), tables of superseded documents, process narrative, hedges.
10. **Same language as the input.** French stays French.
11. **No implicit context.** The author writes with the whole project loaded; the reader has only the text. Three tells of context left implicit, each replaced by the fact stated in full: a phrase coined while working, in quotation marks as if established ("had its chance"); an image the reader must translate to know what happens ("waiting for December" for "until the end of the year"); a comparison to something outside the section ("the same threshold the rule applies elsewhere"). Quotation marks hold a real quote only: UI text, a user's words, a document.

## Process

1. Read the whole input once and list every term a cold reader meets before its definition. Done when each term has a source for its meaning or a `[to define]` marker.
2. Write the intro: two to four sentences of scene (what the thing does, the two or three systems it touches), then the glossary table.
3. Rewrite section by section. Done when every section opens on a question, answers in its first sentence, carries one why, and holds its parallel facts in a table.
4. Cold read, when the text is longer than about 300 words: spawn a fresh subagent with no context (a mid-size model is enough), told it is a colleague new to the subject. Ask it to restate each answer in one sentence of its own words, and to list what blocks it (heading without stake, undefined term, missing why, implicit context (a coined phrase, an image, a comparison pointing elsewhere), filler, contradiction). A section it cannot restate without guessing is a blocker. Fix every real blocker. The text is publishable only after this pass.
5. Voice pass with `VOICE.md`. Done when its checklist returns nothing.
6. Return the rewritten text alone, or the before/after when the user asked to see what moved.

## Scope

A PR body is one sentence of intent; what was checked goes to the author in the reply. A session reply is a paragraph or two in the first person with no heading and no table: each check named without its count ("the suite is green", never "412 tests pass"), ending on where the reader should look. A pedagogical document for a newcomer keeps its own structure (context before jargon, a running example) with this register inside it. A three-line note stays three lines: no heading, no table.

## Evals

`evals/cases.md` holds six cases with a named trap each, `evals/rubric.md` a 0-2 rubric per dimension. Generate with a fresh subagent per case, judge with a fresh strict subagent per case, and run `hooks/prose-gate.sh doc` on each output with a real file path (the gate reads the file from disk). On the session-reply case the doc-only proof-trail finding on "I verified" is expected: a reply runs under `stop`, which has no such check.
