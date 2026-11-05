extends "res://tests/test_case.gd"
## The box-plot situation (FAL-740): t4-box-plot and t4-outlier-rule are built on it with every
## cell and all four skills, every cell makes four options with one right, a GDC method is Paper 2
## only, a test is an outlier about half of the time and can't be told from its numbers or wording,
## figures show the numbers on ticks, quartiles follow data_summary's convention, and every
## misconception shows up. The SymPy checker (tools/check-answers) checks the maths.

const TYPES := ["t4-box-plot", "t4-outlier-rule"]
const CELLS := {"t4-box-plot": 25, "t4-outlier-rule": 34}
const SKILLS := {"t4-box-plot": 2, "t4-outlier-rule": 2}
const GDC := ["gdc-stats", "gdc-modified-box"]


func _make(t: String, c: Dictionary, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var view := {"type": t, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func test_the_types_are_built_with_every_cell() -> void:
	for t in TYPES:
		check(t in QuestionEngine.built_types(), "%s is not built" % t)
		check_eq(QuestionEngine.cells(false, [t]).size(), CELLS[t], t)
		var skills := {}
		for u in QuestionEngine.type_of(t).unknowns:
			for s in u.skills:
				skills[s] = true
		check_eq(skills.size(), SKILLS[t], "all the listed skills have a question")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for t in TYPES:
		for c in QuestionEngine.cells(false, [t]):
			check(QuestionEngine.extra_formats(t, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
			for f in ["value", "mcq"]:
				for seed in [1, 2, 3]:
					var q := _make(t, c, seed, f)
					check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
					if q.has("error"):
						break
					check_eq(q.situation_id, "box-plot", c.key)
					check_eq(q.choices.size(), 4, c.key)
					check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
					var texts := {}
					for o in q.choices:
						texts[o.text] = true
					check_eq(texts.size(), 4, c.key + ": two options read the same")
					check(q.solutions[0].angle == c.angle or c.angle == "any", c.key)


func test_a_gdc_method_is_paper_2_only() -> void:
	for t in TYPES:
		var type := QuestionEngine.type_of(t)
		for c in QuestionEngine.cells(false, [t]):
			var want: Array = [2] if c.angle in GDC else [1, 2]
			check_eq(QuestionEngine.cell_papers(type, c.unknown, c.rep, c.angle), want, c.key)


func test_a_test_is_a_fair_coin() -> void:
	for c in QuestionEngine.cells(false, ["t4-outlier-rule"]):
		if c.unknown != "decide-outlier":
			continue
		for paper in [1, 2]:
			var yes := 0
			for seed in range(1, 121):
				if _make("t4-outlier-rule", c, seed, "mcq", paper).situation.outl:
					yes += 1
			check(yes >= 40 and yes <= 80, "%s Paper %d: an outlier %d times in 120" % [c.key, paper, yes])


func test_a_test_cant_be_guessed_from_its_options() -> void:
	for c in QuestionEngine.cells(false, ["t4-outlier-rule"]):
		if c.unknown != "decide-outlier":
			continue
		for seed in range(1, 31):
			var q := _make("t4-outlier-rule", c, seed)
			var no := 0
			for o in q.choices:
				if String(o.text).ends_with("is not an outlier"):
					no += 1
			check_eq(no, 2, "%s seed %d: two options end in each verdict" % [c.key, seed])


func test_a_test_stays_close_to_its_fence() -> void:
	# The value is one or two ticks from the fence on either side, on the same kind of quartiles.
	for i in 200:
		var s: Dictionary = BoxPlotSituation.generate(Seeded.new("t|%d" % i), {"ask": "decide-outlier", "rep": "graph", "paper": 2})
		var fence: Q = s.hi_f if s.side == "up" else s.lo_f
		check(not s.x.eq(fence), "draw %d: on the fence" % i)
		check(absf(s.x.sub(fence).to_float()) <= 2.0 * s.tick.to_float(), "draw %d: too far from the fence" % i)
		var beyond: bool = fence.lt(s.x) if s.side == "up" else s.x.lt(fence)
		check_eq(beyond, s.outl, "draw %d" % i)


func test_a_typed_test_needs_the_numbers_and_the_verdict() -> void:
	var c := {"unknown": "decide-outlier", "rep": "words", "angle": "fences"}
	for seed in range(1, 11):
		var q := _make("t4-outlier-rule", c, seed, "value")
		var v: Dictionary = q.answer.values
		var right := {"l": v.l.text(), "r": v.r.text(), "verdict": v.verdict}
		check(QuestionEngine.mark(q, right).correct, "seed %d: the answer itself" % seed)
		var flipped := right.duplicate()
		flipped.verdict = "is not an outlier" if v.verdict == "is an outlier" else "is an outlier"
		var m := QuestionEngine.mark(q, flipped)
		check(not m.correct, "seed %d: the wrong verdict" % seed)
		check_eq(m.misconception, "SL4.2.outlier-test#4", "seed %d" % seed)


func test_figures_show_the_numbers() -> void:
	var one := {"unknown": "read-iqr", "rep": "graph", "angle": "any"}
	var pair := {"unknown": "compare-box-plots", "rep": "graph", "angle": "median-iqr"}
	var pick := {"unknown": "pick-box-from-data", "rep": "terms", "angle": "five-number-summary"}
	var sketch := {"unknown": "quartile-from-no-outliers", "rep": "graph", "angle": "fences"}
	var curve := {"unknown": "five-number-from-cumfreq", "rep": "graph", "angle": "from-cumfreq"}
	for seed in range(1, 13):
		var g: Dictionary = _make("t4-box-plot", one, seed).graph
		check_eq(g.kind, "box")
		check(g.boxes.size() in [1, 2], "one or two boxes")
		var f: Dictionary = _make("t4-box-plot", pair, seed).graph
		check_eq(f.boxes.size(), 2)
		check(f.boxes[0].name != "" and f.boxes[1].name != "", "two named boxes")
		var p: Dictionary = _make("t4-box-plot", pick, seed).graph
		check_eq(p.boxes.map(func(b): return b.name), ["A", "B", "C", "D"])
		var k: Dictionary = _make("t4-outlier-rule", sketch, seed).graph
		check_eq(k.labels[1], "L")
		check_eq(k.scale, false)
		check_eq(_make("t4-box-plot", curve, seed).graph.kind, "cumfreq")


func test_quartiles_follow_data_summary() -> void:
	# The median is left out of the halves when n is odd, as DataSummarySituation does.
	var data: Array = [1, 3, 5, 7, 9, 11, 13].map(func(v): return Q.new(v))
	var f := BoxPlotSituation._quartiles_of(data)
	check(f.q1.eq(Q.new(3)), "Q1 of seven values")
	check(f.q3.eq(Q.new(11)), "Q3 of seven values")
	var kept := BoxPlotSituation.keep_median(data)
	check(kept.q1.eq(Q.new(4)), "the slip keeps the median")
	var even: Array = [1, 2, 3, 4, 5, 6, 7, 8].map(func(v): return Q.new(v))
	var g := BoxPlotSituation._quartiles_of(even)
	check(g.q1.eq(Q.new(5, 2)), "Q1 of eight values")
	check(g.q3.eq(Q.new(13, 2)), "Q3 of eight values")


func test_every_distractor_shows_up() -> void:
	for t in TYPES:
		var seen := {}
		for c in QuestionEngine.cells(false, [t]):
			for seed in range(1, 41):
				for o in _make(t, c, seed).choices:
					if o.ref != "":
						seen[o.ref] = true
		for m in QuestionEngine.type_of(t).misconceptions:
			check(seen.has(m.ref), "%s never comes up" % m.ref)


func test_hand_values() -> void:
	# Q1 = 6, Q3 = 10: the IQR is 4, so the fence is 10 + 6 = 16, and 16 itself is not an outlier.
	var s := {"a": BoxPlotSituation.five(Q.new(2), Q.new(6), Q.new(7), Q.new(10), Q.new(18))}
	check(BoxPlotSituation._fences(s), "the fences")
	check(s.hi_f.eq(Q.new(16)), "the upper fence")
	check(s.lo_f.eq(Q.new(0)), "the lower fence")
	# max 75, IQR 20, no outliers: U is at least 75 − 30 = 45, and L at least 25.
	check(Q.new(75).sub(Q.new(20).mul(Q.new(3, 2))).eq(Q.new(45)), "the least U")
