// Content validator: `node --test tests/content/`
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { loadItems, loadPacks, loadGenerated, PACK_FILES } from './packs.mjs';
import { CHECKS, splitMath, textsOf } from './checks.mjs';
import { KNOWN_DEFECTS } from './known-defects.mjs';

const items = loadItems();
const byId = new Map(items.map(i => [i.id, i]));
const isKnown = (id, check) => KNOWN_DEFECTS.some(d => d.id === id && d.check === check);

test('all five packs register', () => {
  const packs = loadPacks();
  assert.equal(packs.length, PACK_FILES.length);
  for (const pack of packs) assert.ok(pack.subtopics?.length > 0, `${pack.id} has no subtopics`);
});

test('question ids are unique', () => {
  const seen = new Map();
  const dupes = [];
  for (const item of items.filter(i => !i.parent)) {
    if (seen.has(item.id)) dupes.push(`${item.id} (${seen.get(item.id)} and ${item.packId})`);
    else seen.set(item.id, item.packId);
  }
  assert.deepEqual(dupes, []);
});

for (const [name, check] of Object.entries(CHECKS)) {
  test(name, () => {
    const failures = items
      .filter(item => !isKnown(item.id, name))
      .flatMap(item => check(item).map(p => `${item.id}: ${p}`));
    assert.deepEqual(failures, []);
  });
}

// Guard against the KaTeX check passing because it found no maths at all
test('validator self-check: KaTeX check sees the maths and rejects bad TeX', () => {
  const segments = items.flatMap(i => textsOf(i.q)).flatMap(([, t]) => splitMath(t)).filter(s => s.math);
  assert.ok(segments.length > 300, `only ${segments.length} maths segments found`);
  assert.equal(CHECKS['katex-parses']({ q: { question: 'Find $\\frac{1}$.' } }).length, 1);
  assert.equal(CHECKS['katex-parses']({ q: { question: '$\\notacommand x$' } }).length, 1);
  // An unclosed brace means auto-render never finds the closing $, so it's shown raw
  assert.equal(CHECKS['no-raw-tex']({ q: { question: 'Find $\\frac{1}{2$.' } }).length, 1);
  assert.equal(CHECKS['no-raw-tex']({ q: { options: ['\\$5', '$\\$5$', 'b', 'c'] } }).length, 1);
});

// ── Generated questions ─────────────────────────────────────────────────
// Every template expanded 200 times by the real QGen, each expansion run
// through the same checks as static content.
const RUNS = 200;
const generated = loadGenerated(RUNS);

test('there are generated templates to check', () => {
  assert.ok(generated.length >= 30, `only ${generated.length} templates`);
});

for (const g of generated) {
  test(`generated ${g.id}: ${RUNS} expansions pass every check`, () => {
    const problems = new Set();
    for (const q of g.expansions) {
      if (!q) { problems.add('expand() failed'); continue; }
      if (q.id !== g.id) problems.add(`id ${q.id} is not the template id (spaced repetition keys on it)`);
      if (!['mcq', 'value'].includes(q.type)) problems.add(`type ${q.type}`);
      if (q.difficulty !== g.template.difficulty) problems.add('difficulty not copied');
      for (const [name, check] of Object.entries(CHECKS)) {
        for (const p of check({ q })) problems.add(`${name}: ${p}`);
      }
    }
    assert.deepEqual([...problems].slice(0, 10), []);
  });
}

test('generated MCQs put the answer in every position', () => {
  for (const g of generated.filter(g => g.expansions[0]?.type === 'mcq')) {
    const seen = new Set(g.expansions.map(q => q.correctIndex));
    assert.deepEqual([...seen].sort(), [0, 1, 2, 3], g.id);
  }
});

// ── Content fixed in FAL-210 stays fixed ───────────────────────────────
const get = id => byId.get(id)?.q;
const genOf = id => generated.find(g => g.id === id).expansions;

test('sl1-4-a: keyed 1200 × 1.05³ = 1389.15, with the $ inside maths', () => {
  const q = get('sl1-4-a');
  assert.equal(Math.round(1200 * 1.05 ** 3 * 100) / 100, 1389.15);
  assert.match(q.options[q.correctIndex], /1389\.15/);
  assert.equal(q.options.filter(o => /1389\.15/.test(o)).length, 1);
});

test('sl1-5-d: keyed x = ln3 / (ln5 − ln3) ≈ 2.15', () => {
  const q = get('sl1-5-d');
  const x = Math.log(3) / (Math.log(5) - Math.log(3));
  assert.match(q.options[q.correctIndex], new RegExp(x.toFixed(2).replace('.', '\\.')));
  assert.doesNotMatch(q.worked_solution, /3\.15/);
});

test('sl1-9-d: only one option is k = ±2', () => {
  const q = get('sl1-9-d');
  assert.ok(!q.options.some(o => /\\pm\s*\\sqrt\{4\}/.test(o)));
  assert.match(q.options[q.correctIndex], /\\pm 2\b/);
});

test('sl2-5-natlog: ln√7 is no longer an option', () => {
  const q = get('sl2-5-natlog');
  assert.ok(!q.options.some(o => /\\ln\\sqrt\{7\}/.test(o)));
  assert.doesNotMatch(q.worked_solution, /also correct/);
});

test('sl5-boss-1 (d): the worked solution reaches the stored answer 8', () => {
  const part = get('sl5-boss-1').parts[3];
  assert.equal(part.answer, 8);
  assert.match(part.worked_solution, /= 8\$ square units/);
});

test('sl2-boss-1 (a) and sl5-4-stationary say which root to enter', () => {
  assert.match(get('sl2-boss-1').parts[0].question, /smaller/);
  for (const q of genOf('sl5-4-stationary')) assert.match(q.question, /positive one/);
});

test('sl5-8-accel states the time', () => {
  for (const q of genOf('sl5-8-accel')) {
    const t = Number(q.question.match(/at \$t = (\d+)\$/)?.[1]);
    assert.ok(t > 0, q.question);
  }
});

test('sl3-4-rad-deg asks for k in kπ, which the numpad can enter', () => {
  for (const q of genOf('sl3-4-rad-deg')) {
    const deg = Number(q.question.match(/\$(\d+)°\$/)[1]);
    assert.ok(Math.abs(q.answer - deg / 180) < 1e-12, q.question);
    assert.doesNotMatch(q.question, /d\.p\./);
  }
});

test('sl2-4-vertex only asks for the vertex', () => {
  for (const q of genOf('sl2-4-vertex')) assert.doesNotMatch(q.question, /expand/i);
});

// ── Known defects: reported as TODO until they're fixed ────────────────
for (const d of KNOWN_DEFECTS) {
  test(`known defect ${d.id}: ${d.reason}`, { todo: 'content fix' }, () => {
    const item = byId.get(d.id);
    assert.ok(item, `no item ${d.id}`);
    if (d.check) assert.deepEqual(CHECKS[d.check](item), []);
    else d.assert(item.q);
  });
}

test('known-defect list is current (delete entries once fixed)', () => {
  const stale = KNOWN_DEFECTS.filter(d => {
    const item = byId.get(d.id);
    if (!item) return true;
    if (d.check) return CHECKS[d.check](item).length === 0;
    try { d.assert(item.q); return true; } catch { return false; }
  }).map(d => `${d.id}: ${d.reason}`);
  assert.deepEqual(stale, []);
});
