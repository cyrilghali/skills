# Plan and brief format

A series plan is one `plan.json`. `scripts/plan.py <folder>` checks it and writes one brief per unit into `briefs/`. A unit is one item of the series: a video, a lesson or a page.

## plan.json

```json
{
  "goal": "What the people who finish the series can do",
  "evidence": "What they do that shows the goal is reached, such as returning a bike to a full dock without help",
  "audiences": [
    {"id": "rider", "who": "anyone who rents a bike", "knows": "how to ride, nothing of the app"},
    {"id": "mechanic", "who": "a mechanic who repairs the fleet", "knows": "the overview units"}
  ],
  "tiers": [
    {"id": "overview", "audiences": ["rider", "mechanic"], "standalone": true},
    {"id": "deep-dive", "audiences": ["mechanic"]}
  ],
  "units": [
    {"id": "u01-unlock-a-bike", "title": "Unlock a bike", "tier": "overview", "idea": "One sentence: what the viewer can do or see after this unit", "length": "about 2 minutes"},
    {"id": "u04-brake-checks", "tier": "deep-dive", "idea": "...", "prerequisites": ["u01-unlock-a-bike"]}
  ],
  "facts": [
    {"id": "f01", "text": "One true statement the series must teach", "source": "where it can be checked", "unit": "u01-unlock-a-bike"},
    {"id": "f17", "text": "...", "source": "...", "dropped": "outdated: the app replaced the card reader"}
  ]
}
```

| Field | Rule |
|---|---|
| `goal`, `evidence` | Both set before any unit is chosen. |
| `tiers` | Listed from broad to deep. A tier marked `standalone` holds units that each make sense alone, so they take no prerequisites. |
| `units` | Listed in viewing order. A prerequisite comes earlier in the list and sits in the same tier or a broader one. |
| `facts` | Each fact has exactly one `unit` or one `dropped` reason. |
| `dropped` | Starts with `false:`, `outdated:`, `duplicate:` or `off-goal:`. Depth is never a reason: a fact too deep for one tier goes to a deeper tier. |

## The brief

`plan.py` writes `briefs/<unit id>.md` for each unit. The brief is the hand-off to whoever makes the unit:

```markdown
# Brief: u04-brake-checks — Brake checks

- **Series goal:** ...
- **How the series knows it worked:** ...
- **Audience — mechanic:** a mechanic who repairs the fleet. Already knows: the overview units.
- **Tier:** deep-dive (2 of 2); stands alone: no, it builds on its prerequisites
- **The one idea:** ...
- **Length:** about 4 minutes
- **Prerequisites:** u01-unlock-a-bike (its idea)

## Facts this unit must say

| id | fact | source |
|---|---|---|

## Facts the viewer already has (cue them when the story needs them; never teach them again)

| id | fact | taught in |
|---|---|---|
```

The second table lists every fact taught in the unit's prerequisites, followed back to the start, so the maker can lean on them without teaching them again. A one-clause cue reminds; to make the viewer actually recall a fact, ask it as a question before giving it.
