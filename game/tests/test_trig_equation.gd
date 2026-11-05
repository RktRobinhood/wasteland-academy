extends "res://tests/test_case.gd"
## The `trig-equation` situation (FAL-727): t3-trig-equation is built with every cell and its skills, every cell
## makes four options with one right on each paper it can make, every misconception shows up, no
## cell offers an extra format, and the type is on the courses with SL3.8. The SymPy checker
## (tools/check-answers) checks the maths.

const TYPE := "t3-trig-equation"
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
	for s in ["SL3.8.solve-basic", "SL3.8.compound-angle", "SL3.8.factorise-not-divide"]:
		check(skills.has(s), s + " has no question")


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
				if found:
					break
			check(found, "%s never appears on %s" % [m.ref, u])


func test_only_the_decimals_are_paper_2() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2] if c.unknown in ["basic-decimal", "compound-decimal"] else [1], c.key)


func test_the_solutions_can_be_typed_in_any_order() -> void:
	var c := {"unknown": "basic-exact", "rep": "equation", "angle": "unit-circle-cast"}
	for seed in range(1, 30):
		var q := _make(c, seed, "value")
		if q.answer.values.has("a1"):
			check(q.answer.unordered.size() == 1, q.cell)
			var right := {"a0": str(q.answer.values.a1.key()), "a1": str(q.answer.values.a0.key())}
			check(Answer.mark(q.answer, right).correct, "either order")
			return
	fail("no equation had two solutions")


func test_an_interval_can_change_the_solutions() -> void:
	var open := TrigEquationSituation.solve("sin", TrigKit.V(0), Q.new(1), Q.new(0), Q.new(0), Q.new(2), true)
	var closed := TrigEquationSituation.solve("sin", TrigKit.V(0), Q.new(1), Q.new(0), Q.new(0), Q.new(2))
	check_eq(open.size(), 2)
	check_eq(closed.size(), 3)


func test_a_compound_angle_keeps_every_wave() -> void:
	var xs := TrigEquationSituation.solve("sin", TrigKit.V(Q.new(1, 2)), Q.new(2), Q.new(0), Q.new(0), Q.new(2))
	check_eq(xs.size(), 4)
	check_eq(xs[0].key(), "1/12")


func test_the_type_is_in_the_courses_with_sl38() -> void:
	for course in ["aa-sl", "aa-hl"]:
		check(TYPE in QuestionEngine.built_types(course), course)
