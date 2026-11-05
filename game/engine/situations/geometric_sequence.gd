class_name GeometricSequenceSituation
extends RefCounted
## The `geometric-sequence` situation (curriculum/question-types.json): one geometric sequence,
## with u₁, r, its terms and its sums (FAL-728). t1-geometric-sequence and t1-sum-to-infinity are
## both on it. Every value is an exact Q, except where Paper 2 solves for an irrational root, which
## comes out as a Q of nine decimal places, as a GDC gives it.
##
## need.ask is the unknown (see GeometricSequenceViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx (an index into the views' stories)
##   u1, r    the sequence (r may be missing: an x-interval has only ax, b and c)
##   n        a term number or the number of terms
##   v        the answer, or [both answers], so a rounding edge can be refused here
##   and, for one kind of question each:
##   p, q, up, uq          two given terms u_p and u_q
##   m, cond               a term whose sign settles r, and which condition is given
##   a, b, k2              k, k + a, bk; k2 = [the two k]
##   c, b, lower, shift, upper    Σ (k = lower to upper) c(b)^(k + shift)
##   last                  the last term of a finite series
##   kind                  conv, big, neg-big, one or neg-one (does a sum to infinity exist?)
##   ax, bx, cx, lo, hi    r = (ax·x + bx)/cx, and −1 < r < 1 for lo < x < hi
##   sinf, u2, roots       a given S∞, a given u₂, and the roots of the quadratic in r
##   mult                  S∞ = mult × u₁
##   digits, len           the repeating block of a recurring decimal and its length
##   h                     the height a ball is dropped from
##   t                     how far along a side the next nested square's corner sits
##   cut, shaded           a square cut into cut² squares, with `shaded` of them shaded
##   target, pct           what a story's total has to reach; its percentage
##
## The clean limits are the numbers behind the catalogue's `clean` text. The SymPy checker
## (tools/check_answers.py) holds its own copy and fails on any breach.

const TRIES := 4000
const WHOLE := [2, 3, 4, 5, -2, -3]
const FRACS := [[1, 2], [1, 3], [2, 3], [1, 4], [3, 4], [3, 2], [-1, 2], [-1, 3], [-2, 3], [-3, 2]]
const CONV := [[1, 2], [1, 3], [2, 3], [1, 4], [3, 4], [2, 5], [3, 5], [4, 5], [-1, 2], [-1, 3], [-2, 3], [-1, 4], [-3, 4]]
## Paper 2 ratios, in hundredths. Every one has a small denominator, so r¹⁰ stays an exact Q.
const P2_R := [40, 50, 60, 75, 80, 85, 90, 105, 110, 120, 125, 150, 200, -50, -60, -75, -80, -150]
const P2_CONV := [20, 25, 30, 35, 40, 45, 55, 60, 65, 70, 75, 80, 85, 90, -20, -25, -40, -50, -60, -75, -80]
const P2_NICE := [40, 50, 60, 80, 120, 125, 150, 200, 250, -50, -80, -150, -200]
## r with (1 + r)/(1 − r) simple, for a ball dropped from any height x.
const BOUNCE_P1 := [[1, 2], [2, 3], [3, 5], [3, 4], [1, 3], [1, 5], [2, 5], [5, 7]]
const BOUNCE_P2 := [50, 60, 75, 80, 90, 20]
const STORY_P1 := [[1, 2], [3, 4], [4, 5], [9, 10], [3, 5], [2, 5]]
const STORY_P2 := [65, 70, 72, 76, 84, 85, 88, 92, 95]
## 1/(1 − r) ends, for S∞ = k × u₁ on Paper 2.
const MULT_P1 := [[1, 2], [2, 3], [3, 4], [1, 3], [4, 5], [3, 5], [-1, 2], [-1, 3], [1, 4], [2, 5]]
const MULT_P2 := [200, 500, 600, 750, 800, 875, 900, -250, -3000]
## The inner corner sits t of the way along a side, so each area is t² + (1 − t)² of the last.
const NEST := [[1, 2], [1, 3], [1, 4], [2, 5], [1, 5]]
const EDGE := 0.02
const LIMIT_P1 := 200000
const LIMIT_P2 := 5000000
const DEN_MAX := 6561


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var paper: int = need.get("paper", 0)
	if paper == 0:
		paper = 1
	var ask: String = need.get("ask", "term-from-u1-r")
	var rep: String = need.get("rep", "notation")
	for i in TRIES:
		var s := _draw(rng, ask, rep, paper)
		if s.is_empty():
			continue
		s.paper = paper
		s.ask = ask
		s.rep = rep
		s.ctx = rng.int_in(0, 5)
		if _fits(s):
			return s
	push_error("GeometricSequenceSituation: no clean situation for %s" % need)
	return {}


## u₁r^(k − 1)
static func term(s: Dictionary, k: int) -> Q:
	return s.u1.mul(power(s.r, k - 1))


static func sum(s: Dictionary, k: int) -> Q:
	return partial(s.u1, s.r, k)


static func power(b: Q, e: int) -> Q:
	var out := Q.new(1)
	for i in e:
		out = out.mul(b)
	return out


static func partial(u1: Q, r: Q, k: int) -> Q:
	return u1.mul(Q.new(1).sub(power(r, k))).div(Q.new(1).sub(r))


static func to_infinity(u1: Q, r: Q) -> Q:
	return u1.div(Q.new(1).sub(r))


static func hundredths(rng: Seeded, list: Array) -> Q:
	return Q.new(rng.pick(list), 100)


static func from_pair(rng: Seeded, list: Array) -> Q:
	var p: Array = rng.pick(list)
	return Q.new(p[0], p[1])


## A GDC value: nine decimal places, as an exact Q.
static func gdc(x: float) -> Q:
	return Q.new(roundi(x * 1e9), 1000000000)


## No answer on a rounding edge, none too large, and no denominator past what a hand can do.
static func _fits(s: Dictionary) -> bool:
	var list: Array = s.v if s.v is Array else [s.v]
	for v in list:
		var x: float = v.to_float()
		if s.paper == 1:
			if absf(x) > LIMIT_P1 or v.d > DEN_MAX:
				return false
		elif absf(x) > LIMIT_P2 or (Answer.needs_rounding(v) and not Answer.rounds_clearly(x, EDGE)):
			return false
	return true


## Whole-number first terms: every term of the first `k` is whole when r is a fraction.
static func _whole_u1(rng: Seeded, r: Q, k: int, top: int) -> Q:
	var base := int(pow(float(r.d), k - 1))
	if base > top:
		return null
	var t := rng.int_in(1, maxi(top / base, 1)) * base
	return Q.new(t if rng.chance(0.85) else -t)


## u₁ and r for most questions. Paper 1 is whole terms; Paper 2 has decimals that end.
static func _sequence(rng: Seeded, paper: int, kind: String, shown: int = 4) -> Dictionary:
	var r: Q
	var u1: Q
	if paper == 2:
		r = hundredths(rng, P2_CONV if kind == "conv" else P2_R)
		u1 = Q.new(rng.int_in(1, 25) * 20)
		if rng.chance(0.15):
			u1 = u1.neg()
		return {"u1": u1, "r": r}
	match kind:
		"conv":
			r = from_pair(rng, CONV)
		"frac":
			r = from_pair(rng, FRACS)
		"whole":
			r = Q.new(rng.pick(WHOLE))
		_:
			r = Q.new(rng.pick(WHOLE)) if rng.chance(0.6) else from_pair(rng, FRACS)
	if r.is_int():
		u1 = Q.new(ExtensionViews.nonzero(rng, -5, 12))
	else:
		u1 = _whole_u1(rng, r, shown, 256)
	if u1 == null:
		return {}
	return {"u1": u1, "r": r}


## A graph's dots stay on small whole numbers, on both papers.
static func _graph_seq(rng: Seeded) -> Dictionary:
	var pick: Array = rng.pick([[1, 2, 2], [3, 2, 2], [5, 2, 2], [1, 3, 3], [2, 3, 3], [32, 1, 2], [48, 1, 2], [81, 1, 3], [54, 1, 3]])
	if pick[1] == 1:
		return {"u1": Q.new(pick[0]), "r": Q.new(1, pick[2])}
	return {"u1": Q.new(pick[0]), "r": Q.new(pick[2])}


static func _draw(rng: Seeded, ask: String, rep: String, paper: int) -> Dictionary:
	match ask:
		"r-from-terms":
			var s := _graph_seq(rng) if rep == "graph" else _sequence(rng, paper, "any")
			if not s.is_empty():
				s.v = s.r
			return s
		"term-from-u1-r":
			var s := _graph_seq(rng) if rep == "graph" else _sequence(rng, paper, "any")
			if s.is_empty():
				return s
			# Multiples of r's top, so u₁/r is a plain number for the rewritten form.
			if rep != "graph" and not s.u1.div(s.r).mul(s.r.d).is_int():
				return {}
			s.n = rng.int_in(5, 9)
			s.v = term(s, s.n)
			return s
		"term-exact":
			var s := _sequence(rng, 1, "frac")
			if s.is_empty():
				return s
			s.n = rng.int_in(6, 9)
			s.v = term(s, s.n)
			return s if not s.v.is_int() or s.r.sign() < 0 else {}
		"general-term":
			var s := _sequence(rng, paper, "any")
			if s.is_empty() or s.u1.eq(1) or s.r.d > 4 and paper == 1:
				return {}
			var a: Q = s.u1.div(s.r)
			if not a.mul(20).is_int() or a.eq(1):
				return {}
			s.v = s.u1
			return s
		"r-odd-gap", "r-even-gap", "u1-from-two-terms", "term-choose-sign":
			return _two_terms(rng, ask, paper)
		"k-consecutive":
			return _consecutive(rng, paper)
		"sum-from-u1-r":
			var s := _sequence(rng, paper, "any")
			if s.is_empty():
				return s
			s.n = rng.int_in(5, 8) if paper == 1 else rng.int_in(6, 10)
			s.v = sum(s, s.n)
			return s
		"sum-exact":
			var s := _sequence(rng, 1, "frac")
			if s.is_empty():
				return s
			s.n = rng.int_in(4, 7)
			s.v = sum(s, s.n)
			return s
		"sum-last-term":
			var s: Dictionary
			if paper == 1:
				var r: int = rng.pick([2, 3, 2, 4, 5, -2])
				s = {"u1": Q.new(rng.int_in(1, 9)), "r": Q.new(r)}
			else:
				s = {"u1": Q.new(rng.int_in(2, 40) * 2), "r": hundredths(rng, [120, 125, 150, 50, 60, 80])}
			s.n = rng.int_in(5, 9)
			s.last = term(s, s.n)
			s.v = sum(s, s.n)
			return s if paper == 1 or s.last.mul(10000).is_int() else {}
		"sum-closed-form":
			var r: int = rng.pick([2, 3, 4, 5, 6, 7, 8, 9, 10])
			var u1: int = 1 if rng.chance(0.5) else (r - 1) * rng.int_in(2, 5)
			return {"u1": Q.new(u1), "r": Q.new(r), "v": Q.new(u1, r - 1)}
		"bounce-before":
			var s := _ball(rng, paper)
			s.n = rng.int_in(3, 6)
			s.v = s.h.add(s.h.mul(2).mul(s.r).mul(Q.new(1).sub(power(s.r, s.n - 1))).div(Q.new(1).sub(s.r)))
			return s
		"sigma-first-r", "sigma-evaluate":
			return _sigma(rng, ask, paper)
		"sigma-write":
			var r: int = rng.pick([2, 3, 4, 5, -2])
			var s := {"u1": Q.new(rng.int_in(2, 9)), "r": Q.new(r), "n": rng.int_in(5, 9)}
			s.last = term(s, s.n)
			s.v = s.last
			return s
		"exists-claim", "exists-table":
			return _exists(rng, ask, paper)
		"x-interval":
			return _interval(rng)
		"x-interval-graph":
			return _interval_on_grid(rng)
		"sinf-u1-r", "sinf-terms":
			var s := _sequence(rng, paper, "conv")
			if s.is_empty():
				return s
			s.v = to_infinity(s.u1, s.r)
			return s if paper == 2 or s.v.d <= 30 else {}
		"sinf-sigma":
			var c: Q = Q.new(rng.int_in(1, 9) * 20) if paper == 2 else Q.new(rng.int_in(1, 12))
			var b: Q = hundredths(rng, [40, 50, 60, 75, 80, 90, -50]) if paper == 2 else from_pair(rng, CONV)
			var s := {"c": c, "b": b, "lower": 1, "shift": 0, "u1": c.mul(b), "r": b}
			s.v = to_infinity(s.u1, s.r)
			return s if paper == 2 or s.v.d <= 30 else {}
		"sinf-table":
			var s := {"u1": Q.new(rng.int_in(1, 30) * 10), "r": hundredths(rng, [30, 40, 50, 60, 65, 70, -40, -50, -60])}
			s.v = to_infinity(s.u1, s.r)
			return s
		"sinf-shaded":
			var cut: int = rng.pick([2, 3])
			var shaded: int = rng.int_in(1, 2 if cut == 3 else 1)
			var u1 := Q.new(shaded, cut * cut)
			var r := Q.new(1, cut * cut)
			return {"cut": cut, "shaded": shaded, "u1": u1, "r": r, "v": to_infinity(u1, r)}
		"u1-from-sinf", "r-from-sinf":
			var s := _sequence(rng, paper, "conv")
			if s.is_empty():
				return s
			# S∞ is a clean number here, so the working stays exact.
			s.sinf = to_infinity(s.u1, s.r)
			if not s.sinf.mul(100).is_int():
				return {}
			s.v = s.u1 if ask == "u1-from-sinf" else s.r
			return s
		"r-from-multiple":
			var r: Q = from_pair(rng, MULT_P1) if paper == 1 else Q.new(rng.pick(MULT_P2), 1000)
			if r.abs_q().to_float() >= 1.0:
				r = Q.new(r.n, r.d * 10)
			var s := {"r": r, "mult": Q.new(1).div(Q.new(1).sub(r)), "v": r}
			return s if s.mult.mul(10000).is_int() else {}
		"r-from-u2-reject":
			return _quadratic_reject(rng, paper)
		"r-from-u2-both":
			return _quadratic_both(rng, paper)
		"bounce-total":
			var s := _ball(rng, paper)
			s.v = s.h.mul(Q.new(1).add(s.r)).div(Q.new(1).sub(s.r))
			return s
		"bounce-multiple":
			var r: Q = from_pair(rng, BOUNCE_P1) if paper == 1 else hundredths(rng, BOUNCE_P2)
			return {"r": r, "v": Q.new(1).add(r).div(Q.new(1).sub(r)), "h": Q.new(10)}
		"recurring-decimal":
			var length := rng.int_in(1, 3)
			var top := int(pow(10.0, length))
			var digits := rng.int_in(1, top - 2)
			if digits % 10 == 0 or digits * 10 < top and length == 3 and rng.chance(0.7):
				return {}
			var u1 := Q.new(digits, top)
			var r := Q.new(1, top)
			return {"digits": digits, "len": length, "u1": u1, "r": r, "v": to_infinity(u1, r)}
		"nested-squares":
			var t: Q = from_pair(rng, NEST)
			var side := Q.new(t.d * rng.int_in(1, 3) * 2)
			var r := t.sq().add(Q.new(1).sub(t).sq())
			var s := {"t": t, "h": side, "u1": side.sq(), "r": r}
			s.v = to_infinity(s.u1, r)
			return s
		"story-total":
			var r: Q = from_pair(rng, STORY_P1) if paper == 1 else hundredths(rng, STORY_P2)
			var s := {"u1": Q.new(rng.int_in(1, 40) * 10), "r": r, "pct": r.mul(100)}
			s.v = to_infinity(s.u1, r)
			return s if paper == 2 or s.v.is_int() else {}
		"story-target":
			return _story_target(rng, paper)
	push_error("GeometricSequenceSituation: no draw for %s" % ask)
	return {}


static func _two_terms(rng: Seeded, ask: String, paper: int) -> Dictionary:
	var even: bool = ask in ["r-even-gap", "term-choose-sign"]
	var gap: int = rng.pick([2, 4]) if even else rng.pick([3, 3, 5])
	var p := rng.int_in(2, 4)
	var q := p + gap
	var r: Q
	var u1: Q
	if paper == 2:
		r = hundredths(rng, P2_NICE)
		u1 = Q.new(rng.int_in(1, 12) * 5)
	elif rng.chance(0.65):
		r = Q.new(rng.pick([2, 3, -2, -3, 2, 3, 4, 5]))
		u1 = Q.new(rng.int_in(1, 6))
	else:
		r = from_pair(rng, [[1, 2], [1, 3], [2, 3], [-1, 2], [3, 2]])
		var base := int(pow(float(r.d), q - 1))
		if base > 800:
			return {}
		u1 = Q.new(base * rng.int_in(1, 3))
	if even:
		# ±r: the sign of the positive root is the one drawn unless a view asks otherwise.
		r = r.abs_q() if ask == "r-even-gap" else r
	var s := {"u1": u1, "r": r, "p": p, "q": q}
	s.up = term(s, p)
	s.uq = term(s, q)
	if absf(s.uq.to_float()) > 40000 or absf(s.up.to_float()) > 40000 or s.up.eq(s.uq):
		return {}
	if paper == 2 and not (s.up.mul(10000).is_int() and s.uq.mul(10000).is_int()):
		return {}
	match ask:
		"r-odd-gap":
			s.v = r
		"r-even-gap":
			s.v = [r.neg(), r]
		"u1-from-two-terms":
			s.v = u1
		"term-choose-sign":
			if s.up.sign() < 0:
				return {}
			# r < 0, or it is settled by the sign of a far term an odd number of steps past p.
			s.m = p + 1 + 2 * rng.int_in(20, 45)
			s.cond = rng.pick(["ratio", "far"])
			s.n = q + 1
			s.v = term(s, s.n)
	return s


## k, k + a, bk: (k + a)² = bk². b is a square on Paper 1, so both k are simple.
static func _consecutive(rng: Seeded, paper: int) -> Dictionary:
	var a := rng.int_in(1, 4)
	if paper == 1:
		var m: int = rng.pick([2, 2, 3, 4])
		a *= m * m - 1
		var k1 := Q.new(a, m - 1)
		var k2 := Q.new(-a, m + 1)
		if rng.chance(0.3):
			a = -a
			k1 = k1.neg()
			k2 = k2.neg()
		return {"a": a, "b": m * m, "k2": [k1, k2], "v": [k1, k2]}
	var b: int = rng.pick([2, 3, 5, 6, 7, 10])
	a = rng.int_in(2, 12) * (1 if rng.chance(0.7) else -1)
	var root := sqrt(float(b))
	var both := [gdc(float(a) / (root - 1.0)), gdc(-float(a) / (root + 1.0))]
	return {"a": a, "b": b, "k2": both, "v": both}


static func _sigma(rng: Seeded, ask: String, paper: int) -> Dictionary:
	var shape: Array = rng.pick([[1, 0], [1, 0], [1, -1], [0, 0]])
	var c: Q
	var b: Q
	if paper == 1:
		if rng.chance(0.65):
			b = Q.new(rng.pick([2, 3, 4, 5, -2, -3]))
			c = Q.new(rng.int_in(2, 7))
		else:
			b = from_pair(rng, [[1, 2], [1, 3], [3, 4], [-1, 2], [2, 3]])
			c = Q.new(rng.int_in(1, 3) * int(pow(float(b.d), 5)))
	else:
		b = hundredths(rng, [40, 50, 60, 75, 80, 85, 90, 105, 110, 120, 125, 150, -60])
		c = Q.new(rng.int_in(2, 40) * 5)
	if c.eq(b) or b.eq(1):
		return {}
	var upper := rng.int_in(5, 6) if paper == 1 else rng.int_in(6, 10)
	var s := {"c": c, "b": b, "lower": shape[0], "shift": shape[1], "upper": upper}
	s.u1 = c.mul(power(b, shape[0] + shape[1]))
	s.r = b
	s.n = upper - shape[0] + 1
	s.v = [s.u1, b] if ask == "sigma-first-r" else sum(s, s.n)
	return s


static func _exists(rng: Seeded, ask: String, paper: int) -> Dictionary:
	var kind: String
	if ask == "exists-table":
		kind = rng.pick(["conv", "conv", "big", "neg-big"])
	else:
		kind = rng.pick(["conv", "conv", "conv", "big", "neg-big", "neg-big", "one", "neg-one"])
	var r: Q
	var u1 := Q.new(rng.int_in(1, 12))
	match kind:
		"conv":
			var s := _sequence(rng, paper, "conv")
			if s.is_empty():
				return s
			r = s.r
			u1 = s.u1.abs_q()
		"big":
			r = hundredths(rng, [110, 120, 125, 150, 200]) if paper == 2 else from_pair(rng, [[3, 2], [4, 3], [2, 1], [3, 1], [5, 4]])
		"neg-big":
			r = hundredths(rng, [-110, -120, -125, -150, -200]) if paper == 2 else from_pair(rng, [[-3, 2], [-4, 3], [-2, 1], [-3, 1], [-5, 4]])
		"one":
			r = Q.new(1)
		"neg-one":
			r = Q.new(-1)
	if paper == 1 and not r.is_int() and not u1.div(int(pow(float(r.d), 3))).is_int():
		u1 = u1.mul(int(pow(float(r.d), 3)))
	if paper == 2:
		u1 = u1.mul(20)
	var out := {"u1": u1, "r": r, "kind": kind, "v": Q.new(1)}
	if ask == "exists-table":
		out.v = to_infinity(u1, r) if kind == "conv" else Q.new(1)
	return out


## r = (ax + b)/c, with the ends of −1 < r < 1 whole or simple fractions.
static func _interval(rng: Seeded) -> Dictionary:
	var a: int = rng.pick([1, 1, 2, 2, 3, -1, -2])
	var b := rng.int_in(-4, 4)
	var c: int = rng.pick([2, 3, 4, 5, 6])
	if Q.gcd(Q.gcd(absi(a), absi(b)), c) != 1:
		return {}
	var lo := Q.new(-c - b, a)
	var hi := Q.new(c - b, a)
	if a < 0:
		var t := lo
		lo = hi
		hi = t
	return {"ax": a, "bx": b, "cx": c, "lo": lo, "hi": hi, "v": hi if not hi.is_zero() else lo}


## The line runs from (lo, ∓1) to (hi, ±1), with whole ends on the grid.
static func _interval_on_grid(rng: Seeded) -> Dictionary:
	var half: int = rng.pick([1, 2, 3, 4])
	var mid := rng.int_in(-3, 3)
	var up := rng.chance(0.7)
	return {"ax": 1 if up else -1, "bx": -mid if up else mid, "cx": half, "lo": Q.new(mid - half), "hi": Q.new(mid + half), "v": Q.new(mid + half if mid + half != 0 else 1)}


static func _ball(rng: Seeded, paper: int) -> Dictionary:
	var r: Q = from_pair(rng, [[1, 2], [2, 3], [3, 4], [3, 5], [4, 5], [1, 3]]) if paper == 1 else hundredths(rng, [55, 60, 65, 70, 75, 80, 85])
	var h := Q.new(r.d * r.d * r.d * rng.int_in(1, 2)) if paper == 1 and r.d <= 3 else Q.new(rng.int_in(1, 4) * 2 * r.d)
	return {"r": r, "h": h}


## u₂ < 0 and S∞ > 0: one root of S r² − S r + u₂ = 0 is in (−1, 0), the other past 1.
static func _quadratic_reject(rng: Seeded, paper: int) -> Dictionary:
	var keep: Q
	var sinf: Q
	var u2: Q
	if paper == 1:
		keep = from_pair(rng, [[-1, 2], [-1, 3], [-2, 3], [-1, 4], [-3, 4], [-2, 5]])
		sinf = Q.new(keep.d * keep.d * rng.int_in(1, 4))
		u2 = sinf.mul(keep).mul(Q.new(1).sub(keep))
		return {"sinf": sinf, "u2": u2, "roots": [keep, Q.new(1).sub(keep)], "v": keep}
	sinf = Q.new(rng.int_in(4, 60))
	u2 = Q.new(-rng.int_in(1, 40))
	var disc := 1.0 - 4.0 * u2.to_float() / sinf.to_float()
	var root := sqrt(disc)
	var lo := (1.0 - root) / 2.0
	if lo <= -0.95 or absf(lo) < 0.05 or is_equal_approx(root, roundf(root)):
		return {}
	var a := gdc(lo)
	return {"sinf": sinf, "u2": u2, "roots": [a, gdc((1.0 + root) / 2.0)], "v": a}


## 0 < u₂ < S∞/4: both roots are between 0 and 1, so both are ratios.
static func _quadratic_both(rng: Seeded, paper: int) -> Dictionary:
	if paper == 1:
		var low: Q = from_pair(rng, [[1, 3], [1, 4], [1, 5], [2, 5], [1, 6], [3, 10]])
		var other := Q.new(1).sub(low)
		var sinf := Q.new(low.d * low.d * rng.int_in(1, 3))
		var u2: Q = sinf.mul(low).mul(other)
		return {"sinf": sinf, "u2": u2, "roots": [low, other], "v": [low, other]}
	var sinf := Q.new(rng.int_in(8, 90))
	var u2 := Q.new(rng.int_in(1, 20))
	var disc := 1.0 - 4.0 * u2.to_float() / sinf.to_float()
	if disc <= 0.02:
		return {}
	var root := sqrt(disc)
	if absf(root * 40.0 - roundf(root * 40.0)) < 1e-9:
		return {}
	var both := [gdc((1.0 - root) / 2.0), gdc((1.0 + root) / 2.0)]
	return {"sinf": sinf, "u2": u2, "roots": both, "v": both}


## kind: under (the total stops short of the target), over (it passes it) or grow (no limit).
static func _story_target(rng: Seeded, paper: int) -> Dictionary:
	var kind: String = rng.pick(["under", "under", "over", "grow"])
	var u1 := Q.new(rng.int_in(2, 30) * 100)
	var r: Q
	if kind == "grow":
		r = hundredths(rng, [105, 110, 120, 125]) if paper == 2 else from_pair(rng, [[5, 4], [3, 2], [6, 5]])
	else:
		r = from_pair(rng, STORY_P1) if paper == 1 else hundredths(rng, STORY_P2)
	var limit: Q = to_infinity(u1, r)
	var near: float = limit.abs_q().to_float()
	var target: Q
	if kind == "over":
		target = Q.new(snappedi(near * 0.8, 100))
	else:
		target = Q.new(snappedi(near * 1.25, 100))
	if target.is_zero() or target.to_float() <= u1.to_float() and kind != "grow":
		return {}
	return {"u1": u1, "r": r, "kind": kind, "target": target, "sinf": limit, "v": limit.abs_q()}


## The situation as plain strings, for the answer export.
static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
