// Spaced repetition and question selection (js/spaced-rep.js, SPEC §7)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { loadScripts } from '../content/packs.mjs';

function freshSR() {
  const ctx = loadScripts(['js/spaced-rep.js'], { WA: { save() {} } });
  const SR = vm.runInContext('SR', ctx);
  SR.init({ spaced: { wanted: [], answered: 0 } });
  return SR;
}

const pool = (n, difficulty = 1) =>
  Array.from({ length: n }, (_, i) => ({ id: `q${i}`, difficulty }));

// Plays like combat: select (never the last one), then answer and tick once
function play(SR, questions, answerFor, turns) {
  let last = null;
  const log = [];
  for (let i = 0; i < turns; i++) {
    const { question, isWanted } = SR.selectNext(questions, { tier: 1, excludeId: last });
    const right = answerFor(question, isWanted, log);
    SR.tick();
    if (right) SR.clear(question.id); else SR.flag(question.id, 's');
    log.push({ id: question.id, isWanted, right });
    last = question.id;
  }
  return log;
}

test('wrong → returns after 3–5 other questions, as WANTED → right → cleared', () => {
  for (let seed = 0; seed < 200; seed++) {
    const SR = freshSR();
    const questions = pool(8);
    const log = play(SR, questions, () => false, 1);
    const target = log[0].id;
    assert.ok(SR.isWanted(target));

    // Answer everything else right until the target comes back
    const after = play(SR, questions, () => true, 6);
    const back = after.findIndex(e => e.id === target);
    assert.ok(back >= 3 && back <= 5, `came back after ${back} others`);
    assert.equal(after[back].isWanted, true, 'shown as WANTED (BOUNTY badge)');
    // Not shown early: the others before it weren't WANTED
    assert.ok(after.slice(0, back).every(e => !e.isWanted));
    // It was answered right on its return, so it's cleared
    assert.equal(SR.isWanted(target), false);
  }
});

test('a wrong answer on its return resets the gap', () => {
  for (let seed = 0; seed < 100; seed++) {
    const SR = freshSR();
    const questions = pool(8);
    const first = play(SR, questions, () => false, 1)[0].id;
    // Right on everything except the target, which is failed again on return
    const log = play(SR, questions, q => q.id !== first, 14);
    const returns = log.map((e, i) => (e.id === first ? i : -1)).filter(i => i >= 0);
    assert.ok(returns.length >= 2, `returned ${returns.length} times`);
    assert.ok(returns[0] >= 3 && returns[0] <= 5);
    const gap = returns[1] - returns[0] - 1;
    assert.ok(gap >= 3 && gap <= 5, `second gap ${gap}`);
    assert.ok(SR.isWanted(first));
  }
});

test('the return gap varies between 3 and 5', () => {
  const gaps = new Set();
  for (let i = 0; i < 200; i++) {
    const SR = freshSR();
    SR.tick();
    SR.flag('q', 's');
    gaps.add(SR.getAll()[0].nextAfter - 1);
  }
  assert.deepEqual([...gaps].sort(), [3, 4, 5]);
});

test('never the same question twice in a row, unless it is the only one', () => {
  const SR = freshSR();
  const two = pool(2);
  let last = null;
  for (let i = 0; i < 200; i++) {
    const { question } = SR.selectNext(two, { tier: 1, excludeId: last });
    assert.notEqual(question.id, last);
    last = question.id;
  }
  const one = pool(1);
  assert.equal(SR.selectNext(one, { tier: 1, excludeId: 'q0' }).question.id, 'q0');
});

test('a pool whose questions are all WANTED (none due) still plays', () => {
  const SR = freshSR();
  const questions = pool(3);
  questions.forEach(q => SR.flag(q.id, 's'));
  const { question, isWanted } = SR.selectNext(questions, { tier: 1 });
  assert.ok(question);
  assert.equal(isWanted, true);
});

test('tier: matches the enemy tier, else the nearest (lower on a tie)', () => {
  const SR = freshSR();
  const mixed = [
    { id: 'd1', difficulty: 1 }, { id: 'd2', difficulty: 2 },
    { id: 'd4', difficulty: 4 }, { id: 'd5', difficulty: 5 },
  ];
  const picks = tier => new Set(Array.from({ length: 50 }, () => SR.selectNext(mixed, { tier }).question.id));
  assert.deepEqual([...picks(2)], ['d2']);
  assert.deepEqual([...picks(5)], ['d5']);
  assert.deepEqual([...picks(3)], ['d2']);   // 2 and 4 are equally near: the lower one
  // The just-asked question is skipped before the tier is matched
  assert.equal(SR.selectNext(mixed, { tier: 2, excludeId: 'd2' }).question.id, 'd1');
});

test('a due WANTED question comes first, even from another tier', () => {
  const SR = freshSR();
  const mixed = [{ id: 'easy', difficulty: 1 }, { id: 'hard', difficulty: 3 }];
  SR.tick();
  SR.flag('hard', 's');
  for (let i = 0; i < 5; i++) SR.tick();
  const pick = SR.selectNext(mixed, { tier: 1 });
  assert.equal(pick.question.id, 'hard');
  assert.equal(pick.isWanted, true);
});
