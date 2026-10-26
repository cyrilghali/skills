#!/usr/bin/env python3
"""Check that every checkable claim in beats.json has a sourced, judged entry in claims.json.

Usage: claims.py <project> [--stamp] [--final | --blind]

Fails (exit 1) and lists each offending beat and token when:
  - a beat holds a checkable token (number, CamelCase, snake_case, path.ext, `backticks`,
    quoted product name, or an absolute word such as only, never or largest) but claims.json has
    no entry for that beat;
  - an entry lacks a claim, source or valid verdict;
  - an entry judged false, outdated or unverifiable has not changed its beat since
    (the beat text equals `text_at_check`);
  - an entry names a beat id that beats.json does not hold.
--stamp  writes the current beat text into `text_at_check` of every entry that has none. Run it
         after judging a claim and before fixing the narration.
--blind  prints claims.json with only beat, claim and source: the file to hand the second reader,
         so it judges without the author's verdicts and notes.
--final  also requires second-read.json, written by the second reader: a verdict for every entry
         (matched on beat and claim), a `resolved` note in claims.json where the two differ, and
         an entry in claims.json for each claim the reader added.
"""

import json
import re
import sys
from pathlib import Path

VERDICTS = {"true", "partly", "false", "outdated", "unverifiable"}
MUST_CHANGE = {"false", "outdated", "unverifiable"}
NUMBER_WORDS = (
    "two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen "
    "seventeen eighteen nineteen twenty thirty forty fifty sixty seventy eighty ninety hundred "
    "thousand million billion percent"
).split()
TOKENS = [
    ("number", re.compile(r"\d[\d.,]*%?|\b(?:" + "|".join(NUMBER_WORDS) + r")\b", re.I)),
    ("CamelCase", re.compile(r"\b[A-Za-z]+[a-z][A-Z]\w*|\b[A-Z][a-z]+[A-Z]\w*")),
    ("snake_case", re.compile(r"\b[a-z0-9]+(?:_[a-z0-9]+)+\b")),
    ("path.ext", re.compile(r"\b[\w/-]+\.[a-z]{1,5}\b")),
    ("backticks", re.compile(r"`[^`]+`")),
    ("quoted name", re.compile(r"[\"“]([A-Z][^\"”]*)[\"”]")),
    ("absolute", re.compile(r"\b(?:only|always|never|nobody|no one|none|largest|smallest|longest|shortest|oldest|newest|fastest|slowest|biggest|highest|lowest)\b", re.I)),
]


def tokens(text):
    found = []
    for kind, pattern in TOKENS:
        for match in pattern.finditer(text):
            found.append(f"{kind} {match.group(0)!r}")
    return found


def main(argv):
    flags = {a for a in argv if a.startswith("--")}
    args = [a for a in argv if not a.startswith("--")]
    if len(args) != 1:
        print(__doc__)
        return 2
    project = Path(args[0])
    beats = {b["id"]: b["text"] for b in json.loads((project / "beats.json").read_text())}
    claims_path = project / "claims.json"
    if not claims_path.exists():
        print(f"FAIL: {claims_path} does not exist; write one entry per checkable claim in beats.json")
        for beat, text in beats.items():
            found = tokens(text)
            if found:
                print(f"  beat {beat}: {', '.join(found)}")
        return 1
    claims = json.loads(claims_path.read_text())

    if "--blind" in flags:
        blind = [{k: e.get(k) for k in ("beat", "claim", "source")} for e in claims]
        print(json.dumps(blind, indent=2, ensure_ascii=False))
        return 0

    second_reads = None
    problems = []
    if "--final" in flags:
        second_path = project / "second-read.json"
        if second_path.exists():
            second_reads = {(r.get("beat"), r.get("claim")): r.get("verdict") for r in json.loads(second_path.read_text())}
        else:
            problems.append(f"{second_path} does not exist; the second reader writes it from claims.py --blind")

    if "--stamp" in flags:
        for entry in claims:
            if "text_at_check" not in entry and entry.get("beat") in beats:
                entry["text_at_check"] = beats[entry["beat"]]
        claims_path.write_text(json.dumps(claims, indent=2, ensure_ascii=False) + "\n")

    covered = set()
    for i, entry in enumerate(claims, 1):
        beat = entry.get("beat")
        label = f"entry {i} (beat {beat})"
        if beat not in beats:
            problems.append(f"{label}: no such beat id in beats.json")
            continue
        covered.add(beat)
        for field in ("claim", "source", "verdict"):
            if not str(entry.get(field, "")).strip():
                problems.append(f"{label}: missing {field}")
        verdict = entry.get("verdict")
        if verdict and verdict not in VERDICTS:
            problems.append(f"{label}: verdict {verdict!r} is not one of {sorted(VERDICTS)}")
        if verdict in MUST_CHANGE and entry.get("text_at_check") in (None, beats[beat]):
            problems.append(f"{label}: verdict {verdict}, but the beat is unchanged; fix or reword the narration (run --stamp before editing)")
        if verdict == "partly" and not str(entry.get("note", "")).strip():
            problems.append(f"{label}: verdict partly needs a note saying which part holds")
        if second_reads is not None:
            second = second_reads.get((beat, entry.get("claim")))
            if second not in VERDICTS:
                problems.append(f"{label}: no second_read verdict")
            elif second != verdict and not str(entry.get("resolved", "")).strip():
                problems.append(f"{label}: second_read {second} differs from verdict {verdict}; read the source and set resolved")

    if second_reads is not None:
        known = {(e.get("beat"), e.get("claim")) for e in claims}
        for beat, claim in second_reads:
            if (beat, claim) not in known:
                problems.append(f"second read added a claim in beat {beat}: {claim!r}; judge it and add it to claims.json")

    for beat, text in beats.items():
        found = tokens(text)
        if found and beat not in covered:
            problems.append(f"beat {beat}: no claims entry for {', '.join(found)}")

    if problems:
        print("FAIL:")
        for p in problems:
            print("  " + p)
        return 1
    print(f"ok: {len(claims)} claims cover {len(covered)} beats")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
