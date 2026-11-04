class_name SolidSituation
extends RefCounted
## The `solid` situation (curriculum/question-types.json): one solid and its measurements
## (FAL-726). `shape` is cone, pyramid, sphere, hemisphere, cone-hemisphere (a cone on a
## hemisphere), cone-cylinder, hemisphere-cylinder or cylinder-minus-hemisphere (a cylinder with
## a hemisphere hollowed out of its top). sector is the flat sheet a cone unrolls into.
## Paper 1 measurements are whole, from Pythagorean triples wherever a slant comes in, so a
## volume or area is an exact multiple of π. Paper 2 measurements have one decimal place and
## answers are to 3 s.f.
##
## need.ask is the unknown (see SolidViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx (an index into SolidViews' stories), shape, unit ("cm", or "m" for paint)
##   r, h, l    radius, perpendicular height and slant height of the cone (r also of a sphere,
##              a hemisphere or a cylinder), floats. Where one comes from the others it is exact
##   given      "h" or "l": which of the two a cone's question shows
##   dia        true: the question shows the diameter, not the radius
##   c, big     the cylinder's height and, on cylinder-minus-hemisphere, its radius
##   a, b, t    a pyramid's base edges and the slant height of a square pyramid's face
##   vol        the volume given, on the unknowns that start from it: on Paper 1 a multiple of π
##              (a plain number for a pyramid), on Paper 2 the whole number shown
##   theta      a sector's angle in degrees
##   price      the cost per m² on paint-cost
##   rx, hx, lx, tail  in terms of x: r = rx·x, h = hx·x, l = lx·x and the cylinder's height a
##              plain number `tail`; x is only the size the solid is drawn at, and is never shown
##   total      on surface-in-terms: the cone's whole surface, not just the curved part
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 6000
const EDGE := 0.03
const CONTEXTS := 6
const TRIPLES := [[3, 4, 5], [6, 8, 10], [5, 12, 13], [9, 12, 15], [8, 15, 17], [12, 16, 20]]
const COMPOSITES := ["cone-hemisphere", "cone-cylinder", "hemisphere-cylinder", "cylinder-minus-hemisphere"]
## Sheets that roll into a cone with a whole base radius on Paper 1: slant heights.
const SHEETS := [6, 8, 9, 10, 12, 15, 18, 20, 24]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "cone-volume")
	var rep: String = need.get("rep", "diagram")
	var paper: int = int(need.get("paper", 1))
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, CONTEXTS - 1), "unit": "cm", "dia": false, "given": "h"}
		if _draw(rng, s) and _clear(s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"cone-volume":
			s.dia = rng.chance(0.4)
			return _cone(rng, s, "h")
		"cone-volume-from-slant", "height-from-slant":
			return _cone(rng, s, "l")
		"cone-curved":
			return _cone(rng, s, "h" if rng.chance(0.6) else "l")
		"cone-total":
			return _cone(rng, s, "h" if rng.chance(0.6) else "l")
		"pyramid-volume":
			return _pyramid(rng, s, rng.chance(0.5))
		"pyramid-volume-from-slant", "pyramid-surface":
			return _square_pyramid(rng, s, "t" if s.ask == "pyramid-volume-from-slant" else "h")
		"sphere-volume", "sphere-surface":
			s.shape = "sphere"
			s.dia = rng.chance(0.5)
			return _radius(rng, s, 2, 12)
		"hemisphere-volume", "hemisphere-surface":
			s.shape = "hemisphere"
			s.dia = rng.chance(0.4)
			return _radius(rng, s, 2, 12)
		"radius-from-volume":
			return _radius_from_volume(rng, s)
		"height-from-volume":
			return _height_from_volume(rng, s)
		"composite-volume", "composite-surface":
			return _composite(rng, s, rng.pick(COMPOSITES))
		"paint-cost":
			return _paint(rng, s)
		"composite-volume-solve":
			return _solve(rng, s)
		"volume-in-terms", "surface-in-terms":
			return _in_terms(rng, s)
		"sector-cone-radius":
			return _sector(rng, s)
	return false


## One decimal place on Paper 2.
static func tenth(rng: Seeded, lo: float, hi: float) -> float:
	return rng.int_in(roundi(lo * 10.0), roundi(hi * 10.0)) / 10.0


static func _radius(rng: Seeded, s: Dictionary, lo: int, hi: int) -> bool:
	s.r = float(rng.int_in(lo, hi)) if s.paper == 1 else tenth(rng, lo, hi)
	return true


## A right cone: on Paper 1 a Pythagorean triple, on Paper 2 r and the `given` one of h and l.
static func _cone(rng: Seeded, s: Dictionary, given: String) -> bool:
	s.shape = "cone" if not s.has("shape") else s.shape
	s.given = given
	if s.paper == 1:
		var t: Array = rng.pick(TRIPLES)
		var flip := rng.chance(0.5)
		s.r = float(t[1] if flip else t[0])
		s.h = float(t[0] if flip else t[1])
		s.l = float(t[2])
		return s.r <= 12.0
	s.r = tenth(rng, 2.0, 12.0)
	if given == "l":
		s.l = tenth(rng, s.r + 1.5, 26.0)
		s.h = sqrt(s.l * s.l - s.r * s.r)
	else:
		s.h = tenth(rng, 3.0, 20.0)
		s.l = sqrt(s.r * s.r + s.h * s.h)
	return s.h / s.r >= 0.6 and s.h / s.r <= 3.5


static func _pyramid(rng: Seeded, s: Dictionary, square: bool) -> bool:
	s.shape = "pyramid"
	if s.paper == 1:
		s.a = float(rng.int_in(2, 12))
		s.b = s.a if square else float(rng.int_in(2, 12))
		s.h = float(rng.int_in(2, 15))
		return (roundi(s.a * s.b * s.h) % 3 == 0) and (square or s.a != s.b)
	s.a = tenth(rng, 3.0, 16.0)
	s.b = s.a if square else tenth(rng, 3.0, 16.0)
	s.h = tenth(rng, 3.0, 18.0)
	return square or absf(s.a - s.b) >= 0.5


## A square pyramid and the slant height t of a face: half the base, the height and t make a
## right triangle. `given` says whether the height or t is shown.
static func _square_pyramid(rng: Seeded, s: Dictionary, given: String) -> bool:
	s.shape = "pyramid"
	s.given = given
	if s.paper == 1:
		var p: Array = rng.pick(TRIPLES)
		var flip := rng.chance(0.5)
		s.a = 2.0 * (p[1] if flip else p[0])
		s.h = float(p[0] if flip else p[1])
		s.t = float(p[2])
		s.b = s.a
		return s.a <= 24.0
	s.a = tenth(rng, 3.0, 16.0)
	s.b = s.a
	if given == "t":
		s.t = tenth(rng, s.a / 2.0 + 1.5, 20.0)
		s.h = sqrt(s.t * s.t - s.a * s.a / 4.0)
	else:
		s.h = tenth(rng, 3.0, 18.0)
		s.t = sqrt(s.h * s.h + s.a * s.a / 4.0)
	return s.h >= 0.5 * s.a


## A sphere, hemisphere or cone with a volume given, r to find. On Paper 2 the volume is a whole
## number, so r comes from it and needs a calculator.
static func _radius_from_volume(rng: Seeded, s: Dictionary) -> bool:
	s.shape = rng.pick(["sphere", "hemisphere", "cone"])
	if s.paper == 1:
		s.r = float(rng.int_in(2, 10))
		if s.shape == "cone":
			s.h = float(rng.pick([3, 6, 9, 12]))
		s.vol = vol_k(s)
		return true
	s.r = tenth(rng, 2.0, 12.0)
	if s.shape == "cone":
		s.h = tenth(rng, 3.0, 20.0)
	s.vol = float(roundi(vol_k(s) * PI))
	match s.shape:
		"sphere":
			s.r = pow(3.0 * s.vol / (4.0 * PI), 1.0 / 3.0)
		"hemisphere":
			s.r = pow(3.0 * s.vol / (2.0 * PI), 1.0 / 3.0)
		_:
			s.r = sqrt(3.0 * s.vol / (PI * s.h))
	return s.vol >= 20.0


static func _height_from_volume(rng: Seeded, s: Dictionary) -> bool:
	s.shape = "cone" if rng.chance(0.65) else "pyramid"
	if s.shape == "cone":
		s.dia = rng.chance(0.4)
		s.r = float(rng.int_in(2, 8)) if s.paper == 1 else tenth(rng, 2.0, 12.0)
	else:
		s.a = float(rng.int_in(2, 12)) if s.paper == 1 else tenth(rng, 3.0, 14.0)
		s.b = s.a
	if s.paper == 1:
		s.h = float(rng.int_in(1, 5) * 3)
		s.vol = vol_k(s)
		return true
	s.h = tenth(rng, 3.0, 20.0)
	s.vol = float(roundi(vol_k(s) * (PI if s.shape == "cone" else 1.0)))
	s.h = 3.0 * s.vol / (PI * s.r * s.r) if s.shape == "cone" else 3.0 * s.vol / (s.a * s.a)
	return s.vol >= 20.0


static func _composite(rng: Seeded, s: Dictionary, shape: String) -> bool:
	s.shape = shape
	match shape:
		"cone-hemisphere", "cone-cylinder":
			if not _cone(rng, s, "h" if rng.chance(0.6) else "l"):
				return false
			if shape == "cone-cylinder":
				s.c = float(rng.int_in(2, 12)) if s.paper == 1 else tenth(rng, 3.0, 16.0)
			return true
		"hemisphere-cylinder":
			s.r = float(rng.int_in(2, 9)) if s.paper == 1 else tenth(rng, 2.0, 10.0)
			s.c = float(rng.int_in(2, 12)) if s.paper == 1 else tenth(rng, 3.0, 16.0)
			return true
	s.big = float(rng.int_in(3, 10)) if s.paper == 1 else tenth(rng, 3.0, 12.0)
	s.r = float(rng.int_in(2, 8)) if s.paper == 1 else tenth(rng, 2.0, 10.0)
	s.c = float(rng.int_in(4, 14)) if s.paper == 1 else tenth(rng, 4.0, 16.0)
	return s.r < s.big - 0.4 and s.c > s.r + 0.9


## A tank in the open, in metres. Its base stands on the ground and costs nothing.
static func _paint(rng: Seeded, s: Dictionary) -> bool:
	s.unit = "m"
	var shape: String = rng.pick(["cone-cylinder", "hemisphere-cylinder"])
	if not _composite(rng, s, shape):
		return false
	s.price = float(rng.int_in(2, 9)) if s.paper == 1 else tenth(rng, 1.5, 9.5)
	return true


## A composite volume with r unknown: r² and r³ together, so the equation is left to the GDC.
static func _solve(rng: Seeded, s: Dictionary) -> bool:
	s.shape = rng.pick(["cone-hemisphere", "hemisphere-cylinder"])
	s.given = "h"
	s.r = tenth(rng, 2.0, 9.0)
	if s.shape == "cone-hemisphere":
		s.h = tenth(rng, 3.0, 18.0)
		s.l = sqrt(s.r * s.r + s.h * s.h)
	else:
		s.c = tenth(rng, 3.0, 16.0)
	s.vol = float(roundi(vol_k(s) * PI))
	s.r = solve_r(s, 2.0 / 3.0, s.h / 3.0 if s.shape == "cone-hemisphere" else s.c)
	if s.shape == "cone-hemisphere":
		s.l = sqrt(s.r * s.r + s.h * s.h)
	return s.r > 1.0 and absf(s.r - roundf(s.r)) > 0.02


## The positive root of π(p r³ + q r²) = vol: the GDC's solver, by Brent's method.
static func solve_r(s: Dictionary, p: float, q: float) -> float:
	var f := func(x: float) -> float: return PI * (p * x * x * x + q * x * x) - s.vol
	var hit := Brent.root(f, 0.01, 200.0)
	return hit.x if hit.ok else -1.0


## r = rx·x with x still to come: the answer is an expression. On surface-in-terms the cone's
## r, h and l are a multiple of a triple, so l is a whole multiple of x too.
static func _in_terms(rng: Seeded, s: Dictionary) -> bool:
	var volume: bool = s.ask == "volume-in-terms"
	s.x = float(rng.int_in(2, 3))
	if volume:
		s.shape = rng.pick(["cone", "sphere", "hemisphere", "hemisphere-cylinder", "cone-cylinder"])
	else:
		s.shape = rng.pick(["cone", "hemisphere", "hemisphere-cylinder"])
	s.rx = rng.int_in(1, 3)
	if s.shape == "cone":
		if volume:
			s.hx = rng.int_in(1, 6)
			s.h = s.hx * s.x
			s.r = s.rx * s.x
			s.l = sqrt(s.r * s.r + s.h * s.h)
		else:
			var t: Array = rng.pick([[3, 4, 5], [4, 3, 5], [5, 12, 13], [6, 8, 10], [8, 6, 10]])
			s.rx = t[0]
			s.hx = t[1]
			s.lx = t[2]
			s.total = rng.chance(0.5)
			s.r = s.rx * s.x
			s.h = s.hx * s.x
			s.l = s.lx * s.x
		return s.h / s.r >= 0.5 and s.h / s.r <= 3.5
	s.r = s.rx * s.x
	if s.shape == "cone-cylinder":
		s.hx = rng.int_in(1, 4)
		s.h = s.hx * s.x
		s.l = sqrt(s.r * s.r + s.h * s.h)
	if s.shape in ["hemisphere-cylinder", "cone-cylinder"]:
		s.tail = rng.int_in(3, 12)
		s.c = float(s.tail)
	return true


## The flat sheet of a cone: a sector with radius l, the cone's slant height.
static func _sector(rng: Seeded, s: Dictionary) -> bool:
	s.shape = "sector"
	if s.paper == 1:
		s.l = float(rng.pick(SHEETS))
		s.r = float(rng.int_in(2, roundi(s.l) - 1))
		s.theta = 360.0 * s.r / s.l
		return is_equal_approx(s.theta, roundf(s.theta)) and s.theta >= 60.0 and s.theta <= 300.0
	s.l = tenth(rng, 6.0, 30.0)
	s.theta = float(rng.int_in(60, 300))
	s.r = s.l * s.theta / 360.0
	return true


# ── The formulas ─────────────────────────────────────────────
# Each area and volume as a multiple of π, but a pyramid's, which is plain. SolidViews and the
# clean limits below share them. The checker has its own.

static func has_pi(s: Dictionary) -> bool:
	return s.shape != "pyramid"


static func vol_k(s: Dictionary) -> float:
	match s.shape:
		"cone":
			return s.r * s.r * s.h / 3.0
		"pyramid":
			return s.a * s.b * s.h / 3.0
		"sphere":
			return 4.0 * pow(s.r, 3.0) / 3.0
		"hemisphere":
			return 2.0 * pow(s.r, 3.0) / 3.0
		"cone-hemisphere":
			return s.r * s.r * s.h / 3.0 + 2.0 * pow(s.r, 3.0) / 3.0
		"cone-cylinder":
			return s.r * s.r * s.h / 3.0 + s.r * s.r * s.c
		"hemisphere-cylinder":
			return 2.0 * pow(s.r, 3.0) / 3.0 + s.r * s.r * s.c
		"cylinder-minus-hemisphere":
			return s.big * s.big * s.c - 2.0 * pow(s.r, 3.0) / 3.0
	return 0.0


## The whole outer surface of a solid, join faces left out.
static func surf_k(s: Dictionary) -> float:
	match s.shape:
		"cone":
			return s.r * s.l + s.r * s.r
		"sphere":
			return 4.0 * s.r * s.r
		"hemisphere":
			return 3.0 * s.r * s.r
		"cone-hemisphere":
			return s.r * s.l + 2.0 * s.r * s.r
		"cone-cylinder":
			return s.r * s.l + 2.0 * s.r * s.c + s.r * s.r
		"hemisphere-cylinder":
			return 2.0 * s.r * s.r + 2.0 * s.r * s.c + s.r * s.r
		"cylinder-minus-hemisphere":
			return 2.0 * s.r * s.r + 2.0 * s.big * s.c + s.big * s.big + (s.big * s.big - s.r * s.r)
	return 0.0


## The area of the base that stands on the ground, as a multiple of π.
static func base_k(s: Dictionary) -> float:
	return s.big * s.big if s.shape == "cylinder-minus-hemisphere" else s.r * s.r


## The answer of a Paper 2 question, as a number, for the rounding edge.
static func value(s: Dictionary) -> float:
	match s.ask:
		"cone-curved":
			return PI * s.r * s.l
		"cone-total", "hemisphere-surface", "sphere-surface", "composite-surface":
			return PI * surf_k(s)
		"pyramid-surface":
			return s.a * s.a + 2.0 * s.a * s.t
		"paint-cost":
			return PI * (surf_k(s) - base_k(s)) * s.price
		"height-from-slant":
			return s.h
		"radius-from-volume", "composite-volume-solve":
			return s.r
		"height-from-volume":
			return s.h
		"sector-cone-radius":
			return s.r
	return vol_k(s) * (PI if has_pi(s) else 1.0)


## Paper 2 answers stay off rounding edges and need a calculator.
static func _clear(s: Dictionary) -> bool:
	if s.paper == 1 or s.ask in ["volume-in-terms", "surface-in-terms"]:
		return true
	var v := value(s)
	return Answer.rounds_clearly(v, EDGE) and Answer.needs_rounding(TriangleViews.qf(v))


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
