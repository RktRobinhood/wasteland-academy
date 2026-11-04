extends "res://tests/test_case.gd"
## The concavity situation (FAL-723): t5-concavity is built with every catalogue cell, a
## matching question is four graphs with one right, the GDC methods are Paper 2, and a Paper 2
## answer to concave-gdc is not a whole number. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t5-concavity"
const CELLS := 22
const SKILLS := 3


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), SKILLS, "every SL5.7 skill the catalogue lists has a question")


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
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)


func test_matching_is_four_graphs() -> void:
	for u in [["match-derivative", "graph", "degree-drop"], ["match-second-derivative", "graph", "degree-drop"], ["match-from-signs", "table", "sign-tables"]]:
		for seed in range(1, 13):
			var q := _make(u[0], u[1], u[2], seed)
			check_eq(q.format, "pick-the-graph", u[0])
			check_eq(q.graphs.size(), 4, u[0])


func test_a_shifted_copy_is_logged_as_that_mistake() -> void:
	var q := _make("match-derivative", "graph", "turning-points-to-zeros", 2)
	var shifted: Array = q.choices.filter(func(o): return o.mistake == "shifted")
	check_eq(shifted.size(), 1)
	check_eq(shifted[0].ref, ConcavityViews.R_SHIFTED)


func test_a_gdc_method_is_paper_2() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.angle.begins_with("gdc-") or c.unknown == "concave-gdc":
			check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2], c.key)


func test_concave_gdc_needs_a_calculator() -> void:
	for seed in range(1, 40):
		var q := _make("concave-gdc", "equation", "sign-of-second-derivative", seed, "value")
		check(q.situation.b != q.situation.c, "ln 1 is 0: no calculator needed")


func test_a_hand_second_derivative() -> void:
	# x² ln x: f′ = 2x ln x + x, f″ = 2 ln x + 3, which at e is 5.
	var s := {"fam": "ln", "a": 1, "c": 2, "k": Q.new(27183, 10000)}
	check(absf(ConcavitySituation.second_value(s) - (2.0 * log(2.7183) + 3.0)) < 1e-9, "2 ln x + 3")
