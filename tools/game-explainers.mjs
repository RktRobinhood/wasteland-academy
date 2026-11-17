#!/usr/bin/env node
// ── GAME EXPLAINERS COPY ─────────────────────────────────────
// The Godot game can't read files outside game/, so the lesson player (#218, FAL-1088)
// reads a copy of the explainer scripts and the stock lines they share: every
// writing/explainers/ex.*.json, callbacks.json and reactions.json, byte for byte, in
// game/data/explainers/. The manifest and the style sheets stay behind.
//
//   node tools/game-explainers.mjs           print whether the copy is current
//   node tools/game-explainers.mjs --write   rewrite game/data/explainers/
//
// writing/explainers/ stays the single source. tests/unit/game-explainers.test.mjs fails
// when the copy is stale.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SRC = path.join(ROOT, 'writing/explainers');
export const OUT = path.join(ROOT, 'game/data/explainers');
const SHARED = ['callbacks.json', 'reactions.json'];

// The files to copy, by name: { name: text }.
export function build() {
  const out = {};
  for (const f of fs.readdirSync(SRC).sort()) {
    if ((f.startsWith('ex.') && f.endsWith('.json')) || SHARED.includes(f)) {
      out[f] = fs.readFileSync(path.join(SRC, f), 'utf8');
    }
  }
  return out;
}

// What the copy has now: { name: text }.
export function current() {
  const out = {};
  if (!fs.existsSync(OUT)) return out;
  for (const f of fs.readdirSync(OUT).sort()) if (f.endsWith('.json')) out[f] = fs.readFileSync(path.join(OUT, f), 'utf8');
  return out;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const want = build();
  const have = current();
  const same = JSON.stringify(want) === JSON.stringify(have);
  if (process.argv.includes('--write')) {
    fs.mkdirSync(OUT, { recursive: true });
    for (const f of Object.keys(have)) if (!(f in want)) fs.unlinkSync(path.join(OUT, f));
    for (const [f, text] of Object.entries(want)) fs.writeFileSync(path.join(OUT, f), text);
    console.log(`Wrote ${Object.keys(want).length} files to ${path.relative(ROOT, OUT)}/.`);
  } else {
    console.log(same ? 'game/data/explainers/ is current.' : 'game/data/explainers/ is stale: run with --write.');
    if (!same) process.exit(1);
  }
}
