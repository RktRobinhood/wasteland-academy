extends "res://tests/test_case.gd"
## The complex-polar and conjugate-roots situations (FAL-1005): t1-ahl-complex-polar (AHL1.13) and
## t1-ahl-conjugate-roots (AHL1.14) are built with every cell for their skills, on AA HL only.
## Every cell makes four options with one right in both formats, every misconception comes up as
## an option, an Argand diagram names its axes Re and Im and keeps its points on it, and the exact
## arithmetic matches hand values. The SymPy checker (tools/check-answers) checks the maths.

const POLAR := "t1-ahl-complex-polar"
const CONJ := "t1-ahl-conjugate-roots"
const S := preload("res://engine/situations/complex_polar.gd")
const V := preload("res://engine/situations/complex_polar_views.gd")


func _make(t: String, c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": t, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_both_types_are_built_with_every_cell_on_aa_hl_only() -> void:
	for t in [POLAR, CONJ]:
		check(t in QuestionEngine.built_types(), "%s is not built" % t)
		var all := QuestionEngine.cells(false, [t]).size()
		check_eq(QuestionEngine.cells(false, [t], "aa-hl").size(), all, t)
		for course in ["aa-sl", "ai-sl", "ai-hl"]:
			check(QuestionEngine.cells(false, [t], course).is_empty(), "%s has %s" % [course, t])
	check_eq(QuestionEngine.cells(false, [POLAR]).size(), 20)
	check_eq(QuestionEngine.cells(false, [CONJ]).size(), 12)
	var skills := {}
	for t in [POLAR, CONJ]:
		for u in QuestionEngine.type_of(t).unknowns:
			for sk in u.skills:
				skills[sk] = true
	check_eq(skills.size(), 7, "the five AHL1.13 skills and two of AHL1.14")


func test_every_cell_makes_four_options_with_one_right() -> void:
	for t in [POLAR, CONJ]:
		check(QuestionEngine.extra_formats(t, "to-polar" if t == POLAR else "real-root", "any").is_empty(), "an exam type offers no extra format")
		for c in QuestionEngine.cells(false, [t]):
			for f in ["value", "mcq"]:
				for seed in range(1, 6):
					var q := _make(t, c, seed, f)
					check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
					if q.has("error"):
						break
					check_eq(q.paper, 2 if c.angle.begins_with("gdc-") else 1, c.key)
					check_eq(q.choices.size(), 4, c.key)
					check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
					check(q.solutions[-1].steps[-1].contains(q.answer_text), "%s: the last step says the answer" % c.key)


func test_every_distractor_shows_up() -> void:
	for t in [POLAR, CONJ]:
		var seen := {}
		for c in QuestionEngine.cells(false, [t]):
			for seed in range(1, 41):
				for o in _make(t, c, seed).choices:
					if o.ref != "":
						seen[o.ref] = true
		var ms: Array = QuestionEngine.type_of(t).misconceptions
		for i in ms.size():
			var ref: String = ms[i].get("ref", "%s#%d" % [t, i])
			check(seen.has(ref), "%s never comes up on %s" % [ref, t])


func test_an_argand_diagram_names_its_axes_and_keeps_its_points_on_it() -> void:
	for c in QuestionEngine.cells(false, [POLAR]).filter(func(c): return c.rep == "graph"):
		for seed in range(1, 11):
			var g: Dictionary = _make(POLAR, c, seed).graph
			check_eq([g.x_name, g.y_name], ["Re", "Im"], c.key)
			for p in g.points:
				check(p.x > g.x0 and p.x < g.x1 and p.y > g.y0 and p.y < g.y1, "%s: %s is off the diagram" % [c.key, p.label])


func test_hand_values() -> void:
	# 4 cis(5π/6) = −2√3 + 2i, and 3√2 cis(−3π/4) = −3 − 3i.
	check_eq(S.ctext(S.cart(S.sd(4), Q.new(5, 6))), "−2√3 + 2i")
	check_eq(S.ctext(S.cart(S.sd(3, 2), Q.new(-3, 4))), "−3 − 3i")
	check_eq(S.ptext(S.sd(1, 2), Q.new(-1, 4), "euler"), "√2 e^(−πi/4)")
	check_eq(S.ptext(S.sd(4), Q.new(1), "cis"), "4 cis(π)")
	check_eq(S.principal(Q.new(5, 4)).text(), "−3/4")
	check_eq(S.principal(Q.new(-1)).text(), "1")
	# (√2/2 − √2/2 i)(1 + i) is √2, real: a quarter turn clockwise of 1 + i, then 1 + i = √2 cis(π/4).
	check_eq(V.cmul(S.cx(2, 1), S.cx(1, -3)).map(func(p): return S.stext(p)), ["5", "−5"])
	# e^(2πi/3) + e^(πi/3) = √3 e^(πi/2), and 2 cos(π/6) = √3.
	check_eq(S.stext(V.two_cos_half(Q.new(1, 3))), "√3")
	check_eq(V.trig_term(-6, "sin", 2, "x", true), "−6i sin 2x")
	check_eq(V.trig_term(2, "cos", 1, "θ", false), "2 cos θ")
