extends "res://tests/test_case.gd"
## The gradient-from-graph situation (FAL-777): t5-ext-gradient-from-graph is built with every
## cell. The tangent at P runs through grid points two units either side of P; the height of P
## and the line from the origin give other gradients; the chord's estimate is m + 0.01c; every
## tag shows up on each unknown it names. The SymPy checker (tools/check-answers) works every
## gradient out again.

const TYPE := "t5-ext-gradient-from-graph"
const CELLS := 6
const S := preload("res://engine/situations/gradient_from_graph.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)


func test_every_cell_and_format_makes_a_question() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var fmts: Array = ["mcq"] + QuestionEngine.extra_formats(TYPE, c.unknown, c.angle)
		check_eq(fmts, ["mcq"] if c.unknown == "pick-tangent" else ["mcq", "true-false-reason"], c.key)
		for f in fmts:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.paper, 2 if c.unknown == "gdc-gradient" else 1, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				if c.unknown == "pick-tangent":
					check_eq(q.format, "pick-the-graph", c.key)
					check_eq(q.graphs.size(), 4, c.key)
				if c.rep == "graph":
					check(q.graph != null, "%s: no figure" % c.key)


func test_the_tangent_meets_the_curve_with_gradient_m() -> void:
	for i in 40:
		var s := S.generate(Seeded.new("t|%d" % i), {"ask": "tangent-drawn"})
		check(S.slope(s, s.a).eq(Q.new(s.m)), "draw %d" % i)
		check(S.value(s, s.a).eq(Q.new(s.y0)), "draw %d" % i)
		check(s.y0 != s.m and not Q.new(s.y0, s.a).eq(Q.new(s.m)), "draw %d: a slip gives the answer" % i)
	# f(x) = (x − 2)³/4 + 3(x − 2) + 1: f′(2) = 3, and the chord over 2 ± 0.1 has gradient 3.0025.
	var s := {"deg": 3, "c": Q.new(1, 4), "a": 2, "y0": 1, "m": 3}
	check(S.slope(s, 2).eq(Q.new(3)))
	check(S.value(s, Q.new(21, 10)).sub(S.value(s, Q.new(19, 10))).div(Q.new(1, 5)).eq(Q.new(12010, 4000)))


func test_compare_two_puts_the_heights_the_other_way() -> void:
	var ways := {}
	for i in 60:
		var s := S.generate(Seeded.new("c|%d" % i), {"ask": "compare-two"})
		var ga := S.slope(s, s.xa)
		var gb := S.slope(s, s.xb)
		check(ga.lt(gb) != S.value(s, s.xa).lt(S.value(s, s.xb)), "draw %d" % i)
		ways[s.way] = true
	check_eq(ways.size(), 3, "mixed, up and down all come up")


func test_every_tag_shows_up_on_each_unknown_it_names() -> void:
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		for u in ms[i].in:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 40):
					if _make(c, seed).choices.any(func(o): return o.ref == ref):
						found = true
						break
				if found:
					break
			check(found, "%s never shows on %s" % [ref, u])
