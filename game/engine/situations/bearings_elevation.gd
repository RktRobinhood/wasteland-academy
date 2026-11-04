class_name BearingsSituation
extends RefCounted
## The `bearings-elevation` situation (curriculum/question-types.json): points on a map or in a
## side view (FAL-726). Every question is Paper 2. Lengths are Q to 1 d.p. or whole, angles and
## bearings are whole degrees, and everything else is worked out from them by the views, from
## what the student is shown.
##
## need.ask is the unknown (see BearingsViews). generate() returns a Dictionary:
##   paper 2, ask, rep, ctx (a story, an index into the views' lists)
##   d1, d2      Q: distances: two legs, or sides AB and AC or AC alone
##   b1, b2      ints: bearings
##   phi         int: an angle inside a triangle
##   e, form     Q and "deg" or "rad": an angle of elevation or depression
##   h, x        Q: a height and a horizontal distance
##   eye, gap    Q: an observer's height and a clearance
##   v1, v2      ints: speeds in km/h;  which  which length or route is asked
##   ab, ad, bc, a_angle, dbc  shared-side and quadrilateral-area: B and D are joined
##   rule, sides  rule-to-use: what is known about the triangle PQR
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 6000
const EDGE := 0.03
const CONTEXTS := 6
const RULES := ["sas", "sss", "aas", "right"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "back-bearing")
	var rep: String = need.get("rep", "words")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep, "ctx": rng.int_in(0, CONTEXTS - 1)}
		var ok := false
		match ask:
			"back-bearing":
				s.b1 = rng.int_in(5, 355)
				ok = s.b1 != 180 and s.b1 % 90 != 0
			"two-leg-distance", "two-leg-bearing", "return-bearing":
				ok = _journey(rng, s)
			"angle-from-bearing", "due-east-distance", "sine-rule-distance":
				ok = _east(rng, s)
			"due-west-side":
				ok = _west(rng, s)
			"height-from-elevation", "height-with-eye-level", "chain-below-hook", "distance-from-depression":
				ok = _elevation(rng, s)
			"angle-of-depression":
				ok = _depression_angle(rng, s)
			"time-from-depression":
				ok = _sighting(rng, s)
			"route-time":
				ok = _route(rng, s)
			"shared-side", "quadrilateral-area":
				ok = _two_triangles(rng, s)
			"perpendicular-split":
				ok = _split(rng, s)
			"rule-to-use":
				ok = _rule(rng, s)
		if ok and clear(s):
			return s
	return {}


## Every value offered is clear of a rounding edge.
static func clear(s: Dictionary) -> bool:
	var out: Dictionary = BearingsViews.new().build(s.ask, s.rep, s, null)
	if out.answer.kind != "number":
		return true
	var vs: Array = [out.answer.values.v]
	for w in out.wrongs:
		vs.append(w.values.v)
	for g in out.generic:
		vs.append(g.v)
	return vs.all(func(v): return v.to_float() <= 0.0 or Answer.rounds_clearly(v.to_float(), EDGE))


static func _d(rng: Seeded, lo: int, hi: int) -> Q:
	return Q.new(rng.int_in(lo, hi), 10)


static func _journey(rng: Seeded, s: Dictionary) -> bool:
	s.d1 = _d(rng, 20, 400)
	s.d2 = _d(rng, 20, 400)
	s.b1 = rng.int_in(10, 350)
	var turn := rng.int_in(30, 150) * (1 if rng.chance(0.5) else -1)
	s.b2 = posmod(s.b1 + turn, 360)
	if s.b2 == 0 or s.b1 % 90 == 0 or s.b2 % 90 == 0:
		return false
	if s.ask == "two-leg-distance":
		return true
	var b := BearingsViews.start_to_end(s)
	# The working adds the angle at A to the first bearing, so that stays between 0° and 360°.
	if absf(b - float(s.b1)) > 150.0:
		return false
	if s.ask == "return-bearing":
		b = fposmod(b + 180.0, 360.0)
	return b >= 100.0 and b <= 355.0 and fposmod(b + 180.0, 360.0) >= 10.0


static func _east(rng: Seeded, s: Dictionary) -> bool:
	s.d1 = _d(rng, 30, 300)
	s.d2 = _d(rng, 30, 300)
	s.b1 = rng.int_in(15, 75)
	s.phi = rng.int_in(25, 80)
	s.which = "AC" if rng.chance(0.5) else "BC"
	# The third angle stays well away from nothing and from a right angle.
	var third: int = 180 - (90 - s.b1) - s.phi
	return third > 25 and third != 90 and third != s.phi and third != 90 - s.b1 and s.phi != 90 - s.b1


static func _west(rng: Seeded, s: Dictionary) -> bool:
	s.d1 = Q.new(rng.int_in(20, 90) * 10)
	s.b1 = rng.int_in(150, 225)
	s.phi = rng.int_in(20, 50)
	var abc: int = s.b1 - 90
	return absi(abc - 90) >= 8 and 180 - s.phi - abc > 20


static func _angle(rng: Seeded, s: Dictionary) -> void:
	s.form = "rad" if rng.chance(0.3) else "deg"
	s.e = Q.new(rng.int_in(25, 120), 100) if s.form == "rad" else Q.new(rng.int_in(12, 70))


static func _elevation(rng: Seeded, s: Dictionary) -> bool:
	_angle(rng, s)
	s.eye = Q.new(rng.int_in(15, 19), 10)
	s.gap = Q.new(rng.int_in(10, 40), 10)
	s.x = _d(rng, 50, 800)
	s.h = _d(rng, 50, 800)
	var t := tan(BearingsViews.elev(s))
	if s.ask == "chain-below-hook":
		s.x = _d(rng, 40, 200)
		var top: float = s.x.to_float() * t
		return top > s.eye.to_float() + s.gap.to_float() + 3.0 and top > 8.0 and top < 20.0
	if s.ask == "height-from-elevation" or s.ask == "height-with-eye-level":
		s.x = _d(rng, 40, 300)
		return s.x.to_float() * t < 60.0
	return s.h.to_float() / t < 300.0


static func _depression_angle(rng: Seeded, s: Dictionary) -> bool:
	s.h = _d(rng, 50, 800)
	s.x = _d(rng, 50, 800)
	var d := rad_to_deg(atan(s.h.to_float() / s.x.to_float()))
	return d > 12.0 and d < 68.0 and absf(d - 45.0) > 6.0


## A small angle from a tower to something far out: the sketch is not to scale.
static func _sighting(rng: Seeded, s: Dictionary) -> bool:
	s.form = "deg"
	s.e = Q.new(rng.int_in(10, 60), 10)
	s.h = Q.new(rng.int_in(20, 120))
	s.v1 = rng.int_in(12, 60)
	return s.h.to_float() / tan(BearingsViews.elev(s)) / 1000.0 / float(s.v1) * 60.0 > 1.5


static func _route(rng: Seeded, s: Dictionary) -> bool:
	s.d1 = _d(rng, 30, 150)
	s.d2 = _d(rng, 50, 400)
	s.v1 = rng.int_in(8, 25)
	s.v2 = rng.int_in(30, 70)
	s.which = "direct" if rng.chance(0.5) else "legs"
	return true


## Triangle ABD, joined along BD to triangle BCD on its far side.
static func _two_triangles(rng: Seeded, s: Dictionary) -> bool:
	s.ab = _d(rng, 40, 200)
	s.ad = _d(rng, 40, 200)
	s.bc = _d(rng, 40, 200)
	s.a_angle = 90 if s.ask == "shared-side" else rng.int_in(50, 130)
	s.dbc = rng.int_in(30, 110)
	if s.ask == "quadrilateral-area" and absi(s.a_angle - 90) < 8:
		return false
	return absi(s.dbc - 90) >= 8 and BearingsViews.bd(s) < 30.0


static func _split(rng: Seeded, s: Dictionary) -> bool:
	s.d1 = _d(rng, 60, 300)
	s.d2 = _d(rng, 40, 250)
	s.phi = rng.int_in(25, 78)
	return s.d2.to_float() * cos(deg_to_rad(s.phi)) < s.d1.to_float() - 1.0


static func _rule(rng: Seeded, s: Dictionary) -> bool:
	s.rule = rng.pick(RULES)
	s.sides = [rng.int_in(4, 20), rng.int_in(4, 20), rng.int_in(4, 20)]
	s.phi = rng.int_in(25, 80)
	s.b1 = rng.int_in(25, 65)
	var a: int = s.sides[0]
	var b: int = s.sides[1]
	var c: int = s.sides[2]
	return a != b and b != c and a != c and a + b > c + 2 and a + c > b + 2 and b + c > a + 2


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
