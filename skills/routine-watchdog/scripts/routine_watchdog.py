#!/usr/bin/env python3
"""Model-free health check for launchd routines (macOS).

For every non-disabled *.plist directly under a LaunchAgents directory, checks:
  (a) last exit code nonzero (`launchctl print` "last exit code")
  (b) zero runs although the schedule should have fired since the plist was
      last loaded (the later of the plist's own mtime and the last boot time -
      launchd resets the run count on every boot, and keeps no load-time log)
  (c) its newest non-empty log/output file (StandardErrorPath/StandardOutPath,
      or a literal existing path found in the command) older than 2x the
      schedule interval - a 0-byte file (never written to) doesn't count
  (d) bare command names in a shell ProgramArguments that don't resolve under
      the plist's own PATH in a clean `env -i` shell

With no arguments, prints one table row per plist (name, what, frequency, at,
next run, status, last run), grouped by the plist's first "Tags" entry. WHAT is
the plist's "Description" string and FREQUENCY can be overridden by its
"Frequency" string; launchd ignores both keys. With --problems, prints only the
flagged lines with evidence, silent except one "all N routines healthy" line — this is what a
cron/launchd routine should call.

  routine_watchdog.py                        table of every routine, healthy or not
  routine_watchdog.py --sort next            sort by label (default), next, last or status
  routine_watchdog.py --failing              only rows whose status is not ok
  routine_watchdog.py --tag work             only rows whose Tags list holds the tag
  routine_watchdog.py --grep backup          only rows whose label, schedule, what or tags match
  routine_watchdog.py --columns name,what    only these columns, in this order
  routine_watchdog.py --prefix com.example.  only labels with this prefix (comma-separated)
  routine_watchdog.py --problems             only the flagged routines, with evidence
  routine_watchdog.py --runs                 last run, status, result and handoffs, failures first
  routine_watchdog.py --self-test

Environment:
  ROUTINE_WATCHDOG_DIR      directory of plists to scan (default: ~/Library/LaunchAgents)
  ROUTINE_WATCHDOG_PREFIX   comma-separated label prefixes to restrict to (default: all)
  ROUTINE_WATCHDOG_STAMP_DIR  directory of once-per-period stamp files, one named after a
                            word of each job's ProgramArguments (optional)
"""
import argparse
import datetime as dt
import os
import plistlib
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

DEFAULT_DIR = Path.home() / "Library/LaunchAgents"
DAY = 86400
WEEKDAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
SORT_KEYS = ("label", "next", "last", "status")
SHELL_KEYWORDS = {
    "if", "then", "else", "elif", "fi", "for", "while", "until", "do", "done",
    "case", "esac", "function", "select", "in", "echo", "cd",
    "exit", "return", "export", "set", "local", "readonly", "unset",
}
# Wrappers that take the real command as an argument, not the command itself.
WRAPPER_CMDS = {"nice", "time", "env", "sudo", "exec"}
# The plist's "Frequency" string is the real cadence of a script that gates itself
# (hourly launchd slots that run once a week); "once" has no cadence to go stale against.
FREQUENCY_SECONDS = {"hourly": 3600, "daily": DAY, "weekdays": DAY, "weekly": 7 * DAY, "monthly": 31 * DAY}
ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")


def boot_time():
    """Unix timestamp of the last boot (macOS: sysctl kern.boottime), or 0 if unreadable."""
    try:
        out = subprocess.run(["sysctl", "-n", "kern.boottime"], capture_output=True, text=True, timeout=5)
        m = re.search(r"sec\s*=\s*(\d+)", out.stdout)
        return int(m.group(1)) if m else 0
    except Exception:
        return 0


def load_plist(path):
    with open(path, "rb") as f:
        return plistlib.load(f)


def schedule_seconds(pl):
    """Best-effort interval this job is supposed to fire at, in seconds. None if unknown."""
    if "StartInterval" in pl:
        return int(pl["StartInterval"])
    cal = pl.get("StartCalendarInterval")
    if cal is None:
        return None
    entries = cal if isinstance(cal, list) else [cal]
    intervals = []
    for e in entries:
        if "Weekday" in e:
            intervals.append(7 * DAY)
        elif "Day" in e:
            intervals.append(28 * DAY)
        else:
            intervals.append(DAY)
    return min(intervals) if intervals else None


def expected_interval(pl):
    """schedule_seconds, overridden by the plist's declared Frequency when it names a period."""
    word = str(pl.get("Frequency", "")).split(",")[0].split(" ")[0].lower()
    if word == "once":
        return None
    return FREQUENCY_SECONDS.get(word) or schedule_seconds(pl)


def schedule_human(pl):
    """Plain-words schedule, e.g. 'daily 09:00', 'Mon–Fri hourly 10:05–18:05', 'every 10m'."""
    if "StartInterval" in pl:
        return _interval_human(int(pl["StartInterval"]))
    cal = pl.get("StartCalendarInterval")
    if cal is None:
        return "always on" if pl.get("KeepAlive") else "no schedule"
    entries = cal if isinstance(cal, list) else [cal]
    groups = _calendar_groups(entries)
    if groups is None:
        return "; ".join(_entry_human(e) for e in entries)
    return "; ".join(f"{days} {_times_human(times)}" for days, times in groups)


def schedule_parts(pl):
    """(how often, at what time), e.g. ('daily', '10:00'), ('hourly, weekdays', '10:05–18:05'),
    ('weekly, Mon', '11:00'), ('monthly, days 1–7', '11:00'), ('every 10m', '-').
    The plist's own "Frequency" string replaces the computed one, for a script that
    gates itself (hourly slots that run once a month)."""
    freq, at = schedule_human(pl), "-"
    cal = pl.get("StartCalendarInterval")
    groups = _calendar_groups(cal if isinstance(cal, list) else [cal]) if cal is not None else None
    if groups and len(groups) == 1:
        days, times = groups[0]
        hourly = _hourly_range(times)
        at = hourly or ", ".join(_clock(t) for t in times)
        if days.startswith("monthly"):
            freq = days.replace("monthly ", "monthly, ")
        elif days == "daily":
            freq = "hourly" if hourly or times[0][0] is None else "daily" if len(times) == 1 else f"{len(times)}× daily"
        elif days == "Mon–Fri":
            freq = "hourly, weekdays" if hourly else "weekdays"
        elif "," in days or "–" in days:
            freq = days
        else:
            freq = f"weekly, {days}"
    return str(pl.get("Frequency", freq)), at


def _interval_human(seconds):
    return "hourly" if seconds == 3600 else "daily" if seconds == DAY else f"every {human(seconds)}"


def _calendar_groups(entries):
    """[(days phrase, sorted times)] sharing one days phrase each, or None when the
    entries mix Month, Day+Weekday or Day with weekday entries (listed one by one)."""
    if not entries or any("Month" in e or ("Day" in e and "Weekday" in e) for e in entries):
        return None
    if all("Day" in e for e in entries):
        days_by_time = {}
        for e in entries:
            days_by_time.setdefault((e.get("Hour"), e.get("Minute", 0)), set()).add(e["Day"])
        return [(_month_days_human(sorted(d)), [t]) for t, d in sorted(days_by_time.items(), key=lambda kv: kv[1])]
    if any("Day" in e for e in entries):
        return None
    # Group times by the set of weekdays they fire on, so 45 slots read as one phrase.
    days_by_time = {}
    for e in entries:
        t = (e.get("Hour"), e.get("Minute", 0))
        days_by_time.setdefault(t, set()).add(e["Weekday"] % 7 if "Weekday" in e else None)
    times_by_days = {}
    for t, days in days_by_time.items():
        key = None if None in days or len(days) == 7 else frozenset(days)
        times_by_days.setdefault(key, []).append(t)
    return [
        (_days_human(days), sorted(times, key=lambda t: (t[0] is not None, t)))
        for days, times in sorted(times_by_days.items(), key=lambda kv: _day_order(kv[0]))
    ]


def _clock(t):
    h, m = t
    return f"{h:02d}:{m:02d}" if h is not None else f":{m:02d}"


def _hourly_range(times):
    """'10:05–18:05' when times are the same minute on 3+ consecutive hours, else None."""
    hours = [h for h, _ in times]
    if len(times) >= 3 and None not in hours and len({m for _, m in times}) == 1 \
            and hours == list(range(hours[0], hours[-1] + 1)):
        return f"{_clock(times[0])}–{_clock(times[-1])}"
    return None


def _day_order(days):
    return (-1,) if days is None else tuple(sorted((d - 1) % 7 for d in days))


def _days_human(days):
    """{1..5} -> 'Mon–Fri', {1, 4} -> 'Mon, Thu', None or all seven -> 'daily'."""
    if days is None or len(days) == 7:
        return "daily"
    order = sorted((d - 1) % 7 for d in days)  # Monday first
    runs, start = [], order[0]
    for prev, cur in zip(order, order[1:] + [None]):
        if cur != prev + 1:
            runs.append((start, prev))
            start = cur
    name = lambda i: WEEKDAY_NAMES[(i + 1) % 7]
    return ", ".join(name(a) if a == b else f"{name(a)}, {name(b)}" if b == a + 1 else f"{name(a)}–{name(b)}"
                     for a, b in runs)


def _month_days_human(days):
    """[1..7] -> 'monthly days 1–7', [1] -> 'monthly day 1', [1, 15] -> 'monthly days 1, 15'."""
    runs, start = [], days[0]
    for prev, cur in zip(days, days[1:] + [None]):
        if cur != prev + 1:
            runs.append(str(start) if start == prev else f"{start}–{prev}")
            start = cur
    return f"monthly day{'s' if len(days) > 1 else ''} {', '.join(runs)}"


def _times_human(times):
    """[(10,5), (11,5), ... (18,5)] -> 'hourly 10:05–18:05'; else a comma list."""
    hourly = _hourly_range(times)
    if hourly:
        return f"hourly {hourly}"
    return ", ".join(_clock(t) if t[0] is not None else f"hourly at {_clock(t)}" for t in times)


def _entry_human(e):
    hh, mm = e.get("Hour"), e.get("Minute", 0)
    time_str = f"{hh:02d}:{mm:02d}" if hh is not None else f"*:{mm:02d}"
    if "Weekday" in e:
        return f"{WEEKDAY_NAMES[e['Weekday'] % 7]} {time_str}"
    if "Day" in e:
        return f"day {e['Day']} {time_str}"
    return f"daily {time_str}"


def _calendar_matches(t, e):
    for key, attr in (("Month", "month"), ("Day", "day"), ("Hour", "hour"), ("Minute", "minute")):
        if key in e and getattr(t, attr) != e[key]:
            return False
    if "Weekday" in e and e["Weekday"] % 7 != (t.weekday() + 1) % 7:
        return False
    return True


def next_run(pl, now=None):
    """Next fire time for StartCalendarInterval, brute-forced minute by minute.
    None for StartInterval (relative to last run, not a fixed clock time) or no schedule."""
    if "StartInterval" in pl or "StartCalendarInterval" not in pl:
        return None
    now = now or dt.datetime.now()
    entries = pl["StartCalendarInterval"]
    entries = entries if isinstance(entries, list) else [entries]
    limit = now + dt.timedelta(days=32)
    candidates = []
    for e in entries:
        t = now.replace(second=0, microsecond=0) + dt.timedelta(minutes=1)
        while t <= limit:
            if _calendar_matches(t, e):
                candidates.append(t)
                break
            t += dt.timedelta(minutes=1)
    return min(candidates) if candidates else None


def launchctl_print(label):
    uid = os.getuid()
    try:
        out = subprocess.run(
            ["launchctl", "print", f"gui/{uid}/{label}"],
            capture_output=True, text=True, timeout=10,
        )
    except Exception as e:
        return None, None, False, f"launchctl print failed: {e}"
    if out.returncode != 0:
        return None, None, False, "not loaded in launchd"
    text = out.stdout
    m_exit = re.search(r"last exit code\s*=\s*(-?\d+)", text)
    m_runs = re.search(r"runs\s*=\s*(\d+)", text)
    exit_code = int(m_exit.group(1)) if m_exit else None
    runs = int(m_runs.group(1)) if m_runs else None
    running = re.search(r"^\s*state\s*=\s*running", text, re.M) is not None
    return exit_code, runs, running, None


def tail(path, n=2):
    try:
        lines = Path(path).read_text(errors="replace").splitlines()
        return " | ".join(l.strip() for l in lines[-n:] if l.strip())
    except Exception:
        return ""


def log_paths(pl):
    """Literal, existing log/output paths for this job: declared keys first,
    else any absolute path already present in the command text, then the logs
    its own scripts write."""
    paths = []
    for key in ("StandardErrorPath", "StandardOutPath"):  # stderr first: the useful
        p = pl.get(key)                                    # evidence for a failure tail
        if p:
            paths.append(p)
    if not paths:
        cmd = " ".join(pl.get("ProgramArguments", []))
        for candidate in re.findall(r"/[^\s\"'>]+\.(?:log|txt)", cmd):
            if Path(candidate).exists():
                paths.append(candidate)
    paths += [p for p in script_logs(pl) if Path(p).exists()]
    return list(dict.fromkeys(paths))


def script_text(arg):
    """The text of a ProgramArguments word that names a small text file, else None."""
    p = Path(os.path.expanduser(arg))
    try:
        if not p.is_file() or p.stat().st_size > 200_000:
            return None
        return p.read_text()
    except (OSError, UnicodeDecodeError):
        return None


def script_logs(pl, texts=None):
    """*.log paths a job's scripts write to. Many scripts redirect to their own log
    (`exec >>"$LOG"`) and declare no StandardOutPath, so without this their runs
    leave no trace the watchdog can see. Expands $HOME, the plist's own environment
    and the script's plain `VAR=value` / `VAR=${VAR:-default}` assignments."""
    env = {"HOME": str(Path.home()), **pl.get("EnvironmentVariables", {})}
    if texts is None:
        texts = [t for t in map(script_text, pl.get("ProgramArguments", [])) if t]
    found = []
    for text in texts:
        known = dict(env)

        def expand(value):
            return re.sub(r"\$\{?(\w+)\}?", lambda m: known.get(m.group(1), m.group(0)), value)
        for name, value in re.findall(r"^[ \t]*(?:export[ \t]+)?([A-Za-z_]\w*)=(\S+)", text, re.M):
            value = value.strip("\"'")
            m = re.fullmatch(r"\$\{" + name + r":-(.*)\}", value)
            if m:
                if name in env:
                    continue
                value = m.group(1)
            known[name] = expand(value)
        found += [v for v in known.values() if v.endswith(".log") and v.startswith("/")]
        found += [expand(p) for p in re.findall(r"(?:\$\{?HOME\}?|(?<![\w}/])/)[^\s\"'>;)]*\.log\b", text)]
    return [p for p in dict.fromkeys(found) if "$" not in p]


def stamp_path(pl):
    """A once-per-period stamp file named after one of the job's ProgramArguments words, if any."""
    stamp_dir = os.environ.get("ROUTINE_WATCHDOG_STAMP_DIR")
    if not stamp_dir:
        return None
    for arg in pl.get("ProgramArguments", []):
        candidate = Path(os.path.expanduser(stamp_dir)) / arg
        if "/" not in arg and candidate.is_file():
            return candidate
    return None


def last_block(text):
    """(start time text or None, lines) of the newest run in a log: the lines after the
    last `=== <date> <time> ...` header, or the last 20 lines when the log has none."""
    lines = [ANSI.sub("", l).rstrip() for l in text.splitlines()]
    for i in range(len(lines) - 1, -1, -1):
        m = re.match(r"=== (\d{4}-\d\d-\d\d \d\d:\d\d)", lines[i])
        if m:
            return m.group(1), lines[i + 1:]
    return None, lines[-20:]


def run_result(log_text, read=lambda p: Path(os.path.expanduser(p)).read_text(errors="replace")):
    """(start, one-line result, [(handoff slug, state)]) of the newest run in a log.
    The result is the first line of the report the run names (`report: <path>`),
    else the run's last non-empty log line."""
    start, lines = last_block(log_text)
    body = [l.strip() for l in lines if l.strip()]
    report_text = ""
    for l in body:
        m = re.match(r"report:\s*(\S+)", l)
        if m:
            try:
                report_text = read(m.group(1))
            except OSError:
                report_text = ""
    report_lines = [re.sub(r"^(#+\s*|VERDICT:\s*)", "", l.strip()) for l in report_text.splitlines() if l.strip()]
    result = (report_lines or body or [""])[0] if report_lines else (body[-1] if body else "")
    handoffs = []
    for folder, slug in re.findall(r"(\S*handoffs/)([\w-]+?)(?:\.done)?\.md", "\n".join(body) + "\n" + report_text):
        folder = Path(os.path.expanduser(folder.lstrip("`'\"(")))
        state = "done" if (folder / f"{slug}.done.md").exists() else "open" if (folder / f"{slug}.md").exists() else "gone"
        if (slug, state) not in handoffs:
            handoffs.append((slug, state))
    return start, " ".join(result.split()), handoffs


def shell_script_body(pl):
    """The script text if ProgramArguments runs a shell with -c/-lc, else None."""
    args = pl.get("ProgramArguments", [])
    for i, a in enumerate(args):
        if Path(a).name in ("zsh", "bash", "sh"):
            for flag in args[i + 1:]:
                if flag.startswith("-"):
                    continue
                return flag
    return None


def bare_commands(script):
    """First real command word of each shell segment, skipping wrappers like nice/env."""
    segments = re.split(r"[;\n]|&&|\|\||\|", script)
    names = []
    for seg in segments:
        seg = re.sub(r"^\s*\w+=\S+\s*", "", seg.strip())  # drop leading VAR=val
        tokens = seg.split()
        i = 0
        while i < len(tokens):
            m = re.match(r"([A-Za-z_][A-Za-z0-9_.-]*)$", tokens[i])
            if not m:
                break
            name = m.group(1)
            if name not in WRAPPER_CMDS:
                if name not in SHELL_KEYWORDS:
                    names.append(name)
                break
            i += 1
            while i < len(tokens) and tokens[i].startswith("-"):
                i += 1
                if i < len(tokens) and not tokens[i].startswith("-"):
                    i += 1
    return list(dict.fromkeys(names))


def unresolved_commands(pl):
    script = shell_script_body(pl)
    if not script:
        return []
    path = pl.get("EnvironmentVariables", {}).get("PATH", "/usr/bin:/bin:/usr/sbin:/sbin")
    names = bare_commands(script)
    if not names:
        return []
    unresolved = []
    for name in names:
        r = subprocess.run(
            ["env", "-i", f"PATH={path}", "sh", "-c", f"command -v {name}"],
            capture_output=True, timeout=5,
        )
        if r.returncode != 0:
            unresolved.append(name)
    return unresolved


def human(seconds):
    seconds = int(seconds)
    if seconds >= DAY:
        return f"{seconds // DAY}d"
    if seconds >= 3600:
        return f"{seconds // 3600}h"
    if seconds >= 60:
        return f"{seconds // 60}m"
    return f"{seconds}s"


def evaluate(plist_path):
    """One plist's full facts: schedule, last run/exit, next run, status, problem lines."""
    pl = load_plist(plist_path)
    label = pl.get("Label", plist_path.stem)
    what = str(pl.get("Description", ""))
    tags = [str(t) for t in pl.get("Tags", [])] if isinstance(pl.get("Tags"), list) else []
    interval = expected_interval(pl)
    schedule = schedule_human(pl)
    frequency, at = schedule_parts(pl)
    nrun = next_run(pl)
    problems = []
    status = "ok"

    exit_code, runs, running, err = launchctl_print(label)
    if err:
        return {
            "label": label, "schedule": schedule, "last_run": "unknown", "last_run_age": None,
            "last_exit": "-", "next_run": nrun, "status": "not loaded", "what": what, "tags": tags,
            "frequency": frequency, "at": at, "started": None, "result": "", "handoffs": [],
            "problems": [f"{label}: {err}"],
        }

    log_files = log_paths(pl)
    log_stats = []  # (path, mtime) for paths that exist
    for p in log_files:
        try:
            st = Path(p).stat()
        except FileNotFoundError:
            continue
        if st.st_size > 0:  # a 0-byte log (never written to, e.g. an all-stdout job's
            log_stats.append((p, st.st_mtime))  # empty stderr file) isn't evidence of staleness
    stamp = stamp_path(pl)
    outputs = log_stats + ([(str(stamp), stamp.stat().st_mtime)] if stamp else [])
    last_run_age = time.time() - max(m for _, m in outputs) if outputs else None
    last_run = f"{human(last_run_age)} ago" if last_run_age is not None else "unknown"
    started, result, handoffs = None, "", []
    if log_stats:
        newest_log = max(log_stats, key=lambda ps: ps[1])
        started, result, handoffs = run_result(Path(newest_log[0]).read_text(errors="replace"))
        started = started or dt.datetime.fromtimestamp(newest_log[1]).strftime("%Y-%m-%d %H:%M")
    elif stamp:
        started, result = dt.datetime.fromtimestamp(stamp.stat().st_mtime).strftime("%Y-%m-%d %H:%M"), "finished (stamp only, no log)"

    if exit_code not in (None, 0):
        ev = tail(log_stats[0][0]) if log_stats else ""  # first non-empty file, stderr-first
        problems.append(
            f"{label}: last exit {exit_code} ({runs} runs)" + (f" -- tail: {ev}" if ev else "")
        )
        status = "FAILED"

    # launchd resets `runs` to 0 on every boot, but the plist's mtime doesn't move —
    # "loaded since" is really since the plist was last written OR since the last boot,
    # whichever is more recent, or a job untouched since before a reboot reads as never-ran
    # for up to one schedule cycle after every restart.
    loaded_since = max(plist_path.stat().st_mtime, boot_time())
    plist_age = time.time() - loaded_since
    if runs == 0 and interval and plist_age > interval:
        problems.append(
            f"{label}: 0 runs but loaded {human(plist_age)} ago on a ~{human(interval)} schedule"
        )
        status = "never ran" if status == "ok" else status

    if interval and outputs:
        # newest output only: a job with a separate stderr file that stays empty
        # on success isn't stale just because that one file is old
        newest_path, newest_mtime = max(outputs, key=lambda ps: ps[1])
        log_age = time.time() - newest_mtime
        if log_age > 2 * interval:
            problems.append(
                f"{label}: log {newest_path} is {human(log_age)} old on a ~{human(interval)} schedule"
            )
            status = "stale" if status == "ok" else status

    # A job that leaves nothing behind can't be told apart from one that silently did nothing,
    # so it must not read as healthy. A running daemon with an empty stderr is the exception.
    if not outputs and not (running and pl.get("KeepAlive")) and status == "ok":
        problems.append(f"{label}: wrote no log, report or stamp; nothing shows what its last run did")
        status = "no output"

    unresolved = unresolved_commands(pl)
    if unresolved:
        path = pl.get("EnvironmentVariables", {}).get("PATH", "(default)")
        problems.append(f"{label}: {', '.join(unresolved)} not on PATH={path}")
        status = "missing tool" if status == "ok" else status

    return {
        "label": label, "schedule": schedule, "last_run": last_run, "last_run_age": last_run_age,
        "last_exit": exit_code if exit_code is not None else "-",
        "next_run": nrun, "status": status, "what": what, "tags": tags, "problems": problems,
        "frequency": frequency, "at": at, "started": started, "result": result, "handoffs": handoffs,
    }


def collect(directory=None, prefixes=None):
    directory = Path(directory or os.environ.get("ROUTINE_WATCHDOG_DIR", DEFAULT_DIR))
    prefixes = prefixes if prefixes is not None else [
        p for p in os.environ.get("ROUTINE_WATCHDOG_PREFIX", "").split(",") if p
    ]
    plists = sorted(p for p in directory.glob("*.plist") if not p.name.endswith(".disabled"))
    if prefixes:
        plists = [p for p in plists if any(p.name.startswith(pre) for pre in prefixes)]
    rows = []
    for p in plists:
        try:
            rows.append(evaluate(p))
        except Exception as e:
            rows.append({
                "label": p.stem, "schedule": "-", "last_run": "-", "last_run_age": None, "last_exit": "-",
                "next_run": None, "status": "error", "what": "", "tags": [], "frequency": "-", "at": "-",
                "started": None, "result": "", "handoffs": [],
                "problems": [f"{p.stem}: watchdog error checking this plist: {e}"],
            })
    return rows


def print_problems(rows):
    any_problem = False
    for row in rows:
        for line in row["problems"]:
            print(line)
            any_problem = True
    if not any_problem:
        print(f"all {len(rows)} routines healthy")


def print_runs(rows, width=None, color=None):
    """One line per routine, failures first, then newest run first:
    glyph, name, status, run start, [handoffs], result."""
    color = use_color() if color is None else color
    # piped (`routines --runs | less -S`), results print whole
    width = width or (shutil.get_terminal_size((120, 24)).columns if sys.stdout.isatty() else 10**6)
    names = short_names([r["label"] for r in rows])
    rows = sorted(rows, key=lambda r: (r["status"] == "ok", -(time.time() - (r["last_run_age"] or 1e12)), r["label"]))
    name_w = max([4] + [len(names[r["label"]]) for r in rows])
    for r in rows:
        glyph, hue = STATUS_LOOK.get(r["status"], ("▲", "yellow"))
        status = f"exit {r['last_exit']}" if r["status"] == "FAILED" else r["status"]
        when = dt.datetime.strptime(r["started"], "%Y-%m-%d %H:%M").strftime("%d/%m %H:%M") if r.get("started") else "never seen"
        handoffs = " ".join(f"[{slug} {state}]" for slug, state in r.get("handoffs", []))
        head = f"{glyph} {names[r['label']]:<{name_w}}  {status:<12} {when:<11}  "
        tail = fit(" ".join(x for x in (handoffs, r.get("result") or "-") if x), max(10, width - len(head)))
        print(paint(head, hue, on=color) + tail)


def sort_rows(rows, key):
    """Missing values (no next run, unknown last run) sort after known ones."""
    far = float("inf")
    keys = {
        "label": lambda r: r["label"],
        "next": lambda r: (r["next_run"] is None, r["next_run"] or dt.datetime.min, r["label"]),
        "last": lambda r: (r["last_run_age"] is None, r["last_run_age"] or far, r["label"]),
        "status": lambda r: (r["status"] == "ok", r["status"], r["label"]),
    }
    return sorted(rows, key=keys[key])


def filter_rows(rows, failing=False, grep=None, tag=None):
    if failing:
        rows = [r for r in rows if r["status"] != "ok"]
    if tag:
        rows = [r for r in rows if tag.lower() in (t.lower() for t in r.get("tags", []))]
    if grep:
        g = grep.lower()
        rows = [r for r in rows
                if any(g in str(r.get(k, "")).lower() for k in ("label", "schedule", "frequency", "what"))
                or any(g in t.lower() for t in r.get("tags", []))]
    return rows


STYLES = {"bold": "1", "dim": "2", "red": "31", "green": "32", "yellow": "33",
          "blue": "34", "magenta": "35", "cyan": "36", "grey": "90"}
TAG_COLORS = ["magenta", "blue", "cyan", "yellow", "green"]
STATUS_LOOK = {"ok": ("●", "green"), "FAILED": ("✗", "red"), "error": ("✗", "red"),
               "not loaded": ("○", "grey")}  # stale, never ran, missing tool: ▲ yellow


def use_color(stream=sys.stdout):
    return stream.isatty() and "NO_COLOR" not in os.environ


def paint(text, *styles, on=True):
    if not on or not styles:
        return text
    return f"\033[{';'.join(STYLES.get(x, x) for x in styles)}m{text}\033[0m"


def fit(text, width):
    return text if len(text) <= width else text[:max(width - 1, 0)] + "…"


def short_names(labels):
    """Drop the reverse-DNS prefix: com.me.backup -> backup, fr.shop.seo -> shop.seo.
    The owner segment ('me') is the one most labels share."""
    owners = {}
    for label in labels:
        parts = label.split(".")
        if len(parts) >= 3:
            owners[parts[1]] = owners.get(parts[1], 0) + 1
    owner = max(owners, key=owners.get) if owners else None
    names = {}
    for label in labels:
        parts = label.split(".")
        if len(parts) < 3:
            names[label] = label
            continue
        rest = parts[1:]
        names[label] = ".".join(rest[1:] if rest[0] == owner else rest)
    return names


COLUMNS = {"name": "NAME", "what": "WHAT", "frequency": "FREQUENCY", "at": "AT",
           "next": "NEXT RUN", "status": "STATUS", "last": "LAST RUN"}
CAPS = {"name": 30, "frequency": 22, "at": 20, "next": 9, "status": 12, "last": 9, "what": 60}
AUTO_DROP = ("last", "next", "at", "frequency")  # dropped in this order until WHAT fits


def print_table(rows, width=None, color=None, tag=None, columns=None):
    """One line per routine, never wrapped. With columns=None every column shows and
    AUTO_DROP makes room for WHAT; with an explicit list, that list is kept and the
    last cell is cut to fit."""
    color = use_color() if color is None else color
    width = width or shutil.get_terminal_size((120, 24)).columns
    names = short_names([r["label"] for r in rows])

    def status_text(r):
        if r["status"] == "FAILED" and r["last_exit"] not in ("-", None):
            return f"exit {r['last_exit']}"
        return r["status"]

    table = [{"name": names[r["label"]], "what": " ".join(r.get("what", "").split()),
              "frequency": r.get("frequency", r["schedule"]), "at": r.get("at", "-"),
              "next": r["next_run"].strftime("%a %H:%M") if r["next_run"] else "-",
              "status": status_text(r), "last": r["last_run"]} for r in rows]
    shown = list(columns or COLUMNS)
    widths = {k: min(max([len(COLUMNS[k])] + [len(t[k]) for t in table]), CAPS[k]) for k in shown}

    def total():
        return 1 + sum(widths[k] + 2 for k in shown)
    if columns is None:
        for drop in AUTO_DROP:
            if total() <= width:
                break
            shown.remove(drop)
    # Last resort, and for an explicit column list: cut WHAT (or the last column), then NAME.
    for k in (["what"] if "what" in shown else []) + [shown[-1], "name"]:
        if k in shown and total() > width:
            widths[k] = max(len(COLUMNS[k]), widths[k] - (total() - width))

    styles = {"what": (), "frequency": (), "at": (), "next": ("cyan",), "last": ("dim",)}

    def line(glyph, cells, styles_for):
        out = [glyph]
        for k in shown:
            cell = fit(cells[k], widths[k])
            pad = "" if k == shown[-1] else " " * (widths[k] - len(cell))
            out.append(paint(cell, *styles_for(k), on=color) + pad)
        return " ".join([out[0], "  ".join(out[1:])]).rstrip()

    bad = sum(r["status"] != "ok" for r in rows)
    parts = [("routines", ("bold",)), (f"  {len(rows)} total  ", ("dim",)), (f"● {len(rows) - bad} ok", ("green",))]
    if bad:
        parts += [("  ", ()), (f"✗ {bad} to check", ("red", "bold"))]
    plain = "".join(text for text, _ in parts)
    print("".join(paint(text, *st, on=color) for text, st in parts) if len(plain) <= width else fit(plain, width))
    print(line(" ", COLUMNS, lambda k: ("dim",)))

    groups = {}
    for r, cells in zip(rows, table):
        group = tag or (r.get("tags") or ["untagged"])[0]  # --tag shows one group, named after it
        groups.setdefault(group.lower(), []).append((r, cells))
    order = sorted(groups, key=lambda t: (t == "untagged", t))
    for n, group in enumerate(order):
        members = groups[group]
        badge = paint(f" {group.upper()} ", "bold", "7", TAG_COLORS[n % len(TAG_COLORS)], on=color) if color else f"[{group}]"
        print(f"{badge} {paint(str(len(members)), 'dim', on=color)}")
        for r, cells in members:
            glyph, hue = STATUS_LOOK.get(r["status"], ("▲", "yellow"))
            def styles_for(k, hue=hue, r=r):
                if k == "name":
                    return ("bold",) if r["status"] == "ok" else ("bold", hue)
                if k == "status":
                    return (hue,)
                return styles[k]
            print(line(paint(glyph, hue, on=color), cells, styles_for))


def parse_columns(text):
    keys = [k.strip().lower() for k in text.split(",") if k.strip()]
    unknown = [k for k in keys if k not in COLUMNS]
    if unknown or not keys:
        raise argparse.ArgumentTypeError(
            f"unknown column {', '.join(unknown) or '(none)'}; choose from {','.join(COLUMNS)}")
    return list(dict.fromkeys(keys))


def main(argv=None):
    ap = argparse.ArgumentParser(
        prog="routines", description="Health and schedule of every launchd routine.",
        epilog="examples: routines --tag work | routines --sort next | routines --failing | routines --columns name,what,next")
    ap.add_argument("--problems", action="store_true",
                    help="print only flagged routines with evidence, or one 'all N routines healthy' line")
    ap.add_argument("--runs", action="store_true",
                    help="last run, status, result and handoffs of each routine, failures first")
    ap.add_argument("--sort", choices=SORT_KEYS, default="label", help="table order (default: label)")
    ap.add_argument("--failing", action="store_true", help="only rows whose status is not ok")
    ap.add_argument("--grep", metavar="TEXT", help="only rows whose label, schedule, what or tags contain TEXT")
    ap.add_argument("--tag", metavar="TAG", help="only rows tagged TAG (the plist's Tags list), e.g. work")
    ap.add_argument("--prefix", metavar="PREFIXES",
                    help="comma-separated label prefixes (overrides ROUTINE_WATCHDOG_PREFIX)")
    ap.add_argument("--columns", metavar="LIST", type=parse_columns,
                    help=f"comma-separated columns to show, in order: {','.join(COLUMNS)} "
                         "(default: all, dropping last, next, at, frequency until WHAT fits)")
    ap.add_argument("--self-test", action="store_true", help="run the parsing self-test")
    args = ap.parse_args(argv)
    if args.self_test:
        return self_test()
    prefixes = [p for p in args.prefix.split(",") if p] if args.prefix else None
    rows = collect(prefixes=prefixes)
    if args.problems:
        print_problems(rows)
        return
    if args.runs:
        print_runs(filter_rows(rows, args.failing, args.grep, args.tag))
        return
    rows = sort_rows(filter_rows(rows, args.failing, args.grep, args.tag), args.sort)
    if rows:
        print_table(rows, tag=args.tag, columns=args.columns)
    else:
        print("no routine matches", file=sys.stderr)


def self_test():
    assert schedule_seconds({"StartInterval": 1800}) == 1800
    assert schedule_seconds({"StartCalendarInterval": {"Hour": 9, "Minute": 30}}) == DAY
    assert schedule_seconds({"StartCalendarInterval": {"Weekday": 1, "Hour": 8}}) == 7 * DAY
    assert schedule_seconds({}) is None
    script = 'd=$HOME/x; mkdir -p $d; nice -n 15 python3 foo.py >$d/r 2>>$d/l; cat $d/r; digest-add "a" "b"'
    names = bare_commands(script)
    assert "mkdir" in names and "python3" in names and "digest-add" in names and "d" not in names

    def sched(cal):
        return schedule_human({"StartCalendarInterval": cal})
    grid = [{"Weekday": d, "Hour": h, "Minute": 5} for d in range(1, 6) for h in range(10, 19)]
    assert sched(grid) == "Mon–Fri hourly 10:05–18:05", sched(grid)
    assert sched([{"Hour": h, "Minute": 0} for h in (11, 14, 17)]) == "daily 11:00, 14:00, 17:00"
    assert sched([{"Weekday": 1, "Hour": 11, "Minute": 45}, {"Weekday": 4, "Hour": 11, "Minute": 45}]) == "Mon, Thu 11:45"
    assert sched({"Weekday": 1, "Hour": 12, "Minute": 0}) == "Mon 12:00"
    assert sched({"Minute": 5}) == "daily hourly at :05"
    assert sched([{"Weekday": d, "Hour": 10, "Minute": 0} for d in (0, 1, 2, 3, 4, 5, 6)]) == "daily 10:00"
    assert sched([{"Weekday": d, "Hour": 10, "Minute": 0} for d in (6, 0)]) == "Sat, Sun 10:00"
    assert sched([{"Weekday": 1, "Hour": 9, "Minute": 0}, {"Hour": 12, "Minute": 0}]) == "daily 12:00; Mon 09:00"
    assert sched({"Day": 1, "Hour": 10, "Minute": 0}) == "monthly day 1 10:00"
    assert sched([{"Day": d, "Hour": 11, "Minute": 0} for d in range(1, 8)]) == "monthly days 1–7 11:00"
    assert sched([{"Day": d, "Hour": 9, "Minute": 30} for d in (1, 15)]) == "monthly days 1, 15 09:30"

    now = dt.datetime(2026, 9, 28, 10, 0)
    rows = [
        {"label": "b", "schedule": "Mon 12:00", "what": "Weekly disk cleanup", "status": "ok",
         "next_run": now, "last_run_age": None},
        {"label": "a", "schedule": "every 1m", "what": "Calendar alerts", "status": "FAILED",
         "next_run": None, "last_run_age": 60},
        {"label": "c", "schedule": "daily 10:00", "what": "Backup", "status": "ok",
         "next_run": now - dt.timedelta(hours=1), "last_run_age": 5},
    ]
    assert [r["label"] for r in sort_rows(rows, "label")] == ["a", "b", "c"]
    assert [r["label"] for r in sort_rows(rows, "next")] == ["c", "b", "a"]
    assert [r["label"] for r in sort_rows(rows, "last")] == ["c", "a", "b"]
    assert [r["label"] for r in sort_rows(rows, "status")] == ["a", "b", "c"]
    assert [r["label"] for r in filter_rows(rows, failing=True)] == ["a"]
    assert [r["label"] for r in filter_rows(rows, grep="DISK")] == ["b"]
    assert [r["label"] for r in filter_rows(rows, grep="daily")] == ["c"]
    rows[0]["tags"], rows[1]["tags"], rows[2]["tags"] = ["work"], ["personal", "work"], []
    assert [r["label"] for r in filter_rows(rows, tag="WORK")] == ["b", "a"]
    assert [r["label"] for r in filter_rows(rows, grep="person")] == ["a"]
    assert short_names(["com.me.backup", "com.me.cal", "fr.shop.seo", "sh.brew.ollama", "solo"]) == {
        "com.me.backup": "backup", "com.me.cal": "cal", "fr.shop.seo": "shop.seo",
        "sh.brew.ollama": "brew.ollama", "solo": "solo"}
    assert schedule_human({"KeepAlive": True}) == "always on"

    def parts(cal, **extra):
        return schedule_parts({"StartCalendarInterval": cal, **extra})
    assert parts(grid) == ("hourly, weekdays", "10:05–18:05")
    assert parts(grid, Frequency="monthly") == ("monthly", "10:05–18:05")
    assert parts({"Hour": 10, "Minute": 0}) == ("daily", "10:00")
    assert parts([{"Hour": h, "Minute": 0} for h in (11, 14, 17)]) == ("3× daily", "11:00, 14:00, 17:00")
    assert parts([{"Weekday": d, "Hour": 10, "Minute": 15} for d in range(1, 6)]) == ("weekdays", "10:15")
    assert parts({"Weekday": 1, "Hour": 11, "Minute": 0}) == ("weekly, Mon", "11:00")
    assert parts([{"Weekday": 1, "Hour": 11, "Minute": 45}, {"Weekday": 4, "Hour": 11, "Minute": 45}]) == ("Mon, Thu", "11:45")
    assert parts([{"Day": d, "Hour": 11, "Minute": 0} for d in range(1, 8)]) == ("monthly, days 1–7", "11:00")
    assert parts({"Minute": 5}) == ("hourly", ":05")
    assert parts([{"Weekday": 1, "Hour": 9, "Minute": 0}, {"Hour": 12, "Minute": 0}]) == ("daily 12:00; Mon 09:00", "-")
    assert parts([]) == ("", "-")
    assert sched([{"Weekday": d, "Hour": 9, "Minute": 0} for d in range(7)] + [{"Hour": 10, "Minute": 0}]) == "daily 09:00, 10:00"
    assert sched([{"Day": 1, "Hour": 9, "Minute": 0}] * 2) == "monthly day 1 09:00"
    assert schedule_parts({"StartInterval": 600}) == ("every 10m", "-")
    assert schedule_parts({"KeepAlive": True}) == ("always on", "-")
    import io, contextlib
    rows[0]["what"] = "Prunes forks, worktrees, caches, Docker images"
    rows.append(dict(rows[0], label="com.me.monthly-cleanup", status="ok", tags=["Work"],
                     frequency="monthly, 1st weekday", at="11:00, 14:00, 17:00",
                     what="Health of the monthly cleanup run"))
    rows = [dict(r, last_exit="-", last_run="1h ago", schedule="Mon 12:00") for r in rows]
    for w in (40, 60, 80, 120, 200):
        for cols in (None, ["name", "what"], ["status", "name", "frequency", "at", "next", "last", "what"]):
            buf = io.StringIO()
            with contextlib.redirect_stdout(buf):
                print_table(rows, width=w, color=False, columns=cols)
            out = buf.getvalue().splitlines()
            if cols is None or len(cols) <= 2 or w >= 120:  # seven explicit columns can't fit 40
                assert all(len(l) <= w for l in out), (w, cols, out)
            assert len(out) == 2 + 3 + len(rows), (w, cols, out)  # no wrapped continuation lines
            if w >= 120 and cols is None:
                assert all(r["what"] in "\n".join(out) for r in rows), (w, cols, out)
            if cols:
                assert out[1].split() == " ".join(COLUMNS[k] for k in cols).split(), (cols, out[1])
    assert parse_columns("Name, what,name") == ["name", "what"]
    many = [dict(rows[1], label=f"com.me.x{i}", status="FAILED") for i in range(30)]
    for colored in (False, True):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            print_table(many, width=40, color=colored)
        assert len(re.sub(r"\033\[[0-9;]*m", "", buf.getvalue().splitlines()[0])) <= 40
    for bad in ("nope", ","):
        try:
            parse_columns(bad)
            raise AssertionError(bad)
        except argparse.ArgumentTypeError:
            pass
    assert expected_interval({"Frequency": "weekly, Mon", "StartCalendarInterval": grid}) == 7 * DAY
    assert expected_interval({"Frequency": "once", "StartCalendarInterval": {"Hour": 9}}) is None
    assert expected_interval({"StartCalendarInterval": {"Hour": 9}}) == DAY
    home = str(Path.home())
    script = 'OUT="${OUT:-$HOME/s/ch}"\nLOG="$OUT/routine.log"\nexec >>"$LOG" 2>&1\nfoo >>/tmp/x.log\nB="${B:-$HOME/b.log}"'
    assert script_logs({}, [script]) == [f"{home}/s/ch/routine.log", f"{home}/b.log", "/tmp/x.log"], script_logs({}, [script])
    assert "/e/b.log" in script_logs({"EnvironmentVariables": {"B": "/e/b.log"}}, [script])
    log = "=== 2026-10-05 09:05:02 x ===\nreport: /r.md\nlimit hit\n=== 2026-10-05 11:05:04 x ===\n\x1b[1Areport: /r.md\nmap refreshed\n"
    report = "VERDICT: Fix handed off from the brief at `~/st/handoffs/fix-1.md`.\nmore"
    assert run_result(log, read=lambda p: report) == (
        "2026-10-05 11:05", "Fix handed off from the brief at `~/st/handoffs/fix-1.md`.", [("fix-1", "gone")])
    assert run_result("a\n\nlast line  \n", read=lambda p: "") == (None, "last line", [])
    assert run_result("", read=lambda p: "") == (None, "", [])
    print("self-test passed")


if __name__ == "__main__":
    main()
