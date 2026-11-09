# complexity-trend reference

## History columns

Tab-separated, one header line, one row per measured day, sorted by date.

| Column | Meaning |
|---|---|
| `date` | Day of the run (a same-day rerun replaces the row) |
| `commit` | Short SHA of `origin/HEAD` that was measured |
| `credo_total` | Credo `--strict` findings from checks the project's own config enables |
| `complexity` | Findings from CyclomaticComplexity, ABCSize, Nesting and FunctionArity that the project's config enables |
| `complexity_all` | Findings from those four checks, each force-enabled with default parameters when the config disables it |
| `duplicated` | DuplicatedCode findings, force-enabled |
| `loc` | Newline count across git-tracked `lib/**/*.ex` files |
| `modules` | `defmodule` lines across the same files |

Density in the report is `complexity_all` per 1,000 `loc`.

## How the counts are derived

One Credo run passes `--enable-disabled-checks` with the four complexity checks
and DuplicatedCode. `mix credo info --verbose --format json` lists the checks the
project's config enables; a finding counts toward `credo_total` and
`complexity` only when its check is in that list. A check the config enables
keeps the config's own parameters; a force-enabled one runs with Credo's
defaults.

## Baselines

- Week on week: the latest row at least 7 days older than the newest row.
- 30-day: the latest row at least 30 days older; before 30 days of history, the
  oldest row, and the report names its date.
- Merged pull requests: GitHub search `is:pr is:merged base:<default branch>
  merged:<baseline date>..<newest date>`, via `gh`. Unavailable when `gh` is
  missing or unauthenticated; the report says so.

## Cost

A fresh worktree starts from a copy of the clone's own `deps` and `_build`
(copy-on-write where the filesystem allows), so only what differs from the
clone recompiles. Without a warm build in the clone, the first run compiles
every dependency (tens of minutes on a large app); later runs reuse the
worktree's `_build`.
