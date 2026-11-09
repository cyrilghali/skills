#!/usr/bin/env python3
"""Mark the daily report's flags that carry new information, so an unchanged flag is not sent again.

Usage: new-flags.py <report> <seen-file> [YYYY-MM-DD]

A flag is new when its item (a milestone, a ticket, or the project itself) was not flagged on the
previous run, or its facts changed: the ticket IDs or dates in the line. The report is model-written
and rewords the same flag daily, so wording, percentages and status names are not compared.
New flags get " (new)" appended in the report. The seen file keeps only today's flags, so an item
that drops out and comes back later counts as new. Prints: <new> <unchanged> <oldest first-seen date>.
"""
import datetime as dt
import re
import sys
from pathlib import Path


def flags(report):
    project, section = None, None
    for line in report.splitlines():
        if line.startswith("## "):
            project, section = line[3:].strip(), None
        elif line.endswith(":") and not line.startswith("- "):
            section = line
        elif section == "Needs a person:" and line.startswith("- ") and project:
            text = line[2:].strip()
            item = re.match(r'Milestone "([^"]+)"|([A-Z]+-\d+)\b', text)
            facts = " ".join(sorted(set(re.findall(r"\b[A-Z]+-\d+\b|\d{4}-\d{2}-\d{2}", text))))
            yield f"{project}|{item.group(1) or item.group(2) if item else 'project'}", facts, text


def main(report_path, seen_path, today=str(dt.date.today())):
    report, seen_file = Path(report_path), Path(seen_path)
    seen = {}
    if seen_file.exists():
        for row in seen_file.read_text().splitlines():
            key, first, facts = row.split("\t", 2)
            seen[key] = (first, facts)

    current, new = {}, set()
    for key, facts, text in flags(report.read_text()):
        first, old = seen.get(key, (today, None))
        if old != facts:
            first = today
            new.add(text)
        current[key] = (first, facts)

    if new:
        report.write_text("\n".join(f"{l} (new)" if l.startswith("- ") and l[2:].strip() in new else l
                                    for l in report.read_text().splitlines()) + "\n")
    seen_file.write_text("".join(f"{k}\t{f}\t{t}\n" for k, (f, t) in current.items()))
    unchanged = [f for k, (f, _) in current.items() if seen.get(k, (None, None))[1] == current[k][1]]
    print(len(new), len(unchanged), min(unchanged, default="-"))


if __name__ == "__main__":
    main(*sys.argv[1:])
