// In-process static server for the browser tests. It serves the repo as-is at
// both / and /wasteland-academy/ (the GitHub Pages path), and has switches the
// service-worker test uses to fake a redeploy and to go offline.
// Seeded from the FAL-205 audit harness.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

export const REPO = path.resolve(import.meta.dirname, '../..');
export const BASE_PATH = '/wasteland-academy/';

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json',
  '.png': 'image/png',
  '.woff2': 'font/woff2',
};

// Never serve tooling or dev files, only what Pages would publish
const HIDDEN = /^(\.git|node_modules|_scratch|tests|test-results|playwright-report)(\/|$)/;

export async function startServer() {
  const state = {
    offline: false,
    // path (relative to the site root) -> function(buffer) returning a new body
    overrides: new Map(),
    requests: [],
  };
  const sockets = new Set();

  const server = http.createServer((req, res) => {
    if (state.offline) { req.socket.destroy(); return; }
    let u = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    if (u.startsWith(BASE_PATH)) u = u.slice(BASE_PATH.length - 1);
    if (u.endsWith('/')) u += 'index.html';
    const rel = u.replace(/^\/+/, '');
    state.requests.push(rel);

    const send = (code, body, type = 'text/plain') => {
      res.writeHead(code, { 'content-type': type, 'cache-control': 'max-age=600' });
      res.end(body);
    };
    const fp = path.join(REPO, rel);
    if (HIDDEN.test(rel) || !fp.startsWith(REPO + path.sep)) return send(404, 'not found');
    fs.readFile(fp, (err, data) => {
      if (err) return send(404, 'not found');
      const override = state.overrides.get(rel);
      send(200, override ? override(data) : data, MIME[path.extname(fp)] || 'application/octet-stream');
    });
  });
  server.on('connection', s => { sockets.add(s); s.on('close', () => sockets.delete(s)); });

  await new Promise(r => server.listen(0, '127.0.0.1', r));
  const origin = `http://127.0.0.1:${server.address().port}`;

  return {
    state,
    origin,
    url: origin + BASE_PATH,
    setOffline(v) {
      state.offline = v;
      if (v) for (const s of sockets) s.destroy();
    },
    close() {
      for (const s of sockets) s.destroy();
      return new Promise(r => server.close(r));
    },
  };
}
