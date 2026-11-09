#!/usr/bin/env python3
"""List open handoff sessions with their state, and nudge the stalled ones.

  watchdog.py list [--json] [--notify] [--terminals FILE] [--now EPOCH]
  watchdog.py nudge <session, tab or terminal id> [--send] [--terminals FILE] [--now EPOCH]
  watchdog.py selftest

A handoff is an unsuffixed brief (<slug>.md, not .done.md or .superseded.md)
whose path appears in the launch command of a Claude terminal in Herdr (`hc ls`),
or of a recent Claude Desktop transcript (entrypoint "claude-desktop"). Desktop
sessions cannot be nudged: a stalled one is reported, and with --notify raised as a
macOS notification. An open brief that no session ever opened, past the grace
period, is "not-started" (Enter was likely never pressed).

Environment: HANDOFF_DIR, CLAUDE_PROJECTS_DIR, WATCHDOG_STATE (nudge log),
WATCHDOG_IDLE_MIN (default 20), HC_BIN (default hc).
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from dataclasses import asdict, dataclass
from pathlib import Path

HOME = Path.home()
HANDOFF_DIR = Path(os.environ.get("HANDOFF_DIR", HOME / ".local/state/handoffs"))
PROJECTS_DIR = Path(os.environ.get("CLAUDE_PROJECTS_DIR", HOME / ".claude/projects"))
STATE_FILE = Path(os.environ.get("WATCHDOG_STATE", HOME / ".local/state/session-watchdog/nudges.json"))
IDLE_MIN = float(os.environ.get("WATCHDOG_IDLE_MIN", "20"))
HC = os.environ.get("HC_BIN", "hc")

# The last paragraph of an idle session's final message decides its class.
ASKS_USER = re.compile(
    r"\?\s*$|\b(need (your|you to)|your (approval|decision|call|go-ahead|login|cookie)|waiting (on|for) you)\b",
    re.I | re.M,
)
ANNOUNCES_WORK = re.compile(
    r"\b(I'll|I will|I'm going to|let me|next[:,]|once (it|they|the|that|those)|while (it|they|the|those)"
    r"|still running|in the background|I'm (now )?(running|waiting|checking|starting|writing|launching|moving))\b",
    re.I,
)


@dataclass
class Handoff:
    brief: str
    tab: str
    terminal: str
    session: str
    agent_state: str
    idle_min: int
    cls: str  # working | waiting | finished | stalled | not-started
    reason: str
    last_uuid: str
    tail: str
    nudge: str  # the message a stalled row would receive, or why it is refused
    surface: str = "herdr"  # herdr | desktop | none (not started)


def open_briefs():
    return [p for p in HANDOFF_DIR.glob("*.md") if not re.search(r"\.(done|superseded)\.md$", p.name)]


def read_transcript(session):
    hits = list(PROJECTS_DIR.glob(f"*/{session}.jsonl"))
    if not hits:
        return None, []
    path = hits[0]
    entries = []
    for line in path.read_text(errors="replace").splitlines():
        try:
            entries.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return path, entries


def first_prompt(entries):
    for e in entries:
        if e.get("type") != "user" or e.get("isMeta"):
            continue
        content = e.get("message", {}).get("content")
        if isinstance(content, list):
            content = " ".join(b.get("text", "") for b in content if isinstance(b, dict))
        if isinstance(content, str) and content and not content.lstrip().startswith("<"):
            return content
    return ""


def last_turn(entries):
    """(last assistant text, its uuid, name of a tool call still waiting for its result)."""
    text, uuid, pending = "", "", ""
    answered = set()
    for e in entries:
        content = e.get("message", {}).get("content")
        if not isinstance(content, list):
            continue
        for b in content:
            if not isinstance(b, dict):
                continue
            if b.get("type") == "tool_result":
                answered.add(b.get("tool_use_id"))
            elif e.get("type") == "assistant" and b.get("type") == "text" and b.get("text", "").strip():
                text, uuid = b["text"], e.get("uuid", "")
            elif e.get("type") == "assistant" and b.get("type") == "tool_use":
                pending = (b.get("id"), b.get("name", ""))
    if pending and pending[0] not in answered:
        return text, uuid, pending[1]
    return text, uuid, ""


def classify(agent_state, idle_min, text, pending_tool):
    paragraphs = [p for p in re.split(r"\n\s*\n", re.sub(r"<[^>]+>", "", text).strip()) if p.strip()]
    last_par = paragraphs[-1] if paragraphs else ""
    rules = [
        (agent_state == "processing", "working", "Herdr reports working"),
        (agent_state == "awaiting", "waiting", "Herdr reports a blocked terminal"),
        (pending_tool == "AskUserQuestion", "waiting", "asked a question with AskUserQuestion"),
        (bool(pending_tool), "waiting", f"tool call {pending_tool} has no result (permission prompt)"),
        (bool(ASKS_USER.search(last_par)), "waiting", "last message asks the user"),
        (bool(ANNOUNCES_WORK.search(last_par)), "stalled", "last message announces work it never did"),
        (True, "finished", "last message reads as a final report"),
    ]
    cls, why = next((cls, why) for hit, cls, why in rules if hit)
    # A background command can still wake the session, so a fresh announcement is not a stall yet.
    if cls == "stalled" and idle_min < IDLE_MIN:
        return "working", f"announced work {idle_min} min ago, grace is {IDLE_MIN:g} min"
    return cls, why


def hc_json(*args):
    return json.loads(subprocess.run([HC, *args, "--json"], capture_output=True, text=True, check=True).stdout)


def agent_state(status):
    """Herdr's terminal status as the classifier's agent state."""
    status = (status or "").lower()
    if status == "working":
        return "processing"
    if "block" in status or "wait" in status:
        return "awaiting"
    return "idle"


def load_panes(terminals_file):
    """Local Claude terminals in Herdr that were launched on an open brief, with the session that works it.

    Returns dicts with id (terminal address), tab_id (the tab's label), agent_session_id and agent_state.
    A terminal on another machine (address machine/tN) is skipped: its transcripts are not on this one."""
    try:
        if terminals_file:
            return [p for p in json.loads(Path(terminals_file).read_text())["data"] if p.get("agent_session_id")]
        terminals = hc_json("ls")["terminals"]
        briefs = open_briefs()
        out = []
        for t in terminals:
            if t.get("agent") != "claude-code" or "/" in t["address"] or t.get("state") != "live":
                continue
            launch = " ".join(hc_json("get", t["address"]).get("argv") or [])
            brief = next((b for b in briefs if str(b) in launch), None)
            if not brief:
                continue
            found = [x for x in scan_sessions([brief], brief.stat().st_mtime - 60).get(brief, []) if x[2] != "claude-desktop"]
            if found:
                out.append({"id": t["address"], "tab_id": t.get("where", ""), "agent_session_id": max(found)[1].stem,
                            "agent_state": agent_state(t.get("status"))})
        return out
    except (OSError, subprocess.CalledProcessError, KeyError, json.JSONDecodeError):
        return []  # no Herdr running: Desktop sessions are still watched


def head_text(path, n=12):
    """Text of the first user entries and the entrypoint, without reading the whole transcript."""
    text, entry = [], ""
    with path.open(errors="replace") as f:
        for _, line in zip(range(n), f):
            try:
                e = json.loads(line)
            except json.JSONDecodeError:
                continue
            entry = entry or e.get("entrypoint", "")
            content = e.get("message", {}).get("content") if e.get("type") == "user" else None
            if isinstance(content, list):
                content = " ".join(b.get("text", "") for b in content if isinstance(b, dict))
            if isinstance(content, str):
                text.append(content)
    return " ".join(text), entry


def scan_sessions(briefs, since):
    """{brief: [(mtime, path, entrypoint)]} for transcripts modified since `since` that name an open brief."""
    found = {}
    for path in PROJECTS_DIR.glob("*/*.jsonl"):
        mtime = path.stat().st_mtime
        if mtime < since:
            continue
        text, entry = head_text(path)
        for b in briefs:
            if str(b) in text:
                found.setdefault(b, []).append((mtime, path, entry))
    return found


def collect(terminals_file=None, now=None):
    now = now or time.time()
    briefs = set(open_briefs())
    state = load_state()
    rows, seen = [], set()
    for pane in load_panes(terminals_file):
        session = pane["agent_session_id"]
        path, entries = read_transcript(session)
        if not path:
            continue
        prompt = first_prompt(entries)
        brief = next((b for b in briefs if str(b) in prompt), None)
        if not brief:
            continue
        idle = max(0, int((now - path.stat().st_mtime) // 60))
        text, uuid, pending = last_turn(entries)
        cls, why = classify(pane.get("agent_state", ""), idle, text, pending)
        tail = " ".join(text.split())[-240:]
        row = Handoff(brief.name, pane.get("tab_id", ""), pane["id"], session,
                      pane.get("agent_state", ""), idle, cls, why, uuid, tail, "")
        if cls == "stalled":
            row.nudge = ("refused: already nudged, no output since" if state.get(session) == uuid
                         else nudge_message(row))
        rows.append(row)
        seen.add(brief)
    rows += unpaned_rows(briefs - seen, state, now)
    return sorted(rows, key=lambda r: ("stalled", "not-started", "finished", "waiting", "working").index(r.cls))


def unpaned_rows(briefs, state, now):
    """Desktop sessions found by transcript, and briefs no session ever opened."""
    if not briefs:
        return []
    found = scan_sessions(briefs, min(b.stat().st_mtime for b in briefs) - 60)
    rows = []
    for b in sorted(briefs):
        sessions = [x for x in found.get(b, []) if x[0] >= b.stat().st_mtime - 60]
        age = max(0, int((now - b.stat().st_mtime) // 60))
        if not sessions:
            if IDLE_MIN <= age <= 7 * 24 * 60:  # older briefs are abandoned, not unopened
                rows.append(Handoff(b.name, "-", "", "", "", age, "not-started",
                                    "no session has opened this brief; Enter was likely never pressed",
                                    "", "", "report only: nothing to nudge", "none"))
            continue
        mtime, path, entry = max(sessions)
        if entry != "claude-desktop":
            continue  # a CLI session outside Herdr: not ours to watch
        _, entries = read_transcript(path.stem)
        idle = max(0, int((now - mtime) // 60))
        text, uuid, pending = last_turn(entries)
        cls, why = classify("", idle, text, pending)
        if cls == "waiting" and pending not in ("", "AskUserQuestion") and idle < IDLE_MIN:
            cls, why = "working", f"tool call {pending} running or awaiting permission, {idle} min"
        row = Handoff(b.name, "desktop", "", path.stem, "", idle, cls, why, uuid,
                      " ".join(text.split())[-240:], "", "desktop")
        if cls == "stalled":
            row.nudge = "report only: Desktop sessions cannot be nudged; reopen the session and tell it to continue"
        rows.append(row)
    return rows


def notify_rows(rows, state):
    """macOS notification for each stalled Desktop session and not-started brief, once per silence."""
    sent = []
    for r in rows:
        if not (r.cls == "not-started" or (r.cls == "stalled" and r.surface == "desktop")):
            continue
        key = f"notify:{r.brief}:{r.last_uuid}"
        if state.get(key):
            continue
        what = "was never started (press Enter in the Desktop session)" if r.cls == "not-started" else "went idle"
        notifier("Handoff needs you", f"{r.brief} {what}")
        state[key] = True
        sent.append(r.brief)
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, indent=2))
    return sent


def notifier(title, message):
    esc = lambda t: t.replace("\\", "\\\\").replace('"', '\\"')
    subprocess.run(["osascript", "-e", f'display notification "{esc(message)}" with title "{esc(title)}"'], check=False)


def nudge_message(row):
    return (f"Watchdog nudge: you went idle before finishing {HANDOFF_DIR / row.brief}. "
            "Re-read its Deliverable section and continue until every item is done and verified; "
            "if something blocks you, say what.")


def load_state():
    return json.loads(STATE_FILE.read_text()) if STATE_FILE.exists() else {}


def nudge(target, send, terminals_file=None, now=None):
    row = next((r for r in collect(terminals_file, now) if target in (r.session, r.tab, r.terminal)), None)
    if not row:
        return 2, f"no open handoff with session, tab or terminal id {target}"
    if row.surface != "herdr":
        return 3, f"refused: {row.brief} is a {row.surface} row ({row.reason}); only Herdr sessions can be nudged"
    if row.cls != "stalled":
        return 3, f"refused: {row.brief} is {row.cls} ({row.reason})"
    if row.nudge.startswith("refused"):
        return 3, f"refused: {row.brief} was already nudged and has produced no output since"
    msg, state = row.nudge, load_state()
    if not send:
        return 0, f"dry run, would send to terminal {row.terminal}:\n{msg}"
    subprocess.run([HC, "send", row.terminal, msg], check=True)
    state[row.session] = row.last_uuid
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, indent=2))
    return 0, f"sent to terminal {row.terminal}:\n{msg}"


def print_table(rows):
    print(f"{'CLASS':9} {'IDLE':>6} {'TAB':18} {'BRIEF':34} REASON")
    for r in rows:
        print(f"{r.cls:9} {r.idle_min:>5}m {r.tab[:18]:18} {r.brief:34} {r.reason}")
        print(f"{'':9} {'':>6} session {r.session} | …{r.tail[-140:]}")
        if r.nudge:
            print(f"{'':9} {'':>6} nudge: {r.nudge}")


def selftest():
    global HANDOFF_DIR, PROJECTS_DIR, STATE_FILE, HC
    tmp = Path(tempfile.mkdtemp())
    HANDOFF_DIR, PROJECTS_DIR, STATE_FILE, HC = tmp / "h", tmp / "p", tmp / "s.json", "true"
    (PROJECTS_DIR / "proj").mkdir(parents=True)
    HANDOFF_DIR.mkdir()
    (HANDOFF_DIR / "closed.done.md").write_text("x")
    cases = {  # session: (agent_state, final text, expected class)
        "s-work": ("processing", "I'll run the tests.", "working"),
        "s-ask": ("idle", "Which schema should I use?", "waiting"),
        "s-done": ("idle", "Built the skill.\n\nAll five evals pass.", "finished"),
        "s-stall": ("idle", "Tests are running.\n\nI'll commit once they pass.", "stalled"),
        "s-br": ("idle", "Tests run in the background. I'll push once they pass.\n\n<br>\n\n<br>", "stalled"),
        "s-closed": ("idle", "I'll continue.", None),
    }
    panes = []
    for sid, (st, text, _) in cases.items():
        brief = HANDOFF_DIR / ("closed.done.md" if sid == "s-closed" else f"{sid}.md")
        brief.touch()
        lines = [{"type": "user", "message": {"content": f"Read {brief} and execute it end to end."}},
                 {"type": "assistant", "uuid": f"u-{sid}", "message": {"content": [{"type": "text", "text": text}]}}]
        f = PROJECTS_DIR / "proj" / f"{sid}.jsonl"
        f.write_text("\n".join(json.dumps(line) for line in lines))
        os.utime(f, (time.time() - 3600, time.time() - 3600))
        panes.append({"id": f"p-{sid}", "tab_id": f"t-{sid}", "agent_session_id": sid, "agent_state": st})
    pf = tmp / "panes.json"
    pf.write_text(json.dumps({"data": panes}))
    got = {r.session: r.cls for r in collect(pf)}
    want = {sid: c for sid, (_, _, c) in cases.items() if c}
    assert got == want, f"classes: got {got}, want {want}"
    desktop_selftest(tmp, pf)
    assert classify("idle", 5, "I'll commit once they pass.", "")[0] == "working", "a fresh announcement gets a grace period"
    assert nudge("s-ask", True, pf)[0] == 3, "a waiting session must never be nudged"
    assert nudge("t-s-stall", False, pf)[0] == 0, "a tab id selects the session"
    assert nudge("s-stall", True, pf)[0] == 0, "a stalled session is nudged once"
    assert nudge("s-stall", True, pf)[0] == 3, "no second nudge without new output"
    herdr_selftest(tmp)
    print("selftest ok")


def herdr_selftest(tmp):
    """The Herdr path: a fake hc lists terminals; one claude terminal is launched on an open brief."""
    global HC
    brief = HANDOFF_DIR / "hz-live.md"
    brief.touch()
    f = PROJECTS_DIR / "proj" / "hz-sess.jsonl"
    lines = [{"type": "user", "entrypoint": "cli", "message": {"content": f"/goal The brief at {brief} is executed."}},
             {"type": "assistant", "uuid": "u-hz", "message": {"content": [{"type": "text", "text": "Tests are running.\n\nI'll commit once they pass."}]}}]
    f.write_text("\n".join(json.dumps(line) for line in lines))
    t = time.time() + 60 - 3600
    os.utime(f, (t, t))
    os.utime(brief, (t - 120, t - 120))
    ls = {"terminals": [
        {"address": "t7", "agent": "claude-code", "state": "live", "status": "done", "where": "~ / hz tab"},
        {"address": "t8", "agent": "claude-code", "state": "live", "status": "done", "where": "~ / other"},
        {"address": "t9", "agent": "zsh", "state": "live", "where": "~ / shell"},
        {"address": "nas/t1", "agent": "claude-code", "state": "live", "status": "done", "where": "remote"}]}
    sent = tmp / "hc-sent.log"
    fake = tmp / "hc"
    fake.write_text(
        "#!/bin/sh\ncase \"$1\" in\n"
        f"  ls) echo '{json.dumps(ls)}' ;;\n"
        f"  get) if [ \"$2\" = t7 ]; then echo '{json.dumps({'argv': ['claude', '--model', 'sonnet', f'/goal The brief at {brief} is executed.']})}'; "
        "else echo '{\"argv\": [\"claude\"]}'; fi ;;\n"
        f"  send) shift; echo \"$*\" >> {sent} ;;\nesac\n")
    fake.chmod(0o755)
    HC = str(fake)
    rows = {r.brief: r for r in collect() if r.brief == "hz-live.md"}
    row = rows["hz-live.md"]
    assert (row.terminal, row.tab, row.session, row.cls, row.surface) == ("t7", "~ / hz tab", "hz-sess", "stalled", "herdr"), row
    assert nudge("t7", True)[0] == 0 and sent.read_text().startswith("t7 Watchdog nudge"), "hc send gets the terminal and the message"
    assert [agent_state(x) for x in ("working", "done", None, "blocked")] == ["processing", "idle", "idle", "awaiting"]


def desktop_selftest(tmp, pf):
    """Desktop transcripts (no terminal) and briefs nobody opened."""
    def transcript(sid, brief, entry, text, age_min):
        lines = [{"type": "user", "entrypoint": entry, "message": {"content": f"/goal The brief at {brief} is executed."}},
                 {"type": "assistant", "uuid": f"u-{sid}", "message": {"content": [{"type": "text", "text": text}]}}]
        f = PROJECTS_DIR / "proj" / f"{sid}.jsonl"
        f.write_text("\n".join(json.dumps(line) for line in lines))
        t = time.time() - age_min * 60
        os.utime(f, (t, t))

    for name, sid, entry, text, age in [
        ("d-stall.md", "dk-stall", "claude-desktop", "Tests are running.\n\nI'll commit once they pass.", 60),
        ("d-done.md", "dk-done", "claude-desktop", "Built it.\n\nAll checks pass.", 60),
        ("d-ask.md", "dk-ask", "claude-desktop", "Which schema should I use?", 60),
        ("d-fresh.md", "dk-fresh", "claude-desktop", "I'll run the tests now.", 3),
        ("d-cli.md", "dk-cli", "cli", "I'll continue.", 60),
    ]:
        b = HANDOFF_DIR / name
        b.touch()
        os.utime(b, (time.time() - 3600, time.time() - 3600))
        transcript(sid, b, entry, text, age)
    old, new = HANDOFF_DIR / "n-old.md", HANDOFF_DIR / "n-new.md"
    old.touch(); new.touch()
    os.utime(old, (time.time() - 3600, time.time() - 3600))
    rows = {r.brief: r for r in collect(pf)}
    want = {"d-stall.md": "stalled", "d-done.md": "finished", "d-ask.md": "waiting", "d-fresh.md": "working",
            "n-old.md": "not-started"}
    got = {k: v.cls for k, v in rows.items() if k in want or k in ("d-cli.md", "n-new.md")}
    assert got == want, f"desktop classes: got {got}, want {want}"
    assert rows["d-stall.md"].surface == "desktop" and rows["n-old.md"].surface == "none"
    assert nudge("dk-stall", True, pf)[0] == 3, "a Desktop session must never be nudged"
    assert nudge("n-old.md", True, pf)[0] == 2, "a not-started brief has no session to nudge"
    calls = []
    global notifier
    real, notifier = notifier, lambda t, m: calls.append(m)
    try:
        sent = notify_rows(list(rows.values()), {})
        assert sorted(sent) == ["d-stall.md", "n-old.md"], f"notified {sent}"
        state = {f"notify:{r.brief}:{r.last_uuid}": True for r in rows.values()}
        assert notify_rows(list(rows.values()), state) == [], "one notification per silence"
    finally:
        notifier = real


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["list", "nudge", "selftest"])
    ap.add_argument("session", nargs="?")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--send", action="store_true")
    ap.add_argument("--notify", action="store_true", help="macOS notification for stalled Desktop sessions and not-started briefs")
    ap.add_argument("--terminals", "--panes", dest="terminals", help="JSON file of already-resolved terminals ({\"data\": [...]}), instead of asking Herdr")
    ap.add_argument("--now", type=float, help="epoch seconds to measure idle time from")
    a = ap.parse_args()
    if a.cmd == "selftest":
        return selftest()
    if a.cmd == "list":
        rows = collect(a.terminals, a.now)
        if a.notify:
            notify_rows(rows, load_state())
        print(json.dumps([asdict(r) for r in rows], indent=2)) if a.json else print_table(rows)
        return
    if not a.session:
        ap.error("nudge needs a session id")
    code, out = nudge(a.session, a.send, a.terminals, a.now)
    print(out)
    sys.exit(code)


if __name__ == "__main__":
    main()
