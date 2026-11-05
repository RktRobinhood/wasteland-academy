extends "res://tests/test_case.gd"
## The `trig-model` situation (FAL-727): t3-trig-model-parameters is built with every cell and its skills, every cell
## makes four options with one right on each paper it can make, every misconception shows up, no
## cell offers an extra format, and the type is on the courses with SL3.7. The SymPy checker
## (tools/check-answers) checks the maths.

const TYPE := "t3-trig-model-parameters"
const CELLS := 67


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
	for s in ["SL3.7.equation-from-graph", "SL3.7.transformations", "SL3.7.model-context"]:
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


func test_paper_1_is_exact_and_paper_2_is_a_story_or_a_decimal() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.rep == "words" and c.unknown != "image-equation":
			check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2], c.key)
		for paper in QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle):
			if paper == 1:
				var a: Dictionary = _make(c, 5, "value", 1).answer
				check(a.kind == "claim" or a.get("exact", false), c.key)


func test_a_paper_1_wave_is_marked_in_multiples_of_pi() -> void:
	var c := {"unknown": "all-four", "rep": "graph", "angle": "max-min-averages"}
	var q := _make(c, 3, "value", 1)
	check(not q.graph.x_ticks.is_empty(), "the axis has π ticks")
	check(q.graph.x_ticks.any(func(k): return k[1] == "π"), "π is marked")


func test_a_story_shows_its_turning_points() -> void:
	var q := _make({"unknown": "amp-axis", "rep": "words", "angle": "max-min-averages"}, 2, "value", 2)
	check(q.lines[1].contains("largest value"), q.lines[1])


func test_the_type_is_in_the_courses_with_sl37() -> void:
	for course in ["aa-sl", "aa-hl"]:
		check(TYPE in QuestionEngine.built_types(course), course)
