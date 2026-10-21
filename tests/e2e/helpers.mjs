import fs from 'node:fs';
import path from 'node:path';
import { expect } from '@playwright/test';
import { REPO } from './server.mjs';

const KATEX_CDN = 'https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.16.9/';
const KATEX_DIST = path.join(REPO, 'node_modules/katex/dist/');

// Serve the KaTeX CDN from node_modules and stub Google Fonts, so the tests
// don't depend on third-party hosts.
export async function routeCdn(context) {
  await context.route(KATEX_CDN + '**', route => {
    const rel = new URL(route.request().url()).pathname.split('/KaTeX/0.16.9/')[1];
    const fp = path.join(KATEX_DIST, rel);
    if (!fp.startsWith(KATEX_DIST) || !fs.existsSync(fp)) return route.fulfill({ status: 404 });
    return route.fulfill({
      path: fp,
      headers: { 'access-control-allow-origin': '*' },
      contentType: fp.endsWith('.css') ? 'text/css' : fp.endsWith('.js') ? 'text/javascript' : 'font/woff2',
    });
  });
  await context.route(/^https:\/\/fonts\.(googleapis|gstatic)\.com\//, route =>
    route.fulfill({ status: 200, contentType: 'text/css', body: '', headers: { 'access-control-allow-origin': '*' } }));
}

// A seeded Math.random, so question order is the same on every run
export async function seedRandom(context, seed = 20261021) {
  await context.addInitScript(s => {
    let a = s >>> 0;
    Math.random = () => {
      a = (a + 0x6D2B79F5) >>> 0;
      let t = a;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }, seed);
}

// Collects uncaught page errors; call expectNoPageErrors() at the end of a test
export function trackPageErrors(page) {
  const errors = [];
  page.on('pageerror', e => errors.push(String(e.stack || e)));
  return {
    errors,
    expectNone() { expect(errors, 'uncaught page errors').toEqual([]); },
  };
}

export async function createProfile(page, name = 'VIPER') {
  await expect(page.locator('#screen-profile')).toBeVisible();
  await page.fill('#profile-name', name);
  await page.click('.avatar-choice[data-avatar="male"]');
  await page.click('#screen-profile .btn-primary');
  await expect(page.locator('#screen-world')).toBeVisible();
}

export async function openIsland(page, name) {
  await page.locator('#world-islands > *', { hasText: name }).click();
  await expect(page.locator('#screen-island')).toBeVisible();
}

export async function startNode(page, nodeName) {
  await page.locator('#island-nodes .node-btn', { hasText: nodeName }).click();
  await expect(page.locator('#screen-combat')).toBeVisible();
  await expect(page.locator('#outcome-overlay')).toBeHidden();
}

// What the engine is currently asking. Read from the engine (not the DOM) so the
// test knows which answer is right; the answer itself is always given by tapping.
export function currentQuestion(page) {
  return page.evaluate(() => {
    const q = Combat._run?._currentQuestion;
    return q ? { id: q.id, type: q.type, correctIndex: q.correctIndex, answer: q.answer } : null;
  });
}

export async function typeValue(page, value) {
  const s = String(value);
  for (const ch of s.replace(/^-/, '')) {
    await page.locator('#value-area .numpad-key').filter({ hasText: new RegExp(`^${ch.replace('.', '\\.')}$`) }).click();
  }
  if (s.startsWith('-')) await page.locator('#value-area .numpad-key', { hasText: '±' }).click();
}

// Taps an answer. `right` picks the correct one, otherwise a wrong one.
export async function answer(page, q, right) {
  if (q.type === 'mcq') {
    let idx = q.correctIndex;
    if (!right) {
      const enabled = await page.locator('#mcq-area .mcq-btn:not([disabled])').evaluateAll(
        els => els.map(e => Number(e.dataset.idx)));
      idx = enabled.find(i => i !== q.correctIndex);
    }
    await page.click(`#mcq-area .mcq-btn[data-idx="${idx}"]`);
  } else if (q.type === 'value') {
    await typeValue(page, right ? q.answer : Number(q.answer) + 1000);
    await page.click('#value-area .numpad-submit');
  } else {
    throw new Error(`smoke test can't answer a ${q.type} question (${q.id})`);
  }
}

// After an answer: the outcome shows, then either the next question or the debrief
export async function waitForNext(page) {
  await expect(page.locator('#outcome-overlay')).toBeVisible();
  await page.waitForFunction(() =>
    !document.getElementById('screen-debrief').classList.contains('hidden') ||
    document.getElementById('outcome-overlay').classList.contains('hidden'), null, { timeout: 5000 });
}
