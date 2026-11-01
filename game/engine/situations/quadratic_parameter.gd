class_name QuadraticParameterSituation
extends RefCounted
## The `quadratic-parameter` situation (curriculum/question-types.json), which extends
## `quadratic`: a quadratic whose coefficients hold a constant k, given directly or
## after equating a line and a curve, so its discriminant is an expression in k
## (FAL-414).
##
## Views that ask about a plain quadratic with numbers (the nature of its roots, the
## sign of Δ from a graph) call QuadraticSituation.generate() and use its parabola as
## it is, adding a repeated-root mode. Views with a parameter pick a family:
##   c      ax² + bx + k              Δ = b² − 4ak, one critical k = b²/(4a)
##   b      ax² + kx + c, ac = s²     Δ = k² − 4ac, critical k = ±2s
##   grad   y = x² + px + r and the line y = kx + n, with r − n = s²: critical k = p ± 2s
##   icpt   y = x² + px + r and the line y = mx + k, with p − m even: one critical k
##   both   x² + kx + (αk + β)        Δ = k² − 4αk − 4β = (k − 2u)(k − 2v)
##
## Every family is written as the quadratic in x it gives (after moving the line
## across): a0·x² + (b0 + b1·k)x + (c0 + c1·k) = 0, so Δ(k) = dA·k² + dB·k + dC.
##
## generate() returns, besides the family's own numbers:
##   family, a0, b0, b1, c0, c1, dA, dB, dC (Q)
##   crit      the critical values of k, smallest first (whole numbers)
##   kv        a value of k to put in (when need.kv)
##   cond      "two", "none" or "real" (when need.cond)
##
## need (all optional):
##   base       use the plain parabola: a Dictionary passed to QuadraticSituation, with
##              mode "any4" for rational, surd, no real roots or a repeated root
##   families   the families the view can use
##   kv         pick a value of k
##   cond       pick a condition
##   a_pos      the quadratic in x opens upwards (a0 > 0)
##   paper      2 for Paper 2 (FAL-419): a family whose Δ is a quadratic in k (b, grad,
##              both) with irrational critical values, which need a calculator and are
##              given to 3 s.f. crit then holds them to six decimal places (few
##              enough that products of Qs stay inside 64 bits), and crit_f as
##              floats. When the view's families have none of these, the situation
##              stays Paper 1.
##
## Every situation carries `paper` (1 or 2).

const CRIT_MAX := 30
const COEF_MAX := 24
const TRIES := 4000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	if need.has("base"):
		var bs := _base(rng, need.base)
		if not bs.is_empty():
			bs.paper = 1
		return bs
	var fams: Array = need.get("families", ["c", "b", "grad", "icpt", "both"])
	if int(need.get("paper", 1)) == 2:
		var f2: Array = fams.filter(func(f): return f in P2_FAMILIES)
		if not f2.is_empty():
			return _generate_p2(rng, f2, need)
	for i in TRIES:
		var fam: String = fams[rng.int_in(0, fams.size() - 1)]
		var s := _draw(rng, fam, need)
		if s.is_empty():
			continue
		_derive(s)
		if not _clean(s, need):
			continue
		if need.get("kv", false):
			_pick_kv(rng, s)
		if need.get("cond", false):
			s.cond = ["two", "none", "real"][rng.int_in(0, 2)]
		s.paper = 1
		return s
	push_error("QuadraticParameterSituation: no clean situation for %s" % need)
	return {}


# ── Paper 2 ──────────────────────────────────────────────────

## The families whose Δ is a quadratic in k, so its zeros can be irrational.
const P2_FAMILIES := ["b", "grad", "both"]
const SCALE := 1000000
## Whole numbers that aren't squares, for √ under a Paper 2 critical k.
const NON_SQUARES := [2, 3, 5, 6, 7, 8, 10, 11, 12, 13]


static func _generate_p2(rng: Seeded, fams: Array, need: Dictionary) -> Dictionary:
	for i in TRIES:
		var fam: String = fams[rng.int_in(0, fams.size() - 1)]
		var s := _draw_p2(rng, fam, need)
		if s.is_empty():
			continue
		_derive_p2(s)
		if not _clean_p2(s):
			continue
		if need.get("cond", false):
			s.cond = ["two", "none", "real"][rng.int_in(0, 2)]
		s.paper = 2
		return s
	push_error("QuadraticParameterSituation: no clean Paper 2 situation for %s" % need)
	return {}


static func _draw_p2(rng: Seeded, fam: String, need: Dictionary) -> Dictionary:
	var s := {"family": fam, "a0": Q.new(1), "b0": Q.new(0), "b1": Q.new(0), "c0": Q.new(0), "c1": Q.new(0),
		"p": null, "r": null, "m": null, "n": null, "kv": null, "cond": ""}
	match fam:
		"b":
			# ax² + kx + c with ac not a square: k = ±2√(ac).
			var a: int = [1, 1, 2, 3, -1, -2][rng.int_in(0, 5)]
			if need.get("a_pos", false) and a < 0:
				return {}
			var c := rng.int_in(1, 12) * (1 if a > 0 else -1)
			if not ((a * c) in NON_SQUARES):
				return {}
			s.a0 = Q.new(a)
			s.c0 = Q.new(c)
			s.b1 = Q.new(1)
		"grad":
			# r − n not a square: k = p ± 2√(r − n).
			var p := rng.int_in(-6, 6)
			var sq: int = NON_SQUARES[rng.int_in(0, NON_SQUARES.size() - 1)]
			var n := rng.int_in(-6, 6)
			s.p = Q.new(p)
			s.n = Q.new(n)
			s.r = Q.new(n + sq)
			s.b0 = Q.new(p)
			s.b1 = Q.new(-1)
			s.c0 = Q.new(sq)
		"both":
			# x² + kx + (αk + β): Δ = k² − 4αk − 4β, zero at 2α ± 2√(α² + β).
			var al := rng.int_in(-4, 4)
			var be := rng.int_in(-12, 12)
			if al == 0 or not ((al * al + be) in NON_SQUARES):
				return {}
			s.b1 = Q.new(1)
			s.c1 = Q.new(al)
			s.c0 = Q.new(be)
	return s


static func _derive_p2(s: Dictionary) -> void:
	var a0: Q = s.a0
	s.dA = s.b1.sq()
	s.dB = s.b0.mul(s.b1).mul(2).sub(a0.mul(s.c1).mul(4))
	s.dC = s.b0.sq().sub(a0.mul(s.c0).mul(4))
	var disc: float = s.dB.sq().sub(s.dA.mul(s.dC).mul(4)).to_float()
	s.crit = []
	if disc <= 0.0:
		return
	var A2: float = 2.0 * s.dA.to_float()
	var k1: float = (-s.dB.to_float() - sqrt(disc)) / A2
	var k2: float = (-s.dB.to_float() + sqrt(disc)) / A2
	s.crit = [approx(minf(k1, k2)), approx(maxf(k1, k2))]
	s.crit_f = [minf(k1, k2), maxf(k1, k2)]


## A float as a Q to six decimal places; −x gives exactly the negative.
static func approx(x: float) -> Q:
	return Q.new(roundi(x * SCALE), SCALE)


## Two irrational critical values, each clear of a 3 s.f. rounding edge and not tiny,
## inside the Paper 1 limits for the coefficients.
static func _clean_p2(s: Dictionary) -> bool:
	if s.crit.size() != 2:
		return false
	for k in s.crit_f:
		if absf(k) < 0.2 or absf(k) > CRIT_MAX or not Answer.rounds_clearly(k, 0.05):
			return false
	for key in ["b0", "c0", "dC"]:
		if absi(s[key].n) > (COEF_MAX if key != "dC" else 150):
			return false
	if s.r != null and absi(s.r.n) > 20:
		return false
	return true


static func _base(rng: Seeded, base: Dictionary) -> Dictionary:
	var b := base.duplicate()
	var repeated := false
	if b.get("mode", "") == "any4":
		var m: String = ["rational", "rational", "surd", "none", "repeated"][rng.int_in(0, 4)]
		repeated = m == "repeated"
		b.mode = "none" if repeated else m
	for i in 200:
		var s := QuadraticSituation.generate(rng, b)
		if s.is_empty():
			return {}
		if repeated:
			s.mode = "repeated"
			s.k = Q.new(0)
			s.b = s.a.mul(s.h).mul(-2)
			s.c = s.a.mul(s.h.sq())
			s.disc = Q.new(0)
			if not s.h.is_int() or absi(s.c.n) > (QuadraticSituation.GRAPH_Y_MAX if b.get("graph", false) else QuadraticSituation.C_MAX) * s.c.d:
				continue
			s.p = s.h
			s.q = s.h
		s.family = "base"
		return s
	return {}


static func _draw(rng: Seeded, fam: String, need: Dictionary) -> Dictionary:
	var s := {"family": fam, "a0": Q.new(1), "b0": Q.new(0), "b1": Q.new(0), "c0": Q.new(0), "c1": Q.new(0),
		"p": null, "r": null, "m": null, "n": null, "kv": null, "cond": ""}
	match fam:
		"c":
			var a: int = [1, 1, 2, -1, -2][rng.int_in(0, 4)]
			if need.get("a_pos", false) and a < 0:
				return {}
			var b := 2 * rng.int_in(-6, 6)
			if b == 0 or (b * b) % (4 * absi(a)) != 0:
				return {}
			s.a0 = Q.new(a)
			s.b0 = Q.new(b)
			s.c1 = Q.new(1)
		"b":
			var opts := [[1, 1], [1, 4], [1, 9], [1, 16], [1, 25], [1, 36], [2, 2], [2, 8], [4, 1], [-1, -1], [-1, -4], [-1, -9], [-1, -16]]
			var ac: Array = opts[rng.int_in(0, opts.size() - 1)]
			if need.get("a_pos", false) and ac[0] < 0:
				return {}
			s.a0 = Q.new(ac[0])
			s.c0 = Q.new(ac[1])
			s.b1 = Q.new(1)
		"grad":
			var p := rng.int_in(-6, 6)
			var sq := rng.int_in(1, 4)
			var n := rng.int_in(-6, 6)
			s.p = Q.new(p)
			s.n = Q.new(n)
			s.r = Q.new(n + sq * sq)
			s.b0 = Q.new(p)
			s.b1 = Q.new(-1)
			s.c0 = s.r.sub(n)
		"icpt":
			var p := rng.int_in(-6, 6)
			var m := rng.int_in(-4, 4)
			if m == 0 or p == m or (p - m) % 2 != 0:
				return {}
			var r := rng.int_in(-8, 8)
			s.p = Q.new(p)
			s.m = Q.new(m)
			s.r = Q.new(r)
			s.b0 = Q.new(p - m)
			s.c0 = Q.new(r)
			s.c1 = Q.new(-1)
		"both":
			var u := rng.int_in(-5, 5)
			var v := rng.int_in(-5, 5)
			if u == v or (u + v) % 2 != 0 or u + v == 0:
				return {}
			s.b1 = Q.new(1)
			s.c1 = Q.new((u + v) / 2)
			s.c0 = Q.new(-u * v)
	return s


static func _derive(s: Dictionary) -> void:
	var a0: Q = s.a0
	s.dA = s.b1.sq()
	s.dB = s.b0.mul(s.b1).mul(2).sub(a0.mul(s.c1).mul(4))
	s.dC = s.b0.sq().sub(a0.mul(s.c0).mul(4))
	s.crit = roots_of(s.dA, s.dB, s.dC)


## The real roots of A·k² + B·k + C (A may be 0), smallest first, when they are
## rational; [] otherwise.
static func roots_of(A: Q, B: Q, C: Q) -> Array:
	if A.is_zero():
		return [] if B.is_zero() else [C.neg().div(B)]
	var disc := B.sq().sub(A.mul(C).mul(4))
	if disc.sign() < 0 or not disc.is_int():
		return []
	var r := int(round(sqrt(float(disc.n))))
	if r * r != disc.n:
		return []
	var k1 := B.neg().sub(r).div(A.mul(2))
	var k2 := B.neg().add(r).div(A.mul(2))
	if k1.eq(k2):
		return [k1]
	return [k1, k2] if k1.lt(k2) else [k2, k1]


static func _clean(s: Dictionary, need: Dictionary) -> bool:
	if s.crit.is_empty() or (s.dA.sign() > 0 and s.crit.size() != 2):
		return false
	for k in s.crit:
		if not k.is_int() or absi(k.n) > CRIT_MAX:
			return false
	for key in ["b0", "c0", "dC"]:
		if absi(s[key].n) > (COEF_MAX if key != "dC" else 150):
			return false
	if s.r != null and absi(s.r.n) > 20:
		return false
	if need.get("a_pos", false) and s.a0.sign() < 0:
		return false
	# A tangent's point of contact on whole numbers (icpt and c have one critical k).
	if s.crit.size() == 1:
		var x0 := contact_x(s, s.crit[0])
		if not x0.is_int():
			return false
	return true


static func _pick_kv(rng: Seeded, s: Dictionary) -> void:
	for i in 40:
		var kv := rng.int_in(-9, 9)
		if rng.chance(0.2):
			kv = s.crit[rng.int_in(0, s.crit.size() - 1)].n
		if absi(delta_at(s, Q.new(kv)).n) <= 200:
			s.kv = Q.new(kv)
			return
	s.kv = Q.new(s.crit[0].n + 1)


## The quadratic in x at a value of k: [a, b, c].
static func at(s: Dictionary, k: Q) -> Array:
	return [s.a0, s.b0.add(s.b1.mul(k)), s.c0.add(s.c1.mul(k))]


static func delta_at(s: Dictionary, k: Q) -> Q:
	return s.dA.mul(k.sq()).add(s.dB.mul(k)).add(s.dC)


## Where a repeated root sits: x = −b/(2a) at that k.
static func contact_x(s: Dictionary, k: Q) -> Q:
	var abc := at(s, k)
	return abc[1].neg().div(abc[0].mul(2))


## The point where a tangent touches: on the line for the line families, on the x-axis
## otherwise.
static func contact(s: Dictionary, k: Q) -> Array:
	var x0 := contact_x(s, k)
	match s.family:
		"icpt":
			return [x0, s.m.mul(x0).add(k)]
		"grad":
			return [x0, k.mul(x0).add(s.n)]
	return [x0, Q.new(0)]


static func export(s: Dictionary) -> Dictionary:
	var out := {}
	for key in s:
		var v = s[key]
		if v is Q:
			out[key] = v.key()
		elif v is Array:
			out[key] = v.map(func(e): return e.key() if e is Q else e)
		else:
			out[key] = v
	return out
