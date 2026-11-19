extends "res://tests/test_case.gd"
## The complex-polar recipe's four types (FAL-1005): t1-ahl-complex-polar (AHL1.13),
## t1-ahl-de-moivre and t1-ahl-conjugate-roots (AHL1.14) on AA HL only, and t1-ai-complex-polar
## (AI-AHL1.13) on AI HL only, each built with every cell for its skills. Every cell makes four
## options with one right in both formats, on the paper its course sets; every misconception
## comes up as an option; an Argand diagram names its axes Re and Im and keeps its points on it;
## and the exact arithmetic matches hand values. The SymPy checker (tools/check-answers) checks
## the maths.

const POLAR := "t1-ahl-complex-polar"
const DM := "t1-ahl-de-moivre"
const CONJ := "t1-ahl-conjugate-roots"
const AI := "t1-ai-complex-polar"
const TYPES := [POLAR, DM, CONJ, AI]
const S := preload("res://engine/situations/complex_polar.gd")
const V := preload("res://engine/situations/complex_polar_views.gd")
const DV := preload("res://engine/situations/de_moivre_views.gd")


func _make(t: String, c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": t, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_every_type_is_built_with_every_cell_on_its_own_course() -> void:
	var courses := {POLAR: "aa-hl", DM: "aa-hl", CONJ: "aa-hl", AI: "ai-hl"}
	for t in TYPES:
		check(t in QuestionEngine.built_types(), "%s is not built" % t)
		var all := QuestionEngine.cells(false, [t]).size()
		check_eq(QuestionEngine.cells(false, [t], courses[t]).size(), all, t)
		for course in ["aa-sl", "ai-sl", "aa-hl", "ai-hl"]:
			if course != courses[t]:
				check(QuestionEngine.cells(false, [t], course).is_empty(), "%s has %s" % [course, t])
	check_eq(QuestionEngine.cells(false, [POLAR]).size(), 20)
	check_eq(QuestionEngine.cells(false, [DM]).size(), 20)
	check_eq(QuestionEngine.cells(false, [CONJ]).size(), 12)
	check_eq(QuestionEngine.cells(false, [AI]).size(), 24)
	for pair in [[[POLAR, DM, CONJ], 11, "the five AHL1.13 skills and the six of AHL1.14"], [[AI], 5, "the five AI-AHL1.13 skills"]]:
		var skills := {}
		for t in pair[0]:
			for u in QuestionEngine.type_of(t).unknowns:
				for sk in u.skills:
					skills[sk] = true
		check_eq(skills.size(), pair[1], pair[2])


func test_every_cell_makes_four_options_with_one_right() -> void:
	for t in TYPES:
		var first: String = QuestionEngine.type_of(t).unknowns[0].id
		check(QuestionEngine.extra_formats(t, first, "any").is_empty(), "an exam type offers no extra format")
		for c in QuestionEngine.cells(false, [t]):
			for f in ["value", "mcq"]:
				for seed in range(1, 6):
					var q := _make(t, c, seed, f)
					check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
					if q.has("error"):
						break
					# Every AI paper allows a GDC, and a GDC method is Paper 2. On AA HL every cell makes
					# both papers but De Moivre's identities and proof, which are Paper 1.
					if t == AI or c.angle.begins_with("gdc-"):
						check_eq(q.paper, 2, c.key)
					elif t != DM or c.unknown in DV.DM_BOTH_PAPERS:
						check(q.paper in [1, 2], c.key)
					else:
						check_eq(q.paper, 1, c.key)
					check_eq(q.choices.size(), 4, c.key)
					check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
					check(q.solutions[-1].steps[-1].contains(q.answer_text), "%s: the last step says the answer" % c.key)


func test_every_distractor_shows_up() -> void:
	for t in TYPES:
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
	for t in [POLAR, AI]:
		for c in QuestionEngine.cells(false, [t]).filter(func(c): return c.rep == "graph"):
			for seed in range(1, 11):
				var g: Dictionary = _make(t, c, seed).graph
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
	# De Moivre: cos 3θ = 4cos³θ − 3cos θ, sin 3θ = 3sin θ − 4sin³θ, and cos³θ = (cos 3θ + 3cos θ)/4.
	check_eq(DV.ma_poly("cos", 3), [0, -3, 0, 4])
	check_eq(DV.ma_poly("sin", 3), [0, 3, 0, -4])
	check_eq(DV.pr_text(DV.pr_terms("cos", 3), "θ"), "(cos 3θ + 3cos θ)/4")
	check_eq(DV.pr_text(DV.pr_terms("sin", 3), "θ"), "(3sin θ − sin 3θ)/4")
	# (cis(3π/4))² = cis(3π/2) is purely imaginary; cis(5π/6) needs n = 6 to be real, 12 to be positive.
	check_eq(S.least_n(Q.new(3, 4), "imaginary"), 2)
	check_eq(S.least_n(Q.new(5, 6), "real"), 6)
	check_eq(S.least_n(Q.new(5, 6), "positive"), 12)
