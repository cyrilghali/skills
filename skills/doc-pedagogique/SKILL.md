---
name: doc-pedagogique
description: Writes a teaching technical document in polished French, with context before jargon, one running example, compared options and honest verdicts. Use when writing a French technical document that compares several options or must onboard a reader who doesn't know the subject (design doc, étude, note d'architecture, "doc pédagogique", "fil rouge"), or when the user rejects a draft as "difficilement compréhensible" or "français moyen". Not for short notes to an expert audience — scale down instead.
metadata:
  category: write
---

# Teaching document in French

Write for a reader who is discovering the subject. They must understand the problem in 60 seconds and read the document in one sitting, without the code or the context in front of them.

## Lay out the sections in this order

Sections 1 to 3 apply to every document. Sections 4 to 7 apply only when the document compares options or settles a choice. A document that explains a system with no choice to make leaves them out. A short request merges or drops the sections it does not need. Keep the French section titles in the document.

1. **Chapeau**: what the document compares or explains and how to read it (4-6 lines).
2. **D'où on part**: how the system works today, in human language. Introduce every technical term before you use it.
3. **Le problème, sur un exemple**: the running example (see below), then the questions nobody can answer today, one by one.
4. **Ce que le produit demande**: the requirements, each linked to its source (brief, roadmap).
5. **Les options**: one section per option, all on the same template (see below).
6. **Comparaison**: one table plus 3-5 lessons in prose, such as « le vrai choix est X contre Y » or « Z est un complément, pas un concurrent ».
7. **Recommandation**: a phased trajectory, then the decisions to take, written as questions, such as « L'escalation est-elle au scope de septembre ? Si oui… ».

## Carry one running example through the whole document

Pick one concrete, named example, such as « le fichier de Léa, détecté le 1er mars, résolu le 12 ». Introduce it in the problem section, then replay it in every option: « sur notre exemple, voici ce qui s'écrit, où ». The example is what makes the data model tangible, because a reader does not understand a schema, they understand what happens to Léa.

## Write every option on the same template

- **L'idée**: 2-3 sentences, with no table name before it has been explained.
- **Sur notre exemple**: the running example replayed in this design.
- **Ce qu'il faut construire**: a numbered list, ordered by dependency, with figures when possible.
- **Ce que ça donne**: one entry for each audience the option touches (users, teams, future product changes).
- **Où ça coince**: the real limits, the worst one in bold. Never leave them out, because the document's credibility comes from them.
- **En une phrase**: the verdict.

## Build each diagram in layers

Never introduce a diagram with three or more elements in one go, because the reader cannot follow a system that appears already assembled. Draw a short series of diagrams instead, each one redrawing the previous and adding a single element. For a flow A → B → C, draw A → B first, then the same diagram with C, then with the return path or the last piece. A single complete diagram, kept for the end, is a reference, not teaching. Skip the diagram for a simple point.

## Follow these French rules

- Write full prose in complete sentences. Never use telegraph style (`A → B → échec`), fragments, or invented abbreviations.
- Put each technical term in `code` and explain it at its first appearance, never later.
- Use French quotation marks « », a non-breaking space before : ; ? !, and accents on capitals (À, É).
- Give each sentence one idea. Cut any sentence that needs a second read.
- Give precise figures and units (« ~6 j-h », « 31 figures »), never « rapidement » or « facilement ».

## Write the final pass yourself, in the main context

Let subagents and workflows produce the material: research, long proposals, syntheses. Write the final pass in the main context yourself, as the assistant that holds the whole context, sentence by sentence. Never publish or assemble the compressed prose of subagents, because it produces average French and a text that reads like a scorecard. Do the compression yourself, and compress by choosing what to leave out, not by shortening sentences.

## Learn from the reference document

When `private/EXEMPLAR.md` exists beside this file, read it: it is the document that won the user over (« exactement ce que je voulais ») after they rejected a version compressed by agents. Use it for the tone, the running example and the option template. It describes a private product, so it is not published.

## Finish the document

Give it the length the subject needs: a rich comparison reads in 10-12 minutes, a short note in 2-3. Reread each section asking « un nouveau sur le projet comprend-il sans moi ? ». Close the delivery by pointing the reader's eyes at the 1-2 sections that carry the decision, in the certification voice: say in the first person what you checked, which risks that covers, and what needs the reader's review.

Sources : la construction de schéma par couches adapte le skill `teach` de pstack par poteto (MIT).
