// The takeover switch (README, "Switching to Godot"): scripts/assemble-site.sh lays
// out each position, publishing no repository document (#197, scripts/check-site.sh),
// and the root worker in _takeover/ keeps Godot playable offline and clears the HTML
// game's caches. tools/takeover-dry-run checks the same in a real browser.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { execFileSync, spawnSync } from 'node:child_process';
import { REPO } from '../content/packs.mjs';

const SITE = 'https://rktrobinhood.github.io/wasteland-academy/';
const ASSEMBLE = path.join(REPO, 'scripts/assemble-site.sh');
const CHECK = path.join(REPO, 'scripts/check-site.sh');

// What Jekyll publishes besides the HTML game: the whole repository, Markdown both as
// itself and as a page (#197)
const REPO_FILES = {
  'site/ROADMAP.md': 'roadmap', 'site/ROADMAP.html': 'roadmap page', 'site/README.html': 'readme page',
  'site/game/project.godot': 'godot', 'site/services/telemetry/wrangler.toml': 'toml',
  'site/writing/voice-sheets.md': 'voices', 'site/tools/takeover-dry-run': 'tool', 'site/curriculum/aa-sl.md': 'syllabus',
  'site/package.json': '{}', 'site/scripts/assemble-site.sh': 'sh',
  'site/assets/audio/CREDITS.md': 'credits', 'site/assets/audio/CREDITS.html': 'credits page',
};

// A Jekyll site and a Godot export, in a fresh folder under _scratch/
function fixture() {
  fs.mkdirSync(path.join(REPO, '_scratch'), { recursive: true });
  const dir = fs.mkdtempSync(path.join(REPO, '_scratch', 'takeover-unit-'));
  const files = {
    'site/index.html': 'html game', 'site/service-worker.js': 'html worker', 'site/js/engine.js': 'engine',
    'site/manifest.json': read(REPO, 'manifest.json'), 'site/assets/audio/hit.ogg': 'ogg', 'site/css/game.css': 'css',
    ...REPO_FILES,
    'export/index.html': '<html>\n<head>\n<meta charset="utf-8">\n<title>godot</title>', 'export/index.pck': 'pck', 'export/index.wasm': 'wasm',
  };
  for (const [rel, text] of Object.entries(files)) {
    fs.mkdirSync(path.dirname(path.join(dir, rel)), { recursive: true });
    fs.writeFileSync(path.join(dir, rel), text);
  }
  return { dir, site: path.join(dir, 'site'), exp: path.join(dir, 'export') };
}

function read(dir, rel) { return fs.readFileSync(path.join(dir, rel), 'utf8'); }

// Every file under dir, relative to it
function files(dir) {
  return fs.readdirSync(dir, { recursive: true }).filter(f => fs.statSync(path.join(dir, f)).isFile()).sort();
}

const check = site => spawnSync(CHECK, [site], { encoding: 'utf8' });

test('switch off: the HTML game at the root, Godot at next/, and nothing else', t => {
  const { dir, site, exp } = fixture();
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  execFileSync(ASSEMBLE, [site, exp, 'off'], { stdio: 'pipe' });
  assert.equal(read(site, 'index.html'), 'html game');
  assert.equal(read(site, 'service-worker.js'), 'html worker');
  assert.equal(read(site, 'next/index.pck'), 'pck');
  assert.deepEqual(files(site), ['assets/audio/hit.ogg', 'css/game.css', 'index.html', 'js/engine.js', 'manifest.json',
    'next/index.html', 'next/index.pck', 'next/index.wasm', 'service-worker.js']);
  assert.equal(check(site).status, 0, check(site).stderr);
});

test('switch on: Godot at the root and next/ a redirect, with no HTML game and no classic/', t => {
  const { dir, site, exp } = fixture();
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  execFileSync(ASSEMBLE, [site, exp, 'on'], { stdio: 'pipe', env: { ...process.env, WA_BUILD_ID: 'v9.9.9' } });
  const html = read(site, 'index.html');
  assert.match(html, /<head>\n<meta charset="utf-8">\n<script>/);
  assert.doesNotMatch(html, /wa-classic/);
  assert.ok(html.includes(read(REPO, '_takeover/register-worker.html')));
  assert.match(html, /<\/script>\n<title>godot/);
  assert.equal(read(site, 'index.pck'), 'pck');
  // The worker with the build id (scripts/build-id.sh) in place of its placeholder
  assert.equal(read(site, 'service-worker.js'), read(REPO, '_takeover/service-worker.js').replace('__BUILD_ID__', 'v9.9.9'));
  assert.equal(read(site, 'next/index.html'), read(REPO, '_takeover/next.html'));
  assert.deepEqual(files(site), ['index.html', 'index.pck', 'index.wasm', 'next/index.html', 'service-worker.js']);
  assert.equal(check(site).status, 0, check(site).stderr);
});

test('check-site fails on any repository document or source folder on the site', t => {
  fs.mkdirSync(path.join(REPO, '_scratch'), { recursive: true });
  const dir = fs.mkdtempSync(path.join(REPO, '_scratch', 'takeover-unit-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  const site = path.join(dir, 'site');
  const reset = () => {
    fs.rmSync(site, { recursive: true, force: true });
    fs.mkdirSync(path.join(site, 'js'), { recursive: true });
    fs.writeFileSync(path.join(site, 'index.html'), 'html game');
  };
  reset();
  assert.equal(check(site).status, 0, check(site).stderr);
  for (const leak of ['ROADMAP.md', 'ROADMAP.html', 'game/project.godot', 'services/telemetry/wrangler.toml',
    'writing/voice-sheets.md', 'tools/takeover-dry-run', 'curriculum/x.txt', 'assets/audio/CREDITS.html',
    'classic/index.html', 'next/notes.md']) {
    reset();
    fs.mkdirSync(path.dirname(path.join(site, leak)), { recursive: true });
    fs.writeFileSync(path.join(site, leak), 'x');
    const run = check(site);
    assert.notEqual(run.status, 0, leak);
    assert.match(run.stderr, new RegExp(leak.split('/')[0].replace('.', '\\.')), leak);
  }
});

test('switch off keeps the app id', t => {
  const { dir, site, exp } = fixture();
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  execFileSync(ASSEMBLE, [site, exp, 'off'], { stdio: 'pipe' });
  assert.equal(read(site, 'manifest.json'), read(REPO, 'manifest.json'));
  assert.equal(JSON.parse(read(site, 'manifest.json')).id, 'wasteland-academy');
});

test('any other switch value, or a published next/, stops the build', t => {
  const { dir, site, exp } = fixture();
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  for (const value of ['true', 'ON', '']) {
    const run = spawnSync(ASSEMBLE, [site, exp, value], { encoding: 'utf8' });
    assert.notEqual(run.status, 0, value);
  }
  fs.mkdirSync(path.join(site, 'next'));
  const run = spawnSync(ASSEMBLE, [site, exp, 'on'], { encoding: 'utf8' });
  assert.notEqual(run.status, 0);
  assert.match(run.stderr, /already publishes a next\//);
});

test('next/ sends people to the root with their ?… and #…', () => {
  const html = read(REPO, '_takeover/next.html');
  assert.match(html, /location\.replace\('\.\.\/' \+ location\.search \+ location\.hash\)/);
});

test('switch on stops the build if the Godot index.html has no <meta charset>', t => {
  const { dir, site, exp } = fixture();
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  fs.writeFileSync(path.join(exp, 'index.html'), '<html>\n<head>\n<title>godot</title>');
  const run = spawnSync(ASSEMBLE, [site, exp, 'on'], { encoding: 'utf8' });
  assert.notEqual(run.status, 0);
  assert.match(run.stderr, /meta charset/);
});

// The root worker (_takeover/service-worker.js) with stub caches, clients and network.
// `cached` is the caches it starts with, cache name to URLs; `online` the URLs the
// network has, URL (less its ?… and #…) to body. Returns its listeners, the caches' state and its calls.
function rootWorker(cached = {}, online = {}) {
  const listeners = {};
  const store = new Map(Object.entries(cached).map(([k, urls]) => [k, new Map(urls.map(u => [u, `cached ${u}`]))]));
  const navigated = [];
  const calls = [];
  const fetched = [];
  const response = (body, etag) => ({ ok: true, body, headers: { get: h => (h === 'etag' ? etag : null) }, clone() { return this; } });
  const ctx = vm.createContext({
    URL,
    Request: class { constructor(r, init) { Object.assign(this, r, init); } },
    fetch: async r => {
      const url = (typeof r === 'string' ? r : r.url).replace(/[?#].*/, '');
      fetched.push(url);
      if (!(url in online)) throw new TypeError('Failed to fetch');
      return response(online[url], `"${online[url]}"`);
    },
    self: {
      location: new URL('service-worker.js', SITE),
      addEventListener: (type, fn) => { listeners[type] = fn; },
      skipWaiting: async () => calls.push('skipWaiting'),
      registration: { unregister: async () => calls.push('unregister') },
      clients: {
        claim: async () => calls.push('claim'),
        matchAll: async () => [SITE, SITE + '#functions', SITE + 'classic/'].map(url => ({
          url, navigate: async u => navigated.push(u),
        })),
      },
    },
    caches: {
      keys: async () => [...store.keys()],
      has: async key => store.has(key),
      match: async (url, { cacheName }) => {
        const v = store.get(cacheName)?.get(url);
        return typeof v === 'string' ? response(v) : v;
      },
      open: async key => {
        if (!store.has(key)) store.set(key, new Map());
        const c = store.get(key);
        return {
          keys: async () => [...c.keys()].map(url => ({ url })),
          delete: async r => c.delete(r.url),
          match: async u => (c.has(u) ? (typeof c.get(u) === 'string' ? response(c.get(u)) : c.get(u)) : undefined),
          put: async (u, r) => { c.set(u, r); },
        };
      },
      delete: async key => store.delete(key),
    },
  });
  vm.runInContext(read(REPO, '_takeover/service-worker.js').replace('__BUILD_ID__', 'test'), ctx);
  const run = async (type, event = {}) => {
    const pending = [];
    let responded;
    listeners[type]({ ...event, waitUntil: p => pending.push(p), respondWith: p => { responded = p; } });
    const result = responded ? await responded.catch(e => e) : undefined;
    await Promise.all(pending);
    return result;
  };
  const state = () => Object.fromEntries([...store].map(([k, v]) => [k, [...v.keys()]]));
  const body = key => { const v = store.get(CACHE)?.get(key); return typeof v === 'string' ? v : v?.body; };
  return { run, state, body, navigated, calls, fetched };
}

const CACHE = 'wasteland-academy-godot-test';
const GET = (url, mode = 'no-cors') => ({ request: { method: 'GET', url, mode } });

test('the root worker clears the HTML game, classic/ too, and reloads the old pages', async () => {
  const w = rootWorker({
    'wasteland-academy-v3': [SITE, SITE + 'js/engine.js', SITE + 'index.wasm', SITE + 'classic/', SITE + 'classic/js/engine.js'],
    'wasteland-academy-v2': [SITE + 'index.html'],
    'someone-else': [SITE + 'x'],
    CACHE: [SITE + 'index.pck'],
  });
  await w.run('activate');
  assert.deepEqual(w.state(), { 'someone-else': [SITE + 'x'], CACHE: [SITE + 'index.pck'] });
  assert.deepEqual(w.calls, ['claim']);
  assert.deepEqual(w.navigated, [SITE, SITE + '#functions', SITE + 'classic/']);
});

test('the root worker reloads no page when there was no old game to clear', async () => {
  const w = rootWorker({ CACHE: [SITE + 'index.pck'] });
  await w.run('activate');
  assert.deepEqual(w.state(), { CACHE: [SITE + 'index.pck'] });
  assert.deepEqual(w.navigated, []);
  assert.deepEqual(w.calls, ['claim']);
});

test('the root worker\'s install copies the Godot build, skipping a file the export lacks', async () => {
  const files = ['index.html', 'index.js', 'index.wasm', 'index.pck', 'index.audio.worklet.js'];
  const w = rootWorker({}, Object.fromEntries(files.map(f => [SITE + f, f])));
  await w.run('install');
  assert.deepEqual(w.state()[CACHE].sort(), files.map(f => SITE + f).sort());
  assert.deepEqual(w.calls, ['skipWaiting']);
});

test('the root worker is cache first: a cached file never waits on the network', async () => {
  const online = { [SITE]: 'new html', [SITE + 'index.pck']: 'new pck' };
  const w = rootWorker({ [CACHE]: [SITE + 'index.html', SITE + 'index.pck'] }, online);
  // A deep link is the root page; its ?… and #… don't make another cache entry
  assert.equal((await w.run('fetch', GET(SITE + '?play=quadratics&seed=3#x', 'navigate'))).body, 'cached ' + SITE + 'index.html');
  assert.equal((await w.run('fetch', GET(SITE + 'index.pck'))).body, 'cached ' + SITE + 'index.pck');
  assert.deepEqual(w.fetched, []);
  assert.deepEqual(w.state()[CACHE], [SITE + 'index.html', SITE + 'index.pck']);
  // A file the cache lacks comes from the network and is kept; with no network it is an error
  online[SITE + 'index.wasm'] = 'wasm';
  assert.equal((await w.run('fetch', GET(SITE + 'index.wasm'))).body, 'wasm');
  assert.equal(w.body(SITE + 'index.wasm'), 'wasm');
  assert.ok(await w.run('fetch', GET(SITE + 'index.js')) instanceof TypeError);
});

test('the root worker waits behind a worker of ours, and drops an earlier build\'s cache on activation', async () => {
  const files = { [SITE + 'index.pck']: 'pck' };
  const first = rootWorker({}, files);
  await first.run('install');
  assert.deepEqual(first.calls, ['skipWaiting']);
  const next = rootWorker({ 'wasteland-academy-godot-v1': [SITE + 'index.pck'] }, files);
  await next.run('install');
  assert.deepEqual(next.calls, [], 'no skipWaiting while a build of ours is running');
  assert.deepEqual(Object.keys(next.state()).sort(), [CACHE, 'wasteland-academy-godot-v1'].sort());
  await next.run('message', { data: 'skip-waiting' });
  assert.deepEqual(next.calls, ['skipWaiting']);
  await next.run('activate');
  assert.deepEqual(Object.keys(next.state()), [CACHE]);
});

test('the root worker keeps audio.pck once the game fetches it, never at install (#183)', async () => {
  const online = { [SITE + 'index.pck']: 'pck', [SITE + 'audio.pck']: 'audio' };
  const w = rootWorker({}, online);
  await w.run('install');
  assert.deepEqual(w.state()[CACHE], [SITE + 'index.pck']);
  assert.equal((await w.run('fetch', GET(SITE + 'audio.pck'))).body, 'audio');
  assert.equal(w.body(SITE + 'audio.pck'), 'audio');
  delete online[SITE + 'audio.pck'];
  assert.equal((await w.run('fetch', GET(SITE + 'audio.pck'))).body, 'audio');
});

test('the root worker leaves next/ and anything outside the build to the network', async () => {
  const w = rootWorker();
  for (const url of [SITE + 'classic/', SITE + 'classic/index.html', SITE + 'classic/index.pck', SITE + 'next/',
    SITE + 'service-worker.js', SITE + 'manifest.json', 'https://example.com/index.pck']) {
    assert.equal(await w.run('fetch', GET(url, url.endsWith('/') ? 'navigate' : 'no-cors')), undefined, url);
  }
  assert.equal(await w.run('fetch', { request: { method: 'POST', url: SITE + 'index.pck' } }), undefined);
  assert.deepEqual(w.fetched, []);
});
