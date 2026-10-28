// The course layers of the curriculum map and the course index (FAL-393).
// Runs the same check as `node tools/courses.mjs` and keeps the generated files in step.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { build, OUT } from '../../tools/courses.mjs';

const result = build();
const read = f => fs.readFileSync(new URL('../../' + f, import.meta.url), 'utf8');

test('aa-sl.json, aa-hl.json and ai.json pass tools/courses.mjs', () => {
  assert.deepEqual(result.errors, []);
});

test('the course index lists the four courses, every one with five topics', () => {
  assert.deepEqual(result.index.courses.map(c => c.id), ['aa-sl', 'aa-hl', 'ai-sl', 'ai-hl']);
  assert.deepEqual(result.index.courses.map(c => c.status), ['live', 'mapped', 'mapped', 'mapped']);
  for (const c of result.index.courses) {
    assert.deepEqual(c.topics.map(t => t.n), [1, 2, 3, 4, 5], c.id);
    for (const t of c.topics) assert.ok(t.subtopics > 0 && t.skills > 0, `${c.id} topic ${t.n}`);
  }
});

test('course hours match the guides: 120 for SL and 210 for HL', () => {
  const hours = Object.fromEntries(result.index.courses.map(c => [c.id, c.topics.reduce((s, t) => s + t.hours, 0)]));
  assert.deepEqual(hours, { 'aa-sl': 120, 'aa-hl': 210, 'ai-sl': 120, 'ai-hl': 210 });
});

test('AA HL contains all of AA SL, and AI HL all of AI SL', () => {
  const by = Object.fromEntries(result.index.courses.map(c => [c.id, c]));
  for (const [sl, hl] of [['aa-sl', 'aa-hl'], ['ai-sl', 'ai-hl']])
    for (const t of by[sl].topics) assert.ok(by[hl].topics[t.n - 1].skills > t.skills, `${hl} topic ${t.n}`);
});

test('game/data/courses.json and curriculum/COURSES.md are up to date', () => {
  assert.equal(read(OUT.json), result.jsonText, 'rerun node tools/courses.mjs --write');
  assert.equal(read(OUT.md), result.mdText, 'rerun node tools/courses.mjs --write');
});
