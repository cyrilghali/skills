#!/usr/bin/env bash
# Renders a fixture with known layout defects and checks that render.sh reports exactly those:
# nothing for the hidden label, the off-camera shapes and labels, or the backed label on hatching. The half-transparent
# shape two screens away once crashed resvg. Every label near a visible shape stays quiet: "backed", "first" and
# "second" each get a small anchor shape, because a texture does not count as something to label. "floating" and
# "ghost" (whose shape is at opacity 0) float on empty paper, "near" and the Note do not. Three labels on the
# second beat's words check the SHOWN: verdict: one the voice never says, one it says later, one it says at once.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
"$here/scripts/new.sh" "$work/p" >/dev/null
cp "$here/tests/LayoutFixture.tsx" "$work/p/src/Explainer.tsx"
echo '[{"id": "only", "text": "Layout check."}, {"id": "then", "text": "Then the voice says the later words."}]' > "$work/p/beats.json"
"$here/scripts/render.sh" "$work/p" preview 2> "$work/err" >/dev/null || { cat "$work/err" >&2; exit 1; }
got=$(grep -o 'LAYOUT: beat 1 [^:]*: .*' "$work/err" | sed 's/^LAYOUT: beat 1 [^:]*: //' | sort -u)
want=$(sort <<'LIST'
"crossing" crosses the edge of shape "box"
"first" overlaps "second"
shape "runaway" leaves the frame
"struck" crosses the edge of shape "rule"
"ring" overlaps icon "bell"
"raw" sits on texture "crowd" without a paper backing
"floating" floats on empty paper: no shape is visible within 160 px
"ghost" floats on empty paper: no shape is visible within 160 px
LIST
)
shown=$(for t in "unsaid words" "later words" "layout check"; do
  grep -F "SHOWN: " "$work/err" | grep -F "\"$t\"" | sed "s/^SHOWN: [^\"]*\"\([^\"]*\)\" as the voice says \"[^\"]*\"/\1|/; s/[0-9][0-9.]*s/Ns/g"
done)
want_shown=$(cat <<'LIST'
unsaid words|; the voice never says it
later words|; the voice says it at Ns, Ns later
layout check|
LIST
)
if [ "$got" = "$want" ] && [ "$shown" = "$want_shown" ]; then echo "layout check ok"; rm -rf "$work"; else printf 'want:\n%s\n%s\ngot:\n%s\n%s\n' "$want" "$want_shown" "$got" "$shown" >&2; exit 1; fi
