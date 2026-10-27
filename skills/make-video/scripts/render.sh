#!/usr/bin/env bash
# Usage: render.sh <project-dir> [preview|final]  ->  prints the MP4 path.
# Voices beats.json, makes the sounds, lints the style, type-checks, bakes the paper, renders and mixes the sound.
# Prints voice:, STYLE:, LAYOUT: and SHOWN: lines to stderr. Draws frames on one worker per CPU unless EXPLAINER_WORKERS says otherwise.
set -euo pipefail
project=$(cd "${1:?usage: render.sh <project-dir> [preview|final]}" && pwd)
quality=${2:-preview}
here=$(cd "$(dirname "$0")" && pwd)
case $quality in
  preview) scale=0.5 ;;
  final) scale=1 ;;
  *) echo "quality must be preview or final" >&2; exit 2 ;;
esac
vlog=$(mktemp)
uv run -q --python 3.12 --with kokoro-onnx --with soundfile --with av --with faster-whisper python "$here/voice.py" "$project" >"$vlog" 2>&1 || { cat "$vlog" >&2; exit 1; }
grep '^voice:' "$vlog" >&2
uv run -q --python 3.12 --with numpy --with soundfile python "$here/sound.py" "$project" >&2
uv run -q --python 3.12 python "$here/lint.py" "$project" >&2
cd "$project"
pnpm exec tsc --noEmit >&2
fin=$("$here/finish.sh" "$project" "$scale")
out="$project/out/$quality.mp4"
log=$(mktemp)
node "$here/render.mjs" "$project" video "$scale" "$fin" "$project/out/$quality.video.mp4" >"$log" || { tail -40 "$log" >&2; exit 1; }
uv run -q --python 3.12 --with numpy --with soundfile --with soxr python "$here/mix.py" "$project" >/dev/null
ffmpeg -v error -y -i "$project/out/$quality.video.mp4" -i "$project/out/mix.wav" -map 0:v -map 1:a -c:v copy -c:a aac -ac 2 "$out" ||
  { echo "adding the sound failed" >&2; exit 1; }
rm -f "$project/out/$quality.video.mp4"
grep -o 'BEAT: [0-9.]*' "$log" | awk '{ print $2 }' | sort -n > "${out%.mp4}.beats.txt"
grep -o 'LAYOUT: .*' "$log" | sort -u >&2 || true
# First appearance of each text; digits are ignored so a running counter counts once.
grep -o 'SHOWN: .*' "$log" | sort -s -k2,2n | awk -F'"' '{ k = $2; gsub(/[0-9.]/, "", k) } !seen[k]++' >&2 || true
echo "$out"
