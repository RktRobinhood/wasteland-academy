class_name ArcSectorSituation
extends RefCounted
## The `arc-sector` situation (curriculum/question-types.json): one sector of a circle, radius r
## and angle θ (FAL-726). `form` says how the angle is written:
##   pi    a multiple of π: t is the multiple, Paper 1 only
##   rad   t is the angle in radians
##   deg   t is the angle in degrees
## Paper 1 is exact: r is a whole number and an arc, an area or a perimeter is a + bπ, kept as
## [a, b]. Paper 2 has r to 1 d.p., and where r or θ is worked back, the given arc, area or
## perimeter to 1 d.p., and r or θ follows from it, so what the student sees decides the answer.
##
## need.ask is the unknown (see ArcSectorViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx (an index into ArcSectorViews.CONTEXTS), form
##   r, t             Q: the radius and the angle (r is 9-place on Paper 2 where it is worked back)
##   l, area, per     [a, b]: the arc, the area and the perimeter, where they are given
##   rin              Q: the inner radius of a curved strip (ring-*)
##   w, h, rho        ints: a plate's sides and its circle's radius (segments-theta)
##   strip, side      Q: a bent strip's width and straight sides (theta-from-bent-strip)
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 6000
const EDGE := 0.03
const CONTEXTS := 6
const MAX_DEN := 24
const PI_T := [[1, 6], [1, 4], [1, 3], [1, 2], [2, 3], [3, 4], [5, 6], [1, 1], [7, 6], [5, 4], [4, 3], [3, 2], [5, 3]]
const DEG_T := [30, 45, 60, 90, 120, 135, 150, 210, 225, 240, 270, 300]
const RAD_T := [[1, 2], [3, 4], [1, 1], [6, 5], [3, 2], [2, 1], [5, 2], [3, 1]]
## The forms each unknown can take, on each paper.
const FORMS := {
	"deg-to-rad": [["deg"], ["deg"]], "rad-to-deg": [["pi"], ["rad"]],
	"arc-length": [["pi", "rad", "deg"], ["rad", "deg"]], "perimeter": [["pi", "rad", "deg"], ["rad", "deg"]],
	"sector-area": [["pi", "rad", "deg"], ["rad", "deg"]], "r-from-arc": [["pi", "rad", "deg"], ["rad", "deg"]],
	"r-from-area": [["pi", "rad", "deg"], ["rad", "deg"]], "major-arc": [["pi", "rad", "deg"], ["rad", "deg"]],
	"major-sector": [["pi", "rad", "deg"], ["rad", "deg"]], "cone-radius": [["pi", "deg"], ["rad", "deg"]],
	"theta-from-arc": [["pi", "rad"], ["rad"]], "theta-from-area": [["pi", "rad"], ["rad"]],
}
const MINOR := ["major-arc", "major-sector", "major-from-perimeter"]
## Given the arc, the area or the perimeter on Paper 2, with r worked back.
const GIVE_L := ["r-from-arc"]
const GIVE_A := ["r-from-area", "perimeter-from-area"]
const GIVE_P := ["r-from-perimeter", "major-from-perimeter"]
## The same, with θ worked back.
const THETA_L := ["theta-from-arc", "area-from-arc", "r-in-terms-of-theta"]
const THETA_A := ["theta-from-area"]
const THETA_P := ["theta-from-perimeter"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "arc-length")
	var rep: String = need.get("rep", "diagram")
	var paper: int = int(need.get("paper", 1))
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, CONTEXTS - 1)}
		var ok := false
		match ask:
			"ring-inner-radius", "ring-perimeter":
				ok = _ring(rng, s)
			"segments-theta":
				ok = _plate(rng, s)
			_:
				ok = _sector(rng, s)
		if ok and clear(s):
			return s
	return {}


## Every value offered is clear of a rounding edge, and Paper 1 stays simple.
static func clear(s: Dictionary) -> bool:
	var out: Dictionary = ArcSectorViews.new().build(s.ask, s.rep, s, null)
	if out.answer.kind == "number":
		var vs: Array = [out.answer.values.v]
		for w in out.wrongs:
			vs.append(w.values.v)
		for g in out.generic:
			vs.append(g.v)
		return vs.all(func(v): return v.to_float() <= 0.0 or Answer.rounds_clearly(v.to_float(), EDGE))
	return out.answer.values.values().all(func(v): return not v is Q or v.d <= MAX_DEN)


static func _sector(rng: Seeded, s: Dictionary) -> bool:
	var ask: String = s.ask
	s.form = rng.pick(FORMS[ask][s.paper - 1]) if FORMS.has(ask) else "rad"
	if s.paper == 1:
		s.r = Q.new(rng.int_in(2, 12))
		s.t = _p1_angle(rng, s.form)
	else:
		s.r = Q.new(rng.int_in(20, 300), 10)
		s.t = _p2_angle(rng, s.form)
	if ask in MINOR and ArcSectorViews.radians(s) >= PI:
		return false
	if ask == "major-from-perimeter" and s.paper == 1 and not s.t.mul(2).is_int():
		return false
	if ask == "theta-from-bent-strip":
		s.side = Q.new(rng.int_in(2, 12)) if s.paper == 1 else Q.new(rng.int_in(20, 120), 10)
		s.strip = s.side.mul(2).add(s.r.mul(s.t))
		if s.paper == 2:
			s.strip = _1dp(s.strip.to_float())
			s.t = s.strip.sub(s.side.mul(2)).div(s.r)
		return s.t.lt(Q.new(5))
	var th: Array = ArcSectorViews.theta(s)
	if ask in GIVE_L or ask in THETA_L:
		s.l = ArcSectorViews.scale(th, s.r)
	if ask in GIVE_A or ask in THETA_A:
		s.area = ArcSectorViews.scale(th, s.r.sq().div(2))
	if ask in GIVE_P or ask in THETA_P:
		s.per = ArcSectorViews.plus(ArcSectorViews.scale(th, s.r), [s.r.mul(2), Q.new(0)])
	return _p2_back(s) if s.paper == 2 else true


## On Paper 2 what is given is rounded, and what is worked back comes from it.
static func _p2_back(s: Dictionary) -> bool:
	var ask: String = s.ask
	var th := ArcSectorViews.radians(s)
	if s.has("l"):
		s.l = [_1dp(ArcSectorViews.fl(s.l)), Q.new(0)]
	if s.has("area"):
		s.area = [_1dp(ArcSectorViews.fl(s.area)), Q.new(0)]
	if s.has("per"):
		s.per = [_1dp(ArcSectorViews.fl(s.per)), Q.new(0)]
	if ask in GIVE_L:
		s.r = GdcKit.qf(s.l[0].to_float() / th)
	elif ask in GIVE_A:
		s.r = GdcKit.qf(sqrt(2.0 * s.area[0].to_float() / th))
	elif ask in GIVE_P:
		s.r = GdcKit.qf(s.per[0].to_float() / (2.0 + th))
	elif ask in THETA_L:
		s.t = s.l[0].div(s.r)
	elif ask in THETA_A:
		s.t = s.area[0].mul(2).div(s.r.sq())
	elif ask in THETA_P:
		s.t = s.per[0].sub(s.r.mul(2)).div(s.r)
	return s.t.sign() > 0 and s.r.sign() > 0 and ArcSectorViews.radians(s) > 0.2 and ArcSectorViews.radians(s) < 6.0


static func _1dp(x: float) -> Q:
	return Q.new(roundi(x * 10.0), 10)


static func _p1_angle(rng: Seeded, form: String) -> Q:
	match form:
		"pi":
			var p: Array = rng.pick(PI_T)
			return Q.new(p[0], p[1])
		"deg":
			return Q.new(rng.pick(DEG_T))
	var p: Array = rng.pick(RAD_T)
	return Q.new(p[0], p[1])


static func _p2_angle(rng: Seeded, form: String) -> Q:
	if form == "deg":
		var d := rng.int_in(20, 340)
		while d % 15 == 0:
			d = rng.int_in(20, 340)
		return Q.new(d)
	return Q.new(rng.int_in(25, 550), 100)


## A curved strip between two circles, Paper 2: a reflex angle in radians.
static func _ring(rng: Seeded, s: Dictionary) -> bool:
	s.form = "rad"
	s.r = Q.new(rng.int_in(60, 200), 10)
	s.t = Q.new(rng.int_in(35, 56), 10)
	s.rin = Q.new(rng.int_in(20, 180), 10)
	if not s.rin.lt(s.r.mul(Q.new(9, 10))) or s.rin.lt(s.r.mul(Q.new(3, 10))):
		return false
	if s.ask == "ring-inner-radius":
		s.area = [_1dp(s.t.to_float() * (s.r.sq().sub(s.rin.sq())).to_float() / 2.0), Q.new(0)]
		s.rin = GdcKit.qf(sqrt(s.r.sq().to_float() - 2.0 * s.area[0].to_float() / s.t.to_float()))
	return true


## A plate w by h with a segment of a circle of radius rho cut from each of two opposite edges.
## The student gets the area, to 1 d.p., and θ follows from it.
static func _plate(rng: Seeded, s: Dictionary) -> bool:
	s.form = "rad"
	s.w = rng.int_in(8, 20)
	s.h = rng.int_in(8, 20)
	s.rho = rng.int_in(3, 8)
	var drawn := float(rng.int_in(100, 280)) / 100.0
	s.area = [_1dp(s.w * s.h - s.rho * s.rho * (drawn - sin(drawn))), Q.new(0)]
	var th := ArcSectorViews.solve_plate(s)
	s.t = GdcKit.qf(th)
	var half := th / 2.0
	var chord: float = 2.0 * s.rho * sin(half)
	var depth: float = s.rho * (1.0 - cos(half))
	return chord < s.h - 1.0 and depth * 2.0 < s.w - 1.0 and th > 1.0 and th < 3.0


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
