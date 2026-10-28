// game/data/catalogue.json is a generated copy of curriculum/question-types.json for the
// Godot question engine (FAL-322). The JSON in curriculum/ is the source.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { build, OUT } from '../../tools/game-catalogue.mjs';

test('game/data/catalogue.json is up to date with curriculum/question-types.json', () => {
  assert.equal(fs.readFileSync(OUT, 'utf8'), build(), 'rerun node tools/game-catalogue.mjs --write');
});
