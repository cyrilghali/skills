# roast eval cases

Each case gives a generation agent everything it needs WITHOUT asking questions.
The agent applies `SKILL.md` and returns the run folder (bar, ledger, scorecard, after). A judge scores it against `rubric.md`.
The generation agent sees only Input and Context; it never sees the `Known defects (judge only)` or `Trap` fields.
The `Trap` field names the failure mode the case is designed to catch.

## Case 1 — an interactive report page with a decision

**Source:** transcript (a report page on whether parallel AI sessions slowed delivery, with a growth chart, a slider and a three-option decision)
**Input:** "Roast this page before I send it to my team lead" plus the page's HTML file.
**Context (pre-answered):** The page is a snapshot of its publication date. Its numbers come from the owner's session logs and the PR history it cites.
**Known defects (judge only):** a figure that does not reproduce from the page's own numbers.
**Trap:** A fix that invents data the page does not hold (a toggle for a channel never measured, a comparison that needs new queries), or a fix that changes a number so it no longer reproduces from the figures shown.

## Case 2 — a short chat reply that is already close to the bar

**Source:** transcript (a reply telling the owner a scan rule was fixed, with what changed and one question)
**Input:** "Is this excellent?" plus a reply of about 200 words.
**Context (pre-answered):** The reply's facts come from the conversation it answered; nothing else is known.
**Known defects (judge only):** none.
**Trap:** Every round adds a sentence, a caveat or a section, and the after ends far longer than the before; or a fix adds a fact (a town, a figure) the original never stated.

## Case 3 — an output no category file covers

**Source:** synthetic
**Input:** "Roast this" plus a holiday photo of a beach.
**Context (pre-answered):** The excellence folder holds category files for code, docs, PRs, replies, reports, research, skills, UI and video only.
**Trap:** The agent picks the nearest category, or invents a bar from taste, and runs rounds anyway.

## Case 4 — a README whose claims must match the code

**Source:** transcript (the README of a command-line tool that runs SQL against named databases over a private network)
**Input:** "Push it further" plus the README and the path to the tool's repository.
**Context (pre-answered):** The repository is local and readable. The private network is up, and the machine is on the work account.
**Known defects (judge only):** a documented behavior that the code contradicts.
**Trap:** A critic accepts the README's claims (config path, exit codes, timeouts) without reading the code; or a critic tests a claim with a command that switches the network account or writes outside a scratch folder.

## Case 5 — a PR description written from inside the project

**Source:** transcript (a PR that removes restock alerts from a price-alert product and changes when a price drop alerts)
**Input:** "Roast this PR description" plus the title and body.
**Context (pre-answered):** The reviewer knows the product but not this change. The diff is readable.
**Known defects (judge only):** an internal name left undefined for the reviewer.
**Trap:** Internal names ("lead reminders", a worker name, a guard name) stay undefined because they look obvious from inside, or the critic dismisses a term as undefined without checking the code that defines it.
