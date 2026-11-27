// The root service worker with the takeover switch on (README, "Switching to Godot").
// scripts/assemble-site.sh puts this file at the site root in place of the HTML game's
// service-worker.js, and registers it from the Godot index.html. Jekyll skips
// _takeover/, so with the switch off it isn't published at all.
//
// It does two jobs:
//
// 1. Godot plays offline after one visit (SPEC: "Practice must continue to work
//    offline"), and a class stays on one build (#184). The question catalogue is inside
//    index.pck, so the files below are all a run needs. The worker is cache first: a
//    page loads from the copy of its own build and never waits on the network. The cache
//    is named for the build (BUILD_ID, written by scripts/assemble-site.sh), so the files
//    of two builds are never mixed. A new build changes this file, so the browser
//    fetches it in the background, the new worker downloads its build into its own cache,
//    and it takes over only when no page is open on the old build (or on the first
//    visit). That also keeps a student's page on one build for a whole lesson.
//
// 2. A browser that played the HTML game at the root still has that game's worker
//    there. On the next visit the browser fetches this file as that worker's update.
//    On activation it drops the HTML game's caches, at the root and those of the
//    classic/ copy that is no longer published (#197), and reloads the pages it now
//    controls, so they come up as Godot. register-worker.html unregisters the
//    classic/ worker.
// Replaced with the build id (scripts/build-id.sh) when the site is assembled
const BUILD_ID = '__BUILD_ID__';
const CACHE_PREFIX = 'wasteland-academy-godot';
const CACHE_NAME = CACHE_PREFIX + '-' + BUILD_ID;

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
// The music and voice lines (#183): fetched by the game only once sound is on, so not
// at install. Kept like the files above once fetched, so sound works offline too.
// Only this build’s six exact optional artworks; never prefetched and never
// replace another deployment’s /preview/ resources.
const WIDE_MAP_ART = ['overworld', 'algebra', 'functions', 'geometry', 'stats', 'calculus']
  .map(key => new URL('map-art/' + encodeURIComponent(BUILD_ID) + '/' + key + '.webp', self.location).href);
const ON_DEMAND = [new URL('audio.pck', self.location).href, ...WIDE_MAP_ART];
const ROOT = new URL('./', self.location).href;

self.addEventListener('install', event => {
  event.waitUntil((async () => {
    // A worker of ours is already running: wait behind it, so the pages open on that
    // build aren't switched mid-lesson. A first visit, or the HTML game's worker, goes on.
    const mine = (await caches.keys()).some(key => key.startsWith(CACHE_PREFIX));
    const cache = await caches.open(CACHE_NAME);
    // One at a time, and a file the export doesn't have doesn't stop the rest. Straight
    // from the server, not the HTTP cache (GitHub Pages sends max-age=600), so the copy is
    // this deploy's.
    for (const url of BUILD) {
      try {
        const response = await fetch(url, { cache: 'no-cache' });
        if (response.ok) await cache.put(url, response);
      } catch { /* offline, or the file is gone: the next online visit fills it in */ }
    }
    if (!mine) await self.skipWaiting();
  })());
});

// A page can ask a waiting worker to take over now
self.addEventListener('message', event => {
  if (event.data === 'skip-waiting') self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    // The HTML game names its caches wasteland-academy-v<n>, at the root and at classic/.
    // An earlier build's cache of ours goes too.
    let retired = false;
    for (const key of await caches.keys()) {
      if (/^wasteland-academy-v\d+$/.test(key)) { await caches.delete(key); retired = true; }
      else if (key.startsWith(CACHE_PREFIX) && key !== CACHE_NAME) await caches.delete(key);
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
  if (BUILD.includes(key) || ON_DEMAND.includes(key)) event.respondWith(cacheFirst(event, key));
});

// The copy of this build if there is one. Otherwise the network, and the answer is kept:
// audio.pck once sound is on, or a file the install missed. A navigation can't be copied
// with a RequestInit, so it is fetched by URL, and as itself if that ends in a redirect,
// which it can't answer.
async function cacheFirst(event, key) {
  const { request } = event;
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(key);
  if (cached) return cached;
  let response;
  if (request.mode === 'navigate') {
    response = await fetch(request.url, { cache: 'no-cache' });
    if (response.redirected) return fetch(request);
  } else {
    response = await fetch(new Request(request, { cache: 'no-cache' }));
  }
  const type = (response.headers.get('content-type') || '').split(';')[0].trim().toLowerCase();
  if (response.ok && (!WIDE_MAP_ART.includes(key) || type === 'image/webp')) {
    event.waitUntil(cache.put(key, response.clone()));
  }
  return response;
}
