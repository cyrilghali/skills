---
name: linear-project-hygiene
description: Keeps the Linear projects you lead up to date. A daily pass repairs drift on its own (a ticket with no milestone takes its parent's or its team's, an overdue milestone or project date moves to the next week's Friday, a past empty milestone loses its date, a start date later than the day the project was marked started moves back to that day) and reports what it changed. A weekly pass drafts a short pulse per active project (status, progress, blockers, what stakeholders need) for the lead to post. Use when asked whether a Linear project is up to date, to check or clean up milestones, overdue milestones or tickets missing a milestone, to write or draft a project status update or weekly pulse, or to run the Linear hygiene routine.
metadata:
  category: operate
---

# Linear project hygiene

Run two passes over every project whose lead is the current user and whose status is started. `scripts/routine.sh daily|weekly` runs them headless on a schedule; `INSTALL.md` wires it up. In a live session, run the same pass with the Linear tools. When asked for a dry run or handed a snapshot, list what you would do instead of writing.

## Write only what the Linear data says

Take every sentence from Linear data read in this pass: a ticket, a date, a status, a description line, a comment. Repeat a date, plan or decision only when a project, milestone or comment states it. Never write one nobody wrote down, and never write a link between tickets the data does not record. Name each ticket with the status the data gives it; never group a range of tickets under one status. Write dates as `YYYY-MM-DD` in the daily report, and as a person says them, weekday first, in a pulse.

## Run the daily pass

1. **Collect the fields.** For each project, read its `startedAt`, `startDate`, `targetDate`, its milestones with target date and progress, and its open tickets with milestone and parent. Done when every project has those fields.
2. **Repair the drift.** The lead wants drift fixed, not reported. Apply these rules in order. "Next Friday" is the first Friday at least 7 days after today.

   | Drift | Repair |
   |---|---|
   | An open ticket has no milestone, and its parent ticket has one | Give it the parent's milestone |
   | An open ticket has no milestone and no parent with one, in a project that uses milestones | Give it the milestone that holds most of the project's other open tickets from the same team |
   | A milestone is past its target date, under 100% and holds an open ticket | Set its target date to next Friday |
   | A milestone is past its target date and holds no ticket | Clear its target date |
   | The project is past its `targetDate` and not completed | Set `targetDate` to the latest milestone target date after the repairs above, or next Friday when that is earlier |
   | `startDate` is empty, or later than the date of `startedAt` | Set `startDate` to that date |

   Give no milestone to the tickets of a project with no milestones, because that project uses cycles. Done when each repair is written and listed as `<item> <field>: <old> → <new>`, for example `ENG-123 milestone: none → Backend ready` or `Backend ready targetDate: 2026-10-14 → 2026-10-23`.
3. **Flag only what no rule settles.** Flag an open ticket with no milestone whose team has no open ticket in any milestone, or whose team ties between two milestones: name the ticket and the tied milestones. Done when every such ticket is flagged once.
4. **Write the report.** When nothing was repaired or flagged in any project, output the single line `NOTHING`. Otherwise:

   ```
   HEADLINE: <n> repairs, <n> flags across <n> projects
   ## <project name>
   Repaired:
   - <repair line>
   Needs a person:
   - <flag line>
   ```

   Omit an empty section and a project with nothing in it. Add no advice, scores, summaries or closing lines. Record the run with `skill-record linear-project-hygiene verdict=daily repaired=R flagged=F` (R counts repair lines, F flag lines, 0 on `NOTHING`), once, only when the run finished; a dry run or an aborted run records nothing.

## Run the weekly pass

1. **Collect the week.** For each project, read its summary and description, the tickets done in the last 7 days, the tickets in progress, the open tickets left, the milestones with their descriptions, its `targetDate`, and the last pulse. Done when each project has them.
2. **Skip what is parked.** Give no pulse to a project in backlog status, or with no ticket updated in 14 days.
3. **Set health from momentum.** Read the signals, strongest first: a blocker a ticket or comment states; the pull requests linked to the project's tickets (`gh pr view <url> --json state,reviewDecision,updatedAt`) and how long each waits on review; the tickets and pull requests that moved in the last 3 working days. Default to `onTrack`. Set `atRisk` only with a named stopper: a stated blocker, a pull request waiting on review for over 2 working days, nothing moving for 5 working days with the target within 10 days, or a step the target depends on not yet started with the target within 3 working days. Set `offTrack` only when a ticket, a comment or the last pulse says the date will slip. Never set health from ticket counts or milestone percentages. Done when health has its one-clause signal.
4. **Check that what is left still stands.** An open ticket can outlive the plan it served. Before the pulse names open work as left, blocking or without an owner, test that ticket for these facts: a later done ticket or merged pull request does the same job another way; its own pull request closed unmerged; a ticket it depends on was cancelled; or a decision recorded after its last update removed the need for it. A ticket whose scope only narrowed is still left work. Read the ticket, its linked pull requests (`gh pr view <url> --json state,mergedAt,closedAt`) and the project's tickets done or cancelled since it last moved. Keep a ticket that fails out of the pulse and give it a `Stale:` line under the pulse; the lead decides whether to cancel it. Done when every open ticket the pulse names has passed.
5. **Draft the pulse for a colleague who does not follow the project.** After a five-second read they can say what it ships, what changed this week, whether it makes its date, and what they must do, if anything. Leave the progress and milestone changes out, because Linear prints them under every update. Output, per project:

   ```
   HEADLINE: <n> pulse drafts to post
   ## <project name> — <On track | At risk | Off track>
   <two to four short paragraphs>
   Stale: <ticket ID> <what it was for>: <the fact that overtook it>
   ```

   - On a project's first pulse, open with what it gives users and its target date, taken from the summary or description. When neither says, write `(no description: say what this ships)` rather than guess. In later pulses give the date alone, since the project page carries the rest.
   - Say what changed this week as what users or admins can now do, not as tickets closed.
   - Say whether it makes the date, with the reason taken from the work left rather than from how busy the week was. Call it late, in plain words, when work is still open past the date it was due. Count a date the daily pass moved from its first date, which the daily reports' `targetDate: <old> → <new>` lines keep.
   - When one exists, say what a named team must know or do, and why it matters to them.

   Write plain sentences of 25 words at most, one idea each. Name work by what it does; its ticket ID may follow in parentheses, two IDs per pulse at most. Keep milestone names, percentages, ticket counts, status names and `Label: value` lines out. Output this block and nothing around it. When every project was skipped, output `NOTHING`.
6. **Rewrite it as the lead would post it.** Keep every fact and the health; change only the voice. Write "we" for the team, name teammates by the first name their assignee field gives, use contractions, mix short and long sentences, and give a plain personal read of the date. Then reread each sentence against the data from step 1 and drop any that no longer traces to it. Done when the pulse reads like a person's note and every fact still holds.
7. **Hand it over.** The lead posts the pulse. Never call `save_status_update`. Done when the drafts are written and nothing was posted. Record the run with `skill-record linear-project-hygiene verdict=weekly`, once, only when the run finished; a dry run or an aborted run records nothing.
