const WA = {
  VERSION: 1,   // save format version; see MIGRATIONS

  // ── Registered content packs ──────────────────────────────────
  packs: [],
  library: [],   // flat array of all questions

  registerPack(pack) {
    if (!pack || !pack.subtopics) return console.warn('[WA] Invalid pack', pack);
    this.packs.push(pack);
    pack.subtopics.forEach(st => {
      (st.questions || []).forEach(q => {
        q._packId   = pack.id;
        q._topicId  = pack.id;
        q._subtopic = q.subtopic || st.id;
        this.library.push(q);
      });
    });
    console.log(`[WA] Pack registered: ${pack.name} (${pack.subtopics.reduce((a,s)=>a+(s.questions||[]).length,0)} questions)`);
  },

  // ── Persistent state ──────────────────────────────────────────
  state: null,

  _defaultState() {
    return {
      version: WA.VERSION,
      profile: {
        name: '',
        avatar: null,
        scrap: 500,
        lifelines: { fifty: 1, freeze: 1, hint: 1 },
        perks: [],
        equipped: {}
      },
      progress: {
        islands: {}
      },
      stats: {
        runs: [],
        topicAccuracy: {},
        subtopicAccuracy: {},
        highScores: { endurance: 0, gauntlet: 0 }
      },
      spaced: {
        wanted: [],
        answered: 0
      }
    };
  },

  // ── Saves ──────────────────────────────────────────────────────
  // The save is one JSON string under SAVE_KEY, read and written through
  // Platform.storage. A save is never wiped because its format changed: it's
  // brought up to VERSION by MIGRATIONS instead.
  SAVE_KEY: 'wa_save',

  // MIGRATIONS[n] turns a version-n save into a version-(n + 1) save. To change
  // the save format: add the step here, then bump VERSION. Never remove a step,
  // so a save from any older version can still be brought up to date.
  MIGRATIONS: {},

  // Brings a parsed save up to VERSION and fills in any field it lacks.
  // Returns a new object and never changes `data`. Throws an Error whose
  // message can be shown to the player if `data` isn't a save it can use.
  migrate(data) {
    const fail = msg => { throw Object.assign(new Error(msg), { forPlayer: true }); };
    const isObj = v => !!v && typeof v === 'object' && !Array.isArray(v);
    if (!isObj(data) || !Number.isInteger(data.version) || data.version < 1)
      fail("That file isn't a Wasteland Academy save. Nothing was changed.");
    if (data.version > this.VERSION)
      fail('That save is from a newer version of the game. Update the game, then try again. Nothing was changed.');

    let s = JSON.parse(JSON.stringify(data));
    for (let n = s.version; n < this.VERSION; n++) {
      const step = this.MIGRATIONS[n];
      if (!step) throw new Error(`[WA] No save migration from version ${n}`);
      s = step(s);
      s.version = n + 1;
    }

    const ok = isObj(s.profile) && isObj(s.progress) && isObj(s.progress.islands) &&
      isObj(s.stats) && Array.isArray(s.stats.runs) &&
      isObj(s.spaced) && Array.isArray(s.spaced.wanted);
    if (!ok) fail('That save file is damaged, so it was not loaded. Nothing was changed.');
    return this._fillDefaults(s, this._defaultState());
  },

  // Adds any key `defaults` has and `s` lacks, at any depth. Never overwrites.
  _fillDefaults(s, defaults) {
    for (const [k, d] of Object.entries(defaults)) {
      if (s[k] === undefined) s[k] = d;
      else if (d && typeof d === 'object' && !Array.isArray(d) &&
               s[k] && typeof s[k] === 'object' && !Array.isArray(s[k])) this._fillDefaults(s[k], d);
    }
    return s;
  },

  // Turns a save file's text into a state, or throws an Error for the player
  parseSave(text) {
    let data;
    try { data = JSON.parse(text); }
    catch { data = null; }
    try { return this.migrate(data); }
    catch (e) {
      if (e.forPlayer) throw e;
      console.warn('[WA] Save migration failed', e);
      throw Object.assign(new Error('That save file is damaged, so it was not loaded. Nothing was changed.'), { forPlayer: true });
    }
  },

  load() {
    const raw = Platform.storage.get(this.SAVE_KEY);
    if (!raw) { this.state = this._defaultState(); return; }
    try {
      this.state = this.parseSave(raw);
    } catch (e) {
      // Never overwrite a save that can't be read: set it aside, then start fresh
      console.warn('[WA] Load failed, starting a new save', e);
      try { Platform.storage.set(`${this.SAVE_KEY}_unreadable_${Date.now()}`, raw); }
      catch (e2) { console.warn('[WA] Could not set the unreadable save aside', e2); }
      this.state = this._defaultState();
      this._loadProblem = true;
    }
  },

  save() {
    try { Platform.storage.set(this.SAVE_KEY, JSON.stringify(this.state)); }
    catch(e) { console.warn('[WA] Save failed', e); }
  },

  reset() {
    if (!confirm('WIPE ALL DATA? This cannot be undone.')) return;
    Platform.storage.remove(this.SAVE_KEY);
    location.reload();
  },

  exportSave() {
    const date = new Date().toISOString().slice(0, 10);
    Platform.saveFile(`wasteland-academy-save-${date}.json`, JSON.stringify(this.state, null, 2));
  },

  // Replaces the current save with one from a file. A file that can't be used
  // changes nothing: the new state is only swapped in once it's fully read,
  // migrated and stored.
  async importSave() {
    let text;
    try { text = await Platform.loadFile(); }
    catch (e) { return Toast.show("Couldn't read that file. Nothing was changed.", 'error', 4000); }
    if (text == null) return;

    let next;
    try { next = this.parseSave(text); }
    catch (e) { return Toast.show(e.message, 'error', 4000); }

    try { Platform.storage.set(this.SAVE_KEY, JSON.stringify(next)); }
    catch (e) { return Toast.show("Couldn't store the save on this device. Nothing was changed.", 'error', 4000); }

    this.state = next;
    SR.init(next);
    Stats.init(next);
    this.unlockStartingNodes();
    UI.updateScrapDisplay();
    Toast.show('Save loaded!', 'success');
    Router.go(next.profile.name && next.profile.avatar ? 'world' : 'profile');
  },

  // ── Island progress helpers ───────────────────────────────────
  getIslandProgress(islandId) {
    return this.state.progress.islands[islandId] || {};
  },

  setNodeState(islandId, nodeId, st) {
    if (!this.state.progress.islands[islandId])
      this.state.progress.islands[islandId] = {};
    this.state.progress.islands[islandId][nodeId] = st;
    this.save();
  },

  getNodeState(islandId, nodeId) {
    return (this.state.progress.islands[islandId] || {})[nodeId] || 'locked';
  },

  unlockStartingNodes() {
    this.packs.forEach(pack => {
      const islandId = pack.island;
      pack.subtopics.forEach(st => {
        if (!st.prerequisite) {
          if (this.getNodeState(islandId, st.id) === 'locked')
            this.setNodeState(islandId, st.id, 'available');
        }
      });
    });
  },

  unlockNextNodes(islandId, completedNodeId) {
    const pack = this.packs.find(p => p.island === islandId);
    if (!pack) return;
    pack.subtopics.forEach(st => {
      if (st.prerequisite === completedNodeId) {
        if (this.getNodeState(islandId, st.id) === 'locked')
          this.setNodeState(islandId, st.id, 'available');
      }
    });
  },

  // ── Question helpers ──────────────────────────────────────────
  getQuestionsForSubtopic(subtopicId) {
    return this.library.filter(q => q._subtopic === subtopicId);
  },

  getQuestionsForIsland(islandId) {
    return this.library.filter(q => q._packId === islandId ||
      this.packs.find(p => p.island === islandId && p.id === q._packId));
  },

  getQuestionsForTopics(topicIds, difficultyRange = [1, 5]) {
    return this.library.filter(q =>
      topicIds.includes(q._packId) &&
      q.difficulty >= difficultyRange[0] &&
      q.difficulty <= difficultyRange[1]
    );
  },

  // ── Economy ───────────────────────────────────────────────────
  addScrap(amount) {
    this.state.profile.scrap = Math.max(0, this.state.profile.scrap + amount);
    this.save();
    UI.updateScrapDisplay();
  },

  spendScrap(amount) {
    if (this.state.profile.scrap < amount) return false;
    this.state.profile.scrap -= amount;
    this.save();
    UI.updateScrapDisplay();
    return true;
  },

  // ── Boot ──────────────────────────────────────────────────────
  async init() {
    console.log('[WA] Booting Wasteland Academy...');
    this.load();
    SR.init(this.state);
    Stats.init(this.state);

    await new Promise(r => setTimeout(r, 100));  // allow packs to register

    this.unlockStartingNodes();

    const loaderBar = document.getElementById('loader-bar');
    let progress = 0;
    const tick = setInterval(() => {
      progress = Math.min(progress + Math.random() * 20, 90);
      if (loaderBar) loaderBar.style.width = progress + '%';
    }, 120);

    await new Promise(r => setTimeout(r, 800));
    clearInterval(tick);
    if (loaderBar) loaderBar.style.width = '100%';
    await new Promise(r => setTimeout(r, 300));

    if (!this.state.profile.name || !this.state.profile.avatar) {
      Router.go('profile');
    } else {
      Router.go('world');
    }
    if (this._loadProblem) Toast.show("Your old save couldn't be read, so a new one was started. The old one is kept on this device.", 'warn', 6000);
  }
};

// ── Toast helper ──────────────────────────────────────────────
const Toast = {
  show(msg, type = 'info', duration = 2000) {
    const container = document.getElementById('toast-container');
    if (!container) return;
    const el = document.createElement('div');
    el.className = `toast ${type}`;
    el.textContent = msg;
    // The CSS fade-out starts at 1.7 s; move it so a longer toast stays readable
    el.style.animationDelay = `0s, ${Math.max(0, duration - 300) / 1000}s`;
    container.appendChild(el);
    setTimeout(() => el.remove(), duration + 100);
  }
};

// ── Generic UI helpers ────────────────────────────────────────
const UI = {
  updateScrapDisplay() {
    document.querySelectorAll('.scrap-display').forEach(el => {
      el.textContent = WA.state?.profile?.scrap ?? 0;
    });
  }
};
