extends "res://tests/test_case.gd"
## The complex-number situation (FAL-1004): t1-ahl-complex-cartesian is built with every cell for
## the five AHL1.12 skills, on AA HL only, and t1-ai-complex-cartesian with every cell for the six
## AI-AHL1.12 skills, on AI HL only and Paper 2 throughout. Every cell makes four options with one
## right, every slip shows up, an Argand diagram names its axes Re and Im and keeps its points on
## it, and the arithmetic matches hand values. The SymPy checker (tools/check-answers) checks the maths.

const AA_TYPE := "t1-ahl-complex-cartesian"
const AI_TYPE := "t1-ai-complex-cartesian"
const S := preload("res://engine/situations/complex_number.gd")
const V := preload("res://engine/situations/complex_number_views.gd")


func _make(t: String, c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": t, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_both_types_are_built_with_every_cell_on_their_own_course() -> void:
	for t in [AA_TYPE, AI_TYPE]:
		check(t in QuestionEngine.built_types(), "%s is not built" % t)
		var all := QuestionEngine.cells(false, [t]).size()
		var home := "aa-hl" if t == AA_TYPE else "ai-hl"
		check_eq(QuestionEngine.cells(false, [t], home).size(), all, home)
		for course in ["aa-sl", "aa-hl", "ai-sl", "ai-hl"]:
			if course != home:
				check(QuestionEngine.cells(false, [t], course).is_empty(), "%s has %s" % [course, t])
	check_eq(QuestionEngine.cells(false, [AA_TYPE]).size(), 31)
	check_eq(QuestionEngine.cells(false, [AI_TYPE]).size(), 32)
	var skills := {}
	for t in [AA_TYPE, AI_TYPE]:
		for u in QuestionEngine.type_of(t).unknowns:
			for sk in u.skills:
				skills[sk] = true
	check_eq(skills.size(), 11, "the five AHL1.12 skills and the six AI-AHL1.12 ones")


func test_every_cell_makes_four_options_with_one_right() -> void:
	for t in [AA_TYPE, AI_TYPE]:
		check(QuestionEngine.extra_formats(t, "product", "expand-brackets").is_empty(), "an exam type offers no extra format")
		for c in QuestionEngine.cells(false, [t]):
			for f in ["value", "mcq"]:
				for seed in range(1, 6):
					var q := _make(t, c, seed, f)
					check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
					if q.has("error"):
						break
					if t == AI_TYPE:
						check_eq(q.paper, 2, c.key + ": every AI paper allows a GDC")
					elif c.unknown == "power-of-i":
						check_eq(q.paper, 1, c.key)
					check_eq(q.choices.size(), 4, c.key)
					check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
					check(q.solutions[-1].steps[-1].contains(q.answer_text), "%s: the last step says the answer" % c.key)


func test_every_distractor_shows_up() -> void:
	for t in [AA_TYPE, AI_TYPE]:
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
	for t in [AA_TYPE, AI_TYPE]:
		for c in QuestionEngine.cells(false, [t]).filter(func(c): return c.rep == "graph" and c.unknown != "quadratic-roots"):
			for seed in range(1, 11):
				var g: Dictionary = _make(t, c, seed).graph
				check_eq([g.x_name, g.y_name], ["Re", "Im"], c.key)
				for p in g.points:
					check(p.x > g.x0 and p.x < g.x1 and p.y > g.y0 and p.y < g.y1, "%s: %s is off the diagram" % [c.key, p.label])
	# The parabola for a quadratic with complex roots sits above the x-axis, vertex marked.
	for seed in range(1, 11):
		var q := _make(AI_TYPE, {"unknown": "quadratic-roots", "rep": "graph", "angle": "complete-square"}, seed)
		check(q.graph.k > 0.0 and q.graph.points.size() == 1, "the vertex is above the axis")


func test_hand_values() -> void:
	var z := S.c(3, -2)
	var w := S.c(1, 4)
	check_eq(S.text(S.mul(z, w)), "11 + 10i")
	check_eq(S.text(S.mul_plus(z, w)), "−5 + 10i")
	check_eq(S.text(S.div(S.c(-10, 11), S.c(-3, 2))), "4 − i")
	check_eq(S.text(S.power(S.c(2, -1), 4)), "−7 − 24i")
	check_eq(S.text(S.power(S.c(1, 1), 8)), "16")
	check_eq(S.text(S.times_i(S.c(2, 3))), "−3 + 2i")
	check_eq(S.text(S.c(Q.new(3, 5), Q.new(-4, 5))), "3/5 − (4/5)i")
	check_eq(S.text(S.c(0, -1)), "−i")
	check_eq(S.norm(S.c(-3, 4)).text(), "25")
	check(absf(S.arg(S.c(-1, 1)) - 3.0 * PI / 4.0) < 1e-12, "arg(−1 + i) = 3π/4")
	# The Paper 1 points: −1 + √3 i is on the 60° line in the second quadrant.
	check_eq(V.special_text(V.special_parts([Q.new(1, 3), 2, 1])), "−1 + √3 i")
	check_eq(V.special_arg(Q.new(1, 3), 2).text(), "2/3")
	check_eq(V.special_arg(Q.new(1, 6), 3).text(), "−5/6")
	# 3z − 4iz* = 25 − 24i has z = 3 − 4i.
	var s := {"mode": "iconj", "alpha": 3, "beta": -4}
	check_eq(S.text(S.lhs(s, S.c(3, -4))), "25 − 24i")
