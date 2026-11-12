// curriculum/question-types.json: the situation-and-view catalogue (FAL-311).
// Runs the same check as `node tools/pedagogy.mjs` and keeps PEDAGOGY_GAPS.md in step.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { load, check, render } from '../../tools/pedagogy.mjs';

const data = load();
const result = check(data);

test('the pedagogy catalogue passes tools/pedagogy.mjs', () => {
  assert.deepEqual(result.errors, []);
});

test('every skill has a type and every thread a link type', () => {
  assert.equal(result.counts.skillsTyped, result.counts.skills);
  const linked = new Set(data.doc.types.filter(t => t.kind === 'link').map(t => t.thread));
  for (const th of data.threads.threads) assert.ok(linked.has(th.id), th.id);
});

test('every Functions type is placed in a region and carries views', () => {
  for (const t of data.doc.types.filter(t => t.topic === 2)) {
    assert.ok(t.region, `${t.id}: region`);
    assert.ok(t.unknowns?.length && t.angles?.length && t.representations?.length, `${t.id}: views`);
  }
});

test('curriculum/PEDAGOGY_GAPS.md is up to date', () => {
  const file = fs.readFileSync(new URL('../../curriculum/PEDAGOGY_GAPS.md', import.meta.url), 'utf8');
  assert.equal(file, render(data, result.counts), 'rerun node tools/pedagogy.mjs --write');
});

// "Exam-style only" keys on exam eligibility, not provenance (FAL-796, GH #132): an
// extension skill type may mark exam unknowns when it gives examStyle; nothing else may.
test('only exam types and extension skill types with examStyle have exam views', () => {
  const counting = data.doc.types.find(t => t.id === 't1-ahl-counting');
  assert.equal(counting.source, 'extension');
  assert.ok(counting.examStyle && counting.unknowns.some(u => u.exam));
  const without = { ...counting, examStyle: undefined };
  const concept = { ...counting, kind: 'concept' };
  for (const t of [without, concept]) {
    const doc = { ...data.doc, types: data.doc.types.map(o => (o === counting ? t : o)) };
    const errors = check({ ...data, doc }).errors.filter(e => e.startsWith('t1-ahl-counting'));
    assert.ok(errors.some(e => /exam unknown|exam representations|examStyle/.test(e)), JSON.stringify(errors));
  }
});
