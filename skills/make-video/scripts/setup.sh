#!/usr/bin/env bash
# Checks the tools and downloads, once: the free Kokoro voice (~340 MB), the faster-whisper model that times
# its words (~480 MB), and the two fonts the render draws text with (~10 MB).
set -euo pipefail
for t in node pnpm uv ffmpeg ffprobe; do command -v "$t" >/dev/null || { echo "missing: $t" >&2; exit 2; }; done
dir=${KOKORO_DIR:-$HOME/.cache/kokoro}
mkdir -p "$dir"
base=https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0
for f in kokoro-v1.0.onnx voices-v1.0.bin; do
  [ -s "$dir/$f" ] || curl -fsSL -o "$dir/$f" "$base/$f"
done
fonts=${EXPLAINER_CACHE:-$HOME/.cache/make-video}/fonts
mkdir -p "$fonts"
for f in gaegu/Gaegu-Light.ttf gaegu/Gaegu-Regular.ttf gaegu/Gaegu-Bold.ttf jetbrainsmono/JetBrainsMono%5Bwght%5D.ttf; do
  out="$fonts/$(basename "$f" | sed 's/%5Bwght%5D/-Variable/')"
  [ -s "$out" ] && continue
  curl -fsSL -o "$out.tmp" "https://raw.githubusercontent.com/google/fonts/main/ofl/$f" ||
    { rm -f "$out.tmp"; echo "could not download the font $(basename "$out"); check the network and run setup.sh again" >&2; exit 1; }
  mv "$out.tmp" "$out"
done
uv run -q --python 3.12 --with faster-whisper python -c "from faster_whisper import download_model; download_model('${WHISPER_MODEL:-small.en}')" >/dev/null
if [ -n "${ELEVENLABS_API_KEY:-}" ]; then echo "voice: elevenlabs"; else echo "voice: kokoro ($dir)"; fi
