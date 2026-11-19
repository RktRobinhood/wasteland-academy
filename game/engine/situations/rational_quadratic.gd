class_name RationalQuadraticSituation
extends RefCounted
## The `rational-quadratic` situation (curriculum/question-types.json), FAL-1007: the AA HL
## rational functions of AHL2.13. Two forms, each drawn from the features it must have, so
## every asymptote, intercept and turning value is known before anything is hidden:
##
##   lq  f(x) = (ax + b)/(x² + px + q), a linear over a quadratic. Its denominator has
##       two whole zeros r₁ < r₂ (p = −(r₁ + r₂), q = r₁r₂), one repeated zero, or none:
##       (x + h)² + s², so p = 2h and q = h² + s². The horizontal asymptote is y = 0.
##   ql  f(x) = (mx² + bx + c)/(x + e), a quadratic over a linear, written from its division
##       f(x) = mx + k + R/(x + e) (b = me + k, c = ke + R, R ≠ 0): the vertical asymptote
##       x = −e and the oblique asymptote y = mx + k. With `roots`, the numerator is
##       m(x − s₁)(x − s₂) for whole s₁ < s₂.
##
## generate() returns, for lq:
##   form "lq";  a, b, p, q  ints;  nz  the denominator's real zeros (0, 1 or 2);  zs  them,
##   in order (ints);  fake  for nz = 0, the two whole numbers −h ± s (the zeros a student
##   who believes every quadratic has two would find by dropping the discriminant's sign);
##   z  Q, the numerator's zero −b/a;  yi  Q, the y-intercept b/q
## and with `range` (nz = 0): E = b² − abp + a²q (> 0), and the turning points (xlo, ylo)
## and (xhi, yhi), the least and greatest values: Q when exact (Paper 1, E a square), else
## floats to be given to 3 s.f. (Paper 2). The range is ylo ≤ f(x) ≤ yhi.
## For ql:
##   form "ql";  m, b, c, e, k, R  ints;  roots  [s₁, s₂] or [];  yi  Q, c/e
## and with `turns` (mR > 0): L < U, the turning values k − me ∓ 2√(mR), and xL, xU, where
## they are (Q when exact, Paper 1 with mR a square; floats on Paper 2). The range is
## f(x) ≤ L or f(x) ≥ U.
##
## need: form ("lq", "ql" or "any"); den for lq ("two", "none", "count": two, one or none,
## for the discriminant-count method, or "any": two, or count when the method is
## discriminant-count); roots, turns, range (bool); graph (every feature inside the plot,
## RationalQuadraticViews.WIN); paper (1 or 2). `family` only keeps the views' families apart.
##
## The clean limits below are the checker's too (tools/check_answers.py, R9RQ_*).

const TRIES := 6000
## A simple fraction's denominator, at most.
const FRAC_MAX := 12
## The plot is −8 to 8 both ways; features stay this far inside it.
const PLOT := 6


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var paper: int = 2 if int(need.get("paper", 1)) == 2 else 1
	var form: String = need.get("form", "any")
	for i in TRIES:
		var f := form
		if f == "any":
			f = "lq" if rng.chance(0.5) else "ql"
		var s := _lq(rng, need, paper) if f == "lq" else _ql(rng, need, paper)
		if s.is_empty():
			continue
		s.paper = paper
		return s
	push_error("RationalQuadraticSituation: no clean situation for %s" % need)
	return {}


# ── A linear over a quadratic ────────────────────────────────

static func _lq(rng: Seeded, need: Dictionary, paper: int) -> Dictionary:
	var den: String = need.get("den", "any")
	if den == "any":
		den = "count" if need.get("angle", "") == "discriminant-count" else "two"
	if den == "count":
		den = ["two", "one", "none"][rng.weighted([4, 3, 3])]
	var graph: bool = need.get("graph", false)
	var s := {"form": "lq", "zs": [], "fake": []}
	match den:
		"two":
			var r1 := ExtensionViews.nonzero(rng, -5, 5)
			var r2 := ExtensionViews.nonzero(rng, -5, 5)
			if r1 == r2 or r1 == -r2:
				return {}
			s.zs = [mini(r1, r2), maxi(r1, r2)]
			s.p = -(r1 + r2)
			s.q = r1 * r2
		"one":
			var r := ExtensionViews.nonzero(rng, -5, 5)
			s.zs = [r]
			s.p = -2 * r
			s.q = r * r
		_:
			var h := rng.int_in(-3, 3)
			var sq := rng.int_in(1, 4)
			s.p = 2 * h
			s.q = h * h + sq * sq
			s.fake = [-h - sq, -h + sq]
	s.nz = s.zs.size()
	s.a = ExtensionViews.nonzero(rng, -3, 3)
	s.b = ExtensionViews.nonzero(rng, -8, 8)
	if Q.gcd(absi(s.a), absi(s.b)) != 1:
		return {}
	s.z = Q.new(-s.b, s.a)
	s.yi = Q.new(s.b, s.q)
	# No common factor: the numerator is not zero where the denominator is.
	for r in s.zs:
		if s.z.eq(r):
			return {}
	if s.yi.d > FRAC_MAX:
		return {}
	if graph:
		if s.nz != 2 or s.zs[1] - s.zs[0] < 2 or absf(s.z.to_float()) > PLOT or absf(s.yi.to_float()) > PLOT:
			return {}
		# The zero is clear of each asymptote and of its mirror image, so the cards with the
		# asymptotes' or the zero's sign changed have no common factor either.
		for r in s.zs:
			if absf(s.z.to_float() - r) < 1.0 or s.z.eq(-r):
				return {}
		if not visible(s, [-8.0] + s.zs.map(func(r): return float(r)) + [8.0]):
			return {}
	if need.get("range", false) and not _lq_range(s, paper):
		return {}
	return s


## The range of an lq with no vertical asymptote: y(x² + px + q) = ax + b has a real x
## exactly when (p² − 4q)y² + (4b − 2ap)y + a² ≥ 0, so y lies between ((ap − 2b) ± 2√E)/(p² − 4q),
## E = b² − abp + a²q. f′(x) = 0 where ax² + 2bx + (bp − aq) = 0, x = (−b ± √E)/a.
static func _lq_range(s: Dictionary, paper: int) -> bool:
	if s.nz != 0:
		return false
	var a: int = s.a
	var b: int = s.b
	var p: int = s.p
	var q: int = s.q
	var E: int = b * b - a * b * p + a * a * q
	var dd: int = p * p - 4 * q
	s.E = E
	var root := isqrt(E)
	var exact := root * root == E
	if (paper == 1) != exact:
		return false
	var xs: Array = []
	if exact:
		var y1 := Q.new(a * p - 2 * b + 2 * root, dd)
		var y2 := Q.new(a * p - 2 * b - 2 * root, dd)
		var lo: Q = y1 if y1.lt(y2) else y2
		var hi: Q = y2 if y1.lt(y2) else y1
		for v in [lo, hi]:
			if v.d > FRAC_MAX or absi(v.n) > 60:
				return false
		s.ylo = lo
		s.yhi = hi
		xs = [Q.new(-b - root, a), Q.new(-b + root, a)]
		for x in xs:
			if x.d > FRAC_MAX:
				return false
	else:
		var rt := sqrt(float(E))
		var y1 := (a * p - 2 * b + 2.0 * rt) / dd
		var y2 := (a * p - 2 * b - 2.0 * rt) / dd
		s.ylo = minf(y1, y2)
		s.yhi = maxf(y1, y2)
		xs = [(-b - rt) / a, (-b + rt) / a]
		for v in [s.ylo, s.yhi] + xs:
			if not GdcKit.fair(v):
				return false
	# Which turning point is the least value: the one where f is smaller.
	var f0 := lq_y(s, _f(xs[0]))
	var f1 := lq_y(s, _f(xs[1]))
	s.xlo = xs[0] if f0 < f1 else xs[1]
	s.xhi = xs[1] if f0 < f1 else xs[0]
	return true


static func _f(v: Variant) -> float:
	return v.to_float() if v is Q else float(v)


static func isqrt(n: int) -> int:
	if n < 0:
		return -1
	var r := int(sqrt(float(n)))
	while r * r > n:
		r -= 1
	while (r + 1) * (r + 1) <= n:
		r += 1
	return r


static func lq_y(s: Dictionary, x: float) -> float:
	var den: float = x * x + s.p * x + s.q
	return NAN if den == 0.0 else (s.a * x + s.b) / den


# ── A quadratic over a linear ────────────────────────────────

static func _ql(rng: Seeded, need: Dictionary, paper: int) -> Dictionary:
	var graph: bool = need.get("graph", false)
	var m: int = [1, 1, 1, 2, 2, -1, -1, -2, 3][rng.int_in(0, 8)]
	if graph and absi(m) > 2:
		return {}
	var e := ExtensionViews.nonzero(rng, -5, 5)
	var s := {"form": "ql", "m": m, "e": e, "roots": []}
	if need.get("roots", false):
		var s1 := rng.int_in(-6, 6)
		var s2 := rng.int_in(-6, 6)
		if s1 == s2 or s1 == -s2 or s1 == -e or s2 == -e or s1 == 0 or s2 == 0:
			return {}
		s.roots = [mini(s1, s2), maxi(s1, s2)]
		s.b = -m * (s1 + s2)
		s.c = m * s1 * s2
		s.k = s.b - m * e
		s.R = s.c - s.k * e
	else:
		s.k = rng.int_in(-6, 6)
		s.R = ExtensionViews.nonzero(rng, -9, 9)
		s.b = m * e + s.k
		s.c = s.k * e + s.R
	# k, b, b + me and c all nonzero, so the oblique slips are four different lines and
	# the y-intercept is not the origin.
	if s.k == 0 or s.b == 0 or s.b + m * e == 0 or s.c == 0 or s.R == 0:
		return {}
	s.yi = Q.new(s.c, e)
	if s.yi.eq(m):
		return {}
	if absi(s.b) > 20 or absi(s.c) > 40:
		return {}
	if graph:
		if absi(s.k) > 4 or absi(s.R) > 5 or absf(s.yi.to_float()) > PLOT or absi(e) > 4:
			return {}
		for r in s.roots:
			if absi(r) > PLOT or absi(r + e) < 1:
				return {}
	if graph and not visible(s, [-8.0, float(-e), 8.0]):
		return {}
	if need.get("turns", false) and not _ql_turns(s, paper):
		return {}
	return s


## f = mx + k + R/(x + e): with mR > 0, f′ = m − R/(x + e)² is zero at x = −e ± √(R/m), where
## f = k − me ± 2√(mR). The lower value is a local maximum and the higher a local minimum,
## on the two branches.
static func _ql_turns(s: Dictionary, paper: int) -> bool:
	var m: int = s.m
	var R: int = s.R
	var e: int = s.e
	if m * R <= 0:
		return false
	var root := isqrt(m * R)
	var exact := root * root == m * R
	if (paper == 1) != exact:
		return false
	var mid: int = s.k - m * e
	if exact:
		s.L = Q.new(mid - 2 * root)
		s.U = Q.new(mid + 2 * root)
		# t = x + e = ±√(R/m) = ±root/|m|; the value there is mid + 2mt.
		var t := Q.new(root, absi(m))
		var tl: Q = t if m < 0 else t.neg()
		s.xL = tl.sub(e)
		s.xU = tl.neg().sub(e)
		for v in [s.xL, s.xU]:
			if v.d > FRAC_MAX:
				return false
		if absi(mid) + 2 * root > 60:
			return false
	else:
		var w := 2.0 * sqrt(float(m * R))
		s.L = mid - w
		s.U = mid + w
		var t := sqrt(float(R) / m)
		s.xL = (t if m < 0 else -t) - e
		s.xU = (-t if m < 0 else t) - e
		for v in [s.L, s.U, s.xL, s.xU]:
			if not GdcKit.fair(v):
				return false
	return true


## Every piece of the curve between the breaks (its vertical asymptotes and the plot's
## edges) comes well inside the plot somewhere, so a graph shows every branch.
static func visible(s: Dictionary, breaks: Array) -> bool:
	for i in breaks.size() - 1:
		var lo: float = breaks[i]
		var hi: float = breaks[i + 1]
		var seen := false
		for j in range(1, 80):
			var x := lo + (hi - lo) * j / 80.0
			var y := lq_y(s, x) if s.form == "lq" else ql_y(s, x)
			if absf(y) <= PLOT:
				seen = true
				break
		if not seen:
			return false
	return true


static func ql_y(s: Dictionary, x: float) -> float:
	var den: float = x + s.e
	return NAN if den == 0.0 else (s.m * x * x + s.b * x + s.c) / den


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
