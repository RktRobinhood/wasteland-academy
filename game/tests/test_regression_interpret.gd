extends "res://tests/test_case.gd"
## The regression-interpret situation (FAL-751): t4-regression-interpret is built with every cell
## and both skills, on Paper 2. A line given is the table's own to 3 s.f., and the cases of a
## judgement really differ: x = 0 in the table or far below it, r strong or weak, x inside the data
## or well outside it. The scatter draws the data. The SymPy checker (tools/check-answers) checks
## the maths and judges every statement from the numbers.

const TYPE := "t4-regression-interpret"
const CELLS := 24


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _draw(ask: String, i: int, rep: String = "equation") -> Dictionary:
	return RegressionInterpretSituation.generate(Seeded.new("%s|%s|%d" % [ask, rep, i]), {"ask": ask, "rep": rep})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 2, "both skills have a question")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2], c.key)
		for seed in [1, 2, 3, 4, 5]:
			var q := _make(c, seed)
			check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
			if q.has("error"):
				break
			check_eq(q.choices.size(), 4, c.key)
			check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
			check(q.solutions[0].angle == c.angle, c.key)


func test_only_the_expected_change_is_typed() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var q := _make(c, 3, "value")
		check_eq(q.format, "value" if c.unknown == "expected-change" else "mcq", c.key)


func test_a_line_given_is_the_tables_own() -> void:
	for i in 30:
		var s := _draw("interpret-gradient", i)
		check(not s.is_empty(), "draw %d" % i)
		check(s.a.eq(s.sxy.div(s.sxx)), "draw %d: a = Sxy / Sxx" % i)
		check_eq(Fmt.sf(s.a3), Fmt.sf(s.a), "draw %d" % i)
		check_eq(Fmt.sf(s.b3), Fmt.sf(s.b), "draw %d" % i)
		check_eq(s.a.sign(), RegressionInterpretSituation.STORIES[s.ctx].sign, "draw %d: the story's sign" % i)


func test_a_table_uses_the_unrounded_gradient_for_a_change() -> void:
	for i in 20:
		var s := _draw("expected-change", i, "table")
		check(s.ch.eq(s.a.mul(Q.new(s.k))), "draw %d: the change is k × a" % i)
		var g := _draw("expected-change", i, "equation")
		check(g.ch.eq(g.a3.mul(Q.new(g.k))), "draw %d: from the line given" % i)


func test_an_intercept_is_in_the_data_or_far_from_it() -> void:
	var seen := {}
	for i in 60:
		var s := _draw("intercept-sensible", i)
		seen[s.case] = true
		if s.case == "sensible":
			check_eq(s.lo, 0, "draw %d" % i)
			check(s.b3.sign() > 0, "draw %d: a possible amount" % i)
		else:
			check(s.lo * 2 >= s.hi - s.lo, "draw %d: far below the data" % i)
			check_eq(s.b3.sign() < 0, s.case == "negative", "draw %d" % i)
	check_eq(seen.size(), 3, "every case comes up")


func test_the_cases_of_an_estimate_stand_apart() -> void:
	var seen := {}
	for i in 60:
		var s := _draw("judge-prediction", i)
		seen[s.case] = true
		var inside: bool = s.x0 > s.lo and s.x0 < s.hi
		check_eq(inside, s.case != "outside", "draw %d" % i)
		check_eq(absf(s.r) <= RegressionInterpretSituation.WEAK_MAX, s.case == "weak", "draw %d" % i)
		check(s.y0.sign() > 0, "draw %d: the estimate is a possible amount" % i)
	check_eq(seen.size(), 3, "every case comes up")


func test_a_line_solved_for_x_is_not_the_line_of_x_on_y() -> void:
	var n := 0
	for i in 40:
		var s := _draw("flawed-estimate", i)
		if s.case == "rearranged":
			n += 1
			check(not s.xr.eq(s.xc), "draw %d" % i)
			check(s.given_y > s.ys.min() and s.given_y < s.ys.max(), "draw %d: y is inside the data" % i)
	check(n > 0, "the case comes up")


func test_the_scatter_is_the_data() -> void:
	var c := {"unknown": "read-estimate", "rep": "graph", "angle": "read-off-line"}
	for seed in range(1, 11):
		var q := _make(c, seed)
		var s: Dictionary = q.situation
		check_eq(q.graph.points.size(), s.xs.size(), "one dot per row")
		check_eq(q.graph.vlines[0].at, float(s.x0), "the x is marked")
		check(q.graph.x1 >= s.hi and q.graph.y1 >= s.ys.max(), "the window holds the data")


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 41):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	for m in QuestionEngine.type_of(TYPE).misconceptions:
		check(seen.has(m.ref), "%s never comes up" % m.ref)
