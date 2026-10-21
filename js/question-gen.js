// ── PARAMETRIC QUESTION GENERATOR ────────────────────────────
// Questions can be static objects OR parametric templates.
// A parametric template has type:'parametric' and a generate() function
// that returns a fresh question object with computed answer each call.
//
// This allows:
//   • Infinite variety — same structure, different numbers every run
//   • Bidirectional questions — same template can yield forward/inverse
//   • Boss multi-part questions that reference each other's answers
//   • No answer bank needed — the engine always knows the correct answer

const QGen = {

  // ── Random helpers ────────────────────────────────────────────
  int(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; },
  float(min, max, dp = 1) {
    return parseFloat((Math.random() * (max - min) + min).toFixed(dp));
  },
  pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; },
  shuffle(arr) { return [...arr].sort(() => Math.random() - 0.5); },
  sign() { return Math.random() < 0.5 ? 1 : -1; },

  // Non-zero integer
  nonzero(min, max) {
    let n;
    do { n = this.int(min, max); } while (n === 0);
    return n;
  },

  // Nice fraction: numerator / denominator, reduced
  fraction(maxNum = 9, maxDen = 8) {
    const den = this.int(2, maxDen);
    const num = this.int(1, maxNum);
    const g   = this._gcd(num, den);
    return { num: num/g, den: den/g, value: num/(den*g), tex: `\\dfrac{${num/g}}{${den/g}}` };
  },

  _gcd(a, b) { return b === 0 ? a : this._gcd(b, a % b); },

  // Round to n significant figures
  sf(n, digits = 3) {
    if (n === 0) return 0;
    const d = Math.ceil(Math.log10(Math.abs(n)));
    const power = digits - d;
    const magnitude = Math.pow(10, power);
    return Math.round(n * magnitude) / magnitude;
  },

  // Format a number cleanly for LaTeX — avoids -0, ugly decimals
  tex(n, dp = 0) {
    const val = dp > 0 ? parseFloat(n.toFixed(dp)) : Math.round(n);
    return val < 0 ? `(${val})` : `${val}`;
  },

  // ── Expand a parametric template ─────────────────────────────
  // Called by the combat engine when it picks a parametric question.
  // Returns a plain question object identical in shape to a static question.
  expand(template) {
    try {
      const params   = template.params ? template.params() : {};
      const question = template.question(params);
      const answer   = template.answer(params);

      const obj = {
        id:       `${template.id}_${Date.now()}_${Math.random().toString(36).slice(2,6)}`,
        type:     template.outputType || 'value',
        difficulty: template.difficulty,
        _subtopic:  template._subtopic,
        _packId:    template._packId,
        _topicId:   template._topicId,
        _template:  template.id,   // keep reference for SR (same template = same subtopic)
        question,
        answer,
        tolerance:  template.tolerance ?? 0.005,
        hint:       template.hint    ? template.hint(params)            : null,
        worked_solution: template.worked_solution ? template.worked_solution(params) : null,
        spark_mood: template.spark_mood || 'thinking',
      };

      // MCQ variant: if template supplies mcq_options, generate distractor choices
      if (template.mcqDistractors) {
        const distractors = template.mcqDistractors(params, answer);
        const correct = this.int(0, 3);
        const options  = [...distractors];
        options.splice(correct, 0, this._formatAnswer(answer, template.answerDp || 0));
        obj.type = 'mcq';
        obj.options = options.slice(0, 4).map(o => `$${o}$`);
        obj.correctIndex = correct;
        delete obj.answer;
        delete obj.tolerance;
      }

      return obj;
    } catch(e) {
      console.warn('[QGen] expand failed for', template.id, e);
      return null;
    }
  },

  _formatAnswer(n, dp = 0) {
    if (dp > 0) return n.toFixed(dp);
    return String(Math.round(n));
  },

  // ── Boss question builder ─────────────────────────────────────
  // Builds a multi-part boss question where later parts may use earlier answers.
  // Each part receives { params, priorAnswers: [{correct, studentAnswer, officialAnswer}] }
  expandBoss(template) {
    try {
      const params = template.params ? template.params() : {};
      return {
        id:         `${template.id}_boss_${Date.now()}`,
        type:       'boss',
        difficulty: template.difficulty || 5,
        _subtopic:  template._subtopic,
        _packId:    template._packId,
        _topicId:   template._topicId,
        title:      template.title || 'Boss Encounter',
        intro:      template.intro ? template.intro(params) : null,
        parts:      template.parts.map((pt, i) => ({
          label:    String.fromCharCode(97 + i),   // a, b, c…
          type:     pt.type || 'value',
          question: pt.question(params),
          answer:   pt.answer(params),
          tolerance: pt.tolerance ?? 0.005,
          options:  pt.options ? pt.options(params) : null,
          correctIndex: pt.correctIndex ? pt.correctIndex(params) : null,
          marks:    pt.marks || 2,
          hint:     pt.hint ? pt.hint(params) : null,
          worked_solution: pt.worked_solution ? pt.worked_solution(params) : null,
          followThrough: pt.followThrough !== false,  // default true
        })),
        spark_mood: template.spark_mood || 'surprised',
      };
    } catch(e) {
      console.warn('[QGen] expandBoss failed for', template.id, e);
      return null;
    }
  },
};
