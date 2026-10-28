// resvg 2.6 clamps the layer of a group with opacity, a clip, a mask or a filter to the box from -2 to +3 canvases
// and panics, killing the process, when the group lies wholly outside it. The camera's world puts shapes there
// routinely, so each frame drops such elements first. A frame or more away from the canvas, they draw nothing.

const NOT_DRAWN = new Set(["defs", "clipPath", "mask", "pattern", "marker", "symbol", "filter", "linearGradient", "radialGradient"]);

/** Parses React's static markup into a light tree: tag name, attribute string, and where each element starts and ends. */
const tree = (svg) => {
  const root = { children: [], end: svg.length };
  const stack = [root];
  for (const m of svg.matchAll(/<(\/?)([A-Za-z][\w:-]*)([^>]*?)(\/?)>/g)) {
    if (m[1]) {
      stack.pop().end = m.index + m[0].length;
      continue;
    }
    const node = { name: m[2], attrs: m[3], start: m.index, open: m[0], children: [], end: m.index + m[0].length };
    stack.at(-1).children.push(node);
    if (!m[4]) stack.push(node);
  }
  return root;
};

const attr = (attrs, name) => attrs.match(new RegExp(`\\s${name}="([^"]*)"`))?.[1];

export function farCull({ Resvg, font, width: W, height: H }) {
  const boxes = new Map();
  const box = (markup) => {
    if (boxes.size > 4000) boxes.clear();
    if (!boxes.has(markup)) {
      const doc = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${markup}</svg>`;
      boxes.set(markup, new Resvg(doc, { font: markup.includes("<text") ? font : { loadSystemFonts: false } }).getBBox() ?? null);
    }
    return boxes.get(markup);
  };
  const near = (b) => b && b.x < 2 * W && b.x + b.width > -W && b.y < 2 * H && b.y + b.height > -H;

  return (svg) => {
    if (!/\s(opacity|filter|clip-path|mask)="|opacity:/.test(svg)) return svg;
    // A filter with its region in user space gets a layer the size of that region, wherever its content sits.
    const spaceFilters = new Set([...svg.matchAll(/<filter\b[^>]*>/g)].filter((m) => m[0].includes('filterUnits="userSpaceOnUse"')).map((m) => attr(m[0], "id")));
    const drop = [];
    const visit = (node, wraps) => {
      for (const el of node.children) {
        if (NOT_DRAWN.has(el.name)) continue;
        const a = el.attrs;
        const opacity = Number(attr(a, "opacity") ?? a.match(/[\s";]opacity:\s*([^;"]+)/)?.[1] ?? 1);
        const filter = attr(a, "filter")?.match(/url\(#([^)]+)\)/)?.[1];
        const layered = opacity < 1 || (filter && !spaceFilters.has(filter)) || / (clip-path|mask)="/.test(a);
        if (opacity === 0) {
          drop.push(el);
          continue;
        }
        if (layered) {
          // Only geometry counts: paint servers and effects are swapped out so the box needs no <defs>.
          const bare = svg.slice(el.start, el.end).replace(/ (clip-path|mask|filter)="[^"]*"/g, "").replace(/="url\([^)]*\)"/g, '="#000"');
          if (!near(box(wraps.join("") + bare + "</g>".repeat(wraps.length)))) {
            drop.push(el);
            continue;
          }
        }
        const t = attr(a, "transform");
        visit(el, el.name === "svg" ? [...wraps, `<g transform="${nestedTransform(a, W, H)}">`] : t ? [...wraps, `<g transform="${t}">`] : wraps);
      }
    };
    visit(tree(svg).children[0], []);
    if (!drop.length) return svg;
    let out = "";
    let at = 0;
    for (const el of drop) {
      out += svg.slice(at, el.start);
      at = el.end;
    }
    return out + svg.slice(at);
  };
}

/** The user-space transform a nested <svg> applies: its x/y offset and, with a viewBox, the scale to its size. */
const nestedTransform = (a, W, H) => {
  const x = Number(attr(a, "x") ?? 0);
  const y = Number(attr(a, "y") ?? 0);
  const vb = attr(a, "viewBox")?.trim().split(/[\s,]+/).map(Number);
  if (!vb) return `translate(${x} ${y})`;
  const w = Number(attr(a, "width") ?? W);
  const h = Number(attr(a, "height") ?? H);
  const s = Math.min(w / vb[2], h / vb[3]);
  return `translate(${x} ${y}) scale(${s}) translate(${-vb[0]} ${-vb[1]})`;
};
