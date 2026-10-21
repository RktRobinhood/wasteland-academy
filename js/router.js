const Router = {
  _current: 'loader',

  SCREENS: [
    'loader', 'profile', 'world', 'island',
    'td-config', 'combat', 'debrief', 'stats', 'bazaar'
  ],

  go(screenId, data = {}) {
    this.SCREENS.forEach(id => {
      const el = document.getElementById(`screen-${id}`);
      if (el) el.classList.toggle('hidden', id !== screenId);
    });
    this._current = screenId;
    this._onEnter(screenId, data);
  },

  _onEnter(screenId, data) {
    switch(screenId) {
      case 'world':    WorldScreen.render();                           break;
      case 'island':   IslandScreen.render(data);                     break;
      case 'td-config': TDConfigScreen.render();                      break;
      case 'combat':   if (!data?._combatAlreadyStarted) Combat.start(data); break;
      case 'debrief':  DebriefScreen.render(data);                    break;
      case 'stats':    StatsScreen.render();                          break;
      case 'bazaar':   BazaarScreen.render();                         break;
      case 'profile':  ProfileScreen.render();                        break;
    }
  },

  back() {
    const backMap = {
      'island':    'world',
      'td-config': 'world',
      'stats':     'world',
      'bazaar':    'world',
      'debrief':   'world',
    };
    const target = backMap[this._current];
    if (target) this.go(target);
  }
};

// ── Profile Setup Screen ──────────────────────────────────────
const ProfileScreen = {
  render() {
    const nameInput = document.getElementById('profile-name');
    if (nameInput) nameInput.value = WA.state.profile.name || '';
    this._selectAvatar(WA.state.profile.avatar || 'female');
    Art.scan(document.querySelector('.avatar-grid'));
  },

  _selectAvatar(id) {
    document.querySelectorAll('.avatar-choice').forEach(el => {
      el.classList.toggle('selected', el.dataset.avatar === id);
    });
    WA.state.profile.avatar = id;
  },

  confirm() {
    const name = document.getElementById('profile-name')?.value?.trim();
    if (!name || name.length < 2) return Toast.show('Enter a callsign (min 2 chars)', 'error');
    WA.state.profile.name = name;
    WA.save();
    Router.go('world');
  },

  selectAvatar(id) { this._selectAvatar(id); }
};

// ── World Map Screen ──────────────────────────────────────────
const WorldScreen = {
  ISLANDS: [
    { id: 'topic-1-algebra',   name: 'Scrap Fields',    topic: 'Numbers & Algebra',       icon: '⚙️',  art: 'scrap-fields',  pos: { top: '20%', left: '12%' } },
    { id: 'topic-2-functions', name: 'Signal Tower',    topic: 'Functions',                icon: '📡', art: 'signal-tower',  pos: { top: '15%', right: '12%' } },
    { id: 'topic-3-geometry',  name: 'Dry Flats',       topic: 'Geometry & Trig',         icon: '📐', art: 'dry-flats',     pos: { top: '50%', left: '8%' } },
    { id: 'topic-4-stats',     name: 'Radio Spires',    topic: 'Stats & Probability',     icon: '📊', art: 'radio-spires',  pos: { top: '50%', right: '8%' } },
    { id: 'topic-5-calculus',  name: 'Engine Core',     topic: 'Calculus',                icon: '⚡', art: 'engine-core',   pos: { bottom: '20%', left: '50%', transform: 'translateX(-50%)' } },
  ],

  render() {
    UI.updateScrapDisplay();
    const grid = document.getElementById('world-islands');
    if (!grid) return;
    grid.innerHTML = '';

    this.ISLANDS.forEach(island => {
      const pack = WA.packs.find(p => p.id === island.id);
      const cleared = this._isCleared(island.id, pack);
      const hasQuestions = pack && pack.subtopics.some(s => (s.questions||[]).length > 0);

      const el = document.createElement('button');
      el.className = `island-node ${cleared ? 'cleared' : ''} ${!hasQuestions ? 'locked' : ''}`;
      el.innerHTML = `
        <img class="island-art hidden" data-art="assets/map/island-${island.art}.png" alt="">
        <div class="island-icon art-fallback">${island.icon}</div>
        <div class="island-name">${island.name}</div>
        <div class="island-topic">${island.topic}</div>
        ${cleared ? '<div class="island-cleared-badge">✓ CLEARED</div>' : ''}
        ${!hasQuestions ? '<div class="island-locked-badge">NO DATA</div>' : ''}
      `;
      if (hasQuestions) el.onclick = () => Router.go('island', { islandId: island.id, island });
      grid.appendChild(el);
    });
    Art.scan(grid);
    Art.scan(document.querySelector('.thunderdome-btn'));

    const nameEl = document.getElementById('world-player-name');
    if (nameEl) nameEl.textContent = WA.state.profile.name;

    const av = WA.state.profile.avatar || 'female';
    Art.show(document.getElementById('world-player-avatar'), `assets/avatars/avatar-${av}.png`);
  },

  _isCleared(islandId, pack) {
    if (!pack) return false;
    return pack.subtopics.every(st =>
      WA.getNodeState(islandId, st.id) === 'cleared'
    );
  }
};

// ── Island Node Map Screen ────────────────────────────────────
const IslandScreen = {
  _current: null,

  render({ islandId, island } = {}) {
    this._current = { islandId, island };
    const pack = WA.packs.find(p => p.id === islandId);
    if (!pack) return;

    const title = document.getElementById('island-title');
    if (title) title.textContent = island.name;

    const topic = document.getElementById('island-topic');
    if (topic) topic.textContent = island.topic;

    const grid = document.getElementById('island-nodes');
    if (!grid) return;
    grid.innerHTML = '';

    pack.subtopics.forEach(st => {
      const nodeState = WA.getNodeState(islandId, st.id);
      const qs = (st.questions || []).length;

      const el = document.createElement('button');
      el.className = `node-btn node-${nodeState}`;
      el.disabled = nodeState === 'locked';

      const wantedCount = WA.state.spaced.wanted.filter(w => w.subtopic === st.id).length;
      el.innerHTML = `
        <div class="node-name">${st.name}</div>
        <div class="node-meta">${qs} questions</div>
        ${nodeState === 'cleared' ? '<div class="node-state-icon">✓</div>' : ''}
        ${nodeState === 'locked'  ? '<div class="node-state-icon">🔒</div>' : ''}
        ${wantedCount > 0 ? `<div class="node-wanted-badge">${wantedCount} WANTED</div>` : ''}
      `;

      if (nodeState !== 'locked') {
        el.onclick = () => Router.go('combat', {
          mode: 'island',
          islandId,
          subtopicId: st.id,
          subtopicName: st.name
        });
      }
      grid.appendChild(el);
    });
  }
};

// ── Thunderdome Config Screen ─────────────────────────────────
const TDConfigScreen = {
  _selectedTopics: new Set(),
  _selectedMode: 'endurance',

  render() {
    this._selectedTopics = new Set(WA.packs.map(p => p.id));
    this._selectedMode = 'endurance';
    this._buildTopicToggles();
    this._updateModeButtons();
    this._updateHighScores();
  },

  _buildTopicToggles() {
    const container = document.getElementById('td-topic-toggles');
    if (!container) return;
    container.innerHTML = '';
    WA.packs.forEach(pack => {
      const btn = document.createElement('button');
      btn.className = 'topic-toggle active';
      btn.dataset.packId = pack.id;
      btn.textContent = pack.name;
      btn.onclick = () => this._toggleTopic(pack.id, btn);
      container.appendChild(btn);
    });
  },

  _toggleTopic(id, btn) {
    if (this._selectedTopics.has(id)) {
      if (this._selectedTopics.size <= 1) return Toast.show('Select at least one topic', 'warn');
      this._selectedTopics.delete(id);
      btn.classList.remove('active');
    } else {
      this._selectedTopics.add(id);
      btn.classList.add('active');
    }
  },

  _updateModeButtons() {
    document.querySelectorAll('.mode-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.mode === this._selectedMode);
    });
  },

  _updateHighScores() {
    const hs = WA.state.stats.highScores;
    const el = document.getElementById('td-high-scores');
    if (el) el.innerHTML = `
      <span>ENDURANCE BEST: <b class="neon-dust">${hs.endurance || 0}</b></span>
      <span>GAUNTLET BEST: <b class="neon-magenta">${hs.gauntlet || 0}</b></span>
    `;
  },

  selectMode(mode) {
    this._selectedMode = mode;
    this._updateModeButtons();
  },

  start() {
    const topics = [...this._selectedTopics];
    if (topics.length === 0) return Toast.show('Select at least one topic', 'warn');
    Router.go('combat', {
      mode: this._selectedMode,
      topicIds: topics,
      islandId: null
    });
  }
};

// A WANTED board entry's badge: the art, or a text badge without it
const WANTED_BADGE = `<img class="wanted-badge-img hidden" data-art="assets/ui/wanted-badge.png" alt="WANTED">`
  + `<span class="badge badge-rust art-fallback">WANTED</span>`;

// ── Debrief Screen ────────────────────────────────────────────
const DebriefScreen = {
  render(data = {}) {
    const { score = 0, mode = '', runHistory = [], duration = 0 } = data;

    const scoreEl = document.getElementById('debrief-score');
    if (scoreEl) scoreEl.textContent = score;

    const modeEl = document.getElementById('debrief-mode');
    if (modeEl) modeEl.textContent = mode.toUpperCase();

    this._renderWanted();
    this._renderTrend();
    this._renderSpider(runHistory);

    const hs = WA.state.stats.highScores;
    if (mode === 'endurance' && score > (hs.endurance || 0)) {
      hs.endurance = score;
      WA.save();
      Toast.show('🏆 NEW HIGH SCORE!', 'success', 3000);
    }
    if (mode === 'gauntlet' && score > (hs.gauntlet || 0)) {
      hs.gauntlet = score;
      WA.save();
      Toast.show('🏆 NEW HIGH SCORE!', 'success', 3000);
    }
  },

  _renderSpider(runHistory) {
    const canvas = document.getElementById('debrief-spider');
    if (!canvas) return;

    const thisRun = Stats.getThisRunAccuracy(runHistory);
    const overall = Stats.getTopicAccuracy();

    const labels = {
      'topic-1-algebra':   'Algebra',
      'topic-2-functions': 'Functions',
      'topic-3-geometry':  'Geometry',
      'topic-4-stats':     'Stats',
      'topic-5-calculus':  'Calculus'
    };

    const isOverall = document.getElementById('debrief-spider-toggle')?.dataset.view === 'overall';
    Stats.drawSpiderDiagram(canvas, isOverall ? overall : thisRun, labels);
  },

  toggleSpider() {
    const btn = document.getElementById('debrief-spider-toggle');
    if (!btn) return;
    const current = btn.dataset.view || 'run';
    const next = current === 'run' ? 'overall' : 'run';
    btn.dataset.view = next;
    btn.textContent = next === 'run' ? 'THIS RUN' : 'OVERALL';
    this._renderSpider(this._lastRunHistory || []);
  },

  _renderWanted() {
    const el = document.getElementById('debrief-wanted');
    if (!el) return;
    const wanted = SR.getAll();
    if (wanted.length === 0) { el.innerHTML = '<p class="text-dim text-sm">No bounties active</p>'; return; }
    el.innerHTML = wanted.slice(0, 8).map(w => `
      <div class="wanted-item">
        ${WANTED_BADGE}
        <span class="wanted-subtopic text-sm">${w.subtopic}</span>
        <span class="text-dim text-xs">${w.attempts} attempt${w.attempts !== 1 ? 's' : ''}</span>
      </div>
    `).join('') + (wanted.length > 8 ? `<p class="text-dim text-xs">+${wanted.length - 8} more</p>` : '');
    Art.scan(el);
  },

  _renderTrend() {
    const el = document.getElementById('debrief-trend');
    if (!el) return;
    const improvements = Stats.getTopImprovements(3);
    if (improvements.length === 0) { el.classList.add('hidden'); return; }
    el.classList.remove('hidden');
    const topicNames = {
      'topic-1-algebra':   'Algebra',
      'topic-2-functions': 'Functions',
      'topic-3-geometry':  'Geometry',
      'topic-4-stats':     'Stats',
      'topic-5-calculus':  'Calculus'
    };
    el.innerHTML = `<div class="trend-title">📈 IMPROVING</div>` +
      improvements.map(imp => `
        <div class="trend-item">
          <span>${topicNames[imp.topicId] || imp.topicId}</span>
          <span class="neon-teal">+${Math.round(imp.delta * 100)}%</span>
        </div>
      `).join('');
  },

  _lastRunHistory: []
};

// ── Stats Screen ──────────────────────────────────────────────
const StatsScreen = {
  render() {
    const overall = Stats.getTopicAccuracy();
    const labels = {
      'topic-1-algebra':   'Algebra',
      'topic-2-functions': 'Functions',
      'topic-3-geometry':  'Geometry',
      'topic-4-stats':     'Stats',
      'topic-5-calculus':  'Calculus'
    };
    const canvas = document.getElementById('stats-spider');
    if (canvas) Stats.drawSpiderDiagram(canvas, overall, labels);

    const wanted = SR.getAll();
    const wantedEl = document.getElementById('stats-wanted');
    if (wantedEl) {
      wantedEl.innerHTML = wanted.length === 0
        ? '<p class="text-dim text-sm">No active bounties — you\'re clean, Scavenger.</p>'
        : wanted.map(w => `
          <div class="wanted-item">
            ${WANTED_BADGE}
            <span class="wanted-subtopic">${w.subtopic}</span>
            <span class="text-dim text-xs">${w.attempts} miss${w.attempts !== 1 ? 'es' : ''}</span>
          </div>
        `).join('');
      Art.scan(wantedEl);
    }

    const runsEl = document.getElementById('stats-runs');
    if (runsEl) {
      const runs = [...WA.state.stats.runs].reverse().slice(0, 10);
      runsEl.innerHTML = runs.length === 0
        ? '<p class="text-dim text-sm">No runs recorded yet.</p>'
        : runs.map(r => `
          <div class="run-item">
            <span class="badge badge-teal">${r.mode?.toUpperCase()}</span>
            <span class="run-score neon-dust">${r.score}</span>
            <span class="text-dim text-xs">${new Date(r.ts).toLocaleDateString()}</span>
          </div>
        `).join('');
    }
  }
};

// ── Bazaar (Shop) Screen ──────────────────────────────────────
const BazaarScreen = {
  ITEMS: [
    { id: 'refill-lifelines', name: 'Refill All Lifelines', desc: 'Restore 50-50, Freeze and Hint', cost: 150,
      action: () => { WA.state.profile.lifelines = { fifty: 1, freeze: 1, hint: 1 }; WA.save(); Toast.show('Lifelines restored!', 'success'); } },
    { id: 'perk-armour', name: 'Scrap Armour', desc: 'Start next run with +20 HP', cost: 200,
      action: () => { if (!WA.state.profile.perks.includes('armour')) WA.state.profile.perks.push('armour'); WA.save(); Toast.show('Perk active for next run!', 'success'); } },
    { id: 'perk-time', name: 'Field Watch', desc: 'All timers +10s for next run', cost: 175,
      action: () => { if (!WA.state.profile.perks.includes('time')) WA.state.profile.perks.push('time'); WA.save(); Toast.show('Perk active for next run!', 'success'); } },
    { id: 'perk-hint-free', name: 'Spark\'s Notes', desc: 'Hints are free this run', cost: 250,
      action: () => { if (!WA.state.profile.perks.includes('hint-free')) WA.state.profile.perks.push('hint-free'); WA.save(); Toast.show('Perk active for next run!', 'success'); } },
  ],

  render() {
    const scrapEl = document.getElementById('bazaar-scrap');
    if (scrapEl) scrapEl.textContent = WA.state.profile.scrap;

    const grid = document.getElementById('bazaar-grid');
    if (!grid) return;
    grid.innerHTML = this.ITEMS.map(item => `
      <div class="bazaar-item">
        <div class="bazaar-item-name">${item.name}</div>
        <div class="bazaar-item-desc text-dim text-sm">${item.desc}</div>
        <button class="btn btn-scrap bazaar-buy-btn" data-item="${item.id}"
          ${WA.state.profile.scrap < item.cost ? 'disabled' : ''}>
          Buy — ⚙ ${item.cost}
        </button>
      </div>
    `).join('');

    grid.querySelectorAll('.bazaar-buy-btn').forEach(btn => {
      btn.onclick = () => this._buy(btn.dataset.item);
    });
  },

  _buy(itemId) {
    const item = this.ITEMS.find(i => i.id === itemId);
    if (!item) return;
    if (!WA.spendScrap(item.cost)) return Toast.show('Not enough Scrap', 'error');
    item.action();
    this.render();
  }
};
