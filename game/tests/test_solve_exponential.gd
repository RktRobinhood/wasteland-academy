extends "res://tests/test_case.gd"
## The solve-exponential situation (FAL-754): t1-solve-exponential is built with every cell and
## all four methods of SL1.7.solve-with-logs. Exact cells make either paper and show no calculator;
## 3 s.f. cells are Paper 2. Values match sums done by hand, an answer is clear of a rounding edge,
## early rounding moves the third figure only, an exact answer stays in range, a figure shows its
## crossing, and every tag shows up as an option. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t1-solve-exponential"
const CELLS := 26


func _make(c: Dictionary, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var v := {"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}
	if paper > 0:
		v.paper = paper
	return QuestionEngine.make(v)


func _draw(ask: String, i: int, rep: String = "equation") -> Dictionary:
	return SolveExponentialSituation.generate(Seeded.new("%s|%s|%d" % [ask, rep, i]), {"ask": ask, "rep": rep})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var want: Array = [1, 2] if c.unknown in SolveExponentialSituation.EXACT else [2]
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), want, c.key)


func test_every_method_of_the_skill_is_an_angle() -> void:
	var angles := {}
	for a in QuestionEngine.type_of(TYPE).angles:
		angles[a.method] = true
	for m in ["log-both-sides", "isolate-then-log", "graph-intersect", "gdc-solver"]:
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
				check_eq(q.situation_id, "solve-exponential", c.key)
				check_eq(q.paper, 2, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.solutions[0].angle, c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps in %s" % [c.key, sol.steps.size(), sol.name])


func test_an_exact_cell_asked_on_paper_1_is_exact_and_by_hand() -> void:
	var rx := RegEx.create_from_string("(?i)\\b(gdc|calculator|solver|graph)\\b")
	for c in QuestionEngine.cells(false, [TYPE]):
		if not c.unknown in SolveExponentialSituation.EXACT:
			continue
		var q := _make(c, 4, "value", 1)
		check_eq(q.paper, 1, c.key)
		check(q.answer.exact, c.key)
		for sol in q.solutions:
			for st in sol.steps:
				check(rx.search(st) == null, "%s: %s" % [c.key, st])


func test_the_sums_match_hand_values() -> void:
	# 2^(x + 1) = 3^x: x = ln 2/(ln 3 − ln 2) = 1.70951.
	var s := {"shape": "shift", "a": 2, "b": 3, "p": 1, "c": 1}
	check(absf(SolveExponentialSituation.two_bases(s) - 1.709511) < 1e-5)
	# 5^x = 2^(1 − x): x = ln 2/(ln 5 + ln 2) = ln 2/ln 10 = 0.30103.
	var m := {"shape": "mirror", "a": 5, "b": 2, "p": 1, "c": 1}
	check(absf(SolveExponentialSituation.two_bases(m) - 0.30103) < 1e-5)
	# 12e^(0.35t) = 40 × 1.15^t: t = ln(40/12)/(0.35 − ln 1.15) = 5.72670.
	var meet := {"A0": 12, "B0": 40, "kk": Q.new(35, 100), "g": Q.new(115, 100)}
	check(absf(SolveExponentialSituation.model_meet(meet) - 5.72670) < 1e-4)
	check_eq(SolveExponentialViews.ln_of(Q.new(5, 3)), "ln(5/3)")
	check_eq(SolveExponentialViews.pw(3, "x + 2"), "3^(x + 2)")
	check_eq(SolveExponentialViews.k_exp(4, Q.new(3, 5)), "4e^(0.6x)")


func test_an_answer_is_clear_of_an_edge_and_early_rounding_moves_the_third_figure() -> void:
	for i in 60:
		var s := _draw("two-bases-3sf", i)
		check(SolveExponentialSituation.clean(s.x), "two bases %d" % i)
		check(SolveExponentialSituation.third_off(SolveExponentialSituation.two_bases_early(s), s.x), "early %d" % i)
		var t := _draw("model-meet", i, "words")
		check(SolveExponentialSituation.clean(t.t), "meet %d" % i)
		check(SolveExponentialSituation.third_off(t.early, t.t), "meet early %d" % i)
		var u := _draw("isolate-3sf", i)
		check(SolveExponentialSituation.clean(u.x), "isolate %d" % i)


## Close bases with a big shift (6^x = 7^(x − 3)) would put the root near 38: an exact
## two-bases answer keeps to the same range as the 3 s.f. ones.
func test_an_exact_two_bases_answer_stays_in_range() -> void:
	for i in 200:
		var s := _draw("shift-base-exact", i)
		check(s.x > 0.0 and s.x <= SolveExponentialSituation.MAX_X, "shift %d: x = %s" % [i, s.x])
		var t := _draw("one-minus-exact", i)
		check(absf(t.x) <= SolveExponentialSituation.MAX_X, "one minus %d: x = %s" % [i, t.x])
	check(SolveExponentialSituation.two_bases({"shape": "shift", "a": 7, "b": 6, "p": -3, "c": 1}) > SolveExponentialSituation.MAX_X, "the bad case is out of range")


func test_a_figure_shows_its_crossing() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(e): return e.rep == "graph"):
		for seed in [1, 2, 3]:
			var q := _make(c, seed)
			check(q.graph != null, c.key)
			var p: Dictionary = q.graph.points[0]
			check_eq(p.label, "P", c.key)
			check(p.x > float(q.graph.x0) and p.x < float(q.graph.x1) and p.y > float(q.graph.y0) and p.y < float(q.graph.y1), "%s: P is off the window" % c.key)
			check(q.graph.curves[0].size() > 10, c.key)


func test_the_map_strings_quote_no_numbers() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for m in t.misconceptions:
		check(RegEx.create_from_string("\\d").search(m.text) == null, m.text)


func test_every_tag_shows_up_as_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 16):
			var q := _make(c, seed)
			for o in q.choices:
				if o.ref != "":
					seen[o.ref] = true
	for i in t.misconceptions.size():
		var ref: String = t.misconceptions[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never shows" % ref)
