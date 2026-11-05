class_name LinkVectorsSituation
extends RefCounted
## The `fn-link-vectors` situation (curriculum/question-types.json): a vector picked first,
## then read as a graph translation, a vertex, a wave's shift, a line's direction, a step
## between two points in 3D or a time delay (FAL-424). All of it is Paper 1.
##
## generate() returns, by need.kind, with kind and paper:
##   "graph"   fam (sq, recip, exp, line; line has lm, ln: y = lm·x + ln), a, b, px, py (a point
##             on the graph), as Q
##   "vertex"  k (±1 to ±3), h, c, as Q
##   "line"    p, q (gradient p/q in lowest terms, q > 0, |p| ≠ q), n (y-intercept), x0, y0 (a
##             point on the line), as Q
##   "wave"    A, B, D, as Q, and E, the phase as a multiple of π (shift −E/B)
##   "3d"      ax, ay, az, sx, sy, sz (the whole step, even parts, a whole length len), neg
##             (the coordinate where A is negative and B positive), whole numbers
##   "delay"   dform ("sq" or "line"), dm, dn, d, whole numbers: s_A(t) = dm·t² or dm·t + dn
## tools/check_answers.py (check_link_vectors) reads them back from what the student sees.

const PARENTS := ["sq", "recip", "exp", "line"]
## Multiples of π that a wave can be moved by.
const SHIFTS := [[1, 6], [1, 4], [1, 3], [1, 2]]
## Steps with even parts and a whole length, as |Δx|, |Δy|, |Δz|, length.
const STEPS := [[2, 4, 4, 6], [4, 6, 12, 14], [4, 8, 8, 12], [2, 8, 16, 18], [12, 12, 6, 18], [8, 8, 14, 18]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var kind: String = need.get("kind", "graph")
	var s: Dictionary
	match kind:
		"vertex":
			s = _vertex(rng)
		"line":
			s = _line(rng)
		"wave":
			s = _wave(rng)
		"3d":
			s = _steps(rng)
		"delay":
			s = _delay(rng)
		_:
			s = _graph(rng, need.get("fams", PARENTS))
	if s.is_empty():
		return {}
	s.kind = kind
	s.paper = 1
	return s


static func _graph(rng: Seeded, fams: Array) -> Dictionary:
	var fam: String = rng.pick(fams)
	var s := {"fam": fam, "a": Q.new(ExtensionViews.nonzero(rng, -5, 5)), "b": Q.new(ExtensionViews.nonzero(rng, -5, 5))}
	var u := rng.int_in(-3, 3)
	match fam:
		"sq":
			u = ExtensionViews.nonzero(rng, -3, 3)
			s.px = Q.new(u)
			s.py = Q.new(u * u)
		"recip":
			u = 1 if rng.chance(0.5) else -1
			s.px = Q.new(u)
			s.py = Q.new(u)
		"exp":
			s.px = Q.new(0)
			s.py = Q.new(1)
		_:
			# A gradient of 1 would hide the vertical part put inside the bracket.
			var m: int = rng.pick([-3, -2, 2, 3])
			var n := ExtensionViews.nonzero(rng, -5, 5)
			s.lm = Q.new(m)
			s.ln = Q.new(n)
			s.px = Q.new(u)
			s.py = Q.new(m * u + n)
	return s


static func _vertex(rng: Seeded) -> Dictionary:
	var k := ExtensionViews.nonzero(rng, -3, 3)
	return {"k": Q.new(k), "h": Q.new(ExtensionViews.nonzero(rng, -5, 5)), "c": Q.new(ExtensionViews.nonzero(rng, -7, 7))}


static func _line(rng: Seeded) -> Dictionary:
	for i in 500:
		var p := ExtensionViews.nonzero(rng, -5, 5)
		var q := rng.int_in(2, 5)
		if Q.new(p, q).d != q or absi(p) == q:
			continue
		var n := ExtensionViews.nonzero(rng, -4, 4)
		var t := ExtensionViews.nonzero(rng, -1, 2)
		return {"p": Q.new(p), "q": Q.new(q), "n": Q.new(n), "x0": Q.new(t * q), "y0": Q.new(t * p + n)}
	return {}


static func _wave(rng: Seeded) -> Dictionary:
	# E = ±π would make the shifts ±E/B one period apart, so a sign slip wouldn't be wrong.
	var pick: Array = rng.pick(SHIFTS)
	var B: int = rng.pick([2, 3])
	while Q.new(pick[0] * B, pick[1]).eq(1):
		pick = rng.pick(SHIFTS)
	var sign := 1 if rng.chance(0.5) else -1
	return {"A": Q.new(rng.int_in(2, 4)), "B": Q.new(B), "D": Q.new(ExtensionViews.nonzero(rng, -4, 4)), "E": Q.new(sign * pick[0] * B, pick[1])}


static func _steps(rng: Seeded) -> Dictionary:
	var pick: Array = rng.pick(STEPS)
	var parts: Array = rng.shuffled(pick.slice(0, 3))
	var neg := rng.int_in(0, 2)
	# A's coordinate at neg is negative and B's positive, so the sign can be mishandled.
	parts[neg] = absi(parts[neg])
	for i in 3:
		if i != neg and rng.chance(0.5):
			parts[i] = -parts[i]
	var a: Array = [rng.int_in(-6, 6), rng.int_in(-6, 6), rng.int_in(-6, 6)]
	a[neg] = -rng.int_in(1, maxi(parts[neg] - 1, 1))
	return {"ax": a[0], "ay": a[1], "az": a[2], "sx": parts[0], "sy": parts[1], "sz": parts[2], "len": pick[3], "neg": neg}


static func _delay(rng: Seeded) -> Dictionary:
	var sq := rng.chance(0.5)
	return {"dform": "sq" if sq else "line", "dm": rng.int_in(1, 3) if sq else rng.int_in(2, 5), "dn": rng.int_in(1, 6), "d": rng.int_in(1, 5)}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
