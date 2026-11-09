---
name: deep-research
description: Turns a question into a sourced answer by splitting it into sub-questions, searching wide in parallel (semantic search and page extraction when those tools are present, the host's web search and fetch otherwise), reading the sources that matter in full, triangulating every load-bearing claim across two independent sources and writing the answer first with each claim linked to the page it came from. Use when the user says "research X", "deep research", "what's the state of the art on", "compare tools for", "find the best setup for", "étude sur", "explore what X's API or logs expose", or "what data can we get from vendor X".
metadata:
  category: research
---

# Research a question into a sourced answer

Treat a search result as a guess about a page, a page as a claim by whoever wrote it, and a fact as what two independent pages agree on. Move each thing you learn up that ladder, and say which rung it reached.

## Pin the question

Restate the question as the decision it serves: which tool, whether to do X, what a number is. List the sub-questions whose answers settle it. Use one sub-question when the question asks for a single fact, and rarely more than seven. You are done when every sub-question names what counts as an answer: a number with its date, a named source, or a comparison on stated criteria.

## Search wide

For each sub-question, run the searches in parallel. Run a semantic search (an Exa tool, when the tool list has one) phrased as the sentence you hope to find. Run a keyword search (the host's web search) with two or three distinct phrasings. Collect the candidate URLs with the sentence that surfaced each one. You are done when each sub-question has five to ten candidates from at least two different domains, or the search log shows the field is thinner than that.

## Read every page you intend to cite

Fetch every candidate you intend to cite, with a page extraction tool when present and the host's fetch otherwise. Pull the sentence, number or table that answers the sub-question, with its date. Drop a URL that does not open, or a page that does not say what the snippet promised; do not keep it as a maybe. Mark a claim `inferred` when you reached it by combining what the page says elsewhere, and cite the page for the premise only, never for the conclusion. You are done when every retained claim has a quoted anchor from the fetched page, or is marked `inferred`.

## Triangulate every load-bearing claim

A load-bearing claim is one that changes the answer. For each one, find a second source that shares no author, vendor or press release with the first, and that states the same claim: the same mechanism, the same number, the same error message.

Treat a page that says something adjacent (a related but different event, error or condition) as a different claim, because citing it as the second source is the commonest way a `confirmed` turns out false. Treat a vendor's page about its own product as evidence of the claim, not of the fact, and a benchmark published by a contestant as a claim. When sources disagree, record the disagreement as a finding with both sides and their dates. You are done when every load-bearing claim carries one of four marks:

- `confirmed`: two independent sources state it;
- `single-source`: one source states it, and you name it;
- `inferred`: you reasoned it from a stated premise, and you show the reasoning;
- `contested`: sources disagree, and you name both.

## Stop when widening stops paying

Prefer coverage over depth until this step; then go deep on the weakest sub-question. After the first pass, fetch two more sources for it. If neither changes a claim's status, the research is done. You are also done when the honest answer is "no reliable source", written as such.

## Write the answer in the register of REGISTER.md

Make the heading the question. Make the first sentence the answer, then give one why, then a table of the details with a source link on every row, then a bias line naming who wrote what. Answer the question as asked: answer a yes/no question about risk with the worst outcome the table shows, not with a reassuring property that also holds. Under a screen, the reply is the document; longer than that, write a Markdown file at the path the user named. You are done when every link in the document was fetched in the reading step, every number carries its date, and the first sentence agrees with the worst row of the table.

Record the run with `skill-record deep-research sources=S claims=C triangulated=K/C`. S is the number of pages the document cites, C the number of load-bearing claims and K how many of them are `confirmed`. Record once, only when the run finished; a dry run or an aborted run records nothing.

## Check your work against this example

The question is "what are the free-tier limits of a hosting service?" The sub-questions are the request quota, the storage cap, the bandwidth cap and the overage rules. The pricing page and an independent review both state the request quota, so that row is `confirmed`. The storage cap appears only on the pricing page, so that row is `single-source`. The bandwidth cap appears nowhere; it is derived from a stated monthly total, so that row is `inferred` and cites only that total. Each row links the page that was read and carries its date. The bias line says which figures came from the provider itself.

## Hold these rules in every step

- Cite only a page you read. The search result's summary is never the source.
- Give every number a date and a source. An undated number is a rumour.
- Cite a source for what it says, never for what follows from it. The row's status says which.
- Report disagreement between sources. Never average it away.
- Say in every conclusion how many independent sources hold it up.
