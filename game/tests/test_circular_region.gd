extends "res://tests/test_case.gd"
## The circular-region situation (FAL-739): t3-composite-circular-region is built with every cell
## and both its skills, every cell makes four options with one right on each paper it can make,
## every diagram draws its real shape with the region shaded, the two-conditions roots do what the
## cell says, every misconception shows up, and the type is on the courses with SL3.4. The SymPy
## checker (tools/check-answers) checks the maths.

const TYPE := "t3-composite-circular-region"
const CELLS := 50
const SEG := "sector-minus-triangle"


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
	for s in ["SL3.4.segment-shaded", "SL3.4.sector-two-conditions"]:
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


func test_paper_1_is_the_exact_segment_and_the_two_conditions() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var only: Array = []
	for c in QuestionEngine.cells(false, [TYPE]):
		var ps := QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle)
		if ps == [1]:
			only.append(c.unknown)
		if 1 in ps:
			check(c.unknown == "segment-exact" or c.unknown in CircularRegionViews.BOTH_PAPERS, c.key)
			check(_make(c, 5, "value", 1).answer.get("exact", false), c.key)
	check_eq(only, ["segment-exact"])


func test_a_diagram_draws_the_region_with_its_numbers() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.rep == "diagram"):
		for seed in range(1, 6):
			var q := _make(c, seed, "value")
			check(q.graph != null, c.key + " has no figure")
			check(q.graph.kind in ["region", "sector"], c.key)
			var plot := PlotView.new()
			plot.set_spec(q.graph)
			check(plot.custom_minimum_size.y >= 400.0, c.key)
			plot.free()


func test_a_labelled_angle_is_the_angle_drawn() -> void:
	var c := {"unknown": "segment-area", "rep": "diagram", "angle": SEG}
	for seed in range(1, 30):
		var q := _make(c, seed)
		var label: String = q.graph.angle_label
		var want := float(label.trim_suffix("°"))
		if label.ends_with("°"):
			want = deg_to_rad(want)
		check(absf(q.graph.theta - want) < 1e-9, "seed %d" % seed)
		check(q.graph.shape == "segment" and q.graph.theta < PI, "seed %d" % seed)


func test_the_root_past_two_pi_is_thrown_out() -> void:
	var c := {"unknown": "two-conditions-r", "rep": "equation", "angle": "substitute-eliminate"}
	for paper in [1, 2]:
		for seed in range(1, 25):
			var s: Dictionary = _make(c, seed, "mcq", paper).situation
			var per := float(Answer.parse_number(s.per[0]).q.to_float())
			var r1: float = Answer.parse_number(s.r1).q.to_float()
			var r2: float = Answer.parse_number(s.r2).q.to_float()
			check((per - 2.0 * r1) / r1 > TAU, "seed %d: the small root is a real sector" % seed)
			check((per - 2.0 * r2) / r2 < TAU, "seed %d: the large root is no sector" % seed)


func test_both_roots_are_real_sectors_where_both_are_asked() -> void:
	var c := {"unknown": "two-conditions-both", "rep": "equation", "angle": "substitute-eliminate"}
	for paper in [1, 2]:
		for seed in range(1, 25):
			var s: Dictionary = _make(c, seed, "mcq", paper).situation
			var per: float = Answer.parse_number(s.per[0]).q.to_float()
			var r1: float = Answer.parse_number(s.r1).q.to_float()
			check((per - 2.0 * r1) / r1 < TAU, "seed %d" % seed)


func test_either_order_of_the_two_roots_is_right() -> void:
	var q := _make({"unknown": "two-conditions-both", "rep": "equation", "angle": "substitute-eliminate"}, 7, "value", 1)
	var a: Dictionary = q.answer
	check(Answer.mark(a, {"a": a.values.b.text(), "b": a.values.a.text()}).correct)


func test_the_bank_ratios_are_left_out() -> void:
	for r in CircularRegionSituation.RATIOS:
		check(r != [1, 1] and r != [3, 5], str(r))


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


func test_the_type_is_in_the_courses_with_sl34() -> void:
	for course in ["aa-sl", "aa-hl"]:
		check(TYPE in QuestionEngine.built_types(course), course)
