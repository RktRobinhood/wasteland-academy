extends "res://tests/test_case.gd"
## The reading pass on the triangle situation (t3-sine-cosine-rule, t3-triangle-area and
## t3-ambiguous-case), FAL-1605 / GitHub #193: each test pins one fixed finding, over
## seeds 1..30 and every cell of the unknown it is about.

const SC := "t3-sine-cosine-rule"
const AREA := "t3-triangle-area"
const AMB := "t3-ambiguous-case"
const SEEDS := 30
const OUTSIDE := "is obtuse, so the height falls outside the triangle"


## Every question of an unknown, for each cell, seed and paper the cell has.
func _each(type: String, unknown: String, format: String = "mcq") -> Array:
	var out: Array = []
	for c in QuestionEngine.cells(false, [type]).filter(func(c): return c.unknown == unknown):
		for paper in QuestionEngine.cell_papers(QuestionEngine.type_of(type), c.unknown, c.rep, c.angle):
			for seed in range(1, SEEDS + 1):
				var q := QuestionEngine.make({"type": type, "unknown": unknown, "rep": c.rep, "angle": c.angle, "seed": seed,
					"format": format, "paper": paper})
				if q.has("error"):
					fail("%s seed %d: %s" % [c.key, seed, q.error])
					break
				out.append(q)
	return out


func _label(q: Dictionary) -> String:
	return "%s paper %d seed %d" % [q.cell, q.paper, q.view.seed]


## The steps of the method a question is set in (its cell's angle).
func _steps(q: Dictionary, method: String) -> Array:
	for sol in q.solutions:
		if sol.angle == method:
			return sol.steps.map(func(st): return Step.text(st))
	return []


## The situation's angle at a vertex, in degrees.
func _deg(q: Dictionary, L: String) -> float:
	return float(q.situation.angles[L])


func _side(q: Dictionary, l: String) -> float:
	return float(q.situation.sides[l])


func _v(values: Dictionary) -> float:
	var v: Variant = values.v
	return (v as Q).to_float() if v is Q else float(str(v))


## A Paper 2 option's value and the answer's, to compare.
func _near(a: float, b: float, tol: float = 1e-6) -> bool:
	return absf(a - b) <= tol * maxf(1.0, absf(b))


# ── t3-sine-cosine-rule ──────────────────────────────────────

## side-cosine-rule, drop-perpendicular: with the given angle obtuse, F lies beyond the
## vertex, and the working said "In the right triangle AFC: CF = 16 sin 101°" and
## "FB = 9 − 16 cos 101°", a right triangle with a 101° angle. It now says F is on the
## line extended, works in the right triangle's own 180° − X, and adds FX to XY.
func test_perpendicular_from_an_obtuse_angle_lands_beyond_it() -> void:
	var obtuse := 0
	for q in _each(SC, "side-cosine-rule"):
		var X: String = q.situation.X
		var d := _deg(q, X)
		var steps := _steps(q, "drop-perpendicular")
		check(not steps.is_empty(), _label(q) + ": no drop-perpendicular working")
		if d <= 90.0:
			continue
		obtuse += 1
		var label := _label(q)
		var e := str(roundi(180.0 - d))
		check(steps.any(func(t): return t.contains("extended beyond " + X) and t.contains("= %s°" % e)),
			"%s: the working does not say F lies beyond %s" % [label, X])
		for t in steps:
			check(not (t.contains("In the right triangle") and t.contains("sin %d°" % roundi(d))),
				"%s: a right triangle with the angle %d°: %s" % [label, roundi(d), t])
			check(not t.contains("cos %d°" % roundi(d)), "%s: the obtuse cosine in the perpendicular: %s" % [label, t])
	check(obtuse >= 20, "only %d side-cosine-rule questions with an obtuse angle" % obtuse)


## angle-sine-rule and side-sine-rule, drop-altitude: "in the right triangle with
## hypotenuse a, h = 6 sin 113°" put an obtuse angle in a right triangle. Where an angle
## the height is worked from is obtuse, a step now says the height falls outside, in a
## right triangle with 180° minus it, whose sine is the same.
func test_altitude_from_an_obtuse_angle_says_it_falls_outside() -> void:
	var obtuse := 0
	for spec in [[SC, "angle-sine-rule", "drop-altitude"], [SC, "side-sine-rule", "drop-altitude"],
			[AMB, "largest-angle", "altitude-test"], [AREA, "area-from-two-sides", "base-height"],
			[AREA, "side-from-area", "base-height"]]:
		for q in _each(spec[0], spec[1]):
			var used: Array = [q.situation.X]
			if spec[1] == "side-sine-rule":
				used.append(q.situation.Y)
			var obt: Array = used.filter(func(L): return _deg(q, L) > 90.0)
			var steps := _steps(q, spec[2])
			var says: bool = steps.any(func(t): return t.contains(OUTSIDE))
			if obt.is_empty():
				check(not says, "%s: an outside step with no obtuse angle" % _label(q))
				continue
			obtuse += 1
			var d := roundi(_deg(q, obt[0]))
			check(steps.any(func(t): return t.contains(OUTSIDE) and t.contains("180° − %d° = %d°" % [d, 180 - d])),
				"%s (%s): no step says the height from the %d° angle falls outside" % [_label(q), spec[2], d])
	check(obtuse >= 50, "only %d questions with an obtuse angle under the height" % obtuse)


## angle-sine-rule: the filler sin⁻¹(b/a) (the sine of the given angle left out) sat
## next to the answer when that angle is near 90° (55.4° beside 55.1°). No filler of a
## Paper 2 question in these three types is now within 5% of the answer.
func test_no_filler_sits_next_to_the_answer() -> void:
	var seen := 0
	for type in [SC, AREA, AMB]:
		for c in QuestionEngine.cells(false, [type]):
			for q in _each(type, c.unknown):
				if q.paper != 2 or not q.answer.values.has("v"):
					continue
				var key := _v(q.answer.values)
				for o in q.choices.filter(func(o): return o.get("src", "") == "fillers"):
					seen += 1
					check(absf(_v(o.values) - key) > 0.05 * absf(key), "%s: filler %s beside %s" % [_label(q), o.text, q.answer_text])
	check(seen >= 200, "only %d fillers" % seen)


## angle-cosine-rule: the filler angle Z + 5° was the answer + 5° in an isosceles
## triangle (58.1° beside 53.1°, with sides 6, 5, 5). It takes the other angle there, and
## a filler for 2bc's 2 left out joins it, so the options no longer run short.
func test_cosine_rule_angle_filler_is_not_the_answer_plus_5() -> void:
	var isosceles := 0
	var no_two := 0
	for q in _each(SC, "angle-cosine-rule"):
		if q.paper != 2:
			continue
		var X: String = q.situation.X
		var Y: String = q.situation.Y
		var Z: String = q.situation.Z
		var key := _v(q.answer.values)
		if absf(_deg(q, Y) - key) < 1.0 or absf(_deg(q, Z) - key) < 1.0:
			isosceles += 1
		var y := _side(q, Y.to_lower())
		var z := _side(q, Z.to_lower())
		var x := _side(q, X.to_lower())
		var c := (y * y + z * z - x * x) / (y * z)
		for o in q.choices.filter(func(o): return o.get("src", "") == "fillers"):
			check(not _near(_v(o.values), key + 5.0, 1e-4), "%s: filler %s is the answer + 5°" % [_label(q), o.text])
			if absf(c) < 1.0 and _near(_v(o.values), rad_to_deg(acos(c)), 1e-4):
				no_two += 1
	check(isosceles >= 2, "only %d isosceles angle-cosine-rule questions" % isosceles)
	check(no_two >= 3, "only %d angle-cosine-rule questions offer cos⁻¹((b² + c² − a²)/(bc))" % no_two)


# ── t3-triangle-area ─────────────────────────────────────────

## side-from-area: the filler z sin X always equalled 2 × Area / y, the no-sine slip, so
## it was never shown and the options ran short (a nudged answer ± 1). It is now the
## height y sin X, given as if it were the side.
func test_side_from_area_offers_the_height_as_a_filler() -> void:
	var height := 0
	for q in _each(AREA, "side-from-area"):
		if q.paper != 2:
			continue
		var X: String = q.situation.X
		var Y: String = q.situation.Y
		var h := _side(q, Y.to_lower()) * sin(deg_to_rad(_deg(q, X)))
		var area := float(q.situation.shown.area)
		for o in q.choices.filter(func(o): return o.get("src", "") == "fillers"):
			var v := _v(o.values)
			check(_near(v, h, 1e-6) or _near(v, area / _side(q, Y.to_lower()), 1e-6),
				"%s: filler %s is neither the height nor Area / %s" % [_label(q), o.text, Y.to_lower()])
			if _near(v, h, 1e-6):
				height += 1
	check(height >= 20, "only %d side-from-area questions offer the height" % height)


## angle-from-area, acute: the fillers cos⁻¹(2 × Area / bc) and 90° − the acute angle are
## the same number, so one was never shown. The second is now 180° minus the angle with
## the ½ left out.
func test_acute_angle_from_area_fillers_differ() -> void:
	var obtuse_no_half := 0
	for q in _each(AREA, "angle-from-area"):
		if q.paper != 2 or q.situation.shown.obtuse:
			continue
		var X: String = q.situation.X
		var y := _side(q, q.situation.Y.to_lower())
		var z := _side(q, q.situation.Z.to_lower())
		var ratio := 2.0 * float(q.situation.shown.area) / (y * z)
		var target := 180.0 - rad_to_deg(asin(ratio / 2.0))
		for o in q.choices.filter(func(o): return o.get("src", "") == "fillers"):
			if _near(_v(o.values), target, 1e-6):
				obtuse_no_half += 1
	check(obtuse_no_half >= 5, "only %d acute angle-from-area questions offer 180° − sin⁻¹(Area / bc)" % obtuse_no_half)


## area-from-two-sides, Paper 1: with 30°, 45° or 135° the slips coincide (½yz is twice
## the area at 30°) and the options were filled with the answer ± 1. yz, both the ½ and
## the sine left out, now comes first.
func test_exact_area_offers_yz_before_the_answer_plus_1() -> void:
	var yz := 0
	for q in _each(AREA, "area-from-two-sides"):
		if q.paper != 1:
			continue
		var y := int(q.situation.shown.sides[q.situation.Y.to_lower()])
		var z := int(q.situation.shown.sides[q.situation.Z.to_lower()])
		for o in q.choices.filter(func(o): return o.get("src", "") == "fillers"):
			var m: Variant = o.values.get("m", o.values.get("v"))
			var r: Variant = o.values.get("r", Q.new(1))
			if (m as Q).eq(y * z) and (r as Q).eq(1):
				yz += 1
	check(yz >= 20, "only %d exact areas offer yz" % yz)
