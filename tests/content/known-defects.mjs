// Content defects found by the FAL-205 engine audit. They're reported as TODO
// tests, so they stay visible without turning the suite red. Task 2/8 fixes
// them; when one is fixed, the "known-defect list is current" test fails until
// its entry is deleted here.
//
// Each entry is either:
//   { id, check, reason }   a mechanical check from checks.mjs that fails on this item
//   { id, reason, assert }  a targeted assertion that holds once the item is fixed
//
// Generated (parametric) templates aren't covered here; they belong to the
// task that wires up QGen.
import assert from 'node:assert/strict';

export const KNOWN_DEFECTS = [
  {
    id: 'sl1-4-a',
    check: 'no-raw-tex',
    reason: 'options are "\\$1380.00" with no maths delimiters, so players see a raw "\\$"',
  },
  {
    id: 'sl1-4-a',
    reason: 'answer key is wrong: 1200 × 1.05³ = 1389.15, keyed 1386.45, and no option is right',
    assert: q => assert.match(q.options[q.correctIndex], /1389\.15/),
  },
  {
    id: 'sl1-5-d',
    reason: 'answer key is wrong: x = ln3 / (ln5 − ln3) ≈ 2.15 (option A), keyed 3.15',
    assert: q => {
      assert.match(q.options[q.correctIndex], /2\.15/);
      assert.doesNotMatch(q.worked_solution, /3\.15/);
    },
  },
  {
    id: 'sl1-9-d',
    reason: 'two options are correct: k = ±√4 and k = ±2',
    assert: q => assert.ok(!(q.options.some(o => /\\pm\s*\\sqrt\{4\}/.test(o)) && q.options.some(o => /\\pm\s*2\b/.test(o)))),
  },
  {
    id: 'sl2-5-natlog',
    reason: 'two options are correct: x = ln7 / 2 and x = ln√7 (the worked solution says so)',
    assert: q => assert.ok(!(q.options.some(o => /\\dfrac\{\\ln 7\}\{2\}/.test(o)) && q.options.some(o => /\\ln\\sqrt\{7\}/.test(o)))),
  },
  {
    id: 'sl5-boss-1.parts[3]',
    reason: 'worked solution says "= 4" but the stored (correct) answer is 8',
    assert: q => assert.doesNotMatch(q.worked_solution, /=\s*4\$?\s*square units/),
  },
];
