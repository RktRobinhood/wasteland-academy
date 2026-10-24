// Accepted Kenney CC0 palette (FAL-372). Quiet and off until the player opts in.
const SFX = {
  enabled: false,
  current: null,
  files: {
    confirm: 'ui-confirm-01', correct: 'answer-correct-01', retry: 'answer-retry-01',
    hint: 'hint-relay-01', reward: 'scrap-reward-01', open: 'encounter-open-01', clear: 'encounter-clear-01',
  },
  base: new URL('../assets/audio/proposed/fal-372/', document.currentScript.src),
  stop() {
    if (this.current) { this.current.pause(); this.current.currentTime = 0; this.current = null; }
  },
  toggle() {
    this.enabled = !this.enabled;
    this.stop();
    document.querySelectorAll('[data-sfx-toggle]').forEach(button => {
      button.textContent = `Sound: ${this.enabled ? 'on' : 'off'}`;
      button.setAttribute('aria-pressed', String(this.enabled));
    });
    if (this.enabled) this.play('confirm');
  },
  play(cue) {
    if (!this.enabled || document.hidden || !this.files[cue]) return;
    this.stop(); // One effect at a time: never stack a reward over an answer.
    try {
      const sound = new Audio(new URL(`${this.files[cue]}.wav`, this.base).href);
      sound.volume = cue === 'clear' ? 0.10 : 0.16;
      this.current = sound;
      const release = () => { if (this.current === sound) this.current = null; };
      sound.addEventListener('ended', release, { once: true });
      sound.addEventListener('error', release, { once: true });
      const started = sound.play();
      if (started?.catch) started.catch(release); // Autoplay rejection must never affect a question.
    } catch { this.current = null; }
  },
  mount() {
    if (document.getElementById('sfx-toggle')) return;
    const headers = [...document.querySelectorAll('.world-header, .combat-header')];
    // Keep the control in the layout so it never covers answer or navigation buttons.
    (headers.length ? headers : [document.body]).forEach((header, i) => {
      const button = document.createElement('button');
      button.id = i === 0 ? 'sfx-toggle' : 'sfx-toggle-combat';
      button.type = 'button'; button.textContent = 'Sound: off';
      button.dataset.sfxToggle = '';
      button.setAttribute('aria-pressed', 'false');
      Object.assign(button.style, { flexShrink: '0', minHeight: '48px', padding: '8px', font: 'inherit', fontSize: '12px', background: '#111827', color: '#9ff0e6', border: '1px solid #22d3c5', borderRadius: '8px' });
      button.addEventListener('click', () => this.toggle()); header.append(button);
    });
    document.addEventListener('visibilitychange', () => { if (document.hidden) this.stop(); });
  },
};
document.addEventListener('DOMContentLoaded', () => SFX.mount());
