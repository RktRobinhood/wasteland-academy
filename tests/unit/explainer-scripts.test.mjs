// writing/explainers/: every script and callbacks.json against format 2 in writing/explainers/README.md
// (tools/explainer-scripts.mjs, FAL-952, FAL-1043). Each bad fixture below is pilot 1 with one rule broken.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  loadContext, loadScripts, checkScript, checkScripts, checkRepeats, sayHash, writeManifest, checkManifest, lines,
} from '../../tools/explainer-scripts.mjs';
import { sheetFor, compare, sayProblems, numberWords } from '../../tools/explainer-speech.mjs';

const ctx = loadContext();
const scripts = loadScripts();
const PILOT = 'ex.algebra.arithmetic-sequence.json';
const pilot = scripts.find(s => s.file === PILOT).script;
const section = (s, id) => s.sections.find(x => x.id === id);
const firstLine = (s, id) => section(s, id).beats.find(b => b.say);
const slip = s => section(s, 'spot-the-slip');
const ask = (s, id) => section(s, id).beats.find(b => b.ask).ask;
const turn = (s, id) => section(s, id).turn;

// Break one rule on a copy of pilot 1 and return the errors, or the to-dos.
const broken = edit => { const s = structuredClone(pilot); edit(s); return checkScript(s, ctx, PILOT).errors.join('\n'); };
const todo = edit => { const s = structuredClone(pilot); edit(s); return checkScript(s, ctx, PILOT).todo.join('\n'); };

test('every script and callbacks.json pass, and every script in writing/explainers is checked', () => {
  assert.ok(scripts.length >= 12);
  for (const f of [PILOT, 'ex.algebra.arithmetic-series.json']) assert.ok(scripts.some(s => s.file === f), f);
  assert.deepEqual(checkScripts(ctx, scripts).errors, []);
});

test('the scripts are format 2, and none is approved while it still has words to fix', () => {
  const { drafts } = checkScripts(ctx, scripts);
  for (const { file, script } of scripts) {
    assert.equal(script.format, 2, file);
    if (drafts.has(file)) assert.equal(script.status, 'draft', file);
  }
});

const RULES = [
  // Map
  ['an id that is not in the map', s => { s.id = 'ex.algebra.no-such-explainer'; }, /is not in curriculum\/explainers\.json/],
  ['courses that differ from the map', s => { s.courses = ['aa-sl', 'aa-hl']; }, /courses: .* does not match the map's/],
  ['skills that differ from the map', s => { s.skills.push('SL1.2.find-n'); }, /skills: .* does not match the map's/],
  ['a builds_on that is not a prereq', s => { s.builds_on = ['ex.foundations.pre-balance']; }, /builds_on: ex\.foundations\.pre-balance is not one of the map's prereqs/],
  ['a leads_to that does not exist', s => { s.leads_to = ['ex.algebra.no-such-explainer']; }, /leads_to: ex\.algebra\.no-such-explainer is not in/],
  ['format 1', s => { s.format = 1; }, /format is 1; scripts are format 2/],
  ['an unknown status', s => { s.status = 'done'; }, /status done is not one of/],
  // References
  ['an unknown move', s => { section(s, 'example-1').beats.find(b => b.board?.some(x => x.move)).board.find(x => x.move).move = 'wave-hands'; }, /move wave-hands is not in curriculum\/moves\.json/],
  ['an unknown speaker', s => { firstLine(s, 'cold-open').speaker = 'nobody'; }, /speaker nobody is not in tools\/explainer-clips\/teachers\.json/],
  ['an unknown callback', s => { section(s, 'recall').watched.find(b => b.use).use = 'mags-the-ledger.own.forgot'; }, /use mags-the-ledger\.own\.forgot is not in callbacks\.json/],
  ['an unknown cue', s => { firstLine(s, 'cold-open').cue = 'yodels'; }, /cue yodels is not in callbacks\.json cues/],
  // Line ids
  ['a spoken line with no id', s => { delete firstLine(s, 'cold-open').line; }, /a spoken line has a line id/],
  ['a line id used twice', s => { const [a, b] = section(s, 'cold-open').beats.filter(x => x.say); b.line = a.line; }, /line id \w+ is also used at/],
  // Turns
  ['a turn with an unknown type', s => { turn(s, 'turn-1').cell.type = 't9-no-such-type'; }, /type t9-no-such-type is not in curriculum\/question-types\.json/],
  ['a turn that is neither engine nor fallback', s => { turn(s, 'turn-1').serve = 'live'; }, /serve is engine or fallback, not live/],
  ['an engine turn with an unknown the type lacks', s => { turn(s, 'turn-1').cell.unknown = 'no-such-unknown'; }, /unknown no-such-unknown is not one of t1-arithmetic-in-context's unknowns/],
  ['an engine turn with a representation its unknown lacks', s => { turn(s, 'turn-1').cell.rep = 'diagram'; }, /rep diagram is not one of term-in-context's representations/],
  ['an engine turn with a method that does not suit', s => { turn(s, 'turn-1').cell.angle = 'gdc-regression'; }, /method gdc-regression does not suit term-in-context/],
  ['an engine turn with no command', s => { delete turn(s, 'turn-1').command; }, /an engine turn names the command term/],
  ['an engine turn with a fallback in parts', s => { const t = turn(s, 'turn-1'); t.fallback.parts.push({ part: 'b', text: 'Find u₂.', answer: '33' }); }, /the engine serves one part, but the fallback has 2/],
  ['an engine turn whose fallback asks another command', s => { turn(s, 'turn-1').command = 'Write down'; }, /does not start with the turn's command, Write down/],
  ['a fallback turn that pins an unknown', s => { turn(s, 'turn-2').cell.unknown = 'nth-term'; }, /a fallback turn names only cell.type, not unknown/],
  ['a not-yet line keyed to an unknown misconception', s => { turn(s, 'turn-1').not_yet[0].misconception = 'SL9.9.nothing#0'; }, /misconception SL9\.9\.nothing#0 is not a misconception of t1-arithmetic-in-context/],
  ['two not-yet lines keyed to one misconception', s => { const n = turn(s, 'turn-1').not_yet; n.push(structuredClone(n[0])); n[0].misconception = n[2].misconception = 'SL1.2.nth-term#0'; n[2].line = 'zzzzz9'; }, /misconception SL1\.2\.nth-term#0 has two lines/],
  ['the old turn type field', s => { turn(s, 'turn-1').type = 't1-arithmetic-in-context'; }, /a format 2 turn names its type in cell\.type/],
  // Figures
  ['a figure of an unknown kind', s => { section(s, 'big-idea').beats[0].board = [{ figure: { kind: 'hologram' }, alt: 'x' }]; }, /figure kind hologram is not one of/],
  ['a figure with a missing field', s => { section(s, 'big-idea').beats[0].board = [{ figure: { kind: 'gauge', marks: [{ at: 0, label: '0' }, { at: 4, label: '20' }], steps: 4, unit: 'L' }, alt: 'A gauge' }]; }, /a gauge figure needs needle/],
  ['a figure with no alt text', s => { section(s, 'big-idea').beats[0].board = [{ figure: { kind: 'table', rows: [['n', '1'], ['uₙ', '22']] } }]; }, /a figure has alt/],
  // Structure
  ['sections out of arc order', s => { s.sections.reverse(); }, /is out of arc order/],
  ['a recall with neither version', s => { delete section(s, 'recall').not_watched; }, /a recall section has both watched and not_watched/],
  ['a no-prerequisite recall in a script that builds on one', s => { const r = section(s, 'recall'); r.builds_on = null; r.beats = r.watched; }, /builds_on null is only for a script with no builds_on/],
  ['a no-prerequisite recall with no beats', s => { s.builds_on = []; const r = section(s, 'recall'); r.builds_on = null; delete r.watched; delete r.not_watched; }, /a recall section with builds_on null has beats/],
  ['an unknown section kind', s => { section(s, 'recap').kind = 'encore'; }, /unknown section kind encore/],
  ['a strike with no board key', s => { slip(s).beats.find(b => b.board?.some(x => x.strike)).board.find(x => x.strike).strike = 's9'; }, /strike s9 is not an earlier board key/],
  ['a tap-line choice with no board key', s => { ask(s, 'spot-the-slip').choices[0] = 's9'; }, /tap-line choice s9 is not a board key/],
  ['an answer index out of range', s => { const a = ask(s, 'example-1'); a.answer = a.choices.length; }, /answer \d+ is not an index of its \d+ choices/],
];
for (const [name, edit, want] of RULES) test(`the check catches ${name}`, () => assert.match(broken(edit), want));

// To-dos: the words a draft can still have, and an approved script can't.
const line = s => firstLine(s, 'cold-open');
const turnLine = s => turn(s, 'turn-1').intro[0];
const TODOS = [
  ['a digit in say', s => { line(s).say = 'Row 40 has the most seats.'; }, /say has "4"; write it the way it is said/],
  ['a raw abbreviation in say', s => { line(s).say = 'Use your GDC for this one.'; }, /say has "GDC"; the voice says "g d c"/],
  ['a banned word in say', s => { line(s).say = 'This one is easy.'; }, /say uses "easy"/],
  ['a banned word in the caption only', s => { line(s).caption = 'This one is easy.'; line(s).say = 'This one is easy.'; }, /caption uses "easy"/],
  ['a line that genders the player', s => { line(s).say = 'Righto, lad. Into the book.'; }, /say uses "lad", which genders the player/],
  ['maths in words with no caption', s => { line(s).say = 'So u n is the term in row n.'; }, /say has maths in words \("u n"\); show its notation in caption/],
  ['a caption that says another number', s => { const l = line(s); l.caption = 'Row 41 has the most seats.'; l.say = 'Row forty has the most seats.'; }, /caption and say part .*"41"/],
  ['(−3)² said with no brackets', s => { const l = line(s); l.caption = 'So (−3)² is 9.'; l.say = 'So minus three squared is nine.'; }, /caption has "\)", said "in brackets"/],
  ['a caption that drops a word', s => { const l = line(s); l.caption = 'So uₙ is the term.'; l.say = 'So u n is the term in row n.'; }, /say has more words than the caption/],
  ['a caption the same as say', s => { line(s).caption = line(s).say; }, /caption is the same as say; give only say/],
  ['a joke that writes on the board', s => { const b = line(s); b.joke = true; b.board = [{ write: 'ha' }]; }, /a joke line writes on the board/],
  ['a text drawing on the board', s => { section(s, 'big-idea').beats[0].board = [{ write: 'n:    1    2    3' }]; }, /is drawn with spaces; make it a figure/],
  ['a script waiting for a figure', s => { s.waits_for = ['figure']; }, /waits for a figure board item/],
  ['a number word in a turn line', s => { turnLine(s).say = 'Your turn. Twenty-five rows this time.'; }, /a turn line says "twenty"/],
  ['a story word in a turn line', s => { turnLine(s).say = 'Your turn. Count the seats.'; }, /a turn line names "seats", from the fallback's story/],
  ['parts in an engine turn line', s => { turnLine(s).say = 'Your turn. Label part b.'; }, /a turn line talks about parts; the engine serves one part/],
  ['two neutral not-yet lines', s => { for (const l of turn(s, 'turn-1').not_yet) delete l.misconception; }, /has 2 neutral lines; key every not-yet line but one/],
  ['a keyed misconception the cell does not ask about', s => { turn(s, 'turn-1').not_yet[0].misconception = 'SL1.2.find-n#3'; }, /misconception SL1\.2\.find-n#3 is not one term-in-context asks about/],
  ['a fallback not-yet line with no matching wrong answer', s => { turn(s, 'turn-2').not_yet[0].misconception = turn(s, 'turn-2').not_yet[0].misconception ?? 'SL1.2.nth-term#0'; for (const p of turn(s, 'turn-2').fallback.parts) delete p.wrong; }, /is not a wrong answer of the fallback/],
];
for (const [name, edit, want] of TODOS) test(`the check lists ${name} as a to-do`, () => assert.match(todo(edit), want));

test('an approved script with a to-do fails, and a draft one only lists it', () => {
  const s = structuredClone(pilot);
  line(s).say = 'This one is easy.';
  const as = status => { s.status = status; return checkScripts(ctx, [...scripts.filter(x => x.file !== PILOT), { file: PILOT, script: s }]); };
  assert.ok(as('draft').todo.some(e => /uses "easy"/.test(e)));
  assert.ok(!as('draft').errors.some(e => /uses "easy"/.test(e)));
  assert.ok(as('approved').errors.some(e => /uses "easy"/.test(e)));
});

// #190 "Done when": notation in the caption, the spoken form in say.
test('pilot 1 shows uₙ and u₁ in the caption, and the voice says "u n" and "u one"', () => {
  const l = [...lines(pilot.sections)].map(([x]) => x).find(x => /u n, so u one is twenty-two/.test(x.say));
  assert.ok(l, 'the line is in pilot 1');
  assert.match(l.caption, /uₙ, so u₁ is twenty-two/);
  assert.equal(compare(l.caption, l.say, sheetFor(ctx.pron, l.speaker)), null);
});

// ── The pronunciation sheet ──
const mags = sheetFor(ctx.pron, 'mags-the-ledger'), tess = sheetFor(ctx.pron, 'tin-can-tess'), rook = sheetFor(ctx.pron, 'rook-dead-air');
const SAME = [
  ['The term in row n is uₙ, so u₁ is 22.', 'The term in row n is u n, so u one is twenty-two.'],
  ['Sₙ = n/2 (u₁ + uₙ)', 'S n equals n over two, u one plus u n'],
  ['(−3)² = 9', 'minus three, in brackets, squared, is nine'],
  ['−3² = −9', 'minus three squared is minus nine'],
  ['0.0045678', 'zero point zero zero four five six seven eight'],
  ['178 seats', 'one hundred and seventy-eight seats'],
  ['480 − 285', 'four eighty take away two eighty-five'],
  ['u₁ + (n − 1)d', 'u one plus n minus one lots of d'],
  ['y = mx + c', 'y equals m x plus c'],
  ["The GDC's value", "The G D C's value"],
  ['f(x) = 4 + 2x − x²', 'f of x equals four, plus two x, minus x squared'],
  ['3 s.f.', 'three significant figures'],
  ['u₄₀, the 40th term', 'u forty, the fortieth term'],
  ['f⁻¹(29)', 'f inverse of twenty-nine'],
  ['x² ≥ 0', 'x squared is at least zero'],
];
for (const [caption, say] of SAME) test(`"${caption}" is said "${say}"`, () => assert.equal(compare(caption, say, mags), null));
const DIFFERENT = [
  ['(−3)² = 9', 'minus three squared is nine'],
  ['−3² = −9', 'minus three in brackets squared is minus nine'],
  ['22 seats', 'twenty-three seats'],
  ['0.6', 'zero point nine'],
  ['x + 5', 'x minus five'],
];
for (const [caption, say] of DIFFERENT) test(`"${caption}" is not said "${say}"`, () => assert.notEqual(compare(caption, say, mags), null));
test('a tutor sheet replaces the default: Tess says percent, and Rook never says nought', () => {
  assert.match(sayProblems('Up six per cent.', tess).join(), /per cent/);
  assert.deepEqual(sayProblems('Up six per cent.', mags), []);
  assert.ok(!numberWords('0.5', rook.zero).includes('nought point five'));
  assert.notEqual(compare('0.5', 'nought point five', rook), null);
});
test('a caption character with no spoken form is an error', () => assert.match(compare('x ⊕ y', 'x and y', mags), /no spoken form/));

// ── Repeats across scripts (#191) ──
test('the same joke in two scripts is listed for both', () => {
  const a = structuredClone(pilot), b = structuredClone(scripts.find(s => s.file === 'ex.algebra.arithmetic-series.json').script);
  const joke = { line: 'jjjjj1', speaker: 'mags-the-ledger', say: 'My uncle Wal fenced a paddock once with ten panels and ten posts.', joke: true };
  section(a, 'recap').beats.push(joke);
  section(b, 'recap').beats.push({ ...joke, line: 'jjjjj2', say: 'Uncle Wal fenced his paddock with ten posts for ten panels once.' });
  const out = checkRepeats([{ file: 'a.json', script: a }, { file: 'b.json', script: b }], ctx).join('\n');
  assert.match(out, /a\.json .*the joke repeats one in b\.json/);
  assert.match(out, /b\.json .*the joke repeats one in a\.json/);
});
test('a stock frame in two scripts is listed, and a tutor tic is not', () => {
  const a = structuredClone(pilot), b = structuredClone(pilot);
  b.id = 'other';
  turn(a, 'turn-1').intro[0].say = 'Into the book it goes, then the next one.';
  turn(b, 'turn-1').intro[0].say = 'Into the book it goes, and off you go.';
  const quiet = checkRepeats([{ file: 'a.json', script: a }, { file: 'b.json', script: b }], ctx).join('\n');
  assert.doesNotMatch(quiet, /into the book it goes/);
  turn(a, 'turn-1').intro[0].say = turn(b, 'turn-1').intro[0].say = 'Your turn, and no help on the first go.';
  assert.match(checkRepeats([{ file: 'a.json', script: a }, { file: 'b.json', script: b }], ctx).join('\n'), /no help on the first is a stock frame|"your turn and no help/);
});

// ── Line ids and the manifest (#189) ──
test('a caption edit keeps the say hash, and a say edit changes it', () => {
  const l = { line: 'abc123', speaker: 'mags-the-ledger', say: 'u n is the term.', caption: 'uₙ is the term.' };
  const h = sayHash(l);
  assert.equal(sayHash({ ...l, caption: 'uₙ is the nth term.' }), h);
  assert.notEqual(sayHash({ ...l, say: 'u n is a term.' }), h);
  assert.notEqual(sayHash({ ...l, cue: 'laughs' }), h);
});
test('the manifest is up to date, and catches a changed say, a retired id and a recorded line that changed', () => {
  assert.deepEqual(checkManifest(ctx.manifest, scripts, ctx.callbacks).errors, []);
  const s = structuredClone(pilot), l = line(s);
  const all = [...scripts.filter(x => x.file !== PILOT), { file: PILOT, script: s }];
  l.say = 'Something new.';
  assert.match(checkManifest(ctx.manifest, all, ctx.callbacks).errors.join('\n'), new RegExp(`line ${l.line} is not up to date`));
  // Write it, take the line out: its id is retired, and using it again is an error.
  const m = writeManifest(ctx.manifest, all, ctx.callbacks);
  const gone = section(s, 'cold-open').beats.shift();
  const m2 = writeManifest(m, all, ctx.callbacks);
  assert.ok(m2.retired[pilot.id][gone.line]);
  section(s, 'cold-open').beats.unshift(gone);
  assert.match(checkManifest(m2, all, ctx.callbacks).errors.join('\n'), /the id was retired/);
  // A take made from another say: a to-do for a draft, an error once recorded.
  const m3 = writeManifest(ctx.manifest, all, ctx.callbacks);
  m3.lines[pilot.id][l.line].take = { say: '0000000000000000', provider: 'gemini' };
  assert.match(checkManifest(m3, all, ctx.callbacks).todo.join('\n'), /say changed since its take/);
  s.status = 'recorded';
  assert.match(checkManifest(m3, all, ctx.callbacks).errors.join('\n'), /say changed since its take/);
});

// Each exam example reads its stem before part (a) (FAL-995). Rook's function-machine has a two-line stem;
// with it taken off the board, or labelled as part (a), the check fails.
const STEM = 'ex.functions.function-machine.json';
const stemmed = scripts.find(s => s.file === STEM).script;
const exam = s => s.sections.find(x => x.kind === 'example' && x.level === 'exam');
const stemErrors = s => checkScript(s, ctx, STEM).errors.filter(e => /stem/.test(e));
test('an exam example with its stem on the board before part (a) passes', () => assert.deepEqual(stemErrors(stemmed), []));
test('the check catches an exam example with no stem before part (a)', () => {
  const s = structuredClone(stemmed);
  for (const b of exam(s).beats) if (b.board) b.board = b.board.filter(x => x.part);
  assert.match(stemErrors(s).join('\n'), /puts its stem on the board, with no part, before part \(a\)/);
});
test('the check catches a stem labelled as part (a)', () => {
  const s = structuredClone(stemmed);
  for (const b of exam(s).beats) for (const x of b.board || []) x.part ??= 'a';
  assert.match(stemErrors(s).join('\n'), /before part \(a\)/);
});
