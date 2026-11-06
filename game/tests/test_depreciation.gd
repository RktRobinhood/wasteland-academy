extends "res://tests/test_case.gd"
## The depreciation situation (FAL-752): t1-depreciation is built with every cell and both skills,
## on Paper 2. Values match sums done by hand, money is clear of the half-dollar edge, a table is
## exact to the cent, the least time is the first that works, and every tag shows up as an option.
## The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t1-depreciation"
const CELLS := 110


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _draw(ask: String, i: int, rep: String = "words") -> Dictionary:
	return DepreciationSituation.generate(Seeded.new("%s|%s|%d" % [ask, rep, i]), {"ask": ask, "rep": rep})


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
				check_eq(q.situation_id, "depreciation", c.key)
				check_eq(q.paper, 2, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.solutions[0].angle, c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps in %s" % [c.key, sol.steps.size(), sol.name])


func test_the_sums_match_hand_values() -> void:
	# 24000 × 0.85^3 = 14739, by hand.
	check(absf(DepreciationSituation.value(24000.0, 0.85, 3) - 14739.0) < 1e-6)
	# 1000 → 810 over 2 years keeps 0.9, a rate of 10%.
	var s := {"p": Q.new(1000), "v": Q.new(810), "n": 2}
	check(absf(DepreciationSituation.rate_of(s) - 10.0) < 1e-9)
	check(absf(DepreciationSituation.straight_rate(s) - 9.5) < 1e-9)
	check(absf(DepreciationSituation.whole_rate(s) - 19.0) < 1e-9)
	# At 20% off a price of 1000, 200 a year passes 500 in the 3rd year.
	check_eq(DepreciationSituation.straight_years({"p": Q.new(1000), "r": Q.new(20), "target": Q.new(500)}), 3)


func test_money_is_clear_of_the_half_dollar_edge() -> void:
	for i in 60:
		var s := _draw("value-after", i)
		check(DepreciationSituation.dollars_clear(DepreciationViews.V(s, s.n)), "value %d" % i)
		var t := _draw("two-rate-value", i)
		check(DepreciationSituation.dollars_clear(DepreciationSituation.two_value(t)), "two rates %d" % i)
		var u := _draw("shortfall", i)
		var m: float = DepreciationViews.V(u, u.n) - DepreciationSituation.account(u)
		check(DepreciationSituation.dollars_clear(m) and m >= DepreciationSituation.LOSS_MIN, "shortfall %d" % i)


func test_a_table_is_exact_to_the_cent() -> void:
	for ask in ["value-after", "least-periods", "years-from-periods", "original-value"]:
		for i in 40:
			var s := _draw(ask, i, "table")
			check(not s.is_empty(), "%s %d" % [ask, i])
			var start: Q = s.v if ask == "original-value" else s.p
			var third: Q = start.mul(s.c).mul(s.c).mul(Q.new(100))
			check(third.is_int(), "%s %d: the third value %s" % [ask, i, third.text()])


func test_the_least_time_is_the_first_that_works() -> void:
	for ask in ["years-below", "years-fraction", "years-from-periods", "least-periods"]:
		for i in 60:
			var s := _draw(ask, i)
			check(not s.is_empty(), "%s %d" % [ask, i])
			var per: int = s.k if ask == "years-from-periods" else 1
			var t: float = s.target.to_float()
			check(DepreciationViews.V(s, s.least * per) < t, "%s %d" % [ask, i])
			check(DepreciationViews.V(s, (s.least - 1) * per) >= t, "%s %d" % [ask, i])


func test_the_figure_marks_the_crossing() -> void:
	var cells := QuestionEngine.cells(false, [TYPE]).filter(func(c): return c.rep == "graph")
	check(not cells.is_empty())
	for c in cells:
		var q := _make(c, 2)
		check(q.graph != null, c.key)
		check_eq(q.graph.points.size(), 1, c.key)
		check_eq(q.graph.hlines[0].at, q.graph.points[0].y, c.key)
		check_eq(q.graph.x1, q.situation.least + 2, c.key)


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
