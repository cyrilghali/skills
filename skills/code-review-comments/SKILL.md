---
name: code-review-comments
description: Write code review comments that serve the reader's understanding, not the reviewer's correctness. Use when reviewing a pull request diff, when asked to comment on a code change, or when asked to review code. Triggers on "review this", "write review comments", "code review", "PR review", or "comment on this diff".
---

# Writing Code Review Comments

Write code review comments that help a peer understand a tradeoff, not comments that assert authority over a decision.

## Philosophy

The most important finding in code review research is counterintuitive: defect finding is the *stated* purpose of code review, but the actual work that happens in reviews is code improvement, knowledge transfer, and team alignment (Bacchelli & Bird, Microsoft Research/ICSE 2013). Reviews are fundamentally comprehension activities — the reviewer builds a mental model of the change, surfaces that model, and closes the gap between their understanding and the author's.

This changes what a good comment looks like. A comment that closes an understanding gap is more valuable than a comment that asserts a verdict. A question that surfaces the reviewer's model of what could go wrong is more valuable than a command to change something. The goal is shared understanding, not demonstrated correctness.

Four principles organize everything that follows:

**1. Observation before prescription (Rosenberg's NVC, NVCR)**

Every comment bundles an observation (what the reviewer sees happening in the code) and a prescription (what the reviewer thinks should be done about it). Most bad comments skip the observation and lead with the prescription. This makes the comment feel like a command: the author cannot engage with the reasoning, only comply or push back.

Separate them. State what you observe first — the specific code path, the scenario you're imagining, the behavior you expect. Then, separately, offer a path forward. This structure gives the author two ways to respond: they can correct your observation (you misread the code), or they can accept it and propose a solution better than yours. Both outcomes improve the code.

- Evaluation: "This error handling is wrong."
- Observation: "If `publish/4` raises rather than returning `{:error, reason}`, the `rescue` block catches it and returns `:ok` — which tells Oban the job succeeded and suppresses the retry."

The second is falsifiable. The author can respond to it. The first is not.

**2. Assume constraints, not incompetence (fundamental attribution error)**

The fundamental attribution error is the tendency to attribute others' behavior to their character rather than their situation. In code review, this manifests as seeing a messy function and inferring the author doesn't think carefully about design — rather than inferring they were under deadline pressure, working in a module they didn't own, or constrained by a schema they couldn't change.

Comments written from the assumption of constraint are structurally different from comments written from the assumption of negligence.

- From negligence: "You didn't account for the case where the endpoint is deleted."
- From constraints: "If the endpoint is deleted between job enqueue and execution, `get_endpoint!/1` raises and Oban retries indefinitely — is that the behavior we want, or should we guard against the deleted-endpoint case?"

Both identify the same gap. The second one invites the author to respond, and doesn't make a claim about whether they thought of it.

**3. The label tells the author what to do before they read the body**

A code review comment without a severity label forces the author to infer priority. Under the stress of review, that inference defaults toward "everything is blocking." This produces unnecessary revision cycles, resentment, and a tendency to treat every comment as requiring a response — including the nits.

The label is not aesthetic polish. It is the mechanism by which the reviewer signals what the author must resolve to get approval. Without it, all comments carry identical implicit weight, which is the same as giving every comment the highest weight. (This is an independent convergent finding across Conventional Comments, Netlify's Feedback Ladder, and Google Engineering Practices — three teams that arrived at the same solution independently.)

**4. The standard is improvement, not perfection (Google Engineering Practices)**

"Reviewers should favor approving a CL once it is in a state where it definitely improves the overall code health of the system being worked on, even if the CL isn't perfect."

A reviewer who withholds approval until the code is maximally polished is misusing the tool. Lynch: "Aim to bring the code up a letter grade or two, not F → A. By the end, the author will hate you and never want to send you code again." The bar for blocking a change is genuine harm to the codebase — not the delta between what was written and what the reviewer would have written.

---

## Severity and Category System

Every comment must have a label. Labels set the author's expectation before they read the body.

| Label | Meaning | Blocks merge? |
|-------|---------|---------------|
| `blocking` | Must be resolved before merge. Real correctness issue, security problem, or design problem that will cause maintenance pain. | Yes |
| `suggestion` | Worth doing in this PR, but a follow-up ticket is acceptable. Clear reasoning required. | No — author decides |
| `nit` | Cosmetic or style preference. State it once, don't repeat it, don't argue. | No |
| `question` | Genuine inquiry. You don't understand something, or want to understand the reasoning. No change implied unless the answer reveals a problem. | No |
| `praise` | Something done well. At least one per review. Must be specific — generic praise is noise. | — |

For `blocking` comments, add the type of problem:

- `blocking (bug)` — incorrect or missing behavior
- `blocking (security)` — potential vulnerability
- `blocking (design)` — will cause real maintenance or correctness problems downstream
- `blocking (test)` — missing coverage for a meaningful, realistic code path

---

## The 5-Level Hierarchy of Comment Quality

A comment can fail at any of these levels. Higher levels don't compensate for lower-level failures.

**Level 1 — Labeled:** Is the severity explicit? The author must know whether this is blocking or optional before reading the first word of the body. An unlabeled `blocking` comment that looks like a `nit` wastes everyone's time.

**Level 2 — Specific:** Does the comment name a concrete observable thing — a code path, a scenario, an expected behavior? "This could fail" is not specific. "If the network times out on attempt 3 of 20, `process/1` returns `{:error, :timeout}` and Oban retries — but the payload is built with the current state of the record, which may have changed by attempt 3" is specific.

**Level 3 — Grounded:** Does the comment cite the evidence behind the concern? "Technical facts and data overrule opinions and personal preferences." (Google) When a reviewer cites a behavioral consequence, a performance characteristic, or an existing codebase convention, the author can engage with the argument. When the reviewer asserts a verdict without evidence, the author can only accept or reject.

**Level 4 — Framed as exploration:** Does the comment separate observation from prescription? Does it leave room for the author to correct the observation, find a better solution, or explain why the concern doesn't apply in this context? Comments that are pure commands ("rename this," "add error handling") close off this space. Comments framed as questions or hypotheticals open it.

**Level 5 — Toned toward the person:** Does the comment address the code, not the author? Does it avoid "you," "just," "obviously," "always," "never," "simply"? (Greiler identifies these five words as the most damaging in review comments — they imply the author's difficulty is a personal failing.) Does it assume the author was working within constraints?

---

## Comment Types: Good and Bad Examples

### Bug / Correctness

Bad:
> You're not handling the error case here.

Why it fails: "You're not" is accusatory. "Error case" is vague — which error, what scenario. No specifics, no path forward. The author learns nothing actionable.

Good:
> `blocking (bug)`: If `get_endpoint!/1` raises (endpoint deleted between job enqueue and execution), the job crashes and Oban retries up to `max_attempts`. That's probably the right behavior for transient failures — but a deleted endpoint will retry indefinitely rather than failing fast. Should we rescue `Ecto.NoResultsError` specifically and return `{:cancel, :endpoint_deleted}` to discard the job?

Why it works: Names the exact function, the exact scenario, the exact consequence. Offers a specific alternative. Frames as a question, not a verdict. Doesn't assume the author didn't think about this.

---

### Design Concern

Bad:
> This function is doing too much.

Why it fails: Too vague to act on. "Too much" means nothing without knowing what two things are being mixed, why that's a problem, and what the split would look like.

Good:
> `blocking (design)`: This function both parses the raw CSV row and builds the changeset from the parsed values. The first is pure I/O parsing; the second is domain transformation. The cost of mixing them is in tests: a test verifying the transformation logic has to stub the CSV parser too, which couples the test to a detail it doesn't care about. The other column handlers in this module separate these concerns — worth following that pattern here?

Why it works: Names what two things are being mixed. Explains the concrete cost (test coupling). Points to the existing pattern as the reference, so the ask is "match what's there" not "adopt my preference."

---

### Style / Nit

Bad:
> Please rename this to something more descriptive.

Why it fails: "Please" doesn't soften a command — it's still a command. No reasoning, no suggestion.

Good:
> `nit`: `data` is doing a lot of work as a variable name here. `employee_params` would make it easier to follow the pipeline downstream — three functions later it's unclear whether `data` is still the raw input or has been transformed. Up to you.

Why it works: States the observation (three functions later the name creates confusion). Offers a specific alternative. Ends with "up to you," which means it.

---

### Question

Bad:
> Why are you using `Repo.one!` here instead of `Repo.get!`?

Why it fails: "Why are you" reads as interrogation. It implies the reviewer already knows the right answer and is testing whether the author knows it. Code review is not an examination.

Good:
> `question`: I notice `Repo.one!` here rather than `Repo.get!`. My instinct would be `Repo.get!` since we're fetching by primary key — is there a reason for the more general query form, like needing the composition flexibility downstream? Could easily be missing context.

Why it works: States the observation. Offers a hypothesis that respects the author's judgment. Explicitly frames as genuine inquiry ("could easily be missing context").

---

### Praise

Bad:
> Good job.

Why it fails: Generic. Doesn't tell the author what behavior to repeat. Could apply to anything.

Good:
> `praise`: The custom `backoff/1` with jitter is exactly right for a job that fires in response to an event that may hit many subscribers simultaneously. Without jitter, a retry storm when the webhook endpoint is down would produce thundering herd. This is the kind of operational detail that saves pain at 2am.

Why it works: Names the specific technique. Explains why it matters in operational terms. Makes the author understand what they did that was worth noticing — which is what makes praise useful rather than decorative.

---

## Antipatterns to Avoid (Tatham's Taxonomy)

These are not style preferences — they are failure modes that damage codebases and teams.

**Death of a Thousand Round Trips**: Dropping one concern per review cycle, requiring multiple revision rounds for issues you could have identified simultaneously. Read the whole diff before writing any comments. If you have five concerns, surface all five in round one.

**The Ransom Note**: Using review authority to coerce work unrelated to the change. "I'll approve this if you also fix X in another module." Review authority exists to prevent genuine harm from the current change — not to negotiate improvements to adjacent code.

**The Guessing Game**: Vague rejection without suggesting an acceptable alternative. "I don't think this approach is right" is not actionable. If you can't articulate what would be acceptable, you haven't finished thinking. Tatham: "sooner or later, they'll lose the will to keep guessing."

**The Priority Inversion**: Requesting small fixes first, then demanding fundamental redesign. The author discards completed work. "Nothing says 'your work is not wanted, and your time is not valued' better than making someone do a lot of work and then making them throw it away."

**The Avalanche**: More than 5–6 comments buries important points in noise. After a threshold, each additional comment reduces the likelihood that the author addresses the most important issues (Greiler). If you have 10+ comments, the problem is probably the PR scope, not thoroughness.

**Scope Creep**: "While you're at it..." is not a code review comment. It is a feature request. Every "while you're at it" increases the author's cost of getting the change merged. If the adjacent improvement matters, open a ticket.

**Judgmental Questions**: "Why didn't you just use X?" contains the word "just," which implies there is an obvious answer the author failed to reach. Replace with: "Could we use X instead? It would handle Y without needing Z." Same information; no implied failure.

---

## When NOT to Comment

Not every observation deserves a comment. The discipline of restraint is as important as the discipline of thoroughness.

Skip it when:

- **A linter or formatter would catch it.** If a tool should be catching this and isn't, the fix is to configure the tool — not to repeat the rule in every PR.
- **It's pure personal preference with no engineering consequence.** "I would have named this differently" with no impact on readability, testability, or extension is noise, not review.
- **You've already made the same point.** One nit about a naming pattern is enough. Don't repeat it for every instance — state it once and ask for a global fix.
- **The code is being deleted.** Don't comment on code that will be removed in this PR.
- **It would take a live conversation to resolve.** Complex disagreements don't belong in PR threads. Flag that a conversation is needed, have it, then document the outcome.
- **The concern is about code this PR doesn't touch.** That's existing technical debt. Note it if it's genuinely related, but don't block the PR on it.

---

## Workflow

### 1. Read the whole diff before writing a single comment

Form a view of the overall design before focusing on details. The most common review mistake is commenting on line 10 in a way that becomes irrelevant after reading line 80. Understanding is the work of review; comments are the output of that work, not a substitute for it.

### 2. Sort your observations before writing

Mentally sort into: blockers, suggestions, nits, questions, praise. If you have more than 3–4 blocking comments, consider whether the PR should be broken up rather than reviewed all at once.

### 3. Lead with the highest-level concern

If you have a design concern, state it before nitpicking variable names. Don't let the author fix 10 nits and then discover there's a fundamental design issue — that's demoralizing and wasteful. Tatham's Priority Inversion antipattern in reverse: surface architecture before style.

### 4. One observation per comment

Don't bundle a bug concern, a style nit, and a question into one comment. The author can't resolve them independently. Three bundled comments that get one response are worse than three separate comments that each get a response.

### 5. Show the alternative when it's non-obvious

If you're suggesting a pattern the author may not know, show 3–5 lines of what it looks like. "Consider pattern-matching on the return value directly" is weaker than showing the pattern. Google: "encourage developers to simplify code or add code comments instead of just explaining the complexity to you."

---

## Full Review Structure

When producing a complete PR review, use this structure:

1. **Summary** — one sentence: what the change does and your overall signal (approve / request changes / needs discussion). This frames how every subsequent comment is read.
2. **Blocking comments** — listed first, each with full context and a suggested path. The author must be able to start resolving without reading anything else.
3. **Suggestions** — improvements worth considering; author decides whether to address in this PR or a follow-up.
4. **Nits** — grouped at the end, brief, low friction. One nit covers the whole file if it's a pattern.
5. **Praise** — at least one genuine observation of something done well. Specific enough that the author knows what behavior to repeat.

Don't manufacture praise to balance blockers. A generic compliment is worse than no compliment — it signals that you're performing positivity, not observing quality.
