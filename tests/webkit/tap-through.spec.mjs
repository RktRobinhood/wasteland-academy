// The Godot web export on an iPhone (FAL-1042, #187): from the title to the summary by
// real touch taps, a reload that keeps the save, and a question clock that holds while
// the tab is hidden. Serves build/next (./export.sh) the way Pages does, at
// /wasteland-academy/next/.
//
// The game is one canvas, so taps are at fixed points of the 390x844 screen. The wall
// clock is pinned: a run's seed comes from it, so the first question is always the same
// one (a table, d = (101 - 53) / (16 - 10) = 8). A layout change moves these points and
// fails the test: read the screenshot in test-results/webkit, and move them.
import { test, expect } from '@playwright/test';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '../..');
const DIR = path.resolve(process.env.WA_BUILD || path.join(ROOT, 'build/next'));
const BASE = '/wasteland-academy/next/';
const PINNED_CLOCK = 1700000000000;
const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream', '.png': 'image/png' };

// The points to tap, in CSS pixels on a 390x844 screen.
const TAP = {
  play: [72, 773],
  courseAaSl: [195, 180],
  courseContinue: [195, 749],
  scrapFields: [86, 325],
  sequences: [94, 607],
  startRun: [195, 414],
  skipCards: [188, 293],
  keyEight: [46, 680],
  lockIn: [195, 764],
  quit: [260, 22],
  playAgain: [195, 293],
};
// The timer's seconds, over the bar's right end on the fight screen.
const TIMER = { x: 300, y: 280, width: 50, height: 24 };

let server, url;
test.beforeAll(async () => {
  server = http.createServer((req, res) => {
    let u = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    if (!u.startsWith(BASE)) return res.writeHead(404).end();
    const fp = path.join(DIR, u.slice(BASE.length) || 'index.html');
    if (!fp.startsWith(DIR + path.sep)) return res.writeHead(404).end();
    fs.readFile(fp, (err, data) => {
      if (err) return res.writeHead(404).end();
      res.writeHead(200, { 'content-type': MIME[path.extname(fp)] || 'application/octet-stream' }).end(data);
    });
  });
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  url = `http://127.0.0.1:${server.address().port}${BASE}`;
});
test.afterAll(() => server.close());

async function boot(page, problems) {
  page.on('pageerror', e => problems.push(`page error: ${e.message}`));
  page.on('console', m => { if (m.type() === 'error') problems.push(`console error: ${m.text()}`); });
  await page.clock.setFixedTime(PINNED_CLOCK);
  await page.goto(url);
  // The Godot shell removes its #status overlay once the engine is running.
  await page.waitForFunction(() => !document.getElementById('status'), null, { timeout: 120_000 });
  await page.waitForTimeout(2500);
}

async function tap(page, point) {
  await page.touchscreen.tap(...point);
  await page.waitForTimeout(1500);
}

// The save file from the browser's IndexedDB, which is where Godot's user:// lives.
async function savedGame(page) {
  const text = await page.evaluate(() => new Promise((resolve, reject) => {
    const open = indexedDB.open('/userfs');
    open.onerror = () => reject(open.error);
    open.onsuccess = () => {
      const get = open.result.transaction('FILE_DATA').objectStore('FILE_DATA')
        .get('/userfs/godot/app_userdata/Wasteland Academy/save.json');
      get.onerror = () => reject(get.error);
      get.onsuccess = () => resolve(get.result ? new TextDecoder().decode(get.result.contents) : null);
    };
  }));
  return text ? JSON.parse(text) : null;
}

// The clock is pinned while the run starts (its seed comes from it), then let go: the
// browser keeps a file only when it is newer than the one it has, so a pinned clock would
// keep every later save out of IndexedDB.
async function toFirstQuestion(page) {
  for (const point of [TAP.play, TAP.courseAaSl, TAP.courseContinue, TAP.scrapFields, TAP.scrapFields,
    TAP.sequences, TAP.sequences, TAP.startRun, TAP.skipCards]) {
    await tap(page, point);
  }
  await page.clock.setSystemTime(new Date());
}

const timerShot = page => page.screenshot({ clip: TIMER });

async function setVisibility(page, hidden) {
  await page.evaluate(h => {
    Object.defineProperty(document, 'hidden', { value: h, configurable: true });
    Object.defineProperty(document, 'visibilityState', { value: h ? 'hidden' : 'visible', configurable: true });
    document.dispatchEvent(new Event('visibilitychange'));
    window.dispatchEvent(new Event(h ? 'blur' : 'focus'));
  }, hidden);
}

test('taps from the title to the summary, and the save survives a reload', async ({ page }) => {
  const problems = [];
  await boot(page, problems);
  expect(await savedGame(page)).toBeNull();

  await toFirstQuestion(page);
  await tap(page, TAP.keyEight);
  await tap(page, TAP.lockIn);
  await page.screenshot({ path: path.join(ROOT, 'test-results/webkit/after-answer.png') });

  await tap(page, TAP.quit);
  await page.screenshot({ path: path.join(ROOT, 'test-results/webkit/summary.png') });
  // The browser writes the save to IndexedDB a moment after the game does.
  await expect.poll(async () => (await savedGame(page))?.scrap ?? 0).toBe(30);
  const before = await savedGame(page);
  expect(before.course).toBe('aa-sl');
  expect(before.intro.cards).toBe(true);

  await page.reload();
  await page.waitForFunction(() => !document.getElementById('status'), null, { timeout: 120_000 });
  await page.waitForTimeout(2500);
  const after = await savedGame(page);
  expect(after.course).toBe('aa-sl');
  expect(after.scrap).toBe(30);

  // The title still opens on the map, not the course question: it is not asked twice.
  await tap(page, TAP.play);
  await page.screenshot({ path: path.join(ROOT, 'test-results/webkit/after-reload.png') });
  expect(problems).toEqual([]);
});

test('the question clock holds while the tab is hidden', async ({ page }) => {
  const problems = [];
  await boot(page, problems);
  await toFirstQuestion(page);

  // The clock runs: two seconds apart the seconds differ.
  const first = await timerShot(page);
  await page.waitForTimeout(2500);
  expect(Buffer.compare(first, await timerShot(page))).not.toBe(0);

  await setVisibility(page, true);
  await page.waitForTimeout(500);
  const held = await timerShot(page);
  await page.waitForTimeout(4000);
  expect(Buffer.compare(held, await timerShot(page))).toBe(0);

  await setVisibility(page, false);
  await page.waitForTimeout(3000);
  expect(Buffer.compare(held, await timerShot(page))).not.toBe(0);
  expect(problems).toEqual([]);
});
