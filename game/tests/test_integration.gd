extends "res://tests/test_case.gd"
## The integration situation (FAL-724): t5-indefinite-integral is built with every catalogue
## cell, each option reads differently, + C is part of the answer, and the method sets the
## answer's shape where two shapes are both right. The SymPy checker checks the maths.

const TYPE := "t5-indefinite-integral"
const CELLS := 36
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


func test_an_answer_ends_in_plus_c() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(_make(c.unknown, c.rep, c.angle, 2).answer_text.ends_with(" + C"), c.key)


func test_a_hand_case() -> void:
	# ∫ (6x² − 4x + 1) dx = 2x³ − 2x² + x + C
	var s := {"a": 6, "b": -4, "c": 1, "ask": "power-polynomial", "paper": 1, "fam": ""}
	var v := IntegrationViews.new()
	var b := v.u_power_polynomial("equation", s, Seeded.new("t"))
	check_eq(b.answer.values.text, "2x³ − 2x² + x + C")
	check_eq(b.lines[0], "∫ (6x² − 4x + 1) dx")


func test_a_wrong_number_is_marked_wrong() -> void:
	var q := _make("linear-exp", "equation", "divide-by-a", 4, "value")
	var v: Dictionary = q.answer.values
	check(QuestionEngine.mark(q, {"c0": v.c0.text(), "c1": v.c1.text()}).correct, "the right numbers")
	check(not QuestionEngine.mark(q, {"c0": "1", "c1": v.c1.text()}).correct, "no division by a")


func test_the_method_sets_the_shape_of_the_answer() -> void:
	check(")³" in _make("linear-square", "equation", "divide-by-a", 3).answer_text, "a bracket, cubed")
	check(not ")³" in _make("linear-square", "equation", "expand-first", 3).answer_text, "a polynomial")
	check("sin²" in _make("rewrite-trig-product", "equation", "inspection-alternative", 3).answer_text, "sin² x")
	check("cos(2x)" in _make("rewrite-trig-product", "equation", "identity-substitution", 3).answer_text, "cos 2x")


func test_a_sum_is_in_brackets_and_a_bracket_is_not_doubled() -> void:
	check_eq(IntegrationViews.wrapped("x² + 1"), "(x² + 1)")
	check_eq(IntegrationViews.wrapped("(2x + 1)²"), "(2x + 1)²")
	check_eq(IntegrationViews.wrapped("4x/(x² + 1)"), "4x/(x² + 1)")
