const CACHE_NAME = 'wasteland-academy-v1';

// Assets to pre-cache on install
const PRECACHE_URLS = [
  './',
  './index.html',
  './manifest.json',
  './css/tokens.css',
  './css/base.css',
  './css/screens.css',
  './css/combat.css',
  './js/engine.js',
  './js/router.js',
  './js/combat.js',
  './js/spaced-rep.js',
  './js/stats.js',
  './js/katex-render.js',
  './js/pwa.js',
  './content/topic-1-algebra.js',
  // KaTeX from CDN — graceful cache
  'https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.16.9/katex.min.css',
  'https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.16.9/katex.min.js',
  'https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.16.9/contrib/auto-render.min.js',
  // Google Fonts — best-effort cache (may be blocked in some regions)
  'https://fonts.googleapis.com/css2?family=Bangers&family=Share+Tech+Mono&display=swap',
];

// ── Install ───────────────────────────────────────────────────
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      // Cache local assets strictly, CDN assets best-effort
      const local  = PRECACHE_URLS.filter(u => !u.startsWith('http'));
      const remote = PRECACHE_URLS.filter(u => u.startsWith('http'));

      return cache.addAll(local).then(() =>
        Promise.allSettled(remote.map(url =>
          fetch(url).then(r => r.ok ? cache.put(url, r) : null).catch(() => null)
        ))
      );
    }).then(() => self.skipWaiting())
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

// ── Fetch — cache-first for assets, network-first for HTML ────
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  // Skip non-GET
  if (event.request.method !== 'GET') return;

  // Skip chrome-extension and other non-http(s)
  if (!url.protocol.startsWith('http')) return;

  // HTML navigation → network-first with cache fallback
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request)
        .then(response => {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
          return response;
        })
        .catch(() => caches.match('./index.html'))
    );
    return;
  }

  // Everything else → cache-first with network fallback
  event.respondWith(
    caches.match(event.request).then(cached => {
      if (cached) return cached;
      return fetch(event.request).then(response => {
        if (!response || response.status !== 200 || response.type === 'error') return response;
        const clone = response.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
        return response;
      }).catch(() => null);
    })
  );
});
