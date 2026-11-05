class_name AntiderivativeConditionSituation
extends RefCounted
## The `antiderivative-condition` situation (curriculum/question-types.json): a derivative and a
## condition that fixes the constant (FAL-740). The maths stays exact where the exam's does: a
## Q wherever a polynomial, a trig term at a landmark angle, e⁰ or ln 1 is met. Only two families
## use floats: the Paper 2 e^(ax) with a decimal point, and the Paper 2 rate model.
##
## need.ask is the unknown (see AntiderivativeConditionViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx, name    name is f, g or h
##   style      how the numbers read: "num" (exact) or "dec" (the bank's 1.2 and 7.32)
##   fp         the derivative as powers, [[c, p], ...], where it is a sum of powers
##   fpp        the second derivative as powers
##   x0, y0     the condition; a trig family's x0 is a multiple of π
##   k          the constant the condition gives (Q, or a float on the decimal e^(ax))
##   b          further-value and friends: f(b) is asked
##   m, x1      parameter-from-gradient: the gradient m at x1
##   p, q       a second derivative's f′(x0) and f(x0)
##   c1, c2     a second derivative's two constants
##   fam, K, a  the term K·cos(ax) or K·sin(ax), or the shift `sh` of cos(x + shπ)
##   sv, cv     sin and cos at the landmark angle, Q; cv or sv is null where it has no fraction
##   A, B, e    A x^n or A cos x beside B e^(ex)
##   lin_b      k/(ax + lin_b)
##   rate: A, kq, P0, T, sign      dP/dt = sign·A e^(−kq t), P(0) = P0
##   xs, ys, from  accumulate-graph: the corners of f′ and the index of the start
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 8000
const EDGE := 0.05
const NAMES := ["f", "g", "h"]
const MAX_DEN := 24
## An angle as a multiple of π, with sin and cos at it. The first are on an axis, so a slip that
## swaps sin and cos still gives a fraction.
const TURNS := [[1, 2, 1, 0], [1, 1, 0, -1], [3, 2, -1, 0], [2, 1, 0, 1]]
const SHIFTS := [[1, 3], [1, 4], [1, 6], [-1, 3], [-1, 4], [-1, 6]]
const EXPS := [1, 1, 2, 3, -1, -2]
## Labels on a family of curves stay this far apart.
const FAMILY_GAP := 2


static func nz(rng: Seeded, lo: int, hi: int) -> int:
	return ExtensionViews.nonzero(rng, lo, hi)


# ── Sums of powers ───────────────────────────────────────────

static func power(x: Q, p: int) -> Q:
	var out := Q.new(1)
	for i in absi(p):
		out = out.mul(x)
	return Q.new(1).div(out) if p < 0 else out


## The value of [[c, p], ...] at x.
static func val(terms: Array, x: Variant) -> Q:
	var out := Q.new(0)
	for t in terms:
		out = out.add(Q.of(t[0]).mul(power(Q.of(x), t[1])))
	return out


static func anti(terms: Array) -> Array:
	return terms.map(func(t): return [Q.of(t[0]).div(t[1] + 1), t[1] + 1])


static func diff(terms: Array) -> Array:
	return terms.filter(func(t): return t[1] != 0).map(func(t): return [Q.of(t[0]).mul(t[1]), t[1] - 1])


static func _fits(k: Q) -> bool:
	return not k.is_zero() and k.d <= MAX_DEN


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "poly-function")
	for i in TRIES:
		var s := {"ask": ask, "rep": need.get("rep", "equation"), "paper": int(need.get("paper", 1)), "ctx": rng.int_in(0, 3),
			"name": rng.pick(NAMES), "style": "num"}
		if call_draw(ask, rng, s):
			return s
	return {}


static func call_draw(ask: String, rng: Seeded, s: Dictionary) -> bool:
	match ask:
		"poly-function", "find-constant", "curve-through-point":
			return _poly(rng, s)
		"poly-decimal-point":
			return _decimal(rng, s)
		"further-value":
			return _further(rng, s)
		"negative-power":
			return _negative(rng, s)
		"trig-chain":
			return _trig_chain(rng, s)
		"trig-shift":
			return _trig_shift(rng, s)
		"reciprocal-linear":
			return _reciprocal(rng, s)
		"exp-and-power", "trig-and-exp":
			return _exp_sum(rng, s)
		"exp-linear-decimal":
			return _exp_decimal(rng, s)
		"log-inspection":
			return _log(rng, s)
		"log-given-log":
			return _log_given(rng, s)
		"rate-model":
			return _rate(rng, s)
		"second-derivative", "second-derivative-value":
			return _second(rng, s)
		"second-derivative-exp":
			return _second_exp(rng, s)
		"parameter-from-gradient":
			return _parameter(rng, s)
		"family-pick":
			return _family(rng, s)
		"accumulate-graph":
			return _pieces(rng, s)
	return false


static func _whole_quadratic(rng: Seeded) -> Array:
	var a: int = rng.pick([3, 6, 9, 12, -3, -6, 2, 4])
	var b: int = 2 * nz(rng, -4, 5)
	return [[a, 2], [b, 1], [nz(rng, -9, 9), 0]]


static func _poly(rng: Seeded, s: Dictionary) -> bool:
	s.fp = _whole_quadratic(rng) if rng.chance(0.6) else [[2 * rng.int_in(1, 6), 1], [nz(rng, -9, 9), 0]]
	s.x0 = Q.new(rng.pick([1, 1, 2, 2, 3, -1]))
	s.y0 = Q.new(nz(rng, -9, 15))
	s.k = s.y0.sub(val(anti(s.fp), s.x0))
	return _fits(s.k) and not s.k.eq(s.y0)


## f′ = ax + b, at a point in tenths, as the bank's Paper 2 part: C ends as a decimal.
static func _decimal(rng: Seeded, s: Dictionary) -> bool:
	s.style = "dec"
	s.fp = [[2 * rng.int_in(1, 5), 1], [nz(rng, -9, 9), 0]]
	s.x0 = Q.new(rng.int_in(11, 29), 10)
	if s.x0.is_int():
		return false
	s.k = Q.new(nz(rng, -89, 89), 10)
	s.y0 = val(anti(s.fp), s.x0).add(s.k)
	return not s.k.is_int() and s.y0.sign() > 0


static func _further(rng: Seeded, s: Dictionary) -> bool:
	if not _poly(rng, s):
		return false
	s.b = Q.new(rng.int_in(-1, 5))
	return not s.b.eq(s.x0) and absf(val(anti(s.fp), s.b).add(s.k).to_float()) <= 300.0 and not val(anti(s.fp), s.b).is_zero()


static func _negative(rng: Seeded, s: Dictionary) -> bool:
	var n: int = rng.pick([2, 2, 3])
	s.n = n
	s.fp = [[(n - 1) * nz(rng, -6, 6), -n], [2 * nz(rng, -4, 4), 1]]
	s.x0 = Q.new(rng.pick([1, 1, 2]))
	s.y0 = Q.new(nz(rng, -9, 15))
	s.k = s.y0.sub(val(anti(s.fp), s.x0))
	return _fits(s.k)


static func _trig_chain(rng: Seeded, s: Dictionary) -> bool:
	var turn: Array = rng.pick(TURNS)
	s.fam = rng.pick(["cos", "sin"])
	s.a = rng.pick([2, 2, 3, 4])
	s.K = s.a * nz(rng, -3, 4) if rng.chance(0.6) else nz(rng, -6, 6)
	s.x0 = Q.new(turn[0], turn[1]).div(s.a)
	s.sv = Q.new(turn[2])
	s.cv = Q.new(turn[3])
	s.y0 = Q.new(nz(rng, -9, 12))
	var c0 := Q.new(s.K, s.a)
	var fv: Q = c0.mul(s.sv) if s.fam == "cos" else c0.mul(s.cv).neg()
	s.fv = fv
	s.k = s.y0.sub(fv)
	return _fits(s.k)


static func _trig_shift(rng: Seeded, s: Dictionary) -> bool:
	var turn: Array = rng.pick(TURNS)
	var sh: Array = rng.pick(SHIFTS)
	s.fam = rng.pick(["cos", "sin"])
	s.K = nz(rng, -5, 5)
	s.sh = Q.new(sh[0], sh[1]).neg()              # the shift added to x
	s.theta = Q.new(turn[0], turn[1])
	s.x0 = s.theta.sub(s.sh)
	s.sv = Q.new(turn[2])
	s.cv = Q.new(turn[3])
	s.y0 = Q.new(nz(rng, -9, 12))
	var fv: Q = Q.new(s.K).mul(s.sv) if s.fam == "cos" else Q.new(s.K).mul(s.cv).neg()
	s.fv = fv
	s.k = s.y0.sub(fv)
	return s.x0.sign() > 0 and _fits(s.k)


static func _reciprocal(rng: Seeded, s: Dictionary) -> bool:
	s.a = rng.pick([1, 1, 2, 3, 4])
	s.K = s.a * nz(rng, -4, 5) if rng.chance(0.6) else nz(rng, -6, 6)
	s.x0 = Q.new(rng.int_in(0, 3))
	s.lin_b = 1 - s.a * s.x0.n                    # ax₀ + b = 1, so ln 1 falls out
	s.y0 = Q.new(nz(rng, -9, 12))
	s.k = s.y0
	return s.lin_b != 0


static func _exp_sum(rng: Seeded, s: Dictionary) -> bool:
	s.e = rng.pick(EXPS)
	s.B = nz(rng, -6, 6)
	s.y0 = Q.new(nz(rng, -9, 12))
	s.x0 = Q.new(0)
	var at0 := Q.new(s.B, s.e)
	if s.ask == "exp-and-power":
		s.n = rng.pick([1, 2])
		s.A = (s.n + 1) * nz(rng, -3, 4)
	else:
		s.fam = rng.pick(["cos", "sin"])
		s.A = nz(rng, -5, 5)
		if s.fam == "sin":
			at0 = at0.sub(s.A)                    # −A cos 0 = −A
	s.fv = at0
	s.k = s.y0.sub(at0)
	return _fits(s.k)


## h′ = e^(ax) + b at a point in tenths, with a value in whole numbers, as the bank's Paper 2 parts.
static func _exp_decimal(rng: Seeded, s: Dictionary) -> bool:
	s.style = "dec"
	s.a = rng.pick([2, 3, 4])
	s.b0 = rng.int_in(2, 9)
	s.x0 = Q.new(rng.int_in(11, 21), 10)
	var ex: float = s.a * s.x0.to_float()
	if s.x0.is_int() or ex > 7.0 or ex < 3.0:
		return false
	var fv: float = exp(ex) / s.a + s.b0 * s.x0.to_float()
	s.y0 = Q.new(roundi(fv + rng.int_in(3, 40) * (1 if rng.chance(0.5) else -1)))
	if s.y0.sign() <= 0:
		return false
	s.k = s.y0.to_float() - fv
	return GdcKit.fair(s.k) and absf(s.k) >= 1.0


static func _log(rng: Seeded, s: Dictionary) -> bool:
	s.K = rng.int_in(1, 6)
	s.a = rng.int_in(1, 8)
	s.x0 = Q.new(rng.int_in(1, 3))
	s.n = s.x0.n * s.x0.n + s.a
	s.y0 = Q.new(rng.int_in(1, 12))
	return true


static func _log_given(rng: Seeded, s: Dictionary) -> bool:
	s.K = rng.pick([1, 1, 2, 3])
	s.lin_b = rng.pick([2, 2, 4, -2, 6])
	s.c = rng.int_in(2, 12)
	s.x0 = Q.new(rng.int_in(0, 3))
	s.n = s.x0.n * s.x0.n + s.lin_b * s.x0.n + s.c
	s.y0 = Q.new(rng.int_in(1, 12))
	return s.lin_b * s.lin_b < 4 * s.c and s.n > 1


static func _rate(rng: Seeded, s: Dictionary) -> bool:
	s.sign = 1 if rng.chance(0.5) else -1
	s.A = 10 * rng.int_in(4, 40)
	s.kq = Q.new(5 * rng.int_in(2, 18), 1000)
	s.P0 = 10 * rng.int_in(250, 950)
	s.T = rng.int_in(4, 12)
	var k: float = s.kq.to_float()
	var change: float = s.sign * s.A / k * (1.0 - exp(-k * s.T))
	s.Pt = s.P0 + change
	var flat: float = s.P0 + s.sign * s.A * s.T
	return s.Pt > 500.0 and flat > 0.0 and absf(change) >= 100.0 and GdcKit.fair(s.Pt) and GdcKit.fair(change) and Fmt.sf(flat) != Fmt.sf(s.Pt) \
		and Answer.rounds_clearly(flat, EDGE)


static func _second(rng: Seeded, s: Dictionary) -> bool:
	s.fpp = [[6 * nz(rng, -3, 4), 1], [2 * nz(rng, -4, 4), 0]]
	s.x0 = Q.new(rng.pick([0, 0, 1, 1, 2]))
	s.p = Q.new(nz(rng, -7, 9))
	s.q = Q.new(nz(rng, -7, 9))
	var G := anti(s.fpp)
	var H := anti(G)
	s.c1 = s.p.sub(val(G, s.x0))
	s.c2 = s.q.sub(val(H, s.x0)).sub(s.c1.mul(s.x0))
	s.b = Q.new(rng.int_in(-1, 3))
	return not s.c1.is_zero() and not s.c2.is_zero() and not s.b.eq(s.x0) and not s.p.eq(s.q) and not s.b.is_zero()


static func _second_exp(rng: Seeded, s: Dictionary) -> bool:
	s.A = 6 * nz(rng, -2, 3)
	s.B = nz(rng, -6, 6)
	s.x0 = Q.new(0)
	s.p = Q.new(nz(rng, -7, 9))
	s.q = Q.new(nz(rng, -7, 9))
	s.c1 = s.p.sub(s.B)
	s.c2 = s.q.sub(s.B)
	return not s.c1.is_zero() and not s.c2.is_zero() and not s.p.eq(s.q)


static func _parameter(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.pick([1, 2])
	s.c = nz(rng, -6, 6)                          # dy/dx = Kxⁿ + c, with K unknown
	s.K = (s.n + 1) * nz(rng, -3, 4)
	s.x1 = Q.new(nz(rng, -2, 3))
	s.m = power(s.x1, s.n).mul(s.K).add(s.c)
	s.x0 = Q.new(rng.pick([1, 2, 3, -1]))
	s.y0 = Q.new(nz(rng, -9, 15))
	s.fp = [[s.K, s.n], [s.c, 0]]
	s.k = s.y0.sub(val(anti(s.fp), s.x0))
	# Putting the point in dy/dx must be able to give some other K.
	return not s.x0.is_zero() and _fits(s.k) and not s.m.is_zero() and not s.y0.sub(s.c).div(power(s.x0, s.n)).eq(s.K)


## F(x) = ax² + 2mx, a = ±1, so the vertex is at a whole x. The four curves are the right one
## and three slips, far enough apart to label.
static func _family(rng: Seeded, s: Dictionary) -> bool:
	var a: int = rng.pick([1, -1])
	var m := rng.int_in(-3, 3)
	s.fp = [[2 * a, 1], [2 * m, 0]]
	var vx := -m * a
	s.vx = vx
	s.x0 = Q.new(vx + nz(rng, -2, 2))
	s.y0 = Q.new(rng.int_in(-5, 8))
	var F := anti(s.fp)
	s.k = s.y0.sub(val(F, s.x0))
	s.cs = [s.k, s.y0, s.y0.add(val(F, s.x0)), s.y0.sub(val(s.fp, s.x0))]
	var sorted: Array = s.cs.map(func(c): return c.n)
	sorted.sort()
	for i in 3:
		if sorted[i + 1] - sorted[i] < FAMILY_GAP:
			return false
	return not s.k.is_zero() and s.x0.n != 0 and absi(sorted[3]) <= 16 and absi(sorted[0]) <= 16


## f′ in three straight pieces, with whole corners, above and below the axis.
static func _pieces(rng: Seeded, s: Dictionary) -> bool:
	var xs: Array = [0]
	for i in 3:
		xs.append(xs[-1] + rng.pick([1, 2, 2, 3]))
	var ys: Array = []
	for i in 4:
		ys.append(rng.int_in(-5, 6))
	s.xs = xs
	s.ys = ys
	s.from = rng.pick([0, 0, 1])
	s.x0 = Q.new(xs[s.from])
	s.b = Q.new(xs[3])
	s.y0 = Q.new(nz(rng, -6, 12))
	var below := false
	var above := false
	for y in ys.slice(s.from):
		below = below or y < 0
		above = above or y > 0
	s.area = signed_area(s, false)
	return below and above and not s.area.is_zero() and not ys[3] == 0 and ys[s.from] != ys[s.from + 1]


## The area under f′ from the start to the end, with every part positive if asked.
static func signed_area(s: Dictionary, all_positive: bool) -> Q:
	var out := Q.new(0)
	for i in range(s.from, 3):
		var w: int = s.xs[i + 1] - s.xs[i]
		var l: int = s.ys[i]
		var r: int = s.ys[i + 1]
		if not all_positive or l * r >= 0:
			var part := Q.new((l + r) * w, 2)
			out = out.add(part.abs_q() if all_positive else part)
		else:
			# The piece crosses the axis: two triangles.
			var cut := Q.new(w * absi(l), absi(l) + absi(r))
			out = out.add(cut.mul(absi(l)).div(2)).add(Q.new(w).sub(cut).mul(absi(r)).div(2))
	return out


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
