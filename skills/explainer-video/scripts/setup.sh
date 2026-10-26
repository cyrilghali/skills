#!/usr/bin/env bash
# Checks the tools and downloads the free Kokoro voice (~340 MB) and the faster-whisper model that times its words (~480 MB), once.
set -euo pipefail
for t in node pnpm uv ffmpeg ffprobe; do command -v "$t" >/dev/null || { echo "missing: $t" >&2; exit 2; }; done
dir=${KOKORO_DIR:-$HOME/.cache/kokoro}
mkdir -p "$dir"
base=https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0
for f in kokoro-v1.0.onnx voices-v1.0.bin; do
  [ -s "$dir/$f" ] || curl -fsSL -o "$dir/$f" "$base/$f"
done
uv run -q --python 3.12 --with faster-whisper python -c "from faster_whisper import download_model; download_model('${WHISPER_MODEL:-small.en}')" >/dev/null
if [ -n "${ELEVENLABS_API_KEY:-}" ]; then echo "voice: elevenlabs"; else echo "voice: kokoro ($dir)"; fi
