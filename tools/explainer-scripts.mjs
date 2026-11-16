#!/usr/bin/env node
// ── EXPLAINER SCRIPT CHECK ───────────────────────────────────
// Checks every writing/explainers/ex.*.json against the script format in
// writing/explainers/README.md (FAL-952): the map entry it teaches, the moves, speakers,
// callbacks, cues and question types it names, the arc order and board keys, and the
// words in its captions. tools/explainers.mjs runs it after the map check.
//
//   node tools/explainer-scripts.mjs     check every script; exit 1 on any error

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const readJSON = f => JSON.parse(fs.readFileSync(path.join(ROOT, f), 'utf8'));
export const DIR = 'writing/explainers';

// The arc (README, "The arc"): a section's slot is its kind, plus the example level or the turn kind.
export const ARC = ['cold-open', 'recall', 'big-idea', 'example/full', 'your-turn/twin', 'example/faded', 'example/exam',
  'second-method', 'spot-the-slip', 'your-turn/exam', 'recap'];
const KINDS = new Set(ARC.map(a => a.split('/')[0]));
const ASK_KINDS = ['recall', 'why', 'fill', 'choose', 'tap-line'];
// Captions are spoken words: no digits, ASCII or sub- and superscript.
const DIGIT = /[0-9₀-₉⁰¹²³⁴⁵⁶⁷⁸⁹]/;

// The clip renderer's banned words (tools/explainer-clips/render.mjs), read from its source so
// the two lists can't drift. render.mjs launches a browser on import, so it is not imported.
export function bannedWords() {
  const src = fs.readFileSync(path.join(ROOT, 'tools/explainer-clips/render.mjs'), 'utf8');
  const m = /const BANNED = \/(.+)\/([a-z]*);/.exec(src);
  if (!m) throw new Error('tools/explainer-clips/render.mjs: no BANNED list found');
  return new RegExp(m[1], m[2]);
}

export function loadContext() {
  const callbacks = readJSON(`${DIR}/callbacks.json`);
  return {
    map: new Map(readJSON('curriculum/explainers.json').explainers.map(n => [n.id, n])),
    moves: new Set(readJSON('curriculum/moves.json').moves.map(m => m.id)),
    teachers: readJSON('tools/explainer-clips/teachers.json'),
    callbacks,
    cues: new Set(callbacks.cues || []),
    types: new Set(readJSON('curriculum/question-types.json').types.map(t => t.id)),
    banned: bannedWords(),
  };
}

export function loadScripts() {
  return fs.readdirSync(path.join(ROOT, DIR)).filter(f => /^ex\..+\.json$/.test(f)).sort()
    .map(file => ({ file, script: readJSON(`${DIR}/${file}`) }));
}

const sameSet = (a = [], b = []) => a.length === b.length && new Set(a).size === new Set(b).size && a.every(x => b.includes(x));

// Every object in v, with a path for messages.
function* objects(v, where) {
  if (Array.isArray(v)) { for (const [i, x] of v.entries()) yield* objects(x, `${where}[${i}]`); return; }
  if (!v || typeof v !== 'object') return;
  yield [v, where];
  for (const [k, x] of Object.entries(v)) yield* objects(x, `${where}.${k}`);
}

// The board items and tap questions of one board scope (a section, or one recall version), in order.
function* items(beats, where) {
  for (const [i, b] of (beats || []).entries()) {
    const w = `${where}[${i}]`;
    if (b.write != null || b.strike != null) yield { item: b, where: w };
    for (const [j, x] of (b.board || []).entries()) yield { item: x, where: `${w}.board[${j}]` };
    if (b.ask) yield { ask: b.ask, where: `${w}.ask` };
  }
}

export function checkScript(script, ctx, file = `${script.id}.json`) {
  const errors = [];
  const err = (where, msg) => errors.push(`${file}${where ? ` ${where}` : ''}: ${msg}`);

  // ── Map ──
  const entry = ctx.map.get(script.id);
  if (file !== `${script.id}.json`) err('', `file name does not match id ${script.id}`);
  if (!entry) err('', `id ${script.id} is not in curriculum/explainers.json`);
  else {
    if (!sameSet(script.courses, entry.courses)) err('courses', `${JSON.stringify(script.courses)} does not match the map's ${JSON.stringify(entry.courses)}`);
    if (!sameSet(script.skills, entry.skills)) err('skills', `${JSON.stringify(script.skills)} does not match the map's ${JSON.stringify(entry.skills)}`);
    for (const b of script.builds_on || []) if (!(entry.prereqs || []).includes(b)) err('builds_on', `${b} is not one of the map's prereqs for ${script.id}`);
    if (script.zone !== entry.zone) err('zone', `${script.zone} does not match the map's ${entry.zone}`);
  }
  for (const l of script.leads_to || []) if (!ctx.map.has(l)) err('leads_to', `${l} is not in curriculum/explainers.json`);
  const zoneTutor = ctx.teachers.zones?.[script.zone];
  if (script.tutor !== zoneTutor) err('tutor', `${script.tutor} is not the ${script.zone} tutor (${zoneTutor})`);

  // ── References and words, wherever they appear ──
  for (const [o, w] of objects(script.sections, 'sections')) {
    if ('move' in o && !ctx.moves.has(o.move)) err(w, `move ${o.move} is not in curriculum/moves.json`);
    if ('speaker' in o && !ctx.teachers.teachers?.[o.speaker]) err(w, `speaker ${o.speaker} is not in tools/explainer-clips/teachers.json`);
    if ('cue' in o && !ctx.cues.has(o.cue)) err(w, `cue ${o.cue} is not in callbacks.json cues`);
    if ('use' in o) {
      const [tutor, ...rest] = String(o.use).split('.');
      if (!ctx.callbacks.tutors?.[tutor]?.lines?.[rest.join('.')]) err(w, `use ${o.use} is not in callbacks.json`);
    }
    if ('say' in o) {
      if (DIGIT.test(o.say)) err(w, `say has a digit; write numbers in words: "${o.say}"`);
      const bad = ctx.banned.exec(o.say);
      if (bad) err(w, `say uses "${bad[0]}", a word the voice sheets rule out`);
      if (o.joke && o.board?.length) err(w, 'a joke line writes on the board; jokes live in the voice');
    }
  }

  // ── Structure ──
  const ids = new Set();
  let last = -1;
  for (const [i, s] of (script.sections || []).entries()) {
    const w = `sections[${i}] (${s.id})`;
    if (ids.has(s.id)) err(w, 'duplicate section id');
    ids.add(s.id);
    if (!KINDS.has(s.kind)) { err(w, `unknown section kind ${s.kind}`); continue; }
    const slot = s.kind === 'example' ? `example/${s.level}` : s.kind === 'your-turn' ? `your-turn/${s.turn?.kind}` : s.kind;
    const at = ARC.indexOf(slot);
    if (at < 0) err(w, `${slot} is not a place in the arc`);
    else if (at <= last) err(w, `${slot} is out of arc order (after ${ARC[last]})`);
    else last = at;

    if (s.kind === 'your-turn' && !ctx.types.has(s.turn?.type)) err(`${w}.turn`, `type ${s.turn?.type} is not in curriculum/question-types.json`);
    if (s.kind === 'recall') {
      for (const b of s.builds_on ? [s.builds_on].flat() : []) if (!(script.builds_on || []).includes(b)) err(w, `builds_on ${b} is not in the script's builds_on`);
      // With no prerequisite there is nothing to have watched: one beats list, builds_on null (README, "Callback lines").
      if (s.builds_on === null) {
        if ((script.builds_on || []).length) err(w, 'a recall section with builds_on null is only for a script with no builds_on');
        if (!s.beats?.length) err(w, 'a recall section with builds_on null has beats');
      } else if (!s.watched?.length || !s.not_watched?.length) err(w, 'a recall section has both watched and not_watched');
    }
    // Each recall version is its own board; any other section is one board.
    const scopes = s.kind === 'recall' && s.builds_on !== null ? [['watched', s.watched], ['not_watched', s.not_watched]] : [['beats', s.beats]];
    for (const [name, beats] of scopes) {
      const keys = new Set(), all = new Set();
      for (const { item } of items(beats, '')) if (item?.key) all.add(item.key);
      for (const x of items(beats, `${w}.${name}`)) {
        if (x.ask) {
          const a = x.ask, n = (a.choices || []).length;
          if (!ASK_KINDS.includes(a.kind)) err(x.where, `unknown ask kind ${a.kind}`);
          if (!Number.isInteger(a.answer) || a.answer < 0 || a.answer >= n) err(x.where, `answer ${a.answer} is not an index of its ${n} choices`);
          if (a.kind === 'tap-line') for (const c of a.choices || []) if (!all.has(c)) err(x.where, `tap-line choice ${c} is not a board key in this section`);
          continue;
        }
        const it = x.item;
        if (it.strike != null && !keys.has(it.strike)) err(x.where, `strike ${it.strike} is not an earlier board key in this section`);
        if (it.key != null) {
          if (keys.has(it.key)) err(x.where, `board key ${it.key} is used twice in this section`);
          keys.add(it.key);
        }
      }
    }
  }
  return errors;
}

export function checkScripts(ctx = loadContext(), scripts = loadScripts()) {
  const errors = [];
  for (const { file, script } of scripts) errors.push(...checkScript(script, ctx, file));
  return { errors, count: scripts.length };
}

// ── CLI ──────────────────────────────────────────────────────
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const { errors, count } = checkScripts();
  console.log(`Explainer scripts: ${count} checked`);
  if (errors.length) { console.error(`\n${errors.length} error(s):\n  ` + errors.join('\n  ')); process.exit(1); }
  console.log('OK.');
}
