// The root service worker with the takeover switch on (README, "Switching to Godot").
// scripts/assemble-site.sh puts this file at the site root in place of the HTML game's
// service-worker.js, and registers it from the Godot index.html. Jekyll skips
// _takeover/, so with the switch off it isn't published at all.
//
// It does two jobs:
//
// 1. Godot plays offline after one visit (SPEC: "Practice must continue to work
//    offline"). The question catalogue is inside index.pck, so the files below are all
//    a run needs. Files are network-first, revalidated with the server each time, so a
//    player who is online always gets the latest export and never a mix of two. The
//    cache is only the offline fallback. Install copies the files the page has just
//    loaded, mostly from the HTTP cache, so the first visit doesn't fetch them twice.
//
// 2. A browser that played the HTML game at the root still has that game's worker
//    there. On the next visit the browser fetches this file as that worker's update.
//    On activation it drops the HTML game's caches, at the root and those of the
//    classic/ copy that is no longer published (#197), and reloads the pages it now
//    controls, so they come up as Godot. register-worker.html unregisters the
//    classic/ worker.
const CACHE_NAME = 'wasteland-academy-godot';

// The Web export's files (game/export_presets.cfg, ./export.sh). The takeover dry run
// checks this covers everything the export writes (tests/takeover/takeover.spec.mjs).
const BUILD = [
  'index.html',
  'index.js',
  'index.wasm',
  'index.pck',
  'index.audio.worklet.js',
  'index.audio.position.worklet.js',
  'index.png',
  'index.icon.png',
  'index.apple-touch-icon.png',
  'share-card.png',
].map(f => new URL(f, self.location).href);
const ROOT = new URL('./', self.location).href;

self.addEventListener('install', event => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    // One at a time, and a file the export doesn't have doesn't stop the rest
    for (const url of BUILD) {
      try {
        const response = await fetch(url);
        if (response.ok) await cache.put(url, response);
      } catch { /* offline, or the file is gone: the next online visit fills it in */ }
    }
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    // The HTML game names its caches wasteland-academy-v<n>, at the root and at classic/
    let retired = false;
    for (const key of await caches.keys()) {
      if (/^wasteland-academy-v\d+$/.test(key)) { await caches.delete(key); retired = true; }
    }
    await self.clients.claim();
    // A page the old worker served may be the old game, from its cache
    if (retired) {
      for (const client of await self.clients.matchAll({ type: 'window' })) client.navigate(client.url);
    }
  })());
});

self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  url.search = url.hash = '';
  // The root page, whatever its ?… (deep links) and #… (map links), is index.html
  const key = url.href === ROOT ? ROOT + 'index.html' : url.href;
  // Anything else, next/ included, goes straight to the network
  if (BUILD.includes(key)) event.respondWith(networkFirst(event, key));
});

async function networkFirst(event, key) {
  const { request } = event;
  const cache = await caches.open(CACHE_NAME);
  try {
    // Every file revalidates with the server instead of trusting the HTTP cache (GitHub
    // Pages sends max-age=600), the page too, or a new index.pck could meet the last
    // deploy's index.js. A navigation can't be copied with a RequestInit, so it's
    // fetched by URL, and as itself if that ends in a redirect, which it can't answer.
    let response;
    if (request.mode === 'navigate') {
      response = await fetch(request.url, { cache: 'no-cache' });
      if (response.redirected) return fetch(request);
    } else {
      response = await fetch(new Request(request, { cache: 'no-cache' }));
    }
    // Written while the page reads its copy, so the progress bar isn't held up
    if (response.ok) event.waitUntil(keep(cache, key, response.clone()));
    return response;
  } catch (err) {
    const cached = await cache.match(key);
    if (cached) return cached;
    throw err;
  }
}

// index.pck is about 50 MB: don't write it again when the deploy hasn't changed it
async function keep(cache, key, response) {
  const cached = await cache.match(key);
  const etag = response.headers.get('etag');
  if (cached && etag && cached.headers.get('etag') === etag) return;
  await cache.put(key, response);
}
