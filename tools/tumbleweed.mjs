#!/usr/bin/env node
// ── TUMBLEWEED FRAMES ────────────────────────────────────────
// Builds the overworld's tumbleweed (FAL-373) as a 3D tangle of curling
// stems and spiky twigs, then draws it from the map's camera, one frame per
// step of a roll, side by side in one SVG strip. css/screens.css steps
// through the frames, so near twigs sweep downwind while the ones behind,
// seen through the gaps, sweep back.
//
//   node tools/tumbleweed.mjs           print whether the file is up to date
//   node tools/tumbleweed.mjs --write   rewrite assets/map/tumbleweed.svg
//
// The tangle is seeded, so the output only changes when this file does.
// tests/unit/tumbleweed.test.mjs fails when the SVG is stale.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const OUT = path.join(ROOT, 'assets/map/tumbleweed.svg');

export const FRAMES = 32;            // one full turn; css/screens.css steps through this many
const SIZE = 100;                    // each frame is SIZE × SIZE, ball centred
const RADIUS = 36;                   // ball radius, in frame units
const GROUND = 79;                   // where the ball touches the sand, in frame units from the top
const CAMERA = 42 * Math.PI / 180;   // the overworld art looks down at about this angle
const SEED = 373;

// Darkest (deep inside, facing away from the sun) to lightest (sunlit, near side)
const SHADES = [
  { stroke: '#33241a', width: 2.4, opacity: 0.85 },
  { stroke: '#56402c', width: 2.6, opacity: 0.95 },
  { stroke: '#7f6544', width: 2.8, opacity: 1 },
  { stroke: '#b39a70', width: 3.0, opacity: 1 },
];

// ── Vectors and a seeded random ──
const add = (a, b) => a.map((v, i) => v + b[i]);
const scale = (a, k) => a.map(v => v * k);
const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const cross = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
const len = a => Math.hypot(...a);
const unit = a => scale(a, 1 / len(a));
// Rodrigues: v turned by angle t about the unit axis k
const turn = (v, k, t) => add(add(scale(v, Math.cos(t)), scale(cross(k, v), Math.sin(t))), scale(k, dot(k, v) * (1 - Math.cos(t))));

function mulberry32(a) {
  return () => {
    a |= 0; a = a + 0x6D2B79F5 | 0;
    let t = Math.imul(a ^ a >>> 15, 1 | a);
    t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
    return ((t ^ t >>> 14) >>> 0) / 4294967296;
  };
}
let rand;
const between = (lo, hi) => lo + (hi - lo) * rand();
const randomUnit = () => {
  const z = between(-1, 1), a = between(0, 2 * Math.PI), r = Math.sqrt(1 - z * z);
  return [r * Math.cos(a), z, r * Math.sin(a)];
};
const perpendicular = d => unit(cross(d, randomUnit()));

// ── The tangle, in a unit ball, drawn frame by frame ──
export function build() {
  rand = mulberry32(SEED);
  // A lumpy, slightly squat outline, so the roll bobs and the silhouette shifts
  const LUMPS = Array.from({ length: 5 }, () => ({ dir: randomUnit(), amp: between(0.04, 0.09) }));
  const SQUASH = [1, 0.86, 0.94];
  function envelope(p) {
    const d = unit(p);
    const lumps = LUMPS.reduce((s, l) => s + l.amp * Math.cos(2.4 * Math.acos(Math.max(-1, Math.min(1, dot(d, l.dir))))), 0);
    const e = 1 / Math.hypot(d[0] / SQUASH[0], d[1] / SQUASH[1], d[2] / SQUASH[2]);
    return e * (1 + lumps);
  }

  const stems = [];   // each a list of points
  const STEP = 0.15;

  // A stem grows in arcs: outward from the crown, then curling along the
  // surface. Side branches fork off it, and every tip ends in a spike that
  // pokes past the outline.
  function grow(start, dir, steps, depth) {
    const pts = [start];
    let p = start, d = dir;
    const bendAxis = perpendicular(d);
    const curve = between(0.16, 0.4) * (rand() < 0.5 ? -1 : 1);
    for (let i = 0; i < steps; i++) {
      d = unit(turn(d, bendAxis, curve + between(-0.3, 0.3)));
      const r = len(p), env = envelope(p);
      if (r > 0.6 * env) {
        const radial = scale(p, 1 / r), out = dot(d, radial);
        if (out > 0) d = unit(add(d, scale(radial, -out * Math.min(1, r / env))));
      }
      p = add(p, scale(d, STEP * between(0.8, 1.2)));
      const env2 = envelope(p);
      if (len(p) > env2) p = scale(unit(p), env2);
      pts.push(p);
      if (depth < 2 && i > 1 && rand() < (depth ? 0.2 : 0.3)) {
        const fork = unit(turn(d, perpendicular(d), between(0.5, 1.0) * (rand() < 0.5 ? -1 : 1)));
        grow(p, fork, Math.round(steps * between(0.3, 0.5)), depth + 1);
      }
    }
    // The spike: short, nearly straight, past the outline
    const tip = add(p, scale(unit(add(scale(unit(p), 0.8), scale(d, 0.6))), between(0.06, 0.16)));
    pts.push(tip);
    stems.push(pts);
  }

  for (let i = 0; i < 9; i++) {
    grow([between(-0.06, 0.06), between(-0.12, -0.04), between(-0.06, 0.06)], randomUnit(), Math.round(between(9, 13)), 0);
  }
  // Loose spiky twigs on the outside, the ragged edge you see first
  for (let i = 0; i < 16; i++) {
    const n = randomUnit(), at = scale(n, envelope(n) * between(0.82, 0.98));
    const d = unit(add(scale(n, between(0.4, 1)), scale(perpendicular(n), between(-0.7, 0.7))));
    stems.push([at, add(at, scale(d, between(0.1, 0.22)))]);
  }

  // ── Draw it from the camera, one frame per step of the roll ──
  // World axes: x downwind (screen right), y up, z toward the viewer. The roll
  // turns the ball about z (tipped a touch, so it wobbles), top going downwind.
  const ROLL_AXIS = unit([0, 0.12, 1]);
  // Sun from the upper left, as in the art
  const SUN = unit([-0.6, 0.75, 0.3]);
  // A random starting attitude, so the squash isn't lined up with the axes
  const START = { axis: randomUnit(), angle: between(0, 2 * Math.PI) };

  // Screen position, and depth toward the viewer (-1 far side .. 1 near side)
  const project = p => ({ x: p[0], up: p[1] * Math.cos(CAMERA) - p[2] * Math.sin(CAMERA), depth: p[1] * Math.sin(CAMERA) + p[2] * Math.cos(CAMERA) });

  function shadeOf(p) {
    const near = (project(p).depth + 1) / 2;   // 0 far side .. 1 near side
    const lit = Math.max(0, dot(unit(p), SUN));
    const s = 0.55 * near + 0.45 * lit * (0.4 + 0.6 * len(p));
    return Math.max(0, Math.min(SHADES.length - 1, Math.floor(s * SHADES.length * 1.05)));
  }

  const runs = SHADES.map(() => []);   // per shade: polylines of [x, y] in strip units
  for (let f = 0; f < FRAMES; f++) {
    const angle = -2 * Math.PI * f / FRAMES;
    const placed = stems.map(s => s.map(p => turn(turn(p, START.axis, START.angle), ROLL_AXIS, angle)));
    // Rest the lowest twig on the ground, so a lumpy ball bobs as it rolls
    const lowest = Math.min(...placed.flat().map(p => p[1]));
    const cy = GROUND + lowest * Math.cos(CAMERA) * RADIUS;
    const cx = f * SIZE + SIZE / 2;
    const toStrip = p => { const q = project(p); return [Math.round(cx + q.x * RADIUS), Math.round(cy - q.up * RADIUS)]; };
    for (const pts of placed) {
      let current = null, currentShade = -1;
      for (let i = 1; i < pts.length; i++) {
        const s = shadeOf(scale(add(pts[i - 1], pts[i]), 0.5));
        if (s !== currentShade) {
          current = [toStrip(pts[i - 1])];
          runs[s].push(current);
          currentShade = s;
        }
        current.push(toStrip(pts[i]));
      }
    }
  }

  // Absolute moves, then relative lines from rounded points, so nothing drifts
  const append = (out, v) => out + (v < 0 || out.endsWith('l') ? '' : ' ') + v;
  function pathData(polylines) {
    let out = '';
    for (const line of polylines) {
      const pts = line.filter((p, i) => i === 0 || p[0] !== line[i - 1][0] || p[1] !== line[i - 1][1]);
      if (pts.length < 2) continue;
      out += `M${pts[0][0]} ${pts[0][1]}l`;
      for (let i = 1; i < pts.length; i++) {
        out = append(out, pts[i][0] - pts[i - 1][0]);
        out = append(out, pts[i][1] - pts[i - 1][1]);
      }
    }
    return out;
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${FRAMES * SIZE} ${SIZE}" width="${FRAMES * SIZE}" height="${SIZE}" fill="none" stroke-linecap="round" stroke-linejoin="round">
<!-- The overworld tumbleweed, ${FRAMES} frames of one turn. Made by tools/tumbleweed.mjs: change that, not this. -->
${SHADES.map((s, i) => `<path stroke="${s.stroke}" stroke-width="${s.width}"${s.opacity < 1 ? ` stroke-opacity="${s.opacity}"` : ''} d="${pathData(runs[i])}"/>`).join('\n')}
</svg>
`;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const next = build();
  if (process.argv.includes('--write')) {
    fs.writeFileSync(OUT, next);
    console.log(`wrote ${path.relative(ROOT, OUT)}: ${FRAMES} frames, ${(next.length / 1024).toFixed(1)} KB`);
  } else {
    const now = fs.existsSync(OUT) ? fs.readFileSync(OUT, 'utf8') : '';
    console.log(now === next ? 'assets/map/tumbleweed.svg is up to date' : 'assets/map/tumbleweed.svg is out of date: run with --write');
    process.exit(now === next ? 0 : 1);
  }
}
