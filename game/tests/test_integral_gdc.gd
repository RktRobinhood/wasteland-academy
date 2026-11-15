extends "res://tests/test_case.gd"
## The integral-gdc situation (FAL-776): t5-ext-integral-gdc is built with every cell, on Paper 2.
## The values are Simpson's rule to 9 decimals, each slip gives a different 3 s.f. value, the graph
## shades the region of the integral, and every tag shows up. The SymPy checker
## (tools/check-answers) integrates every question again with mpmath.

const TYPE := "t5-ext-integral-gdc"
const CELLS := 7
const S := preload("res://engine/situations/integral_gdc.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell_on_paper_2() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2], c.key)
		for f in ["value", "mcq"] + QuestionEngine.extra_formats(TYPE, c.unknown, c.angle):
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.paper, 2, c.key)
				check_eq(q.graph != null, c.rep == "graph", c.key)


func test_the_values_match_hand_values() -> void:
	# ∫ from 0 to 1 of e^(x + 1) dx = e² − e = 4.67077.
	var s := {"fam": "eshift", "c": 1, "a": 0, "b": 1}
	check(absf(DefiniteIntegralSituation.simpson(S.f(s), 0.0, 1.0) - (exp(2.0) - exp(1.0))) < 1e-9)
	# With the bracket closed too soon: ∫ from 0 to 1 of (e^x + 1) dx = e.
	check(absf(DefiniteIntegralSituation.simpson(S.slipped(s), 0.0, 1.0) - exp(1.0)) < 1e-9)
	# In degree mode sin x is sin(πx/180): ∫ from 0 to 1 of sin(x²) dx then is about π/540.
	var t := {"fam": "sinx2", "c": 1, "a": 0, "b": 1}
	check(absf(DefiniteIntegralSituation.simpson(S.f(t, true), 0.0, 1.0) - PI / 540.0) < 1e-6)


func test_each_slip_gives_its_own_value() -> void:
	for i in 60:
		var s := S.generate(Seeded.new("value|%d" % i), {"ask": "gdc-value"})
		var other: float = s.deg if s.fam in S.TRIG else s.slip
		check(Fmt.sf(s.v) != Fmt.sf(other) and Fmt.sf(s.v) != Fmt.sf(-s.v), "draw %d" % i)


func test_every_tag_shows_up_as_an_option() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 15):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	for m in QuestionEngine.type_of(TYPE).misconceptions:
		if m.as == "distractor":
			check(seen.has(m.ref), "%s never shows" % m.ref)


func test_the_graph_shades_the_integral() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.rep == "graph"):
		for seed in range(1, 6):
			var q := _make(c, seed)
			var sh: Array = q.graph.shade[0]
			check_eq([sh[0][0], sh[-1][0]], [float(q.situation.a), float(q.situation.b)], c.key)
