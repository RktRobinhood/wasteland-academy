// Install: on Chromium the world screen's INSTALL APP button shows only once
// the browser fires beforeinstallprompt. iOS has no prompt, so it gets a
// one-time Add to Home Screen tip instead. Headless Chromium never fires the
// event on its own, so the tests fire one shaped like the real thing.
import { test, expect } from '@playwright/test';
import { startServer } from './server.mjs';
import { blockRemote, trackPageErrors, createProfile } from './helpers.mjs';

test.use({ serviceWorkers: 'block' });

const SHOTS = 'test-results/screenshots';
const IPHONE_UA = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1';

let server;
test.beforeAll(async () => { server = await startServer(); });
test.afterAll(async () => { await server?.close(); });
test.beforeEach(async ({ context }) => { await blockRemote(context, server.origin); });

function fireInstallPrompt(page) {
  return page.evaluate(() => {
    const e = new Event('beforeinstallprompt', { cancelable: true });
    e.prompt = () => { window.__installPrompted = (window.__installPrompted || 0) + 1; };
    e.userChoice = Promise.resolve({ outcome: 'accepted', platform: 'web' });
    window.dispatchEvent(e);
    return e.defaultPrevented;
  });
}

test('the install button shows only when the browser offers to install, and opens its prompt', async ({ page }) => {
  const pageErrors = trackPageErrors(page);
  await page.goto(server.url);
  await createProfile(page);

  await expect(page.locator('#install-btn')).toBeHidden();
  await expect(page.locator('#ios-install-tip'), 'no iOS tip on Chromium').toBeHidden();

  expect(await fireInstallPrompt(page), 'the mini-infobar is held back').toBe(true);
  await expect(page.locator('#install-btn')).toBeVisible();
  await expect(page.locator('#install-btn'), 'on screen without scrolling').toBeInViewport({ ratio: 1 });
  await page.screenshot({ path: `${SHOTS}/install-01-button-390x844.png` });

  await page.click('#install-btn');
  expect(await page.evaluate(() => window.__installPrompted)).toBe(1);
  // A prompt can only be used once, so the button goes until the browser offers again
  await expect(page.locator('#install-btn')).toBeHidden();

  await fireInstallPrompt(page);
  await expect(page.locator('#install-btn')).toBeVisible();
  await page.evaluate(() => window.dispatchEvent(new Event('appinstalled')));
  await expect(page.locator('#install-btn')).toBeHidden();
  pageErrors.expectNone();
});

test.describe('iPhone', () => {
  test.use({ userAgent: IPHONE_UA });

  test('shows the Add to Home Screen tip once, until it is closed', async ({ page }) => {
    const pageErrors = trackPageErrors(page);
    await page.goto(server.url);
    await createProfile(page);

    await expect(page.locator('#ios-install-tip')).toBeVisible();
    await expect(page.locator('#ios-install-tip')).toContainText('Add to Home Screen');
    await expect(page.locator('#ios-install-tip'), 'on screen without scrolling').toBeInViewport({ ratio: 1 });
    await expect(page.locator('#install-btn')).toBeHidden();
    await page.screenshot({ path: `${SHOTS}/install-02-ios-tip-390x844.png` });

    await page.click('#ios-install-tip .ios-install-tip-close');
    await expect(page.locator('#ios-install-tip')).toBeHidden();
    await page.reload();
    await expect(page.locator('#screen-world')).toBeVisible();
    await expect(page.locator('#ios-install-tip')).toBeHidden();
    pageErrors.expectNone();
  });
});
