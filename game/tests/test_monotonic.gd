extends "res://tests/test_case.gd"
## The monotonic situation (FAL-723): t5-increasing-decreasing is built with every catalogue
## cell, the GDC methods are Paper 2, an interval gives neither shape away, a parameter's bound
## is whole, and a quotient's f′ keeps the sign of its top. The SymPy checker
## (tools/check-answers) checks the maths.

const TYPE := "t5-increasing-decreasing"
const CELLS := 25
const SKILLS := 4


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), SKILLS, "every SL5.2 skill the catalogue lists has a question")


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
		if c.angle.begins_with("gdc-") or c.unknown == "interval-gdc":
			check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2], c.key)


func test_an_interval_is_marked_in_either_order_and_the_shape_counts() -> void:
	var q := _make("interval-from-equation", "equation", "solve-inequality", 3, "value")
	var v: Dictionary = q.answer.values
	check(QuestionEngine.mark(q, {"shape": v.shape, "lo": v.lo.text(), "hi": v.hi.text()}).correct, "in order")
	check(QuestionEngine.mark(q, {"shape": v.shape, "lo": v.hi.text(), "hi": v.lo.text()}).correct, "swapped")
	var other := MonotonicViews.other(v.shape)
	check(not QuestionEngine.mark(q, {"shape": other, "lo": v.lo.text(), "hi": v.hi.text()}).correct, "the other side")


func test_a_hand_case() -> void:
	# f′(x) = 3(x − 1)(x − 3) is negative between its roots.
	var s := {"fam": "cubic", "A": 1, "p": 1, "q": 3, "d": 0, "coeffs": [1, -6, 9, 0], "want": "decreasing"}
	check_eq(MonotonicViews.dec_shape(s), "between")
	check_eq(MonotonicViews.df_at(s, 2).text(), "−3")


func test_a_parameter_keeps_f_prime_on_one_side() -> void:
	for seed in range(1, 25):
		var q := _make("parameter-discriminant", "equation", "discriminant-condition", seed)
		var n: int = q.situation.n
		check_eq(q.answer_text, "−%d ≤ k ≤ %d" % [3 * n, 3 * n])


func test_a_quotient_keeps_the_sign_of_its_top() -> void:
	# f(x) = (ax + b)/(cx + d) has f′(x) = (ad − bc)/(cx + d)²: one sign either side of the gap.
	var t := QuestionEngine.type_of(TYPE)
	check_eq(QuestionEngine.cell_papers(t, "quotient-sign", "equation", "sum-of-positive-terms"), [1, 2])
	for seed in range(1, 25):
		var q := _make("quotient-sign", "equation", "sum-of-positive-terms", seed)
		var s: Dictionary = q.situation
		check_eq(s.D, s.a * s.d - s.b * s.c)
		check(q.answer_text.begins_with("f′(x) = %s/" % Fmt.num(s.D)), q.answer_text)
		check(q.answer_text.ends_with("f is " + ("increasing" if s.D > 0 else "decreasing")), q.answer_text)
