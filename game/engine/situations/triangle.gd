class_name TriangleSituation
extends RefCounted
## The `triangle` situation (curriculum/question-types.json): one triangle ABC with
## side a opposite angle A, b opposite B and c opposite C, and its area.
##
## A view says which givens it shows (need.givens); generate() picks them as clean
## numbers and solves the whole triangle from them, so every side, angle and the area
## are known. Given sides are whole numbers of cm, given angles whole numbers of
## degrees and a given area a whole number of cm². The rest are floats worked out from
## the givens as shown, which is what a student with a calculator works from.
##
## The roles are dealt to the letters at random: X is the vertex the question turns
## on, Y and Z the other two (each "A", "B" or "C"). Lower case is the side opposite:
## side x is opposite X. In the code sx, sy, sz are those sides and ax, ay, az those
## angles.
##
## need.givens (what is shown, and what is asked):
##   "sas"         sides y, z and the angle X between them; asks side x or the area
##   "sss"         all three sides; asks angle X
##   "aas"         side x, angle X and angle Y ("pair") or Z ("sum"); asks side y
##   "ssa"         sides x > y and angle X, so one triangle fits; asks angle Y
##   "area-side"   the area, side y and angle X; asks side z
##   "area-angle"  the area, sides y and z, and whether X is obtuse; asks angle X
## need.ask: "area" makes "sas" ask the area.
##
## generate() returns a Dictionary:
##   givens, ask        as above; ask is a side ("a"), an angle ("A") or "area"
##   X, Y, Z            the letters in their roles
##   variant            "pair" or "sum" for "aas", else ""
##   angles             letter -> degrees (float);  sides  side letter -> cm (float)
##   area               cm² (float)
##   shown              what the question shows: {"sides": {"b": 7}, "angles": {"A": 50},
##                      "area": 30 or null, "obtuse": true/false or null} (whole numbers)
##   value              the asked quantity (float)
##
## Paper 1 or 2 (FAL-419): need.paper 2 (or none) gives the numbers above, which need a
## calculator; a value that comes out rational (a whole side, a whole area) is drawn
## again, so a Paper 2 answer always needs one. need.paper 1 gives a triangle whose
## givens are exact without a calculator, as the IB's Paper 1 asks them: angles of 30°,
## 45°, 60°, 90°, 120° or 135°, whose sines and cosines are ½, √2/2, √3/2, and sides
## chosen so the asked value is a whole number or m√r (r 2, 3 or 6): a cosine rule
## with 60° or 120° whose c² is a perfect square (3, 5, 7 with 120°), a sine rule on two
## such angles, an area ½ab sin C with a whole m in m√r. Paper 1 adds
##   paper              1 (Paper 2 says 2)
##   exact              the asked value as [m (Q), r (int)]: m√r, r square-free
##   shown.area_root    r when the shown area is m√r (area-angle), else absent
## The ambiguous sine-rule angle (ssa) is Paper 2 only: from whole sides and a nice
## angle, sin B is only nice when B is 30° opposite half the side opposite 90°.
##
## The clean limits below are the numbers behind the catalogue's `clean` text. The
## SymPy checker (tools/check_answers.py) holds its own copy and fails on any breach.

const SIDE_MIN := 3
const SIDE_MAX := 20
const ANGLE_MIN := 20.0
const ANGLE_MAX := 140.0
const RIGHT_GAP := 10.0    ## an angle found from an area is at least this far from 90°
const EDGE := 0.02         ## the answer (and every option) is this far, in units of its 3rd s.f., from a rounding edge
const AREA_MIN := 3
const TRIES := 4000
const LETTERS := ["A", "B", "C"]
## Paper 1's angles: their sines and cosines are exact (sin_of, cos_of).
const NICE := [30, 45, 60, 90, 120, 135]
## The angle between two sides on Paper 1, for an area: a right angle would be ½ab.
const NICE_AREA := [30, 45, 60, 120, 135]
## A Paper 2 value this close to a fraction with a small denominator needs no calculator.
const RATIONAL_DEN := 24
const RATIONAL_TOL := 1e-7


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var givens: String = need.get("givens", "sas")
	if int(need.get("paper", 2)) == 1:
		var s1 := _draw_p1(rng, givens, need)
		if not s1.is_empty() and _clean(s1):
			return s1
		push_error("TriangleSituation: no Paper 1 situation for %s" % need)
		return {}
	for i in TRIES:
		var s := _draw(rng, givens, need)
		if s.is_empty():
			continue
		s.paper = 2
		if not _clean(s):
			continue
		return s
	push_error("TriangleSituation: no clean situation for %s" % need)
	return {}


static func lower(letter: String) -> String:
	return letter.to_lower()


static func rad(deg: float) -> float:
	return deg_to_rad(deg)


static func _draw(rng: Seeded, givens: String, need: Dictionary) -> Dictionary:
	var roles := rng.shuffled(LETTERS)
	var X: String = roles[0]
	var Y: String = roles[1]
	var Z: String = roles[2]
	# Where y and z play the same part, they come in alphabetical order (½bc sin A).
	if givens in ["sas", "sss", "area-angle"] and Z < Y:
		var t := Y
		Y = Z
		Z = t
	var sx := 0.0
	var sy := 0.0
	var sz := 0.0
	var ax := 0.0
	var ay := 0.0
	var shown := {"sides": {}, "angles": {}, "area": null, "obtuse": null}
	var variant := ""
	var ask := ""
	match givens:
		"sas":
			sy = rng.int_in(SIDE_MIN, SIDE_MAX)
			sz = rng.int_in(SIDE_MIN, SIDE_MAX)
			ax = rng.int_in(int(ANGLE_MIN), int(ANGLE_MAX))
			sx = sqrt(sy * sy + sz * sz - 2.0 * sy * sz * cos(rad(ax)))
			ay = rad_to_deg(acos(clampf((sx * sx + sz * sz - sy * sy) / (2.0 * sx * sz), -1.0, 1.0)))
			shown.sides = {lower(Y): int(sy), lower(Z): int(sz)}
			shown.angles = {X: int(ax)}
			ask = "area" if need.get("ask", "") == "area" else lower(X)
		"sss":
			sx = rng.int_in(SIDE_MIN, SIDE_MAX)
			sy = rng.int_in(SIDE_MIN, SIDE_MAX)
			sz = rng.int_in(SIDE_MIN, SIDE_MAX)
			var cx := (sy * sy + sz * sz - sx * sx) / (2.0 * sy * sz)
			var cy := (sx * sx + sz * sz - sy * sy) / (2.0 * sx * sz)
			if absf(cx) >= 1.0 or absf(cy) >= 1.0:
				return {}
			ax = rad_to_deg(acos(cx))
			ay = rad_to_deg(acos(cy))
			shown.sides = {lower(X): int(sx), lower(Y): int(sy), lower(Z): int(sz)}
			ask = X
		"aas":
			ax = rng.int_in(int(ANGLE_MIN), int(ANGLE_MAX))
			var other := rng.int_in(int(ANGLE_MIN), int(ANGLE_MAX))
			variant = "sum" if rng.chance(0.5) else "pair"
			ay = float(other) if variant == "pair" else 180.0 - ax - other
			sx = rng.int_in(SIDE_MIN, SIDE_MAX)
			sy = sx * sin(rad(ay)) / sin(rad(ax))
			shown.sides = {lower(X): int(sx)}
			shown.angles = {X: int(ax)}
			shown.angles[Y if variant == "pair" else Z] = other
			ask = lower(Y)
		"ssa":
			sx = rng.int_in(SIDE_MIN + 1, SIDE_MAX)
			sy = rng.int_in(SIDE_MIN, int(sx) - 1)
			ax = rng.int_in(int(ANGLE_MIN), int(ANGLE_MAX))
			ay = rad_to_deg(asin(sy * sin(rad(ax)) / sx))
			shown.sides = {lower(X): int(sx), lower(Y): int(sy)}
			shown.angles = {X: int(ax)}
			ask = Y
		"area-side":
			sy = rng.int_in(SIDE_MIN, SIDE_MAX)
			ax = rng.int_in(int(ANGLE_MIN), int(ANGLE_MAX))
			var target := rng.int_in(SIDE_MIN, SIDE_MAX)
			var area := roundi(0.5 * sy * target * sin(rad(ax)))
			if area < AREA_MIN:
				return {}
			sz = 2.0 * area / (sy * sin(rad(ax)))
			sx = sqrt(sy * sy + sz * sz - 2.0 * sy * sz * cos(rad(ax)))
			ay = rad_to_deg(acos(clampf((sx * sx + sz * sz - sy * sy) / (2.0 * sx * sz), -1.0, 1.0)))
			shown.sides = {lower(Y): int(sy)}
			shown.angles = {X: int(ax)}
			shown.area = area
			ask = lower(Z)
		"area-angle":
			sy = rng.int_in(SIDE_MIN, SIDE_MAX)
			sz = rng.int_in(SIDE_MIN, SIDE_MAX)
			var target := rng.int_in(int(ANGLE_MIN), int(ANGLE_MAX))
			var area := roundi(0.5 * sy * sz * sin(rad(target)))
			if area < AREA_MIN:
				return {}
			var ratio := 2.0 * area / (sy * sz)
			if ratio >= 1.0:
				return {}
			var acute := rad_to_deg(asin(ratio))
			ax = acute if target < 90 else 180.0 - acute
			sx = sqrt(sy * sy + sz * sz - 2.0 * sy * sz * cos(rad(ax)))
			ay = rad_to_deg(acos(clampf((sx * sx + sz * sz - sy * sy) / (2.0 * sx * sz), -1.0, 1.0)))
			shown.sides = {lower(Y): int(sy), lower(Z): int(sz)}
			shown.area = area
			shown.obtuse = ax > 90.0
			ask = X
		_:
			push_error("TriangleSituation: unknown givens %s" % givens)
			return {}
	return _finish(givens, ask, variant, [X, Y, Z], [sx, sy, sz], ax, ay, shown)


## The whole triangle from what a draw found: the third angle, and every side not yet
## known from the sine rule on side x. {} if the angles leave no room for the third.
static func _finish(givens: String, ask: String, variant: String, roles: Array, xyz: Array, ax: float, ay: float,
		shown: Dictionary) -> Dictionary:
	var X: String = roles[0]
	var Y: String = roles[1]
	var Z: String = roles[2]
	var sx: float = xyz[0]
	var sy: float = xyz[1]
	var sz: float = xyz[2]
	var az := 180.0 - ax - ay
	if az <= 0.0:
		return {}
	# Every side from the sine rule on side sx, unless it is already known.
	var k := sx / sin(rad(ax))
	if sy == 0.0:
		sy = k * sin(rad(ay))
	if sz == 0.0:
		sz = k * sin(rad(az))
	var s := {
		"givens": givens, "ask": ask, "variant": variant, "X": X, "Y": Y, "Z": Z,
		"angles": {X: ax, Y: ay, Z: az}, "sides": {lower(X): sx, lower(Y): sy, lower(Z): sz},
		"area": 0.5 * sy * sz * sin(rad(ax)), "shown": shown,
	}
	s.value = s.area if ask == "area" else (s.sides[ask] if s.sides.has(ask) else s.angles[ask])
	return s


static func _clean(s: Dictionary) -> bool:
	for L in LETTERS:
		var a: float = s.angles[L]
		if a < ANGLE_MIN or a > ANGLE_MAX:
			return false
	for v in s.shown.sides.values():
		if v < SIDE_MIN or v > SIDE_MAX:
			return false
	if s.givens == "ssa" and not s.sides[lower(s.X)] > s.sides[lower(s.Y)]:
		return false
	if s.givens == "area-angle" and absf(s.angles[s.X] - 90.0) < RIGHT_GAP:
		return false
	if s.paper == 1:
		return true
	return not _rational(s.value) and Answer.rounds_clearly(s.value, EDGE)


## Whether x is (to the engine's precision) a fraction with a small denominator: a
## whole side, a half area. Such a value needs no calculator, so Paper 2 draws again.
static func _rational(x: float) -> bool:
	for d in range(1, RATIONAL_DEN + 1):
		var t := x * d
		if absf(t - roundf(t)) < RATIONAL_TOL * maxf(1.0, absf(t)):
			return true
	return false


# ── Paper 1 ──────────────────────────────────────────────────
# Exact values are [m, r]: m√r with m a Q and r a square-free whole number.

## sin d° exactly, for a NICE angle (or 150°).
static func sin_of(d: int) -> Array:
	match d:
		30, 150:
			return [Q.new(1, 2), 1]
		45, 135:
			return [Q.new(1, 2), 2]
		60, 120:
			return [Q.new(1, 2), 3]
		90:
			return [Q.new(1), 1]
	push_error("TriangleSituation: no exact sine of %d°" % d)
	return [Q.new(0), 1]


## cos d° exactly, for a NICE angle (or 150°).
static func cos_of(d: int) -> Array:
	match d:
		30:
			return [Q.new(1, 2), 3]
		45:
			return [Q.new(1, 2), 2]
		60:
			return [Q.new(1, 2), 1]
		90:
			return [Q.new(0), 1]
		120:
			return [Q.new(-1, 2), 1]
		135:
			return [Q.new(-1, 2), 2]
		150:
			return [Q.new(-1, 2), 3]
	push_error("TriangleSituation: no exact cosine of %d°" % d)
	return [Q.new(0), 1]


## m√r with the square factors of r taken out.
static func ex(m: Variant, r: int = 1) -> Array:
	var mq := Q.of(m)
	if mq.is_zero():
		return [mq, 1]
	var sq := SurdsSituation.largest_square(r)
	return [mq.mul(roundi(sqrt(float(sq)))), r / sq]


static func ex_mul(a: Array, b: Array) -> Array:
	return ex((a[0] as Q).mul(b[0]), int(a[1]) * int(b[1]))


## a / b, the root in b moved to the top: 1/√r = √r/r.
static func ex_div(a: Array, b: Array) -> Array:
	return ex((a[0] as Q).div((b[0] as Q).mul(int(b[1]))), int(a[1]) * int(b[1]))


static func ex_float(a: Array) -> float:
	return (a[0] as Q).to_float() * sqrt(float(a[1]))


## As the working writes it: "7", "1/2", "√3/2", "5√3/2", "−1/2", "4√2".
static func ex_text(a: Array) -> String:
	var m: Q = a[0]
	var r: int = a[1]
	if r == 1:
		return m.text()
	var top := ("" if absi(m.n) == 1 else str(absi(m.n))) + "√%d" % r
	return ("−" if m.n < 0 else "") + top + ("" if m.d == 1 else "/%d" % m.d)


## The angles of a triangle with sides x, y, z opposite X, Y, Z, all inside the limits.
static func _fits(x: float, y: float, z: float) -> bool:
	for t in [[x, y, z], [y, x, z], [z, x, y]]:
		var c: float = (t[1] * t[1] + t[2] * t[2] - t[0] * t[0]) / (2.0 * t[1] * t[2])
		if absf(c) >= 1.0:
			return false
		var a := rad_to_deg(acos(c))
		if a < ANGLE_MIN or a > ANGLE_MAX:
			return false
	return true


## The third side opposite angle X between sides y and z.
static func _opposite(y: float, z: float, ax: float) -> float:
	return sqrt(y * y + z * z - 2.0 * y * z * cos(rad(ax)))


## Sides y, z and a 60° or 120° angle X between them whose opposite side x is whole:
## [X, y, z, x] (3, 5, 7 with 120°; 3, 8, 7 with 60°). Never equilateral.
static func _whole_cosine_rule() -> Array:
	var out: Array = []
	for X in [60, 120]:
		for y in range(SIDE_MIN, SIDE_MAX + 1):
			for z in range(SIDE_MIN, SIDE_MAX + 1):
				if X == 60 and y == z:
					continue
				var x2: int = y * y + z * z + (-y * z if X == 60 else y * z)
				var x := roundi(sqrt(float(x2)))
				if x * x == x2 and _fits(x, y, z):
					out.append([X, y, z, x])
	return out


static func _draw_p1(rng: Seeded, givens: String, need: Dictionary) -> Dictionary:
	# The stream's first draw leans low (FAL-460), so it is spent first.
	rng.int_in(0, 1)
	var roles := rng.shuffled(LETTERS)
	var X: String = roles[0]
	var Y: String = roles[1]
	var Z: String = roles[2]
	if givens in ["sas", "sss", "area-angle"] and Z < Y:
		var t := Y
		Y = Z
		Z = t
	var sx := 0.0
	var sy := 0.0
	var sz := 0.0
	var ax := 0.0
	var ay := 0.0
	var shown := {"sides": {}, "angles": {}, "area": null, "obtuse": null}
	var variant := ""
	var ask := ""
	var exact: Array = []
	match givens:
		"sas":
			if need.get("ask", "") == "area":
				var deg: int = rng.pick(NICE_AREA)
				var pairs: Array = []
				for y in range(SIDE_MIN, SIDE_MAX + 1):
					for z in range(SIDE_MIN, SIDE_MAX + 1):
						if (y * z) % 4 == 0 and _fits(_opposite(y, z, deg), y, z):
							pairs.append([y, z])
				var p: Array = rng.pick(pairs)
				sy = p[0]
				sz = p[1]
				ax = deg
				sx = _opposite(sy, sz, ax)
				exact = ex_mul([Q.new(p[0] * p[1], 2), 1], sin_of(deg))
				ask = "area"
			else:
				var c: Array = rng.pick(_whole_cosine_rule())
				ax = c[0]
				sy = c[1]
				sz = c[2]
				sx = c[3]
				exact = [Q.new(c[3]), 1]
				ask = lower(X)
			ay = rad_to_deg(acos(clampf((sx * sx + sz * sz - sy * sy) / (2.0 * sx * sz), -1.0, 1.0)))
			shown.sides = {lower(Y): int(sy), lower(Z): int(sz)}
			shown.angles = {X: int(ax)}
		"sss":
			var c: Array = rng.pick(_whole_cosine_rule().filter(func(t): return t[3] <= SIDE_MAX))
			ax = c[0]
			sy = c[1]
			sz = c[2]
			sx = c[3]
			ay = rad_to_deg(acos((sx * sx + sz * sz - sy * sy) / (2.0 * sx * sz)))
			shown.sides = {lower(X): int(sx), lower(Y): int(sy), lower(Z): int(sz)}
			exact = [Q.new(c[0]), 1]
			ask = X
		"aas":
			variant = "sum" if rng.chance(0.5) else "pair"
			# [X, the other shown angle, Y]: Y given (pair) or 180° − X − Z (sum), never X.
			var combos: Array = []
			for a in NICE:
				for o in NICE:
					var b: int = o if variant == "pair" else 180 - a - o
					var c: int = 180 - a - b
					if b == a or not b in NICE or c < ANGLE_MIN or c > ANGLE_MAX:
						continue
					combos.append([a, o, b])
			var combo: Array = rng.pick(combos)
			var ratio := ex_div(sin_of(combo[2]), sin_of(combo[0]))
			var xs: Array = range(SIDE_MIN, SIDE_MAX + 1).filter(func(v): return (ratio[0] as Q).mul(v).is_int())
			sx = rng.pick(xs)
			ax = combo[0]
			ay = combo[2]
			exact = ex_mul([Q.new(int(sx)), 1], ratio)
			sy = ex_float(exact)
			shown.sides = {lower(X): int(sx)}
			shown.angles = {X: int(ax)}
			shown.angles[Y if variant == "pair" else Z] = combo[1]
			ask = lower(Y)
		"area-side":
			# z = m√r with r the root in sin X, so the area ½yz sin X = y·m·r/4 is whole.
			var deg: int = rng.pick(NICE_AREA)
			var r: int = sin_of(deg)[1]
			var picks: Array = []
			for y in range(SIDE_MIN, SIDE_MAX + 1):
				for m in range(1, SIDE_MAX + 1):
					var z := m * sqrt(float(r))
					if z < SIDE_MIN or z > SIDE_MAX or (y * m * r) % 4 != 0 or y * m * r / 4 < AREA_MIN:
						continue
					if _fits(_opposite(y, z, deg), y, z):
						picks.append([y, m])
			var p: Array = rng.pick(picks)
			sy = p[0]
			ax = deg
			exact = [Q.new(p[1]), r]
			sz = ex_float(exact)
			sx = _opposite(sy, sz, ax)
			ay = rad_to_deg(acos(clampf((sx * sx + sz * sz - sy * sy) / (2.0 * sx * sz), -1.0, 1.0)))
			shown.sides = {lower(Y): int(sy)}
			shown.angles = {X: int(ax)}
			shown.area = p[0] * p[1] * r / 4
			ask = lower(Z)
		"area-angle":
			# The area (yz/4)√r, r the root in sin X: whole for 30°, else a surd.
			var deg: int = rng.pick(NICE_AREA)
			var pairs: Array = []
			for y in range(SIDE_MIN, SIDE_MAX + 1):
				for z in range(SIDE_MIN, SIDE_MAX + 1):
					if (y * z) % 4 == 0 and y * z / 4 >= AREA_MIN and _fits(_opposite(y, z, deg), y, z):
						pairs.append([y, z])
			var p: Array = rng.pick(pairs)
			sy = p[0]
			sz = p[1]
			ax = deg
			sx = _opposite(sy, sz, ax)
			ay = rad_to_deg(acos(clampf((sx * sx + sz * sz - sy * sy) / (2.0 * sx * sz), -1.0, 1.0)))
			shown.sides = {lower(Y): int(sy), lower(Z): int(sz)}
			shown.area = p[0] * p[1] / 4
			shown.area_root = sin_of(deg)[1]
			shown.obtuse = ax > 90.0
			exact = [Q.new(deg), 1]
			ask = X
		_:
			push_error("TriangleSituation: no Paper 1 version of %s" % givens)
			return {}
	var s := _finish(givens, ask, variant, [X, Y, Z], [sx, sy, sz], ax, ay, shown)
	if s.is_empty():
		return {}
	s.paper = 1
	s.exact = exact
	s.value = ex_float(exact)
	return s


## The situation as plain strings, for the answer export.
static func export(s: Dictionary) -> Dictionary:
	var out := {}
	for key in s:
		out[key] = _plain(s[key])
	return out


static func _plain(v: Variant) -> Variant:
	if v is float:
		return String.num(v, 10)
	if v is Q:
		return v.key()
	if v is Array:
		return v.map(func(e): return _plain(e))
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _plain(v[k])
		return d
	return v
