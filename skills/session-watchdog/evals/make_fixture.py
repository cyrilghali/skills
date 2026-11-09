#!/usr/bin/env python3
"""Build the fixture for one eval case: briefs, transcripts, a nudge log and a fake hc.

  make_fixture.py <case 1-5> <dir>

Prints the environment to export. The fake hc answers `ls --json` and `get <t> --json`
(each terminal's launch command) from terminals.json and appends every `send` call to sent.log.
"""
import json
import os
import sys
import time
from pathlib import Path

# session: (brief or None for a non-handoff session, agent_state, final text, idle minutes)
CASES = {
    1: {
        "a1": ("fix-login.md", "processing", "Reproduced the login bug. Now writing the failing test.", 1),
        "b1": ("db-cleanup.md", "idle", "Both migrations drop the column.\n\nWhich of the two should I keep?", 70),
        "c1": ("add-metrics.md", "idle", "Opened PR #41 with the three counters; the test suite passes.\n\nThe reviewer should check the metric names against the dashboard.", 90),
        "d1": ("cron-dedupe.md", "idle", "The build is running detached.\n\nI'll run the tests once it finishes, then report.", 95),
        "e1": (None, "idle", "I'll summarise the next video too.", 120),
        "f1": ("old-task.done.md", "idle", "I'll continue with part two.", 300),
    },
    2: {
        "a2": ("fix-login.md", "processing", "Writing the failing test.", 0),
        "b2": ("db-cleanup.md", "processing", "Checking which migration ran last.", 2),
        "c2": ("add-metrics.md", "idle", "The compile is running in the background. I'll push once it passes.", 6),
    },
    3: {
        "a3": ("cron-dedupe.md", "idle", "Tests are running in the background.\n\nI'll commit once they pass.", 240),
    },
    4: {
        "g4": ("schema-pick.md", "idle", "Both schemas fit the brief.\n\nTell me which one you prefer and I'll wire it in.", 80),
        "h4": ("eval-harness.md", "idle", "All five evals pass and PR #88 is open.\n\nI'll leave the tab open for your review.", 85),
        "i4": ("flaky-suite.md", "idle", "Two tests still fail.\n\nI'm rerunning the suite in the background; next I'll fix the two failures.", 90),
        "j4": ("report-export.md", "idle", "Exported three of the five reports.\n\nI'll export the fourth next, then report.", 60),
    },
    5: {
        "k5": ("ci-cache.md", "idle", "I started the full test run detached.\n\nI'll add the cache step to the setup script, then report.", 45),
        "l5": ("test-runner-setup.md", "idle", "The runner is set up and the smoke test passes in 41 s.\n\nNothing is left from the brief.", 50),
    },
}


def build(case, root):
    root = Path(root).resolve()
    handoffs, projects = root / "handoffs", root / "projects" / "work"
    handoffs.mkdir(parents=True, exist_ok=True)
    projects.mkdir(parents=True, exist_ok=True)
    terminals, argvs, state = [], {}, {}
    now = time.time()
    for sid, (brief, agent_state, text, idle) in CASES[case].items():
        prompt = "Summarise this video for me."
        if brief:
            path = handoffs / brief
            path.write_text(f"# {brief}\n\n## Task\nDo {brief}.\n\n## Deliverable\n1. Finish {brief}.\n")
            prompt = f"Read {path} and execute it end to end, then report to the reviewer it names."
        lines = [
            {"type": "user", "uuid": f"{sid}-u", "message": {"content": prompt}},
            {"type": "assistant", "uuid": f"{sid}-last", "message": {"content": [{"type": "text", "text": text}]}},
        ]
        f = projects / f"{sid}.jsonl"
        f.write_text("\n".join(json.dumps(line) for line in lines) + "\n")
        os.utime(f, (now - idle * 60, now - idle * 60))
        if brief:
            os.utime(path, (now - idle * 60 - 120, now - idle * 60 - 120))
        status = {"processing": "working", "idle": "done"}[agent_state]
        terminals.append({"address": f"t_{sid}", "agent": "claude-code", "state": "live", "status": status,
                          "where": f"work / {sid}"})
        argvs[f"t_{sid}"] = ["claude", "--model", "sonnet", prompt]
    if case == 3:
        state["a3"] = "a3-last"
    (root / "terminals.json").write_text(json.dumps({"ls": {"terminals": terminals}, "get": argvs}, indent=2))
    (root / "nudges.json").write_text(json.dumps(state))
    hc = root / "hc"
    hc.write_text(
        '#!/bin/sh\nd=$(dirname "$0")\ncase "$1" in\n'
        '  ls) python3 -c \'import json,sys; print(json.dumps(json.load(open(sys.argv[1]))["ls"]))\' "$d/terminals.json" ;;\n'
        '  get) python3 -c \'import json,sys; print(json.dumps({"argv": json.load(open(sys.argv[1]))["get"].get(sys.argv[2], [])}))\' "$d/terminals.json" "$2" ;;\n'
        '  send) shift; printf "%s\\n" "$*" >> "$d/sent.log" ;;\n'
        '  *) echo "hc: unsupported: $*" >&2; exit 1 ;;\nesac\n'
    )
    hc.chmod(0o755)
    print(f"export HANDOFF_DIR={handoffs} CLAUDE_PROJECTS_DIR={root / 'projects'} "
          f"WATCHDOG_STATE={root / 'nudges.json'} HC_BIN={hc}")


if __name__ == "__main__":
    build(int(sys.argv[1]), sys.argv[2])
