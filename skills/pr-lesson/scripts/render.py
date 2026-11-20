#!/usr/bin/env python3
"""Render one lesson record into an HTML fragment, and keep the lesson site in step.

  render.py <record.json> --home <store>                        write rows/<repo>-<n>.json, the row the lessons page shows
  render.py <record.json> --home <store> --preview <out.html>   also write one standalone page for a local look
  render.py <prepare.json> --home <store> --skip "<reason>"     write a row that says the pull request gets no lesson

The store holds areas/<area>.json (the map of each area), records/<repo>-<n>.json and rows/<repo>-<n>.json.
It also adds the lesson's new steps to the area file, so the next lesson of the area can point back at them.
Run check-record.py first: this script trusts the record's shape. Standard library only.
"""
import argparse
from datetime import datetime, timezone
import html
import json
import shutil
import sys
from pathlib import Path

SKILL = Path(__file__).resolve().parent.parent
E = html.escape


def fail(message, next_step):
    print(f"error: {message}\n  next: {next_step}", file=sys.stderr)
    sys.exit(1)


def cite_url(cite, shas):
    sha = cite.get("sha") or shas[cite["repo"]][cite.get("at", "base")]
    return f"https://github.com/{cite['repo']}/blob/{sha}/{cite['path']}#L{cite['line']}"


def cite_link(cite, shas, narrow=False):
    name = E(f"{cite['path'].rsplit('/', 1)[-1]}:{cite['line']}")
    if narrow:  # in a table cell the name may break before the line number
        name = name.replace(":", "<wbr>:")
    return f'<a class="cite" href="{E(cite_url(cite, shas))}" title="{E(cite["path"])}">{name}</a>'


def tag(text):
    return f'<span class="tag">{E(text)}</span>'


# ---- Figure: map of the whole area ---------------------------------------------------------
# Figures are drawn 880 units wide and shown at that width, so no label is smaller than 12px.

def mono(text, x, y, room, anchor="start"):
    """A code name; squeezed a little when it is wider than the room it has."""
    squeeze = f' textLength="{room}" lengthAdjust="spacingAndGlyphs"' if len(text) * 7.3 > room else ""
    return f'<text class="code" x="{x}" y="{y}" text-anchor="{anchor}"{squeeze}>{E(text)}</text>'


def flags(x_right, y, here, actor):
    """Tags on a box's top edge: this lesson's marker, and the name the path figure gives this part."""
    out = []
    if here:
        out.append(f'<rect class="flag" x="{x_right - 112}" y="{y - 11}" width="104" height="22" rx="11"/>'
                   f'<text class="flag-t" x="{x_right - 60}" y="{y + 4.5}" text-anchor="middle">THIS LESSON</text>')
        x_right -= 112
    if actor:
        w = int(len(actor) * 7.6) + 22
        out.append(f'<rect class="tagbox" x="{x_right - w - 8}" y="{y - 11}" width="{w}" height="22" rx="11"/>'
                   f'<text class="tag-t" x="{x_right - 8 - w / 2}" y="{y + 4.5}" text-anchor="middle">{E(actor)}</text>')
    return "".join(out)


def node_svg(node, x, y, w, h, here, actor):
    out = [f'<rect class="box{" here" if here else ""}" x="{x}" y="{y}" width="{w}" height="{h}" rx="6"/>',
           f'<text x="{x + 12}" y="{y + 24}" class="b">{E(node["label"])}</text>']
    for i, line in enumerate(node.get("sub", [])[:2]):
        out.append(f'<text class="sub" x="{x + 12}" y="{y + 42 + i * 16}">{E(line)}</text>')
    if node.get("code"):
        out.append(mono(node["code"], x + 12, y + h - 11, w - 24))
    out.append(flags(x + w, y, here, actor))
    return "".join(out)


def map_svg(area, marker, actors=None):
    """`actors` maps a node id to the label the path figure uses for that part."""
    m, actors = area["map"], actors or {}
    left, right, stages = m["left"]["nodes"], m["right"]["nodes"], m["center"]["stages"]
    top = m.get("top")
    y0 = 118 if top else 34
    rows = max(len(left), len(right))
    box_h, gap = 96, 16
    side_h = rows * box_h + (rows - 1) * gap
    stage_h, stage_gap = 42, 14
    center_h = max(side_h + 40, 34 + len(stages) * stage_h + (len(stages) - 1) * stage_gap + 16)
    height = y0 + center_h + 12
    out = [f'<svg class="fig map" viewBox="0 0 880 {height}" role="img" aria-label="{E(area["title"])}">',
           '<defs><marker id="am" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" '
           'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="context-stroke"/></marker></defs>']
    if top:
        here = marker == top.get("id")
        out.append(f'<rect class="box{" here" if here else ""}" x="6" y="12" width="868" height="54" rx="6"/>'
                   f'<text x="20" y="35" class="b">{E(top["label"])}</text>'
                   f'<text class="sub" x="20" y="53">{E(top.get("sub", ""))}</text>'
                   + mono(top.get("code", ""), 860, 35, 200, "end") + flags(874, 12, here, actors.get(top.get("id"))))
        if top.get("note"):
            out.append('<line class="arrow" x1="138" y1="66" x2="138" y2="92" marker-end="url(#am)"/>'
                       f'<text class="sub" x="148" y="84">{E(top["note"])}</text>')
    out.append(f'<text class="band" x="6" y="{y0 - 14}">{E(m["left"]["title"].upper())}</text>'
               f'<text class="band" x="440" y="{y0 - 14}" text-anchor="middle">{E(m["center"]["title"].upper())}</text>'
               f'<text class="band" x="610" y="{y0 - 14}">{E(m["right"]["title"].upper())}</text>')
    side_y = y0 + (center_h - side_h) // 2
    for nodes, x, arrow in ((left, 6, (272, 304)), (right, 610, (576, 608))):
        for i, node in enumerate(nodes):
            y = side_y + i * (box_h + gap)
            out.append(node_svg(node, x, y, 264, box_h, marker == node["id"], actors.get(node["id"])))
            out.append(f'<line class="arrow" x1="{arrow[0]}" y1="{y + 48}" x2="{arrow[1]}" y2="{y + 48}" marker-end="url(#am)"/>')
    here = marker == m["center"].get("id")
    out.append(f'<rect class="box row{" here" if here else ""}" x="306" y="{y0}" width="268" height="{center_h}" rx="8"/>'
               + mono(m["center"].get("code", ""), 440, y0 + 22, 244, "middle") + flags(574, y0, here, actors.get(m["center"].get("id"))))
    y = y0 + 34
    for i, stage in enumerate(stages):
        last = i == len(stages) - 1
        bold = ' class="b"' if last else ""
        out.append(f'<rect class="pill{" done" if last else ""}" x="330" y="{y}" width="220" height="{stage_h}" rx="21"/>'
                   f'<text x="440" y="{y + 18}" text-anchor="middle"{bold}>{E(stage["label"])}</text>'
                   + mono(stage.get("code", ""), 440, y + 34, 196, "middle"))
        if not last:
            out.append(f'<line class="arrow" x1="440" y1="{y + stage_h}" x2="440" y2="{y + stage_h + stage_gap - 2}" marker-end="url(#am)"/>')
        y += stage_h + stage_gap
    out.append("</svg>")
    return "".join(out)


# ---- Figure: what the person sees ----------------------------------------------------------

def screen_html(screen):
    cards = []
    for case in screen["cases"]:
        lines = []
        for line in case["lines"]:
            note = f'<small>{E(line["note"])}</small>' if line.get("note") else ""
            state = line.get("state", "shown")
            if state == "missing":
                lines.append(f'<li class="missing"><span class="hole">{E(line["text"])}{note}</span></li>')
            else:
                lines.append(f'<li class="{state}">{E(line["text"])}{note}</li>')
        cards.append(f'<div class="card"><div class="who">{E(case["label"])}</div><ul class="tl">{"".join(lines)}</ul></div>')
    return f'<div class="cards n{len(cards)}">{"".join(cards)}</div>'


# ---- Figure: the numbered path -------------------------------------------------------------

def actor_code(code, x, room):
    """A name too long for the actor's box is cut with "…", and keeps its full text for a pointer and a screen reader."""
    fits = int(room / 7.3)
    if len(code) <= fits:
        return mono(code, x, 49, room, "middle")
    return f'<g><title>{E(code)}</title>{mono(code[:fits - 1] + "…", x, 49, room, "middle")}</g>'


def path_svg(path):
    actors, steps = path["actors"], path["steps"]
    n = len(actors)
    span = 740 / (n - 1) if n > 1 else 0
    xs = {a["id"]: (70 + i * span if n > 1 else 440) for i, a in enumerate(actors)}
    order = {a["id"]: i for i, a in enumerate(actors)}
    head_w = min(138, int(span) - 10) if n > 1 else 138
    body, y, phase = [], 78, None
    for i, step in enumerate(steps, 1):
        if step.get("phase") and step["phase"] != phase:
            phase = step["phase"]
            y += 24
            body.append(f'<line class="rule" x1="6" y1="{y}" x2="874" y2="{y}"/>'
                        f'<rect class="bandbg" x="0" y="{y + 5}" width="{len(phase) * 9 + 14}" height="18"/>'
                        f'<text class="band" x="6" y="{y + 18}">{E(phase.upper())}</text>')
            y += 32
        y += 42
        a, b = xs[step["from"]], xs[step["to"]]
        cls = "lost" if step.get("lost") else ("known" if step.get("known") else "")
        g = [f'<g class="{cls}">']
        if step["from"] == step["to"]:
            left_side = order[step["from"]] == n - 1 and n > 1
            d = -1 if left_side else 1
            g.append(f'<path class="arrow" d="M{a},{y - 8} h{26 * d} v22 h{-24 * d}" marker-end="url(#ah)"/>'
                     f'<text x="{a + 34 * d}" y="{y + 8}" text-anchor="{"end" if left_side else "start"}">{E(step["label"])}</text>')
            cy = y - 8
            y += 12
        else:
            end = b - 2 if b > a else b + 2
            g.append(f'<line class="arrow" x1="{a}" y1="{y}" x2="{end}" y2="{y}" marker-end="url(#ah)"/>'
                     f'<text x="{(a + b) / 2}" y="{y - 8}" text-anchor="middle">{E(step["label"])}</text>')
            cy = y
        g.append(f'<circle class="badge" cx="{a}" cy="{cy}" r="11"/>'
                 f'<text class="badge-t" x="{a}" y="{cy + 4}" text-anchor="middle">{i}</text></g>')
        body.append("".join(g))
    height = y + 30
    out = [f'<svg class="fig seq" viewBox="0 0 880 {height}" role="img" aria-label="{E(path["title"])}">',
           '<defs><marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" '
           'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="context-stroke"/></marker></defs>']
    for a in actors:
        x = xs[a["id"]]
        out.append(f'<line class="life" x1="{x}" y1="62" x2="{x}" y2="{height - 12}"/>'
                   f'<rect class="box" x="{x - head_w / 2}" y="10" width="{head_w}" height="50" rx="6"/>'
                   f'<text x="{x}" y="31" text-anchor="middle" class="b">{E(a["label"])}</text>'
                   + actor_code(a.get("code", ""), x, head_w - 10))
    out.append("".join(body))
    out.append("</svg>")
    return "".join(out)


def steps_html(path, shas):
    items = []
    for step in path["steps"]:
        cls = "lost" if step.get("lost") else ("known" if step.get("known") else "")
        lead = "<b>Where it goes wrong:</b> " if step.get("lost") else ""
        seen = f' <span class="seen">seen in the lesson on #{step["known"]}</span>' if step.get("known") else ""
        items.append(f'<li class="{cls}">{lead}{E(step["text"])} {cite_link(step["cite"], shas)}{seen}</li>')
    return f'<ol class="steps">{"".join(items)}</ol>'


# ---- Figure: what each action writes -------------------------------------------------------

def state_html(state, shas):
    head = "".join(f"<th>{E(c['label'])}</th>" for c in state["columns"])
    rows = []
    for row in state["rows"]:
        cells = []
        for cell in row["cells"]:
            mark = cell.get("mark", "text")
            note = f'<small>{E(cell["note"])}</small>' if cell.get("note") else ""
            if mark == "dot":
                cells.append(f'<td><span class="dot"></span>{note}</td>')
            elif mark == "none":
                cells.append(f'<td class="none">{E(cell.get("text", "–"))}</td>')
            else:
                cells.append(f'<td>{E(cell.get("text", ""))}{note}</td>')
        rows.append(f'<tr class="{"hl" if row.get("highlight") else ""}"><th><code>{E(row["name"]).replace("_", "_<wbr>")}</code></th>{"".join(cells)}</tr>')
    foot = "".join(f"<td>{cite_link(c['cite'], shas, narrow=True) if c.get('cite') else ''}</td>" for c in state["columns"])
    return (f'<p class="hint t">Scroll the table sideways to see every column.</p><div class="scroll" role="group" aria-label="{E(state["title"])}"><table class="grid"><thead><tr><th>{E(state["header"])}</th>{head}</tr></thead>'
            f'<tbody>{"".join(rows)}</tbody><tfoot><tr><td>Where it is written</td>{foot}</tr></tfoot></table></div>')


# ---- The lesson ----------------------------------------------------------------------------

def wide(svg, title):
    return f'<p class="hint">Scroll the figure sideways to see all of it.</p><div class="wide" role="group" aria-label="{E(title)}">{svg}</div>'


def figure(number, when, title, body, caption):
    cap = f"<figcaption>{E(caption)}</figcaption>" if caption else ""
    return f'<figure>{tag(f"Figure {number} · {when}")}<h3>{E(title)}</h3>{body}{cap}</figure>'


def made(record):
    repo = record["pr"]["repo"]
    sha = record["shas"][repo]["base"]
    day = datetime.strptime(record["written"], "%Y-%m-%d").strftime("%-d %B %Y") if record.get("written") else "an unknown day"
    fc = record.get("factcheck")
    checked = (f"A second program then compared each of its {fc['sentences']} sentences with the code and corrected {fc['corrected'] or 'none'} of them."
               if fc else "No second program has compared its sentences with the code yet.")
    return (f'<p class="made">A program wrote this lesson on {E(day)} from the code at commit '
            f'<a class="cite" href="https://github.com/{E(repo)}/tree/{E(sha)}">{E(sha[:9])}</a>, the commit this pull request started from. '
            "It checked that every cited line exists at that commit. " + checked + " No person reviewed the explanation. "
            f'To correct it, say to Claude: “redo the lesson of pull request {record["pr"]["number"]}”, and say what is wrong.</p>')


def lesson_html(record, area):
    pr, shas = record["pr"], record["shas"]
    parts = [f'<article class="lesson" data-pr="{pr["number"]}">',
             f'<header><p class="eyebrow">{E(area["name"])} · {E(pr["repo"])} #{pr["number"]} · {E(pr["author"])}</p>'
             f'<h2>{E(record["headline"])}</h2><p class="prtitle">Title of the pull request: {E(pr["title"])}</p>'
             f'<p class="intro">{E(record["intro"])}</p>{made(record)}</header>']
    on_map = {a["node"]: a["label"] for a in record["path"]["actors"] if a.get("node")}
    number = 1
    parts.append(figure(number, "the whole feature, before the PR", area["title"], wide(map_svg(area, record.get("marker"), on_map), area["title"]),
                        (area["map"].get("caption") or "") + (" A grey tag on a box is the name Figure " + ("3" if record.get("screen") else "2") + " gives that part." if on_map else "")))
    taught = area.get("lessons", [])
    position = next((i for i, l in enumerate(taught) if l["pr"] == pr["number"] and l.get("repo") == pr["repo"]), len(taught))
    earlier = taught[:position]
    if earlier:
        links = ", ".join(f'<a href="#pr-{E(slug({"repo": l["repo"], "number": l["pr"]}))}">#{l["pr"]}</a>' for l in earlier)
        parts.append(f'<p class="note">This map is the same as in the earlier {"lesson" if len(earlier) == 1 else "lessons"} of this area ({links}). The blue marker and the grey name tags show the parts of this lesson.</p>')
    if record.get("screen"):
        number += 1
        s = record["screen"]
        parts.append(figure(number, s["when"], s["title"], screen_html(s), s.get("caption")))
    else:
        parts.append(f'<p class="note"><b>No figure of a screen.</b> {E(record["no_screen"])}</p>')
    number += 1
    p = record["path"]
    parts.append(figure(number, p["when"], p["title"], wide(path_svg(p), p["title"]) + steps_html(p, shas), p.get("caption")))
    if record.get("state"):
        number += 1
        s = record["state"]
        parts.append(figure(number, s["when"], s["title"], state_html(s, shas), s.get("caption")))
    guess = record["guess"]
    questions = "".join(f"<li>{E(q)}</li>" for q in guess["questions"])
    answer = guess["answer"]
    body = "".join(f"<p>{E(t)}</p>" for t in answer["text"])
    if answer.get("changes"):
        changes = "".join(f'<li><b>Step {c["step"]}.</b> {E(c["text"])} {cite_link(c["cite"], shas)}</li>' for c in answer["changes"])
        body += f'<h4>What the PR changes in Figure {number - (1 if record.get("state") else 0)}</h4><ul class="changes">{changes}</ul>'
    if answer.get("screen"):
        s = answer["screen"]
        body += f'<h4>{E(s["title"])}</h4>{screen_html(s)}'
    if answer.get("check"):
        body += "<h4>What to check in the review</h4><ul>" + "".join(f"<li>{E(c)}</li>" for c in answer["check"]) + "</ul>"
    links = [{"url": f'https://github.com/{pr["repo"]}/pull/{pr["number"]}', "label": "Open the pull request"}]
    links += [l for l in pr.get("links", []) if l["url"] != links[0]["url"]]
    parts.append(f'<section class="guess"><h3>Before you open the diff</h3><ol class="q">{questions}</ol>'
                 f'<details><summary>Show what this PR changes</summary><div class="answer">{body}</div></details>'
                 '<p class="open-pr">' + "".join(f'<a href="{E(l["url"])}">{E(l["label"])}</a>' for l in links) + "</p></section>")
    parts.append("</article>")
    return "".join(parts)


def slug(pr):
    return f'{pr["repo"].split("/")[-1]}-{pr["number"]}'


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("record")
    ap.add_argument("--home", required=True, help="the lesson store (areas/, records/, rows/)")
    ap.add_argument("--preview", help="also write one standalone page here, for a local look")
    ap.add_argument("--skip", metavar="REASON", help="write a row that says this pull request gets no lesson, and why; <record> is then prepare.sh's output")
    args = ap.parse_args()
    home = Path(args.home)
    record = json.loads(Path(args.record).read_text())
    if args.skip:
        pr = record["pr"]
        (home / "rows").mkdir(parents=True, exist_ok=True)
        row_file = home / "rows" / f"{slug(pr)}.json"
        row_file.write_text(json.dumps({"slug": slug(pr), "pr": pr["number"], "repo": pr["repo"], "title": pr["title"], "author": pr["author"],
                                        "written": record.get("written", ""), "added": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                                        "skipped": args.skip}, ensure_ascii=False) + "\n")
        print(json.dumps({"row": str(row_file), "slug": slug(pr), "skipped": args.skip}))
        return
    area_file = home / "areas" / f'{record["area"]}.json'
    if not area_file.exists():
        fail(f"no map for area {record['area']}", f"write {area_file} as RECORD.md describes, then run check-record.py")
    area = json.loads(area_file.read_text())
    fragment = lesson_html(record, area)

    (home / "rows").mkdir(exist_ok=True)
    (home / "records").mkdir(exist_ok=True)
    name = slug(record["pr"])
    kept = home / "records" / f"{name}.json"
    if Path(args.record).resolve() != kept.resolve():
        shutil.copyfile(args.record, kept)

    # the area remembers what each lesson taught, so the next one can point back instead of repeating
    taught = [{"text": s["text"], "cite": s["cite"]} for s in record["path"]["steps"] if not s.get("known")]
    entry = {"pr": record["pr"]["number"], "repo": record["pr"]["repo"], "marker": record.get("marker"), "shas": record["shas"], "steps": taught}
    lessons = area.setdefault("lessons", [])
    at = next((i for i, l in enumerate(lessons) if l["pr"] == entry["pr"] and l.get("repo") == entry["repo"]), None)
    if at is None:
        lessons.append(entry)
    else:
        lessons[at] = entry  # a lesson written again keeps its place, so later lessons still point back at it
    area_file.write_text(json.dumps(area, indent=1, ensure_ascii=False) + "\n")

    # one row per lesson: the page lists the rows and shows `html` when one is opened
    row_file = home / "rows" / f"{name}.json"
    # a lesson rendered again keeps its place in the page's list
    added = (json.loads(row_file.read_text()).get("added") if row_file.exists() else None) or datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    steps = record["path"]["steps"]
    row = {"slug": name, "pr": record["pr"]["number"], "repo": record["pr"]["repo"], "title": record["pr"]["title"], "headline": record["headline"],
           "author": record["pr"]["author"], "area": record["area"], "area_name": area["name"],
           "written": record.get("written", ""), "added": added, "steps": len(steps), "new_steps": sum(1 for s in steps if not s.get("known")),
           "checked": bool(record.get("factcheck")), "html": fragment}
    row_file.write_text(json.dumps(row, ensure_ascii=False) + "\n")
    if row_file.stat().st_size > 240_000:
        fail(f"the row is {row_file.stat().st_size} bytes and the page stores at most 256 KiB per lesson", "shorten the record's texts")

    if args.preview:
        shell = (SKILL / "template" / "index.html").read_text()
        style = shell[shell.index("<style>"):shell.index("</style>") + 8]
        Path(args.preview).write_text(f'<!doctype html>\n<html lang="en"><head><meta charset="utf-8"><title>Lesson preview</title>{style}</head>'
                                      f'<body><main class="wrap">{fragment}</main></body></html>\n')
    print(json.dumps({"row": str(row_file), "slug": name, "steps": row["steps"], "new_steps": row["new_steps"]}))


if __name__ == "__main__":
    main()
