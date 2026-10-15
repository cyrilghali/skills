# Voice: would a human have written this sentence?

The voice pass of the prose skill (`SKILL.md`). Subtraction first: delete before you tweak, and leave clean text alone. Meaning wins over pattern: when removing a pattern changes what the author meant, keep the original.

## Checklist

- [ ] Throat-clearing opener ("Here's the thing", "Let's dive in", "It is worth noting")? Cut to the point.
- [ ] Passive voice or an inanimate thing doing a human verb ("the decision emerges", "the data suggests")? Name the actor.
- [ ] A reframe ("not X, it's Y") used as flourish, or a contrast the source never drew? State Y. Keep the shape only when it corrects a wrong belief the reader holds.
- [ ] A rhetorical question the text answers itself? Fold it into a statement.
- [ ] A dramatic fragment or a punchline closing the paragraph? End on content.
- [ ] Three items where two carry the meaning (tricolon)? Drop one.
- [ ] Three consecutive sentences of the same length? Break one.
- [ ] A vague declarative ("the implications are significant")? Name the implication.
- [ ] A phrase in quotation marks the author coined while working, read as an established term? Write what it means; quotation marks hold UI text, a user's words or a document.
- [ ] An image the reader must translate to know what happens? State the literal fact it stands for.
- [ ] A comparison pointing to something the section never defines? Cut it; the fact stands alone, or the thing compared to is stated here in full.
- [ ] "Serves as", "acts as", "functions as"? Use "is".
- [ ] Meta-commentary ("the rest of this section", "as mentioned above")? Delete.
- [ ] Every bullet opening with a bold keyword? Reformulate as sentences.
- [ ] A label and a colon standing in for a sentence ("Bottom line: ship it", "Cost: two days")? Write the sentence; the label becomes its subject or disappears ("It costs two days"). A colon stays only inside a sentence, before a list or a quote.
- [ ] An em dash? Replace with a comma, two sentences, or a colon inside the sentence.
- [ ] An adverb that adds no precision ("very", "really", "essentially", "basically")? Delete. An adverb that narrows a claim ("only", "monthly", "retroactively") stays.
- [ ] Elegant variation (three names for one thing to avoid repeating a word)? Repeat the word.
- [ ] A patronising analogy or hand-holding ("think of it as a mailbox")? Delete unless the reader is new to the domain.
- [ ] An opener that flatters or a closer that offers more ("Great question", "Let me know if", "Feel free to")? Start on the answer, end on content or the ask.
- [ ] Glue opening a sentence ("That said", "Moving forward", "With that in mind")? Delete it; the sentence stands alone.
- [ ] "First… Second… Finally" carrying a sequence? A table, or plain sentences.
- [ ] A sentence starting on a dangling "this" ("This means", "This ensures")? Name the noun the "this" stands for.
- [ ] Hedges stacked on one claim ("may potentially", "it seems that", "arguably")? State the claim, or name the uncertainty in its own sentence.
- [ ] "Not only X but also Y", "more than just X"? "X and Y".
- [ ] Bullets in changelog voice ("Added X", "Improved Y")? A subject for each, or a table.
- [ ] Scare quotes on an ordinary word (the "engine")? Drop them.
- [ ] A status emoji or a checkmark? Words.
- [ ] An exclamation mark? A full stop.
- [ ] A sentence that would read the same in any other project's document ("the system stays close at hand", "built for reliability")? Name the mechanism, the fact, or the number, or cut it.

## Vocabulary

| Replace | With |
| -- | -- |
| utilize, leverage | use |
| delve into | look at |
| robust, seamless, cutting-edge | the concrete property (fails over, needs no setup, new) |
| in order to | to |
| a number of, a variety of | the number, or "some" |
| it is important to note that | (nothing) |
| ensure that | make sure, or the verb alone |
| facilitate | help, allow |
| comprehensive | complete, or the scope in words |
| key, crucial, critical, essential, significant, powerful | the concrete property, or nothing |
| the implementation of, provide a solution for | implement, solve |
| impact (as a verb) | change, or the effect named |

## Three deliberate departures from common anti-slop guides

| Common rule | Here |
| -- | -- |
| Delete every adverb | Delete the ones that add no precision; keep the ones that narrow the claim |
| One em dash per 500 words | None: a colon or a comma does the job and reads the same in every font |
| Ban "X, not Y" outright | Allowed as a correction of a belief the reader holds; banned as a flourish |

Sources this pass condenses: stop-slop (hardikpandya), skill-deslop (stephenturner), tropes.fyi, anti-slop-writing (coderjatin), and the pstack plugin (github.com/cursor/plugins/tree/main/pstack, MIT, Lauren Tan) for the reusability test and the ambiguity table below.

## Patterns the checklist does not name

| Pattern | Instead |
| -- | -- |
| Negative listing ("Not X. Not Y. Z.") | State Z. |
| Anaphora: three sentences opening the same way | Vary the opening, or combine the points. |
| Superficial participle ("underscoring the need", "highlighting its importance") | Delete it, or name the evidence. An analysis that fits any subject says nothing. |
| False range ("from innovation to implementation to culture") | "From X to Y" only on a real scale with a real midpoint. |
| Listicle disguised as prose ("The first wall is… The second wall is…") | A list, or one sentence per point without the numbering. |
| Vague attribution ("experts argue", "studies show") | Name the source, or drop the claim. |
| Notability recital (every outlet that covered the subject) | The one source the sentence needs. |
| "Despite its X, Y faces challenges… continues to thrive" | The specific problem with its evidence, and no closing optimism. |
| Emphasis crutch ("Full stop.", "Let that sink in.", "Make no mistake.") | Delete. |

## Ambiguity

A cold reader fails on a sentence that reads two ways, not just on a jargon word.

| Pattern | Instead |
| -- | -- |
| "only" or "not" placed away from the word it changes ("only fails on growth" vs. "fails only on growth", two different claims) | Put the modifier next to what it changes. |
| A long noun string ("the proto import budget check script") | Break it up: "the script that checks the proto-import budget." |
| A parallel construction that drops a verb ("Phase 1 moves the converters and Phase 2 the runtime") | Give every branch its own verb. |
| A slash standing for a real choice ("a/b", "and/or") | Write it out: "a, b, or both." |

Source: Kohl, *The Global English Style Guide*, via the pstack plugin.

## Brevity

Length is a rule, not a taste. An answer stops when the decision and its one why are on the page.

- The verdict occupies the first sentence (or, when the source asks the reader to choose, the question the reader must settle). What led to it goes to the requester, never into the text.
- When the source makes a decision, state one recommendation and at most the obvious rejected alternative, in a sentence. When the source asks the reader to choose, keep each option with its outcome and cost, in a table.
- Say a thing once. A fact restated in the summary is cut from the summary.
- A reply in a session is six lines or fewer, unless the user asked for a document, a walkthrough or a per-phase report.
- Brevity comes from saying less, never from dropping articles or verbs. Sentences stay grammatical: the register is a colleague writing quickly, not a telegram.
