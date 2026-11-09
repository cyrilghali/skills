---
name: crap-check
description: Scores every function a branch changed with CRAP (complexity squared times uncovered share cubed, plus complexity), lists those above a threshold with complexity, coverage and the cheapest fix (a test to N% or a split), marks each NEW or pre-existing, and records the count for the head commit. Works for Elixir (Credo complexity, ExCoveralls coverage) and TypeScript or JavaScript (crapper). Use when the user says "crap check this branch", "which functions I changed are too complex and untested", "CRAP score of my diff", "check the tests and code quality of this branch", or before opening a PR.
metadata:
  category: verify
---

# CRAP check on a branch

CRAP = CC^2 x (1 - coverage)^3 + CC. A complex function with thin tests scores high. List the changed functions above `CRAP_THRESHOLD` (default 10) and the cheapest fix for each. Run `dry-check` (duplicates) and `mutation-test` (weak tests) beside it for "check the tests and code quality of this branch".

## 1. Pin the base and the target

Work from the repo root with a clean worktree (`git status --porcelain` prints nothing; never `git stash`, `git checkout .` or `git reset`). The base is the branch the PR targets; fetch it so `origin/<base>` is current. The target is every `.ex` outside `test/` and every `.ts .tsx .js .jsx .mjs .cjs` outside test directories in `git diff --name-only $(git merge-base origin/<base> HEAD)..HEAD`.
Done when the base ref resolves and the target list is known. With no target, the script says so and writes `new=0`.

## 2. Run the script

```sh
scripts/crap-check.sh [--base <branch>] [--no-coverage] [--coverage-json <path>]
```

- Elixir needs a compiled Credo under `_build/test` or `_build/dev`; get a warm build instead of compiling cold. The script runs `mix coveralls.json --max-cases 4` in the foreground on the branch's test files, the test files naming a changed module, and the mirror `test/<x>_test.exs` of each `lib/<x>.ex`. It instruments only the changed modules, so a suite that copies many modules with a mock library can finish. It sets a private test database through `MIX_TEST_PARTITION` unless the caller set one.
- TypeScript uses crapper, cloned once into the cache at a pinned commit (`CRAP_CHECK_CRAPPER` points at an existing clone). It leaves the repo as it found it.
- `--coverage-json` reuses an ExCoveralls file (Elixir) or the LCOV already on disk (TypeScript). `--no-coverage` scores every function at 0% and says so.

Done when stdout ends with `new=<N> pre-existing=<M> threshold=<T> coverage=<source>` and the exit code is 0.

## 3. Handle a failed run

A red test run or a tool crash prints the failure, writes no record and exits non-zero. Report that failure and stop; a score on red tests means nothing. When no test covers a changed module, the script scores it at 0% and prints why.
Done when the report quotes the failure or the "no covering test" line.

## 4. Read NEW and pre-existing

A finding is NEW when the function is absent at the base (matched by file, module and name/arity) or its complexity at HEAD is above its complexity at the base. Any other function above the threshold that overlaps a line the branch added is pre-existing: list it, never block on it. The cheapest fix is "split" when CC exceeds the threshold, because full coverage still leaves CRAP at CC. Otherwise it is "test to N% coverage".
Three cases fall outside this rule; say so when they apply. A renamed file or moved function counts as absent at the base, so its functions show as NEW. A new clause of an existing function is compared with the highest base clause, so a new simple clause stays pre-existing. Coverage is not compared with the base, so a branch that only deletes tests is caught by `mutation-test`, not here.
Done when every row carries a label and a fix.

## 5. Turn each NEW row into a concrete fix

For "test to N%", name the branch of the function the test must reach (the clause or condition no test exercises). For "split", name the two or three helpers the function divides into. Keep the figures from the table.
Done when every NEW row names a test case or a split.

## 6. Report

Open with the verdict: `new=0` means the branch adds no risky function and the PR gate will pass; otherwise N functions need work and the gate blocks until a new commit and run. Give NEW rows first, each with its reason (absent at the base, or CC up from its base value), then pre-existing ones as a count. List only rows the script printed; a function under the threshold never appears. End with the script's last line verbatim, so the base, threshold and coverage source are the script's own; a value missing from the output is written as "not in the output", never guessed. When the run failed or did not happen, say the gate will block. When the request covers tests or code quality, name `dry-check` and `mutation-test` as the checks that cover the rest. The gate record sits at `${CRAP_DRY_STATE:-$HOME/.claude/state/crap-dry}/crap/<repo>-<head sha>`: first line `new=<N>`, then one line per NEW row.
Done when the verdict, the rows and the coverage source are all in the reply.
