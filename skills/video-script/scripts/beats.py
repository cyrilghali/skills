#!/usr/bin/env python3
"""Check the beat table in script.md against the beat rules and beats.json.

Usage: beats.py <folder>

Reads the table in <folder>/script.md whose header names a narration column and a words-on-screen
column. Fails (exit 1) and lists each beat that breaks a rule:
  - its narration holds more than two sentences;
  - its words on screen are empty, or hold a word its narration does not say (numbers and short
    words such as "of" are not checked);
  - beats.json, when present, differs from the table in ids, order or text.
"""

import json
import re
import sys
from pathlib import Path

STOP = {"the", "and", "for", "with", "from", "its", "per", "via", "not", "are", "was", "you", "your", "our", "but"}


def cells(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def table(text):
    lines = text.splitlines()
    for i, line in enumerate(lines):
        head = [c.lower() for c in cells(line)] if line.lstrip().startswith("|") else []
        n = next((j for j, c in enumerate(head) if "narration" in c), None)
        s = next((j for j, c in enumerate(head) if "screen" in c), None)
        if n is None or s is None:
            continue
        rows = []
        for row in lines[i + 2:]:
            if not row.lstrip().startswith("|"):
                break
            c = cells(row)
            rows.append((c[0].strip("`"), c[n] if n < len(c) else "", c[s] if s < len(c) else ""))
        return rows
    return None


def words(text):
    return {re.sub(r"'s$", "", w).strip("'-") for w in re.findall(r"[a-z][a-z'-]*", text.lower())}


def said(word, spoken):
    """A word counts as said when the narration has it, or the same stem with another ending (match, matches, matching)."""
    def stem(a, b):
        common = len(next((a[:i] for i in range(min(len(a), len(b)), 0, -1) if a[:i] == b[:i]), ""))
        return common >= max(4, min(len(a), len(b)) - 3)
    return any(word == w or w == word + "s" or word == w + "s" or stem(word, w) for w in spoken)


def sentences(text):
    return [s for s in re.split(r"(?<=[.!?])\s+", text.strip()) if re.search(r"\w", s)]


def main(argv):
    if len(argv) != 1:
        print(__doc__)
        return 2
    folder = Path(argv[0])
    rows = table((folder / "script.md").read_text())
    if not rows:
        print("FAIL: script.md has no beat table with a narration column and a words-on-screen column")
        return 1
    problems = []
    for beat, narration, screen in rows:
        if len(sentences(narration)) > 2:
            problems.append(f"beat {beat}: {len(sentences(narration))} sentences; one point in one or two sentences")
        if not re.search(r"\w", screen):
            problems.append(f"beat {beat}: no words on screen")
        spoken = words(narration)
        unsaid = sorted(w for w in words(screen) if len(w) > 2 and w not in STOP and not said(w, spoken))
        if unsaid:
            problems.append(f"beat {beat}: on screen but not said: {', '.join(unsaid)}")
    beats_path = folder / "beats.json"
    if beats_path.exists():
        beats = json.loads(beats_path.read_text())
        if [(b.get("id"), b.get("text")) for b in beats] != [(r[0], r[1]) for r in rows]:
            problems.append("beats.json differs from the script.md table; copy the narration column again, in order")
    if problems:
        print("FAIL:")
        for p in problems:
            print("  " + p)
        return 1
    print(f"ok: {len(rows)} beats, {sum(len(r[1].split()) for r in rows)} narration words")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
