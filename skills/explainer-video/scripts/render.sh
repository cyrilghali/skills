#!/usr/bin/env bash
# Usage: render.sh <project-dir> [preview|final]  ->  prints the MP4 path.
# Voices beats.json, makes the sounds, lints the style, type-checks, bakes the paper and renders.
# Prints voice:, STYLE:, LAYOUT: and SHOWN: lines to stderr. Renders on 2 browser tabs unless EXPLAINER_CONCURRENCY says otherwise.
set -euo pipefail
project=$(cd "${1:?usage: render.sh <project-dir> [preview|final]}" && pwd)
quality=${2:-preview}
here=$(cd "$(dirname "$0")" && pwd)
case $quality in
  preview) flags=(--scale=0.5) ;;
  final) flags=() ;;
  *) echo "quality must be preview or final" >&2; exit 2 ;;
esac
vlog=$(mktemp)
uv run -q --python 3.12 --with kokoro-onnx --with soundfile --with av --with faster-whisper python "$here/voice.py" "$project" >"$vlog" 2>&1 || { cat "$vlog" >&2; exit 1; }
grep '^voice:' "$vlog" >&2
uv run -q --python 3.12 --with numpy --with soundfile python "$here/sound.py" "$project" >&2
uv run -q --python 3.12 python "$here/lint.py" "$project" >&2
cd "$project"
pnpm exec tsc --noEmit >&2
# Bake the paper and six grain frames once; live full-frame noise filters would slow every frame.
if [ ! -s public/tex/paper.png ] || [ ! -s public/tex/grain-5.png ]; then
  mkdir -p public/tex
  tlog=$(mktemp)
  ( pnpm exec remotion still PaperTex public/tex/paper.png --image-format=png &&
    for i in 0 1 2 3 4 5; do pnpm exec remotion still GrainTex "public/tex/grain-$i.png" --frame="$i" --image-format=png || exit 1; done ) >"$tlog" 2>&1 ||
    { tail -20 "$tlog" >&2; echo "baking the paper texture failed" >&2; exit 1; }
fi
out="$project/out/$quality.mp4"
log=$(mktemp)
pnpm exec remotion render Explainer "$out" "${flags[@]}" --concurrency="${EXPLAINER_CONCURRENCY:-2}" --timeout=120000 --log=verbose >"$log" 2>&1 &
rpid=$!
# Verbose logging grows with every rendered frame, so a log that stops growing means a stalled render.
last=-1; idle=0
while kill -0 "$rpid" 2>/dev/null; do
  sleep 10
  size=$(wc -c <"$log")
  if [ "$size" = "$last" ]; then idle=$((idle + 10)); else idle=0; last=$size; fi
  if [ "$idle" -ge "${EXPLAINER_STALL_SECONDS:-300}" ]; then
    pkill -P "$rpid" 2>/dev/null || true; kill "$rpid" 2>/dev/null || true
    grep -v '^\[' "$log" | tail -40 >&2
    echo "render stalled: no new frames for ${idle}s" >&2; exit 1
  fi
done
wait "$rpid" || { grep -v '^\[' "$log" | tail -40 >&2; exit 1; }
grep -o 'BEAT: [0-9.]*' "$log" | awk '{ print $2 }' | sort -n > "${out%.mp4}.beats.txt"
grep -o 'LAYOUT: .*' "$log" | sort -u >&2 || true
# First appearance of each text; digits are ignored so a running counter counts once.
grep -o 'SHOWN: .*' "$log" | sort -s -k2,2n | awk -F'"' '{ k = $2; gsub(/[0-9.]/, "", k) } !seen[k]++' >&2 || true
echo "$out"
