#!/usr/bin/env python3
import re, sys, unicodedata

def slugify(text):
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")

for line in sys.stdin:
    print(slugify(line))
