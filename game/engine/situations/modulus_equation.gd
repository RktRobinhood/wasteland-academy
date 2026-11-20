class_name ModulusEquationSituation
extends RefCounted
## The `modulus-equation` situation (curriculum/question-types.json), for
## fn-ahl-modulus-equations (AHL2.16, FAL-1008): a modulus against a constant, a modulus, a
## line or a curve. Every solution is picked or worked out before anything is written, so
## both cases, the rejected root and every end of a solution set are known exactly (or, for
## a curve, to the GDC's precision).
##
## need.kind picks the form; generate() returns, with `kind` and `paper`:
##   shift  |x − a| = k: a, k ints (k > 0); roots [a − k, a + k] (Q)
##   lin    |ax + b| = k: a (2 to 4), b, k ints; roots [(−k − b)/a, (k − b)/a]
##   mm     |ax + b| = |cx + d|: a ≠ c (1 to 4), b ≠ ±d; r1 = (d − b)/(a − c) from the
##          positive case and r2 = −(b + d)/(a + c) from the negative
##   ml     |ax + b| = mx + c: a (1 to 4), m ≠ ±a; x1 = (c − b)/(a − m) (the inside equal to
##          the line), x2 = −(b + c)/(a + m) (the inside equal to minus the line). Exactly
##          one makes mx + c negative: good, bad (Q)
##   count  y = |f(x)|, f = A(x − p)(x − q): A ∈ {±1, ±2}, p < q with q − p even, so the
##          hump's top (h, d) is whole: h = (p + q)/2, d = |A|((q − p)/2)²
##   lt/gt  |x − a| (form shift) or |ax + b| (form lin) < or ≤ (lt), > or ≥ (gt) a positive
##          constant: rel, and the critical values lo < hi (Q)
##   amm    |x + a| rel m|x − b|, m ∈ {2, 3}, a ≠ −b: the crossings lo < hi (Q), and the
##          set is between them for ≥ and >, outside them for ≤ and <
##   curve  |f(x)| rel g(x) on a closed domain, f a quadratic x² + Bx + C ("quad") or
##          A sin x + D / A cos x + D ("trig"), g a line mx + c: the crossings in the domain
##          (floats, fair to 3 s.f.), the solution set's pieces, and for a quadratic the
##          set over every real x (the domain slip), when it differs
##
## A set is a list of pieces {"lo", "hi", "lo_in", "hi_in"}; an end is an "end"
## {"v": float, "t": text} (exact text, 3 s.f., or π), or null for no end. set_text writes
## one canonically, so two sets read the same only when they are the same set.
##
## The checker (tools/check_answers.py, MODEQ_*) has its own copy of the clean limits.

const TRIES := 6000
## The window a curve's crossings are looked for in, and the sampling.
const GRID := 3000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var kind: String = need.get("kind", "shift")
	var paper: int = 2 if int(need.get("paper", 1)) == 2 else 1
	for i in TRIES:
		var s: Dictionary = {}
		match kind:
			"shift":
				s = _shift(rng)
			"lin":
				s = _lin(rng)
			"mm":
				s = _mm(rng)
			"ml":
				s = _ml(rng)
			"count":
				s = _count(rng)
			"lt", "gt":
				s = _ineq(rng, kind)
			"amm":
				s = _amm(rng)
			"curve":
				s = _curve(rng, need.get("graph", false))
		if s.is_empty():
			continue
		s.kind = kind
		s.paper = 2 if kind == "curve" else paper
		return s
	push_error("ModulusEquationSituation: no clean situation for %s" % need)
	return {}


static func nz(rng: Seeded, lo: int, hi: int) -> int:
	return ExtensionViews.nonzero(rng, lo, hi)


# ── Equations ────────────────────────────────────────────────

static func _shift(rng: Seeded) -> Dictionary:
	var a := nz(rng, -8, 8)
	var k := rng.int_in(1, 9)
	if a == k or a == -k:
		return {}
	return {"a": a, "k": k, "roots": [Q.new(a - k), Q.new(a + k)]}


static func _lin(rng: Seeded) -> Dictionary:
	var a := rng.int_in(2, 4)
	var b := nz(rng, -9, 9)
	var k := rng.int_in(1, 9)
	if k == absi(b) or Q.gcd(a, absi(b)) != 1:
		return {}
	return {"a": a, "b": b, "k": k, "roots": [Q.new(-k - b, a), Q.new(k - b, a)]}


static func _mm(rng: Seeded) -> Dictionary:
	var a := rng.int_in(1, 4)
	var c := rng.int_in(1, 4)
	var b := nz(rng, -8, 8)
	var d := nz(rng, -8, 8)
	if a == c or b == d or b == -d:
		return {}
	# Each modulus in lowest terms, so its corner is where it reads.
	if Q.gcd(a, absi(b)) != 1 or Q.gcd(c, absi(d)) != 1:
		return {}
	var r1 := Q.new(d - b, a - c)
	var r2 := Q.new(-b - d, a + c)
	if r1.eq(r2) or r1.d > 6 or r2.d > 6 or absf(r1.to_float()) > 12 or absf(r2.to_float()) > 12:
		return {}
	return {"a": a, "b": b, "c": c, "d": d, "r1": r1, "r2": r2}


static func _ml(rng: Seeded) -> Dictionary:
	var a := rng.int_in(1, 4)
	var b := nz(rng, -8, 8)
	var m := nz(rng, -3, 3)
	var c := nz(rng, -8, 8)
	if m == a or m == -a or Q.gcd(a, absi(b)) != 1:
		return {}
	var x1 := Q.new(c - b, a - m)
	var x2 := Q.new(-b - c, a + m)
	if x1.eq(x2) or x1.d > 6 or x2.d > 6:
		return {}
	var y1 := x1.mul(m).add(c)
	var y2 := x2.mul(m).add(c)
	# Exactly one root makes the line negative (and neither makes it 0).
	if y1.is_zero() or y2.is_zero() or y1.sign() == y2.sign():
		return {}
	var good := x1 if y1.sign() > 0 else x2
	var bad := x2 if y1.sign() > 0 else x1
	if absf(good.to_float()) > 10 or absf(bad.to_float()) > 10 or bad.is_zero() or good.is_zero() or good.eq(bad.neg()):
		return {}
	return {"a": a, "b": b, "m": m, "c": c, "x1": x1, "x2": x2, "good": good, "bad": bad,
		"good_case": 1 if y1.sign() > 0 else 2}


static func _count(rng: Seeded) -> Dictionary:
	var A: int = [1, 1, -1, 2, -1][rng.int_in(0, 4)]
	var w: int = [2, 4, 6][rng.int_in(0, 2)]
	var p := rng.int_in(-6, 2)
	var q := p + w
	var d := absi(A) * (w / 2) * (w / 2)
	if d < 2 or d > 9 or q > 6 or p == 0 or q == 0:
		return {}
	var ask: String = ["count", "count", "three", "four", "k-three"][rng.int_in(0, 4)]
	var k := 0
	match ask:
		"count":
			k = rng.int_in(1, d - 1)
		"three":
			k = d
	return {"A": A, "p": p, "q": q, "h": (p + q) / 2, "dtop": d, "ask": ask, "k": k}


# ── Inequalities ─────────────────────────────────────────────

static func _ineq(rng: Seeded, kind: String) -> Dictionary:
	var s := {"form": "shift" if rng.chance(0.5) else "lin"}
	if s.form == "shift":
		s.a = nz(rng, -8, 8)
		s.k = rng.int_in(1, 9)
		if s.a == s.k or s.a == -s.k:
			return {}
		s.lo = Q.new(s.a - s.k)
		s.hi = Q.new(s.a + s.k)
	else:
		s.a = rng.int_in(2, 4)
		s.b = nz(rng, -9, 9)
		s.k = rng.int_in(1, 9)
		if Q.gcd(s.a, absi(s.b)) != 1 or s.k == absi(s.b):
			return {}
		s.lo = Q.new(-s.k - s.b, s.a)
		s.hi = Q.new(s.k - s.b, s.a)
	if s.lo.is_zero() or s.hi.is_zero() or s.lo.eq(s.hi.neg()):
		return {}
	var strict := rng.chance(0.5)
	s.rel = ("<" if strict else "≤") if kind == "lt" else (">" if strict else "≥")
	return s


static func _amm(rng: Seeded) -> Dictionary:
	var m: int = [2, 2, 3][rng.int_in(0, 2)]
	var a := nz(rng, -6, 6)
	var b := nz(rng, -6, 6)
	if a == -b:
		return {}
	var r1 := Q.new(m * b + a, m - 1)
	var r2 := Q.new(m * b - a, m + 1)
	var lo: Q = r1 if r1.lt(r2) else r2
	var hi: Q = r2 if r1.lt(r2) else r1
	if lo.is_zero() or hi.is_zero() or lo.eq(hi.neg()) or absf(lo.to_float()) > 12 or absf(hi.to_float()) > 12:
		return {}
	var rel: String = ["<", "≤", ">", "≥"][rng.int_in(0, 3)]
	return {"m": m, "a": a, "b": b, "lo": lo, "hi": hi, "rel": rel, "inside": rel in [">", "≥"]}


## |f(x)| against a line on a domain, solved as a GDC would.
static func _curve(rng: Seeded, graph: bool) -> Dictionary:
	var s := {"fam": "quad" if rng.chance(0.55) else "trig"}
	if s.fam == "quad":
		var p := rng.int_in(-4, 3)
		var w := rng.int_in(2, 5)
		s.B = -(2 * p + w)
		s.C = p * (p + w) + rng.int_in(-2, 2)
		# Two zeros, so |f| has a reflected part.
		var disc: int = s.B * s.B - 4 * s.C
		if disc <= 0:
			return {}
		s.d1 = p - rng.int_in(1, 2)
		s.d2 = p + w + rng.int_in(1, 2)
		s.dom = [_end(s.d1, Fmt.num(s.d1)), _end(s.d2, Fmt.num(s.d2))]
	else:
		s.fn = "sin" if rng.chance(0.5) else "cos"
		s.A = rng.int_in(1, 3)
		s.D = rng.int_in(-2, 2)
		if s.D == 0 and s.A == 1:
			return {}
		var two := rng.chance(0.5)
		s.dom = [_end(0.0, "0"), _end(TAU if two else PI, "2π" if two else "π")]
	s.m = [Q.new(1, 2), Q.new(1), Q.new(-1, 2), Q.new(-1), Q.new(2), Q.new(0)][rng.int_in(0, 5)]
	s.c = rng.int_in(0, 6)
	if s.m.is_zero() and s.c == 0:
		return {}
	s.rel = ["<", "≤", ">", "≥"][rng.int_in(0, 3)]
	var lo: float = s.dom[0].v
	var hi: float = s.dom[1].v
	var xs := crossings(s, lo, hi)
	if xs.is_empty() or xs.size() > 3:
		return {}
	for x in xs:
		if not GdcKit.fair(x) or x - lo < 0.15 or hi - x < 0.15:
			return {}
	for i in xs.size() - 1:
		if xs[i + 1] - xs[i] < 0.3:
			return {}
	s.xs = xs
	s.set = solve_on(s, lo, hi, xs, s.dom[0], s.dom[1])
	if s.set.is_empty() or s.set.size() > 2:
		return {}
	# The domain slip: the same inequality over every real x (a quadratic only).
	s.wide = []
	if s.fam == "quad":
		var every := crossings(s, -60.0, 60.0)
		if every.size() > 4:
			return {}
		for x in every:
			if not GdcKit.fair(x) or absf(x) > 40:
				return {}
		var wide := solve_on(s, -1e9, 1e9, every, null, null)
		if wide.size() <= 3 and set_text(wide) != set_text(s.set):
			s.wide = wide
			s.wide_xs = every
	if graph:
		var top := 0.0
		for i in 81:
			var x := lo + (hi - lo) * i / 80.0
			top = maxf(top, absf(f_at(s, x)))
		if top > 14:
			return {}
	return s


static func _end(v: float, t: String) -> Dictionary:
	return {"v": float(v), "t": t}


## An end at a crossing, to 3 s.f.
static func cross_end(x: float) -> Dictionary:
	return {"v": x, "t": Fmt.sf(x), "x": true}


static func f_at(s: Dictionary, x: float) -> float:
	if s.fam == "quad":
		return x * x + s.B * x + s.C
	var t := sin(x) if s.fn == "sin" else cos(x)
	return s.A * t + s.D


static func g_at(s: Dictionary, x: float) -> float:
	return Q.of(s.m).to_float() * x + s.c


static func h_at(s: Dictionary, x: float) -> float:
	return absf(f_at(s, x)) - g_at(s, x)


## Where |f(x)| = g(x) between lo and hi: each a sign change of |f| − g, found by
## bisection. A touch or a near-touch (the gap small away from every crossing, or growing
## slowly from one) gives [], so a tangency never makes a fragile answer.
static func crossings(s: Dictionary, lo: float, hi: float) -> Array:
	var out: Array = []
	var prev := h_at(s, lo)
	var xp := lo
	for i in range(1, GRID + 1):
		var x := lo + (hi - lo) * i / GRID
		var y := h_at(s, x)
		if (y > 0.0) != (prev > 0.0):
			var a := xp
			var b := x
			var fa := prev
			for j in 80:
				var mid := (a + b) / 2.0
				var fm := h_at(s, mid)
				if (fm > 0.0) == (fa > 0.0):
					a = mid
					fa = fm
				else:
					b = mid
			var r := (a + b) / 2.0
			if absf(h_at(s, r - 0.05)) < 0.02 or absf(h_at(s, r + 0.05)) < 0.02:
				return []
			out.append(r)
		prev = y
		xp = x
	for i in GRID + 1:
		var x := lo + (hi - lo) * i / GRID
		if absf(h_at(s, x)) < 0.03 and not out.any(func(r): return absf(r - x) < 0.05):
			return []
	return out


## Whether |f(x)| rel g(x) at x.
static func holds(s: Dictionary, x: float) -> bool:
	var h := h_at(s, x)
	match s.rel:
		"<", "≤":
			return h < 0.0
	return h > 0.0


## The solution set between the ends (null for none), cut at the crossings xs.
static func solve_on(s: Dictionary, lo: float, hi: float, xs: Array, end_lo: Variant, end_hi: Variant) -> Array:
	var cuts: Array = [end_lo]
	for x in xs:
		cuts.append(cross_end(x))
	cuts.append(end_hi)
	var inc: bool = s.rel in ["≤", "≥"]
	var out: Array = []
	for i in cuts.size() - 1:
		var a: float = lo if cuts[i] == null else cuts[i].v
		var b: float = hi if cuts[i + 1] == null else cuts[i + 1].v
		if cuts[i] == null:
			a = b - 50.0
		if cuts[i + 1] == null:
			b = a + 50.0
		if not holds(s, (a + b) / 2.0):
			continue
		# A domain end is in the set; a crossing is in it for ≤ and ≥.
		var lo_in: bool = i == 0 or inc
		var hi_in: bool = i == cuts.size() - 2 or inc
		out.append({"lo": cuts[i], "hi": cuts[i + 1], "lo_in": lo_in, "hi_in": hi_in})
	return out


## The complement of a set inside the domain [d0, d1] (both ends dicts).
static func complement(pieces: Array, d0: Dictionary, d1: Dictionary) -> Array:
	var out: Array = []
	var at: Dictionary = d0
	var at_in := true
	for p in pieces:
		if p.lo.v > at.v + 1e-12:
			out.append({"lo": at, "hi": p.lo, "lo_in": at_in, "hi_in": not p.lo_in})
		at = p.hi
		at_in = not p.hi_in
	if at.v < d1.v - 1e-12:
		out.append({"lo": at, "hi": d1, "lo_in": at_in, "hi_in": true})
	return out


# ── Writing a set ────────────────────────────────────────────

## An exact end: {"v", "t"} from a Q.
static func qend(q: Q) -> Dictionary:
	return {"v": q.to_float(), "t": Fmt.num(q)}


static func piece_text(p: Dictionary, v: String = "x") -> String:
	var l := "≤" if p.lo_in else "<"
	var r := "≤" if p.hi_in else "<"
	if p.lo == null:
		return "%s %s %s" % [v, r, p.hi.t]
	if p.hi == null:
		return "%s %s %s" % [v, "≥" if p.lo_in else ">", p.lo.t]
	return "%s %s %s %s %s" % [p.lo.t, l, v, r, p.hi.t]


## A set as the answer writes it: its pieces left to right, joined by "or".
static func set_text(pieces: Array, v: String = "x") -> String:
	return " or ".join(pieces.map(func(p): return piece_text(p, v)))


## lo < x < hi (between) and x < lo or x > hi (outside), with the ends in or out.
static func between(lo: Q, hi: Q, inc: bool) -> Array:
	return [{"lo": qend(lo), "hi": qend(hi), "lo_in": inc, "hi_in": inc}]


static func outside(lo: Q, hi: Q, inc: bool) -> Array:
	return [{"lo": null, "hi": qend(lo), "lo_in": false, "hi_in": inc}, {"lo": qend(hi), "hi": null, "lo_in": inc, "hi_in": false}]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
