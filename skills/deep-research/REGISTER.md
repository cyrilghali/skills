# The register of a research write-up

How the answer is laid out so a reader gets the decision in the first line and the evidence on demand. Condensed from public anti-slop writing guides and the house rules of the author's `prose` skill; the mechanical checks are listed so a reader can apply them without a tool.

## Shape

| Element | Rule |
| -- | -- |
| Heading | the question the section answers, with its alternatives inside it ("Which database: engine A, engine B or engine C?") |
| First sentence | the answer to the question as asked, with its status (`confirmed`, `single-source`, `inferred`, `contested`); it agrees with the worst row of the table |
| Second | one why, in one sentence |
| Details | a table, one row per claim, with columns for the claim, the number and its date, the status, and the source link |
| Bias line | who wrote each source and what they sell; a vendor's benchmark result is flagged as such; omitted when no source has a stake |
| Open | what no reliable source settled, named as such; omitted when nothing is open, never padded with reassurance |

## Sentence rules

- Answer first; context after, only where it changes the reading.
- One idea per sentence; under 30 words.
- Plain words a stranger follows; a project term is restated in plain words on first use.
- No em dashes; a comma, a colon or two sentences instead.
- No bold for emphasis; a strong idea carries itself.
- Adverbs stay when they are precise (`independently`, `twice`), go when they are hedges (`very`, `really`, `basically`).
- "X, not Y" only when correcting a belief the reader holds.
- Nothing about how the research was done: the trail (searches run, pages skipped) stays out of the document.

## Source lines

Every row and every inline claim links the page that was read, as a Markdown link on the page's own title. A number reads `4.2 ms p99 (May 2026, vendor blog)`. Two sources for one claim are listed in the same cell. A contested claim shows both values with both sources.

## Length

Under a screen (about 40 lines) the reply is the document. Beyond that, a Markdown file, and the reply is the first sentence plus the path.
