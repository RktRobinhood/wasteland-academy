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
