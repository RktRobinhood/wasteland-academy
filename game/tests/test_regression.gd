extends "res://tests/test_case.gd"
## The regression situation (FAL-695): t4-regression-gdc is built with every catalogue cell,
## every question is Paper 2, the data are near a line of the story's sign, the line passes
## through the mean point, r and the sums match hand values, an estimate is made inside the
## data and the early-rounding slip differs from it, every distractor misconception shows up
## as an option, and answers are marked to 3 s.f. The SymPy checker (tools/check-answers)
## checks the maths.

const TYPE := "t4-regression-gdc"
## Cells, counted as tools/pedagogy.mjs counts them.
const CELLS := 7


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func _draw(ask: String, i: int) -> Dictionary:
	return RegressionSituation.generate(Seeded.new("%s|%d" % [ask, i]), {"ask": ask})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	check_eq(t.unknowns.size(), 6)
	var skills := {}
	for u in t.unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 4, "every SL4.4 skill of the type has a question")


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		# An exam type offers no extra format (test_extension.gd holds that rule).
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3, 4, 5, 6]:
				var q := _make(c.unknown, c.rep, c.angle, seed, f)
				check(not q.has("error"), "%s as %s seed %d: %s" % [c.key, f, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "regression", c.key)
				check_eq(q.choices.size(), 4, "%s as %s: options" % [c.key, f])
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, "%s as %s: right options" % [c.key, f])
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s as %s: two options read the same" % [c.key, f])
				check(not q.solutions.is_empty() and q.solutions[0].angle == c.angle, "%s: the asked method is the first worked solution" % c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps in %s" % [c.key, sol.steps.size(), sol.name])


func test_every_question_is_paper_2() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2], c.key)
		check_eq(_make(c.unknown, c.rep, c.angle, 3, "mcq").paper, 2, c.key)


func test_same_seed_same_question_and_seeds_vary() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var a := _make(c.unknown, c.rep, c.angle, 7, "mcq")
		var b := _make(c.unknown, c.rep, c.angle, 7, "mcq")
		check_eq(a.prompt, b.prompt, c.key)
		check_eq(a.answer_text, b.answer_text, c.key)
		check_eq(a.lines, b.lines, c.key)
		var seen := {}
		for seed in range(1, 13):
			var q := _make(c.unknown, c.rep, c.angle, seed, "mcq")
			seen[q.answer_text] = true
		check(seen.size() > 3, "%s: only %d different answers in 12 seeds" % [c.key, seen.size()])


func test_the_sums_the_line_and_r_match_hand_values() -> void:
	# (1, 2), (2, 4), (3, 5), (4, 4), (5, 5): means (3, 4), Sxx = 10, Sxy = 6, Syy = 6.
	var s := {"n": 5, "xs": [1, 2, 3, 4, 5], "ys": [2, 4, 5, 4, 5]}
	RegressionSituation.stats(s)
	check(s.mx.eq(Q.new(3)) and s.my.eq(Q.new(4)), "the means")
	check(s.sxx.eq(Q.new(10)) and s.sxy.eq(Q.new(6)) and s.syy.eq(Q.new(6)), "the sums")
	check(s.a.eq(Q.new(3, 5)) and s.b.eq(Q.new(11, 5)), "y = 0.6x + 2.2")
	check(absf(s.r - 6.0 / sqrt(60.0)) < 1e-12, "r = 6 / sqrt(60)")
	# x on y: ay = Sxy / Syy = 1, by = 3 - 1 * 4 = -1.
	check(s.ay.eq(Q.new(1)) and s.by.eq(Q.new(-1)), "the line of x on y")


func test_the_data_are_near_a_line_of_the_storys_sign() -> void:
	for ask in ["regression-line", "correlation-coefficient", "mean-point", "predict-from-data"]:
		for i in 60:
			var s := _draw(ask, i)
			check(not s.is_empty(), "%s draw %d" % [ask, i])
			if s.is_empty():
				continue
			check(s.n >= 6 and s.n <= 9, "%s draw %d: n = %d" % [ask, i, s.n])
			var ascending := true
			for j in range(1, s.n):
				if s.xs[j] <= s.xs[j - 1]:
					ascending = false
			check(ascending and s.xs[0] >= 1 and s.xs[s.n - 1] <= 20, "%s draw %d: x-values %s" % [ask, i, s.xs])
			check(s.ys.min() >= 8 and s.ys.max() <= 99, "%s draw %d: y-values %s" % [ask, i, s.ys])
			check(absf(s.r) >= RegressionSituation.R_MIN and absf(s.r) <= RegressionSituation.R_MAX, "%s draw %d: r = %s" % [ask, i, s.r])
			check((s.r > 0.0) == (RegressionSituation.SIGNS[s.ctx] > 0), "%s draw %d: the story's sign" % [ask, i])
			check(s.a.mul(s.mx).add(s.b).eq(s.my), "%s draw %d: the line passes through the mean point" % [ask, i])


func test_the_mean_point_is_exact_and_c_makes_the_line_pass_through_it() -> void:
	for i in 60:
		var m := _draw("mean-point", i)
		check(Q.new(100).mul(m.mx).is_int() and Q.new(100).mul(m.my).is_int(), "draw %d: both means end within two decimal places" % i)
		var s := _draw("c-from-mean-point", i)
		check(s.a.mul(s.mx).add(s.c).eq(s.my), "draw %d: a x-bar + c = y-bar" % i)
		check(not s.a.eq(Q.new(1)) and not s.a.eq(Q.new(-1)) and not s.c.is_zero(), "draw %d: a is not 1, c is not 0" % i)


func test_an_estimate_is_inside_the_data_and_the_slip_reads_differently() -> void:
	for i in 80:
		var s := _draw("predict-from-data", i)
		check(s.x0 > s.xs[0] and s.x0 < s.xs[s.n - 1] and not s.x0 in s.xs, "draw %d: x = %d is inside the data and off the table" % [i, s.x0])
		check(s.y0.eq(s.a.mul(Q.new(s.x0)).add(s.b)), "draw %d: the estimate is the line at x0" % i)
		check(Fmt.sf(s.y0) != Fmt.sf(s.y3), "draw %d: rounding a and b early changes the estimate" % i)
		check(Fmt.sf(s.y0) != Fmt.sf(s.xr) and Fmt.sf(s.y3) != Fmt.sf(s.xr), "draw %d: the rearranged line reads differently" % i)
		check(s.y0.sign() > 0 and Answer.needs_rounding(s.y0), "draw %d: a positive estimate that needs rounding" % i)
	for i in 80:
		var g := _draw("predict-from-line", i)
		check(g.y0.eq(g.a.mul(Q.new(g.x0)).add(g.b)), "line %d: the estimate is the line at x0" % i)
		check(g.x0 >= 5 and g.x0 <= 40 and g.y0.to_float() >= 5.0 and g.y0.to_float() <= 500.0, "line %d: x = %d, y = %s" % [i, g.x0, g.y0.text()])


func test_a_line_is_written_with_its_sign() -> void:
	check_eq(RegressionViews.line_text(Q.new(234, 100), Q.new(126, 10)), "y = 2.34x + 12.6")
	check_eq(RegressionViews.line_text(Q.new(-55, 100), Q.new(-31, 10)), "y = −0.55x − 3.1")
	var q := _make("predict-from-line", "equation", "substitute", 5, "value")
	check(q.lines[0].begins_with("The regression line of y on x is y = "), q.lines[0])


func test_answers_are_marked_to_3_sf_and_the_mean_point_exactly() -> void:
	var done := 0
	for seed in range(1, 30):
		var q := _make("predict-from-data", "table", "substitute", seed, "value")
		var x: float = Q.of(q.answer.values.v).to_float()
		check(QuestionEngine.mark(q, {"v": Fmt.sf(x, 3)}).correct, "seed %d: %s is right" % [seed, Fmt.sf(x, 3)])
		var two := Fmt.sf(x, 2)
		if absf(float(two) - float(Fmt.sf(x, 3))) > 1e-9:
			var r := QuestionEngine.mark(q, {"v": two})
			check(not r.correct and r.glancing, "seed %d: %s is a glancing hit" % [seed, two])
			done += 1
		check(not QuestionEngine.mark(q, {"v": Fmt.sf(x * 1.1, 3)}).correct, "seed %d: 10%% off is wrong" % seed)
	check(done > 10, "only %d 2 s.f. answers were tried" % done)
	# The line: a and b each to 3 s.f.
	var l := _make("regression-line", "table", "gdc-linreg", 4, "value")
	var m: Q = l.answer.values.m
	var c: Q = l.answer.values.c
	check(QuestionEngine.mark(l, {"m": Fmt.sf(m, 3), "c": Fmt.sf(c, 3)}).correct, "a and b to 3 s.f.")
	check(not QuestionEngine.mark(l, {"m": Fmt.sf(c, 3), "c": Fmt.sf(m, 3)}).correct, "a and b the wrong way round")
	# The mean point is exact.
	var p := _make("mean-point", "table", "mean-coordinates", 4, "value")
	var v: Dictionary = p.answer.values
	check(QuestionEngine.mark(p, {"x": Fmt.dec(v.x), "y": Fmt.dec(v.y)}).correct, "the mean point")
	check(not QuestionEngine.mark(p, {"x": Fmt.dec(v.x.add(Q.new(1, 100))), "y": Fmt.dec(v.y)}).correct, "a hundredth off")


func test_every_distractor_misconception_is_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for m in t.misconceptions:
		check_eq(m.as, "distractor", m.ref)
		for u in m["in"]:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 60):
					var q := _make(u, c.rep, c.angle, seed, "mcq")
					if q.choices.any(func(o): return o.ref == m.ref):
						found = true
						break
				if found:
					break
			check(found, "%s never appears on %s" % [m.ref, u])


func test_the_r_squared_option_is_r_squared_and_r_has_a_sign() -> void:
	for seed in range(1, 20):
		var q := _make("correlation-coefficient", "table", "gdc-linreg", seed, "mcq")
		var r: float = Q.of(q.answer.values.v).to_float()
		check(absf(r) > 0.0 and absf(r) < 1.0, "seed %d: r = %s" % [seed, r])
		for o in q.choices:
			var v: float = Q.of(o.values.v).to_float()
			check(absf(v) < 1.0, "seed %d: option %s is not a possible r" % [seed, o.text])
			if o.ref == RegressionViews.R_R_SQUARED:
				check(absf(v - r * r) < 0.0006, "seed %d: %s is not r²" % [seed, o.text])


func test_probes_are_served() -> void:
	var mine := QuestionEngine.probes().filter(func(x): return x.type == TYPE)
	check_eq(mine.size(), 3)
	check_eq(QuestionEngine.probe(TYPE, 0).verdict, "False")
	check_eq(QuestionEngine.probe(TYPE, 1).verdict, "Sometimes")
	check_eq(QuestionEngine.probe(TYPE, 2).verdict, "False")


func test_the_type_is_in_every_course_that_shares_sl4_4() -> void:
	# SL4.4 is on all four syllabuses, so every course has every cell.
	for course in Courses.ids():
		check_eq(QuestionEngine.cells(false, [TYPE], course).size(), CELLS, course)
		check(TYPE in QuestionEngine.built_types(course), course)
