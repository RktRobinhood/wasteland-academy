extends "res://tests/test_case.gd"
## The regression-x-on-y situation (FAL-725): t4-regression-x-on-y is built with every cell and
## all four SL4.10 skills, cells make both forms with one right option, the table's line of x on
## y is exact, the working shows the real line, both lines given pass through a whole mean
## point, only choosing a line and the mean point reach Paper 1, every misconception shows up,
## and it stays out of the AI courses.
## The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t4-regression-x-on-y"
const CELLS := 12


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 4, "every SL4.10 skill has a question")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3, 4, 5]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check(q.solutions[0].angle == c.angle, c.key)


func test_the_line_of_x_on_y_is_the_line_of_the_table() -> void:
	for i in 40:
		var s: Dictionary = RegressionPairSituation.generate(Seeded.new("line|%d" % i), {"ask": "x-on-y-line"})
		check(not s.is_empty(), "draw %d" % i)
		check(s.c.eq(s.sxy.div(s.syy)), "draw %d: c = Sxy / Syy" % i)
		check(s.d.eq(s.mx.sub(s.c.mul(s.my))), "draw %d: the line passes through the mean point" % i)
		check(not s.c.eq(Q.new(1).div(s.a)), "draw %d: x on y is not y on x rearranged" % i)


func test_the_working_shows_the_real_line() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in [1, 2, 3]:
			var q := _make(c, seed)
			for sol in q.solutions:
				for text in Step.texts(sol.steps):
					check(not (text.contains("cy + d") and not text.contains("in the form")), "%s: %s" % [c.key, text])


func test_given_lines_cross_at_a_whole_mean_point() -> void:
	for i in 60:
		var s: Dictionary = RegressionPairSituation.generate(Seeded.new("pt|%d" % i), {"ask": "mean-point-from-lines"})
		check(s.my.eq(s.a.mul(s.mx).add(s.b)), "draw %d: on y on x" % i)
		check(s.mx.eq(s.c.mul(s.my).add(s.d)), "draw %d: on x on y" % i)
		check(s.mx.is_int() and s.my.is_int(), "draw %d: a whole point" % i)
		var ac: float = s.a.mul(s.c).to_float()
		check(ac > 0.0 and ac < 1.0, "draw %d: 0 < ac < 1" % i)


func test_a_table_an_estimate_or_a_gdc_is_paper_2() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var either: bool = c.unknown in ["choose-line", "mean-point-from-lines", "mean-from-one-mean"] and not c.angle.begins_with("gdc-")
		var want: Array = [1, 2] if either else [2]
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), want, c.key)


func test_the_mean_point_is_drawn_where_the_lines_cross() -> void:
	var q := QuestionEngine.make({"type": TYPE, "unknown": "mean-point-from-lines", "rep": "graph", "angle": "gdc-intersect", "seed": 4})
	check(q.graph != null and q.graph.curves.size() == 2, "both lines are drawn")
	check_eq(q.graph.points.size(), 1, "the crossing is marked")


func test_every_distractor_misconception_is_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for m in t.misconceptions:
		for u in m["in"]:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 80):
					if _make(c, seed).choices.any(func(o): return o.ref == m.ref):
						found = true
						break
			check(found, "%s never appears on %s" % [m.ref, u])


func test_only_the_aa_courses_have_it() -> void:
	check(TYPE in QuestionEngine.built_types("aa-sl"), "AA SL")
	check(TYPE in QuestionEngine.built_types("aa-hl"), "AA HL")
	check(not TYPE in QuestionEngine.built_types("ai-sl"), "SL4.10 is not on AI SL")
