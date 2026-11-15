// SALVAGE INK: the Wasteland Academy house look for explainer clips. Classic script; load after lib/stage.js.
// It is the "Ink and Toon" kit from styles/ink-toon.reference.js with the Salvage Neon Bazaar palette
// (assets/style-guide/README.md), the game's fonts (Bangers, Share Tech Mono) and a dark print finish:
// charcoal margin, teal ruled panel, dust-paper tooth. Every clip builds its objects with this kit, so
// change the look here and nowhere else.
// Globals: INK, PAPER, MARGIN, PAL, FONTS, inkKit(S, opts).
const INK = '#0a0d14', PAPER = '#f3e6c4', MARGIN = '#0c1118';
// Each colour has a hand-picked shadow partner, shifted towards the cool charcoal ground.
const PAL = {
  ground: { lit: '#263242', shade: '#151c28', deep: '#090d14' },
  groundDot: { lit: '#2f3e52', shade: '#151c28', deep: '#090d14' },
  slate: { lit: '#1a2330', shade: '#10161f', deep: '#090d14' },
  teal: { lit: '#22d3c5', shade: '#12807f', gloss: '#d6fffa' },
  magenta: { lit: '#ff3da7', shade: '#a31f7c', gloss: '#ffd0ea' },
  mint: { lit: '#9ff0e6', shade: '#58a9ab' },
  rust: { lit: '#faa261', shade: '#b35a3c', gloss: '#ffe2c6' },
  dust: { lit: '#eacb74', shade: '#a98a4c', gloss: '#fff4cf' },
  spark: { lit: '#f2b630', shade: '#b06c26', gloss: '#fff1c4' },
  concrete: { lit: '#9ca3af', shade: '#566073', gloss: '#e8ecf2' },
  iron: { lit: '#4a5568', shade: '#2a3242', gloss: '#aab6cc' },
  paper: { lit: '#f3e6c4', shade: '#a9b0a8' },
};
const FONTS = ['260px "Bangers"', '130px "Share Tech Mono"'];
function inkKit(S, o = {}) {
  const { THREE, K } = S, px = S.H / 1080;
  const G = { res: { value: new THREE.Vector2(S.W, S.H) }, light: { value: new THREE.Vector3(0, 1, 0) }, up: { value: new THREE.Vector3(0, 1, 0) }, seed: { value: 0 }, pitch: { value: (o.pitch || 11) * px } };
  const srgb = (hex) => new THREE.Vector3(parseInt(hex.slice(1, 3), 16) / 255, parseInt(hex.slice(3, 5), 16) / 255, parseInt(hex.slice(5, 7), 16) / 255);

  // One hard sun. Its direction is the "hand-placed shadow shape": low and from the side gives big readable shadows.
  const sun = K.sun(S, { pos: o.sun || [-6.2, 6.2, 4.8], target: o.sunTarget || [0.3, 1, 0], power: Math.PI, size: o.sunSize || 6.5, mapSize: 4096, normalBias: 0.03 });

  // FILL. MeshToonMaterial with a plain 0..1 ramp as its gradient map, so three.js hands us one number per pixel:
  // how lit it is (half-Lambert times the cast shadow). The patch turns that number into print: lit colour, shadow
  // colour, a band of halftone dots where light turns into shadow, optional hatching inside the shadow, and a
  // hard-edged highlight (a round glint, or a vertical streak down turned shapes).
  const ramp = new THREE.DataTexture(new Uint8Array(1024).map((_, i) => (i % 4 === 3 ? 255 : i >> 2)), 256, 1);
  ramp.minFilter = ramp.magFilter = THREE.LinearFilter; ramp.needsUpdate = true;
  const FILL_PARS = `
    uniform vec3 uLit, uShade, uDeep, uGloss, uUp; uniform float uThr, uBand, uPitch, uHatch, uGlossSize, uStreak;`;
  const FILL_MAIN = `{
    float v = outgoingLight.r;                                            // 0 = in shadow, 1 = facing the light
    float k = clamp((v - uThr) / max(uBand, 1e-4), 0.0, 1.0);             // 0 at the shadow edge, 1 in full light
    vec2 g = mat2(0.819, 0.574, -0.574, 0.819) * gl_FragCoord.xy / uPitch;   // dot screen, turned 35 degrees, fixed to the page
    float rad = 0.74 * (1.0 - k), aa = 0.8 / uPitch;                      // dots grow until they merge into solid shadow
    float tone = v < uThr ? 1.0 : (1.0 - smoothstep(rad - aa, rad + aa, length(fract(g) - 0.5))) * step(k, 0.999);
    vec3 c = mix(uLit, uShade, tone);
    if (uHatch > 0.0) {                                                   // pen hatching inside the shadow
      float sp = uPitch * 1.3, h = abs(fract((gl_FragCoord.x + gl_FragCoord.y) / sp) - 0.5) * sp;
      float lw = uHatch * (0.75 + 0.5 * sin(gl_FragCoord.x * 0.011 - gl_FragCoord.y * 0.017));
      c = mix(c, uDeep, (1.0 - smoothstep(lw - 0.7, lw + 0.7, h)) * step(v, uThr));
    }
    #if NUM_DIR_LIGHTS > 0
      vec3 hv = normalize(directionalLights[0].direction + normalize(vViewPosition));
      float lit = step(uThr + uBand, v);
      if (uGlossSize > 0.0) c = mix(c, uGloss, step(1.0 - uGlossSize, dot(normal, hv)) * lit);
      if (uStreak > 0.0) {                                                // the long glint down a turned shape
        float ny = dot(normal, uUp); vec3 nh = normalize(normal - uUp * ny), hh = normalize(hv - uUp * dot(hv, uUp));
        c = mix(c, uGloss, step(1.0 - uStreak, dot(nh, hh)) * step(abs(ny), 0.55) * lit);
      }
    #endif
    outgoingLight = c;
  }`;
  function fill(c, f = {}) {
    const m = new THREE.MeshToonMaterial({ color: '#ffffff', gradientMap: ramp, side: f.side || THREE.FrontSide });
    const u = m.userData.u = { uLit: { value: new THREE.Color(c.lit) }, uShade: { value: new THREE.Color(c.shade) }, uDeep: { value: new THREE.Color(c.deep || c.shade) }, uGloss: { value: new THREE.Color(c.gloss || '#ffffff') },
      uUp: G.up, uPitch: G.pitch, uThr: { value: f.thr == null ? 0.56 : f.thr }, uBand: { value: f.band == null ? 0.1 : f.band }, uHatch: { value: (f.hatch || 0) * px }, uGlossSize: { value: f.gloss || 0 }, uStreak: { value: f.streak || 0 } };
    m.onBeforeCompile = (sh) => {
      Object.assign(sh.uniforms, u);
      sh.fragmentShader = sh.fragmentShader.replace('#include <common>', '#include <common>\n' + FILL_PARS).replace('#include <opaque_fragment>', FILL_MAIN + '\n#include <opaque_fragment>');
    };
    return m;
  }

  // OUTLINE: the inverted hull. A back-faced copy of the mesh in ink, pushed outwards along its normals by a number
  // of screen pixels. The push is not even: it swells on the side away from the light, thins towards the light and
  // wavers along the form, like a brush line. Needs smooth normals (turned, rounded and tube shapes all have them).
  function hull(width, color) {
    return new THREE.ShaderMaterial({
      side: THREE.BackSide,
      uniforms: { uRes: G.res, uLight: G.light, uSeed: G.seed, uWidth: { value: width * px }, uColor: { value: new THREE.Color(color) } },
      vertexShader: `uniform vec2 uRes; uniform vec3 uLight; uniform float uWidth, uSeed;
        void main() {
          vec4 mv = modelViewMatrix * vec4(position, 1.0);
          vec3 n = normalize(normalMatrix * normal);
          float waver = 0.6 * sin(dot(position, vec3(7.1, 5.3, 6.7)) + uSeed * 2.1) + 0.4 * sin(dot(position, vec3(-17.3, 12.9, 15.1)) + uSeed * 5.3);
          float w = uWidth * (1.0 + 0.3 * waver) * mix(0.55, 1.45, smoothstep(-0.6, 0.8, -dot(n, uLight)));
          // surfaces that face the ground come a little towards the lens, so the line survives where a prop stands on it
          mv.xyz *= 1.0 - 0.006 * smoothstep(0.85, 1.0, -normalize(mat3(modelMatrix) * normal).y);
          gl_Position = projectionMatrix * mv;
          gl_Position.xy += n.xy / max(length(n.xy), 0.35) * w * 2.0 / uRes * gl_Position.w;
        }`,
      fragmentShader: 'uniform vec3 uColor; void main() { gl_FragColor = vec4(uColor, 1.0); }',
    });
  }
  const outline = (mesh, width = 4.2, color = INK) => { const h = new THREE.Mesh(mesh.geometry, hull(width, color)); h.frustumCulled = false; mesh.add(h); return mesh; };
  // a filled, outlined, shadow-casting solid: the basic building block
  const solid = (geo, mat, parent, f = {}) => { const m = new THREE.Mesh(geo, mat); m.castShadow = f.cast !== false; m.receiveShadow = true; if (f.line !== 0) outline(m, f.line); if (parent) parent.add(m); return m; };

  const flat = (color) => new THREE.MeshBasicMaterial({ color, side: THREE.DoubleSide });
  // INNER LINES: a thin ink line round a turned shape at height y, drawn only part of the way (angles in degrees,
  // 0 = right, 90 = towards the camera) so it breaks off on the lit side. Thinner than the outline on purpose.
  const crease = (parent, r, y, a0 = -70, a1 = 105, w = 0.0085) => { const n = 28, pts = Array.from({ length: n + 1 }, (_, i) => { const a = (a0 + (a1 - a0) * i / n) * Math.PI / 180; return [Math.cos(a) * r, y, Math.sin(a) * r]; });
    const m = new THREE.Mesh(K.tube(pts, w, { segments: 56, radial: 5 }), flat(INK)); parent.add(m); return m; };

  // TURNED SHAPES: a profile of [radius, height] points, corners softened, spun round the axis. Draw the profile from
  // the bottom of the axis, out, up the outside, over the lip and back down the inside, so the shape is closed.
  const soften = (pts, n = 2) => { for (; n > 0; n--) { const q = [pts[0]]; for (let i = 0; i < pts.length - 1; i++) { const a = pts[i], b = pts[i + 1]; q.push([a[0] * 0.75 + b[0] * 0.25, a[1] * 0.75 + b[1] * 0.25], [a[0] * 0.25 + b[0] * 0.75, a[1] * 0.25 + b[1] * 0.75]); } q.push(pts[pts.length - 1]); pts = q; } return pts; };
  const turned = (pts, seg = 64, n = 2) => new THREE.LatheGeometry(soften(pts, n).map(([r, y]) => new THREE.Vector2(r, y)), seg);

  // MARKS: brush strokes as flat geometry (speed lines, impact bursts, steam, arrows). strokes([[points, width,
  // taper], ...]) -> one geometry in the XY plane; taper 'both' | 'head' | 'tail' | 'none' thins the ends like a brush.
  function strokes(list, grow = 0) {
    const pos = [], idx = [];
    for (let [pts, w, taper = 'both'] of list) {
      while (pts.length < 5) pts = pts.flatMap((p, i) => (i ? [[(p[0] + pts[i - 1][0]) / 2, (p[1] + pts[i - 1][1]) / 2], p] : [p]));   // short strokes need points to taper over
      const n = pts.length, base = pos.length / 3;
      for (let i = 0; i < n; i++) {
        const a = pts[Math.max(0, i - 1)], b = pts[Math.min(n - 1, i + 1)], dx = b[0] - a[0], dy = b[1] - a[1], l = Math.hypot(dx, dy) || 1, u = i / (n - 1);
        const k = taper === 'both' ? Math.pow(Math.sin(Math.PI * u), 0.5) : taper === 'head' ? Math.pow(1 - u, 0.6) : taper === 'tail' ? Math.pow(u, 0.6) : 1;
        const hw = (w * k + grow * Math.min(1, k * 3)) / 2;
        pos.push(pts[i][0] - dy / l * hw, pts[i][1] + dx / l * hw, 0, pts[i][0] + dy / l * hw, pts[i][1] - dx / l * hw, 0);
        if (i < n - 1) idx.push(base + 2 * i, base + 2 * i + 1, base + 2 * i + 2, base + 2 * i + 1, base + 2 * i + 3, base + 2 * i + 2);
      }
    }
    const g = new THREE.BufferGeometry(); g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3)); g.setIndex(idx); return g;
  }
      // an ink mark, or (with a colour) a coloured mark with an ink edge
  function mark(list, color, edge = 0.03) {
    const g = new THREE.Group();
    if (!color) { g.add(new THREE.Mesh(strokes(list), flat(INK))); return g; }
    g.add(new THREE.Mesh(strokes(list, edge * 2), flat(INK)));
    const top = new THREE.Mesh(strokes(list), flat(color)); top.position.z = 0.004; g.add(top);
    return g;
  }
  const arc = (r, a0, a1, n = 24, ry = r) => Array.from({ length: n + 1 }, (_, i) => { const a = a0 + (a1 - a0) * i / n; return [Math.cos(a) * r, Math.sin(a) * ry]; });
  // radial impact ticks around an ellipse
  const burst = (n, rx, ry, len, w, seed = 1) => { const r = K.rng(seed); return Array.from({ length: n }, (_, i) => { const a = (i + r.range(-0.25, 0.25)) / n * Math.PI * 2, l = len * r.range(0.6, 1.25), c = Math.cos(a), s = Math.sin(a); return [[[c * rx, s * ry], [c * (rx + l * 0.5), s * (ry + l * 0.5)], [c * (rx + l), s * (ry + l)]], w, 'head']; }); };

  // LETTERING: display type drawn like a comic sound effect: slanted, cream face with a dot-screen fade, heavy ink
  // edge and a solid colour block behind it. Returns a flat mesh; `height` is the world height of a capital.
  function lettering(text, f = {}) {
    const fpx = 260, font = `${fpx}px "Bangers"`, sk = -0.13, dep = 26, lw = 30, pad = 54, ls = '10px';
    const m = document.createElement('canvas').getContext('2d'); m.font = font; m.letterSpacing = ls;
    const mt = m.measureText(text), asc = Math.ceil(mt.actualBoundingBoxAscent), W = Math.ceil(mt.width + pad * 2 + dep + asc * -sk), H = asc + pad * 2 + dep, x = pad, y = pad + asc;
    const prep = (c) => { c.font = font; c.letterSpacing = ls; c.lineJoin = 'round'; c.textBaseline = 'alphabetic'; c.setTransform(1, 0, sk, 1, -sk * y, 0); c.lineWidth = lw; c.strokeStyle = INK; };
    const tex = K.canvasTex(W, H, (ctx) => {
      prep(ctx);
      for (let k = dep; k >= 0; k -= 2) ctx.strokeText(text, x + k, y + k);                    // ink round the whole block
      ctx.fillStyle = f.block || PAL.magenta.lit; for (let k = dep; k > 0; k -= 1) ctx.fillText(text, x + k, y + k);   // the block
      ctx.strokeText(text, x, y); ctx.fillStyle = f.face || PAPER; ctx.fillText(text, x, y);   // the face
      const dots = document.createElement('canvas'); dots.width = W; dots.height = H; const d = dots.getContext('2d');   // dot-screen fade up from the baseline
      d.fillStyle = f.dots || PAL.teal.lit;
      for (let j = -2; j < H / 13 + 2; j++) for (let i = -2; i < W / 13 + 2; i++) { const cx = i * 15 + (j % 2) * 7.5, cy = j * 13, r = 9.4 * K.clamp((cy - (y - asc * 0.62)) / (asc * 0.6)); if (r > 0.5) { d.beginPath(); d.arc(cx, cy, r, 0, 7); d.fill(); } }
      prep(d); d.globalCompositeOperation = 'destination-in'; d.fillStyle = '#000'; d.fillText(text, x, y);
      ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.drawImage(dots, 0, 0);
    });
    const unit = (f.height || 0.6) / asc, mesh = new THREE.Mesh(new THREE.PlaneGeometry(W * unit, H * unit), new THREE.MeshBasicMaterial({ map: tex, transparent: true, depthWrite: false }));
    mesh.userData.size = [W * unit, H * unit]; return mesh;
  }
  // the step number in a starburst
  function badge(text, f = {}) {
    const tex = K.canvasTex(420, 420, (ctx) => {
      const r = K.rng(text + 'b'); ctx.translate(210, 210); ctx.lineJoin = 'round';
      ctx.beginPath(); for (let i = 0; i < 24; i++) { const a = i / 24 * Math.PI * 2, rr = (i % 2 ? 142 : 188) * r.range(0.95, 1.05); ctx.lineTo(Math.cos(a) * rr, Math.sin(a) * rr); } ctx.closePath();
      ctx.save(); ctx.translate(12, 14); ctx.fillStyle = INK; ctx.fill(); ctx.restore();
      ctx.fillStyle = f.color || PAL.dust.lit; ctx.fill(); ctx.lineWidth = 15; ctx.strokeStyle = INK; ctx.stroke();
      ctx.font = '230px "Bangers"'; ctx.textAlign = 'center'; ctx.textBaseline = 'alphabetic'; ctx.fillStyle = INK; ctx.fillText(text, 0, 84);
    });
    const s = f.height || 0.8; return new THREE.Mesh(new THREE.PlaneGeometry(s, s), new THREE.MeshBasicMaterial({ map: tex, transparent: true, depthWrite: false }));
  }
  // a caption box, as in a graphic novel: hand-written note on a slip of paper with an inked edge
  function caption(text, f = {}) {
    const fpx = 130, font = `${fpx}px "Share Tech Mono"`, m = document.createElement('canvas').getContext('2d'); m.font = font;
    const tw = Math.ceil(m.measureText(text).width), bw = tw + 110, bh = 190, W = bw + 60, H = bh + 60;
    const tex = K.canvasTex(W, H, (ctx) => {
      const r = K.rng(text), j = () => r.range(-7, 7), box = (dx, dy) => { ctx.beginPath(); ctx.moveTo(20 + dx + j(), 20 + dy + j()); ctx.lineTo(20 + bw + dx + j(), 20 + dy + j()); ctx.lineTo(20 + bw + dx + j(), 20 + bh + dy + j()); ctx.lineTo(20 + dx + j(), 20 + bh + dy + j()); ctx.closePath(); };
      ctx.lineJoin = 'round'; box(14, 16); ctx.fillStyle = INK; ctx.fill();
      box(0, 0); ctx.fillStyle = PAPER; ctx.fill(); ctx.lineWidth = 11; ctx.strokeStyle = INK; ctx.stroke();
      ctx.font = font; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillStyle = INK; ctx.fillText(text, 20 + bw / 2, 20 + bh / 2 + 6);
    });
    const unit = (f.height || 0.42) / bh, mesh = new THREE.Mesh(new THREE.PlaneGeometry(W * unit, H * unit), new THREE.MeshBasicMaterial({ map: tex, transparent: true, depthWrite: false }));
    mesh.userData.size = [W * unit, H * unit]; return mesh;
  }

  // PRINT FINISH: a filter over the finished picture. Edges wander by about a pixel and are "redrawn" a few times a
  // second (line boil), paper tooth and fibres multiply through the colour, tiny pinholes where ink did not take,
  // and a hand-ruled panel border with bare paper outside it.
  function print(f = {}) {
    return S.addFilter(`uniform vec3 uPaper, uInk, uMargin; uniform float uBoil, uBorder;
      float h21(vec2 p){ p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
      float vn(vec2 p){ vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f); return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
      void main(){
        float s = res.y / 1080.0; vec2 px = vUv * res; float b = floor(time * uBoil);
        vec2 w = (vec2(vn(px / (42.0 * s) + b * 7.31), vn(px / (42.0 * s) + 19.7 - b * 3.17)) - 0.5) * 3.0 * s;
        vec3 c = texture2D(tex, (px + w) / res).rgb;
        if (uBorder > 0.0) {
          vec2 q = abs(px + w * 1.6 - res * 0.5) - (res * 0.5 - (uBorder + 16.0) * s);
          float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - 16.0 * s, lw = (2.6 + 1.5 * vn(px / (120.0 * s))) * s;
          c = mix(c, uInk, 1.0 - smoothstep(lw - 0.8, lw + 0.8, abs(d)));
          c = mix(c, uMargin, smoothstep(lw - 0.6, lw + 0.8, d));
        }
        float tooth = 0.6 * vn(px / (1.8 * s)) + 0.4 * vn(px / (6.0 * s)), fibre = vn(px * vec2(0.03, 0.8) / s + 3.0);
        c *= mix(vec3(1.0), uPaper, 0.12) * (0.95 + 0.07 * tooth + 0.025 * fibre);
        c = mix(c, uPaper, 0.25 * step(0.9988, h21(floor(px / (2.0 * s)) + 5.0)));
        gl_FragColor = vec4(c, 1.0);
      }`, { uPaper: { value: srgb(PAPER) }, uInk: { value: srgb(PAL.teal.lit) }, uMargin: { value: srgb(MARGIN) }, uBoil: { value: f.boil == null ? 6 : f.boil }, uBorder: { value: f.border == null ? 26 : f.border } });
  }

  // call once per update(t), after the camera is placed: gives the outline and the fills the light and "up" in view space
  const frame = (t, camera) => {
    camera.updateMatrixWorld();
    G.light.value.copy(sun.position).sub(sun.target.position).normalize().transformDirection(camera.matrixWorldInverse);
    G.up.value.set(0, 1, 0).transformDirection(camera.matrixWorldInverse);
    G.seed.value = Math.floor(t * 6);
  };
  return { G, sun, fill, outline, solid, turned, crease, strokes, mark, arc, burst, lettering, badge, caption, print, frame, flat };
}
