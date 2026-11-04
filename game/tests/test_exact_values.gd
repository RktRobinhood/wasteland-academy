extends "res://tests/test_case.gd"
## The `exact-trig` situation (FAL-727): t3-exact-values is built with every cell and its skills, every cell
## makes four options with one right on each paper it can make, every misconception shows up, no
## cell offers an extra format, and the type is on the courses with SL3.5. The SymPy checker
## (tools/check-answers) checks the maths.

const TYPE := "t3-exact-values"
const CELLS := 53


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
	for s in ["SL3.5.exact-special", "SL3.5.related-angles", "SL3.5.unit-circle"]:
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


func test_a_landmark_table_is_right() -> void:
	check_eq(TrigKit.text(TrigKit.sin_pi(Q.new(5, 6))), "1/2")
	check_eq(TrigKit.text(TrigKit.cos_pi(Q.new(5, 6))), "−√3/2")
	check_eq(TrigKit.text(TrigKit.tan_pi(Q.new(7, 6))), "√3/3")
	check_eq(TrigKit.text(TrigKit.tan_pi(Q.new(-1, 4))), "−1")
	check(TrigKit.tan_pi(Q.new(1, 2)).is_empty(), "tan(π/2) has no value")
	check_eq(TrigKit.text(TrigKit.plus(TrigKit.V(Q.new(1, 2)), TrigKit.V(0, Q.new(1, 2), 3))), "(1 + √3)/2")
	check(TrigKit.plus(TrigKit.V(0, 1, 2), TrigKit.V(0, 1, 3)).is_empty(), "two surds")


func test_the_unit_circle_is_drawn_where_the_angle_is() -> void:
	for seed in range(1, 20):
		var q := QuestionEngine.make({"type": TYPE, "unknown": "related-value", "rep": "diagram", "angle": "identity", "seed": seed})
		check_eq(q.graph.kind, "unit-circle")
		var th: float = Answer.parse_number(q.situation.t).q.to_float() * PI
		check(is_equal_approx(q.graph.points[0].x, cos(th)), "seed %d" % seed)
	var plot := PlotView.new()
	plot.set_spec({"kind": "unit-circle", "points": []})
	check(plot.custom_minimum_size.y >= 600.0, "the circle has room")
	plot.free()


func test_a_special_triangle_is_a_diagram() -> void:
	var q := QuestionEngine.make({"type": TYPE, "unknown": "special-value", "rep": "diagram", "angle": "special-triangles", "seed": 2})
	check(q.diagram != null, "the triangle is drawn")
	check_eq(q.diagram.angles[0].label, "θ")


func test_the_type_is_in_the_courses_with_sl35() -> void:
	for course in ["aa-sl", "aa-hl"]:
		check(TYPE in QuestionEngine.built_types(course), course)
