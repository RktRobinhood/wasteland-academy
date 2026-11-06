extends "res://tests/test_case.gd"
## The geometric-context situation (FAL-752): t1-geometric-in-context is built with every cell and
## both skills, on the bank's split of the papers. "After t" is t multiplications and "in round n"
## is n − 1, a least n is the first whole number past the crossing and no earlier, B starts below
## A and passes it once, and Paper 1 has exact values and no calculator working. The SymPy checker
## (tools/check-answers) checks the maths and works every tagged option out from its slip.

const TYPE := "t1-geometric-in-context"
const CELLS := 98


func _make(c: Dictionary, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var view := {"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func _draw(ask: String, i: int, rep: String = "words", paper: int = 2) -> Dictionary:
	return GeometricContextSituation.generate(Seeded.new("%s|%s|%d" % [ask, rep, i]), {"ask": ask, "rep": rep, "paper": paper})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 2, "both skills have a question")


func test_every_method_of_the_map_has_a_cell() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		seen[c.angle] = true
	for m in ["multiplier", "tabulate", "gdc-table-compare", "graph-intersect", "logs", "gdc-table", "exact-power"]:
		check(seen.has(m), "%s has no cell" % m)


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for paper in QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle):
			for seed in [1, 2, 3, 4, 5]:
				var q := _make(c, seed, "mcq", paper)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.paper, paper, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check(q.solutions[0].angle == c.angle, c.key)


func test_paper_1_has_no_calculator_work() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var both := 0
	for c in QuestionEngine.cells(false, [TYPE]):
		var papers := QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle)
		if papers.size() == 2:
			both += 1
		if not 1 in papers:
			continue
		check(not c.angle in ["logs", "gdc-table", "gdc-table-compare", "graph-intersect"], c.key)
		var q := _make(c, 2, "value", 1)
		check(q.answer.get("exact", false), c.key + " is exact")
		for sol in q.solutions:
			check(sol.angle in ["multiplier", "tabulate", "exact-power"], c.key + " shows " + sol.angle)
	check(both > 0, "some cells make both papers")
	check(QuestionEngine.paper_chance(t) > 0.2, "the cells on both papers make Paper 2 as well")


func test_after_t_is_t_multiplications_and_in_round_n_is_one_fewer() -> void:
	for i in 40:
		var a := _draw("value-after-years", i)
		check(absf(a.v - a.start.to_float() * pow(a.r.to_float(), a.t)) < 1e-6, "draw %d: after t" % i)
		var b := _draw("value-in-round", i)
		check(absf(b.v - b.u1.to_float() * pow(b.r.to_float(), b.n - 1)) < 1e-6, "draw %d: in round n" % i)


func test_a_least_n_is_the_first_past_the_target() -> void:
	for i in 40:
		var s := _draw("least-n-term", i)
		var t: float = s.target.to_float()
		var u: float = s.u1.to_float()
		var r: float = s.r.to_float()
		check(GeometricContextSituation.term(u, r, s.n) > t and GeometricContextSituation.term(u, r, s.n - 1) < t, "draw %d: uₙ" % i)
		var f := _draw("first-below", i)
		check(GeometricContextSituation.term(f.u1.to_float(), f.r.to_float(), f.n) < f.target.to_float(), "draw %d: first below" % i)
		check(GeometricContextSituation.term(f.u1.to_float(), f.r.to_float(), f.n - 1) > f.target.to_float(), "draw %d: not before" % i)
		var g := _draw("least-n-sum", i)
		check(GeometricContextSituation.sum(g.u1.to_float(), g.r.to_float(), g.n) > g.target.to_float(), "draw %d: Sₙ" % i)
		check(GeometricContextSituation.sum(g.u1.to_float(), g.r.to_float(), g.n - 1) < g.target.to_float(), "draw %d: not before" % i)


func test_a_gap_is_the_tail_of_the_series() -> void:
	for i in 30:
		var s := _draw("gap-to-limit", i, "notation")
		check(s.u1.eq(s.c.mul(s.r)), "draw %d: the first term is at k = 1" % i)
		var u: float = s.u1.to_float()
		var r: float = s.r.to_float()
		var tail: float = s.sinf.to_float() - u * (1.0 - pow(r, s.n)) / (1.0 - r)
		check(absf(tail - s.after) < 1e-6, "draw %d: the gap" % i)
		check(tail < s.target.to_float(), "draw %d: past the target" % i)


func test_b_starts_behind_and_passes_once() -> void:
	for i in 40:
		var s := _draw("overtake-first-round", i)
		check(s.b.to_float() < s.a.to_float(), "draw %d" % i)
		check(s.after_b > s.after_a and s.before_b < s.before_a, "draw %d: either side of n" % i)


func test_an_exact_power_is_exact() -> void:
	for i in 30:
		var s := _draw("count-terms-power", i, "notation", 1 + i % 2)
		check(s.last.eq(s.u1.mul(GeometricSequenceSituation.power(s.r, s.n - 1))), "draw %d" % i)
		check(s.last.is_int(), "draw %d" % i)


func test_a_figure_is_the_question() -> void:
	var ball := _make({"unknown": "rebound-height", "rep": "diagram", "angle": "multiplier"}, 1)
	check_eq(ball.graph.kind, "bounce")
	check_eq(ball.graph.peaks.size(), 7, "the bounces are drawn")
	var dots := _make({"unknown": "first-below", "rep": "graph", "angle": "logs"}, 3)
	check_eq(dots.graph.hlines.size(), 1, "the target is drawn")
	check(dots.graph.points.size() >= dots.situation.n, "the dots pass the target")
	var race := _make({"unknown": "overtake-first-round", "rep": "graph", "angle": "graph-intersect"}, 2)
	check_eq(race.graph.curves.size(), 2, "both models are drawn")


func test_every_distractor_shows_up() -> void:
	var seen := {}
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		for paper in QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle):
			for seed in range(1, 31):
				for o in _make(c, seed, "mcq", paper).choices:
					if o.ref != "":
						seen[o.ref] = true
	for m in t.misconceptions:
		check(seen.has(m.ref), "%s never comes up" % m.ref)
