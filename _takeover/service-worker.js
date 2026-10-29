// The HTML game's service worker, retired. With the takeover switch on (README,
// "Switching to Godot"), scripts/assemble-site.sh puts this file at the site root in
// place of the HTML game's service-worker.js. Jekyll skips _takeover/, so with the
// switch off it isn't published at all.
//
// A browser that played the HTML game at the root still has its worker there. On the
// next visit the browser fetches this file as that worker's update and runs it once:
// it drops the old game's cached files, unregisters, and reloads the pages it
// controlled, so the root ends up as the Godot build with no worker. The HTML game at
// classic/ registers its own worker there, and its cached files are kept.
const CLASSIC = new URL('classic/', self.location).href;

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    // The HTML game names its caches wasteland-academy-v<n>, at the root and at classic/
    for (const key of await caches.keys()) {
      if (!key.startsWith('wasteland-academy')) continue;
      const cache = await caches.open(key);
      for (const request of await cache.keys()) {
        if (!request.url.startsWith(CLASSIC)) await cache.delete(request);
      }
      if ((await cache.keys()).length === 0) await caches.delete(key);
    }
    await self.clients.claim();
    await self.registration.unregister();
    // A page this worker controls may be the old game, served from its cache
    for (const client of await self.clients.matchAll({ type: 'window' })) {
      if (!client.url.startsWith(CLASSIC)) client.navigate(client.url);
    }
  })());
});
