#!/usr/bin/env node
// ── EXAM QUESTION-TYPE CATALOGUE ─────────────────────────────
// Checks curriculum/question-types.json against the Math-AA question bank
// and prints how every tagged part is assigned.
//
//   node tools/question-types.mjs --bank <path>          check and print the counts
//   node tools/question-types.mjs --bank <path> --write  also refresh the stats in the JSON, pin the
//                                                         bank commit, rewrite curriculum/QUESTION_TYPES.md
//                                                         and merge the bank's catalogue fragments
//                                                         into curriculum/bank-types.json
//   --commit <sha>                                       the bank commit to pin, when <path> is not a
//                                                         git checkout (an export, say)
//
// The bank is RktRobinhood/Math-AA---Question-Bank. --bank defaults to $QBANK,
// then to a sibling checkout ../Math-AA---Question-Bank. Exit 1 on any error.
//
// The bank serves four courses (its data/courses.json). Every AA SL part from the sessions
// in `bank.assigned` must have a type; parts of the other courses, and AA SL parts from later
// sessions, are counted per course as unassigned and do not fail the run.

import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const argv = process.argv.slice(2);
const flag = n => argv.includes(n);
const opt = n => { const i = argv.indexOf(n); return i >= 0 ? argv[i + 1] : undefined; };
const BANK = path.resolve(opt('--bank') || process.env.QBANK || path.join(ROOT, '..', 'Math-AA---Question-Bank'));

const readJSON = f => JSON.parse(fs.readFileSync(f, 'utf8'));
const inBank = f => path.join(BANK, f);
const TYPES_FILE = path.join(ROOT, 'curriculum/question-types.json');
const BANK_TYPES_FILE = path.join(ROOT, 'curriculum/bank-types.json');
const doc = readJSON(TYPES_FILE);
// Extension types (source: extension) have no bank parts; tools/pedagogy.mjs checks them.
const examTypes = doc.types.filter(t => t.source !== 'extension');
const map = readJSON(path.join(ROOT, 'curriculum/aa-sl.json'));
if (!fs.existsSync(inBank('data/tags.json'))) {
  console.error(`No question bank at ${BANK}. Pass --bank <path to Math-AA---Question-Bank>.`);
  process.exit(1);
}
const statements = readJSON(inBank('data/syllabus.json')).statements;
const errors = [];

// ── Bank courses ─────────────────────────────────────────────
// Each course names its tags and crops files and its papers. A paper's identity (P1 to P3) is
// kept apart from its calculator policy: AI Paper 1 allows a GDC, AA Paper 1 does not. A bank
// from before data/courses.json has AA SL only.
const COURSES = fs.existsSync(inBank('data/courses.json')) ? readJSON(inBank('data/courses.json')).courses : [
  { id: 'aa-sl', short: 'AA SL', subject: 'aa', tags: 'data/tags.json', crops: 'data/crops.json',
    papers: [{ id: 'P1', calculator: false }, { id: 'P2', calculator: true }] },
];
// A question on both the SL and the HL paper of an exam is stored once, under its SL id;
// data/shared.json lists each HL appearance. Its parts are counted once, under the SL course.
const shared = fs.existsSync(inBank('data/shared.json')) ? readJSON(inBank('data/shared.json')).appearances : {};

// Syllabus code -> statement id, per subject. AA HL tags use SL and AHL codes. AI tags use AI
// guide codes; `shared` in syllabus-ai.json maps those that equal an AA statement to its id.
const codeIds = { aa: new Map(), ai: new Map() };
for (const s of statements) codeIds.aa.set(s.code, s.id || `SL${s.code}`);
const optional = f => fs.existsSync(inBank(f)) ? readJSON(inBank(f)) : null;
for (const s of optional('data/syllabus-aa-hl.json')?.statements || []) codeIds.aa.set(s.code, s.id);
const aiSyllabus = optional('data/syllabus-ai.json');
for (const s of aiSyllabus?.statements || []) codeIds.ai.set(s.code, s.id);
for (const s of aiSyllabus?.shared || []) codeIds.ai.set(s.code, s.id);

// Sessions in order: 2025-nov is after 2025-may.
const ID_RE = /^([a-z]+-[a-z]+)-(\d{4})-(may|nov)-.*-(p[123])-q(\d+)$/;
const sessionKey = s => { const [y, m] = s.split('-'); return Number(y) * 2 + (m === 'nov' ? 1 : 0); };
const assignedThrough = doc.bank?.assigned || {};
const mustAssign = p => p.course in assignedThrough && sessionKey(p.session) <= sessionKey(assignedThrough[p.course]);

// ── Bank parts ───────────────────────────────────────────────
const all = new Map();    // part ID -> { course, session, tags, main, paper, calculator, section, marks, unresolved }
const questions = {};     // course -> its stored question IDs
const missingCourses = [];
let tags = {}, crops = {}; // AA SL, for the AA SL report below
for (const c of COURSES) {
  if (!fs.existsSync(inBank(c.tags))) { missingCourses.push(c.id); continue; }
  const ctags = readJSON(inBank(c.tags)).questions;
  const ccrops = readJSON(inBank(c.crops));
  const papers = new Map(c.papers.map(p => [p.id.toLowerCase(), p]));
  const ids = codeIds[c.subject || c.id.split('-')[0]] || new Map();
  questions[c.id] = Object.keys(ctags);
  if (c.id === 'aa-sl') crops = ccrops;
  for (const [qid, q] of Object.entries(ctags)) {
    const m = qid.match(ID_RE);
    if (!m || m[1] !== c.id) { errors.push(`bank question ${qid} does not fit ${c.id} <year>-<may|nov>-…-p<n>-q<n>`); continue; }
    const [, , year, month, paper, qn] = m;
    if (!papers.has(paper)) errors.push(`bank question ${qid}: ${c.id} has no paper ${paper.toUpperCase()}`);
    if (shared[qid]) errors.push(`bank question ${qid} is stored and also listed in shared.json`);
    const marks = Object.fromEntries((ccrops[qid]?.parts || []).map(p => [p.label, p.marks]));
    for (const p of q.parts) {
      const id = p.label ? `${qid}.${p.label}` : qid;
      all.set(id, {
        course: c.id, session: `${year}-${month}`,
        tags: p.syllabus, main: p.syllabus[0], paper, calculator: papers.get(paper)?.calculator,
        // AA SL: questions 1 to 6 are Section A. Elsewhere the crop says, or there are no sections.
        section: c.id === 'aa-sl' ? (Number(qn) <= 6 ? 'A' : 'B') : ccrops[qid]?.section ?? null,
        marks: p.label ? marks[p.label] : ccrops[qid]?.marks,
        unresolved: p.syllabus.filter(code => !ids.has(code)),
      });
    }
  }
  if (c.id === 'aa-sl') tags = Object.fromEntries(Object.entries(ctags).filter(([qid]) => {
    const m = qid.match(ID_RE);
    return m && mustAssign({ course: c.id, session: `${m[2]}-${m[3]}` });
  }));
}
for (const [hid, a] of Object.entries(shared))
  if (!missingCourses.some(c => a.canonical.startsWith(`${c}-`)) && !Object.values(questions).some(qs => qs.includes(a.canonical))) errors.push(`shared.json: ${hid} points at ${a.canonical}, which is not in the bank`);
// The parts the catalogue must assign: AA SL up to bank.assigned.
const parts = new Map([...all].filter(([, p]) => mustAssign(p)));

const FORMATS = ['mcq', 'value', 'multipart', 'error-spot', 'method-pick', 'match',
                 'order-steps', 'graph-pick', 'true-false-reason'];
const FULL_FIELDS = ['name', 'summary', 'syllabus', 'skills', 'skillFit', 'chain', 'given', 'asked',
                     'answerForms', 'randomise', 'constraints', 'formats', 'parts'];

// ── Validate ─────────────────────────────────────────────────
const skillIds = new Map();
for (const t of map.topics) for (const st of t.subtopics) for (const sk of st.skills) skillIds.set(sk.id, st.id);
const codes = new Set(statements.map(s => s.code));
const owner = new Map();
const typeIds = new Set();
for (const t of doc.types) {
  if (typeIds.has(t.id)) errors.push(`duplicate type ${t.id}`);
  typeIds.add(t.id);
}

for (const t of examTypes) {
  const where = t.id;
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
    if (!all.has(p)) errors.push(`${where}: part ${p} is not in the bank`);
    else if (!parts.has(p)) errors.push(`${where}: part ${p} is outside bank.assigned; widen it first`);
    if (owner.has(p)) errors.push(`${p} is in both ${owner.get(p)} and ${t.id}`);
    owner.set(p, t.id);
  }
  for (const p of t.alsoSeenIn || []) if (!all.has(p)) errors.push(`${where}: alsoSeenIn ${p} is not in the bank`);
}
for (const u of doc.unclassified || []) {
  if (!parts.has(u.part)) errors.push(`unclassified ${u.part} is ${all.has(u.part) ? 'outside bank.assigned' : 'not in the bank'}`);
  if (!u.reason) errors.push(`unclassified ${u.part} has no reason`);
  if (owner.has(u.part)) errors.push(`${u.part} is unclassified and in ${owner.get(u.part)}`);
  owner.set(u.part, 'unclassified');
}
const missing = [...parts.keys()].filter(p => !owner.has(p));
for (const p of missing) errors.push(`part ${p} has no type`);

// ── Stats ────────────────────────────────────────────────────
const median = a => { const s = [...a].sort((x, y) => x - y); return s.length ? s[Math.floor((s.length - 1) / 2)] : null; };
function statsFor(ids) {
  const ps = ids.map(id => all.get(id)).filter(Boolean);
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
for (const t of examTypes) t.stats = statsFor(t.parts || []);

// Coverage per syllabus statement
const usedSkills = new Set(examTypes.flatMap(t => t.skills || []));
const coverage = statements.map(s => {
  const sub = `SL${s.code}`;
  const tagged = [...parts.values()].filter(p => p.tags.includes(s.code)).length;
  const main = [...parts.values()].filter(p => p.main === s.code).length;
  const types = examTypes.filter(t => (t.syllabus || []).includes(s.code)).map(t => t.id);
  const skills = [...skillIds].filter(([, st]) => st === sub).map(([id]) => id);
  return {
    statement: s.code, title: s.title, partsTagged: tagged, partsMain: main, types,
    skillsWithoutType: skills.filter(id => !usedSkills.has(id)),
    typesWithoutSkill: examTypes.filter(t => types.includes(t.id) && t.skillFit === 'partial'
      && (t.syllabus || [])[0] === s.code).map(t => t.id),
  };
});

// ── Report ───────────────────────────────────────────────────
const assigned = examTypes.reduce((n, t) => n + (t.parts?.length || 0), 0);
const unclassified = (doc.unclassified || []).length;
console.log(`Bank: ${Object.keys(tags).length} questions, ${parts.size} parts (${BANK})`);
console.log(`Types: ${examTypes.length} (${examTypes.filter(t => t.detail === 'full').length} in full detail)`);
console.log(`Parts assigned to a type: ${assigned}; unclassified: ${unclassified}; total ${assigned + unclassified} of ${parts.size}`);
const byTopic = {};
for (const t of examTypes) {
  const k = `topic ${t.topic}`;
  byTopic[k] ??= { types: 0, parts: 0 };
  byTopic[k].types++; byTopic[k].parts += t.parts.length;
}
for (const [k, v] of Object.entries(byTopic)) console.log(`  ${k}: ${v.types} types, ${v.parts} parts`);
const fnTouch = [...parts.values()].filter(p => p.tags.some(s => s.startsWith('2.'))).length;
const fnMain = [...parts.values()].filter(p => p.main.startsWith('2.')).length;
console.log(`  Functions: ${fnTouch} parts carry a 2.x tag, ${fnMain} as the main tag`);
console.log('');
for (const t of examTypes) console.log(`  ${t.id.padEnd(36)} ${String(t.parts.length).padStart(3)}  P1 ${t.stats.paper.p1} / P2 ${t.stats.paper.p2}  A ${t.stats.section.A} / B ${t.stats.section.B}`);


// ── Per course ───────────────────────────────────────────────
const bankCommit = (() => {
  // Only when BANK is the top of a checkout, not an export inside some other repository
  const git = (...a) => execFileSync('git', ['-C', BANK, ...a], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
  try { return fs.realpathSync(git('rev-parse', '--show-toplevel')) === fs.realpathSync(BANK) ? git('rev-parse', 'HEAD') : null; }
  catch { return null; }
})();
const courseStats = Object.fromEntries(COURSES.filter(c => questions[c.id]).map(c => {
  const ps = [...all].filter(([, p]) => p.course === c.id);
  const kind = id => owner.get(id) === 'unclassified' ? 'unclassified' : owner.has(id) ? 'assigned' : 'unassigned';
  const n = k => ps.filter(([id]) => kind(id) === k).length;
  const appearances = Object.entries(shared).filter(([hid]) => hid.startsWith(`${c.id}-`)).map(([, a]) => a);
  return [c.id, {
    questions: questions[c.id].length, parts: ps.length,
    assigned: n('assigned'), unclassified: n('unclassified'), unassigned: n('unassigned'),
    papers: Object.fromEntries(c.papers.map(pp => [pp.id, { calculator: pp.calculator, parts: ps.filter(([, p]) => p.paper === pp.id.toLowerCase()).length }])),
    shared: { questions: appearances.length, parts: [...all].filter(([id]) => appearances.some(a => id === a.canonical || id.startsWith(`${a.canonical}.`))).length },
    unknownCodes: ps.filter(([, p]) => p.unresolved.length).length,
  }];
}));
console.log(`\nCourses (bank ${bankCommit ? bankCommit.slice(0, 8) : 'not a git checkout'}${doc.bank?.commit ? `, catalogue pinned to ${doc.bank.commit.slice(0, 8)}` : ''}):`);
for (const c of COURSES) {
  const s = courseStats[c.id];
  if (!s) { console.log(`  ${c.short.padEnd(6)} not in this bank`); continue; }
  const later = c.id in assignedThrough ? ` (sessions after ${assignedThrough[c.id]})` : '';
  console.log(`  ${c.short.padEnd(6)} ${s.questions} questions, ${s.parts} parts: ${s.assigned} assigned, ${s.unclassified} unclassified, ${s.unassigned} unassigned${s.unassigned ? later : ''}`);
  const papers = Object.entries(s.papers).map(([id, x]) => `${id} ${x.calculator ? 'GDC' : 'no GDC'} ${x.parts}`).join(', ');
  const sh = s.shared.questions ? `; also ${s.shared.questions} SL questions (${s.shared.parts} parts) on its papers, counted under SL` : '';
  console.log(`  ${''.padEnd(6)} ${papers}${sh}${s.unknownCodes ? `; ${s.unknownCodes} parts carry a code that is in no syllabus file` : ''}`);
}
if (bankCommit && doc.bank?.commit && bankCommit !== doc.bank.commit) console.log(`  Note: the bank is at ${bankCommit.slice(0, 8)}; --write re-pins the catalogue to it.`);

if (errors.length) {
  console.error(`\n${errors.length} error(s):\n  ` + errors.join('\n  '));
  process.exit(1);
}
console.log('\nOK: every part is assigned exactly once.');

if (!flag('--write')) process.exit(0);

// ── Write ────────────────────────────────────────────────────
const commit = opt('--commit') || bankCommit;
if (!/^[0-9a-f]{40}$/.test(commit || '')) {
  console.error(`--write pins the bank commit: ${BANK} is not a git checkout, so pass --commit <full sha>.`);
  process.exit(1);
}
if (missingCourses.length) {
  console.error(`--write needs all four courses; this bank has no ${missingCourses.join(', ')}.`);
  process.exit(1);
}
doc.bank = { ...doc.bank, commit, questions: Object.keys(tags).length, parts: parts.size, courses: courseStats };
doc.coverage = coverage;
const bankTypes = mergeFragments(commit);
fs.writeFileSync(TYPES_FILE, JSON.stringify(doc, null, 1) + '\n');
fs.writeFileSync(path.join(ROOT, 'curriculum/QUESTION_TYPES.md'), renderMarkdown());
fs.writeFileSync(BANK_TYPES_FILE, JSON.stringify(bankTypes, null, 1) + '\n');
console.log(`Wrote curriculum/question-types.json, curriculum/QUESTION_TYPES.md and curriculum/bank-types.json (${bankTypes.types.length} unbuilt types), pinned to ${commit.slice(0, 8)}`);

// The bank's HL and AI catalogue fragments (data/question-types/*.json), as unbuilt types.
// Their ids are the bank's and stay as they are; a type moves to question-types.json when it
// is built. Each gets `courses` (the fragment's `home` unless it says), the statement ids its
// `syllabus` codes name, and the fragment it came from. Skills the curriculum maps don't have
// yet are the bank's sub-tags; `skills` lists them with the bank's name for each.
function mergeFragments(commit) {
  const dir = inBank('data/question-types');
  const files = fs.readdirSync(dir).filter(f => f.endsWith('.json')).sort();
  const mapSkills = new Set();
  for (const f of ['aa-sl', 'aa-hl', 'ai'])
    for (const t of readJSON(path.join(ROOT, `curriculum/${f}.json`)).topics)
      for (const st of t.subtopics) for (const sk of st.skills) mapSkills.add(sk.id);
  const subtags = new Map();
  for (const f of ['data/syllabus.json', 'data/syllabus-aa-hl.json', 'data/syllabus-ai.json'])
    for (const s of readJSON(inBank(f)).statements) for (const x of s.subtags || []) subtags.set(x.id, x);
  const fragSkills = new Map();
  const types = [];
  for (const f of files) {
    const frag = readJSON(path.join(dir, f));
    for (const v of Object.values(frag.subtopics || {})) for (const sk of v.skills || []) fragSkills.set(sk.id, sk);
    for (const t of frag.types) {
      const home = t.home || frag.home || 'aa-sl';
      const ids = codeIds[home.split('-')[0]];
      types.push({ ...t, home, courses: t.courses || [home], subtopics: (t.syllabus || []).map(code => ids.get(code) ?? null), fragment: f });
    }
  }
  const named = [...new Set(types.flatMap(t => [...(t.skills || []), ...(t.unknowns || []).flatMap(u => u.skills || [])]))].sort();
  const skills = {};
  for (const id of named) {
    if (mapSkills.has(id)) continue;
    const st = subtags.get(id), fr = fragSkills.get(id);
    skills[id] = { name: st?.name ?? null, ...(fr?.levels && { levels: fr.levels }), ...(fr?.paper && { paper: fr.paper }) };
  }
  return {
    about: 'Unbuilt AA HL, AI SL and AI HL question types from the Math-AA question bank\'s catalogue fragments (data/question-types/*.json), merged by node tools/question-types.mjs --write. Not read at runtime. Type ids are the bank\'s; `courses`, `subtopics` and `fragment` are added. `skills` lists the bank sub-tags these types name that the curriculum maps do not have yet, with the bank\'s name for each. Checked by tools/courses.mjs (courses and subtopics) and tools/pedagogy.mjs (the type fields). Edit the bank, not this file.',
    bank: { repo: doc.bank.repo, commit, fragments: files },
    types, skills,
  };
}

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
  const fnFull = examTypes.filter(t => t.detail === 'full' && t.topic === 2);
  const otherFull = examTypes.filter(t => t.detail === 'full' && t.topic !== 2);
  L.push(`- **${examTypes.length} types**, ${fnFull.length} of them Functions (topic 2) in full detail${otherFull.length ? ` and ${otherFull.length} from other topics` : ''}. The rest of the other topics are at catalogue level: name, mapping, counts and part IDs.`);
  L.push(`- **${assigned} parts assigned**, ${unclassified} unclassified, out of ${parts.size}.`);
  L.push(`- **Functions:** ${fnTouch} parts carry a 2.x tag, ${fnMain} of them as the main tag.`);
  L.push('- A part normally goes to a type of its first (main) syllabus tag. A few parts follow the pattern instead: for example, twin-paper parts whose taggers listed the same two tags in opposite orders are kept together, and log-law steps inside an exponential model go with the model.');
  L.push('- `alsoSeenIn` on a Functions type lists parts from other topics that use it as a step (a quadratic solved inside a probability question, a GDC intersection inside a kinematics question).');
  L.push(`- This file covers the exam types only. The ${doc.types.length - examTypes.length} extension types, and the unknowns, representations and methods of every Functions type, are in \`PEDAGOGY_GAPS.md\`.`, '');

  L.push('## All four courses in the bank', '');
  L.push(`The bank at \`${doc.bank.commit.slice(0, 8)}\` (the pinned commit) holds all four courses. This catalogue assigns the AA SL parts up to ${assignedThrough['aa-sl']}; the rest are unassigned until types are built for them. The bank's own HL and AI type briefs are in \`bank-types.json\`, unbuilt. A question on both an SL and an HL paper is stored once, under its SL id, so its parts are counted under the SL course only. Paper and calculator are kept apart: every AI paper allows a GDC.`, '');
  L.push('| Course | Questions | Parts | Assigned | Unassigned | Parts per paper | SL questions also on its papers |', '|---|--:|--:|--:|--:|---|--:|');
  for (const c of COURSES) {
    const s = doc.bank.courses[c.id];
    const papers = Object.entries(s.papers).map(([id, x]) => `${id} (${x.calculator ? 'GDC' : 'no GDC'}) ${x.parts}`).join(', ');
    L.push(`| ${c.short} | ${s.questions} | ${s.parts} | ${s.assigned + s.unclassified} | ${s.unassigned} | ${papers} | ${s.shared.questions ? `${s.shared.questions} (${s.shared.parts} parts)` : '–'} |`);
  }
  L.push('');

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
  for (const t of fnFull)
    L.push(`| [${t.name}](#${t.id}) | ${t.parts.length} | ${where(t.stats)} | ${marks(t.stats)} | ${list(t.formats)} |`);
  L.push('');
  const fullBlock = t => {
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
  };
  for (const t of fnFull) fullBlock(t);

  for (const [n, name] of [[1, 'Number and algebra'], [3, 'Geometry and trigonometry'], [4, 'Statistics and probability'], [5, 'Calculus']]) {
    L.push(`## Topic ${n}: ${name} (catalogue level)`, '');
    L.push('| Type | Name | Syllabus | Skills | Parts | Where | Marks |', '|---|---|---|---|---|---|---|');
    for (const t of examTypes.filter(t => t.topic === n))
      L.push(`| \`${t.id}\` | ${t.name} | ${list(t.syllabus)} | ${t.skills.map(s => s.replace(/^SL\d+\.\d+\./, '')).join(', ')} | ${t.parts.length} | ${where(t.stats)} | ${marks(t.stats)} |`);
    L.push('');
    for (const t of otherFull.filter(t => t.topic === n)) fullBlock(t);
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
