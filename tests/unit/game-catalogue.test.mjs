// game/data/catalogue.json is a generated copy of curriculum/question-types.json for the
// Godot question engine (FAL-322). The JSON in curriculum/ is the source.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { build, caretPowers, OUT } from '../../tools/game-catalogue.mjs';

test('game/data/catalogue.json is up to date with curriculum/question-types.json', () => {
  assert.equal(fs.readFileSync(OUT, 'utf8'), build(), 'rerun node tools/game-catalogue.mjs --write');
});

// The game's font has no superscript letters (FAL-499), so the copy writes those powers
// with a caret and keeps powers of digits only.
test('powers with a letter are written with a caret in the game copy', () => {
  assert.equal(caretPowers('eˣ, b²ˣ + p·bˣ, x⁻ⁿ, xᵐ⁻¹, (1/2)ˣ'), 'e^x, b^(2x) + p·b^x, x^(−n), x^(m−1), (1/2)^x');
  assert.equal(caretPowers('x², 2⁻¹, (xᵢ, yᵢ), P₀'), 'x², 2⁻¹, (xᵢ, yᵢ), P₀');
  assert.doesNotMatch(fs.readFileSync(OUT, 'utf8'), /[ᵃᵇᶜᵈᵉᶠᵍʰⁱʲᵏˡᵐⁿᵒᵖʳˢᵗᵘᵛʷˣʸᶻ]/u);
});
