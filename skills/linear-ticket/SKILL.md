---
name: linear-ticket
description: Write a clear, actionable Linear ticket. Use when the user wants to create a bug report, feature request, tech debt ticket, or investigation spike. Triggers on "write a ticket", "create a Linear issue", "open a ticket", "file a bug", or when the user describes a problem or request that needs to be tracked.
---

# Writing Linear Tickets

Write Linear tickets that give an engineer enough context to start — and enough room to think.

## Philosophy

A ticket is not a specification. It is a placeholder for a conversation that has already happened or still needs to happen. Jeff Patton's observation cuts to the core: "shared documents aren't shared understanding." The document is evidence that understanding *might* exist — the ticket author's job is to make it real enough that the builder can start working without interruption, while leaving their expertise fully engaged.

This sets up the central tension: too little information and the builder stalls, guesses wrong, or solves the wrong problem. Too much information and the builder becomes a transcriber, not a thinker — their expertise is atrophied, not used.

### The core problem: dead-level abstracting

S.I. Hayakawa's abstraction ladder explains most bad tickets. Hayakawa described language as existing on rungs: at the bottom, concrete specifics ("Bessie the cow"); at the top, pure abstractions ("wealth"). Most failed communication is *dead-level abstracting* — writing stuck at a single rung without moving up or down.

Tickets fail in both directions:

**Dead-level abstracting upward:** "Improve the user experience of imports." No toehold. The builder cannot determine what "improve" means, what behavior to change, or when they're done. It's a goal dressed as a task.

**Dead-level abstracting downward:** "Add a `charset` column to the `employee_imports` table, set it to `utf8mb4`, and update the `ImportParser` to use it." All rungs removed except implementation coordinates. The builder cannot question whether this is the right diagnosis, whether the real issue is elsewhere, or whether there is a simpler fix.

The right rung is where the builder understands the problem completely and still has to do the thinking about how to solve it. A practical test: could two thoughtful engineers read this ticket and propose different valid solutions? If yes, the rung is right. If the solution is implicit in the problem statement, the rung is too low.

### Diagnosis, not prescription

Write the problem statement as if you have no solution in mind. This is harder than it sounds — most tickets are written after a solution has occurred to the author, and the problem statement gets unconsciously shaped around it.

The prescription-as-diagnosis failure looks like: "Fix the encoding handling in the import parser." This embeds a diagnosis (the issue is in the import parser) and a solution direction (encoding handling) in what claims to be a problem statement. If the actual bug is at the HTTP layer — if the file is being mangled on upload before it ever reaches the parser — this ticket sends the builder to the wrong place.

The diagnosis looks like: "Three customers this month couldn't import employee files with names containing é, ñ, or similar characters. The import shows a success message but creates no records." This states the observable gap without hypothesizing its cause. The builder starts with clear symptoms and does the diagnostic work themselves — which is their job.

### Appetite, not estimate

Ryan Singer's distinction is precise: "Estimates start with a design and end with a number. Appetites start with a number and end with a design."

An appetite is a time budget set before the solution is known. It forces the ticket author to decide how much this problem is worth solving — which is a product and business decision, not an engineering decision. Once the appetite is explicit, scope becomes the variable: "given two weeks, what's the most important version of this to build?"

Tickets without appetite force engineers to make an implicit bet: they try to build the complete solution they imagine, with no constraint to force tradeoffs. Either they under-build (no scope guidance) or over-build (gold plating), and either way the result is arbitrary.

### Out-of-scope bounding is a gift

Every ticket should state what it is *not* asking for. This is not a limitation — it is a decision made in advance by someone with more context, preventing the builder from spending time on work that will be thrown away or that has been deliberately deferred.

Singer names these "no-gos." Without them, engineers reasonably infer that related-looking problems are in scope. The CSV import ticket that doesn't say "out of scope: handling non-UTF-8 files" leaves the builder uncertain: should I add charset detection? UTF-16 support? SFTP imports? Each looks adjacent. The no-go removes that uncertainty before the builder wastes time on it.

### Tickets preserve autonomy for cognitive work

Daniel Pink's research on motivation: for cognitive work — design, problem-solving, engineering — intrinsic motivation (autonomy, mastery, purpose) outperforms extrinsic reward. An over-specified ticket attacks all three:

- **Autonomy:** It removes the builder's ability to make implementation decisions.
- **Mastery:** There is nothing to figure out — the thinking has already been done.
- **Purpose:** The problem the work serves is buried under implementation steps. The builder loses the thread of why it matters.

An engineer who reads a ticket and feels like they're executing instructions rather than solving a problem will do worse work — not from lack of effort, but from lack of engagement. The ticket format shapes the quality of the thinking that follows.

### Herbert Simon: specify the right things, not everything

Simon's bounded rationality: agents have limited information, limited time, limited cognitive capacity. The ticket author cannot know everything about how the solution will work. Any attempt to fully specify the implementation embeds the author's current ignorance into the requirement.

The question is not "what is the complete specification?" It is "what is the minimum specification that enables good decisions?" For a bug: the observable symptoms, reproduction steps, and expected behavior. For a feature: the user need, acceptance criteria, and appetite. For a refactor: the current friction, the improved state, and why now. Everything else is the engineer's to work out.

---

## Ticket Types

Different problems need different structures.

### Bug Report

A bug is a gap between observed behavior and expected behavior. The ticket should make that gap unmistakable without hypothesizing its cause.

**What to include:**
- What the user was doing (the trigger, not the cause)
- What happened (observed behavior — concrete, specific)
- What should have happened (expected behavior)
- Reproduction steps, if known (numbered, atomic, complete)
- Frequency and scope (always? sometimes? for which users or conditions?)
- Customer or business impact

**What to omit:**
- Root cause hypotheses (put them in a note, never in the problem statement — they corrupt the diagnosis)
- Implementation steps
- File paths, function names, database tables — unless the bug is definitively isolated there

**Title format:** "Employee CSV import silently fails for files with accented characters" — not "Fix the import bug." The title should describe the gap, not the desired action.

**Good example:**
> When a CSV file contains employee names with accented characters (é, ñ, ü, etc.), the import appears to succeed — the UI shows a success message — but no records are created in the system. Three customers have reported this month; imports with plain ASCII names work correctly.
>
> Steps to reproduce:
> 1. Prepare a CSV with at least one name containing an accented character (e.g. "José García")
> 2. Upload via the employee import flow
> 3. Observe the success toast
> 4. Check the employee list — no new records appear
>
> Expected: records are created for all rows, including those with accented characters.
> Actual: no records created, no error surfaced.
>
> Frequency: reproducible for any file with accented characters. Plain ASCII files succeed.
> Impact: customers with non-English employee rosters cannot use this feature.

**Bad example:**
> Fix the ImportParser so it handles UTF-8 correctly. The issue is in charset handling when reading CSV rows.

The bad example embeds a diagnosis (the ImportParser is at fault) and a solution direction (charset handling) in what claims to be a problem statement. If the bug is actually at the upload layer — if the file is being mangled before the parser sees it — this ticket sends the engineer to the wrong place.

---

### Feature Request

A feature ticket describes a capability the system doesn't have, framed around the user's job to be done. Christensen: "A job is not a task. A job is progress." The user isn't asking for a feature — they're trying to make progress in their work. The ticket should describe the progress, not the feature.

**What to include:**
- Who needs this and why (the job to be done — what progress are they trying to make?)
- What the current experience is (the gap, stated concretely)
- What "done" looks like from the user's perspective
- Acceptance criteria (observable behavior — testable, outcome-focused)
- What's explicitly out of scope
- Appetite (a time budget: S/M/L, or a number of days)

**What to omit:**
- Database schema
- API endpoint signatures (unless the API contract is itself the deliverable)
- Component names, file paths
- The implementation approach (this is what the appetite + acceptance criteria define the space for)

**Acceptance criteria test:** Each criterion should be verifiable with a yes/no. "The export succeeds" is testable. "The export is performant" is not. "The export succeeds for files up to 50,000 rows within 30 seconds" is testable. Write the former kind.

**Good example:**
> API clients currently have no visibility into rate limit state until they receive a 429. This produces thundering-herd failures: clients retry immediately, compounding the problem, because they have no signal about when the window resets.
>
> The job: clients need to pace their requests to avoid hitting the limit, and need to know how long to back off when they do.
>
> The standard for surfacing this (Retry-After, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset) is documented in IETF draft-ietf-httpapi-ratelimit-headers and used by GitHub and Stripe — clients often already implement handling for this shape.
>
> Acceptance criteria:
> - [ ] Every API response that goes through the rate limiter includes these headers, populated with the current state for that client
> - [ ] A client that reads Retry-After and waits before retrying does not receive a second 429 in the same window
> - [ ] The OpenAPI spec documents these headers
>
> Out of scope: changing rate limit thresholds, adding per-endpoint limits, client SDK changes.
> Appetite: M (one week).

**Bad example:**
> Add Retry-After, X-RateLimit-Remaining headers to the v3 API. Update the RateLimiter plug to inject these headers. See the plug pipeline in router.ex.

The bad example skips the "why" entirely and jumps to implementation coordinates. An engineer following it would add headers without understanding what clients will do with them — meaning they can't make good decisions about what values to put in them, or whether the headers are sufficient on their own.

---

### Tech Debt / Refactor

Tech debt is invisible by nature. The primary job of a tech debt ticket is making the cost concrete enough to compete for prioritization alongside features.

"Too many responsibilities" is a conclusion, not a description. "We can't write a test for encoding logic without also setting up CSV parsing, validation, and record creation" is a description. Lead with the friction.

**What to include:**
- Current state and the friction it creates (concrete: this is how long X takes, this is what breaks when you change Y)
- The improved state (measurable — not "cleaner" but "a new validation rule can be added and tested without reading the whole pipeline")
- Why now (what is making this worth doing, what is the cost of deferring)
- Appetite

**What to omit:**
- The exact refactor strategy (the engineer doing the work should own this — this is the no-gold-plating principle applied to tech debt)
- Promises about future velocity — state the current friction instead; let the reader draw their own conclusions

**Good example:**
> The employee import module currently handles CSV parsing, validation, encoding normalization, and record creation in a single pass. Adding a test for any one behavior requires wiring up all the others. When the encoding bug from RIO-412 appeared, it took two days to isolate because we couldn't write a test for the encoding path in isolation.
>
> The improved state: each concern can be tested independently. A new validation rule or a new file format doesn't require reading the full module to understand the impact.
>
> Why now: we're about to add SFTP imports and a second file format (XLSX). Adding those without this work will compound the problem.
>
> Appetite: M. This shouldn't touch the API layer or change any external behavior — just restructure internals.

**Bad example:**
> Refactor the ImportParser module. It has too many responsibilities and should be split up.

---

### Spike / Investigation

A spike is a time-boxed investigation with a specific question to answer. The output is knowledge, not code.

The title of a spike is always a question. "Investigate authentication options" is not a spike title — "Determine whether Auth0 or a home-built OAuth server is viable for our compliance requirements within a 6-week window" is.

**What to include:**
- The specific question(s) to answer (not "explore X" — every spike needs a question)
- Why this uncertainty blocks other work
- The time box (explicit, enforced — if the answer arrives early, stop)
- What the output should look like (written summary? prototype? decision? ADR?)

**What to omit:**
- Anything that implies the answer is already known
- Open-ended scope — if there's no question, there's no spike

**Good example:**
> Before hardening the import pipeline against encoding issues, we need to know what we're hardening against. We don't know whether HRIS providers like BambooHR and Workday export UTF-8, whether they document encoding guarantees, or whether the format varies by customer configuration.
>
> Questions to answer:
> 1. What file formats and encodings do BambooHR and Workday use in their CSV/SFTP exports?
> 2. Do they document this? Are there known edge cases in the wild?
> 3. Are there providers that export in a format we can't easily normalize?
>
> Output: written summary on this ticket, answering the three questions with enough specificity to inform the encoding work.
> Time box: 2 hours.

**Bad example:**
> Investigate encoding issues in HRIS integrations.

No question, no time box, no output format. This ticket will either run forever or produce a vague doc that doesn't unblock anything.

---

## The Five Failure Modes

These are patterns worth recognizing by name.

**1. Solution masquerading as problem.** The problem description embeds the approach. "Add a `charset` column to the `employee_imports` table" — this is an implementation step dressed as a problem. If you removed the solution, there would be nothing left. The test: can you state what goes wrong for a user, without mentioning code?

**2. Scope creep by omission.** The ticket says what to build but not what not to build. Engineers correctly assume that related-looking problems are in scope unless told otherwise. Without explicit no-gos, scope expands to fill whatever time the engineer has.

**3. Context rot.** The ticket was clear when written — to the person who wrote it, standing in the context of a specific conversation. Two weeks later, the builder starts the work and finds the ticket makes assumptions the reader can't recover. Tickets written for the author's current mental model instead of the builder's future mental state decay quickly.

**4. Gold plating.** Database schema, API signatures, UI layouts, pixel dimensions. The builder's job is reduced to transcription. This embeds the author's current (possibly wrong) understanding as a constraint, prevents the builder from discovering better approaches, and destroys the autonomy that makes cognitive work worth doing.

**5. Memory dump.** Everything the author knows — background history, related tickets, design alternatives considered, edge cases, open questions, file names — without prioritization. Signal lost in noise. The builder cannot tell what is essential vs. informational vs. speculative. Cost: cognitive load before a line of work begins.

---

## What Every Ticket Should Answer

Regardless of type, three questions should always be answerable from the ticket:

1. **Why does this matter?** Who is affected, how much, and what happens if we don't address it?
2. **What does done look like?** Observable behavior from the user's perspective, not internal system state.
3. **What's out of scope?** Explicitly bound the work. Silence implies everything adjacent is in scope.

---

## Workflow

### 1. Gather context

Start with what the user gives you. They might provide a Slack message, a customer complaint, a vague description, or a detailed problem statement. Ask clarifying questions if you're missing the impact, the reproduction case, or the acceptance criteria — but don't over-interview. Start with what you have.

If given a Linear ticket ID or URL, fetch it via the Linear MCP tools to read the current state.

### 2. Research the codebase (for bugs and features)

For bugs: understand the system well enough to write a precise problem statement — what the trigger is, what the gap looks like, how to reproduce it. You are not diagnosing the root cause in the ticket. But codebase knowledge tempts you toward prescription: if you find the likely cause, put it as a hypothesis in a note, not as the problem statement.

For features: understand the existing surface so acceptance criteria are grounded in how the system actually works.

Use subagents to parallelize exploration of large codebases.

**Note on scope:** This skill is for tickets written for human engineers. If you need to write a ticket optimized for an AI agent to implement (with file lists, implementation steps, and test scaffolding), that is a different format.

### 3. Draft the ticket

Pick the right type. Write the problem statement first, before thinking about solutions. Apply the abstraction test: could two thoughtful engineers read this and propose different valid implementations? If not, move up a rung.

Title format: `[Noun phrase describing the gap or capability]` — not a verb command. "Employee CSV import silently fails for accented characters" is scannable. "Fix the import bug" is not.

### 4. Publish or display

If Linear MCP tools are available, use `mcp__linear__save_issue` to create the issue, or update an existing one. Ask the user which team to assign if not specified.

If no MCP tools are available, display the ticket as formatted markdown for copy-paste.

---

## Templates

### Bug Report

```markdown
**[Noun phrase describing the observable gap]**

[1-2 sentences: what the user was doing and what went wrong. Concrete and specific. No root cause hypotheses.]

**Steps to reproduce:**
1. [Step]
2. [Step]
3. [Step]

**Expected:** [What should happen]
**Actual:** [What happens instead]

**Frequency / scope:** [Always? Sometimes? For which users or conditions?]

**Impact:** [Who is affected and what is the consequence?]
```

### Feature Request

```markdown
**[Noun phrase describing the capability]**

[1-2 sentences: the user's job to be done and the current gap. Why does this matter now?]

**Current experience:** [What the user has to do today, or what's missing or broken]

**Acceptance criteria:**
- [ ] [Observable behavior, testable with yes/no]
- [ ] [Observable behavior, testable with yes/no]

**Out of scope:** [Things that might look related but aren't part of this ticket]

**Appetite:** [S / M / L, or a number of days]
```

### Tech Debt / Refactor

```markdown
**[Noun phrase describing the friction or improvement]**

**Current friction:** [Specific, concrete description of what's slow, brittle, or hard today — include numbers where possible]

**Improved state:** [What becomes possible or easier — measurable, not just "cleaner"]

**Why now:** [What makes this worth doing at this point?]

**Appetite:** [S / M / L]

**Out of scope:** [Behavior changes, API changes, or related cleanup that isn't part of this]
```

### Spike / Investigation

```markdown
**Spike: [Question being investigated — must be a question]**

**Why this is blocking:** [What decision or work depends on the answer]

**Questions to answer:**
1. [Specific question]
2. [Specific question]

**Output:** [Written summary / prototype / decision / ADR — specific about what lands on the ticket]

**Time box:** [X hours / half a day]
```
