// ── PLATFORM ──────────────────────────────────────────────────
// The only file that touches the browser for storage, external links and
// files. This is the web version. An app build (Capacitor) replaces this one
// file with its own version of the same calls, and nothing else changes.
const Platform = {
  // Where student reports go (FAL-221). The one remote URL the game may hold.
  ISSUES_URL: 'https://github.com/RktRobinhood/wasteland-academy/issues/new',

  // Key-value storage. Values are strings. get() returns null for a missing key.
  // set() throws if the value can't be stored (e.g. storage is full).
  storage: {
    get(key) {
      try { return localStorage.getItem(key); }
      catch (e) { console.warn('[Platform] storage read failed', e); return null; }
    },
    set(key, value) {
      localStorage.setItem(key, value);
    },
    remove(key) {
      try { localStorage.removeItem(key); }
      catch (e) { console.warn('[Platform] storage remove failed', e); }
    },
  },

  // Opens a link outside the game (a new tab on the web)
  openExternal(url) {
    window.open(url, '_blank', 'noopener');
  },

  // Saves `text` as a file the player keeps (a download on the web)
  saveFile(filename, text, type = 'application/json') {
    const url = URL.createObjectURL(new Blob([text], { type }));
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  },

  // Asks the player for a file and resolves with its text, or null if they
  // cancel. Call it straight from a tap, or the browser blocks the picker.
  loadFile(accept = '.json,application/json') {
    return new Promise((resolve, reject) => {
      const input = document.createElement('input');
      input.type = 'file';
      input.accept = accept;
      input.hidden = true;
      const done = () => input.remove();
      input.addEventListener('cancel', () => { done(); resolve(null); });
      input.addEventListener('change', () => {
        const file = input.files && input.files[0];
        done();
        if (!file) return resolve(null);
        file.text().then(resolve, reject);
      });
      document.body.appendChild(input);
      input.click();
    });
  },
};
