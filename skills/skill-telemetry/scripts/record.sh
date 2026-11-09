#!/usr/bin/env bash
# Appends one JSON line for a skill run to $SKILL_TELEMETRY_DIR/runs.jsonl.
# Usage: record.sh <skill> [key=value ...]
# Never fails the caller: on any error it prints one line to stderr and exits 0.
set -u

main() {
  local skill="${1:-}"
  if [ -z "$skill" ]; then
    echo "skill-telemetry: usage: record.sh <skill> [key=value ...]" >&2
    return 0
  fi
  shift
  if ! command -v python3 >/dev/null 2>&1; then
    echo "skill-telemetry: python3 not found, run not recorded" >&2
    return 0
  fi

  local dir="${SKILL_TELEMETRY_DIR:-${HOME:-/tmp}/.local/share/skill-telemetry}"
  if ! mkdir -p "$dir" 2>/dev/null; then
    echo "skill-telemetry: cannot create $dir, run not recorded" >&2
    return 0
  fi

  local repo="" branch=""
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    repo=$(git remote get-url origin 2>/dev/null || true)
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    [ "$branch" = "HEAD" ] && branch=""
  fi

  local err
  if ! err=$(python3 - "$skill" "$dir/runs.jsonl" "$repo" "$branch" "$@" 2>&1 >/dev/null <<'PY'
import json, os, re, subprocess, sys
from datetime import datetime, timezone

skill, path, remote, branch, *pairs = sys.argv[1:]
RESERVED = {"ts", "skill", "repo", "branch", "pr", "session"}

def repo_from(remote):
    m = re.search(r'[:/]([^/:]+)/([^/]+?)(?:\.git)?/?$', remote.strip())
    return f"{m.group(1)}/{m.group(2)}" if m else None

def pr_number():
    if not remote:
        return None
    try:
        out = subprocess.run(["gh", "pr", "view", "--json", "number"],
                             capture_output=True, text=True, timeout=2)
        return json.loads(out.stdout)["number"] if out.returncode == 0 else None
    except Exception:
        return None

def typed(value):
    if re.fullmatch(r'-?\d+', value):
        return int(value)
    if re.fullmatch(r'-?\d+\.\d+', value):
        return float(value)
    return value

row = {
    "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "skill": skill,
    "repo": repo_from(remote) if remote else None,
    "branch": branch or None,
    "pr": pr_number(),
    "session": os.environ.get("CLAUDE_SESSION_ID") or None,
}
for pair in pairs:
    key, sep, value = pair.partition("=")
    if not sep or not key:
        raise SystemExit(f"bad argument {pair!r}, expected key=value")
    if key in RESERVED:
        raise SystemExit(f"reserved key {key!r}, pick another name")
    ratio = re.fullmatch(r'(-?\d+(?:\.\d+)?)/(-?\d+(?:\.\d+)?)', value)
    if ratio:
        row[key] = typed(ratio.group(1))
        row[key + "_of"] = typed(ratio.group(2))
    else:
        row[key] = typed(value)

with open(path, "a", encoding="utf-8") as f:
    f.write(json.dumps(row, ensure_ascii=False) + "\n")
PY
  ); then
    echo "skill-telemetry: run not recorded: $(printf '%s\n' "$err" | tail -n 1)" >&2
  fi
  return 0
}

main "$@"
exit 0
