extends "res://tests/test_case.gd"
## The cumulative-frequency situation (FAL-726): t4-cumulative-frequency is built with every cell
## and all three skills, every cell makes four options with one right on Paper 1 alone, a curve
## rises through grid corners and every class boundary is one, a table adds up and its estimates
## end, the figure has room, every misconception shows up, and SL4.2 is in every course. The SymPy
## checker (tools/check-answers) reads each answer back off the drawn curve.

const TYPE := "t4-cumulative-frequency"
const CELLS := 30


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 3, "all three listed skills have a question")


func test_every_cell_makes_a_paper_1_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in range(1, 8):
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					continue
				check_eq(q.paper, 1, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				if q.answer.kind == "number":
					check(q.answer.get("exact", false), c.key)


func test_a_curve_rises_through_grid_corners() -> void:
	for i in 80:
		var s := CumulativeFrequencySituation.generate(Seeded.new("c|%d" % i), {"ask": "cutoff-top", "rep": "graph"})
		check_eq(s.dy * CumulativeFrequencySituation.SQUARES, s.n, "draw %d" % i)
		for k in s.knots.size():
			check_eq(s.knots[k][0] % s.dx, 0, "draw %d" % i)
			check_eq(s.knots[k][1] % s.dy, 0, "draw %d" % i)
			check(k == 0 or (s.knots[k][0] > s.knots[k - 1][0] and s.knots[k][1] > s.knots[k - 1][1]), "draw %d: not rising" % i)
		for k in range(1, s.curve.size()):
			check(s.curve[k][0] > s.curve[k - 1][0] and s.curve[k][1] > s.curve[k - 1][1], "draw %d: the curve overshoots" % i)
		for x in s.bs:
			check(x == s.bs[0] or CumulativeFrequencySituation.y_at(s, x) > 0, "draw %d: a boundary off the knots" % i)
		check(CumulativeFrequencySituation.x_at(s, s.n - s.top) > 0, "draw %d" % i)
		check(CumulativeFrequencySituation.x_at(s, s.top) > 0, "draw %d" % i)


func test_a_table_adds_up_and_its_estimates_end() -> void:
	for i in 80:
		var s := CumulativeFrequencySituation.generate(Seeded.new("t|%d" % i), {"ask": "median-from-table", "rep": "table"})
		check_eq(s.cf[-1], s.n, "draw %d" % i)
		var v: Q = CumulativeFrequencySituation.interp(s, s.n / 2)
		check(Q.new(10).mul(v).is_int(), "draw %d: %s" % [i, v.text()])
		check(Q.new(s.bs[0]).lt(v) and v.lt(Q.new(s.bs[-1])), "draw %d" % i)


func test_a_curve_is_drawn_with_room_to_read() -> void:
	var q := QuestionEngine.make({"type": TYPE, "unknown": "median-from-graph", "rep": "graph", "angle": "across-and-down", "seed": 4})
	check_eq(q.graph.kind, "cumfreq")
	var plot := PlotView.new()
	plot.set_spec(q.graph)
	check(plot.custom_minimum_size.y >= 800.0, "the curve has room")
	plot.free()


func test_pick_the_curve_has_four_graphs() -> void:
	for seed in range(1, 12):
		var q := QuestionEngine.make({"type": TYPE, "unknown": "pick-curve", "rep": "table", "angle": "plot-upper-bounds", "seed": seed})
		check_eq(q.format, "pick-the-graph")
		check_eq(q.graphs.size(), 4)


func test_every_distractor_misconception_is_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for m in t.misconceptions:
		for u in m["in"]:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 60):
					if _make(c, seed).choices.any(func(o): return o.ref == m.ref):
						found = true
						break
			check(found, "%s never appears on %s" % [m.ref, u])


func test_the_type_is_in_every_course() -> void:
	for course in Courses.ids():
		check(TYPE in QuestionEngine.built_types(course), course)
