// Same-origin files (code, CSS, content, art) are network-first, so a returning
// player who is online always gets the latest deploy with no version bump.
// The cache is only the offline fallback. Versioned CDN files (KaTeX, fonts)
// never change under the same URL, so they are cache-first.
const CACHE_NAME = 'wasteland-academy-v2';

// Everything index.html loads, so the game boots offline after one visit
const PRECACHE_LOCAL = [
  './',
  './index.html',
  './manifest.json',
  './css/tokens.css',
  './css/base.css',
  './css/screens.css',
  './css/combat.css',
  './js/katex-render.js',
  './js/spaced-rep.js',
  './js/question-gen.js',
  './js/stats.js',
  './js/engine.js',
  './js/router.js',
  './js/combat.js',
  './js/pwa.js',
  './content/topic-1-algebra.js',
  './content/topic-2-functions.js',
  './content/topic-3-geometry.js',
  './content/topic-4-stats.js',
  './content/topic-5-calculus.js',
];

// Best-effort: a CDN outage must not stop the worker installing
const PRECACHE_REMOTE = [
  'https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.16.9/katex.min.css',
  'https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.16.9/katex.min.js',
  'https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.16.9/contrib/auto-render.min.js',
  'https://fonts.googleapis.com/css2?family=Bangers&family=Share+Tech+Mono&display=swap',
  'https://fonts.googleapis.com/css2?family=Bangers&family=Share+Tech+Mono:wght@400&display=swap',
];

const CDN_HOSTS = ['cdnjs.cloudflare.com', 'fonts.googleapis.com', 'fonts.gstatic.com'];

function offlineResponse() {
  return new Response('Offline', { status: 503, statusText: 'Offline', headers: { 'Content-Type': 'text/plain' } });
}

// ── Install ───────────────────────────────────────────────────
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache =>
      // cache:'reload' skips the HTTP cache, so we never precache a stale copy
      cache.addAll(PRECACHE_LOCAL.map(url => new Request(url, { cache: 'reload' }))).then(() =>
        Promise.allSettled(PRECACHE_REMOTE.map(url =>
          fetch(url).then(r => r.ok ? cache.put(url, r) : null)
        ))
      )
    ).then(() => self.skipWaiting())
  );
});

// ── Activate — delete old caches ──────────────────────────────
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// ── Fetch ─────────────────────────────────────────────────────
self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (!url.protocol.startsWith('http')) return;

  if (url.origin === self.location.origin) {
    event.respondWith(networkFirst(request));
  } else if (CDN_HOSTS.includes(url.hostname)) {
    event.respondWith(cacheFirst(request));
  }
  // Anything else goes straight to the network
});

async function networkFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  try {
    // Navigations can't take a RequestInit. Everything else revalidates with the
    // server instead of trusting the HTTP cache (GitHub Pages sends max-age=600).
    const response = await fetch(request.mode === 'navigate' ? request : new Request(request, { cache: 'no-cache' }));
    if (response.ok) cache.put(request, response.clone()).catch(() => {});
    return response;
  } catch (err) {
    const cached = await cache.match(request, { ignoreSearch: request.mode === 'navigate' });
    if (cached) return cached;
    if (request.mode === 'navigate') {
      const shell = await cache.match('./index.html');
      if (shell) return shell;
    }
    return offlineResponse();
  }
}

async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);
  if (cached) return cached;
  try {
    const response = await fetch(request);
    // Opaque = a no-cors <link>/<script>; we can't read its status, but it's still usable
    if (response.ok || response.type === 'opaque') cache.put(request, response.clone()).catch(() => {});
    return response;
  } catch (err) {
    return offlineResponse();
  }
}
