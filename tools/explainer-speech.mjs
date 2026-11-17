// ── HOW A CAPTION IS SAID ────────────────────────────────────
// A spoken line in an explainer has two texts (GitHub #190): `caption`, what the player
// reads, in proper notation (uₙ, (−3)², Sₙ = n/2 (u₁ + uₙ)), and `say`, what the voice is
// sent, written the way it is spoken ("u n", "minus three, in brackets, squared").
// This module reads a caption through the tutor's pronunciation sheet
// (writing/explainers/pronunciation.json) and checks that `say` is the same line, word
// for word: every symbol has one of its agreed spoken forms, and every number is the
// same number. tools/explainer-scripts.mjs calls it for every line.

// Sub- and superscript characters, and what they stand for.
const SUB = { '₀': '0', '₁': '1', '₂': '2', '₃': '3', '₄': '4', '₅': '5', '₆': '6', '₇': '7', '₈': '8', '₉': '9',
  '₊': '+', '₋': '−', '₌': '=', '₍': '(', '₎': ')', 'ₐ': 'a', 'ₑ': 'e', 'ₒ': 'o', 'ₓ': 'x', 'ₕ': 'h', 'ₖ': 'k', 'ₗ': 'l',
  'ₘ': 'm', 'ₙ': 'n', 'ₚ': 'p', 'ₛ': 's', 'ₜ': 't', 'ᵢ': 'i', 'ⱼ': 'j', 'ᵣ': 'r' };
const SUP = { '⁰': '0', '¹': '1', '²': '2', '³': '3', '⁴': '4', '⁵': '5', '⁶': '6', '⁷': '7', '⁸': '8', '⁹': '9',
  '⁺': '+', '⁻': '−', '⁼': '=', '⁽': '(', '⁾': ')', 'ⁿ': 'n', 'ˣ': 'x', 'ʸ': 'y', 'ᵏ': 'k', 'ᵗ': 't' };
// Punctuation: it separates words and is not said.
const PUNCT = new Set([...'.,;:!?"“”‘’—–\'']);
const LETTER = /[A-Za-zÀ-ÖØ-öø-ÿ]/;

// ── The sheet ──
export function sheetFor(pron, tutor) {
  const d = pron.default, t = pron.tutors?.[tutor] || {};
  return {
    symbols: { ...d.symbols, ...(t.symbols || {}) },
    words: { ...d.words, ...(t.words || {}) },
    bracketPower: t.bracket_power || d.bracket_power,
    zero: t.zero || d.zero,
    avoid: [...(d.avoid || []), ...(t.avoid || [])],
  };
}

// ── Words ──
// The words of a spoken text: lower case, hyphens and punctuation dropped.
export function words(text) {
  return String(text).toLowerCase().replace(/[’‘]/g, "'").replace(/[-‐]/g, ' ')
    .replace(/[.,;:!?"“”—–…()]/g, ' ').split(/\s+/).map(w => w.replace(/^'+|'+$/g, '')).filter(Boolean);
}
const split = s => (s ? s.split(' ') : []);

// ── Numbers, in words ──
const ONES = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven', 'twelve',
  'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'];
const TENS = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'];
export const NUMBER_WORDS = new Set([...ONES, ...TENS.filter(Boolean), 'hundred', 'thousand', 'million', 'nought', 'oh', 'point']);

function below100(n) { return n < 20 ? ONES[n] : TENS[Math.floor(n / 10)] + (n % 10 ? ' ' + ONES[n % 10] : ''); }
function below1000(n, a = false) {
  const h = Math.floor(n / 100), r = n % 100;
  if (!h) return [below100(r)];
  const head = [`${ONES[h]} hundred`].concat(a && h === 1 ? ['a hundred'] : []);
  return head.map(x => (r ? `${x} and ${below100(r)}` : x));
}
// Every way an integer may be said: 178 is "one hundred and seventy eight" or "a hundred and
// seventy eight"; 480 is also "four eighty" (shorthand for a number on the board); 1400 is
// also "fourteen hundred".
export function intWords(n) {
  if (n < 1000) {
    const out = below1000(n, true);
    if (n > 100 && n % 100 && n % 100 >= 10) out.push(`${ONES[Math.floor(n / 100)]} ${below100(n % 100)}`);
    return out;
  }
  if (n < 1e6) {
    const th = Math.floor(n / 1000), r = n % 1000, out = [];
    for (const t of th < 1000 ? below1000(th, true) : [String(th)]) {
      const head = `${t} thousand`;
      if (!r) out.push(head);
      else for (const x of below1000(r)) out.push(`${head}${r < 100 ? ' and' : ''} ${x}`);
    }
    if (n % 100 === 0 && n < 10000 && Math.floor(n / 100) % 10) out.push(`${below100(Math.floor(n / 100))} hundred`);
    return out;
  }
  if (n % 1e6 === 0 && n < 1e9) return below1000(n / 1e6).map(x => `${x} million`);
  return [];
}
// Every way a number written in digits may be said. "045" is a bearing: digit by digit.
export function numberWords(s, zero = ['zero', 'nought', 'oh']) {
  const [int, dec] = s.split('.');
  const digit = d => (d === '0' ? zero : [ONES[+d]]);
  const digits = ds => [...ds].reduce((acc, d) => acc.flatMap(a => digit(d).map(w => (a ? `${a} ${w}` : w))), ['']);
  let heads = int.length > 1 && int[0] === '0' ? digits(int) : intWords(+int).map(w => (w === 'zero' ? null : w)).filter(Boolean);
  if (+int === 0 && int.length === 1) heads = [...zero];
  if (dec == null) return heads;
  if (+int === 0 && int.length === 1) heads = [...heads, ''];
  return heads.flatMap(h => digits(dec).map(d => `${h ? h + ' ' : ''}point ${d}`));
}
const ORD = { one: 'first', two: 'second', three: 'third', five: 'fifth', eight: 'eighth', nine: 'ninth', twelve: 'twelfth' };
const ordinal = w => ORD[w] || (w.endsWith('y') ? w.slice(0, -1) + 'ieth' : w + 'th');
function ordinalWords(n) { return intWords(n).map(s => { const p = s.split(' '); p.push(ordinal(p.pop())); return p.join(' '); }); }

// ── The caption, as tokens ──
// Each token lists the word sequences it may be said as. A token that can't be said
// at all (a character with no entry in the sheet) is an error.
export function tokens(caption, sheet) {
  const out = [], errors = [];
  const abbrev = Object.keys(sheet.words).sort((a, b) => b.length - a.length);
  const alts = list => list.map(split);
  const push = (kind, raw, a, glued) => out.push({ kind, raw, alts: a, glued });
  const stack = [];
  let glued = false;   // no space since the last token
  const lex = (text, inner) => {
    for (let p = 0; p < text.length;) {
      const ch = text[p];
      if (/\s/.test(ch)) { glued = false; p++; continue; }
      // An abbreviation or unit, as a whole word.
      const ab = abbrev.find(k => text.startsWith(k, p) && !LETTER.test(text[p - 1] || '') && !/[0-9]/.test(text[p - 1] || '')
        && !LETTER.test(text[p + k.length] || ''));
      if (ab) {
        // GDC's: the possessive goes on the last spoken word.
        const poss = /^['’]s\b/.exec(text.slice(p + ab.length));
        push('word', ab, sheet.words[ab].map(x => split(poss ? `${x}'s` : x)), glued);
        glued = true; p += ab.length + (poss ? 2 : 0); continue;
      }
      if (LETTER.test(ch)) {
        let q = p; while (q < text.length && (LETTER.test(text[q]) || (/['’]/.test(text[q]) && LETTER.test(text[q + 1] || '')))) q++;
        const w = text.slice(p, q).toLowerCase().replace(/’/g, "'");
        const a = [[w]];
        // y = mx + c: a short run of letters may be said letter by letter.
        if (w.length > 1 && w.length <= 4 && !w.includes("'")) a.push([...w]);
        push(w.length === 1 ? 'letter' : 'word', w, a, glued); glued = true; p = q; continue;
      }
      if (/[0-9]/.test(ch)) {
        let q = p; while (/[0-9]/.test(text[q] || '')) q++;
        if (text[q] === '.' && /[0-9]/.test(text[q + 1] || '')) { q++; while (/[0-9]/.test(text[q] || '')) q++; }
        const num = text.slice(p, q), ord = /^(st|nd|rd|th)\b/i.exec(text.slice(q));
        if (ord && !num.includes('.')) { push('number', num + ord[1], alts(ordinalWords(+num)), glued); q += ord[1].length; }
        else push('number', num, alts(numberWords(num, sheet.zero)), glued);
        glued = true; p = q; continue;
      }
      if (SUB[ch]) {
        let q = p; while (SUB[text[q]]) q++;
        push('sub', text.slice(p, q), alts(sheet.symbols.subscript), glued);
        glued = false; lex([...text.slice(p, q)].map(c => SUB[c]).join(''), true); glued = true; p = q; continue;
      }
      if (SUP[ch]) {
        let q = p; while (SUP[text[q]]) q++;
        const run = text.slice(p, q);
        // A power of a bracket that holds a negative is said with "in brackets": (−3)² is
        // never "minus three squared", which is −3² (#190).
        const last = out[out.length - 1];
        if (last?.kind === ')' && last.negative && glued) last.alts = alts(sheet.bracketPower);
        if (sheet.symbols[run]) push('sup', run, alts(sheet.symbols[run]), glued);
        else { push('sup', run, alts(sheet.symbols.power), glued); glued = false; lex([...run].map(c => SUP[c]).join(''), true); }
        glued = true; p = q; continue;
      }
      if (ch === '-' && LETTER.test(text[p - 1] || '') && LETTER.test(text[p + 1] || '')) { glued = false; p++; continue; }
      if (ch === '-') { errors.push(`caption uses "-" as a minus sign; write − (U+2212)`); p++; continue; }
      // "..." is an ellipsis.
      if (ch === '…' || text.startsWith('...', p)) { push('symbol', '…', alts(sheet.symbols['…']), glued); glued = false; p += ch === '…' ? 1 : 3; continue; }
      if (PUNCT.has(ch)) { glued = false; p++; continue; }
      if (sheet.symbols[ch]) {
        // Two things side by side multiply: 2x, (n − 1)d, 3(x − 2).
        const prev = out[out.length - 1];
        if (glued && prev && ['number', 'letter', ')', 'sup'].includes(prev.kind) && (ch === '(' || ch === '√')) push('implicit', '', alts(sheet.symbols.implicit), true);
        if (ch === '(') stack.push(out.length);
        push(ch === '(' || ch === ')' ? ch : 'symbol', ch, alts(sheet.symbols[ch]), glued);
        if (ch === ')') {
          const open = stack.pop();
          if (open != null) out[out.length - 1].negative = out[open + 1]?.raw === '−';
        }
        glued = true; p++; continue;
      }
      errors.push(`caption has "${ch}", which pronunciation.json gives no spoken form`);
      p++;
    }
  };
  lex(String(caption), false);
  // Two things side by side multiply: 2x, (n − 1)d.
  const withImplicit = [];
  for (const [i, t] of out.entries()) {
    const prev = out[i - 1];
    if (i && t.glued && ['letter', 'word'].includes(t.kind) && prev && ['number', ')', 'sup'].includes(prev.kind))
      withImplicit.push({ kind: 'implicit', raw: '', alts: alts(sheet.symbols.implicit) });
    withImplicit.push(t);
  }
  return { tokens: withImplicit, errors };
}

// ── Caption against say ──
// Is there a way to say the caption's tokens, one spoken form each, that gives exactly
// the words of say? Returns null when there is, or a message saying where they part.
export function compare(caption, say, sheet) {
  const { tokens: T, errors } = tokens(caption, sheet);
  if (errors.length) return errors[0];
  const W = words(say);
  const seen = new Set();
  let best = { i: 0, j: 0 };
  const reach = (i, j) => {
    const key = i * 10000 + j;
    if (seen.has(key)) return false;
    seen.add(key);
    if (j > best.j || (j === best.j && i > best.i)) best = { i, j };
    if (i === T.length) return j === W.length;
    for (const a of T[i].alts) {
      if (a.length + j > W.length) continue;
      if (a.every((w, k) => W[j + k] === w) && reach(i + 1, j + a.length)) return true;
    }
    return false;
  };
  if (reach(0, 0)) return null;
  const t = T[best.i];
  const heard = W.slice(Math.max(0, best.j - 4), best.j).join(' ');
  const next = W.slice(best.j, best.j + 4).join(' ');
  if (!t) return `say has more words than the caption: "${next}…"`;
  const forms = t.alts.map(a => a.join(' ') || '(nothing)').slice(0, 4).map(x => `"${x}"`).join(' or ');
  return `caption and say part after "${heard}": the caption has "${t.raw || '×'}", said ${forms}, but say goes on "${next || '(end)'}"`;
}

// ── Say on its own ──
// What the voice is sent: words only, no digits or symbols, no raw abbreviations.
const NOT_SAID = /[0-9₀-₉⁰-⁹²³¹ⁿˣ+−×÷=≈≠<>≤≥±√π%°→∈ℤℝ∞✓✗½/|^*_\[\]{}]/;
export function sayProblems(say, sheet) {
  const out = [];
  const m = NOT_SAID.exec(say);
  if (m) out.push(`say has "${m[0]}"; write it the way it is said, and show the notation in caption`);
  const W = ` ${words(say).join(' ')} `;
  for (const ab of Object.keys(sheet.words)) {
    if (ab.length < 2 || !/[A-Z.]/.test(ab)) continue;
    if (new RegExp(`(^|[^A-Za-z])${ab.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&')}(?![A-Za-z])`).test(say))
      out.push(`say has "${ab}"; the voice says ${sheet.words[ab].map(x => `"${x}"`).join(' or ')}`);
  }
  for (const a of sheet.avoid) if (W.includes(` ${a} `)) out.push(`say has "${a}", which this tutor's sheet rules out`);
  return out;
}
