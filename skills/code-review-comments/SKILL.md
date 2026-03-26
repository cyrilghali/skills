---
name: code-review-comments
description: Write code review comments that serve the reader's understanding, not the reviewer's correctness. Use when reviewing a pull request diff, when asked to comment on a code change, or when asked to review code. Triggers on "review this", "write review comments", "code review", "PR review", or "comment on this diff".
---

# Writing Code Review Comments

Write code review comments that help a peer understand a tradeoff, not comments that assert authority over a decision.

## Philosophy

The person who wrote the code you are reviewing made reasonable choices with the information they had. They are a peer, not a student. Your goal is not to find mistakes — it is to build shared understanding of the code so the team can maintain it confidently.

This changes how you write. A comment that says "this is wrong" closes the conversation. A comment that says "I want to understand the reasoning here — if X happens, would we expect Y?" opens it. The first positions you as a judge; the second positions you as a collaborator examining the same problem.

Three principles organize this:

**1. Match your comment to the decision being made.** Abstraction laddering (Horst Rittel's design thinking technique, popularized by modern practitioners) means you can frame a concern at different levels: "this variable name is unclear" (implementation) vs. "this function mixes two responsibilities" (design) vs. "this approach makes the system harder to extend" (architecture). Don't conflate them. A style nit dressed up as an architectural concern wastes everyone's time. An architectural concern buried in a style suggestion gets ignored. Name the level you're operating at.

**2. Separate observation from prescription.** Feynman's principle for intellectual honesty: distinguish what you *observe* ("when the job fails on attempt 10, the error isn't surfaced to the caller") from what you *believe should be done* ("consider returning the error from `process/1` rather than swallowing it"). Many comments skip the observation entirely and jump to the prescription — this feels like a command rather than a reasoned request. State what you see, then offer a path forward. This also invites the author to correct your observation if you misread the code.

**3. The reader of your comment will be the author, feeling some mix of pride and exposure.** Psychological safety in code review isn't soft — research shows destructive feedback measurably reduces motivation to continue working (-0.13 average vs. +1.11 for constructive feedback). That isn't a reason to avoid hard feedback. It is a reason to frame hard feedback as problem-solving, not judgment.

---

## Severity and Category System

Every comment should have a label that sets the author's expectation for what action is needed.

| Label | Meaning | Blocking? |
|-------|---------|-----------|
| `blocking` | Must be resolved before merge. Real bug, security issue, or design problem that will cause maintenance pain. | Yes |
| `suggestion` | Worth doing in this PR, but you could also open a follow-up. Improvement with clear reasoning. | No (author decides) |
| `nit` | Purely cosmetic or style preference. State it once, don't repeat it, don't argue about it. | No |
| `question` | Genuine inquiry. You don't understand something, or you want to understand the reasoning. No change implied. | No |
| `praise` | Something done well. At least one per review. | — |

Use these as prefixes in your comments: `blocking:`, `suggestion:`, `nit:`, `question:`, `praise:`.

For `blocking` comments, add a sub-category to signal what kind of problem it is:

- `blocking (bug)` — incorrect behavior
- `blocking (security)` — potential vulnerability
- `blocking (design)` — will cause real maintenance or correctness problems
- `blocking (test)` — missing coverage for a meaningful code path

---

## Comment Types: Good and Bad Examples

### Bug / Correctness

Bad:
> You're not handling the error case here.

Why it fails: accusatory "you", no specifics about what case, no suggestion.

Good:
> `blocking (bug)`: If `get_endpoint!/1` raises (endpoint deleted between job enqueue and execution), the job will crash and the queue will retry it. That's probably correct — but should we guard against the case where the endpoint is soft-deleted but still in the DB? A deleted endpoint retrying 10 times seems wasteful.

Why it works: Specific scenario, explains the consequence, frames as a question rather than a command, respects that the author may have already considered this.

---

### Design Concern

Bad:
> This function is doing too much.

Why it fails: Too vague to act on. What does "too much" mean in this context?

Good:
> `blocking (design)`: This function both fetches the CSV row and transforms it into a changeset. I'd consider splitting those — the fetch is pure I/O, the transform is pure data shaping. Right now a test that wants to verify the transformation logic has to stub the CSV parse too. Does that match how other column handlers are structured in the codebase?

Why it works: Names what two things are being mixed, explains the concrete cost (test complexity), points to existing convention as the reference.

---

### Style / Nit

Bad:
> Please rename this to something more descriptive.

Why it fails: "Please" doesn't soften a command. Still a command.

Good:
> `nit`: `data` is doing a lot of work as a variable name here — `employee_params` would make it easier to follow the pipeline downstream. Up to you.

Why it works: Explains *why* the name matters (downstream readability), ends with deference to the author.

---

### Question

Bad:
> Why are you using `Repo.one!` here instead of `Repo.get!`?

Why it fails: "Why are you" reads as interrogation. Also implies there's a right answer the reviewer already knows.

Good:
> `question`: I notice we use `Repo.one!` here rather than `Repo.get!`. Is that because we need the query composition flexibility, or is there a simpler fetch that would work? Curious if there's a reason I might be missing.

Why it works: States the observation neutrally, offers a hypothesis, explicitly frames as genuine inquiry.

---

### Praise

Bad:
> Good job.

Why it fails: Generic. Doesn't reinforce *what* behavior to repeat.

Good:
> `praise`: The custom `backoff/1` with jitter is a nice touch — it prevents thundering herd if a batch of webhooks all fail at the same time. This is exactly the kind of operational detail that saves pain at 2am.

Why it works: Names the specific technique, explains why it matters operationally, makes the author understand what they did that was worth noting.

---

## Workflow

### 1. Read the whole diff before writing a single comment

Form a view of the overall design before focusing on details. The most common review mistake is commenting on line 10 in a way that becomes irrelevant after reading line 80.

### 2. Identify the comment types you have

Mentally sort your observations into: blockers, suggestions, nits, questions, praise. If you have more than 3-4 blocking comments, consider whether the PR should be broken up rather than reviewed all at once.

### 3. Lead with the highest-level concern

If you have a design concern, state it before nitpicking variable names. Don't let the author fix 10 nits and then discover there's a fundamental design issue — that's demoralizing and wasteful.

### 4. One observation per comment

Don't bundle a bug concern, a style nit, and a question into one comment. The author can't resolve them independently. Separate them.

### 5. Provide a code example when your suggestion is non-obvious

If you're suggesting a pattern the author may not be familiar with, show it. "Consider pattern matching on the return value directly in the function head" is weaker than showing 3 lines of what that looks like.

---

## When NOT to Comment

Not every observation deserves a comment. Skip it when:

- **A linter or formatter would catch it.** Don't manually enforce what `mix format` or `mix credo` should catch. If a linter isn't catching it, the fix is to configure the linter — not to repeat the rule in every PR.
- **It's a matter of pure personal taste with no engineering consequence.** "I would have named this differently" with no impact on readability, testability, or extension is noise.
- **You've already made the same point.** One nit about a naming convention in the file is enough. Don't repeat it for every instance.
- **The code is being deleted.** Don't comment on code that will be removed.
- **You'd need the full context of a live conversation to resolve it.** Complex disagreements don't belong in PR threads. Flag them and have the conversation async or in person, then document the outcome.

---

## Codebase Conventions Matter More Than Personal Taste

When reviewing, apply the project's established conventions as the reference point rather than personal preference. Before commenting on a pattern, check if it's how the rest of the codebase does it. If it is, don't flag it — even if you'd personally do it differently. Consistency across a codebase is worth more than local optimality.

When you find a genuine convention violation, frame it as such: "The rest of the codebase uses pattern X here — was this an intentional departure?" This gives the author a chance to explain rather than defend.

---

## Full Review Structure

When producing a complete PR review (not just individual comments), structure it as:

1. **Summary sentence** — one line: what the change does and your overall signal (approve / request changes / needs discussion).
2. **Blocking comments** — list first, each with full context and a suggested path.
3. **Suggestions** — improvements worth considering; author decides.
4. **Nits** — grouped at the end, brief, low friction.
5. **Praise** — at least one genuine one.

Don't manufacture praise just to balance blockers. A fake compliment is worse than no compliment.
