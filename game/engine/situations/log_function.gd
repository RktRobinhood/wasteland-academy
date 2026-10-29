class_name LogFunctionSituation
extends RefCounted
## The `log-function` situation (curriculum/question-types.json), which extends
## `exp-log-pair`: the log form with a linear inside, y = A·log_b(mx + n) + c, so the
## asymptote and the domain come from mx + n = 0 (FAL-418). It calls
## ExpLogPairSituation.generate() for the base and the shift c (and, for a reflection,
## the exponential's shift h), then adds the inside and the stretch. Paper 1: exact.
##
## generate() returns the log mode's b, h, c, plus:
##   m, n    the inside mx + n (m from ±1, ±2, ±3); x0 = −n/m, the asymptote (a Q: whole,
##           or a half when |m| = 2)
##   A       the stretch in front (1, 2, 3 or −1)
##   e       (need.intercept) c = −A·e, so the x-intercept has mx + n = bᵉ: xi
##   k, rel  (need.ineq) log_b(mx + n) rel k
##   ratio   (need.ratio) ln(x − h)/x^pw with h ≥ 0, so x^pw > 0 on the domain: pw, rel
##
## need (all optional): m1 (m = 1), a1 (A = 1), intercept, ineq, ratio
##
## The clean limits are the checker's too (tools/check_answers.py, LF_*).

const TRIES := 2000
const MS := [1, 2, 3, -1, -2, -3]
const AS := [1, 1, 2, 3, -1]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var s := ExpLogPairSituation.generate(rng, {"mode": "log"})
	if s.is_empty():
		return {}
	for i in TRIES:
		var t := _draw(rng, s.duplicate(), need)
		if not t.is_empty():
			t.mode = "logfn"
			return t
	push_error("LogFunctionSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, s: Dictionary, need: Dictionary) -> Dictionary:
	if need.get("ratio", false):
		s.b = "e"
		s.h = rng.int_in(0, 4)
		s.pw = rng.int_in(1, 3)
		s.rel = [">", "<"][rng.int_in(0, 1)]
		return s
	s.m = 1 if need.get("m1", false) else MS[rng.int_in(0, MS.size() - 1)]
	s.A = 1 if need.get("a1", false) else AS[rng.int_in(0, AS.size() - 1)]
	var x0 := Q.new(rng.int_in(-8, 8), 2) if absi(s.m) == 2 else Q.new(rng.int_in(-5, 5))
	if absi(s.m) != 2 and x0.is_zero() and rng.chance(0.5):
		return {}
	s.x0 = x0
	s.n = x0.mul(Q.new(-s.m))
	if not s.n.is_int():
		return {}
	if need.get("intercept", false):
		s.e = rng.int_in(-1, 2)
		s.c = -s.A * s.e
		var v := Q.new(1)
		for j in absi(s.e):
			v = v.mul(Q.new(s.b)) if s.e > 0 else v.div(Q.new(s.b))
		s.xi = v.sub(s.n).div(Q.new(s.m))
		if absi(s.c) > 6:
			return {}
	if need.get("ineq", false):
		s.k = rng.int_in(-1, 2) if s.b <= 5 else rng.int_in(-1, 1)
		s.rel = ["<", ">", "≤", "≥"][rng.int_in(0, 3)]
	return s


## b^k as a Q (k may be negative).
static func bpow(b: int, k: int) -> Q:
	var v := Q.new(1)
	for j in absi(k):
		v = v.mul(Q.new(b)) if k > 0 else v.div(Q.new(b))
	return v


## y at x, or NAN outside the domain.
static func at(s: Dictionary, x: float) -> float:
	var inside: float = s.m * x + s.n.to_float()
	if inside <= 0.0:
		return NAN
	return s.A * log(inside) / log(float(s.b)) + s.c


static func export(s: Dictionary) -> Dictionary:
	return ExpLogPairSituation.export(s)
