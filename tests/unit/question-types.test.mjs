// curriculum/question-types.json: the exam question-type catalogue.
// The full check against the question bank is tools/question-types.mjs --bank;
// these tests need no bank and keep the committed file consistent.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

const read = f => JSON.parse(fs.readFileSync(new URL(`../../${f}`, import.meta.url), 'utf8'));
const doc = read('curriculum/question-types.json');
const map = read('curriculum/aa-sl.json');
const skillIds = new Set(map.topics.flatMap(t => t.subtopics.flatMap(st => st.skills.map(sk => sk.id))));
const FORMATS = ['mcq', 'value', 'multipart', 'error-spot', 'method-pick', 'match',
                 'order-steps', 'graph-pick', 'true-false-reason'];

test('type IDs are unique', () => {
  const ids = doc.types.map(t => t.id);
  assert.equal(new Set(ids).size, ids.length);
});

test('every bank part is assigned once, or listed as unclassified with a reason', () => {
  const all = [...doc.types.flatMap(t => t.parts), ...doc.unclassified.map(u => u.part)];
  assert.equal(new Set(all).size, all.length, 'a part appears twice');
  assert.equal(all.length, doc.bank.parts);
  for (const u of doc.unclassified) assert.ok(u.reason, u.part);
});

test('skills and formats exist in aa-sl.json', () => {
  for (const t of doc.types) {
    assert.ok(t.skills.length, `${t.id} has no skills`);
    for (const s of t.skills) assert.ok(skillIds.has(s), `${t.id}: unknown skill ${s}`);
    for (const f of t.formats || []) assert.ok(FORMATS.includes(f), `${t.id}: bad format ${f}`);
  }
});

test('Functions types carry every field a recipe needs', () => {
  const full = doc.types.filter(t => t.detail === 'full');
  assert.ok(full.length > 0);
  for (const t of full) {
    assert.equal(t.topic, 2, t.id);
    for (const f of ['name', 'summary', 'syllabus', 'skills', 'skillFit', 'chain', 'given', 'asked',
                     'answerForms', 'randomise', 'constraints', 'formats', 'parts', 'stats'])
      assert.ok(t[f] && (!Array.isArray(t[f]) || t[f].length), `${t.id}: missing ${f}`);
    if (t.skillFit === 'partial') assert.ok(t.skillGap, `${t.id}: partial fit needs skillGap`);
    assert.equal(t.stats.parts, t.parts.length, `${t.id}: stats are stale; rerun tools/question-types.mjs --write`);
  }
});
