#!/usr/bin/env node
// ── EXAM QUESTION-TYPE CATALOGUE ─────────────────────────────
// Checks curriculum/question-types.json against the Math-AA question bank
// and prints how every tagged part is assigned.
//
//   node tools/question-types.mjs --bank <path>          check and print the counts
//   node tools/question-types.mjs --bank <path> --write  also refresh the stats in the JSON
//                                                         and rewrite curriculum/QUESTION_TYPES.md
//
// The bank is RktRobinhood/Math-AA---Question-Bank. --bank defaults to $QBANK,
// then to a sibling checkout ../Math-AA---Question-Bank. Exit 1 on any error.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const argv = process.argv.slice(2);
const flag = n => argv.includes(n);
const opt = n => { const i = argv.indexOf(n); return i >= 0 ? argv[i + 1] : undefined; };
const BANK = path.resolve(opt('--bank') || process.env.QBANK || path.join(ROOT, '..', 'Math-AA---Question-Bank'));

const readJSON = f => JSON.parse(fs.readFileSync(f, 'utf8'));
const TYPES_FILE = path.join(ROOT, 'curriculum/question-types.json');
const doc = readJSON(TYPES_FILE);
const map = readJSON(path.join(ROOT, 'curriculum/aa-sl.json'));
if (!fs.existsSync(path.join(BANK, 'data/tags.json'))) {
  console.error(`No question bank at ${BANK}. Pass --bank <path to Math-AA---Question-Bank>.`);
  process.exit(1);
}
const tags = readJSON(path.join(BANK, 'data/tags.json')).questions;
const crops = readJSON(path.join(BANK, 'data/crops.json'));
const statements = readJSON(path.join(BANK, 'data/syllabus.json')).statements;

const FORMATS = ['mcq', 'value', 'multipart', 'error-spot', 'method-pick', 'match',
                 'order-steps', 'graph-pick', 'true-false-reason'];
const FULL_FIELDS = ['name', 'summary', 'syllabus', 'skills', 'skillFit', 'chain', 'given', 'asked',
                     'answerForms', 'randomise', 'constraints', 'formats', 'parts'];

// ── Bank parts ───────────────────────────────────────────────
const parts = new Map();   // part ID -> { tags, main, paper, section, marks }
for (const [qid, q] of Object.entries(tags)) {
  const marks = Object.fromEntries((crops[qid]?.parts || []).map(p => [p.label, p.marks]));
  const [, paper, qn] = qid.match(/-(p[12])-q(\d+)$/);
  for (const p of q.parts) {
    const id = p.label ? `${qid}.${p.label}` : qid;
    parts.set(id, {
      tags: p.syllabus, main: p.syllabus[0], paper,
      section: Number(qn) <= 6 ? 'A' : 'B',
      marks: p.label ? marks[p.label] : crops[qid]?.marks,
    });
  }
}

// ── Validate ─────────────────────────────────────────────────
const errors = [];
const skillIds = new Map();
for (const t of map.topics) for (const st of t.subtopics) for (const sk of st.skills) skillIds.set(sk.id, st.id);
const codes = new Set(statements.map(s => s.code));
const owner = new Map();
const typeIds = new Set();

for (const t of doc.types) {
  const where = t.id;
  if (typeIds.has(t.id)) errors.push(`duplicate type ${t.id}`);
  typeIds.add(t.id);
  if (!['full', 'catalogue'].includes(t.detail)) errors.push(`${where}: detail must be full or catalogue`);
  if (t.detail === 'full') {
    for (const f of FULL_FIELDS) {
      const v = t[f];
      if (v == null || (Array.isArray(v) && !v.length) || v === '') errors.push(`${where}: missing ${f}`);
    }
    if (t.skillFit === 'partial' && !t.skillGap) errors.push(`${where}: partial skillFit needs a skillGap`);
  }
  for (const s of t.syllabus || []) if (!codes.has(s)) errors.push(`${where}: unknown statement ${s}`);
  for (const s of t.skills || []) if (!skillIds.has(s)) errors.push(`${where}: unknown skill ${s}`);
  for (const f of t.formats || []) if (!FORMATS.includes(f)) errors.push(`${where}: bad format ${f}`);
  if (!t.parts?.length) errors.push(`${where}: no parts`);
  for (const p of t.parts || []) {
    if (!parts.has(p)) errors.push(`${where}: part ${p} is not in the bank`);
    if (owner.has(p)) errors.push(`${p} is in both ${owner.get(p)} and ${t.id}`);
    owner.set(p, t.id);
  }
  for (const p of t.alsoSeenIn || []) if (!parts.has(p)) errors.push(`${where}: alsoSeenIn ${p} is not in the bank`);
}
for (const u of doc.unclassified || []) {
  if (!parts.has(u.part)) errors.push(`unclassified ${u.part} is not in the bank`);
  if (!u.reason) errors.push(`unclassified ${u.part} has no reason`);
  if (owner.has(u.part)) errors.push(`${u.part} is unclassified and in ${owner.get(u.part)}`);
  owner.set(u.part, 'unclassified');
}
const missing = [...parts.keys()].filter(p => !owner.has(p));
for (const p of missing) errors.push(`part ${p} has no type`);

// ── Stats ────────────────────────────────────────────────────
const median = a => { const s = [...a].sort((x, y) => x - y); return s.length ? s[Math.floor((s.length - 1) / 2)] : null; };
function statsFor(ids) {
  const ps = ids.map(id => parts.get(id)).filter(Boolean);
  const count = (k, v) => ps.filter(p => p[k] === v).length;
  const m = ps.map(p => p.marks).filter(x => x != null);
  const mainTags = {};
  for (const p of ps) mainTags[p.main] = (mainTags[p.main] || 0) + 1;
  return {
    parts: ps.length,
    paper: { p1: count('paper', 'p1'), p2: count('paper', 'p2') },
    section: { A: count('section', 'A'), B: count('section', 'B') },
    marks: { min: Math.min(...m), median: median(m), max: Math.max(...m) },
    mainTags,
  };
}
for (const t of doc.types) t.stats = statsFor(t.parts || []);

// Coverage per syllabus statement
const usedSkills = new Set(doc.types.flatMap(t => t.skills || []));
const coverage = statements.map(s => {
  const sub = `SL${s.code}`;
  const tagged = [...parts.values()].filter(p => p.tags.includes(s.code)).length;
  const main = [...parts.values()].filter(p => p.main === s.code).length;
  const types = doc.types.filter(t => (t.syllabus || []).includes(s.code)).map(t => t.id);
  const skills = [...skillIds].filter(([, st]) => st === sub).map(([id]) => id);
  return {
    statement: s.code, title: s.title, partsTagged: tagged, partsMain: main, types,
    skillsWithoutType: skills.filter(id => !usedSkills.has(id)),
    typesWithoutSkill: doc.types.filter(t => types.includes(t.id) && t.skillFit === 'partial'
      && (t.syllabus || [])[0] === s.code).map(t => t.id),
  };
});

// ── Report ───────────────────────────────────────────────────
const assigned = doc.types.reduce((n, t) => n + (t.parts?.length || 0), 0);
const unclassified = (doc.unclassified || []).length;
console.log(`Bank: ${Object.keys(tags).length} questions, ${parts.size} parts (${BANK})`);
console.log(`Types: ${doc.types.length} (${doc.types.filter(t => t.detail === 'full').length} in full detail)`);
console.log(`Parts assigned to a type: ${assigned}; unclassified: ${unclassified}; total ${assigned + unclassified} of ${parts.size}`);
const byTopic = {};
for (const t of doc.types) {
  const k = `topic ${t.topic}`;
  byTopic[k] ??= { types: 0, parts: 0 };
  byTopic[k].types++; byTopic[k].parts += t.parts.length;
}
for (const [k, v] of Object.entries(byTopic)) console.log(`  ${k}: ${v.types} types, ${v.parts} parts`);
const fnTouch = [...parts.values()].filter(p => p.tags.some(s => s.startsWith('2.'))).length;
const fnMain = [...parts.values()].filter(p => p.main.startsWith('2.')).length;
console.log(`  Functions: ${fnTouch} parts carry a 2.x tag, ${fnMain} as the main tag`);
console.log('');
for (const t of doc.types) console.log(`  ${t.id.padEnd(36)} ${String(t.parts.length).padStart(3)}  P1 ${t.stats.paper.p1} / P2 ${t.stats.paper.p2}  A ${t.stats.section.A} / B ${t.stats.section.B}`);

if (errors.length) {
  console.error(`\n${errors.length} error(s):\n  ` + errors.join('\n  '));
  process.exit(1);
}
console.log('\nOK: every part is assigned exactly once.');

if (!flag('--write')) process.exit(0);

// ── Write ────────────────────────────────────────────────────
doc.bank = { ...doc.bank, questions: Object.keys(tags).length, parts: parts.size };
doc.coverage = coverage;
fs.writeFileSync(TYPES_FILE, JSON.stringify(doc, null, 1) + '\n');
fs.writeFileSync(path.join(ROOT, 'curriculum/QUESTION_TYPES.md'), renderMarkdown());
console.log('Wrote curriculum/question-types.json and curriculum/QUESTION_TYPES.md');

function renderMarkdown() {
  const L = [];
  const list = a => (a || []).join(', ');
  const where = s => `P1 ${s.paper.p1}, P2 ${s.paper.p2}; Section A ${s.section.A}, B ${s.section.B}`;
  const marks = s => s.marks.min === s.marks.max ? `${s.marks.median}` : `usually ${s.marks.median} (${s.marks.min} to ${s.marks.max})`;
  const sectionStats = sec => {
    const qs = Object.keys(tags).filter(q => (Number(q.slice(-2)) <= 6) === (sec === 'A'));
    const ps = [...parts.values()].filter(p => p.section === sec);
    const qm = qs.map(q => crops[q].marks);
    return { q: qs.length, parts: ps.length, perQ: (ps.length / qs.length).toFixed(1),
             marks: `${Math.min(...qm)} to ${Math.max(...qm)}`, mean: (qm.reduce((a, b) => a + b, 0) / qm.length).toFixed(1),
             fn: ps.filter(p => p.main.startsWith('2.')).length };
  };
  const A = sectionStats('A'), B = sectionStats('B');

  L.push('# Exam question types (AA SL)', '');
  L.push('Generated by `node tools/question-types.mjs --bank <path> --write` from `question-types.json`. Edit the JSON, not this file.', '');
  L.push(`Every tagged part of the ${Object.keys(tags).length} questions in the [Math-AA question bank](https://github.com/RktRobinhood/Math-AA---Question-Bank) (${parts.size} parts, ${doc.bank.papers || '34 papers, May 2021 to May 2025'}) is assigned to one **question type**: a pattern a recipe can generate fresh numbers for. The structures are described in our own words; nothing here copies IB question text, numbers or images. Part IDs are listed in the JSON only.`, '');
  L.push(`- **${doc.types.length} types**, ${doc.types.filter(t => t.detail === 'full').length} of them Functions (topic 2) in full detail. The other topics are at catalogue level: name, mapping, counts and part IDs.`);
  L.push(`- **${assigned} parts assigned**, ${unclassified} unclassified, out of ${parts.size}.`);
  L.push(`- **Functions:** ${fnTouch} parts carry a 2.x tag, ${fnMain} of them as the main tag.`);
  L.push('- A part normally goes to a type of its first (main) syllabus tag. A few parts follow the pattern instead: for example, twin-paper parts whose taggers listed the same two tags in opposite orders are kept together, and log-law steps inside an exponential model go with the model.');
  L.push('- `alsoSeenIn` on a Functions type lists parts from other topics that use it as a step (a quadratic solved inside a probability question, a GDC intersection inside a kinematics question).', '');

  L.push('## Section A and Section B', '');
  L.push('| | Section A (questions 1 to 6) | Section B (questions 7 to 9) |', '|---|---|---|');
  L.push(`| Questions in the bank | ${A.q} | ${B.q} |`);
  L.push(`| Marks per question | ${A.marks}, mean ${A.mean} | ${B.marks}, mean ${B.mean} |`);
  L.push(`| Parts per question | ${A.perQ} | ${B.perQ} |`);
  L.push(`| Parts with a Functions main tag | ${A.fn} of ${A.parts} | ${B.fn} of ${B.parts} |`, '');
  L.push('**Section A** questions are short and self-contained: one idea, worked in one to three parts, often a single 4 to 7 mark task with no lettered parts at all. A recipe for a Section A type generates one function and asks one or two things about it.', '');
  L.push('**Section B** questions are long chains of three to seven parts around one function or context. Early parts are cheap (write down an asymptote, evaluate at zero, read a vertex) and feed later ones; "show that" parts hand the student a result so they can carry on even if they went wrong; the last parts are worth the most and usually cross topics (a quadratic leads to a tangent, then an area; a log function leads to a discriminant). A Section B recipe must therefore generate one coherent set of numbers that keeps every later part clean, not each part on its own. The `chain` field of each Functions type records the usual order.', '');
  L.push('**Paper 1 versus Paper 2:** Paper 1 (no calculator) types need values that come out exact: integers, simple fractions, small surds, logs of exact powers. Paper 2 types expect technology and answers to 3 s.f., so a recipe should pick values that are *not* nice, to make the GDC route the natural one.', '');

  L.push('## Functions (topic 2) types', '');
  L.push('| Type | Parts | Where | Marks | Formats |', '|---|---|---|---|---|');
  for (const t of doc.types.filter(t => t.detail === 'full'))
    L.push(`| [${t.name}](#${t.id}) | ${t.parts.length} | ${where(t.stats)} | ${marks(t.stats)} | ${list(t.formats)} |`);
  L.push('');
  for (const t of doc.types.filter(t => t.detail === 'full')) {
    L.push(`### ${t.id}`, '', `**${t.name}.** ${t.summary}`, '');
    L.push(`- **Syllabus:** ${list(t.syllabus)}`);
    L.push(`- **Skills:** ${t.skills.map(s => '`' + s + '`').join(', ')}${t.skillFit === 'partial' ? ` (partial fit: ${t.skillGap})` : ''}`);
    L.push(`- **Where it appears:** ${where(t.stats)}. Marks per part: ${marks(t.stats)}.`);
    L.push(`- **Usual chain:** ${t.chain.join(' → ')}`);
    L.push(`- **Given:** ${list(t.given)}. **Asked:** ${t.asked} **Answer form:** ${list(t.answerForms)}.`);
    L.push(`- **A recipe can randomise:** ${t.randomise.join('; ')}.`);
    L.push(`- **Limits that keep answers clean:** ${t.constraints.join('; ')}.`);
    L.push(`- **Game formats:** ${list(t.formats)}`);
    L.push(`- **Bank parts:** ${t.parts.length}${t.alsoSeenIn?.length ? `; also used as a step in ${t.alsoSeenIn.length} parts from other topics` : ''}.`, '');
  }

  for (const [n, name] of [[1, 'Number and algebra'], [3, 'Geometry and trigonometry'], [4, 'Statistics and probability'], [5, 'Calculus']]) {
    L.push(`## Topic ${n}: ${name} (catalogue level)`, '');
    L.push('| Type | Name | Syllabus | Skills | Parts | Where | Marks |', '|---|---|---|---|---|---|---|');
    for (const t of doc.types.filter(t => t.topic === n))
      L.push(`| \`${t.id}\` | ${t.name} | ${list(t.syllabus)} | ${t.skills.map(s => s.replace(/^SL\d+\.\d+\./, '')).join(', ')} | ${t.parts.length} | ${where(t.stats)} | ${marks(t.stats)} |`);
    L.push('');
  }

  L.push('## Coverage per syllabus statement', '');
  L.push('"Parts" counts parts carrying the tag anywhere, then those where it is the main tag. "Skills with no exam type" are `aa-sl.json` skills that no type maps to: either the bank never examines them or they appear only inside another type. "Types with no full skill" are types whose pattern no curriculum skill fully names.', '');
  L.push('| Statement | Parts (main) | Types | Skills with no exam type | Types with no full skill |', '|---|---|---|---|---|');
  for (const c of coverage)
    L.push(`| ${c.statement} ${c.title} | ${c.partsTagged} (${c.partsMain}) | ${c.types.length} | ${c.skillsWithoutType.map(s => s.replace(/^SL\d+\.\d+\./, '')).join(', ') || '–'} | ${c.typesWithoutSkill.join(', ') || '–'} |`);
  L.push('');
  if (unclassified) {
    L.push('## Unclassified parts', '');
    for (const u of doc.unclassified) L.push(`- \`${u.part}\`: ${u.reason}`);
    L.push('');
  }
  return L.join('\n');
}
