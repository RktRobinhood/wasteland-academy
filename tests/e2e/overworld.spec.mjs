// The overworld (SPEC §4.1) on the real art in assets/: the map in a 9:16
// frame, a button over each painted zone, the locked haze and the cleared
// crown, at both phone sizes.
import { test, expect } from '@playwright/test';
import { startServer } from './server.mjs';
import { routeCdn, seedRandom, trackPageErrors, createProfile } from './helpers.mjs';

test.use({ serviceWorkers: 'block' });

let server;
test.beforeAll(async () => { server = await startServer(); });
test.afterAll(async () => { await server?.close(); });

test.beforeEach(async ({ context }) => {
  await routeCdn(context);
  await seedRandom(context);
});

const SHOTS = 'test-results/screenshots';
const ZONES = ['Scrap Fields', 'Signal Tower', 'Dry Flats', 'Thunderdome', 'Radio Spires', 'Engine Core'];

const overlaps = (a, b) =>
  a.x < b.x + b.width && b.x < a.x + a.width && a.y < b.y + b.height && b.y < a.y + a.height;
const inside = (a, b) =>
  a.x >= b.x - 0.5 && a.y >= b.y - 0.5 && a.x + a.width <= b.x + b.width + 0.5 && a.y + a.height <= b.y + b.height + 0.5;

async function openWorld(page) {
  await page.goto(server.url);
  await createProfile(page);
  await expect(page.locator('#world-map-art')).toBeVisible();
  await expect(page.locator('#world-grid')).toBeHidden();
}

for (const [width, height] of [[390, 844], [375, 667]]) {
  test.describe(`${width}×${height}`, () => {
    test.use({ viewport: { width, height } });

    test('the map fits between header and footer, with every zone on it', async ({ page }) => {
      const pageErrors = trackPageErrors(page);
      await openWorld(page);

      // 9:16, as large as fits, and nothing overlaps the header or footer
      const map = await page.locator('.world-map').boundingBox();
      const body = await page.locator('.world-body').boundingBox();
      expect(map.width / map.height).toBeCloseTo(9 / 16, 2);
      expect(inside(map, body), 'map inside the world body').toBe(true);
      expect(Math.min(body.width - map.width, body.height - map.height), 'map fills one side').toBeLessThan(1);
      const art = await page.locator('#world-map-art').evaluate(e => [e.naturalWidth, e.naturalHeight]);
      expect(art).toEqual([1080, 1920]);

      // A real button per zone, named by its visible label, big enough to tap,
      // on the map, and clear of every other zone and its label
      const boxes = [];
      for (const name of ZONES) {
        const btn = page.getByRole('button', { name: new RegExp(`^${name}`) });
        await expect(btn).toBeVisible();
        await expect(btn.locator('.zone-name')).toHaveText(name);
        const box = await btn.boundingBox();
        const label = await btn.locator('.zone-label').boundingBox();
        expect(box.width, `${name} width`).toBeGreaterThanOrEqual(48);
        expect(box.height, `${name} height`).toBeGreaterThanOrEqual(48);
        expect(inside(box, map), `${name} on the map`).toBe(true);
        expect(inside(label, box), `${name} label inside its zone`).toBe(true);
        boxes.push({ name, box, label });
      }
      for (const a of boxes) for (const b of boxes) {
        if (a.name < b.name) {
          expect(overlaps(a.box, b.box), `${a.name} / ${b.name} zones overlap`).toBe(false);
        }
      }
      await page.screenshot({ path: `${SHOTS}/overworld-${width}x${height}.png` });
      pageErrors.expectNone();
    });

    test('each zone opens its island, and the Thunderdome its set-up', async ({ page }) => {
      const pageErrors = trackPageErrors(page);
      await openWorld(page);
      for (const name of ZONES.filter(n => n !== 'Thunderdome')) {
        await page.getByRole('button', { name: new RegExp(`^${name}`) }).click();
        await expect(page.locator('#screen-island')).toBeVisible();
        await expect(page.locator('#island-title')).toHaveText(name);
        await page.click('#screen-island .back-btn');
        await expect(page.locator('#world-map-art')).toBeVisible();
      }
      await page.getByRole('button', { name: /^Thunderdome/ }).click();
      await expect(page.locator('#screen-td-config')).toBeVisible();
      pageErrors.expectNone();
    });
  });
}

test('a locked zone is hazed and does nothing; a cleared one wears a crown', async ({ page }) => {
  const pageErrors = trackPageErrors(page);
  await openWorld(page);

  // Radio Spires with no questions (locked); every Scrap Fields node cleared
  await page.evaluate(() => {
    WA.packs.find(p => p.id === 'topic-4-stats').subtopics.forEach(st => { st.questions = []; });
    WA.packs.find(p => p.id === 'topic-1-algebra').subtopics.forEach(st =>
      WA.setNodeState('topic-1-algebra', st.id, 'cleared'));
    WorldScreen.render();
  });

  const locked = page.getByRole('button', { name: /^Radio Spires/ });
  await expect(locked).toHaveAccessibleName(/locked/);
  await expect(locked).toHaveAttribute('aria-disabled', 'true');
  await expect(locked.locator('.zone-state')).toHaveText('LOCKED');
  expect(await locked.evaluate(e => {
    const s = getComputedStyle(e, '::before');
    return [s.content, s.backdropFilter];
  })).toEqual(['""', expect.stringContaining('grayscale(1)')]);
  await locked.click({ force: true });  // aria-disabled: Playwright would wait for it to enable
  await expect(page.locator('#screen-world')).toBeVisible();

  const cleared = page.getByRole('button', { name: /^Scrap Fields/ });
  await expect(cleared).toHaveAccessibleName(/cleared/);
  await expect(cleared.locator('.zone-crown')).toBeVisible();
  const crown = await cleared.locator('.zone-crown').boundingBox();
  expect(crown.width).toBeGreaterThanOrEqual(16);

  // The others are neither
  for (const name of ['Signal Tower', 'Dry Flats', 'Engine Core']) {
    const btn = page.getByRole('button', { name: new RegExp(`^${name}`) });
    await expect(btn).not.toHaveAccessibleName(/locked|cleared/);
    await expect(btn.locator('.zone-crown')).toHaveCount(0);
  }
  await page.screenshot({ path: `${SHOTS}/overworld-locked-cleared.png` });
  pageErrors.expectNone();
});

test('without the overworld file, the card grid shows and works', async ({ page, context }) => {
  await context.route(/\/assets\/map\/overworld\.png$/, route => route.fulfill({ status: 404, body: 'not found' }));
  const pageErrors = trackPageErrors(page);
  await page.goto(server.url);
  await createProfile(page);
  await expect(page.locator('#world-grid')).toBeVisible();
  await expect(page.locator('.world-map')).toBeHidden();
  await expect(page.locator('#world-islands .island-node')).toHaveCount(5);
  for (const img of await page.locator('#world-islands .island-art, .thunderdome-art').all()) await expect(img).toBeVisible();
  await page.screenshot({ path: `${SHOTS}/overworld-missing-grid.png` });
  await page.locator('#world-islands .island-node', { hasText: 'Engine Core' }).click();
  await expect(page.locator('#island-title')).toHaveText('Engine Core');
  pageErrors.expectNone();
});

test('while the map loads, the grid does not flash up first', async ({ page, context }) => {
  let release;
  const held = new Promise(r => { release = r; });
  await context.route(/\/assets\/map\/overworld\.png$/, async route => { await held; await route.continue(); });
  await page.goto(server.url);
  await createProfile(page);
  await expect(page.locator('#world-map-art')).toHaveAttribute('data-art-state', 'loading');
  await expect(page.locator('#world-grid')).toHaveCSS('visibility', 'hidden');
  release();
  await expect(page.locator('#world-map-art')).toBeVisible();
  await expect(page.locator('#world-grid')).toBeHidden();
});
