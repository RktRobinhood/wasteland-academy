#!/usr/bin/env node
// ── GAME EXPLAINERS COPY ─────────────────────────────────────
// The Godot game can't read files outside game/, so the lesson player (#218, FAL-1088)
// reads a copy of the explainer scripts and the stock lines they share: every
// writing/explainers/ex.*.json, callbacks.json and reactions.json, byte for byte, in
// game/data/explainers/. Export only a compact manifest of verified spoken lines.
//
//   node tools/game-explainers.mjs           print whether the copy is current
//   node tools/game-explainers.mjs --write   rewrite game/data/explainers/
//
// writing/explainers/ stays the single source. tests/unit/game-explainers.test.mjs fails
// when the copy is stale.

import fs from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { lines, sayOf, sayHash } from './explainer-scripts.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SRC = path.join(ROOT, 'writing/explainers');
export const OUT = path.join(ROOT, 'game/data/explainers');
const SHARED = ['archive.json', 'callbacks.json', 'reactions.json'];

// The files to copy, by name: { name: text }.
export function build() {
  const out = {};
  for (const f of fs.readdirSync(SRC).sort()) {
    if ((f.startsWith('ex.') && f.endsWith('.json')) || SHARED.includes(f)) {
      out[f] = fs.readFileSync(path.join(SRC, f), 'utf8');
    }
  }
  checkArchive(out);
  const manifest = JSON.parse(fs.readFileSync(path.join(SRC, 'manifest.json'), 'utf8'));
  out['voice-index.json'] = voiceJson(voiceIndex(out, manifest, readAudio));
  return out;
}

// A file in the build doesn't make a draft visible. Each published excerpt must
// explicitly name a checked worked part and its matching practice part.
export function checkArchive(sources) {
  const { format, entries } = JSON.parse(sources['archive.json']);
  if (format !== 1 || !Array.isArray(entries)) throw Error('Invalid archive catalog format');
  const seen = new Set();
  for (const e of entries) {
    const fail = msg => { throw Error(`Archive ${e.lesson}: ${msg}`); };
    if (seen.has(e.lesson)) fail('duplicate entry');
    seen.add(e.lesson);
    const script = JSON.parse(sources[e.lesson + '.json'] ?? 'null');
    const watch = script?.sections?.find(x => x.id === e.worked);
    const practice = script?.sections?.find(x => x.id === e.practice);
    if (watch?.kind !== 'example' || watch.level !== 'full' || !watch.problem?.setup ||
        practice?.kind !== 'your-turn' || practice.turn?.like !== e.worked) fail('expected a worked example and its own twin');
    if (e.practice_mode !== 'authored-twin' || !(practice.turn.fallback?.parts?.length > 0)) fail('the authored twin needs a complete stem');
    if (e.activity?.kind === 'gauge') {
      const { low, high, intervals, needle_step } = e.activity;
      if (![low, high, intervals, needle_step].every(Number.isSafeInteger) ||
          !(high > low && intervals >= 2 && intervals <= 12 && needle_step >= 0 && needle_step <= intervals) ||
          practice.turn.fallback.parts.length !== 1 ||
          Number(practice.turn.fallback.parts[0].answer) !== low + (high - low) * needle_step / intervals)
        fail('gauge markings and needle must match the marked answer');
    }
    if (e.activity?.kind === 'stands') {
      const { first, change, rows, mode } = e.activity;
      const last = first + (rows - 1) * change;
      const expected = mode === 'term' ? last : rows * (first + last) / 2;
      if (![first, change, rows, expected].every(Number.isSafeInteger) ||
          first < 1 || last < 1 || rows < 2 || !['term', 'total'].includes(mode) ||
          practice.turn.fallback.parts.length !== 1 || Number(practice.turn.fallback.parts[0].answer) !== expected)
        fail('seat count must match the selected row or stand');
    }
    if (['balance', 'substitute', 'backtrace', 'price'].includes(e.activity?.kind)) {
      const { options, results, correct } = e.activity.control ?? {};
      if (!Array.isArray(options) || !Array.isArray(results) ||
          options.length !== 2 || results.length !== 2 ||
          ![...options, ...results].every(text => typeof text === 'string' && text.trim()) ||
          new Set(options).size !== 2 || ![0, 1].includes(correct))
        fail('a rehearsal bench needs two distinct authored moves, feedback, and one correct choice');
    }
    for (const part of practice.turn.fallback.parts) {
      if (!Object.hasOwn(part, 'polynomial')) continue;
      const { variable, label, powers, coefficients } = part.polynomial ?? {};
      if (!['x', 't'].includes(variable) || typeof label !== 'string' ||
          !Array.isArray(powers) || !Array.isArray(coefficients) ||
          !['1,0', '2,1,0'].includes(powers.join(',')) ||
          coefficients.length !== powers.length || !coefficients.every(Number.isSafeInteger))
        fail('an authored polynomial needs exact coefficient slots');
      const canonical = label + coefficients.map((c, i) => {
        const abs = powers[i] && Math.abs(c) === 1 ? '' : Math.abs(c);
        const sign = c < 0 ? '−' : i > 0 ? '+' : '';
        return sign + abs + (powers[i] ? variable + (powers[i] === 2 ? '²' : '') : '');
      }).join('');
      if (canonical.replaceAll(' ', '') !== String(part.answer).replaceAll(' ', ''))
        fail('authored coefficient slots must match the published solution');
    }
    if (!e.title?.trim() || !e.zone?.trim() || !e.prompt?.trim()) fail('missing student-facing entry text');
    if (!Array.isArray(e.courses) || !e.courses.length || !e.courses.every(c => script.courses.includes(c)) ||
        new Set(e.courses).size !== e.courses.length) fail('course mapping does not match the source lesson');
  }
}

function voiceJson(index) {
  const sets = Object.entries(index).map(([id, lines]) => {
    const entries = Object.entries(lines).map(([key, cue]) => `    ${JSON.stringify(key)}: ${JSON.stringify(cue)}`);
    return `  ${JSON.stringify(id)}: {\n${entries.join(',\n')}\n  }`;
  });
  return `{\n${sets.join(',\n')}\n}\n`;
}

function readAudio(file) {
  const name = path.join(ROOT, file);
  return fs.existsSync(name) ? fs.readFileSync(name) : null;
}

// Keep transcript review and provider details out of the game. Only an exact,
// accepted line plus the actual matching audio bytes may enter the runtime index.
export function voiceIndex(sources, manifest, audioBytes) {
  const index = {};
  for (const [name, text] of Object.entries(sources)) {
    const id = name.slice(0, -5);
    const verified = {};
    for (const [line] of lines(JSON.parse(text))) {
      const key = line.line ?? '';
      if (!/^[a-z0-9]{6}$/.test(key)) continue;
      const entry = manifest.lines?.[id]?.[key];
      const take = entry?.take;
      const expected = `game/assets/audio/voice/explainers/${id}/${key}.ogg`;
      if (manifest.retired?.[id]?.[key] || !take || entry.speaker !== line.speaker ||
          entry.say !== sayHash(line) || take.say !== entry.say || take.file !== expected ||
          !/^(passed|accepted on review: .+)$/.test(take.word_check ?? '') || !/^[a-f0-9]{64}$/.test(take.sha256 ?? '')) continue;
      const bytes = audioBytes(expected);
      if (!bytes || createHash('sha256').update(bytes).digest('hex') !== take.sha256) continue;
      verified[key] = [line.speaker, sayOf(line), line.cue ?? null, line.cue_at ?? null];
    }
    if (Object.keys(verified).length) index[id] = verified;
  }
  return index;
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
