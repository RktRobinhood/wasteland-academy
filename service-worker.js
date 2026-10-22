// Every file is same-origin: KaTeX and the fonts are vendored (vendor/), so
// nothing is fetched from another host. Files are network-first, so a returning
// player who is online always gets the latest deploy with no version bump. The
// cache is only the offline fallback.
const CACHE_NAME = 'wasteland-academy-v3';

// Everything a run needs, so the whole game plays offline after one visit.
// tests/unit/offline.test.mjs checks this covers index.html, vendor/ and the icons.
const PRECACHE = [
  './',
  './index.html',
  './manifest.json',
  './assets/icons/favicon-32.png',
  './assets/icons/icon-192.png',
  './assets/icons/icon-512.png',
  './css/tokens.css',
  './css/base.css',
  './css/screens.css',
  './css/combat.css',
  './js/platform.js',
  './js/art.js',
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
  './vendor/fonts/bangers-latin-ext.woff2',
  './vendor/fonts/bangers-latin.woff2',
  './vendor/fonts/bangers-vietnamese.woff2',
  './vendor/fonts/fonts.css',
  './vendor/fonts/share-tech-mono-latin.woff2',
  './vendor/katex/contrib/auto-render.min.js',
  './vendor/katex/fonts/KaTeX_AMS-Regular.woff2',
  './vendor/katex/fonts/KaTeX_Caligraphic-Bold.woff2',
  './vendor/katex/fonts/KaTeX_Caligraphic-Regular.woff2',
  './vendor/katex/fonts/KaTeX_Fraktur-Bold.woff2',
  './vendor/katex/fonts/KaTeX_Fraktur-Regular.woff2',
  './vendor/katex/fonts/KaTeX_Main-Bold.woff2',
  './vendor/katex/fonts/KaTeX_Main-BoldItalic.woff2',
  './vendor/katex/fonts/KaTeX_Main-Italic.woff2',
  './vendor/katex/fonts/KaTeX_Main-Regular.woff2',
  './vendor/katex/fonts/KaTeX_Math-BoldItalic.woff2',
  './vendor/katex/fonts/KaTeX_Math-Italic.woff2',
  './vendor/katex/fonts/KaTeX_SansSerif-Bold.woff2',
  './vendor/katex/fonts/KaTeX_SansSerif-Italic.woff2',
  './vendor/katex/fonts/KaTeX_SansSerif-Regular.woff2',
  './vendor/katex/fonts/KaTeX_Script-Regular.woff2',
  './vendor/katex/fonts/KaTeX_Size1-Regular.woff2',
  './vendor/katex/fonts/KaTeX_Size2-Regular.woff2',
  './vendor/katex/fonts/KaTeX_Size3-Regular.woff2',
  './vendor/katex/fonts/KaTeX_Size4-Regular.woff2',
  './vendor/katex/fonts/KaTeX_Typewriter-Regular.woff2',
  './vendor/katex/katex.min.css',
  './vendor/katex/katex.min.js',
];

function offlineResponse() {
  return new Response('Offline', { status: 503, statusText: 'Offline', headers: { 'Content-Type': 'text/plain' } });
}

// ── Install ───────────────────────────────────────────────────
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache =>
      // cache:'reload' skips the HTTP cache, so we never precache a stale copy
      cache.addAll(PRECACHE.map(url => new Request(url, { cache: 'reload' })))
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

  if (url.origin === self.location.origin) event.respondWith(networkFirst(request));
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
