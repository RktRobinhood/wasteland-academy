#!/usr/bin/env node
// ── COURSE AUDIT ─────────────────────────────────────────────
// Where the engine stands for each IB course, so the order of the rollout comes from
// numbers. For every course and syllabus topic it counts the skills the course has, the
// skills with a question type in the catalogue ("catalogued") and the skills a built
// question tests ("playable"); then which subtopics have no type at all, and which
// catalogued types to build next, ranked by the skills they would make playable.
//
//   tools/course-audit                       builds the report and prints these tables
//   node tools/course-audit.mjs <report>     the tables from a report tools/course-audit made
//
// The report is game/tools/course_report.gd's JSON: the types the engine can make, and
// per course the types, unknowns and cells it covers (Courses, FAL-397). The curriculum
// maps and curriculum/question-types.json give the rest. Nothing is written to the repo:
// the numbers change with every type that lands, so they are not committed.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const readJSON = f => JSON.parse(fs.readFileSync(path.isAbsolute(f) ? f : path.join(ROOT, f), 'utf8'));

const LAYERS = [['aa-sl', 'AA SL'], ['aa-hl', 'AA HL-only'], ['ai', 'AI-only']];
const TOP = 15;

export function build(report) {
  const courses = readJSON('game/data/courses.json').courses.map(c => ({ id: c.id, short: c.short }));
  const typesDoc = readJSON('curriculum/question-types.json').types;

  // skill id -> where it sits in the curriculum
  const skills = new Map();
  const subtopics = [];
  for (const [layer] of LAYERS) {
    for (const t of readJSON(`curriculum/${layer}.json`).topics)
      for (const st of t.subtopics) {
        if (st.retired) continue;
        const sub = { id: st.id, title: st.title, topic: t.topic, topicName: t.name, layer, courses: st.courses, skills: st.skills.map(s => s.id) };
        subtopics.push(sub);
        for (const s of st.skills) skills.set(s.id, sub);
      }
  }

  // type id -> the skills it lists (its own and its unknowns'), and unknown -> skills
  const typeSkills = new Map();
  const unknownSkills = new Map();
  for (const t of typesDoc) {
    const set = new Set(t.skills || []);
    for (const u of t.unknowns || []) {
      unknownSkills.set(`${t.id}|${u.id}`, u.skills || []);
      for (const s of u.skills || []) set.add(s);
    }
    typeSkills.set(t.id, set);
  }
  const catalogued = new Set([...typeSkills.values()].flatMap(s => [...s]));

  const built = new Set(report.built);
  const rows = [];
  const playableBy = {};
  for (const c of courses) {
    const inCourse = new Set([...skills].filter(([, sub]) => sub.courses.includes(c.id)).map(([id]) => id));
    const playable = new Set();
    const rep = report.courses[c.id] || { cells: 0, types: {} };
    for (const [typeId, info] of Object.entries(rep.types))
      for (const u of info.unknowns)
        for (const s of unknownSkills.get(`${typeId}|${u}`) || []) if (inCourse.has(s)) playable.add(s);
    playableBy[c.id] = { inCourse, playable };
    for (const n of [1, 2, 3, 4, 5]) {
      const subs = subtopics.filter(s => s.topic === n && s.courses.includes(c.id));
      const ids = subs.flatMap(s => s.skills);
      rows.push({
        course: c.id, topic: n, name: subs[0]?.topicName ?? '', subtopics: subs.length, skills: ids.length,
        catalogued: ids.filter(s => catalogued.has(s)).length, playable: ids.filter(s => playable.has(s)).length,
      });
    }
  }
  const totals = Object.fromEntries(courses.map(c => {
    const r = rows.filter(x => x.course === c.id);
    const sum = k => r.reduce((a, x) => a + x[k], 0);
    return [c.id, { subtopics: sum('subtopics'), skills: sum('skills'), catalogued: sum('catalogued'), playable: sum('playable'), cells: report.courses[c.id]?.cells ?? 0 }];
  }));

  // Subtopics with no type in the catalogue: the content still to design, by layer.
  const noType = [];
  for (const sub of subtopics) {
    const missing = sub.skills.filter(s => !catalogued.has(s));
    if (missing.length) noType.push({ id: sub.id, title: sub.title, topic: sub.topic, layer: sub.layer, courses: sub.courses, skills: missing.length, of: sub.skills.length });
  }

  // Catalogued types not built, ranked by the skills each would make playable.
  const unbuilt = [];
  for (const t of typesDoc) {
    if (built.has(t.id)) continue;
    const unlocks = {};
    for (const c of courses) {
      const { inCourse, playable } = playableBy[c.id];
      unlocks[c.id] = [...typeSkills.get(t.id)].filter(s => inCourse.has(s) && !playable.has(s)).length;
    }
    const total = Object.values(unlocks).reduce((a, b) => a + b, 0);
    if (total) unbuilt.push({ id: t.id, name: t.name, topic: t.topic, source: t.source, parts: t.stats?.parts ?? 0, unlocks, total });
  }
  unbuilt.sort((a, b) => b.total - a.total || b.parts - a.parts || a.id.localeCompare(b.id));

  return { courses, rows, totals, noType, unbuilt, markdown: render({ courses, rows, totals, noType, unbuilt }) };
}

function render({ courses, rows, totals, noType, unbuilt }) {
  const row = cells => `| ${cells.join(' | ')} |`;
  const pct = (a, b) => (b ? `${Math.round((100 * a) / b)}%` : '0%');
  const md = ['# Course audit', '',
    'Skills a course has, skills with a question type in the catalogue (**catalogued**), and skills a built question tests (**playable**).', '',
    row(['Course', 'Subtopics', 'Skills', 'Catalogued', 'Playable', 'Playable %', 'Cells']),
    row(['---', '--:', '--:', '--:', '--:', '--:', '--:']),
    ...courses.map(c => { const t = totals[c.id]; return row([c.short, t.subtopics, t.skills, t.catalogued, t.playable, pct(t.playable, t.skills), t.cells]); }), ''];
  for (const c of courses) {
    md.push(`## ${c.short} by topic`, '', row(['Topic', 'Subtopics', 'Skills', 'Catalogued', 'Playable']), row(['---', '--:', '--:', '--:', '--:']),
      ...rows.filter(r => r.course === c.id).map(r => row([`${r.topic}. ${r.name}`, r.subtopics, r.skills, r.catalogued, r.playable])), '');
  }

  md.push('## Subtopics with no question type', '',
    'Skills no type lists. Each needs its types designed (`curriculum/question-types.json`) before a generator can be built. A subtopic is counted once, under the courses that list it.', '',
    row(['Layer', 'Subtopics', 'Skills without a type', 'Courses']), row(['---', '--:', '--:', '---']));
  for (const [layer, label] of LAYERS) {
    const list = noType.filter(x => x.layer === layer);
    if (!list.length) continue;
    const cs = courses.filter(c => list.some(x => x.courses.includes(c.id))).map(c => c.short).join(', ');
    md.push(row([label, list.length, list.reduce((a, x) => a + x.skills, 0), cs]));
  }
  md.push('');
  for (const n of [1, 2, 3, 4, 5]) {
    const list = noType.filter(x => x.topic === n);
    if (!list.length) continue;
    md.push(`- **Topic ${n}:** ` + list.map(x => `${x.id} ${x.title} (${x.skills}${x.skills === x.of ? '' : ` of ${x.of}`})`).join('; ') + '.');
  }

  md.push('', `## Types to build next`, '',
    `Catalogued types the engine cannot make yet, with the skills each would make playable in each course (its skills the course covers that have no built question). The top ${TOP} by total, then by exam parts.`, '',
    row(['Type', 'Topic', ...courses.map(c => c.short), 'Total', 'Exam parts']), row(['---', '--:', ...courses.map(() => '--:'), '--:', '--:']),
    ...unbuilt.slice(0, TOP).map(t => row([`\`${t.id}\``, t.topic, ...courses.map(c => t.unlocks[c.id]), t.total, t.parts])), '');
  return md.join('\n');
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const file = process.argv[2];
  if (!file) {
    console.error('usage: node tools/course-audit.mjs <report.json>   (tools/course-audit makes the report first)');
    process.exit(2);
  }
  console.log(build(readJSON(path.resolve(file))).markdown);
}
