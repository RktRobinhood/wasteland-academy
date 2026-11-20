// The takeover dry run (README, "Switching to Godot"). tools/takeover-dry-run lays out
// the site twice with scripts/assemble-site.sh, in $TAKEOVER_SITES/off and /on, and
// this serves them the way GitHub Pages does, at /wasteland-academy/, and checks each.
//
// Switch off: the site as it was, the HTML game at the root and Godot at next/.
// Switch on: Godot at the root with no Classic link, the HTML game not published,
// next/ links sent to the root, a browser that ran the old game's service worker
// (at the root or at classic/) ends up on Godot, and Godot plays offline after one
// visit and picks up a new deploy. In neither is a repository document published (#197).
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
// change mid-test, as a deploy that flips the switch would, and `edit` stands in for
// a new export: edit(rel, text) is what that file becomes. `extra` is files served
// besides the site, path to text, as an older deploy had them.
async function startSite(position) {
  const state = { position, edit: null, extra: {} };
  const sockets = new Set();
  const server = http.createServer((req, res) => {
    const url = new URL(req.url, 'http://x');
    let rel = decodeURIComponent(url.pathname);
    if (!rel.startsWith(BASE)) return res.writeHead(404).end('not found');
    rel = rel.slice(BASE.length);
    const root = path.join(SITES, state.position);
    let fp = path.join(root, rel);
    if (fp !== root && !fp.startsWith(root + path.sep)) return res.writeHead(404).end('not found');
    const extra = rel.endsWith('/') ? rel + 'index.html' : rel;
    if (extra in state.extra) {
      return res.writeHead(200, { 'content-type': MIME[path.extname(extra)] }).end(state.extra[extra]);
    }
    if (fs.existsSync(fp) && fs.statSync(fp).isDirectory()) {
      if (rel && !rel.endsWith('/')) return res.writeHead(301, { location: url.pathname + '/' + url.search }).end();
      fp = path.join(fp, 'index.html');
    }
    fs.readFile(fp, (err, data) => {
      if (err) return res.writeHead(404, { 'content-type': 'text/plain' }).end('not found');
      if (state.edit) data = state.edit(path.relative(root, fp), data);
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

// Every URL in the page's caches, by cache name
async function cachedUrls(page) {
  return page.evaluate(async () => {
    const out = {};
    for (const key of await caches.keys()) out[key] = (await (await caches.open(key)).keys()).map(r => r.url).sort();
    return out;
  });
}

// The worker's cache is named for the build (scripts/build-id.sh); tools/takeover-dry-run sets it
const BUILD_ID = process.env.WA_BUILD_ID;
const CACHE = 'wasteland-academy-godot-' + BUILD_ID;

// The root worker controls the page and has copied the whole export
async function godotCached(page, site) {
  await waitForWorker(page);
  // Every file the export put at the root: the worker's list must cover them all,
  // less audio.pck, which waits until sound is on (#183)
  const root = path.join(SITES, 'on');
  const exported = fs.readdirSync(root).filter(f => !['service-worker.js', 'audio.pck'].includes(f) && fs.statSync(path.join(root, f)).isFile());
  await expect.poll(async () => (await cachedUrls(page))[CACHE] || [], { timeout: 60_000 })
    .toEqual(exported.map(f => site.url + f).sort());
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

// From #197: all of these were published under classic/ with the switch on
const UNPUBLISHED = ['classic/', 'classic/index.html', 'classic/ROADMAP.md', 'classic/game/project.godot',
  'classic/services/telemetry/wrangler.toml', 'classic/writing/voice-sheets.md', 'ROADMAP.md', 'ROADMAP.html',
  'README.md', 'game/project.godot', 'services/telemetry/wrangler.toml', 'writing/voice-sheets.md',
  'assets/audio/CREDITS.md', 'tools/takeover-dry-run', 'package.json'];

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

  test('/classic/ and the repository\'s documents and source aren\'t published', async ({ request }) => {
    for (const rel of UNPUBLISHED) expect((await request.get(site.url + rel)).status(), rel).toBe(404);
  });
});

test.describe('switch on: Godot at the root, the HTML game not published', () => {
  test.beforeEach(async ({ context }) => {
    site = await startSite('on');
    await blockRemote(context, site.origin);
  });

  for (const [size, options] of Object.entries(SIZES)) {
    test(`/ is Godot, with no Classic game link (${size})`, async ({ browser }) => {
      const context = await browser.newContext(options);
      await blockRemote(context, site.origin);
      const page = await context.newPage();
      const errors = trackPageErrors(page);
      await page.goto(site.url);
      await godotBoots(page);
      await expect(page.locator('meta[name="wa-classic"]')).toHaveCount(0);
      expect(await page.title()).toBe('Wasteland Academy');
      await shot(page, `on-root-${size}`);
      // The bottom right corner, where the link was, goes nowhere
      const { width, height } = options.viewport;
      const corner = { x: width - (size === 'pc' ? 60 : 40), y: height - (size === 'pc' ? 32 : 28) };
      if (size === 'pc') await page.mouse.click(corner.x, corner.y);
      else await page.touchscreen.tap(corner.x, corner.y);
      await page.waitForTimeout(1500);
      expect(page.url()).toBe(site.url);
      errors.expectNone();
      await context.close();
    });
  }

  test('/classic/ and the repository\'s documents and source aren\'t published', async ({ request }) => {
    for (const rel of UNPUBLISHED) expect((await request.get(site.url + rel)).status(), rel).toBe(404);
  });

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
    // The worker update (the root worker, _takeover/) clears the old game and reloads the page
    await expect.poll(async () => {
      try {
        return await page.evaluate(async () => ({
          registrations: (await navigator.serviceWorker.getRegistrations()).length,
          worker: navigator.serviceWorker.controller?.scriptURL.endsWith('/service-worker.js'),
          oldGame: !!document.getElementById('screen-profile'),
        }));
      } catch { return 'navigating'; }
    }, { timeout: 60_000 }).toEqual({ registrations: 1, worker: true, oldGame: false });
    // The old worker is service-worker.js too, so wait for the new one's activation:
    // no old game file is left in any cache, only Godot's
    await expect.poll(async () => {
      try { return Object.keys(await cachedUrls(page)); } catch { return 'navigating'; }
    }, { timeout: 60_000 }).toEqual([CACHE]);
    await godotBoots(page);
    expect(new URL(page.url()).pathname).toBe(BASE);
    await godotCached(page, site);
    // A reload stays on Godot
    await page.reload();
    await godotBoots(page);
    expect(await workerScopes(page, site)).toEqual(['']);

    // Saves: the HTML game's keys are untouched by Godot
    expect(await page.evaluate(() => localStorage.getItem('wa_save'))).toBe(save);
    const keys = await page.evaluate(() => Object.keys(localStorage).sort());
    expect(keys.every(k => k.startsWith('wa_')), `localStorage keys: ${keys}`).toBe(true);
    const databases = await page.evaluate(async () => (await indexedDB.databases()).map(d => d.name).sort());
    console.log(`localStorage keys: ${keys.join(', ')}; IndexedDB databases: ${databases.join(', ')}`);
    expect(databases).toContain('/userfs');
  });

  test('a browser that ran the HTML game at classic/ loses its worker and cached copy there', async ({ page }) => {
    // The last deploy's classic/: a page that registers its worker and caches itself
    site.state.extra = {
      'classic/index.html': `<script>
        navigator.serviceWorker.register('service-worker.js');
        caches.open('wasteland-academy-v3').then(c => c.put(location.href, new Response('classic')));
      </script>`,
      'classic/service-worker.js': `self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
        self.addEventListener('fetch', () => {});`,
    };
    await page.goto(site.url + 'classic/');
    await waitForWorker(page);
    await expect.poll(async () => Object.keys(await cachedUrls(page))).toEqual(['wasteland-academy-v3']);
    expect(await workerScopes(page, site)).toEqual(['classic/']);

    // This deploy: no classic/. Godot at the root retires the worker and its cache.
    site.state.extra = {};
    await page.goto(site.url);
    await godotBoots(page);
    await waitForWorker(page);
    await expect.poll(() => workerScopes(page, site)).toEqual(['']);
    await expect.poll(async () => Object.keys(await cachedUrls(page))).toEqual([CACHE]);
    expect((await page.request.get(site.url + 'classic/')).status()).toBe(404);
  });

  // SPEC: "Practice must continue to work offline with the reviewed runtime catalogue."
  // The catalogue is in index.pck, so a question in the explorer proves it loaded.
  test('/ plays offline after one visit: a practice question and a fight', async ({ page, context }) => {
    const errors = trackPageErrors(page);
    await page.goto(site.url);
    await godotBoots(page);
    await godotCached(page, site);

    await context.setOffline(true);
    // The explorer opens on a question from the catalogue and puts it in the URL
    await page.goto(site.url + '?explore');
    await godotBoots(page);
    await expect.poll(() => page.url()).toMatch(/\?explore&view=[^&]+\/[^&]+&seed=\d+$/);
    await shot(page, 'on-offline-explore-phone');
    await page.reload();
    await godotBoots(page);
    await expect.poll(() => page.url()).toMatch(/\?explore&view=/);

    await page.goto(site.url + '?play=quadratics&seed=3');
    await godotBoots(page);
    await shot(page, 'on-offline-fight-phone');
    // Map links too
    await page.goto(site.url + '#functions/quadratics');
    await godotBoots(page);
    expect(new URL(page.url()).hash).toBe('#functions/quadratics');
    errors.expectNone();
  });

  test('a new build waits for the lesson to end, and reaches the player after, offline too', async ({ page, context }) => {
    await page.goto(site.url);
    await godotBoots(page);
    await godotCached(page, site);
    const build = () => page.locator('meta[name="wa-build"]').getAttribute('content').catch(() => null);
    expect(await build()).toBe(null);

    // The next deploy: a new index.html, index.js and worker (a new build id)
    site.state.edit = (rel, data) => {
      if (rel === 'index.html') return data.toString().replace('<head>', '<head>\n<meta name="wa-build" content="2">');
      if (rel === 'index.js') return data.toString() + '\nwindow.waBuildJs = 2;\n';
      if (rel === 'service-worker.js') return data.toString().replace(`const BUILD_ID = '${BUILD_ID}'`, "const BUILD_ID = 'next'");
      return data;
    };
    // The page loads from its cache and doesn't wait on the network, so it is still build 1
    await page.reload();
    await godotBoots(page);
    expect(await build()).toBe(null);
    // The browser updates the worker in the background; it fills its own cache and waits
    await expect.poll(async () => {
      const reg = await page.evaluate(async () => {
        const r = await navigator.serviceWorker.getRegistration();
        await r?.update();
        return !!r?.waiting;
      });
      return reg && Object.keys(await cachedUrls(page)).sort();
    }, { timeout: 60_000 }).toEqual([CACHE, 'wasteland-academy-godot-next'].sort());
    await page.reload();
    await godotBoots(page);
    expect(await build()).toBe(null);

    // The lesson ends: the new build takes over, with the old cache dropped
    await page.evaluate(async () => (await navigator.serviceWorker.getRegistration()).waiting.postMessage('skip-waiting'));
    await expect.poll(async () => Object.keys(await cachedUrls(page))).toEqual(['wasteland-academy-godot-next']);
    await page.reload();
    await godotBoots(page);
    expect(await build()).toBe('2');
    expect(await page.evaluate(() => window.waBuildJs)).toBe(2);
    await context.setOffline(true);
    await page.reload();
    await godotBoots(page);
    expect(await build()).toBe('2');
    expect(await page.evaluate(() => window.waBuildJs)).toBe(2);
  });
});
