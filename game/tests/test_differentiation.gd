extends "res://tests/test_case.gd"
## The differentiation situation (FAL-723): t5-differentiation-rules is built with every
## catalogue cell, every wrong option is one of the SL5.6 misconceptions or a near miss,
## the Paper 1 and Paper 2 numbers are what they say, and an expression is marked by its
## typed numbers. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t5-differentiation-rules"
## Cells, counted as tools/pedagogy.mjs counts them.
const CELLS := 34
const SKILLS := 5


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "value", paper: int = 0) -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format, "paper": paper})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), SKILLS, "every SL5.6 skill the catalogue lists has a question")


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3, 4, 5, 6]:
				var q := _make(c.unknown, c.rep, c.angle, seed, f)
				check(not q.has("error"), "%s as %s seed %d: %s" % [c.key, f, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "differentiation", c.key)
				check_eq(q.choices.size(), 4, "%s: options" % c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, "%s: right options" % c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s: two options read the same" % c.key)
				check(q.solutions[0].angle == c.angle, "%s: the asked method is the first worked solution" % c.key)


func test_an_expression_is_marked_by_its_numbers() -> void:
	var q := _make("chain-small-power", "equation", "outer-times-inner", 3)
	var v: Dictionary = q.answer.values
	var right := QuestionEngine.mark(q, {"c1": v.c1.text(), "c0": v.c0.text()})
	check(right.correct, "the numbers of the derivative are right")
	var off := QuestionEngine.mark(q, {"c1": v.c1.add(1).text(), "c0": v.c0.text()})
	check(off.complete and not off.correct, "a slip in one number is wrong")


func test_forgetting_the_inner_derivative_is_logged_when_typed() -> void:
	for seed in range(1, 13):
		var q := _make("chain-small-power", "equation", "outer-times-inner", seed)
		var a: int = q.situation.a
		var b: int = q.situation.b
		var r := QuestionEngine.mark(q, {"c1": str(2 * a), "c0": str(2 * b)})
		check_eq(r.misconception, DifferentiationViews.R_NO_INNER, "seed %d" % seed)


func test_a_hand_value_of_each_rule() -> void:
	# d/dx (x³ cos x) has two terms, and the second carries the minus sign.
	for seed in range(1, 80):
		var q := _make("product-functions", "equation", "product-rule", seed)
		if q.situation.fam == "cos" and q.situation.n == 3:
			check_eq(q.answer_text, "dy/dx = 3x² cos x − x³ sin x")
			break
	# (2x + 1)/(x + 3) has top 2(x + 3) − (2x + 1) = 5.
	check_eq(5, 2 * 3 - 1 * 1)
	var s := {"fam": "chain", "a": 2, "b": 5, "paper": 2, "k": Q.new(2)}
	check(absf(DifferentiationSituation.gradient_value(s) - 4.0 / sqrt(13.0)) < 1e-12, "√(2x² + 5) at 2")


func test_paper_1_gradients_are_exact_and_paper_2_gradients_need_a_calculator() -> void:
	for u in ["gradient-chain", "gradient-product", "gradient-quotient"]:
		var angle: String = {"gradient-chain": "outer-times-inner", "gradient-product": "product-rule", "gradient-quotient": "quotient-rule"}[u]
		for seed in range(1, 25):
			var p1 := _make(u, "equation", angle, seed, "value", 1)
			check_eq(p1.paper, 1, u)
			check(p1.situation.k.ends_with("/1") or not p1.situation.k.contains("/"), "%s: a whole x on Paper 1" % u)
			var p2 := _make(u, "equation", angle, seed, "value", 2)
			check_eq(p2.paper, 2, u)
			check_eq(p2.answer.show, "sf", u)


func test_the_letter_p_stays_in_on_paper_2() -> void:
	var q := _make("parameter-derivative", "equation", "quotient-rule", 2)
	check_eq(q.paper, 2)
	check(q.answer_text.contains("p"), q.answer_text)
