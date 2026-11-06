extends "res://tests/test_case.gd"
## The inverse-normal situation (FAL-752): t4-inverse-normal is built with every cell. A value is
## the one whose area is the area given, on the right side of the mean, and Paper 1 reaches it with
## no calculator, exactly. The figure shades the area and marks the value. The SymPy checker
## (tools/check-answers) finds every value again from what the student sees.

const TYPE := "t4-inverse-normal"
const CELLS := 95
const P1 := ["shift-same-sd", "mirror-bound", "rule-value", "given-z"]


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _draw(ask: String, i: int) -> Dictionary:
	return InverseNormalSituation.generate(Seeded.new("%s|%d" % [ask, i]), {"ask": ask})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)


func test_every_method_of_the_map_is_in_a_cell() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		seen[c.angle] = true
	check_eq(seen.keys().size(), 3)
	for m in ["gdc-invnorm-left", "via-z", "sketch-tail"]:
		check(seen.has(m), m)


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [1 if c.unknown in P1 else 2], c.key)
		for seed in [1, 2, 3, 4, 5]:
			var q := _make(c, seed)
			check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
			if q.has("error"):
				break
			check_eq(q.choices.size(), 4, c.key)
			check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
			check(q.solutions[0].angle == c.angle, c.key)


func test_a_value_has_the_area_it_was_given() -> void:
	for ask in ["value-below", "value-above", "top-percent", "bottom-percent", "quartile", "percentile", "most-above"]:
		for i in 20:
			var s := _draw(ask, i)
			check(not s.is_empty(), "%s draw %d" % [ask, i])
			var area := InverseNormalSituation.phi((s.x - s.muf) / s.sgf)
			check(absf(area - s.left.to_float()) < 1e-6, "%s draw %d" % [ask, i])
			check_eq(s.x > s.muf, s.left.to_float() > 0.5, "%s draw %d: the side of the mean" % [ask, i])


func test_a_top_share_is_above_the_mean_and_most_above_is_below() -> void:
	for i in 20:
		check(_draw("top-percent", i).z > 0.0, "draw %d" % i)
		check(_draw("bottom-percent", i).z < 0.0, "draw %d" % i)
		check(_draw("most-above", i).z < 0.0, "draw %d" % i)


func test_a_central_interval_holds_its_area() -> void:
	for i in 20:
		var s := _draw("central-bounds", i)
		var inside := InverseNormalSituation.phi((s.hif - s.muf) / s.sgf) - InverseNormalSituation.phi((s.lof - s.muf) / s.sgf)
		check(absf(inside - s.level.to_float()) < 1e-6, "draw %d" % i)
		check(absf(s.muf - s.lof - (s.hif - s.muf)) < 1e-6, "draw %d: the same distance" % i)


func test_a_band_runs_from_its_known_end_to_the_value() -> void:
	for i in 40:
		var s := _draw("band-end", i)
		var a: float = s.b.to_float()
		var inside := absf(InverseNormalSituation.phi((a - s.muf) / s.sgf) - InverseNormalSituation.phi((s.x - s.muf) / s.sgf))
		check(absf(inside - s.level.to_float()) < 1e-6, "draw %d" % i)
		check_eq(s.x < a, s.which == "lower", "draw %d" % i)


func test_the_tails_of_a_ratio_are_in_that_ratio() -> void:
	for i in 40:
		var s := _draw("ratio-tails", i)
		check(s.large.eq(s.small.mul(Q.new(s.r))), "draw %d" % i)
		check(s.ta.add(s.tb).add(s.level).eq(Q.new(1)), "draw %d: the areas add to 1" % i)
		check(s.afl < s.muf and s.bfl > s.muf, "draw %d: the band holds the mean" % i)


func test_paper_1_is_exact_and_shows_no_calculator() -> void:
	var rx := RegEx.create_from_string("(?i)invnorm|normalcdf|gdc|calculator")
	for c in QuestionEngine.cells(false, [TYPE]):
		if not c.unknown in P1:
			continue
		for seed in [1, 2, 3]:
			var q := _make(c, seed)
			check_eq(q.paper, 1, c.key)
			check(q.answer.get("exact", false), c.key + " is not exact")
			for sol in q.solutions:
				for st in sol.steps:
					check(rx.search(str(st)) == null, c.key + ": " + str(st))


func test_a_shift_keeps_the_distance_from_the_mean() -> void:
	for i in 40:
		var s := _draw("shift-same-sd", i)
		var d: int = s.x - s.mu1
		check_eq(absi(d), absi(s.c - s.mu2), "draw %d" % i)
		check_eq(d == s.c - s.mu2, s.rel_x == s.rel_y, "draw %d: same side, same sign" % i)


func test_a_given_line_of_z_is_true_to_3_dp() -> void:
	for i in 40:
		var s := _draw("given-z", i)
		check(absf(s.table.to_float() - InverseNormalSituation.phi(s.z0.to_float())) <= 0.00051, "draw %d" % i)


func test_a_figure_shades_the_area_and_marks_the_value() -> void:
	var c := {"unknown": "value-above", "rep": "diagram", "angle": "gdc-invnorm-left"}
	for seed in range(1, 11):
		var q := _make(c, seed)
		var s: Dictionary = q.situation
		check_eq(q.graph.kind, "normal")
		check_eq(q.graph.shade[0][0], s.x, "the tail starts at the value")
		check(q.graph.shade[0][1] == null, "it runs to the end")
		check_eq(q.graph.marks[0].label, "a")


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 41):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	var t := QuestionEngine.type_of(TYPE)
	for i in t.misconceptions.size():
		var ref: String = t.misconceptions[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never comes up" % ref)
