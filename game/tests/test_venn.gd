extends "res://tests/test_case.gd"
## The venn situation (FAL-725): t4-venn-addition-rule is built with every cell and both skills,
## every cell makes four options with one right, the regions add to the total, every option
## that should be a probability is one, a Venn diagram is drawn with its four regions, Paper 1 is
## exact, every misconception shows up, and SL4.6 is in every course. The SymPy checker
## (tools/check-answers) checks the maths.

const TYPE := "t4-venn-addition-rule"
const CELLS := 30
const COUNTS := ["region-from-totals", "x-from-total", "table-missing-entry"]


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
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for paper in [1, 2]:
				var q := _make(c, 3, f, paper)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					continue
				check_eq(q.paper, paper, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check(q.solutions[0].angle == c.angle, c.key)


func test_the_regions_add_to_the_total() -> void:
	for i in 80:
		for paper in [1, 2]:
			var s: Dictionary = VennSituation.generate(Seeded.new("r|%d" % i), {"ask": "union-from-rule", "paper": paper})
			check_eq(s.a + s.i + s.b + s.o, s.u, "draw %d" % i)
			check(s.a > 0 and s.i > 0 and s.b > 0 and s.o > 0, "draw %d: every region is positive" % i)
			check(s.o > s.i, "draw %d: P(A) + P(B) stays below 1" % i)


func test_every_probability_option_is_a_probability() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.unknown in COUNTS:
			continue
		for seed in range(1, 25):
			for o in _make(c, seed).choices:
				var v: float = Q.of(o.values.v).to_float()
				check(v > 0.0 and v < 1.0, "%s seed %d: option %s" % [c.key, seed, o.text])


func test_a_diagram_shows_its_four_regions() -> void:
	for seed in range(1, 12):
		var q := QuestionEngine.make({"type": TYPE, "unknown": "union-from-regions", "rep": "diagram", "angle": "venn-regions", "seed": seed})
		check_eq(q.graph.kind, "venn")
		for key in ["a", "i", "b", "o"]:
			check(q.graph[key] != "", "seed %d: region %s" % [seed, key])
		var plot := PlotView.new()
		plot.set_spec(q.graph)
		check(plot.custom_minimum_size.y >= 400.0, "the diagram has room")
		plot.free()


func test_x_comes_out_whole_and_the_regions_are_positive() -> void:
	for i in 80:
		var s: Dictionary = VennSituation.generate(Seeded.new("x|%d" % i), {"ask": "x-from-total", "paper": 1})
		check_eq(s.ma * s.x + s.ca + s.mi * s.x + s.ci + s.mb * s.x + s.cb + s.o, s.u, "draw %d" % i)
		check(s.b >= 1, "draw %d: B only is positive" % i)


func test_paper_1_answers_are_exact() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var q := _make(c, 5, "value", 1)
		check(q.answer.get("exact", false), c.key)


func test_the_overlaps_are_right() -> void:
	for i in 40:
		var s: Dictionary = VennSituation.generate(Seeded.new("o|%d" % i), {"ask": "least-overlap", "paper": 1})
		check(Q.new(1).lt(s.pa.add(s.pb)), "draw %d: the two must overlap" % i)
	var a := {"unknown": "least-overlap", "rep": "equation", "angle": "addition-rule"}
	var b := {"unknown": "greatest-overlap", "rep": "equation", "angle": "addition-rule"}
	for seed in range(1, 20):
		var q := _make(a, seed)
		var pa: Q = Answer.parse_number(String(q.lines[0]).trim_prefix("P(A) = ")).q
		var pb: Q = Answer.parse_number(String(q.lines[1]).trim_prefix("P(B) = ")).q
		check(q.answer.values.v.eq(pa.add(pb).sub(Q.new(1))), "least, seed %d" % seed)
		var r := _make(b, seed)
		var ra: Q = Answer.parse_number(String(r.lines[0]).trim_prefix("P(A) = ")).q
		var rb: Q = Answer.parse_number(String(r.lines[1]).trim_prefix("P(B) = ")).q
		check(r.answer.values.v.eq(ra if ra.lt(rb) else rb), "greatest, seed %d" % seed)


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
			check(found, "%s never appears on %s" % [m.ref, u])


func test_the_type_is_in_every_course() -> void:
	for course in Courses.ids():
		check(TYPE in QuestionEngine.built_types(course), course)
