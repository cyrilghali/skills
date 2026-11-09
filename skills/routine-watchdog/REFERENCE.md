# routine-watchdog reference

## Computing the schedule interval

Only `StartInterval` (seconds) and `StartCalendarInterval` are read; a job on
`WatchPaths`, `KeepAlive`, or `RunAtLoad` alone has no computable interval and
only check 1 and check 4 apply to it (checks 2 and 3 need an interval to
compare against, and are skipped rather than guessed at).

`StartCalendarInterval` can be a single dict or a list of dicts (several fire
times). Each entry's own interval is inferred from which keys it sets:

| Keys present | Assumed interval |
|---|---|
| `Weekday` | 7 days |
| `Day` (no `Weekday`) | 28 days |
| `Hour`/`Minute` only | 1 day |

A list takes the tightest (smallest) of its entries' intervals, since that's
how often the job is expected to produce fresh evidence at minimum.

## Finding the log path

`StandardErrorPath`/`StandardOutPath` are checked first (in that order — a
failure's evidence is usually on stderr) since they're the plist's own
declared destination. When neither is set (a job that logs to a path it
builds at runtime, e.g. from a `$HOME`-relative variable), the script falls
back to scanning the joined `ProgramArguments` text for a literal absolute
path ending `.log` or `.txt` that already exists on disk — a dynamic path
built from a shell variable (`$d/routine.log`) isn't visible to a regex and
is silently skipped, not guessed at. When no path is found at all, check 3
has nothing to compare and does not fire for that job.

A 0-byte log file (never written to — e.g. a job that only writes to stdout
on success, leaving its declared stderr file empty) is not evidence of
anything and is excluded before picking the newest file; check 3 compares
only the newest non-empty log file's age, not each declared file
individually, so a fresh stdout log next to an untouched, empty stderr file
doesn't read as stale.

## Bare-command resolution

Only fires on `ProgramArguments` shaped like `[<shell>, <-c flag>, <script>]`
— matched by the shell's file name (`zsh`/`bash`/`sh`), any leading path
included, so `/opt/homebrew/bin/bash -c ...` is recognized the same as
`/bin/bash -c ...`. The script string is split on `;`, newline, `&&`, `||`, and `|`; each
segment's leading `VAR=val` assignment is dropped, then wrapper commands
(`nice`, `time`, `env`, `sudo`, `exec`) are stepped over — including their
flags and, heuristically, one non-flag token right after a flag (covers
`nice -n 15 <cmd>`) — to reach the real command name. Shell keywords
(`if`/`for`/`echo`/... ) are excluded. Each remaining bare name is checked
with `command -v` inside `env -i PATH=<plist's EnvironmentVariables.PATH,
or /usr/bin:/bin:/usr/sbin:/sbin if unset> sh -c 'command -v <name>'` — the
same minimal environment launchd itself gives a job with no `PATH` override,
which is exactly the gap that leaves a `zsh -lc`/`bash -lc` job silently unable
to find a tool from `~/.local/bin` or a package manager's bin dir until its
plist gets an explicit `PATH`.

An absolute path used directly as `ProgramArguments[0]` (no shell) is never
checked — it either exists on disk or it doesn't, and `PATH` plays no part.

## Known limits

- "Loaded since" is the later of the plist file's own mtime and the machine's
  last boot time (`sysctl -n kern.boottime`) — launchd resets every job's
  `runs` counter on every boot, so without the boot-time floor a job untouched
  since before a reboot would read as "never ran" for up to one full schedule
  cycle after every restart. A login/logout that resets the `gui/<uid>` domain
  without a full reboot isn't covered the same way (no equivalent syscall);
  that case can still read as a false never-ran for one cycle.
- A plist that was re-saved for an unrelated edit (e.g. a comment fix) without
  ever being reloaded resets its own mtime and could mask a real "never ran"
  case for one schedule cycle, the same way a reboot does.
- A `not loaded` status says only that launchd holds no job with that label
  right now; the script records no reason why the job left.
- The failure-exit check reads "last exit code" from `launchctl print`; a job
  killed by a signal rather than exiting may have no such line, which this
  check would then miss (untested — no plist here has hit it).
- The `ROUTINE_WATCHDOG_PREFIX` filter matches the plist's *file name*, not
  its `Label` — the two differ only if a plist is renamed without updating
  its `Label` key inside, which none of the plists this was built against do.
- A `StartCalendarInterval` entry with only `Minute` set (fires every hour)
  prints as "daily *:MM" and is treated as a 1-day interval — this can only
  under-flag a genuinely hourly job as less frequent than it is, never
  invent a problem. An entry with `Month` set gets a 28-day interval and no
  computed next run; no plist here uses `Month`.
- A job that keeps `runs > 0`, exits 0 every time, and only ever produces
  0-byte logs (or none at all) is caught by no check: checks 1 and 2 see a
  clean exit and a nonzero run count, and check 3 has no non-empty file to
  compare an age against. A silent regression in a job's own logging (it stops
  writing but keeps "succeeding") is invisible to this script by construction.
- Bare-command detection is heuristic, not a shell parser: `env FOO=1 <cmd>`
  or `sudo -E <cmd>` can misidentify the real command, a `;` inside a quoted
  string is treated as a segment break, and a shell function definition
  (`f() { ...; }; f`) is checked as if `f` were a PATH lookup. None of this
  machine's plists hit these shapes; a job that does will need eyeballing.
