class_name ExactTrigSituation
extends RefCounted
## The `exact-trig` situation (curriculum/question-types.json): one or two landmark angles, or a
## point on the unit circle, for t3-exact-values (FAL-727). Every question is Paper 1, as every
## bank part is. An angle t is a Q, the multiple of π, and `form` says how it is written:
## "pi" (5π/6) or "deg" (150°).
##
## need.ask is the unknown (see ExactTrigViews). generate() returns a Dictionary:
##   paper, ask, rep
##   fn, t, form       the ratio and the angle
##   k                 the number in front of the ratio (scaled-value)
##   fn2, t2, plus     the second term of a sum, and whether it is added
##   rule              the related angle: "pi-minus", "pi-plus" or "minus" (given-related)
##   g, n              the given ratio, g/n, of an acute θ (given-related)
##   x, y              a point on the unit circle: Qs (ratio-from-point, tan-from-point)
##   q                 the quadrant (sign-in-quadrant)

const TRIES := 400
const SPECIAL := [[0, 1], [1, 6], [1, 4], [1, 3], [1, 2]]
const ACUTE := [[1, 6], [1, 4], [1, 3]]
## Angles past the first quadrant, on the first turn, then negative or on the second turn.
const ROUND := [[2, 3], [3, 4], [5, 6], [7, 6], [5, 4], [4, 3], [5, 3], [7, 4], [11, 6]]
const FAR := [[-1, 6], [-1, 4], [-1, 3], [-2, 3], [-3, 4], [-5, 6], [13, 6], [9, 4], [7, 3]]
const TRIPLES := [[3, 4, 5], [5, 12, 13], [8, 15, 17], [7, 24, 25], [20, 21, 29]]
const GIVEN := [[1, 3], [2, 3], [1, 4], [3, 4], [2, 5], [3, 5], [1, 5], [4, 5], [2, 7], [3, 7], [5, 7], [5, 8], [3, 8]]
const RULES := {"pi-minus": ["sin", "cos", "tan"], "pi-plus": ["sin", "cos", "tan"], "minus": ["sin", "cos"]}
const UNDEFINED := [[1, 2], [3, 2], [-1, 2], [5, 2]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "special-value")
	var rep: String = need.get("rep", "equation")
	for i in TRIES:
		var s := {"paper": 1, "ask": ask, "rep": rep, "form": "pi"}
		if new().call("_" + ask.replace("-", "_"), rng, s):
			return s
	return {}


static func _q(p: Array) -> Q:
	return Q.new(p[0], p[1])


static func _pick(rng: Seeded, list: Array) -> Q:
	return _q(rng.pick(list))


static func _special_value(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(TrigKit.FNS)
	s.t = _pick(rng, ACUTE if s.rep == "diagram" else SPECIAL)
	s.form = "pi" if s.rep != "equation" or rng.chance(0.6) else "deg"
	return not TrigKit.of(s.fn, s.t).is_empty()


static func _scaled_value(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(["sin", "cos"])
	s.t = _pick(rng, ACUTE)
	s.k = rng.int_in(2, 12)
	return true


static func _special_sum(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(TrigKit.FNS)
	s.t = _pick(rng, ACUTE)
	s.fn2 = rng.pick(TrigKit.FNS)
	s.t2 = _pick(rng, ACUTE)
	s.plus = rng.chance(0.7)
	s.first = rng.int_in(1, 3)
	return not ExactTrigViews.special_sum(s).is_empty()


static func _related_value(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(["sin", "cos"] if s.rep == "graph" else TrigKit.FNS)
	s.t = _pick(rng, ROUND if s.rep == "graph" else ROUND + FAR)
	return true


static func _related_sum(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(TrigKit.FNS)
	s.t = _pick(rng, ROUND)
	s.fn2 = rng.pick(TrigKit.FNS)
	s.t2 = _pick(rng, ROUND)
	s.plus = true
	return s.t2.key() != s.t.key() and not TrigKit.plus(TrigKit.of(s.fn, s.t), TrigKit.of(s.fn2, s.t2)).is_empty()


static func _given_related(rng: Seeded, s: Dictionary) -> bool:
	var g: Array = rng.pick(GIVEN)
	s.g = g[0]
	s.n = g[1]
	s.rule = "pi-minus" if s.rep == "diagram" else rng.pick(RULES.keys())
	s.fn = "sin" if s.rep == "diagram" else rng.pick(RULES[s.rule])
	return true


static func _point_at_angle(rng: Seeded, s: Dictionary) -> bool:
	s.t = _pick(rng, ACUTE + ROUND)
	return true


static func _ratio_from_point(rng: Seeded, s: Dictionary) -> bool:
	_point(rng, s)
	s.fn = rng.pick(["sin", "cos"])
	return true


static func _tan_from_point(rng: Seeded, s: Dictionary) -> bool:
	_point(rng, s)
	return true


static func _point(rng: Seeded, s: Dictionary) -> void:
	var t: Array = rng.pick(TRIPLES)
	var a: int = t[0]
	var b: int = t[1]
	if rng.chance(0.5):
		a = t[1]
		b = t[0]
	s.x = Q.new(a * (1 if rng.chance(0.5) else -1), t[2])
	s.y = Q.new(b * (1 if rng.chance(0.5) else -1), t[2])


static func _sign_in_quadrant(rng: Seeded, s: Dictionary) -> bool:
	s.q = rng.int_in(1, 4)
	var pair: Array = rng.pick([["sin", "cos"], ["cos", "tan"], ["sin", "tan"]])
	s.fn = pair[0]
	s.fn2 = pair[1]
	return true


static func _tan_undefined(rng: Seeded, s: Dictionary) -> bool:
	s.t = _pick(rng, UNDEFINED.slice(0, 2) if s.rep == "graph" else UNDEFINED)
	return true


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
