# Install

1. Copy this folder to `~/.claude/skills/make-video/`.
2. Install Node, pnpm, uv and ffmpeg: `brew install node pnpm uv ffmpeg`. On Linux, use the distribution's packages for the same four.
3. Run `scripts/setup.sh`. It downloads the free Kokoro voice model (about 340 MB) to `~/.cache/kokoro` and the faster-whisper model that times Kokoro's words (about 480 MB) to `~/.cache/huggingface`, and the Gaegu and JetBrains Mono fonts (about 10 MB) to `~/.cache/make-video/fonts`, once. Set `EXPLAINER_CACHE` to keep the fonts and baked textures somewhere else.
4. To use ElevenLabs instead of Kokoro, export `ELEVENLABS_API_KEY` in the shell file every non-interactive shell reads (`~/.zshenv` for zsh). A key that ElevenLabs refuses (out of credit or revoked) makes the render fall back to Kokoro and say so; it does not need unsetting.

To check the install, run `tests/test_layout.sh`. It builds a project from the template, renders a fixture with known layout defects, and prints `layout check ok` when the check reports exactly those. It also exercises the paper bake and the Kokoro word timing.
