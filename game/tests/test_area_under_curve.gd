extends "res://tests/test_case.gd"
## The area-under-curve situation (FAL-776): t5-ext-area-under-curve is built with every cell. R is
## above the x-axis, the figure shades exactly R, the pick-the-graph cards shade the region of
## their own limits, the GDC cells are Paper 2, and every tag shows up as an option. The SymPy
## checker (tools/check-answers) reads R back from the figure or the words and integrates again.

const TYPE := "t5-ext-area-under-curve"
const CELLS := 19
const S := preload("res://engine/situations/area_under_curve.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	for c in QuestionEngine.cells(false, [TYPE]):
		for f in ["value", "mcq"] + QuestionEngine.extra_formats(TYPE, c.unknown, c.angle):
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
				if q.has("error"):
					break
				var gdc: bool = c.angle.begins_with("gdc-") or c.unknown == "area-gdc-limits"
				check_eq(q.paper, 2 if gdc else 1, c.key)
				check_eq(q.graph != null, c.rep == "graph", c.key + ": a figure on the graph view only")


func test_r_is_above_the_axis_and_shaded() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.rep == "graph"):
		for seed in range(1, 8):
			var q := _make(c, seed)
			var sh: Array = q.graph.shade
			check_eq(sh.size(), 1, c.key)
			for strip in sh[0]:
				check(strip[1] == 0.0 and strip[2] >= -1e-9, "%s: a strip below the axis" % c.key)


func test_the_cards_shade_their_own_limits() -> void:
	var c := {"unknown": "region-for-integral", "rep": "equation", "angle": "read-boundaries"}
	for seed in range(1, 10):
		var q := _make(c, seed)
		check_eq(q.format, "pick-the-graph")
		check_eq(q.graphs.size(), 4)
		var right: int = q.choices.find(q.choices.filter(func(o): return o.correct)[0])
		var sh: Array = q.graphs[right].shade[0]
		check_eq([sh[0][0], sh[-1][0]], [float(q.situation.p), float(q.situation.q)], "seed %d" % seed)


func test_the_areas_match_hand_values() -> void:
	# −(x + 2)(x − 2) = 4 − x² from −2 to 2: 32/3.
	var s := {"coeffs": [Q.new(-1), Q.new(0), Q.new(4)]}
	check_eq(S.area(s, -2, 2).text(), "32/3")
	# The trapezium under 2x + 3 from 2 to 6: ½ × (7 + 15) × 4 = 44.
	check_eq(S.area({"coeffs": [Q.new(2), Q.new(3)]}, 2, 6).text(), "44")


func test_every_tag_shows_up_as_an_option() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 10):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	for m in QuestionEngine.type_of(TYPE).misconceptions:
		if m.as == "distractor":
			check(seen.has(m.ref), "%s never shows" % m.ref)
