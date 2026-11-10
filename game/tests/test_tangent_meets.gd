extends "res://tests/test_case.gd"
## The tangent-meets-curve situation (FAL-754): t5-normal-meets-curve is built with every cell, on
## Paper 2. The line really is the tangent or the normal, an intercept is on its axis, Q is on both
## the curve and the line, a built-backwards cubic has (x − x₀)² in curve minus tangent, the figure
## is the curve and the line, and every tag shows up as an option. The SymPy checker
## (tools/check-answers) checks the maths.

const TYPE := "t5-normal-meets-curve"
const CELLS := 30


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _draw(ask: String, i: int) -> Dictionary:
	return TangentMeetsSituation.generate(Seeded.new("%s|%d" % [ask, i]), {"ask": ask})


func _line_at(s: Dictionary, x: float) -> float:
	return TangentMeetsSituation.fl(s.lm) * x + TangentMeetsSituation.fl(s.lc)


func test_the_type_is_built_with_every_cell_on_paper_2() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2], c.key)


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "tangent-meets-curve", c.key)
				check_eq(q.paper, 2, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.solutions[0].angle, c.angle, c.key)
				check_eq(q.graph == null, c.rep == "equation", c.key + ": a figure on the graph and the diagram only")


func test_the_sums_match_hand_values() -> void:
	# x² + 16/x at x = 2: f = 12, f′ = 4 − 4 = 0; at x = 1: f = 17, f′ = 2 − 16 = −14.
	var r := {"fam": "recip", "f": {"p": Q.new(1), "A": Q.new(16), "q": Q.new(0)}}
	check_eq(TangentMeetsSituation.fq(r, 2).text(), "12")
	check_eq(TangentMeetsSituation.dfq(r, 1).text(), "−14")
	# x³ − 3x at x = 1: the tangent y = −2 meets it again where x³ − 3x + 2 = (x − 1)²(x + 2) = 0.
	var c := {"fam": "cubic", "x0": 1, "f": {"a": Q.new(1), "b": Q.new(0), "c": Q.new(-3), "d": Q.new(0)}}
	check_eq(TangentMeetsSituation.fq(c, -2).text(), "−2")
	check(TangentMeetsSituation.dfq(c, 1).is_zero())
	# 2e^(0.5x) − x² at x = 0: f = 2, f′ = 1.
	var e := {"fam": "exp", "f": {"A": Q.new(2), "k": Q.new(1, 2), "p": Q.new(-1), "q": Q.new(0)}}
	check(absf(TangentMeetsSituation.fv(e, 0.0) - 2.0) < 1e-12)
	check(absf(TangentMeetsSituation.dfv(e, 0.0) - 1.0) < 1e-12)


func test_the_line_is_the_tangent_or_the_normal() -> void:
	for ask in TangentMeetsSituation.FAMS:
		for i in 25:
			var s := _draw(ask, i)
			check(not s.is_empty(), "%s draw %d" % [ask, i])
			var m := TangentMeetsSituation.dfv(s, float(s.x0))
			var lm := TangentMeetsSituation.fl(s.lm)
			check(absf((lm - m) if s.line == "tangent" else (lm * m + 1.0)) < 1e-9, "%s %d: the gradient" % [ask, i])
			check(absf(_line_at(s, float(s.x0)) - TangentMeetsSituation.fv(s, float(s.x0))) < 1e-9, "%s %d: the line misses P" % [ask, i])


func test_intercepts_are_on_their_axes_and_q_on_both() -> void:
	for ask in ["tangent-x-intercept", "normal-y-intercept", "tangent-triangle-area"]:
		for i in 25:
			var s := _draw(ask, i)
			check(absf(_line_at(s, TangentMeetsSituation.fl(s.xa))) < 1e-9, "%s %d: A is not on the x-axis" % [ask, i])
			check(absf(_line_at(s, 0.0) - TangentMeetsSituation.fl(s.yb)) < 1e-9, "%s %d: B" % [ask, i])
	for ask in ["tangent-meets-again", "tangent-meets-again-gdc", "normal-meets-again"]:
		for i in 25:
			var s := _draw(ask, i)
			var x := TangentMeetsSituation.fl(s.qx)
			check(absf(TangentMeetsSituation.fv(s, x) - _line_at(s, x)) < 1e-6, "%s %d: Q is off the line" % [ask, i])
			check(absf(TangentMeetsSituation.fl(s.qy) - TangentMeetsSituation.fv(s, x)) < 1e-6, "%s %d: Q is off the curve" % [ask, i])
			check(absf(x - s.x0) >= TangentMeetsSituation.GAP, "%s %d: Q is P" % [ask, i])


func test_a_built_cubic_has_the_double_root() -> void:
	for i in 40:
		var s := _draw("tangent-meets-again", i)
		var x0: int = s.x0
		# Curve minus tangent and its gradient are both 0 at P.
		var g := TangentMeetsSituation.fq(s, x0).sub(s.lm.mul(x0).add(s.lc))
		check(g.is_zero(), "draw %d: P" % i)
		check(TangentMeetsSituation.dfq(s, x0).eq(s.lm), "draw %d: not a double root" % i)
		check(s.qx.is_int(), "draw %d: Q is not whole" % i)


func test_the_figure_is_the_curve_and_the_line() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(c): return c.rep != "equation"):
		var q := _make(c, 2)
		check_eq(q.graph.curves.size(), 2, c.key)
		check_eq(q.graph.points[0].label, "P", c.key)
		check_eq(q.graph.points.size() > 1, c.rep == "diagram", c.key + ": only the diagram letters its points")
		check_eq(q.graph.get("y_bare", false), c.rep == "diagram", c.key)
		check_eq(q.graph.has("shade"), c.unknown.ends_with("area"), c.key)


func test_every_tag_shows_up_as_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 10):
			var q := _make(c, seed)
			for o in q.choices:
				if o.ref != "":
					seen[o.ref] = true
	for m in t.misconceptions:
		check(seen.has(m.ref), "%s never shows" % m.ref)
