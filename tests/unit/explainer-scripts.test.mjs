// writing/explainers/ex.*.json: every script against the format in writing/explainers/README.md
// (tools/explainer-scripts.mjs, FAL-952). Each bad fixture below is pilot 1 with one rule broken.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { loadContext, loadScripts, checkScript, checkScripts } from '../../tools/explainer-scripts.mjs';

const ctx = loadContext();
const scripts = loadScripts();
const PILOT = 'ex.algebra.arithmetic-sequence.json';
const pilot = scripts.find(s => s.file === PILOT).script;
const section = (s, id) => s.sections.find(x => x.id === id);
const firstLine = (s, id) => section(s, id).beats.find(b => b.say);
const slip = s => section(s, 'spot-the-slip');
const ask = (s, id) => section(s, id).beats.find(b => b.ask).ask;

// Break one rule on a copy of pilot 1 and return the errors.
const broken = edit => { const s = structuredClone(pilot); edit(s); return checkScript(s, ctx, PILOT).join('\n'); };

test('both pilots pass, and every script in writing/explainers is checked', () => {
  assert.ok(scripts.length >= 2);
  for (const f of [PILOT, 'ex.algebra.arithmetic-series.json']) assert.ok(scripts.some(s => s.file === f), f);
  assert.deepEqual(checkScripts(ctx, scripts).errors, []);
});

const RULES = [
  // Map
  ['an id that is not in the map', s => { s.id = 'ex.algebra.no-such-explainer'; }, /is not in curriculum\/explainers\.json/],
  ['courses that differ from the map', s => { s.courses = ['aa-sl', 'aa-hl']; }, /courses: .* does not match the map's/],
  ['skills that differ from the map', s => { s.skills.push('SL1.2.find-n'); }, /skills: .* does not match the map's/],
  ['a builds_on that is not a prereq', s => { s.builds_on = ['ex.foundations.pre-balance']; }, /builds_on: ex\.foundations\.pre-balance is not one of the map's prereqs/],
  ['a leads_to that does not exist', s => { s.leads_to = ['ex.algebra.no-such-explainer']; }, /leads_to: ex\.algebra\.no-such-explainer is not in/],
  // References
  ['an unknown move', s => { section(s, 'example-1').beats.find(b => b.board?.some(x => x.move)).board.find(x => x.move).move = 'wave-hands'; }, /move wave-hands is not in curriculum\/moves\.json/],
  ['an unknown speaker', s => { firstLine(s, 'cold-open').speaker = 'nobody'; }, /speaker nobody is not in tools\/explainer-clips\/teachers\.json/],
  ['an unknown callback', s => { section(s, 'recall').watched.find(b => b.use).use = 'mags-the-ledger.own.forgot'; }, /use mags-the-ledger\.own\.forgot is not in callbacks\.json/],
  ['an unknown cue', s => { firstLine(s, 'cold-open').cue = 'yodels'; }, /cue yodels is not in callbacks\.json cues/],
  ['an unknown turn type', s => { section(s, 'turn-1').turn.type = 't9-no-such-type'; }, /type t9-no-such-type is not in curriculum\/question-types\.json/],
  // Structure
  ['sections out of arc order', s => { s.sections.reverse(); }, /is out of arc order/],
  ['a recall with neither version', s => { delete section(s, 'recall').not_watched; }, /a recall section has both watched and not_watched/],
  ['a no-prerequisite recall in a script that builds on one', s => { const r = section(s, 'recall'); r.builds_on = null; r.beats = r.watched; }, /builds_on null is only for a script with no builds_on/],
  ['a no-prerequisite recall with no beats', s => { s.builds_on = []; const r = section(s, 'recall'); r.builds_on = null; delete r.watched; delete r.not_watched; }, /a recall section with builds_on null has beats/],
  ['an unknown section kind', s => { section(s, 'recap').kind = 'encore'; }, /unknown section kind encore/],
  ['a strike with no board key', s => { slip(s).beats.find(b => b.board?.some(x => x.strike)).board.find(x => x.strike).strike = 's9'; }, /strike s9 is not an earlier board key/],
  ['a tap-line choice with no board key', s => { ask(s, 'spot-the-slip').choices[0] = 's9'; }, /tap-line choice s9 is not a board key/],
  ['an answer index out of range', s => { const a = ask(s, 'example-1'); a.answer = a.choices.length; }, /answer \d+ is not an index of its \d+ choices/],
  // Words
  ['a digit in a caption', s => { firstLine(s, 'cold-open').say = 'Row 40 has the most seats.'; }, /say has a digit/],
  ['a banned word in a caption', s => { firstLine(s, 'cold-open').say = 'This one is easy.'; }, /say uses "easy"/],
  ['a joke that writes on the board', s => { const b = firstLine(s, 'cold-open'); b.joke = true; b.board = [{ write: 'ha' }]; }, /a joke line writes on the board/],
];

for (const [name, edit, want] of RULES) test(`the check catches ${name}`, () => assert.match(broken(edit), want));
