// game/data/explainers/ is a copy of the explainer scripts, callbacks.json and
// reactions.json for the Godot lesson player (#218, FAL-1088).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { build, current } from '../../tools/game-explainers.mjs';

test('game/data/explainers/ is up to date with writing/explainers/', () => {
  assert.deepEqual(current(), build(), 'rerun node tools/game-explainers.mjs --write');
});

test('the game never accepts a stale, retired, unreviewed or substituted take', async () => {
  const { createHash } = await import('node:crypto');
  const { sayHash } = await import('../../tools/explainer-scripts.mjs');
  const { voiceIndex } = await import('../../tools/game-explainers.mjs');
  const sid = 'ex.z.demo', key = 'abcdef';
  const line = { line: key, speaker: 'rook', say: 'Six plus eight', caption: '6 + 8', cue: 'radio' };
  const sources = l => ({ [sid + '.json']: JSON.stringify({ sections: [{ beats: [l] }] }) });
  const bytes = Buffer.from('original audio');
  const file = `game/assets/audio/voice/explainers/${sid}/${key}.ogg`;
  const hash = sayHash(line);
  const entry = { speaker: line.speaker, say: hash, take: { say: hash, file,
    word_check: 'passed', sha256: createHash('sha256').update(bytes).digest('hex') } };
  const manifest = (e = entry, retired = {}) => ({ lines: { [sid]: { [key]: e } }, retired });
  const accepted = { [sid]: { [key]: ['rook', 'Six plus eight', 'radio', null] } };
  const read = name => name === file ? bytes : null;
  assert.deepEqual(voiceIndex(sources(line), manifest(), read), accepted);
  assert.deepEqual(voiceIndex(sources({ ...line, caption: '6 plus 8' }), manifest(), read), accepted);
  assert.deepEqual(voiceIndex(sources({ ...line, say: 'Six plus four' }), manifest(), read), {});
  assert.deepEqual(voiceIndex(sources(line), manifest(entry, { [sid]: { [key]: entry } }), read), {});
  assert.deepEqual(voiceIndex(sources(line), manifest({ ...entry, take: null }), read), {});
  assert.deepEqual(voiceIndex(sources(line), manifest({ ...entry, take: { ...entry.take, word_check: 'failed' } }), read), {});
  assert.deepEqual(voiceIndex(sources(line), manifest({ ...entry, take: { ...entry.take, word_check: 'accepted on review: ja -> yeah' } }), read), accepted);
  assert.deepEqual(voiceIndex(sources(line), manifest(), () => Buffer.from('wrong recording')), {});
  assert.deepEqual(voiceIndex(sources(line), manifest(), () => null), {});
});


test('release catalog requires a real worked example and an exact course-fit twin', async () => {
  const { checkArchive } = await import('../../tools/game-explainers.mjs');
  const sources = build();
  const original = JSON.parse(sources['archive.json']);
  assert.doesNotThrow(() => checkArchive(sources));
  assert.deepEqual(original.entries.map(e => e.lesson), [
    'ex.functions.function-machine', 'ex.foundations.pre-substitute',
  ], 'publish only the two individually reviewed excerpts');
  const invalid = fields => ({ ...sources, 'archive.json': JSON.stringify({ ...original, entries: [
    { ...original.entries[0], ...fields },
  ] }) });
  assert.throws(() => checkArchive(invalid({ practice: 'turn-2' })), /its own twin/);
  assert.throws(() => checkArchive(invalid({ courses: ['unknown-course'] })), /course mapping/);
  assert.throws(() => checkArchive(invalid({ lesson: 'ex.not.ready' })), /worked example/);
  assert.throws(() => checkArchive(invalid({ practice_mode: 'unverified-engine' })), /complete stem/);
});
