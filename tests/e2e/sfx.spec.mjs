import { test, expect } from '@playwright/test';
import { startServer } from './server.mjs';
import { createProfile, openIsland, startNode, answer, currentQuestion, waitForNext, clearNode, trackPageErrors, seedRandom } from './helpers.mjs';
let server;
test.beforeEach(async ({ context }) => {
  server = await startServer();
  await seedRandom(context);
  await context.addInitScript(() => {
    window.playedSFX = [];
    const original = HTMLMediaElement.prototype.play;
    HTMLMediaElement.prototype.play = function () {
      window.playedSFX.push({ src: this.src, volume: this.volume });
      return original.call(this);
    };
  });
});
test.afterEach(async () => { await server.close(); });

test('accepted SFX are opt-in, follow real answers and lifelines, and mute immediately', async ({ page }) => {
  const errors = trackPageErrors(page);
  await page.goto(server.url); await createProfile(page);
  expect(await page.evaluate(() => playedSFX)).toHaveLength(0);
  await page.locator('#sfx-toggle').click();
  await openIsland(page, 'Scrap Fields'); await startNode(page, 'Standard Form');
  await expect(page.locator('#sfx-toggle-combat')).toHaveText('Sound: on');
  expect(await page.evaluate(() => playedSFX.at(-1).src)).toContain('encounter-open-01.wav');
  await answer(page, await currentQuestion(page), false);
  expect(await page.evaluate(() => playedSFX.at(-1).src)).toContain('answer-retry-01.wav');
  await waitForNext(page);
  await page.click('#lifeline-freeze');
  expect(await page.evaluate(() => playedSFX.at(-1).src)).toContain('hint-relay-01.wav');
  await answer(page, await currentQuestion(page), true);
  expect(await page.evaluate(() => playedSFX.at(-1).src)).toContain('answer-correct-01.wav');
  await waitForNext(page);
  await clearNode(page);
  expect(await page.evaluate(() => playedSFX.at(-1))).toMatchObject({ volume: 0.10 });
  expect(await page.evaluate(() => playedSFX.at(-1).src)).toContain('encounter-clear-01.wav');
  await page.evaluate(() => Router.go('world'));
  await page.locator('#sfx-toggle').click();
  expect(await page.evaluate(() => SFX.current)).toBeNull();
  await expect(page.locator('#sfx-toggle')).toHaveAttribute('aria-pressed', 'false');
  errors.expectNone();
});

test('all accepted WAVs decode from the offline cache under the Pages subpath', async ({ page, context }) => {
  await page.goto(server.url);
  await page.evaluate(async () => {
    await navigator.serviceWorker.ready;
    if (!navigator.serviceWorker.controller) await new Promise(resolve => navigator.serviceWorker.addEventListener('controllerchange', resolve, { once: true }));
  });
  server.setOffline(true); await context.setOffline(true); await page.reload();
  await createProfile(page); await page.locator('#sfx-toggle').click();
  const assets = await page.evaluate(async () => {
    const result = [];
    for (const file of Object.values(SFX.files)) {
      const url = new URL(file + '.wav', SFX.base);
      const response = await fetch(url); const audio = new Audio(url);
      await new Promise((resolve, reject) => { audio.onloadedmetadata = resolve; audio.onerror = reject; audio.load(); });
      result.push({ file, status: response.status, bytes: (await response.arrayBuffer()).byteLength, duration: audio.duration });
    }
    return result;
  });
  expect(assets).toHaveLength(7);
  for (const asset of assets) { expect(asset.status).toBe(200); expect(asset.bytes).toBeGreaterThan(1000); expect(asset.duration).toBeGreaterThan(0); }
});

test('the small-phone control stays in the header and only successful purchases play', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto(server.url); await createProfile(page);
  const bounds = await page.locator('#sfx-toggle').boundingBox();
  expect(bounds.x).toBeGreaterThanOrEqual(0); expect(bounds.x + bounds.width).toBeLessThanOrEqual(375);
  expect(bounds.height).toBeGreaterThanOrEqual(48);
  await page.locator('#sfx-toggle').click();
  await page.evaluate(() => Router.go('bazaar'));
  await page.locator('[data-item="refill-lifelines"]').click();
  expect(await page.evaluate(() => playedSFX.at(-1).src)).toContain('scrap-reward-01.wav');
  const count = await page.evaluate(() => playedSFX.length);
  await page.evaluate(() => { WA.state.profile.scrap = 0; BazaarScreen._buy('perk-armour'); });
  expect(await page.evaluate(() => playedSFX.length)).toBe(count);
});
