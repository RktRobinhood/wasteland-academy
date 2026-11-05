extends "res://tests/test_case.gd"
## The right-triangle situation (FAL-739): t3-right-angle-trig is built with every cell and its four
## skills, each cell has one right option in both formats, the figure carries the horizontal at
## the eye, a triangle really is right-angled in every position, an exact answer is exact, every
## misconception shows up, and the type is in every course. tools/check-answers checks the maths.

const TYPE := "t3-right-angle-trig"
const CELLS := 50


func _make(c: Dictionary, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var view := {"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func test_the_type_is_built_with_every_cell_and_skill() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	for s in QuestionEngine.type_of(TYPE).skills:
		check(skills.has(s), s + " has no unknown")


func test_every_cell_has_one_right_option_and_no_extra_format() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			var q := _make(c, 3, f)
			check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
			if q.has("error"):
				continue
			check_eq(q.choices.size(), 4, c.key)
			check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
			check(q.solutions[0].angle == c.angle, c.key)


func test_elevation_and_depression_always_have_a_figure() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for u in t.unknowns:
		if "SL3.3.elevation-depression" in u.skills:
			check_eq(u.reps, ["diagram"], u.id)
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.rep == "diagram"):
		var g: Dictionary = _make(c, 4).graph
		check_eq(g.kind, "sketch", c.key)


func test_words_have_no_sketch() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.rep == "words"):
		check(_make(c, 2).graph == null, c.key)


func test_depression_is_drawn_from_the_horizontal_at_the_top() -> void:
	for u in ["depression-sight-line", "depression-from-sight-line", "depression-two-points"]:
		for seed in range(1, 20):
			var g: Dictionary = _make({"unknown": u, "rep": "diagram", "angle": "alternate-angles"}, seed).graph
			check_eq(g.pts["H"][1], g.pts["T"][1], "%s: TH is not horizontal" % u)
			check(g.arcs.all(func(a): return a.at == "T" and a.from == "H"), u)


func test_a_turned_triangle_keeps_its_right_angle_and_sides() -> void:
	for seed in range(1, 40):
		var q := _make({"unknown": "ratio-from-sides", "rep": "diagram", "angle": "label-soh-cah-toa"}, seed)
		var r: String = q.graph.right[0]
		var others: Array = q.graph.pts.keys().filter(func(n): return n != r)
		var at: Array = q.graph.pts[r]
		var u := [q.graph.pts[others[0]][0] - at[0], q.graph.pts[others[0]][1] - at[1]]
		var v := [q.graph.pts[others[1]][0] - at[0], q.graph.pts[others[1]][1] - at[1]]
		check(absf(u[0] * v[0] + u[1] * v[1]) < 1e-6, "no right angle at %s" % r)


func test_no_vertex_is_called_n() -> void:
	# PlotView reads an arc from "N" as a bearing.
	for seed in range(1, 200):
		var s: Dictionary = RightTriangleSituation.generate(Seeded.new("n|%d" % seed), {"ask": "ratio-from-sides"})
		check(not "N" in s.names, "seed %d" % seed)


func test_a_circle_is_drawn_for_a_chord_and_for_a_rectangle() -> void:
	var chord := _make({"unknown": "chord-length", "rep": "diagram", "angle": "pythagoras"}, 1)
	check_eq(chord.graph.circles.size(), 1)
	var hatch := _make({"unknown": "side-in-letters", "rep": "diagram", "angle": "choose-ratio-rearrange"}, 1)
	check_eq(hatch.graph.circles.size(), 1)
	var plot := PlotView.new()
	plot.set_spec(chord.graph)
	check(plot.custom_minimum_size.y >= 600.0, "the sketch has room")
	plot.free()


func test_an_exact_answer_is_only_right_exactly() -> void:
	for seed in range(1, 30):
		var q := _make({"unknown": "side-special", "rep": "diagram", "angle": "special-triangle"}, seed, "value", 1)
		check_eq(q.paper, 1)
		check(q.answer.get("exact", false), q.answer_text)
		var p := _make({"unknown": "ratio-needs-pythagoras", "rep": "words", "angle": "pythagoras-third-side"}, seed, "value", 1)
		check(p.answer_text.contains("√"), p.answer_text)


func test_a_gradient_is_tan_of_the_angle() -> void:
	for seed in range(1, 40):
		var q := _make({"unknown": "gradient-from-angle", "rep": "words", "angle": "gradient-tan"}, seed)
		var e: float = Q.of(q.given.e).to_float() if q.given.e is Q else float(q.given.e)
		check(absf(Q.of(q.answer.values.v).to_float() - tan(deg_to_rad(e))) < 1e-6, q.answer_text)


func test_every_distractor_misconception_is_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for i in t.misconceptions.size():
		var m: Dictionary = t.misconceptions[i]
		var ref: String = m.get("ref", "%s#%d" % [TYPE, i])
		for u in m["in"]:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 120):
					if _make(c, seed).choices.any(func(o): return o.ref == ref):
						found = true
						break
				if found:
					break
			check(found, "%s never appears on %s" % [ref, u])


func test_the_type_is_in_every_course() -> void:
	for course in Courses.ids():
		check(TYPE in QuestionEngine.built_types(course), course)
