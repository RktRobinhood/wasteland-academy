extends "res://tests/test_case.gd"
## The motion-distance situation (FAL-739): t5-kinematics-distance is built with every catalogue
## cell and both skills, Paper 1 is whole numbers, a GDC method is Paper 2, and a v–t graph is
## read as areas. The SymPy checker checks the maths.

const TYPE := "t5-kinematics-distance"
const CELLS := 63
const SKILLS := 2


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format, "paper": paper})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), SKILLS, "every skill the catalogue lists has a question")


func test_every_cell_makes_a_question_with_four_different_options() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in range(1, 7):
				var q := _make(c.unknown, c.rep, c.angle, seed, f)
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.choices.size(), 4, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s: two options read the same" % c.key)


func test_a_gdc_method_is_paper_2_and_integrating_by_hand_paper_1() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.angle.begins_with("gdc-"):
			check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2], c.key)
		if c.angle == "integrate-with-constant":
			check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [1], c.key)


func test_the_same_unknown_is_a_polynomial_on_paper_1_and_a_model_on_paper_2() -> void:
	var one := _make("position-at-time", "equation", "start-plus-change", 3, "mcq", 1)
	check_eq(one.situation.fam, "poly")
	var two := _make("position-at-time", "equation", "start-plus-change", 3, "mcq", 2)
	check(two.situation.fam in ["pulse", "wave", "damped"], two.situation.fam)


func test_an_antiderivative_matches_each_velocity() -> void:
	var cases := [
		{"fam": "pulse", "A": 7, "B": 2, "k": Q.new(1, 5)},
		{"fam": "wave", "A": 7, "B": 2, "w": Q.new(4, 5)},
		{"fam": "damped", "A": 7, "k": Q.new(1, 5), "w": Q.new(4, 5)},
		{"fam": "poly", "vc": [3, -12, 9]},
	]
	var h := 1e-5
	for s in cases:
		var v := MotionSituation.v_of(s)
		for t in [0.5, 1.7, 3.2]:
			var slope := (MotionDistanceSituation.anti(s, t + h) - MotionDistanceSituation.anti(s, t - h)) / (2.0 * h)
			check(absf(slope - v.call(t)) < 1e-6, "%s: the antiderivative is not v" % s.fam)


func test_a_hand_case() -> void:
	# v(t) = 3(t − 1)(t − 3), with s(t) = t³ − 6t² + 9t: 4 m out, 4 m back and 20 m out again.
	var s := {"fam": "poly", "vc": [3, -12, 9], "T": 5}
	MotionSituation.features(s)
	var legs := MotionDistanceSituation.legs(s, 0.0, 5.0)
	check_eq(legs.size(), 3)
	check(absf(legs[0] - 4.0) < 1e-6 and absf(legs[1] + 4.0) < 1e-6 and absf(legs[2] - 20.0) < 1e-6, "the legs are %s" % [legs])
	check(absf(MotionDistanceSituation.total(legs) - 28.0) < 1e-6, "the distance")
	check(absf(MotionDistanceSituation.change(s, 0.0, 5.0) - 20.0) < 1e-6, "the net displacement")


func test_a_graph_breaks_at_a_corner_on_the_axis() -> void:
	for seed in range(1, 40):
		var q := _make("distance-from-graph", "graph", "area-under-v-t", seed)
		var ys: Array = q.situation.ys
		for i in ys.size() - 1:
			check(int(ys[i]) * int(ys[i + 1]) >= 0, "a piece crosses the axis")
		check_eq(q.graph.x_name, "t")
		check_eq(q.graph.y_name, "v")


func test_a_return_question_comes_out_both_ways() -> void:
	var said := {}
	for seed in range(1, 30):
		var q := _make("does-it-return", "equation", "start-plus-change", seed)
		said[q.situation.back] = true
	check_eq(said.size(), 2, "the answer can't always be the same")


func test_a_graph_question_shows_its_graph() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.rep == "graph":
			var q := _make(c.unknown, c.rep, c.angle, 2)
			check(q.graph != null and not q.graph.curves.is_empty(), c.key + " has no graph")
