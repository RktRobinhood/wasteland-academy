// Saves are never lost: export → reset → import gives back the same save, a
// bad file changes nothing, and a save in today's format loads as it is.
import fs from 'node:fs';
import path from 'node:path';
import { test, expect } from '@playwright/test';
import { startServer, REPO } from './server.mjs';
import {
  blockRemote, seedRandom, trackPageErrors, createProfile, openIsland, startNode,
  currentQuestion, answer, waitForNext, clearNode,
} from './helpers.mjs';

test.use({ serviceWorkers: 'block' });

const SHOTS = 'test-results/screenshots';
const FIXTURE = fs.readFileSync(path.join(REPO, 'tests/fixtures/save-v1.json'), 'utf8');

let server;
test.beforeAll(async () => { server = await startServer(); });
test.afterAll(async () => { await server?.close(); });

test.beforeEach(async ({ context }) => {
  await blockRemote(context, server.origin);
  await seedRandom(context);
});

const stored = page => page.evaluate(() => JSON.parse(localStorage.getItem('wa_save')));
const toast = page => page.locator('#toast-container .toast').last();

// Seeds the browser's storage before the game's first load
async function seedSave(page, raw) {
  await page.goto(server.url + 'manifest.json');
  await page.evaluate(r => { localStorage.clear(); localStorage.setItem('wa_save', r); }, raw);
}

async function importFile(page, file) {
  const chooser = page.waitForEvent('filechooser');
  await page.click('#import-save-btn');
  await (await chooser).setFiles(file);
}

// A profile with real progress: one node cleared after one wrong answer
async function playSomething(page) {
  await page.goto(server.url);
  await createProfile(page, 'VIPER');
  await openIsland(page, 'Scrap Fields');
  await startNode(page, 'Standard Form');
  await answer(page, await currentQuestion(page), false);
  await waitForNext(page);
  await clearNode(page);
  await page.click('#screen-debrief .btn-primary');
  await expect(page.locator('#screen-stats')).toBeVisible();
}

test('export, reset, import gives back the same save', async ({ page }, testInfo) => {
  const pageErrors = trackPageErrors(page);
  await playSomething(page);
  const before = await stored(page);
  expect(before.spaced.wanted.length).toBeGreaterThan(0);
  expect(before.stats.runs.length).toBe(1);

  // Export
  await expect(page.locator('#import-save-btn')).toBeVisible();
  await page.screenshot({ path: `${SHOTS}/saves-01-stats-export-import-390x844.png` });
  const download = page.waitForEvent('download');
  await page.click('#screen-stats .btn:has-text("EXPORT SAVE")');
  const file = testInfo.outputPath('export.json');
  await (await download).saveAs(file);
  expect((await download).suggestedFilename()).toMatch(/^wasteland-academy-save-\d{4}-\d\d-\d\d\.json$/);
  expect(JSON.parse(fs.readFileSync(file, 'utf8'))).toEqual(before);

  // Reset wipes it (after the confirm)
  page.once('dialog', d => d.accept());
  await page.click('#screen-stats .btn-danger');
  await expect(page.locator('#screen-profile')).toBeVisible();
  expect((await stored(page))?.profile?.name ?? '').toBe('');

  // A fresh profile, then import
  await createProfile(page, 'NEWBIE');
  await page.click('#screen-world .world-footer .btn:has-text("STATS")');
  await importFile(page, file);
  await expect(toast(page)).toHaveText('Save loaded!');
  await expect(page.locator('#screen-world')).toBeVisible();
  await expect(page.locator('#world-player-name')).toHaveText('VIPER');

  // The same save, in memory and in storage, and after a reload
  expect(await page.evaluate(() => JSON.parse(JSON.stringify(WA.state)))).toEqual(before);
  expect(await stored(page)).toEqual(before);
  await page.reload();
  await expect(page.locator('#screen-world')).toBeVisible();
  expect(await page.evaluate(() => JSON.parse(JSON.stringify(WA.state)))).toEqual(before);

  // And the game uses it: the node is cleared, the bounty is on the board
  await openIsland(page, 'Scrap Fields');
  await expect(page.locator('#island-nodes .node-btn', { hasText: 'Standard Form' })).toHaveClass(/node-cleared/);
  pageErrors.expectNone();
});

test('a bad save file is rejected with a clear message and changes nothing', async ({ page }) => {
  const pageErrors = trackPageErrors(page);
  await playSomething(page);
  const before = await stored(page);
  const v1 = JSON.parse(FIXTURE);

  const bad = [
    ['damaged.json', JSON.stringify({ ...v1, spaced: 'oops' }), 'That save file is damaged, so it was not loaded. Nothing was changed.'],
    ['not-json.json', '{"version": 1, "profile": {', "That file isn't a Wasteland Academy save. Nothing was changed."],
    ['photo.json', '{"hello": "world"}', "That file isn't a Wasteland Academy save. Nothing was changed."],
    ['future.json', JSON.stringify({ ...v1, version: 99 }), 'That save is from a newer version of the game. Update the game, then try again. Nothing was changed.'],
  ];
  for (const [name, text, message] of bad) {
    await importFile(page, { name, mimeType: 'application/json', buffer: Buffer.from(text) });
    await expect(toast(page)).toHaveText(message);
    await expect(toast(page)).toHaveClass(/error/);
    if (name === 'damaged.json') {
      await page.waitForTimeout(300);  // let the toast finish fading in
      await page.screenshot({ path: `${SHOTS}/saves-02-bad-file-390x844.png` });
    }
    await expect(page.locator('#screen-stats')).toBeVisible();
    expect(await stored(page), `${name}: storage unchanged`).toEqual(before);
    expect(await page.evaluate(() => JSON.parse(JSON.stringify(WA.state))), `${name}: game state unchanged`).toEqual(before);
  }
  pageErrors.expectNone();
});

test("a save in today's format loads without loss", async ({ page }) => {
  const pageErrors = trackPageErrors(page);
  await seedSave(page, FIXTURE);
  await page.goto(server.url);
  await expect(page.locator('#screen-world')).toBeVisible();
  await expect(page.locator('#world-player-name')).toHaveText('FIXTURE');
  expect(await page.evaluate(() => JSON.parse(JSON.stringify(WA.state)))).toEqual(JSON.parse(FIXTURE));
  expect(await stored(page)).toEqual(JSON.parse(FIXTURE));

  await openIsland(page, 'Scrap Fields');
  await expect(page.locator('#island-nodes .node-btn', { hasText: 'Standard Form' })).toHaveClass(/node-cleared/);
  pageErrors.expectNone();
});

test("a save that can't be read is kept aside, never overwritten", async ({ page }) => {
  const pageErrors = trackPageErrors(page);
  const future = JSON.stringify({ ...JSON.parse(FIXTURE), version: 99 });
  await seedSave(page, future);
  await page.goto(server.url);
  await expect(page.locator('#screen-profile')).toBeVisible();
  await expect(toast(page)).toContainText("Your old save couldn't be read");

  const kept = await page.evaluate(() => Object.keys(localStorage)
    .filter(k => k.startsWith('wa_save_unreadable_')).map(k => localStorage.getItem(k)));
  expect(kept).toEqual([future]);
  pageErrors.expectNone();
});
