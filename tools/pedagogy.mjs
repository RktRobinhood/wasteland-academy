#!/usr/bin/env node
// ── PEDAGOGY CATALOGUE CHECK ─────────────────────────────────
// Checks the situation-and-view fields in curriculum/question-types.json
// (FAL-310 plan, FAL-311 catalogue) and prints coverage counts per region.
//
//   node tools/pedagogy.mjs                    check everything, print the counts
//   node tools/pedagogy.mjs --region <id>      check one Functions region only
//   node tools/pedagogy.mjs --write            also rewrite curriculum/PEDAGOGY_GAPS.md
//
// No question bank is needed. Exit 1 on any error.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const readJSON = f => JSON.parse(fs.readFileSync(path.join(ROOT, f), 'utf8'));

export const REPS = ['equation', 'graph', 'table', 'words'];
export const KINDS = ['skill', 'prior-learning', 'concept', 'link'];
export const PROBES = ['true-false-reason', 'always-sometimes-never', 'interpret-parameter', 'predict-check'];
const FULL = ['region', 'situation', 'representations', 'unknowns', 'angles', 'concepts', 'misconceptions'];
const CATALOGUE = ['name', 'summary', 'skills', 'level', 'gap'];

export function load() {
  return { doc: readJSON('curriculum/question-types.json'), map: readJSON('curriculum/aa-sl.json'), threads: readJSON('curriculum/threads.json') };
}

// Number of coverage cells a type can make: one per (unknown, representation, angle);
// an unknown no listed method suits still counts once per representation ("any method").
export function cells(t) {
  return (t.unknowns || []).reduce((n, u) => {
    const angles = (t.angles || []).filter(a => a.suits.includes(u.id)).length;
    return n + u.reps.length * Math.max(1, angles);
  }, 0);
}

export function check({ doc, map, threads }, { region } = {}) {
  const errors = [], warnings = [];
  const skills = new Map(), subOf = new Map();
  for (const t of map.topics) for (const st of t.subtopics) for (const s of st.skills) { skills.set(s.id, { ...s, topic: t.topic }); subOf.set(s.id, st.id); }
  const threadIds = new Map(threads.threads.map(t => [t.id, t]));
  const regionIds = new Set((doc.regions || []).map(r => r.id));
  const sits = doc.situations || {};
  const all = doc.types;
  const scoped = region ? all.filter(t => t.region === region) : all;
  if (region && !regionIds.has(region)) errors.push(`unknown region ${region}`);

  // situations
  for (const [id, s] of Object.entries(sits)) {
    if (s.extends && !sits[s.extends]) errors.push(`situation ${id} extends unknown ${s.extends}`);
    if (!s.name || !s.quantities?.length) errors.push(`situation ${id} needs a name and quantities`);
  }
  const root = s => { let id = s; while (sits[id]?.extends) id = sits[id].extends; return id; };

  for (const t of scoped) {
    const w = t.id;
    if (!['exam', 'extension'].includes(t.source)) errors.push(`${w}: source must be exam or extension`);
    if (t.source === 'extension') {
      if (!KINDS.includes(t.kind)) errors.push(`${w}: kind must be one of ${KINDS}`);
      for (const f of CATALOGUE) if (t[f] == null || t[f] === '') errors.push(`${w}: missing ${f}`);
      if (!Array.isArray(t.level) || t.level.length !== 2 || t.level[0] > t.level[1] || t.level[0] < 0 || t.level[1] > 5) errors.push(`${w}: level must be [min, max] within 0-5`);
      if (t.kind === 'prior-learning') {
        if (t.level?.[1] !== 0) errors.push(`${w}: prior-learning types sit at level 0`);
        if (!t.supports?.length) errors.push(`${w}: prior-learning needs supports`);
        for (const s of t.supports || []) if (!skills.has(s)) errors.push(`${w}: supports unknown skill ${s}`);
      } else if (!t.skills?.length) errors.push(`${w}: no skills`);
      if (['concept', 'link'].includes(t.kind) && t.level?.[0] < 3) errors.push(`${w}: ${t.kind} types sit at levels 3-5`);
      if (t.kind === 'link') {
        if (!threadIds.has(t.thread)) errors.push(`${w}: unknown thread ${t.thread}`);
        else for (const b of t.blueprints || []) if (!threadIds.get(t.thread).blueprints[b]) errors.push(`${w}: no blueprint ${b} on ${t.thread}`);
      }
    }
    for (const s of t.skills || []) if (!skills.has(s)) errors.push(`${w}: unknown skill ${s}`);
    if (t.topic !== 2) continue;

    // ── Functions: the full view model ──
    for (const f of FULL) { const v = t[f]; if (v == null || (Array.isArray(v) && !v.length)) errors.push(`${w}: missing ${f}`); }
    if (t.region && !regionIds.has(t.region)) errors.push(`${w}: unknown region ${t.region}`);
    if (t.situation && !sits[t.situation]) errors.push(`${w}: unknown situation ${t.situation}`);
    const share = all.filter(o => o !== t && o.situation && t.situation && root(o.situation) === root(t.situation)).map(o => o.id).sort();
    if (JSON.stringify(share) !== JSON.stringify([...(t.sharesSituation || [])].sort())) errors.push(`${w}: sharesSituation should be [${share}]`);

    const reps = new Set();
    for (const r of t.representations || []) {
      if (!REPS.includes(r.rep)) errors.push(`${w}: bad representation ${r.rep}`);
      if (typeof r.exam !== 'boolean' || !r.how) errors.push(`${w}: representation ${r.rep} needs exam and how`);
      if (t.source === 'extension' && r.exam) errors.push(`${w}: extension types have no exam representations`);
      reps.add(r.rep);
    }
    if (t.source === 'exam' && !(t.representations || []).some(r => r.exam)) errors.push(`${w}: no representation is marked exam`);

    const local = new Map((t.methods || []).map(m => [m.id, m]));
    const uids = new Set();
    for (const u of t.unknowns || []) {
      const uw = `${w}/${u.id}`;
      if (uids.has(u.id)) errors.push(`${uw}: duplicate unknown`);
      uids.add(u.id);
      if (!u.given?.length || !u.asked) errors.push(`${uw}: needs given and asked`);
      if (!Number.isInteger(u.level) || u.level < 0 || u.level > 5) errors.push(`${uw}: level must be 0-5`);
      if (typeof u.exam !== 'boolean') errors.push(`${uw}: exam must be true or false`);
      if (u.exam && t.source === 'extension') errors.push(`${uw}: an extension type cannot have an exam unknown`);
      if (!u.reps?.length) errors.push(`${uw}: no representations`);
      for (const r of u.reps || []) if (!reps.has(r)) errors.push(`${uw}: representation ${r} is not listed on the type`);
      if (t.kind !== 'prior-learning' && !u.skills?.length) errors.push(`${uw}: no skills`);
      for (const s of u.skills || []) if (!skills.has(s)) errors.push(`${uw}: unknown skill ${s}`);
    }
    if (t.source === 'exam' && !(t.unknowns || []).some(u => u.exam)) errors.push(`${w}: no unknown is marked exam`);
    if ((t.unknowns || []).length === 1 && !t.singleUnknown) errors.push(`${w}: one unknown only; say why in singleUnknown`);
    const uskills = new Set((t.unknowns || []).flatMap(u => u.skills || []));
    for (const s of t.skills || []) if (!uskills.has(s)) errors.push(`${w}: no unknown tests ${s}`);

    for (const a of t.angles || []) {
      const aw = `${w}/angle ${a.method}`;
      if (a.skill) {
        if (!skills.has(a.skill)) errors.push(`${aw}: unknown skill ${a.skill}`);
        else if (!skills.get(a.skill).methods.some(m => m.id === a.method)) errors.push(`${aw}: ${a.skill} has no method ${a.method}`);
      } else if (!local.has(a.method)) errors.push(`${aw}: not a method of ${a.skill || 'the type'}`);
      if (!a.suits?.length) errors.push(`${aw}: suits no unknown`);
      for (const u of a.suits || []) if (!uids.has(u)) errors.push(`${aw}: suits unknown ${u} that does not exist`);
      if (a.weak) {
        if (!['slow', 'fails'].includes(a.weak.kind) || !a.weak.why) errors.push(`${aw}: weak needs kind slow|fails and why`);
        for (const u of a.weak.unknowns || []) if (u !== '*' && !uids.has(u)) errors.push(`${aw}: weak names unknown ${u}`);
      }
    }
    for (const u of t.unknowns || []) if (!(t.angles || []).some(a => a.suits.includes(u.id))) warnings.push(`${w}/${u.id}: no listed method suits it (counts as "any method")`);

    const nc = (t.concepts || []).length;
    if (nc < 1 || nc > 3) errors.push(`${w}: needs 1-3 concepts, has ${nc}`);
    for (const c of t.concepts || []) {
      if (!PROBES.includes(c.kind)) errors.push(`${w}: bad concept kind ${c.kind}`);
      if (!c.prompt || !c.answer) errors.push(`${w}: concept needs prompt and answer`);
      if (!(c.level >= 3 && c.level <= 5)) errors.push(`${w}: concept levels are 3-5`);
    }

    for (const x of t.misconceptions || []) {
      const xw = `${w}/misconception ${x.ref || x.text}`;
      if (!['distractor', 'error-spot'].includes(x.as)) errors.push(`${xw}: as must be distractor or error-spot`);
      if (!x.wrong) errors.push(`${xw}: needs wrong`);
      if (!x.in?.length) errors.push(`${xw}: used in no unknown`);
      for (const u of x.in || []) if (!uids.has(u)) errors.push(`${xw}: unknown ${u} does not exist`);
      if (x.ref) {
        const [sid, i] = x.ref.split('#');
        const text = skills.get(sid)?.misconceptions?.[Number(i)];
        if (text == null) errors.push(`${xw}: no such misconception in aa-sl.json`);
        else if (text !== x.text) errors.push(`${xw}: text does not match aa-sl.json; rerun the merge`);
      } else if (!x.text) errors.push(`${w}: misconception needs ref or text`);
    }
  }

  // ── Whole-catalogue checks ──
  const fnTypes = all.filter(t => t.topic === 2);
  const used = new Set(fnTypes.flatMap(t => (t.misconceptions || []).map(x => x.ref).filter(Boolean)));
  const fnSkillsIn = region ? new Set(scoped.flatMap(t => [...(t.skills || []), ...(t.unknowns || []).flatMap(u => u.skills || [])])) : null;
  for (const [id, s] of skills) {
    if (s.topic !== 2) continue;
    if (fnSkillsIn && !fnSkillsIn.has(id)) continue;
    s.misconceptions.forEach((m, i) => {
      if (used.has(`${id}#${i}`)) return;
      (region ? warnings : errors).push(`misconception ${id}#${i} is not used by any Functions type: "${m}"`);
    });
  }
  if (!region) {
    const typed = new Set(all.flatMap(t => t.skills || []));
    for (const id of skills.keys()) if (!typed.has(id)) errors.push(`skill ${id} has no type`);
    const linked = new Set(all.filter(t => t.kind === 'link').map(t => t.thread));
    for (const id of threadIds.keys()) if (!linked.has(id)) errors.push(`thread ${id} has no link type`);
    for (const r of doc.regions || []) if (!all.some(t => t.region === r.id && t.source === 'exam')) warnings.push(`region ${r.id} has no exam type`);
    for (const t of fnTypes) if (!t.region) errors.push(`${t.id}: Functions type with no region`);
  }
  return { errors, warnings, counts: countAll(doc, skills, used) };
}

export function countAll(doc, skills, used) {
  const regions = (doc.regions || []).map(r => {
    const ts = doc.types.filter(t => t.region === r.id);
    const us = ts.flatMap(t => t.unknowns || []);
    return {
      id: r.id, name: r.name,
      examTypes: ts.filter(t => t.source === 'exam').length, extTypes: ts.filter(t => t.source === 'extension').length,
      examUnknowns: us.filter(u => u.exam).length, extUnknowns: us.filter(u => !u.exam).length,
      reps: ts.reduce((n, t) => n + (t.representations || []).length, 0),
      repsNotExam: ts.reduce((n, t) => n + (t.representations || []).filter(r => !r.exam).length, 0),
      angles: ts.reduce((n, t) => n + (t.angles || []).length, 0),
      weak: ts.reduce((n, t) => n + (t.angles || []).filter(a => a.weak).length, 0),
      concepts: ts.reduce((n, t) => n + (t.concepts || []).length, 0),
      cells: ts.reduce((n, t) => n + cells(t), 0),
      examCells: ts.filter(t => t.source === 'exam').reduce((n, t) => n + cells({
        ...t, unknowns: (t.unknowns || []).filter(u => u.exam).map(u => ({ ...u, reps: u.reps.filter(r => (t.representations || []).find(x => x.rep === r)?.exam) })),
      }), 0),
    };
  });
  const fnMis = [...skills.values()].filter(s => s.topic === 2).reduce((n, s) => n + s.misconceptions.length, 0);
  return {
    regions,
    skills: skills.size, skillsTyped: new Set(doc.types.flatMap(t => t.skills || [])).size,
    fnMisconceptions: fnMis, fnMisconceptionsUsed: [...used].filter(r => skills.get(r.split('#')[0])?.topic === 2).length,
  };
}

// ── Report ───────────────────────────────────────────────────
export function render({ doc, map, threads }, counts) {
  const L = [];
  const skills = new Map();
  for (const t of map.topics) for (const st of t.subtopics) for (const s of st.skills) skills.set(s.id, { ...s, topic: t.topic });
  const short = s => s.replace(/^SL\d+\.\d+\./, '');
  const lv = u => `L${u.level}`;
  const methodName = (t, a) => a.skill ? skills.get(a.skill)?.methods.find(m => m.id === a.method)?.name : t.methods?.find(m => m.id === a.method)?.name;
  const exam = doc.types.filter(t => t.source === 'exam'), ext = doc.types.filter(t => t.source === 'extension');
  const sum = k => counts.regions.reduce((n, r) => n + r[k], 0);

  L.push('# Pedagogical gaps: the catalogue the question engine plans from', '');
  L.push('Generated by `node tools/pedagogy.mjs --write` from `question-types.json`. Edit the JSON, not this file.', '');
  L.push('The exam catalogue (`QUESTION_TYPES.md`) records what the IB asked, in the direction it asked it. This file adds what it leaves out, so the game can test every skill and concept: every sensible **unknown** on each question\'s situation, the **representations** it can be given in, the **methods** (angles) that work or fail, **concept probes**, the **misconceptions** each wrong option uses, and **extension types** for skills, prior learning, concepts and concept threads that no exam question covers. The plan is on FAL-310.', '');
  L.push('**Every question here is described in our own words.** Nothing copies IB question text, numbers or images.', '');
  L.push('## In numbers', '');
  L.push(`- **Types:** ${exam.length} exam and ${ext.length} extension (${KINDS.map(k => `${ext.filter(t => t.kind === k).length} ${k}`).join(', ')}).`);
  L.push(`- **Skills with a type:** ${counts.skillsTyped} of ${counts.skills}.`);
  L.push(`- **Functions:** ${sum('examUnknowns')} unknowns the exam asks and ${sum('extUnknowns')} it doesn't; ${sum('angles')} angles, ${sum('weak')} of them with a weak spot for method-pick questions; ${sum('concepts')} concept probes; ${counts.fnMisconceptionsUsed} of ${counts.fnMisconceptions} misconceptions used as wrong options or error-spots.`);
  L.push(`- **Coverage cells** (one unknown in one representation by one method): ${sum('cells')} in Functions, of which ${sum('examCells')} are reachable with "Exam-style only" on.`, '');
  L.push('## Levels', '');
  for (const [k, v] of Object.entries(doc.levels || {})) L.push(`- **${k}.** ${v}`);
  L.push('');
  L.push('## Functions regions', '');
  L.push('| Region | Exam types | Extension types | Unknowns (exam + new) | Representations (new) | Angles (weak) | Concepts | Cells (exam-only) |', '|---|---|---|---|---|---|---|---|');
  for (const r of counts.regions)
    L.push(`| ${r.name} | ${r.examTypes} | ${r.extTypes} | ${r.examUnknowns} + ${r.extUnknowns} | ${r.reps} (${r.repsNotExam}) | ${r.angles} (${r.weak}) | ${r.concepts} | ${r.cells} (${r.examCells}) |`);
  L.push('');

  const typeBlock = t => {
    const head = t.source === 'exam' ? `exam, ${t.parts.length} bank parts` : `${t.kind}, level ${t.level.join('–')}`;
    L.push(`#### ${t.name} (\`${t.id}\`, ${head})`, '');
    if (t.gap) L.push(`*Gap:* ${t.gap}`, '');
    const sit = doc.situations?.[t.situation];
    if (sit) L.push(`- **Situation:** ${sit.name}${t.sharesSituation?.length ? `, shared with ${t.sharesSituation.map(s => '`' + s + '`').join(', ')}` : ''}.`);
    if (t.supports) L.push(`- **Supports:** ${t.supports.map(s => '`' + short(s) + '`').join(', ')}`);
    L.push(`- **Representations:** ${(t.representations || []).map(r => r.exam ? `**${r.rep}**` : r.rep).join(', ')} (bold: the exam uses it)`);
    L.push('- **Unknowns:**');
    for (const u of t.unknowns || []) L.push(`  - ${u.exam ? '**exam**' : 'new'} ${lv(u)}: given ${u.given.join('; ')} → ${u.asked}${u.note ? ` *(${u.note})*` : ''}`);
    const weak = (t.angles || []).filter(a => a.weak);
    L.push(`- **Angles:** ${(t.angles || []).map(a => methodName(t, a) || a.method).join('; ')}.`);
    for (const a of weak) L.push(`  - *${a.weak.kind === 'fails' ? 'Fails' : 'Slow'}:* ${methodName(t, a) || a.method}: ${a.weak.why}.`);
    L.push('- **Concept probes:**');
    for (const c of t.concepts || []) L.push(`  - *${c.kind}* (L${c.level}): ${c.prompt} — ${c.answer}`);
    L.push(`- **Misconceptions used:** ${(t.misconceptions || []).length}. ${(t.misconceptions || []).map(x => x.text).join('; ')}.`, '');
  };

  for (const r of doc.regions || []) {
    const c = counts.regions.find(x => x.id === r.id);
    L.push(`### ${r.order}. ${r.name} (syllabus ${r.syllabus.join(', ')})`, '');
    L.push(`${c.examTypes} exam types, ${c.extTypes} extension types; ${c.examUnknowns} exam unknowns and ${c.extUnknowns} new ones; ${c.cells} coverage cells (${c.examCells} with "Exam-style only" on).`, '');
    for (const t of doc.types.filter(t => t.region === r.id && t.source === 'exam')) typeBlock(t);
    for (const t of doc.types.filter(t => t.region === r.id && t.source === 'extension')) typeBlock(t);
  }
  const unplaced = doc.types.filter(t => t.topic === 2 && !t.region);
  if (unplaced.length) L.push('### Functions types not yet catalogued', '', unplaced.map(t => `\`${t.id}\``).join(', '), '');

  for (const [n, name] of [[1, 'Number and algebra'], [3, 'Geometry and trigonometry'], [4, 'Statistics and probability'], [5, 'Calculus']]) {
    const ts = ext.filter(t => t.topic === n);
    L.push(`## Topic ${n}: ${name} (catalogue level)`, '');
    L.push(`${exam.filter(t => t.topic === n).length} exam types (see \`QUESTION_TYPES.md\`) and ${ts.length} extension types. Unknowns and angles follow one topic at a time, as Functions did.`, '');
    if (ts.length) {
      L.push('| Type | Kind | Skills | Level | Gap | What it asks |', '|---|---|---|---|---|---|');
      for (const t of ts) L.push(`| \`${t.id}\` ${t.name} | ${t.kind}${t.thread ? ` (${t.thread})` : ''} | ${t.skills.map(short).join(', ')} | ${t.level.join('–')} | ${t.gap} | ${t.summary} |`);
      L.push('');
    }
  }
  L.push('## Concept threads and their link types', '');
  L.push('| Thread | Link type | Level | Blueprints used |', '|---|---|---|---|');
  for (const th of threads.threads) {
    const ls = ext.filter(t => t.kind === 'link' && t.thread === th.id);
    L.push(`| ${th.name} (\`${th.id}\`) | ${ls.map(t => '`' + t.id + '`').join(', ') || '**none**'} | ${ls.map(t => t.level.join('–')).join(', ') || '–'} | ${ls.map(t => (t.blueprints || []).length).join(', ') || '–'} of ${th.blueprints.length} |`);
  }
  L.push('');
  return L.join('\n');
}

// ── CLI ──────────────────────────────────────────────────────
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const argv = process.argv.slice(2);
  const i = argv.indexOf('--region');
  const region = i >= 0 ? argv[i + 1] : undefined;
  const data = load();
  const { errors, warnings, counts } = check(data, { region });
  const pad = (s, n) => String(s).padEnd(n);
  console.log(`Skills with a type: ${counts.skillsTyped} of ${counts.skills}`);
  console.log(`Functions misconceptions used: ${counts.fnMisconceptionsUsed} of ${counts.fnMisconceptions}`);
  console.log('');
  console.log(`${pad('region', 26)}${pad('types ex+ext', 14)}${pad('unknowns ex+new', 17)}${pad('reps (new)', 12)}${pad('angles (weak)', 15)}${pad('concepts', 10)}cells (exam-only)`);
  for (const r of counts.regions) {
    if (region && r.id !== region) continue;
    console.log(`${pad(r.name, 26)}${pad(`${r.examTypes}+${r.extTypes}`, 14)}${pad(`${r.examUnknowns}+${r.extUnknowns}`, 17)}${pad(`${r.reps} (${r.repsNotExam})`, 12)}${pad(`${r.angles} (${r.weak})`, 15)}${pad(r.concepts, 10)}${r.cells} (${r.examCells})`);
  }
  if (warnings.length) console.log(`\n${warnings.length} warning(s):\n  ` + warnings.join('\n  '));
  if (errors.length) { console.error(`\n${errors.length} error(s):\n  ` + errors.join('\n  ')); process.exit(1); }
  console.log(`\nOK${region ? ` (region ${region})` : ''}.`);
  if (argv.includes('--write')) {
    fs.writeFileSync(path.join(ROOT, 'curriculum/PEDAGOGY_GAPS.md'), render(data, counts));
    console.log('Wrote curriculum/PEDAGOGY_GAPS.md');
  }
}
