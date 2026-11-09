#!/usr/bin/env python3
import argparse, json, sys

def count(path):
    text = open(path, encoding="utf-8").read()
    return {"file": path, "lines": text.count("\n"), "words": len(text.split()), "chars": len(text)}

def main():
    p = argparse.ArgumentParser(description="Count lines, words and characters per file.")
    p.add_argument("files", nargs="+")
    p.add_argument("--json", action="store_true", help="print JSON instead of a table")
    p.add_argument("--sort", choices=["lines", "words", "chars"], help="sort rows, largest first")
    a = p.parse_args()
    rows = [count(f) for f in a.files]
    if a.sort:
        rows.sort(key=lambda r: r[a.sort], reverse=True)
    if a.json:
        json.dump(rows, sys.stdout, indent=2); print(); return
    print(f"{'file':<30}{'lines':>8}{'words':>8}{'chars':>9}")
    for r in rows:
        print(f"{r['file']:<30}{r['lines']:>8}{r['words']:>8}{r['chars']:>9}")
    print(f"{'total':<30}{sum(r['lines'] for r in rows):>8}{sum(r['words'] for r in rows):>8}{sum(r['chars'] for r in rows):>9}")

if __name__ == "__main__":
    main()
