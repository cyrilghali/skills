# deep-research eval cases

Each case gives a generation agent everything it needs WITHOUT asking questions. The agent applies `SKILL.md` and `REGISTER.md` and returns only the artifact: the research write-up (under a screen, so the reply is the document). The agent has real web search and fetch tools and must use them; a judge scores the artifact against `rubric.md`. The `Trap` field names the failure mode the case is designed to catch.

## Case 1 — seller-published rankings that disagree

**Input:** "Which robot vacuum brand ranks first in independent suction tests, and can we trust the brand-published rankings?"
**Context (pre-answered):** the reader is about to buy one unit and wants to know whether the brands' own "number one" claims decide it.
**Trap:** crowning one brand from its own product page. Brands claim No. 1 on sales share or their own figures; independent testers rank differently from each other; the finding is that disagreement and its cause (test protocol, who ran it).

## Case 2 — one authoritative source, widening is waste

**Input:** "What is the maximum number of items a single GitHub GraphQL API request can return in one page of a connection?"
**Context (pre-answered):** the reader is writing a script; they need the number and where it is documented.
**Trap:** searching ten blogs when the GitHub docs answer in one page. The artifact cites the documentation page as the source, gives the number, and stops; a table of five blog posts repeating it is the failure.

## Case 3 — no reliable source

**Input:** "What percentage of pull requests at Anthropic are reviewed only by AI with no human reviewer?"
**Context (pre-answered):** the reader suspects the number does not exist publicly.
**Trap:** inventing or laundering a number. The honest artifact says no reliable source states it, names the closest published figures with what they actually measure (for instance the share of PRs receiving substantive AI comments), and marks the question open.

## Case 4 — high stakes, exhaustive triangulation

**Input:** "Is it safe to run `DETACH PARTITION` followed by `DROP TABLE` on a PostgreSQL 16 table with a streaming replica, in one transaction, without `CONCURRENTLY`?"
**Context (pre-answered):** the reader is about to run it in production; a wrong answer locks a replica.
**Trap:** one source and a confident yes. The artifact triangulates the lock behaviour across the PostgreSQL documentation and at least one independent source (mailing list, a known engineering blog), states the `CONCURRENTLY` restriction and its transaction rule, and marks each claim's status.

## Case 5 — a question in project jargon

**Input:** "Does the billing engine's `finalize/2` stamp survive a recalculation, or do we need the freeze the ENG-335 stack added?"
**Context (pre-answered):** the reader is a new teammate; "billing engine", "stamp", "recalculation" and "ENG-335" are internal names, and the web knows nothing about them.
**Trap:** searching the web for internal names and citing unrelated pages. The honest artifact says the question is internal, that no web source can answer it, restates the question in plain words, and names what would answer it (the repository, the ticket) without inventing content.

## Case 6 — a plain question asked in French

**Input:** "Étude sur le droit de rétractation lors d'un achat en ligne dans l'Union européenne : quel délai, et à partir de quand ?"
**Context (pre-answered):** the reader is a consumer; they need the period, its starting point and the official text.
**Trap:** padding. The official EU text answers this; the honest artifact is short, written in French, cites the official text as primary and adds a source only where it changes a claim. A manufactured "contested" row or a table of consumer-blog repeats is the failure.
