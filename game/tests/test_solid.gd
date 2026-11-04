extends "res://tests/test_case.gd"
## The solid situation (FAL-726): t3-solid-volume-area is built with every cell and both skills,
## every cell makes four options with one right on each paper it can, the GDC solver is Paper 2,
## a sketch labels only what is given, Paper 1 is exact, the situation's lengths fit, and every
## misconception shows up. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t3-solid-volume-area"
const CELLS := 58


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
	check_eq(skills.size(), 2, "both listed skills have a question")


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


func test_the_gdc_solver_is_paper_2() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var papers := QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle)
		check_eq(papers, [2] if c.angle.begins_with("gdc-") else papers, c.key)
		if c.angle.begins_with("gdc-"):
			check_eq(_make(c, 4).paper, 2, c.key)


func test_paper_1_is_exact_and_paper_2_is_to_three_figures() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var papers := QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle)
		if 1 in papers:
			check(_make(c, 5, "value", 1).answer.get("exact", false), c.key)
		if 2 in papers and not c.unknown in SolidSituation.EXPRESSIONS:
			check_eq(_make(c, 5, "value", 2).answer.get("show", ""), "sf", c.key)


func test_a_diagram_labels_only_what_is_given() -> void:
	for seed in range(1, 12):
		var q := _make({"unknown": "cone-volume-from-slant", "rep": "diagram", "angle": "height-by-pythagoras"}, seed)
		check_eq(q.graph.kind, "solid")
		check(q.graph.has("l") and q.graph.has("r"), "seed %d: r and l are labelled" % seed)
		check(not q.graph.has("h"), "seed %d: the height is not given" % seed)
		var plot := PlotView.new()
		plot.set_spec(q.graph)
		check(plot.custom_minimum_size.y >= 600.0, "the sketch has room")
		plot.free()


func test_every_cell_in_words_has_no_sketch() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var q := _make(c, 7)
		check_eq(q.graph == null, c.rep == "words", c.key)


func test_a_hemisphere_fits_in_its_cylinder() -> void:
	for i in 200:
		var s: Dictionary = SolidSituation.generate(Seeded.new("h|%d" % i), {"ask": "composite-volume", "paper": 1 + i % 2})
		if s.shape == "cylinder-minus-hemisphere":
			check(s.r < s.big and s.r < s.c, "draw %d" % i)


func test_the_cone_is_a_right_triangle() -> void:
	for i in 100:
		var s: Dictionary = SolidSituation.generate(Seeded.new("c|%d" % i), {"ask": "cone-volume-from-slant", "paper": 1 + i % 2})
		check(is_equal_approx(s.r * s.r + s.h * s.h, s.l * s.l), "draw %d" % i)
		if s.paper == 1:
			check(is_equal_approx(s.h, roundf(s.h)), "draw %d: a Paper 1 height is whole" % i)


func test_the_sector_rolls_into_its_cone() -> void:
	for i in 100:
		var s: Dictionary = SolidSituation.generate(Seeded.new("s|%d" % i), {"ask": "sector-cone-radius", "paper": 1 + i % 2})
		check(is_equal_approx(2.0 * PI * s.r, s.theta / 360.0 * TAU * s.l), "draw %d" % i)
		check(s.r < s.l, "draw %d" % i)


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
			check(found, "%s never appears on %s" % [m.ref, u])


func test_the_type_is_in_every_course_it_should_be() -> void:
	check(TYPE in QuestionEngine.built_types("aa-sl"))
