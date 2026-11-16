// curriculum/signoff.json: which situations have had their prompts and worked steps
// read by a person (GitHub #193, FAL-1033). Keeps the list in step with the catalogue.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

const read = f => JSON.parse(fs.readFileSync(new URL(`../../curriculum/${f}`, import.meta.url), 'utf8'));
const doc = read('question-types.json');
const list = read('signoff.json');

test('every situation is on the sign-off list once, and nothing else is', () => {
  const ids = list.situations.map(r => r.situation);
  assert.equal(new Set(ids).size, ids.length, 'a situation is listed twice');
  assert.deepEqual([...ids].sort(), Object.keys(doc.situations).sort(), 'add or remove rows to match question-types.json');
});

test('each row names the types built on its situation, and whether one is an exam type', () => {
  for (const r of list.situations) {
    const ts = doc.types.filter(t => t.situation === r.situation);
    assert.deepEqual([...r.types].sort(), ts.map(t => t.id).sort(), r.situation);
    assert.equal(r.exam, ts.some(t => t.source === 'exam'), `${r.situation}: exam`);
  }
});

test('exam situations come first, and every status is known', () => {
  const firstNon = list.situations.findIndex(r => !r.exam);
  assert.ok(firstNon === -1 || list.situations.slice(firstNon).every(r => !r.exam), 'exam situations first');
  for (const r of list.situations) {
    assert.ok(r.status in list.statuses, `${r.situation}: status ${r.status}`);
    if (r.status !== 'unread') assert.ok(r.readBy && /^\d{4}-\d\d-\d\d$/.test(r.date) && r.note, `${r.situation}: who, when and what`);
  }
});
