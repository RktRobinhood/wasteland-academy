// The service worker must (a) let the game boot offline after one online visit
// and (b) never pin returning players to an old build. The test server sends
// GitHub Pages' `cache-control: max-age=600`, so (b) also covers the HTTP cache.
import { test, expect } from '@playwright/test';
import { startServer } from './server.mjs';
import { routeCdn, trackPageErrors } from './helpers.mjs';

let server;
test.beforeEach(async ({ context }) => {
  server = await startServer();
  await routeCdn(context);
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
