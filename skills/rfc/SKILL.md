---
name: rfc
description: Research the codebase and write a technical RFC (Request for Comments) design document. Use when the user wants to propose a technical change, design a new feature, document an architecture decision, or write a design doc. Triggers on "rfc", "design doc", "write an rfc", "technical proposal", "architecture decision", or when a feature is complex enough to warrant written design review before implementation.
---

# Writing RFCs

Write technical RFCs that help a reader evaluate a design decision.

## Philosophy

An RFC is a thinking tool, not an implementation spec. It exists to help a team decide whether to proceed with an approach — and to record the trade-offs that led to that decision.

Five principles guide the writing:

**1. Every word earns its place by serving the reader's decision.** Tufte's data-ink ratio applies to prose: if a sentence doesn't help the reader say "yes," "no," or "have you considered X," it's noise. Module names, file paths, and line numbers are the textual equivalent of chartjunk — decorative detail that doesn't help anyone decide anything. Remove them. Describe systems by what they do, not what they're called.

**2. Write at the floor where the reader lives.** An RFC is read by people making "what should we build" decisions, not "how should we code it" decisions. When you write implementation details — function signatures, module paths, plug orderings — you're on the wrong floor of the abstraction ladder. Stay on the "what" floor: capabilities, behaviors, constraints, trade-offs. The "how" floor is for the implementation PR.

**3. Separate diagnosis from prescription.** Write the problem statement as if you had no solution yet. This prevents the common failure where the motivation is reverse-engineered from the proposal, making it implicitly biased toward that solution's strengths. Describe the current state honestly — what exists, what's insufficient, what's at stake. Then, separately, propose.

**4. Utter honesty about what you do and don't know.** Feynman called this "a kind of leaning over backwards" — report everything that might make your proposal invalid, not just what supports it. State uncertainty plainly. An RFC that hides unknowns behind confident language is a cargo-cult proposal: it has the form of rigorous analysis without the substance.

**5. As little as possible.** Rams' principle: not minimal, but essential. "Back to purity, back to simplicity." Every section, every sentence — does it earn its place? A focused RFC with five strong sections beats a comprehensive one with ten mediocre sections. The template is a menu, not a checklist.

## Workflow

### 1. Gather context

Start by understanding what the user wants to propose. They might give you:
- A feature description or problem statement
- A ticket from your issue tracker (fetch via MCP if available)
- A conversation where they've been exploring an idea
- Just a topic ("RFC for rate limiting")

Ask clarifying questions if the scope is ambiguous, but don't over-interview — start researching and fill gaps as you go.

### 2. Research the codebase

Research thoroughly to inform your design. Understand existing patterns, schemas, API surfaces, and cross-repo impacts so that your proposal is realistic.

But the research is an input to your thinking, not the output. The engineer's instinct is to decompose a system and present the decomposition. Resist this. Your job is to synthesize — to build a mental model that helps the reader understand the problem and evaluate the solution. The codebase tour stays in your head; the mental model goes in the document.

Use subagents to parallelize research when exploring multiple areas of the codebase.

### 3. Draft the RFC

Use the RFC template if one exists in the repo (check `.claude/templates/` or `docs/templates/`). If none exists, use the section structure from the guidance table at the bottom of this skill.

#### Writing at the right level

The Go proposal for non-cooperative goroutine preemption is a good model. It describes a deeply technical runtime change in ~8 inline code references. Not because it avoids specifics — it includes before/after code where prose can't do the job. But every section flows from one clearly stated constraint: "Go must be able to find the live pointers on a goroutine's stack wherever it stops it." That single sentence organizes the entire document.

Your RFC should have a similar organizing constraint — the one tension or insight that everything flows from. If you can't state it in one sentence, you haven't finished thinking.

For the prose itself:

- **Describe systems by capability.** "The existing webhook delivery queue with exponential backoff and SSRF protection" — not a module name. The reader learns what the system does, which is what they need to evaluate your proposal.
- **Name things once, then use plain language.** First mention: "the manual imports table (`employee_manual_imports`)." Every mention after: "the imports table."
- **Domain concepts are vocabulary, not code.** Event names like campaign.completed, scope names, queue names — write them as plain text, not backtick-quoted code.
- **Prose over tables for field lists.** "The payload includes the event type, a timestamp, and the affected resource ID" — not a backtick-heavy table. Reserve structured tables for when the structure itself is the point (column types in a migration, comparison of alternatives).
- **Diagrams over module lists.** A sequence diagram communicates relationships between five systems better than five module names in a paragraph. Use Mermaid (renders natively on GitHub). Think C4 model: System Context or Container level, not Component or Code level.
- **No file paths, no line numbers.** These are implementation coordinates, not design information.

#### Neutral analytical posture

State facts and let the reader decide. Never tell the reader how to feel.

Avoid advocacy language: "battle-tested," "low-risk," "industry standard," "strictly better," "critical need." If you're about to write "this is the standard approach," instead describe what it does and let the reader judge.

When describing the current state's drawbacks, be brief and factual — 2-4 sentences, no drama. When describing the proposal's drawbacks, be genuinely honest about costs.

#### Alternatives are the most important section

Google's design doc culture makes this explicit: an RFC's primary purpose is to record trade-offs. If the alternatives section is thin, the RFC isn't doing its job. Present genuine options with honest rejection reasoning — things a reasonable engineer might actually propose. If you only considered one approach, say that.

#### Rollout should be concrete

Someone should be able to read the rollout plan and know where to start. Feature flags, migration ordering, phased rollout steps, and always a rollback strategy.

### 4. Fill in metadata

- **Author**: Use the user's name (from git config or conversation context)
- **Status**: Always `Draft` for new RFCs
- **Date**: Today's date
- **Ticket**: Link to the relevant issue/ticket if one exists

### 5. Save the RFC

Save to `docs/rfc/` in the relevant repo. Create the directory if it doesn't exist.

File naming: `YYYY-MM-DD-short-slug.md` (e.g., `2026-03-26-rate-limiting.md`).

If a change spans multiple repos, put the RFC in the repo where the primary work happens and reference the others in the Dependencies section.

### 6. Present to the user

After writing, give a brief summary of what you proposed and flag any sections where you had to make judgment calls or where you're least confident. Invite them to review and iterate.

## Section-by-section guidance

| Section | What makes it good |
|---------|-------------------|
| **Summary** | One paragraph a busy engineer can read in 30 seconds. Lead with the conclusion, not the background. |
| **Motivation** | Describes the problem as if you had no solution yet. Answers "why now" and "what happens if we don't." |
| **Detailed Design** | Describes the architecture in plain language. Uses diagrams for flows. Code appears only when prose can't do the job. |
| **Dependencies** | Lists concrete ordering constraints, not just "depends on X" |
| **Security** | Covers auth, data exposure, and input validation — skip if genuinely N/A |
| **Observability** | Metrics, alerts, and dashboards — skip if no new failure modes |
| **Drawbacks** | Honest about the costs of what you're proposing |
| **Alternatives** | The most important section. Real options, real tradeoffs, honest rejection reasoning. |
| **Unresolved Questions** | Genuine open items discovered during research — not placeholders |
| **Rollout Plan** | Concrete steps: feature flags, migration order, phased rollout, rollback strategy |
