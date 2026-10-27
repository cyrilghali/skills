---
name: series-planner
description: Plans a series of videos, lessons or doc pages from a source document - which units to make, for which audience, in what order. Sets the goal and how to tell it was reached, lists every checkable fact in the source with where it comes from, catches false or outdated ones, places each fact in exactly one unit, checks coverage with a script and writes one brief per unit. Use when the user asks to plan a video series, episodes, a course outline, lessons or a set of docs pages from notes, a handbook, a spec or a backlog, asks how many videos or lessons a source needs and what goes in each, or wants one source split for several audiences, broad first.
metadata:
  category: plan
---

# Plan a series

Turn audiences, a goal and a source into `plan.json`, checked by this skill's `scripts/plan.py`, which also writes one brief per unit. A unit is one item of the series: a video, a lesson or a page. The format is in `FORMAT.md`; read it before step 1.

Plan backward: first what the audience can do at the end and how you will know, then the facts, then the units that carry them. The sources behind each rule are in `REFERENCE.md`.

## Hard rules

- **One home per fact.** Every fact sits in exactly one unit. A later unit that needs it cues it in a clause, as the brief's "already has" table lists; it never teaches it again. When the viewer should actually recall a fact, the brief asks it as a question before giving it.
- **Depth never drops a fact.** A fact too deep for one audience moves to a deeper tier. A fact leaves the plan only as `false:`, `outdated:`, `duplicate:` or `off-goal:`, and `off-goal:` means the fact serves none of the audiences' goals, not that it is hard.
- **Size follows the source.** Start from one unit and split only for a reason the source or the audience gives. A source that fits one unit gets a one-unit plan. Every unit carries facts no other unit has: an intro, a recap, a summary or a worked case with no fact of its own is not a unit.

## Defaults the user can swap

Tier names, unit lengths, one idea per unit and the time a fact takes on screen come from `STYLE.md`. They are taste, not research. Use the style file the user names instead when there is one; the hard rules above stay.

## Steps

1. **Set the goal and the evidence.** Write `goal` as one clause per audience: what that audience can do after the series. Write `evidence` as what each audience does that shows the goal is reached, such as a task done without help. List each audience with what it already knows. Done when every audience appears in both `goal` and `evidence`, before any unit exists.

2. **Inventory the facts.** Read the source from top to bottom and write one fact row for each checkable claim, in the source's own terms, with `source` set to where it is (section and paragraph, or line). Keep a rule and its numbers in one row; one claim is one row even when several audiences need it. Mark a claim the source itself calls false, old, replaced or removed with `false:` or `outdated:` and the reason; when two statements conflict, keep the current one and drop the other. When an audience may still believe the wrong claim (an old deck, a common belief), add a correcting fact ("X is not true: Y") and place it like any other. Done when every sentence of the source that makes a claim maps to a row, and no two rows say the same thing in different words.

3. **Set the tiers by audience need.** Start with one tier for everyone. Add a tier only when one audience needs facts another audience should not have to watch. List tiers from broad to deep. Mark the first tier `standalone: true`, because most people stop early. Done when every audience sits in at least one tier and every fact has an audience that needs it.

4. **Cut the units.** Start from one unit per audience tier. Name what the viewer can do after it as one `idea`. Split a unit only where its viewer would stop between the parts: a different audience, a different moment of use, or a skill to practise before the next part makes sense. Length never splits a unit by itself: a unit that runs past the cap in `STYLE.md` gets chapters inside it, named in its `length`. A format with a fixed slot it cannot run past, such as a lesson in a timetable, splits at the break closest to the slot. Done when each unit's `idea` names one outcome, and each split has one of those reasons.

5. **Place every fact.** Give each fact the first unit, in the broadest tier, whose audience needs it. Order units so each prerequisite comes earlier, and name it in `prerequisites`. A unit in a standalone tier takes no prerequisites, so it must not lean on another unit's facts. Done when every fact has one `unit` or one `dropped` reason, and every unit that uses another unit's facts names it.

6. **Check the plan.** Run `python3 <this skill's folder>/scripts/plan.py <plan folder>`. Fix every problem it lists in `plan.json`, never by loosening a fact's text, and run it again. Done when it prints `ok:`.

7. **Read the briefs.** Open `briefs/`. A deep unit whose "must say" table repeats an earlier unit's fact in other words means two rows hold one fact: merge them and rerun step 6. Done when each brief's facts are new to its viewer.

## Return

Return `plan.json`, the `briefs/` folder and the `ok:` line with the dropped facts it prints. Write no other plan text: the briefs are what a maker starts from.
