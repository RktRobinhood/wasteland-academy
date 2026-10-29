// The takeover switch (README, "Switching to Godot"): scripts/assemble-site.sh lays
// out each position, and the retiring worker in _takeover/ clears the old game from
// the root without touching the HTML game at classic/. tools/takeover-dry-run checks
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
    'export/index.html': '<html>\n<head>\n<title>godot</title>', 'export/index.pck': 'pck', 'export/index.wasm': 'wasm',
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
  assert.match(read(site, 'index.html'), /<head>\n<meta name="wa-classic" content="classic\/">\n<title>godot/);
  assert.equal(read(site, 'index.pck'), 'pck');
  assert.equal(read(site, 'classic/index.html'), 'html game');
  assert.equal(read(site, 'classic/service-worker.js'), 'html worker');
  assert.equal(read(site, 'classic/js/engine.js'), 'engine');
  assert.equal(read(site, 'service-worker.js'), read(REPO, '_takeover/service-worker.js'));
  assert.equal(read(site, 'next/index.html'), read(REPO, '_takeover/next.html'));
  assert.deepEqual(fs.readdirSync(site).sort(),
    ['classic', 'index.html', 'index.pck', 'index.wasm', 'next', 'service-worker.js']);
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

// Runs the retiring worker's install and activate with stub caches and clients
async function retire(cached) {
  const listeners = {};
  const store = new Map(Object.entries(cached).map(([k, urls]) => [k, new Set(urls)]));
  const navigated = [];
  const calls = [];
  const ctx = vm.createContext({
    URL,
    self: {
      location: new URL('service-worker.js', SITE),
      addEventListener: (type, fn) => { listeners[type] = fn; },
      skipWaiting: () => calls.push('skipWaiting'),
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
      open: async key => ({
        keys: async () => [...store.get(key)].map(url => ({ url })),
        delete: async r => store.get(key).delete(r.url),
      }),
      delete: async key => store.delete(key),
    },
  });
  vm.runInContext(read(REPO, '_takeover/service-worker.js'), ctx);
  listeners.install({});
  let done;
  listeners.activate({ waitUntil: p => { done = p; } });
  await done;
  return { store: Object.fromEntries([...store].map(([k, v]) => [k, [...v]])), navigated, calls };
}

test('the retiring worker clears the old game from the root and keeps classic/', async () => {
  const { store, navigated, calls } = await retire({
    'wasteland-academy-v3': [SITE, SITE + 'js/engine.js', SITE + 'index.wasm', SITE + 'classic/', SITE + 'classic/js/engine.js'],
    'wasteland-academy-v2': [SITE + 'index.html'],
    'someone-else': [SITE + 'x'],
  });
  assert.deepEqual(store, {
    'wasteland-academy-v3': [SITE + 'classic/', SITE + 'classic/js/engine.js'],
    'someone-else': [SITE + 'x'],
  });
  assert.deepEqual(calls, ['skipWaiting', 'claim', 'unregister']);
  assert.deepEqual(navigated, [SITE, SITE + '#functions']);
});

test('the retiring worker has no fetch handler, so the root goes to the network', () => {
  assert.doesNotMatch(read(REPO, '_takeover/service-worker.js'), /addEventListener\('fetch'/);
});
