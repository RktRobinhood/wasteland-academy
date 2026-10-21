const SR = {
  // A WANTED question comes back after 3–5 other questions (SPEC §7). The gap
  // is drawn at random, so the player can't count it.
  GAP_MIN: 3,
  GAP_MAX: 5,

  init(state) {
    this._state = state;
  },

  // Call after tick() for the failed answer, so the gap counts only the
  // questions answered after it. Failing a WANTED question again resets its gap.
  flag(questionId, subtopic) {
    const wanted = this._state.spaced.wanted;
    const nextAfter = this._state.spaced.answered + this._gap();
    const existing = wanted.find(w => w.id === questionId);
    if (existing) {
      existing.nextAfter = nextAfter;
      existing.attempts = (existing.attempts || 0) + 1;
    } else {
      wanted.push({
        id: questionId,
        subtopic,
        nextAfter,
        attempts: 1,
        flaggedAt: Date.now()
      });
    }
    WA.save();
  },

  _gap() {
    return this.GAP_MIN + Math.floor(Math.random() * (this.GAP_MAX - this.GAP_MIN + 1));
  },

  clear(questionId) {
    const wanted = this._state.spaced.wanted;
    const idx = wanted.findIndex(w => w.id === questionId);
    if (idx !== -1) {
      wanted.splice(idx, 1);
      WA.save();
    }
  },

  isWanted(questionId) {
    return this._state.spaced.wanted.some(w => w.id === questionId);
  },

  isDue(questionId) {
    const w = this._state.spaced.wanted.find(w => w.id === questionId);
    return !!w && w.nextAfter <= this._state.spaced.answered;
  },

  getDue() {
    const answered = this._state.spaced.answered;
    return this._state.spaced.wanted.filter(w => w.nextAfter <= answered);
  },

  getAll() {
    return [...this._state.spaced.wanted];
  },

  // Once per answered question
  tick() {
    this._state.spaced.answered++;
  },

  // Picks the next question from `pool` (ids are question or template ids).
  //   tier:      the enemy's tier. If the pool has nothing at that tier, the
  //              nearest tier is used (the lower one on a tie).
  //   excludeId: the question just asked. It's never asked twice in a row,
  //              unless it's the only question in the pool.
  // Priority: a WANTED question that's due, then questions that aren't WANTED,
  // then WANTED questions that aren't due yet (so a node whose questions are
  // all WANTED still plays).
  selectNext(pool, { tier = null, excludeId = null } = {}) {
    let candidates = pool.filter(q => q.id !== excludeId);
    if (candidates.length === 0) candidates = pool;
    if (candidates.length === 0) return { question: null, isWanted: false };

    const wantedBy = new Map(this._state.spaced.wanted.map(w => [w.id, w]));
    const answered = this._state.spaced.answered;

    const due = candidates.filter(q => wantedBy.get(q.id)?.nextAfter <= answered);
    if (due.length > 0) {
      const mostOverdue = Math.min(...due.map(q => wantedBy.get(q.id).nextAfter));
      const oldest = this._nearestTier(due.filter(q => wantedBy.get(q.id).nextAfter === mostOverdue), tier);
      return { question: this._pick(oldest), isWanted: true };
    }

    let fresh = candidates.filter(q => !wantedBy.has(q.id));
    if (fresh.length === 0) fresh = candidates;
    const q = this._pick(this._nearestTier(fresh, tier));
    return { question: q, isWanted: wantedBy.has(q.id) };
  },

  _nearestTier(questions, tier) {
    if (tier == null) return questions;
    // Distance from the tier, with a half-step penalty for being above it
    const cost = q => Math.abs(q.difficulty - tier) * 2 + (q.difficulty > tier ? 1 : 0);
    const best = Math.min(...questions.map(cost));
    return questions.filter(q => cost(q) === best);
  },

  _pick(arr) {
    return arr[Math.floor(Math.random() * arr.length)];
  },
};
