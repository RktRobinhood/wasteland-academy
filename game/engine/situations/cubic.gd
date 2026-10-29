class_name CubicSituation
extends RefCounted
## The `cubic` situation (curriculum/question-types.json): one cubic
## f(x) = ax³ + bx² + cx + d built from f′(x) = 3a(x − p)(x − q), so the stationary
## points fall on whole numbers, with every linked quantity at a chosen point x₀.
##
## generate() returns a Dictionary of Q values:
##   a, b, c, d      the coefficients
##   p, q            the stationary x-values, p < q
##   fp, fq          f(p) and f(q)
##   xi, yi          the point of inflexion ((p + q)/2, f((p + q)/2))
##   x0, y0, m0      the chosen point (not 0, which makes the working trivial), f(x0)
##                   and f′(x0) (when need.x0)
##   r1, r2, g       two x-values with the same gradient g = f′(r1) = f′(r2), r1 < r2
##                   (when need.gradient)
##   hidden          "b" or "c": the coefficient written as k (when need.hide)
##
## need (all optional):
##   even       p + q even, so the point of inflexion is on whole numbers
##   x0         pick x0 (not 0, p or q, so f′(x0) ≠ 0)
##   normal     with x0: a Paper 1 normal, its gradient −1/f′(x0) and c with
##              denominators of NORMAL_DEN_MAX or less
##   gradient   pick r, s and g
##   hide       pick the hidden coefficient, b or c
##   paper      1 or 2 (from QuestionEngine). Absent or 1: the Paper 1 cubic above,
##              drawn exactly as before. 2: a Paper 2 cubic (see below). The
##              situation's own `paper` says which it is.
##
## Paper 2 (FAL-419): a calculator cubic, IB style. Its coefficients are decimals to
## one place (at least one of a, b, c not whole), and f′ has two irrational roots, so
## the stationary points are found on a GDC and given to 3 s.f. p, q, fp and fq are
## then those values to P2_SCALE (Q can't hold a surd); xi and yi stay exact. With x0,
## x₀ is a decimal to one place (not whole), so f(x₀), f′(x₀), the tangent and the
## normal are messy decimals given to 3 s.f. With gradient, g stays a whole number and
## f′(x) = g has two irrational roots. Every 3 s.f. answer is at least P2_V_MIN and clear of a rounding
## edge (P2_EDGE). hide and even are Paper 1 only (their views are).
##
## The clean limits below are the numbers behind the catalogue's `clean` text. The
## SymPy checker (tools/check_answers.py) holds its own copy and fails on any breach.

const A_CHOICES := [1, -1, 2, -2]
const PQ_MAX := 4        ## |p|, |q| ≤ 4
const B_MAX := 30
const C_MAX := 30
const D_MAX := 9
const Y_MAX := 60        ## |f| at the stationary points, the inflexion and x0
const X0_MAX := 3
const M0_MAX := 40       ## 0 < |f′(x0)| ≤ 40
## f′ is 3a(x − p)(x − q), a multiple of 3, so the normal's gradient −1/f′(x0) has
## denominator 3 or 6, and c = f(x0) + x0/f′(x0) a denominator dividing it.
const NORMAL_DEN_MAX := 6
const R_MAX := 5         ## the x-values with a given gradient
const G_MAX := 60
const TRIES := 4000

## Paper 2 limits. a is one of P2_A_TENTHS / 10; b, c and d are tenths.
const P2_A_TENTHS := [2, -2, 4, -4, 5, -5, 10, -10, 15, -15, 20, -20]
const P2_B_MAX := 40     ## |b| ≤ 4.0
const P2_C_MAX := 90     ## |c| ≤ 9.0
const P2_D_MAX := 90     ## |d| ≤ 9.0
const P2_X_MAX := 5.0    ## |x| of the stationary points and the x-values with gradient g
const P2_X_MIN := 0.1    ## ... and at least this far from 0
const P2_X_GAP := 0.5    ## the two x-values at least this far apart
const P2_X0_MAX := 30    ## x₀ in tenths: |x₀| ≤ 3.0, not whole
const P2_G_MAX := 20     ## the whole-number gradient g for f′(x) = g
## How far a 3 s.f. value keeps from a rounding edge, in units of its 3rd figure (the
## SymPy checker fails on less than 0.02).
const P2_EDGE := 0.05
const P2_SCALE := 100000000
## Every number of a Paper 2 answer is at least this big (0.00221 to 3 s.f. is fussy).
const P2_V_MIN := 0.1


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	if int(need.get("paper", 1)) == 2:
		return _generate_p2(rng, need)
	for i in TRIES:
		var s := _draw(rng, need)
		if s.is_empty():
			continue
		if need.get("x0", false) and not _pick_x0(rng, s, need):
			continue
		if need.get("gradient", false) and not _pick_gradient(rng, s):
			continue
		s.paper = 1
		return s
	push_error("CubicSituation: no clean situation for %s" % need)
	return {}


static func _generate_p2(rng: Seeded, need: Dictionary) -> Dictionary:
	# The stream's first draw leans low (FAL-460), so it is spent first.
	rng.int_in(0, 1)
	for i in TRIES:
		var s := _draw_p2(rng)
		if s.is_empty():
			continue
		if need.get("x0", false) and not _pick_x0_p2(rng, s, need):
			continue
		if need.get("gradient", false) and not _pick_gradient_p2(rng, s):
			continue
		return s
	push_error("CubicSituation: no Paper 2 situation for %s" % need)
	return {}


static func f(s: Dictionary, x: Variant) -> Q:
	var xq := Q.of(x)
	return s.a.mul(xq).add(s.b).mul(xq).add(s.c).mul(xq).add(s.d)


static func f1(s: Dictionary, x: Variant) -> Q:
	var xq := Q.of(x)
	return s.a.mul(3).mul(xq).add(s.b.mul(2)).mul(xq).add(s.c)


static func f2(s: Dictionary, x: Variant) -> Q:
	return s.a.mul(6).mul(Q.of(x)).add(s.b.mul(2))


static func _draw(rng: Seeded, need: Dictionary) -> Dictionary:
	var a: int = A_CHOICES[rng.int_in(0, A_CHOICES.size() - 1)]
	var p := rng.int_in(-PQ_MAX, PQ_MAX)
	var q := rng.int_in(-PQ_MAX, PQ_MAX)
	if p == q:
		return {}
	if p > q:
		var t := p
		p = q
		q = t
	# b = −3a(p + q)/2 is a whole number only when a(p + q) is even.
	if (a * (p + q)) % 2 != 0:
		return {}
	if need.get("even", false) and (p + q) % 2 != 0:
		return {}
	var s := {"a": Q.new(a), "b": Q.new(-3 * a * (p + q), 2), "c": Q.new(3 * a * p * q),
		"d": Q.new(rng.int_in(-D_MAX, D_MAX)), "p": Q.new(p), "q": Q.new(q),
		"x0": null, "y0": null, "m0": null, "r1": null, "r2": null, "g": null, "hidden": null}
	if absi(s.b.n) > B_MAX or absi(s.c.n) > C_MAX:
		return {}
	s.fp = f(s, s.p)
	s.fq = f(s, s.q)
	s.xi = Q.new(p + q, 2)
	s.yi = f(s, s.xi)
	if absi(s.fp.n) > Y_MAX or absi(s.fq.n) > Y_MAX:
		return {}
	if need.get("even", false) and absi(s.yi.n) > Y_MAX:
		return {}
	return s


static func _pick_x0(rng: Seeded, s: Dictionary, need: Dictionary) -> bool:
	var options := []
	for x in range(-X0_MAX, X0_MAX + 1):
		if x == 0 or x == s.p.n or x == s.q.n:
			continue
		var y := f(s, x)
		var m := f1(s, x)
		if need.get("normal", false) and absi(m.n) > NORMAL_DEN_MAX:
			continue
		if absi(y.n) <= Y_MAX and absi(m.n) <= M0_MAX:
			options.append(x)
	if options.is_empty():
		return false
	var x0: int = options[rng.int_in(0, options.size() - 1)]
	s.x0 = Q.new(x0)
	s.y0 = f(s, s.x0)
	s.m0 = f1(s, s.x0)
	if need.get("hide", false):
		var hide: String = ["b", "c"][rng.int_in(0, 1)]
		if s[hide].is_zero():
			return false
		s.hidden = hide
	return true


## Two whole x-values r1 < r2 with the same gradient: r1 + r2 = p + q, so
## f′(x) − g = 3a(x − r1)(x − r2).
static func _pick_gradient(rng: Seeded, s: Dictionary) -> bool:
	var options := []
	var sum: int = s.p.n + s.q.n
	for r in range(-R_MAX, R_MAX + 1):
		var other := sum - r
		if other <= r or absi(other) > R_MAX:
			continue
		var g := f1(s, r)
		if not g.is_zero() and absi(g.n) <= G_MAX:
			options.append(r)
	if options.is_empty():
		return false
	var r: int = options[rng.int_in(0, options.size() - 1)]
	s.r1 = Q.new(r)
	s.r2 = Q.new(sum - r)
	s.g = f1(s, s.r1)
	return true


# ── Paper 2 ──────────────────────────────────────────────────

## A value a calculator gives, as a Q to P2_SCALE.
static func qf(x: float) -> Q:
	return Q.new(roundi(x * P2_SCALE), P2_SCALE)


## Whether x is a value whose 3 s.f. are safe to ask for: not 0 and clear of an edge.
static func clear3(x: float) -> bool:
	return Answer.rounds_clearly(x, P2_EDGE)


## Whether x is fit to be an answer's number: clear3, and not so small that its 3 s.f.
## hang on a fourth decimal place.
static func answer3(x: float) -> bool:
	return absf(x) >= P2_V_MIN and clear3(x)


## The two real roots of Ax² + Bx + C = 0 when they are irrational (Δ > 0 and not a
## square of a fraction), smaller first, else [].
static func irrational_roots(A: Q, B: Q, C: Q) -> Array:
	var disc := B.sq().sub(A.mul(C).mul(4))
	if disc.sign() <= 0:
		return []
	var rn := roundi(sqrt(float(disc.n)))
	var rd := roundi(sqrt(float(disc.d)))
	if rn * rn == disc.n and rd * rd == disc.d:
		return []
	var root := sqrt(disc.to_float())
	var x1 := (-B.to_float() - root) / (2.0 * A.to_float())
	var x2 := (-B.to_float() + root) / (2.0 * A.to_float())
	return [minf(x1, x2), maxf(x1, x2)]


## Whether two x-values are fit to ask for to 3 s.f.: in range, apart and clear.
static func good_pair(xs: Array) -> bool:
	if xs.size() != 2 or xs[1] - xs[0] < P2_X_GAP:
		return false
	for x in xs:
		if absf(x) > P2_X_MAX or absf(x) < P2_X_MIN or not clear3(x):
			return false
	return true


static func f_float(s: Dictionary, x: float) -> float:
	return ((s.a.to_float() * x + s.b.to_float()) * x + s.c.to_float()) * x + s.d.to_float()


static func f1_float(s: Dictionary, x: float) -> float:
	return (3.0 * s.a.to_float() * x + 2.0 * s.b.to_float()) * x + s.c.to_float()


static func _draw_p2(rng: Seeded) -> Dictionary:
	var a10: int = P2_A_TENTHS[rng.int_in(0, P2_A_TENTHS.size() - 1)]
	var b10 := rng.int_in(-P2_B_MAX, P2_B_MAX)
	var c10 := rng.int_in(-P2_C_MAX, P2_C_MAX)
	var d10 := rng.int_in(-P2_D_MAX, P2_D_MAX)
	if b10 == 0 or c10 == 0 or d10 == 0:
		return {}
	if a10 % 10 == 0 and b10 % 10 == 0 and c10 % 10 == 0:
		return {}
	var s := {"a": Q.new(a10, 10), "b": Q.new(b10, 10), "c": Q.new(c10, 10), "d": Q.new(d10, 10), "paper": 2,
		"x0": null, "y0": null, "m0": null, "r1": null, "r2": null, "g": null, "hidden": null}
	var xs := irrational_roots(s.a.mul(3), s.b.mul(2), s.c)
	if not good_pair(xs):
		return {}
	var ys: Array = xs.map(func(x): return f_float(s, x))
	for y in ys:
		if absf(y) > Y_MAX or not answer3(y):
			return {}
	s.p = qf(xs[0])
	s.q = qf(xs[1])
	s.fp = qf(ys[0])
	s.fq = qf(ys[1])
	s.xi = s.b.div(s.a.mul(-3))
	s.yi = f(s, s.xi)
	return s


## x₀ to one decimal place, not whole, with f(x₀) and f′(x₀) messy. With need.normal,
## the normal's numbers are clear of rounding edges too.
static func _pick_x0_p2(rng: Seeded, s: Dictionary, need: Dictionary) -> bool:
	var options := []
	for k in range(-P2_X0_MAX, P2_X0_MAX + 1):
		if k % 10 == 0:
			continue
		var x := Q.new(k, 10)
		var y := f(s, x)
		var m := f1(s, x)
		if m.is_zero() or m.abs_q().eq(1) or absf(m.to_float()) > M0_MAX or absf(y.to_float()) > Y_MAX:
			continue
		var c := y.sub(m.mul(x))
		if c.is_zero() or not answer3(m.to_float()) or not answer3(c.to_float()):
			continue
		if not (Answer.needs_rounding(m) or Answer.needs_rounding(c)):
			continue
		if need.get("normal", false):
			var mn := -1.0 / m.to_float()
			var cn := y.to_float() - mn * x.to_float()
			if not answer3(mn) or not answer3(cn):
				continue
		options.append(k)
	if options.is_empty():
		return false
	var k: int = options[rng.int_in(0, options.size() - 1)]
	s.x0 = Q.new(k, 10)
	s.y0 = f(s, s.x0)
	s.m0 = f1(s, s.x0)
	return true


## A whole-number gradient g where f′(x) = g has two irrational roots, fit for 3 s.f.
static func _pick_gradient_p2(rng: Seeded, s: Dictionary) -> bool:
	var options := []
	for g in range(-P2_G_MAX, P2_G_MAX + 1):
		if g == 0:
			continue
		if good_pair(irrational_roots(s.a.mul(3), s.b.mul(2), s.c.sub(g))):
			options.append(g)
	if options.is_empty():
		return false
	var g: int = options[rng.int_in(0, options.size() - 1)]
	var xs := irrational_roots(s.a.mul(3), s.b.mul(2), s.c.sub(g))
	s.g = Q.new(g)
	s.r1 = qf(xs[0])
	s.r2 = qf(xs[1])
	return true


## The situation as plain strings, for the answer export.
static func export(s: Dictionary) -> Dictionary:
	var out := {}
	for key in s:
		var v = s[key]
		if v is Q:
			out[key] = v.key()
		elif v is Array:
			out[key] = v.map(func(e): return e.key())
		else:
			out[key] = v
	return out
