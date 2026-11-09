---
name: complexity-trend
disable-model-invocation: true
description: Weekly, model-free reading of an Elixir codebase's complexity trend (Credo complexity findings for cyclomatic complexity, ABC size, nesting and arity, total Credo findings, duplicated code, lines and modules under lib/), measured on a clean checkout of the default branch, kept as one dated row per run in a local history, and reported week on week and over 30 days next to the number of pull requests merged in the same window. Use when asked for the "complexity trend", "is our code getting more complex", "weekly complexity reading", "did complexity go up since AI tools", or as the weekly complexity-trend routine.
metadata:
  category: operate
---

# Read the complexity trend

Watch the trend, not the level. A codebase whose complexity per line keeps climbing while pull requests pour in is the pattern to catch early. The script does all the measuring. Run it, then read the result honestly for the person or routine log that asked.

## Measure with the script

```sh
COMPLEXITY_REPO=/path/to/clone scripts/complexity_trend.py
```

The script moves its own detached worktree (`COMPLEXITY_CHECKOUT`) to `origin/HEAD`, runs Credo once with the complexity and duplication checks force-enabled on the command line (the repo's `.credo.exs` stays as it is), counts lines and `defmodule`s in `lib/**/*.ex`, writes one row to the history (a rerun the same day replaces that day's row) and prints the trend. Pass `--report` to print the trend from the history without measuring. Read `REFERENCE.md` for the column meanings.

Done when the output starts with today's date and commit, or the script's error is quoted verbatim in the report.

## Give the answer in one line, then at most three judgments

Open with one line: complexity per 1,000 lines went up, went down or held over the 30-day window (or the shorter span the output names instead), and how many pull requests merged in that window. Shape it as: "Complexity per 1,000 lines <went up | went down | held> <by change> <over 30 days | over the span the output names> while <N> pull requests merged." Pick the verdict from the numbers.

When the measurement failed, open the answer line with the failure and the date of the last good row, and label any trend quoted after it as that date's.

Then add at most three short lines. Make each one a judgment the printed output does not already state, and name each number in plain words rather than by its column. Trace every claim to a line of that output; leave the history file's row count and anything the output leaves out unclaimed. Judge by these three rules:

- **Density before counts.** Base the verdict on complexity per 1,000 lines, because a raw count also moves with the size of the code. When you quote a raw count, set it against the change in lines.
- **Both complexity numbers.** `complexity` follows the project's own Credo config; `complexity_all` also counts the complexity checks it switches off. When `complexity_all` moves while the own-config delta stays near zero, say the project's config cannot see the trend. Say it as a finding, never as a config change.
- **Thin history.** Without a baseline there is no trend. Read a window the output marks "baseline not reached yet" as the span it names. Treat one week's move as a data point, not a direction.

Done when the answer line carries the 30-day density change and the merged pull request count (or states why either is missing), and nothing below it repeats a number without adding a judgment. Record the run with `skill-record complexity-trend verdict="..." findings_per_kloc=F`, where verdict is the answer line and findings_per_kloc today's complexity per 1,000 lines from the output, once, only when the run finished; a dry run or an aborted run records nothing.

## Keep the measured repo untouched

- Stay read-only toward the measured repo: never edit `.credo.exs`, never add a `credo:disable` directive, never touch the main checkout's branch. The script only moves the worktree it owns.
- Ship a failed measurement with its error. The previous rows stay untouched.
