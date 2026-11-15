// curriculum/explainers.json: the explainer map across all four courses (FAL-935).
// Runs the same check as `node tools/explainers.mjs --check` and keeps EXPLAINERS.md in step.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { load, check, render, refresh, index, COURSES } from '../../tools/explainers.mjs';
import { format } from '../../tools/lessons.mjs';

const data = load();
const result = check(data);
const clone = () => ({ ...data, file: structuredClone(data.file) });
const node = (d, id) => d.file.explainers.find(n => n.id === id);
const errorsOf = d => check(refresh(d)).errors.join('\n');

test('the explainer map passes tools/explainers.mjs', () => {
  assert.deepEqual(result.errors, []);
});

test('every subtopic of every course has an explainer in that course', () => {
  const { subtopics } = index(data);
  for (const [id, st] of subtopics) for (const c of st.courses)
    assert.ok(data.file.explainers.some(n => n.zone !== 'foundations' && n.subtopics.includes(id) && n.courses.includes(c)), `${id} in ${c}`);
  for (const c of COURSES) assert.ok(result.counts.course[c] > 0, c);
});

test('every Relic lesson has exactly one explainer, with the lesson slug', () => {
  for (const l of data.lessons.lessons) {
    const ex = data.file.explainers.filter(n => n.lesson === l.id);
    assert.equal(ex.length, 1, l.id);
    assert.equal(ex[0].id.split('.').pop(), l.id.split('.').pop());
  }
});

test('the check catches a duplicate id, an unknown reference and a bad id', () => {
  const d = clone();
  d.file.explainers.push(structuredClone(node(d, 'ex.functions.gradient')));
  assert.match(errorsOf(d), /ex\.functions\.gradient: duplicate id/);
  const e = clone();
  const n = node(e, 'ex.functions.line-equation');
  n.prereqs.push('ex.functions.no-such-explainer');
  n.related.push('ex.stats.no-such-explainer');
  n.subtopics.push('SL9.9');
  n.skills.push('SL2.1.no-such-skill');
  n.lesson = 'lesson.fn.no-such-lesson';
  const errors = errorsOf(e);
  assert.match(errors, /unknown prerequisite ex\.functions\.no-such-explainer/);
  assert.match(errors, /unknown related explainer ex\.stats\.no-such-explainer/);
  assert.match(errors, /unknown subtopic SL9\.9/);
  assert.match(errors, /unknown skill SL2\.1\.no-such-skill/);
  assert.match(errors, /unknown lesson lesson\.fn\.no-such-lesson/);
  const f = clone();
  node(f, 'ex.functions.gradient').id = 'ex.island.gradient';
  assert.match(errorsOf(f), /id must look like ex\.<zone>\.<slug>/);
});

test('the check catches a prerequisite cycle', () => {
  const d = clone();
  node(d, 'ex.functions.gradient').prereqs.push('ex.functions.perpendicular');
  assert.match(errorsOf(d), /prerequisite cycle/);
});

test('the check catches a subtopic that loses its explainer in a course', () => {
  const d = clone();
  for (const n of d.file.explainers) if (n.subtopics.includes('AI-SL3.6')) n.courses = ['ai-hl'];
  assert.match(errorsOf(d), /AI-SL3\.6 \(AI SL\)/);
});

test('the check catches courses outside the subtopics, and an SL course without its HL', () => {
  const d = clone();
  node(d, 'ex.functions.zero-product').courses = ['aa-sl', 'aa-hl', 'ai-sl', 'ai-hl'];
  assert.match(errorsOf(d), /zero-product: course ai-sl is not a course of any of its subtopics/);
  const e = clone();
  node(e, 'ex.algebra.arithmetic-sequence').courses = ['aa-sl', 'ai-sl', 'ai-hl'];
  assert.match(errorsOf(e), /arithmetic-sequence: an AA SL explainer is in AA HL too/);
});

test('the check catches a prerequisite that a course of the explainer does not have', () => {
  // binomial-probability is in all four courses; pascal-ncr (the binomial theorem) is AA only.
  const d = clone();
  node(d, 'ex.stats.binomial-probability').prereqs.push('ex.algebra.pascal-ncr');
  node(d, 'ex.stats.binomial-probability').related = [];
  assert.match(errorsOf(d), /binomial-probability: prerequisite ex\.algebra\.pascal-ncr is not in AI SL, AI HL/);
});

test('explainer prerequisites follow the lesson prerequisites wherever the courses allow', () => {
  const d = clone();
  node(d, 'ex.functions.line-equation').prereqs = ['ex.foundations.pre-balance'];
  assert.match(errorsOf(d), /line-equation: lesson lesson\.fn\.line-equation needs lesson\.fn\.gradient/);
  // parabola-symmetry is shared by all four courses, so its lesson prerequisite zero-product (AA only) may be left out.
  assert.ok(!node(data, 'ex.functions.parabola-symmetry').prereqs.includes('ex.functions.zero-product'));
  assert.ok(data.lessons.lessons.find(l => l.id === 'lesson.fn.parabola-symmetry').prerequisites.includes('lesson.fn.zero-product'));
});

test('every explainer is built after its prerequisites', () => {
  const rank = new Map(data.file.explainers.map(n => [n.id, n.priority.rank]));
  for (const n of data.file.explainers) for (const p of n.prereqs) assert.ok(rank.get(p) < rank.get(n.id), `${n.id} before ${p}`);
});

test('explainers.json and EXPLAINERS.md are up to date', () => {
  const json = fs.readFileSync(new URL('../../curriculum/explainers.json', import.meta.url), 'utf8');
  assert.equal(json, format(refresh(clone()).file) + '\n', 'rerun node tools/explainers.mjs --write');
  const md = fs.readFileSync(new URL('../../curriculum/EXPLAINERS.md', import.meta.url), 'utf8');
  assert.equal(md, render(data, result.counts), 'rerun node tools/explainers.mjs --write');
});
