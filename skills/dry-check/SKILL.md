---
name: dry-check
description: Lists near-duplicate code pairs that involve lines a branch added, with both locations and the shared helper that removes them, marks each NEW and records the count for the head commit. Works for Elixir (Credo DuplicatedCode) and for TypeScript, Python, Go, Java, Rust and Clojure (dryer). Use when the user says "check my branch for copy-paste", "did I duplicate code", "dry check", "run dryer on my branch", "find duplicates before the PR", or "check the tests and code quality of this branch".
metadata:
  category: verify
---

# Duplication check on a branch

Find code the branch copied. A pair counts when at least one side overlaps a line the branch added and its two files hold more pairs at HEAD than the same tool finds on the base tree, so editing an old duplicate never lists it. A renamed file is skipped, so a copy added inside a renamed file is missed rather than an old one blocked. The result is a table, one row per pair, plus a record the PR gate reads.

Run it with its siblings for "check the tests and code quality of this branch": `crap-check` (complexity without tests) and `mutation-test` (weak tests).

## Run the check

1. Commit the work and stand at the repo root on the branch. The script refuses a tree with uncommitted tracked changes, because line numbers must match HEAD. Done when `git status --porcelain --untracked-files=no` prints nothing.
2. Run the script with the base branch:

   ```sh
   <skill folder>/scripts/dry-check.sh --base origin/main
   ```

   Without `--base` it tries `origin/staging`, `origin/main`, `origin/master`, then the remote's default branch; a `--base` that does not resolve stops the run instead of falling back. Done when it exits 0 and its last stdout line reads `new=<N> threshold=<score> min_lines=<L>`. Exit 2 means a setup error; report the message, because a failed run writes no record.
3. Read the table. `NEW` rows come first, best score first. Each side is `file:start-end`; the left side is the one with branch-added lines. Done when every row's two locations are open and compared in the source.
4. Replace the placeholder in each `fix` cell with a concrete reuse: the helper's name and signature, the module both sides can reach (their nearest shared parent, or an existing util or context module), and the call sites that switch to it. Prefer calling code that already exists over writing a new helper. A matching tree can still call different local helpers, so compare every function each body calls before proposing one side call the other, and grep for the copy's callers instead of assuming some exist. Done when no row keeps the placeholder text.
5. Report from the run on the user's branch only. Open with the verdict (`new=N`, and whether the PR gate will pass), give the rows the script printed and nothing else, then end with the script's last line verbatim and the record path it printed on stderr. When the script did not run or failed, say so and say the gate will block; never predict rows. When the request covers tests or code quality, name `crap-check` and `mutation-test` as the checks that cover the rest. Done when every figure in the report appears in the script's output.

## What each tool matches

| Language | Tool | Match | Score |
|---|---|---|---|
| Elixir | Credo `DuplicatedCode`, the only check enabled, config in `credo/dry.exs` | identical syntax tree, metadata removed, mass 40 or more | 1.0 |
| Others | dryer, pinned to one commit and cloned once into the cache | structural similarity over normalized functions | 0.8 or more |

Credo matches exact trees, so a copy with renamed locals escapes it where dryer would catch it. Say so when an Elixir branch reports `new=0`. Credo reports only a start line, so `scripts/spans.exs` computes each side's span with plain `elixir`; `scripts/join.py` keeps the pairs that touch added lines and drops pairs whose shorter side has fewer than `DRY_MIN_LINES` lines.

## Rules that keep the repo untouched

- Credo runs over the whole source tree with no path argument, because a path argument makes this check return nothing. Dryer compares the whole source tree too, so a changed function can match an unchanged one. Never use `--changed` in either tool: dryer's flag reads uncommitted work, not the branch.
- The Credo config lives in this skill; the project's own config stays as it is. Dryer writes its metrics folder to a scratch directory. Done when `git status --porcelain` is empty after the run.
- Never run `git stash`, `git checkout .` or `git reset` in the target repo.
- In a project copy with a cold build, restore a warm build before the run; Credo loads dependencies only and needs no project compile.

## Settings

| Variable | Default | Effect |
|---|---|---|
| `DRY_THRESHOLD` | 0.8 | dryer's minimum score |
| `DRY_MIN_LINES` | 6 | shortest duplicated block, both tools |
| `DRY_CHECK_DRYER` | cache clone | folder of an existing dryer clone |
| `DRY_CHECK_SRC` | `src lib app apps packages server services source`, else the repo root | dryer's source dirs, colon-separated |
| `DRY_CHECK_MIX_ENV` | test | Mix environment for Credo |
| `CRAP_DRY_STATE` | `$HOME/.claude/state/crap-dry` | folder holding the gate record |

State the thresholds in the report when the user gave none.

## The gate record

On success the script writes `$CRAP_DRY_STATE/dry/<repo>-<head sha>`: first line `new=<N>`, then one line per row. A PR gate compares that file with the head commit. Rewriting the placeholder in the chat does not change the file; the count is what the gate reads.
