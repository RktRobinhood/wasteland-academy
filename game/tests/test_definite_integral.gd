extends "res://tests/test_case.gd"
## The definite-integral situation (FAL-724): t5-definite-integral-area is built with every
## catalogue cell, the GDC methods are Paper 2, a region is shaded on its figure, and the
## exact arithmetic matches hand values. The SymPy checker checks the maths.

const TYPE := "t5-definite-integral-area"
const CELLS := 43
const SKILLS := 5


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


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


func test_a_gdc_method_is_paper_2() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2] if c.angle.begins_with("gdc-") else [1], c.key)


func test_a_region_is_shaded_on_its_figure() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.rep != "graph":
			continue
		var q := _make(c.unknown, c.rep, c.angle, 5)
		check(q.graph != null and not q.graph.shade.is_empty(), c.key + " has no shaded region")
		for region in q.graph.shade:
			check(region.size() >= 3, c.key)


func test_the_exact_integral_against_hand_values() -> void:
	# ∫ from 1 to 3 of (3x² − 2x + 1) dx = 27 − 9 + 3 − (1 − 1 + 1) = 20
	check_eq(DefiniteIntegralSituation.integral([3, -2, 1], 1, 3).text(), "20")
	# ∫ from 0 to 1 of x² dx = 1/3
	check_eq(DefiniteIntegralSituation.integral([1, 0, 0], 0, 1).text(), "1/3")
	check_eq(DefiniteIntegralSituation.at([3, -2, 1], 2).text(), "9")


func test_simpson_against_a_hand_value() -> void:
	var f := func(x: float) -> float: return sin(x)
	check(absf(DefiniteIntegralSituation.simpson(f, 0.0, PI) - 2.0) < 1e-9, "∫ sin x from 0 to π")


func test_a_tangent_region_is_a_twelfth() -> void:
	# y = (x − 1)², tangent at x = 3: a p³/12 = 8/12.
	var s := {"a": 1, "r": 1, "p": 2, "paper": 1, "ask": "region-tangent", "fam": ""}
	var b := DefiniteIntegralViews.new().u_region_tangent("graph", s, Seeded.new("t"))
	check_eq(b.answer.values.text, "Area = 2/3")


func test_a_wrong_value_can_carry_plus_c_or_rate_units() -> void:
	var q := _make("evaluate-linear", "equation", "antiderivative-substitute", 3)
	check(q.choices.any(func(o): return o.text == q.answer_text + " + C"), "an option with + C")
	var r := _make("total-from-rate", "words", "antiderivative-of-rate", 3)
	check(r.choices.any(func(o): return " per " in o.text), "an option in rate units")
