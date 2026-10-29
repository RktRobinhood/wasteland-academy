// The takeover dry run (README, "Switching to Godot"). tools/takeover-dry-run lays out
// the site twice with scripts/assemble-site.sh, in $TAKEOVER_SITES/off and /on, and
// this serves them the way GitHub Pages does, at /wasteland-academy/, and checks each.
//
// Switch off: the site as it was, the HTML game at the root and Godot at next/.
// Switch on: Godot at the root, the HTML game at classic/, next/ links sent to the
// root, and a browser that ran the old game's service worker ends up on Godot.
import { test, expect } from '@playwright/test';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import {
  blockRemote, trackPageErrors, createProfile, openIsland, startNode, currentQuestion, answer,
} from '../e2e/helpers.mjs';

const REPO = path.resolve(import.meta.dirname, '../..');
const SITES = path.resolve(process.env.TAKEOVER_SITES || path.join(REPO, '_scratch/takeover'));
const SHOTS = path.join(REPO, 'test-results/takeover-shots');
const BASE = '/wasteland-academy/';
const SIZES = {
  phone: { viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true },
  pc: { viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1, isMobile: false, hasTouch: false },
};
const MIME = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8',
  '.json': 'application/json', '.wav': 'audio/wav', '.png': 'image/png', '.svg': 'image/svg+xml',
  '.woff2': 'font/woff2', '.wasm': 'application/wasm', '.webp': 'image/webp',
};

// Serves $TAKEOVER_SITES/<position> like Pages: a folder without its slash redirects,
// a folder serves its index.html, and everything has max-age=600. `position` can
// change mid-test, as a deploy that flips the switch would.
async function startSite(position) {
  const state = { position };
  const sockets = new Set();
  const server = http.createServer((req, res) => {
    const url = new URL(req.url, 'http://x');
    let rel = decodeURIComponent(url.pathname);
    if (!rel.startsWith(BASE)) return res.writeHead(404).end('not found');
    rel = rel.slice(BASE.length);
    const root = path.join(SITES, state.position);
    let fp = path.join(root, rel);
    if (fp !== root && !fp.startsWith(root + path.sep)) return res.writeHead(404).end('not found');
    if (fs.existsSync(fp) && fs.statSync(fp).isDirectory()) {
      if (rel && !rel.endsWith('/')) return res.writeHead(301, { location: url.pathname + '/' + url.search }).end();
      fp = path.join(fp, 'index.html');
    }
    fs.readFile(fp, (err, data) => {
      if (err) return res.writeHead(404, { 'content-type': 'text/plain' }).end('not found');
      res.writeHead(200, { 'content-type': MIME[path.extname(fp)] || 'application/octet-stream', 'cache-control': 'max-age=600' });
      res.end(data);
    });
  });
  server.on('connection', s => { sockets.add(s); s.on('close', () => sockets.delete(s)); });
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  const origin = `http://127.0.0.1:${server.address().port}`;
  return {
    state, origin, url: origin + BASE,
    close() { for (const s of sockets) s.destroy(); return new Promise(r => server.close(r)); },
  };
}

// The Godot shell removes its #status overlay once the engine is running
async function godotBoots(page) {
  await expect(page.locator('#canvas')).toBeAttached();
  await page.waitForFunction(() => !document.getElementById('status'), null, { timeout: 120_000 });
  await page.waitForTimeout(1500);
}

// Every service worker registration's scope, relative to the site
async function workerScopes(page, site) {
  return page.evaluate(async base => (await navigator.serviceWorker.getRegistrations())
    .map(r => r.scope.slice(base.length)), site.url);
}

async function playOneQuestion(page) {
  await openIsland(page, 'Scrap Fields');
  await startNode(page, 'Standard Form');
  await answer(page, await currentQuestion(page), true);
  await expect(page.locator('#outcome-msg')).toHaveText('CORRECT!');
}

async function waitForWorker(page) {
  await page.evaluate(async () => {
    await navigator.serviceWorker.ready;
    if (!navigator.serviceWorker.controller) {
      await new Promise(r => navigator.serviceWorker.addEventListener('controllerchange', r, { once: true }));
    }
  });
}

function shot(page, name) {
  fs.mkdirSync(SHOTS, { recursive: true });
  return page.screenshot({ path: path.join(SHOTS, `${name}.png`) });
}

let site;
test.afterEach(async () => { await site?.close(); });

test.describe('switch off: the site as it was', () => {
  test.beforeEach(async ({ context }) => {
    site = await startSite('off');
    await blockRemote(context, site.origin);
  });

  test('/ is the HTML game, with its worker at the root and no New version link', async ({ page }) => {
    const errors = trackPageErrors(page);
    await page.goto(site.url);
    await createProfile(page);
    await expect(page.locator('#new-version-link')).toBeHidden();
    await playOneQuestion(page);
    await waitForWorker(page);
    expect(await workerScopes(page, site)).toEqual(['']);
    errors.expectNone();
  });

  test('the root service-worker.js is the HTML game\'s', async ({ request }) => {
    const served = await (await request.get(site.url + 'service-worker.js')).text();
    expect(served).toBe(fs.readFileSync(path.join(REPO, 'service-worker.js'), 'utf8'));
  });

  test('/next/ is Godot, with no Classic link, and region links stay there', async ({ page }) => {
    await page.goto(site.url + 'next/#functions/quadratics');
    await godotBoots(page);
    expect(new URL(page.url()).pathname).toBe(BASE + 'next/');
    expect(new URL(page.url()).hash).toBe('#functions/quadratics');
    await expect(page.locator('meta[name="wa-classic"]')).toHaveCount(0);
  });

  test('the root manifest keeps the app id', async ({ request }) => {
    expect((await (await request.get(site.url + 'manifest.json')).json()).id).toBe('wasteland-academy');
  });

  test('/classic/ isn\'t published', async ({ request }) => {
    expect((await request.get(site.url + 'classic/')).status()).toBe(404);
  });
});

test.describe('switch on: Godot at the root, the HTML game at classic/', () => {
  test.beforeEach(async ({ context }) => {
    site = await startSite('on');
    await blockRemote(context, site.origin);
  });

  for (const [size, options] of Object.entries(SIZES)) {
    test(`/ is Godot, with the Classic game link (${size})`, async ({ browser }) => {
      const context = await browser.newContext(options);
      await blockRemote(context, site.origin);
      const page = await context.newPage();
      const errors = trackPageErrors(page);
      await page.goto(site.url);
      await godotBoots(page);
      await expect(page.locator('meta[name="wa-classic"]')).toHaveAttribute('content', 'classic/');
      expect(await page.title()).toBe('Wasteland Academy');
      await shot(page, `on-root-${size}`);
      // The link is drawn in the canvas, in the bottom right corner
      const { width, height } = options.viewport;
      const corner = { x: width - (size === 'pc' ? 60 : 40), y: height - (size === 'pc' ? 32 : 28) };
      if (size === 'pc') await page.mouse.click(corner.x, corner.y);
      else await page.touchscreen.tap(corner.x, corner.y);
      await page.waitForURL(site.url + 'classic/');
      await expect(page.locator('#screen-profile')).toBeVisible();
      errors.expectNone();
      await context.close();
    });

    test(`/classic/ is the HTML game, with the New version link (${size})`, async ({ browser }) => {
      const context = await browser.newContext(options);
      await blockRemote(context, site.origin);
      const page = await context.newPage();
      const errors = trackPageErrors(page);
      await page.goto(site.url + 'classic/');
      await createProfile(page);
      const link = page.locator('#new-version-link');
      await expect(link).toBeVisible();
      expect(await link.evaluate(a => a.href)).toBe(site.url);
      await shot(page, `on-classic-${size}`);
      await playOneQuestion(page);
      await waitForWorker(page);
      // The HTML game's worker lives under classic/ only
      expect(await workerScopes(page, site)).toEqual(['classic/']);
      errors.expectNone();
      await context.close();
    });
  }

  test('next/ links go to the root, keeping their #… and ?…', async ({ page }) => {
    await page.goto(site.url + 'next/#functions/quadratics');
    await godotBoots(page);
    expect(page.url()).toBe(site.url + '#functions/quadratics');
    await shot(page, 'on-next-quadratics-phone');

    await page.goto(site.url + 'next/?explore');
    await godotBoots(page);
    // The explorer then adds the question it opened on (&view=…&seed=…)
    expect(page.url()).toMatch(new RegExp(`^${site.url}\\?explore(&|$)`));
    await shot(page, 'on-next-explore-phone');

    // Without the trailing slash, as Pages redirects
    await page.goto(site.url + 'next?play=quadratics&seed=3');
    expect(page.url()).toBe(site.url + '?play=quadratics&seed=3');
  });

  test('classic/ has its own app id, so an app installed from the old root stays there', async ({ request }) => {
    const manifest = await (await request.get(site.url + 'classic/manifest.json')).json();
    expect(manifest.id).toBe('wasteland-academy-classic');
    expect([manifest.start_url, manifest.scope]).toEqual(['./index.html', './']);
  });

  test('a browser that ran the old game ends up on Godot at /, and keeps its save', async ({ page }) => {
    // Before the switch: the HTML game at the root installs its worker and saves
    site.state.position = 'off';
    await page.goto(site.url);
    await createProfile(page, 'OLDSAVE');
    await waitForWorker(page);
    expect(await workerScopes(page, site)).toEqual(['']);
    const save = await page.evaluate(() => localStorage.getItem('wa_save'));
    expect(save).toContain('OLDSAVE');

    // The switch goes on. The next visit to the root goes through the old worker.
    site.state.position = 'on';
    await page.goto(site.url);
    // The retiring worker unregisters and reloads the page
    await expect.poll(async () => {
      try {
        return await page.evaluate(async () => ({
          registrations: (await navigator.serviceWorker.getRegistrations()).length,
          controlled: !!navigator.serviceWorker.controller,
        }));
      } catch { return 'navigating'; }
    }, { timeout: 60_000 }).toEqual({ registrations: 0, controlled: false });
    await godotBoots(page);
    expect(new URL(page.url()).pathname).toBe(BASE);
    await expect(page.locator('meta[name="wa-classic"]')).toHaveCount(1);
    // No old game file is left in any cache
    expect(await page.evaluate(async () => {
      const urls = [];
      for (const key of await caches.keys()) {
        for (const r of await (await caches.open(key)).keys()) urls.push(r.url);
      }
      return urls;
    })).toEqual([]);
    // A reload stays on Godot, with no worker
    await page.reload();
    await godotBoots(page);
    expect(await page.evaluate(() => !!navigator.serviceWorker.controller)).toBe(false);

    // Saves: the HTML game's keys are untouched by Godot, and classic/ picks them up
    expect(await page.evaluate(() => localStorage.getItem('wa_save'))).toBe(save);
    const keys = await page.evaluate(() => Object.keys(localStorage).sort());
    expect(keys.every(k => k.startsWith('wa_')), `localStorage keys: ${keys}`).toBe(true);
    const databases = await page.evaluate(async () => (await indexedDB.databases()).map(d => d.name).sort());
    console.log(`localStorage keys: ${keys.join(', ')}; IndexedDB databases: ${databases.join(', ')}`);
    expect(databases).toContain('/userfs');

    await page.goto(site.url + 'classic/');
    await expect(page.locator('#screen-world')).toBeVisible();
    await expect(page.locator('#world-player-name')).toHaveText('OLDSAVE');
    await waitForWorker(page);
    expect(await workerScopes(page, site)).toEqual(['classic/']);
    expect(await page.evaluate(async () => (await indexedDB.databases()).map(d => d.name).sort())).toEqual(databases);
  });
});
