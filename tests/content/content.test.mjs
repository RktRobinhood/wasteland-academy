// Content validator: `node --test tests/content/`
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { loadItems, loadPacks, PACK_FILES } from './packs.mjs';
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

// ── Known defects: reported as TODO until task 2/8 fixes them ──────────
for (const d of KNOWN_DEFECTS) {
  test(`known defect ${d.id}: ${d.reason}`, { todo: 'content fix (task 2/8)' }, () => {
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
