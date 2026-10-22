import { expect } from '@playwright/test';

// Everything the game needs is served by the test server, so any request to
// another host is a bug (a CDN link crept back in). This aborts such requests
// and records them; call expectNone() at the end of a test.
export async function blockRemote(context, origin) {
  const hits = [];
  await context.route(url => url.origin !== origin, route => {
    hits.push(route.request().url());
    return route.abort();
  });
  return {
    hits,
    expectNone() { expect(hits, 'requests to other hosts').toEqual([]); },
  };
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

// Taps an island on the world screen: its zone on the overworld, or its card
// when the map art is missing
export async function openIsland(page, name) {
  await page.locator('#world-zones .zone, #world-islands .island-node')
    .filter({ hasText: name, visible: true }).click();
  await expect(page.locator('#screen-island')).toBeVisible();
}

// Taps the Thunderdome on the world screen, on the map or in the card grid
export async function openThunderdome(page) {
  await page.locator('#world-zones .zone-thunderdome, .thunderdome-btn').filter({ visible: true }).click();
  await expect(page.locator('#screen-td-config')).toBeVisible();
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
    if (!q) return null;
    return {
      id: q.id, type: q.type, difficulty: q.difficulty, isWanted: !!q._isWanted,
      correctIndex: q.correctIndex, answer: q.answer,
      parts: q.parts?.map(p => ({ type: p.type, correctIndex: p.correctIndex, answer: p.answer })),
      enemyTier: Combat._run._currentEnemy.difficulty,
    };
  });
}

// Types a number on a numpad: the main one, or a multi-part question's own
export async function typeValue(page, value, scope = '#value-area') {
  const s = String(value);
  for (const ch of s.replace(/^-/, '')) {
    await page.locator(`${scope} .numpad-key`).filter({ hasText: new RegExp(`^${ch.replace('.', '\\.')}$`) }).click();
  }
  if (s.startsWith('-')) await page.locator(`${scope} .numpad-key`, { hasText: '±' }).click();
}

// Answers the current part of a multi-part question and confirms it
export async function answerPart(page, part, right) {
  if (part.type === 'mcq') {
    const idx = right ? part.correctIndex : (part.correctIndex + 1) % 4;
    await page.click(`#mp-answer-area .mcq-btn[data-idx="${idx}"]`);
  } else {
    const v = right ? part.answer : Number(part.answer) + 1000;
    await typeValue(page, v, '#mp-answer-area');
    await expect(page.locator('#mp-numpad-display')).toHaveText(String(v));
  }
  await page.click('#multipart-area .multipart-nav .btn');
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
  } else if (q.parts) {
    for (const part of q.parts) await answerPart(page, part, right);
  } else {
    throw new Error(`can't answer a ${q.type} question (${q.id})`);
  }
}

// Answers right until the node is cleared and the debrief shows
export async function clearNode(page, maxTurns = 30) {
  for (let turn = 0; turn < maxTurns; turn++) {
    if (await page.locator('#screen-debrief').isVisible()) return;
    const q = await currentQuestion(page);
    expect(q, 'a question is showing').not.toBeNull();
    await answer(page, q, true);
    await expect(page.locator('#outcome-msg')).toHaveText('CORRECT!');
    await waitForNext(page);
  }
  await expect(page.locator('#screen-debrief')).toBeVisible();
}

// After an answer: the outcome shows, then either the next question or the debrief
export async function waitForNext(page) {
  await expect(page.locator('#outcome-overlay')).toBeVisible();
  await page.waitForFunction(() =>
    !document.getElementById('screen-debrief').classList.contains('hidden') ||
    document.getElementById('outcome-overlay').classList.contains('hidden'), null, { timeout: 5000 });
}
