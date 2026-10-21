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
  // Fisher–Yates: every order equally likely
  shuffle(arr) {
    const out = [...arr];
    for (let i = out.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [out[i], out[j]] = [out[j], out[i]];
    }
    return out;
  },
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
    return { num: num/g, den: den/g, value: num/den, tex: `\\dfrac{${num/g}}{${den/g}}` };
  },

  _gcd(a, b) { a = Math.abs(a); b = Math.abs(b); return b === 0 ? a : this._gcd(b, a % b); },

  // Round to n significant figures
  sf(n, digits = 3) {
    if (n === 0) return 0;
    const d = Math.ceil(Math.log10(Math.abs(n)));
    const power = digits - d;
    const magnitude = Math.pow(10, power);
    return Math.round(n * magnitude) / magnitude;
  },

  // Format a number cleanly for LaTeX — avoids -0, ugly decimals.
  // Negatives are bracketed, for substituting into an expression: 3(-2) → 3(−2)
  tex(n, dp = 0) {
    const val = dp > 0 ? parseFloat(n.toFixed(dp)) : Math.round(n);
    return val < 0 ? `(${val})` : `${val}`;
  },

  // ── LaTeX formatting ──────────────────────────────────────────
  // A power of a variable: pow('x', 1) → 'x', pow('x', 0) → ''
  pow(v, n) { return n === 0 ? '' : n === 1 ? v : `${v}^{${n}}`; },

  // A polynomial from [coefficient, variable-part] pairs, dropping zero terms
  // and unit coefficients: poly([[3,'x^2'],[-1,'x'],[0,'']]) → '3x^2 - x'
  poly(terms) {
    let out = '';
    for (const [c, v] of terms) {
      if (c === 0) continue;
      const mag = Math.abs(c);
      const body = v && mag === 1 ? v : `${mag}${v}`;
      out += out ? (c < 0 ? ` - ${body}` : ` + ${body}`) : (c < 0 ? `-${body}` : body);
    }
    return out || '0';
  },

  // A constant appended to an expression: signed(-5) → ' - 5', signed(0) → ''
  signed(n) { return n === 0 ? '' : n < 0 ? ` - ${-n}` : ` + ${n}`; },

  // A reduced fraction as a coefficient of `v`, sign out front:
  // frac(-4, 6, 'x') → '-\dfrac{2}{3}x', frac(4, 2, 'x') → '2x', frac(1, 1, 'x') → 'x'
  frac(num, den, v = '') {
    if (num === 0) return '0';
    const g = this._gcd(num, den);
    let n = Math.abs(num / g), d = Math.abs(den / g);
    const neg = (num < 0) !== (den < 0) ? '-' : '';
    if (d === 1) return neg + (v && n === 1 ? v : `${n}${v}`);
    return `${neg}\\dfrac{${n}}{${d}}${v}`;
  },

  // Joins working steps with ' = ', skipping a step that repeats the one before
  chain(...steps) {
    return steps.map(String).filter((s, i, a) => i === 0 || s !== a[i - 1]).join(' = ');
  },

  // ── Expand a parametric template ─────────────────────────────
  // Called by the combat engine when it picks a parametric question.
  // Returns a plain question object identical in shape to a static question.
  // The id is the template's id, so spaced repetition tracks the template.
  expand(template) {
    try {
      const params   = template.params ? template.params() : {};
      const question = template.question(params);
      const answer   = template.answer(params);

      const obj = {
        id:       template.id,
        type:     template.outputType || 'value',
        difficulty: template.difficulty,
        _subtopic:  template._subtopic,
        _packId:    template._packId,
        _topicId:   template._topicId,
        _template:  template.id,
        question,
        answer,
        tolerance:  template.tolerance ?? 0,
        hint:       template.hint    ? template.hint(params)            : null,
        worked_solution: template.worked_solution ? template.worked_solution(params) : null,
        spark_mood: template.spark_mood || 'thinking',
      };

      // MCQ variant: the template lists wrong answers, best first. The first
      // three that differ from the answer and from each other are used.
      if (template.mcqDistractors) {
        const right = this._formatAnswer(answer, template.answerDp || 0);
        const norm  = s => String(s).replace(/\s+/g, '');
        const seen  = new Set([norm(right)]);
        const wrong = [];
        for (const d of template.mcqDistractors(params, answer)) {
          const s = this._formatAnswer(d, template.answerDp || 0);
          if (wrong.length < 3 && !seen.has(norm(s))) { seen.add(norm(s)); wrong.push(s); }
        }
        if (wrong.length < 3) throw new Error(`only ${wrong.length} distinct distractors`);
        const correct = this.int(0, 3);
        const options = [...wrong];
        options.splice(correct, 0, right);
        obj.type = 'mcq';
        obj.options = options.map(o => `$${o}$`);
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

  // MCQ answers are LaTeX strings or numbers
  _formatAnswer(a, dp = 0) {
    if (typeof a !== 'number') return String(a);
    if (dp > 0) return a.toFixed(dp);
    return String(Math.round(a));
  },

  // ── Boss question builder ─────────────────────────────────────
  // Builds a multi-part boss question where later parts may use earlier answers.
  // Each part receives { params, priorAnswers: [{correct, studentAnswer, officialAnswer}] }
  expandBoss(template) {
    try {
      const params = template.params ? template.params() : {};
      return {
        id:         template.id,
        type:       'boss',
        difficulty: template.difficulty || 5,
        _subtopic:  template._subtopic,
        _packId:    template._packId,
        _topicId:   template._topicId,
        _template:  template.id,
        title:      template.title || 'Boss Encounter',
        intro:      template.intro ? template.intro(params) : null,
        parts:      template.parts.map((pt, i) => ({
          label:    String.fromCharCode(97 + i),   // a, b, c…
          type:     pt.type || 'value',
          question: pt.question(params),
          answer:   pt.answer(params),
          tolerance: pt.tolerance ?? 0,
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
