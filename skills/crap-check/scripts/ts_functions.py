#!/usr/bin/env python3
"""Lists TypeScript/JavaScript functions with spans, complexity and coverage via crapper's own modules.

Run with crapper's venv python. Prints rows for report.py: kind lang file namespace name start end cc cov.
Usage: ts_functions.py --root <repo> --base <commit> [--run-coverage | --use-existing] <files...>
"""
import argparse
import os
import subprocess
import sys
from pathlib import Path

from crapper.coverage import load_bundle
from crapper.discover import is_test_file, language_of
from crapper.languages import functions_in_file
from crapper.runners import run_coverage

ap = argparse.ArgumentParser()
ap.add_argument("--root", required=True)
ap.add_argument("--base", required=True)
ap.add_argument("--run-coverage", action="store_true")
ap.add_argument("--use-existing", action="store_true")
ap.add_argument("files", nargs="*")
a = ap.parse_args()

root = Path(a.root).resolve()
files = [root / f for f in a.files if language_of(f) == "typescript" and not is_test_file(f)]
rels = [f.relative_to(root).as_posix() for f in files]

bundle = None
if a.run_coverage:
    # The test runner's output must not mix with the rows on stdout.
    saved = os.dup(1)
    os.dup2(2, 1)
    try:
        run_coverage(root, files, None)
    finally:
        os.dup2(saved, 1)
if a.run_coverage or a.use_existing:
    bundle = load_bundle(root)
    bundle.bind_sources(rels)

for f, rel in zip(files, rels):
    head = functions_in_file("typescript", f.read_text(encoding="utf-8", errors="replace"), rel, str(root))
    shown = subprocess.run(["git", "show", f"{a.base}:{rel}"], cwd=root, capture_output=True, text=True)
    base = functions_in_file("typescript", shown.stdout, rel, str(root)) if shown.returncode == 0 else []
    for kind, fns in (("H", head), ("B", base)):
        for fn in fns:
            cov = "-"
            if kind == "H" and bundle is not None:
                found = bundle.percent_for(fn)
                cov = f"{(found if found is not None else 0.0):.4f}"
            print("\t".join(map(str, [kind, "ts", rel, fn.namespace, fn.name, fn.start_line, fn.end_line, fn.complexity, cov])))
