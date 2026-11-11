extends "res://tests/test_case.gd"
## The trig-sketch situation (FAL-754): t3-trig-sketch is built with every cell and all three methods
## of SL3.7.sketch. The four sketch unknowns are pick-the-graph, four different cards on one window;
## the features are typed. The GDC's cells are Paper 2 and everything else Paper 1, worked by hand.
## Values match sums done by hand, a figure is the wave with nothing marked, the map strings quote no
## numbers, and every tag shows up as an option. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t3-trig-sketch"
const CELLS := 22


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var want: Array = [2] if c.angle == TrigSketchViews.GDC else [1]
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), want, c.key)


func test_every_method_of_the_skill_is_an_angle() -> void:
	var angles := {}
	for a in QuestionEngine.type_of(TYPE).angles:
		angles[a.method] = true
	for m in ["quarter-period-points", "transform-base", "gdc-transfer"]:
		check(angles.has(m), m)


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		var pick: bool = c.unknown in TrigSketchSituation.PICKS
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "trig-sketch", c.key)
				check_eq(q.format, "pick-the-graph" if pick else f, c.key)
				check_eq(q.paper, 2 if c.angle == TrigSketchViews.GDC else 1, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options are the same")
				check_eq(q.solutions[0].angle, c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps in %s" % [c.key, sol.steps.size(), sol.name])


func test_paper_1_is_worked_by_hand() -> void:
	var rx := RegEx.create_from_string("(?i)\\b(gdc|calculator|radian mode|zero tool|maximum tool)\\b")
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.angle == TrigSketchViews.GDC:
			continue
		for seed in [4, 5]:
			var q := _make(c, seed)
			check_eq(q.paper, 1, c.key)
			for sol in q.solutions:
				for st in sol.steps:
					check(rx.search(st) == null, "%s: %s" % [c.key, st])


func test_the_sums_match_hand_values() -> void:
	# One period of sin(2x) is π, of tan(x/2) 2π.
	check(TrigSketchSituation.period({"fn": "sin", "b": Q.new(2)}).eq(1))
	check(TrigSketchSituation.period({"fn": "tan", "b": Q.new(1, 2)}).eq(2))
	check(TrigSketchSituation.period({"fn": "cos", "b": Q.new(3)}).eq(Q.new(2, 3)))
	# −6 sin(x/2) + 3 = 0: sin(x/2) = 1/2, x/2 = π/6 or 5π/6, so x = π/3 or 5π/3.
	var xs := TrigSketchSituation.zeros_exact("sin", Q.new(1, 2), Q.new(1, 2))
	check(xs[0].eq(Q.new(1, 3)) and xs[1].eq(Q.new(5, 3)), str(xs))
	# 6 cos(2x) + 3 = 0: cos(2x) = −1/2, 2x = 2π/3 or 4π/3, so x = π/3 or 2π/3.
	var ys := TrigSketchSituation.zeros_exact("cos", Q.new(-1, 2), Q.new(2))
	check(ys[0].eq(Q.new(1, 3)) and ys[1].eq(Q.new(2, 3)), str(ys))
	# 2.8 sin(1.1x) − 1.9 peaks at 1.1x = π/2: x = 1.42800, y = 0.9; its low at x = 4.28399, y = −4.7.
	var w := {"fn": "sin", "a": Q.new(28, 10), "b": Q.new(11, 10), "d": Q.new(-19, 10)}
	var t := TrigSketchSituation.dec_turns(w, 0.0, 5.0)
	check(t.tops.size() == 1 and absf(t.tops[0] - 1.428000) < 1e-5, str(t))
	check(t.lows.size() == 1 and absf(t.lows[0] - 4.283999) < 1e-5, str(t))
	check(absf(TrigSketchSituation.value(w, t.tops[0]) - 0.9) < 1e-9)
	# 2.8 sin(0.7x) − 2.1 = 0: sin(0.7x) = 0.75, x = 1.21152 or 3.27647.
	var z := TrigSketchSituation.dec_zeros({"fn": "sin", "a": Q.new(28, 10), "b": Q.new(7, 10), "d": Q.new(-21, 10)}, 0.0, 4.0)
	check(z.size() == 2 and absf(z[0] - 1.21152) < 1e-5 and absf(z[1] - 3.27647) < 1e-5, str(z))
	check_eq(TrigSketchViews.fn_text(Q.new(-2), "tan", Q.new(1, 2), Q.new(2)), "−2 tan(x/2) + 2")
	check_eq(TrigSketchViews.fn_text(Q.new(1), "cos", Q.new(1), Q.new(0)), "cos x")
	check_eq(TrigSketchViews.fn_text(Q.new(28, 10), "sin", Q.new(11, 10), Q.new(-19, 10)), "2.8 sin(1.1x) − 1.9")


func test_the_four_cards_share_a_window_and_differ() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if not c.unknown in TrigSketchSituation.PICKS:
			continue
		for seed in [1, 2, 3, 4]:
			var q := _make(c, seed)
			check_eq(q.graphs.size(), 4, c.key)
			var first: Dictionary = q.graphs[0]
			var seen := {}
			for g in q.graphs:
				check(g.card, c.key)
				check_eq([g.x0, g.x1, g.y0, g.y1], [first.x0, first.x1, first.y0, first.y1], c.key + ": the windows differ")
				check_eq(g.x_ticks, first.x_ticks, c.key + ": the axis marks differ")
				check(g.curves.size() >= 1 and g.curves[0].size() > 10, c.key)
				seen[str(g.curves)] = true
			check_eq(seen.size(), 4, "%s seed %d: two cards are the same" % [c.key, seed])
			if c.unknown == "sketch-tan":
				var right: Dictionary = q.graphs[q.choices.find(q.choices.filter(func(o): return o.correct)[0])]
				check(right.vlines.size() == 2 and right.curves.size() >= 2, c.key + ": the right card shows no asymptotes")


func test_a_figure_is_the_wave_with_nothing_marked() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(e): return e.rep == "graph"):
		for seed in [1, 2, 3]:
			var q := _make(c, seed)
			check(q.graph != null, c.key)
			check(q.graph.curves[0].size() > 10, c.key)
			check(q.graph.points.is_empty(), c.key + ": a point is marked")
			check(q.lines[0].contains("with nothing marked"), c.key)


func test_a_table_gives_five_key_points() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(e): return e.rep == "table"):
		for seed in [1, 2, 3]:
			var q := _make(c, seed)
			check_eq(q.table.rows[0][0], "x", c.key)
			check_eq(q.table.rows[0][1].size(), 5, c.key)
			check_eq(q.table.rows[1][1].size(), 5, c.key)


func test_the_map_strings_quote_no_numbers() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for m in t.misconceptions:
		check(RegEx.create_from_string("\\d").search(m.text) == null, m.text)


func test_every_tag_shows_up_as_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 16):
			var q := _make(c, seed)
			for o in q.choices:
				if o.ref != "":
					seen[o.ref] = true
	for i in t.misconceptions.size():
		var ref: String = t.misconceptions[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never shows" % ref)
