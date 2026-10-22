// A full island fight on a phone-sized screen, played by tapping, plus a
// layout check on a small phone. Fails on any uncaught page error.
// 404s for art that hasn't been delivered yet are expected and ignored.
import { test, expect } from '@playwright/test';
import { startServer } from './server.mjs';
import {
  blockRemote, seedRandom, trackPageErrors, createProfile, openIsland, startNode,
  currentQuestion, answer, waitForNext,
} from './helpers.mjs';

// Service workers are covered by service-worker.spec.mjs. Here they'd only add
// caching between steps, and Playwright can't route requests a worker handles.
test.use({ serviceWorkers: 'block' });

let server;
test.beforeAll(async () => { server = await startServer(); });
test.afterAll(async () => { await server?.close(); });

test.beforeEach(async ({ context }) => {
  await blockRemote(context, server.origin);
  await seedRandom(context);
});

const SHOTS = 'test-results/screenshots';

test('Scrap Fields fight at 390×844: first launch → node cleared → debrief → map', async ({ page }) => {
  const pageErrors = trackPageErrors(page);

  await page.goto(server.url);
  await createProfile(page);
  await openIsland(page, 'Scrap Fields');
  await startNode(page, 'Standard Form');

  // The question renders as text with answer controls, not "[object Object]"
  await expect(page.locator('#question-text')).not.toHaveText(/object Object|^\s*$/);
  await expect(page.locator('#question-diff-badge')).toHaveText(/^D[1-5] · \w+/);
  await page.screenshot({ path: `${SHOTS}/01-question-390x844.png` });

  const used = { fifty: false, freeze: false, hint: false };
  let rightAnswers = 0;
  let wrongAnswers = 0;
  let afterAnswerShot = false;

  for (let turn = 0; turn < 20; turn++) {
    if (await page.locator('#screen-debrief').isVisible()) break;
    const q = await currentQuestion(page);
    expect(q, 'a question is showing').not.toBeNull();
    await expect(page.locator(q.type === 'mcq' ? '#mcq-area' : '#value-area')).toBeVisible();

    // Lifelines, each once
    if (!used.freeze) {
      await page.click('#lifeline-freeze');
      const t0 = await page.locator('#timer-text').textContent();
      await page.waitForTimeout(2200);
      await expect(page.locator('#timer-text'), 'timer holds while frozen').toHaveText(t0);
      await expect(page.locator('#lifeline-freeze')).toBeDisabled();
      used.freeze = true;
    }
    if (!used.hint) {
      await page.click('#lifeline-hint');
      await expect(page.locator('#hint-modal')).toBeVisible();
      await expect(page.locator('#hint-text')).not.toBeEmpty();
      await page.click('#hint-modal .btn');
      await expect(page.locator('#hint-modal')).toBeHidden();
      await expect(page.locator('#lifeline-hint')).toBeDisabled();
      used.hint = true;
    }
    if (!used.fifty && q.type === 'mcq') {
      await page.click('#lifeline-fifty');
      await expect(page.locator('#mcq-area .mcq-btn.eliminated')).toHaveCount(2);
      await expect(page.locator(`#mcq-area .mcq-btn[data-idx="${q.correctIndex}"]`)).toBeEnabled();
      await expect(page.locator('#lifeline-fifty')).toBeDisabled();
      used.fifty = true;
    }

    // One wrong answer after the first right one; right answers otherwise
    const right = !(rightAnswers === 1 && wrongAnswers === 0);
    const hpBefore = await page.locator('#hp-player-text').textContent();
    await answer(page, q, right);
    await expect(page.locator('#outcome-msg')).toHaveText(right ? 'CORRECT!' : 'WRONG');
    if (!right) {
      await expect(page.locator('#hp-player-text')).not.toHaveText(hpBefore);
      await expect(page.locator('#outcome-solution')).toBeVisible();
    }
    if (!afterAnswerShot) {
      await page.screenshot({ path: `${SHOTS}/02-after-answer-390x844.png` });
      afterAnswerShot = true;
    }
    right ? rightAnswers++ : wrongAnswers++;
    await waitForNext(page);
  }

  expect(used, 'every lifeline was used').toEqual({ fifty: true, freeze: true, hint: true });
  expect(wrongAnswers).toBe(1);

  // Node cleared → debrief
  await expect(page.locator('#screen-debrief')).toBeVisible();
  await expect(page.locator('#debrief-mode')).toHaveText('ISLAND');
  await expect(page.locator('#debrief-score')).not.toHaveText('0');
  await page.screenshot({ path: `${SHOTS}/03-debrief-390x844.png` });

  // Back to the map, and the node shows as cleared
  await page.click('#screen-debrief .btn-ghost');
  await expect(page.locator('#screen-world')).toBeVisible();
  await openIsland(page, 'Scrap Fields');
  await expect(page.locator('#island-nodes .node-btn', { hasText: 'Standard Form' })).toHaveClass(/node-cleared/);

  pageErrors.expectNone();
});

test.describe('small phone', () => {
  test.use({ viewport: { width: 375, height: 667 } });

  test('375×667: SUBMIT and lifelines are on screen on a value question', async ({ page }) => {
    const pageErrors = trackPageErrors(page);
    await page.goto(server.url);
    await createProfile(page);
    await openIsland(page, 'Scrap Fields');
    await startNode(page, 'Arithmetic Sequences');

    // Answer right until a value question comes up (restarting the node if it's cleared)
    let q = await currentQuestion(page);
    for (let i = 0; i < 20 && q?.type !== 'value'; i++) {
      await answer(page, q, true);
      await waitForNext(page);
      if (await page.locator('#screen-debrief').isVisible()) {
        await page.click('#screen-debrief .btn-ghost');
        await openIsland(page, 'Scrap Fields');
        await startNode(page, 'Arithmetic Sequences');
      }
      q = await currentQuestion(page);
    }
    expect(q?.type).toBe('value');
    await expect(page.locator('#value-area')).toBeVisible();
    await page.screenshot({ path: `${SHOTS}/04-value-question-375x667.png` });

    // Fully inside the viewport, without scrolling, and not covered by anything
    const vp = page.viewportSize();
    for (const sel of ['#value-area .numpad-submit', '#lifeline-fifty', '#lifeline-freeze', '#lifeline-hint']) {
      const box = await page.locator(sel).boundingBox();
      expect(box, `${sel} is rendered`).not.toBeNull();
      expect(box.y, `${sel} top`).toBeGreaterThanOrEqual(0);
      expect(box.y + box.height, `${sel} bottom`).toBeLessThanOrEqual(vp.height);
      expect(box.x + box.width, `${sel} right`).toBeLessThanOrEqual(vp.width);
      // Nothing covers it. (A disabled lifeline has pointer-events:none, so the
      // point then hits its parent row, which is fine.)
      const uncovered = await page.evaluate(([s, x, y]) => {
        const el = document.elementFromPoint(x, y);
        return !!el && (!!el.closest(s) || el.contains(document.querySelector(s)));
      }, [sel, box.x + box.width / 2, box.y + box.height / 2]);
      expect(uncovered, `${sel} is not covered`).toBe(true);
    }

    // And it's actually usable: a right answer lands
    await answer(page, q, true);
    await expect(page.locator('#outcome-msg')).toHaveText('CORRECT!');
    pageErrors.expectNone();
  });
});

test('layout: screen fills the viewport up to 600px, then is centred', async ({ page }) => {
  await page.setViewportSize({ width: 1024, height: 768 });
  await page.goto(server.url);
  await expect(page.locator('#screen-profile')).toBeVisible();
  const box = await page.locator('#screen-profile').boundingBox();
  expect(box.width).toBe(600);
  expect(box.x).toBe((1024 - 600) / 2);
  expect(box.height).toBe(768);

  await page.setViewportSize({ width: 390, height: 844 });
  const phone = await page.locator('#screen-profile').boundingBox();
  expect(phone).toEqual({ x: 0, y: 0, width: 390, height: 844 });
});
