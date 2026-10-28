// assets/map/tumbleweed.svg is drawn by tools/tumbleweed.mjs (FAL-373). The
// script is the source; css/screens.css steps through its frames.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { build, OUT, FRAMES } from '../../tools/tumbleweed.mjs';
import { REPO } from '../content/packs.mjs';

test('assets/map/tumbleweed.svg is up to date with tools/tumbleweed.mjs', () => {
  assert.equal(fs.readFileSync(OUT, 'utf8'), build(), 'rerun node tools/tumbleweed.mjs --write');
});

test('the CSS steps through as many frames as the strip has', () => {
  const css = fs.readFileSync(path.join(REPO, 'css/screens.css'), 'utf8');
  const frames = css.match(/\.amb-weed-frames \{[^}]*\}/)?.[0] || '';
  assert.match(frames, new RegExp(`width: ${FRAMES * 100}%;`));
  assert.match(frames, new RegExp(`steps\\(${FRAMES}\\)`));
});
