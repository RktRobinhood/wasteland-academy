const Stats = {
  init(state) {
    this._state = state;
  },

  recordAnswer({ questionId, subtopic, topicId, difficulty, correct, isWanted }) {
    const acc = this._state.stats;

    if (!acc.subtopicAccuracy[subtopic]) acc.subtopicAccuracy[subtopic] = { correct: 0, total: 0 };
    acc.subtopicAccuracy[subtopic].total++;
    if (correct) acc.subtopicAccuracy[subtopic].correct++;

    if (!acc.topicAccuracy[topicId]) acc.topicAccuracy[topicId] = { correct: 0, total: 0 };
    acc.topicAccuracy[topicId].total++;
    if (correct) acc.topicAccuracy[topicId].correct++;

    WA.save();
  },

  recordRun({ mode, config, score, topicBreakdown, duration }) {
    this._state.stats.runs.push({
      ts: Date.now(),
      mode,
      config,
      score,
      topicBreakdown: { ...topicBreakdown },
      duration
    });
    if (this._state.stats.runs.length > 50) {
      this._state.stats.runs = this._state.stats.runs.slice(-50);
    }
    WA.save();
  },

  getTopicAccuracy() {
    const acc = this._state.stats.topicAccuracy;
    const result = {};
    for (const [id, data] of Object.entries(acc)) {
      result[id] = data.total > 0 ? (data.correct / data.total) : 0;
    }
    return result;
  },

  getThisRunAccuracy(runHistory) {
    const result = {};
    for (const entry of runHistory) {
      if (!result[entry.topicId]) result[entry.topicId] = { correct: 0, total: 0 };
      result[entry.topicId].total++;
      if (entry.correct) result[entry.topicId].correct++;
    }
    const pct = {};
    for (const [id, data] of Object.entries(result)) {
      pct[id] = data.total > 0 ? data.correct / data.total : 0;
    }
    return pct;
  },

  getTopImprovements(limit = 3) {
    const runs = this._state.stats.runs;
    if (runs.length < 2) return [];

    const recentRuns = runs.slice(-5);
    const olderRuns = runs.slice(0, -5);
    if (olderRuns.length === 0) return [];

    const avgFor = (runSet, topicId) => {
      const relevant = runSet.filter(r => r.topicBreakdown && r.topicBreakdown[topicId]);
      if (relevant.length === 0) return null;
      const sum = relevant.reduce((acc, r) => {
        const d = r.topicBreakdown[topicId];
        return acc + (d.total > 0 ? d.correct / d.total : 0);
      }, 0);
      return sum / relevant.length;
    };

    const topics = Object.keys(this._state.stats.topicAccuracy);
    const improvements = [];
    for (const topicId of topics) {
      const oldAvg = avgFor(olderRuns, topicId);
      const newAvg = avgFor(recentRuns, topicId);
      if (oldAvg !== null && newAvg !== null && newAvg > oldAvg) {
        improvements.push({ topicId, delta: newAvg - oldAvg, newAvg });
      }
    }
    improvements.sort((a, b) => b.delta - a.delta);
    return improvements.slice(0, limit);
  },

  drawSpiderDiagram(canvasEl, accuracyMap, topicLabels) {
    const ctx = canvasEl.getContext('2d');
    const W = canvasEl.width;
    const H = canvasEl.height;
    const cx = W / 2;
    const cy = H / 2;
    const r = Math.min(W, H) * 0.38;

    ctx.clearRect(0, 0, W, H);

    const topics = Object.keys(topicLabels);
    const n = topics.length;
    const angleStep = (2 * Math.PI) / n;
    const startAngle = -Math.PI / 2;

    const pt = (i, radius) => ({
      x: cx + radius * Math.cos(startAngle + i * angleStep),
      y: cy + radius * Math.sin(startAngle + i * angleStep)
    });

    // Grid rings
    const rings = [0.25, 0.5, 0.75, 1];
    ctx.strokeStyle = 'rgba(55,65,81,0.7)';
    ctx.lineWidth = 1;
    for (const ring of rings) {
      ctx.beginPath();
      for (let i = 0; i < n; i++) {
        const p = pt(i, r * ring);
        i === 0 ? ctx.moveTo(p.x, p.y) : ctx.lineTo(p.x, p.y);
      }
      ctx.closePath();
      ctx.stroke();
    }

    // Spokes
    ctx.strokeStyle = 'rgba(75,85,99,0.5)';
    for (let i = 0; i < n; i++) {
      const p = pt(i, r);
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.lineTo(p.x, p.y);
      ctx.stroke();
    }

    // Data polygon
    ctx.beginPath();
    for (let i = 0; i < n; i++) {
      const val = accuracyMap[topics[i]] ?? 0;
      const p = pt(i, r * Math.max(0.05, val));
      i === 0 ? ctx.moveTo(p.x, p.y) : ctx.lineTo(p.x, p.y);
    }
    ctx.closePath();
    ctx.fillStyle = 'rgba(34,211,197,0.18)';
    ctx.fill();
    ctx.strokeStyle = '#22D3C5';
    ctx.lineWidth = 2;
    ctx.stroke();

    // Dots
    ctx.fillStyle = '#22D3C5';
    for (let i = 0; i < n; i++) {
      const val = accuracyMap[topics[i]] ?? 0;
      const p = pt(i, r * Math.max(0.05, val));
      ctx.beginPath();
      ctx.arc(p.x, p.y, 4, 0, 2 * Math.PI);
      ctx.fill();
    }

    // Labels
    ctx.fillStyle = '#9FF0E6';
    ctx.font = '11px "Share Tech Mono", monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    for (let i = 0; i < n; i++) {
      const p = pt(i, r + 22);
      const lines = (topicLabels[topics[i]] || topics[i]).split('\n');
      lines.forEach((line, li) => {
        ctx.fillText(line, p.x, p.y + li * 13);
      });
    }
  }
};
