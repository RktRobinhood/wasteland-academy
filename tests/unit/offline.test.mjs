// The game must run with no network after one visit, and ship as an app later
// with the same files. So: no remote or root-absolute URL in the game's own
// files, every vendored file is precached, and the vendored KaTeX is the
// real 0.16.9 build.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { REPO } from '../content/packs.mjs';

const read = rel => fs.readFileSync(path.join(REPO, rel), 'utf8');
const walk = dir => fs.readdirSync(path.join(REPO, dir), { withFileTypes: true }).flatMap(e =>
  e.isDirectory() ? walk(`${dir}/${e.name}`) : [`${dir}/${e.name}`]);

// The one allowed remote URL: where student reports go (FAL-221)
const ALLOWED = { 'js/platform.js': ['https://github.com/RktRobinhood/wasteland-academy/issues/new'] };

// The files a browser or app build runs, besides vendor/ and content/
const GAME_FILES = ['index.html', 'manifest.json', 'service-worker.js',
  ...walk('js').filter(f => f.endsWith('.js')), ...walk('css').filter(f => f.endsWith('.css'))];

test('no http(s) URL in the game files, except the report link in platform.js', () => {
  const found = [];
  for (const file of GAME_FILES) {
    for (const url of read(file).match(/\bhttps?:\/\/[^\s'"`)<>]*/gi) || []) {
      if (!(ALLOWED[file] || []).includes(url)) found.push(`${file}: ${url}`);
    }
  }
  assert.deepEqual(found, []);
});

test('no root-absolute or protocol-relative path in the game files', () => {
  // A quote, url( or a src/href= followed by "/x" or "//x". '/' on its own
  // (a fraction key) and regex literals don't match.
  const PATTERN = /(?:["'`]|url\(\s*)\/{1,2}[\w.~-]/g;
  const found = [];
  for (const file of GAME_FILES) {
    read(file).split('\n').forEach((line, i) => {
      for (const m of line.match(PATTERN) || []) found.push(`${file}:${i + 1}: ${m} … ${line.trim().slice(0, 100)}`);
    });
  }
  assert.deepEqual(found, []);
});

test('the checks above catch what they should', () => {
  const PATTERN = /(?:["'`]|url\(\s*)\/{1,2}[\w.~-]/;
  for (const bad of ['<script src="/js/a.js">', "fetch('/api')", 'url(/img/x.png)', "url('//cdn.x/y.css')", '`/assets/${x}`'])
    assert.ok(PATTERN.test(bad), bad);
  for (const ok of ["numpadPress('/')", 'href="vendor/katex/katex.min.css"', "s.split('/')", "'./service-worker.js'", 'x.replace(/\\s+/g, "")'])
    assert.ok(!PATTERN.test(ok), ok);
});

// PRECACHE from service-worker.js, run with a stub `self`
function precache() {
  const ctx = vm.createContext({ self: { addEventListener() {} }, Response: class {} });
  vm.runInContext(read('service-worker.js'), ctx);
  return Array.from(vm.runInContext('PRECACHE', ctx), u => u.replace(/^\.\//, ''));
}

test('every precached file exists (cache.addAll fails the install on a 404)', () => {
  const missing = precache().filter(f => f !== '' && !fs.existsSync(path.join(REPO, f)));
  assert.deepEqual(missing, []);
});

test('the precache covers vendor/, the icons, and everything index.html and the manifest load', () => {
  const list = new Set(precache());
  const needed = [
    ...walk('vendor').filter(f => !/\.(md|txt)$|\/LICENSE$/.test(f)),
    ...walk('assets/icons'),
    ...[...read('index.html').matchAll(/(?:src|href)="([^"#]+)"/g)].map(m => m[1]),
    ...JSON.parse(read('manifest.json')).icons.map(i => i.src),
  ];
  assert.deepEqual([...new Set(needed)].filter(f => !list.has(f)), []);
});

test('fonts load once, from vendor/, and every font file they name is there', () => {
  const html = read('index.html');
  assert.equal(html.match(/vendor\/fonts\/fonts\.css/g)?.length, 1);
  for (const file of GAME_FILES) assert.ok(!/@import|fonts\.googleapis|fonts\.gstatic/.test(read(file)), file);
  const css = read('vendor/fonts/fonts.css');
  const urls = [...css.matchAll(/url\(([^)]+)\)/g)].map(m => m[1]);
  assert.ok(urls.length >= 2);
  for (const u of urls) assert.ok(fs.existsSync(path.join(REPO, 'vendor/fonts', u)), u);
  for (const family of ['Bangers', 'Share Tech Mono']) assert.ok(css.includes(`font-family: '${family}'`), family);
});

test('vendored KaTeX is byte-for-byte katex@0.16.9, with every woff2 font its CSS names', () => {
  const dist = path.join(REPO, 'node_modules/katex/dist');
  assert.equal(JSON.parse(fs.readFileSync(path.join(REPO, 'node_modules/katex/package.json'), 'utf8')).version, '0.16.9');
  for (const f of ['katex.min.css', 'katex.min.js', 'contrib/auto-render.min.js']) {
    assert.ok(fs.readFileSync(path.join(REPO, 'vendor/katex', f)).equals(fs.readFileSync(path.join(dist, f))), f);
  }
  const woff2 = [...new Set([...read('vendor/katex/katex.min.css').matchAll(/url\((fonts\/[^)]+\.woff2)\)/g)].map(m => m[1]))];
  assert.equal(woff2.length, 20);
  for (const f of woff2) {
    assert.ok(fs.readFileSync(path.join(REPO, 'vendor/katex', f)).equals(fs.readFileSync(path.join(dist, f))), f);
  }
});

test('vendor/LICENSES.md names every vendored file', () => {
  const doc = read('vendor/LICENSES.md');
  const files = walk('vendor').map(f => f.slice('vendor/'.length)).filter(f => f !== 'LICENSES.md');
  const unlisted = files.filter(f => !doc.includes(f) && !(f.startsWith('katex/fonts/KaTeX_') && doc.includes('katex/fonts/KaTeX_*.woff2')));
  assert.deepEqual(unlisted, []);
});

test('manifest: an id, and each icon has a single purpose with both any and maskable present', () => {
  const m = JSON.parse(read('manifest.json'));
  assert.ok(m.id);
  for (const icon of m.icons) assert.ok(['any', 'maskable'].includes(icon.purpose), JSON.stringify(icon));
  for (const size of ['192x192', '512x512']) {
    assert.deepEqual(m.icons.filter(i => i.sizes === size).map(i => i.purpose).sort(), ['any', 'maskable'], size);
  }
});
