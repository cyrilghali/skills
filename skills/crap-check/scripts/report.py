#!/usr/bin/env python3
"""Scores functions, marks them NEW or pre-existing, prints the report and writes the gate record.

Input rows (tab separated, one per function clause):
  H|B  lang  file  module  name  start  end  cc  cov
H = head, B = base. cov is a percentage, or "-" when this script must read it from ExCoveralls JSON
(Elixir) or score 0% (no coverage).
"""
import argparse
import json
import math
import os
import sys

ap = argparse.ArgumentParser()
ap.add_argument("--rows", required=True)
ap.add_argument("--added", required=True, help="TSV: file, first added line, last added line")
ap.add_argument("--threshold", type=float, default=10)
ap.add_argument("--excoveralls", default="")
ap.add_argument("--coverage-source", default="none")
ap.add_argument("--record", default="")
ap.add_argument("--notes", default="")
args = ap.parse_args()
T = args.threshold


def crap(cc, cov):
    return cc * cc * (1 - cov / 100) ** 3 + cc


def fix(cc, cov):
    if cc > T:
        return "split"
    if cc == T:
        return "test to 100% coverage"
    need = math.ceil(100 * (1 - ((T - cc) / (cc * cc)) ** (1 / 3)) - 1e-9)
    return f"test to {need}% coverage"


added = {}
for line in open(args.added):
    f, a, b = line.rstrip("\n").split("\t")
    added.setdefault(f, []).append((int(a), int(b)))

ex_cov = {}
if args.excoveralls and os.path.isfile(args.excoveralls):
    for sf in json.load(open(args.excoveralls)).get("source_files", []):
        ex_cov[sf["name"]] = sf["coverage"]


def ex_percent(file, start, end):
    arr = ex_cov.get(file)
    if arr is None:
        # A build cloned from another checkout records that checkout's absolute source paths.
        arr = next((v for k, v in ex_cov.items() if k.endswith("/" + file)), None)
    if arr is None:
        return None
    window = [v for v in arr[start - 1 : end] if v is not None]
    return 100.0 * sum(1 for v in window if v > 0) / len(window) if window else 100.0


base = {}
head = []
for line in open(args.rows):
    p = line.rstrip("\n").split("\t")
    kind, lang, file, mod, name, s, e, cc, cov = p
    if kind == "B":
        k = (file, mod, name)
        base[k] = max(base.get(k, 0), int(cc))
    else:
        head.append((lang, file, mod, name, int(s), int(e), int(cc), cov))

new, old, missing = [], [], set()
for lang, file, mod, name, s, e, cc, cov in head:
    if not any(a <= e and b >= s for a, b in added.get(file, [])):
        continue
    if cov != "-":
        pct = float(cov)
    elif lang == "ex" and args.excoveralls:
        pct = ex_percent(file, s, e)
        if pct is None:
            missing.add(file)
            pct = 0.0
    else:
        pct = 0.0
    score = crap(cc, pct)
    if score <= T:
        continue
    key = (file, mod, name)
    is_new = key not in base or cc > base[key]
    row = (score, f"{file}:{s}", f"{mod}.{name}" if mod else name, cc, pct, fix(cc, pct))
    (new if is_new else old).append(row)

out, record = [], []
if new or old:
    out.append("| new? | file:line | function | CC | coverage % | CRAP | cheapest fix |")
    out.append("|---|---|---|---|---|---|---|")
    for label, rows in (("NEW", new), ("pre-existing", old)):
        for score, loc, fn, cc, pct, fx in sorted(rows, key=lambda r: -r[0]):
            text = f"| {label} | {loc} | {fn} | {cc} | {pct:.0f} | {score:.0f} | {fx} |"
            out.append(text)
            if label == "NEW":
                record.append(text)
else:
    out.append(f"No function above CRAP {T:g} in the code this branch changed.")
for f in sorted(missing):
    out.append(f"note: no coverage entry for {f}; its functions scored 0%.")
if args.notes:
    out.append(args.notes)
out.append(f"new={len(new)} pre-existing={len(old)} threshold={T:g} coverage={args.coverage_source}")
print("\n".join(out))

if args.record:
    os.makedirs(os.path.dirname(args.record), exist_ok=True)
    with open(args.record, "w") as fh:
        fh.write("\n".join([f"new={len(new)}"] + record) + "\n")
