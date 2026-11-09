---
name: prose
description: Prose register for any text a human will read - a question heading that carries its stake, the answer first, one why, details in a table, no proof trail, every term defined for a cold reader. Use when the user hands over text to rewrite or review, calls a text verbose, sloppy or unclear in any language, or asks to restate something in plain language with no jargon. Also the register for every document and reply the agent writes.
metadata:
  category: write
---

# Writing in the prose register

Run three passes, each answering one question, each with one home in this folder.

| Pass | Question | Home |
| -- | -- | -- |
| Register | Is the decision first, the why single, the detail in a table, the trail gone? | this file |
| Cold read | Does a reader new to the subject follow every term and every why? | this file, process step 4 |
| Voice | Would a human have written this sentence? | `VOICE.md` |
| Brevity | Is the decision on the page in as few words as it takes? | `VOICE.md`, last section |

Let `hooks/prose-gate.sh` do the mechanical half: it runs as a hook on every reply and every document write (`INSTALL.md`). On a document write it blocks and names the tells. On a reply it only names them, because a blocked reply is re-emitted whole and costs its tokens twice. Make the judgement calls below yourself.

Write a document to record what is decided and what it changes, never how the author got convinced. Write for the audience the request names. When none is named, write for a colleague who knows the field but not this subject. For text that leaves the team, assume the reader does not know the company either. Keep the first person in a reply that reports work (what was checked, where the reader should look), in the same register: answer first, short sentences, plain words.

## Measure against this reference

Before:

> **Quel prix le crawler relève-t-il ?**
> Le prix public. Documentation du fournisseur de crawl, verbatim : « Pages are fetched without a session... ». Deux corroborations dans notre propre code : la fixture de test montre le prix barré (« 49 € au lieu de 59 € »), que la boutique n'affiche qu'aux visiteurs sans compte ; et le job de relevé ignore déjà le bloc « prix membre », ce qui n'aurait aucun sens en vue connectée. Conséquence : « moins cher » signifie « moins cher pour un inconnu », exactement la définition produit, sans faux positif dû à un prix membre.

After:

> **Le crawler voit-il le prix d'un membre connecté ou celui d'un inconnu sans compte ?**
> Celui d'un inconnu : le crawler ne se connecte pas à la boutique. « Moins cher » signifie donc « moins cher pour un inconnu », la définition produit, sans faux positif dû à un prix membre.

Same decision, 110 words to 40, and the reader knows the stake before the answer.

## Apply these rules to every section

1. **Make the heading a question that carries its own alternatives**, so a cold reader knows what they will learn before reading the answer. "Quelle vue ?" fails; "comme un membre ou comme un inconnu ?" passes. Name the alternative the source rejects, never a neighbour it only mentions. Put the interrogative word first.
2. **Answer first.** Make the decision the first sentence, often one word: "Non." "Comme un inconnu." "Le moteur commun."
3. **Give one why, standing on a fact the section states.** Write a single sentence with the reason that changes implementation or reading. Do not use a resemblance to something outside the section as a why (rule 11). Keep the trail (quotes, corroborations, `vérifié dans le code`, the facts that convinced the author) in the reply to the requester.
4. **Put details in a table or nowhere.** Fields, settings, statuses, costs, columns: three columns at most, one row per item.
5. **Let plain words carry the weight.** Lead with the consequence instead of trailing it. Drop emphasis and scaffolding words (the gate names them).
6. **Introduce every referent, never invent one.** Put a term used before it is defined into the document's intro glossary table (Term | Meaning). When the text is a single section, let the answer lead and the terms follow it. Take a definition from the source text, the project glossary or the code. When none gives it, keep the term and write `[to define: term]` for the author, because a rewrite that reads well with a wrong definition is worse than the original. Name a file or function only to say where to look.
7. **Keep to the budget.** An answer is at most four sentences; a section at most 120 words outside tables. Split a paragraph that needs more into two questions.
8. **Keep** what changes implementation or reading. Keep the rejected alternative in one sentence when it is the obvious one. Keep open questions marked "Undecided" with a leaning and one reason. When the source asks the reader to choose, keep every option with its outcome and cost.
9. **Strip** session bookkeeping (dates of discussion, who said what), tables of superseded documents, process narrative and hedges.
10. **Keep the language of the input.** French stays French.
11. **Leave no context implicit.** The author writes with the whole project loaded; the reader has only the text. Replace each of these three tells with the fact stated in full. The first is a phrase coined while working, put in quotation marks as if it were an established term. The second is an image the reader must translate into what actually happens. The third is a comparison to something the section never defines. Use quotation marks for a real quote only: UI text, a user's words, a document.

## Follow these steps

1. Read the whole input once and list every term a cold reader meets before its definition. Done when each term has a source for its meaning or a `[to define]` marker.
2. When the text is a multi-section document and step 1 found undefined terms, write a short intro saying what the subject is and does, then the glossary table. Otherwise skip this step.
3. Rewrite section by section. Done when every section opens on a question, answers in its first sentence, carries one why, and holds its parallel facts in a table.
4. Cold read any text longer than about 300 words. Spawn a fresh subagent with no context (a mid-size model is enough) and tell it that it is a colleague new to the subject. Ask it to restate each answer in one sentence of its own words. Ask it to list what blocks it: a heading without stake, an undefined term, a missing why, implicit context (a coined phrase, an image, a comparison pointing elsewhere), filler, a contradiction. Treat a section it cannot restate without guessing as a blocker. Fix every real blocker. Publish only after this pass.
5. Run the voice pass with `VOICE.md`. Done when its checklist returns nothing.
6. Return the rewritten text alone, or the before/after when the user asked to see what moved. Record the run with `skill-record prose tells_before=B tells_after=A`. B is the number of tells `hooks/prose-gate.sh` names on the input and A the number it names on the returned text. Record once, only when the run finished; a dry run or an aborted run records nothing.

## Fit the register to the text's shape

Write a PR body as one sentence of intent; send what was checked to the author in the reply. Write a session reply as a paragraph or two in the first person with no heading and no table. Name each check without its count ("the suite is green", not the number of tests), and end on where the reader should look. Keep a pedagogical document for a newcomer in its own structure (context before jargon, a running example) with this register inside it. Keep a three-line note three lines long: no heading, no table.

## Run the evals this way

`evals/cases.md` holds the public cases with a named trap each (more in `evals/private/` when present), and `evals/rubric.md` a 0-2 rubric per dimension. Generate with a fresh subagent per case, judge with a fresh strict subagent per case, and run `hooks/prose-gate.sh doc` on each output with a real file path, because the gate reads the file from disk.
