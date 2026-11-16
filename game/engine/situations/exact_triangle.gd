class_name ExactTriangleSituation
extends RefCounted
## The `exact-triangle` situation (curriculum/question-types.json): a triangle ABC whose angle has an
## exact sine and cosine, for t3-ext-exact-triangle (FAL-778). Every question is Paper 1 and exact.
##
## Sides are named as usual: a = BC opposite A, b = CA opposite B, c = AB opposite C. By unknown:
##   exact-area, side-from-exact-area   a, b and the angle C between them (45°, 60°, 120°, 135°;
##                                      30° and 150° too for the side), with ab a multiple of 4 so
##                                      the area is whole times √r
##   exact-side                         a, b and C of 60° or 120°, with c² not a square
##   exact-cos                          three whole sides a, b, c, and cos C, not 0
##   exact-height                       the angle A (30°, 45°, 60°) and b = AC, even, with c = AB
##                                      long enough that the foot H of the height from C is on AB
## generate() returns ask, paper (1), a, b, c (c is c² for exact-side: "c2"), C, A and the exact
## results as [m (Q), r]: area, side (c = m√r), cos, h.

const TRIES := 4000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "exact-area")
	for t in TRIES:
		var s := {"ask": ask, "paper": 1, "a": rng.int_in(2, 12), "b": rng.int_in(2, 12), "c": 0, "C": 0, "A": 0, "c2": 0}
		if _fill(rng, s):
			return s
	push_error("ExactTriangleSituation: no clean situation for %s" % need)
	return {}


static func _fill(rng: Seeded, s: Dictionary) -> bool:
	var a: int = s.a
	var b: int = s.b
	match s.ask:
		"exact-area", "side-from-exact-area":
			s.C = [45, 60, 60, 120, 135][rng.int_in(0, 4)] if s.ask == "exact-area" else rng.pick([30, 60, 120, 150, 45, 135])
			if (a * b) % 4 != 0 or a == b:
				return false
			if s.ask == "side-from-exact-area" and b % 2 != 0:
				return false
			s.area = [Q.new(a * b, 4), sin_of(s.C)[1]]
		"exact-side":
			s.C = 120 if rng.chance(0.6) else 60
			var c2 := a * a + b * b + (a * b if s.C == 120 else -a * b)
			if a == b or is_square(c2) or (a * b) % 2 != 0:
				return false
			s.c2 = c2
			s.side = simplify(c2)
		"exact-cos":
			var c := rng.int_in(2, 12)
			if a + b <= c or a + c <= b or b + c <= a or a == b or b == c or a == c:
				return false
			s.c = c
			var top := a * a + b * b - c * c
			if top == 0:
				return false
			s.cos = [Q.new(top, 2 * a * b), 1]
			var other := Q.new(b * b + c * c - a * a, 2 * b * c)
			var mine: Q = s.cos[0]
			# The tagged slips must give values different from the answer and from each other.
			if other.eq(mine) or other.eq(mine.neg()) or mine.mul(2).eq(other) or mine.mul(2).eq(mine.neg()):
				return false
		"exact-height":
			s.A = [30, 45, 60, 60][rng.int_in(0, 3)]
			if b % 2 != 0:
				return false
			# The foot of the height is on AB: AB is longer than AH = b cos A.
			s.c = rng.int_in(ceili(b * cos(deg_to_rad(s.A))) + 1, ceili(b * cos(deg_to_rad(s.A))) + 6)
			s.h = [Q.new(b, 2), sin_of(s.A)[1]]
	return true


## sin and cos of the exact angles as [m, r]: m√r.
static func sin_of(deg: int) -> Array:
	return {30: [Q.new(1, 2), 1], 45: [Q.new(1, 2), 2], 60: [Q.new(1, 2), 3], 120: [Q.new(1, 2), 3], 135: [Q.new(1, 2), 2], 150: [Q.new(1, 2), 1]}[deg]


static func cos_of(deg: int) -> Array:
	return {30: [Q.new(1, 2), 3], 45: [Q.new(1, 2), 2], 60: [Q.new(1, 2), 1], 120: [Q.new(-1, 2), 1], 135: [Q.new(-1, 2), 2], 150: [Q.new(-1, 2), 3]}[deg]


static func is_square(n: int) -> bool:
	var r := int(round(sqrt(float(n))))
	return r * r == n


## √n as m√r with r square-free.
static func simplify(n: int) -> Array:
	var m := 1
	var r := n
	var k := 2
	while k * k <= r:
		while r % (k * k) == 0:
			r /= k * k
			m *= k
		k += 1
	return [Q.new(m), r]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
