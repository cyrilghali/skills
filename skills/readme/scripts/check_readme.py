#!/usr/bin/env python3
"""Check a README's external links, in-page anchors and, given --help output, flag coverage, and that section headings are questions. Exit 1 on any failure."""
import re
import sys
import urllib.error
import urllib.request

LINK = re.compile(r"\]\(([^)\s]+)\)|<(https?://[^>\s]+)>|src=\"(https?://[^\"]+)\"")
FENCE = re.compile(r"^(```|~~~).*?^\1", re.S | re.M)


def slug(heading: str) -> str:
    text = re.sub(r"[`*_]|\[([^\]]*)\]\([^)]*\)", r"\1", heading).strip().lower()
    return re.sub(r"\s", "-", re.sub(r"[^\w\s-]", "", text))


def anchors(markdown: str) -> set[str]:
    seen: dict[str, int] = {}
    out = set()
    for heading in re.findall(r"^#{1,6}\s+(.+?)\s*#*$", markdown, re.M):
        base = slug(heading)
        n = seen.get(base, 0)
        seen[base] = n + 1
        out.add(base if n == 0 else f"{base}-{n}")
    return out


def status(url: str) -> str | None:
    # Some hosts refuse HEAD, so a failed HEAD is retried as GET.
    for method in ("HEAD", "GET"):
        req = urllib.request.Request(url, method=method, headers={"User-Agent": "Mozilla/5.0 readme-check"})
        try:
            with urllib.request.urlopen(req, timeout=15):
                return None
        except urllib.error.HTTPError as e:
            error = f"HTTP {e.code}"
        except (urllib.error.URLError, TimeoutError) as e:
            error = str(getattr(e, "reason", e))
    return error


def main() -> int:
    if len(sys.argv) not in (2, 3):
        print("usage: check_readme.py README.md [HELP.txt]", file=sys.stderr)
        return 2
    markdown = open(sys.argv[1], encoding="utf-8").read()
    prose = FENCE.sub("", markdown)
    known = anchors(prose)
    failures = []
    for groups in LINK.findall(prose):
        target = next(g for g in groups if g)
        if target.startswith("#"):
            if target[1:] not in known:
                failures.append(f"anchor {target}: no heading has this slug")
        elif target.startswith("http"):
            error = status(target)
            if error:
                failures.append(f"link {target}: {error}")
    for heading in re.findall(r"^#{2,6}\s+(.+?)\s*$", prose, re.M):
        if not heading.endswith("?") and not heading.startswith("<"):
            failures.append(f"heading '{heading}': write it as a question a reader asks")
    if len(sys.argv) == 3:
        help_text = open(sys.argv[2], encoding="utf-8").read()
        documented = set(re.findall(r"--[\w-]+", markdown))
        for flag in sorted(set(re.findall(r"(?<![\w-])--[a-z][\w-]*", help_text)) - {"--help"}):
            if flag not in documented:
                failures.append(f"flag {flag}: in --help but not in the README")
    for line in failures:
        print(line, file=sys.stderr)
    print(f"{len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
