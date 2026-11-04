extends "res://tests/test_case.gd"
## The arc-sector situation (FAL-726): t3-arc-sector is built with every cell and its three
## skills, every cell makes four options with one right on each paper it can make, Paper 1 is
## exact, a sector is drawn to its real angle, every misconception shows up, and the type is on
## the courses that have SL3.4. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t3-arc-sector"
const CELLS := 78


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
	for s in ["SL3.4.arc-length", "SL3.4.sector-area", "SL3.4.convert"]:
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


func test_paper_1_is_exact_and_paper_2_has_a_rounding_trap() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		if 1 in QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle):
			check(_make(c, 5, "value", 1).answer.get("exact", false), c.key)
		if c.unknown != "r-in-terms-of-theta" and 2 in QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle):
			var a: Dictionary = _make(c, 5, "value", 2).answer
			check_eq(a.kind, "number", c.key)
			check_eq(a.show, "sf", c.key)


func test_a_paper_1_answer_keeps_pi() -> void:
	var c := {"unknown": "perimeter", "rep": "equation", "angle": "l-equals-r-theta"}
	var seen := false
	for seed in range(1, 40):
		var q := _make(c, seed, "value", 1)
		if q.answer_text.contains("π"):
			seen = true
			check(q.answer_text.contains(" + "), q.answer_text)
			check(q.asked.ends_with("in terms of π."), q.asked)
	check(seen, "no perimeter in terms of π")


func test_a_sector_is_drawn_to_its_real_angle() -> void:
	for seed in range(1, 30):
		var q := QuestionEngine.make({"type": TYPE, "unknown": "arc-length", "rep": "diagram", "angle": "l-equals-r-theta", "seed": seed})
		check_eq(q.graph.kind, "sector")
		var s: Dictionary = {"form": q.situation.form, "t": Q.of(_parse(q.situation.t))}
		check(is_equal_approx(q.graph.theta, ArcSectorViews.radians(s)), "seed %d" % seed)
	var plot := PlotView.new()
	plot.set_spec({"kind": "sector", "theta": 1.2, "shade": "minor", "names": ["O", "A", "B"], "r_label": "6 cm", "angle_label": "1.2", "arc_label": ""})
	check(plot.custom_minimum_size.y >= 400.0, "the sector has room")
	plot.free()


func _parse(text: String) -> Q:
	return Answer.parse_number(text).q


func test_a_major_sector_shades_the_big_part() -> void:
	for seed in range(1, 12):
		var q := QuestionEngine.make({"type": TYPE, "unknown": "major-sector", "rep": "diagram", "angle": "complement", "seed": seed})
		check_eq(q.graph.shade, "major")
		check(q.graph.theta < PI, "seed %d: the labelled angle is the minor one" % seed)


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


func test_the_composite_shapes_are_paper_2() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for u in ["ring-inner-radius", "ring-perimeter", "segments-theta"]:
		for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
			check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2], c.key)


func test_the_type_is_in_the_courses_with_sl34() -> void:
	for course in ["aa-sl", "aa-hl"]:
		check(TYPE in QuestionEngine.built_types(course), course)
