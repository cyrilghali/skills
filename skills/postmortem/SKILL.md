---
name: postmortem
description: Research an incident and write a blameless post-mortem / incident review. Use when the user wants to document an outage, security incident, data loss event, or any production failure. Triggers on "postmortem", "post-mortem", "incident review", "write up the outage", "incident retrospective", or "what happened with [incident]".
---

# Writing Post-Mortems

Write incident reviews that help a team learn from failure — not assign fault for it.

## Philosophy

A post-mortem is not a verdict. It's a map of how a complex system arrived at an unexpected state, drawn carefully enough that the system can be made more resilient.

Five principles guide the writing:

**1. Systems fail; people respond.** Allspaw's foundational insight from Etsy: in complex systems, operators are never the cause of failure — they are the inheritors of latent conditions that predate the incident. "Every system has bugs that have never been triggered and conditions that have never been exercised." The question is never "who broke it" but "what made it breakable." Write accordingly.

**2. Describe what happened, not what should have happened.** Feynman's "leaning over backwards" principle: report facts that might undermine your preferred narrative, not just facts that support it. If monitoring was absent, say so. If alerts fired and were silenced, say so. If a fix was attempted and made things worse before making them better — say so. A post-mortem that sanitizes the timeline to protect appearances is not a post-mortem; it's fiction.

**3. "How" questions, not "why" questions.** The Salesforce engineering team put it plainly: "Why" forces people to justify decisions, implicitly framing them as blameworthy. "How did the queue back up?" describes a mechanism. "Why did you let the queue back up?" assigns fault. Write in the "how" register throughout. This isn't just cultural kindness — it produces better analysis. Complex systems fail through interaction of multiple factors; "why" implies a single cause where none exists.

**4. Separate timeline from analysis from action.** These are distinct cognitive acts. The timeline is archaeology: what happened, in order, with timestamps. Analysis is interpretation: which conditions enabled this failure mode. Action items are prescription: what specific changes make recurrence less likely. Mixing these layers produces muddled documents. Write them in sequence; keep them clearly labeled.

**5. Honest uncertainty is strength.** "We do not yet know why the circuit breaker tripped" is a stronger sentence than a plausible-sounding explanation that isn't verified. Unknown causes belong in the Unresolved Questions section, not papered over with speculation dressed as fact. A post-mortem that acknowledges what it doesn't know is one the team can trust — and can update as investigation continues.

## The core problem this skill solves

Most post-mortems fail in one of three ways:

- **Blame-heavy**: The narrative centers on a human decision — a deploy, a config change, a missed alert — and implicitly or explicitly treats that decision as the incident's cause. This protects the system (which will fail again) at the cost of the person (who now fears future honesty).

- **Solution-first**: The action items are written before the analysis is done. The team knows what they want to fix and works backward to justify it. The result is action items that address symptoms, not mechanisms.

- **Too shallow**: The timeline stops at "root cause identified" without asking what made that root cause possible. The five whys stops at one branch of a tree that has many. Future incidents recur in slightly different form.

This skill builds post-mortems that do the opposite: system-focused, analysis-first, and honest about depth of understanding.

## Workflow

### 1. Gather context

Start by understanding what the user knows about the incident. They might provide:
- A rough description of what happened ("job queue backed up, emails delayed 6 hours")
- Slack threads, alert histories, or internal runbooks
- Timeline fragments from memory
- A ticket or incident from your monitoring system

Don't wait for a complete picture before starting. Begin with what you have and fill gaps through research.

Ask: What was the impact on users or customers? When was it first detected vs. when did it actually start? What changed in the hours or days before the incident?

### 2. Research the incident

Investigate thoroughly using available tooling:
- **Monitoring/APM**: Query logs, metrics, traces, and dashboards around the incident window. Look for queue depth metrics, error rates, latency spikes, memory or process anomalies.
- **Error tracking**: Find error events, affected users, and stack traces from the incident window.
- **Job queue state**: Look for failed, retrying, or dead jobs. Check retry configs, backoff schedules, and error payloads.
- **Deployment history**: Was there a recent deploy? A dependency version bump? A scheduled job that ran for the first time?
- **Database**: Check for migration timing, lock contention, slow queries during the window.

Use subagents to parallelize investigation across these sources.

The research informs the timeline — it is not the timeline. Synthesize findings into a narrative; don't paste raw logs.

### 3. Draft the post-mortem

Use the template at `.claude/templates/postmortem.md`.

#### Writing posture

**Passive voice is your friend for sensitive facts.** "The queue depth was not monitored" rather than "The team failed to monitor the queue depth." Both are true; only one is blameless.

**Name systems, not people.** "A deploy of the campaign rollout service introduced a configuration change" not "Alice deployed a change." If roles are relevant to the narrative, use the role: "the on-call engineer," "a backend engineer," never a name.

**State facts at the right level of confidence.**
- Confirmed: "At 14:23 UTC, the `campaign_rollout` queue depth crossed 10,000 jobs."
- Inferred: "This appears to have been caused by the queue concurrency limit being reduced in the previous deploy."
- Unknown: "It is not yet clear why the alert did not fire."

Don't elide the difference between these.

**Timeline entries are observations, not judgments.**

Good: `14:31 UTC — On-call engineer acknowledged the alert and began investigating queue metrics.`
Bad: `14:31 UTC — On-call engineer failed to immediately identify the cause.`

**Action items must be specific and bounded.**

Good: "Add a monitor on email delivery queue depth that alerts at > 500 jobs pending for more than 5 minutes. Assigned: [name]. Due: [date]."
Bad: "Improve monitoring."

Good: "Reduce delivery job max retries from 10 to 3 for non-transient errors and add explicit dead-letter handling. Assigned: [name]. Due: [date]."
Bad: "Fix the job retry logic."

Action items that can't be started tomorrow aren't action items — they're wishes.

#### Concrete posture examples

| Blame register | Blameless register |
|---|---|
| "The engineer forgot to set the queue limit." | "The queue concurrency limit was not set in the new configuration." |
| "Nobody noticed the queue was backing up." | "No alert existed for queue depth exceeding a threshold." |
| "The team should have caught this in code review." | "The configuration change did not have a corresponding monitoring update." |
| "Why did you deploy on a Friday?" | "The deploy occurred at 16:45 UTC on a Friday, outside standard deployment windows." |
| "Root cause: human error." | "Contributing factor: no automated check existed to validate queue configuration before deploy." |

## Section-by-section guidance

| Section | What makes it good |
|---------|-------------------|
| **Summary** | 3–5 sentences. Lead with impact (what users experienced, for how long), then the mechanism (what broke and why in plain language), then the resolution. A busy engineer can read this in 30 seconds and understand what happened. |
| **Impact** | Quantify everything possible: duration, number of affected users/workspaces, business function interrupted, SLA breach Y/N. "Some users were affected" is not impact. "Campaign emails were delayed for 847 affected workspaces over a 6-hour window" is impact. |
| **Timeline** | Chronological, UTC timestamps, factual. Start before the incident (the last known-good state or relevant preceding event). Include detection, key investigation decisions, remediation steps, and resolution. Do not editorialize — "14:45 UTC — Engineer escalated to senior engineer" is fine; "14:45 UTC — Engineer realized they couldn't fix it alone" is not. |
| **Contributing Factors** | This is the heart of the analysis. Not "root cause" (a fiction in complex systems) but the set of conditions that were each necessary and jointly sufficient for the incident to occur. Use the "how" framing: "How did X become possible?" List 3–7 factors. Each should be a system condition, not a human decision. |
| **What Worked** | What detection, communication, or mitigation strategies performed well? This isn't self-congratulation — it tells the team what NOT to change and what to invest in further. |
| **Action Items** | Verb-first, specific, assigned, due-dated. Categorize as: prevent (stop recurrence), detect (improve alerting), mitigate (reduce impact if it recurs), process (improve response). Limit to 10; if you have more, prioritize ruthlessly. |
| **Unresolved Questions** | Genuine unknowns discovered during analysis. Not placeholders — only include if you actively investigated and couldn't determine the answer. This section builds trust by being honest about the limits of the post-mortem. |

## What to skip

The template is a menu, not a checklist. Skip sections that genuinely don't apply:
- No external customers? Skip "External Communication."
- Incident is fully understood? You may still have an Unresolved Questions section — surface what the team wants to monitor going forward.
- Simple incident with a single contributing factor? Don't manufacture complexity; say so.

## When to write a post-mortem

Write a post-mortem when any of the following apply:
- User-visible degradation lasting more than 30 minutes
- Data loss or exposure of any scope
- Job queue backup causing delayed delivery of customer-facing events
- Security incident of any severity
- Any incident that required a rollback or emergency hotfix
- On-call escalation outside business hours
- Any SLA breach

## Save and present

Save to `docs/postmortems/` in the relevant repo. Create the directory if it doesn't exist.

File naming: `YYYY-MM-DD-short-slug.md` (e.g., `2026-03-26-campaign-queue-backup.md`).

After writing, present a brief summary: what the key contributing factors were, what action items you identified, and any sections where you had to make inference calls or where facts were unavailable. Invite review and iteration.
