// The layout check over one frame's SVG: text that crosses a shape's edge, overlaps other text or an icon,
// or sits on texture without a paper backing, and anything cut by the frame edge. Each marked element is
// measured alone by resvg, under its ancestors' transforms; anything wholly outside the frame is off camera.

const GEOMETRY = new Set(["path", "rect", "circle", "ellipse", "line", "polyline", "polygon"]);

export function layoutCheck({ Resvg, DOMParser, XMLSerializer, font, width: W = 1920, height: H = 1080 }) {
  const xml = new XMLSerializer();
  const bare = { font: { loadSystemFonts: false } };
  const frame = { x0: 0, y0: 0, x1: W, y1: H };
  const overlaps = (a, b, eps = 2) => Math.min(a.x1, b.x1) - Math.max(a.x0, b.x0) > eps && Math.min(a.y1, b.y1) - Math.max(a.y0, b.y0) > eps;
  const inside = (a, b) => a.x0 >= b.x0 && a.y0 >= b.y0 && a.x1 <= b.x1 && a.y1 <= b.y1;
  const off = (b) => b.x0 < -2 || b.y0 < -2 || b.x1 > W + 2 || b.y1 > H + 2;
  const elements = (el) => Array.from(el.childNodes).filter((n) => n.nodeType === 1);
  const descendants = (el) => elements(el).flatMap((c) => [c, ...descendants(c)]);
  const contains = (a, b) => {
    for (let e = b; e; e = e.parentNode) if (e === a) return true;
    return false;
  };
  const opacityOf = (e) => {
    const css = /(?:^|;)\s*opacity:\s*([^;]+)/.exec(e.getAttribute("style") ?? "")?.[1];
    return Number(e.getAttribute("opacity") || 1) * Number(css ?? 1);
  };
  const effectiveOpacity = (el) => {
    let o = 1;
    for (let e = el; e && e.nodeType === 1; e = e.parentNode) o *= opacityOf(e);
    return o;
  };

  // The element's markup inside its ancestors' transforms, with the frame's <defs>, as a document of its own.
  const alone = (doc, el, markup) => {
    let s = markup;
    for (let e = el.parentNode; e && e.nodeType === 1; e = e.parentNode) {
      const t = e.getAttribute("transform");
      if (t) s = `<g transform="${t}">${s}</g>`;
    }
    const defs = Array.from(doc.getElementsByTagName("defs")).map((d) => xml.serializeToString(d)).join("");
    return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}">${defs}${s}</svg>`;
  };
  const toBox = (r) => r && { x0: r.x, y0: r.y, x1: r.x + r.width, y1: r.y + r.height };
  // Most marked elements hold still for many frames, so a measured document is remembered.
  const memo = new Map();
  const remember = (key, f) => {
    if (!memo.has(key)) {
      if (memo.size > 2000) memo.clear();
      memo.set(key, f());
    }
    return memo.get(key);
  };

  // A shape counts by its painted geometry; an outline drawn with no paint (Hatch's texture mark) gets a fill
  // so it still has a box. resvg's box ignores clip paths, so clipped parts (hatch strokes) are left out when
  // anything else is drawn. `solid` also strips opacity, for the fill sample.
  const painted = (el, solid) => {
    const c = el.cloneNode(true);
    const clipped = descendants(c).filter((e) => e.hasAttribute("clip-path") || e.tagName === "clipPath");
    const free = descendants(c).filter((e) => GEOMETRY.has(e.tagName) && !clipped.some((k) => contains(k, e)));
    if (!solid && free.length > 0) for (const e of clipped) if (e.parentNode) e.parentNode.removeChild(e);
    for (const e of [c, ...descendants(c)]) {
      if (solid) e.removeAttribute("opacity");
      if (GEOMETRY.has(e.tagName) && (e.getAttribute("fill") ?? "") === "none" && (e.getAttribute("stroke") ?? "none") === "none") e.setAttribute("fill", "#000");
      if (solid && GEOMETRY.has(e.tagName)) {
        e.setAttribute("fill", "#000");
        if ((e.getAttribute("stroke") ?? "none") !== "none") e.setAttribute("stroke", "#000");
      }
    }
    return xml.serializeToString(c);
  };
  const shapeBox = (doc, el) => {
    const svg = alone(doc, el, painted(el, false));
    const b = remember(svg, () => toBox(new Resvg(svg, bare).getBBox()));
    if (!b) return undefined;
    const half = 3; // A straight line has a zero-height box; give it a stroke's thickness.
    const pad = (lo, hi) => (hi - lo < 2 * half ? [lo - half, hi + half] : [lo, hi]);
    const [x0, x1] = pad(b.x0, b.x1);
    const [y0, y1] = pad(b.y0, b.y1);
    return { x0, y0, x1, y1 };
  };
  // The box of the words, the untyped rest included, without the paper backing.
  const textBox = (doc, el) => {
    const texts = el.tagName === "text" ? [el] : Array.from(el.getElementsByTagName("text"));
    const markup = texts
      .map((t) => {
        let s = xml.serializeToString(t).replace(/ fill-opacity="0"/g, "");
        for (let e = t.parentNode; e && e !== el.parentNode; e = e.parentNode) {
          const tr = e.getAttribute("transform");
          if (tr) s = `<g transform="${tr}">${s}</g>`;
        }
        return s;
      })
      .join("");
    const svg = alone(doc, el, markup);
    return remember(svg, () => toBox(new Resvg(svg, { font }).getBBox()));
  };

  // The share of a 13 x 5 grid over the text box that lands on the shape's fill or stroke; undefined for a
  // group or a flat shape, which are judged by their box.
  const fillShare = (doc, s, b) => {
    if (!GEOMETRY.has(s.tagName)) return undefined;
    const r = toBox(new Resvg(alone(doc, s, painted(s, false)), bare).getBBox());
    if (!r || r.x1 - r.x0 < 6 || r.y1 - r.y0 < 6) return undefined;
    const k = 4;
    const img = new Resvg(alone(doc, s, painted(s, true)), { ...bare, fitTo: { mode: "zoom", value: 1 / k } }).render();
    let hits = 0;
    let total = 0;
    for (let i = 0; i <= 12; i++)
      for (let j = 0; j <= 4; j++) {
        const x = Math.floor((b.x0 + ((b.x1 - b.x0) * i) / 12) / k);
        const y = Math.floor((b.y0 + ((b.y1 - b.y0) * j) / 4) / k);
        total++;
        if (x >= 0 && y >= 0 && x < img.width && y < img.height && img.pixels[(y * img.width + x) * 4 + 3] > 0) hits++;
      }
    return hits / total;
  };

  const quote = (el) => JSON.stringify((el.textContent ?? "").trim().slice(0, 30));
  const name = (el) => el.getAttribute("data-name") || el.tagName;
  const parse = (svg) => new DOMParser().parseFromString(svg, "image/svg+xml");
  const marked = (doc, kind) => Array.from(doc.getElementsByTagName("*")).filter((e) => e.getAttribute("data-layout") === kind);

  /** The visible texts in frame, for the SHOWN: lines. */
  const shown = (svg) => {
    const doc = parse(svg);
    return marked(doc, "text")
      .filter((el) => effectiveOpacity(el) > 0.5)
      .filter((el) => {
        const b = textBox(doc, el);
        return b && overlaps(b, frame, 0);
      })
      .map(quote);
  };

  const problems = (svg) => {
    const doc = parse(svg);
    // Anything a viewer can still make out counts; only near-invisible elements are skipped.
    const measured = (kind, box) =>
      marked(doc, kind)
        .filter((el) => effectiveOpacity(el) > 0.02)
        .map((el) => ({ el, b: box(doc, el) }))
        .filter((x) => x.b && overlaps(x.b, frame, 0));
    const texts = measured("text", textBox);
    const shapes = measured("shape", shapeBox);
    const icons = measured("icon", shapeBox);
    const textures = measured("texture", shapeBox);
    const out = [];
    for (const s of [...shapes, ...icons]) if (off(s.b)) out.push(`shape "${name(s.el)}" leaves the frame`);
    texts.forEach((t, i) => {
      if (off(t.b)) out.push(`${quote(t.el)} leaves the frame`);
      for (const o of texts.slice(i + 1)) if (overlaps(t.b, o.b)) out.push(`${quote(t.el)} overlaps ${quote(o.el)}`);
      for (const s of shapes) {
        if (contains(s.el, t.el) || contains(t.el, s.el) || !overlaps(t.b, s.b)) continue;
        const share = fillShare(doc, s.el, t.b);
        if (share === undefined ? !inside(t.b, s.b) && !inside(s.b, t.b) : share > 0 && share < 1) out.push(`${quote(t.el)} crosses the edge of shape "${name(s.el)}"`);
      }
      for (const c of icons) if (overlaps(t.b, c.b)) out.push(`${quote(t.el)} overlaps icon "${name(c.el)}"`);
      if (!t.el.hasAttribute("data-backed"))
        for (const x of textures) {
          if (!overlaps(t.b, x.b)) continue;
          const share = fillShare(doc, x.el, t.b);
          if (share === undefined || share > 0) out.push(`${quote(t.el)} sits on texture "${name(x.el)}" without a paper backing`);
        }
    });
    return [...new Set(out)];
  };

  return { problems, shown };
}
