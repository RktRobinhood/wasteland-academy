extends "res://tests/test_case.gd"
## The standard-form situation (FAL-726): t1-standard-form is built with every cell and all three
## skills, every cell makes four options with one right on each paper it can, a × 10^k is typed
## with a negative k, an answer outside 1 ≤ a < 10 is marked wrong, E-notation can't be typed, the
## superscripts have glyphs, and every misconception shows up. The SymPy checker
## (tools/check-answers) checks the maths.

const TYPE := "t1-standard-form"
const CELLS := 45


func _make(c: Dictionary, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var view := {"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 3, "all three listed skills have a question")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for paper in QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle):
			for f in ["value", "mcq"]:
				var q := _make(c, 3, f, paper)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					continue
				check_eq(q.paper, paper, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check(q.solutions[0].angle == c.angle, c.key)


func test_a_power_of_ten_is_written_for_every_k() -> void:
	check_eq(StandardFormViews.ten(5), "10⁵")
	check_eq(StandardFormViews.ten(-4), "10⁻⁴")
	check_eq(StandardFormViews.ten(1), "10¹")
	check_eq(StandardFormViews.ten(-1), "10⁻¹")
	check_eq(StandardFormViews.ten(0), "10⁰")
	check_eq(StandardFormViews.ten(-12), "10⁻¹²")


func test_the_superscripts_have_glyphs() -> void:
	check_eq(UiTheme.missing_glyphs("10⁰ 10¹ 10² 10³ 10⁴ 10⁵ 10⁶ 10⁷ 10⁸ 10⁹ 10⁻¹²"), "")


func test_an_answer_is_typed_with_a_negative_power() -> void:
	var ans := StandardFormViews.form_ans(Q.new(52, 10), -5, false)
	check(Answer.mark(ans, {"a": "5.2", "k": "-5"}).correct, "a hyphen for the minus")
	check(Answer.mark(ans, {"a": "5.2", "k": "−5"}).correct, "a minus sign")
	check(not Answer.mark(ans, {"a": "5.2", "k": "5"}).correct, "a positive power is wrong")


func test_the_right_value_with_a_outside_the_limits_is_wrong() -> void:
	var ans := StandardFormViews.form_ans(Q.new(64, 10), 6, false)
	check(Answer.mark(ans, {"a": "6.4", "k": "6"}).correct)
	check(not Answer.mark(ans, {"a": "64", "k": "5"}).correct, "64 × 10⁵")
	check(not Answer.mark(ans, {"a": "0.64", "k": "7"}).correct, "0.64 × 10⁷")


func test_a_rounded_a_is_right_to_three_figures_and_glances_at_two() -> void:
	var ans := StandardFormViews.form_ans(Q.new(32417, 10000), 5, true)
	check_eq(Answer.text(ans), "3.24 × 10⁵")
	check(Answer.mark(ans, {"a": "3.24", "k": "5"}).correct)
	check(Answer.mark(ans, {"a": "3.2", "k": "5"}).glancing, "2 s.f. is a glancing hit")


func test_e_notation_can_be_picked_but_not_typed() -> void:
	var c := {"unknown": "display-to-form", "rep": "equation", "angle": "gdc-sci"}
	for seed in range(1, 20):
		var q := _make(c, seed)
		for o in q.choices.filter(func(x): return String(x.text).contains("E")):
			check(not Answer.typable(q.answer, o.values), o.text)


func test_every_answer_a_is_between_1_and_10() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 12):
			var q := _make(c, seed)
			if q.answer.kind == "form":
				var a: Q = Q.of(q.answer.values.a)
				check(not a.lt(Q.new(1)) and a.lt(Q.new(10)), "%s seed %d: a = %s" % [c.key, seed, a.text()])


func test_a_list_has_four_different_values() -> void:
	for i in 60:
		var s: Dictionary = StandardFormSituation.generate(Seeded.new("o|%d" % i), {"ask": "order-mixed", "paper": 1})
		var seen := {}
		for row in s.list:
			seen[row[0].key()] = true
		check_eq(seen.size(), 4, "draw %d" % i)


func test_paper_1_answers_are_exact() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		if 1 in QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle):
			check(_make(c, 5, "value", 1).answer.get("exact", false), c.key)


func test_every_distractor_misconception_is_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for m in t.misconceptions:
		for u in m["in"]:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 120):
					if _make(c, seed).choices.any(func(o): return o.ref == m.ref):
						found = true
						break
			check(found, "%s never appears on %s" % [m.ref, u])


func test_the_type_is_in_every_course() -> void:
	for course in Courses.ids():
		check(TYPE in QuestionEngine.built_types(course), course)
