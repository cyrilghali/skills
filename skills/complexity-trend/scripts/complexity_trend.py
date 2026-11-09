#!/usr/bin/env python3
"""Measure an Elixir repo's complexity on its default branch and report the trend.

  complexity_trend.py            measure, write today's row to the history, print the trend
  complexity_trend.py --report   print the trend from the history alone
  complexity_trend.py --self-test

Environment:
  COMPLEXITY_REPO      local clone of the repo to measure (required to measure)
  COMPLEXITY_CHECKOUT  worktree this script owns and moves (default: $HOME/.local/share/complexity-trend/checkout)
  COMPLEXITY_HISTORY   history file (default: $HOME/.local/share/complexity-trend/history.tsv)
"""
import datetime as dt
import json
import os
import re
import subprocess
import sys
from pathlib import Path

DATA = Path.home() / ".local/share/complexity-trend"
HISTORY = Path(os.environ.get("COMPLEXITY_HISTORY", DATA / "history.tsv"))
CHECKOUT = Path(os.environ.get("COMPLEXITY_CHECKOUT", DATA / "checkout"))

COLUMNS = ["date", "commit", "credo_total", "complexity", "complexity_all", "duplicated", "loc", "modules"]
COMPLEXITY_CHECKS = {
    "Credo.Check.Refactor.CyclomaticComplexity",
    "Credo.Check.Refactor.ABCSize",
    "Credo.Check.Refactor.Nesting",
    "Credo.Check.Refactor.FunctionArity",
}
DUPLICATION_CHECK = "Credo.Check.Design.DuplicatedCode"
FORCED = sorted(COMPLEXITY_CHECKS | {DUPLICATION_CHECK})


def run(cmd, cwd, stdout=subprocess.PIPE):
    # Build noise goes to stderr so stdout stays parseable.
    return subprocess.run(cmd, cwd=cwd, stdout=stdout, stderr=sys.stderr, text=True, check=True).stdout


def git(*args, cwd):
    return run(["git", *args], cwd).strip()


def json_from(output):
    # Credo can print compile lines before the JSON document.
    return json.loads(output[output.index("{"):])


def prepare_checkout(repo):
    head = git("symbolic-ref", "--short", "refs/remotes/origin/HEAD", cwd=repo)
    branch = head.removeprefix("origin/")
    git("fetch", "-q", "origin", branch, cwd=repo)
    if (CHECKOUT / ".git").is_dir():
        sys.exit(f"{CHECKOUT} is a main clone, not a worktree; point COMPLEXITY_CHECKOUT elsewhere")
    if not (CHECKOUT / ".git").exists():
        CHECKOUT.parent.mkdir(parents=True, exist_ok=True)
        git("worktree", "add", "--detach", str(CHECKOUT), head, cwd=repo)
        seed_build(repo)
    git("checkout", "-q", "--detach", head, cwd=CHECKOUT)
    if git("status", "--porcelain", cwd=CHECKOUT):
        sys.exit(f"{CHECKOUT} has local changes; it must stay a clean copy of {head}")
    return git("rev-parse", "--short", "HEAD", cwd=CHECKOUT)


def seed_build(repo):
    # A fresh worktree would recompile every dependency (tens of minutes on a large app);
    # the clone's own deps and _build are a warm start. `cp -c` clones copy-on-write on APFS.
    for name in ("deps", "_build"):
        src = repo / name
        if src.is_dir() and not (CHECKOUT / name).exists():
            # cp exits non-zero on sockets it skips, so success is judged by the copy existing.
            for cp in (["cp", "-cR"], ["cp", "-R"]):
                if not (CHECKOUT / name).exists():
                    subprocess.run([*cp, str(src), str(CHECKOUT / name)], stderr=subprocess.DEVNULL)


def credo_counts(issues, project_enabled):
    checks = [i["check"] for i in issues]
    return {
        "credo_total": sum(c in project_enabled for c in checks),
        "complexity": sum(c in COMPLEXITY_CHECKS and c in project_enabled for c in checks),
        "complexity_all": sum(c in COMPLEXITY_CHECKS for c in checks),
        "duplicated": sum(c == DUPLICATION_CHECK for c in checks),
    }


def measure(repo):
    commit = prepare_checkout(repo)
    run(["mix", "deps.get"], CHECKOUT, stdout=sys.stderr)
    run(["mix", "deps.loadpaths"], CHECKOUT, stdout=sys.stderr)  # compiles only stale deps; deps.compile rebuilds all
    info = json_from(run(["mix", "credo", "info", "--strict", "--verbose", "--format", "json"], CHECKOUT))
    project_enabled = {c["name"].removeprefix("Elixir.") for c in info["config"]["checks"]}
    # Credo exits non-zero whenever it finds issues, so the exit code is ignored.
    credo = subprocess.run(
        ["mix", "credo", "--strict", "--format", "json", "--enable-disabled-checks", ",".join(FORCED)],
        cwd=CHECKOUT, stdout=subprocess.PIPE, stderr=sys.stderr, text=True,
    )
    counts = credo_counts(json_from(credo.stdout)["issues"], project_enabled)
    files = [f for f in git("ls-files", "--", "lib/*.ex", cwd=CHECKOUT).splitlines() if f]
    loc = modules = 0
    for f in files:
        text = (CHECKOUT / f).read_text(errors="replace")
        loc += text.count("\n")
        modules += len(re.findall(r"^\s*defmodule\s", text, re.M))
    return {"date": dt.date.today().isoformat(), "commit": commit, **counts, "loc": loc, "modules": modules}


def read_history(path):
    if not path.exists():
        return []
    lines = path.read_text().splitlines()
    return [dict(zip(COLUMNS, line.split("\t"))) for line in lines[1:] if line.strip()]


def write_row(path, row):
    rows = [r for r in read_history(path) if r["date"] != row["date"]] + [row]
    rows.sort(key=lambda r: r["date"])
    path.parent.mkdir(parents=True, exist_ok=True)
    body = ["\t".join(COLUMNS)] + ["\t".join(str(r[c]) for c in COLUMNS) for r in rows]
    tmp = path.with_suffix(".tmp")
    tmp.write_text("\n".join(body) + "\n")
    tmp.replace(path)
    return rows


def baseline(rows, days):
    """Latest row at least `days` before the newest one, else the oldest earlier row."""
    newest = dt.date.fromisoformat(rows[-1]["date"])
    earlier = rows[:-1]
    cutoff = (newest - dt.timedelta(days=days)).isoformat()
    due = [r for r in earlier if r["date"] <= cutoff]
    return due[-1] if due else (earlier[0] if earlier else None)


def merged_prs(repo, since, until):
    if not repo:
        return None
    try:
        slug = run(["gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"], repo).strip()
        branch = git("symbolic-ref", "--short", "refs/remotes/origin/HEAD", cwd=repo).removeprefix("origin/")
        q = f"repo:{slug} is:pr is:merged base:{branch} merged:{since}..{until}"
        return int(run(["gh", "api", "-X", "GET", "search/issues", "-f", f"q={q}", "--jq", ".total_count"], repo))
    except (subprocess.CalledProcessError, ValueError, FileNotFoundError):
        return None


def delta(new, old, key):
    a, b = int(new[key]), int(old[key])
    pct = f" ({(a - b) / b:+.1%})" if b else ""
    return f"{a - b:+d}{pct}"


def density(row):
    return 1000 * int(row["complexity_all"]) / max(int(row["loc"]), 1)


def report(rows, prs=lambda since, until: None):
    if not rows:
        return "No measurement yet: the history is empty."
    new = rows[-1]
    out = [
        f"{new['date']} @ {new['commit']}: {new['complexity_all']} complexity findings "
        f"({new['complexity']} under the project's own Credo config), {new['credo_total']} Credo findings, "
        f"{new['duplicated']} duplicated-code findings, {new['loc']} lines in {new['modules']} modules, "
        f"{density(new):.2f} complexity findings per 1,000 lines."
    ]
    for label, days in (("Week on week", 7), ("30-day", 30)):
        old = baseline(rows, days)
        if old is None:
            out.append(f"{label}: no earlier row yet.")
            continue
        merged = prs(old["date"], new["date"])
        merged_text = f"{merged} PRs merged" if merged is not None else "merged PR count unavailable"
        span = (dt.date.fromisoformat(new["date"]) - dt.date.fromisoformat(old["date"])).days
        if span < days:
            label = f"{span}-day ({days}-day baseline not reached yet)"
        out.append(
            f"{label} (since {old['date']}, {merged_text}): complexity {delta(new, old, 'complexity_all')} "
            f"(own config {delta(new, old, 'complexity')}), per 1,000 lines {density(new) - density(old):+.2f}, Credo {delta(new, old, 'credo_total')}, "
            f"duplicated {delta(new, old, 'duplicated')}, lines {delta(new, old, 'loc')}, "
            f"modules {delta(new, old, 'modules')}."
        )
    if new["complexity"] == "0" and new["complexity_all"] != "0":
        out.append("The project's own Credo config reports zero complexity findings; only the force-enabled checks see any.")
    return "\n".join(out)


def self_test():
    import tempfile

    def row(date, cx, loc):
        return {"date": date, "commit": "abc", "credo_total": "10", "complexity": "0",
                "complexity_all": str(cx), "duplicated": "1", "loc": str(loc), "modules": "5"}

    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "h.tsv"
        for r in (row("2026-01-01", 100, 10000), row("2026-01-25", 110, 10000), row("2026-02-01", 121, 11000)):
            write_row(path, r)
        rows = write_row(path, row("2026-02-01", 120, 11000))
        assert [r["date"] for r in rows] == ["2026-01-01", "2026-01-25", "2026-02-01"], rows
        assert rows[-1]["complexity_all"] == "120", "same-day rerun replaces the row"
        assert baseline(rows, 7)["date"] == "2026-01-25"
        assert baseline(rows, 30)["date"] == "2026-01-01"
        assert baseline(rows[:2], 30)["date"] == "2026-01-01", "falls back to the oldest row"
        assert baseline(rows[:1], 7) is None
        text = report(rows, prs=lambda since, until: 42)
        assert "Week on week (since 2026-01-25, 42 PRs merged): complexity +10 (+9.1%) (own config +0)" in text, text
        assert "30-day (since 2026-01-01, 42 PRs merged): complexity +20 (+20.0%) (own config +0)" in text, text
        assert "24-day (30-day baseline not reached yet) (since 2026-01-01" in report(rows[:2]), report(rows[:2])
        assert "only the force-enabled checks" in text
        issues = [{"check": c} for c in ("Credo.Check.Refactor.Nesting", "Credo.Check.Refactor.ABCSize",
                                         DUPLICATION_CHECK, "Credo.Check.Readability.Foo")]
        enabled = {"Credo.Check.Refactor.Nesting", "Credo.Check.Readability.Foo"}
        assert credo_counts(issues, enabled) == {"credo_total": 2, "complexity": 1, "complexity_all": 2, "duplicated": 1}
        assert json_from('==> compiling\n{"issues": []}') == {"issues": []}
        assert report([]) == "No measurement yet: the history is empty."
    print("self-test passed")


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    if arg == "--self-test":
        return self_test()
    repo = os.environ.get("COMPLEXITY_REPO")
    if arg != "--report":
        if not repo:
            sys.exit("set COMPLEXITY_REPO to a local clone of the repo to measure")
        write_row(HISTORY, measure(Path(repo).expanduser()))
    print(report(read_history(HISTORY), prs=lambda since, until: merged_prs(repo, since, until)))
    print(f"History: {HISTORY}")


if __name__ == "__main__":
    main()
