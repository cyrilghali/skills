---
name: routine-watchdog
description: Daily, model-free health check for launchd routines (macOS) — scans every plist in a LaunchAgents directory and flags a nonzero last exit code, zero runs despite a schedule that should have fired, a log or output file gone stale relative to the schedule, or a bare command in the job's shell script that doesn't resolve under the plist's own PATH. Prints only problems, one line each with evidence (a log tail); silent except one "all N routines healthy" line when nothing is wrong. Use when asked "are my launchd routines healthy", "why did this scheduled job never run", "routine watchdog", "check my plists", "silent launchd failures", or as the daily routine-watchdog routine.
metadata:
  category: operate
---

# Checking launchd routines

Run one script and report what it prints. The script does no model reasoning: every check is a file read, a `launchctl print`, a file mtime, or a `command -v` in a clean `env -i` shell.

## Run the script

The script is installed on `PATH` as `routines`, a symlink to `scripts/routine_watchdog.py`. Pick the view you need:

```sh
routines                 # table: every routine, healthy or not
routines --sort next     # order by label (default), next, last or status
routines --failing       # only rows whose status is not ok
routines --tag personal  # only rows whose plist Tags list holds the tag
routines --grep backup   # only rows whose label, schedule, frequency, what or tags contain the text
routines --columns name,what,next   # these columns, in this order
routines --problems      # only the flagged ones, with evidence; this is what a cron job runs
routines --runs          # each last run: start, status, [handoff state], result; failures first
routines --self-test     # runs the parsing, schedule, sort and filter logic on fixed inputs; prints "self-test passed"
```

`--runs` reads each run from three places. The start comes from the log's last `=== <date> <time>` header, else the log's mtime. The result comes from the first line of the report the run names (`report: <path>`), else the log's last line. The handoffs come from any `handoffs/<slug>.md` the run mentions, shown as done, open or gone.

The script scans `ROUTINE_WATCHDOG_DIR` (default `$HOME/Library/LaunchAgents`) and skips any `*.plist.disabled`. Pass `--prefix` (or set `ROUTINE_WATCHDOG_PREFIX`, comma-separated) to keep only certain label prefixes, such as `com.example.,fr.example.`.

Read the table by its groups: rows sit under each plist's first `Tags` entry (case-insensitive, `untagged` last). The table is colored on a terminal unless `NO_COLOR` is set. Its columns:

| Column | Source |
|---|---|
| NAME | label minus its reverse-DNS prefix |
| WHAT | the plist's `Description` string; keep it under 50 characters |
| FREQUENCY | how often, from the schedule (`daily`, `3× daily`, `hourly, weekdays`, `weekly, Mon`, `monthly, days 1–7`, `every 10m`, `always on`), or the plist's `Frequency` string for a script that gates itself (hourly slots that run once a month) |
| AT | clock times (`10:00`, `11:00, 14:00`, `10:05–18:05`), `-` for an interval |
| NEXT RUN | next calendar fire; `-` for an interval, which is relative to the last run |
| STATUS | `ok` / `FAILED` (`exit N`) / `never ran` / `stale` / `missing tool` / `no output` / `not loaded` / `error` (plist unreadable) |
| LAST RUN | newest log/output file's mtime, or `unknown` |

launchd ignores `Description`, `Frequency` and `Tags`; they exist for this table. Each routine takes one line, never wrapped. To fit the terminal, the default view drops LAST RUN, NEXT RUN, AT, then FREQUENCY until WHAT shows whole; only then is WHAT cut with `…`. `--columns` keeps exactly the listed columns and cuts WHAT (or else the last column), then NAME, to fit.

Know the four checks the script runs on each plist, in this order, so you can read a flag:

1. **Nonzero last exit.** Reads the "last exit code" from `launchctl print gui/$UID/<label>`. Evidence is the tail of the first non-empty `StandardErrorPath`/`StandardOutPath` (stderr first), or else the first existing `*.log`/`*.txt` path written literally in the command, if one exists.
2. **Never ran on schedule.** Zero runs, and the plist is older than its own computed interval (`StartInterval`, or the tightest `StartCalendarInterval` entry: weekly for a `Weekday`, monthly for a `Day`, daily otherwise). "Loaded since" is the later of the plist's own mtime and the machine's last boot time (`sysctl kern.boottime`), because launchd resets every job's run count on boot without touching the plist; the boot-time floor stops a reboot from reading as "never ran" for a whole schedule cycle.
3. **Stale output.** The newest non-empty log/output path (same rule as check 1; a 0-byte file was never written to and does not count) is older than 2x the computed interval.
4. **Unresolvable command.** For a shell-run job (`ProgramArguments` calling `zsh`/`bash`/`sh -c`/`-lc`), every bare command name in the script is checked with `command -v` under `env -i PATH=<the plist's own PATH>`. Wrapper commands such as `nice`/`env`/`sudo` are stepped over to reach the real command.

Done when the script prints either problem lines or the one healthy-count line: never both, never nothing.

## Report what the script printed

Pass the printed lines on as they are; each already carries its evidence. A status that is not one of the four numbered checks is a different kind of signal: say which kind it is, and weigh what you know about the job. Before you call it a failure, check what the job is meant to do: its plist, its script's comments, any notes about it.

## Stay inside these limits

- Stay read-only: edit no plist, and load, unload or kick no job.
- Count as outputs only the plist's log keys, the `*.log` files the job's scripts write, and a stamp in `ROUTINE_WATCHDOG_STAMP_DIR` named after a `ProgramArguments` word. A job with none of these reads `no output`, never `ok`; a running `KeepAlive` daemon is exempt. A plist `Frequency` sets the stale threshold.
- Expect bare-command detection only on jobs whose `ProgramArguments` runs a shell script. A job that calls an absolute binary path directly (`/opt/homebrew/bin/uv`) has nothing this check can catch, by construction: an absolute path resolves or does not, whatever `PATH` holds.

Open `REFERENCE.md` for how the interval, the log path and the bare-command lookup are computed, and for the known limits.
