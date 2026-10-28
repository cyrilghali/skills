import { createContext, useContext } from "react";

/** The frame being drawn and the renderer's text measure (the width in pixels of a one-line SVG <text> element). */
export const FrameContext = createContext<{ n: number; measure: (svgText: string) => number }>({ n: 0, measure: () => 0 });

export const useCurrentFrame = () => useContext(FrameContext).n;
export const useMeasure = () => useContext(FrameContext).measure;

type Extrapolate = "clamp" | "extend" | "identity";

/** Rejects a bad range with the same words as Remotion, so a typo fails loudly instead of drawing NaN. */
const check = (input: number, inRange: readonly number[], outRange: readonly number[]) => {
  if (input === undefined) throw new Error("input can not be undefined");
  if (inRange === undefined) throw new Error("inputRange can not be undefined");
  if (outRange === undefined) throw new Error("outputRange can not be undefined");
  if (inRange.length !== outRange.length)
    throw new Error(`inputRange (${inRange.length}) and outputRange (${outRange.length}) must have the same length`);
  for (const [name, range] of [["inputRange", inRange], ["outputRange", outRange]] as const) {
    if (range.length < 1) throw new Error(`${name} must have at least 1 element`);
    for (const v of range) {
      if (typeof v !== "number") throw new Error(`${name} must contain only numbers`);
      if (!Number.isFinite(v)) throw new Error(`${name} must contain only finite numbers, but got [${range.join(",")}]`);
    }
  }
  for (let i = 1; i < inRange.length; i++)
    if (!(inRange[i] > inRange[i - 1])) throw new Error(`inputRange must be strictly monotonically increasing but got [${inRange.join(",")}]`);
  if (typeof input !== "number") throw new TypeError("Cannot interpolate an input which is not a number");
};

/** Maps `input` from `inRange` to `outRange`, piece by piece; past the ends it extends, clamps or returns the input. */
export const interpolate = (
  input: number,
  inRange: readonly number[],
  outRange: readonly number[],
  opts: { easing?: (x: number) => number; extrapolateLeft?: Extrapolate; extrapolateRight?: Extrapolate } = {},
) => {
  check(input, inRange, outRange);
  const { easing = (x: number) => x, extrapolateLeft = "extend", extrapolateRight = "extend" } = opts;
  if (inRange.length === 1) return outRange[0];
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
  if (!(x1 >= 0 && x1 <= 1 && x2 >= 0 && x2 <= 1)) throw new Error("bezier x values must be in [0, 1] range");
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
