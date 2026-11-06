extends "res://tests/test_case.gd"
## The trig-model-equation situation (FAL-752): t3-trig-model-equation is built with every cell, on a
## situation that extends trig-wave; no extra format; four different options; exact times are Paper 1
## and a GDC or a story's level Paper 2; the figures are drawn when asked; the counts, bands and times
## against hand values; degree mode and the touching line as options; and every misconception shows
## up. tools/check-answers checks the maths.

const T := "t3-trig-model-equation"
const GDC := "gdc-intersect"


func _make(c: Dictionary, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var view := {"type": T, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func _view(unknown: String, rep: String, angle: String, seed: int, paper: int = 0) -> Dictionary:
	return _make({"unknown": unknown, "rep": rep, "angle": angle}, seed, "mcq", paper)


## y = 2 sin x + 1 on 0 ≤ x ≤ 2π, or another wave with these changed.
func _wave(fn: String = "sin", hi: Q = Q.new(2)) -> Dictionary:
	return {"kind": "x", "fn": fn, "a": Q.new(2), "d": Q.new(1), "bq": Q.new(1), "c": Q.new(0), "top": Q.new(3), "low": Q.new(-1), "lo_x": Q.new(0), "hi_x": hi}


func test_the_type_is_built_with_every_cell_and_skill() -> void:
	check(T in QuestionEngine.built_types(), "not built")
	check(QuestionEngine.cells(false, [T]).size() >= 90, "cells")
	var ty := QuestionEngine.type_of(T)
	check(ty.unknowns.all(func(u): return "SL3.8.graphical" in u.skills), "skill")
	check_eq(ty.situation, "trig-model-equation")
	var methods: Array = ty.angles.map(func(a): return a.method)
	for m in [GDC, "sketch-and-count", "range-reasoning"]:
		check(m in methods, m)


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [T]):
		check(QuestionEngine.extra_formats(T, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "trig-model-equation", c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check_eq(q.solutions[0].angle, c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 6, "%s: %d steps" % [c.key, sol.steps.size()])
				check_eq(q.graph != null, c.rep == "graph", c.key + ": the figure")


func test_the_papers_are_where_the_maths_is() -> void:
	var type := QuestionEngine.type_of(T)
	for c in QuestionEngine.cells(false, [T]):
		var ps := QuestionEngine.cell_papers(type, c.unknown, c.rep, c.angle)
		if c.unknown in TrigModelEquationViews.EXACT:
			check_eq(ps, [1], c.key)
		elif c.angle == GDC or c.unknown in TrigModelEquationViews.STORY or c.unknown in TrigModelEquationViews.VS:
			check_eq(ps, [2], c.key)
		else:
			check_eq(ps, [1, 2], c.key)


func test_paper_1_is_exact_with_no_calculator() -> void:
	for c in QuestionEngine.cells(false, [T]).filter(func(x): return x.angle != GDC and x.unknown in TrigModelEquationViews.EXACT + TrigModelEquationViews.WAVE):
		for seed in range(1, 4):
			var q := _make(c, seed, "mcq", 1)
			check_eq(q.paper, 1, c.key)
			check(q.solutions.all(func(sol): return sol.angle != GDC), c.key)
			check(q.choices.all(func(o): return o.ref != TrigModelEquationViews.R_GDC_DEGREES), c.key + ": degree mode on Paper 1")


func test_counting_along_a_wave_by_hand() -> void:
	var s := _wave()
	check_eq(TrigModelEquationViews.count_k(s, 2.0), 2, "crosses twice")
	check_eq(TrigModelEquationViews.count_k(s, 3.0), 1, "touches the top")
	check_eq(TrigModelEquationViews.count_k(s, 1.0), 3, "the ends and the middle")
	check_eq(TrigModelEquationViews.count_k(s, -1.0), 1, "touches the bottom")
	check_eq(TrigModelEquationViews.count_k(s, 4.0), 0, "over the top")
	# In degree mode 2π is a tiny angle, so the wave barely leaves its start.
	check_eq(TrigModelEquationViews.count_k(s, 2.0, true), 0, "degree mode")


func test_a_band_of_k_by_hand() -> void:
	# 2 cos x + 1 on 0 ≤ x ≤ 2π: the top is at both ends, so k = 3 still has two solutions.
	var bs := TrigModelEquationViews.bands(_wave("cos"))
	var b := TrigModelEquationSituation._band(bs, 2)
	check(b.lo.eq(-1) and b.hi.eq(3), "−1 to 3")
	check_eq(b.r1, "<")
	check_eq(b.r2, "≤")
	# 2 sin x + 1 on 0 ≤ x ≤ π: a hump, whose top only touches.
	var hump := TrigModelEquationSituation._band(TrigModelEquationViews.bands(_wave("sin", Q.new(1))), 2)
	check(hump.lo.eq(1) and hump.hi.eq(3), "1 to 3")
	check_eq(hump.r1, "≤")
	check_eq(hump.r2, "<")
	# 2 sin x + 1 on 0 ≤ x ≤ 2π: two has a gap at k = 1, so it isn't one band.
	check(TrigModelEquationSituation._band(TrigModelEquationViews.bands(_wave()), 2).is_empty(), "a broken band")


func test_exact_times_by_hand() -> void:
	# −10 cos(πt/6) + 20 at 15: cos = 1/2, t = 2 or 10.
	var s := {"fn": "cos", "A": Q.new(-10), "a": Q.new(10), "d": Q.new(20), "C": Q.new(0), "period": Q.new(12), "ratio": Q.new(1, 2), "level": Q.new(15)}
	var ts := TrigModelEquationViews.exact_ts(s, TrigModelEquationViews.exact_us(s), Q.new(24))
	check_eq(ts.map(func(t): return t.to_float()), [2.0, 10.0, 14.0, 22.0])


func test_the_stretches_of_a_span_by_hand() -> void:
	# 10 cos(π(t − 6)/6) + 20 is above 25 from 4 to 8 in each cycle of 12.
	var s := {"fn": "cos", "A": Q.new(10), "a": Q.new(10), "d": Q.new(20), "C": Q.new(6), "B": PI / 6.0, "T": 12.0}
	var ps := TrigModelEquationViews.pieces(s, 25.0, 18.0, true)
	check_eq(ps.size(), 2)
	check_eq(snappedf(ps[0][0], 1e-9), 4.0)
	check_eq(snappedf(ps[1][1], 1e-9), 18.0)
	check_eq(snappedf(TrigModelEquationViews.total(ps), 1e-9), 4.0 + 2.0)
	check_eq(TrigModelEquationViews.set_text([[4.0, 8.0], [16.0, 18.0]], 18.0), "4.00 < t < 8.00 or 16.0 < t ≤ 18")


func test_a_curve_against_a_line_by_hand() -> void:
	var s := {"vs": "line", "fn": "sin", "a": Q.new(1), "bq": Q.new(1), "m": Q.new(1, 2), "origin": true, "lo_x": Q.new(-1), "hi_x": Q.new(1)}
	var xs := TrigModelEquationViews.vs_roots(s)
	check_eq(xs.size(), 3)
	check_eq(xs[1], 0.0)
	check(absf(xs[2] - 1.8955) < 1e-4, "the crossing")
	check_eq(TrigModelEquationViews.vs_roots(s, true), [0.0], "in degrees only x = 0 is left")


func test_the_map_examples_are_never_asked() -> void:
	var rx := RegEx.create_from_string("^(sin\\(x\\) = 0\\.3x|2 cos\\(x\\) = e\\^\\(−x\\))")
	for seed in range(1, 41):
		for u in ["solve-vs-line", "solve-vs-exp", "count-vs-line"]:
			check(rx.search(_view(u, "equation", GDC, seed).lines[0]) == null, u)


func test_a_touching_line_is_an_option_that_isnt_right() -> void:
	for seed in range(1, 11):
		var q := _view("k-no-solution", "equation", "range-reasoning", seed)
		var slip: Array = q.choices.filter(func(o): return o.ref == "SL3.8.graphical#1")
		check_eq(slip.size(), 1, "the ends offered")
		check(slip[0].text.contains("≤"), slip[0].text)
		var q2 := _view("count-at-extreme", "equation", "sketch-and-count", seed)
		check(q2.choices.any(func(o): return o.ref == "SL3.8.graphical#4"), "two for each touch")


func test_degree_mode_is_worked_out_and_named() -> void:
	var seen := 0
	for seed in range(1, 21):
		for u in ["times-in-window", "set-above-level", "solve-vs-line", "count-vs-line"]:
			var q := _view(u, "equation", GDC, seed)
			for o in q.choices:
				if o.ref == "SL3.8.graphical#2":
					seen += 1
					check(not o.correct, "degree mode can't be right")
	check(seen >= 40, "degree mode is usually an option: %d" % seen)


func test_a_figure_shows_every_curve_and_the_level() -> void:
	var q := _view("set-above-level", "graph", GDC, 1)
	check_eq(q.graph.hlines.size(), 1, "the level")
	q = _view("solve-vs-exp", "graph", GDC, 1)
	check_eq(q.graph.curves.size(), 2, "both curves")
	q = _view("k-exactly-n", "graph", "sketch-and-count", 1)
	check(q.graph.points.size() >= 1, "a turning point marked")


func test_every_misconception_shows_up() -> void:
	var ty := QuestionEngine.type_of(T)
	for m in ty.misconceptions:
		for u in m.in:
			var found := false
			for c in QuestionEngine.cells(false, [T]).filter(func(x): return x.unknown == u):
				for seed in range(1, 41):
					if _make(c, seed).choices.any(func(o): return o.ref == m.ref):
						found = true
						break
				if found:
					break
			check(found, "%s never appears on %s" % [m.ref, u])
