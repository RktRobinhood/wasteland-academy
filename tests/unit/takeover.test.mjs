// The takeover switch (README, "Switching to Godot"): scripts/assemble-site.sh lays
// out each position, and the root worker in _takeover/ keeps Godot playable offline
// and clears the old game from the root without touching the HTML game at classic/. tools/takeover-dry-run checks
// the same in a real browser.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { execFileSync, spawnSync } from 'node:child_process';
import { REPO } from '../content/packs.mjs';

const SITE = 'https://rktrobinhood.github.io/wasteland-academy/';
const ASSEMBLE = path.join(REPO, 'scripts/assemble-site.sh');

// A Jekyll site and a Godot export, in a fresh folder under _scratch/
function fixture() {
  fs.mkdirSync(path.join(REPO, '_scratch'), { recursive: true });
  const dir = fs.mkdtempSync(path.join(REPO, '_scratch', 'takeover-unit-'));
  const files = {
    'site/index.html': 'html game', 'site/service-worker.js': 'html worker', 'site/js/engine.js': 'engine',
    'site/manifest.json': read(REPO, 'manifest.json'),
    'export/index.html': '<html>\n<head>\n<meta charset="utf-8">\n<title>godot</title>', 'export/index.pck': 'pck', 'export/index.wasm': 'wasm',
  };
  for (const [rel, text] of Object.entries(files)) {
    fs.mkdirSync(path.dirname(path.join(dir, rel)), { recursive: true });
    fs.writeFileSync(path.join(dir, rel), text);
  }
  return { dir, site: path.join(dir, 'site'), exp: path.join(dir, 'export') };
}

function read(dir, rel) { return fs.readFileSync(path.join(dir, rel), 'utf8'); }

test('switch off: the HTML game at the root, Godot at next/', t => {
  const { dir, site, exp } = fixture();
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  execFileSync(ASSEMBLE, [site, exp, 'off'], { stdio: 'pipe' });
  assert.equal(read(site, 'index.html'), 'html game');
  assert.equal(read(site, 'service-worker.js'), 'html worker');
  assert.equal(read(site, 'next/index.pck'), 'pck');
  assert.equal(fs.existsSync(path.join(site, 'classic')), false);
});

test('switch on: Godot at the root, the HTML game at classic/, next/ a redirect', t => {
  const { dir, site, exp } = fixture();
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  execFileSync(ASSEMBLE, [site, exp, 'on'], { stdio: 'pipe' });
  const html = read(site, 'index.html');
  assert.match(html, /<head>\n<meta name="wa-classic" content="classic\/">\n<meta charset="utf-8">\n<script>/);
  assert.ok(html.includes(read(REPO, '_takeover/register-worker.html')));
  assert.match(html, /<\/script>\n<title>godot/);
  assert.equal(read(site, 'index.pck'), 'pck');
  assert.equal(read(site, 'classic/index.html'), 'html game');
  assert.equal(read(site, 'classic/service-worker.js'), 'html worker');
  assert.equal(read(site, 'classic/js/engine.js'), 'engine');
  assert.equal(read(site, 'service-worker.js'), read(REPO, '_takeover/service-worker.js'));
  assert.equal(read(site, 'next/index.html'), read(REPO, '_takeover/next.html'));
  assert.deepEqual(fs.readdirSync(site).sort(),
    ['classic', 'index.html', 'index.pck', 'index.wasm', 'next', 'service-worker.js']);
});

test('switch on gives the HTML game its own app id, so an installed app stays at the root', t => {
  const { dir, site, exp } = fixture();
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  execFileSync(ASSEMBLE, [site, exp, 'on'], { stdio: 'pipe' });
  const classic = JSON.parse(read(site, 'classic/manifest.json'));
  assert.equal(classic.id, 'wasteland-academy-classic');
  assert.equal(classic.start_url, './index.html');
  assert.equal(classic.scope, './');
  const { id, ...rest } = classic;
  const { id: repoId, ...repoRest } = JSON.parse(read(REPO, 'manifest.json'));
  assert.equal(repoId, 'wasteland-academy');
  assert.deepEqual(rest, repoRest);
});

test('switch off keeps the app id', t => {
  const { dir, site, exp } = fixture();
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  execFileSync(ASSEMBLE, [site, exp, 'off'], { stdio: 'pipe' });
  assert.equal(read(site, 'manifest.json'), read(REPO, 'manifest.json'));
  assert.equal(JSON.parse(read(site, 'manifest.json')).id, 'wasteland-academy');
});

test('switch on stops the build if the HTML game\'s manifest has another id', t => {
  const { dir, site, exp } = fixture();
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  fs.writeFileSync(path.join(site, 'manifest.json'), '{ "id": "something-else" }');
  const run = spawnSync(ASSEMBLE, [site, exp, 'on'], { encoding: 'utf8' });
  assert.notEqual(run.status, 0);
  assert.match(run.stderr, /manifest\.json/);
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
  vm.runInContext(read(REPO, '_takeover/service-worker.js'), ctx);
  const run = async (type, event = {}) => {
    const pending = [];
    let responded;
    listeners[type]({ ...event, waitUntil: p => pending.push(p), respondWith: p => { responded = p; } });
    const result = responded ? await responded.catch(e => e) : undefined;
    await Promise.all(pending);
    return result;
  };
  const state = () => Object.fromEntries([...store].map(([k, v]) => [k, [...v.keys()]]));
  const body = key => { const v = store.get('wasteland-academy-godot')?.get(key); return typeof v === 'string' ? v : v?.body; };
  return { run, state, body, navigated, calls, fetched };
}

const GET = (url, mode = 'no-cors') => ({ request: { method: 'GET', url, mode } });

test('the root worker clears the old game from the root, keeps classic/, and reloads the old pages', async () => {
  const w = rootWorker({
    'wasteland-academy-v3': [SITE, SITE + 'js/engine.js', SITE + 'index.wasm', SITE + 'classic/', SITE + 'classic/js/engine.js'],
    'wasteland-academy-v2': [SITE + 'index.html'],
    'someone-else': [SITE + 'x'],
  });
  await w.run('activate');
  assert.deepEqual(w.state(), {
    'wasteland-academy-v3': [SITE + 'classic/', SITE + 'classic/js/engine.js'],
    'someone-else': [SITE + 'x'],
  });
  assert.deepEqual(w.calls, ['claim']);
  assert.deepEqual(w.navigated, [SITE, SITE + '#functions']);
});

test('the root worker reloads no page when there was no old game to clear', async () => {
  const w = rootWorker({ 'wasteland-academy-v3': [SITE + 'classic/'], 'wasteland-academy-godot': [SITE + 'index.pck'] });
  await w.run('activate');
  assert.deepEqual(w.state(), { 'wasteland-academy-v3': [SITE + 'classic/'], 'wasteland-academy-godot': [SITE + 'index.pck'] });
  assert.deepEqual(w.navigated, []);
  assert.deepEqual(w.calls, ['claim']);
});

test('the root worker\'s install copies the Godot build, skipping a file the export lacks', async () => {
  const files = ['index.html', 'index.js', 'index.wasm', 'index.pck', 'index.audio.worklet.js'];
  const w = rootWorker({}, Object.fromEntries(files.map(f => [SITE + f, f])));
  await w.run('install');
  assert.deepEqual(w.state()['wasteland-academy-godot'].sort(), files.map(f => SITE + f).sort());
  assert.deepEqual(w.calls, ['skipWaiting']);
});

test('the root worker is network-first: online gets the new export, offline the cached one', async () => {
  const online = { [SITE]: 'new html', [SITE + 'index.pck']: 'new pck' };
  const w = rootWorker({ 'wasteland-academy-godot': [SITE + 'index.html', SITE + 'index.pck'] }, online);
  // A deep link is the root page; its ?… and #… don't make another cache entry
  assert.equal((await w.run('fetch', GET(SITE + '?play=quadratics&seed=3#x', 'navigate'))).body, 'new html');
  assert.equal((await w.run('fetch', GET(SITE + 'index.pck'))).body, 'new pck');
  assert.equal(w.body(SITE + 'index.html'), 'new html');
  assert.equal(w.body(SITE + 'index.pck'), 'new pck');
  assert.deepEqual(w.state()['wasteland-academy-godot'], [SITE + 'index.html', SITE + 'index.pck']);

  for (const k of Object.keys(online)) delete online[k];
  assert.equal((await w.run('fetch', GET(SITE + '?explore', 'navigate'))).body, 'new html');
  assert.equal((await w.run('fetch', GET(SITE + 'index.pck'))).body, 'new pck');
  // Offline with nothing cached is a network error, as with no worker
  assert.ok(await w.run('fetch', GET(SITE + 'index.wasm')) instanceof TypeError);
});

test('the root worker leaves classic/, next/ and anything outside the build to the network', async () => {
  const w = rootWorker();
  for (const url of [SITE + 'classic/', SITE + 'classic/index.html', SITE + 'classic/index.pck', SITE + 'next/',
    SITE + 'service-worker.js', SITE + 'manifest.json', 'https://example.com/index.pck']) {
    assert.equal(await w.run('fetch', GET(url, url.endsWith('/') ? 'navigate' : 'no-cors')), undefined, url);
  }
  assert.equal(await w.run('fetch', { request: { method: 'POST', url: SITE + 'index.pck' } }), undefined);
  assert.deepEqual(w.fetched, []);
});
