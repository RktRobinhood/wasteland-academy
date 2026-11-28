import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';

const source = readFileSync(new URL('../../_takeover/service-worker.js', import.meta.url), 'utf8');
const BASE = 'https://example.test/wasteland-academy/';
const name = (id) => 'wasteland-academy-godot-' + id;

function worker(id, { installed = true, retired = false } = {}) {
  const handlers = new Map();
  let claimed = false;
  const keys = new Set(installed ? [name(id)] : []);
  if (retired) keys.add(name('old'));
  const stored = new Map();
  const opened = [];
  const self = {
    location: BASE + 'service-worker.js',
    addEventListener: (type, fn) => handlers.set(type, fn),
    skipWaiting: () => Promise.resolve('requested'),
    clients: { async claim() { claimed = true; }, async matchAll() { return []; } },
  };
  const caches = {
    async keys() { return [...keys]; },
    async delete(key) {
      keys.delete(key);
      // An in-flight request from the prior controller reopens the old cache
      // if deletion happens while it can still receive fetches.
      if (!claimed && key === name('old')) keys.add(key);
      return true;
    },
    async has(key) { return keys.has(key); },
    async match(key, { cacheName }) { return stored.get(cacheName + key); },
    async open(key) {
      keys.add(key);
      opened.push(key);
      return {
        async match(url) { return stored.get(key + url); },
        async put(url, response) { stored.set(key + url, response); },
      };
    },
  };
  runInNewContext(source.replace('__BUILD_ID__', id), {
    self, caches, URL, Request, fetch: async () => new Response('real network fallback', { status: 200 }),
  });
  function dispatch(type, init = {}) {
    const pending = [];
    let responded;
    handlers.get(type)({
      ...init, waitUntil: (promise) => pending.push(promise),
      respondWith: (promise) => { responded = promise; },
    });
    return { pending, get response() { return responded; } };
  }
  return { dispatch, keys, opened, stored };
}

test('activate takes control before deleting the previous cache', async () => {
  const w = worker('new', { retired: true });
  await Promise.all(w.dispatch('activate').pending);
  assert.deepEqual([...w.keys], [name('new')]);
});

test('skip-waiting remains alive until the request completes', async () => {
  const w = worker('new');
  const event = w.dispatch('message', { data: 'skip-waiting' });
  assert.equal(event.pending.length, 1);
  assert.deepEqual(await Promise.all(event.pending), ['requested']);
});

test('a late request from a retired worker does not recreate the deleted cache', async () => {
  const w = worker('old', { installed: false });
  const event = w.dispatch('fetch', { request: new Request(BASE + 'audio.pck') });
  assert.equal(await (await event.response).text(), 'real network fallback');
  await Promise.all(event.pending);
  assert.deepEqual([...w.keys], []);
  assert.deepEqual(w.opened, []);
});

test('the current worker still caches optional network assets for offline use', async () => {
  const w = worker('new');
  const url = BASE + 'audio.pck';
  const first = w.dispatch('fetch', { request: new Request(url) });
  assert.equal(await (await first.response).text(), 'real network fallback');
  await Promise.all(first.pending);
  assert.ok(w.stored.has(name('new') + url));
  const hit = w.dispatch('fetch', { request: new Request(url) });
  assert.equal(await (await hit.response).text(), 'real network fallback');
});
