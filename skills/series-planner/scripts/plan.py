#!/usr/bin/env python3
"""Check a series plan and write one brief per unit.

Usage: plan.py <folder>

Reads <folder>/plan.json (format in FORMAT.md). Fails (exit 1) and lists every problem when:
  - a fact sits in no unit and has no drop reason, or has both;
  - a fact names a unit that does not exist;
  - a drop reason does not start with false:, outdated:, duplicate: or off-goal:, or gives depth as
    the reason (a fact too deep for one tier moves to a deeper tier; it is never dropped);
  - a unit id is used twice, or a unit has no fact, no idea, or a tier that does not exist;
  - a unit in a standalone tier has prerequisites;
  - a prerequisite is unknown, comes later in the unit order, or sits in a later tier;
  - a tier has no unit, or names an audience that does not exist;
  - the plan has no goal, no evidence (what the audience does that shows the goal is reached), or no
    audiences.
A missing or unreadable plan.json, or one whose lists hold something other than objects with an id,
fails with one line instead.
When the plan passes, writes <folder>/briefs/<unit id>.md, one per unit, and prints a coverage line.
"""

import json
import re
import sys
from pathlib import Path

DROP_KINDS = ("false:", "outdated:", "duplicate:", "off-goal:")
DEPTH = re.compile(
    r"\b(too )?(deep|depth|advanced|detail(ed|s)?|technical|complex|niche|in the weeds|beginners?|newcomers?)\b",
    re.I,
)


def read(path):
    try:
        return Path(path).read_text()
    except OSError as err:
        raise SystemExit(f"FAIL: cannot read {path}: {err.strerror}")


def load_json(path, shape):
    try:
        data = json.loads(read(path))
    except json.JSONDecodeError as err:
        raise SystemExit(f"FAIL: {path} is not valid JSON: {err}")
    if shape is list and not (isinstance(data, list) and all(isinstance(x, dict) for x in data)):
        raise SystemExit(f"FAIL: {path} must be a JSON list of objects")
    if shape is dict and not isinstance(data, dict):
        raise SystemExit(f"FAIL: {path} must be a JSON object")
    return data


def check_shape(plan):
    for key in ("audiences", "tiers", "units", "facts"):
        value = plan.get(key, [])
        if not (isinstance(value, list) and all(isinstance(x, dict) for x in value)):
            raise SystemExit(f"FAIL: plan.json {key!r} must be a list of objects")
        for item in value:
            if not str(item.get("id", "")).strip():
                raise SystemExit(f"FAIL: plan.json: an item in {key!r} has no id")


def check(plan):
    problems = []
    for key in ("goal", "evidence"):
        if not str(plan.get(key, "")).strip():
            problems.append(f"plan: no {key}; set it before choosing units")
    if not plan.get("audiences"):
        problems.append("plan: no audiences; list who the series is for and what each already knows")
    audiences = {a.get("id") for a in plan.get("audiences", [])}
    tiers = [t.get("id") for t in plan.get("tiers", [])]
    tier_of = {t.get("id"): t for t in plan.get("tiers", [])}
    units = plan.get("units", [])
    order = {u.get("id"): i for i, u in enumerate(units)}
    tier_of_unit = {u.get("id"): u.get("tier") for u in units}
    for uid in {u.get("id") for u in units}:
        if sum(u.get("id") == uid for u in units) > 1:
            problems.append(f"unit {uid}: id used twice")
    facts_in = {u.get("id"): [] for u in units}

    for t in plan.get("tiers", []):
        for a in t.get("audiences", []):
            if a not in audiences:
                problems.append(f"tier {t.get('id')}: audience {a!r} is not in audiences")
        if not any(u.get("tier") == t.get("id") for u in units):
            problems.append(f"tier {t.get('id')}: no unit")

    seen_ids, seen_text = set(), {}
    for f in plan.get("facts", []):
        fid, unit, dropped = f.get("id"), f.get("unit"), str(f.get("dropped", "")).strip()
        if fid in seen_ids:
            problems.append(f"fact {fid}: id used twice")
        seen_ids.add(fid)
        key = " ".join(str(f.get("text", "")).lower().split())
        if key and key in seen_text and unit:
            problems.append(f"fact {fid}: same text as {seen_text[key]}; a fact is taught in one unit only")
        elif unit:
            seen_text.setdefault(key, fid)
        if not str(f.get("text", "")).strip():
            problems.append(f"fact {fid}: no text")
        if unit and dropped:
            problems.append(f"fact {fid}: both a unit and a drop reason; keep one")
        elif not unit and not dropped:
            problems.append(f"fact {fid}: in no unit; place it in the tier whose audience needs it")
        elif unit and unit not in order:
            problems.append(f"fact {fid}: unit {unit!r} does not exist")
        elif unit:
            facts_in[unit].append(fid)
        elif not dropped.lower().startswith(DROP_KINDS):
            problems.append(f"fact {fid}: drop reason must start with one of {', '.join(DROP_KINDS)}")
        elif not dropped.lower().startswith("duplicate:") and DEPTH.search(dropped):
            problems.append(f"fact {fid}: dropped for depth ({dropped!r}); move it to a deeper tier instead")

    for u in units:
        uid, tier = u.get("id"), u.get("tier")
        if tier not in tier_of:
            problems.append(f"unit {uid}: tier {tier!r} does not exist")
            continue
        if not str(u.get("idea", "")).strip():
            problems.append(f"unit {uid}: no idea")
        if not facts_in.get(uid):
            problems.append(f"unit {uid}: no fact; merge it into another unit or give it facts")
        prereqs = u.get("prerequisites", [])
        if tier_of[tier].get("standalone") and prereqs:
            problems.append(f"unit {uid}: tier {tier} stands alone, so it takes no prerequisites")
        for p in prereqs:
            if p not in order:
                problems.append(f"unit {uid}: prerequisite {p!r} does not exist")
            elif order[p] >= order[uid]:
                problems.append(f"unit {uid}: prerequisite {p} comes later in the unit order")
            elif tier_of_unit[p] in tier_of and tiers.index(tier_of_unit[p]) > tiers.index(tier):
                problems.append(f"unit {uid}: prerequisite {p} sits in a later tier")
    return problems, facts_in


def ancestors(uid, by_id):
    seen, stack = [], list(by_id[uid].get("prerequisites", []))
    while stack:
        p = stack.pop(0)
        if p not in seen and p in by_id:
            seen.append(p)
            stack.extend(by_id[p].get("prerequisites", []))
    return seen


def brief(plan, unit, facts_in):
    by_id = {u["id"]: u for u in plan["units"]}
    facts = {f["id"]: f for f in plan["facts"]}
    tier = next(t for t in plan["tiers"] if t["id"] == unit["tier"])
    tiers = [t["id"] for t in plan["tiers"]]
    who = [a for a in plan.get("audiences", []) if a["id"] in tier.get("audiences", [])]
    lines = [f"# Brief: {unit['id']}" + (f" — {unit['title']}" if unit.get("title") else ""), ""]
    lines.append(f"- **Series goal:** {plan.get('goal', '')}")
    lines.append(f"- **How the series knows it worked:** {plan.get('evidence', '')}")
    for a in who:
        lines.append(f"- **Audience — {a['id']}:** {a.get('who', '')}. Already knows: {a.get('knows', '')}.")
    alone = "yes, a viewer may stop after this unit" if tier.get("standalone") else "no, it builds on its prerequisites"
    lines.append(f"- **Tier:** {tier['id']} ({tiers.index(tier['id']) + 1} of {len(tiers)}); stands alone: {alone}")
    lines.append(f"- **The one idea:** {unit['idea']}")
    if unit.get("length"):
        lines.append(f"- **Length:** {unit['length']}")
    prior = ancestors(unit["id"], by_id)
    lines.append("- **Prerequisites:** " + ("; ".join(f"{p} ({by_id[p]['idea']})" for p in prior) if prior else "none"))
    lines += ["", "## Facts this unit must say", "", "| id | fact | source |", "|---|---|---|"]
    lines += [f"| {fid} | {facts[fid]['text']} | {facts[fid].get('source', '')} |" for fid in facts_in[unit["id"]]]
    known = [fid for p in prior for fid in facts_in[p]]
    if known:
        lines += ["", "## Facts the viewer already has (cue them when the story needs them; never teach them again)", "",
                  "| id | fact | taught in |", "|---|---|---|"]
        lines += [f"| {fid} | {facts[fid]['text']} | {facts[fid]['unit']} |" for fid in known]
    return "\n".join(lines) + "\n"


def main(argv):
    if len(argv) != 1:
        print(__doc__)
        return 2
    folder = Path(argv[0])
    plan = load_json(folder / "plan.json", dict)
    check_shape(plan)
    problems, facts_in = check(plan)
    if problems:
        print("FAIL:")
        for p in problems:
            print("  " + p)
        return 1
    out = folder / "briefs"
    out.mkdir(exist_ok=True)
    for unit in plan["units"]:
        (out / f"{unit['id']}.md").write_text(brief(plan, unit, facts_in))
    placed = sum(len(v) for v in facts_in.values())
    dropped = [f for f in plan["facts"] if f.get("dropped")]
    print(f"ok: {placed} facts placed once across {len(plan['units'])} units in {len(plan['tiers'])} tiers, "
          f"{len(dropped)} dropped (none for depth); briefs in {out}")
    for f in dropped:
        print(f"  dropped {f['id']}: {f['dropped']}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
