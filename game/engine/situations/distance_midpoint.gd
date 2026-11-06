class_name DistanceMidpointSituation
extends RefCounted
## The `distance-midpoint` situation (curriculum/question-types.json): points in 2D or 3D, for
## t3-distance-midpoint (FAL-751). The points are drawn first and everything is worked out of them
## with whole numbers or Q, so a length is the root of a whole number and a midpoint is exact.
##
## need.ask is the unknown (see DistanceMidpointViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx (a story, an index into the views' lists)
##   dim       2 or 3
##   A, B      arrays of Q: the two points the unknown turns on (for a missing endpoint, B is found)
##   M         array of Q: the midpoint or centre, for the midpoint unknowns
##   C         array of Q: the third vertex (show-isosceles)
##   names     the letters of A and B as the question calls them
##   sq        int: the square of the distance between A and B
##   shape     radius and centre unknowns: "sphere", "hemisphere" or "circle"; origin-to-curve: "x", "x2", "x3"
##   turn      degrees round the figure's circle, where the point on the surface is drawn
##   mode      pyramid-edge: "upright" (rectangular base OABC on the axes), "height" or "edge"
##   a, b, h   pyramid-edge upright: half the base edges, and the height
##   apex      show-isosceles: the index of the vertex where the equal sides meet; top is the third side squared
##   axis, p, t, top  find-k: which coordinate of B is k, A's value there, (k − p)² = t, and AB² = top
##   ca, cb    origin-to-curve: the numbers in f(x)²
##
## Paper 1 is whole numbers and exact answers. Paper 2 has a length that needs rounding, clear of a
## rounding edge, and a midpoint or an endpoint from coordinates to 1 d.p. The bank's points, and
## the skill's worked examples, are left out (see BANK). The clean limits are the numbers behind
## the catalogue's `clean` text. The checker holds its own copy.

const TRIES := 6000
const CONTEXTS := 6
const EDGE := 0.03
## The largest size of a coordinate, and of one difference.
const REACH := 15
const STEP := 9
const STEP_P2 := 12
## A length that comes out whole, this share of the time on Paper 1.
const WHOLE := 0.35
const TRIPLES := [[3, 4], [6, 8], [5, 12], [8, 6]]
const QUADS := [[1, 2, 2], [2, 3, 6], [1, 4, 8], [4, 4, 7], [2, 6, 9], [6, 6, 7], [2, 4, 4], [3, 6, 6], [4, 6, 12], [3, 4, 12], [2, 5, 14], [2, 10, 11], [8, 9, 12]]
## Pairs of points from the bank's parts and the skill's examples.
const BANK := [[[8, 6, 0], [4, 3, 10]], [[8, 0, 0], [4, 3, 10]], [[6, 8, 0], [3, 4, 9]], [[6, 0, 0], [3, 4, 9]], [[1, 5, 0], [-1, 1, 6]],
	[[1, 7, 0], [-3, 4, 2]], [[6, -1, -3], [4, -5, -9]], [[1, 4, 0], [-3, 2, -4]], [[1, -2, 3], [4, 2, 15]], [[2, 5, -1], [6, 3, 4]]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	for i in TRIES:
		var s := {"paper": int(need.get("paper", 1)), "ask": need.get("ask", "distance-two-points"), "rep": need.get("rep", "equation"),
			"ctx": rng.int_in(0, CONTEXTS - 1), "dim": 3, "A": [], "B": [], "M": [], "C": [], "names": ["A", "B"], "sq": 0, "shape": "",
			"turn": rng.int_in(0, 359), "mode": "", "a": 0, "b": 0, "h": 0, "apex": 0, "axis": 0, "p": 0, "t": 0, "top": 0, "ca": 0, "cb": 0}
		if _draw(rng, s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"distance-two-points":
			return _pair(rng, s, 3)
		"distance-2d":
			return _pair(rng, s, 2)
		"find-k-two-values":
			return _find_k(rng, s, true)
		"find-k-surd":
			return _find_k(rng, s, false)
		"show-isosceles":
			return _isosceles(rng, s)
		"space-diagonal":
			return _cuboid(rng, s)
		"pyramid-edge":
			return _pyramid(rng, s)
		"radius-from-centre":
			s.shape = "sphere" if rng.chance(0.5) else "hemisphere"
			s.names = ["C", "P"]
			s.turn = rng.int_in(200, 340) if s.shape == "hemisphere" else s.turn
			return _pair(rng, s, 3)
		"radius-from-diameter":
			s.shape = "sphere" if rng.chance(0.5) else "circle"
			return _pair(rng, s, 3, s.paper == 1)
		"origin-to-curve":
			s.shape = rng.pick(["x", "x2", "x3"])
			s.ca = rng.int_in(2, 9)
			s.cb = rng.int_in(2, 12)
			return true
		"midpoint-3d":
			return _segment(rng, s, 3)
		"midpoint-2d":
			return _segment(rng, s, 2)
		"centre-from-diameter":
			s.shape = "sphere" if rng.chance(0.5) else "circle"
			s.names = ["A", "B"]
			return _segment(rng, s, 3)
		"missing-endpoint":
			return _endpoint(rng, s, 3)
		"missing-endpoint-2d":
			return _endpoint(rng, s, 2)
	return false


# ── Numbers ──────────────────────────────────────────────────

## The whole square root of n, or -1.
static func root_of(n: int) -> int:
	var r := roundi(sqrt(float(n)))
	return r if r * r == n else -1


## √n as [m, r] with r as small as it goes: 72 is [6, 2], and 49 is [7, 1].
static func surd(n: int) -> Array:
	var m := 1
	var r := n
	var f := 2
	while f * f <= r:
		while r % (f * f) == 0:
			r /= f * f
			m *= f
		f += 1
	return [m, r]


static func ints(v: Array) -> Array:
	return v.map(func(e): return Q.new(e))


static func plus(a: Array, b: Array) -> Array:
	var out: Array = []
	for i in a.size():
		out.append(a[i].add(b[i]))
	return out


static func minus(a: Array, b: Array) -> Array:
	var out: Array = []
	for i in a.size():
		out.append(a[i].sub(b[i]))
	return out


static func times(a: Array, k: Variant) -> Array:
	return a.map(func(e): return e.mul(k))


## The squares of the coordinates added up, for whole coordinates.
static func norm(a: Array) -> int:
	var t := Q.new(0)
	for e in a:
		t = t.add(e.sq())
	return t.n


static func midpoint(a: Array, b: Array) -> Array:
	return times(plus(a, b), Q.new(1, 2))


## Whether the two points, either way round, are a pair from the bank.
static func from_bank(a: Array, b: Array) -> bool:
	var p: Array = a.map(func(e): return e.n if e.is_int() else 1000)
	var q: Array = b.map(func(e): return e.n if e.is_int() else 1000)
	for pair in BANK:
		if (pair[0] == p and pair[1] == q) or (pair[0] == q and pair[1] == p):
			return true
	return false


## Some coordinate changes sign between the points, so a minus sign matters.
static func crosses(a: Array, b: Array) -> bool:
	for i in a.size():
		if a[i].sign() * b[i].sign() < 0:
			return true
	return false


## The points differ in every coordinate, so no move along an axis is 0.
static func moves_on_every_axis(a: Array, b: Array) -> bool:
	for i in a.size():
		if a[i].eq(b[i]):
			return false
	return true


static func in_reach(a: Array, reach: int = REACH) -> bool:
	return a.all(func(e): return e.abs_q().to_float() <= reach)


## A length a Paper 2 answer can show to 3 s.f.: not whole, and clear of a rounding edge.
static func clear_length(sq: int) -> bool:
	return root_of(sq) < 0 and Answer.rounds_clearly(sqrt(float(sq)), EDGE)


static func _moves(rng: Seeded, dim: int, whole: bool, even: bool, reach: int) -> Array:
	var out: Array = []
	if whole:
		var base: Array = rng.shuffled(rng.pick(QUADS if dim == 3 else TRIPLES).duplicate())
		for v in base:
			out.append(v if rng.chance(0.5) else -v)
	else:
		for i in dim:
			out.append(ExtensionViews.nonzero(rng, -reach, reach))
	if not even:
		return out
	# Even moves, so a diameter's centre is whole: the whole lengths doubled, the others rounded to 2.
	return out.map(func(v): return v * 2 if whole else (v / 2 if absi(v) > 1 else v) * 2)


static func _whole_point(rng: Seeded, dim: int, reach: int) -> Array:
	var out: Array = []
	for i in dim:
		out.append(Q.new(rng.int_in(-reach, reach)))
	return out


# ── Two points and a length ──────────────────────────────────

static func _pair(rng: Seeded, s: Dictionary, dim: int, even: bool = false) -> bool:
	s.dim = dim
	var reach: int = STEP if s.paper == 1 else STEP_P2
	var d := _moves(rng, dim, s.paper == 1 and rng.chance(WHOLE), even, reach)
	s.A = _whole_point(rng, dim, 9)
	s.B = plus(s.A, ints(d))
	s.sq = norm(ints(d))
	if not in_reach(s.B) or not crosses(s.A, s.B) or from_bank(s.A, s.B):
		return false
	if s.ask == "radius-from-diameter" and s.paper == 2:
		return clear_length(s.sq) and Answer.rounds_clearly(sqrt(float(s.sq)) / 2.0, EDGE)
	return s.paper == 1 or clear_length(s.sq)


static func _find_k(rng: Seeded, s: Dictionary, whole: bool) -> bool:
	s.axis = rng.int_in(0, 2)
	s.A = _whole_point(rng, 3, 9)
	s.B = plus(s.A, ints([ExtensionViews.nonzero(rng, -7, 7), ExtensionViews.nonzero(rng, -7, 7), ExtensionViews.nonzero(rng, -7, 7)]))
	s.p = s.A[s.axis].n
	if s.p == 0 or not in_reach(s.B):
		return false
	var rest := 0
	for i in 3:
		if i != s.axis:
			rest += s.A[i].sub(s.B[i]).sq().n
	if whole:
		s.t = rng.int_in(1, 9) ** 2
	else:
		var d := roundi(sqrt(float(rest))) + rng.int_in(1, 4)
		s.t = d * d - rest
		if root_of(s.t) >= 0 or s.t < 2:
			return false
		var p2: float = sqrt(float(s.t))
		if s.paper == 2 and not (Answer.rounds_clearly(s.p + p2, EDGE) and Answer.rounds_clearly(s.p - p2, EDGE)):
			return false
	s.top = rest + s.t
	s.sq = s.top
	return not from_bank(s.A, s.B) and (root_of(s.top) >= 0 or surd(s.top)[0] == 1)


static func _isosceles(rng: Seeded, s: Dictionary) -> bool:
	var v: Array = [ExtensionViews.nonzero(rng, -6, 6), ExtensionViews.nonzero(rng, -6, 6), ExtensionViews.nonzero(rng, -6, 6)]
	var n := norm(ints(v))
	if surd(n)[0] != 1:
		return false
	# Another move of the same length: a different mix of squares where there is one.
	var others: Array = []
	for x in range(-6, 7):
		for y in range(-6, 7):
			for z in range(-6, 7):
				if x * x + y * y + z * z == n:
					others.append([x, y, z])
	var w: Array = rng.pick(others)
	var third := norm(minus(ints(v), ints(w)))
	if third == 0 or third == n or third == 4 * n:
		return false
	var apex := _whole_point(rng, 3, 7)
	var one := plus(apex, ints(v))
	var two := plus(apex, ints(w))
	if not in_reach(one) or not in_reach(two):
		return false
	if not (crosses(apex, one) or crosses(apex, two) or crosses(one, two)):
		return false
	s.apex = rng.int_in(0, 2)
	var order: Array = [[apex, one, two], [one, apex, two], [one, two, apex]][s.apex]
	s.A = order[0]
	s.B = order[1]
	s.C = order[2]
	s.sq = n
	s.top = third
	return true


static func _cuboid(rng: Seeded, s: Dictionary) -> bool:
	s.names = ["O", "G"]
	var e: Array = []
	if s.paper == 1 and rng.chance(WHOLE):
		e = rng.shuffled(rng.pick(QUADS).duplicate())
	else:
		e = [rng.int_in(2, 12), rng.int_in(2, 12), rng.int_in(2, 12)]
	s.A = ints([0, 0, 0])
	s.B = ints(e)
	s.sq = norm(s.B)
	if e[0] == e[1] or e[1] == e[2] or e[0] == e[2]:
		return false
	return s.paper == 1 or clear_length(s.sq)


static func _pyramid(rng: Seeded, s: Dictionary) -> bool:
	if s.rep == "diagram" or rng.chance(0.5):
		s.mode = "upright"
		s.a = rng.int_in(2, 7)
		s.b = rng.int_in(2, 7)
		s.h = rng.int_in(3, 14)
		if s.a == s.b:
			return false
		var corner: Array = rng.pick([["A", [0, 2 * s.b, 0]], ["B", [2 * s.a, 2 * s.b, 0]], ["C", [2 * s.a, 0, 0]]])
		s.names = [corner[0], "V"]
		s.A = ints(corner[1])
		s.B = ints([s.a, s.b, s.h])
		s.sq = norm(minus(s.A, s.B))
		if from_bank(s.A, s.B):
			return false
		return s.paper == 1 or clear_length(s.sq)
	s.mode = "height" if rng.chance(0.5) else "edge"
	s.names = ["V", "X"] if s.mode == "height" else ["A", "V"]
	return _pair(rng, s, 3)


# ── Midpoints and endpoints ──────────────────────────────────

## A coordinate: whole on Paper 1, to 1 d.p. on Paper 2.
static func _coordinate(rng: Seeded, s: Dictionary) -> Q:
	return Q.new(rng.int_in(-9, 9)) if s.paper == 1 else Q.new(rng.int_in(-120, 120), 10)


static func _point(rng: Seeded, s: Dictionary, dim: int) -> Array:
	var out: Array = []
	for i in dim:
		out.append(_coordinate(rng, s))
	return out


static func _segment(rng: Seeded, s: Dictionary, dim: int) -> bool:
	s.dim = dim
	s.A = _point(rng, s, dim)
	s.B = _point(rng, s, dim)
	s.M = midpoint(s.A, s.B)
	return moves_on_every_axis(s.A, s.B) and crosses(s.A, s.B) and not from_bank(s.A, s.B)


static func _endpoint(rng: Seeded, s: Dictionary, dim: int) -> bool:
	s.dim = dim
	s.A = _point(rng, s, dim)
	s.M = _point(rng, s, dim)
	s.B = minus(times(s.M, 2), s.A)
	return in_reach(s.B, 30) and moves_on_every_axis(s.A, s.M) and crosses(s.A, s.M) and not from_bank(s.A, s.M) and not from_bank(s.M, s.A)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
