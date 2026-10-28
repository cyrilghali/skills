#!/usr/bin/env bash
# Usage: render.sh <project-dir> [preview|final|720p]  ->  prints the MP4 path.
# Voices beats.json, makes the sounds, lints the style, type-checks, bakes the paper, renders and mixes the sound.
# Prints voice:, STYLE:, LAYOUT: and SHOWN: lines to stderr and writes out/beats.txt beside the video. Draws frames on one worker per CPU unless EXPLAINER_WORKERS says otherwise.
set -euo pipefail
project=$(cd "${1:?usage: render.sh <project-dir> [preview|final|720p]}" && pwd)
quality=${2:-preview}
here=$(cd "$(dirname "$0")" && pwd)
case $quality in
  preview) scale=0.5 ;;
  final) scale=1 ;;
  720p) scale=0.6666666666666666 ;;
  *) echo "quality must be preview, final or 720p" >&2; exit 2 ;;
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
# The frames and the mux land in temp files, so a failed step leaves the last good video in place.
trap 'rm -f "$out.frames.mp4" "$out.tmp.mp4"' EXIT
node "$here/render.mjs" "$project" video "$scale" "$fin" "$out.frames.mp4" >/dev/null
uv run -q --python 3.12 --with numpy --with soundfile --with soxr python "$here/mix.py" "$project" >/dev/null
ffmpeg -v error -y -i "$out.frames.mp4" -i "$project/out/mix.wav" -map 0:v -map 1:a -c:v copy -c:a aac -ac 2 "$out.tmp.mp4" ||
  { echo "adding the sound failed" >&2; exit 1; }
mv "$out.tmp.mp4" "$out"
echo "$out"
