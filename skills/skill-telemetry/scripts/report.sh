#!/usr/bin/env bash
# Prints one plain-text block per skill from $SKILL_TELEMETRY_DIR/runs.jsonl.
# Usage: report.sh [skill] [--since 30d|90d|all]   (default window: 30d)
# The change column splits the window's runs into an older and a newer half by
# count and compares their medians; it prints n/a under 2 runs.
# The compliance line counts session transcripts under $HOME/.claude/projects
# that invoked the skill (a Skill tool call or a typed slash command). The
# scan is cached in $SKILL_TELEMETRY_DIR/sessions.tsv; only new or grown
# transcripts are read again, so the first run is the slow one.
set -u

skill=""
since="30d"
while [ $# -gt 0 ]; do
  case "$1" in
    --since) since="${2:-}"; shift 2 ;;
    --since=*) since="${1#--since=}"; shift ;;
    -h|--help) sed -n '2,9p' "$0" | cut -c3-; exit 0 ;;
    *) skill="$1"; shift ;;
  esac
done
case "$since" in 30d|90d|all) ;; *) echo "report.sh: --since takes 30d, 90d or all" >&2; exit 2 ;; esac

dir="${SKILL_TELEMETRY_DIR:-$HOME/.local/share/skill-telemetry}"
mkdir -p "$dir" 2>/dev/null || { echo "report.sh: cannot create $dir" >&2; exit 1; }

exec python3 - "$dir" "$skill" "$since" "$HOME/.claude/projects" <<'PY'
import json, os, re, subprocess, sys
from datetime import datetime, timedelta, timezone
from statistics import median

dir_, only, since, transcripts = sys.argv[1:5]
log = os.path.join(dir_, "runs.jsonl")
cache_path = os.path.join(dir_, "sessions.tsv")
now = datetime.now(timezone.utc)
cutoff = None if since == "all" else now - timedelta(days=int(since[:-1]))
BASE = {"ts", "skill", "repo", "branch", "pr", "session"}
INVOKED = re.compile(r'"skill":"([a-z0-9:_-]+)"|<command-name>/([a-z0-9:_-]+)')


def load_runs():
    runs = {}
    if not os.path.isfile(log):
        return runs
    with open(log, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
                ts = datetime.strptime(row["ts"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
            except (ValueError, KeyError, TypeError):
                continue
            if cutoff and ts < cutoff:
                continue
            runs.setdefault(str(row.get("skill", "?")), []).append((ts, row))
    return runs


def load_cache():
    cache = {}
    if os.path.isfile(cache_path):
        with open(cache_path, encoding="utf-8") as f:
            for line in f:
                parts = line.rstrip("\n").split("\t")
                if len(parts) == 4:
                    try:
                        cache[parts[0]] = (int(parts[1]), float(parts[2]), set(filter(None, parts[3].split(","))))
                    except ValueError:
                        continue
    return cache


def scan(files):
    """One grep pass over the given transcripts; returns {path: set of skill names}."""
    found = {p: set() for p in files}
    for i in range(0, len(files), 200):
        batch = files[i:i + 200]
        out = subprocess.run(
            ["grep", "-a", "-o", "-H", "-E", INVOKED.pattern, *batch],
            capture_output=True, text=True, errors="replace")
        for line in out.stdout.splitlines():
            path, _, match = line.rpartition(".jsonl:")
            m = INVOKED.search(match)
            if m and path + ".jsonl" in found:
                found[path + ".jsonl"].add(m.group(1) or m.group(2))
    return found


def sessions_by_skill():
    """Transcripts in the window, grouped by the skills they invoked."""
    if not os.path.isdir(transcripts):
        return {}
    cache = load_cache()
    files = {}
    for project in os.scandir(transcripts):
        if not project.is_dir():
            continue
        for entry in os.scandir(project.path):
            if entry.name.endswith(".jsonl") and entry.is_file():
                st = entry.stat()
                files[entry.path] = (st.st_size, st.st_mtime)
    stale = [p for p, (size, _) in files.items() if p not in cache or cache[p][0] != size]
    if stale:
        print(f"report.sh: indexing {len(stale)} transcript(s), the first run takes minutes", file=sys.stderr)
        for path, names in scan(stale).items():
            cache[path] = (files[path][0], files[path][1], names)
        with open(cache_path, "w", encoding="utf-8") as f:
            for path, (size, mtime, names) in cache.items():
                if path in files:
                    f.write(f"{path}\t{size}\t{mtime}\t{','.join(sorted(names))}\n")
    by_skill = {}
    for path, (size, mtime) in files.items():
        if cutoff and datetime.fromtimestamp(mtime, timezone.utc) < cutoff:
            continue
        for name in cache.get(path, (0, 0, set()))[2]:
            by_skill[name] = by_skill.get(name, 0) + 1
    return by_skill


def fmt(v):
    if isinstance(v, bool) or not isinstance(v, (int, float)):
        return str(v)
    return str(v) if isinstance(v, int) else f"{v:g}"


def change(values):
    if len(values) < 2:
        return "n/a"
    half = len(values) // 2
    diff = median(values[half:]) - median(values[:half])
    return f"{'+' if diff >= 0 else ''}{diff:g}"


def is_number(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)


runs = load_runs()
names = [only] if only else sorted(runs)
if not names:
    print(f"no runs recorded in {since}")
    print(f"log: {log}", file=sys.stderr)
    sys.exit(0)
sessions = sessions_by_skill()

for name in names:
    rows = sorted(runs.get(name, []), key=lambda r: r[0])
    head = f"{name}: {len(rows)} run{'s' if len(rows) != 1 else ''} in {since}"
    print(head + (f", last {rows[-1][0].strftime('%Y-%m-%d')}" if rows else ""))
    metrics = []
    for _, row in rows:
        for k in row:
            if k not in BASE and k not in metrics:
                metrics.append(k)
    numeric = [m for m in metrics if all(is_number(r[m]) for _, r in rows if m in r)]
    if numeric:
        width = max(len(m) for m in numeric)
        print(f"  {'metric':<{width}}  {'median':>8}  {'last':>8}  {'change':>8}")
        for m in numeric:
            vals = [r[m] for _, r in rows if m in r]
            print(f"  {m:<{width}}  {fmt(median(vals)):>8}  {fmt(vals[-1]):>8}  {change(vals):>8}")
    for m in metrics:
        if m not in numeric:
            vals = [r[m] for _, r in rows if m in r]
            print(f"  last {m}: {fmt(vals[-1])[:70 - len(m)]}")
    n = sessions.get(name, 0)
    print(f"  compliance: {n} session{'' if n == 1 else 's'} invoked it, {len(rows)} recorded")
    print()
PY
