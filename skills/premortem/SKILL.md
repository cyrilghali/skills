---
name: premortem
description: Research the codebase and write a pre-mortem for a planned change. Use when the user wants to surface failure risks before implementation begins — for migrations, new systems, architectural changes, or any feature where failure would be costly to discover late. Triggers on "pre-mortem", "premortem", "what could go wrong with", "risks before we build", or when a feature is risky enough to warrant failure analysis before design is locked.
---

# Writing Pre-Mortems

Surface the failure modes a team wouldn't otherwise see — before implementation begins.

## Philosophy

A pre-mortem is not a risk register. It is the inverse of a post-mortem.

In a post-mortem, you examine a system that has already failed and work backward to understand the causal chain. In a pre-mortem, you imagine that future failure as if it has already happened — then work backward through the same causal logic to identify what caused it. The output is not a list of what *might* go wrong. It is an account of what *did* go wrong, told from a future that hasn't arrived yet.

This distinction is the entire technique.

**Why it works: prospective hindsight.** In 1989, Mitchell, Russo, and Pennington published the foundational study "Back to the future: Temporal perspective in the explanation of events." They found that imagining a future event as having already occurred — rather than imagining it *might* occur — increased the ability to correctly identify causal reasons by approximately 30%. The mechanism is well-understood: when you treat an outcome as certain, your mind shifts from possibility-scanning (which is suppressed by optimism bias) to explanation-building (which is fluent and generative). You stop asking "could this fail?" — a question optimism actively resists — and start asking "how did this fail?" — a question the pattern-matching machinery of the brain is built for.

Gary Klein, who formalized the pre-mortem technique in his 2007 Harvard Business Review article "Performing a Project Premortem," put the practical insight plainly: the technique allows team members to "safely voice their concerns" — the kind of concern they would ordinarily suppress for fear of appearing obstructionist or disloyal. Klein, writing from his naturalistic decision-making research in "Sources of Power," observed that expert practitioners routinely carry mental simulations of how a plan could unravel. The pre-mortem externalizes those private simulations into shared analysis.

Daniel Kahneman, in *Thinking, Fast and Slow*, calls the pre-mortem "the most useful thing I know" for overcoming overconfidence. He frames it specifically as a counter to what he and Tversky called the planning fallacy — the near-universal tendency to underestimate task duration, underestimate obstacles, and overestimate the team's ability to handle contingencies. "Organizations really don't like pessimists," Kahneman observed. The pre-mortem converts pessimism into an intellectual exercise, making it safe to surface what the team already privately suspects.

The same logic runs through millennia of Stoic philosophy. Seneca's *premeditatio malorum* — the premeditation of adversity — was a deliberate practice of imagining misfortune before it occurred, not to cultivate anxiety, but to strip it of its surprise. Nassim Taleb, drawing on Seneca in *Antifragile*, frames this as essential to building systems that gain from disorder rather than merely surviving it. A team that has pre-mortemed a design has done the cognitive work to understand which failure modes are recoverable and which are catastrophic — and can design accordingly.

**Five principles:**

**1. Commit to the failure.** The single most common pre-mortem failure is writing one while emotionally hedging the premise. "If the migration were to fail..." is the wrong register. "The migration failed. It is six months from now. Here is what happened." Certainty is the mechanism. You are not brainstorming risk categories. You are narrating an event that has already occurred.

**2. Work backward, not forward.** The natural instinct is to list risks and then describe their impact (forward). The pre-mortem runs in reverse: start from a specific failure state (delayed launch, data corruption, customer-visible outage, team burnout, or whatever "failure" means for this project), then ask what conditions had to exist for that failure to occur. Then ask what had to be true for *those* conditions to exist. This is causal inversion, and it produces different output than forward risk enumeration.

**3. Specificity over coverage.** A pre-mortem that produces "the migration could fail due to data integrity issues" is not a pre-mortem — it is a restatement of concern. A useful pre-mortem scenario reads: "The cutover ran successfully, but three weeks later the billing calculation started producing wrong results because the new system didn't account for mid-month plan changes, which were stored as audit events in the old schema and not migrated to the new one." Specificity is what makes risks actionable. Generic risks produce generic mitigations that nobody acts on.

**4. Separate failure modes.** Complex systems have multiple independent failure paths. Run multiple scenarios: the technical failure (the system breaks), the integration failure (the system works but the things around it don't adapt), the timeline failure (the project ships so late it's irrelevant or creates secondary damage), the human failure (the team's coordination breaks down). Each scenario will surface different risks.

**5. Distinguish catastrophic from recoverable.** Not all failures are equal. The pre-mortem's most important output is not a list of risks but a characterization of which failure modes are acceptable (slow, painful but recoverable) and which are unacceptable (data loss, customer-visible corruption, security exposure). This directly shapes design decisions — which parts need circuit breakers, rollback paths, feature flags, or phased rollout.

## What a pre-mortem is not

**Not a risk register.** A risk register catalogues what *might* happen, assigns probability and impact scores, and lives in a spreadsheet that nobody reads after the kickoff meeting. A pre-mortem produces narrative scenarios grounded in the specific system being built. The posture difference: a risk register asks "what are the things that could go wrong?" A pre-mortem asks "I'm looking back at the wreckage — what happened?"

**Not a design review.** A design review evaluates whether the proposed solution is correct. A pre-mortem evaluates whether the proposed solution will survive contact with reality. They are complementary: the RFC (what we're building) and the pre-mortem (what could go wrong with it) should be read together.

**Not a post-mortem.** A post-mortem examines an incident that has already occurred. A pre-mortem imagines one that hasn't. The output of a good pre-mortem is a set of changes to the design, rollout plan, or monitoring strategy — made before the first line of code is written. If a pre-mortem produces no design changes, it was either unnecessary or poorly executed.

## Workflow

### 1. Understand what's being built

Start by understanding the change in enough depth to imagine specific failures. Read the RFC, design doc, or project description. If neither exists, ask the user to describe:
- What system is changing?
- What's the migration or deployment path?
- What does "done" look like?
- What does "failure" look like from the user's perspective?

Do not proceed with a superficial understanding. The failure scenarios you generate are only as specific as your understanding of the system.

### 2. Research the codebase

For a pre-mortem to produce useful output, you must understand the systems involved deeply enough to name specific failure mechanisms — not abstract risk categories.

Research what you need in parallel. For a migration:
- Read the source system's data model and any existing business logic that touches the migrated data
- Read the destination system's data model and validation constraints
- Look for consumers of the migrated data that will be affected
- Look at existing monitoring and what gaps exist
- Look at the deployment and rollback history in this area to understand what "normal" looks like

For a new system:
- Understand dependencies: what does the new system call, what calls it?
- Look for analogous systems in the codebase to understand precedent and existing failure patterns
- Read the schema, job queues, and retry logic if relevant
- Understand where state lives and how it can become inconsistent

Use subagents to parallelize research across multiple areas.

### 3. Write the failure scenarios

This is the core of the pre-mortem. Write 3–5 distinct failure scenarios. Each follows the same structure:

```
**Scenario: [name the failure mode]**

[One paragraph narrating the failure as if it already happened — past tense, specific, reads like the first paragraph of a post-mortem.]

**Causal chain:** What had to be true for this to occur?
- Condition A
- Condition B (often enabled by condition A)
- Condition C

**Severity:** Catastrophic / Significant / Recoverable — and why.
```

The scenarios should cover different failure types:
- A **technical failure** in the new system itself (wrong assumption, missed edge case, race condition)
- An **integration failure** — the new system works, but surrounding systems weren't updated or behave differently than expected
- A **timeline/migration failure** — partial state, dual-write inconsistency, rollout was paused mid-way
- A **observability failure** — the system has been broken for days before anyone noticed because the right alerts didn't exist

If the project touches external customers or involves a data model change, also write:
- A **data integrity failure** — silent data corruption that's hard to detect and harder to fix after the fact

### 4. Identify conditions to design against

After writing scenarios, extract the conditions that appear in multiple causal chains. These are the load-bearing risks — the ones worth designing against rather than simply monitoring for. For each:
- Is this condition preventable (can the design be changed to make it impossible)?
- Is it detectable early (can a metric or alert catch it before it becomes a failure)?
- Is it recoverable (is there a rollback path, a re-migration, a way to undo it)?

### 5. Write the pre-mortem document

Use the template at `.claude/templates/premortem.md` if it exists in the repo. If not, use the section structure from the guidance table at the bottom of this skill.

Save to `docs/premortems/` in the relevant repo. Create the directory if it doesn't exist.

File naming: `YYYY-MM-DD-short-slug.md` (e.g., `2026-03-26-employee-csv-migration.md`).

### 6. Present to the user

After writing, give a brief summary of:
- The most serious failure scenario identified (the one that would change what you build)
- Any design conditions that appear in multiple causal chains (the load-bearing risks)
- Anything the pre-mortem surfaced that you'd recommend addressing in the RFC or rollout plan before implementation begins

Invite them to review and iterate. A pre-mortem is a conversation starter, not a verdict.

## Section-by-section guidance

| Section | What makes it good |
|---------|-------------------|
| **Summary** | One paragraph: what system is changing, what "failure" means in this context, and which failure mode is most likely to cause irreversible damage. Written as if addressed to someone about to start implementation. |
| **System context** | What exists today? Describe the systems involved, their state, the migration or deployment path. This grounds the failure scenarios in specifics. No module paths or file names — describe what systems do, not what they're called. |
| **Failure scenarios** | 3–5 scenarios, each narrated in past tense as if already happened. Each has: what the failure looked like externally, the causal chain, and a severity rating with reasoning. The most important section. |
| **Conditions to design against** | The load-bearing risks extracted from the causal chains. Not a complete risk list — just the conditions that appeared in multiple scenarios or would cause irreversible damage if unaddressed. Each with: preventable / detectable / recoverable. |
| **Recommended mitigations** | Concrete, bounded changes to the design, rollout plan, or monitoring strategy. These should be specific enough that an engineer can act on them before writing the first line of code. Not "add monitoring" — "add a metric on the job success rate and alert if the 5-minute rate drops below 95% during the migration window." |
| **Unresolved questions** | Genuine unknowns that the pre-mortem surfaced but couldn't answer — things that need investigation before design is finalized. Not placeholders. |

## Posture: specific vs. vague

The failure between a useful pre-mortem and a waste of time is specificity.

**Vague (risk register posture):**
> Risk: Data migration could introduce inconsistencies.
> Likelihood: Medium. Impact: High.
> Mitigation: Test thoroughly before deploying.

This is noise. It adds no information the team didn't already have, produces no action they wouldn't have taken, and creates the illusion of analysis without the substance.

**Specific (pre-mortem posture):**
> The migration ran successfully in the development environment and passed all existing tests. Three days after the production cutover, the campaign statistics dashboard started showing incorrect completion rates. Investigation revealed that the migration script had correctly moved employee records but had assumed a 1:1 relationship between employees and email addresses. A small subset of employees (~3%) had multiple email addresses due to alias handling in the legacy system. The new system didn't model this — it silently dropped the secondary addresses during import. Campaigns that had been sent to those addresses appeared undelivered in the new schema, deflating completion rates. By the time it was caught, the affected workspaces had already received automated reports with incorrect numbers.
>
> Causal chain: The legacy email address model was not fully documented and not fully read during migration design. No reconciliation check compared record counts between old and new schemas post-migration. No alert existed for sudden drops in campaign completion rates within a workspace.

The second version produces three specific action items: document the email address model, add a post-migration record count reconciliation step, and add a completion rate alert. The first version produces "test more."

## When to run a pre-mortem

Use when:
- A migration moves data between systems (especially if there's no easy rollback)
- A new system replaces an existing one and there's a cutover with shared state
- A feature touches billing, email delivery, or any customer-visible metric
- The architecture introduces a new dependency, queue, or async process
- The project has a non-trivial rollout plan (feature flags, phased rollout, dual-write period)
- The RFC has an "Unresolved Questions" section with more than two items

Skip when:
- The change is additive and has no effect on existing data or existing behavior
- The feature is completely isolated and has a straightforward rollback (e.g., delete the feature flag)
- The system involved is already heavily tested and the change is a well-understood pattern

## How this fits with RFC and post-mortem skills

**Sequence in a well-run project:**

```
1. RFC (rfc skill)         — What are we building and why?
2. Pre-mortem (this skill) — What's most likely to go wrong, and what does it mean for the design?
3. [Implementation]
4. Post-mortem (postmortem skill) — What actually went wrong, and how do we make the system more resilient?
```

A pre-mortem is most valuable when it can still change the design. Run it after the RFC has established what's being built but before implementation begins. If the pre-mortem surfaces a catastrophic failure mode in the proposed design, that's a finding for the RFC — the design should change before implementation starts.

A post-mortem after an incident should reference any pre-mortem that was written. If the failure mode was in the pre-mortem and wasn't addressed, that is itself a contributing factor worth naming.
