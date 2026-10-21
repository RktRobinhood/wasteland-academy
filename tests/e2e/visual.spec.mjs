// Every screen on the real art in assets/, at both phone sizes: each image at
// its display size, every control on screen, and a screenshot of each step
// (test-results/screenshots/visual-*) for the visual review.
import { test, expect } from '@playwright/test';
import { startServer } from './server.mjs';
import {
  routeCdn, seedRandom, trackPageErrors, createProfile, openIsland, openThunderdome, startNode,
  currentQuestion, answer, waitForNext,
} from './helpers.mjs';

test.use({ serviceWorkers: 'block' });

let server;
test.beforeAll(async () => { server = await startServer(); });
test.afterAll(async () => { await server?.close(); });

test.beforeEach(async ({ context }) => {
  await routeCdn(context);
  await seedRandom(context);
});

const SHOTS = 'test-results/screenshots';

// The image has loaded and is drawn at `size` × `size` CSS px
async function expectShownAt(img, size, what) {
  await expect(img, what).toBeVisible();
  await expect.poll(() => img.evaluate(e => e.complete && e.naturalWidth > 0), what).toBe(true);
  const box = await img.boundingBox();
  expect([Math.round(box.width), Math.round(box.height)], what).toEqual([size, size]);
}

// Every visible button on the current screen is inside the viewport. The
// question area scrolls by design, so only its SUBMIT (sticky) has to be.
async function expectControlsOnScreen(page, screen) {
  const vp = page.viewportSize();
  const off = await page.locator(`${screen} button`).evaluateAll((els, vp) => els
    .filter(e => e.checkVisibility() && (!e.closest('.question-card-wrap') || e.matches('.numpad-submit')))
    .map(e => ({ e, r: e.getBoundingClientRect() }))
    .filter(({ r }) => r.left < -0.5 || r.top < -0.5 || r.right > vp.width + 0.5 || r.bottom > vp.height + 0.5)
    .map(({ e }) => e.id || e.className || e.textContent.trim()), vp);
  expect(off, `${screen}: buttons off screen`).toEqual([]);
}

for (const [width, height] of [[390, 844], [375, 667]]) {
  test.describe(`${width}×${height}`, () => {
    test.use({ viewport: { width, height } });
    const short = height <= 740;  // css/combat.css: short screens shrink the enemy
    const shot = async (page, name) => {
      await page.evaluate(() => document.fonts.ready);
      await page.screenshot({ path: `${SHOTS}/visual-${width}x${height}-${name}.png` });
    };

    test('profile, world, island, Thunderdome set-up, stats, bazaar', async ({ page }) => {
      const pageErrors = trackPageErrors(page);
      await page.goto(server.url);
      await expect(page.locator('#screen-profile')).toBeVisible();
      for (const av of ['female', 'male', 'spark']) {
        await expectShownAt(page.locator(`.avatar-choice[data-avatar="${av}"] img`), 72, `${av} avatar`);
      }
      await page.fill('#profile-name', 'VIPER');
      await page.click('.avatar-choice[data-avatar="female"]');
      await expectControlsOnScreen(page, '#screen-profile');
      await shot(page, '01-profile');

      await page.click('#screen-profile .btn-primary');
      await expect(page.locator('#world-map-art')).toBeVisible();
      await expectShownAt(page.locator('#world-player-avatar'), 36, 'map avatar');
      await expectControlsOnScreen(page, '#screen-world');
      await shot(page, '02-world');

      await openIsland(page, 'Scrap Fields');
      await expectControlsOnScreen(page, '#screen-island .island-header');
      await shot(page, '03-island');
      await page.click('#screen-island .back-btn');

      await openThunderdome(page);
      await shot(page, '04-thunderdome-setup');
      await page.click('#screen-td-config .back-btn');

      await page.evaluate(() => {
        SR.flag('sl1-1-a', 'sl1-1-standard-form');
        SR.flag('sl1-2-a', 'sl1-2-arithmetic');
      });
      await page.click('.world-footer .btn:has-text("STATS")');
      await expect(page.locator('#stats-wanted .wanted-badge-img').first()).toBeVisible();
      await shot(page, '05-stats');
      await page.click('#screen-stats .back-btn');

      await page.click('.world-footer .btn:has-text("BAZAAR")');
      await expect(page.locator('#bazaar-grid .bazaar-item')).toHaveCount(4);
      await shot(page, '06-bazaar');
      pageErrors.expectNone();
    });

    test('island fight: enemy, lifelines, hint, outcomes, debrief', async ({ page }) => {
      const pageErrors = trackPageErrors(page);
      await page.goto(server.url);
      await createProfile(page);
      await openIsland(page, 'Scrap Fields');
      await startNode(page, 'Standard Form');
      await page.evaluate(() => Combat._stopTimer());

      await expectShownAt(page.locator('#enemy-sprite'), short ? 56 : 96, 'enemy');
      for (const ll of ['fifty', 'freeze', 'hint']) {
        await expectShownAt(page.locator(`#lifeline-${ll} .lifeline-img`), 28, `${ll} lifeline`);
      }
      await expectControlsOnScreen(page, '#screen-combat');
      await shot(page, '07-fight');

      await page.click('#lifeline-hint');
      await expectShownAt(page.locator('#hint-spark'), 48, 'hint Spark');
      await shot(page, '08-hint');
      await page.click('#hint-modal .btn');

      let q = await currentQuestion(page);
      await answer(page, q, true);
      await expect(page.locator('#outcome-msg')).toHaveText('CORRECT!');
      await expectShownAt(page.locator('#outcome-spark'), 64, 'outcome Spark');
      await shot(page, '09-outcome-correct');
      await waitForNext(page);

      q = await currentQuestion(page);
      await answer(page, q, false);
      await expect(page.locator('#outcome-msg')).toHaveText('WRONG');
      await expectShownAt(page.locator('#outcome-spark'), 64, 'outcome Spark');
      await shot(page, '10-outcome-wrong');
      await waitForNext(page);

      // A value question, with the numpad
      for (let i = 0; i < 20 && q?.type !== 'value'; i++) {
        if (await page.locator('#screen-debrief').isVisible()) break;
        q = await currentQuestion(page);
        if (q.type === 'value') break;
        await answer(page, q, true);
        await waitForNext(page);
      }
      if (q?.type === 'value' && await page.locator('#value-area').isVisible()) {
        await page.evaluate(() => Combat._stopTimer());
        await expectControlsOnScreen(page, '#screen-combat');
        await shot(page, '11-fight-value');
      }

      await page.evaluate(() => Router.go('debrief', { score: 120, mode: 'island', runHistory: [] }));
      await expect(page.locator('#screen-debrief')).toBeVisible();
      await shot(page, '12-debrief');
      pageErrors.expectNone();
    });

    test('Thunderdome fight on the arena', async ({ page }) => {
      const pageErrors = trackPageErrors(page);
      await page.goto(server.url);
      await createProfile(page);
      await openThunderdome(page);
      await page.click('#screen-td-config .btn-primary');
      await expect(page.locator('#screen-combat')).toBeVisible();
      await page.evaluate(() => Combat._stopTimer());
      await expect(page.locator('#arena-bg')).toBeVisible();
      await expectShownAt(page.locator('#enemy-sprite'), short ? 56 : 96, 'enemy');
      await expectControlsOnScreen(page, '#screen-combat');
      await shot(page, '13-thunderdome-fight');
      pageErrors.expectNone();
    });
  });
}
