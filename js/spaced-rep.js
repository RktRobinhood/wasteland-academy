const SR = {
  BREATHING_ROOM: 4,   // min questions before a WANTED Q resurfaces

  init(state) {
    this._state = state;
  },

  flag(questionId, subtopic) {
    const wanted = this._state.spaced.wanted;
    const existing = wanted.find(w => w.id === questionId);
    if (existing) {
      existing.nextAfter = this._state.spaced.answered + this.BREATHING_ROOM;
      existing.attempts = (existing.attempts || 0) + 1;
    } else {
      wanted.push({
        id: questionId,
        subtopic,
        nextAfter: this._state.spaced.answered + this.BREATHING_ROOM,
        attempts: 1,
        flaggedAt: Date.now()
      });
    }
    WA.save();
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

  getDue() {
    const answered = this._state.spaced.answered;
    return this._state.spaced.wanted.filter(w => w.nextAfter <= answered);
  },

  getAll() {
    return [...this._state.spaced.wanted];
  },

  tick() {
    this._state.spaced.answered++;
  },

  selectNext(pool, preferSubtopics = null) {
    const due = this.getDue();
    if (due.length > 0) {
      const pick = due[Math.floor(Math.random() * due.length)];
      const q = pool.find(q => q.id === pick.id);
      if (q) return { question: q, isWanted: true };
    }
    let candidates = pool;
    if (preferSubtopics && preferSubtopics.length > 0) {
      candidates = pool.filter(q => preferSubtopics.includes(q.subtopic));
      if (candidates.length === 0) candidates = pool;
    }
    const q = candidates[Math.floor(Math.random() * candidates.length)];
    return { question: q, isWanted: false };
  }
};
