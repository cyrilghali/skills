#!/usr/bin/env python3
"""Check one lesson record before it is rendered.

  check-record.py <record.json> --home <store> --repo <owner/name>=<local checkout> [--repo ...]

Fails (exit 1) on: a missing field, a label too long for its figure, a citation whose line does not
exist at the recorded commit or does not hold its `has` text, a figure with no before/after label,
a step an earlier lesson of the area already taught and that is not marked `known`, or an idiom.
On success (exit 0) it prints every cited line: read each one, it must show what its text says.
Exit 2: bad arguments. Standard library and git only.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

LIMITS = {"actor.label": 12, "actor.code": 40, "side.title": 28, "center.title": 30, "step.label": 18, "node.label": 30, "node.sub": 40, "node.code": 36, "headline": 90,
          "top.label": 40, "top.sub": 100, "top.note": 60, "stage.label": 20, "stage.code": 24, "center.code": 30}
WHEN = re.compile(r"^(before|after) the PR\b")
IDIOMS = Path(__file__).resolve().parent / "idioms.txt"

errors, cited = [], []


def err(where, message):
    errors.append(f"{where}: {message}")


def need(obj, key, where, kind=str):
    value = obj.get(key) if isinstance(obj, dict) else None
    if not isinstance(value, kind) or (kind in (str, list) and not value):
        err(where, f"`{key}` is missing or empty")
        return None
    return value


def fits(text, limit_name, where):
    if isinstance(text, str) and len(text) > LIMITS[limit_name]:
        err(where, f"{len(text)} characters, the figure holds {LIMITS[limit_name]}: shorten \"{text}\"")


def line_at(repos, repo, sha, path, line):
    if repo not in repos:
        return None, f"no --repo {repo}=<checkout> was given"
    out = subprocess.run(["git", "-C", repos[repo], "show", f"{sha}:{path}"], capture_output=True, text=True)
    if out.returncode != 0:
        return None, f"{path} does not exist at {sha[:10]} in {repo} (git fetch the commit, or fix the path)"
    lines = out.stdout.split("\n")
    if not 1 <= line <= len(lines):
        return None, f"{path} has {len(lines)} lines at {sha[:10]}, not {line}"
    return lines[line - 1], None


def name_exists(name, shas, repos):
    """True when the whole word `name` occurs in a repo of the record at its base commit."""
    for repo, pair in shas.items():
        if repo in repos and isinstance(pair, dict) and pair.get("base"):
            if subprocess.run(["git", "-C", repos[repo], "grep", "-q", "-w", "-F", name, pair["base"]], capture_output=True).returncode == 0:
                return True
    return False


def check_cite(cite, shas, repos, where):
    if not isinstance(cite, dict):
        return err(where, "`cite` is missing: every step, column, node and claim cites one line")
    for key in ("repo", "path", "line", "has"):
        if key not in cite:
            return err(where, f"cite has no `{key}`")
    at = cite.get("at", "base")
    sha = cite.get("sha") or shas.get(cite["repo"], {}).get(at)
    if not sha:
        return err(where, f"`shas` has no {at} commit for {cite['repo']}")
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        return err(where, f"`{sha}` is not a full commit id: a branch name moves, so a link to it stops showing the cited line")
    text, problem = line_at(repos, cite["repo"], sha, cite["path"], cite["line"])
    if problem:
        return err(where, problem)
    if len(cite["has"]) < 3 or cite["has"] not in text:
        return err(where, f"line {cite['line']} of {cite['path']} at {at} is `{text.strip()[:90]}`, which does not hold `{cite['has']}`")
    cited.append((where, cite, at, text.strip()))
    return text.strip()


def texts(node, path=""):
    if isinstance(node, str):
        yield path, node
    elif isinstance(node, dict):
        for k, v in node.items():
            if k not in ("cite", "shas", "links", "code", "has", "id", "from", "to", "area", "marker", "repo"):
                yield from texts(v, f"{path}.{k}" if path else k)
    elif isinstance(node, list):
        for i, v in enumerate(node):
            yield from texts(v, f"{path}[{i}]")


def check_idioms(doc, label):
    idioms = [l.split("|") for l in IDIOMS.read_text().splitlines() if l.strip() and not l.startswith("#")]
    for where, text in texts(doc):
        low = text.lower()
        for phrase, instead in idioms:
            if phrase in low:
                err(f"{label} {where}", f"idiom \"{phrase}\": say what happens literally ({instead})")


def check_screen(screen, where):
    if not WHEN.match(need(screen, "when", where) or ""):
        err(where, "`when` must start with \"before the PR\" or \"after the PR\"")
    need(screen, "title", where)
    cases = need(screen, "cases", where, list) or []
    if not 1 <= len(cases) <= 2:
        err(where, f"{len(cases)} cases, the figure holds 1 or 2")
    for i, case in enumerate(cases):
        need(case, "label", f"{where}.cases[{i}]")
        for j, line in enumerate(need(case, "lines", f"{where}.cases[{i}]", list) or []):
            need(line, "text", f"{where}.cases[{i}].lines[{j}]")
            if line.get("state", "shown") not in ("shown", "missing", "later", "added"):
                err(f"{where}.cases[{i}].lines[{j}]", "`state` is one of shown, missing, later, added")


def check_area(area, repos):
    m = need(area, "map", "area", dict) or {}
    if len(need(area, "name", "area") or "") > 28:
        err("area.name", f"{len(area['name'])} characters, at most 28: the name is a short label, the title holds the sentence")
    need(area, "title", "area")
    shas = area.get("shas", {})
    ids = set()
    top = m.get("top")
    if top:
        ids.add(top.get("id"))
        fits(need(top, "label", "area.map.top"), "top.label", "area.map.top.label")
        fits(top.get("sub", ""), "top.sub", "area.map.top.sub"), fits(top.get("note", ""), "top.note", "area.map.top.note")
        check_cite(top.get("cite"), shas, repos, "area.map.top")
    for side in ("left", "right"):
        col = need(m, side, "area.map", dict) or {}
        fits(need(col, "title", f"area.map.{side}") or "", "side.title", f"area.map.{side}.title")
        nodes = need(col, "nodes", f"area.map.{side}", list) or []
        if not 1 <= len(nodes) <= 4:
            err(f"area.map.{side}", f"{len(nodes)} nodes, the figure holds 1 to 4")
        for i, node in enumerate(nodes):
            where = f"area.map.{side}.nodes[{i}]"
            ids.add(need(node, "id", where))
            fits(need(node, "label", where), "node.label", where + ".label"), fits(node.get("code", ""), "node.code", where + ".code")
            if len(node.get("sub", [])) > 2:
                err(where, "`sub` holds at most 2 lines")
            for line in node.get("sub", []):
                fits(line, "node.sub", where + ".sub")
            check_cite(node.get("cite"), shas, repos, where)
    center = need(m, "center", "area.map", dict) or {}
    ids.add(center.get("id"))
    fits(need(center, "title", "area.map.center") or "", "center.title", "area.map.center.title"), fits(center.get("code", ""), "center.code", "area.map.center.code")
    check_cite(center.get("cite"), shas, repos, "area.map.center")
    stages = need(center, "stages", "area.map.center", list) or []
    if not 2 <= len(stages) <= 6:
        err("area.map.center", f"{len(stages)} stages, the figure holds 2 to 6")
    for i, stage in enumerate(stages):
        fits(need(stage, "label", f"area.map.center.stages[{i}]"), "stage.label", f"area.map.center.stages[{i}].label")
        fits(stage.get("code", ""), "stage.code", f"area.map.center.stages[{i}].code")
    for i, claim in enumerate(m.get("claims", [])):
        check_cite(claim.get("cite"), shas, repos, f"area.map.claims[{i}]")
    # a number in the caption is a claim: it needs its line
    numbers = set(re.findall(r"\b\d+\b", m.get("caption", "") + " " + (top or {}).get("sub", "")))
    backed = " ".join(c.get("text", "") for c in m.get("claims", [])) + " " + (top or {}).get("cite", {}).get("has", "")
    if numbers and len(m.get("claims", [])) + (1 if top else 0) == 0:
        err("area.map", f"the caption states numbers ({', '.join(sorted(numbers))}) and `claims` cites no line for them")
    check_idioms(m, "area")
    return ids - {None}


def taught_lines(area, repos):
    seen = {}
    for lesson in area.get("lessons", []):
        for step in lesson.get("steps", []):
            c = step["cite"]
            sha = lesson.get("shas", {}).get(c["repo"], {}).get(c.get("at", "base"))
            text, _ = line_at(repos, c["repo"], sha, c["path"], c["line"]) if sha else (None, None)
            if text:
                seen[(c["repo"], c["path"], text.strip())] = lesson["pr"]
    return seen


def map_shas(area):
    """(where, sha) for every part of the area map whose citation pins a commit."""
    m = area.get("map") or {}
    parts = [("top", m.get("top")), ("center", m.get("center"))] + [(f"{side}.nodes[{i}]", n) for side in ("left", "right") for i, n in enumerate((m.get(side) or {}).get("nodes", []))]
    return [(f"area.map.{name}", part["cite"]["sha"]) for name, part in parts if part and isinstance(part.get("cite"), dict) and part["cite"].get("sha")]


def check_record(record, area, repos, marker_ids):
    pr = need(record, "pr", "record", dict) or {}
    for key in ("repo", "title", "author"):
        need(pr, key, "pr")
    need(pr, "number", "pr", int)
    shas = need(record, "shas", "record", dict) or {}
    if not shas.get(pr.get("repo"), {}).get("base") or not shas.get(pr.get("repo"), {}).get("head"):
        err("shas", f"{pr.get('repo')} needs both `base` (the merge-base) and `head`")
    headline = need(record, "headline", "record") or ""
    fits(headline, "headline", "headline")
    if headline.rstrip().endswith("?") or headline.strip().lower() == (pr.get("title") or "").strip().lower():
        err("headline", "`headline` says in plain words what changes for a person; it is not a question and not the pull request's title")
    intro = need(record, "intro", "record") or ""
    if len(intro.split()) > 90:
        err("intro", f"{len(intro.split())} words, at most 90: say what the PR touches and what the lesson covers")
    heads = {pair.get("head") for pair in (record.get("shas") or {}).values() if isinstance(pair, dict)}
    for where, text in ((w, t) for w, t in map_shas(area)):
        if text in heads:
            err(where, "this map part is cited at the pull request's head commit, so it exists only after the change: the map shows the feature before it. Take the part off the map and put the marker on the existing part it will join")
    if record.get("marker") not in marker_ids:
        err("marker", f"`{record.get('marker')}` is no id of the area map; ids: {', '.join(sorted(marker_ids))}")
    if record.get("screen"):
        check_screen(record["screen"], "screen")
    elif len((record.get("no_screen") or "").split()) < 5:
        err("screen", "the record has no `screen`: set `no_screen` to one sentence that says why no person sees this change on a screen")
    fc = record.get("factcheck")
    if fc is not None and not (isinstance(fc, dict) and isinstance(fc.get("sentences"), int) and isinstance(fc.get("corrected"), int) and 0 <= fc["corrected"] <= fc["sentences"] and fc["sentences"] > 0):
        err("factcheck", '`factcheck` is {"sentences": <checked>, "corrected": <rewritten>}, written by the fact-check of FACTCHECK.md')
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", record.get("written") or ""):
        err("written", "`written` is today's date as YYYY-MM-DD")

    path = need(record, "path", "record", dict) or {}
    if not WHEN.match(need(path, "when", "path") or ""):
        err("path", "`when` must start with \"before the PR\" or \"after the PR\"")
    need(path, "title", "path")
    actors = need(path, "actors", "path", list) or []
    if not 2 <= len(actors) <= 6:
        err("path.actors", f"{len(actors)} actors, the figure holds 2 to 6")
    actor_ids = set()
    for i, actor in enumerate(actors):
        actor_ids.add(need(actor, "id", f"path.actors[{i}]"))
        fits(need(actor, "label", f"path.actors[{i}]"), "actor.label", f"path.actors[{i}].label")
        fits(actor.get("code", ""), "actor.code", f"path.actors[{i}].code")
        code = actor.get("code", "")
        if re.fullmatch(r"[A-Z][A-Za-z0-9_.]*", code) and not name_exists(code, record.get("shas") or {}, repos):
            err(f"path.actors[{i}].code", f"`{code}` is no name in the code at the base commit: write a real module or table name in full, never a cut one (the figure shortens it)")
        if actor.get("node") and [x.get("node") for x in actors].count(actor["node"]) > 1:
            err(f"path.actors[{i}].node", f"two actors name the map part `{actor['node']}`; give `node` to one of them")
        if actor.get("node") and actor["node"] not in marker_ids:
            err(f"path.actors[{i}].node", f"`{actor['node']}` is no id of the area map; ids: {', '.join(sorted(marker_ids))}")
    steps = need(path, "steps", "path", list) or []
    if not 3 <= len(steps) <= 12:
        err("path.steps", f"{len(steps)} steps, the figure holds 3 to 12: one step per place where control or data changes hands")
    taught = taught_lines(area, repos)
    lesson_prs = {l["pr"] for l in area.get("lessons", []) if l["pr"] != pr.get("number")}
    for i, step in enumerate(steps, 1):
        where = f"path.steps[{i}]"
        for end in ("from", "to"):
            if step.get(end) not in actor_ids:
                err(where, f"`{end}` is `{step.get(end)}`, which is no actor id")
        fits(need(step, "label", where), "step.label", where + ".label")
        text = need(step, "text", where) or ""
        if len(text.split()) > 45 or not text.rstrip().endswith((".", ".\"")):
            err(where, "`text` is one sentence of at most 45 words that ends with a period")
        line = check_cite(step.get("cite"), shas, repos, where)
        if line is not None:
            earlier = taught.get((step["cite"]["repo"], step["cite"]["path"], line))
            if earlier and earlier != pr.get("number") and step.get("known") != earlier:
                err(where, f"the lesson on #{earlier} already taught this line: set `known` to {earlier} and keep the text short")
        if step.get("known") and step["known"] not in lesson_prs:
            err(where, f"`known` is {step['known']}, and the area holds no lesson on that PR")
    if sum(1 for s in steps if s.get("lost")) > 1:
        err("path.steps", "more than one step is marked `lost`: mark the first step where the outcome differs from what the person expects")
    if steps and all(s.get("known") for s in steps):
        err("path.steps", "every step is `known`: follow the action through the code this PR changes")

    state = record.get("state")
    if state:
        if not WHEN.match(need(state, "when", "state") or ""):
            err("state", "`when` must start with \"before the PR\" or \"after the PR\"")
        need(state, "title", "state"), need(state, "header", "state")
        columns = need(state, "columns", "state", list) or []
        if not 2 <= len(columns) <= 4:
            err("state.columns", f"{len(columns)} columns, the figure holds 2 to 4")
        for i, column in enumerate(columns):
            need(column, "label", f"state.columns[{i}]")
            check_cite(column.get("cite"), shas, repos, f"state.columns[{i}]")
        for i, row in enumerate(need(state, "rows", "state", list) or []):
            need(row, "name", f"state.rows[{i}]")
            if len(row.get("cells", [])) != len(columns):
                err(f"state.rows[{i}]", f"{len(row.get('cells', []))} cells for {len(columns)} columns")

    guess = need(record, "guess", "record", dict) or {}
    questions = need(guess, "questions", "guess", list) or []
    if not 1 <= len(questions) <= 2:
        err("guess.questions", f"{len(questions)} questions, ask 1 or 2")
    answer = need(guess, "answer", "guess", dict) or {}
    need(answer, "text", "guess.answer", list)
    changes = need(answer, "changes", "guess.answer", list) or []
    for i, change in enumerate(changes):
        where = f"guess.answer.changes[{i}]"
        if not isinstance(change.get("step"), int) or not 1 <= change["step"] <= len(steps):
            err(where, f"`step` must be a step number from 1 to {len(steps)}")
        need(change, "text", where)
        cite = change.get("cite") or {}
        if cite.get("at") != "head":
            err(where, "the cite of a change points at the PR's code: set `at` to \"head\"")
        check_cite(change.get("cite"), shas, repos, where)
    if answer.get("screen"):
        check_screen(answer["screen"], "guess.answer.screen")
        if not answer["screen"].get("when", "").startswith("after"):
            err("guess.answer.screen", "the answer shows what the person sees after the PR")
    need(answer, "check", "guess.answer", list)
    prose = {k: v for k, v in record.items() if k not in ("pr", "shas")}
    check_idioms(prose, "record")
    for where, text in texts(prose):
        for sentence in re.split(r"(?<=[.!?])\s+", text):
            if len(sentence.split()) > 30:
                err(where, f"a sentence of {len(sentence.split())} words, at most 30: cut it in two (\"{sentence[:60]}…\")")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("record")
    ap.add_argument("--home", required=True)
    ap.add_argument("--repo", action="append", default=[], metavar="OWNER/NAME=DIR")
    args = ap.parse_args()
    repos = dict(r.split("=", 1) for r in args.repo if "=" in r)
    try:
        record = json.loads(Path(args.record).read_text())
    except (OSError, json.JSONDecodeError) as e:
        print(f"error: cannot read the record: {e}", file=sys.stderr)
        sys.exit(2)
    area_file = Path(args.home) / "areas" / f"{record.get('area')}.json"
    if not area_file.exists():
        print(f"error: {area_file} does not exist\n  next: write the area map there first (RECORD.md, \"The area file\")", file=sys.stderr)
        sys.exit(1)
    area = json.loads(area_file.read_text())
    ids = check_area(area, repos)
    check_record(record, area, repos, ids)
    if errors:
        print(f"{len(errors)} problem(s):", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        sys.exit(1)
    for where, cite, at, text in cited:
        print(f"OK  {where}  {cite['path']}:{cite['line']} ({at})  {text[:110]}")
    print("All checks pass. Read each OK line: it must show what its text says.")


if __name__ == "__main__":
    main()
