#!/usr/bin/env bash
# Renders a fixture with known layout defects and checks that render.sh reports exactly those:
# nothing for the hidden label, the off-camera shapes and labels, or the backed label on hatching. The half-transparent
# shape two screens away once crashed resvg.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
"$here/scripts/new.sh" "$work/p" >/dev/null
cp "$here/tests/LayoutFixture.tsx" "$work/p/src/Explainer.tsx"
echo '[{"id": "only", "text": "Layout check."}]' > "$work/p/beats.json"
"$here/scripts/render.sh" "$work/p" preview 2> "$work/err" >/dev/null || { cat "$work/err" >&2; exit 1; }
got=$(grep -o 'LAYOUT: beat 1 [^:]*: .*' "$work/err" | sed 's/^LAYOUT: beat 1 [^:]*: //' | sort -u)
want=$(sort <<'LIST'
"crossing" crosses the edge of shape "box"
"first" overlaps "second"
shape "runaway" leaves the frame
"struck" crosses the edge of shape "rule"
"ring" overlaps icon "bell"
"raw" sits on texture "crowd" without a paper backing
LIST
)
if [ "$got" = "$want" ]; then echo "layout check ok"; rm -rf "$work"; else printf 'want:\n%s\ngot:\n%s\n' "$want" "$got" >&2; exit 1; fi
