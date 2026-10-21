#!/usr/bin/env node
// ── CURRICULUM COVERAGE REPORT ───────────────────────────────
// Checks the curriculum map, then measures the content packs against it.
//
//   node tools/coverage.mjs           print the report to stdout
//   node tools/coverage.mjs --write   also write curriculum/COVERAGE.md and curriculum/THREADS.md
//   node tools/coverage.mjs --check   map validation only; exit 1 on any error
//
// A question counts toward a skill through `skill` (content schema v2) or,
// for older questions, through `legacyMap` in curriculum/aa-sl.json.

import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const args = new Set(process.argv.slice(2));

const ENUMS = {
  paper: ['p1', 'p2', 'either'],
  formats: ['mcq', 'value', 'multipart', 'error-spot', 'method-pick', 'match',
            'order-steps', 'graph-pick', 'true-false-reason'],
  representations: ['symbolic', 'graph', 'table', 'words', 'context', 'diagram', 'vector'],
  approach: ['algebraic', 'formula', 'graphical', 'gdc', 'numerical', 'geometric',
             'calculus', 'symmetry', 'structural', 'transformation', 'diagram',
             'counting', 'estimation', 'contextual', 'proof'],
};

const readJSON = f => JSON.parse(fs.readFileSync(path.join(ROOT, f), 'utf8'));
const map     = readJSON('curriculum/aa-sl.json');
const threads = readJSON('curriculum/threads.json').threads;
const threadIds = new Set(threads.map(t => t.id));

// ── 1. Validate the map ──────────────────────────────────────
const errors = [];
const subtopics = new Map();   // id -> subtopic
const skills    = new Map();   // id -> { skill, subtopic, topic }

for (const t of map.topics) {
  for (const st of t.subtopics) {
    if (subtopics.has(st.id)) errors.push(`duplicate subtopic ${st.id}`);
    subtopics.set(st.id, st);
    if (!st.skills?.length) errors.push(`${st.id}: no skills`);
    for (const sk of st.skills || []) {
      const where = `${st.id} ${sk.id}`;
      if (skills.has(sk.id)) errors.push(`duplicate skill ${sk.id}`);
      if (!sk.id.startsWith(st.id + '.')) errors.push(`${where}: skill id must start with ${st.id}.`);
      skills.set(sk.id, { skill: sk, subtopic: st, topic: t });
      const [lo, hi] = sk.difficulty || [];
      if (!(lo >= 1 && hi <= 5 && lo <= hi)) errors.push(`${where}: bad difficulty ${JSON.stringify(sk.difficulty)}`);
      if (!ENUMS.paper.includes(sk.paper)) errors.push(`${where}: bad paper ${sk.paper}`);
      for (const f of sk.formats || []) if (!ENUMS.formats.includes(f)) errors.push(`${where}: bad format ${f}`);
      for (const r of sk.representations || []) if (!ENUMS.representations.includes(r)) errors.push(`${where}: bad representation ${r}`);
      if (!sk.methods?.length) errors.push(`${where}: no methods`);
      for (const m of sk.methods || []) if (!ENUMS.approach.includes(m.approach)) errors.push(`${where}: bad approach ${m.approach} on ${m.id}`);
      if (sk.methods?.length === 1 && !sk.singleMethod) errors.push(`${where}: one method but singleMethod not set`);
      for (const th of sk.threads || []) {
        if (!threadIds.has(th.thread)) errors.push(`${where}: unknown thread ${th.thread}`);
        if (!th.echo) errors.push(`${where}: thread ${th.thread} has no echo`);
      }
    }
  }
}
for (const st of subtopics.values())
  for (const p of st.prereqs || []) if (!subtopics.has(p)) errors.push(`${st.id}: unknown prereq ${p}`);
for (const [q, sk] of Object.entries(map.legacyMap || {}))
  if (!skills.has(sk)) errors.push(`legacyMap ${q}: unknown skill ${sk}`);

if (errors.length) {
  console.error(`Map has ${errors.length} error(s):\n  ` + errors.join('\n  '));
  process.exit(1);
}
if (args.has('--check')) {
  console.log(`Map OK: ${subtopics.size} subtopics, ${skills.size} skills, ${threads.length} threads.`);
  process.exit(0);
}

// ── 2. Load the content packs the way the browser does ───────
const packs = [];
const ctx = vm.createContext({ console: { log() {}, warn() {} }, Math, Date });
ctx.WA = { registerPack: p => packs.push(p) };
vm.runInContext(fs.readFileSync(path.join(ROOT, 'js/question-gen.js'), 'utf8'), ctx);
for (const f of fs.readdirSync(path.join(ROOT, 'content')).filter(f => f.endsWith('.js')).sort())
  vm.runInContext(fs.readFileSync(path.join(ROOT, 'content', f), 'utf8'), ctx, { filename: f });

const formatOf = q =>
  q.type === 'parametric' ? (q.outputType === 'mcq' || q.mcqDistractors ? 'mcq' : 'value')
  : q.type === 'boss' ? 'multipart' : q.type;
const methodsOf = q =>
  Array.isArray(q.solutions) ? new Set(q.solutions.map(s => s.method)).size
  : (q.worked_solution || q.solution) ? 1 : 0;

const questions = [];
const unmapped  = [];
for (const p of packs) for (const st of p.subtopics) for (const q of st.questions || []) {
  const skill = q.skill || map.legacyMap?.[q.id];
  if (!skill || !skills.has(skill)) { unmapped.push(`${p.id}/${q.id}`); continue; }
  questions.push({
    id: q.id, skill, difficulty: q.difficulty, format: formatOf(q),
    parametric: q.type === 'parametric' || q.type === 'boss',
    methods: methodsOf(q), threads: q.threads || [],
  });
}

// ── 3. Measure ───────────────────────────────────────────────
const bySkill = new Map([...skills.keys()].map(k => [k, []]));
for (const q of questions) bySkill.get(q.skill).push(q);

const pct = (a, b) => b ? Math.round(100 * a / b) : 0;
const rag = (skillsHit, skillsAll, slotPct) =>
  skillsHit === skillsAll && slotPct >= 80 ? '🟢' : pct(skillsHit, skillsAll) >= 50 ? '🟠' : '🔴';

const out = [];
const totals = { skills: 0, skillsHit: 0, slots: 0, slotsHit: 0, q: 0, multiMethod: 0, methodsMapped: 0 };
out.push('# Curriculum coverage', '',
  `Generated by \`node tools/coverage.mjs --write\` from \`curriculum/aa-sl.json\` and \`content/*.js\`. Do not edit by hand.`, '',
  '**Skill** = a question type IB examines in that subtopic. **Slots** = each skill × each difficulty in its range; a slot is filled by at least one question. ' +
  '**Multi-method** = questions whose solution shows two or more methods (content schema v2). 🟢 every skill hit and ≥80% of slots, 🟠 at least half the skills hit, 🔴 less.', '');

const rows = [];
for (const t of map.topics) {
  rows.push(`| **Topic ${t.topic}: ${t.name}** | | | | | | |`);
  for (const st of t.subtopics) {
    let hit = 0, slots = 0, slotsHit = 0, nq = 0, mm = 0;
    for (const sk of st.skills) {
      const qs = bySkill.get(sk.id);
      if (qs.length) hit++;
      const [lo, hi] = sk.difficulty;
      for (let d = lo; d <= hi; d++) { slots++; if (qs.some(q => q.difficulty === d)) slotsHit++; }
      nq += qs.length; mm += qs.filter(q => q.methods >= 2).length;
      totals.methodsMapped += sk.methods.length;
    }
    totals.skills += st.skills.length; totals.skillsHit += hit;
    totals.slots += slots; totals.slotsHit += slotsHit; totals.q += nq; totals.multiMethod += mm;
    rows.push(`| ${rag(hit, st.skills.length, pct(slotsHit, slots))} ${st.id} ${st.title} | ${hit}/${st.skills.length} | ${slotsHit}/${slots} | ${nq} | ${mm} | ${st.skills.reduce((a, s) => a + s.methods.length, 0)} | ${new Set(st.skills.flatMap(s => (s.threads || []).map(x => x.thread))).size} |`);
  }
}
out.push('## Summary', '',
  `- Subtopics: **${subtopics.size}**. Skills: **${totals.skills}**. Methods mapped: **${totals.methodsMapped}**. Concept threads: **${threads.length}**.`,
  `- Skills with at least one question: **${totals.skillsHit}/${totals.skills}** (${pct(totals.skillsHit, totals.skills)}%).`,
  `- Difficulty slots filled: **${totals.slotsHit}/${totals.slots}** (${pct(totals.slotsHit, totals.slots)}%).`,
  `- Questions mapped: **${totals.q}**, of which multi-method: **${totals.multiMethod}**. Unmapped questions: **${unmapped.length}**.`,
  `- Concept-link questions (tagged with a thread): **${questions.filter(q => q.threads.length).length}**.`, '',
  '## By subtopic', '',
  '| Subtopic | Skills hit | Slots | Questions | Multi-method | Methods mapped | Threads |',
  '|---|---|---|---|---|---|---|', ...rows, '');

out.push('## Skills with no questions yet', '');
for (const t of map.topics) {
  const gaps = t.subtopics.flatMap(st => st.skills.filter(sk => !bySkill.get(sk.id).length).map(sk => `\`${sk.id}\` ${sk.name}`));
  out.push(`<details><summary>Topic ${t.topic}: ${gaps.length} gaps</summary>`, '', ...gaps.map(g => `- ${g}`), '', '</details>', '');
}
if (unmapped.length) out.push('## Unmapped questions', '', ...unmapped.map(u => `- \`${u}\``), '');

// ── 4. Threads view ──────────────────────────────────────────
const th = ['# Concept threads', '',
  'Generated by `node tools/coverage.mjs --write`. Each thread is one big idea that recurs across the islands. ' +
  'Appearances come from the `threads` tags on skills in `curriculum/aa-sl.json`; names and link-question blueprints from `curriculum/threads.json`.', ''];
for (const t of threads) {
  const apps = [...skills.values()].flatMap(({ skill, subtopic }) =>
    (skill.threads || []).filter(x => x.thread === t.id).map(x => ({ skill, subtopic, echo: x.echo })));
  const islands = new Set(apps.map(a => a.subtopic.id.split('.')[0]));
  const linkQs = questions.filter(q => q.threads.includes(t.id)).length;
  th.push(`## ${t.name} (\`${t.id}\`)`, '', t.bigIdea, '',
    `${apps.length} skills across ${islands.size} topics. Link questions written: ${linkQs}.`, '',
    '| Where | Skill | How the idea shows up |', '|---|---|---|',
    ...apps.map(a => `| ${a.subtopic.id} | ${a.skill.name} | ${a.echo.replace(/\|/g, '\\|')} |`), '');
  if (t.blueprints?.length) th.push('**Link-question blueprints**', '', ...t.blueprints.map(b => `- *${b.format}*: ${b.prompt}`), '');
}

const report = out.join('\n');
if (args.has('--write')) {
  fs.writeFileSync(path.join(ROOT, 'curriculum/COVERAGE.md'), report);
  fs.writeFileSync(path.join(ROOT, 'curriculum/THREADS.md'), th.join('\n'));
  console.log('Wrote curriculum/COVERAGE.md and curriculum/THREADS.md');
} else {
  console.log(report);
}
