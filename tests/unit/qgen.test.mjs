// QGen's helpers, loaded from js/question-gen.js as the browser does
import { test } from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { loadScripts } from '../content/packs.mjs';

const QGen = vm.runInContext('QGen', loadScripts(['js/question-gen.js']));

test('fraction(): value equals num/den, including when it reduces', () => {
  for (let i = 0; i < 2000; i++) {
    const f = QGen.fraction();
    assert.ok(Math.abs(f.value - f.num / f.den) < 1e-12, JSON.stringify(f));
    assert.equal(QGen._gcd(f.num, f.den), 1);
  }
});

test('shuffle(): every order of 3 items is about equally likely', () => {
  const counts = {};
  const N = 60000;
  for (let i = 0; i < N; i++) {
    const k = QGen.shuffle(['a', 'b', 'c']).join('');
    counts[k] = (counts[k] || 0) + 1;
  }
  assert.equal(Object.keys(counts).length, 6);
  // Expected N/6 = 10000 each; the old sort-based shuffle gave ~3700–18700
  for (const [k, n] of Object.entries(counts)) assert.ok(Math.abs(n - N / 6) < 600, `${k}: ${n}`);
});

test('shuffle() does not change its input', () => {
  const a = [1, 2, 3, 4];
  QGen.shuffle(a);
  assert.deepEqual(a, [1, 2, 3, 4]);
});

test('poly(): signs and unit coefficients', () => {
  assert.equal(QGen.poly([[3, 'x^2'], [-5, 'x'], [2, '']]), '3x^2 - 5x + 2');
  assert.equal(QGen.poly([[1, 'x^2'], [0, 'x'], [-1, '']]), 'x^2 - 1');
  assert.equal(QGen.poly([[-1, 'x'], [1, '']]), '-x + 1');
  assert.equal(QGen.poly([[0, 'x'], [0, '']]), '0');
  assert.equal(QGen.poly([[0, 'x'], [-4, '']]), '-4');
});

test('signed(), pow(), frac(), chain()', () => {
  assert.equal(`x${QGen.signed(-5)}`, 'x - 5');
  assert.equal(`x${QGen.signed(5)}`, 'x + 5');
  assert.equal(`x${QGen.signed(0)}`, 'x');
  assert.equal(QGen.pow('x', 1), 'x');
  assert.equal(QGen.pow('x', 0), '');
  assert.equal(QGen.pow('x', 3), 'x^{3}');
  assert.equal(QGen.frac(-4, 6, 'x'), '-\\dfrac{2}{3}x');
  assert.equal(QGen.frac(4, -6), '-\\dfrac{2}{3}');
  assert.equal(QGen.frac(4, 2, 'x'), '2x');
  assert.equal(QGen.frac(-3, 3, 'x'), '-x');
  assert.equal(QGen.chain('f(2)', '3(2)', '3(2)', 6), 'f(2) = 3(2) = 6');
});

test('expand(): MCQ answers that are LaTeX strings are shown, not $NaN$', () => {
  const t = {
    id: 't', type: 'parametric', difficulty: 2, outputType: 'mcq',
    params: () => ({}),
    question: () => 'Q',
    answer: () => '\\dfrac{1}{2}',
    mcqDistractors: () => ['\\dfrac{1}{2}', 'a', 'a', 'b', 'c', 'd'],
  };
  const q = QGen.expand(t);
  assert.equal(q.id, 't');
  assert.equal(q.options[q.correctIndex], '$\\dfrac{1}{2}$');
  // Distractors that repeat the answer or each other are skipped
  assert.deepEqual([...q.options.filter((_, i) => i !== q.correctIndex)], ['$a$', '$b$', '$c$']);
});

test('expand(): too few distinct distractors fails instead of showing duplicates', () => {
  const t = {
    id: 't', type: 'parametric', difficulty: 2, outputType: 'mcq',
    question: () => 'Q', answer: () => 'x', mcqDistractors: () => ['x', 'y', 'y', 'z'],
  };
  const warn = console.warn;
  console.warn = () => {};
  try { assert.equal(QGen.expand(t), null); } finally { console.warn = warn; }
});
