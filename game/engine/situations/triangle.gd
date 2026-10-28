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


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var givens: String = need.get("givens", "sas")
	for i in TRIES:
		var s := _draw(rng, givens, need)
		if s.is_empty() or not _clean(s):
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
	return Answer.rounds_clearly(s.value, EDGE)


## The situation as plain strings, for the answer export.
static func export(s: Dictionary) -> Dictionary:
	var out := {}
	for key in s:
		out[key] = _plain(s[key])
	return out


static func _plain(v: Variant) -> Variant:
	if v is float:
		return String.num(v, 10)
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _plain(v[k])
		return d
	return v
