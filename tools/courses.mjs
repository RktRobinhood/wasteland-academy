#!/usr/bin/env node
// ── COURSE INDEX ─────────────────────────────────────────────
// Checks the three layers of the curriculum map and builds the course index.
//
//   node tools/courses.mjs           print the summary to stdout
//   node tools/courses.mjs --write   also write game/data/courses.json and curriculum/COURSES.md
//   node tools/courses.mjs --check   validate only; exit 1 on any error or if the generated files are stale
//
// Layers: curriculum/aa-sl.json (AA SL), aa-hl.json (AA HL-only) and ai.json
// (AI-only). A course is every subtopic, in any layer, whose `courses` lists it.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { ENUMS } from './map-schema.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const readJSON = f => JSON.parse(fs.readFileSync(path.join(ROOT, f), 'utf8'));

const COURSES = [
  { id: 'aa-sl', short: 'AA SL', name: 'Analysis and Approaches SL', status: 'live' },
  { id: 'aa-hl', short: 'AA HL', name: 'Analysis and Approaches HL', status: 'mapped' },
  { id: 'ai-sl', short: 'AI SL', name: 'Applications and Interpretation SL', status: 'mapped' },
  { id: 'ai-hl', short: 'AI HL', name: 'Applications and Interpretation HL', status: 'mapped' },
];
const COURSE_IDS = COURSES.map(c => c.id);

// Each layer: its file, the subtopic ID pattern, and the courses its subtopics must list.
const LAYERS = [
  { key: 'aa-sl', file: 'curriculum/aa-sl.json', idRe: /^SL([1-5])\.\d+$/,
    mustHave: () => ['aa-sl', 'aa-hl'], mayAdd: ['ai-sl', 'ai-hl'] },
  { key: 'aa-hl', file: 'curriculum/aa-hl.json', idRe: /^AHL([1-5])\.\d+$/,
    mustHave: () => ['aa-hl'], mayAdd: [] },
  { key: 'ai', file: 'curriculum/ai.json', idRe: /^AI-(?:SL|AHL)([1-5])\.\d+$/,
    mustHave: id => id.startsWith('AI-SL') ? ['ai-sl', 'ai-hl'] : ['ai-hl'], mayAdd: [] },
];
const THIN_FIELDS = ['difficulty', 'formats', 'representations', 'methods', 'misconceptions'];

// Validate the three layers and build the index. Returns everything the CLI and the tests need.
export function build() {
  const threadIds = new Set(readJSON('curriculum/threads.json').threads.map(t => t.id));
  const layers = LAYERS.map(l => ({ ...l, map: readJSON(l.file) }));
  const byKey = Object.fromEntries(layers.map(l => [l.key, l]));

  // ── 1. Validate ──────────────────────────────────────────────
  const errors = [];
  const warnings = [];
  const subtopics = new Map();   // id -> { st, topic, layer }
  const skills = new Set();

  for (const l of layers) {
    for (const t of l.map.topics) {
      if (!(t.topic >= 1 && t.topic <= 5)) errors.push(`${l.file}: bad topic number ${t.topic}`);
      for (const st of t.subtopics) {
        const m = l.idRe.exec(st.id);
        if (!m) errors.push(`${l.file}: subtopic ID ${st.id} does not fit this file`);
        else if (Number(m[1]) !== t.topic) errors.push(`${st.id}: listed under topic ${t.topic}`);
        if (subtopics.has(st.id)) errors.push(`duplicate subtopic ${st.id}`);
        subtopics.set(st.id, { st, topic: t.topic, layer: l.key });
        if (!st.title) errors.push(`${st.id}: no title`);
        if (st.retired) continue;
        const cs = st.courses || [];
        for (const c of cs) if (!COURSE_IDS.includes(c)) errors.push(`${st.id}: unknown course ${c}`);
        for (const c of l.mustHave(st.id)) if (!cs.includes(c)) errors.push(`${st.id}: courses must include ${c}`);
        for (const c of cs) if (!l.mustHave(st.id).includes(c) && !l.mayAdd.includes(c)) errors.push(`${st.id}: course ${c} does not belong in ${l.file}`);
        if (!st.skills?.length) errors.push(`${st.id}: no skills`);
        for (const sk of st.skills || []) {
          const where = `${st.id} ${sk.id}`;
          if (skills.has(sk.id)) errors.push(`duplicate skill ${sk.id}`);
          skills.add(sk.id);
          if (!sk.id?.startsWith(st.id + '.')) errors.push(`${where}: skill ID must start with ${st.id}.`);
          if (!sk.name) errors.push(`${where}: no name`);
          if (!ENUMS.paper.includes(sk.paper)) errors.push(`${where}: bad paper ${sk.paper}`);
          if (l.key === 'ai' && sk.paper !== 'p2') errors.push(`${where}: AI skills are p2 (every AI paper allows a GDC)`);
          if (sk.difficulty) {
            const [lo, hi] = sk.difficulty;
            if (!(lo >= 1 && hi <= 5 && lo <= hi)) errors.push(`${where}: bad difficulty ${JSON.stringify(sk.difficulty)}`);
          }
          for (const f of sk.formats || []) if (!ENUMS.formats.includes(f)) errors.push(`${where}: bad format ${f}`);
          for (const r of sk.representations || []) if (!ENUMS.representations.includes(r)) errors.push(`${where}: bad representation ${r}`);
          for (const mt of sk.methods || []) if (!ENUMS.approach.includes(mt.approach)) errors.push(`${where}: bad approach ${mt.approach} on ${mt.id}`);
          if (sk.methods?.length === 1 && !sk.singleMethod) errors.push(`${where}: one method but singleMethod not set`);
          for (const th of sk.threads || []) {
            if (!threadIds.has(th.thread)) errors.push(`${where}: unknown thread ${th.thread}`);
            if (!th.echo) errors.push(`${where}: thread ${th.thread} has no echo`);
          }
        }
      }
    }
  }

  const coursesOf = id => subtopics.get(id)?.st.courses || [];
  for (const [id, { st }] of subtopics) {
    for (const p of st.prereqs || []) {
      if (!subtopics.has(p)) { errors.push(`${id}: unknown prereq ${p}`); continue; }
      const gap = coursesOf(id).filter(c => !coursesOf(p).includes(c));
      if (gap.length) warnings.push(`${id} (${gap.join(', ')}) has prereq ${p}, which is not in that course`);
    }
    for (const o of st.overlaps || []) {
      if (!subtopics.has(o)) errors.push(`${id}: unknown overlap ${o}`);
      else if (subtopics.get(o).layer === 'ai') errors.push(`${id}: overlaps must name AA subtopics, not ${o}`);
    }
  }
  // Prereq cycles
  const state = new Map();
  const visit = (id, trail) => {
    if (state.get(id) === 'done') return;
    if (state.get(id) === 'open') { errors.push(`prereq cycle: ${[...trail, id].join(' → ')}`); return; }
    state.set(id, 'open');
    for (const p of subtopics.get(id)?.st.prereqs || []) if (subtopics.has(p)) visit(p, [...trail, id]);
    state.set(id, 'done');
  };
  for (const id of subtopics.keys()) visit(id, []);

  // `shared` in ai.json must agree with the AI courses listed on AA subtopics.
  const shared = byKey.ai.map.shared || [];
  const sharedIds = new Set();
  for (const s of shared) {
    const hit = subtopics.get(s.id);
    if (!hit || hit.layer === 'ai') { errors.push(`shared ${s.ai}: ${s.id} is not an AA subtopic`); continue; }
    sharedIds.add(s.id);
    const want = [...s.courses].sort().join(), have = coursesOf(s.id).filter(c => c.startsWith('ai-')).sort().join();
    if (want !== have) errors.push(`shared ${s.ai} → ${s.id}: ai.json says [${want}], the subtopic says [${have}]`);
    if (Number(s.ai.match(/(\d)\./)?.[1]) !== hit.topic) errors.push(`shared ${s.ai} → ${s.id}: different topics`);
  }
  for (const [id, { layer }] of subtopics)
    if (layer !== 'ai' && coursesOf(id).some(c => c.startsWith('ai-')) && !sharedIds.has(id))
      errors.push(`${id} lists an AI course but is not in ai.json shared`);

  // ── 2. Count ─────────────────────────────────────────────────
  const live = [...subtopics.values()].filter(x => !x.st.retired);
  const topicNames = Object.fromEntries(byKey['aa-sl'].map.topics.map(t => [t.topic, t.name]));
  const topicHours = (course, n) => {
    const sl = byKey['aa-sl'].map.topics.find(t => t.topic === n)?.hours;
    const ahl = byKey['aa-hl'].map.topics.find(t => t.topic === n)?.hours;
    const ai = byKey.ai.map.topics.find(t => t.topic === n)?.hours || {};
    return { 'aa-sl': sl, 'aa-hl': sl + ahl, 'ai-sl': ai.sl, 'ai-hl': ai.sl + ai.ahl }[course];
  };
  const inCourse = (course, n) => live.filter(x => x.topic === n && x.st.courses.includes(course));
  const skillCount = list => list.reduce((s, x) => s + x.st.skills.length, 0);
  const isThin = sk => THIN_FIELDS.some(f => !sk[f]?.length);

  // `subtopics` lists the subtopic IDs the course covers, so the engine can tell which
  // questions a student on that course may be asked (a skill's subtopic is its first two
  // dot-separated parts, as in engine/courses.gd).
  const index = {
    courses: COURSES.map(c => ({
      ...c,
      topics: [1, 2, 3, 4, 5].map(n => {
        const list = inCourse(c.id, n);
        return { n, name: topicNames[n], subtopics: list.length, skills: skillCount(list), hours: topicHours(c.id, n) };
      }),
      subtopics: live.filter(x => x.st.courses.includes(c.id)).map(x => x.st.id),
    })),
  };
  for (const c of index.courses) for (const t of c.topics)
    if (!Number.isFinite(t.hours)) errors.push(`${c.id} topic ${t.n}: no hours`);

  // ── 3. Report ────────────────────────────────────────────────
  const sum = (rows, k) => rows.reduce((s, r) => s + r[k], 0);
  const row = cells => `| ${cells.join(' | ')} |`;
  const md = [
    '# Courses', '',
    'Generated by `node tools/courses.mjs --write` from `curriculum/aa-sl.json`, `aa-hl.json` and `ai.json`. Do not edit by hand.', '',
    'A course is a filter over the shared map: every subtopic whose `courses` lists it. The five islands are the five syllabus topics, which all four courses share. Hours are the guides\' recommended teaching hours for the syllabus content (AA SL 120, HL 210; AI the same), excluding the 30 hours for the toolkit and exploration.', '',
    row(['Course', 'Status', 'Subtopics', 'Skills', 'Hours']),
    row(['---', '---', '--:', '--:', '--:']),
    ...index.courses.map(c => row([`${c.short}: ${c.name}`, c.status, sum(c.topics, 'subtopics'), sum(c.topics, 'skills'), sum(c.topics, 'hours')])),
    '',
  ];
  for (const c of index.courses) {
    md.push(`## ${c.short}: ${c.name}`, '',
      row(['Topic', 'Subtopics', 'Skills', 'Hours']), row(['---', '--:', '--:', '--:']),
      ...c.topics.map(t => row([`${t.n}. ${t.name}`, t.subtopics, t.skills, t.hours])),
      row(['**Total**', `**${sum(c.topics, 'subtopics')}**`, `**${sum(c.topics, 'skills')}**`, `**${sum(c.topics, 'hours')}**`]), '');
  }

  md.push('## What AA HL adds to AA SL', '',
    'AA HL is all of AA SL plus the AHL subtopics in `aa-hl.json`.', '',
    row(['Topic', 'SL subtopics', 'SL skills', 'SL hours', 'AHL subtopics', 'AHL skills', 'AHL hours']),
    row(['---', '--:', '--:', '--:', '--:', '--:', '--:']));
  for (const n of [1, 2, 3, 4, 5]) {
    const s = inCourse('aa-sl', n), h = inCourse('aa-hl', n).filter(x => x.layer === 'aa-hl');
    md.push(row([`${n}. ${topicNames[n]}`, s.length, skillCount(s), topicHours('aa-sl', n), h.length, skillCount(h), topicHours('aa-hl', n) - topicHours('aa-sl', n)]));
  }
  md.push('');
  for (const n of [1, 2, 3, 4, 5]) {
    const h = inCourse('aa-hl', n).filter(x => x.layer === 'aa-hl');
    md.push(`- **${topicNames[n]}:** ` + h.map(x => `${x.st.id} ${x.st.title}`).join('; ') + '.');
  }
  md.push('');

  md.push('## How much AI shares with AA', '',
    'Where an AI content statement matches the AA one, AI reuses the AA subtopic and its skills (listed in `shared` in `ai.json`). Everything else is an `AI-` subtopic. Some of those overlap AA content in part; their `overlaps` field names the AA subtopics.', '',
    row(['Course', 'Subtopics', 'Shared with AA', 'AI-only', 'Skills', 'Shared skills', 'Shared']),
    row(['---', '--:', '--:', '--:', '--:', '--:', '--:']));
  for (const cid of ['ai-sl', 'ai-hl']) {
    const all = live.filter(x => x.st.courses.includes(cid));
    const sh = all.filter(x => x.layer !== 'ai');
    const pct = Math.round(100 * sh.length / all.length);
    md.push(row([COURSES.find(c => c.id === cid).short, all.length, sh.length, all.length - sh.length, skillCount(all), skillCount(sh), `${pct}% of subtopics`]));
  }
  md.push('', row(['Topic', 'AI SL: shared / all', 'AI HL: shared / all']), row(['---', '--:', '--:']));
  for (const n of [1, 2, 3, 4, 5]) {
    const f = cid => { const a = inCourse(cid, n); return `${a.filter(x => x.layer !== 'ai').length} / ${a.length}`; };
    md.push(row([`${n}. ${topicNames[n]}`, f('ai-sl'), f('ai-hl')]));
  }
  md.push('', '**Shared subtopics** (AI guide number → map ID):', '',
    row(['AI guide', 'Map ID', 'Title', 'Courses', 'Note']), row(['---', '---', '---', '---', '---']),
    ...shared.map(s => row([s.ai, s.id, subtopics.get(s.id)?.st.title ?? '?', s.courses.join(', '), s.note ?? ''])), '',
    '**AI-only subtopics that overlap AA in part:**', '',
    row(['AI subtopic', 'Title', 'Overlaps']), row(['---', '---', '---']),
    ...live.filter(x => x.st.overlaps?.length).map(x => row([x.st.id, x.st.title, x.st.overlaps.join(', ')])), '');

  md.push('## Map depth', '',
    `A skill is **thin** when it has only the required fields (id, name, paper) and is missing any of ${THIN_FIELDS.map(f => '`' + f + '`').join(', ')}. Thin skills still count above; they need filling in before a generator is built on them.`, '',
    row(['File', 'Subtopics', 'Skills', 'Thin skills']), row(['---', '--:', '--:', '--:']));
  const thin = [];
  for (const l of layers) {
    const sts = l.map.topics.flatMap(t => t.subtopics).filter(s => !s.retired);
    const sks = sts.flatMap(s => s.skills);
    const th = sks.filter(isThin);
    thin.push(...th.map(s => s.id));
    md.push(row([`\`${l.file.replace('curriculum/', '')}\``, sts.length, sks.length, th.length]));
  }
  md.push('');
  if (thin.length) md.push('Thin skills: ' + thin.map(s => '`' + s + '`').join(', ') + '.', '');
  if (warnings.length) {
    md.push('## Prerequisites outside a course', '',
      'A shared subtopic keeps its AA prerequisites, and some of those are not in every course that uses it. The engine should treat a prerequisite outside the student\'s course as already met.', '',
      ...warnings.map(w => `- ${w}`), '');
  }
  const mdText = md.join('\n');
  const jsonText = JSON.stringify(index, null, 2) + '\n';
  const line = index.courses.map(c => `${c.short} ${sum(c.topics, 'subtopics')}/${sum(c.topics, 'skills')}`).join(', ');
  return { errors, warnings, index, thin, jsonText, mdText, line };
}

// ── 4. Output ────────────────────────────────────────────────
export const OUT = { json: 'game/data/courses.json', md: 'curriculum/COURSES.md' };

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = new Set(process.argv.slice(2));
  const { errors, warnings, thin, jsonText, mdText, line } = build();
  if (errors.length) {
    console.error(`Course map has ${errors.length} error(s):\n  ` + errors.join('\n  '));
    process.exit(1);
  }
  const current = f => fs.existsSync(path.join(ROOT, f)) ? fs.readFileSync(path.join(ROOT, f), 'utf8') : null;
  if (args.has('--check')) {
    const stale = [[OUT.json, jsonText], [OUT.md, mdText]].filter(([f, t]) => current(f) !== t).map(([f]) => f);
    if (stale.length) {
      console.error(`Out of date: ${stale.join(', ')}. Run node tools/courses.mjs --write`);
      process.exit(1);
    }
    console.log(`Courses OK (subtopics/skills): ${line}. ${thin.length} thin skills, ${warnings.length} cross-course prereqs.`);
    process.exit(0);
  }
  if (args.has('--write')) {
    fs.mkdirSync(path.join(ROOT, 'game/data'), { recursive: true });
    fs.writeFileSync(path.join(ROOT, OUT.json), jsonText);
    fs.writeFileSync(path.join(ROOT, OUT.md), mdText);
    console.log(`Wrote ${OUT.json} and ${OUT.md}.`);
  }
  console.log(`Courses (subtopics/skills): ${line}. ${thin.length} thin skills.`);
  for (const w of warnings) console.log(`  note: ${w}`);
}
