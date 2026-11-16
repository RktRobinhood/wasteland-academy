// curriculum/question-types.json: the exam question-type catalogue.
// The full check against the question bank is tools/question-types.mjs --bank;
// these tests need no bank and keep the committed file consistent.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

const read = f => JSON.parse(fs.readFileSync(new URL(`../../${f}`, import.meta.url), 'utf8'));
const doc = read('curriculum/question-types.json');
// Extension types have no bank parts; tests/unit/pedagogy.test.mjs covers them.
const exam = doc.types.filter(t => t.source === 'exam');
const map = read('curriculum/aa-sl.json');
const skillIds = new Set(map.topics.flatMap(t => t.subtopics.flatMap(st => st.skills.map(sk => sk.id))));
const FORMATS = ['mcq', 'value', 'multipart', 'error-spot', 'method-pick', 'match',
                 'order-steps', 'graph-pick', 'true-false-reason'];

test('every type says where it comes from', () => {
  for (const t of doc.types) assert.ok(['exam', 'extension'].includes(t.source), `${t.id}: source`);
  assert.equal(exam.length, exam.filter(t => t.parts?.length).length, 'every exam type has bank parts');
});

test('type IDs are unique', () => {
  const ids = doc.types.map(t => t.id);
  assert.equal(new Set(ids).size, ids.length);
});

test('every bank part is assigned once, or listed as unclassified with a reason', () => {
  const all = [...exam.flatMap(t => t.parts), ...doc.unclassified.map(u => u.part)];
  assert.equal(new Set(all).size, all.length, 'a part appears twice');
  assert.equal(all.length, doc.bank.parts);
  for (const u of doc.unclassified) assert.ok(u.reason, u.part);
});

test('skills and formats exist in aa-sl.json', () => {
  for (const t of exam) {
    assert.ok(t.skills.length, `${t.id} has no skills`);
    for (const s of t.skills) assert.ok(skillIds.has(s), `${t.id}: unknown skill ${s}`);
    for (const f of t.formats || []) assert.ok(FORMATS.includes(f), `${t.id}: bad format ${f}`);
  }
});

test('full-detail types carry every field a recipe needs', () => {
  const full = exam.filter(t => t.detail === 'full');
  assert.ok(full.length > 0);
  for (const t of full) {
    assert.ok(t.topic === 2 || t.situation, `${t.id}: a full type outside Functions needs a situation`);
    for (const f of ['name', 'summary', 'syllabus', 'skills', 'skillFit', 'chain', 'given', 'asked',
                     'answerForms', 'randomise', 'constraints', 'formats', 'parts', 'stats'])
      assert.ok(t[f] && (!Array.isArray(t[f]) || t[f].length), `${t.id}: missing ${f}`);
    if (t.skillFit === 'partial') assert.ok(t.skillGap, `${t.id}: partial fit needs skillGap`);
    assert.equal(t.stats.parts, t.parts.length, `${t.id}: stats are stale; rerun tools/question-types.mjs --write`);
  }
});

// The exchange with the bank (GH #134): one pinned commit for the catalogue and the bank's
// unbuilt HL and AI types, and per-course counts in which every part is counted once.
const bankTypes = read('curriculum/bank-types.json');

test('the catalogue and the unbuilt bank types are pinned to one bank commit', () => {
  assert.match(doc.bank.commit, /^[0-9a-f]{40}$/);
  assert.equal(bankTypes.bank.commit, doc.bank.commit, 'rerun tools/question-types.mjs --write');
  assert.ok(bankTypes.types.length > 0);
});

test('per-course counts add up, and AA SL is assigned up to bank.assigned', () => {
  assert.deepEqual(Object.keys(doc.bank.courses), ['aa-sl', 'aa-hl', 'ai-sl', 'ai-hl']);
  for (const [id, c] of Object.entries(doc.bank.courses)) {
    assert.equal(c.assigned + c.unclassified + c.unassigned, c.parts, id);
    assert.equal(Object.values(c.papers).reduce((n, p) => n + p.parts, 0), c.parts, `${id}: parts per paper`);
  }
  assert.equal(doc.bank.courses['aa-sl'].assigned + doc.bank.courses['aa-sl'].unclassified, doc.bank.parts);
  assert.ok(doc.bank.assigned['aa-sl']);
  // Paper and calculator are separate: AI Paper 1 allows a GDC, AA Paper 1 does not; Paper 3 is HL only.
  assert.equal(doc.bank.courses['aa-sl'].papers.P1.calculator, false);
  assert.equal(doc.bank.courses['ai-sl'].papers.P1.calculator, true);
  assert.ok(doc.bank.courses['aa-hl'].papers.P3 && doc.bank.courses['ai-hl'].papers.P3 && !doc.bank.courses['aa-sl'].papers.P3);
});
