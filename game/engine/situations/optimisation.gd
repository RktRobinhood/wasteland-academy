class_name OptimisationSituation
extends RefCounted
## The `optimisation-model` situation (curriculum/question-types.json): one shape or journey
## with a fixed amount, one free length, and a quantity to make as large or as small as it
## can go (FAL-739). The generator picks a family, then numbers that give a clean optimum.
##
## Families, with x (r on a cylinder) the free length:
##   pen      fence F against a wall, n sections of x and one of y: A = Fx − nx²
##   paddock  area P against a wall: L = nx + P/x
##   can      a cylinder of volume V, ends e times the rate of the side: S = eπr² + 2qV/r
##   bin      an open square-based bin from a sheet of area P: V = (Px − x³)/4
##   box      a tray from a w by h sheet, corners of side x cut out: V = x(w − 2x)(h − 2x)
##   arch     a rectangle under y = c − ax²: A = 2cx − 2ax³
##   route    a straight leg off a road, then along it: W = α√(a² + x²) + β(b − x)
##   closest  the point of a curve nearest a fixed point
##
## need.fams lists the families a view can use; need.mode "surd" asks for an optimum with no
## tidy value, to be left exact. need.paper is 1 or 2. Paper 1 numbers are exact: `x`, `y` and
## `best` are Q, and on a cylinder they and the whole objective are multiples of π where
## `pi` is true. Paper 2 numbers are awkward: `x`, `y` and `best` are floats, to 3 s.f.
##
## generate() returns a Dictionary:
##   paper, fam, mode;  ctx  the story (an index into the views' stories)
##   the family's numbers (n, F, P, ends, rate_end, rate_side, e, k, V, w, h, a, c, b, kind ...)
##   x, y, best       the optimum: the free length, the second length (null if none), the value
##   big              true for a maximum, false for a minimum
##   lo, hi, dlo, dhi x-values either side of the optimum and the derivative there
##   d2               the second derivative at the optimum
##
## The clean limits below are the numbers behind the catalogue's `clean` text. The SymPy checker
## (tools/check_answers.py) holds its own copy and fails on any breach.

const CONTEXTS := 3
const TRIES := 4000
const EDGE := 0.03
const NON_SQUARE := [2, 3, 5, 6, 7]
const ROUTE_TIME_FRONT := [20, 25, 30, 35, 40]
const ROUTE_TIME_BACK := [50, 60, 70, 80, 90]
const ROUTE_COST_FRONT := [12, 15, 18, 20, 25]
const ROUTE_COST_BACK := [4, 5, 6, 8, 10]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var fams: Array = need.get("fams", ["paddock"])
	var mode: String = need.get("mode", "clean")
	var paper := int(need.get("paper", 1))
	for i in TRIES:
		var fam: String = fams[rng.int_in(0, fams.size() - 1)]
		if (paper == 1 and fam == "route") or (paper == 2 and fam == "closest"):
			continue
		if mode == "surd" and (fam == "can") != (paper == 2):
			continue
		var s := {"paper": paper, "fam": fam, "mode": mode, "ctx": rng.int_in(0, CONTEXTS - 1), "pi": false, "y": null, "big": true}
		var ok := false
		match fam:
			"pen":
				ok = _pen(rng, s)
			"paddock":
				ok = _paddock(rng, s)
			"can":
				ok = _can(rng, s)
			"bin":
				ok = _bin(rng, s)
			"box":
				ok = _box(rng, s)
			"arch":
				ok = _arch(rng, s)
			"route":
				ok = _route(rng, s)
			"closest":
				ok = _closest(rng, s)
		if ok and _finish(s):
			return s
	return {}


static func is_square(v: int) -> bool:
	var r := roundi(sqrt(float(v)))
	return r * r == v


static func _pen(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(2, 5)
	if s.paper == 1:
		var x := rng.int_in(4, 15)
		s.F = 2 * s.n * x
		s.x = Q.new(x)
		s.y = Q.new(s.F).div(2)
		s.best = Q.new(s.n * x * x)
		return true
	s.F = rng.int_in(40, 400)
	if s.F % (2 * s.n) == 0:
		return false
	s.x = float(s.F) / (2.0 * s.n)
	s.y = float(s.F) / 2.0
	s.best = s.x * s.y
	return true


static func _paddock(rng: Seeded, s: Dictionary) -> bool:
	s.big = false
	s.n = rng.int_in(2, 4)
	if s.mode == "surd":
		s.m = rng.int_in(2, 4)
		s.t = int(NON_SQUARE[rng.int_in(0, NON_SQUARE.size() - 1)])
		s.P = s.n * s.m * s.m * s.t
		s.x = Q.new(0)
		return s.P >= 20 and s.P <= 900
	if s.paper == 1:
		var c := rng.int_in(2, 12)
		s.P = s.n * c * c
		s.x = Q.new(c)
		s.y = Q.new(s.n * c)
		s.best = Q.new(2 * s.n * c)
		return true
	s.P = rng.int_in(30, 900)
	if s.P % s.n == 0 and is_square(s.P / s.n):
		return false
	s.x = sqrt(float(s.P) / s.n)
	s.y = s.P / s.x
	s.best = s.n * s.x + s.y
	return true


static func _can(rng: Seeded, s: Dictionary) -> bool:
	s.big = false
	s.ends = rng.int_in(1, 2)
	s.cost = rng.chance(0.4)
	s.rate_end = int([2, 3, 4][rng.int_in(0, 2)]) if s.cost else 1
	s.rate_side = 1
	s.e = s.rate_end * s.ends
	if s.paper == 1:
		var c := rng.int_in(2, 6)
		s.k = s.e * c * c * c
		s.pi = true
		s.V = 0
		s.x = Q.new(c)
		s.y = Q.new(s.e * c)
		s.best = Q.new(3 * s.e * c * c)
		return s.k <= 1000
	s.k = 0
	s.V = rng.int_in(5, 90) if s.cost else rng.int_in(100, 2000)
	s.x = pow(float(s.V) / (s.e * PI), 1.0 / 3.0)
	s.y = s.V / (PI * s.x * s.x)
	s.best = s.e * PI * s.x * s.x + 2.0 * s.V / s.x
	return s.x >= 1.0 and s.x <= 30.0


static func _bin(rng: Seeded, s: Dictionary) -> bool:
	if s.mode == "surd":
		s.m = rng.int_in(2, 6)
		s.t = int(NON_SQUARE[rng.int_in(0, NON_SQUARE.size() - 1)])
		s.P = 3 * s.m * s.m * s.t
		s.x = Q.new(0)
		return s.P <= 900
	if s.paper == 1:
		var c := 2 * rng.int_in(2, 10)
		s.P = 3 * c * c
		s.x = Q.new(c)
		s.y = Q.new(c).div(2)
		s.best = Q.new(c * c * c).div(2)
		return true
	s.P = rng.int_in(150, 2400)
	if s.P % 3 == 0 and is_square(s.P / 3):
		return false
	s.x = sqrt(float(s.P) / 3.0)
	s.y = (s.P - s.x * s.x) / (4.0 * s.x)
	s.best = s.x * s.x * s.y
	return true


## Paper 1 sheets are the ones whose V′ has rational roots: w² − wh + h² is a square.
static func _box(rng: Seeded, s: Dictionary) -> bool:
	var w := rng.int_in(12, 40)
	var h := w + rng.int_in(5, 40)
	s.w = w
	s.h = h
	var d := w * w - w * h + h * h
	var root := sqrt(float(d))
	if s.paper == 1:
		if not is_square(d):
			return false
		var r := roundi(root)
		s.x = Q.new(w + h - r, 6)
		s.other = Q.new(w + h + r, 6)
		if s.x.mul(2).is_int() == false:
			return false
		var X: Q = s.x
		s.best = X.mul(Q.new(w).sub(X.mul(2))).mul(Q.new(h).sub(X.mul(2)))
		return true
	if is_square(d):
		return false
	s.x = (w + h - root) / 6.0
	s.other = (w + h + root) / 6.0
	s.best = s.x * (w - 2.0 * s.x) * (h - 2.0 * s.x)
	return true


static func _arch(rng: Seeded, s: Dictionary) -> bool:
	s.a = rng.int_in(1, 2)
	if s.mode == "surd":
		s.m = rng.int_in(2, 3)
		s.t = int(NON_SQUARE[rng.int_in(0, NON_SQUARE.size() - 1)])
		s.c = 3 * s.a * s.m * s.m * s.t
		s.x = Q.new(0)
		return s.c <= 60
	if s.paper == 1:
		var k := rng.int_in(1, 3)
		s.c = 3 * s.a * k * k
		s.x = Q.new(k)
		s.y = Q.new(2 * s.a * k * k)
		s.best = Q.new(4 * s.a * k * k * k)
		return s.c >= 6 and s.c <= 60
	s.c = rng.int_in(5, 40)
	if s.c % (3 * s.a) == 0 and is_square(s.c / (3 * s.a)):
		return false
	s.x = sqrt(float(s.c) / (3.0 * s.a))
	s.y = s.c - s.a * s.x * s.x
	s.best = 2.0 * s.x * s.y
	return true


static func _route(rng: Seeded, s: Dictionary) -> bool:
	s.big = false
	s.cost = rng.chance(0.5)
	s.a = rng.int_in(4, 18) * 5
	s.b = rng.int_in(10, 40) * 5
	var fronts: Array = ROUTE_COST_FRONT if s.cost else ROUTE_TIME_FRONT
	var backs: Array = ROUTE_COST_BACK if s.cost else ROUTE_TIME_BACK
	s.front = int(fronts[rng.int_in(0, fronts.size() - 1)])
	s.back = int(backs[rng.int_in(0, backs.size() - 1)])
	var alpha: float = float(s.front) if s.cost else 1.0 / s.front
	var beta: float = float(s.back) if s.cost else 1.0 / s.back
	s.x = s.a * beta / sqrt(alpha * alpha - beta * beta)
	s.best = route_value(s, s.x)
	return s.x >= 0.15 * s.b and s.x <= 0.8 * s.b


## The time or cost through the point x along the road.
static func route_value(s: Dictionary, x: float) -> float:
	var leg := sqrt(float(s.a * s.a) + x * x)
	if s.cost:
		return s.front * leg + s.back * (s.b - x)
	return leg / s.front + (s.b - x) / s.back


static func _closest(rng: Seeded, s: Dictionary) -> bool:
	s.big = false
	s.kind = "root" if rng.chance(0.6) else "log"
	if s.kind == "root":
		s.k = 2 * rng.int_in(1, 6)
		s.px = rng.int_in(3, 16)
		s.c = 0
		s.x = Q.new(s.px).sub(Q.new(s.k).div(2))
		s.best = Q.new(0)
		return s.x.sign() > 0 and s.x.to_float() >= 1.0
	var m := rng.int_in(1, 3)
	s.k = 2 * m * m
	s.px = 0
	s.c = rng.int_in(ceili(s.k * log(float(m))) + 1, ceili(s.k * log(float(m))) + 9)
	s.x = Q.new(m)
	s.best = Q.new(0)
	return true


## The objective as terms [coefficient Q, power, has π]. The route and closest families have none.
static func terms(s: Dictionary) -> Array:
	match s.fam:
		"pen":
			return [[Q.new(s.F), 1, false], [Q.new(-s.n), 2, false]]
		"paddock":
			return [[Q.new(s.n), 1, false], [Q.new(s.P), -1, false]]
		"can":
			if s.paper == 1:
				return [[Q.new(s.e), 2, true], [Q.new(2 * s.rate_side * s.k), -1, true]]
			return [[Q.new(s.e), 2, true], [Q.new(2 * s.rate_side * s.V), -1, false]]
		"bin":
			return [[Q.new(s.P, 4), 1, false], [Q.new(-1, 4), 3, false]]
		"box":
			return [[Q.new(4), 3, false], [Q.new(-2 * (s.w + s.h)), 2, false], [Q.new(s.w * s.h), 1, false]]
		"arch":
			return [[Q.new(2 * s.c), 1, false], [Q.new(-2 * s.a), 3, false]]
	return []


static func diff(ts: Array) -> Array:
	var out: Array = []
	for t in ts:
		if t[1] != 0:
			out.append([t[0].mul(t[1]), t[1] - 1, t[2]])
	return out


static func at_f(ts: Array, x: float) -> float:
	var v := 0.0
	for t in ts:
		v += t[0].to_float() * pow(x, t[1]) * (PI if t[2] else 1.0)
	return v


## The exact value of terms at x, without its factor π where they have one.
static func at_q(ts: Array, x: Q) -> Q:
	var v := Q.new(0)
	for t in ts:
		var c: Q = t[0]
		for i in absi(t[1]):
			c = c.mul(x) if t[1] > 0 else c.div(x)
		v = v.add(c)
	return v


## The value of terms at x: exact on Paper 1, a float on Paper 2.
static func at(s: Dictionary, ts: Array, x: Variant) -> Variant:
	return at_q(ts, x) if x is Q else at_f(ts, x)


## Whether a Paper 2 value reads clearly to 3 s.f.
static func clear(v: Variant) -> bool:
	return not v is float or Answer.rounds_clearly(absf(v), EDGE)


## The steps either side of the optimum, and the derivatives. What can't reach them is refused.
static func _finish(s: Dictionary) -> bool:
	if s.fam == "route":
		return clear(s.x) and clear(s.best) and clear(s.b - s.x) and clear(route_value(s, 0.0)) and clear(route_value(s, float(s.b)))
	if s.fam == "closest" or s.mode == "surd":
		if s.fam != "closest":
			s.xf = exact_x(s)
		return true
	var ts := terms(s)
	var d := diff(ts)
	var x: Variant = s.x
	var xf: float = x.to_float() if x is Q else x
	s.xf = xf
	s.d2 = at(s, diff(d), x)
	var lo: Variant
	var hi: Variant
	if x is Q:
		lo = x.sub(1) if x.to_float() > 1.0 else x.div(2)
		hi = x.add(1)
		if not _inside(s, hi.to_float()):
			hi = x.mul(Q.new(3, 2))
	else:
		lo = floorf(xf)
		hi = ceilf(xf)
		if lo <= 0.0 or hi == lo:
			return false
	s.lo = lo
	s.hi = hi
	s.dlo = at(s, d, lo)
	s.dhi = at(s, d, hi)
	if not _inside(s, hi.to_float() if hi is Q else hi):
		return false
	return clear(s.x) and clear(s.best) and clear(s.d2) and clear(s.dlo) and clear(s.dhi) and (s.y == null or clear(s.y))


## Whether x is inside the domain, where the shape still exists.
static func _inside(s: Dictionary, x: float) -> bool:
	match s.fam:
		"pen":
			return x < float(s.F) / s.n
		"bin":
			return x * x < s.P
		"box":
			return x < mini(s.w, s.h) / 2.0
		"arch":
			return s.a * x * x < s.c
	return true


## The optimum of a surd situation, as a float.
static func exact_x(s: Dictionary) -> float:
	match s.fam:
		"paddock", "bin", "arch":
			return s.m * sqrt(float(s.t))
		"can":
			return s.x
	return 0.0


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
