#!/usr/bin/env node
// ── LESSON MAP CHECK ─────────────────────────────────────────
// Checks curriculum/lessons.json, the design-down map of playable Relic lessons
// (GitHub issue #13, FAL-327), against the skill map and the question-type catalogue.
//
//   node tools/lessons.mjs            check, print the counts (same as --check)
//   node tools/lessons.mjs --check    check only
//   node tools/lessons.mjs --write    check, refresh each lesson's priority in
//                                     lessons.json, rewrite curriculum/LESSONS.md
//
// Exit 1 on any error.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const readJSON = f => JSON.parse(fs.readFileSync(path.join(ROOT, f), 'utf8'));

// Island prefix and Relic stations for each syllabus topic (ROADMAP.md, "Where the lessons live").
export const ISLANDS = {
  1: { prefix: 'num', stations: ['traders-caravan'] },
  2: { prefix: 'fn', stations: ['scrapworks'] },
  3: { prefix: 'geo', stations: ['broken-observatory'] },
  4: { prefix: 'stat', stations: ['signal-bunker'] },
  5: { prefix: 'calc', stations: ['engine-graveyard', 'flooded-reservoir'] },
};
const ID = /^lesson\.(num|fn|geo|stat|calc)\.[a-z0-9]+(-[a-z0-9]+)*$/;
const REQUIRED = ['id', 'title', 'objective', 'idea', 'region', 'topic', 'station', 'skills', 'supports', 'levels',
  'prerequisites', 'misconceptions', 'interaction', 'scenario', 'apply', 'alignment', 'priority'];
const ALIGN = ['ccss', 'apPrecalc', 'gcse', 'aLevel'];
const OPEN_LICENCES = ['CC0 1.0', 'Public domain', 'CC BY 4.0', 'CC BY 3.0', 'CC BY-SA 4.0', 'CC BY-SA 3.0', 'MIT', 'BSD-3-Clause', 'Apache-2.0'];
// A full stop, question or exclamation mark followed by a space or the end; 4.2 and f(x).y don't count.
const sentences = s => s.split(/[.!?]+(?:\s+|$)/).filter(x => x.trim()).length;

export function load() {
  return { lessons: readJSON('curriculum/lessons.json'), doc: readJSON('curriculum/question-types.json'), map: readJSON('curriculum/aa-sl.json') };
}

// Weighted exam parts a lesson prepares for: each supported exam type's bank parts,
// times the share of that type's exam unknowns the lesson lists under `unknowns`.
export function weightedParts(l, types) {
  let n = 0;
  for (const tid of l.supports || []) {
    const t = types.get(tid);
    if (!t || t.source !== 'exam') continue;
    const exam = t.unknowns.filter(u => u.exam).map(u => u.id);
    const hit = (l.unknowns?.[tid] || []).filter(u => exam.includes(u)).length;
    n += t.parts.length * hit / exam.length;
  }
  return Math.round(n * 10) / 10;
}

// Lessons that need this one, directly or through other lessons.
function dependents(lessons) {
  const out = new Map(lessons.map(l => [l.id, new Set()]));
  const visit = (root, id, seen) => {
    for (const l of lessons) if ((l.prerequisites || []).includes(id) && !seen.has(l.id)) {
      seen.add(l.id); out.get(root).add(l.id); visit(root, l.id, seen);
    }
  };
  for (const l of lessons) visit(l.id, l.id, new Set([l.id]));
  return out;
}

// Build order: weighted exam parts, then how many lessons need it, then ID.
export function priorities(lessons, types) {
  const deps = dependents(lessons);
  const rows = lessons.map(l => ({ id: l.id, parts: weightedParts(l, types), unlocks: deps.get(l.id)?.size || 0 }));
  rows.sort((a, b) => b.parts - a.parts || b.unlocks - a.unlocks || a.id.localeCompare(b.id));
  return new Map(rows.map((r, i) => [r.id, { parts: r.parts, rank: i + 1, unlocks: r.unlocks }]));
}

export function check({ lessons: file, doc, map }) {
  const errors = [], warnings = [];
  const skills = new Map(), subtopics = new Map();
  for (const t of map.topics) for (const st of t.subtopics) {
    subtopics.set(st.id, { ...st, topic: t.topic });
    for (const s of st.skills) skills.set(s.id, { ...s, topic: t.topic });
  }
  const types = new Map(doc.types.map(t => [t.id, t]));
  const regions = new Set((doc.regions || []).map(r => r.id));
  const kinds = new Set((file.interactions || []).map(k => k.id));
  if (kinds.size !== 8) errors.push(`interactions must list the 8 kinds from issue #13, has ${kinds.size}`);
  const codes = {};
  for (const k of ALIGN) codes[k] = new Set(Object.keys(file.sources?.[k]?.codes || {}));
  for (const k of ALIGN) if (!file.sources?.[k]?.url) errors.push(`sources.${k} needs the URL the codes were checked against`);

  const lessons = file.lessons || [];
  const byId = new Map();
  for (const l of lessons) {
    const w = l.id || '(no id)';
    if (byId.has(l.id)) errors.push(`${w}: duplicate id`);
    byId.set(l.id, l);
    if (!ID.test(l.id || '')) errors.push(`${w}: id must look like lesson.fn.some-idea`);
    for (const f of REQUIRED) {
      const v = l[f];
      if (v == null || v === '' || (Array.isArray(v) && !v.length && !['prerequisites', 'skills'].includes(f))) errors.push(`${w}: missing ${f}`);
    }
    const island = ISLANDS[l.topic];
    if (!island) errors.push(`${w}: topic must be 1-5`);
    else {
      if (l.id && !l.id.startsWith(`lesson.${island.prefix}.`)) errors.push(`${w}: topic ${l.topic} lessons use the prefix lesson.${island.prefix}.`);
      if (!island.stations.includes(l.station)) errors.push(`${w}: station ${l.station} is not a topic ${l.topic} station (${island.stations})`);
    }
    if (l.topic === 2 && !regions.has(l.region)) errors.push(`${w}: unknown region ${l.region}`);
    if (sentences(l.objective || '') !== 1) errors.push(`${w}: objective should be one sentence`);
    const ns = sentences(l.scenario || '');
    if (ns < 2 || ns > 3) errors.push(`${w}: scenario should be 2 or 3 sentences, has ${ns}`);
    if (!kinds.has(l.interaction)) errors.push(`${w}: interaction ${l.interaction} is not one of the 8 kinds`);

    // levels and prior learning
    const lv = l.levels;
    if (!Array.isArray(lv) || lv.length !== 2 || !lv.every(Number.isInteger) || lv[0] > lv[1] || lv[0] < 0 || lv[1] > 5) errors.push(`${w}: levels must be [min, max] within 0-5`);
    const prior = lv?.[1] === 0;
    if (!prior && !l.skills?.length) errors.push(`${w}: no skills`);
    for (const s of l.skills || []) if (!skills.has(s)) errors.push(`${w}: unknown skill ${s}`);
    // assumes: skills the lesson needs but another island teaches
    for (const s of l.assumes || []) {
      if (!skills.has(s)) errors.push(`${w}: assumes unknown skill ${s}`);
      else if (skills.get(s).topic === l.topic) errors.push(`${w}: assumes ${s}, which is on this island; make it a skill or a prerequisite`);
    }

    // supports and the unknowns behind them
    for (const tid of l.supports || []) {
      const t = types.get(tid);
      if (!t) { errors.push(`${w}: supports unknown type ${tid}`); continue; }
      if (t.source === 'exam' && !l.unknowns?.[tid]?.length) errors.push(`${w}: list the unknowns of exam type ${tid} it prepares for`);
    }
    for (const [tid, us] of Object.entries(l.unknowns || {})) {
      if (!(l.supports || []).includes(tid)) errors.push(`${w}: unknowns for ${tid}, which is not in supports`);
      const t = types.get(tid);
      for (const u of us) if (t && !t.unknowns?.some(x => x.id === u)) errors.push(`${w}: ${tid} has no unknown ${u}`);
    }

    // apply: what the engine generates for the independent task
    const a = l.apply || {}, at = types.get(a.type);
    if (!at) errors.push(`${w}: apply type ${a.type} does not exist`);
    else {
      if (prior !== (at.kind === 'prior-learning')) errors.push(`${w}: level 0 lessons apply a prior-learning type, and only they do`);
      if (!(l.supports || []).includes(a.type)) errors.push(`${w}: apply type ${a.type} must be in supports`);
      if (!a.unknowns?.length) errors.push(`${w}: apply needs unknowns`);
      for (const u of a.unknowns || []) {
        const x = at.unknowns?.find(y => y.id === u);
        if (!x) { errors.push(`${w}: apply unknown ${u} is not on ${a.type}`); continue; }
        if (a.reps && !a.reps.some(r => x.reps.includes(r))) errors.push(`${w}: apply unknown ${u} has none of the reps ${a.reps}`);
      }
      for (const r of a.reps || []) if (!at.representations?.some(x => x.rep === r)) errors.push(`${w}: apply rep ${r} is not listed on ${a.type}`);
    }

    // misconceptions: skill#index into aa-sl.json, or type#index for prior-learning types
    for (const ref of l.misconceptions || []) {
      const [owner, i] = ref.split('#');
      if (!/^\d+$/.test(i || '')) { errors.push(`${w}: misconception ${ref} must be skill#index or type#index`); continue; }
      if (skills.has(owner)) { if (skills.get(owner).misconceptions?.[Number(i)] == null) errors.push(`${w}: no misconception ${ref} in aa-sl.json`); }
      else if (types.get(owner)?.kind === 'prior-learning') { if (!types.get(owner).misconceptions?.[Number(i)]) errors.push(`${w}: no misconception ${ref} in question-types.json`); }
      else errors.push(`${w}: misconception ${ref} names neither a skill nor a prior-learning type`);
    }

    // alignment: IB subtopics, plus only codes recorded in sources
    if (!l.alignment?.ib?.length) errors.push(`${w}: alignment needs the IB subtopic`);
    for (const s of l.alignment?.ib || []) if (!subtopics.has(s)) errors.push(`${w}: unknown IB subtopic ${s}`);
    for (const k of Object.keys(l.alignment || {})) if (k !== 'ib' && !ALIGN.includes(k)) errors.push(`${w}: unknown alignment field ${k}`);
    for (const k of ALIGN) for (const c of l.alignment?.[k] || []) if (!codes[k].has(c)) errors.push(`${w}: ${k} code ${c} is not in sources.${k}`);

    for (const m of l.materials || []) {
      if (!/^https:\/\//.test(m.url || '') || !m.title) errors.push(`${w}: material needs a title and an https URL`);
      if (!OPEN_LICENCES.includes(m.licence)) errors.push(`${w}: material licence "${m.licence}" is not on the open list (${OPEN_LICENCES.join(', ')})`);
    }
  }

  // prerequisites: exist, and no cycles
  for (const l of lessons) for (const p of l.prerequisites || []) {
    if (p === l.id) errors.push(`${l.id}: lists itself as a prerequisite`);
    else if (!byId.has(p)) errors.push(`${l.id}: unknown prerequisite ${p}`);
  }
  const state = new Map();
  const walk = (id, trail) => {
    if (state.get(id) === 2 || !byId.has(id)) return;
    if (state.get(id) === 1) { errors.push(`prerequisite cycle: ${[...trail.slice(trail.indexOf(id)), id].join(' → ')}`); return; }
    state.set(id, 1);
    for (const p of byId.get(id).prerequisites || []) walk(p, [...trail, id]);
    state.set(id, 2);
  };
  for (const l of lessons) walk(l.id, []);

  // priority must match what the map computes
  const prio = priorities(lessons, types);
  for (const l of lessons) {
    const p = prio.get(l.id);
    if (l.priority?.parts !== p.parts || l.priority?.rank !== p.rank) errors.push(`${l.id}: priority should be { parts: ${p.parts}, rank: ${p.rank} }; run node tools/lessons.mjs --write`);
  }

  // milestones from ROADMAP.md
  const pilot = byId.get(file.pilot), second = byId.get(file.second);
  if (!pilot) errors.push(`pilot ${file.pilot} is not a lesson`);
  if (!second) errors.push(`second ${file.second} is not a lesson`);
  if (pilot && second && pilot.interaction === second.interaction) errors.push('the second lesson must use a different interaction kind from the pilot');

  // coverage: every Functions exam type has a lesson, or is in gaps with a reason
  const fnExam = doc.types.filter(t => t.topic === 2 && t.source === 'exam');
  const supported = new Set(lessons.flatMap(l => l.supports || []));
  const gaps = new Map((file.gaps || []).map(g => [g.type, g]));
  for (const t of fnExam) {
    if (!supported.has(t.id) && !gaps.get(t.id)?.reason) errors.push(`exam type ${t.id} has no lesson and no gaps entry with a reason`);
    if (supported.has(t.id) && gaps.has(t.id)) errors.push(`${t.id} has a lesson, so remove it from gaps`);
    if (!supported.has(t.id)) continue;
    const served = new Set(lessons.flatMap(l => l.unknowns?.[t.id] || []));
    for (const u of t.unknowns.filter(u => u.exam)) if (!served.has(u.id)) warnings.push(`${t.id}/${u.id}: an exam unknown no lesson lists`);
  }
  for (const g of file.gaps || []) if (!types.has(g.type)) errors.push(`gaps names unknown type ${g.type}`);
  for (const t of doc.types.filter(t => t.topic === 2 && t.kind === 'prior-learning'))
    if (!lessons.some(l => l.apply?.type === t.id)) warnings.push(`prior-learning type ${t.id} has no level 0 lesson`);

  // outlook for the other islands: big ideas only
  for (const o of file.outlook || []) {
    if (!ISLANDS[o.topic] || o.topic === 2) errors.push(`outlook topic ${o.topic} should be 1, 3, 4 or 5`);
    if (!o.bigIdeas?.length || !Array.isArray(o.lessons) || o.lessons.length !== 2) errors.push(`outlook topic ${o.topic} needs bigIdeas and a lessons range`);
  }

  const counts = countAll(file, doc, prio);
  counts.unlisted = warnings.filter(w => w.includes('an exam unknown no lesson lists')).length;
  return { errors, warnings, counts };
}

export function countAll(file, doc, prio) {
  const lessons = file.lessons || [];
  const regions = (doc.regions || []).map(r => {
    const ls = lessons.filter(l => l.region === r.id);
    return { id: r.id, name: r.name, order: r.order, lessons: ls.length, prior: ls.filter(l => l.levels?.[1] === 0).length,
      exam: doc.types.filter(t => t.region === r.id && t.source === 'exam').length };
  });
  const kinds = {};
  for (const l of lessons) kinds[l.interaction] = (kinds[l.interaction] || 0) + 1;
  return { regions, total: lessons.length, prior: lessons.filter(l => l.levels?.[1] === 0).length, kinds, prio };
}

// ── Report ───────────────────────────────────────────────────
// Lessons in a region with their in-region prerequisites first (stable: map order otherwise).
function ladder(ls) {
  const ids = new Set(ls.map(l => l.id)), done = new Set(), out = [];
  const add = l => {
    if (done.has(l.id)) return;
    done.add(l.id);
    for (const p of l.prerequisites || []) if (ids.has(p)) add(ls.find(x => x.id === p));
    out.push(l);
  };
  ls.forEach(add);
  return out;
}

export function render({ lessons: file, doc, map }, counts) {
  const L = [];
  const lessons = file.lessons, byId = new Map(lessons.map(l => [l.id, l]));
  const types = new Map(doc.types.map(t => [t.id, t]));
  const subtopics = new Map();
  for (const t of map.topics) for (const st of t.subtopics) subtopics.set(st.id, st);
  const kindName = new Map(file.interactions.map(k => [k.id, k.name]));
  const short = id => id.replace(/^lesson\.[a-z]+\./, '');
  const typeName = id => types.get(id)?.name || id;
  const parts = id => types.get(id)?.parts?.length;
  const tag = id => types.get(id)?.source === 'exam' ? `\`${id}\` (${parts(id)})` : `\`${id}\``;
  const fnExam = doc.types.filter(t => t.topic === 2 && t.source === 'exam');
  const P = counts.prio;

  L.push('# Relic lessons: the design-down lesson map', '');
  L.push('Generated by `node tools/lessons.mjs --write` from `lessons.json`. Edit the JSON, not this file.', '');
  L.push('A Relic lesson is a 3 to 6 minute playable episode (GitHub issue #13): a character shows a broken machine, the player takes the controls, the character reacts to what the player actually did, the recipe engine sets an independent task, and a short debrief turns the machine into notation. **Each lesson teaches one idea, not one question type.** This map works back from the exam question types in `question-types.json` to the ideas and prior learning behind them (FAL-327).', '');
  L.push('## In numbers', '');
  L.push(`- **Functions (Scrapworks, B0-LT):** ${counts.total} lessons, of which ${counts.prior} are level 0 prior learning.`);
  L.push(`- **Exam types:** ${fnExam.length} of ${fnExam.length} Functions exam types have at least one lesson${(file.gaps || []).length ? `; ${(file.gaps || []).length} listed as gaps` : ''}.`);
  L.push(`- **Interaction kinds:** ${file.interactions.map(k => `${k.name.toLowerCase()} ${counts.kinds[k.id] || 0}`).join(', ')}.`);
  L.push(`- **Pilot (L2):** ${file.pilot}. **Second lesson (L4):** ${file.second}.`, '');
  L.push('| Region (build order) | Lessons | of which level 0 | Exam types |', '|---|---|---|---|');
  for (const r of counts.regions) L.push(`| ${r.order}. ${r.name} | ${r.lessons} | ${r.prior} | ${r.exam} |`);
  L.push('');

  L.push('## Build order', '');
  L.push('Ranked by **weighted exam parts**: for each exam type a lesson supports, the type\'s parts in the bank (May 2021 to May 2025) times the share of its exam unknowns the lesson prepares for. Ties go to the lesson more other lessons depend on. The pilot and the second lesson are fixed by the roadmap (L2 and L4); this order applies from L5.', '');
  L.push('| Rank | Lesson | Region | Interaction | Weighted parts | Lessons that need it | Exam types it supports |', '|---|---|---|---|---|---|---|');
  for (const l of [...lessons].sort((a, b) => P.get(a.id).rank - P.get(b.id).rank)) {
    const p = P.get(l.id);
    const ex = l.supports.filter(t => types.get(t)?.source === 'exam');
    L.push(`| ${p.rank} | ${l.title} (\`${short(l.id)}\`) | ${doc.regions.find(r => r.id === l.region)?.name} | ${kindName.get(l.interaction)} | ${p.parts} | ${p.unlocks} | ${ex.length ? ex.map(t => `\`${t}\``).join(', ') : '–'} |`);
  }
  L.push('');

  L.push('## Lessons by region', '');
  L.push('Each region\'s ladder lists its lessons with their prerequisites first. Prerequisites in another region are named in full.', '');
  for (const r of doc.regions) {
    const ls = ladder(lessons.filter(l => l.region === r.id));
    L.push(`### ${r.order}. ${r.name} (syllabus ${r.syllabus.join(', ')})`, '');
    L.push('| # | Lesson | Prerequisites | Levels | Interaction | Supports (exam parts) |', '|---|---|---|---|---|---|');
    ls.forEach((l, i) => {
      const pre = (l.prerequisites || []).map(p => byId.get(p)?.region === r.id ? `\`${short(p)}\`` : `\`${short(p)}\` (${doc.regions.find(x => x.id === byId.get(p)?.region)?.name})`).join(', ') || '–';
      L.push(`| ${i + 1} | ${l.title} (\`${short(l.id)}\`) | ${pre} | ${l.levels.join('–')} | ${kindName.get(l.interaction)} | ${l.supports.map(tag).join(', ')} |`);
    });
    L.push('');
    for (const l of ls) {
      L.push(`#### ${l.title} (\`${l.id}\`)`, '');
      L.push(`- **Objective:** ${l.objective}`);
      L.push(`- **Idea:** ${l.idea}`);
      L.push(`- **Scenario (${kindName.get(l.interaction).toLowerCase()}):** ${l.scenario}`);
      L.push(`- **Apply:** \`${l.apply.type}\`: ${l.apply.unknowns.join(', ')}${l.apply.reps ? ` (${l.apply.reps.join(', ')})` : ''}.`);
      L.push(`- **Skills:** ${l.skills.length ? l.skills.map(s => `\`${s}\``).join(', ') : 'prior learning (level 0)'}${l.assumes?.length ? `. Assumes from other islands: ${l.assumes.map(s => `\`${s}\``).join(', ')}` : ''}.`);
      L.push(`- **Misconceptions the react stage targets:** ${l.misconceptions.map(m => `\`${m}\``).join(', ')}.`);
      const al = l.alignment;
      const bits = [`IB ${al.ib.map(s => `${s} ${subtopics.get(s)?.title}`).join('; ')}`];
      if (al.ccss?.length) bits.push(`Common Core ${al.ccss.join(', ')}`);
      if (al.apPrecalc?.length) bits.push(`AP Precalculus ${al.apPrecalc.map(c => `${c} ${file.sources.apPrecalc.codes[c]}`).join('; ')}`);
      if (al.gcse?.length) bits.push(`GCSE ${al.gcse.join(', ')}`);
      if (al.aLevel?.length) bits.push(`A-level ${al.aLevel.join(', ')}`);
      L.push(`- **Alignment:** ${bits.join('. ')}.`);
      if (l.materials?.length) L.push(`- **Materials:** ${l.materials.map(m => `[${m.title}](${m.url}) (${m.licence})`).join('; ')}.`);
      L.push('');
    }
  }

  L.push('## Exam types and the lessons behind them', '');
  L.push('| Exam type | Parts | Lessons |', '|---|---|---|');
  for (const t of [...fnExam].sort((a, b) => b.parts.length - a.parts.length || a.id.localeCompare(b.id))) {
    const ls = lessons.filter(l => l.supports.includes(t.id)).sort((a, b) => P.get(a.id).rank - P.get(b.id).rank);
    L.push(`| ${t.name} (\`${t.id}\`) | ${t.parts.length} | ${ls.map(l => `\`${short(l.id)}\``).join(', ') || `**gap:** ${(file.gaps || []).find(g => g.type === t.id)?.reason}`} |`);
  }
  L.push('');
  L.push('## Gaps', '');
  L.push((file.gaps || []).length ? (file.gaps || []).map(g => `- \`${g.type}\`: ${g.reason}`).join('\n') : 'None: every Functions exam type has at least one lesson.');
  L.push('', counts.unlisted ? `${counts.unlisted} exam unknowns are not yet listed by any lesson; \`node tools/lessons.mjs\` names them.` : 'Every exam unknown of every Functions exam type is listed by at least one lesson.', '');

  L.push('## The other islands (big ideas only)', '');
  L.push('Their catalogues are at summary level, so these are estimates, not lesson entries. Each will be designed down the same way once its catalogue is filled in.', '');
  for (const o of file.outlook || []) {
    L.push(`### ${o.island} (topic ${o.topic}, ${o.station})`, '');
    L.push(`About ${o.lessons[0]} to ${o.lessons[1]} lessons. ${o.note || ''}`.trim(), '');
    for (const b of o.bigIdeas) L.push(`- ${b}`);
    L.push('');
  }

  L.push('## Sources for the alignment codes', '');
  for (const k of ALIGN) {
    const s = file.sources[k];
    L.push(`- **${s.name}:** ${s.url}. ${s.note || ''}`.trim());
  }
  L.push('');
  return L.join('\n');
}

// ── lessons.json writer: two-space JSON, short arrays and small objects on one line ──
export function format(value, indent = '') {
  const inner = indent + '  ';
  if (Array.isArray(value)) {
    if (!value.length) return '[]';
    const flat = value.every(v => v === null || typeof v !== 'object');
    const one = `[${value.map(v => JSON.stringify(v)).join(', ')}]`;
    if (flat && one.length + indent.length <= 140) return one;
    return `[\n${value.map(v => inner + format(v, inner)).join(',\n')}\n${indent}]`;
  }
  if (value && typeof value === 'object') {
    const keys = Object.keys(value);
    if (!keys.length) return '{}';
    const inline = v => Array.isArray(v) ? `[${v.map(x => JSON.stringify(x)).join(', ')}]` : JSON.stringify(v);
    const one = `{ ${keys.map(k => `${JSON.stringify(k)}: ${inline(value[k])}`).join(', ')} }`;
    if (one.length + indent.length <= 140 && keys.every(k => !value[k] || typeof value[k] !== 'object' || (Array.isArray(value[k]) && value[k].every(v => typeof v !== 'object')))) return one;
    return `{\n${keys.map(k => `${inner}${JSON.stringify(k)}: ${format(value[k], inner)}`).join(',\n')}\n${indent}}`;
  }
  return JSON.stringify(value);
}

// ── CLI ──────────────────────────────────────────────────────
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const write = process.argv.includes('--write');
  const data = load();
  if (write) {
    // Refresh the computed priorities first, so a new or edited lesson only needs --write.
    const types = new Map(data.doc.types.map(t => [t.id, t]));
    const prio = priorities(data.lessons.lessons, types);
    for (const l of data.lessons.lessons) { const p = prio.get(l.id); l.priority = { parts: p.parts, rank: p.rank }; }
  }
  const { errors, warnings, counts } = check(data);
  const pad = (s, n) => String(s).padEnd(n);
  console.log(`Lessons: ${counts.total} (${counts.prior} level 0)`);
  console.log(`${pad('region', 26)}${pad('lessons', 9)}${pad('level 0', 9)}exam types`);
  for (const r of counts.regions) console.log(`${pad(r.name, 26)}${pad(r.lessons, 9)}${pad(r.prior, 9)}${r.exam}`);
  console.log(`Interactions: ${Object.entries(counts.kinds).map(([k, n]) => `${k} ${n}`).join(', ')}`);
  if (warnings.length) console.log(`\n${warnings.length} warning(s):\n  ` + warnings.join('\n  '));
  if (errors.length) { console.error(`\n${errors.length} error(s):\n  ` + errors.join('\n  ')); process.exit(1); }
  console.log('\nOK.');
  if (write) {
    fs.writeFileSync(path.join(ROOT, 'curriculum/lessons.json'), format(data.lessons) + '\n');
    fs.writeFileSync(path.join(ROOT, 'curriculum/LESSONS.md'), render(data, counts));
    console.log('Wrote curriculum/lessons.json (priorities) and curriculum/LESSONS.md');
  }
}
