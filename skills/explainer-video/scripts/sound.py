"""Synthesize the music bed and cue sounds into <project>/public/sound/, once.

Everything is generated from code, so the sounds carry no license. Files that already
exist are kept; delete them to regenerate.
"""

import sys
from pathlib import Path

import numpy as np
import soundfile

RATE = 44100
rng = np.random.default_rng(7)


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def reverb(x, seconds=2.2, mix=0.35):
    """Convolve with exponentially decaying noise: a cheap, smooth hall."""
    n = int(seconds * RATE)
    ir = rng.standard_normal(n) * np.exp(-np.linspace(0, 7, n))
    ir /= np.sqrt(np.sum(ir**2))
    size = len(x) + n
    wet = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x) + n]
    out = np.zeros(len(x) + n)
    out[: len(x)] += x * (1 - mix)
    return out + wet * mix


def lowpass(x, cutoff):
    spec = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), 1 / RATE)
    spec *= 1 / np.sqrt(1 + (freqs / cutoff) ** 4)
    return np.fft.irfft(spec, len(x))


def normalize(x, peak_db):
    return x / np.max(np.abs(x)) * 10 ** (peak_db / 20)


def music(seconds=64.0):
    """A slow, warm pad: four seventh chords, eight seconds each, crossfaded, looping cleanly."""
    chords = [[53, 57, 60, 64], [45, 52, 55, 60], [50, 53, 57, 64], [48, 55, 59, 64]]  # Fmaj7 Am7 Dm9 Cmaj7
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    out = np.zeros(n)
    span = seconds / len(chords)
    for k, chord in enumerate(chords):
        center = (k + 0.5) * span
        # Raised-cosine window one span and a half wide, wrapped so the loop has no seam.
        d = (t - center + seconds / 2) % seconds - seconds / 2
        env = np.where(np.abs(d) < 0.75 * span, 0.5 * (1 + np.cos(np.pi * d / (0.75 * span))), 0)
        for note in chord:
            f = hz(note)
            for detune in (-0.0015, 0.0015):
                ff = f * (1 + detune)
                tone = np.sin(2 * np.pi * ff * t) + 0.25 * np.sin(4 * np.pi * ff * t) + 0.08 * np.sin(6 * np.pi * ff * t)
                out += env * tone
    out *= 1 + 0.15 * np.sin(2 * np.pi * 0.07 * t)
    out = lowpass(out, 1800)
    wet = reverb(out, 3.0, 0.45)
    loop = wet[:n].copy()
    loop[: len(wet) - n] += wet[n:]  # fold the reverb tail back to the start so the loop is seamless
    return normalize(loop, -6)


def tick():
    d = 0.09
    t = np.arange(int(d * RATE)) / RATE
    x = (np.sin(2 * np.pi * 1568 * t) + 0.5 * np.sin(2 * np.pi * 2349 * t)) * np.exp(-t * 55)
    return normalize(reverb(x, 0.8, 0.25), -10)


def chime():
    d = 2.0
    t = np.arange(int(d * RATE)) / RATE
    x = sum(a * np.sin(2 * np.pi * f * t) * np.exp(-t * k) for f, a, k in [(880, 1, 2.5), (1320, 0.5, 3.5), (1760, 0.3, 4.5), (2640, 0.12, 6)])
    x *= np.minimum(1, t / 0.005)
    return normalize(reverb(x, 2.0, 0.35), -9)


def noise_band(n, low, high):
    spec = np.fft.rfft(rng.standard_normal(n))
    freqs = np.fft.rfftfreq(n, 1 / RATE)
    spec *= (freqs > low) & (freqs < high)
    return np.fft.irfft(spec, n)


def swell():
    d = 0.9
    n = int(d * RATE)
    t = np.arange(n) / RATE
    env = (t / d) ** 2.2 * np.exp(-np.maximum(0, t - 0.75 * d) * 30)
    return normalize(reverb(lowpass(noise_band(n, 200, 5000) * env, 2500), 1.2, 0.3), -12)


def whoosh():
    d = 0.6
    n = int(d * RATE)
    t = np.arange(n) / RATE
    env = np.sin(np.pi * t / d) ** 2
    sweep = np.concatenate([noise_band(n // 4, lo, lo * 4) for lo in (300, 600, 1000, 600)])
    sweep = np.pad(sweep, (0, n - len(sweep)))
    return normalize(reverb(sweep * env, 0.9, 0.3), -12)


SOUNDS = {"music": music, "tick": tick, "chime": chime, "swell": swell, "whoosh": whoosh}


def main(project):
    out = project / "public" / "sound"
    out.mkdir(parents=True, exist_ok=True)
    for name, make in SOUNDS.items():
        path = out / f"{name}.wav"
        if not path.exists():
            soundfile.write(path, make().astype(np.float32), RATE)


if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "."))
