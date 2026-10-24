// Serve a Web export the way GitHub Pages will (at /wasteland-academy/next/), open it
// in headless Chromium at phone and PC sizes, and save a screenshot of each. Fails if
// the engine doesn't start or the page logs an error.
//
//   node scripts/web-screenshot.mjs [export dir] [out dir] [name=?query ...]
//
// Each name=?query after the out dir is also shot at both sizes, as <size>-<name>.png,
// for example 'graph=?view=fn-quadratic-features/vertex-from-factorised/graph/midpoint-of-roots/value&seed=3'
// (the practice screen's deep links: see game/ui/practice.gd).
//
// Defaults: build/next and _scratch/web-shots. Needs `npm ci` and
// `npx playwright install chromium`. WebGL runs on SwiftShader, so no GPU is used.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from '@playwright/test';

const ROOT = path.resolve(import.meta.dirname, '..');
const dir = path.resolve(process.argv[2] || path.join(ROOT, 'build/next'));
const out = path.resolve(process.argv[3] || path.join(ROOT, '_scratch/web-shots'));
const BASE = '/wasteland-academy/next/';
const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream', '.png': 'image/png' };
const SIZES = [
  { name: 'phone-390x844', viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true },
  { name: 'pc-1280x800', viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1 },
];

const server = http.createServer((req, res) => {
  let u = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  if (!u.startsWith(BASE)) { res.writeHead(404).end(); return; }
  u = u.slice(BASE.length) || 'index.html';
  const fp = path.join(dir, u);
  if (!fp.startsWith(dir + path.sep)) { res.writeHead(404).end(); return; }
  fs.readFile(fp, (err, data) => {
    if (err) { res.writeHead(404).end(); return; }
    res.writeHead(200, { 'content-type': MIME[path.extname(fp)] || 'application/octet-stream' }).end(data);
  });
});
await new Promise(r => server.listen(0, '127.0.0.1', r));
const url = `http://127.0.0.1:${server.address().port}${BASE}`;
const pages = [{ name: '', query: '' }, ...process.argv.slice(4).map(a => {
  const i = a.indexOf('=');
  return { name: a.slice(0, i), query: a.slice(i + 1) };
})];

fs.mkdirSync(out, { recursive: true });
const browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const problems = [];
try {
  for (const shot of pages) {
    for (const size of SIZES) {
      const { name: sizeName, ...options } = size;
      const name = shot.name ? `${sizeName}-${shot.name}` : sizeName;
      const page = await browser.newPage(options);
      page.on('pageerror', e => problems.push(`${name}: page error: ${e.message}`));
      page.on('console', m => {
        if (m.type() === 'error') problems.push(`${name}: console error: ${m.text()}`);
        else if (m.type() === 'warning') console.log(`${name}: console warning: ${m.text()}`);
      });
      await page.goto(url + shot.query);
      // The Godot shell removes its #status overlay once the engine is running.
      await page.waitForFunction(() => !document.getElementById('status'), null, { timeout: 90_000 });
      await page.waitForTimeout(1500);
      const file = path.join(out, `${name}.png`);
      await page.screenshot({ path: file });
      console.log(`ok   ${file}`);
      await page.close();
    }
  }
} catch (e) {
  problems.push(String(e));
} finally {
  await browser.close();
  server.close();
}
if (problems.length) {
  console.error(problems.join('\n'));
  process.exit(1);
}
