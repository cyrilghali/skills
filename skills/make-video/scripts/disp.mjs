// The ink wobble without resvg's per-frame feTurbulence. The noise depends only on the filter's seed, so each
// seed's destination-to-source pixel index is built once and every frame is displaced by a gather.

/** Builds the index from the rendered noise, with resvg's feDisplacementMap rule (nearest pixel, f32 maths). */
export function buildIndex(noise, w, h, scale, out) {
  for (let y = 0, i = 0; y < h; y++)
    for (let x = 0; x < w; x++, i++) {
      const ox = Math.round(Math.fround(x + Math.fround(Math.fround(Math.fround(noise[i * 4] / 255) - 0.5) * scale)));
      const oy = Math.round(Math.fround(y + Math.fround(Math.fround(Math.fround(noise[i * 4 + 1] / 255) - 0.5) * scale)));
      // resvg leaves a pixel taken from outside the frame transparent, which shows the paper under the ink;
      // the nearest edge pixel is that paper.
      out[i] = Math.min(h - 1, Math.max(0, oy)) * w + Math.min(w - 1, Math.max(0, ox));
    }
}

export function displace(src32, idx, dst32) {
  for (let i = 0; i < idx.length; i++) dst32[i] = src32[idx[i]];
}

/** Premultiplied RGBA `layer` over `dst`, in place. */
export function overlay(dst, layer) {
  for (let i = 0; i < dst.length; i += 4) {
    const a = layer[i + 3];
    if (a === 0) continue;
    const k = 255 - a;
    dst[i] = layer[i] + (((dst[i] * k + 127) / 255) | 0);
    dst[i + 1] = layer[i + 1] + (((dst[i + 1] * k + 127) / 255) | 0);
    dst[i + 2] = layer[i + 2] + (((dst[i + 2] * k + 127) / 255) | 0);
    dst[i + 3] = a + (((dst[i + 3] * k + 127) / 255) | 0);
  }
}

/**
 * Splits a frame at the group with filter="url(#ink)": `scene` is everything up to the end of that group with
 * the filter removed, `over` is everything after it plus the frame's <defs>, and `turbulence` and `scale` are
 * the filter's. Returns null when the frame has no ink group, or more than one, so it renders as it is.
 */
export function splitInk(doc) {
  const at = doc.indexOf('filter="url(#ink)"');
  if (at < 0 || doc.indexOf('filter="url(#ink)"', at + 1) >= 0) return null;
  const filter = /<filter id="ink"[\s\S]*?<\/filter>/.exec(doc)?.[0];
  const turbulence = filter && /<feTurbulence[^>]*?(\/>|><\/feTurbulence>)/.exec(filter)?.[0];
  const scale = filter && Number(/<feDisplacementMap[^>]*\bscale="([\d.]+)"/.exec(filter)?.[1]);
  if (!turbulence || !scale) return null;
  const start = doc.lastIndexOf("<", at);
  const tag = /<(\/?)([\w:-]+)[^>]*?(\/?)>/g;
  const open = [];
  for (let m; (m = tag.exec(doc)) && m.index < start; ) {
    if (m[1]) open.pop();
    else if (!m[3]) open.push(m[0]);
  }
  let depth = 0;
  let end = start;
  tag.lastIndex = start;
  for (let m; (m = tag.exec(doc)); ) {
    if (m[1]) depth--;
    else if (!m[3]) depth++;
    if (depth === 0) {
      end = tag.lastIndex;
      break;
    }
  }
  const close = open.map((t) => `</${/<([\w:-]+)/.exec(t)[1]}>`).reverse().join("");
  // Without the ink filter, whose seed changes with every boil, the text layer repeats while the words hold.
  const defs = (doc.slice(0, start).match(/<defs>[\s\S]*?<\/defs>/g) ?? []).join("").replace(filter, "");
  const scene = doc.slice(0, start) + doc.slice(start, end).replace(' filter="url(#ink)"', "") + close;
  const over = open[0] + defs + open.slice(1).join("") + doc.slice(end);
  return { scene, over, turbulence, scale };
}

/** The filter's noise alone, for buildIndex. */
export const noiseSvg = (turbulence, w, h) =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><filter id="n" x="0" y="0" width="${w}" height="${h}" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">${turbulence.replace(/\s*result="[^"]*"/, "")}</filter><rect width="${w}" height="${h}" filter="url(#n)"/></svg>`;
