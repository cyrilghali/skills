"""Voice every beat in <project>/beats.json and write <project>/src/timeline.json.

Voice: ElevenLabs when ELEVENLABS_API_KEY is set, else Kokoro (free, local). When ElevenLabs
refuses the key (401, or its quota is used up), every clip falls back to Kokoro and the voice: line says why.
Clips are cached by text and voice in <project>/public/voice, so re-runs cost nothing.
Each clip gets the time each word starts, beside it as <clip>.words.json: from ElevenLabs when it
voiced the clip, else aligned with faster-whisper. They are gathered into <project>/src/words.json,
which word() in src/beats.ts reads before its estimate.
"""

import base64
import hashlib
import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

import av

KOKORO_DIR = Path(os.environ.get("KOKORO_DIR", Path.home() / ".cache" / "kokoro"))
KOKORO_VOICE = os.environ.get("KOKORO_VOICE", "af_heart")
WHISPER_MODEL = os.environ.get("WHISPER_MODEL", "small.en")
ELEVEN_VOICE = os.environ.get("ELEVENLABS_VOICE_ID", "JBFqnCBsd6RMkjVDRZzb")
ELEVEN_MODEL = os.environ.get("ELEVENLABS_MODEL", "eleven_v4_turbo")
FPS = 30

_kokoro = None
_whisper = None


class Refused(Exception):
    """ElevenLabs will not voice with this key: unauthorized or out of credit."""


def eleven(text, path):
    req = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{ELEVEN_VOICE}/with-timestamps?output_format=mp3_44100_128",
        data=json.dumps({"text": text, "model_id": ELEVEN_MODEL}).encode(),
        headers={"xi-api-key": os.environ["ELEVENLABS_API_KEY"], "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            data = json.load(resp)
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        if e.code == 401 or "quota_exceeded" in body:
            reason = "quota_exceeded" if "quota_exceeded" in body else f"HTTP {e.code}"
            raise Refused(reason) from None
        sys.exit(f"ElevenLabs refused the clip (HTTP {e.code}): {body}")
    path.write_bytes(base64.b64decode(data["audio_base64"]))
    align = data["alignment"]
    words_file(path).write_text(json.dumps(word_starts(align["characters"], align["character_start_times_seconds"])))


def words_file(clip):
    return clip.with_name(clip.name.removeprefix("tmp-")).with_suffix(".words.json")


def word_starts(chars, starts):
    """[[word, start seconds], ...] from per-character times, words lowercased without punctuation."""
    out, cur, t0 = [], "", None
    for ch, st in zip(chars + [" "], starts + [0.0]):
        if ch.isspace():
            if cur:
                out.append([re.sub(r"[^\w']", "", cur.lower()), round(t0, 3)])
            cur, t0 = "", None
        else:
            t0 = st if t0 is None else t0
            cur += ch
    return out


def kokoro(text, path):
    global _kokoro
    import soundfile
    from kokoro_onnx import Kokoro

    if _kokoro is None:
        model, voices = KOKORO_DIR / "kokoro-v1.0.onnx", KOKORO_DIR / "voices-v1.0.bin"
        if not model.exists() or not voices.exists():
            sys.exit(f"Kokoro model missing in {KOKORO_DIR}: run scripts/setup.sh")
        _kokoro = Kokoro(str(model), str(voices))
    samples, rate = _kokoro.create(text, voice=KOKORO_VOICE, speed=1.0, lang="en-us")
    soundfile.write(path, samples, rate)


def align(text, clip):
    """Write [[word, start seconds], ...] for clip's own text, timed by faster-whisper, or return False."""
    global _whisper
    import difflib

    try:
        from faster_whisper import WhisperModel
    except ImportError:
        return False
    if _whisper is None:
        _whisper = WhisperModel(WHISPER_MODEL, device="cpu", compute_type="int8")
    import numpy as np
    import soundfile

    # Decode here: faster-whisper's own decoder breaks on the PyAV version the render installs.
    x, rate = soundfile.read(str(clip), dtype="float32")
    x = x.mean(axis=1) if x.ndim > 1 else x
    n = int(len(x) * 16000 / rate)
    x = np.interp(np.linspace(0, len(x) - 1, n), np.arange(len(x)), x).astype("float32")
    segments, _ = _whisper.transcribe(x, word_timestamps=True, language="en")
    norm = lambda w: re.sub(r"[^\w']", "", w.lower())
    heard = [(norm(w.word), w.start) for s in segments for w in s.words if norm(w.word)]
    want = [norm(w) for w in text.split() if norm(w)]
    times = [None] * len(want)
    for i, j, n in difflib.SequenceMatcher(a=want, b=[h[0] for h in heard], autojunk=False).get_matching_blocks():
        for k in range(n):
            times[i + k] = heard[j + k][1]
    # A word the recognizer heard differently takes a time between its matched neighbours.
    seconds = len(x) / 16000
    known = [(-1, 0.0)] + [(i, x) for i, x in enumerate(times) if x is not None] + [(len(times), seconds)]
    for i, x in enumerate(times):
        if x is None:
            a = max(k for k in known if k[0] < i)
            b = min(k for k in known if k[0] > i)
            times[i] = a[1] + (b[1] - a[1]) * (i - a[0]) / (b[0] - a[0])
    words_file(clip).write_text(json.dumps([[w, round(x, 3)] for w, x in zip(want, times)]))
    return True


def speak(text, cache, use_eleven):
    """Return (audio path, seconds, voice) for text, synthesizing on a cache miss."""
    voice = f"eleven:{ELEVEN_VOICE}:{ELEVEN_MODEL}" if use_eleven else f"kokoro:{KOKORO_VOICE}"
    key = hashlib.sha1(f"{voice}\n{text}".encode()).hexdigest()[:16]
    path = cache / f"{key}.{'mp3' if use_eleven else 'wav'}"
    if not path.exists():
        cache.mkdir(parents=True, exist_ok=True)
        tmp = path.with_name("tmp-" + path.name)
        (eleven if use_eleven else kokoro)(text, tmp)
        tmp.rename(path)
    if not words_file(path).exists():
        align(text, path)
    with av.open(str(path)) as f:
        return path, f.duration / av.time_base, voice


def main(project):
    beats = json.loads((project / "beats.json").read_text())
    ids = [b["id"] for b in beats]
    if len(set(ids)) != len(ids):
        sys.exit(f"beats.json repeats an id: {ids}")
    use_eleven, note = bool(os.environ.get("ELEVENLABS_API_KEY")), ""
    try:
        out, voice, measured = voice_all(beats, project, use_eleven)
    except Refused as e:
        note = f" (ElevenLabs refused the key: {e}; every clip voiced by Kokoro)"
        out, voice, measured = voice_all(beats, project, False)
    (project / "src" / "timeline.json").write_text(json.dumps({"fps": json.loads((project / "src" / "timeline.json").read_text()).get("fps", FPS) if (project / "src" / "timeline.json").exists() else FPS, "voice": voice, "beats": out}, indent=1) + "\n")
    (project / "src" / "words.json").write_text(json.dumps(measured) + "\n")
    words = sum(len(b["text"].split()) for b in beats)
    timed = "measured" if len(measured) == len(beats) else f"measured for {len(measured)} of {len(beats)} beats, estimated for the rest"
    print(f"voice: {voice}{note}, {len(out)} beats, {words} words, {sum(b['seconds'] for b in out):.1f}s of speech, word times {timed}")


def voice_all(beats, project, use_eleven):
    out, voice, measured = [], None, {}
    for b in beats:
        path, seconds, voice = speak(b["text"], project / "public" / "voice", use_eleven)
        out.append({"id": b["id"], "text": b["text"], "file": f"voice/{path.name}", "seconds": round(seconds, 3)})
        if words_file(path).exists():
            measured[b["id"]] = json.loads(words_file(path).read_text())
    return out, voice, measured


if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "."))
