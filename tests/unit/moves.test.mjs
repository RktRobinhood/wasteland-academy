// curriculum/moves.json and moves-map.json: the explainer moves and the move for every
// worked step of every built method (FAL-425). Runs the same check as `node tools/moves.mjs --check`.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { load, check, coverage } from '../../tools/moves.mjs';

const data = load();
const clone = () => ({ ...data, moves: structuredClone(data.moves), map: structuredClone(data.map) });
const errorsOf = d => check(d).errors.join('\n');
const move = (d, id) => d.moves.moves.find(m => m.id === id);
const firstKey = Object.keys(data.map.map)[0];

test('the move list and the step map pass tools/moves.mjs', () => {
  assert.deepEqual(check(data).errors, []);
});

test('every built type in the catalogue has its methods in the map', () => {
  const mapped = new Set(Object.keys(data.map.map).map(k => k.split('/')[0]));
  assert.ok(mapped.size >= 32, `only ${mapped.size} types mapped`);
});

test('the check catches a say line with a number, a symbol or a banned word', () => {
  for (const say of ['Take the square root of both sides twice.', 'Set x equal to the answer.', 'Now we just factorise the brackets.', 'Divide by 2 on each side.']) {
    const d = clone();
    move(d, 'state-answer').say = say;
    assert.match(errorsOf(d), /state-answer: say (has a number|breaks)/, say);
  }
});

test('the check catches a bad or duplicate id and a short say line', () => {
  const d = clone();
  d.moves.moves.push({ ...structuredClone(move(d, 'expand')) });
  move(d, 'factorise').id = 'Factorise';
  move(d, 'isolate').say = 'Isolate it.';
  const errors = errorsOf(d);
  assert.match(errors, /expand: duplicate id/);
  assert.match(errors, /Factorise: id must be/);
  assert.match(errors, /isolate: say has 2 words/);
});

test('the check catches an unknown move, a wrong step count and an unknown method', () => {
  const d = clone();
  const [n, list] = Object.entries(d.map.map[firstKey])[0];
  d.map.map[firstKey][n] = [...list.slice(0, -1), 'no-such-move'];
  d.map.map[firstKey]['50'] = ['state-answer'];
  d.map.map['fn-no-such-type/x/y'] = { 1: ['state-answer'] };
  const errors = errorsOf(d);
  assert.match(errors, /no move no-such-move/);
  assert.match(errors, /needs exactly 50 entries/);
  assert.match(errors, /unknown type fn-no-such-type/);
});

test('coverage counts tagged steps and flags a step count the map lacks', () => {
  const [type, unknown, angle] = firstKey.split('/');
  const [n, list] = Object.entries(data.map.map[firstKey])[0];
  const steps = Array.from({ length: Number(n) }, (_, i) => `step ${i}`);
  const q = solSteps => ({ view: { type, unknown, rep: 'equation' }, solutions: [{ angle, steps: solSteps }] });
  const missing = Array.from({ length: 50 }, (_, i) => `step ${i}`);
  const cov = coverage(data, { questions: [q(steps), q(missing)] });
  assert.equal(cov.total.steps, Number(n) + 50);
  assert.equal(cov.total.tagged, list.filter(m => m !== null).length);
  assert.match(cov.errors.join('\n'), /not in the map with/);
});

test('the check catches a branch with a missing step, a bad pattern or an unknown move', () => {
  const d = clone();
  d.map.branches.push({ key: firstKey, steps: '50', index: 0, match: 'x', move: 'state-answer' });
  d.map.branches.push({ key: d.map.branches[0].key, steps: d.map.branches[0].steps, index: 0, match: '(', move: 'no-such-move' });
  const errors = errorsOf(d);
  assert.match(errors, /no such method and step count/);
  assert.match(errors, /match is not a valid pattern/);
  assert.match(errors, /no move no-such-move/);
});
