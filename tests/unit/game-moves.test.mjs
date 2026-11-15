// game/data/moves.json is a generated copy of curriculum/moves.json and moves-map.json
// for the Godot engine, which tags worked steps from it (FAL-429).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { build, OUT } from '../../tools/game-moves.mjs';

test('game/data/moves.json is up to date with curriculum/moves.json and moves-map.json', () => {
  assert.equal(fs.readFileSync(OUT, 'utf8'), build(), 'rerun node tools/game-moves.mjs --write');
});
