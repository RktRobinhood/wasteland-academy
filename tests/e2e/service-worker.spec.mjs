// The service worker must (a) let the game boot offline after one online visit
// and (b) never pin returning players to an old build. The test server sends
// GitHub Pages' `cache-control: max-age=600`, so (b) also covers the HTTP cache.
import { test, expect } from '@playwright/test';
import { startServer } from './server.mjs';
import { standin } from './standins.mjs';
import {
  blockRemote, trackPageErrors, createProfile, openIsland, startNode, clearNode,
} from './helpers.mjs';

const SHOTS = 'test-results/screenshots';

let server;
let remote;
test.beforeEach(async ({ context }) => {
  server = await startServer();
  remote = await blockRemote(context, server.origin);
});
test.afterEach(async () => { await server?.close(); });

// First visit: load, then wait until the worker is installed (precache done) and controls the page
async function firstVisit(page) {
  await page.goto(server.url);
  await expect(page.locator('#screen-profile')).toBeVisible();
  await page.evaluate(async () => {
    await navigator.serviceWorker.ready;
    if (!navigator.serviceWorker.controller) {
      await new Promise(r => navigator.serviceWorker.addEventListener('controllerchange', r, { once: true }));
    }
  });
}

test('after one online visit, the game boots offline', async ({ page, context }) => {
  const pageErrors = trackPageErrors(page);
  await firstVisit(page);

  server.setOffline(true);
  await context.setOffline(true);
  await page.reload();

  await expect(page.locator('#screen-profile')).toBeVisible();
  expect(await page.evaluate(() => !!navigator.serviceWorker.controller)).toBe(true);
  expect(await page.evaluate(() => WA.packs.map(p => p.id))).toEqual([
    'topic-1-algebra', 'topic-2-functions', 'topic-3-geometry', 'topic-4-stats', 'topic-5-calculus',
  ]);
  // KaTeX came from the cache too
  expect(await page.evaluate(() => typeof katex)).toBe('object');

  // A file that was never cached gets a real offline response, not a network error
  const status = await page.evaluate(() => fetch('assets/enemies/d1-scavenger.png').then(r => r.status, e => 'error: ' + e.message));
  expect(status).toBe(503);

  // And the game is playable: profile → world → island
  await page.fill('#profile-name', 'OFFLINE');
  await page.click('#screen-profile .btn-primary');
  await expect(page.locator('#screen-world')).toBeVisible();
  remote.expectNone();
  pageErrors.expectNone();
});

test('after one online visit, a full island fight plays offline with the network off', async ({ page, context }) => {
  const pageErrors = trackPageErrors(page);
  await firstVisit(page);

  // Network fully off: the server drops every connection and the browser is offline
  server.setOffline(true);
  await context.setOffline(true);
  await page.reload();
  expect(await page.evaluate(() => navigator.onLine)).toBe(false);
  expect(await page.evaluate(() => !!navigator.serviceWorker.controller)).toBe(true);

  await createProfile(page, 'OFFLINE');
  await openIsland(page, 'Scrap Fields');
  await startNode(page, 'Standard Form');

  // Maths is typeset by the vendored KaTeX, in its own fonts, and the game
  // fonts are the vendored ones. All of it came from the worker's cache.
  await expect(page.locator('#question-text .katex').first()).toBeVisible();
  const fonts = await page.evaluate(async () => {
    await document.fonts.ready;
    return [...document.fonts].filter(f => f.status === 'loaded').map(f => f.family.replace(/"/g, ''));
  });
  expect(fonts).toEqual(expect.arrayContaining(['Bangers', 'Share Tech Mono', 'KaTeX_Main']));
  await page.screenshot({ path: `${SHOTS}/offline-01-question-390x844.png` });

  await clearNode(page);
  await expect(page.locator('#debrief-mode')).toHaveText('ISLAND');
  await page.screenshot({ path: `${SHOTS}/offline-02-debrief-390x844.png` });

  // The cleared node was saved, and shows on the map
  await page.click('#screen-debrief .btn-ghost');
  await openIsland(page, 'Scrap Fields');
  await expect(page.locator('#island-nodes .node-btn', { hasText: 'Standard Form' })).toHaveClass(/node-cleared/);

  // Nothing was ever requested from another host, online or off
  remote.expectNone();
  pageErrors.expectNone();
});

test('a returning online player runs the newest code on the next reload', async ({ page }) => {
  const pageErrors = trackPageErrors(page);
  await firstVisit(page);

  // Reload once under the worker: still the original code
  await page.reload();
  await expect(page.locator('#screen-profile')).toBeVisible();
  expect(await page.evaluate(() => !!navigator.serviceWorker.controller)).toBe(true);
  expect(await page.evaluate(() => window.__deployMarker)).toBeUndefined();

  // Redeploy a changed JS file and CSS file, with no change to the service worker
  server.state.overrides.set('js/engine.js', buf => Buffer.concat([buf, Buffer.from('\nwindow.__deployMarker = "v2";\n')]));
  server.state.overrides.set('css/base.css', buf => Buffer.concat([buf, Buffer.from('\nbody { --deploy-marker: v2; }\n')]));

  await page.reload();
  await expect(page.locator('#screen-profile')).toBeVisible();
  expect(await page.evaluate(() => !!navigator.serviceWorker.controller), 'still served via the worker').toBe(true);
  expect(await page.evaluate(() => window.__deployMarker)).toBe('v2');
  expect(await page.evaluate(() => getComputedStyle(document.body).getPropertyValue('--deploy-marker').trim())).toBe('v2');
  pageErrors.expectNone();
});

// The colour of one pixel of a loaded <img>, as the page decoded it
const pixel = (page, sel) => page.locator(sel).evaluate(img => {
  const c = document.createElement('canvas');
  c.width = img.naturalWidth; c.height = img.naturalHeight;
  const ctx = c.getContext('2d');
  ctx.drawImage(img, 0, 0);
  return [...ctx.getImageData(1, 1, 1, 1).data.slice(0, 3)];
});

test('a returning online player sees art re-delivered under the same name', async ({ page }) => {
  const pageErrors = trackPageErrors(page);
  await firstVisit(page);
  await page.fill('#profile-name', 'VIPER');
  await page.click('#screen-profile .btn-primary');
  await expect(page.locator('#world-map-art')).toBeVisible();
  const before = await pixel(page, '#world-map-art');

  // Reload once under the worker: the same art, now in its cache too
  await page.reload();
  await expect(page.locator('#world-map-art')).toBeVisible();
  expect(await page.evaluate(() => !!navigator.serviceWorker.controller)).toBe(true);
  expect(await pixel(page, '#world-map-art')).toEqual(before);

  // The Artist re-delivers the overworld under the same file name
  server.state.overrides.set('assets/map/overworld.png', () => standin('map/overworld.png'));
  const replacement = [17, 24, 39];  // the stand-in's dark outline, at (1, 1)
  expect(before).not.toEqual(replacement);

  await page.reload();
  await expect(page.locator('#world-map-art')).toBeVisible();
  expect(await page.evaluate(() => !!navigator.serviceWorker.controller), 'still served via the worker').toBe(true);
  expect(await pixel(page, '#world-map-art')).toEqual(replacement);
  pageErrors.expectNone();
});
