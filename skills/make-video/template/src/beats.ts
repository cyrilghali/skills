import { Easing, interpolate } from "./frame";
import timeline from "./timeline.json";
import measured from "./words.json";

export const FPS = timeline.fps;
const LEAD_IN = 0.6;
export const GAP = 0.8;
const HOLD = 2.5;

// The silence before a beat gives the viewer time to take in what was just said: a question hangs
// for a moment, and a new chapter (the id prefix changes, "c2-" after "c1-") gets a longer breath.
const chapter = (id: string) => /^(c\d+|s)-/.exec(id)?.[1] ?? "";
const pauseAfter = (b: { id: string; text: string }, next: { id: string }) =>
  chapter(next.id) !== chapter(b.id) ? 2.4 : b.text.trim().endsWith("?") ? 1.6 : GAP;

export type Beat = { id: string; text: string; file: string; seconds: number; start: number; end: number };

let cursor = LEAD_IN;
export const BEATS: Record<string, Beat> = Object.fromEntries(
  timeline.beats.map((b, i) => {
    const beat = { ...b, start: cursor, end: cursor + b.seconds };
    const next = timeline.beats[i + 1];
    cursor += b.seconds + (next ? pauseAfter(b, next) : 0);
    return [b.id, beat];
  }),
);
export const DURATION = Math.ceil((cursor + HOLD) * FPS);

/** Seconds of silence just before beat `id` starts. */
export const pause = (id: string) => {
  const ids = Object.keys(BEATS);
  const i = ids.indexOf(id);
  return i > 0 ? BEATS[id].start - BEATS[ids[i - 1]].end : LEAD_IN;
};

const ease = Easing.bezier(0.22, 1, 0.36, 1);
const easeInOut = Easing.bezier(0.65, 0, 0.35, 1);

/** 0 → 1 over `dur` seconds, starting `delay` seconds into beat `id`. */
export const at = (t: number, id: string, delay = 0, dur = 0.9) => ramp(t, id, delay, dur, ease);

/** Like at(), but eases in as well as out: for an object already at rest that travels to a new place. */
export const move = (t: number, id: string, delay = 0, dur = 0.9) => ramp(t, id, delay, dur, easeInOut);

const ramp = (t: number, id: string, delay: number, dur: number, easing: (x: number) => number) => {
  if (!BEATS[id]) throw new Error(`Unknown beat "${id}"; beats are: ${Object.keys(BEATS).join(", ")}`);
  return interpolate(t, [BEATS[id].start + delay, BEATS[id].start + delay + dur], [0, 1], {
    easing,
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
};

/**
 * Seconds into beat `id` when its narration starts saying `phrase`.
 * at(t, "step1", word("step1", "thirty four")) starts a move as the voice says it.
 * Uses the measured word times in words.json (from the voice service, or aligned by speech recognition);
 * otherwise estimates from the phrase's position in the text (within about 0.1 s typical, 0.3 s worst).
 */
export const word = (id: string, phrase: string) => {
  const beat = BEATS[id];
  if (!beat) throw new Error(`Unknown beat "${id}"; beats are: ${Object.keys(BEATS).join(", ")}`);
  const t = find(beat, phrase);
  if (t === undefined) throw new Error(`Beat "${id}" never says "${phrase}"${(measured as unknown as Record<string, unknown>)[id] ? " in its measured words" : ""}: ${beat.text}`);
  return t;
};

/** Seconds into the video when the narration first says `phrase`, by the same matching as word(); undefined when no beat says it. */
export const said = (phrase: string) => {
  for (const beat of Object.values(BEATS)) {
    const t = find(beat, phrase);
    if (t !== undefined) return beat.start + t;
  }
};

// Whole words, lowercased and stripped of punctuation (accents kept, as the voice script keeps them), each with where
// it starts in the text; the measured words in words.json are stored the same way, so a phrase matches either source
// word for word.
const tokens = (text: string) => [...text.matchAll(/\S+/g)].map((m) => ({ w: m[0].toLowerCase().replace(/[^\p{L}\p{N}']/gu, ""), i: m.index })).filter((t) => t.w);

const find = (beat: Beat, phrase: string) => {
  const want = tokens(phrase).map((t) => t.w);
  const measuredWords = (measured as unknown as Record<string, [string, number][]>)[beat.id];
  const words = measuredWords
    ? measuredWords.map(([w, t]) => ({ w, t }))
    : tokens(beat.text).map(({ w, i }) => ({ w, t: (beat.seconds * spoken(beat.text.slice(0, i))) / spoken(beat.text) }));
  const k = words.findIndex((_, i) => want.every((w, j) => words[i + j]?.w === w));
  return k < 0 ? undefined : words[k].t;
};

// Characters are not spoken at an even pace: a spelled-out acronym like HTTPS takes about
// three characters' time per letter, and a sentence end pauses for about eight.
const spoken = (text: string) =>
  text.length + 2 * (text.match(/\b[A-Z]{2,}\b/g) ?? []).join("").length + 7 * (text.match(/[.!?] /g) ?? []).length;

/** The few words the voice is saying at `t`, by the same estimate as word(); "(silence)" between beats. */
export const saying = (t: number) => {
  const beat = Object.values(BEATS).find((b) => t >= b.start && t <= b.end);
  if (!beat) return "(silence)";
  const target = ((t - beat.start) / beat.seconds) * spoken(beat.text);
  const starts = [...beat.text.matchAll(/\S+/g)].map((m) => m.index ?? 0);
  let i = 0;
  while (i + 1 < starts.length && spoken(beat.text.slice(0, starts[i + 1])) <= target) i++;
  return beat.text.slice(starts[i]).split(/\s+/).slice(0, 4).join(" ");
};

export const mix = (p: number, a: number, b: number) => a + (b - a) * p;

/** Apply moves in order: chain(1, [[at(t, "zoom"), 2], [at(t, "back"), 1]]) goes 1 → 2 → 1. */
export const chain = (start: number, steps: [number, number][]) => steps.reduce((v, [p, target]) => mix(p, v, target), start);
