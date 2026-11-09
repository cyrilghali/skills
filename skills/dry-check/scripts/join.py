#!/usr/bin/env python3
"""Keep duplicate pairs that touch lines a branch added; print one table row per pair.

Run from the repo root.
  join.py credo --base SHA --input credo.json --min-lines N
  join.py dryer --base SHA --input dry.edn --root DIR     (DIR: where dryer's relative paths start)
--base-input/--base-root: the same tool's report on the base tree. A pair counts as NEW only when
its two files hold more pairs at HEAD than at the base, so an old duplicate the branch edits stays out.
Rows go to stdout as "| NEW | score | left | right | fix |". Exit 3: the tool output is unreadable.
"""
import argparse, json, os, re, subprocess, sys

FIX = "extract a shared helper (name it and the module both sides can call)"


def added_ranges(base):
    out = subprocess.run(
        ["git", "-c", "core.quotepath=off", "diff", "-U0", "--no-color", "--no-ext-diff", "--no-renames", base, "HEAD"],
        check=True, capture_output=True, text=True).stdout
    added, path = {}, None
    for line in out.splitlines():
        if line.startswith("+++ "):
            path = None if line == "+++ /dev/null" else line[6:]
        elif line.startswith("@@") and path:
            m = re.match(r"@@ -\S+ \+(\d+)(?:,(\d+))? @@", line)
            start, n = int(m[1]), int(m[2]) if m[2] is not None else 1
            if n:
                added.setdefault(path, []).append((start, start + n - 1))
    return added


def touches(added, side):
    f, a, b = side
    return any(s <= b and a <= e for s, e in added.get(f, []))


def spans_for(sides):
    here = os.path.dirname(os.path.abspath(__file__))
    rows = "".join(f"{f}\t{l}\t{m}\n" for f, l, m in sides)
    out = subprocess.run(["elixir", os.path.join(here, "spans.exs")], input=rows,
                         capture_output=True, text=True)
    if out.returncode:
        sys.exit("spans.exs failed: " + out.stderr.strip()[-400:])
    got = {}
    for row in out.stdout.splitlines():
        f, l, m, a, b, kind = row.split("\t")
        got[(f, int(l), int(m))] = (int(a), int(b))
    return got


def key(x, y):
    return tuple(sorted((x[0], y[0])))


def emit(pairs, added, base_counts):
    """pairs: [(score, side, side)] with side = (file, first, last)."""
    head_counts = {}
    for _, x, y in pairs:
        head_counts[key(x, y)] = head_counts.get(key(x, y), 0) + 1
    budget = {k: n - base_counts.get(k, 0) for k, n in head_counts.items()}
    for score, x, y in pairs:
        if not (touches(added, x) or touches(added, y)):
            continue
        if budget[key(x, y)] <= 0:
            continue
        budget[key(x, y)] -= 1
        if touches(added, y) and not touches(added, x):
            x, y = y, x
        loc = lambda s: f"{s[0]}:{s[1]}-{s[2]}"
        print(f"| NEW | {score:.2f} | {loc(x)} | {loc(y)} | {FIX} |")


def credo_pairs(path, strip=""):
    text = open(path).read()
    try:
        # Mix prints compile progress on stdout before the JSON document.
        data = json.loads(text[list(re.finditer(r'\{\s*"issues"', text))[-1].start():])
    except (ValueError, IndexError):
        sys.exit(3)
    pairs = {}
    for i in data.get("issues", []):
        m = re.match(r"Duplicate code found in (.*) \(mass: (\d+)\)", i.get("message", ""))
        if not m:
            continue
        mass = int(m[2])
        if not i.get("line_no"):
            continue
        this = (i["filename"], i["line_no"], mass)
        for part in m[1].split(", "):
            f, l = part.rsplit(":", 1)
            if not l.isdigit():  # Credo found no start line for that node
                continue
            other = (f, int(l), mass)
            pairs[frozenset([this, other])] = (this, other)
    if strip:
        rel = lambda s: (os.path.relpath(s[0], strip) if os.path.isabs(s[0]) else s[0],) + s[1:]
        pairs = {k: (rel(a), rel(b)) for k, (a, b) in pairs.items()}
    return pairs


def credo(args, added, base_counts):
    pairs = credo_pairs(args.input)
    # Only pairs with a file the branch changed need line spans.
    pairs = {k: v for k, v in pairs.items() if any(s[0] in added for s in v)}
    spans = spans_for(sorted({s for v in pairs.values() for s in v})) if pairs else {}
    out = []
    for a, b in pairs.values():
        sa, sb = spans[a], spans[b]
        if min(sa[1] - sa[0], sb[1] - sb[0]) + 1 < args.min_lines:
            continue
        out.append((1.0, (a[0],) + sa, (b[0],) + sb))
    emit(out, added, base_counts)


def dryer_pairs(path, root, top):
    root, top = os.path.realpath(root), os.path.realpath(top)
    norm = lambda p: os.path.relpath(os.path.realpath(p if os.path.isabs(p) else os.path.join(root, p)), top)
    text = open(path).read()
    if "{:candidates" not in text:
        sys.exit(3)
    span = r'\{:file "([^"]*)", :start-line (\d+), :end-line (\d+)\}'
    pat = re.compile(r"\{:score ([\d.]+)\s+:language \"[^\"]*\"\s+:left " + span + r"\s+:right " + span)
    out = []
    for m in pat.finditer(text):
        l = (norm(m[2]), int(m[3]), int(m[4]))
        r = (norm(m[5]), int(m[6]), int(m[7]))
        out.append((float(m[1]), l, r))
    return out


def dryer(args, added, base_counts):
    emit(dryer_pairs(args.input, args.root, "."), added, base_counts)


def base_counts(args):
    if not args.base_input:
        return {}
    if args.mode == "credo":
        pairs = [(a, b) for a, b in credo_pairs(args.base_input, args.base_root).values()]
    else:
        pairs = [(l, r) for _, l, r in dryer_pairs(args.base_input, args.base_root, args.base_root)]
    counts = {}
    for a, b in pairs:
        counts[key(a, b)] = counts.get(key(a, b), 0) + 1
    return counts


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["credo", "dryer"])
    ap.add_argument("--base", required=True)
    ap.add_argument("--input", required=True)
    ap.add_argument("--min-lines", type=int, default=6)
    ap.add_argument("--root", default=".")
    ap.add_argument("--base-input")
    ap.add_argument("--base-root", default="")
    a = ap.parse_args()
    (credo if a.mode == "credo" else dryer)(a, added_ranges(a.base), base_counts(a))
