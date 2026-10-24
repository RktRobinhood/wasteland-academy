// The service worker sits at the site root, so its scope covers the Godot build at
// next/ too. It must leave next/ and classic/ alone: the Godot .wasm and .pck don't
// belong in the HTML game's cache, and an offline visit to next/ must not get the
// HTML game's index.html.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { REPO } from '../content/packs.mjs';

const SITE = 'https://rktrobinhood.github.io/wasteland-academy/';

// Runs service-worker.js with a stub `self` at the Pages path, and returns its fetch
// handler as url -> whether the worker answered the request itself.
function worker() {
  const listeners = {};
  const cache = { match: async () => undefined, put: async () => {} };
  const ctx = vm.createContext({
    self: { location: new URL('service-worker.js', SITE), addEventListener: (type, fn) => { listeners[type] = fn; } },
    URL, Request: class { constructor(r) { Object.assign(this, r); } }, Response: class {},
    caches: { open: async () => cache },
    fetch: async () => ({ ok: false }),
  });
  vm.runInContext(fs.readFileSync(path.join(REPO, 'service-worker.js'), 'utf8'), ctx);
  return (url, mode = 'no-cors') => {
    let answered = false;
    listeners.fetch({ request: { method: 'GET', url, mode }, respondWith: p => { answered = true; return p; } });
    return answered;
  };
}

test('next/ and classic/ requests go straight to the network', () => {
  const handles = worker();
  for (const rel of ['next', 'next/', 'next/index.html', 'next/index.wasm', 'next/index.pck', 'next/index.js?v=2',
    'classic', 'classic/', 'classic/index.html', 'classic/js/engine.js']) {
    assert.equal(handles(SITE + rel), false, rel);
    assert.equal(handles(SITE + rel, 'navigate'), false, `${rel} (navigation)`);
  }
});

test('the HTML game is still served by the worker, including look-alike paths', () => {
  const handles = worker();
  for (const rel of ['', 'index.html', 'js/engine.js', 'assets/icons/icon-192.png', 'nextlevel.html',
    'assets/next/x.png', 'classical/x.js']) {
    assert.equal(handles(SITE + rel), true, rel);
  }
  assert.equal(handles(SITE, 'navigate'), true, 'navigation to the root');
});

test('other hosts are still left to the network', () => {
  assert.equal(worker()('https://example.com/next/index.wasm'), false);
});
