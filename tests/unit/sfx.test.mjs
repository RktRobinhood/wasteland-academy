import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFileSync } from 'node:fs';
function setup() {
  const sounds = [];
  const document = { hidden: false, currentScript: { src: 'http://localhost/game/js/sfx.js' }, addEventListener() {}, getElementById() { return null; }, querySelectorAll() { return []; } };
  class Audio {
    constructor(src) { this.src = src; this.paused = false; this.currentTime = 0; sounds.push(this); }
    addEventListener() {}
    pause() { this.paused = true; }
    play() { return Promise.reject(new Error('autoplay denied')); }
  }
  const context = vm.createContext({ document, Audio, URL });
  vm.runInContext(readFileSync(new URL('../../js/sfx.js', import.meta.url), 'utf8') + '\nglobalThis.sfx = SFX;', context);
  return { sfx: context.sfx, document, sounds };
}
test('SFX stays silent by default and resolves assets under a deployment subpath', async () => {
  const { sfx, sounds } = setup(); sfx.play('correct'); assert.equal(sounds.length, 0);
  sfx.toggle(); assert.equal(sounds.length, 1);
  assert.equal(sounds[0].src, 'http://localhost/game/assets/audio/proposed/fal-372/ui-confirm-01.wav');
  assert.equal(sounds[0].volume, 0.16);
  await Promise.resolve(); assert.equal(sfx.current, null);
});
test('muting stops playback, overlapping effects replace one another, hidden tabs stay silent', async () => {
  const { sfx, sounds, document } = setup(); sfx.enabled = true;
  sfx.play('correct'); const first = sounds[0]; sfx.play('retry');
  assert.equal(first.paused, true); assert.equal(sounds.length, 2);
  // A rejected earlier play must not release a newer voice.
  await Promise.resolve();
  sfx.play('clear'); assert.equal(sounds.at(-1).volume, 0.10);
  sfx.toggle(); assert.equal(sounds.at(-1).paused, true); assert.equal(sfx.current, null);
  sfx.enabled = true; document.hidden = true; sfx.play('hint'); assert.equal(sounds.length, 3);
  sfx.play('unknown'); assert.equal(sounds.length, 3);
});
