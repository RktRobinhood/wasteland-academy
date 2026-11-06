extends "res://tests/test_case.gd"
## The log-exp-form situation (FAL-753): t1-log-exp-form is built with every cell and both skills,
## exp-log-form on Paper 1 and log-context on Paper 2. Values match sums done by hand, an answer is
## clear of a rounding edge, a very big or small amount is in standard form, a figure shows what it
## says, and every tag shows up as an option. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t1-log-exp-form"
const CELLS := 73


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _draw(ask: String, i: int, rep: String = "equation") -> Dictionary:
	return LogExpFormSituation.generate(Seeded.new("%s|%s|%d" % [ask, rep, i]), {"ask": ask, "rep": rep})


func test_the_type_is_built_with_every_cell_and_both_skills() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	var paper := {"SL1.5.exp-log-form": [1], "SL1.5.log-context": [2]}
	var skills := {}
	for u in t.unknowns:
		for s in u.skills:
			skills[s] = true
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(e): return e.unknown == u.id):
				check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), paper[s], c.key)
	check_eq(skills.size(), 2, "both skills have a question")


func test_every_method_of_both_skills_is_an_angle() -> void:
	var angles := {}
	for a in QuestionEngine.type_of(TYPE).angles:
		angles[a.method] = true
	for m in ["what-power", "rewrite-exponential", "inverse-identities", "substitute-evaluate", "invert-formula", "scale-steps"]:
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
				check_eq(q.situation_id, "log-exp-form", c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.solutions[0].angle, c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps in %s" % [c.key, sol.steps.size(), sol.name])


func test_the_sums_match_hand_values() -> void:
	# H = 10 log₁₀(I × 10⁸) at I = 10⁻⁴: 10 × 4 = 40, and back again.
	var s := {"A": Q.new(10), "d": Q.new(0), "ten": 8, "over": 1, "nat": false}
	check(absf(LogExpFormSituation.reading(s, 0.0001) - 40.0) < 1e-9)
	check(absf(LogExpFormSituation.amount(s, 40.0) - 0.0001) < 1e-12)
	# A rise of 20 is two steps of 10, so a factor of 100.
	check(absf(LogExpFormSituation.factor(s, 20.0) - 100.0) < 1e-9)
	# G = 6 − 2 log₁₀ B at B = 100 is 2.
	var g := {"A": Q.new(-2), "d": Q.new(6), "ten": 0, "over": 1, "nat": false}
	check(absf(LogExpFormSituation.reading(g, 100.0) - 2.0) < 1e-9)
	# N = 4 ln(C/25) at C = 25e is 4.
	var n := {"A": Q.new(4), "d": Q.new(0), "ten": 0, "over": 25, "nat": true}
	check(absf(LogExpFormSituation.reading(n, 25.0 * exp(1.0)) - 4.0) < 1e-9)
	# h = 1 + 2 ln(3t + 1) at t = 0 is 1; h = 1 + 2 ln 7 needs 3t + 1 = 7, so t = 2.
	var m := {"p": Q.new(1), "q": Q.new(2), "r": Q.new(3)}
	check(absf(LogExpFormSituation.level(m, 0.0) - 1.0) < 1e-9)
	check(absf(LogExpFormSituation.time_to(m, 1.0 + 2.0 * log(7.0)) - 2.0) < 1e-9)
	check_eq(LogExpFormViews.lg(2, Q.new(1, 8)), "log₂(1/8)")
	check_eq(LogExpFormViews.pw(4, Q.new(3, 2)), "4^(3/2)")


func test_paper_1_answers_are_exact() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.unknown in LogExpFormSituation.PAPER_1:
			var q := _make(c, 4, "value")
			check_eq(q.paper, 1, c.key)
			check(q.answer.exact, c.key)


func test_a_paper_2_answer_is_clear_of_an_edge() -> void:
	for i in 60:
		var s := _draw("value-from-reading", i)
		check(LogExpFormSituation.clean(LogExpFormSituation.amount(s, s.y.to_float())), "amount %d" % i)
		var t := _draw("model-time", i)
		check(LogExpFormSituation.clean(LogExpFormSituation.time_to(t, t.T.to_float())), "time %d" % i)
		var u := _draw("find-scale-constant", i)
		check(LogExpFormSituation.clean(u.found), "constant %d" % i)


func test_a_very_small_or_big_amount_is_in_standard_form() -> void:
	check_eq(LogExpFormViews.amount_ans("I = ", 3.16e-5).kind, "form")
	check_eq(LogExpFormViews.amount_ans("I = ", 3.16e7).kind, "form")
	check_eq(LogExpFormViews.amount_ans("I = ", 316.2).kind, "number")
	var seen := false
	for seed in range(1, 30):
		var q := QuestionEngine.make({"type": TYPE, "unknown": "acid-value", "rep": "equation", "angle": "invert-formula", "seed": seed, "format": "mcq"})
		if q.answer.kind == "form":
			seen = true
			check(q.answer_text.contains(" × 10"), q.answer_text)
			check(q.choices.any(func(o): return o.get("trap", false)), "a rounding trap")
	check(seen, "no acid content in standard form")


func test_a_figure_shows_what_it_says() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(e): return e.rep == "graph"):
		var q := _make(c, 2)
		check(q.graph != null, c.key)
		check_eq(q.graph.points.size(), 1, c.key)
		check(q.graph.curves[0].size() > 10, c.key)


func test_the_map_strings_quote_no_numbers() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for m in t.misconceptions:
		check(RegEx.create_from_string("\\d").search(m.text) == null, m.text)


func test_every_tag_shows_up_as_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 12):
			var q := _make(c, seed)
			for o in q.choices:
				if o.ref != "":
					seen[o.ref] = true
	for i in t.misconceptions.size():
		var ref: String = t.misconceptions[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never shows" % ref)
