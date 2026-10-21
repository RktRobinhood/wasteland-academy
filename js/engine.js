const WA = {
  VERSION: 1,

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

  load() {
    try {
      const raw = localStorage.getItem('wa_save');
      if (!raw) { this.state = this._defaultState(); return; }
      const parsed = JSON.parse(raw);
      if (parsed.version !== this.VERSION) {
        console.warn('[WA] Save version mismatch — resetting');
        this.state = this._defaultState();
        return;
      }
      this.state = parsed;
    } catch(e) {
      console.warn('[WA] Load failed', e);
      this.state = this._defaultState();
    }
  },

  save() {
    try { localStorage.setItem('wa_save', JSON.stringify(this.state)); }
    catch(e) { console.warn('[WA] Save failed', e); }
  },

  reset() {
    if (!confirm('WIPE ALL DATA? This cannot be undone.')) return;
    localStorage.removeItem('wa_save');
    location.reload();
  },

  exportSave() {
    const blob = new Blob([JSON.stringify(this.state, null, 2)], { type: 'application/json' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `wasteland-academy-save-${Date.now()}.json`;
    a.click();
  },

  importSave(file) {
    const reader = new FileReader();
    reader.onload = e => {
      try {
        const data = JSON.parse(e.target.result);
        if (data.version !== this.VERSION) return Toast.show('Incompatible save file', 'error');
        this.state = data;
        this.save();
        Toast.show('Save loaded!', 'success');
        Router.go('world');
      } catch { Toast.show('Invalid save file', 'error'); }
    };
    reader.readAsText(file);
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
