extends "res://tests/test_case.gd"
## The `trig-identity` situation (FAL-727): t3-identity-values is built with every cell and its skills, every cell
## makes four options with one right on each paper it can make, every misconception shows up, no
## cell offers an extra format, and the type is on the courses with SL3.6. The SymPy checker
## (tools/check-answers) checks the maths.

const TYPE := "t3-identity-values"
const CELLS := 50


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
	for s in ["SL3.6.ratio-from-ratio", "SL3.6.double-angle-values", "SL3.6.simplify"]:
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


func test_the_sign_comes_from_the_quadrant() -> void:
	for seed in range(1, 40):
		var q := QuestionEngine.make({"type": TYPE, "unknown": "cos-from-sin", "rep": "equation", "angle": "pythagorean-identity", "seed": seed})
		var neg_: bool = q.answer_text.contains("−")
		check_eq(neg_, int(q.situation.q) in [2, 3], q.answer_text)


func test_every_answer_is_exact() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(_make(c, 4, "value").answer.get("exact", false), c.key)


func test_a_surd_keeps_one_root() -> void:
	check_eq(TrigKit.text(TrigKit.mul(TrigKit.V(0, Q.new(1, 3), 5), TrigKit.V(Q.new(2, 3)))), "2√5/9")
	check_eq(TrigKit.text(TrigKit.over(TrigKit.V(1), TrigKit.root(37))), "√37/37")
	check_eq(TrigKit.text(TrigKit.sqrt_q(Q.new(3, 4))), "√3/2")


func test_the_type_is_in_the_courses_with_sl36() -> void:
	for course in ["aa-sl", "aa-hl"]:
		check(TYPE in QuestionEngine.built_types(course), course)
