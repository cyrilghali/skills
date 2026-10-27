/** What scripts/render.mjs sets before it renders a frame, and what the scene registers while it renders. */
export type Sound = { file: string; start: number; end?: number; volume?: number };

export const engine = {
  frame: 0,
  /** Width in pixels of a one-line SVG <text> element, measured by resvg. */
  measure: (_text: string): number => 0,
  ids: 0,
  voice: [] as Sound[],
  cues: [] as Sound[],
  music: undefined as number | undefined,
};

export const useCurrentFrame = () => engine.frame;

/** A frame-unique id for a clip path or filter. */
export const uid = (prefix: string) => `${prefix}-${engine.ids++}`;

type Extrapolate = "clamp" | "extend" | "identity";

/** Maps `input` from `inRange` to `outRange`, piece by piece; past the ends it extends, clamps or returns the input. */
export const interpolate = (
  input: number,
  inRange: readonly number[],
  outRange: readonly number[],
  opts: { easing?: (x: number) => number; extrapolateLeft?: Extrapolate; extrapolateRight?: Extrapolate } = {},
) => {
  const { easing = (x: number) => x, extrapolateLeft = "extend", extrapolateRight = "extend" } = opts;
  let i = 1;
  while (i < inRange.length - 1 && inRange[i] < input) i++;
  const [a, b] = [inRange[i - 1], inRange[i]];
  const [lo, hi] = [outRange[i - 1], outRange[i]];
  let x = input;
  if (x < a) {
    if (extrapolateLeft === "identity") return x;
    if (extrapolateLeft === "clamp") x = a;
  }
  if (x > b) {
    if (extrapolateRight === "identity") return x;
    if (extrapolateRight === "clamp") x = b;
  }
  if (lo === hi) return lo;
  return easing((x - a) / (b - a)) * (hi - lo) + lo;
};

const mulberry32 = (a: number) => {
  let t = a + 0x6d2b79f5;
  t = Math.imul(t ^ (t >>> 15), t | 1);
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};

/** The same seed gives the same number in [0, 1), so hatching keeps its jitter between renders. Scenes were tuned
 * against these exact values, so the hash and generator must not change. */
export const random = (seed: string | number) => {
  if (typeof seed === "number") return mulberry32(seed * 10000000000);
  let h = 0;
  for (let i = 0; i < seed.length; i++) h = ((h << 5) - h + seed.charCodeAt(i)) | 0;
  return mulberry32(h);
};

// Cubic bezier easing from React Native's Animated (MIT License, Copyright (c) Meta Platforms, Inc. and
// affiliates).
const A = (a1: number, a2: number) => 1 - 3 * a2 + 3 * a1;
const B = (a1: number, a2: number) => 3 * a2 - 6 * a1;
const C = (a1: number) => 3 * a1;
const calc = (t: number, a1: number, a2: number) => ((A(a1, a2) * t + B(a1, a2)) * t + C(a1)) * t;
const slope = (t: number, a1: number, a2: number) => 3 * A(a1, a2) * t * t + 2 * B(a1, a2) * t + C(a1);

const bezier = (x1: number, y1: number, x2: number, y2: number) => {
  const size = 11;
  const step = 1 / (size - 1);
  const samples = new Float32Array(size);
  for (let i = 0; i < size; i++) samples[i] = calc(i * step, x1, x2);
  const tForX = (x: number) => {
    let start = 0;
    let k = 1;
    for (; k !== size - 1 && samples[k] <= x; ++k) start += step;
    --k;
    let t = start + ((x - samples[k]) / (samples[k + 1] - samples[k])) * step;
    const s = slope(t, x1, x2);
    if (s >= 0.001) {
      for (let i = 0; i < 4; i++) {
        const sl = slope(t, x1, x2);
        if (sl === 0) return t;
        t -= (calc(t, x1, x2) - x) / sl;
      }
      return t;
    }
    if (s === 0) return t;
    let lo = start;
    let hi = start + step;
    let i = 0;
    let cur: number;
    do {
      t = lo + (hi - lo) / 2;
      cur = calc(t, x1, x2) - x;
      if (cur > 0) hi = t;
      else lo = t;
    } while (Math.abs(cur) > 1e-7 && ++i < 10);
    return t;
  };
  return (x: number) => {
    const c = Math.min(1, Math.max(0, x));
    if (x1 === y1 && x2 === y2) return c;
    if (c === 0 || c === 1) return c;
    return calc(tForX(c), y1, y2);
  };
};

export const Easing = { bezier, linear: (x: number) => x };
