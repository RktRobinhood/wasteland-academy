class_name LogQuadraticSituation
extends RefCounted
## The `log-quadratic` situation (curriculum/question-types.json), which extends
## `quadratic`: a downward parabola g(x) = a(x − p)(x − q) inside a log,
## f(x) = log_k(g(x)) (FAL-418). The roots give the domain and asymptotes, g(x) = 1 the
## zeros, and the vertex the maximum. Paper 1: every answer is exact.
##
## The parabola is picked from its shape, not drawn by QuadraticSituation.generate():
## its height G must be a whole power of the base, which that recipe's draw would hit
## only rarely. It carries the quadratic's own quantities, named as that recipe names
## them, so the quadratic's helpers (QuadraticSituation.f) work on it.
##
## generate() returns the parabola's a, b, c, h, k (= G), p, q and disc, plus:
##   w      the half-width (q − p)/2, so G = −a·w²
##   base   the log's base, with G = base^n (n = 2 or 3, so G/n is not the base)
##   n      the maximum value of f, at x = h
##   d      the zeros are h ± √d: g(x) = 1 gives (x − h)² = (G − 1)/(−a) = d
##   zm, zr d = zm²·zr, so the zeros are h ± zm√zr
##
## need (all optional):
##   straddle  p < 0 < q, so the graph meets the y-axis
##   h_not_0   the axis is not the y-axis (when "through the y-intercept" is a wrong option)
##
## The clean limits are the checker's too (tools/check_answers.py, LQ_*).

const TRIES := 2000
## [a, w, base, n]: G = −a·w² = base^n, with d = (G − 1)/(−a) whole and not a square,
## and G/n not the base (4 = 2² is out: 4/2 is 2).
const SHAPES := [
	[[-1, 1], 3, 3, 2], [[-1, 1], 4, 4, 2], [[-1, 1], 5, 5, 2], [[-1, 1], 6, 6, 2],
	[[-1, 1], 8, 4, 3], [[-1, 1], 8, 8, 2], [[-1, 2], 4, 2, 3],
]
const H_MAX := 5


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	# The stream's first draw leans low, so it is spent first (as the quadratic recipes do).
	rng.int_in(0, 1)
	for i in TRIES:
		var shape: Array = SHAPES[rng.int_in(0, SHAPES.size() - 1)]
		var a := Q.new(shape[0][0], shape[0][1])
		var w: int = shape[1]
		var h := rng.int_in(-H_MAX, H_MAX)
		if need.get("straddle", false) and absi(h) >= w:
			continue
		if need.get("h_not_0", false) and h == 0:
			continue
		var s := _from(a, h, w, shape[2], shape[3])
		if not s.is_empty():
			return s
	push_error("LogQuadraticSituation: no clean situation for %s" % need)
	return {}


static func _from(a: Q, h: int, w: int, base: int, n: int) -> Dictionary:
	var G := a.neg().mul(Q.new(w * w))
	if not G.eq(Q.new(int(pow(base, n)))):
		return {}
	var d := G.sub(Q.new(1)).div(a.neg())
	if not d.is_int() or d.n <= 1:
		return {}
	var zm := 1
	var zr: int = d.n
	for f in range(2, 10):
		while zr % (f * f) == 0:
			zr /= f * f
			zm *= f
	if zr == 1:
		return {}
	var hq := Q.new(h)
	var s := {"a": a, "h": hq, "k": G, "p": Q.new(h - w), "q": Q.new(h + w), "w": w, "base": base, "n": n,
		"d": d, "zm": zm, "zr": zr, "mode": "rational"}
	s.b = a.mul(Q.new(-2 * h))
	s.c = a.mul(Q.new(h * h - w * w))
	s.disc = s.b.mul(s.b).sub(Q.new(4).mul(a).mul(s.c))
	return s


## f(x) = log_base(g(x)), or NAN outside the domain.
static func f_at(s: Dictionary, x: float) -> float:
	var g: float = s.a.to_float() * (x - s.p.to_float()) * (x - s.q.to_float())
	return log(g) / log(float(s.base)) if g > 0.0 else NAN


static func export(s: Dictionary) -> Dictionary:
	return ExpLogPairSituation.export(s)
