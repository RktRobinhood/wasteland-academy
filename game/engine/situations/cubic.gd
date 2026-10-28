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


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	for i in TRIES:
		var s := _draw(rng, need)
		if s.is_empty():
			continue
		if need.get("x0", false) and not _pick_x0(rng, s, need):
			continue
		if need.get("gradient", false) and not _pick_gradient(rng, s):
			continue
		return s
	push_error("CubicSituation: no clean situation for %s" % need)
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
