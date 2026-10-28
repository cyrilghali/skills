// Usage: node render.mjs <project> textures <out-dir>
//        node render.mjs <project> video <scale> <finish-dir> <out.mp4>
//        node render.mjs <project> still <frame> <scale> <finish-dir> <out.png>
// Renders src/Explainer.tsx to SVG with React, rasterizes each frame with resvg on worker threads, and streams the
// frames in order into one ffmpeg that multiplies the baked paper, vignette and grain over them. Prints each
// LAYOUT: and SHOWN: line once to stderr; `video` also writes out/audio.json for scripts/mix.py and
// out/beats.txt (each beat's end time, one per line) for scripts/frames.sh.
import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { once } from "node:events";
import { existsSync, mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { availableParallelism, homedir } from "node:os";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { isMainThread, parentPort, Worker, workerData } from "node:worker_threads";
import { farCull } from "./cull.mjs";
import { buildIndex, displace, noiseSvg, overlay, splitInk } from "./disp.mjs";
import { layoutCheck } from "./layout.mjs";

const W = 1920;
const H = 1080;
const { project, scale, bundle } = isMainThread ? { project: resolve(process.argv[2]), scale: 1 } : workerData;
const req = createRequire(join(project, "package.json"));
const { Resvg, renderAsync } = req("@resvg/resvg-js");
const { DOMParser, XMLSerializer } = req("@xmldom/xmldom");

const fontDir = join(process.env.EXPLAINER_CACHE || join(homedir(), ".cache/make-video"), "fonts");
const fontFiles = existsSync(fontDir) ? readdirSync(fontDir).filter((f) => f.endsWith(".ttf")) : [];
const fail = (message) => {
  console.error(message);
  process.exit(1);
};
if (!fontFiles.length) fail(`no fonts in ${fontDir}; run scripts/setup.sh`);
const font = { loadSystemFonts: false, fontFiles: fontFiles.map((f) => join(fontDir, f)) };
// Loading the font files costs about 6 ms, so a document without text skips them.
const options = (s, svg) => ({ font: svg.includes("<text") ? font : { loadSystemFonts: false }, fitTo: s === 1 ? { mode: "original" } : { mode: "width", value: Math.round(W * s) } });
// Attribute numbers keep three decimals: a thousandth of a pixel never shows, and the tail of an easing then
// settles into frames equal to the next, which are drawn once. Text is left as written.
const round = (attr) => attr.replace(/\d+\.\d{4,}/g, (m) => String(Number(Number(m).toFixed(3))));
// resvg 2.6 panics when a group that needs its own layer (opacity, filter) has nothing inside a nested <svg>'s
// viewport. A nested <svg> the size of the frame clips to the canvas anyway, so it becomes a plain <g>.
const frameSvg = new RegExp(`^<svg width="${W}" height="${H}"(?: style="[^"]*")?>$`);
const unnest = (markup) => {
  const open = [];
  return markup.replace(/<svg\b[^>]*?(\/?)>|<\/svg>/g, (tag, selfClosing) => {
    if (tag === "</svg>") return open.pop() ? "</g>" : tag;
    if (selfClosing) return tag;
    open.push(frameSvg.test(tag));
    return open.at(-1) ? "<g>" : tag;
  });
};
const doc = (markup) => `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${unnest(markup).replace(/="[^"]*"/g, round)}</svg>`;

const widths = new Map();
const cull = farCull({ Resvg, font, width: W, height: H });
const measure = (text) => {
  if (!widths.has(text)) widths.set(text, new Resvg(doc(text.replace("<text", '<text x="0" y="500"')), { font }).getBBox()?.width ?? 0);
  return widths.get(text);
};
const frameDoc = (scene, n) => cull(doc(scene.frame(n, measure)));

// Ink displacement indexes, one per noise (one per boil seed), shared by every worker.
const indexes = new Map();
const layers = new Map();

/** One frame's premultiplied RGBA pixels at `s`. */
const raster = (svg, s) => {
  const ink = splitInk(svg);
  if (!ink) return Buffer.from(new Resvg(svg, options(s, svg)).render().pixels);
  const scene = new Resvg(ink.scene, options(s, ink.scene)).render();
  const out = new Uint32Array(scene.width * scene.height);
  displace(new Uint32Array(scene.pixels.buffer, scene.pixels.byteOffset, out.length), indexFor(ink, s, scene.width, scene.height), out);
  const pixels = Buffer.from(out.buffer);
  if (!layers.has(ink.over)) {
    if (layers.size > 3) layers.delete(layers.keys().next().value);
    layers.set(ink.over, new Resvg(ink.over, options(s, ink.over)).render().pixels);
  }
  overlay(pixels, layers.get(ink.over));
  return pixels;
};

const indexFor = (ink, s, w, h) => {
  const key = ink.turbulence + ink.scale;
  if (!indexes.has(key)) {
    const idx = new Int32Array(new SharedArrayBuffer(w * h * 4));
    const noise = noiseSvg(ink.turbulence, W, H);
    buildIndex(new Resvg(noise, options(s, noise)).render().pixels, w, h, ink.scale * s, idx);
    indexes.set(key, idx);
  }
  return indexes.get(key);
};

// resvg draws SVG only, so an HTML element in the scene would silently disappear.
const htmlTag = /<(div|span|p|img|h[1-6]|ul|ol|li|table|button|section|pre|code|br|b|i|em|strong|sub|sup|foreignObject)\b/g;
const htmlLines = (svg) => [...new Set([...svg.matchAll(htmlTag)].map((m) => m[1]))].map((t) => `LAYOUT: <${t}> draws nothing: the render draws SVG only, so draw it with <text>, <rect> or a kit component`);

/** The frame each beat ends on, and the last frame, as frame number -> beat number. */
const endFrames = (scene) => new Map([...Object.values(scene.BEATS).map((b, i) => [Math.round(b.end * scene.FPS), i + 1]), [scene.DURATION - 1, Object.keys(scene.BEATS).length]]);

const probeFrames = (scene) => {
  const ends = endFrames(scene);
  const every = Math.round(scene.FPS / 10);
  const check = layoutCheck({ Resvg, DOMParser, XMLSerializer, font, width: W, height: H });
  return (n, svg) => {
    const t = n / scene.FPS;
    const lines = htmlLines(svg);
    if (n % every === 0) for (const q of check.shown(svg)) lines.push(`SHOWN: ${t.toFixed(1)}s ${q} as the voice says "${scene.saying(t)}"`);
    const beat = ends.get(n);
    if (beat !== undefined) {
      for (const p of check.problems(svg)) lines.push(`LAYOUT: beat ${beat} (${t.toFixed(1)}s): ${p}`);
    }
    return lines;
  };
};

if (!isMainThread) {
  const scene = await import(pathToFileURL(bundle).href);
  const probe = probeFrames(scene);
  parentPort.on("message", (m) => {
    if (m.scan) {
      const out = [];
      for (let n = m.scan[0]; n < m.scan[1]; n++) {
        const svg = frameDoc(scene, n);
        const ink = splitInk(svg);
        out.push({ hash: createHash("sha1").update(svg).digest("hex"), noise: ink && { turbulence: ink.turbulence, scale: ink.scale }, lines: probe(n, svg) });
      }
      parentPort.postMessage(out);
    } else if (m.indexes) {
      for (const [k, v] of m.indexes) indexes.set(k, new Int32Array(v));
      parentPort.postMessage(true);
    } else if (m.noise) {
      parentPort.postMessage([m.noise.turbulence + m.noise.scale, indexFor(m.noise, scale, Math.round(W * scale), Math.round(H * scale)).buffer]);
    } else {
      const px = raster(frameDoc(scene, m.frame), scale);
      const ab = px.buffer.slice(px.byteOffset, px.byteOffset + px.length);
      parentPort.postMessage(ab, [ab]);
    }
  });
} else {
  const mode = process.argv[3];
  const { build } = req("esbuild");
  mkdirSync(join(project, "out"), { recursive: true });
  const bundlePath = join(project, "out", ".scene.mjs");
  await build({
    stdin: {
      resolveDir: project,
      loader: "tsx",
      contents: `import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { Explainer } from "./src/Explainer";
import { FrameContext } from "./src/frame";
import { GrainTexture, PaperTexture } from "./src/look";
export { sound } from "./src/Explainer";
export { BEATS, DURATION, FPS, saying } from "./src/beats";
export { hand, mono } from "./src/theme";
export const frame = (n, measure) => renderToStaticMarkup(createElement(FrameContext.Provider, { value: { n, measure } }, createElement(Explainer)));
export const paper = () => renderToStaticMarkup(createElement(PaperTexture));
export const grain = (seed) => renderToStaticMarkup(createElement(GrainTexture, { seed }));`,
    },
    bundle: true,
    format: "esm",
    platform: "node",
    jsx: "automatic",
    define: { "process.env.NODE_ENV": '"production"' },
    banner: { js: 'import { createRequire } from "node:module"; const require = createRequire(import.meta.url);' },
    outfile: bundlePath,
    logLevel: "error",
  });
  const scene = await import(pathToFileURL(bundlePath).href);
  const fps = scene.FPS;
  // resvg quietly draws a missing family in another font, so each family the theme names needs a file named after it.
  for (const family of [scene.hand, scene.mono])
    if (!fontFiles.some((f) => f.startsWith(family.replaceAll(" ", ""))))
      fail(`no fonts in ${fontDir} for "${family}"; run scripts/setup.sh, or add a .ttf whose name starts with ${family.replaceAll(" ", "")}`);

  // An ffmpeg that gets no frame never ends (blend waits for its first pair while the grain loops), so a render
  // that dies takes its encoders with it.
  const encoders = new Set();
  const stopEncoders = () => encoders.forEach((ff) => ff.kill("SIGKILL"));
  process.on("exit", stopEncoders);
  for (const [signal, code] of [["SIGINT", 130], ["SIGTERM", 143]]) process.on(signal, () => process.exit(code));
  process.on("uncaughtException", (e) => fail(e.stack ?? String(e)));
  process.on("unhandledRejection", (e) => fail(e?.stack ?? String(e)));

  /** Pipes raw RGBA frames through the finish multiply (`paper`, an ffmpeg input) into `out`. */
  const encoder = (s, paper, out, extra) => {
    const [w, h] = [Math.round(W * s), Math.round(H * s)];
    const ff = spawn(
      "ffmpeg",
      ["-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgba", "-s", `${w}x${h}`, "-r", String(fps), "-i", "-",
        ...paper,
        "-filter_complex", "[0:v]format=gbrp[a];[1:v]format=gbrp[b];[a][b]blend=all_mode=multiply:shortest=1[v]", "-map", "[v]", ...extra, out],
      { stdio: ["pipe", "inherit", "inherit"] },
    );
    ff.stdin.on("error", () => {});
    encoders.add(ff);
    ff.on("close", () => encoders.delete(ff));
    return ff;
  };

  if (mode === "textures") {
    const dir = process.argv[4];
    mkdirSync(dir, { recursive: true });
    const jobs = [[scene.paper(), "paper.png"], ...[0, 1, 2, 3, 4, 5].map((i) => [scene.grain(i), `grain-${i}.png`])];
    await Promise.all(jobs.map(async ([svg, name]) => writeFileSync(join(dir, name), (await renderAsync(doc(svg), options(1, svg))).asPng())));
  } else if (mode === "still") {
    const [n, s, finish, out] = [Number(process.argv[4]), Number(process.argv[5]), process.argv[6], process.argv[7]];
    const svg = frameDoc(scene, n);
    const ff = encoder(s, ["-i", join(finish, `f${String(n % fps).padStart(3, "0")}.png`)], out, ["-frames:v", "1"]);
    ff.stdin.end(raster(svg, s));
    await once(ff, "close");
    const check = layoutCheck({ Resvg, DOMParser, XMLSerializer, font, width: W, height: H });
    for (const l of htmlLines(svg)) console.error(l);
    for (const p of check.problems(svg)) console.error(`LAYOUT: frame ${n} (${(n / fps).toFixed(1)}s): ${p}`);
  } else if (mode === "video") {
    const [s, finish, out] = [Number(process.argv[4]), process.argv[5], process.argv[6]];
    const total = scene.DURATION;

    const voice = Object.values(scene.BEATS).map((b) => ({ file: b.file, start: b.start, end: b.end }));
    const { music, cues: wanted = [] } = scene.sound ?? {};
    const cues = wanted.map(({ beat, delay = 0, sound, volume = 0.5 }) => {
      if (!scene.BEATS[beat]) throw new Error(`Unknown beat "${beat}"`);
      return { file: `sound/${sound}.wav`, start: scene.BEATS[beat].start + delay, volume };
    });
    writeFileSync(join(project, "out", "audio.json"), JSON.stringify({ duration: total / fps, fps, voice, cues, music }, null, 1) + "\n");
    const beatTimes = [...endFrames(scene).keys()].sort((a, b) => a - b).map((n) => (n / fps).toFixed(2));
    writeFileSync(join(project, "out", "beats.txt"), beatTimes.join("\n") + "\n");

    const workers = Array.from(
      { length: Number(process.env.EXPLAINER_WORKERS) || availableParallelism() },
      () => new Worker(new URL(import.meta.url), { workerData: { project, scale: s, bundle: bundlePath } }),
    );
    const ask = (w, msg) =>
      new Promise((res, rej) => {
        const done = (f) => (v) => {
          w.off("message", ok);
          w.off("error", bad);
          f(v);
        };
        const ok = done(res);
        const bad = done(rej);
        w.on("message", ok);
        w.on("error", bad);
        w.postMessage(msg);
      });
    const pool = async (items, job) => {
      let next = 0;
      await Promise.all(workers.map(async (w) => { while (next < items.length) await job(w, items[next++]); }));
    };

    // Pass 1: every frame's SVG is hashed and probed, in parallel. Equal SVGs draw equal frames: a hold
    // repeats the boil's 12 seeds, so most of its frames are drawn once.
    const scans = new Array(total);
    const chunks = Array.from({ length: Math.ceil(total / 16) }, (_, i) => [i * 16, Math.min(total, i * 16 + 16)]);
    await pool(chunks, async (w, c) => (await ask(w, { scan: c })).forEach((r, i) => (scans[c[0] + i] = r)));
    // A LAYOUT: line prints once; a SHOWN: line once per text, ignoring digits so a running counter counts once.
    const printed = new Set();
    const lines = scans.flatMap((r) => r.lines);
    for (const l of [...lines.filter((l) => l.startsWith("LAYOUT:")), ...lines.filter((l) => l.startsWith("SHOWN:"))]) {
      const key = l.startsWith("SHOWN:") ? "SHOWN:" + l.split('"')[1].replace(/[0-9.]/g, "") : l;
      if (!printed.has(key)) console.error(l);
      printed.add(key);
    }
    const first = new Map();
    const lastUse = new Map();
    scans.forEach((r, n) => {
      if (!first.has(r.hash)) first.set(r.hash, n);
      lastUse.set(r.hash, n);
    });

    // Pass 2: each boil seed's displacement index, built once, then shared with every worker.
    const noises = [...new Map(scans.filter((r) => r.noise).map((r) => [r.noise.turbulence + r.noise.scale, r.noise])).values()];
    const built = [];
    await pool(noises, async (w, noise) => built.push(await ask(w, { noise })));
    await Promise.all(workers.map((w) => ask(w, { indexes: built })));

    // Pass 3: unique frames rendered in parallel and written in order, each kept until its last repeat.
    const ff = encoder(s, ["-stream_loop", String(Math.ceil(total / fps)), "-framerate", String(fps), "-i", join(finish, "f%03d.png")], out, ["-c:v", "libx264", "-crf", "18", "-pix_fmt", "yuv420p", "-an"]);
    const digest = createHash("sha1");
    const ready = new Map();
    let emitted = 0;
    const waiting = [];
    const emit = async () => {
      while (emitted < total && ready.has(scans[emitted].hash)) {
        const { hash } = scans[emitted];
        const buf = ready.get(hash);
        if (lastUse.get(hash) === emitted) ready.delete(hash);
        digest.update(buf);
        if (!ff.stdin.write(buf)) await once(ff.stdin, "drain");
        emitted++;
      }
      waiting.splice(0).forEach((f) => f());
    };
    const frames = [...first.values()];
    let emitting = Promise.resolve();
    await pool(frames, async (w, n) => {
      while (n > emitted + 4 * workers.length) await new Promise((r) => waiting.push(r));
      ready.set(scans[n].hash, Buffer.from(await ask(w, { frame: n })));
      emitting = emitting.then(emit);
    });
    await emitting;
    ff.stdin.end();
    const [code] = await once(ff, "close");
    await Promise.all(workers.map((w) => w.terminate()));
    if (code !== 0) throw new Error(`ffmpeg exited with ${code}`);
    console.log(`frames: ${total} (${frames.length} drawn), sha1 ${digest.digest("hex")}`);
  } else {
    throw new Error(`unknown mode ${mode}`);
  }
}
