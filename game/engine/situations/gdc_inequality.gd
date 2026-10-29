class_name GdcInequalitySituation
extends RefCounted
## The `gdc-inequality` situation (curriculum/question-types.json): it extends
## gdc-two-curves with an inequality between the curves, f(x) > g(x) or f(x) < g(x),
## solved from where they cross (FAL-420). fn-ext-inequality-graphical is built on it.
##
## generate() returns gdc-two-curves' situation (two crossings) plus
##   rel     ">" or "<": the inequality f(x) rel g(x)
##   inside  whether its solution set is the interval between the crossings (else the two
##           pieces outside them, inside the domain)
## In the level mode (need.mode "level") f is a model a·te^(−kt) and g the level y = L,
## for 0 ≤ t ≤ T, and the set is the times f is above L.


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	# The stream's first draw leans low (FAL-460), so it is spent first.
	rng.int_in(0, 1)
	var s: Dictionary
	if need.get("mode", "") == "level":
		s = _level(rng)
	else:
		s = GdcTwoCurvesSituation.generate(rng, {"mode": "line", "crossings": 2})
	if s.is_empty():
		return {}
	var x0: float = s.crossings[0][0]
	var x1: float = s.crossings[1][0]
	var mid := (x0 + x1) / 2.0
	var f_above_mid: bool = GdcTwoCurvesSituation.h(s, mid) > 0.0
	if s.mode == "level":
		s.rel = ">"
	else:
		match need.get("set", "any"):
			"inside":
				s.rel = ">" if f_above_mid else "<"
			"outside":
				s.rel = "<" if f_above_mid else ">"
			_:
				s.rel = ">" if rng.chance(0.5) else "<"
	s.inside = (s.rel == ">") == f_above_mid
	s.paper = 2
	return s


static func _level(rng: Seeded) -> Dictionary:
	var C = GdcTwoCurvesSituation
	for i in 2000:
		var s := {"mode": "level", "var": "t", "d1": Q.new(0), "d2": Q.new(rng.int_in(8, 12))}
		var k: Q = C._pick(rng, [0.3, 0.4, 0.5])
		var a := Q.new(rng.int_in(4, 12))
		s.f = C.curve("texp", {"A": a, "k": k})
		var top: float = a.to_float() / k.to_float() / exp(1.0)
		s.g = C.line(Q.new(0), C.dq(snappedf(top * rng.int_in(4, 8) / 10.0, 0.1)))
		s.crossings = C.crossings(s, 1e-6, s.d2.to_float())
		if s.crossings.size() == 2 and s.crossings.all(func(c): return GdcKit.fair(c[0])) and s.crossings[1][0] < s.d2.to_float() - 0.3:
			s.ctx = {"kind": "drug"}
			return s
	return {}


static func export(s: Dictionary) -> Dictionary:
	return GdcTwoCurvesSituation.export(s)
