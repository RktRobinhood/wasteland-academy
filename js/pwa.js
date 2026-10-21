const PWA = {
  init() {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('./service-worker.js')
        .then(reg => console.log('[PWA] SW registered', reg.scope))
        .catch(err => console.warn('[PWA] SW failed', err));
    }
    this._installPrompt();
  },

  _deferredPrompt: null,

  _installPrompt() {
    window.addEventListener('beforeinstallprompt', e => {
      e.preventDefault();
      this._deferredPrompt = e;
      this._showBanner();
    });
  },

  _showBanner() {
    const banner = document.getElementById('install-banner');
    if (banner) banner.classList.remove('hidden');
    const btn = document.getElementById('install-btn');
    if (btn) btn.addEventListener('click', () => this.install());
  },

  async install() {
    if (!this._deferredPrompt) return;
    this._deferredPrompt.prompt();
    const { outcome } = await this._deferredPrompt.userChoice;
    console.log('[PWA] Install outcome:', outcome);
    this._deferredPrompt = null;
    const banner = document.getElementById('install-banner');
    if (banner) banner.classList.add('hidden');
  }
};
