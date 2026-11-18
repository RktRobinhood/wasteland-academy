// ── EXPLAINER ITEMS (format 3) ───────────────────────────────
// The player actions format 3 adds to an explainer script (writing/explainers/README.md,
// "Player actions", GitHub #216): the call (predict) and the lines that return to it
// (back_to), a toy, a build, and a typed answer inside an example part. Each check takes
// err (breaks the format, always fails) and fix (a to-do: fails an approved script).
// tools/explainer-scripts.mjs calls them for every item it finds.
//
// Code computes the answer: a predict, a typed answer and a toy's find task are checked by
// working them out here, with evaluate(), so an answer key can't drift from its question.

// ── Arithmetic ──
// A rule or a check, as the board writes it or as code does: x² − 4, x^2 - 4, 6 − 2x,
// (−3)² − 4, 20 + 12×5. Implied multiplication (2x, 3(x + 1)) is allowed. A unary minus
// binds looser than a power, so −3² is −9, as on paper. Returns a number, or throws.
export function evaluate(src, vars = {}) {
  const s = String(src).replace(/−/g, '-').replace(/×/g, '*').replace(/÷/g, '/').replace(/²/g, '^2').replace(/³/g, '^3');
  const toks = [];
  for (let i = 0; i < s.length;) {
    const c = s[i];
    if (/\s/.test(c)) { i++; continue; }
    const num = /^\d+(\.\d+)?/.exec(s.slice(i));
    if (num) { toks.push({ n: Number(num[0]) }); i += num[0].length; continue; }
    if (/[a-z]/i.test(c)) { if (!(c in vars)) throw new Error(`no value for ${c}`); toks.push({ v: c }); i++; continue; }
    if ('+-*/^()'.includes(c)) { toks.push({ op: c }); i++; continue; }
    throw new Error(`can't read "${c}"`);
  }
  // Implied multiplication: a number, a letter or ")" followed by a letter or "(".
  const all = [];
  for (const [i, t] of toks.entries()) {
    const p = toks[i - 1];
    if (p && (p.n != null || p.v || p.op === ')') && (t.v || t.op === '(')) all.push({ op: '*' });
    all.push(t);
  }
  let at = 0;
  const peek = () => all[at], take = () => all[at++];
  const expr = () => { let v = term(); while (peek()?.op === '+' || peek()?.op === '-') v = take().op === '+' ? v + term() : v - term(); return v; };
  const term = () => { let v = unary(); while (peek()?.op === '*' || peek()?.op === '/') v = take().op === '*' ? v * unary() : v / unary(); return v; };
  const unary = () => (peek()?.op === '-' ? (take(), -unary()) : peek()?.op === '+' ? (take(), unary()) : power());
  const power = () => { const b = atom(); return peek()?.op === '^' ? (take(), b ** unary()) : b; };
  const atom = () => {
    const t = take();
    if (!t) throw new Error('ends early');
    if (t.n != null) return t.n;
    if (t.v) return vars[t.v];
    if (t.op === '(') { const v = expr(); if (take()?.op !== ')') throw new Error('a bracket is not closed'); return v; }
    throw new Error(`"${t.op}" where a number should be`);
  };
  const v = expr();
  if (at < all.length) throw new Error('more after the end');
  if (!Number.isFinite(v)) throw new Error('not a number');
  return v;
}
// A value as a script writes it: "5", "−13", "4.5", "80".
export const numberOf = v => (typeof v === 'number' ? v : /^\s*[−-]?\d+(\.\d+)?\s*$/.test(String(v ?? '')) ? Number(String(v).replace('−', '-')) : NaN);
const close = (a, b) => Math.abs(a - b) < 1e-9;
// A check: arithmetic that should give value. Returns a problem, or null.
function checkValue(check, value, what) {
  if (check == null) return null;
  let got;
  try { got = evaluate(check); } catch (e) { return `${what}: can't work out check "${check}" (${e.message})`; }
  return close(got, numberOf(value)) ? null : `${what} is ${value}, but its check "${check}" gives ${+got.toFixed(9)}`;
}

// ── The call ──
// kind type or dial: a number, compared as a number. kind choose: a tapped option, compared
// as text, from choices. answer is one value, or a list when more than one call is right.
const answersOf = p => [p.answer].flat();
export function checkPredict(p, where, refs, err) {
  if (typeof p.id !== 'string' || !p.id) err(where, 'a predict has an id, for the back_to lines that return to it');
  if (!['type', 'dial', 'choose'].includes(p.kind)) err(where, `predict kind is type, dial or choose, not ${p.kind}`);
  if (typeof p.prompt !== 'string' || !p.prompt) err(where, 'a predict has a prompt, shown on screen');
  const choose = p.kind === 'choose';
  const key = choose ? v => String(v) : numberOf;
  const answers = answersOf(p);
  if (!answers.length) err(where, 'a predict has an answer, the value the lesson will show');
  if (choose) {
    if (!Array.isArray(p.choices) || p.choices.length < 2 || new Set(p.choices).size !== p.choices.length) err(where, 'a choose predict has two or more different choices');
    for (const v of [...answers, ...(p.values || []).map(x => x.value)]) if (!(p.choices || []).includes(v)) err(where, `${v} is not one of the choices`);
  } else for (const a of answers) if (Number.isNaN(numberOf(a))) err(where, `a predict's answer is the number the lesson shows, not ${JSON.stringify(a)}`);
  if (answers.length === 1) { const c = checkValue(p.check, answers[0], 'the answer'); if (c) err(where, c); }
  else if (p.check != null) err(where, 'a predict with more than one answer has no single check');
  if (p.kind === 'dial') {
    const d = p.dial;
    if (!Array.isArray(d) || d.length !== 2 || !d.every(Number.isInteger) || d[0] >= d[1]) err(where, 'a dial predict has dial: two whole numbers, least first');
    else for (const a of answers) if (!(numberOf(a) >= d[0] && numberOf(a) <= d[1])) err(where, `the answer ${a} is off the dial`);
  }
  const seen = new Set(answers.map(key));
  for (const [i, v] of (p.values || []).entries()) {
    const w = `${where}.values[${i}]`;
    if (!choose && Number.isNaN(numberOf(v.value))) { err(w, `a value is a number, not ${JSON.stringify(v.value)}`); continue; }
    if (seen.has(key(v.value))) err(w, `the value ${v.value} is the answer or another value`);
    seen.add(key(v.value));
    if (!refs.has(v.misconception)) err(w, `misconception ${v.misconception} is not in curriculum/question-types.json`);
    const vc = checkValue(v.check, v.value, `the value ${v.value}`); if (vc) err(w, vc);
  }
}
// back_to: lines played on the stored call. In the recap it covers every case (#216).
export function checkBackTo(b, where, predicts, err, fix, inRecap) {
  const p = predicts.get(b.predict);
  if (!p) return err(where, `back_to ${b.predict} is not a predict earlier in the script`);
  const key = p.kind === 'choose' ? v => String(v) : numberOf;
  const has = g => Array.isArray(g) && g.length > 0;
  const values = new Set((b.values || []).map(v => key(v.value)));
  for (const [i, v] of (b.values || []).entries()) {
    if (!(p.values || []).some(x => key(x.value) === key(v.value))) err(`${where}.values[${i}]`, `${v.value} is not one of predict ${p.id}'s values`);
    if (!has(v.lines)) err(`${where}.values[${i}]`, 'a back_to value has lines');
  }
  if (!inRecap) return;
  if (!has(b.match)) fix(where, `the recap's back_to ${p.id} has no line for a call that matched`);
  if (!has(b.other)) fix(where, `the recap's back_to ${p.id} has no line for any other call`);
  for (const v of p.values || []) if (!values.has(key(v.value))) fix(where, `the recap's back_to ${p.id} has no line for a call of ${v.value} (${v.misconception})`);
}

// ── Toys ──
// A toy item is the lesson player's (game/docs/TOYS.md): the toy's id, its set-up and its
// tasks. The catalogue, writing/explainers/toys.json, says which toys exist and which task
// kinds each one takes (#221).
export function checkToy(t, where, toys, err) {
  const spec = toys?.toys?.[t.toy];
  if (!spec) return err(where, `toy ${t.toy} is not in writing/explainers/toys.json`);
  if (t.optional != null && typeof t.optional !== 'boolean') err(where, 'optional is true or false');
  if (!Array.isArray(t.tasks) || !t.tasks.length) err(where, 'a toy has at least one task');
  if (t.toy === 'relay') checkRelay(t, where, err);
  for (const [i, task] of (t.tasks || []).entries()) {
    const w = `${where}.tasks[${i}]`;
    if (!(spec.tasks || []).includes(task.kind)) { err(w, `the ${t.toy} toy has no task kind ${task.kind} (${(spec.tasks || []).join(', ')})`); continue; }
    if (task.then != null && !Array.isArray(task.then)) err(w, 'then is a list of beats');
  }
}
function checkRelay(t, where, err) {
  const run = (rule, x) => evaluate(rule, { x });
  let ok = true;
  for (const k of ['rule', 'broken']) {
    if (k === 'broken' && t.broken == null) continue;
    if (typeof t[k] !== 'string' || !t[k].trim()) { err(where, `the relay needs a ${k} in x`); ok = false; continue; }
    try { run(t[k], 1); } catch (e) { err(where, `the relay can't read its ${k} "${t[k]}" (${e.message})`); ok = false; }
  }
  const d = t.dial ?? [-5, 5];
  if (!Array.isArray(d) || d.length !== 2 || !d.every(Number.isInteger) || d[0] >= d[1]) { err(where, "the relay's dial is two whole numbers, least first"); return; }
  for (const k of Object.keys(t.places || {})) if (Number.isNaN(numberOf(k))) err(`${where}.places`, `${k} is not an output`);
  if (!ok) return;
  const inputs = []; for (let x = d[0]; x <= d[1]; x++) inputs.push(x);
  for (const [i, task] of (t.tasks || []).entries()) {
    const w = `${where}.tasks[${i}]`;
    if (task.kind === 'free' && !(Number.isInteger(task.count) && task.count >= 1)) err(w, 'a free task has count, the number of sends');
    if (task.kind === 'send' && !(Number.isInteger(task.input) && task.input >= d[0] && task.input <= d[1])) err(w, `send input ${task.input} is not a whole number on the dial ${JSON.stringify(d)}`);
    if (task.kind === 'find') {
      if (typeof task.output !== 'number') { err(w, 'a find task has output, a number'); continue; }
      const hits = inputs.filter(x => close(run(t.rule, x), task.output));
      if (!hits.length) err(w, `no input on the dial ${JSON.stringify(d)} gives ${task.output}`);
      if (task.place != null && t.places?.[String(task.output)] !== task.place) err(w, `place ${task.place} is not the relay's place for ${task.output}`);
    }
  }
}

// ── Build ──
// The player picks each board line from three tiles: one right, each wrong one keyed to a
// misconception and answered by a not-yet line (#216).
export function checkBuild(b, where, refs, err) {
  if (!Array.isArray(b.steps) || !b.steps.length) return err(where, 'a build has at least one step');
  for (const [i, s] of b.steps.entries()) {
    const w = `${where}.steps[${i}]`;
    const tiles = s.tiles || [];
    if (tiles.length !== 3) err(w, `a build step has three tiles, not ${tiles.length}`);
    if (!Number.isInteger(s.answer) || s.answer < 0 || s.answer >= tiles.length) { err(w, `answer ${s.answer} is not an index of its ${tiles.length} tiles`); continue; }
    if (new Set(tiles.map(t => t.write)).size !== tiles.length || tiles.some(t => typeof t.write !== 'string' || !t.write)) err(w, 'every tile writes a line, and no two tiles write the same one');
    const covered = new Map();
    for (const [j, l] of (s.not_yet || []).entries()) for (const k of l.for || []) {
      if (k === s.answer || !tiles[k]) err(`${w}.not_yet[${j}]`, `for ${k} is not a wrong tile`);
      else if (covered.has(k)) err(`${w}.not_yet[${j}]`, `tile ${k} already has a not-yet line`);
      else covered.set(k, j);
    }
    for (const [k, t] of tiles.entries()) {
      if (k === s.answer) { if (t.misconception != null) err(`${w}.tiles[${k}]`, 'the right tile names no misconception'); continue; }
      if (!refs.has(t.misconception)) err(`${w}.tiles[${k}]`, `a wrong tile is keyed to a misconception in curriculum/question-types.json, not ${t.misconception}`);
      if (!covered.has(k)) err(`${w}.tiles[${k}]`, 'a wrong tile has a not-yet line (list it in a not-yet line\'s for)');
    }
  }
}

// ── A typed answer inside an example part ──
export function checkTyped(t, where, section, refs, err, fix) {
  if (section.kind !== 'example') return err(where, 'a typed answer goes inside an example');
  const parts = (section.problem?.parts || []).map(p => p.part);
  if (!parts.includes(t.part)) err(where, `part ${t.part} is not one of the example's parts (${parts.join(', ') || 'none'})`);
  if (typeof t.prompt !== 'string' || !t.prompt) err(where, 'a typed answer has a prompt');
  if (typeof t.answer !== 'string' || !t.answer) err(where, 'a typed answer has answer, as the player would type it');
  const c = checkValue(t.check, t.answer, 'the answer'); if (c) err(where, c);
  if (!t.right?.length) err(where, 'a typed answer has a right line');
  const wrong = new Map();
  for (const [i, x] of (t.wrong || []).entries()) {
    if (!refs.has(x.misconception)) err(`${where}.wrong[${i}]`, `misconception ${x.misconception} is not in curriculum/question-types.json`);
    if (String(x.answer) === t.answer || (t.accept || []).includes(String(x.answer))) err(`${where}.wrong[${i}]`, `${x.answer} is also the right answer`);
    wrong.set(x.misconception, x);
  }
  const ny = t.not_yet || [];
  const neutral = ny.filter(l => l.misconception == null);
  if (neutral.length !== 1) fix(`${where}.not_yet`, `has ${neutral.length} neutral lines; key every not-yet line but one to a wrong answer's misconception`);
  for (const [i, l] of ny.entries()) if (l.misconception != null && !wrong.has(l.misconception))
    err(`${where}.not_yet[${i}]`, `misconception ${l.misconception} is not the misconception of one of the typed answer's wrong answers`);
}
