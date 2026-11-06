extends "res://tests/test_case.gd"
## The trig-wave situation (FAL-751): t3-trig-read-features and t3-trig-model-use are built with every
## cell and both skills, on a situation that extends trig-model; no extra format; four different
## options; a GDC method is Paper 2 only and shows the equation it graphs; the figures are drawn
## when asked; hand values; and every misconception shows up. tools/check-answers checks the maths.

const TYPES := ["t3-trig-read-features", "t3-trig-model-use"]
const SKILLS := {"t3-trig-read-features": "SL3.7.read-features", "t3-trig-model-use": "SL3.7.model-context"}
const GDC := ["gdc-graph", "gdc-intersection"]


func _make(t: String, c: Dictionary, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var view := {"type": t, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func _view(unknown: String, rep: String, angle: String, seed: int, paper: int = 0, t: String = "t3-trig-read-features") -> Dictionary:
	return _make(t, {"unknown": unknown, "rep": rep, "angle": angle}, seed, "mcq", paper)


func test_the_types_are_built_with_every_cell_and_skill() -> void:
	for t in TYPES:
		check(t in QuestionEngine.built_types(), "%s is not built" % t)
		check(QuestionEngine.cells(false, [t]).size() >= 60, t)
		check(QuestionEngine.type_of(t).unknowns.all(func(u): return SKILLS[t] in u.skills), t)
		check_eq(QuestionEngine.type_of(t).situation, "trig-wave", t)


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for t in TYPES:
		for c in QuestionEngine.cells(false, [t]):
			check(QuestionEngine.extra_formats(t, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
			for f in ["value", "mcq"]:
				for seed in [1, 2]:
					var q := _make(t, c, seed, f)
					check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
					if q.has("error"):
						break
					check_eq(q.situation_id, "trig-wave", c.key)
					check_eq(q.choices.size(), 4, c.key)
					check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
					var texts := {}
					for o in q.choices:
						texts[o.text] = true
					check_eq(texts.size(), 4, c.key + ": two options read the same")
					check_eq(q.solutions[0].angle, c.angle, c.key)
					for sol in q.solutions:
						check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
					check_eq(q.graph != null, c.rep == "graph", c.key + ": the figure")


func test_a_gdc_method_is_paper_2_only() -> void:
	for t in TYPES:
		var type := QuestionEngine.type_of(t)
		for c in QuestionEngine.cells(false, [t]):
			if c.angle in GDC:
				check_eq(QuestionEngine.cell_papers(type, c.unknown, c.rep, c.angle), [2], c.key)


func test_paper_1_shows_no_gdc_tab() -> void:
	for t in TYPES:
		for c in QuestionEngine.cells(false, [t]):
			var q := _make(t, c, 3)
			if q.paper == 1:
				for sol in q.solutions:
					check(not sol.angle in GDC, c.key)


func test_a_figure_hides_its_equation_unless_the_gdc_needs_it() -> void:
	for seed in [1, 2, 3, 4]:
		var read := _view("amplitude", "graph", "read-parameters", seed)
		check_eq(read.lines, ["The graph shows part of y = f(x)."])
		check_eq(read.graph.points.size(), 2, "the turning points are marked")
		check_eq(read.solutions.filter(func(sol): return sol.angle == "gdc-graph").size(), 0, "no equation to graph")
		var gdc := _view("amplitude", "graph", "gdc-graph", seed)
		check(gdc.lines[0].contains("where f(x) = "), gdc.lines[0])
		check_eq(gdc.graph.points.size(), 0, "the GDC finds the turning points")
		check_eq(gdc.paper, 2)


func test_b_is_written_every_way_the_exam_does() -> void:
	var s := {"kind": "x", "bq": Q.new(1, 2), "c": Q.new(0), "a": Q.new(-3), "d": Q.new(1), "fn": "sin"}
	check_eq(TrigWaveViews.wave_text(s), "−3 sin(x/2) + 1")
	check_eq(TrigWaveViews.per(s).key(), "4")
	s.bq = Q.new(2, 3)
	check_eq(TrigWaveViews.b_x(s), "2x/3")
	s.merge({"kind": "pi", "bq": Q.new(4), "a": Q.new(6), "d": Q.new(0), "fn": "cos"}, true)
	check_eq(TrigWaveViews.wave_text(s), "6 cos(4πx)")
	check_eq(TrigWaveViews.per(s).key(), "1/2")
	s.bq = Q.new(1, 6)
	check_eq(TrigWaveViews.b_x(s), "πx/6")
	s.merge({"kind": "x", "bq": Q.new(2), "fn": "tan"}, true)
	check_eq(TrigWaveViews.per(s).key(), "1/2", "tan: π ÷ b")


func test_the_first_peak_by_hand() -> void:
	var s := {"kind": "x", "bq": Q.new(2), "c": Q.new(0), "a": Q.new(3), "d": Q.new(1), "fn": "sin"}
	check_eq(TrigWaveViews.first_max(s).key(), "1/4", "3 sin 2x peaks at π/4")
	s.a = Q.new(-3)
	check_eq(TrigWaveViews.first_max(s).key(), "3/4", "−3 sin 2x peaks at 3π/4")
	s.fn = "cos"
	check_eq(TrigWaveViews.first_max(s).key(), "1/2", "−3 cos 2x peaks at π/2")
	s.a = Q.new(3)
	check_eq(TrigWaveViews.first_max(s).key(), "1", "3 cos 2x first peaks after 0 at π")


func _model() -> Dictionary:
	return {"A": Q.new(-4), "d": Q.new(10), "a": Q.new(4), "C": Q.new(0), "fn": "cos", "T": 12.0, "B": PI / 6.0, "tmax": 6.0, "tmin": 12.0}


func test_a_model_by_hand() -> void:
	var s := _model()
	check_eq(snappedf(TrigWaveViews.m_value(s, 3.0), 1e-9), 10.0, "−4 cos(π/2) + 10")
	check_eq(snappedf(TrigWaveViews.m_value(s, 6.0), 1e-9), 14.0, "the top")
	var xs := TrigWaveViews.crossings(s, 12.0, 24.0)
	check_eq(xs.size(), 4, "two a cycle")
	check_eq(snappedf(xs[0], 1e-9), 4.0, "−4 cos(πt/6) + 10 = 12 at t = 4")
	check_eq(snappedf(xs[1], 1e-9), 8.0)
	check_eq(snappedf(TrigWaveViews.peak_around(s, 12.0)[1], 1e-9), 2.0, "2 either side of the peak")


func test_degree_mode_is_worked_out_and_named() -> void:
	var seen := 0
	for seed in range(1, 21):
		var q := _view("value-at-time", "words", "substitute-evaluate", seed, 2, "t3-trig-model-use")
		for o in q.choices:
			if o.ref == "SL3.7.model-context#0":
				seen += 1
				check(not o.correct, "degree mode can't be right")
	check(seen >= 15, "degree mode is nearly always an option")


func test_only_the_first_time_is_a_wrong_option_that_cant_be_typed_as_the_answer() -> void:
	for seed in range(1, 11):
		var q := _view("all-times", "equation", "gdc-intersection", seed, 2, "t3-trig-model-use")
		check(int(str(q.answer.values.n)) >= 2, "more than one time")
		var only: Array = q.choices.filter(func(o): return o.ref == "SL3.7.model-context#1")
		check_eq(only.size(), 1, "the first time alone is offered")
		check(not only[0].text.contains(" or "), only[0].text)


func test_paper_1_model_is_exact() -> void:
	for seed in range(1, 11):
		var q := _view("exact-value", "words", "substitute-evaluate", seed, 1, "t3-trig-model-use")
		check_eq(q.paper, 1)
		check(q.answer.get("exact", false), "exact")


func test_every_misconception_shows_up() -> void:
	for t in TYPES:
		var ty := QuestionEngine.type_of(t)
		for m in ty.misconceptions:
			for u in m.in:
				var found := false
				for c in QuestionEngine.cells(false, [t]).filter(func(x): return x.unknown == u):
					for seed in range(1, 31):
						if _make(t, c, seed).choices.any(func(o): return o.ref == m.ref):
							found = true
							break
					if found:
						break
				check(found, "%s: %s never appears on %s" % [t, m.ref, u])
