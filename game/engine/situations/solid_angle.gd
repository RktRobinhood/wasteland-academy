class_name SolidAngleSituation
extends RefCounted
## The `solid-angle` situation (curriculum/question-types.json): one solid, or two or three
## points, and an angle in it, for t3-3d-angle (FAL-754). The lengths are drawn first, as whole
## numbers, and the angle is worked out of them.
##
## need.ask is the unknown (see SolidAngleViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx (a story, an index into the views' lists)
##   solid     "cuboid", "pyramid", "cone" or "points"
##   l, w, h   cuboid: AB, BC and AE; pyramid: AB, BC and the height VX; cone: h only
##   r, sl     cone: the base radius and the slant height (0 where it isn't a whole number)
##   given     cone: the two measures the question shows, "rh", "rl" or "hl"
##   edge      cuboid-two-diagonals and cuboid-diagonal-edge: "AB", "AD" or "AE", the edge of the
##             triangle that holds the angle; pyramid-face-base: the base edge M halves
##   corner    pyramid-edge-base: the corner of the slant edge, "A" to "D"
##   pair      pyramid-apex-angle: "AVB" or "BVC" (next to each other) or "AVC" (across the base)
##   A, B, C   the points, arrays of three ints, where the solid is "points"
##   right     coords-right-angle: "A" or "C", where the right angle is
##   shape     landmark-angle: "cone-rl", "cone-hl", "cone-rh", "cuboid" or "pyramid"
##   theta     the angle asked, in degrees (a float; whole on Paper 1)
##
## Paper 2 (every cell but landmark-angle): the angle needs rounding, is clear of a rounding edge
## and of a right angle, and isn't a landmark. Paper 1 (landmark-angle only): the lengths make
## the angle 30°, 45° or 60° exactly. The bank's solids and points are left out (see BANK). The
## clean limits are the numbers behind the catalogue's `clean` text. The checker holds its own copy.

const TRIES := 6000
const CONTEXTS := 6
const EDGE := 0.03
## A Paper 2 line-plane angle stays between these, and a two-lines angle between the wider pair.
const LOW := 12.0
const HIGH := 78.0
const WIDE_LOW := 20.0
const WIDE_HIGH := 160.0
## How far an angle stays from 90°, and from 30°, 45° and 60°, on Paper 2.
const RIGHT_GAP := 4.0
const LANDMARK_GAP := 0.5
const LONGEST := 15
## The unknowns whose angle is between two lines.
const TWO_LINES := ["cuboid-two-diagonals", "pyramid-apex-angle", "cuboid-diagonal-edge", "coords-angle-abc", "coords-right-angle"]
## Pythagorean bases for a cuboid on Paper 1: [l, w, diagonal].
const TRIPLES := [[3, 4, 5], [6, 8, 10], [5, 12, 13], [8, 6, 10], [4, 3, 5], [9, 12, 15]]
## The bank's pyramid (its base corner and vertex on axes) and the points of the skill's examples.
const BANK := [[8, 6, 10], [6, 8, 10], [6, 8, 9], [8, 6, 9]]
const BANK_POINTS := [[[8, 6, 0], [4, 3, 10]], [[6, 8, 0], [3, 4, 9]], [[1, -2, 3], [4, 2, 15]]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	for i in TRIES:
		var s := {"paper": int(need.get("paper", 2)), "ask": need.get("ask", "cuboid-diagonal-base"), "rep": need.get("rep", "diagram"),
			"ctx": rng.int_in(0, CONTEXTS - 1), "solid": "", "l": 0, "w": 0, "h": 0, "r": 0, "sl": 0, "given": "", "edge": "",
			"corner": "", "pair": "", "A": [], "B": [], "C": [], "right": "", "shape": "", "theta": 0.0}
		if s.ask == "landmark-angle":
			s.paper = 1
		elif s.paper != 2:
			s.paper = 2
		if _draw(rng, s) and _clean(s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"cuboid-diagonal-base", "cuboid-two-diagonals", "cuboid-diagonal-edge":
			s.solid = "cuboid"
			s.l = rng.int_in(3, LONGEST)
			s.w = rng.int_in(2, LONGEST)
			s.h = rng.int_in(2, LONGEST)
			if s.l == s.w or s.w == s.h or s.l == s.h:
				return false
			s.edge = rng.pick(["AB", "AD", "AE"])
		"pyramid-edge-base", "pyramid-face-base", "pyramid-apex-angle":
			s.solid = "pyramid"
			s.l = rng.int_in(3, 14)
			s.w = s.l if rng.chance(0.4) else rng.int_in(3, 14)
			s.h = rng.int_in(3, LONGEST)
			if [s.l, s.w, s.h] in BANK:
				return false
			s.corner = rng.pick(["A", "B", "C", "D"])
			s.edge = rng.pick(["AB", "BC", "CD", "DA"])
			s.pair = rng.pick(["AVB", "BVC", "AVC"])
			# A rectangle's two kinds of face are both asked about.
			if s.ask == "pyramid-face-base" and s.l == s.w and rng.chance(0.6):
				return false
		"cone-slant-base":
			s.solid = "cone"
			s.given = rng.pick(["rh", "rl", "hl"])
			match s.given:
				"rh":
					s.r = rng.int_in(2, 12)
					s.h = rng.int_in(2, LONGEST)
				"rl":
					s.r = rng.int_in(2, 12)
					s.sl = rng.int_in(s.r + 1, LONGEST + 3)
				"hl":
					s.h = rng.int_in(2, LONGEST)
					s.sl = rng.int_in(s.h + 1, LONGEST + 3)
		"coords-line-plane":
			s.solid = "points"
			s.A = _point(rng, 8)
			s.B = []
			var d := [ExtensionViews.nonzero(rng, -9, 9), ExtensionViews.nonzero(rng, -9, 9), ExtensionViews.nonzero(rng, -9, 9)]
			if rng.chance(0.3):
				s.A[2] = 0
			for i in 3:
				s.B.append(s.A[i] + d[i])
			if not _in_reach(s.B) or absi(d[0]) == absi(d[1]) or not _sign_change([[s.A, s.B]]):
				return false
		"coords-angle-abc":
			s.solid = "points"
			s.A = _point(rng, 9)
			s.B = _point(rng, 9)
			s.C = _point(rng, 9)
			if not _triangle_ok(s.A, s.B, s.C):
				return false
		"coords-right-angle":
			return _right_triangle(rng, s)
		"landmark-angle":
			return _landmark(rng, s)
		_:
			return false
	return true


static func _point(rng: Seeded, reach: int) -> Array:
	return [rng.int_in(-reach, reach), rng.int_in(-reach, reach), rng.int_in(-reach, reach)]


static func _in_reach(p: Array, reach: int = 12) -> bool:
	return p.all(func(v): return absi(v) <= reach)


static func minus(a: Array, b: Array) -> Array:
	return [a[0] - b[0], a[1] - b[1], a[2] - b[2]]


static func sq(v: Array) -> int:
	return v[0] * v[0] + v[1] * v[1] + v[2] * v[2]


static func dot(a: Array, b: Array) -> int:
	return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


## The angle at q in triangle pqr, in degrees.
static func angle_at(p: Array, q: Array, r: Array) -> float:
	var u := minus(p, q)
	var v := minus(r, q)
	return rad_to_deg(acos(clampf(dot(u, v) / sqrt(float(sq(u)) * float(sq(v))), -1.0, 1.0)))


## Every angle of the triangle clear of a right angle and none of them thin, and some
## coordinate changes sign between two of the points, so a minus sign matters.
static func _triangle_ok(a: Array, b: Array, c: Array) -> bool:
	if sq(minus(a, b)) == 0 or sq(minus(b, c)) == 0 or sq(minus(a, c)) == 0:
		return false
	for t in [angle_at(b, a, c), angle_at(a, b, c), angle_at(a, c, b)]:
		if t < 12.0 or absf(t - 90.0) < RIGHT_GAP:
			return false
	return _sign_change([[a, b], [b, c]])


## Some coordinate changes sign between the two points of a pair, so a minus sign matters.
static func _sign_change(pairs: Array) -> bool:
	for pair in pairs:
		for i in 3:
			if pair[0][i] * pair[1][i] < 0:
				return true
	return false


## A right angle at A or C, from two whole moves at right angles: u from it to B, and v to the third point.
static func _right_triangle(rng: Seeded, s: Dictionary) -> bool:
	s.solid = "points"
	s.right = rng.pick(["A", "C"])
	var u := [ExtensionViews.nonzero(rng, -6, 6), ExtensionViews.nonzero(rng, -6, 6), rng.int_in(-6, 6)]
	var w := [rng.int_in(-4, 4), rng.int_in(-4, 4), rng.int_in(-4, 4)]
	# u × w is at right angles to u; it is cut down by the common factor of its parts.
	var v := [u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0]]
	var g := 0
	for e in v:
		g = Q.gcd(g, absi(e))
	if g == 0:
		return false
	v = v.map(func(e): return e / g)
	if not _in_reach(v, 8) or dot(u, v) != 0:
		return false
	var p := _point(rng, 6)
	var b := [p[0] + u[0], p[1] + u[1], p[2] + u[2]]
	var other := [p[0] + v[0], p[1] + v[1], p[2] + v[2]]
	if not _in_reach(b) or not _in_reach(other):
		return false
	s.B = b
	if s.right == "A":
		s.A = p
		s.C = other
	else:
		s.C = p
		s.A = other
	var t := angle_at(s.A, s.B, s.C)
	if t < WIDE_LOW or t > 90.0 - WIDE_LOW:
		return false
	return _sign_change([[s.A, s.B], [s.B, s.C], [s.A, s.C]])


## Paper 1: whole lengths that make the angle a landmark.
static func _landmark(rng: Seeded, s: Dictionary) -> bool:
	s.shape = rng.pick(["cone-rl", "cone-hl", "cone-rh", "cuboid", "pyramid"])
	var k := rng.int_in(2, 9)
	match s.shape:
		"cone-rl":
			s.solid = "cone"
			s.given = "rl"
			s.r = k
			s.sl = 2 * k
		"cone-hl":
			s.solid = "cone"
			s.given = "hl"
			s.h = k
			s.sl = 2 * k
		"cone-rh":
			s.solid = "cone"
			s.given = "rh"
			s.r = k
			s.h = k
		"cuboid":
			s.solid = "cuboid"
			var t: Array = rng.pick(TRIPLES)
			s.l = t[0]
			s.w = t[1]
			s.h = t[2]
		"pyramid":
			# A square base of side 2k with every slant edge 2k: the height is k√2.
			s.solid = "pyramid"
			s.l = 2 * (k if k <= 6 else k - 3)
			s.w = s.l
			s.sl = s.l
			s.corner = rng.pick(["A", "B", "C", "D"])
	return true


# ── The angle ────────────────────────────────────────────────

## A cuboid's space diagonal squared.
static func diag_sq(s: Dictionary) -> int:
	return s.l * s.l + s.w * s.w + s.h * s.h


## The length of the edge the cuboid's triangle holds.
static func edge_len(s: Dictionary) -> int:
	return {"AB": s.l, "AD": s.w, "AE": s.h}[s.edge]


## A pyramid's base diagonal squared, and its slant edge squared (a float: a quarter of it may be a half).
static func base_sq(s: Dictionary) -> int:
	return s.l * s.l + s.w * s.w


static func slant_edge_sq(s: Dictionary) -> float:
	return base_sq(s) / 4.0 + s.h * s.h


## The side of the base opposite the apex angle, squared.
static func apex_side_sq(s: Dictionary) -> int:
	return {"AVB": s.l * s.l, "BVC": s.w * s.w, "AVC": base_sq(s)}[s.pair]


## The distance from the base's centre X to the midpoint M of the face's edge: half the other edge.
static func face_run(s: Dictionary) -> float:
	return (s.w if s.edge in ["AB", "CD"] else s.l) / 2.0


## The cone's measures as floats: [r, h, l].
static func cone(s: Dictionary) -> Array:
	match s.given:
		"rh":
			return [float(s.r), float(s.h), sqrt(float(s.r * s.r + s.h * s.h))]
		"rl":
			return [float(s.r), sqrt(float(s.sl * s.sl - s.r * s.r)), float(s.sl)]
	return [sqrt(float(s.sl * s.sl - s.h * s.h)), float(s.h), float(s.sl)]


## The angle asked, in degrees.
static func angle(s: Dictionary) -> float:
	match s.ask:
		"cuboid-diagonal-base":
			return rad_to_deg(atan(s.h / sqrt(float(s.l * s.l + s.w * s.w))))
		"cuboid-two-diagonals":
			var e := edge_len(s)
			return rad_to_deg(acos(1.0 - 2.0 * e * e / float(diag_sq(s))))
		"cuboid-diagonal-edge":
			return rad_to_deg(acos(edge_len(s) / sqrt(float(diag_sq(s)))))
		"pyramid-edge-base":
			return rad_to_deg(atan(s.h / (sqrt(float(base_sq(s))) / 2.0)))
		"pyramid-face-base":
			return rad_to_deg(atan(s.h / face_run(s)))
		"pyramid-apex-angle":
			return rad_to_deg(2.0 * asin(sqrt(apex_side_sq(s)) / 2.0 / sqrt(slant_edge_sq(s))))
		"cone-slant-base":
			var c := cone(s)
			return rad_to_deg(atan(c[1] / c[0]))
		"coords-line-plane":
			var d := minus(s.B, s.A)
			return rad_to_deg(atan(absf(d[2]) / sqrt(float(d[0] * d[0] + d[1] * d[1]))))
		"coords-angle-abc", "coords-right-angle":
			return angle_at(s.A, s.B, s.C)
		"landmark-angle":
			return {"cone-rl": 60.0, "cone-hl": 30.0, "cone-rh": 45.0, "cuboid": 45.0, "pyramid": 45.0}[s.shape]
	return 0.0


static func _clean(s: Dictionary) -> bool:
	s.theta = angle(s)
	var t: float = s.theta
	if s.paper == 1:
		return true
	if not Answer.rounds_clearly(t, EDGE):
		return false
	for mark in [30.0, 45.0, 60.0]:
		if absf(t - mark) < LANDMARK_GAP:
			return false
	if s.ask in TWO_LINES:
		return t >= WIDE_LOW and t <= WIDE_HIGH and absf(t - 90.0) >= RIGHT_GAP
	if s.ask == "coords-line-plane" and _from_bank(s.A, s.B):
		return false
	return t >= LOW and t <= HIGH


static func _from_bank(a: Array, b: Array) -> bool:
	for pair in BANK_POINTS:
		if (pair[0] == a and pair[1] == b) or (pair[0] == b and pair[1] == a):
			return true
	return false


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
