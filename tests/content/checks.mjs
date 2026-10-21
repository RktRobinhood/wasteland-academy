// Mechanical checks on content items. Each check returns a list of problems
// (empty = pass). They don't judge whether an answer key is mathematically
// right; known wrong keys are listed in known-defects.mjs instead.
import katex from 'katex';

// Same delimiters, in the same order, as KR.render (js/katex-render.js)
const DELIMITERS = [
  { left: '$$', right: '$$' },
  { left: '$', right: '$' },
  { left: '\\(', right: '\\)' },
  { left: '\\[', right: '\\]' },
];

// Mirrors KaTeX auto-render's splitAtDelimiters: a backslash escapes the next
// character and the closing delimiter must sit at brace depth 0.
function findEndOfMath(delimiter, text, start) {
  let depth = 0;
  for (let i = start; i < text.length; i++) {
    const ch = text[i];
    if (depth <= 0 && text.startsWith(delimiter, i)) return i;
    if (ch === '\\') i++;
    else if (ch === '{') depth++;
    else if (ch === '}') depth--;
  }
  return -1;
}

export function splitMath(text) {
  const out = [];
  let rest = text;
  for (;;) {
    let first = null;
    for (const d of DELIMITERS) {
      const at = rest.indexOf(d.left);
      if (at !== -1 && (first === null || at < first.at)) first = { ...d, at };
    }
    if (!first) break;
    const end = findEndOfMath(first.right, rest, first.at + first.left.length);
    if (end === -1) break;
    if (first.at > 0) out.push({ math: false, text: rest.slice(0, first.at) });
    out.push({ math: true, text: rest.slice(first.at + first.left.length, end), display: first.left === '$$' || first.left === '\\[' });
    rest = rest.slice(end + first.right.length);
  }
  if (rest) out.push({ math: false, text: rest });
  return out;
}

// The player-visible strings on an item. Parametric templates hold functions
// here instead; the validator checks their expanded output (loadGenerated).
const TEXT_FIELDS = ['question', 'stem', 'title', 'intro', 'hint', 'worked_solution'];

export function textsOf(q) {
  const texts = [];
  for (const f of TEXT_FIELDS) if (typeof q[f] === 'string') texts.push([f, q[f]]);
  if (Array.isArray(q.options)) q.options.forEach((o, i) => { if (typeof o === 'string') texts.push([`options[${i}]`, o]); });
  return texts;
}

const KNOWN_TYPES = ['mcq', 'value', 'multipart', 'parametric', 'boss'];

export const CHECKS = {
  'known-type'(item) {
    return KNOWN_TYPES.includes(item.q.type) ? [] : [`unknown type ${JSON.stringify(item.q.type)}`];
  },

  'mcq-options'(item) {
    const q = item.q;
    if (q.type !== 'mcq') return [];
    const problems = [];
    if (!Array.isArray(q.options) || q.options.length !== 4) {
      return [`expected 4 options, got ${Array.isArray(q.options) ? q.options.length : typeof q.options}`];
    }
    if (q.options.some(o => typeof o !== 'string' || !o.trim())) problems.push('every option must be a non-empty string');
    const norm = q.options.map(o => String(o).replace(/\s+/g, ''));
    norm.forEach((o, i) => {
      const j = norm.indexOf(o);
      if (j !== i) problems.push(`options[${i}] duplicates options[${j}]`);
    });
    if (!Number.isInteger(q.correctIndex) || q.correctIndex < 0 || q.correctIndex >= q.options.length) {
      problems.push(`correctIndex ${JSON.stringify(q.correctIndex)} is not 0-3`);
    }
    return problems;
  },

  // Tolerance is absolute (answer ± tolerance) and must be stated
  'value-answer'(item) {
    const q = item.q;
    if (q.type !== 'value') return [];
    const problems = [];
    if (typeof q.answer !== 'number' || !Number.isFinite(q.answer)) problems.push(`answer ${JSON.stringify(q.answer)} is not a finite number`);
    if (!(typeof q.tolerance === 'number' && q.tolerance >= 0)) problems.push(`tolerance ${JSON.stringify(q.tolerance)} is not a number >= 0`);
    return problems;
  },

  'multipart-parts'(item) {
    const q = item.q;
    if (q.type !== 'multipart' && q.type !== 'boss') return [];
    if (!Array.isArray(q.parts) || q.parts.length === 0) return ['has no parts'];
    return q.parts.flatMap((p, i) => ['mcq', 'value'].includes(p.type) ? [] : [`parts[${i}] has type ${JSON.stringify(p.type)}, expected mcq or value`]);
  },

  'katex-parses'(item) {
    const problems = [];
    for (const [field, text] of textsOf(item.q)) {
      for (const seg of splitMath(text)) {
        if (!seg.math) continue;
        try {
          katex.renderToString(seg.text, { throwOnError: true, displayMode: seg.display });
        } catch (e) {
          problems.push(`${field}: $${seg.text}$ — ${e.message.split('\n')[0]}`);
        }
      }
    }
    return problems;
  },

  // Nothing broken leaks into what the player sees
  'no-broken-values'(item) {
    return textsOf(item.q)
      .filter(([, text]) => /\bNaN\b|\bundefined\b|Infinity|\[object Object\]|=>/.test(text))
      .map(([field, text]) => `${field}: ${JSON.stringify(text)}`);
  },

  // Signs and coefficients as a teacher writes them: no "+ -5", "x - -2",
  // "1x", "0x" or "x^{1}"
  'clean-signs'(item) {
    const BAD = [
      [/[+-]\s*-\s*\d/, 'double sign'],
      [/(?<![\w.\\}{^])[01][a-z](?![a-z])/, 'coefficient 0 or 1'],
      [/[xt]\^\{?[01]\}?(?!\d)/, 'power 0 or 1'],
    ];
    const problems = [];
    for (const [field, text] of textsOf(item.q)) {
      for (const seg of splitMath(text)) {
        if (!seg.math) continue;
        for (const [re, what] of BAD) if (re.test(seg.text)) problems.push(`${field}: ${what} in $${seg.text}$`);
      }
    }
    return problems;
  },

  // A $ or \ outside any maths is shown to the player as raw TeX
  'no-raw-tex'(item) {
    const problems = [];
    for (const [field, text] of textsOf(item.q)) {
      for (const seg of splitMath(text)) {
        if (!seg.math && /[$\\]/.test(seg.text)) problems.push(`${field}: raw TeX outside maths in ${JSON.stringify(seg.text.trim())}`);
      }
    }
    return problems;
  },
};
