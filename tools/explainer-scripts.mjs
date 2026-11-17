#!/usr/bin/env node
// ── EXPLAINER SCRIPT CHECK ───────────────────────────────────
// Checks every writing/explainers/ex.*.json, and callbacks.json, against the script format
// in writing/explainers/README.md (format 2, FAL-1043): the map entry it teaches, the moves,
// speakers, callbacks, cues and question cells it names, the arc order and board keys,
// every spoken line's id, caption and say (through pronunciation.json), the pinned turns
// and their not-yet lines, figures, and repeats across scripts. tools/explainers.mjs runs
// it after the map check.
//
//   node tools/explainer-scripts.mjs                    check; exit 1 on any error
//   node tools/explainer-scripts.mjs --write-manifest   refresh writing/explainers/manifest.json, then check
//
// Two kinds of finding. An error breaks the format and always fails. A to-do is
// something the words still need before the script can be approved (README, "Before a
// script ships"): it fails an approved or recorded script, and is listed for a draft.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { sheetFor, compare, sayProblems, words, NUMBER_WORDS } from './explainer-speech.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const readJSON = f => JSON.parse(fs.readFileSync(path.join(ROOT, f), 'utf8'));
export const DIR = 'writing/explainers';
export const MANIFEST = `${DIR}/manifest.json`;
export const FORMAT = 2;

// The arc (README, "The arc"): a section's slot is its kind, plus the example level or the turn kind.
export const ARC = ['cold-open', 'recall', 'big-idea', 'example/full', 'your-turn/twin', 'example/faded', 'example/exam',
  'second-method', 'spot-the-slip', 'your-turn/exam', 'recap'];
const KINDS = new Set(ARC.map(a => a.split('/')[0]));
const ASK_KINDS = ['recall', 'why', 'fill', 'choose', 'tap-line'];
const STATUSES = ['draft', 'approved', 'recorded'];
export const LINE_ID = /^[a-z0-9]{6}$/;
// Ways of addressing someone that gender them. No line calls the player one, caption or voice
// (TONE.md); a tutor's stories may still have a brother or a boy in them.
const GENDERED = /\b(lad|lads|lass|lasses|laddie|sonny|bro|dude|sir|ma'am|madam|guys|young man|young lady|mister|missy)\b/i;
// Number words in a turn line: the live question's numbers change every time (#188).
// "one" and "zero" stay: "the one", "one multiplication", "on the x-axis, y is zero" hold for any question.
const TURN_NUMBERS = new Set([...NUMBER_WORDS].filter(w => !['one', 'zero', 'point', 'oh'].includes(w)).concat(['half', 'twice']));
// Maths said in words, which a caption shows in notation: x squared, u n, f of x.
const SPOKEN_MATHS = /\b(squared|cubed|to the power)\b|\b[uSTx] (n|one|two|three)\b|\b[fghCVW] of [a-z]\b/;
// A board line drawn with spaces or box characters: a text drawing, which a phone can't hold (#191).
// Columns lined up with a wide gap, or with three or more double spaces, or a box character.
const TEXT_DRAWING = /\S {4,}\S|(\S+ {2,}){3}\S|[─│┼┌┐└┘├┤┬┴═║]/;
// The figure board item (README, "Figures"): its kinds and the fields each must have.
export const FIGURES = {
  table: { rows: 'rows' },
  'area-grid': { top: 'list', side: 'list', cells: 'rows' },
  gauge: { marks: 'marks', steps: 'count', needle: 'number', unit: 'text' },
  axes: { x: 'range', y: 'range' },
  'number-line': { from: 'number', to: 'number' },
  balance: { left: 'text', right: 'text' },
};
// Common words that are never a turn's context, even when its fallback story uses them.
const PLAIN = new Set(('the and for are but not you your all any can had her was one our out has his how its may new now '
  + 'see two way who did get let put say she too use with this that from they what when will have been more some then them '
  + 'than into only over also back each find just like make most much must next same take tell very what which while '
  + 'work write down answer value values number numbers first last line lines part parts step steps check give given '
  + 'show hence after before every there their these those here where does done goes going first second time times '
  + 'term terms rule right left top bottom start end total change rate form point points side sides both whole '
  + 'exactly correct figures significant decimal places place nearest equation expression model graph table '
  + 'axis axes intercept gradient coordinate coordinates labelled between scale mark marks hold holds').split(' '));

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
  const qt = readJSON('curriculum/question-types.json');
  return {
    map: new Map(readJSON('curriculum/explainers.json').explainers.map(n => [n.id, n])),
    moves: new Set(readJSON('curriculum/moves.json').moves.map(m => m.id)),
    teachers: readJSON('tools/explainer-clips/teachers.json'),
    callbacks,
    cues: new Set(callbacks.cues || []),
    types: new Map(qt.types.map(t => [t.id, t])),
    pron: readJSON(`${DIR}/pronunciation.json`),
    stock: readJSON(`${DIR}/stock.json`),
    manifest: fs.existsSync(path.join(ROOT, MANIFEST)) ? readJSON(MANIFEST) : null,
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

// A spoken line: a speaker and a text. `say` and `caption` default to each other (#190).
export const isLine = o => o && typeof o === 'object' && 'speaker' in o && ('say' in o || 'caption' in o);
export const sayOf = l => l.say ?? l.caption;
export const captionOf = l => l.caption ?? l.say;
export function* lines(v, where = '') { for (const [o, w] of objects(v, where)) if (isLine(o)) yield [o, w]; }

// What the manifest stores for a line, so only a change to what is heard asks for a new take.
// The caption is not in it (#190).
export const sayHash = l => crypto.createHash('sha256').update(JSON.stringify([l.speaker, sayOf(l), l.cue ?? null, l.cue_at ?? null])).digest('hex').slice(0, 16);

// The board items and tap questions of one board scope (a section, or one recall version), in order.
function* items(beats, where) {
  for (const [i, b] of (beats || []).entries()) {
    const w = `${where}[${i}]`;
    if (b.write != null || b.strike != null || b.figure != null) yield { item: b, where: w };
    for (const [j, x] of (b.board || []).entries()) yield { item: x, where: `${w}.board[${j}]` };
    if (b.ask) yield { ask: b.ask, where: `${w}.ask` };
  }
}

// A misconception's id is its ref in question-types.json, or "<type id>#<index>" (as the
// engine names it in a marked answer: QuestionEngine.mark().misconception).
export function misconceptionRefs(type) {
  return new Map((type?.misconceptions || []).map((m, i) => [m.ref ?? `${type.id}#${i}`, m]));
}

// The words of a turn's fallback story that the type itself doesn't use: its context.
function contextWords(turn, type, script) {
  const fb = turn.fallback || {};
  const own = new Set(words([type?.name, type?.summary, ...(type?.chain || []), type?.asked, ...(type?.given || []),
    ...(script.terms || [])].filter(Boolean).join(' ')).map(stem));
  const story = words([fb.setup, ...(fb.parts || []).map(p => p.text)].filter(Boolean).join(' ').replace(/[0-9]/g, ' '));
  return new Set(story.filter(w => w.length >= 3 && !/[^a-z']/.test(w) && !PLAIN.has(w) && !own.has(stem(w)) && !NUMBER_WORDS.has(w)).map(stem));
}
const stem = w => w.replace(/'s$/, '').replace(/(ies)$/, 'y').replace(/(es|s)$/, '');

function checkFigure(fig, err, where) {
  const spec = FIGURES[fig?.kind];
  if (!spec) return err(where, `figure kind ${fig?.kind} is not one of ${Object.keys(FIGURES).join(', ')}`);
  const isNum = x => typeof x === 'number' && Number.isFinite(x);
  const ok = {
    rows: v => Array.isArray(v) && v.length >= 1 && v.every(r => Array.isArray(r) && r.length === v[0].length && r.length >= 2),
    list: v => Array.isArray(v) && v.length >= 1 && v.every(x => typeof x === 'string'),
    marks: v => Array.isArray(v) && v.length >= 2 && v.every(m => isNum(m.at) && typeof m.label === 'string'),
    count: v => Number.isInteger(v) && v > 0,
    number: isNum,
    text: v => typeof v === 'string',
    range: v => Array.isArray(v) && v.length === 2 && v.every(isNum) && v[0] < v[1],
  };
  for (const [k, kind] of Object.entries(spec)) if (!ok[kind](fig[k])) err(where, `a ${fig.kind} figure needs ${k} (${kind})`);
  if (fig.kind === 'area-grid' && Array.isArray(fig.cells) && (fig.cells.length !== fig.side?.length || fig.cells.some(r => r.length !== fig.top?.length)))
    err(where, 'an area-grid figure has one row of cells per side term and one cell per top term');
}

// One script, or callbacks.json (ctx.callbacks passed as script with kind 'callbacks').
export function checkScript(script, ctx, file = `${script.id}.json`) {
  const errors = [], todo = [];
  const err = (where, msg) => errors.push(`${file}${where ? ` ${where}` : ''}: ${msg}`);
  const fix = (where, msg) => todo.push(`${file}${where ? ` ${where}` : ''}: ${msg}`);

  if (script.format !== FORMAT) err('format', `format is ${script.format}; scripts are format ${FORMAT} (README, "The script format")`);
  if (!STATUSES.includes(script.status)) err('status', `status ${script.status} is not one of ${STATUSES.join(', ')}`);

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
  for (const w of script.waits_for || []) {
    if (w !== 'figure') err('waits_for', `${w} is not something a script can wait for (figure)`);
    fix('waits_for', `waits for a ${w} board item (README, "Figures")`);
  }

  // ── References, wherever they appear ──
  for (const [o, w] of objects(script.sections, 'sections')) {
    if ('move' in o && !ctx.moves.has(o.move)) err(w, `move ${o.move} is not in curriculum/moves.json`);
    if ('speaker' in o && !ctx.teachers.teachers?.[o.speaker]) err(w, `speaker ${o.speaker} is not in tools/explainer-clips/teachers.json`);
    if ('cue' in o && !ctx.cues.has(o.cue)) err(w, `cue ${o.cue} is not in callbacks.json cues`);
    if ('use' in o) {
      const [tutor, ...rest] = String(o.use).split('.');
      if (!ctx.callbacks.tutors?.[tutor]?.lines?.[rest.join('.')]) err(w, `use ${o.use} is not in callbacks.json`);
    }
    if ('figure' in o) {
      checkFigure(o.figure, err, `${w}.figure`);
      if (typeof o.alt !== 'string' || !o.alt) err(w, 'a figure has alt, the words a screen reader reads for it');
    }
    if (typeof o.write === 'string' && TEXT_DRAWING.test(o.write)) fix(w, `"${o.write}" is drawn with spaces; make it a figure (README, "Figures")`);
  }

  // ── Spoken lines ──
  checkLines(script.sections, 'sections', ctx, err, fix);

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

    // The exam example reads its stem first: a board item with no part comes before part (a) (README, "The board").
    if (s.kind === 'example' && s.level === 'exam') {
      const board = [...items(s.beats, '')].filter(x => !x.ask).map(x => x.item);
      const a = board.findIndex(it => it.part === 'a');
      if (!board.slice(0, a < 0 ? board.length : a).some(it => it.part == null)) err(w, 'an exam example puts its stem on the board, with no part, before part (a)');
    }
    if (s.kind === 'your-turn') checkTurn(s.turn || {}, `${w}.turn`, script, ctx, err, fix);
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
  return { errors, todo };
}

// Every spoken line in v: its id, its two texts, and the words in them.
function checkLines(v, where, ctx, err, fix) {
  const seen = new Map();
  for (const [l, w] of lines(v, where)) {
    if (!LINE_ID.test(l.line ?? '')) err(w, `a spoken line has a line id, six lower-case letters and digits (README, "Line ids")`);
    else if (seen.has(l.line)) err(w, `line id ${l.line} is also used at ${seen.get(l.line)}`);
    else seen.set(l.line, w);
    if (l.say != null && typeof l.say !== 'string') err(w, 'say is text');
    if (l.caption != null && typeof l.caption !== 'string') err(w, 'caption is text');
    if (!sayOf(l)) { err(w, 'a spoken line has say or caption'); continue; }
    if (l.say != null && l.caption === l.say) fix(w, 'caption is the same as say; give only say');
    if (l.caption == null && SPOKEN_MATHS.test(l.say)) fix(w, `say has maths in words ("${SPOKEN_MATHS.exec(l.say)[0]}"); show its notation in caption`);
    const sheet = sheetFor(ctx.pron, l.speaker);
    for (const p of sayProblems(sayOf(l), sheet)) fix(w, p);
    if (l.caption != null && l.say != null) { const d = compare(l.caption, l.say, sheet); if (d) fix(w, d); }
    for (const [name, text] of [['say', sayOf(l)], ['caption', captionOf(l)]]) {
      const bad = ctx.banned.exec(text);
      if (bad) fix(w, `${name} uses "${bad[0]}", a word the voice sheets rule out`);
      const g = GENDERED.exec(text);
      if (g) fix(w, `${name} uses "${g[0]}", which genders the player`);
    }
    if (l.joke && l.board?.length) fix(w, 'a joke line writes on the board; jokes live in the voice');
  }
  return seen;
}

// A your-turn: its pinned cell, the lines that must hold for every question it can serve,
// and not-yet lines keyed to misconceptions (#188).
function checkTurn(turn, w, script, ctx, err, fix) {
  const cell = turn.cell || {};
  const type = ctx.types.get(cell.type);
  if (!['engine', 'fallback'].includes(turn.serve)) err(w, `serve is engine or fallback, not ${turn.serve}`);
  if ('type' in turn) err(w, 'a format 2 turn names its type in cell.type');
  if (!type) { err(`${w}.cell`, `type ${cell.type} is not in curriculum/question-types.json`); return; }
  const parts = turn.fallback?.parts || [];
  if (!parts.length) err(`${w}.fallback`, 'a turn has a fallback with at least one part');
  const refs = misconceptionRefs(type);
  if (turn.serve === 'engine') {
    const u = (type.unknowns || []).find(x => x.id === cell.unknown);
    if (!u) err(`${w}.cell`, `unknown ${cell.unknown} is not one of ${type.id}'s unknowns`);
    else {
      if (!u.reps?.includes(cell.rep)) err(`${w}.cell`, `rep ${cell.rep} is not one of ${u.id}'s representations (${(u.reps || []).join(', ')})`);
      if (cell.angle != null && !(type.angles || []).some(a => a.method === cell.angle && a.suits?.includes(u.id)))
        err(`${w}.cell`, `method ${cell.angle} does not suit ${u.id}`);
    }
    if (cell.format != null && !['value', 'mcq'].includes(cell.format)) err(`${w}.cell`, `format ${cell.format} is value or mcq`);
    // The engine serves one part, asked with one command term; game/tests/test_explainer_turns.gd
    // makes the cell's questions and checks the term.
    if (typeof turn.command !== 'string' || !/^[A-Z]/.test(turn.command)) err(w, 'an engine turn names the command term its lines assume (command)');
    if (parts.length > 1) err(`${w}.fallback`, `the engine serves one part, but the fallback has ${parts.length}; serve it from the fallback, or make it one part`);
    else if (parts[0] && turn.command && !String(parts[0].text).startsWith(turn.command)) err(`${w}.fallback`, `the fallback part does not start with the turn's command, ${turn.command}`);
  } else {
    for (const k of ['unknown', 'rep', 'angle', 'format']) if (k in cell) err(`${w}.cell`, `a fallback turn names only cell.type, not ${k}`);
  }
  for (const [p, i] of parts.map((p, i) => [p, i])) for (const x of p.wrong || []) {
    if (!refs.has(x.misconception)) err(`${w}.fallback.parts[${i}].wrong`, `misconception ${x.misconception} is not a misconception of ${type.id}`);
  }

  // Lines that are heard with any question the turn serves.
  const context = contextWords(turn, type, script);
  for (const k of ['intro', 'right', 'not_yet']) for (const [l, lw] of lines(turn[k] || [], `${w}.${k}`)) {
    const said = words(sayOf(l));
    const n = said.find(x => TURN_NUMBERS.has(x));
    if (n) fix(lw, `a turn line says "${n}"; its numbers change with the question (#188)`);
    const c = said.find(x => context.has(stem(x)));
    if (c) fix(lw, `a turn line names "${c}", from the fallback's story; the live question's story changes (#188)`);
    if (turn.serve === 'engine' && /\bparts?\s+[abc]\b|\bparts\b/.test(said.join(' '))) fix(lw, 'a turn line talks about parts; the engine serves one part');
  }
  // Not yet: one line per misconception the turn expects, and one neutral line for anything else.
  const ny = turn.not_yet || [];
  const neutral = ny.filter(l => l.misconception == null);
  if (neutral.length !== 1) fix(`${w}.not_yet`, `has ${neutral.length} neutral lines; key every not-yet line but one to a misconception (README, "Turns")`);
  const keyed = new Set();
  for (const [i, l] of ny.entries()) {
    if (l.misconception == null) continue;
    const m = refs.get(l.misconception);
    if (!m) { err(`${w}.not_yet[${i}]`, `misconception ${l.misconception} is not a misconception of ${type.id}`); continue; }
    if (keyed.has(l.misconception)) err(`${w}.not_yet[${i}]`, `misconception ${l.misconception} has two lines`);
    keyed.add(l.misconception);
    if (turn.serve === 'engine' && m.in && !m.in.includes(cell.unknown)) fix(`${w}.not_yet[${i}]`, `misconception ${l.misconception} is not one ${cell.unknown} asks about`);
    if (turn.serve === 'fallback' && !parts.some(p => (p.wrong || []).some(x => x.misconception === l.misconception)))
      fix(`${w}.not_yet[${i}]`, `misconception ${l.misconception} is not a wrong answer of the fallback; add it to a part's wrong list`);
  }
}

// callbacks.json: every line has an id and its texts pass.
export function checkCallbacks(cb, ctx, file = 'callbacks.json') {
  const errors = [], todo = [];
  const err = (where, msg) => errors.push(`${file}${where ? ` ${where}` : ''}: ${msg}`);
  const fix = (where, msg) => todo.push(`${file}${where ? ` ${where}` : ''}: ${msg}`);
  if (cb.format !== FORMAT) err('format', `format is ${cb.format}; callbacks are format ${FORMAT}`);
  if (!STATUSES.includes(cb.status)) err('status', `status ${cb.status} is not one of ${STATUSES.join(', ')}`);
  for (const [o, w] of objects(cb.tutors, 'tutors')) {
    if ('speaker' in o && !ctx.teachers.teachers?.[o.speaker]) err(w, `speaker ${o.speaker} is not in tools/explainer-clips/teachers.json`);
    if ('cue' in o && !ctx.cues.has(o.cue)) err(w, `cue ${o.cue} is not in callbacks.json cues`);
  }
  checkLines(cb.tutors, 'tutors', ctx, err, fix);
  return { errors, todo };
}

// ── Across scripts ──
// Repeats: the same joke in two scripts, or the same stock frame (an opener, a turn's
// lines, praise, a sign-off) word for word (#191). A tutor's tics may repeat (stock.json).
const STOP = new Set('the a an and of to in on it is i my me you your that this was for with at be he she his her they them there but so as by from or one all once out up what'.split(' '));
const content = text => new Set(words(text).filter(w => w.length > 2 && !STOP.has(w)).map(stem));
function frames(script) {
  const out = [];
  const add = (l, where) => l && isLine(l) && out.push({ l, where });
  for (const [i, s] of (script.sections || []).entries()) {
    const spoken = [...lines(s.beats || [], '')].map(([l]) => l);
    if (s.kind === 'cold-open') add(spoken[0], `sections[${i}] first line`);
    if (s.kind === 'spot-the-slip') add(spoken[0], `sections[${i}] first line`);
    if (s.kind === 'recap') add(spoken[spoken.length - 1], `sections[${i}] last line`);
    for (const [o, w] of objects(s, `sections[${i}]`)) {
      if (o.ask) for (const [l, lw] of lines(o.ask.right || [], `${w}.ask.right`)) add(l, lw);
      if (o === s.turn) for (const k of ['intro', 'right', 'not_yet']) for (const [l, lw] of lines(o[k] || [], `${w}.${k}`)) add(l, lw);
    }
  }
  return out;
}
const grams = (text, n = 5) => { const w = words(text); const g = []; for (let i = 0; i + n <= w.length; i++) g.push(w.slice(i, i + n).join(' ')); return g; };
export function checkRepeats(scripts, ctx) {
  const todo = [];
  const tics = tutor => (ctx.stock.tutors?.[tutor]?.tics || []).map(t => words(t).join(' '));
  const strip = (text, tutor) => tics(tutor).reduce((t, tic) => t.replaceAll(tic, ' | '), ` ${words(text).join(' ')} `);
  const jokes = [], stock = new Map();
  for (const { file, script } of scripts) {
    for (const [l, w] of lines(script.sections, 'sections')) if (l.joke) jokes.push({ file, w, l, words: content(sayOf(l)) });
    for (const { l, where } of frames(script)) for (const g of grams(strip(sayOf(l), l.speaker).split('|').join(' | ')).filter(g => !g.includes('|'))) {
      if (!stock.has(g)) stock.set(g, []);
      stock.get(g).push({ file, where, l });
    }
  }
  for (const [i, a] of jokes.entries()) for (const b of jokes.slice(i + 1)) {
    if (a.file === b.file) continue;
    const shared = [...a.words].filter(x => b.words.has(x));
    if (shared.length >= 4) for (const [x, y] of [[a, b], [b, a]]) todo.push(`${x.file} ${x.w}: the joke repeats one in ${y.file} (${shared.join(', ')}); jokes are told once (#191)`);
  }
  const told = new Set();
  for (const [g, uses] of stock) {
    const files = [...new Set(uses.map(u => u.file))];
    if (files.length < 2) continue;
    for (const u of uses) {
      const key = `${u.file} ${u.where}`;
      if (told.has(key)) continue;
      told.add(key);
      todo.push(`${key}: "${g}" is a stock frame also in ${files.filter(f => f !== u.file).join(', ')}; vary it (#191)`);
    }
  }
  return todo;
}

// ── The manifest ──
// One entry per spoken line, keyed by script and line id: the say hash, and the take
// once one is accepted. A line whose take was made from another say needs a new take.
export function manifestEntries(scripts, callbacks) {
  const out = {};
  for (const { script } of scripts) {
    out[script.id] = {};
    for (const [l] of lines(script.sections)) if (LINE_ID.test(l.line ?? '')) out[script.id][l.line] = { speaker: l.speaker, say: sayHash(l) };
  }
  out.callbacks = {};
  for (const [l] of lines(callbacks.tutors)) if (LINE_ID.test(l.line ?? '')) out.callbacks[l.line] = { speaker: l.speaker, say: sayHash(l) };
  return out;
}
export function writeManifest(old, scripts, callbacks) {
  const now = manifestEntries(scripts, callbacks);
  const m = { format: 1, about: old?.about ?? '', lines: {}, retired: structuredClone(old?.retired ?? {}) };
  for (const [sid, ls] of Object.entries(now)) {
    m.lines[sid] = {};
    for (const [id, e] of Object.entries(ls)) m.lines[sid][id] = { ...e, take: old?.lines?.[sid]?.[id]?.take ?? null };
  }
  // A line that has gone keeps its id out of use for good: saves and takes point at it.
  for (const [sid, ls] of Object.entries(old?.lines ?? {})) for (const [id, e] of Object.entries(ls)) {
    if (m.lines[sid]?.[id]) continue;
    (m.retired[sid] ??= {})[id] = { speaker: e.speaker, say: e.say, take: e.take ?? null };
  }
  return m;
}
export function checkManifest(manifest, scripts, callbacks) {
  const errors = [], todo = [];
  if (!manifest) return { errors: [`${MANIFEST}: missing; run node tools/explainer-scripts.mjs --write-manifest`], todo };
  const now = manifestEntries(scripts, callbacks);
  const status = new Map(scripts.map(({ script }) => [script.id, script.status]));
  for (const [sid, ls] of Object.entries(now)) for (const [id, e] of Object.entries(ls)) {
    const m = manifest.lines?.[sid]?.[id];
    if (manifest.retired?.[sid]?.[id]) errors.push(`${sid} line ${id}: the id was retired; a new line takes a new id`);
    else if (!m || m.say !== e.say || m.speaker !== e.speaker) errors.push(`${MANIFEST}: ${sid} line ${id} is not up to date; run node tools/explainer-scripts.mjs --write-manifest`);
    else if (m.take && m.take.say !== m.say) (status.get(sid) === 'recorded' ? errors : todo).push(`${sid} line ${id}: say changed since its take; record it again`);
    else if (!m.take && status.get(sid) === 'recorded') errors.push(`${sid} line ${id}: the script is recorded, but this line has no take`);
  }
  for (const [sid, ls] of Object.entries(manifest.lines ?? {})) for (const id of Object.keys(ls)) if (!now[sid]?.[id])
    errors.push(`${MANIFEST}: ${sid} line ${id} is not in the script; run node tools/explainer-scripts.mjs --write-manifest`);
  return { errors, todo };
}

export function checkScripts(ctx = loadContext(), scripts = loadScripts()) {
  const errors = [], todo = [], drafts = new Map();
  const add = (status, r, name) => {
    errors.push(...r.errors);
    if (status === 'draft') { todo.push(...r.todo); if (r.todo.length) drafts.set(name, (drafts.get(name) ?? 0) + r.todo.length); }
    else errors.push(...r.todo);
  };
  for (const { file, script } of scripts) add(script.status, checkScript(script, ctx, file), file);
  add(ctx.callbacks.status, checkCallbacks(ctx.callbacks, ctx), 'callbacks.json');
  // Repeats and the manifest: a to-do is charged to the script it names.
  const repeats = checkRepeats(scripts, ctx);
  const man = checkManifest(ctx.manifest, scripts, ctx.callbacks);
  errors.push(...man.errors);
  for (const t of [...repeats, ...man.todo]) {
    const s = scripts.find(x => t.startsWith(x.file) || t.startsWith(`${x.script.id} `));
    add(s?.script.status ?? 'draft', { errors: [], todo: [t] }, s?.file ?? 'manifest');
  }
  // An approved script uses only approved callbacks (#189).
  for (const { file, script } of scripts) if (script.status !== 'draft' && ctx.callbacks.status === 'draft'
      && [...objects(script.sections, '')].some(([o]) => 'use' in o)) errors.push(`${file}: is ${script.status}, but uses callbacks.json, which is a draft`);
  return { errors, todo, drafts, count: scripts.length };
}

// ── CLI ──────────────────────────────────────────────────────
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (process.argv.includes('--write-manifest')) {
    const ctx = loadContext();
    const m = writeManifest(ctx.manifest, loadScripts(), ctx.callbacks);
    m.about ||= 'One entry per spoken line of every explainer script and callbacks.json, keyed by script id and line id (README, "Line ids"). say is a hash of the speaker, say, cue and cue_at: the caption is left out, so a caption edit never asks for a new take. take is null until a take is accepted, then {say, provider, model, voice, direction, date, file, transcript}: say is the hash it was recorded from. A line that leaves a script moves to retired, and its id is never used again. Written by node tools/explainer-scripts.mjs --write-manifest.';
    fs.writeFileSync(path.join(ROOT, MANIFEST), JSON.stringify(m, null, 2) + '\n');
    console.log(`Wrote ${MANIFEST}`);
  }
  const { errors, todo, drafts, count } = checkScripts();
  console.log(`Explainer scripts: ${count} checked, and callbacks.json`);
  if (drafts.size) console.log(`Drafts with words still to fix before approval: ${[...drafts].map(([f, n]) => `${f} (${n})`).join(', ')}`);
  if (process.argv.includes('--todo') && todo.length) console.log(`\n${todo.length} to fix before approval:\n  ` + todo.join('\n  '));
  if (errors.length) { console.error(`\n${errors.length} error(s):\n  ` + errors.join('\n  ')); process.exit(1); }
  console.log('OK.');
}
