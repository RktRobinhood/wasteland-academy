// The web export's link previews (FAL-470): scripts/share-card.sh copies the share card
// next to the export's index.html and points the Open Graph and Twitter tags at it,
// and adds nothing when there is no share card.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { REPO } from '../content/packs.mjs';

const SCRIPT = path.join(REPO, 'scripts/share-card.sh');
const PAGE = '<!DOCTYPE html>\n<html>\n\t<head>\n\t\t<title>Wasteland Academy</title>\n\t</head>\n\t<body></body>\n</html>\n';

function exportDir() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'share-card-'));
  fs.writeFileSync(path.join(dir, 'index.html'), PAGE);
  return dir;
}

function run(dir, ...args) {
  execFileSync(SCRIPT, [dir, ...args], { stdio: 'pipe' });
  return fs.readFileSync(path.join(dir, 'index.html'), 'utf8');
}

test('with a share card, the tags point at its full address', () => {
  const dir = exportDir();
  const card = path.join(dir, 'card-source.png');
  fs.writeFileSync(card, 'png');
  const html = run(dir, 'https://example.org/game/', card);
  assert.ok(fs.existsSync(path.join(dir, 'share-card.png')), 'the card is copied next to index.html');
  assert.match(html, /<meta property="og:image" content="https:\/\/example\.org\/game\/share-card\.png"/);
  assert.match(html, /<meta name="twitter:card" content="summary_large_image"/);
  assert.match(html, /<meta property="og:image:width" content="1200"/);
  assert.ok(html.indexOf('og:image') < html.indexOf('</head>'), 'the tags are in the head');
  fs.rmSync(dir, { recursive: true });
});

test('rerun with another address, the tags are replaced, not added twice', () => {
  const dir = exportDir();
  const card = path.join(dir, 'card-source.png');
  fs.writeFileSync(card, 'png');
  run(dir, 'https://example.org/next/', card);
  const html = run(dir, 'https://example.org/', card);
  assert.equal(html.match(/og:image"/g).length, 1);
  assert.match(html, /content="https:\/\/example\.org\/share-card\.png"/);
  assert.doesNotMatch(html, /example\.org\/next\//);
  fs.rmSync(dir, { recursive: true });
});

test('with no share card, the page is left as it was', () => {
  const dir = exportDir();
  const html = run(dir, 'https://example.org/game/', path.join(dir, 'missing.png'));
  assert.equal(html, PAGE);
  assert.ok(!fs.existsSync(path.join(dir, 'share-card.png')));
  fs.rmSync(dir, { recursive: true });
});
