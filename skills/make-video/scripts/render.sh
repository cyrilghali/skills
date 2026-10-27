#!/usr/bin/env bash
# Usage: render.sh <project-dir> [preview|final]  ->  prints the MP4 path.
# Voices beats.json, makes the sounds, lints the style, type-checks, bakes the paper and renders.
# Prints voice:, STYLE:, LAYOUT: and SHOWN: lines to stderr. Renders on 2 browser tabs unless EXPLAINER_CONCURRENCY says otherwise.
set -euo pipefail
project=$(cd "${1:?usage: render.sh <project-dir> [preview|final]}" && pwd)
quality=${2:-preview}
here=$(cd "$(dirname "$0")" && pwd)
case $quality in
  preview) flags=(--scale=0.5); width=960; height=540 ;;
  final) flags=(); width=1920; height=1080 ;;
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
# The bake depends only on look.tsx and theme.ts, so it is shared between projects through a cache.
cache="${EXPLAINER_CACHE:-$HOME/.cache/make-video}/$(cat src/look.tsx src/theme.ts | shasum | cut -c1-16)"
if [ ! -s public/tex/paper.png ] || [ ! -s public/tex/grain-5.png ]; then
  if [ -s "$cache/grain-5.png" ]; then
    mkdir -p public/tex && cp "$cache"/*.png public/tex/
  else
    mkdir -p public/tex
    tlog=$(mktemp)
    ( pnpm exec remotion bundle --out-dir=build >/dev/null &&
      pnpm exec remotion still build PaperTex public/tex/paper.png --image-format=png &&
      for i in 0 1 2 3 4 5; do pnpm exec remotion still build GrainTex "public/tex/grain-$i.png" --frame="$i" --image-format=png || exit 1; done ) >"$tlog" 2>&1 ||
      { tail -20 "$tlog" >&2; echo "baking the paper texture failed" >&2; exit 1; }
    mkdir -p "$cache" && cp public/tex/*.png "$cache/"
  fi
fi
# The paper, vignette and grain are multiplied in by ffmpeg after a flat render: in the browser those
# full-frame blends cost more than everything else drawn (measured 2.5 to 3x per frame).
fps=$(python3 -c 'import json; print(json.load(open("src/timeline.json")).get("fps", 30))')
fin="$cache/finish-${width}x${height}@$fps"
if [ ! -s "$fin/f000.png" ]; then
  uv run -q --python 3.12 --with numpy --with pillow python "$here/finish-tex.py" "$project" "$fps" "$width" "$height" "$fin" >/dev/null ||
    { echo "baking the finish frames failed" >&2; exit 1; }
fi
out="$project/out/$quality.mp4"
flat="$project/out/$quality.flat.mp4"
log=$(mktemp)
pnpm exec remotion render Explainer "$flat" "${flags[@]}" --props='{"flat":true}' --crf=16 --x264-preset=veryfast --concurrency="${EXPLAINER_CONCURRENCY:-2}" --timeout=120000 --log=verbose >"$log" 2>&1 &
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
ffmpeg -v error -y -i "$flat" -stream_loop -1 -framerate "$fps" -i "$fin/f%03d.png" \
  -filter_complex "[0:v]format=gbrp[a];[1:v]format=gbrp[b];[a][b]blend=all_mode=multiply:shortest=1,format=yuv420p[v]" \
  -map "[v]" -map "0:a?" -c:v libx264 -crf 18 -c:a copy "$out" || { echo "laying the paper on the render failed" >&2; exit 1; }
rm -f "$flat"
grep -o 'BEAT: [0-9.]*' "$log" | awk '{ print $2 }' | sort -n > "${out%.mp4}.beats.txt"
grep -o 'LAYOUT: .*' "$log" | sort -u >&2 || true
# First appearance of each text; digits are ignored so a running counter counts once.
grep -o 'SHOWN: .*' "$log" | sort -s -k2,2n | awk -F'"' '{ k = $2; gsub(/[0-9.]/, "", k) } !seen[k]++' >&2 || true
echo "$out"
