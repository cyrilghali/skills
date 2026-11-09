---
name: deslop-en
description: "Remove AI writing patterns from English prose. Covers blog posts, technical docs, social copy, release notes, scientific writing. Trigger: deslop, de-AI, make it sound human, remove AI patterns, fix slop, polish, rewrite, sound natural"
metadata:
  category: write
  trigger: deslop, de-AI, make it sound human, remove AI patterns, fix slop, sound natural, polish, rewrite, humanize, de-slop
  sources:
    - https://github.com/hardikpandya/stop-slop
    - https://github.com/stephenturner/skill-deslop
    - https://tropes.fyi
    - https://github.com/coderjatin/anti-slop-writing
    - https://github.com/cursor/plugins/tree/main/pstack (unslop skill, MIT, Lauren Tan)
---

# Remove AI writing patterns from English prose

Take a text a model wrote or polished and make it read like a person wrote it. Delete the patterns a reader recognises as machine output, keep every fact and intent, and hand back the clean text alone.

## Hold these four rules through every pass

1. **Leave clean prose alone.** Do not add slang or forced quirks to "sound human". If a sentence is already clean, do not touch it.
2. **Delete before you tweak.** Cut filler, empty adverbs and throat-clearing before you adjust rhythm, because most slop is extra words rather than wrong words.
3. **Keep the meaning.** If removing a pattern changes what the author meant, keep the original wording.
4. **Match the register to the genre.** A blog post and a grant proposal meet different standards; read `references/GENRES.md` for the genre's rules.

## Run every sentence through this checklist

- Delete an adverb that adds no precision (`very`, `really`, `essentially`). Keep an adverb that narrows a claim (`only`, `never`, `monthly`).
- Turn passive voice into active voice: find the actor and make them the subject.
- When an inanimate thing does a human verb ("the decision emerges"), name the person who does it.
- Cut "here's what / this / that" throat-clearing and go straight to the point.
- Replace a "not X, it's Y" contrast with Y stated directly.
- Fold a self-posed rhetorical question and its answer into one statement.
- When three sentences in a row have the same length, break one.
- When a paragraph ends on a punchy one-liner, vary the ending.
- Replace every em dash with a comma, a period or a parenthetical.
- Replace a vague declarative ("The implications are significant") with the specific implication.
- Delete meta-joiners ("The rest of this essay...").
- Delete pedagogical hand-holding, the "let's" sentences that invite the reader to break this down or dive in.
- Reduce a stacked tricolon to two items or one.
- Reformulate a list whose every item opens with a bold keyword.
- Change a Title Case heading ("How The Cache Gets Invalidated") to sentence case.
- Replace curly quotes and apostrophes ("smart quotes") with straight ones.
- Remove decorative emoji from headings and bullets.
- Rewrite a colon used mid-sentence as a connector into a plain statement. Keep a colon before a list or an example.
- Rewrite a label and colon standing in for a sentence ("Bottom line: ship it", "Cost: two days", "Root cause: the cache") as a sentence; the label becomes its subject or disappears ("It costs two days").
- Split a sentence the reader has to re-read, or drop one of its clauses.
- When a sentence would read the same in any other project's docs ("SQL you can read", "the system stays close at hand"), name the mechanism or the number, or cut it.

Open `references/PATTERNS.md` once an item flags something: it holds the exact before/after form of each item and the full pattern catalog (throat-clearing, binary contrasts, tricolon abuse, em dashes, and more) with examples. Open `references/VOCABULARY.md` while rewriting: it holds the banned words and the word-replacement table. Open `references/GENRES.md` once you know the genre: it holds the rules for blog posts, scientific writing, release notes and social copy.

## Work in this order

1. **Identify the genre.** Blog, scientific, release notes or social copy. Lock in that register from `references/GENRES.md` before you change a word, because the same sentence is slop in one genre and correct in another.
2. **Keep the meaning.** Never trade accuracy for style.
3. **Subtract first.** Cut throat-clearing openers, meta-commentary and emphasis crutches. Cut adverbs that add no precision and keep those that narrow a claim. Replace binary contrasts with Y stated directly. Fix passive voice and false agency by naming the actor. Replace "serves as" and other pompous copulas with "is", "are" or "has". Replace vague declaratives with the specific fact.
4. **Then smooth.** Vary sentence length, break tricola, remove em dashes.
5. **Read it through once more.** Fix anything that still sounds unnatural. Do not force a change on a sentence that is already clean.
6. **Deliver the rewritten text only, to the person who asked.** Add no change list, no commentary and no closing line unless they explicitly ask for one.

Worked before/after examples and an optional scoring rubric sit at the end of `references/PATTERNS.md` (the Examples section).

## Point to the sibling skill for Chinese

- `deslop-zh`: Chinese de-AI writing (Chinese-specific patterns: summary tags, contrast formulas, jargon, punctuation, spacing rules).
