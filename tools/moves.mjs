#!/usr/bin/env node
// ── EXPLAINER MOVES CHECK ────────────────────────────────────
// Checks curriculum/moves.json (the move list Spark voices in explainers) and
// curriculum/moves-map.json (the move for every worked step of every built method),
// FAL-425. With an export from game/tools/export_questions.gd it also checks the
// map against the engine's real step counts and measures coverage.
//
//   node tools/moves.mjs                        check both files (same as --check)
//   node tools/moves.mjs --check                check only
//   node tools/moves.mjs --coverage <q.json>    check, then every exported solution
//                                               must be in the map; print coverage
//
// Make the export with (see curriculum/README.md, "Explainer moves"):
//   godot --headless --path game --script res://tools/export_questions.gd -- \
//     --out=/abs/questions.json --per-cell=1 --per-type=1
//
// Exit 1 on any error.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const readJSON = f => JSON.parse(fs.readFileSync(path.isAbsolute(f) ? f : path.join(ROOT, f), 'utf8'));

const ID = /^[a-z][a-z0-9]*(-[a-z0-9]+)*$/;
// A say line is spoken over every question that uses the move, so it can't carry a
// number or anything the board shows. Number words count as numbers.
const NUMBER_WORDS = /\b(zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|hundred|thousand|half|halves|twice|double|triple|third|quarter)\b/i;
const SYMBOLS = /[0-9=+−×÷<>≤≥±√Δ²³′^/()|∞π]|\b[xyzk]\b/;
// writing/voice-sheets.md: nobody calls a question easy, and nobody says "just".
const BANNED = /\b(just|easy|easier|easily|simple|simply|obvious|obviously|guess|wrong)\b/i;
const words = s => s.trim().split(/\s+/).length;

export function load() {
  return { moves: readJSON('curriculum/moves.json'), map: readJSON('curriculum/moves-map.json'), doc: readJSON('curriculum/question-types.json') };
}

export function check({ moves, map, doc }) {
  const errors = [];
  const ids = new Map();
  for (const m of moves.moves ?? []) {
    const at = m.id ?? '(no id)';
    if (!ID.test(m.id ?? '')) errors.push(`${at}: id must be lower-case words joined by hyphens`);
    if (ids.has(m.id)) errors.push(`${at}: duplicate id`);
    ids.set(m.id, m);
    for (const f of ['name', 'when', 'say'])
      if (typeof m[f] !== 'string' || !m[f].trim()) errors.push(`${at}: needs ${f}`);
    if (typeof m.say === 'string') {
      const n = words(m.say);
      if (n < 4 || n > 12) errors.push(`${at}: say has ${n} words, not 4 to 12`);
      if (!/[.?!]$/.test(m.say)) errors.push(`${at}: say must be one sentence ending in a full stop`);
      if (/[.?!]\s/.test(m.say)) errors.push(`${at}: say must be one sentence`);
      if (NUMBER_WORDS.test(m.say) || SYMBOLS.test(m.say)) errors.push(`${at}: say has a number or a board symbol: "${m.say}"`);
      if (BANNED.test(m.say)) errors.push(`${at}: say breaks the voice rules: "${m.say}"`);
    }
    if (!Array.isArray(m.examples) || m.examples.length < 2 || m.examples.length > 3 || m.examples.some(e => typeof e !== 'string' || !e.trim()))
      errors.push(`${at}: needs 2 or 3 examples`);
    if ('retired' in m && typeof m.retired !== 'boolean') errors.push(`${at}: retired must be true or false`);
  }

  const types = new Map(doc.types.map(t => [t.id, t]));
  const used = new Set();
  for (const [key, byCount] of Object.entries(map.map ?? {})) {
    const [type, unknown, angle, extra] = key.split('/');
    const t = types.get(type);
    if (extra !== undefined || !angle) { errors.push(`${key}: key must be type/unknown/angle`); continue; }
    if (!t) { errors.push(`${key}: unknown type ${type}`); continue; }
    if (!(t.unknowns ?? []).some(u => u.id === unknown)) errors.push(`${key}: ${type} has no unknown ${unknown}`);
    // "any" is the engine's angle for an unknown with one obvious route
    if (angle !== 'any' && !(t.angles ?? []).some(a => a.method === angle)) errors.push(`${key}: ${type} has no angle ${angle}`);
    if (!byCount || typeof byCount !== 'object' || Array.isArray(byCount) || !Object.keys(byCount).length) {
      errors.push(`${key}: must map each step count to a list of moves`); continue;
    }
    for (const [k, list] of Object.entries(byCount)) {
      // "<n>", or "<rep>/<n>" where one representation's steps line up differently
      const [rep, n] = k.includes('/') ? k.split('/') : [null, k];
      if (rep !== null && !(t.representations ?? []).some(r => r.rep === rep)) errors.push(`${key}: ${type} has no representation ${rep}`);
      if (!/^[1-9][0-9]*$/.test(n)) { errors.push(`${key}: step count "${n}" is not a whole number`); continue; }
      if (!Array.isArray(list) || list.length !== Number(n)) { errors.push(`${key} (${k}): needs exactly ${n} entries`); continue; }
      list.forEach((id, i) => {
        if (id === null) return;
        const m = ids.get(id);
        if (!m) errors.push(`${key} (${k}) step ${i}: no move ${id}`);
        else if (m.retired) errors.push(`${key} (${k}) step ${i}: move ${id} is retired`);
        used.add(id);
      });
    }
  }
  // Where a method's numbers send one step down another branch with the same step count,
  // a branch names the step by a pattern in its text and gives that branch its own move.
  for (const [i, b] of (map.branches ?? []).entries()) {
    const at = `branch ${i} (${b.key} ${b.steps}:${b.index})`;
    const list = map.map?.[b.key]?.[b.steps];
    if (!list) { errors.push(`${at}: no such method and step count in the map`); continue; }
    if (!Number.isInteger(b.index) || b.index < 0 || b.index >= list.length) errors.push(`${at}: no step ${b.index}`);
    try { new RegExp(b.match, 'u'); } catch { errors.push(`${at}: match is not a valid pattern`); }
    if (!ids.has(b.move)) errors.push(`${at}: no move ${b.move}`);
    else used.add(b.move);
  }
  const unused = [...ids.keys()].filter(id => !used.has(id));
  return { errors, unused, counts: { moves: ids.size, methods: Object.keys(map.map ?? {}).length } };
}

// Every solution of every exported question must be in the map with its step count;
// a "<rep>/<n>" list, where there is one, wins over the plain "<n>" list.
// Coverage is the share of steps whose move is not null, per type and overall.
export function coverage({ map }, exported) {
  const errors = [];
  const branches = new Map();
  for (const b of map.branches ?? []) {
    const k = `${b.key}|${b.steps}|${b.index}`;
    branches.set(k, [...(branches.get(k) ?? []), { re: new RegExp(b.match, 'u'), move: b.move }]);
  }
  const byType = new Map();
  for (const q of exported.questions) {
    const v = q.view;
    for (const s of q.solutions ?? []) {
      const key = `${v.type}/${v.unknown}/${s.angle}`;
      const n = s.steps.length;
      const steps = map.map[key]?.[`${v.rep}/${n}`] ? `${v.rep}/${n}` : String(n);
      const list = map.map[key]?.[steps];
      const row = byType.get(v.type) ?? byType.set(v.type, { type: v.type, steps: 0, tagged: 0 }).get(v.type);
      row.steps += n;
      if (!list) { errors.push(`${key}: not in the map with ${n} steps`); continue; }
      list.forEach((m, i) => {
        const text = typeof s.steps[i] === 'string' ? s.steps[i] : s.steps[i]?.board ?? '';
        const b = (branches.get(`${key}|${steps}|${i}`) ?? []).find(b => b.re.test(text));
        if ((b ? b.move : m) !== null) row.tagged++;
      });
    }
  }
  const rows = [...byType.values()];
  const total = rows.reduce((a, r) => ({ steps: a.steps + r.steps, tagged: a.tagged + r.tagged }), { steps: 0, tagged: 0 });
  return { errors: [...new Set(errors)], rows, total };
}

// ── CLI ──────────────────────────────────────────────────────
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const data = load();
  const { errors, unused, counts } = check(data);
  console.log(`Moves: ${counts.moves}. Methods mapped: ${counts.methods}.`);
  if (unused.length) console.log(`Not used by a built method yet (${unused.length}): ${unused.join(', ')}`);
  const at = process.argv.indexOf('--coverage');
  if (at > 0) {
    const cov = coverage(data, readJSON(process.argv[at + 1]));
    const pct = r => (100 * r.tagged / r.steps).toFixed(1).padStart(5) + '%';
    console.log(`\n${'type'.padEnd(34)}${'steps'.padStart(6)}${'tagged'.padStart(8)}  share`);
    for (const r of cov.rows) console.log(`${r.type.padEnd(34)}${String(r.steps).padStart(6)}${String(r.tagged).padStart(8)}  ${pct(r)}`);
    console.log(`${'all'.padEnd(34)}${String(cov.total.steps).padStart(6)}${String(cov.total.tagged).padStart(8)}  ${pct(cov.total)}`);
    errors.push(...cov.errors);
  }
  if (errors.length) { console.error(`\n${errors.length} error(s):\n  ` + errors.join('\n  ')); process.exit(1); }
  console.log('\nOK.');
}
