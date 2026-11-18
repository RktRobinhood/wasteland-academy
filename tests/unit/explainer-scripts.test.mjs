// writing/explainers/: every script, callbacks.json and reactions.json against writing/explainers/README.md
// (tools/explainer-scripts.mjs, FAL-952, FAL-1043, FAL-1087). Each bad fixture below is pilot 1 (format 2)
// or the exemplar, One In, One Out (format 3), with one rule broken.
import { test } from 'node:test';
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {
  loadContext, loadScripts, checkScript, checkScripts, checkRepeats, checkReactions, sayHash, writeManifest, checkManifest, lines,
  runs, recordedWords,
} from '../../tools/explainer-scripts.mjs';
import { evaluate } from '../../tools/explainer-items.mjs';
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

test('the scripts are format 2 or 3, and none is approved while it still has words to fix', () => {
  const { drafts } = checkScripts(ctx, scripts);
  for (const { file, script } of scripts) {
    assert.ok([2, 3].includes(script.format), file);
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
  ['format 1', s => { s.format = 1; }, /format is 1; scripts are format 3/],
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
  assert.deepEqual(checkManifest(ctx.manifest, scripts, ctx.callbacks, ctx.reactions).errors, []);
  const s = structuredClone(pilot), l = line(s);
  const all = [...scripts.filter(x => x.file !== PILOT), { file: PILOT, script: s }];
  l.say = 'Something new.';
  assert.match(checkManifest(ctx.manifest, all, ctx.callbacks, ctx.reactions).errors.join('\n'), new RegExp(`line ${l.line} is not up to date`));
  // Write it, take the line out: its id is retired, and using it again is an error.
  const m = writeManifest(ctx.manifest, all, ctx.callbacks, ctx.reactions);
  const gone = section(s, 'cold-open').beats.shift();
  const m2 = writeManifest(m, all, ctx.callbacks, ctx.reactions);
  assert.ok(m2.retired[pilot.id][gone.line]);
  section(s, 'cold-open').beats.unshift(gone);
  assert.match(checkManifest(m2, all, ctx.callbacks, ctx.reactions).errors.join('\n'), /the id was retired/);
  // A take made from another say: a to-do for a draft, an error once recorded.
  const m3 = writeManifest(ctx.manifest, all, ctx.callbacks, ctx.reactions);
  m3.lines[pilot.id][l.line].take = { say: '0000000000000000', provider: 'gemini' };
  assert.match(checkManifest(m3, all, ctx.callbacks, ctx.reactions).todo.join('\n'), /say changed since its take/);
  s.status = 'recorded';
  assert.match(checkManifest(m3, all, ctx.callbacks, ctx.reactions).errors.join('\n'), /say changed since its take/);
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

// ── Format 3: the four acts and the player actions (#216) ──
const EX = 'ex.functions.function-machine.json';
const exemplar = scripts.find(s => s.file === EX).script;
const opener = s => section(s, 'opener');
const call = s => opener(s).beats.find(b => b.predict).predict;
const toy = s => section(s, 'play').beats.find(b => b.toy && !b.optional);
const build = s => section(s, 'example-2').beats.find(b => b.build).build;
const typed = s => section(s, 'example-3').beats.find(b => b.typed).typed;
const recapBack = s => section(s, 'recap').beats.find(b => b.back_to).back_to;
const broken3 = edit => { const s = structuredClone(exemplar); edit(s); return checkScript(s, ctx, EX).errors.join('\n'); };
const todo3 = edit => { const s = structuredClone(exemplar); edit(s); return checkScript(s, ctx, EX).todo.join('\n'); };
const say = (words, line = 'zzzz01') => ({ line, speaker: 'rook-dead-air', say: Array.from({ length: words }, () => 'signal').join(' ') + '.' });

test('the exemplar is format 3, in the four acts, and passes with no errors', () => {
  assert.equal(exemplar.format, 3);
  assert.deepEqual(exemplar.sections.map(s => s.act), ['signal', 'play', 'paper', 'paper', 'paper', 'paper', 'paper', 'apply', 'apply', 'apply']);
  assert.deepEqual(checkScript(exemplar, ctx, EX).errors, []);
});
test('the exemplar holds its word limits, and records fewer words than the approved script did', () => {
  const r = runs(exemplar, ctx, 'beats');
  assert.ok(r[0].words <= 60, `${r[0].words} words before the first action`);
  assert.ok(Math.max(...r.map(x => x.words)) <= 100);
  assert.ok(recordedWords(exemplar) <= 1000);
  assert.ok(recordedWords(exemplar) < 1150, 'the approved script recorded 1150');
  assert.ok(r.length >= 14, `${r.length} player actions`);
});
test('the proposal points to the exemplar', () => {
  const md = fs.readFileSync(new URL('../../writing/explainers/proposals/one-in-one-out.interactive.md', import.meta.url), 'utf8');
  assert.match(md.split('\n').slice(0, 5).join('\n'), /ex\.functions\.function-machine\.json/);
});

const RULES3 = [
  // Acts
  ['an act out of order', s => { s.sections[2].act = 'signal'; s.sections[2].kind = 'opener'; }, /act signal is out of order/],
  ['a section kind its act does not hold', s => { section(s, 'spot-the-slip').act = 'paper'; }, /a spot-the-slip section is not part of act paper/],
  ['an unknown act', s => { section(s, 'play').act = 'intermission'; }, /act intermission is not one of/],
  ['no opener first', s => { s.sections.shift(); }, /starts with its opener/],
  ['no recap last', s => { s.sections.pop(); }, /ends with its recap/],
  ['an opener with no call', s => { opener(s).beats = opener(s).beats.filter(b => !b.predict); }, /the opener holds one predict/],
  ['a play section with no toy', s => { section(s, 'play').beats = section(s, 'play').beats.filter(b => !b.toy); }, /a play section has a toy/],
  ['a build example with no build', s => { const e = section(s, 'example-2'); e.beats = e.beats.filter(b => !b.build); }, /a build example has a build/],
  ['an unknown example level', s => { section(s, 'example-1').level = 'gentle'; }, /example level gentle is not one of/],
  ['an exam turn in act 3', s => { section(s, 'turn-1').turn.kind = 'exam'; }, /a your-turn in act paper is a twin turn/],
  // Lines
  ['a say with no speaker', s => { delete opener(s).beats[0].speaker; }, /a spoken line has a speaker/],
  ['a spoken line outside sections', s => { s.extra = [say(3)]; }, /a spoken line goes under sections/],
  // The call
  ['a predict of an unknown kind', s => { call(s).kind = 'shout'; }, /predict kind is type, dial or choose, not shout/],
  ['a choose predict whose answer is not a choice', s => { Object.assign(call(s), { kind: 'choose', choices: ['5', '13'] }); }, /−13 is not one of the choices/],
  ['a predict with two answers and one check', s => { call(s).answer = ['5', '−5']; }, /more than one answer has no single check/],
  ['a dial predict whose answer is off the dial', s => { Object.assign(call(s), { kind: 'dial', dial: [-3, 3] }); }, /the answer 5 is off the dial/],
  ['a predict whose check gives another answer', s => { call(s).answer = '13'; }, /the answer is 13, but its check "\(−3\)² − 4" gives 5/],
  ['a predict value that is the answer', s => { call(s).values[0].value = '5'; delete call(s).values[0].check; }, /the value 5 is the answer or another value/],
  ['a predict value with an unknown misconception', s => { call(s).values[0].misconception = 'fn-nothing#9'; }, /misconception fn-nothing#9 is not in curriculum\/question-types\.json/],
  ['a predict value whose check disagrees', s => { call(s).values[0].check = '(−3)² + 4'; }, /the value −13 is −13, but its check "\(−3\)² \+ 4" gives 13/],
  ['two predicts with one id', s => { opener(s).beats.push(structuredClone(opener(s).beats.find(b => b.predict))); }, /the opener holds one predict|predict id call is used twice/],
  ['a back_to with no predict', s => { recapBack(s).predict = 'hunch'; }, /back_to hunch is not a predict earlier in the script/],
  ['a back_to value the predict does not name', s => { recapBack(s).values[0].value = '−5'; }, /−5 is not one of predict call's values/],
  // Toys
  ['a toy not in the catalogue', s => { toy(s).toy = 'kettle'; }, /toy kettle is not in writing\/explainers\/toys\.json/],
  ['a task kind the toy does not take', s => { toy(s).tasks[0].kind = 'juggle'; }, /the relay toy has no task kind juggle/],
  ['a send off the dial', s => { toy(s).tasks[1].input = 9; }, /send input 9 is not a whole number on the dial/],
  ['a find no input on the dial gives', s => { toy(s).tasks[3].output = 13; delete toy(s).tasks[3].place; }, /no input on the dial \[-5,5\] gives 13/],
  ['a find with the wrong place', s => { toy(s).tasks[3].place = 'Dry Flats'; }, /place Dry Flats is not the relay's place for 12/],
  ['a rule the relay cannot read', s => { toy(s).rule = 'x² −'; }, /the relay can't read its rule/],
  ['a dial the wrong way round', s => { toy(s).dial = [5, -5]; }, /dial is two whole numbers, least first/],
  ['a toy with no tasks', s => { toy(s).tasks = []; }, /a toy has at least one task/],
  // Build
  ['a build step with two tiles', s => { build(s).steps[0].tiles.pop(); }, /a build step has three tiles, not 2/],
  ['a right tile keyed to a misconception', s => { build(s).steps[0].tiles[0].misconception = 'fn-pre-substitute#0'; }, /the right tile names no misconception/],
  ['a wrong tile with no misconception', s => { delete build(s).steps[0].tiles[1].misconception; }, /a wrong tile is keyed to a misconception/],
  ['a wrong tile with no not-yet line', s => { build(s).steps[0].not_yet[0].for = [1]; }, /a wrong tile has a not-yet line/],
  ['two tiles that write the same line', s => { const t = build(s).steps[0].tiles; t[2].write = t[1].write; }, /no two tiles write the same one/],
  ['a build answer out of range', s => { build(s).steps[0].answer = 3; }, /answer 3 is not an index of its 3 tiles/],
  ['a not-yet line for the right tile', s => { build(s).steps[0].not_yet[0].for = [0, 1, 2]; }, /for 0 is not a wrong tile/],
  // Typed
  ['a typed answer outside an example', s => { section(s, 'the-name').beats.push({ typed: structuredClone(typed(s)) }); for (const l of lines(section(s, 'the-name').beats.at(-1))) l[0].line = `zz${l[0].line.slice(2)}`; }, /a typed answer goes inside an example/],
  ['a typed answer for a part the problem lacks', s => { typed(s).part = 'd'; }, /part d is not one of the example's parts/],
  ['a typed answer its check disagrees with', s => { typed(s).answer = '72'; }, /the answer is 72, but its check "20 \+ 12 × 5" gives 80/],
  ['a typed not-yet line keyed to no wrong answer', s => { typed(s).not_yet[0].misconception = 'fn-pre-substitute#0'; }, /is not the misconception of one of the typed answer's wrong answers/],
  ['a typed wrong answer that is right', s => { typed(s).wrong = [{ answer: '80%', misconception: 'fn-pre-substitute#0' }]; }, /80% is also the right answer/],
];
for (const [name, edit, want] of RULES3) test(`the check catches ${name}`, () => assert.match(broken3(edit), want));

const TODOS3 = [
  ['a predict the recap never returns to', s => { const r = section(s, 'recap'); r.beats = r.beats.filter(b => !b.back_to); }, /the recap never returns to predict call/],
  ['a recap back_to with no line for a misconception value', s => { recapBack(s).values = []; }, /no line for a call of −13 \(fn-pre-substitute#0\)/],
  ['a recap back_to with no line for any other call', s => { delete recapBack(s).other; }, /no line for any other call/],
  ['a recap back_to with no line for a match', s => { delete recapBack(s).match; }, /no line for a call that matched/],
  ['more than 60 words before the first action', s => { opener(s).beats.unshift(say(30)); }, /\d+ spoken words before the first player action; the opener asks for the call within 60/],
  ['more than 100 words between two actions', s => { section(s, 'the-name').beats.splice(1, 0, say(60)); }, /\d+ spoken words between two player actions; at most 100/],
  ['more than 1,000 recorded words', s => { section(s, 'recap').beats.push(...Array.from({ length: 6 }, (_, i) => say(10, `zzzz1${i}`))); }, /recorded words, every branch counted; at most 1000/],
  ['a first worked example with no setting', s => { delete section(s, 'example-1').problem.setting; }, /the first worked example has no setting from its zone/],
  ['a typed answer with no neutral not-yet line', s => { typed(s).not_yet = []; }, /has 0 neutral lines; key every not-yet line but one/],
  ['a lesson with slips and no reactions for its tutor', s => { s.tutor = 'tin-can-tess'; }, /tin-can-tess has no reaction lines in reactions\.json/],
];
for (const [name, edit, want] of TODOS3) test(`the check lists ${name} as a to-do`, () => assert.match(todo3(edit), want));

test('a call can be a tapped option, or have more than one right answer', () => {
  const ok = edit => assert.deepEqual(broken3(edit), '');
  ok(s => { Object.assign(call(s), { kind: 'choose', choices: ['5', '13', '−13'] }); });
  ok(s => { delete call(s).check; call(s).answer = ['5', '−5']; });
});
test('a note in exceptions lets a long script or an example with no setting through', () => {
  const quiet = s => { s.exceptions = { recorded_words: 'Two worked examples need the full stem.', first_example_setting: 'Exam wording.' }; };
  assert.doesNotMatch(todo3(s => { quiet(s); section(s, 'recap').beats.push(...Array.from({ length: 6 }, (_, i) => say(10, `zzzz1${i}`))); }), /recorded words/);
  assert.doesNotMatch(todo3(s => { quiet(s); delete section(s, 'example-1').problem.setting; }), /no setting/);
});
test('a branch counts towards the run it opens, and an optional toy is off the main path', () => {
  const base = runs(exemplar, ctx, 'beats');
  const s = structuredClone(exemplar);
  const t = toy(s).tasks[1].then.find(b => b.back_to).back_to;
  t.other.push(say(40));
  const longer = runs(s, ctx, 'beats');
  assert.equal(longer[3].words, base[3].words + 40);
  assert.equal(longer.length, base.length);
  delete section(s, 'play').beats.find(b => b.optional).optional;
  assert.equal(runs(s, ctx, 'beats').length, base.length + 1);
});
test('an approved script that plays reactions fails while reactions.json is a draft', () => {
  const s = structuredClone(exemplar);
  s.status = 'approved';
  const out = checkScripts(ctx, [...scripts.filter(x => x.file !== EX), { file: EX, script: s }]).errors.join('\n');
  assert.match(out, /plays reactions\.json, which is a draft/);
});

// ── reactions.json (#220) ──
const reactionTodo = edit => { const r = structuredClone(ctx.reactions); edit(r); return checkReactions(r, ctx).todo.join('\n'); };
const reactionErr = edit => { const r = structuredClone(ctx.reactions); edit(r); return checkReactions(r, ctx).errors.join('\n'); };
test('reactions.json passes, and Rook has acknowledgements and slip reactions', () => {
  assert.deepEqual(checkReactions(ctx.reactions, ctx).errors, []);
  assert.ok(ctx.reactions.tutors['rook-dead-air'].ack.length >= 2);
  assert.ok(ctx.reactions.tutors['rook-dead-air'].slip.length >= 3);
});
test('the check lists a reaction that names a number', () => assert.match(reactionTodo(r => { r.tutors['rook-dead-air'].slip[0].say = 'Static. Three fuses gone.'; }), /a reaction says "three"/));
test("the check lists a reaction that breaks its tutor's rules", () => assert.match(reactionTodo(r => { r.tutors['tin-can-tess'] = { ack: [{ line: 'zzzzt1', speaker: 'tin-can-tess', say: 'Sweet as.' }, { line: 'zzzzt2', speaker: 'tin-can-tess', say: 'Choice.' }], slip: [{ line: 'zzzzt3', speaker: 'tin-can-tess', say: 'Oops, that went wrong.' }, { line: 'zzzzt4', speaker: 'tin-can-tess', say: 'Back on the bench.' }, { line: 'zzzzt5', speaker: 'tin-can-tess', say: 'Bit off, eh.' }] }; }), /tin-can-tess never says "wrong"/));
test('the check lists a tutor with too few slip reactions', () => assert.match(reactionTodo(r => { r.tutors['rook-dead-air'].slip.length = 2; }), /fewer than three slip reactions/));
test('the check catches a reaction spoken by another tutor', () => assert.match(reactionErr(r => { r.tutors['rook-dead-air'].ack[0].speaker = 'calc'; }), /a rook-dead-air reaction is spoken by calc/));
test('the check catches a reaction set with another key', () => assert.match(reactionErr(r => { r.tutors['rook-dead-air'].praise = []; }), /a tutor's reactions are ack and slip/));
test('a recorded reactions.json needs a take for every line, as a recorded script does', () => {
  const r = structuredClone(ctx.reactions);
  r.status = 'recorded';
  // Rook's reactions have takes (FAL-1110), so take one away.
  const m = structuredClone(ctx.manifest);
  const [id] = Object.keys(m.lines.reactions);
  m.lines.reactions[id].take = null;
  assert.match(checkManifest(m, scripts, ctx.callbacks, r).errors.join('\n'), new RegExp(`reactions line ${id}: the script is recorded, but this line has no take`));
});

// ── Every spoken line is in the manifest (#189) ──
// Lines are found under sections (scripts) and tutors (callbacks.json, reactions.json). A line
// anywhere else in a file would have no manifest entry, so no take and no recording.
test('every say in every explainer file has a manifest entry', () => {
  const says = v => { const out = []; (function walk(x) { if (Array.isArray(x)) return x.forEach(walk); if (x && typeof x === 'object') { if ('say' in x) out.push(x); Object.values(x).forEach(walk); } })(v); return out; };
  const files = [...scripts.map(({ script }) => [script.id, script]), ['callbacks', ctx.callbacks], ['reactions', ctx.reactions]];
  for (const [key, f] of files) for (const l of says(f)) assert.ok(ctx.manifest.lines[key]?.[l.line], `${key}: "${l.say}" (${l.line}) is not in the manifest`);
});
test('a line the exemplar kept from the approved script kept its id and its say hash', () => {
  for (const id of ['taxdom', 'u6isa0', 'ug8rex', 'shxoyu', 'd1ax0c', 'rwww0h', 'xqw813']) {
    const l = [...lines(exemplar.sections)].map(([x]) => x).find(x => x.line === id);
    assert.ok(l, id);
    assert.equal(ctx.manifest.lines[exemplar.id][id].say, sayHash(l));
  }
});

// ── Arithmetic for checks (tools/explainer-items.mjs) ──
const SUMS = [['(−3)² − 4', 5], ['−3² − 4', -13], ['20 + 12 × 5', 80], ['6 − 2(−4)', 14], ['5 − (−2)²', 1], ['2^-1', 0.5], ['12 ÷ 4 × 3', 9]];
for (const [src, want] of SUMS) test(`"${src}" works out to ${want}`, () => assert.equal(evaluate(src), want));
test('a rule in x is worked out at an input, with implied multiplication', () => {
  assert.equal(evaluate('x² − 4', { x: -3 }), 5);
  assert.equal(evaluate('6 − 2x', { x: -4 }), 14);
  assert.equal(evaluate('3(x + 1)', { x: 2 }), 9);
  assert.throws(() => evaluate('x + y', { x: 1 }), /no value for y/);
  assert.throws(() => evaluate('(2 + 3', {}), /not closed/);
});
