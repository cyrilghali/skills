---
name: postmortem
description: Research an incident and write a blameless post-mortem / incident review. Use when the user wants to document an outage, security incident, data loss event, or any production failure. Triggers on "postmortem", "post-mortem", "incident review", "write up the outage", "incident retrospective", or "what happened with [incident]".
---

# Writing Post-Mortems

Write incident reviews that help a team learn from failure — not assign fault for it.

## Philosophy

A post-mortem is not a verdict. It is an engineering artifact: a careful map of how a complex system arrived at an unexpected state, drawn so the system can be made more resilient.

Six foundational ideas ground the writing:

**1. Post-accident attribution to a "root cause" is fundamentally wrong.** Richard Cook, in "How Complex Systems Fail" (1998), puts it directly: *"There is no isolated 'cause' of an accident... Only jointly are these causes sufficient to create an accident."* Complex systems fail through the simultaneous alignment of multiple latent conditions — Cook's Swiss cheese moment, Allspaw's "each necessary but only jointly sufficient." A section called "root cause" has an implied format: one answer. Replace it with "contributing factors." The shift is not semantic. It changes the investigation.

**2. Human error is a symptom, not a cause.** Sidney Dekker: *"Human error is not a cause of trouble in an otherwise safe system. Human error is a symptom of trouble deeper inside a system."* The label "human error" is where investigation begins, not where it ends. The question that replaces "who caused this?" is: why did the actions taken make sense to the people involved, given what they knew, saw, and were navigating at the time? Dekker calls this **local rationality** — every decision in the incident felt like the obviously correct one to the person making it. The investigator's job is to reconstruct that rationality, not override it with hindsight.

**3. Active failures are visible; latent conditions are the actual problem.** James Reason's Swiss Cheese model distinguishes active failures (the sharp-end acts that trigger incidents) from latent conditions (the "resident pathogens" embedded by earlier decisions at the blunt end — design choices, staffing, tooling, missing checks — that lay dormant until they aligned). Most post-mortems analyze only the active failure. Most of the risk lives in the latent conditions. *"These may lie dormant within the system for many years before they combine with active failures and local triggers to create an accident."* Find them.

**4. Work as Imagined is not Work as Done.** Erik Hollnagel's core concept: procedures, runbooks, and system designs describe an imagined world. Operators work in the actual world, which differs from the imagined one in a hundred undocumented ways. When a post-mortem reads *"they didn't follow the procedure,"* the right follow-up question is not "why didn't they?" but "what conditions made the procedure inadequate for the situation they were actually in?" The gap between Work as Imagined and Work as Done is where incidents live — and where the most important contributing factors hide.

**5. Counterfactuals are not analysis — they are retroactive judgment.** Dekker is precise here: *"Saying what people failed to do, or implying what they could or should have done to prevent the mishap, has no role in understanding human error. Counterfactuals make you spend your time talking about a reality that did not happen."* Every time you are tempted to write *"should have," "failed to," "if only," or "could have prevented,"* replace it with a system question: what conditions would have made the safer path the easier and more obvious one?

**6. Safety is an emergent property of systems, and people continuously create it.** Cook's most important observation: *"Safety is a characteristic of systems and not of their components."* And: *"Failure free operations are the result of activities of people who work to keep the system within the boundaries of tolerable performance."* This inverts the usual framing. Operators are not the source of risk; they are the system's primary adaptive defense. Post-mortems that treat operators as the problem destroy the very capacity that makes the system resilient.

## The failure modes this skill guards against

Most post-mortems fail in one of four ways. Name them, because they are easy to fall into:

**Blame in disguise.** The document is labelled "blameless" but contains blame in its language. Detection: does the timeline use judgmental language ("failed to check," "neglected to verify," "incorrectly assumed")? Do contributing factors describe a person's action rather than a system condition? Do action items address a person's behavior rather than a system state? Apply Allspaw's test: if the engineer whose decision is being analyzed could read this document, would it feel fair as an account of why their decision made sense given what they knew? Not "not mentioned by name" — genuinely fair.

**Shallow analysis.** The investigation stops at the first plausible cause: "a deployment introduced a bad configuration." This is Cook's point 15: *"Views of 'cause' limit the effectiveness of defenses against future events."* A post-mortem that has only one contributing factor, or whose factors all describe human behaviors rather than system states, has stopped too early. What made the bad configuration possible to deploy? What monitoring should have caught it? What organizational conditions made the deploy happen in the way it did?

**Action item theater.** Items are created that look like remediation but don't change the conditions that enabled the incident. Test: if the action item is completed exactly as written, does the *system* become measurably safer — or does it just produce documentation that makes it easier to blame someone next time? "Write a runbook" is theater. "Add an automated check in the deployment pipeline that prevents production deployments without a passing staging run" is substance. Theater items address person obligations. Substance items change system states.

**Counterfactual reasoning.** *"If the engineer had checked the staging environment, this would not have happened"* — true, useless, and harmful. It identifies a decision point and an alternative outcome without explaining anything about why the decision happened. Replace every counterfactual with its system equivalent: "What made it possible to deploy to production without a staging check? What would have to change about the system so that a staging check was structural rather than dependent on individual judgment?"

## The posture difference

This table captures the shift from blame register to blameless register. The left column is what blame sounds like — including blame that doesn't know it's blame:

| Blame register | Blameless register |
|---|---|
| "The engineer forgot to set the queue concurrency limit." | "The concurrency limit was not preserved in the new configuration format." |
| "Nobody noticed the queue was backing up for six hours." | "No alert existed for queue depth exceeding a threshold." |
| "The team should have caught this in code review." | "The configuration change did not require a corresponding monitoring review." |
| "Why did you deploy on a Friday afternoon?" | "The deploy occurred at 16:45 UTC on a Friday." |
| "Root cause: human error." | "Contributing factor: no automated validation of queue configuration existed in the deployment pipeline." |
| "The engineer failed to test the endpoint behind auth middleware." | "The authentication middleware was not applied to this route. The PR review process did not include a security checklist for new routes." |
| "They should have known the backup wasn't running." | "Backup status was not surfaced in operational dashboards. No alert existed for backup failures." |

The right column describes system states. The left column describes person failures. The right column produces action items that change systems. The left column produces shame, silence, and recurrence.

## Workflow

### 1. Gather context

Start by understanding what the user knows about the incident. They might provide:
- A rough description of what happened
- Slack threads, alert histories, or internal runbooks
- Timeline fragments from memory
- A Linear ticket or Datadog incident

Ask: What was the impact on users or customers? When was it first detected vs. when did it actually start? What changed in the hours or days before the incident? Don't wait for a complete picture before starting — begin with what you have and fill gaps through research.

### 2. Research the incident

Investigate using available tooling:
- **Datadog**: Query logs, metrics, traces, and dashboards around the incident window. Look for queue depth metrics, error rates, latency spikes, memory or process anomalies.
- **Sentry**: Find error events, affected users, and stack traces from the incident window.
- **Oban job states**: Look for jobs in `discarded`, `retryable`, or `cancelled` states. Check `max_attempts`, backoff schedules, and error payloads.
- **Deployment history**: Was there a recent deploy? A dependency version bump? A scheduled job that ran for the first time?
- **Database**: Check for migration timing, lock contention, slow queries during the window.

Use subagents to parallelize investigation across these sources.

The research informs the timeline — it is not the timeline. Synthesize findings into a narrative; don't paste raw logs.

### 3. Draft the post-mortem

Use the template at `.claude/templates/postmortem.md` if one exists. Otherwise use the section structure below.

#### Writing posture

**Write the timeline forward, not backward.** Start from the last known-good state before the incident, or from the relevant preceding event, and proceed chronologically to resolution. Writing forward forces you — and the reader — to experience the incident as it unfolded, with the same uncertainty operators experienced. Writing backward from the incident introduces hindsight bias structurally. Cook and Woods: *"Hindsight bias remains the primary obstacle to accident investigation, especially when expert human performance is involved."*

**Capture what people knew, saw, and believed — not just what happened.** A timeline entry like "14:53 — engineer deploys config to production" is a technical fact and insufficient for understanding. The entry should note what was being attempted, what the system state appeared to be, what made this action the obviously correct next step. Not because this exculpates anyone — because it is the data from which the organization learns.

**Name systems, not people.** "A deploy of the notification service introduced a configuration change" not "Alice deployed." If roles are relevant, use the role: "the on-call engineer," "a backend engineer" — never a name.

**State facts at the right level of confidence:**
- Confirmed: "At 14:23 UTC, the queue depth crossed 10,000 jobs."
- Inferred: "This appears to have been caused by the concurrency limit being reduced in the previous deploy."
- Unknown: "It is not yet clear why the alert did not fire."

Don't elide the difference. A post-mortem that acknowledges uncertainty is one the team can trust and update.

**Passive voice is your friend for sensitive facts.** "The queue depth was not monitored" rather than "the team failed to monitor the queue depth." Both are true; only one is blameless.

**Timeline entries are observations, not judgments.**

Good: `14:31 UTC — The on-call engineer acknowledged the alert and began investigating queue metrics.`
Bad: `14:31 UTC — The on-call engineer failed to immediately identify the cause.`

**Action items must be specific, bounded, and system-directed.**

Good: "Add a monitor on the notification queue depth that pages at > 500 jobs in available state for more than 5 minutes. Owner: [name]. Due: [date]."
Bad: "Improve monitoring."

Good: "Add a configuration schema validation step to the deployment pipeline that rejects jobs with concurrency values outside the expected range. Owner: [name]. Due: [date]."
Bad: "Be more careful with config changes."

Action items that can't be started tomorrow aren't action items — they're wishes. And action items addressed to changing a person's behavior aren't action items — they're blame dressed as process.

## Section-by-section guidance

| Section | What makes it good |
|---------|-------------------|
| **Summary** | 3–5 sentences. Lead with impact (what users experienced, for how long), then the mechanism (what broke and how in plain language), then the resolution. A busy engineer reads this in 30 seconds and understands what happened. |
| **Impact** | Quantify everything possible: duration, number of affected users/workspaces, business function interrupted, SLA breach Y/N. "Some users were affected" is not impact. "Campaign emails were delayed for 847 affected workspaces over a 6-hour window" is impact. |
| **Timeline** | Chronological, UTC timestamps, factual. Start before the incident — the last known-good state or the relevant preceding change. Include detection, key investigation decisions, remediation steps, and resolution. Do not editorialize. |
| **Contributing Factors** | This is the heart of the analysis. Not "root cause" — which implies a single, locatable cause (Cook says this is "fundamentally wrong"). Instead: the set of conditions each necessary but only jointly sufficient for the incident to occur. Use the "how" framing: "How did X become possible?" List 3–7 factors. Each should describe a system condition, not a human decision. If a factor is a human decision, ask one level deeper: what system condition made that decision more likely? |
| **What Worked** | What detection, communication, or mitigation strategies performed well? This is Safety-II thinking in practice: it tells the team what NOT to change and what to reinforce. It also counteracts the implicit framing that everything about the incident was failure. |
| **Action Items** | Verb-first, specific, assigned, due-dated. Categorize as: **prevent** (eliminate conditions that made this possible), **detect** (improve alerting so you catch it earlier), **mitigate** (reduce impact if it recurs), **repair** (fix the immediate technical issue), **investigate** (understand something you don't yet). Limit to 10; prioritize ruthlessly. Items with no owner are wishes. Items addressed to a person's behavior are blame. |
| **Unresolved Questions** | Genuine unknowns discovered during analysis. Not placeholders — only include if you actively investigated and couldn't determine the answer. This section builds trust by being honest about the limits of the post-mortem. |

## What to skip

The template is a menu, not a checklist. Skip sections that genuinely don't apply:
- No external customers affected? Skip "External Communication."
- Incident fully understood with a single contributing factor? Say so — don't manufacture complexity.
- Simple, low-impact incident? A shorter post-mortem is better than a padded one.

## Triggering criteria

Write a post-mortem when any of the following apply:
- User-visible degradation lasting more than 30 minutes
- Data loss or exposure of any scope
- Background job queue backup causing delayed delivery of customer-facing events
- Security incident of any severity
- Any incident requiring a rollback or emergency hotfix
- On-call escalation outside business hours
- Any SLA breach for enterprise customers

## Save and present

Save to `docs/postmortems/` in the relevant subrepo. Create the directory if it doesn't exist.

File naming: `YYYY-MM-DD-short-slug.md` (e.g., `2026-03-26-campaign-queue-backup.md`).

After writing, give a brief summary: what the key contributing factors were, what action items were identified, and any sections where inference was required or facts were unavailable. Invite review and iteration.
