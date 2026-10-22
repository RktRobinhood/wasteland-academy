// Save migrations and file checks, from js/engine.js as the browser loads it.
// tests/fixtures/save-v1.json is a real save written by the game as it was
// before numbered migrations (main at c03190a): today's format.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { REPO, loadScripts } from '../content/packs.mjs';

const FIXTURE = fs.readFileSync(path.join(REPO, 'tests/fixtures/save-v1.json'), 'utf8');

// A fresh WA each time, so a test that changes VERSION or MIGRATIONS can't leak
const loadWA = () => vm.runInContext('WA', loadScripts(['js/engine.js']));
const plain = v => JSON.parse(JSON.stringify(v));

test("a save in today's format (v1) loads without loss", () => {
  const WA = loadWA();
  assert.equal(WA.VERSION, 1);
  const state = WA.parseSave(FIXTURE);
  assert.deepEqual(plain(state), JSON.parse(FIXTURE));
});

test('a save missing newer fields gets their defaults and keeps everything else', () => {
  const WA = loadWA();
  const old = JSON.parse(FIXTURE);
  delete old.profile.equipped;
  delete old.stats.highScores;
  delete old.spaced.answered;
  const state = plain(WA.migrate(old));
  assert.deepEqual(state.profile.equipped, {});
  assert.deepEqual(state.stats.highScores, { endurance: 0, gauntlet: 0 });
  assert.equal(state.spaced.answered, 0);
  // Nothing that was there changed
  const original = JSON.parse(FIXTURE);
  assert.deepEqual(state.progress, original.progress);
  assert.deepEqual(state.stats.runs, original.stats.runs);
  assert.deepEqual(state.spaced.wanted, original.spaced.wanted);
  assert.equal(state.profile.scrap, original.profile.scrap);
});

test('migrations run in order, one version at a time, and never change the input', () => {
  const WA = loadWA();
  WA.VERSION = 3;
  const seen = [];
  WA.MIGRATIONS = {
    1: s => { seen.push(['1→2', s.version]); s.profile.title = 'Rookie'; return s; },
    2: s => { seen.push(['2→3', s.version]); s.profile.title += ' Scav'; return s; },
  };
  const input = JSON.parse(FIXTURE);
  const state = WA.migrate(input);
  assert.deepEqual(seen, [['1→2', 1], ['2→3', 2]]);
  assert.equal(state.version, 3);
  assert.equal(state.profile.title, 'Rookie Scav');
  assert.deepEqual(input, JSON.parse(FIXTURE), 'input untouched');
  // A save already at version 2 only runs the last step
  seen.length = 0;
  WA.migrate({ ...JSON.parse(FIXTURE), version: 2, profile: { ...JSON.parse(FIXTURE).profile, title: 'Vet' } });
  assert.deepEqual(seen, [['2→3', 2]]);
});

test('a missing migration step is an error, not a wipe', () => {
  const WA = loadWA();
  WA.VERSION = 2;
  assert.throws(() => WA.migrate(JSON.parse(FIXTURE)), /No save migration from version 1/);
  assert.throws(() => WA.parseSave(FIXTURE), e => e.forPlayer && /damaged/.test(e.message));
});

test('files that are not a usable save are rejected with a message for the player', () => {
  const WA = loadWA();
  const v1 = JSON.parse(FIXTURE);
  const cases = {
    'not JSON': ['{"version": 1, "profile":', /isn't a Wasteland Academy save/],
    'JSON array': ['[1, 2]', /isn't a Wasteland Academy save/],
    'JSON null': ['null', /isn't a Wasteland Academy save/],
    'no version': [JSON.stringify({ ...v1, version: undefined }), /isn't a Wasteland Academy save/],
    'version 0': [JSON.stringify({ ...v1, version: 0 }), /isn't a Wasteland Academy save/],
    'version as text': [JSON.stringify({ ...v1, version: '1' }), /isn't a Wasteland Academy save/],
    'newer version': [JSON.stringify({ ...v1, version: 99 }), /newer version of the game/],
    'no profile': [JSON.stringify({ ...v1, profile: undefined }), /damaged/],
    'islands not an object': [JSON.stringify({ ...v1, progress: { islands: [] } }), /damaged/],
    'runs not a list': [JSON.stringify({ ...v1, stats: { ...v1.stats, runs: {} } }), /damaged/],
    'no spaced': [JSON.stringify({ ...v1, spaced: null }), /damaged/],
  };
  for (const [name, [text, msg]] of Object.entries(cases)) {
    assert.throws(() => WA.parseSave(text), e => e.forPlayer === true && msg.test(e.message) && /Nothing was changed/.test(e.message), name);
  }
});
