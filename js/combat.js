// ── COMBAT MODULE ─────────────────────────────────────────────
const Combat = {
  // Timers by difficulty (seconds)
  TIMERS: { 1: 60, 2: 45, 3: 30, 4: 25, 5: 15 },

  // Scrap rewards — INVERTED: harder = less (productive struggle incentive)
  SCRAP_REWARDS: { 1: 40, 2: 30, 3: 20, 4: 15, 5: 10 },

  // Enemy info by difficulty
  ENEMIES: {
    1: { name: 'Scavenger',  hp: 3,  img: 'd1-scavenger.png',  dmg: 20, rank: 'RECRUIT' },
    2: { name: 'Raider',     hp: 4,  img: 'd2-raider.png',     dmg: 25, rank: 'OPERATIVE' },
    3: { name: 'Enforcer',   hp: 5,  img: 'd3-enforcer.png',   dmg: 30, rank: 'SERGEANT' },
    4: { name: 'Warlord',    hp: 5,  img: 'd4-warlord.png',    dmg: 35, rank: 'COMMANDER' },
    5: { name: 'OVERSEER',   hp: 6,  img: 'd5-overseer.png',   dmg: 45, rank: 'OVERSEER' },
  },

  // Player base HP
  BASE_HP: 100,

  _run: null,

  // ── Entry point ───────────────────────────────────────────────
  start(config) {
    const perkArmour = WA.state.profile.perks.includes('armour');
    const perkTime   = WA.state.profile.perks.includes('time');
    const perkHintFree = WA.state.profile.perks.includes('hint-free');

    this._run = {
      mode:        config.mode,         // 'island' | 'endurance' | 'gauntlet'
      islandId:    config.islandId || null,
      subtopicId:  config.subtopicId || null,
      topicIds:    config.topicIds || (config.islandId ? [config.islandId] : []),
      hp:          this.BASE_HP + (perkArmour ? 20 : 0),
      maxHp:       this.BASE_HP + (perkArmour ? 20 : 0),
      score:       0,
      wave:        0,
      questionHistory: [],
      runTopicBreakdown: {},
      lifelines: { ...WA.state.profile.lifelines },
      perkTime,
      perkHintFree,
      startTs:     Date.now(),
      active:      true,
      _timerInterval: null,
      _currentQuestion: null,
      _frozenTime: null,
    };

    // Consume perks
    WA.state.profile.perks = WA.state.profile.perks.filter(
      p => !['armour','time','hint-free'].includes(p)
    );

    // Navigate without re-triggering Combat.start
    Router.go('combat', { _combatAlreadyStarted: true });
    this._nextEnemy();
  },

  // Called by Router._onEnter('combat', data) — but we need to avoid double-init
  // So Router.go('combat') with data that has _alreadyStarted skips this
  _nextEnemy() {
    if (!this._run?.active) return;
    this._run.wave++;

    const diff = this._chooseDifficulty();
    const enemy = { ...this.ENEMIES[diff], difficulty: diff, currentHp: this.ENEMIES[diff].hp, maxHp: this.ENEMIES[diff].hp };
    this._run._currentEnemy = enemy;

    this._renderCombatUI();
    this._nextQuestion();
  },

  _chooseDifficulty() {
    const mode = this._run.mode;
    if (mode === 'island') {
      // Island nodes: D1–D2 normally, D3 mini-boss every 5th, D4 every 10th, D5 boss at end
      const wave = this._run.wave;
      if (wave % 10 === 0) return 5;
      if (wave % 5  === 0) return 4;
      if (wave % 3  === 0) return 3;
      return Math.random() < 0.6 ? 1 : 2;
    }
    if (mode === 'endurance') {
      // Escalates with score
      const score = this._run.score;
      if (score >= 500) return Math.floor(Math.random() * 2) + 4;  // D4-D5
      if (score >= 300) return Math.floor(Math.random() * 2) + 3;  // D3-D4
      if (score >= 150) return Math.floor(Math.random() * 2) + 2;  // D2-D3
      return Math.floor(Math.random() * 2) + 1;                     // D1-D2
    }
    if (mode === 'gauntlet') {
      // Fixed wave progression
      const wave = this._run.wave;
      return Math.min(5, Math.ceil(wave / 3));
    }
    return 1;
  },

  // ── Question selection ────────────────────────────────────────
  _nextQuestion() {
    if (!this._run?.active) return;

    const diff = this._run._currentEnemy.difficulty;
    let pool = this._buildPool();

    // SR: check for WANTED questions
    const question = SR.selectNext(pool, this._run.subtopicId ? [this._run.subtopicId] : null);
    if (!question) {
      Toast.show('No questions available!', 'error');
      this._endRun('no-questions');
      return;
    }

    this._run._currentQuestion = question;
    this._run._currentQuestion._isWanted = SR.isWanted(question.id);

    // For D1-D2, multi-part not allowed; for D3-D5 allow if present
    if (question.type === 'multipart' && diff < 3) {
      // Re-pick a non-multipart question
      const fallback = pool.find(q => q.type !== 'multipart' && q.difficulty === diff);
      if (fallback) this._run._currentQuestion = fallback;
    }

    this._renderQuestion(this._run._currentQuestion);
    this._startTimer(diff);
  },

  _buildPool() {
    const run = this._run;
    let pool = [];

    if (run.subtopicId) {
      pool = WA.getQuestionsForSubtopic(run.subtopicId);
    } else if (run.topicIds?.length > 0) {
      pool = WA.getQuestionsForTopics(run.topicIds);
    } else {
      pool = [...WA.library];
    }

    // Filter out recently answered (SR breathing room)
    return SR.tick(), pool.filter(q => !SR.isWanted(q.id) || SR.getDue().includes(q));
  },

  // ── Timer ─────────────────────────────────────────────────────
  _startTimer(difficulty) {
    if (this._run._timerInterval) clearInterval(this._run._timerInterval);
    this._run._frozenTime = null;

    let seconds = this.TIMERS[difficulty] + (this._run.perkTime ? 10 : 0);
    this._run._timeLeft = seconds;
    this._run._timerTotal = seconds;

    this._updateTimerDisplay(seconds, seconds);

    this._run._timerInterval = setInterval(() => {
      if (!this._run?.active) return clearInterval(this._run._timerInterval);
      if (this._run._frozenTime !== null) return;  // frozen lifeline

      seconds--;
      this._run._timeLeft = seconds;
      this._updateTimerDisplay(seconds, this._run._timerTotal);

      if (seconds <= 0) {
        clearInterval(this._run._timerInterval);
        this._resolveAnswer(null, 'timeout');
      }
    }, 1000);
  },

  _stopTimer() {
    if (this._run?._timerInterval) clearInterval(this._run._timerInterval);
  },

  _updateTimerDisplay(left, total) {
    const bar  = document.getElementById('timer-bar');
    const text = document.getElementById('timer-text');
    if (bar)  bar.style.width  = `${(left / total) * 100}%`;
    if (text) text.textContent = left;

    // Colour shift: green → yellow → red
    if (bar) {
      if (left / total < 0.2) bar.style.background = 'var(--col-magenta)';
      else if (left / total < 0.5) bar.style.background = 'var(--col-rust)';
      else bar.style.background = 'var(--col-teal)';
    }
  },

  // ── Answer submission ─────────────────────────────────────────
  submitMCQ(optionIndex) {
    if (!this._run?._currentQuestion) return;
    const q = this._run._currentQuestion;
    if (q.type !== 'mcq') return;
    const correct = optionIndex === q.correctIndex;
    this._resolveAnswer(correct ? q.options[optionIndex] : null, correct ? 'correct' : 'wrong');
  },

  submitValue() {
    const input = document.getElementById('numpad-display');
    if (!input || !this._run?._currentQuestion) return;
    const raw = input.textContent.trim();
    if (!raw) return Toast.show('Enter a value', 'warn');

    const q = this._run._currentQuestion;
    const correct = this._checkValueAnswer(raw, q);
    this._resolveAnswer(raw, correct ? 'correct' : 'wrong');
  },

  _checkValueAnswer(raw, q) {
    const tolerance = q.tolerance ?? 0.01;
    const student = this._parseValue(raw);
    const expected = this._parseValue(String(q.answer));
    if (student === null || expected === null) return false;
    return Math.abs(student - expected) <= Math.abs(expected) * tolerance + 0.001;
  },

  _parseValue(str) {
    str = str.trim().replace('×', '*').replace('−', '-');
    if (str.includes('/')) {
      const parts = str.split('/');
      if (parts.length === 2) return parseFloat(parts[0]) / parseFloat(parts[1]);
    }
    const n = parseFloat(str);
    return isNaN(n) ? null : n;
  },

  _resolveAnswer(submittedValue, outcome) {
    if (!this._run?.active) return;
    this._stopTimer();

    const q = this._run._currentQuestion;
    const diff = this._run._currentEnemy.difficulty;
    const timeLeft = this._run._timeLeft;
    const timerTotal = this._run._timerTotal;
    const isLate = timeLeft / timerTotal < 0.2;  // last 20% of time

    let isCorrect = (outcome === 'correct');
    let resultType = outcome;  // 'correct' | 'complication' | 'wrong' | 'timeout'

    if (isCorrect && isLate && outcome !== 'timeout') {
      resultType = 'complication';  // Success with complication — chip damage
    }
    if (outcome === 'timeout') {
      isCorrect = false;
      resultType = 'timeout';
    }

    // Record in SR
    if (!isCorrect) {
      SR.flag(q.id, q._subtopic || q.subtopic);
    } else {
      SR.clear(q.id);
    }
    SR.tick();

    // Stats
    const topicId = q._packId || q._topicId;
    Stats.recordAnswer({
      questionId: q.id,
      subtopic:   q._subtopic || q.subtopic,
      topicId,
      difficulty: diff,
      correct:    isCorrect,
      isWanted:   q._isWanted
    });

    // Track per-topic breakdown for run
    if (!this._run.runTopicBreakdown[topicId])
      this._run.runTopicBreakdown[topicId] = { correct: 0, total: 0 };
    this._run.runTopicBreakdown[topicId].total++;
    if (isCorrect) this._run.runTopicBreakdown[topicId].correct++;

    // History entry
    this._run.questionHistory.push({ questionId: q.id, topicId, correct: isCorrect });

    // Apply outcome effects
    if (isCorrect || resultType === 'complication') {
      // Hit the enemy
      this._run._currentEnemy.currentHp--;
      const scrap = Math.round(this.SCRAP_REWARDS[diff] * (resultType === 'complication' ? 0.6 : 1));
      WA.addScrap(scrap);

      if (resultType === 'complication') {
        // Chip damage for late answer
        const chipDmg = Math.round(this._run._currentEnemy.dmg * 0.25);
        this._run.hp = Math.max(0, this._run.hp - chipDmg);
        this._showOutcome('complication', q, chipDmg, scrap);
      } else {
        this._run.score += diff * 10;
        this._showOutcome('correct', q, 0, scrap);
      }

      if (this._run._currentEnemy.currentHp <= 0) {
        // Enemy defeated
        setTimeout(() => this._onEnemyDefeated(), 1800);
      } else {
        setTimeout(() => this._nextQuestion(), 1800);
      }
    } else {
      // Wrong / timeout → take damage
      const dmg = this._run._currentEnemy.dmg + (outcome === 'timeout' ? 10 : 0);
      this._run.hp = Math.max(0, this._run.hp - dmg);
      this._showOutcome(resultType, q, dmg, 0);

      if (this._run.hp <= 0) {
        setTimeout(() => this._endRun('dead'), 1800);
      } else {
        setTimeout(() => this._nextQuestion(), 2000);
      }
    }

    this._updateHPBars();
  },

  _onEnemyDefeated() {
    if (!this._run?.active) return;
    // Mark node cleared if island mode
    if (this._run.mode === 'island' && this._run.islandId && this._run.subtopicId) {
      WA.setNodeState(this._run.islandId, this._run.subtopicId, 'cleared');
      WA.unlockNextNodes(this._run.islandId, this._run.subtopicId);
      // Island mode: one enemy per node, then end
      this._endRun('cleared');
      return;
    }
    // Thunderdome modes: next enemy
    this._nextEnemy();
  },

  _endRun(reason) {
    if (!this._run) return;
    this._run.active = false;
    this._stopTimer();

    const duration = Math.round((Date.now() - this._run.startTs) / 1000);
    Stats.recordRun({
      mode:          this._run.mode,
      config:        { topicIds: this._run.topicIds, subtopicId: this._run.subtopicId },
      score:         this._run.score,
      topicBreakdown: this._run.runTopicBreakdown,
      duration
    });

    const runHistory = [...this._run.questionHistory];
    const score      = this._run.score;
    const mode       = this._run.mode;
    this._run = null;

    DebriefScreen._lastRunHistory = runHistory;
    Router.go('debrief', { score, mode, runHistory, duration });
  },

  // ── Lifelines ─────────────────────────────────────────────────
  useFiftyFifty() {
    if (!this._run?.active) return;
    const q = this._run._currentQuestion;
    if (!q || q.type !== 'mcq') return Toast.show('Only works on multiple choice', 'warn');
    if (!this._run.lifelines.fifty && !this._run.perkHintFree) return Toast.show('50-50 used up', 'warn');

    const wrong = q.options.map((_, i) => i).filter(i => i !== q.correctIndex);
    const remove = wrong.sort(() => Math.random() - 0.5).slice(0, 2);
    remove.forEach(idx => {
      const btn = document.querySelector(`.mcq-btn[data-idx="${idx}"]`);
      if (btn) { btn.disabled = true; btn.classList.add('eliminated'); }
    });
    this._run.lifelines.fifty = 0;
    this._updateLifelineButtons();
    if (!this._run.perkHintFree) {
      WA.state.profile.lifelines.fifty = 0;
      WA.save();
    }
  },

  useFreeze() {
    if (!this._run?.active) return;
    if (this._run._frozenTime !== null) return;  // already frozen
    if (!this._run.lifelines.freeze) return Toast.show('Freeze used up', 'warn');

    this._run._frozenTime = this._run._timeLeft;
    this._run.lifelines.freeze = 0;
    this._updateLifelineButtons();
    if (!this._run.perkHintFree) {
      WA.state.profile.lifelines.freeze = 0;
      WA.save();
    }

    // Freeze for 15 seconds then resume
    setTimeout(() => {
      if (this._run) this._run._frozenTime = null;
    }, 15000);

    Toast.show('⏸ Timer frozen for 15s', 'info');
  },

  useHint() {
    if (!this._run?.active) return;
    const q = this._run._currentQuestion;
    if (!q?.hint) return Toast.show('No hint available', 'warn');
    if (!this._run.lifelines.hint && !this._run.perkHintFree) return Toast.show('Hint used up', 'warn');

    this._showHintModal(q.hint, q.spark_mood || 'thinking');
    this._run.lifelines.hint = 0;
    this._updateLifelineButtons();
    if (!this._run.perkHintFree) {
      WA.state.profile.lifelines.hint = 0;
      WA.save();
    }
  },

  _showHintModal(hintText, sparkMood) {
    const modal = document.getElementById('hint-modal');
    const hintEl = document.getElementById('hint-text');
    const sparkEl = document.getElementById('hint-spark');
    if (modal) modal.classList.remove('hidden');
    if (hintEl) {
      hintEl.innerHTML = hintText;
      KR.render(hintEl);
    }
    if (sparkEl) sparkEl.src = `assets/avatars/spark-${sparkMood}.png`;
  },

  closeHint() {
    const modal = document.getElementById('hint-modal');
    if (modal) modal.classList.add('hidden');
  },

  // ── Numpad ────────────────────────────────────────────────────
  numpadPress(val) {
    const display = document.getElementById('numpad-display');
    if (!display) return;
    let current = display.textContent || '';

    if (val === '⌫') {
      display.textContent = current.slice(0, -1);
    } else if (val === '±') {
      if (current.startsWith('-')) display.textContent = current.slice(1);
      else display.textContent = '-' + current;
    } else if (val === '/' && current.includes('/')) {
      // already has fraction separator
    } else {
      // max length guard
      if (current.length >= 12) return;
      display.textContent = current + val;
    }
  },

  numpadClear() {
    const display = document.getElementById('numpad-display');
    if (display) display.textContent = '';
  },

  // ── Render helpers ────────────────────────────────────────────
  _renderCombatUI() {
    const run   = this._run;
    const enemy = run._currentEnemy;

    // Enemy name / rank
    const nameEl = document.getElementById('enemy-name');
    const rankEl = document.getElementById('enemy-rank');
    if (nameEl) nameEl.textContent = enemy.name;
    if (rankEl) rankEl.textContent = enemy.rank;

    // Enemy sprite
    const sprite = document.getElementById('enemy-sprite');
    if (sprite) {
      sprite.src = `assets/enemies/${enemy.img}`;
      sprite.onerror = () => { sprite.style.display = 'none'; };
    }

    // Wave / score
    const waveEl  = document.getElementById('combat-wave');
    const scoreEl = document.getElementById('combat-score');
    if (waveEl)  waveEl.textContent  = `WAVE ${run.wave}`;
    if (scoreEl) scoreEl.textContent = run.score;

    this._updateHPBars();
    this._updateLifelineButtons();
    this._renderIncomingDamage(enemy.dmg);
  },

  _renderIncomingDamage(dmg) {
    const el = document.getElementById('incoming-damage');
    if (el) {
      el.textContent = `⚠ −${dmg} HP if wrong`;
      el.classList.remove('hidden');
    }
  },

  _updateHPBars() {
    if (!this._run) return;
    const run   = this._run;
    const enemy = run._currentEnemy;

    // Player HP
    const playerFill = document.getElementById('hp-player-fill');
    const playerText = document.getElementById('hp-player-text');
    const playerPct  = (run.hp / run.maxHp) * 100;
    if (playerFill) playerFill.style.width = `${playerPct}%`;
    if (playerText) playerText.textContent = `${run.hp}/${run.maxHp}`;

    // Enemy HP
    const enemyFill = document.getElementById('hp-enemy-fill');
    const enemyText = document.getElementById('hp-enemy-text');
    const enemyPct  = (enemy.currentHp / enemy.maxHp) * 100;
    if (enemyFill) enemyFill.style.width = `${enemyPct}%`;
    if (enemyText) enemyText.textContent = `${enemy.currentHp}/${enemy.maxHp}`;
  },

  _updateLifelineButtons() {
    if (!this._run) return;
    const ll = this._run.lifelines;
    const free = this._run.perkHintFree;

    [
      ['lifeline-fifty',  ll.fifty || free],
      ['lifeline-freeze', ll.freeze],
      ['lifeline-hint',   ll.hint || free],
    ].forEach(([id, active]) => {
      const btn = document.getElementById(id);
      if (!btn) return;
      btn.disabled = !active;
      btn.classList.toggle('depleted', !active);
    });
  },

  _renderQuestion(q) {
    const card = document.getElementById('question-card');
    if (!card) return;

    // Wanted badge
    const wantedBadge = document.getElementById('question-wanted-badge');
    if (wantedBadge) wantedBadge.classList.toggle('hidden', !q._isWanted);

    // Difficulty badge
    const diffBadge = document.getElementById('question-diff-badge');
    if (diffBadge) {
      const labels = ['', 'RECRUIT', 'OPERATIVE', 'SERGEANT', 'COMMANDER', 'OVERSEER'];
      diffBadge.textContent = `D${q.difficulty} · ${labels[q.difficulty] || ''}`;
      diffBadge.className = `diff-badge diff-d${q.difficulty}`;
    }

    // Question text
    const qText = document.getElementById('question-text');
    if (qText) {
      qText.innerHTML = q.question || '';
      KR.render(qText);
    }

    // Answer area
    const mcqArea   = document.getElementById('mcq-area');
    const valueArea = document.getElementById('value-area');
    const multiArea = document.getElementById('multipart-area');

    if (mcqArea)   mcqArea.classList.add('hidden');
    if (valueArea) valueArea.classList.add('hidden');
    if (multiArea) multiArea.classList.add('hidden');

    if (q.type === 'mcq') {
      if (mcqArea) {
        mcqArea.classList.remove('hidden');
        this._renderMCQ(q, mcqArea);
      }
      // Hide 50-50 only for MCQ
      const fiftyBtn = document.getElementById('lifeline-fifty');
      if (fiftyBtn) fiftyBtn.disabled = !this._run.lifelines.fifty;
    } else if (q.type === 'value') {
      if (valueArea) valueArea.classList.remove('hidden');
      const display = document.getElementById('numpad-display');
      if (display) display.textContent = '';
      // Disable 50-50 for value questions
      const fiftyBtn = document.getElementById('lifeline-fifty');
      if (fiftyBtn) { fiftyBtn.disabled = true; fiftyBtn.title = 'N/A for value questions'; }
    } else if (q.type === 'multipart') {
      if (multiArea) {
        multiArea.classList.remove('hidden');
        this._renderMultipart(q, multiArea);
      }
    }
  },

  _renderMCQ(q, container) {
    const grid = container.querySelector('.mcq-grid') || container;
    grid.innerHTML = q.options.map((opt, i) => `
      <button class="mcq-btn" data-idx="${i}" onclick="Combat.submitMCQ(${i})">
        <span class="mcq-label">${String.fromCharCode(65+i)}</span>
        <span class="mcq-text">${opt}</span>
      </button>
    `).join('');

    // Render math in each button
    grid.querySelectorAll('.mcq-text').forEach(el => KR.render(el));
  },

  _renderMultipart(q, container) {
    const partsEl = container.querySelector('.multipart-parts');
    if (!partsEl) return;
    partsEl.innerHTML = '';
    this._run._multipartState = { parts: q.parts, currentPart: 0, answers: [] };
    this._renderMultipartPart(0, q.parts[0], partsEl);
  },

  _renderMultipartPart(idx, part, container) {
    container.innerHTML = `
      <div class="multipart-part-label text-xs text-dim">Part (${String.fromCharCode(97+idx)})</div>
      <div class="multipart-question-text" id="mp-question-text">${part.question}</div>
      <div id="mp-answer-area"></div>
      <div class="multipart-nav">
        <button class="btn btn-primary" onclick="Combat.submitMultipartPart()">CONFIRM</button>
      </div>
    `;
    const qEl = container.querySelector('#mp-question-text');
    if (qEl) KR.render(qEl);

    const ansArea = container.querySelector('#mp-answer-area');
    if (part.type === 'mcq') {
      ansArea.innerHTML = `<div class="mcq-grid">` +
        part.options.map((opt, i) => `
          <button class="mcq-btn" data-idx="${i}" onclick="this.parentElement.querySelectorAll('.mcq-btn').forEach(b=>b.classList.remove('selected')); this.classList.add('selected'); Combat._run._multipartState.currentAnswer=${i}">
            <span class="mcq-label">${String.fromCharCode(65+i)}</span>
            <span class="mcq-text">${opt}</span>
          </button>
        `).join('') + `</div>`;
      ansArea.querySelectorAll('.mcq-text').forEach(el => KR.render(el));
    } else {
      ansArea.innerHTML = `<div class="numpad-display" id="mp-numpad-display"></div>
        <div class="numpad-grid">` + this._numpadHTML('mp') + `</div>`;
    }
  },

  _numpadHTML(prefix = '') {
    const keys = ['7','8','9','4','5','6','1','2','3','±','0','.','/',String.fromCharCode(0x232B),''];
    return keys.map((k,i) => k
      ? `<button class="numpad-key" onclick="Combat.numpadPress('${k}')">${k}</button>`
      : ''
    ).join('');
  },

  submitMultipartPart() {
    const state = this._run?._multipartState;
    if (!state) return;
    const part = state.parts[state.currentPart];

    let answer;
    if (part.type === 'mcq') {
      answer = state.currentAnswer;
      if (answer === undefined) return Toast.show('Select an option', 'warn');
    } else {
      const el = document.getElementById('mp-numpad-display');
      answer = el ? el.textContent.trim() : '';
      if (!answer) return Toast.show('Enter a value', 'warn');
    }

    const correct = (part.type === 'mcq')
      ? answer === part.correctIndex
      : this._checkValueAnswer(String(answer), part);

    state.answers.push({ answer, correct });
    state.currentPart++;

    if (state.currentPart >= state.parts.length) {
      // All parts done
      const allCorrect = state.answers.every(a => a.correct);
      const anyCorrect = state.answers.some(a => a.correct);
      this._resolveAnswer(null, allCorrect ? 'correct' : anyCorrect ? 'complication' : 'wrong');
    } else {
      const partsEl = document.querySelector('.multipart-parts');
      if (partsEl) this._renderMultipartPart(state.currentPart, state.parts[state.currentPart], partsEl);
    }
  },

  _showOutcome(type, q, damage, scrap) {
    const overlay = document.getElementById('outcome-overlay');
    const icon    = document.getElementById('outcome-icon');
    const msg     = document.getElementById('outcome-msg');
    const sub     = document.getElementById('outcome-sub');
    const sol     = document.getElementById('outcome-solution');

    if (!overlay) return;
    overlay.classList.remove('hidden', 'outcome-correct', 'outcome-complication', 'outcome-wrong');
    overlay.classList.add(`outcome-${type}`);

    const sparkEl = document.getElementById('outcome-spark');

    if (type === 'correct') {
      if (icon) icon.textContent = '✓';
      if (msg)  msg.textContent  = 'CORRECT!';
      if (sub)  sub.textContent  = scrap > 0 ? `+${scrap} Scrap` : '';
      if (sparkEl) sparkEl.src   = 'assets/avatars/spark-happy.png';
    } else if (type === 'complication') {
      if (icon) icon.textContent = '⚡';
      if (msg)  msg.textContent  = 'SLOW RESPONSE';
      if (sub)  sub.textContent  = `Correct but late — −${damage} HP`;
      if (sparkEl) sparkEl.src   = 'assets/avatars/spark-surprised.png';
    } else if (type === 'wrong') {
      if (icon) icon.textContent = '✗';
      if (msg)  msg.textContent  = 'WRONG';
      if (sub)  sub.textContent  = `−${damage} HP · Bounty placed`;
      if (sparkEl) sparkEl.src   = 'assets/avatars/spark-sarcastic.png';
    } else if (type === 'timeout') {
      if (icon) icon.textContent = '⏱';
      if (msg)  msg.textContent  = 'TIME\'S UP';
      if (sub)  sub.textContent  = `−${damage} HP`;
      if (sparkEl) sparkEl.src   = 'assets/avatars/spark-surprised.png';
    }

    // Show worked solution if available
    if (sol) {
      if (q?.worked_solution && (type === 'wrong' || type === 'timeout')) {
        sol.innerHTML = q.worked_solution;
        KR.render(sol);
        sol.classList.remove('hidden');
      } else {
        sol.classList.add('hidden');
      }
    }

    overlay.classList.remove('hidden');
  },
};
