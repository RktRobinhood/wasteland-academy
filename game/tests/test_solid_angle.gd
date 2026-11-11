extends "res://tests/test_case.gd"
## The solid-angle situation (FAL-754): t3-3d-angle is built with every cell and all six methods
## of SL3.1.angle-line-plane and SL3.1.angle-two-lines. landmark-angle is Paper 1 and exact, every
## other cell Paper 2 to 3 s.f. Angles match sums done by hand, a Paper 2 angle is clear of a
## rounding edge and in range, a figure marks what is asked, and every tag shows up as an option.
## The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t3-3d-angle"
const CELLS := 49


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _draw(ask: String, i: int, rep: String = "diagram") -> Dictionary:
	return SolidAngleSituation.generate(Seeded.new("%s|%s|%d" % [ask, rep, i]), {"ask": ask, "rep": rep})


func _near(a: float, b: float, msg: String = "") -> void:
	check(absf(a - b) < 1e-4, "%s: %s is not %s" % [msg, a, b])


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var want: Array = [1] if c.unknown == "landmark-angle" else [2]
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), want, c.key)


func test_every_method_of_the_skills_is_an_angle() -> void:
	var angles := {}
	for a in QuestionEngine.type_of(TYPE).angles:
		angles[a.method] = true
	for m in ["project-and-tan", "sin-with-length", "coordinates", "three-sides-cosine", "spot-right-angle", "isosceles-split"]:
		check(angles.has(m), m)


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "solid-angle", c.key)
				check_eq(q.paper, 1 if c.unknown == "landmark-angle" else 2, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.solutions[0].angle, c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps in %s" % [c.key, sol.steps.size(), sol.name])


func test_the_angles_match_hand_values() -> void:
	var base := {"solid": "", "l": 0, "w": 0, "h": 0, "r": 0, "sl": 0, "given": "", "edge": "", "corner": "", "pair": "", "A": [], "B": [], "C": [], "shape": ""}
	var s := base.merged({"ask": "cuboid-diagonal-base", "l": 9, "w": 11, "h": 6}, true)
	# tan θ = 6 ÷ √(9² + 11²).
	_near(SolidAngleSituation.angle(s), 22.887454, "cuboid to base")
	# A pyramid 11 by 8, height 8: M on DA is 11 ÷ 2 from X, M on AB is 8 ÷ 2 from X.
	s = base.merged({"ask": "pyramid-face-base", "l": 11, "w": 8, "h": 8, "edge": "DA"}, true)
	_near(SolidAngleSituation.angle(s), 55.491477, "face DA")
	s.edge = "AB"
	_near(SolidAngleSituation.angle(s), 63.434949, "face AB")
	# A pyramid 6 by 8, height 12: half the base diagonal is 5, so tan θ = 12 ÷ 5.
	s = base.merged({"ask": "pyramid-edge-base", "l": 6, "w": 8, "h": 12}, true)
	_near(SolidAngleSituation.angle(s), 67.380135, "slant edge")
	# A square pyramid of side 8 and height 15: VA² = 257, cos AVB = (514 − 64) ÷ 514.
	s = base.merged({"ask": "pyramid-apex-angle", "l": 8, "w": 8, "h": 15, "pair": "AVB"}, true)
	_near(SolidAngleSituation.angle(s), 28.897409, "apex")
	s = base.merged({"ask": "cone-slant-base", "given": "rh", "r": 3, "h": 4}, true)
	_near(SolidAngleSituation.angle(s), 53.130102, "cone")
	# A 3 by 4 by 12 box: AG = 13, so AM = MB = 6.5 with AB = 3, and cos GAE = 12 ÷ 13.
	s = base.merged({"ask": "cuboid-two-diagonals", "l": 3, "w": 4, "h": 12, "edge": "AB"}, true)
	_near(SolidAngleSituation.angle(s), 26.684728, "two diagonals")
	s = base.merged({"ask": "cuboid-diagonal-edge", "l": 3, "w": 4, "h": 12, "edge": "AE"}, true)
	_near(SolidAngleSituation.angle(s), 22.619865, "diagonal and edge")
	s = base.merged({"ask": "coords-line-plane", "A": [1, 2, 0], "B": [4, 6, 7]}, true)
	_near(SolidAngleSituation.angle(s), 54.462322, "line and plane")
	s = base.merged({"ask": "coords-angle-abc", "A": [-4, -7, 2], "B": [9, 1, 6], "C": [5, 1, 3]}, true)
	_near(SolidAngleSituation.angle(s), 35.789888, "angle ABC")


func test_a_paper_2_angle_is_clean_and_in_range() -> void:
	for u in SolidAngleSituation.TWO_LINES + ["cuboid-diagonal-base", "pyramid-edge-base", "pyramid-face-base", "cone-slant-base", "coords-line-plane"]:
		for i in 40:
			var s := _draw(u, i, "equation" if u.begins_with("coords") else "diagram")
			check(not s.is_empty(), "%s %d" % [u, i])
			var t: float = s.theta
			check(Answer.rounds_clearly(t, SolidAngleSituation.EDGE), "%s %d: %s" % [u, i, t])
			for mark in [30.0, 45.0, 60.0]:
				check(absf(t - mark) >= SolidAngleSituation.LANDMARK_GAP, "%s %d: %s" % [u, i, t])
			if u in SolidAngleSituation.TWO_LINES:
				check(t >= SolidAngleSituation.WIDE_LOW and t <= SolidAngleSituation.WIDE_HIGH and absf(t - 90.0) >= SolidAngleSituation.RIGHT_GAP, "%s %d: %s" % [u, i, t])
			else:
				check(t >= SolidAngleSituation.LOW and t <= SolidAngleSituation.HIGH, "%s %d: %s" % [u, i, t])


func test_a_landmark_angle_is_exact() -> void:
	for i in 60:
		var s := _draw("landmark-angle", i)
		check_eq(s.paper, 1)
		check(s.theta in [30.0, 45.0, 60.0], "%d: %s" % [i, s.theta])


func test_a_right_angle_cell_has_its_right_angle_at_a_or_c() -> void:
	for i in 60:
		var s := _draw("coords-right-angle", i, "equation")
		var at := s.right as String
		var other := "C" if at == "A" else "A"
		var u := SolidAngleSituation.minus(s.B, s[at])
		var v := SolidAngleSituation.minus(s[other], s[at])
		check_eq(SolidAngleSituation.dot(u, v), 0, str(i))


func test_a_figure_marks_what_is_asked() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(e): return e.rep == "diagram"):
		var q := _make(c, 1)
		check(q.graph != null and q.graph.kind == "space", c.key)
		check(q.graph.lines.any(func(ln): return ln.asked), "%s: nothing is marked" % c.key)
		for ln in q.graph.lines:
			check(q.graph.pts.has(ln.a) and q.graph.pts.has(ln.b), "%s: %s%s" % [c.key, ln.a, ln.b])


func test_the_map_strings_quote_no_numbers() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for m in t.misconceptions:
		check(RegEx.create_from_string("\\d").search(m.text) == null, m.text)


func test_every_tag_shows_up_as_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 16):
			var q := _make(c, seed)
			for o in q.choices:
				if o.ref != "":
					seen[o.ref] = true
	for i in t.misconceptions.size():
		var ref: String = t.misconceptions[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never shows" % ref)
