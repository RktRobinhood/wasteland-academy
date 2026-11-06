extends "res://tests/test_case.gd"
## The derivative-model situation (FAL-753): t5-derivative-model-gdc is built with every cell and
## both skills, on Paper 2. Values match sums done by hand, a greatest rate is the top of the
## rate, a time really has the rate asked for, a figure is drawn from the model, and every tag
## shows up as an option. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t5-derivative-model-gdc"
const CELLS := 62


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _draw(ask: String, i: int, rep: String = "equation") -> Dictionary:
	return DerivativeModelSituation.generate(Seeded.new("%s|%s|%d" % [ask, rep, i]), {"ask": ask, "rep": rep})


func test_the_type_is_built_with_every_cell_on_paper_2() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	var skills := {}
	for u in t.unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 2, "both skills have a question")
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2], c.key)


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "derivative-model", c.key)
				check_eq(q.paper, 2, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.solutions[0].angle, c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps in %s" % [c.key, sol.steps.size(), sol.name])


func test_the_sums_match_hand_values() -> void:
	# 40te^(−0.5t) at t = 2: 40 × (1 − 1)e^(−1) = 0, its peak.
	var pulse := {"fam": "pulse", "a": Q.new(40), "k": Q.new(1, 2)}
	check(absf(DerivativeModelSituation.dy(pulse, 2.0)) < 1e-9)
	check(absf(DerivativeModelSituation.y(pulse, 2.0) - 80.0 / exp(1.0)) < 1e-9)
	# 10 + 2 ln(t + 1): the rate at t = 3 is 2/4.
	var ln := {"fam": "log", "c": Q.new(10), "a": Q.new(2), "b": Q.new(1)}
	check(absf(DerivativeModelSituation.dy(ln, 3.0) - 0.5) < 1e-9)
	# A logistic of 100 with a = 9, k = ln 9: half way at t = 1, at the rate Lk/4.
	var k := log(9.0)
	var top := DerivativeModelSituation.top_of({"mod": {"fam": "logistic", "L": Q.new(100), "a": Q.new(9), "k": Q.new(219722, 100000)}})
	check(absf(top.t - 1.0) < 1e-4)
	check(absf(top.r - 25.0 * k) < 1e-2)
	# (f/g)′ with f = 3, g = 2, f′ = 1, g′ = 4: (2 − 12)/4.
	check_eq(DerivativeModelSituation.quotient(3, 2, 1, 4).to_float(), -2.5)
	check_eq(DerivativeModelSituation.height([1, 5, 3, 7], 3), 4)
	check_eq(DerivativeModelSituation.slope([1, 5, 3, 7], 3), -1)
	check_eq(DerivativeModelSituation.two_figures(23456.0).text(), "23000")


func test_a_time_found_has_the_rate_asked_for() -> void:
	for i in 60:
		var s := _draw("time-at-rate", i)
		check(not s.is_empty(), "draw %d" % i)
		check(absf(DerivativeModelSituation.dy(s.mod, s.x) - s.k.to_float()) < 1e-6, "time %d" % i)


func test_the_greatest_rate_is_the_top_of_the_rate() -> void:
	for i in 40:
		var s := _draw("greatest-rate", i)
		var sign := -1.0 if s.fall else 1.0
		for j in 200:
			var t: float = s.T * j / 200.0
			check(sign * DerivativeModelSituation.dy(s.mod, t) <= s.top.r + 1e-6, "draw %d at %f" % [i, t])


func test_the_figure_is_the_model() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(c): return c.rep == "graph" and c.unknown == "rate-at-time"):
		var q := _make(c, 2)
		check_eq(q.graph.curves.size(), 2, c.key)
		check_eq(q.graph.points.size(), 1, c.key)
		check_eq(q.graph.points[0].x, float(q.situation.t0), c.key)


func test_every_tag_shows_up_as_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 10):
			var q := _make(c, seed)
			for o in q.choices:
				if o.ref != "":
					seen[o.ref] = true
	for m in t.misconceptions:
		check(seen.has(m.ref), "%s never shows" % m.ref)
