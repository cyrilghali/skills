---
name: linear-ticket
description: Write a clear, actionable Linear ticket. Use when the user wants to create a bug report, feature request, tech debt ticket, or investigation spike. Triggers on "write a ticket", "create a Linear issue", "open a ticket", "file a bug", or when the user describes a problem or request that needs to be tracked.
---

# Writing Linear Tickets

Write Linear tickets that give an engineer enough context to start — and enough room to think.

## Philosophy

A ticket is a communication device, not a specification. It exists to transfer understanding from the person who discovered a problem or need to the person who will solve it.

The central failure modes are not opposites of each other — they're both failures of abstraction:

**Too vague**: "Fix the CSV import bug." The engineer opens the ticket and has to reconstruct the problem from scratch. They don't know when the bug appears, what the user was doing, or what outcome is expected. They'll ask three Slack questions before writing a line of code, and possibly solve the wrong problem.

**Too prescriptive**: "Add a `charset` column to the `employee_imports` table, set it to `utf8mb4`, and update the ImportParser module to use it." The engineer becomes an executor, not a solver. They can't use their judgment about whether a column is even the right approach, or whether the root cause is elsewhere. Over-prescribed tickets atrophy the engineering instinct that makes your team good.

The right level: **state the problem clearly, describe the expected behavior, and give the implementer room to find the best solution.** Unless the solution is itself the point — when a particular approach was specifically decided and the ticket is tracking that decision — stay on the problem floor.

Four principles guide this:

**1. Abstraction laddering.** Hayakawa's ladder of abstraction applies directly: every ticket lives at a rung. Too low ("add column X") bypasses engineering judgment. Too high ("improve reliability") gives no toehold. The right rung is the one where the engineer understands the problem completely and still has to do the thinking about how to solve it. A useful test: could a thoughtful engineer read this and propose two different valid implementations? If yes, the rung is right.

**2. Separate diagnosis from prescription.** Write the problem statement as if you had no solution in mind. "Three customers this month couldn't import employee files with names containing é, ñ, or similar characters — the import appeared to succeed but no records were created" is a diagnosis. "Fix the encoding handling in the import parser" is a prescription disguised as a diagnosis. The prescription might be wrong. Write the diagnosis; let the engineer prescribe.

**3. As little as possible.** Rams applied to prose: not minimal, but essential. Every sentence earns its place. A reproduction case that can be stated in three steps shouldn't take eight. Context that the engineer already has (because it's in the codebase or obvious from the domain) doesn't need restating. The goal is signal density, not comprehensiveness.

**4. Acceptance criteria, not implementation criteria.** The "done" condition should describe observable behavior, not implementation choices. "Imports with UTF-8 characters in name fields complete successfully and create the expected records" is an acceptance criterion. "The ImportParser correctly handles multi-byte characters" is an implementation criterion dressed as acceptance. Write the former; let the engineer satisfy it however they judge best.

---

## Ticket Types

Different problems need different structures. The four types below cover most engineering work.

### Bug Report

A bug is a gap between observed behavior and expected behavior. The ticket should make that gap unmistakable.

**What to include:**
- What the user was doing (the trigger, not the cause)
- What happened (observed behavior — concrete, specific)
- What should have happened (expected behavior)
- Reproduction steps, if known
- Frequency / scope (every time? sometimes? for which customers?)
- Customer or business impact

**What to omit:**
- Hypotheses about root cause (unless you're certain — and even then, put them in a note, not the problem statement)
- Implementation steps
- References to specific files, functions, or database tables unless the bug is isolated there

**Good example:**
> **Employee CSV imports silently fail for files with accented characters**
>
> When a CSV file contains employee names with accented characters (é, ñ, ü, etc.), the import appears to succeed — the UI shows a success message — but no records are created. We've had 3 customer complaints this month. Imports with plain ASCII names work correctly.
>
> Steps to reproduce:
> 1. Prepare a CSV with at least one name containing an accented character (e.g. "José García")
> 2. Upload via the employee import flow
> 3. Observe the success toast
> 4. Check employee list — no new records appear
>
> Expected: records are created for all rows, including those with accented characters.
> Actual: no records created; no error surfaced to the user.

**Bad example:**
> Fix the ImportParser so it handles UTF-8 characters correctly. The issue is in the charset handling when reading CSV rows.

The bad example tells the engineer where to look and what to fix before they've diagnosed anything. If the actual bug is in how the file is read at the HTTP layer, this ticket sends them to the wrong place.

---

### Feature Request

A feature request describes a capability the system doesn't have, framed around the user need it serves.

**What to include:**
- Who needs this and why (the job to be done)
- What the current experience is (so the engineer understands the gap)
- What "done" looks like from the user's perspective
- Acceptance criteria (observable behavior)
- What's explicitly out of scope (prevents scope creep)
- Appetite, if it's been decided (a rough time budget: S/M/L, or days)

**What to omit:**
- Database schema changes
- API endpoint shapes (unless these are the deliverable — e.g. a contract with a third party)
- Component names or file paths

**Good example:**
> **Rate limiting headers on v3 API responses**
>
> Currently, clients who are approaching the API rate limit have no way to know until they receive a 429. This leads to thundering herd failures — clients retry immediately and compound the problem, or build their own exponential backoff without knowing when to reset.
>
> We need to surface rate limit state in response headers so clients can pace themselves. The standard approach (Retry-After, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset) is documented in IETF draft-ietf-httpapi-ratelimit-headers and used by GitHub, Stripe, and others — clients often expect this shape.
>
> Acceptance criteria:
> - Every API response that goes through the rate limiter includes the headers above, populated with the current state for that client
> - Clients that respect Retry-After stop retrying until the window resets
> - Documentation updated (OpenAPI spec)
>
> Out of scope: changing the rate limit thresholds, adding per-endpoint limits, client SDKs.

**Bad example:**
> Add Retry-After, X-RateLimit-Remaining headers to the v3 API. Update the RateLimiter plug to inject these headers. See the plug pipeline in router.ex.

The bad example skips the "why" entirely and jumps to implementation. An engineer following it would add headers without understanding what clients will do with them — meaning they can't make good decisions about what values to put in them, or whether the headers are sufficient on their own.

---

### Tech Debt / Refactor

Tech debt tickets are easy to write poorly: either too abstract ("clean up the import code") or too prescriptive ("extract X into Y module"). The right level describes the friction clearly and the improvement condition.

**What to include:**
- What the current state is and why it's causing friction (concrete: builds are slow, tests are hard to write, onboarding engineers are confused)
- What the improved state looks like (also concrete — not "cleaner" but "a new endpoint can be added without touching the auth logic")
- Why now (or why this is worth doing at all)
- Appetite

**What to omit:**
- The exact refactor strategy (the engineer doing the work should own this)
- Promises about what will become easier — state the current friction instead

**Good example:**
> **Employee import module is hard to test and growing toward a second responsibility**
>
> The current import module handles CSV parsing, validation, encoding normalization, and record creation in a single pass. Adding a test for any one behavior requires setting up all the others. The recent encoding bug (RIO-412) was hard to isolate because we couldn't write a test for encoding logic in isolation.
>
> The improved state: each of the four concerns can be tested independently. A new validation rule or a new file format doesn't require reading the full module to understand the impact.
>
> Appetite: M (this shouldn't require touching the API layer or changing behavior — just restructuring internals).

**Bad example:**
> Refactor the ImportParser module. It has too many responsibilities and should be split up.

"Too many responsibilities" is a conclusion, not a description. The engineer doesn't know what the friction actually feels like, so they can't judge whether their refactor addressed it.

---

### Spike / Investigation

A spike is a time-boxed investigation with a specific question to answer, not a task with a deliverable. The output is knowledge, not code.

**What to include:**
- The specific question(s) to answer
- Why this uncertainty blocks other work
- The time box (how long is this worth?)
- What the output should look like (written summary? prototype? decision?)

**What to omit:**
- Anything that implies you already know the answer
- Open-ended "explore X" framing — every spike needs a question it's trying to answer

**Good example:**
> **Spike: how do third-party HRIS providers (BambooHR, Workday) export employee data, and what encoding/format guarantees do they provide?**
>
> Before hardening the import pipeline against encoding issues, we need to know what we're hardening against. We don't know if these systems export UTF-8, whether they have documented guarantees, or whether the format varies by customer configuration.
>
> Questions to answer:
> 1. What formats and encodings do BambooHR and Workday use in their CSV/SFTP exports?
> 2. Do they document this? Are there edge cases known in the wild?
> 3. Do any providers export in a format we can't easily normalize?
>
> Output: written summary posted to the ticket, answering the three questions above with enough specificity to inform the encoding work.
> Time box: 2 hours.

**Bad example:**
> Investigate encoding issues in HRIS integrations.

No question, no time box, no output format. This ticket will either run forever or produce a vague doc that doesn't unblock anything.

---

## What Context to Always Include

Regardless of ticket type, three questions should always be answerable from the ticket:

1. **Why does this matter?** Who is affected, how much, and what happens if we don't address it?
2. **What does done look like?** Observable behavior, not internal state.
3. **What's out of scope?** Explicitly bound the work. Engineers correctly assume that related-looking things are in scope unless told otherwise.

---

## Workflow

### 1. Gather context

Start with what the user gives you. They might provide:
- A Slack message or customer complaint
- A vague description ("the import is broken")
- A detailed problem description
- A Linear ticket ID to update

Ask clarifying questions if you're missing the impact, the reproduction case, or the acceptance criteria — but don't over-interview. Start with what you have.

If given a ticket ID or URL, fetch it via available MCP tools to read the current state.

### 2. Research the codebase (for bugs and features)

For bugs: understand the system well enough to write a precise problem statement. You're not diagnosing the root cause in the ticket — but you need to know enough to describe the trigger and the gap accurately. The risk here is the opposite of vagueness: codebase knowledge tempts you to prescribe. If you discover the root cause, note it as a hypothesis in the ticket, not as the problem statement.

For features: understand the existing surface so the acceptance criteria are grounded in how the system actually works.

Use subagents to parallelize exploration of large codebases.

**Note on scope:** This skill is for tickets written for human engineers. If you need to write a ticket optimized for an AI agent to implement (with file lists, implementation steps, and test scaffolding), check if your project has an agent-specific ticket-writing skill.

### 3. Draft the ticket

Pick the right type. Write the problem statement first, before thinking about solutions. Then write acceptance criteria from the user's perspective. Add reproduction steps or context as needed. State what's out of scope.

Title format: `[Noun phrase describing the problem or capability]` — not a verb command. Titles like "Employee CSV import silently fails for accented characters" are scannable. Titles like "Fix the import bug" are not.

### 4. Publish or display

If issue tracker MCP tools are available, use them to create the issue directly. Ask the user which team to assign if not specified.

If no MCP tools are available, display the ticket as formatted markdown for copy-paste.

---

## Templates

### Bug Report

```markdown
**[Short noun-phrase title describing the gap]**

[1-2 sentences describing what the user was doing and what went wrong. Be concrete.]

**Steps to reproduce:**
1. [Step]
2. [Step]
3. [Step]

**Expected:** [What should happen]
**Actual:** [What happens instead]

**Frequency / scope:** [Every time? Sometimes? For which customers/conditions?]

**Impact:** [Who is affected and what is the consequence?]
```

### Feature Request

```markdown
**[Short noun-phrase title describing the capability]**

[1-2 sentences describing the user need or gap this addresses. Why does this matter now?]

**Current experience:** [What the user has to do today, or what's missing]

**Acceptance criteria:**
- [ ] [Observable behavior from the user's perspective]
- [ ] [Observable behavior from the user's perspective]

**Out of scope:** [Things that might seem related but aren't part of this ticket]

**Appetite:** [S / M / L, or a time budget if it's been set]
```

### Tech Debt / Refactor

```markdown
**[Short noun-phrase title describing the friction or improvement]**

**Current friction:** [Specific, concrete description of what's hard, slow, or brittle today]

**Improved state:** [What becomes possible or easier — measurable, not just "cleaner"]

**Why now:** [What's making this worth doing at this point?]

**Appetite:** [S / M / L]

**Out of scope:** [Behavior changes, API changes, or related cleanup that isn't part of this]
```

### Spike / Investigation

```markdown
**Spike: [Question or topic being investigated]**

**Why this is blocking:** [What decision or work depends on this answer]

**Questions to answer:**
1. [Specific question]
2. [Specific question]

**Output:** [Written summary / prototype / ADR / decision — be specific about what lands on the ticket]

**Time box:** [X hours / half a day / etc.]
```
