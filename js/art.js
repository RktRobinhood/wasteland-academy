// ── ART ───────────────────────────────────────────────────────
// Every game image goes through here, so the game looks the same with or
// without the art files: an image shows once it has loaded, its fallback
// shows until then and whenever it fails, and a later load brings it back.
const Art = {
  // Points `img` at the first of `srcs` that loads. `srcs` is a path or a
  // list to try in order; an empty list hides the image. `fallback` is the
  // element to show while there's no image (optional).
  show(img, srcs, fallback = null) {
    if (!img) return;
    srcs = [].concat(srcs || []);
    const state = this._bind(img);
    state.fallback = fallback;
    state.srcs = srcs;
    state.next = 0;
    this._toggle(img, false);
    if (srcs.length === 0) { img.removeAttribute('src'); return; }
    this._try(img);
  },

  // Images declared in markup as <img data-art="path"> (a `|`-separated list
  // tries each in turn). The fallback is the next sibling, if it has the
  // class `art-fallback`.
  scan(root = document) {
    root.querySelectorAll('img[data-art]').forEach(img => {
      const fb = img.nextElementSibling;
      this.show(img, img.dataset.art.split('|'), fb?.classList.contains('art-fallback') ? fb : null);
    });
  },

  // For art drawn by CSS (border-image): `cls` is set on <html> while `src`
  // loads, and the CSS under that class uses it. Call again to re-check.
  flag(cls, src) {
    const probe = new Image();
    probe.onload  = () => document.documentElement.classList.add(cls);
    probe.onerror = () => document.documentElement.classList.remove(cls);
    probe.src = src;
  },

  // CSS-drawn art, checked at boot and again before each fight
  FRAMES: {
    'art-question-card':   'assets/ui/question-card.png',
    'art-hp-frame-player': 'assets/ui/hp-frame-player.png',
    'art-hp-frame-enemy':  'assets/ui/hp-frame-enemy.png',
  },

  checkFrames() {
    for (const [cls, src] of Object.entries(this.FRAMES)) this.flag(cls, src);
  },

  init() {
    this.scan();
    this.checkFrames();
  },

  _bind(img) {
    if (img._art) return img._art;
    const state = img._art = { srcs: [], next: 0, fallback: null };
    // Events for a src that has since been replaced are ignored
    const current = () => img.getAttribute('src') === state.srcs[state.next - 1];
    img.addEventListener('load', () => { if (current()) this._toggle(img, true); });
    img.addEventListener('error', () => {
      if (!current()) return;
      this._toggle(img, false);
      this._try(img);
    });
    return state;
  },

  _try(img) {
    const state = img._art;
    if (state.next >= state.srcs.length) return;
    img.setAttribute('src', state.srcs[state.next++]);
    // An image already in memory is ready now, so it shows with no flicker
    if (img.complete && img.naturalWidth > 0) this._toggle(img, true);
  },

  _toggle(img, loaded) {
    img.classList.toggle('hidden', !loaded);
    img._art.fallback?.classList.toggle('hidden', loaded);
  },
};
