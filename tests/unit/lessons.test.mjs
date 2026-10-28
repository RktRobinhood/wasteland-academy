// curriculum/lessons.json: the design-down map of Relic lessons (FAL-327).
// Runs the same check as `node tools/lessons.mjs --check` and keeps LESSONS.md in step.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { load, check, render, format } from '../../tools/lessons.mjs';

const data = load();
const result = check(data);
const clone = () => ({ ...data, lessons: structuredClone(data.lessons) });
const lesson = (d, id) => d.lessons.lessons.find(l => l.id === id);
const errorsOf = d => check(d).errors.join('\n');

test('the lesson map passes tools/lessons.mjs', () => {
  assert.deepEqual(result.errors, []);
});

test('every Functions exam type has a lesson or a gaps entry', () => {
  const supported = new Set(data.lessons.lessons.flatMap(l => l.supports));
  const gaps = new Set(data.lessons.gaps.map(g => g.type));
  for (const t of data.doc.types.filter(t => t.topic === 2 && t.source === 'exam'))
    assert.ok(supported.has(t.id) || gaps.has(t.id), t.id);
});

test('the check catches a duplicate or badly formed id', () => {
  const d = clone();
  d.lessons.lessons.push({ ...structuredClone(lesson(d, 'lesson.fn.gradient')) });
  assert.match(errorsOf(d), /lesson\.fn\.gradient: duplicate id/);
  const e = clone();
  lesson(e, 'lesson.fn.gradient').id = 'lesson.fn.Gradient';
  assert.match(errorsOf(e), /id must look like/);
});

test('the check catches a missing skill, type or misconception', () => {
  const d = clone();
  const l = lesson(d, 'lesson.fn.gradient');
  l.skills.push('SL2.1.no-such-skill');
  l.supports.push('fn-no-such-type');
  l.misconceptions.push('SL2.1.gradient#9');
  const errors = errorsOf(d);
  assert.match(errors, /unknown skill SL2\.1\.no-such-skill/);
  assert.match(errors, /supports unknown type fn-no-such-type/);
  assert.match(errors, /no misconception SL2\.1\.gradient#9/);
});

test('the check catches a prerequisite cycle', () => {
  const d = clone();
  lesson(d, 'lesson.fn.gradient').prerequisites.push('lesson.fn.perpendicular');
  assert.match(errorsOf(d), /prerequisite cycle/);
});

test('the check catches an exam type with no lesson and no gap', () => {
  const d = clone();
  for (const l of d.lessons.lessons) {
    l.supports = l.supports.filter(t => t !== 'fn-transform-apply');
    delete l.unknowns?.['fn-transform-apply'];
  }
  assert.match(errorsOf(d), /exam type fn-transform-apply has no lesson/);
  d.lessons.gaps = [{ type: 'fn-transform-apply', reason: 'test' }];
  assert.doesNotMatch(errorsOf(d), /fn-transform-apply has no lesson/);
});

test('lessons.json and LESSONS.md are up to date', () => {
  const json = fs.readFileSync(new URL('../../curriculum/lessons.json', import.meta.url), 'utf8');
  assert.equal(json, format(data.lessons) + '\n', 'rerun node tools/lessons.mjs --write');
  const md = fs.readFileSync(new URL('../../curriculum/LESSONS.md', import.meta.url), 'utf8');
  assert.equal(md, render(data, result.counts), 'rerun node tools/lessons.mjs --write');
});
