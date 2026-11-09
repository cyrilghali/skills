---
name: skill-telemetry
disable-model-invocation: true
description: Records one JSON line per skill run (counts such as mutants killed, findings, bugs found) and reads them back per skill as medians, trends and a compliance line, so the owner learns whether a skill works and not only whether it ran. Use when asked for "skill telemetry", "how effective is a skill", "which skills work", "skill report", "is this skill worth keeping", or to add a record step to a skill's last step.
metadata:
  category: agent
---

# Skill telemetry

A skill runs and leaves a report in the session. Nothing says, a month later, whether its runs found anything. This skill gives every skill with a countable outcome one sentence that records the run, and gives the owner one command that reads the runs back per skill.

Two scripts live in `scripts/`. `record.sh` appends one JSON line to `runs.jsonl`. `report.sh` prints one block per skill. Both read `SKILL_TELEMETRY_DIR` and fall back to `$HOME/.local/share/skill-telemetry`, created on first use. Never ask where the folder is: when the variable is unset, the default applies.

## Add telemetry to a skill

1. **Look the skill up in `METRICS.md`, then in `private/METRICS.md` when it exists.** Use its row's metric names as they are, so reports over months compare like with like. Done when every metric you will record is in the row, or you added it to the row first with its unit and direction.
2. **Make the record the skill's last step.** Append one sentence to the step that hands the result to the user: "Record the run: `skill-record <skill> k=v ...`", with the registry's sentence as the template. `skill-record` is `scripts/record.sh` linked onto PATH (see INSTALL.md), so the sentence resolves from any working directory. Done when the sentence sits after the result is delivered and nowhere else, because a run that stops early must leave no line.
3. **Record once per finished run, and never on a dry run.** A retry of the same run records nothing new. A rehearsal, an eval or a demo of the skill records nothing. Done when the sentence names these two exclusions in the skill's own words or the step above it already makes them impossible.
4. **Write a ratio as `k/n`**, such as `killed=10/12`. The recorder stores `killed` and `killed_of` as two numbers. A plain number is stored as a number; any other text is kept as a string, quotes and spaces included. Done when every value is a count the run itself produced; leave a metric out rather than derive or guess it.

The recorder never fails the caller: on any error it prints one line to stderr and exits 0, so a skill's last step cannot break on telemetry.

## Read the report

Run `scripts/report.sh [skill] [--since 30d|90d|all]`. The default window is 30 days. Each block holds the number of runs and the last run date, then one row per numeric metric with its median, its last value and its change. The change is the median of the newer half of the runs minus the median of the older half, `n/a` under two runs. A text metric such as `verdict` prints its last value.

Read a move with the metric's direction from `METRICS.md`. For mutation-test, `real_survivors` rising means the skill finds more real gaps per run, which is the skill earning its keep; `killed` rising means the branches' tests arrive stronger. A change smaller than the metric's spread across runs is noise, so compare the change with the medians before calling a trend.

The block ends with a compliance line: `N sessions invoked it, M recorded`. `N` counts transcripts in the window where the skill was invoked (a Skill tool call or a typed slash command). A gap between `N` and `M` names a skill that runs but never records, so its record step is missing or sits too early. The transcript scan is cached in `sessions.tsv` next to the log; the first run reads every transcript once and says so on stderr.

Answer "is this skill worth keeping" from the block. A skill whose up-metrics stay at zero over a window of many runs finds nothing. A skill with zero runs recorded and many sessions invoked needs its record step before any judgment.

## Keep the data clean

- Point `SKILL_TELEMETRY_DIR` at a scratch folder for every test, smoke run and eval, so no fake row lands in the owner's log.
- Treat `runs.jsonl` as append-only. To correct a row, append a new run; to drop a skill's rows, filter the file by hand and say so.
- `INSTALL.md` holds the optional variable and the one-line smoke test.
