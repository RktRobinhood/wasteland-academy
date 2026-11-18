// game/data/explainers/ is a copy of the explainer scripts, callbacks.json and
// reactions.json for the Godot lesson player (#218, FAL-1088).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { build, current } from '../../tools/game-explainers.mjs';

test('game/data/explainers/ is up to date with writing/explainers/', () => {
  assert.deepEqual(current(), build(), 'rerun node tools/game-explainers.mjs --write');
});
