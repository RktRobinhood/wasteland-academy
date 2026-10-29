class_name GdcKit
extends RefCounted
## What the Graphs and key features region's situations share (FAL-420): the numerical
## tools a GDC uses (every zero of a function on an interval, found by sampling and
## Brent's root finder, engine/brent.gd), the way the region writes a function and its
## numbers, and the cards of a pick-the-graph question.
##
## Paper 2 numbers are found numerically. The engine keeps them as Q to 9 decimal places
## (TriangleViews.qf), shows 6 significant figures in the working (as a GDC does) and
## asks for 3. tools/check_answers.py finds every one again with its own root brackets.

## Samples per interval when looking for sign changes. Features are at least 0.5 apart
## (the situations' clean limits), so a step of a tenth or less never misses one.
const SAMPLES := 160


## Every zero of f in [lo, hi], in order: a sign change between samples, closed in by
## Brent's root finder. f is continuous on [lo, hi] (the situations keep asymptotes
## outside it). A zero exactly at a sample is kept too.
static func zeros(f: Callable, lo: float, hi: float, n: int = SAMPLES) -> Array:
	var out: Array = []
	var xa := lo
	var fa: float = f.call(lo)
	if fa == 0.0:
		out.append(lo)
	for i in range(1, n + 1):
		var xb := lo + (hi - lo) * i / n
		var fb: float = f.call(xb)
		if fb == 0.0:
			out.append(xb)
		elif fa != 0.0 and signf(fa) != signf(fb) and is_finite(fa) and is_finite(fb):
			var r := Brent.root(f, xa, xb)
			if r.ok:
				out.append(r.x)
		xa = xb
		fa = fb
	return out


## The turning points of f on (lo, hi), from the zeros of its derivative df: each
## {"x", "y", "kind"} with kind "max" or "min" (df changes sign through it).
static func turns(f: Callable, df: Callable, lo: float, hi: float, n: int = SAMPLES) -> Array:
	var out: Array = []
	for x in zeros(df, lo, hi, n):
		if x <= lo or x >= hi:
			continue
		var h := 1e-4 * maxf(1.0, hi - lo)
		var before: float = df.call(x - h)
		var after: float = df.call(x + h)
		if signf(before) == signf(after):
			continue
		out.append({"x": x, "y": f.call(x), "kind": "max" if before > 0.0 else "min"})
	return out


# ── Numbers ──────────────────────────────────────────────────

static func qf(x: float) -> Q:
	return TriangleViews.qf(x)


## 3 significant figures, as the answer is written.
static func S(x: Variant) -> String:
	return Fmt.sf(x)


## 6 significant figures: a GDC's screen, for the working.
static func W(x: Variant) -> String:
	return Fmt.sf(x, 6)


## Whether a GDC value is a fair 3 s.f. answer: it needs rounding clearly (not on a
## rounding edge), and it is not a whole number by accident (2.00).
static func fair(x: float) -> bool:
	if not Answer.rounds_clearly(x, 0.05):
		return false
	return absf(x - roundf(x)) > 0.02


## A coefficient in front of a term, as a decimal: "" for 1, "−" for −1, "2.5".
static func lead(v: Variant) -> String:
	var q := Q.of(v)
	if q.eq(1):
		return ""
	if q.eq(-1):
		return "−"
	return Fmt.dec(q)


## A term joined on with its sign: " + 2.5x", " − x", " − 3". "" for a zero coefficient.
static func join(v: Variant, body: String) -> String:
	var q := Q.of(v)
	if q.is_zero():
		return ""
	var mag := q.abs_q()
	var c := Fmt.dec(mag) if body == "" else lead(mag)
	return (" − " if q.sign() < 0 else " + ") + c + body


## The first term of a sum: "2.5x", "−x", "3".
static func first(v: Variant, body: String) -> String:
	var q := Q.of(v)
	return (Fmt.dec(q) if body == "" else lead(q)) + body


## A point to 3 s.f.: "(1.39, −3.21)".
static func pt(x: float, y: float) -> String:
	return "(%s, %s)" % [S(x), S(y)]


## A point to 6 s.f., for the working.
static func pt6(x: float, y: float) -> String:
	return "(%s, %s)" % [W(x), W(y)]


## A whole-unit window around [lo, hi] × [ylo, yhi], with a margin.
static func window(lo: float, hi: float, ylo: float, yhi: float, pad_x: float = 0.6, pad_y: float = 0.15) -> Array:
	var span := maxf(yhi - ylo, 1.0)
	return [floori(lo - pad_x), ceili(hi + pad_x), floori(ylo - pad_y * span), ceili(yhi + pad_y * span)]


# ── Pick the graph (Q13) ─────────────────────────────────────
# Students can't draw, so a sketch question shows four graphs and asks which is right.
# Each wrong graph changes one thing, a typical mistake from the type's misconceptions:
# its `mistake` names what changed (the checker tests that change alone) and `ref` the
# misconception it shows ("" for a mistake the catalogue has no ref for, with `why`).

const LETTERS := ["A", "B", "C", "D"]


## A card: the curves (each sampled [[x, y], ...]), its labelled points ([[x, y, label]])
## and dashed lines, in the window [x0, x1, y0, y1].
static func card(curves: Array, points: Array, win: Array, vlines: Array = [], hlines: Array = []) -> Dictionary:
	var g := Plot.spec(curves, points, win[0], win[1], win[2], win[3], hlines, vlines)
	g.card = true
	return g


## The builder's half of a pick-the-graph question: the right card and three wrong ones,
## shuffled and lettered. Returns {"answer", "graphs", "letter"}: the answer is a choice
## of "Graph A" to "Graph D"; graphs is [{"graph", "correct", "ref", "mistake", "why"}]
## in letter order. QuestionEngine makes them the question's options as they are.
static func pick(right: Dictionary, wrongs: Array, rng: Seeded) -> Dictionary:
	var all: Array = [{"graph": right, "correct": true, "ref": "", "mistake": "", "why": ""}]
	for w in wrongs.slice(0, 3):
		all.append({"graph": w.graph, "correct": false, "ref": w.get("ref", ""), "mistake": w.mistake, "why": w.get("why", "")})
	assert(all.size() == 4, "pick-the-graph needs three wrong graphs")
	all = rng.shuffled(all)
	var letter := ""
	for i in all.size():
		all[i].text = "Graph " + LETTERS[i]
		if all[i].correct:
			letter = all[i].text
	var opts: Array = all.map(func(g): return g.text)
	var ans := Answer.make("graph", {"v": letter}, {"options": opts})
	return {"answer": ans, "graphs": all, "letter": letter}


## The curve of f sampled on [lo, hi].
static func curve(f: Callable, lo: float, hi: float) -> Array:
	return Plot.sample(f, lo, hi)
