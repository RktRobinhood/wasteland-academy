#!/usr/bin/env node
// ── EXPLAINER MAP CHECK ──────────────────────────────────────
// Checks curriculum/explainers.json, the map of every explainer across AA SL, AA HL,
// AI SL and AI HL (FAL-935), against the three course maps, the Relic lessons, the
// question-type catalogue and the concept threads. Then it checks the scripts in
// writing/explainers/ (tools/explainer-scripts.mjs).
//
//   node tools/explainers.mjs            check, print the counts (same as --check)
//   node tools/explainers.mjs --check    check only
//   node tools/explainers.mjs --write    refresh the computed fields in explainers.json,
//                                        check, rewrite curriculum/EXPLAINERS.md
//
// Exit 1 on any error.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { format } from './lessons.mjs';
import { checkScripts } from './explainer-scripts.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const readJSON = f => JSON.parse(fs.readFileSync(path.join(ROOT, f), 'utf8'));
export const OUT = { json: 'curriculum/explainers.json', md: 'curriculum/EXPLAINERS.md' };

export const COURSES = ['aa-sl', 'aa-hl', 'ai-sl', 'ai-hl'];
const COURSE_NAME = { 'aa-sl': 'AA SL', 'aa-hl': 'AA HL', 'ai-sl': 'AI SL', 'ai-hl': 'AI HL' };
// The map zones (game/ui/map.gd, tools/explainer-clips/teachers.json) and their syllabus topic.
export const ZONES = {
  foundations: { topic: null, name: 'Foundations', island: 'prior learning' },
  algebra: { topic: 1, name: 'Number and algebra', island: 'Scrap Fields' },
  functions: { topic: 2, name: 'Functions', island: 'Signal Tower' },
  geometry: { topic: 3, name: 'Geometry and trigonometry', island: 'Dry Flats' },
  stats: { topic: 4, name: 'Statistics and probability', island: 'Radio Spires' },
  calculus: { topic: 5, name: 'Calculus', island: 'Engine Core' },
};
// A layer is the set of courses an explainer is in. Order: widest first.
export const LAYERS = [
  { id: 'core', name: 'Core (all four courses)', courses: ['aa-sl', 'aa-hl', 'ai-sl', 'ai-hl'], style: 'fill:#fff1b8,stroke:#9a7b00,color:#222' },
  { id: 'aa-ai-hl', name: 'AA, plus AI HL', courses: ['aa-sl', 'aa-hl', 'ai-hl'], style: 'fill:#ffd8a8,stroke:#b35c00,color:#222' },
  { id: 'aa-hl-ai', name: 'AA HL, plus AI', courses: ['aa-hl', 'ai-sl', 'ai-hl'], style: 'fill:#fcc2d7,stroke:#a61e4d,color:#222' },
  { id: 'aa', name: 'AA only (SL and HL)', courses: ['aa-sl', 'aa-hl'], style: 'fill:#a5d8ff,stroke:#1864ab,color:#222' },
  { id: 'ai', name: 'AI only (SL and HL)', courses: ['ai-sl', 'ai-hl'], style: 'fill:#b2f2bb,stroke:#2b8a3e,color:#222' },
  { id: 'hl', name: 'HL in both (AA HL and AI HL)', courses: ['aa-hl', 'ai-hl'], style: 'fill:#d0bfff,stroke:#5f3dc4,color:#222' },
  { id: 'aa-hl', name: 'AA HL only', courses: ['aa-hl'], style: 'fill:#4dabf7,stroke:#0b3d75,color:#111' },
  { id: 'ai-hl', name: 'AI HL only', courses: ['ai-hl'], style: 'fill:#51cf66,stroke:#1b5e2a,color:#111' },
];
const OUTSIDE_STYLE = 'fill:#ffffff,stroke:#868e96,stroke-dasharray:4 3,color:#495057';
export const layerOf = courses => LAYERS.find(l => l.courses.length === courses.length && l.courses.every(c => courses.includes(c)))?.id || null;

const ID = /^ex\.(foundations|algebra|functions|geometry|stats|calculus)\.([a-z0-9]+(?:-[a-z0-9]+)*)$/;
const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const REQUIRED = ['id', 'title', 'zone', 'cluster', 'idea', 'courses', 'subtopics'];
// Fields --write fills in; everything else is written by hand.
const COMPUTED = ['layer', 'question_types', 'threads', 'priority'];
const FIELD_ORDER = ['id', 'title', 'zone', 'cluster', 'idea', 'layer', 'courses', 'subtopics', 'skills', 'prereqs', 'related',
  'methods', 'lesson', 'question_types', 'threads', 'priority', 'note'];
// A full stop, question or exclamation mark followed by a space or the end; 4.2 and f(x).y don't count.
const sentences = s => s.split(/[.!?]+(?:\s+|$)/).filter(x => x.trim()).length;

export function load() {
  return {
    file: readJSON(OUT.json),
    maps: ['curriculum/aa-sl.json', 'curriculum/aa-hl.json', 'curriculum/ai.json'].map(readJSON),
    lessons: readJSON('curriculum/lessons.json'),
    doc: readJSON('curriculum/question-types.json'),
    threads: readJSON('curriculum/threads.json'),
    teachers: readJSON('tools/explainer-clips/teachers.json'),
  };
}

// Subtopics and skills of all three layers of the course map.
export function index({ maps }) {
  const subtopics = new Map(), skills = new Map();
  for (const m of maps) for (const t of m.topics) for (const st of t.subtopics) {
    if (st.retired) continue;
    subtopics.set(st.id, { id: st.id, title: st.title, topic: t.topic, courses: st.courses, skills: st.skills.map(s => s.id) });
    for (const s of st.skills) skills.set(s.id, { id: s.id, name: s.name, subtopic: st.id, topic: t.topic, courses: s.courses || st.courses,
      threads: (s.threads || []).map(x => x.thread).filter(Boolean) });
  }
  return { subtopics, skills };
}

// Explainers that need this one, directly or through other explainers.
function dependents(nodes) {
  const kids = new Map(nodes.map(n => [n.id, []]));
  for (const n of nodes) for (const p of n.prereqs || []) kids.get(p)?.push(n.id);
  const out = new Map();
  const visit = id => {
    if (out.has(id)) return out.get(id);
    const s = new Set();
    out.set(id, s);
    for (const k of kids.get(id) || []) { s.add(k); for (const x of visit(k)) s.add(x); }
    return s;
  };
  for (const n of nodes) visit(n.id);
  return out;
}

// The computed fields: layer, the question types an explainer prepares for, its threads,
// its weighted exam parts and its place in the build order.
export function compute(data) {
  const { file, lessons, doc } = data;
  const { skills } = index(data);
  const nodes = file.explainers || [];
  const types = doc.types;
  const lessonById = new Map((lessons.lessons || []).map(l => [l.id, l]));
  const threadOrder = (data.threads.threads || []).map(t => t.id);
  const out = new Map();
  for (const n of nodes) {
    const mine = new Set(n.skills || []);
    const lesson = lessonById.get(n.lesson);
    const qt = [], parts = [];
    for (const t of types) {
      const shared = (t.skills || []).filter(s => mine.has(s)).length;
      const viaLesson = lesson?.supports?.includes(t.id);
      if (!shared && !viaLesson) continue;
      qt.push(t.id);
      if (t.source !== 'exam') continue;
      // Share of the type this explainer prepares for: its skills, or the lesson's exam unknowns.
      let share = t.skills?.length ? shared / t.skills.length : 0;
      if (viaLesson) {
        const exam = t.unknowns.filter(u => u.exam).map(u => u.id);
        const hit = (lesson.unknowns?.[t.id] || []).filter(u => exam.includes(u)).length;
        if (exam.length) share = Math.max(share, hit / exam.length);
      }
      parts.push(t.parts.length * share);
    }
    const th = new Set();
    for (const s of n.skills || []) for (const x of skills.get(s)?.threads || []) th.add(x);
    out.set(n.id, {
      layer: layerOf(n.courses || []),
      question_types: qt,
      threads: threadOrder.filter(t => th.has(t)),
      parts: Math.round(parts.reduce((a, b) => a + b, 0) * 10) / 10,
    });
  }

  // Build order. An explainer always comes after its prerequisites. Among the explainers whose
  // prerequisites are placed, the next is the one with the most exam weight resting on it: its own
  // weighted parts plus those of every explainer that needs it, directly or further on. Ties go to
  // its own weighted parts, then to the explainer more others need, then to the ID.
  const deps = dependents(nodes);
  const byId = new Map(nodes.map(n => [n.id, n]));
  const rows = nodes.map(n => {
    const own = out.get(n.id).parts;
    let lead = own;
    for (const d of deps.get(n.id)) lead += out.get(d)?.parts || 0;
    return { id: n.id, own, lead: Math.round(lead * 10) / 10, unlocks: deps.get(n.id).size };
  });
  rows.sort((a, b) => b.lead - a.lead || b.own - a.own || b.unlocks - a.unlocks || a.id.localeCompare(b.id));
  const placed = new Set();
  let rest = rows, rank = 0;
  while (rest.length) {
    // An unknown prerequisite or a cycle is reported by check(); the plain rule places the rest.
    const next = rest.find(r => (byId.get(r.id).prereqs || []).every(p => placed.has(p) || !byId.has(p))) || rest[0];
    placed.add(next.id);
    rest = rest.filter(r => r !== next);
    Object.assign(out.get(next.id), { rank: ++rank, unlocks: next.unlocks, lead: next.lead });
  }
  return out;
}

// Write the computed fields into each explainer, in the documented field order.
export function refresh(data) {
  const c = compute(data);
  data.file.explainers = data.file.explainers.map(n => {
    const x = c.get(n.id);
    const m = { ...n, layer: x.layer, question_types: x.question_types, threads: x.threads, priority: { parts: x.parts, rank: x.rank } };
    const o = {};
    for (const k of FIELD_ORDER) if (k in m) o[k] = m[k];
    for (const k of Object.keys(m)) if (!(k in o)) o[k] = m[k];
    return o;
  });
  return data;
}

export function check(data) {
  const errors = [], warnings = [];
  const { file, lessons, doc } = data;
  const { subtopics, skills } = index(data);
  const nodes = file.explainers || [];
  const byId = new Map();
  const types = new Map(doc.types.map(t => [t.id, t]));
  const lessonById = new Map((lessons.lessons || []).map(l => [l.id, l]));
  const documented = new Set(Object.keys(file.about?.fields || {}));
  if (!file.about?.text) errors.push('about.text is missing');
  for (const f of FIELD_ORDER) if (!documented.has(f)) errors.push(`about.fields does not document ${f}`);

  for (const n of nodes) {
    const w = n.id || '(no id)';
    if (byId.has(n.id)) errors.push(`${w}: duplicate id`);
    byId.set(n.id, n);
    for (const k of Object.keys(n)) if (!documented.has(k)) errors.push(`${w}: field ${k} is not documented in about.fields`);
    for (const f of REQUIRED) if (n[f] == null || n[f] === '' || (Array.isArray(n[f]) && !n[f].length)) errors.push(`${w}: missing ${f}`);
    const m = ID.exec(n.id || '');
    if (!m) { errors.push(`${w}: id must look like ex.<zone>.<slug>, with zone one of ${Object.keys(ZONES).join(', ')}`); continue; }
    if (n.zone !== m[1]) errors.push(`${w}: zone ${n.zone} does not match the id`);
    if (sentences(n.idea || '') !== 1) errors.push(`${w}: idea should be one sentence`);

    // courses: known, HL contains SL, and within the courses of the subtopics
    const cs = n.courses || [];
    for (const c of cs) if (!COURSES.includes(c)) errors.push(`${w}: unknown course ${c}`);
    if (cs.includes('aa-sl') && !cs.includes('aa-hl')) errors.push(`${w}: an AA SL explainer is in AA HL too`);
    if (cs.includes('ai-sl') && !cs.includes('ai-hl')) errors.push(`${w}: an AI SL explainer is in AI HL too`);
    const stCourses = new Set();
    for (const s of n.subtopics || []) {
      const st = subtopics.get(s);
      if (!st) { errors.push(`${w}: unknown subtopic ${s}`); continue; }
      st.courses.forEach(c => stCourses.add(c));
    }
    for (const c of cs) if (!stCourses.has(c)) errors.push(`${w}: course ${c} is not a course of any of its subtopics (${n.subtopics.join(', ')})`);
    const topics = (n.subtopics || []).map(s => subtopics.get(s)?.topic);
    if (ZONES[n.zone]?.topic && !topics.includes(ZONES[n.zone].topic)) errors.push(`${w}: zone ${n.zone} is topic ${ZONES[n.zone].topic}, but none of its subtopics is`);

    // skills: foundations teach prior learning and list none; every other explainer teaches some
    if (n.zone === 'foundations' && n.skills?.length) errors.push(`${w}: foundations explainers teach prior learning, so they list no skills`);
    if (n.zone !== 'foundations' && !n.skills?.length) errors.push(`${w}: no skills`);
    for (const s of n.skills || []) {
      const sk = skills.get(s);
      if (!sk) errors.push(`${w}: unknown skill ${s}`);
      else if (!(n.subtopics || []).includes(sk.subtopic)) errors.push(`${w}: skill ${s} is in ${sk.subtopic}, which is not in its subtopics`);
      else if (!sk.courses.some(c => cs.includes(c))) errors.push(`${w}: skill ${s} is in none of its courses`);
    }
    for (const s of n.subtopics || []) if (n.zone !== 'foundations' && subtopics.has(s) && !(n.skills || []).some(k => skills.get(k)?.subtopic === s))
      errors.push(`${w}: lists subtopic ${s} but none of its skills`);

    // methods: none, or at least two distinct approaches
    const ms = n.methods || [];
    if (ms.length === 1) errors.push(`${w}: one method is no choice; leave methods empty`);
    if (new Set(ms).size !== ms.length) errors.push(`${w}: repeated method`);
    for (const x of ms) if (!SLUG.test(x)) errors.push(`${w}: method ${x} should be a kebab-case slug`);

    // lesson: the explainer reuses the lesson's slug
    if (n.lesson != null) {
      const l = lessonById.get(n.lesson);
      if (!l) errors.push(`${w}: unknown lesson ${n.lesson}`);
      else if (n.lesson.split('.').pop() !== m[2]) errors.push(`${w}: reuse the slug of its lesson ${n.lesson}`);
    }
    for (const t of n.question_types || []) if (!types.has(t)) errors.push(`${w}: unknown question type ${t}`);
  }

  // prereqs and related: exist, available in the right courses
  for (const n of nodes) {
    const w = n.id, cs = n.courses || [];
    for (const p of n.prereqs || []) {
      const q = byId.get(p);
      if (p === n.id) { errors.push(`${w}: lists itself as a prerequisite`); continue; }
      if (!q) { errors.push(`${w}: unknown prerequisite ${p}`); continue; }
      const missing = cs.filter(c => !(q.courses || []).includes(c));
      if (missing.length) errors.push(`${w}: prerequisite ${p} is not in ${missing.map(c => COURSE_NAME[c] || c).join(', ')}`);
    }
    if (new Set(n.prereqs || []).size !== (n.prereqs || []).length) errors.push(`${w}: repeated prerequisite`);
    for (const r of n.related || []) {
      const q = byId.get(r);
      if (r === n.id) errors.push(`${w}: lists itself as related`);
      else if (!q) errors.push(`${w}: unknown related explainer ${r}`);
      else if ((n.prereqs || []).includes(r)) errors.push(`${w}: ${r} is a prerequisite, so it is not also related`);
      else if (!(q.courses || []).some(c => cs.includes(c))) errors.push(`${w}: related ${r} shares no course with it`);
    }
  }

  // no prerequisite cycles
  const state = new Map();
  const walk = (id, trail) => {
    if (state.get(id) === 2 || !byId.has(id)) return;
    if (state.get(id) === 1) { errors.push(`prerequisite cycle: ${[...trail.slice(trail.indexOf(id)), id].join(' → ')}`); return; }
    state.set(id, 1);
    for (const p of byId.get(id).prereqs || []) walk(p, [...trail, id]);
    state.set(id, 2);
  };
  for (const n of nodes) walk(n.id, []);

  // lessons: one explainer each, and explainer prerequisites follow lesson prerequisites. A lesson
  // prerequisite must be an explainer prerequisite (directly or further back) wherever the course
  // allows it; it may be left out only when its explainer is missing from one of this one's courses.
  const ofLesson = new Map();
  for (const n of nodes) if (n.lesson) {
    if (ofLesson.has(n.lesson)) errors.push(`${n.lesson}: has two explainers, ${ofLesson.get(n.lesson).id} and ${n.id}`);
    ofLesson.set(n.lesson, n);
  }
  for (const l of lessons.lessons || []) if (!ofLesson.has(l.id)) errors.push(`lesson ${l.id} has no explainer`);
  const ancestors = new Map();
  const up = id => {
    if (ancestors.has(id)) return ancestors.get(id);
    const s = new Set();
    ancestors.set(id, s);
    for (const p of byId.get(id)?.prereqs || []) { s.add(p); for (const x of up(p)) s.add(x); }
    return s;
  };
  for (const n of nodes) if (n.lesson && lessonById.has(n.lesson)) {
    for (const lp of lessonById.get(n.lesson).prerequisites || []) {
      const q = ofLesson.get(lp);
      if (!q) continue;
      if (up(q.id).has(n.id)) errors.push(`${n.id}: comes before ${q.id}, but lesson ${n.lesson} needs ${lp}`);
      const fits = (n.courses || []).every(c => (q.courses || []).includes(c));
      if (fits && !up(n.id).has(q.id)) errors.push(`${n.id}: lesson ${n.lesson} needs ${lp}, so list ${q.id} in prereqs (or a prerequisite that builds on it)`);
    }
  }

  // coverage: every subtopic of every course has an explainer in that course (foundations don't count)
  const gaps = [];
  for (const [id, st] of subtopics) for (const c of st.courses) {
    if (!nodes.some(n => n.zone !== 'foundations' && (n.subtopics || []).includes(id) && (n.courses || []).includes(c))) gaps.push(`${id} (${COURSE_NAME[c]})`);
  }
  if (gaps.length) errors.push(`subtopics with no explainer in a course: ${gaps.join(', ')}`);
  // every skill is taught by an explainer; per course, a gap is a warning
  const taught = new Map();
  for (const n of nodes) for (const s of n.skills || []) { if (!taught.has(s)) taught.set(s, new Set()); (n.courses || []).forEach(c => taught.get(s).add(c)); }
  const untaught = [...skills.keys()].filter(s => !taught.has(s));
  if (untaught.length) errors.push(`skills no explainer teaches: ${untaught.join(', ')}`);
  for (const [s, sk] of skills) if (taught.has(s)) {
    const miss = sk.courses.filter(c => !taught.get(s).has(c));
    if (miss.length) warnings.push(`${s} is taught in no ${miss.map(c => COURSE_NAME[c]).join(' or ')} explainer`);
  }

  // computed fields are up to date
  const c = compute(data);
  for (const n of nodes) {
    const x = c.get(n.id);
    if (!x) continue;
    const want = { layer: x.layer, question_types: x.question_types, threads: x.threads, priority: { parts: x.parts, rank: x.rank } };
    for (const k of COMPUTED) if (JSON.stringify(n[k]) !== JSON.stringify(want[k])) { errors.push(`${n.id}: ${k} is out of date; run node tools/explainers.mjs --write`); }
    if (!x.layer) errors.push(`${n.id}: courses ${JSON.stringify(n.courses)} are not one of the layers`);
  }
  // no explainer is built before one of its prerequisites
  for (const n of nodes) for (const p of n.prereqs || []) {
    const a = c.get(p)?.rank, b = c.get(n.id)?.rank;
    if (a != null && b != null && a > b) errors.push(`${n.id}: rank ${b} comes before its prerequisite ${p} (rank ${a})`);
  }

  return { errors, warnings, counts: countAll(data, c) };
}

export function countAll(data, c = compute(data)) {
  const nodes = data.file.explainers || [];
  const { subtopics, skills } = index(data);
  const byId = new Map(nodes.map(n => [n.id, n]));
  const course = Object.fromEntries(COURSES.map(k => [k, nodes.filter(n => n.courses?.includes(k)).length]));
  const layer = Object.fromEntries(LAYERS.map(l => [l.id, nodes.filter(n => c.get(n.id)?.layer === l.id).length]));
  const zone = {};
  for (const z of Object.keys(ZONES)) {
    zone[z] = { total: 0 };
    for (const l of LAYERS) zone[z][l.id] = 0;
  }
  for (const n of nodes) if (zone[n.zone]) { zone[n.zone].total++; zone[n.zone][c.get(n.id)?.layer]++; }
  // links between islands: a prerequisite in another zone
  const cross = [];
  for (const n of nodes) for (const p of n.prereqs || []) if (byId.get(p) && byId.get(p).zone !== n.zone) cross.push({ from: byId.get(p).zone, to: n.zone, pre: p, id: n.id });
  const coverage = Object.fromEntries(COURSES.map(k => {
    const sts = [...subtopics.values()].filter(s => s.courses.includes(k));
    const sks = [...skills.values()].filter(s => s.courses.includes(k));
    const mine = nodes.filter(n => n.courses?.includes(k));
    const stHit = sts.filter(s => mine.some(n => n.zone !== 'foundations' && n.subtopics.includes(s.id))).length;
    const skHit = sks.filter(s => mine.some(n => (n.skills || []).includes(s.id))).length;
    return [k, { subtopics: sts.length, subtopicsCovered: stHit, skills: sks.length, skillsTaught: skHit }];
  }));
  const links = nodes.reduce((a, n) => a + (n.prereqs || []).length, 0);
  const related = nodes.reduce((a, n) => a + (n.related || []).length, 0);
  const withMethods = nodes.filter(n => n.methods?.length).length;
  const withLesson = nodes.filter(n => n.lesson).length;
  return { total: nodes.length, course, layer, zone, cross, coverage, links, related, withMethods, withLesson };
}

// ── Report ───────────────────────────────────────────────────
const cls = id => id.replace(/-/g, '_');
const mid = id => id.replace(/^ex\./, '').replace(/[^a-zA-Z0-9]/g, '_');
const label = s => s.replace(/"/g, '#quot;');
const short = id => id.replace(/^ex\./, '');
const courseList = cs => COURSES.filter(c => cs.includes(c)).map(c => COURSE_NAME[c]).join(', ');

function diagram(cluster, nodes, byId, c) {
  const ids = new Set(cluster.map(n => n.id));
  const outside = new Set();
  for (const n of cluster) for (const p of n.prereqs || []) if (!ids.has(p) && byId.has(p)) outside.add(p);
  // Top-down unless that is wider than left-to-right: a level of the graph is about one box
  // wide across the page in LR and one box per node in TD (boxes are wider than tall).
  const level = new Map([...outside].map(p => [p, 0]));
  const lv = id => {
    if (level.has(id)) return level.get(id);
    level.set(id, 0);
    const v = Math.max(0, ...(byId.get(id).prereqs || []).filter(p => ids.has(p) || outside.has(p)).map(p => lv(p) + 1));
    level.set(id, v);
    return v;
  };
  cluster.forEach(n => lv(n.id));
  const per = {};
  for (const v of level.values()) per[v] = (per[v] || 0) + 1;
  const levels = Object.keys(per).length, breadth = Math.max(...Object.values(per));
  const L = ['```mermaid', `flowchart ${breadth * 200 > levels * 260 ? 'LR' : 'TD'}`];
  for (const n of cluster) L.push(`  ${mid(n.id)}["${label(n.title)}"]:::${cls(c.get(n.id).layer)}`);
  for (const p of outside) {
    const q = byId.get(p);
    const where = q.zone === cluster[0].zone ? q.cluster : `${ZONES[q.zone].name}: ${q.cluster}`;
    L.push(`  ${mid(p)}["${label(q.title)}<br/>(${label(where)})"]:::outside`);
  }
  for (const n of cluster) for (const p of n.prereqs || []) if (byId.has(p)) L.push(`  ${mid(p)} --> ${mid(n.id)}`);
  const used = new Set(cluster.map(n => c.get(n.id).layer));
  for (const l of LAYERS) if (used.has(l.id)) L.push(`  classDef ${cls(l.id)} ${l.style}`);
  if (outside.size) L.push(`  classDef outside ${OUTSIDE_STYLE}`);
  L.push('```');
  return L;
}

export function render(data, counts) {
  const nodes = data.file.explainers;
  const c = compute(data);
  const { subtopics } = index(data);
  const byId = new Map(nodes.map(n => [n.id, n]));
  const lessonById = new Map(data.lessons.lessons.map(l => [l.id, l]));
  const L = [];
  L.push('# Explainers: the map across all four courses', '');
  L.push('Generated by `node tools/explainers.mjs --write` from `explainers.json`. Edit the JSON, not this file.', '');
  L.push('An explainer is a short narrated clip that teaches one idea, the same grain as a Relic lesson (`LESSONS.md`). The explainers build on each other: `prereqs` are what a student should have seen first, and the tutor can call back to them ("remember when Mags showed you this"); `related` are callbacks across the map that are not prerequisites. Which explainers a student gets depends on their course. Where AA and AI handle an idea differently, there is one shared core explainer and a method explainer for each course that builds on it, not two copies; HL extensions build on the SL explainer (FAL-935).', '');
  L.push('Every prerequisite is in every course of the explainer that needs it, so no student is sent to an explainer their course does not have. Like lesson prerequisites, they suggest an order and never lock anything.', '');

  L.push('## In numbers', '');
  L.push(`- **${counts.total} explainers**, ${counts.links} prerequisite links (${counts.cross.length} between islands) and ${counts.related} "remember when" links.`);
  L.push(`- **${counts.withMethods}** explainers show more than one method; **${counts.withLesson}** reuse a Relic lesson.`, '');
  L.push('| Course | Explainers | Subtopics covered | Skills taught |', '|---|--:|--:|--:|');
  for (const k of COURSES) {
    const v = counts.coverage[k];
    L.push(`| ${COURSE_NAME[k]} | ${counts.course[k]} | ${v.subtopicsCovered} / ${v.subtopics} | ${v.skillsTaught} / ${v.skills} |`);
  }
  L.push('');
  L.push('| Layer | Courses | Explainers |', '|---|---|--:|');
  for (const l of LAYERS) L.push(`| ${l.name} (\`${l.id}\`) | ${courseList(l.courses)} | ${counts.layer[l.id]} |`);
  L.push('');
  L.push(`| Zone | Island | ${LAYERS.map(l => `\`${l.id}\``).join(' | ')} | Total |`, `|---|---|${LAYERS.map(() => '--:').join('|')}|--:|`);
  for (const [z, v] of Object.entries(counts.zone)) L.push(`| ${ZONES[z].name} (\`${z}\`) | ${ZONES[z].island} | ${LAYERS.map(l => v[l.id] || '–').join(' | ')} | ${v.total} |`);
  L.push('');

  L.push('## How to read the diagrams', '');
  L.push('Each arrow points from a prerequisite to the explainer that builds on it. The fill is the layer. A dashed box is a prerequisite from another part of the map, with its island and cluster underneath.', '');
  L.push('```mermaid', 'flowchart LR');
  for (const l of LAYERS) L.push(`  L_${cls(l.id)}["${label(l.name)}"]:::${cls(l.id)}`);
  L.push(`  L_outside["From elsewhere on the map"]:::outside`);
  for (const l of LAYERS) L.push(`  classDef ${cls(l.id)} ${l.style}`);
  L.push(`  classDef outside ${OUTSIDE_STYLE}`, '```', '');

  L.push('## Links between islands', '');
  L.push('Each arrow counts the prerequisite links from explainers on one island to explainers on another.', '');
  const pairs = new Map();
  for (const x of counts.cross) { const k = `${x.from}>${x.to}`; pairs.set(k, (pairs.get(k) || 0) + 1); }
  L.push('```mermaid', 'flowchart TD');
  for (const [z, v] of Object.entries(ZONES)) L.push(`  Z_${z}["${label(`${v.name}`)}<br/>${label(v.island)}, ${counts.zone[z].total} explainers"]`);
  for (const [k, v] of [...pairs].sort()) { const [a, b] = k.split('>'); L.push(`  Z_${a} -->|${v}| Z_${b}`); }
  L.push('```', '');
  L.push('| From | To | Links | Examples |', '|---|---|--:|---|');
  for (const [k, v] of [...pairs].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))) {
    const [a, b] = k.split('>');
    const ex = counts.cross.filter(x => x.from === a && x.to === b).slice(0, 3).map(x => `\`${short(x.pre)}\` → \`${short(x.id)}\``).join(', ');
    L.push(`| ${ZONES[a].name} | ${ZONES[b].name} | ${v} | ${ex} |`);
  }
  L.push('');

  L.push('## Build order', '');
  L.push('An explainer always comes after its prerequisites. Among the explainers whose prerequisites are already placed, the next is the one with the most exam weight resting on it: its own **weighted exam parts** plus those of every explainer that needs it, directly or further on (the "Rests on it" column). An explainer\'s weighted parts are, for each AA SL exam type it prepares for, the type\'s parts in the bank times the share of the type it covers (its share of the type\'s skills, or for a lesson explainer the lesson\'s share of the exam unknowns, whichever is larger). Ties go to its own weight, then to the explainer more others need, then to the ID. Only AA SL types have parts in the bank so far, so AI-only and HL-only explainers have no weight of their own yet and come after the AA SL path; within a course, take this order and skip the explainers the course does not have.', '');
  L.push('| Rank | Explainer | Layer | Weighted parts | Rests on it | Explainers that need it | Builds on |', '|--:|---|---|--:|--:|--:|---|');
  for (const n of [...nodes].sort((a, b) => c.get(a.id).rank - c.get(b.id).rank)) {
    const x = c.get(n.id);
    L.push(`| ${x.rank} | ${n.title} (\`${short(n.id)}\`) | \`${x.layer}\` | ${x.parts} | ${x.lead} | ${x.unlocks} | ${(n.prereqs || []).map(p => `\`${short(p)}\``).join(', ') || '–'} |`);
  }
  L.push('');

  for (const [z, zv] of Object.entries(ZONES)) {
    const zn = nodes.filter(n => n.zone === z);
    if (!zn.length) continue;
    const tutor = data.teachers?.zones?.[z];
    L.push(`## ${zv.name} (\`${z}\`, ${zv.island})`, '');
    L.push(`${zn.length} explainers${tutor ? `, narrated by the ${z} tutor (\`${tutor}\` in \`tools/explainer-clips/teachers.json\`)` : ''}.`, '');
    const clusters = [];
    for (const n of zn) if (!clusters.includes(n.cluster)) clusters.push(n.cluster);
    for (const cl of clusters) {
      const cn = zn.filter(n => n.cluster === cl);
      L.push(`### ${cl}`, '');
      L.push(...diagram(cn, nodes, byId, c), '');
      L.push('| Explainer | Idea | Courses | Syllabus | Builds on | Methods | Lesson |', '|---|---|---|---|---|---|---|');
      for (const n of cn) {
        const rel = (n.related || []).length ? `<br/>Remember: ${n.related.map(r => `\`${short(r)}\``).join(', ')}` : '';
        L.push(`| **${n.title}**<br/>\`${short(n.id)}\` | ${n.idea}${rel} | ${courseList(n.courses)} | ${n.subtopics.join(', ')} | ${(n.prereqs || []).map(p => `\`${short(p)}\``).join(', ') || '–'} | ${(n.methods || []).join(', ') || '–'} | ${n.lesson ? `${lessonById.get(n.lesson)?.title} (\`${n.lesson}\`)` : '–'} |`);
      }
      L.push('');
    }
  }

  L.push('## Coverage by subtopic', '');
  L.push('Every subtopic of every course has at least one explainer in that course. Foundations explainers are prior learning and are not counted here.', '');
  L.push('| Subtopic | Title | Courses | Explainers |', '|---|---|---|---|');
  for (const [id, st] of subtopics) {
    const ex = nodes.filter(n => n.zone !== 'foundations' && n.subtopics.includes(id)).map(n => `\`${short(n.id)}\``);
    L.push(`| ${id} | ${st.title} | ${courseList(st.courses)} | ${ex.join(', ')} |`);
  }
  L.push('');
  return L.join('\n');
}

// ── CLI ──────────────────────────────────────────────────────
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const write = process.argv.includes('--write');
  const data = load();
  if (write) refresh(data);
  const { errors, warnings, counts } = check(data);
  const pad = (s, n) => String(s).padEnd(n);
  console.log(`Explainers: ${counts.total}; prerequisite links ${counts.links} (${counts.cross.length} between islands); related ${counts.related}`);
  console.log(`${pad('course', 8)}${pad('explainers', 12)}${pad('subtopics', 12)}skills`);
  for (const k of COURSES) { const v = counts.coverage[k]; console.log(`${pad(COURSE_NAME[k], 8)}${pad(counts.course[k], 12)}${pad(`${v.subtopicsCovered}/${v.subtopics}`, 12)}${v.skillsTaught}/${v.skills}`); }
  console.log('Layers: ' + LAYERS.map(l => `${l.id} ${counts.layer[l.id]}`).join(', '));
  const scripts = checkScripts();
  console.log(`Scripts: ${scripts.count} in writing/explainers/ checked`);
  errors.push(...scripts.errors);
  if (warnings.length) console.log(`\n${warnings.length} warning(s):\n  ` + warnings.join('\n  '));
  if (errors.length) { console.error(`\n${errors.length} error(s):\n  ` + errors.join('\n  ')); process.exit(1); }
  console.log('\nOK.');
  if (write) {
    fs.writeFileSync(path.join(ROOT, OUT.json), format(data.file) + '\n');
    fs.writeFileSync(path.join(ROOT, OUT.md), render(data, counts));
    console.log(`Wrote ${OUT.json} (computed fields) and ${OUT.md}`);
  }
}
