// Every question in the five packs as the player sees it, plus the flows that
// depend on them: a Dry Flats fight, a boss question part by part, and a
// WANTED question coming back. Answers are given by tapping.
import { test, expect } from '@playwright/test';
import { startServer } from './server.mjs';
import {
  blockRemote, seedRandom, trackPageErrors, createProfile, openIsland, startNode,
  currentQuestion, answer, answerPart, waitForNext,
} from './helpers.mjs';

test.use({ serviceWorkers: 'block' });

let server;
test.beforeAll(async () => { server = await startServer(); });
test.afterAll(async () => { await server?.close(); });

test.beforeEach(async ({ context }) => {
  await blockRemote(context, server.origin);
  await seedRandom(context);
});

const SHOTS = 'test-results/screenshots';

// Shows maths as KaTeX, with no raw TeX, leaked code or broken numbers
async function expectCleanText(locator, what) {
  const { text, outsideMaths, katexErrors } = await locator.evaluate(el => {
    const copy = el.cloneNode(true);
    copy.querySelectorAll('.katex').forEach(k => k.remove());
    return {
      text: el.textContent,
      outsideMaths: copy.textContent,
      katexErrors: el.querySelectorAll('.katex-error').length,
    };
  });
  expect(text.trim(), `${what}: has text`).not.toBe('');
  expect(text, `${what}: no leaked code or broken values`).not.toMatch(/object Object|=>|\bNaN\b|\bundefined\b/);
  expect(outsideMaths, `${what}: no TeX outside maths`).not.toMatch(/[$\\]/);
  expect(katexErrors, `${what}: KaTeX errors`).toBe(0);
}

async function expectAllVisible(locator, count, what) {
  await expect(locator, what).toHaveCount(count);
  for (let i = 0; i < count; i++) await expect(locator.nth(i), what).toBeVisible();
}

test('every question in the five packs shows working answer controls', async ({ page }) => {
  test.setTimeout(240_000);
  const pageErrors = trackPageErrors(page);
  await page.goto(server.url);
  await createProfile(page);

  // A fight to host the questions. Each entry is then shown in turn, with the
  // clock stopped so nothing times out while it's checked.
  await page.evaluate(() => Combat.start({ mode: 'endurance', topicIds: WA.packs.map(p => p.id) }));
  await expect(page.locator('#screen-combat')).toBeVisible();

  const entries = await page.evaluate(() => WA.library.map(q => ({ id: q.id, type: q.type, pack: q._packId })));
  const perPack = entries.reduce((m, e) => ({ ...m, [e.pack]: (m[e.pack] || 0) + 1 }), {});
  expect(Object.keys(perPack)).toHaveLength(5);
  expect(entries.length).toBeGreaterThanOrEqual(84);

  const shown = { mcq: 0, value: 0, multipart: 0 };
  for (const entry of entries) {
    // Generated questions differ on every expansion: check several
    const runs = entry.type === 'parametric' ? 5 : 1;
    for (let run = 0; run < runs; run++) {
      const q = await page.evaluate(id => {
        const q = Combat._instantiate(WA.library.find(e => e.id === id));
        if (!q) return null;
        q._isWanted = false;
        Combat._run._currentQuestion = q;
        Combat._run._answered = false;
        Combat._renderQuestion(q);
        Combat._stopTimer();
        return {
          id: q.id, type: q.type, difficulty: q.difficulty,
          parts: q.parts?.map(p => ({ type: p.type, correctIndex: p.correctIndex, answer: p.answer })),
        };
      }, entry.id);
      const what = `${entry.id} (${entry.type})`;
      expect(q, `${what} expands`).not.toBeNull();
      expect(q.id, `${what} keeps its id`).toBe(entry.id);

      await expect(page.locator('#question-diff-badge')).toHaveText(new RegExp(`^D${q.difficulty} · `));
      await expectCleanText(page.locator('#question-text'), what);

      if (q.type === 'mcq') {
        await expect(page.locator('#mcq-area')).toBeVisible();
        await expectAllVisible(page.locator('#mcq-area .mcq-btn:not([disabled])'), 4, `${what} options`);
        await expectCleanText(page.locator('#mcq-area'), `${what} options`);
        shown.mcq++;
      } else if (q.type === 'value') {
        await expect(page.locator('#value-area')).toBeVisible();
        await expectAllVisible(page.locator('#value-area .numpad-key'), 16, `${what} numpad`);
        await expect(page.locator('#value-area .numpad-submit')).toBeVisible();
        shown.value++;
      } else {
        // Multi-part and boss: every part, one at a time
        expect(['multipart', 'boss'], what).toContain(q.type);
        await expect(page.locator('#multipart-area')).toBeVisible();
        for (let i = 0; i < q.parts.length; i++) {
          const part = q.parts[i];
          const label = `Part (${String.fromCharCode(97 + i)}) of ${q.parts.length}`;
          await expect(page.locator('#multipart-area .multipart-part-label')).toHaveText(new RegExp(label.replace(/[()]/g, '\\$&'), 'i'));
          await expectCleanText(page.locator('#mp-question-text'), `${what} part ${i}`);
          await expect(page.locator('#multipart-area .multipart-done-item')).toHaveCount(i);
          if (part.type === 'mcq') {
            await expectAllVisible(page.locator('#mp-answer-area .mcq-btn'), 4, `${what} part ${i} options`);
            await expectCleanText(page.locator('#mp-answer-area'), `${what} part ${i} options`);
          } else {
            await expect(page.locator('#mp-numpad-display')).toBeVisible();
            await expectAllVisible(page.locator('#mp-answer-area .numpad-key'), 14, `${what} part ${i} numpad`);
          }
          await expect(page.locator('#multipart-area .multipart-nav .btn')).toBeVisible();
          // Answer it (not the last part: that would end the question)
          if (i < q.parts.length - 1) {
            await answerPart(page, part, true);
            await page.evaluate(() => Combat._stopTimer());
          }
        }
        shown.multipart++;
      }
    }
  }

  // 1 multipart + 4 bosses; every generated template expanded 5 times
  expect(shown.multipart).toBe(5);
  expect(shown.mcq + shown.value + shown.multipart).toBe(entries.length + 4 * entries.filter(e => e.type === 'parametric').length);
  pageErrors.expectNone();
});

test('Dry Flats fight at 390×844: generated questions, at the enemy tier, node cleared', async ({ page }) => {
  const pageErrors = trackPageErrors(page);
  await page.goto(server.url);
  await createProfile(page);
  await openIsland(page, 'Dry Flats');
  await startNode(page, 'Right-Angle Trigonometry');

  // The node's pool, to check the tier rule against
  const pool = await page.evaluate(() =>
    WA.getQuestionsForSubtopic('sl3-2-right-trig').map(q => ({ id: q.id, difficulty: q.difficulty })));
  expect(pool.length).toBeGreaterThan(0);

  let shot = false;
  let last = null;
  let wrongAnswers = 0;
  for (let turn = 0; turn < 20; turn++) {
    if (await page.locator('#screen-debrief').isVisible()) break;
    const q = await currentQuestion(page);
    expect(q, 'a question is showing').not.toBeNull();
    await expect(page.locator(q.type === 'mcq' ? '#mcq-area' : '#value-area')).toBeVisible();
    await expect(page.locator('#question-text')).not.toHaveText(/object Object|=>|NaN/);
    // The badge shows the question's real tier
    await expect(page.locator('#question-diff-badge')).toHaveText(new RegExp(`^D${q.difficulty} · `));
    // Never the same question twice in a row
    expect(q.id).not.toBe(last);
    // Tier: the nearest the pool has to the enemy's. A WANTED question that's
    // due comes first whatever its tier; one that isn't due waits its turn.
    if (!q.isWanted) {
      const wanted = await page.evaluate(() => SR.getAll().map(w => w.id));
      const choices = pool.filter(p => p.id !== last);
      const fresh = choices.filter(p => !wanted.includes(p.id));
      const best = Math.min(...(fresh.length ? fresh : choices).map(p => Math.abs(p.difficulty - q.enemyTier)));
      expect(Math.abs(q.difficulty - q.enemyTier), `${q.id} vs enemy D${q.enemyTier}`).toBe(best);
    }
    if (!shot) {
      await page.screenshot({ path: `${SHOTS}/05-dry-flats-fight-390x844.png` });
      shot = true;
    }
    const right = turn !== 1;
    await answer(page, q, right);
    await expect(page.locator('#outcome-msg')).toHaveText(right ? /CORRECT!|SLOW RESPONSE/ : 'WRONG');
    if (!right) wrongAnswers++;
    last = q.id;
    await waitForNext(page);
  }
  expect(wrongAnswers).toBe(1);
  await expect(page.locator('#screen-debrief')).toBeVisible();
  pageErrors.expectNone();
});

test('boss question: stem, then each part with its own numpad, totals at the end', async ({ page }) => {
  const pageErrors = trackPageErrors(page);
  await page.goto(server.url);
  await createProfile(page);
  await openIsland(page, 'Dry Flats');
  await startNode(page, 'Boss: Dry Flats');

  const q = await currentQuestion(page);
  expect(q.type).toBe('boss');
  expect(q.parts).toHaveLength(3);
  // The boss's title and intro are the stem; the badge shows its real tier
  await expect(page.locator('#question-text .boss-title')).toHaveText('The Enforcer of the Flats');
  await expect(page.locator('#question-diff-badge')).toHaveText(/^D5 · /);
  await expect(page.locator('#multipart-area .multipart-part-label')).toHaveText(/Part \(a\) of 3/i);

  const before = await page.evaluate(() => ({
    hp: Combat._run.hp, enemyHp: Combat._run._currentEnemy.currentHp,
    enemyDmg: Combat._run._currentEnemy.dmg, scrap: WA.state.profile.scrap,
    perPart: Combat.SCRAP_REWARDS[Combat._run._currentEnemy.difficulty],
  }));

  // (a) right. Its keys type into the part's own display, not the hidden main one
  await answerPart(page, q.parts[0], true);
  await expect(page.locator('#numpad-display')).toHaveText('');

  // (b): part (a) stays on screen, marked right
  await expect(page.locator('#multipart-area .multipart-part-label')).toHaveText(/Part \(b\) of 3/i);
  await expect(page.locator('#multipart-area .multipart-done-item')).toHaveCount(1);
  await expect(page.locator('#multipart-area .multipart-done-item.part-correct')).toHaveCount(1);
  await page.locator('#question-card').evaluate(el => el.scrollIntoView());
  await page.screenshot({ path: `${SHOTS}/06a-boss-part-b-stem-390x844.png` });
  await page.locator('#mp-answer-area .numpad-key', { hasText: /^3$/ }).click();
  await page.locator('#mp-answer-area .numpad-key', { hasText: /^8$/ }).click();
  await expect(page.locator('#mp-numpad-display')).toHaveText('38');
  await page.screenshot({ path: `${SHOTS}/06b-boss-part-b-numpad-390x844.png` });
  await page.locator('#mp-answer-area .numpad-key', { hasText: '⌫' }).click();
  await page.locator('#mp-answer-area .numpad-key', { hasText: '⌫' }).click();

  // (b) right, (c) wrong
  await answerPart(page, q.parts[1], true);
  await answerPart(page, q.parts[2], false);

  // One result for the whole question: 2 of 3 parts, damage and Scrap totalled
  await expect(page.locator('#outcome-overlay')).toBeVisible();
  await expect(page.locator('#outcome-msg')).toHaveText('PARTLY RIGHT');
  await expect(page.locator('#outcome-sub')).toContainText('2/3 parts');
  await expect(page.locator('#outcome-solution')).toContainText('(c)');
  const after = await page.evaluate(() => ({
    hp: Combat._run?.hp, enemyHp: Combat._run?._currentEnemy.currentHp, scrap: WA.state.profile.scrap,
    wanted: SR.isWanted('sl3-boss-1'),
  }));
  expect(after.hp).toBe(before.hp - before.enemyDmg);
  expect(after.enemyHp).toBe(Math.max(0, before.enemyHp - 2));
  expect(after.scrap).toBe(before.scrap + 2 * before.perPart);
  expect(after.wanted, 'a failed part places a bounty').toBe(true);
  pageErrors.expectNone();
});

test('a missed question comes back after 3–5 others with the BOUNTY badge, and a right answer clears it', async ({ page }) => {
  test.setTimeout(120_000);
  const pageErrors = trackPageErrors(page);
  await page.goto(server.url);
  await createProfile(page);
  await page.evaluate(() => Combat.start({ mode: 'endurance', topicIds: ['topic-1-algebra'] }));
  await expect(page.locator('#screen-combat')).toBeVisible();

  const answered = () => page.evaluate(() => WA.state.spaced.answered);

  // Miss the first question
  const missed = await currentQuestion(page);
  await expect(page.locator('#question-wanted-badge')).toBeHidden();
  let count = await answered();
  await answer(page, missed, false);
  await waitForNext(page);
  expect(await answered(), 'one tick per question').toBe(count + 1);
  expect(await page.evaluate(id => SR.isWanted(id), missed.id)).toBe(true);

  // Answer the others right until it returns
  const others = [];
  for (let i = 0; i < 8; i++) {
    const q = await currentQuestion(page);
    if (q.id === missed.id) break;
    await expect(page.locator('#question-wanted-badge')).toBeHidden();
    others.push(q.id);
    count = await answered();
    await answer(page, q, true);
    await waitForNext(page);
    expect(await answered(), 'one tick per question').toBe(count + 1);
  }
  expect(others.length, `returned after ${others.length} others`).toBeGreaterThanOrEqual(3);
  expect(others.length).toBeLessThanOrEqual(5);

  const back = await currentQuestion(page);
  expect(back.id).toBe(missed.id);
  await expect(page.locator('#question-wanted-badge')).toBeVisible();
  await expect(page.locator('#question-wanted-badge')).toHaveText(/BOUNTY/);
  await page.screenshot({ path: `${SHOTS}/07-bounty-returns-390x844.png` });

  await answer(page, back, true);
  await waitForNext(page);
  expect(await page.evaluate(id => SR.isWanted(id), missed.id), 'cleared by a right answer').toBe(false);
  pageErrors.expectNone();
});
