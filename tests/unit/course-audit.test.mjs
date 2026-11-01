// The course audit's numbers (tools/course-audit.mjs): what each IB course has, which of
// its skills have a question type, and which a built question tests. The report from
// Godot is faked here, so these run with the curriculum alone.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { build } from '../../tools/course-audit.mjs';

const read = f => JSON.parse(fs.readFileSync(new URL('../../' + f, import.meta.url), 'utf8'));
const COURSES = ['aa-sl', 'aa-hl', 'ai-sl', 'ai-hl'];
const nothing = { built: [], courses: Object.fromEntries(COURSES.map(c => [c, { cells: 0, types: {} }])) };
const types = read('curriculum/question-types.json').types;

test('every course has five topics, and a skill is never playable without a type', () => {
  const { rows } = build(nothing);
  assert.equal(rows.length, 20);
  for (const r of rows) {
    assert.ok(r.skills > 0 && r.subtopics > 0, `${r.course} topic ${r.topic}`);
    assert.ok(r.catalogued <= r.skills && r.playable <= r.catalogued, `${r.course} topic ${r.topic}`);
  }
});

test('with nothing built, nothing is playable and the build list is every type that lists a course skill', () => {
  const { totals, unbuilt } = build(nothing);
  for (const c of COURSES) assert.equal(totals[c].playable, 0, c);
  assert.ok(unbuilt.length > 0);
  for (const t of unbuilt) assert.equal(t.total, Object.values(t.unlocks).reduce((a, b) => a + b, 0), t.id);
});

test('AA HL has all of AA SL and AI HL all of AI SL', () => {
  const { totals } = build(nothing);
  assert.ok(totals['aa-hl'].skills > totals['aa-sl'].skills);
  assert.ok(totals['ai-hl'].skills > totals['ai-sl'].skills);
  assert.ok(totals['aa-hl'].catalogued >= totals['aa-sl'].catalogued);
  assert.ok(totals['ai-hl'].catalogued >= totals['ai-sl'].catalogued);
});

test('a built unknown makes the skills it lists playable in the courses that cover it', () => {
  const type = types.find(t => t.id === 't1-arithmetic-sequence');
  const unknown = type.unknowns[0];
  const report = {
    built: [type.id],
    courses: Object.fromEntries(COURSES.map(c => [c, { cells: 4, types: { [type.id]: { cells: 4, unknowns: [unknown.id] } } }])),
  };
  const before = build(nothing).totals;
  const after = build(report);
  for (const c of COURSES) {
    const gained = after.totals[c].playable - before[c].playable;
    // SL1.2 is shared by all four courses, so each gains the unknown's skills.
    assert.equal(gained, unknown.skills.length, c);
    assert.equal(after.totals[c].cells, 4, c);
  }
  assert.ok(!after.unbuilt.some(t => t.id === type.id), 'a built type is off the build list');
});

test('a skill a course does not cover is not counted for it', () => {
  const type = types.find(t => t.id === 't1-arithmetic-sequence');
  const only = { built: [type.id], courses: { ...nothing.courses, 'aa-sl': { cells: 1, types: { [type.id]: { cells: 1, unknowns: [type.unknowns[0].id] } } } } };
  const { totals } = build(only);
  assert.ok(totals['aa-sl'].playable > 0);
  assert.equal(totals['aa-hl'].playable, 0, 'the report lists nothing for AA HL');
});

test('the subtopics without a type are the HL-only and AI-only layers', () => {
  const { noType } = build(nothing);
  assert.ok(noType.length > 0);
  for (const x of noType) assert.ok(['aa-hl', 'ai', 'aa-sl'].includes(x.layer), x.id);
  const saSl = noType.filter(x => x.layer === 'aa-sl');
  assert.deepEqual(saSl, [], 'every AA SL skill has a type');
});

test('the markdown has the headline table, a table per course and the build list', () => {
  const { markdown } = build(nothing);
  assert.match(markdown, /^# Course audit/);
  for (const c of ['AA SL', 'AA HL', 'AI SL', 'AI HL']) assert.match(markdown, new RegExp(`## ${c} by topic`));
  assert.match(markdown, /## Subtopics with no question type/);
  assert.match(markdown, /## Types to build next/);
});
