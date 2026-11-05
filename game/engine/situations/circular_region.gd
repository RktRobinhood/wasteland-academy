class_name CircularRegionSituation
extends RefCounted
## The `circular-region` situation (curriculum/question-types.json): a region built from sectors,
## triangles, rectangles and circles, or one sector fixed by two conditions (FAL-739).
##
## need.ask is the unknown (see CircularRegionViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx, form    as on `arc-sector`; form is "rad", "deg" or "pi"
##   r, t         Q: the radius (or the rope, or the slant) and the angle
##   l, area, per [a, b]: the arc, the area and the perimeter, as ArcSectorViews keeps them
##   rin          Q: the inner radius of a curved strip
##   h            Q: the height of a rectangle (arch-*, and a hatch's drawn height)
##   k            int: a hatch is kx wide
##   m, n         ints: the ratio of the segment to the triangle (ratio-*)
##   a2           Q: a whole-number r² on a tangent region in terms of α
##   r1, r2       Q: the two roots of the sector's quadratic, r1 < r2 (two-conditions-*)
##
## Paper 1 has whole-number or landmark numbers and exact answers; everything else is 3 s.f. on
## Paper 2. The clean limits are the numbers behind the catalogue's `clean` text. The checker holds
## its own copy.

const TRIES := 6000
const EDGE := 0.03
const CONTEXTS := 6
const SEG_STORIES := 3
const MAX_DEN := 24
## Segment : triangle. 1 : 1 and 3 : 5 are the bank's own.
const RATIOS := [[1, 2], [2, 3], [3, 2], [3, 4], [4, 3], [2, 1], [5, 4], [4, 5], [5, 2], [1, 3], [3, 1]]
const PI_SEG := [[1, 6], [1, 3], [1, 2], [2, 3], [5, 6]]
const TWO := ["theta-in-r", "two-conditions-quadratic", "two-conditions-r", "two-conditions-theta", "two-conditions-both"]
## The two roots: one with θ past 2π, or both sectors real.
const ONE_ROOT := ["two-conditions-r", "two-conditions-theta"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "segment-area")
	var rep: String = need.get("rep", "diagram")
	var paper: int = int(need.get("paper", 2))
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, CONTEXTS - 1), "form": "rad"}
		var ok := false
		if ask in TWO:
			ok = _two(rng, s)
		else:
			match ask:
				"segment-area", "segment-perimeter", "segment-in-terms-of-theta", "segment-radius":
					ok = _segment(rng, s)
				"segment-exact":
					ok = _exact(rng, s)
				"tether-area", "tether-expression", "tether-angle":
					ok = _tether(rng, s)
				"ratio-equation", "ratio-theta", "ratio-radius":
					ok = _ratio(rng, s)
				"arch-area":
					ok = _arch(rng, s)
				"ring-area", "ring-expression":
					ok = _ring(rng, s)
				"hatch-area", "hatch-height":
					ok = _hatch(rng, s)
				"tangent-region", "tangent-expression":
					ok = _tangent(rng, s)
				"arc-area-radius":
					ok = _arc_area(rng, s)
				"cone-from-area":
					ok = _cone(rng, s)
		if ok and clear(s):
			return s
	return {}


## Every value offered is clear of a rounding edge, and an exact answer stays simple.
static func clear(s: Dictionary) -> bool:
	var out: Dictionary = CircularRegionViews.new().build(s.ask, s.rep, s, null)
	var vs: Array = []
	if out.answer.kind == "number":
		vs = [out.answer.values.v]
		for w in out.wrongs:
			vs.append(w.values.v)
		for g in out.generic:
			vs.append(g.v)
	elif out.answer.kind == "measures":
		vs = [out.answer.values.v1, out.answer.values.v2]
		for w in out.wrongs:
			vs.append(w.values.v1)
			vs.append(w.values.v2)
	else:
		return out.answer.values.values().all(func(v): return not v is Q or v.d <= MAX_DEN)
	return vs.all(func(v): return v.to_float() <= 0.0 or Answer.rounds_clearly(v.to_float(), EDGE))


static func _1dp(x: float) -> Q:
	return Q.new(roundi(x * 10.0), 10)


static func _rad(rng: Seeded, lo: int, hi: int) -> Q:
	return Q.new(rng.int_in(lo, hi), 100)


## A minor segment, on Paper 2.
static func _segment(rng: Seeded, s: Dictionary) -> bool:
	s.ctx = rng.int_in(0, SEG_STORIES - 1)
	s.r = Q.new(rng.int_in(20, 300), 10)
	s.t = _rad(rng, 60, 300)
	match s.ask:
		"segment-in-terms-of-theta":
			s.r = Q.new(rng.int_in(3, 12))
		"segment-radius":
			var area: float = pow(s.r.to_float(), 2) * (s.t.to_float() - sin(s.t.to_float())) / 2.0
			s.area = [_1dp(area), Q.new(0)]
			if s.area[0].to_float() < 2.0:
				return false
			s.r = GdcKit.qf(sqrt(2.0 * s.area[0].to_float() / (s.t.to_float() - sin(s.t.to_float()))))
		_:
			if rng.chance(0.5):
				var d := rng.int_in(35, 170)
				if d % 15 == 0:
					return false
				s.form = "deg"
				s.t = Q.new(d)
	return true


## A segment with a landmark angle, exact, on Paper 1. r is even, so r²/4 is whole.
static func _exact(rng: Seeded, s: Dictionary) -> bool:
	var p: Array = rng.pick(PI_SEG)
	s.form = "pi"
	s.t = Q.new(p[0], p[1])
	s.r = Q.new(2 * rng.int_in(2, 6))
	return true


## A rope tied at O on one wall, reaching A at the walls' corner and D and E on the walls.
static func _tether(rng: Seeded, s: Dictionary) -> bool:
	s.r = Q.new(rng.int_in(40, 300), 10)
	s.t = _rad(rng, 80, 260)
	if s.ask == "tether-expression":
		s.l = [Q.new(2 * rng.int_in(6, 20)), Q.new(0)]
		return not s.l[0].eq(Q.new(28))
	if s.ask == "tether-angle":
		s.l = [_1dp(s.r.to_float() * s.t.to_float()), Q.new(0)]
		s.t = s.l[0].div(s.r)
		return s.t.to_float() > 0.7 and s.t.to_float() < 2.8
	return true


## θ on (0, π) with θ = k sin θ, by halving: θ/sin θ only rises from 1.
static func root(k: float) -> float:
	var lo := 1e-6
	var hi := PI - 1e-6
	for i in 80:
		var mid := (lo + hi) / 2.0
		if mid / sin(mid) < k:
			lo = mid
		else:
			hi = mid
	return (lo + hi) / 2.0


## A semicircle or a circle with a segment and a triangle in the ratio m : n.
static func _ratio(rng: Seeded, s: Dictionary) -> bool:
	var p: Array = rng.pick(RATIOS)
	s.m = p[0]
	s.n = p[1]
	var th := root(1.0 + float(s.m) / s.n)
	s.t = GdcKit.qf(th)
	if s.ask == "ratio-radius":
		var drawn := float(rng.int_in(30, 200)) / 10.0
		s.area = [_1dp(drawn * drawn * (th - sin(th)) / 2.0), Q.new(0)]
		if s.area[0].to_float() < 2.0:
			return false
		s.r = GdcKit.qf(sqrt(2.0 * s.area[0].to_float() * s.n / s.m / sin(th)))
	return true


## A rectangle with a segment on top, with O inside the rectangle.
static func _arch(rng: Seeded, s: Dictionary) -> bool:
	s.r = Q.new(rng.int_in(30, 150), 10)
	s.t = _rad(rng, 120, 300)
	s.h = Q.new(rng.int_in(20, 200), 10)
	var r: float = s.r.to_float()
	var th: float = s.t.to_float()
	var h: float = s.h.to_float()
	var w := 2.0 * r * sin(th / 2.0)
	return h > 1.05 * r * cos(th / 2.0) and h > 0.4 * w and h < 1.3 * w


## A curved strip between two circles, with a reflex angle.
static func _ring(rng: Seeded, s: Dictionary) -> bool:
	s.t = Q.new(rng.int_in(35, 56), 10)
	if s.ask == "ring-expression":
		s.r = Q.new(rng.int_in(6, 20))
		s.rin = s.r.mul(Q.new(rng.int_in(4, 7), 10))
		return not (s.r.eq(Q.new(10)) and s.t.eq(Q.new(24, 5)))
	s.r = Q.new(rng.int_in(60, 200), 10)
	s.rin = Q.new(rng.int_in(20, 180), 10)
	return s.rin.lt(s.r.mul(Q.new(9, 10))) and not s.rin.lt(s.r.mul(Q.new(3, 10)))


## A rectangle kx wide with a semicircle on it. x and h are letters: what is drawn is one shape
## that fits. A perimeter is whole, with the shape worked back from it.
static func _hatch(rng: Seeded, s: Dictionary) -> bool:
	s.k = rng.pick([2, 4, 6])
	s.per = [Q.new(rng.int_in(12, 40)), Q.new(0)]
	var rho: float = s.per[0].to_float() / (2.0 + 2.4 + PI)
	s.r = GdcKit.qf(rho)
	s.h = GdcKit.qf(1.2 * rho)
	return not (s.k == 2 and s.per[0].eq(Q.new(10)))


## Tangents AD and AE to a circle centre O. t is angle DAE, 2α in the expression.
static func _tangent(rng: Seeded, s: Dictionary) -> bool:
	if s.ask == "tangent-expression":
		s.r = Q.new(rng.int_in(2, 12))
		s.a2 = s.r.sq()
		s.t = _rad(rng, 90, 200)
		return true
	s.r = Q.new(rng.int_in(20, 120), 10)
	s.t = _rad(rng, 90, 220)
	return true


## Two conditions, perimeter and area, whose quadratic is r² − (P/2)r + A = 0 with roots r1 < r2.
## The sector of root r has θ = (P − 2r)/r, so θ = 2r2/r1 and 2r1/r2: only the first can pass 2π,
## which it does when r2/r1 > π.
static func _two(rng: Seeded, s: Dictionary) -> bool:
	var ask: String = s.ask
	var r1: float
	var r2: float
	if s.paper == 1:
		s.r1 = Q.new(rng.int_in(1, 7))
		s.r2 = s.r1.add(rng.int_in(1, 11))
		s.per = [s.r1.add(s.r2).mul(2), Q.new(0)]
		s.area = [s.r1.mul(s.r2), Q.new(0)]
		r1 = s.r1.to_float()
		r2 = s.r2.to_float()
		if s.r2.to_float() > 14.0:
			return false
	else:
		s.per = [Q.new(rng.int_in(80, 500), 10), Q.new(0)]
		s.area = [Q.new(rng.int_in(30, 900), 10), Q.new(0)]
		var half: float = s.per[0].to_float() / 2.0
		var a: float = s.area[0].to_float()
		var disc := half * half - 4.0 * a
		if disc <= 0.25:
			return false
		r1 = (half - sqrt(disc)) / 2.0
		r2 = (half + sqrt(disc)) / 2.0
		s.r1 = GdcKit.qf(r1)
		s.r2 = GdcKit.qf(r2)
	var ratio := r2 / r1
	if ask in ONE_ROOT and ratio < 3.3:
		return false
	if ask == "two-conditions-both" and ratio > 2.9:
		return false
	# A drawn sector is the root with a real θ, the larger.
	s.r = s.r2
	s.t = s.r1.mul(2).div(s.r2) if s.paper == 1 else GdcKit.qf(2.0 * r1 / r2)
	return s.t.to_float() > 0.2


## An arc and an area: r = 2A ÷ l.
static func _arc_area(rng: Seeded, s: Dictionary) -> bool:
	if s.paper == 1:
		s.r = Q.new(rng.int_in(2, 12))
		s.l = [Q.new(rng.int_in(2, 30)), Q.new(0)]
		s.area = [s.r.mul(s.l[0]).div(2), Q.new(0)]
		s.t = s.l[0].div(s.r)
	else:
		var r0 := Q.new(rng.int_in(30, 300), 10)
		var t0 := _rad(rng, 40, 550)
		s.l = [_1dp(r0.to_float() * t0.to_float()), Q.new(0)]
		s.area = [_1dp(r0.to_float() * r0.to_float() * t0.to_float() / 2.0), Q.new(0)]
		s.r = s.area[0].mul(2).div(s.l[0])
		s.t = s.l[0].div(s.r)
	return s.t.to_float() > 0.3 and s.t.to_float() < 6.0


## A sector of known area and radius, rolled up into a cone.
static func _cone(rng: Seeded, s: Dictionary) -> bool:
	s.r = Q.new(rng.int_in(40, 300), 10)
	var t0 := _rad(rng, 100, 550)
	s.area = [_1dp(s.r.sq().to_float() * t0.to_float() / 2.0), Q.new(0)]
	s.t = s.area[0].mul(2).div(s.r.sq())
	return s.t.to_float() < 6.0


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
