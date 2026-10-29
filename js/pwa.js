// Web-only install support. An app build doesn't need any of this: there the
// service worker isn't registered and neither install prompt ever shows.
const PWA = {
  IOS_TIP_KEY: 'wa_ios_install_tip_seen',

  init() {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('./service-worker.js')
        .then(reg => console.log('[PWA] SW registered', reg.scope))
        .catch(err => console.warn('[PWA] SW failed', err));
    }

    // Chromium: the INSTALL APP button on the world screen shows only once the
    // browser says the game can be installed
    window.addEventListener('beforeinstallprompt', e => {
      e.preventDefault();
      this._deferredPrompt = e;
      this._showInstallButton(true);
    });
    window.addEventListener('appinstalled', () => {
      this._deferredPrompt = null;
      this._showInstallButton(false);
    });

    // With the takeover switch on (README, "Switching to Godot") this game is at
    // classic/, and the new version is at the site root
    const newVersion = document.getElementById('new-version-link');
    if (newVersion && /\/classic\/(index\.html)?$/.test(location.pathname)) {
      newVersion.href = '../';
      newVersion.classList.remove('hidden');
    }

    // iOS has no install prompt, so explain Add to Home Screen, once
    if (this._isIOS() && !this._isStandalone() && !Platform.storage.get(this.IOS_TIP_KEY)) {
      document.getElementById('ios-install-tip')?.classList.remove('hidden');
    }
  },

  _deferredPrompt: null,

  _showInstallButton(show) {
    document.getElementById('install-btn')?.classList.toggle('hidden', !show);
  },

  async install() {
    const prompt = this._deferredPrompt;
    if (!prompt) return;
    this._deferredPrompt = null;
    this._showInstallButton(false);
    prompt.prompt();
    const { outcome } = await prompt.userChoice;
    console.log('[PWA] Install outcome:', outcome);
  },

  dismissIOSTip() {
    document.getElementById('ios-install-tip')?.classList.add('hidden');
    try { Platform.storage.set(this.IOS_TIP_KEY, '1'); }
    catch (e) { console.warn('[PWA] Could not store the tip flag', e); }
  },

  // iPadOS reports itself as a Mac, so a Mac with a touch screen counts as iOS
  _isIOS() {
    return /iphone|ipad|ipod/i.test(navigator.userAgent) ||
      (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  },

  _isStandalone() {
    return navigator.standalone === true || window.matchMedia?.('(display-mode: standalone)').matches;
  },
};
