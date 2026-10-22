// Every art hook, on each screen, twice: once with the art files missing and
// once with stand-ins served at the exact sizes (tests/e2e/standins.mjs). With
// the art served the image shows; with it missing the fallback shows, as it
// did before the art existed. The art is routed in the browser, so what's in
// assets/ on disk doesn't matter.
import { test, expect } from '@playwright/test';
import { startServer, BASE_PATH } from './server.mjs';
import { standin, STANDIN_SIZES } from './standins.mjs';
import {
  blockRemote, seedRandom, trackPageErrors, createProfile, openIsland, openThunderdome, startNode,
  currentQuestion, answer, waitForNext,
} from './helpers.mjs';

test.use({ serviceWorkers: 'block' });

let server;
test.beforeAll(async () => { server = await startServer(); });
test.afterAll(async () => { await server?.close(); });

const SHOTS = 'test-results/screenshots';
const ASSETS = BASE_PATH + 'assets/';

// Answers every request under assets/: a stand-in when `art.mode` is
// 'served', a 404 when it's 'missing'. Routing also turns off the HTTP cache,
// so switching the mode mid-test takes effect on the next request.
// Files in `art.missing` 404 whatever the mode.
async function routeArt(context, mode) {
  const art = { mode, missing: new Set(), requested: new Set(), unknown: new Set() };
  await context.route(url => url.pathname.startsWith(ASSETS), route => {
    const rel = new URL(route.request().url()).pathname.slice(ASSETS.length);
    art.requested.add(rel);
    const body = art.mode === 'served' && !art.missing.has(rel) ? standin(rel) : null;
    if (art.mode === 'served' && !art.missing.has(rel) && !body) art.unknown.add(rel);
    return body
      ? route.fulfill({ status: 200, contentType: 'image/png', body })
      : route.fulfill({ status: 404, contentType: 'text/plain', body: 'not found' });
  });
  return art;
}

// The image shows at its full size (served), or the fallback does (missing)
async function expectArt(mode, img, file, fallback = null) {
  if (mode === 'served') {
    await expect(img, file).toBeVisible();
    expect(await img.getAttribute('src'), file).toBe(`assets/${file}`);
    await expect.poll(() => img.evaluate(e => [e.naturalWidth, e.naturalHeight]), file)
      .toEqual(STANDIN_SIZES[file]);
    if (fallback) await expect(fallback, `${file} fallback`).toBeHidden();
  } else {
    await expect(img, file).toBeHidden();
    if (fallback) await expect(fallback, `${file} fallback`).toBeVisible();
  }
}

// CSS-drawn art (border-image) is in use when served, and absent when missing
async function expectFrame(mode, el, file) {
  await expect.poll(() => el.evaluate(e => getComputedStyle(e).borderImageSource), file)
    .toMatch(mode === 'served' ? new RegExp(`assets/${file}`) : /^none$/);
}

// No image without a file to show, and no inline handlers left over
async function expectCleanImages(page) {
  expect(await page.locator('img[src=""]').count(), 'images with an empty src').toBe(0);
  expect(await page.locator('img[onerror]').count(), 'inline onerror handlers').toBe(0);
  const visibleWithoutSrc = await page.locator('img:not([src])').evaluateAll(
    els => els.filter(e => e.checkVisibility()).length);
  expect(visibleWithoutSrc, 'visible images with no src').toBe(0);
}

const ISLANDS = {
  'Scrap Fields': 'scrap-fields', 'Signal Tower': 'signal-tower', 'Dry Flats': 'dry-flats',
  'Radio Spires': 'radio-spires', 'Engine Core': 'engine-core',
};
const ISLAND_NAMES = Object.keys(ISLANDS);

// The world screen's card grid (no overworld art): each card's art or icon
async function expectWorldGrid(mode, page) {
  for (const [name, file] of Object.entries(ISLANDS)) {
    const card = page.locator('#world-islands .island-node', { hasText: name });
    await expectArt(mode, card.locator('.island-art'), `map/island-${file}.png`, card.locator('.island-icon'));
    await expect(card.locator('.island-name')).toBeVisible();
  }
  await expectArt(mode, page.locator('.thunderdome-btn .thunderdome-art'), 'map/thunderdome.png');
  await expect(page.locator('.thunderdome-name')).toBeVisible();
  // The taller island cards don't squash the button and clip its text
  const [btnBox, subBox] = await Promise.all(
    ['.thunderdome-btn', '.thunderdome-sub'].map(s => page.locator(s).boundingBox()));
  expect(subBox.y + subBox.height, 'Thunderdome subtitle inside its button').toBeLessThanOrEqual(btnBox.y + btnBox.height);
}

for (const mode of ['missing', 'served']) {
  test.describe(`art ${mode}`, () => {
    let art;
    test.beforeEach(async ({ context }) => {
      await blockRemote(context, server.origin);
      await seedRandom(context);
      art = await routeArt(context, mode);
    });
    // Every file the game asked for has a stand-in, so the hook names match the art names
    test.afterEach(() => {
      expect([...art.unknown], 'art requested that has no stand-in').toEqual([]);
    });

    test('profile, world map, WANTED board and favicon', async ({ page }) => {
      const pageErrors = trackPageErrors(page);
      await page.goto(server.url);
      await expect(page.locator('#screen-profile')).toBeVisible();

      for (const av of ['female', 'male', 'spark']) {
        const img = page.locator(`.avatar-choice[data-avatar="${av}"] img`);
        await expectArt(mode, img, `avatars/avatar-${av}.png`, page.locator(`.avatar-choice[data-avatar="${av}"] .avatar-placeholder`));
      }
      await expectCleanImages(page);
      await page.screenshot({ path: `${SHOTS}/art-${mode}-01-profile.png` });

      await createProfile(page);
      await expectArt(mode, page.locator('#world-player-avatar'), 'avatars/avatar-male.png');
      // The overworld when it's there, and the card grid when it isn't
      await expectArt(mode, page.locator('#world-map-art'), 'map/overworld.png', page.locator('#world-grid'));
      if (mode === 'served') {
        await expect(page.locator('#world-zones .zone')).toHaveCount(6);
        for (const name of ISLAND_NAMES) await expect(page.locator('#world-zones .zone', { hasText: name })).toBeVisible();
      } else {
        await expectWorldGrid(mode, page);
      }
      await expectCleanImages(page);
      await page.screenshot({ path: `${SHOTS}/art-${mode}-02-world.png` });

      // The tab icon
      const favicon = page.locator('link[rel="icon"]');
      await expect(favicon).toHaveAttribute('href', 'assets/icons/favicon-32.png');
      const size = await page.evaluate(href => new Promise(r => {
        const i = new Image();
        i.onload = () => r([i.naturalWidth, i.naturalHeight]);
        i.onerror = () => r(null);
        i.src = href;
      }), 'assets/icons/favicon-32.png');
      expect(size).toEqual(mode === 'served' ? [32, 32] : null);

      // The WANTED board: one badge per bounty
      await page.evaluate(() => {
        SR.flag('sl1-1-a', 'sl1-1-standard-form');
        SR.flag('sl1-2-a', 'sl1-2-arithmetic');
      });
      await page.click('.world-footer .btn:has-text("STATS")');
      await expect(page.locator('#stats-wanted .wanted-item')).toHaveCount(2);
      for (const item of await page.locator('#stats-wanted .wanted-item').all()) {
        await expectArt(mode, item.locator('.wanted-badge-img'), 'ui/wanted-badge.png', item.locator('.badge-rust'));
      }
      await page.locator('#stats-wanted').scrollIntoViewIfNeeded();
      await page.screenshot({ path: `${SHOTS}/art-${mode}-03-stats-wanted.png` });

      // The debrief's board, too
      await page.evaluate(() => Router.go('debrief', { score: 40, mode: 'island', runHistory: [] }));
      await expect(page.locator('#debrief-wanted .wanted-item')).toHaveCount(2);
      for (const item of await page.locator('#debrief-wanted .wanted-item').all()) {
        await expectArt(mode, item.locator('.wanted-badge-img'), 'ui/wanted-badge.png', item.locator('.badge-rust'));
      }
      await page.screenshot({ path: `${SHOTS}/art-${mode}-04-debrief-wanted.png` });
      pageErrors.expectNone();
    });

    test('island fight: enemy, frames, lifelines, Spark, BOUNTY', async ({ page }) => {
      const pageErrors = trackPageErrors(page);
      await page.goto(server.url);
      await createProfile(page);
      await openIsland(page, 'Scrap Fields');
      await startNode(page, 'Standard Form');

      const enemyFile = 'enemies/' + await page.evaluate(() => Combat._run._currentEnemy.img);
      await expectArt(mode, page.locator('#enemy-sprite'), enemyFile, page.locator('#enemy-sprite-fallback'));
      // No arena in an island fight
      await expect(page.locator('#arena-bg')).toBeHidden();
      expect(art.requested.has('map/arena-bg.png')).toBe(false);

      await expectFrame(mode, page.locator('#question-card'), 'ui/question-card.png');
      await expectFrame(mode, page.locator('.hp-block.player .hp-track'), 'ui/hp-frame-player.png');
      await expectFrame(mode, page.locator('.hp-block.enemy .hp-track'), 'ui/hp-frame-enemy.png');
      if (mode === 'served') {
        // Half size: 24 px tall, with the fill in the 10 px window (y 14–34 of 48)
        for (const side of ['player', 'enemy']) {
          const box = await page.locator(`.hp-block.${side} .hp-track`).evaluate(e => {
            const s = getComputedStyle(e);
            return { height: e.offsetHeight, inner: e.clientHeight, top: s.borderTopWidth, left: s.borderLeftWidth };
          });
          expect(box, side).toEqual({ height: 24, inner: 10, top: '7px', left: '12px' });
        }
      }

      for (const ll of ['fifty', 'freeze', 'hint']) {
        await expectArt(mode, page.locator(`#lifeline-${ll} .lifeline-img`), `ui/lifeline-${ll}-on.png`,
          page.locator(`#lifeline-${ll} .lifeline-icon-fallback`));
      }
      await page.evaluate(() => Combat._stopTimer());
      await page.screenshot({ path: `${SHOTS}/art-${mode}-05-fight.png` });

      // Hint: Spark is always thinking, whatever mood the question names
      await page.evaluate(() => { Combat._run._currentQuestion.spark_mood = 'happy'; });
      await page.click('#lifeline-hint');
      await expect(page.locator('#hint-modal')).toBeVisible();
      await expectArt(mode, page.locator('#hint-spark'), 'avatars/spark-thinking.png', page.locator('.hint-spark-placeholder'));
      await page.screenshot({ path: `${SHOTS}/art-${mode}-06-hint.png` });
      await page.click('#hint-modal .btn');

      // A used lifeline swaps to its -off icon; freeze too
      await page.click('#lifeline-freeze');
      for (const ll of ['hint', 'freeze']) {
        await expect(page.locator(`#lifeline-${ll}`)).toBeDisabled();
        await expectArt(mode, page.locator(`#lifeline-${ll} .lifeline-img`), `ui/lifeline-${ll}-off.png`,
          page.locator(`#lifeline-${ll} .lifeline-icon-fallback`));
      }
      await expectArt(mode, page.locator('#lifeline-fifty .lifeline-img'), 'ui/lifeline-fifty-on.png',
        page.locator('#lifeline-fifty .lifeline-icon-fallback'));

      // A WANTED question carries the BOUNTY marker
      await page.evaluate(() => Combat._renderQuestion({ ...Combat._run._currentQuestion, _isWanted: true }));
      await expect(page.locator('#question-wanted-badge')).toBeVisible();
      await expectArt(mode, page.locator('#question-wanted-badge .wanted-badge-img'), 'ui/wanted-badge.png',
        page.locator('#question-wanted-badge .wanted-badge-inline'));
      await page.screenshot({ path: `${SHOTS}/art-${mode}-07-lifelines-off-bounty.png` });

      // Outcomes: happy when right, sarcastic when wrong, surprised when late or out of time
      const sparkImg = page.locator('#outcome-spark');
      const sparkFallback = page.locator('#outcome-spark-fallback');
      let q = await currentQuestion(page);
      await answer(page, q, true);
      await expect(page.locator('#outcome-msg')).toHaveText('CORRECT!');
      await expectArt(mode, sparkImg, 'avatars/spark-happy.png', sparkFallback);
      await page.screenshot({ path: `${SHOTS}/art-${mode}-08-outcome-correct.png` });
      await waitForNext(page);

      q = await currentQuestion(page);
      await answer(page, q, false);
      await expect(page.locator('#outcome-msg')).toHaveText('WRONG');
      await expectArt(mode, sparkImg, 'avatars/spark-sarcastic.png', sparkFallback);
      await page.screenshot({ path: `${SHOTS}/art-${mode}-09-outcome-wrong.png` });
      await waitForNext(page);

      for (const type of ['complication', 'timeout']) {
        await page.evaluate(t => Combat._showOutcome(t, Combat._run._currentQuestion, 10, 0), type);
        await expectArt(mode, sparkImg, 'avatars/spark-surprised.png', sparkFallback);
      }
      await page.evaluate(() => Combat._hideOutcome());

      // The enemy's fill is anchored on the right, so it empties from the left
      const fill = await page.evaluate(() => {
        const track = document.querySelector('.hp-block.enemy .hp-track').getBoundingClientRect();
        const f = document.getElementById('hp-enemy-fill').getBoundingClientRect();
        const s = getComputedStyle(document.querySelector('.hp-block.enemy .hp-track'));
        return { gapRight: track.right - parseFloat(s.borderRightWidth) - f.right, width: f.width, track: track.width };
      });
      expect(fill.width).toBeLessThan(fill.track);
      expect(Math.abs(fill.gapRight)).toBeLessThan(0.5);
      await expectCleanImages(page);
      pageErrors.expectNone();
    });

    test('Thunderdome fight: the arena behind the enemy', async ({ page }) => {
      const pageErrors = trackPageErrors(page);
      await page.goto(server.url);
      await createProfile(page);
      await openThunderdome(page);
      await page.click('#screen-td-config .btn-primary');
      await expect(page.locator('#screen-combat')).toBeVisible();
      await page.evaluate(() => Combat._stopTimer());

      await expectArt(mode, page.locator('#arena-bg'), 'map/arena-bg.png');
      const enemyFile = 'enemies/' + await page.evaluate(() => Combat._run._currentEnemy.img);
      await expectArt(mode, page.locator('#enemy-sprite'), enemyFile, page.locator('#enemy-sprite-fallback'));
      if (mode === 'served') {
        // Behind the enemy, not over it
        const sprite = await page.locator('#enemy-sprite').boundingBox();
        const hit = await page.evaluate(([x, y]) => document.elementFromPoint(x, y)?.id,
          [sprite.x + sprite.width / 2, sprite.y + sprite.height / 2]);
        expect(hit).toBe('enemy-sprite');
      }
      await page.screenshot({ path: `${SHOTS}/art-${mode}-10-thunderdome.png` });
      pageErrors.expectNone();
    });
  });
}

test.describe('art served on a small phone', () => {
  test.use({ viewport: { width: 375, height: 667 } });

  test('375×667: with the frames on, SUBMIT and lifelines stay on screen', async ({ page, context }) => {
    await blockRemote(context, server.origin);
    await seedRandom(context);
    const art = await routeArt(context, 'served');
    const pageErrors = trackPageErrors(page);
    await page.goto(server.url);
    await createProfile(page);
    await openIsland(page, 'Scrap Fields');
    await startNode(page, 'Arithmetic Sequences');
    await expectFrame('served', page.locator('#question-card'), 'ui/question-card.png');

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
    await page.evaluate(() => Combat._stopTimer());
    await page.screenshot({ path: `${SHOTS}/art-served-11-value-375x667.png` });

    const vp = page.viewportSize();
    for (const sel of ['#value-area .numpad-submit', '#lifeline-fifty', '#lifeline-freeze', '#lifeline-hint']) {
      const box = await page.locator(sel).boundingBox();
      expect(box, `${sel} is rendered`).not.toBeNull();
      expect(box.y, `${sel} top`).toBeGreaterThanOrEqual(0);
      expect(box.y + box.height, `${sel} bottom`).toBeLessThanOrEqual(vp.height);
    }
    expect([...art.unknown]).toEqual([]);
    pageErrors.expectNone();
  });
});

test('without the overworld, the card grid shows the island art', async ({ page, context }) => {
  await blockRemote(context, server.origin);
  await seedRandom(context);
  const art = await routeArt(context, 'served');
  art.missing.add('map/overworld.png');
  const pageErrors = trackPageErrors(page);
  await page.goto(server.url);
  await createProfile(page);
  await expectArt('missing', page.locator('#world-map-art'), 'map/overworld.png', page.locator('#world-grid'));
  await expect(page.locator('.world-map')).toBeHidden();
  await expectWorldGrid('served', page);
  await expectCleanImages(page);
  await page.screenshot({ path: `${SHOTS}/art-served-12-world-grid-no-overworld.png` });
  await openIsland(page, 'Signal Tower');
  await expect(page.locator('#island-title')).toHaveText('Signal Tower');
  expect([...art.unknown]).toEqual([]);
  pageErrors.expectNone();
});

test('art that turns up mid-session shows without a reload', async ({ page, context }) => {
  await blockRemote(context, server.origin);
  await seedRandom(context);
  const art = await routeArt(context, 'missing');
  const pageErrors = trackPageErrors(page);
  await page.goto(server.url);
  await createProfile(page);
  const scrapFields = page.locator('#world-islands .island-node', { hasText: 'Scrap Fields' });
  await expectArt('missing', scrapFields.locator('.island-art'), 'map/island-scrap-fields.png', scrapFields.locator('.island-icon'));
  await expectArt('missing', page.locator('#world-map-art'), 'map/overworld.png', page.locator('#world-grid'));

  // The art lands; the next time each screen draws, it shows
  art.mode = 'served';
  await page.click('.world-footer .btn:has-text("STATS")');
  await page.click('#screen-stats .back-btn');
  await expectArt('served', page.locator('#world-map-art'), 'map/overworld.png', page.locator('#world-grid'));
  await expectArt('served', page.locator('#world-player-avatar'), 'avatars/avatar-male.png');

  await openIsland(page, 'Scrap Fields');
  await startNode(page, 'Standard Form');
  const enemyFile = 'enemies/' + await page.evaluate(() => Combat._run._currentEnemy.img);
  await expectArt('served', page.locator('#enemy-sprite'), enemyFile, page.locator('#enemy-sprite-fallback'));
  await expectArt('served', page.locator('#lifeline-hint .lifeline-img'), 'ui/lifeline-hint-on.png');
  await expectFrame('served', page.locator('#question-card'), 'ui/question-card.png');
  await page.click('#lifeline-hint');
  await expectArt('served', page.locator('#hint-spark'), 'avatars/spark-thinking.png', page.locator('.hint-spark-placeholder'));
  pageErrors.expectNone();
});
