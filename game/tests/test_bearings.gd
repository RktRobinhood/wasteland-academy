extends "res://tests/test_case.gd"
## The bearings-elevation situation (FAL-726): t3-bearings-elevation is built with every cell and
## its three skills, every question is Paper 2 with four options and one right, a bearing keeps
## three figures, a sketch has a north line at each bearing, every misconception shows up, and
## the type is in every course. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t3-bearings-elevation"
const CELLS := 56


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 3, "the three listed skills have a question")


func test_every_cell_is_paper_2_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			var q := _make(c, 3, f)
			check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
			if q.has("error"):
				continue
			check_eq(q.paper, 2, c.key)
			check_eq(q.choices.size(), 4, c.key)
			check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
			check(q.solutions[0].angle == c.angle, c.key)


func test_a_bearing_keeps_three_figures() -> void:
	for seed in range(1, 40):
		var q := _make({"unknown": "back-bearing", "rep": "words", "angle": "back-bearing"}, seed)
		check(RegEx.create_from_string("= \\d{3}°$").search(q.answer_text) != null, q.answer_text)
		var r := _make({"unknown": "two-leg-bearing", "rep": "words", "angle": "components"}, seed)
		check(Q.of(r.answer.values.v).to_float() >= 100.0, r.answer_text)


func test_a_sketch_has_a_north_line_at_each_bearing() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.rep == "diagram"):
		var q := _make(c, 4)
		check_eq(q.graph.kind, "sketch", c.key)
		for a in q.graph.arcs:
			if a.from == "N":
				check(a.at in q.graph.north, "%s: no north line at %s" % [c.key, a.at])
	var plot := PlotView.new()
	plot.set_spec(_make({"unknown": "two-leg-distance", "rep": "diagram", "angle": "components"}, 1).graph)
	check(plot.custom_minimum_size.y >= 600.0, "the sketch has room")
	plot.free()


func test_words_have_no_sketch() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.rep == "words"):
		check(_make(c, 2).graph == null, c.key)


func test_the_cosine_rule_agrees_with_the_components() -> void:
	for i in 60:
		var s: Dictionary = BearingsSituation.generate(Seeded.new("j|%d" % i), {"ask": "two-leg-distance"})
		var p := BearingsViews.journey(s)
		var a: float = s.d1.to_float()
		var b: float = s.d2.to_float()
		var byrule := sqrt(a * a + b * b - 2.0 * a * b * cos(deg_to_rad(BearingsViews.inside(s))))
		check(absf(byrule - BearingsViews.dist(p.A, p.C)) < 1e-6, "draw %d" % i)


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
				if found:
					break
			check(found, "%s never appears on %s" % [m.ref, u])


func test_the_type_is_in_every_course() -> void:
	for course in Courses.ids():
		check(TYPE in QuestionEngine.built_types(course), course)
