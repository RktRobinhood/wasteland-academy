class_name RightTriangleSituation
extends RefCounted
## The `right-triangle` situation (curriculum/question-types.json): one right-angled triangle, or a
## side view built from one (FAL-739). Sides are whole numbers or 1 d.p., angles are whole degrees
## or radians to 2 d.p., and everything else is worked out from them by the views.
##
## need.ask is the unknown (see RightTriangleViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx (a story, an index into the views' lists)
##   names       [T, R, O]: the vertex with θ, the right angle, the third vertex
##   spin, flip  how the sketch is turned: degrees, and +1 or -1 for which way O lies
##   fn          "sin", "cos" or "tan": the ratio the question turns on
##   mode        which sides are given and asked, where an unknown has more than one case
##   a, b, c     Q: the opposite side, the adjacent side and the hypotenuse, as far as given
##   e, form     Q and "deg" or "rad": an angle
##   e2          Q: a second angle (two sightings)
##   p, q        ints: a gradient p/q in lowest terms
##   k           the scale of a special triangle
##   h, x, l     Q: a height, a horizontal distance, a slanting length
##   d, r        Q: a distance from a centre, a radius
##   w, eye      Q: a walked distance, or a clearance; an observer's eye height
##   phi         int: the angle between two lines of sight
##   span, over, t  Q: the level span, the overhang and the thickness of a sloping beam
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 6000
const EDGE := 0.03
const CONTEXTS := 6
const TRIPLES := [[3, 4, 5], [5, 12, 13], [8, 15, 17], [7, 24, 25], [20, 21, 29], [9, 40, 41]]
## No N: a sketch reads an arc from "N" as a bearing.
const LETTERS := ["ABC", "PQR", "KLM", "XYZ", "DEF", "UVW"]
const SPINS := [0, 25, 50, 75, 100, 130, 155, 180, 205, 235, 260, 285, 310, 335]
const FNS := ["sin", "cos", "tan"]
## An angle stays this far from 45°, so that it and the other acute angle read differently.
const AWAY := 5


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "ratio-from-sides")
	for i in TRIES:
		var s := _base(rng, ask, need)
		var ok := false
		match ask:
			"ratio-from-sides":
				ok = _triple(rng, s)
			"ratio-needs-pythagoras":
				ok = _legs(rng, s)
			"ratio-in-letters":
				ok = _letters(rng, s)
			"side-in-letters":
				s.fn = rng.pick(["sin", "cos"])
				s.e = Q.new(rng.int_in(28, 62))
				ok = absi(s.e.n - 45) >= AWAY
			"side-from-angle":
				ok = _side(rng, s, rng.pick(["sin", "cos", "tan"]))
			"side-under-ratio":
				ok = _side(rng, s, rng.pick(["sin", "cos"]))
			"side-either-angle":
				ok = _side(rng, s, "tan")
			"chord-length":
				ok = _chord(rng, s)
			"side-special":
				ok = _special_side(rng, s)
			"angle-from-sides":
				ok = _angle(rng, s)
			"angle-special":
				_special_angle(rng, s)
				ok = true
			"gradient-from-angle":
				s.e = Q.new(rng.int_in(8, 50))
				ok = absi(s.e.n - 45) >= AWAY
			"angle-from-gradient", "angle-with-vertical":
				ok = _gradient(rng, s)
			"edge-from-span", "upper-edge":
				ok = _beam(rng, s)
			"height-from-angle":
				ok = _sight(rng, s)
			"elevation-after-walk":
				ok = _walk(rng, s)
			"equal-elevations":
				ok = _two_towers(rng, s)
			"cone-from-eye-level":
				ok = _cone(rng, s)
			"depression-sight-line":
				s.h = _len(rng, 50, 800)
				s.e = Q.new(rng.int_in(14, 70))
				ok = absi(s.e.n - 45) >= AWAY
			"depression-from-sight-line":
				ok = _depression(rng, s)
			"depression-two-points":
				ok = _two_points(rng, s)
			"name-the-angle":
				s.mode = rng.pick(["depression", "elevation"])
				s.e = Q.new(rng.int_in(25, 60))
				ok = true
		if ok and clear(s):
			return s
	return {}


static func _base(rng: Seeded, ask: String, need: Dictionary) -> Dictionary:
	var word: String = rng.pick(LETTERS)
	var order: Array = rng.shuffled([word[0], word[1], word[2]])
	return {"paper": int(need.get("paper", 2)), "ask": ask, "rep": need.get("rep", "words"), "ctx": rng.int_in(0, CONTEXTS - 1),
		"names": order, "spin": rng.pick(SPINS), "flip": 1 if rng.chance(0.5) else -1, "fn": "", "mode": "", "form": "deg"}


## Every value offered is clear of a rounding edge.
static func clear(s: Dictionary) -> bool:
	var out: Dictionary = RightTriangleViews.new().build(s.ask, s.rep, s, null)
	if out.answer.kind != "number":
		return true
	var vs: Array = [out.answer.values.v]
	for w in out.wrongs:
		vs.append(w.values.v)
	for g in out.generic:
		vs.append(g.v)
	return vs.all(func(v): return v.to_float() <= 0.0 or Answer.rounds_clearly(v.to_float(), EDGE))


static func _len(rng: Seeded, lo: int, hi: int) -> Q:
	return Q.new(rng.int_in(lo, hi), 10)


static func _triple(rng: Seeded, s: Dictionary) -> bool:
	var t: Array = rng.pick(TRIPLES)
	var k := rng.int_in(1, 3)
	var swap := rng.chance(0.5)
	s.a = Q.new((t[1] if swap else t[0]) * k)
	s.b = Q.new((t[0] if swap else t[1]) * k)
	s.c = Q.new(t[2] * k)
	s.fn = rng.pick(FNS)
	return s.c.n <= 60


static func _legs(rng: Seeded, s: Dictionary) -> bool:
	var a := rng.int_in(1, 9)
	var b := rng.int_in(1, 9)
	var n := a * a + b * b
	var root := roundi(sqrt(float(n)))
	s.a = Q.new(a)
	s.b = Q.new(b)
	s.fn = rng.pick(["sin", "cos"])
	return a != b and root * root != n


static func _letters(rng: Seeded, s: Dictionary) -> bool:
	var ok := _triple(rng, s)
	s.sides = rng.shuffled(["p", "q", "r"])
	return ok


static func _side(rng: Seeded, s: Dictionary, fn: String) -> bool:
	s.fn = fn
	s.e = Q.new(rng.int_in(12, 75))
	s.x = _len(rng, 20, 400)
	return absi(s.e.n - 45) >= AWAY


static func _chord(rng: Seeded, s: Dictionary) -> bool:
	s.r = Q.new(rng.int_in(12, 90))
	s.d = Q.new(rng.int_in(5, 80))
	return s.d.n * 10 >= s.r.n * 3 and s.d.n * 10 <= s.r.n * 8


static func _special_side(rng: Seeded, s: Dictionary) -> bool:
	s.mode = rng.pick(["leg", "hyp"])
	s.e = Q.new(rng.pick([30, 45, 60]))
	s.fn = rng.pick(["sin", "cos"])
	# Leg: the even hypotenuse. Hyp: a leg that divides by the surd cleanly.
	s.k = rng.int_in(2, 12) * 2 if s.mode == "leg" else rng.int_in(1, 6) * (3 if s.e.n != 45 else 2)
	return true


## sin or cos: a over the hypotenuse b. tan: a over b, the two shorter sides.
static func _angle(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(FNS)
	s.a = _len(rng, 20, 400)
	s.b = _len(rng, 20, 400)
	var r: float = s.a.to_float() / s.b.to_float()
	if s.fn != "tan" and r >= 1.0:
		return false
	var v: float
	match s.fn:
		"sin":
			v = asin(r)
		"cos":
			v = acos(r)
		_:
			v = atan(r)
	v = rad_to_deg(v)
	return v > 12.0 and v < 75.0 and absf(v - 45.0) >= float(AWAY)


static func _special_angle(rng: Seeded, s: Dictionary) -> void:
	s.e = Q.new(rng.pick([30, 45, 60]))
	s.fn = rng.pick(FNS)
	s.k = rng.int_in(2, 9)


static func _gradient(rng: Seeded, s: Dictionary) -> bool:
	s.p = rng.int_in(1, 15)
	s.q = rng.int_in(2, 20)
	var a: int = s.p
	var b: int = s.q
	while b != 0:
		var t := a % b
		a = b
		b = t
	var deg := rad_to_deg(atan(float(s.p) / float(s.q)))
	return a == 1 and deg > 10.0 and deg < 60.0 and absf(deg - 45.0) >= float(AWAY)


static func _beam(rng: Seeded, s: Dictionary) -> bool:
	if not _gradient(rng, s):
		return false
	s.span = _len(rng, 30, 120)
	s.over = Q.new(rng.int_in(4, 15), 10)
	s.t = Q.new(rng.int_in(2, 6), 10)
	return float(s.p) / float(s.q) < 1.0


static func _pick_angle(rng: Seeded, s: Dictionary, chance_rad: float) -> void:
	s.form = "rad" if rng.chance(chance_rad) else "deg"
	s.e = Q.new(rng.int_in(25, 120), 100) if s.form == "rad" else Q.new(rng.int_in(14, 70))


static func _sight(rng: Seeded, s: Dictionary) -> bool:
	_pick_angle(rng, s, 0.5)
	s.x = _len(rng, 40, 300)
	return s.x.to_float() * tan(RightTriangleViews.elev(s)) < 60.0


static func _walk(rng: Seeded, s: Dictionary) -> bool:
	_pick_angle(rng, s, 0.5)
	s.x = Q.new(rng.int_in(10, 90))
	s.w = Q.new(rng.int_in(3, 60))
	var deg := rad_to_deg(RightTriangleViews.elev(s))
	return s.w.n * 10 >= s.x.n * 2 and s.w.n * 10 <= s.x.n * 7 and deg < 60.0


static func _two_towers(rng: Seeded, s: Dictionary) -> bool:
	s.phi = rng.int_in(40, 68) * 2
	s.l = _len(rng, 300, 1500)
	s.x = _len(rng, 200, 900)
	return s.phi != 90 and s.x.to_float() < s.l.to_float() - 5.0


static func _cone(rng: Seeded, s: Dictionary) -> bool:
	s.h = Q.new(rng.int_in(12, 40))
	s.eye = Q.new(rng.int_in(15, 19), 10)
	s.x = Q.new(rng.int_in(2, 12))
	s.e = Q.new(rng.int_in(30, 65))
	var out: float = (s.h.to_float() - s.eye.to_float()) / tan(deg_to_rad(s.e.to_float()))
	return out - s.x.to_float() > 3.0


static func _depression(rng: Seeded, s: Dictionary) -> bool:
	s.h = _len(rng, 50, 800)
	s.l = _len(rng, 100, 1500)
	if s.h.to_float() >= s.l.to_float():
		return false
	var deg := rad_to_deg(asin(s.h.to_float() / s.l.to_float()))
	return deg > 14.0 and deg < 70.0 and absf(deg - 45.0) >= float(AWAY)


static func _two_points(rng: Seeded, s: Dictionary) -> bool:
	s.h = _len(rng, 50, 800)
	s.e = Q.new(rng.int_in(32, 70))
	s.e2 = Q.new(rng.int_in(12, 40))
	return s.e.n - s.e2.n >= 8


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
