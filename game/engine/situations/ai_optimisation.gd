class_name AiOptimisationSituation
extends RefCounted
## The `ai-optimisation` situation (curriculum/question-types.json), FAL-1000, for
## t5-ai-optimisation (AI-SL5.7). Every AI paper allows a GDC, so every question is Paper 2.
##
## need.ask is the unknown (see AiOptimisationViews); need.angle the method, where the numbers
## hang on it. generate() returns a Dictionary with paper 2, ask and ctx (a story index), and:
##
##   kind "shape"   one of OptimisationSituation's Paper 2 shapes (a can, a bin, a tray, a pen,
##                  a paddock, a route), with all its keys (fam, x, y, best, lo, hi, dlo, dhi ...)
##   kind "quad"    a quadratic model c2 x² + c1 x + c0 (Q, decimals): a profit (big) or a cost
##   kind "cubic"   a cubic profit c3 x³ + c2 x² + c1 x + c0 with both stationary points positive:
##                  the local maximum x and the local minimum `other`
##   kind "recip"   a cost a x + b/x + c, or a profit c − a x − b/x (a, b, c Q)
##   kind "angle"   an area k sin θ (w + k cos θ), for 0° < θ < 90°, that only the GDC optimises
##   kind "demand"  a price p, the demand A − Bp, a fixed cost F and a cost per item cost:
##                  the profit (p − cost)(A − Bp) − F, its best price p and its greatest profit
##
## Every model has x (the optimum, a float; Q for the demand), best (the value there), big
## (a maximum), X (the domain's top, where it has one), and for the derivative's sign test
## lo, hi either side of x. A suggested value has p0 with its slope d0 and value v0 (Q). A
## whole-number model (ask whole-number-optimum) has n, the whole number below x, chosen so
## that x rounds to n while n + 1 gives the better value: the nearest whole number is the
## wrong one.
##
## The numbers are drawn, not taken from any exam question. The SymPy checker
## (tools/check_answers.py, R2OP_) holds its own copy of the clean limits.

const TRIES := 4000
const CONTEXTS := 3
## A 3 s.f. value is at least this far (a fraction of its last place) from a rounding edge.
const EDGE := 0.04
const SHAPES := {
	"constraint-second-length": ["pen", "paddock", "can", "bin"],
	"objective-one-variable": ["pen", "paddock", "can", "bin", "box", "box"],
	"container-optimal-dimension": ["paddock", "can", "bin", "box"],
	"container-optimum-value": ["paddock", "can", "bin", "box"],
	"container-other-dimension": ["paddock", "can", "bin"],
	"route-least-time": ["route"],
	"context-domain": ["box", "pen"],
}
const GIVEN := ["optimal-input-given-model", "optimum-value-given-model"]
## x² coefficients of a quadratic, in tenths.
const QUAD_A := [2, 3, 4, 6, 7, 8, 12, 15, 25]
## x³ coefficients of a cubic, in hundredths.
const CUBIC_A := [1, 2, 5, 10, 20]
## x coefficients of a reciprocal model, in tenths.
const RECIP_A := [5, 8, 12, 15, 25, 40, 50, 75]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "optimal-input-given-model")
	var angle: String = str(need.get("angle", ""))
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "ctx": rng.int_in(0, CONTEXTS - 1), "big": true}
		var ok := false
		if SHAPES.has(ask):
			ok = _shape(rng, s, SHAPES[ask])
		elif ask in GIVEN:
			ok = _given(rng, s, angle)
		elif ask == "suggested-not-optimal":
			ok = _suggested(rng, s)
		elif ask == "whole-number-optimum":
			ok = _whole(rng, s)
		elif ask == "profit-from-revenue-cost":
			ok = _demand(rng, s)
		if ok:
			return s
	return {}


static func clear(v: float) -> bool:
	return Answer.rounds_clearly(absf(v), EDGE)


## A GDC value that needs rounding to 3 s.f.: not a whole number or a short decimal.
static func awkward(v: float) -> bool:
	return clear(v) and Answer.needs_rounding(GdcKit.qf(v))


## Two values that read differently at 3 s.f.
static func apart(a: float, b: float) -> bool:
	return Fmt.sf(a) != Fmt.sf(b)


static func tenths(n: int) -> Q:
	return Q.new(n, 10)


# ── The optimisation-model shapes ────────────────────────────

static func _shape(rng: Seeded, s: Dictionary, fams: Array) -> bool:
	var t := OptimisationSituation.generate(rng, {"fams": fams, "mode": "clean", "paper": 2})
	if t.is_empty():
		return false
	for key in t:
		s[key] = t[key]
	s.kind = "shape"
	match s.ask:
		"context-domain":
			# The domain's top is a whole number or a half, so the interval is exact.
			if s.fam == "pen":
				return s.F % s.n == 0
			return mini(s.w, s.h) % 2 == 0
		"route-least-time":
			s.target = "point" if rng.chance(0.5) else "value"
			var one := one_speed(s)
			return clear(one) and apart(one, s.best) and apart(one, OptimisationSituation.route_value(s, float(s.b))) \
				and apart(s.x, float(s.b)) and apart(s.x, s.b - s.x)
		"container-other-dimension":
			s.rounded = rounded_other(s)
			return clear(s.rounded)
	return true


## The least time or cost with both legs at the road's speed or cost: the straight line to B.
static func one_speed(s: Dictionary) -> float:
	var line := sqrt(float(s.a * s.a + s.b * s.b))
	return line * s.back if s.cost else line / s.back


## The second length worked from the free length rounded to 3 s.f. first.
static func rounded_other(s: Dictionary) -> float:
	var x := Fmt.sf(s.x).to_float()
	match s.fam:
		"paddock":
			return s.P / x
		"can":
			return s.V / (PI * x * x)
	return (s.P - x * x) / (4.0 * x)


# ── A given model ────────────────────────────────────────────

## The model's value at x (θ in degrees for an angle model).
static func value(s: Dictionary, x: float) -> float:
	match s.kind:
		"quad", "cubic":
			var v := 0.0
			for t in s.terms:
				v += t[0].to_float() * pow(x, t[1])
			return v
		"recip":
			var core: float = s.a.to_float() * x + s.b.to_float() / x
			return s.c.to_float() + (core if not s.big else -core)
		"angle":
			var r := deg_to_rad(x)
			return s.k.to_float() * sin(r) * (s.w.to_float() + s.k.to_float() * cos(r))
		"demand":
			return (x - s.cost) * (s.A - s.B * x) - s.F
	return 0.0


## The model's derivative at x (for a polynomial or reciprocal model).
static func slope(s: Dictionary, x: float) -> float:
	match s.kind:
		"quad", "cubic":
			var v := 0.0
			for t in s.terms:
				if t[1] > 0:
					v += t[0].to_float() * t[1] * pow(x, t[1] - 1)
			return v
		"recip":
			var core: float = s.a.to_float() - s.b.to_float() / (x * x)
			return core if not s.big else -core
		"demand":
			return -2.0 * s.B * x + s.A + s.B * s.cost
	return 0.0


## A polynomial or reciprocal model's exact value at a rational x.
static func exact(s: Dictionary, x: Q) -> Q:
	if s.kind == "recip":
		var core: Q = s.a.mul(x).add(s.b.div(x))
		return s.c.add(core.neg() if s.big else core)
	var v := Q.new(0)
	for t in s.terms:
		var c: Q = t[0]
		for i in t[1]:
			c = c.mul(x)
		v = v.add(c)
	return v


static func exact_slope(s: Dictionary, x: Q) -> Q:
	var v := Q.new(0)
	for t in s.terms:
		if t[1] > 0:
			var c: Q = t[0].mul(t[1])
			for i in t[1] - 1:
				c = c.mul(x)
			v = v.add(c)
	return v


static func _given(rng: Seeded, s: Dictionary, angle: String) -> bool:
	var kinds: Array = ["quad", "cubic", "recip", "angle", "angle"]
	if angle == "derivative-zero":
		kinds = ["quad", "cubic", "recip"]
	elif angle == "vertex-of-quadratic-model":
		kinds = ["quad"]
	match rng.pick(kinds):
		"quad":
			return _quad(rng, s)
		"cubic":
			return _cubic(rng, s)
		"recip":
			return _recip(rng, s)
	return _angle(rng, s)


## The whole numbers either side of x, for the derivative's sign test.
static func _sides(s: Dictionary) -> bool:
	s.lo = floorf(s.x)
	s.hi = ceilf(s.x)
	if s.lo <= 0.0 or s.hi == s.lo:
		return false
	s.dlo = slope(s, s.lo)
	s.dhi = slope(s, s.hi)
	return clear(s.dlo) and clear(s.dhi)


static func _quad(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "quad"
	s.big = rng.chance(0.6)
	var a := tenths(int(rng.pick(QUAD_A)))
	var b := rng.int_in(12, 240)
	var x := b / (2.0 * a.to_float())
	if x < 6.0 or x > 150.0:
		return false
	var top := b * b / (4.0 * a.to_float())
	var c: int
	if s.big:
		c = rng.int_in(5, 300) * 10
		if c > top - 50.0:
			return false
		s.terms = [[a.neg(), 2], [Q.new(b), 1], [Q.new(-c), 0]]
	else:
		c = ceili((top + rng.int_in(20, 600)) / 10.0) * 10
		s.terms = [[a, 2], [Q.new(-b), 1], [Q.new(c), 0]]
	s.x = x
	s.best = value(s, x)
	s.X = ceili(x * 1.6 / 10.0) * 10
	return awkward(s.x) and awkward(s.best) and _sides(s)


static func _cubic(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "cubic"
	var a := Q.new(int(rng.pick(CUBIC_A)), 100)
	var m0 := rng.int_in(1, 12)
	var M0 := m0 + rng.int_in(6, 40)
	var af := a.to_float()
	var b := tenths(roundi(15.0 * af * (m0 + M0)))
	var c := tenths(roundi(30.0 * af * m0 * M0))
	if b.is_zero() or c.is_zero():
		return false
	# P′ = −3a x² + 2b x − c: both roots positive, as c > 0.
	var bf := b.to_float()
	var cf := c.to_float()
	var disc := bf * bf - 3.0 * af * cf
	if disc <= 0.0:
		return false
	var d := rng.int_in(0, 60) * 10
	s.terms = [[a.neg(), 3], [b, 2], [c.neg(), 1], [Q.new(-d), 0]]
	s.x = (bf + sqrt(disc)) / (3.0 * af)
	s.other = (bf - sqrt(disc)) / (3.0 * af)
	s.best = value(s, s.x)
	s.other_best = value(s, s.other)
	s.X = ceili(s.x * 1.3 / 5.0) * 5
	if s.other < 1.0 or s.x > 120.0 or s.best < 50.0 or s.x - s.other < 3.0:
		return false
	return awkward(s.x) and awkward(s.best) and awkward(s.other) and awkward(s.other_best) and apart(s.best, s.other_best) and _sides(s)


static func _recip(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "recip"
	s.big = false
	s.a = tenths(int(rng.pick(RECIP_A)))
	var x0 := rng.int_in(20, 90)
	s.b = Q.new(roundi(s.a.to_float() * x0 * x0 / 10.0) * 10)
	s.c = Q.new(rng.int_in(0, 30) * 10)
	var r: Q = s.b.div(s.a)
	if r.is_int() and OptimisationSituation.is_square(r.n):
		return false
	s.x = sqrt(r.to_float())
	s.best = value(s, s.x)
	s.X = 0
	return awkward(s.x) and awkward(s.best) and _sides(s)


static func _angle(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "angle"
	s.k = tenths(int(rng.pick([4, 5, 6, 8, 12, 15])))
	s.w = tenths(rng.int_in(2, 20))
	if s.w.eq(s.k):
		return false
	var k: float = s.k.to_float()
	var w: float = s.w.to_float()
	var cosx := (-w + sqrt(w * w + 8.0 * k * k)) / (4.0 * k)
	s.x = rad_to_deg(acos(cosx))
	s.best = value(s, s.x)
	s.X = 90
	return awkward(s.x) and awkward(s.best)


# ── A suggested value that is not the optimum ───────────────

static func _suggested(rng: Seeded, s: Dictionary) -> bool:
	if not (_quad(rng, s) if rng.chance(0.65) else _cubic(rng, s)):
		return false
	if s.kind == "quad" and not s.big:
		return false
	var step := rng.int_in(2, 8) * (1 if rng.chance(0.5) else -1)
	var p0 := roundi(s.x) + step
	if p0 <= 0 or p0 >= s.X:
		return false
	s.p0 = p0
	s.d0 = exact_slope(s, Q.new(p0))
	s.v0 = exact(s, Q.new(p0))
	# The profit there is positive, so "it makes a profit" is a tempting reason.
	return not s.d0.is_zero() and s.v0.sign() > 0 and not s.d0.abs_q().eq(s.v0)


# ── Whole items ──────────────────────────────────────────────

## a x + b/x + c with b = k n(n + 1) and a just under k: x = √(b/a) is just under n + ½, so
## it rounds to n, but the model is lower (a cost) or higher (a profit) at n + 1, by k − a.
static func _whole(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "recip"
	s.big = rng.chance(0.4)
	var n := rng.int_in(2, 8)
	var k := rng.int_in(10, 150)
	var room := float(k) / (4.0 * n * (n + 1) + 1.0)
	var most := floori(room * 10.0 - 1e-9)
	if most < 1:
		return false
	var gap := tenths(rng.int_in(1, most))
	s.n = n
	s.a = Q.new(k).sub(gap)
	s.b = Q.new(k * n * (n + 1))
	var core_best := 2.0 * sqrt(s.a.to_float() * s.b.to_float())
	s.c = Q.new(rng.int_in(0, 30) * 10)
	if s.big:
		s.c = Q.new((ceili(core_best / 100.0) + rng.int_in(1, 15)) * 100)
	s.x = sqrt(s.b.to_float() / s.a.to_float())
	s.best = value(s, s.x)
	s.X = 20
	s.at_n = exact(s, Q.new(n))
	s.at_up = exact(s, Q.new(n + 1))
	var better: bool = s.at_up.lt(s.at_n) != s.big
	var frac: float = s.x - n
	return better and frac > 0.2 and frac < 0.5 and clear(s.x) and clear(s.best) and roundi(s.x) == n


# ── A price and the demand it gives ──────────────────────────

static func _demand(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "demand"
	s.B = rng.int_in(2, 20)
	s.cost = rng.int_in(4, 40)
	var r: int = s.cost + rng.int_in(5, 60)
	s.A = 2 * s.B * r
	if s.A > 4000 or s.A < 150:
		return false
	s.r = r
	s.x = Q.new(2 * r + s.cost, 2)
	var margin: Q = s.x.sub(s.cost)
	var top: Q = margin.mul(margin).mul(s.B)
	s.F = rng.int_in(2, maxi(2, int(top.to_float() * 0.5) / 50)) * 50
	s.best = top.sub(s.F)
	s.revenue = Q.new(s.B * r * r)
	s.no_cost = s.revenue.sub(s.F)
	s.target = "profit" if rng.chance(0.55) else "price"
	return s.best.sign() > 0 and float(s.F) < top.to_float()


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
