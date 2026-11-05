extends "res://tests/test_case.gd"
## The geometric-sequence situation (FAL-728): t1-geometric-sequence and t1-sum-to-infinity are
## built with every catalogue cell on one situation, every misconception shows up as an option,
## a calculator's method stays on Paper 2, a graph, table or diagram is shown where the cell says,
## and the numbers match hand values. The SymPy checker (tools/check-answers) checks the maths.

const GEO := "t1-geometric-sequence"
const INF := "t1-sum-to-infinity"
## Cells, counted as tools/pedagogy.mjs counts them.
const CELLS := {GEO: 95, INF: 64}
const UNKNOWNS := {GEO: 21, INF: 19}
const GDC := ["gdc-seq", "gdc-solver", "gdc-sum-seq", "gdc-sigma", "partial-sums"]


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "value", paper: int = 0) -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format, "paper": paper})


func test_the_types_are_built_with_every_cell() -> void:
	for id in CELLS:
		check(id in QuestionEngine.built_types(), "%s is not built" % id)
		check_eq(QuestionEngine.cells(false, [id]).size(), CELLS[id], id)
		var t := QuestionEngine.type_of(id)
		check_eq(t.unknowns.size(), UNKNOWNS[id], id)
		check_eq(t.situation, "geometric-sequence", id)
		var skills := {}
		for u in t.unknowns:
			for s in u.skills:
				skills[s] = true
		check_eq(skills.size(), 4, id + ": every skill has a question")


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for id in CELLS:
		for c in QuestionEngine.cells(false, [id]):
			check(QuestionEngine.extra_formats(id, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
			for f in ["value", "mcq"]:
				for seed in [1, 2, 3]:
					var q := _make(id, c.unknown, c.rep, c.angle, seed, f)
					check(not q.has("error"), "%s as %s seed %d: %s" % [c.key, f, seed, q.get("error")])
					if q.has("error"):
						break
					check_eq(q.situation_id, "geometric-sequence", c.key)
					check_eq(q.choices.size(), 4, c.key + " options")
					check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key + " right options")
					check(not q.solutions.is_empty() and q.solutions[0].angle == c.angle, c.key + ": the asked method comes first")


func test_a_calculator_method_stays_on_paper_2() -> void:
	for id in CELLS:
		for c in QuestionEngine.cells(false, [id]):
			for seed in range(1, 12):
				var q := _make(id, c.unknown, c.rep, c.angle, seed)
				if c.angle in GDC:
					check_eq(q.paper, 2, c.key)
				if q.paper == 1:
					for sol in q.solutions:
						check(not sol.angle in GDC, c.key + " shows a calculator's working on Paper 1")


func test_each_representation_shows_what_it_says() -> void:
	for id in CELLS:
		for c in QuestionEngine.cells(false, [id]):
			var q := _make(id, c.unknown, c.rep, c.angle, 1)
			if c.rep == "graph":
				check(q.graph != null, c.key + ": no graph")
			if c.rep == "table":
				check(q.table != null, c.key + ": no table")
			if c.rep == "diagram":
				check(q.graph != null and q.graph.kind in ["bounce", "squares"], c.key + ": no figure")


func test_every_distractor_misconception_is_an_option() -> void:
	for id in CELLS:
		var t := QuestionEngine.type_of(id)
		for m in t.misconceptions:
			for u in m.in:
				var found := false
				for c in QuestionEngine.cells(false, [id]).filter(func(x): return x.unknown == u):
					for seed in range(1, 200):
						var q := _make(id, u, c.rep, c.angle, seed, "mcq")
						if q.choices.any(func(o): return o.ref == m.ref):
							found = true
							break
					if found:
						break
				check(found, "%s never shows %s on %s" % [id, m.ref, u])


func test_hand_values() -> void:
	var s := {"u1": Q.new(3), "r": Q.new(2)}
	check(GeometricSequenceSituation.term(s, 5).eq(48), "u₅ of 3, 6, 12, …")
	check(GeometricSequenceSituation.sum(s, 4).eq(45), "S₄ of 3 + 6 + 12 + 24")
	check(GeometricSequenceSituation.to_infinity(Q.new(18), Q.new(-2, 3)).eq(Q.new(54, 5)), "S∞ of 18 − 12 + 8 − …")


func test_an_even_gap_gives_both_signs() -> void:
	for seed in range(1, 40):
		var q := _make(GEO, "r-even-gap", "notation", "divide-terms", seed)
		var vals: Array = [q.answer.values.x0, q.answer.values.x1]
		check(vals[0].neg().eq(vals[1]), "r and −r")


func test_a_rejected_root_is_not_kept() -> void:
	for seed in range(1, 40):
		var q := _make(INF, "r-from-u2-reject", "notation", "form-quadratic", seed)
		check_eq(int(str(q.answer.values.n)), 1, "one root stays")
		check(absf(q.answer.values.x0.to_float()) < 1.0, "the root kept is below 1 in size")


func test_a_ball_keeps_its_first_drop_single() -> void:
	# 10 m, rebounding to 1/2: 10 + 2(5 + 2.5 + …) = 30.
	var h := Q.new(10)
	var r := Q.new(1, 2)
	check(h.mul(Q.new(1).add(r)).div(Q.new(1).sub(r)).eq(30), "the closed form")
	for seed in range(1, 20):
		var q := _make(INF, "bounce-total", "words", "split-series", seed, "mcq")
		check(q.choices.any(func(o): return o.ref == "SL1.8.applications#0"), "doubling the drop is an option")


func test_a_typed_answer_is_marked() -> void:
	var q := _make(INF, "x-interval", "equation", "double-inequality", 3)
	var a: Dictionary = q.answer
	check(QuestionEngine.mark(q, {"lo": a.values.lo.key(), "hi": a.values.hi.key()}).correct, "the interval typed")
	check(not QuestionEngine.mark(q, {"lo": a.values.hi.key(), "hi": a.values.lo.key()}).correct, "the ends swapped")
