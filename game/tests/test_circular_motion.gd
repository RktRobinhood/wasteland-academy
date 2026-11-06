extends "res://tests/test_case.gd"
## The circular-motion situation (FAL-753): t3-circular-motion is built with every cell on Paper 2.
## Values match sums done by hand, an exact answer stays exact, a figure is the chord in the words,
## and every tag shows up as an option. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t3-circular-motion"
const CELLS := 101


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _draw(ask: String, i: int, rep: String = "words") -> Dictionary:
	return CircularMotionSituation.generate(Seeded.new("%s|%s|%d" % [ask, rep, i]), {"ask": ask, "rep": rep})


func test_the_type_is_built_with_every_cell_on_paper_2() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2], c.key)


func test_every_method_of_the_skill_has_a_cell() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		seen[c.angle] = true
	for m in ["multiply-factor", "fraction-of-turn", "landmarks"]:
		check(seen.has(m), "%s has no cell" % m)


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "circular-motion", c.key)
				check_eq(q.paper, 2, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.solutions[0].angle, c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps in %s" % [c.key, sol.steps.size(), sol.name])


func test_the_sums_match_hand_values() -> void:
	# r = 10, d = 5: half of angle AOB is arccos(1/2) = π/3, so the angle is 2π/3.
	var s := {"r": Q.new(10), "d": Q.new(5), "src": "T", "T": 12}
	check(absf(CircularMotionSituation.phi(s) - PI / 3.0) < 1e-9)
	# One turn in 12 s is π/6 a second, so 2π/3 takes 4 s.
	check(absf(CircularMotionSituation.rate(s) - PI / 6.0) < 1e-9)
	check(absf(2.0 * CircularMotionSituation.phi(s) / CircularMotionSituation.rate(s) - 4.0) < 1e-9)
	# 30 revolutions a minute is π radians a second, one turn in 2 s.
	var n := {"src": "n", "n": 30}
	check(absf(CircularMotionSituation.rate(n) - PI) < 1e-9)
	check(absf(CircularMotionSituation.period(n) - 2.0) < 1e-9)
	# 90 degrees a second is π/2, one turn in 4 s.
	check(absf(CircularMotionSituation.rate({"src": "k", "k": 90}) - PI / 2.0) < 1e-9)


func test_an_exact_chord_is_exact() -> void:
	for i in 40:
		var s := _draw("chord-time-exact", i)
		check(not s.is_empty(), "draw %d" % i)
		var p: Array = CircularMotionSituation.LANDMARK[s.ratio].phi
		var share := Q.new(p[0], p[1])
		var t: Q = share.mul(s.T)
		check(t.is_int(), "time %s on draw %d" % [t.text(), i])
		check(absf(CircularMotionSituation.dist(s) / s.r.to_float() - cos(PI * share.to_float())) < 1e-9, "draw %d" % i)


func test_a_chord_is_clear_of_a_landmark_cosine() -> void:
	for ask in CircularMotionSituation.CHORD:
		for i in 25:
			var s := _draw(ask, i)
			check(not s.is_empty(), "%s %d" % [ask, i])
			var c: float = s.d.to_float() / s.r.to_float()
			check(c >= CircularMotionSituation.RATIO_LO and c <= CircularMotionSituation.RATIO_HI, "%s %d: %f" % [ask, i, c])
			for mark in [0.5, sqrt(0.5), sqrt(0.75)]:
				check(absf(c - mark) >= CircularMotionSituation.RATIO_GAP, "%s %d: %f" % [ask, i, c])


func test_the_figure_is_the_chord_or_the_angle() -> void:
	var cells := QuestionEngine.cells(false, [TYPE]).filter(func(c): return c.rep == "diagram")
	check(not cells.is_empty())
	for c in cells:
		var q := _make(c, 2)
		check(q.graph != null, c.key)
		if q.graph.kind == "region":
			check_eq(q.graph.shape, "sweep", c.key)
			check(q.graph.d > 0.0 and q.graph.d < q.graph.r, c.key)
		else:
			check_eq(q.graph.kind, "sector", c.key)
			check(q.graph.theta > 0.0 and q.graph.theta < TAU, c.key)


func test_every_tag_shows_up_as_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 8):
			var q := _make(c, seed)
			for o in q.choices:
				if o.ref != "":
					seen[o.ref] = true
	for m in t.misconceptions:
		check(seen.has(m.ref), "%s never shows" % m.ref)
