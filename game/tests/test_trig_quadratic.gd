extends "res://tests/test_case.gd"
## The `trig-quadratic` situation (FAL-753): t3-trig-quadratic is built with every cell and all three
## methods, every cell makes four options with one right on its one paper, values match sums done by
## hand, a root out of range gives no solutions, a figure is the equation it says, and every tag
## shows up as an option. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t3-trig-quadratic"
const SKILL := "SL3.8.quadratic-in-trig"
const CELLS := 48


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _draw(ask: String, i: int, rep: String = "equation") -> Dictionary:
	return TrigQuadraticSituation.generate(Seeded.new("%s|%s|%d" % [ask, rep, i]), {"ask": ask, "rep": rep})


func test_the_type_is_built_with_every_cell_and_method() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	var cells := QuestionEngine.cells(false, [TYPE])
	check_eq(cells.size(), CELLS)
	var angles := {}
	for c in cells:
		angles[c.angle] = true
	check_eq(angles.size(), 3, "all three methods have a cell")
	var t := QuestionEngine.type_of(TYPE)
	for u in t.unknowns:
		check_eq(u.skills, [SKILL], u.id)


func test_every_cell_makes_a_question_in_both_formats() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		var want: int = 2 if c.unknown in TrigQuadraticViews.P2 else 1
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [want], c.key)
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "trig-quadratic", c.key)
				check_eq(q.paper, want, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.solutions[0].angle, c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps in %s" % [c.key, sol.steps.size(), sol.name])


func test_the_sums_match_hand_values() -> void:
	# 2u² − u − 1 = (2u + 1)(u − 1): the brackets give the roots −1/2 and 1.
	var s := {"p": [2, -1, -1], "sc": 1, "fn": "sin", "dis": "direct", "b": Q.new(1), "phi": Q.new(0), "lay": 0}
	check_eq(TrigQuadraticViews.terms(s), [[2, "sin²x"], [-1, "sin x"], [-1, ""]])
	check_eq(TrigQuadraticViews.eq_text(s), "2 sin²x − sin x − 1 = 0")
	# 2u² − 5u + 2 with cos²x for sin²x is 2 cos²x + 5 sin x − 4, by hand.
	s.p = [2, -5, 2]
	s.dis = "pythag"
	s.lay = 1
	check_eq(TrigQuadraticViews.eq_text(s), "2 cos²x + 5 sin x = 4")
	# u² − u − 2 with cos 2x: double the quadratic, and cos 2x = 1 − 2u² gives cos 2x + 2 sin x + 3.
	s.p = [1, -1, -2]
	s.sc = 2
	s.dis = "double"
	s.lay = 0
	check_eq(TrigQuadraticViews.eq_text(s), "cos 2x + 2 sin x + 3 = 0")
	# sin x = 1/2 on 0 to 2π is π/6 and 5π/6, and sin x = −1 is 3π/2: the sum is 5π/2.
	var w := {"fn": "sin", "b": Q.new(1), "phi": Q.new(0), "lo": Q.new(0), "hi": Q.new(2), "open_hi": false}
	var xs := TrigQuadraticSituation._all_of(w, [TrigKit.V(Q.new(1, 2)), TrigKit.V(-1)])
	check_eq(xs.size(), 3)
	check(TrigQuadraticSituation.total(xs).eq(Q.new(5, 2)), "the sum is 5π/2")


func test_a_root_out_of_range_gives_no_solutions() -> void:
	for ask in ["reject-root", "all-solutions", "count-solutions"]:
		for i in 60:
			var s := _draw(ask, i)
			check(not s.is_empty(), "%s %d" % [ask, i])
			for v in s.bad:
				check(absf(TrigKit.fl(v)) > 1.0, "%s %d" % [ask, i])
			check_eq(s.kept.size() + s.bad.size(), 2, "%s %d" % [ask, i])


func test_a_quadratic_is_built_from_its_roots() -> void:
	for i in 80:
		var s := _draw("all-solutions", i)
		var p: Array = s.p
		for v in s.us:
			var u := TrigKit.fl(v)
			check(absf(p[0] * u * u + p[1] * u + p[2]) < 1e-9, "%d: root %f" % [i, u])
		var c := TrigQuadraticViews.scaled(s)
		check(c[0] % 2 == 0 or s.dis != "double", "%d: cos 2x has a half in front" % i)


func test_the_bank_and_map_equations_stay_theirs() -> void:
	var taken := ["2 cos²x + 5 sin x = 4", "cos 2x = sin x", "2 sin²x − sin x − 1 = 0", "2 cos²x + 3 sin x = 3"]
	for ask in ["all-solutions", "double-angle-solve", "quadratic-in-u"]:
		for i in 300:
			var s := _draw(ask, i)
			check(not TrigQuadraticViews.eq_text(s) in taken, "%s %d" % [ask, i])


func test_a_figure_is_the_equation_it_says() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(c): return c.rep == "graph"):
		var q := _make(c, 2)
		check(q.graph != null, c.key)
		if c.unknown in ["reject-root", "count-solutions"]:
			check_eq(q.graph.hlines.size(), 2, c.key)
		elif c.unknown == "gdc-solve":
			check_eq(q.graph.points.size(), q.situation.xs.size(), c.key)
			for p in q.graph.points:
				check(absf(p.y) < 1e-9, c.key)
		else:
			check_eq(q.graph.hlines.size(), 0, c.key)


func test_no_answer_on_paper_1_needs_a_calculator() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(c): return not c.unknown in TrigQuadraticViews.P2):
		var q := _make(c, 4)
		check(q.answer.get("exact", false) or q.answer.kind == "choice", c.key + " is not exact")


func test_every_tag_shows_up_as_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 40):
			var q := _make(c, seed)
			for o in q.choices:
				if o.ref != "":
					seen[o.ref] = true
	for m in t.misconceptions:
		check(seen.has(m.ref), "%s never shows" % m.ref)
	for i in 3:
		check(seen.has("%s#%d" % [SKILL, i]), "%s#%d never shows" % [SKILL, i])
