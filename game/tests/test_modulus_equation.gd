extends "res://tests/test_case.gd"
## The modulus-equation situation (FAL-1008): fn-ahl-modulus-equations is built with every cell
## and both AHL2.16 modulus skills, only for AA HL; every question is Paper 2, as the exam's part
## is (a GDC method and |f(x)| against a line can only be); every cell makes four distinct options
## with one right and says its answer in each working's last step; graphs are shown; every tagged
## slip shows up; typed roots are marked in either order; roots, counts and solution sets against
## values worked by hand. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "fn-ahl-modulus-equations"
const CELLS := 24
const SKILLS := ["AHL2.16.modulus-equation", "AHL2.16.modulus-inequality"]
const S := preload("res://engine/situations/modulus_equation.gd")
const V := preload("res://engine/situations/modulus_equation_views.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS, TYPE)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	for s in SKILLS:
		check(skills.has(s), "no unknown tests %s" % s)


func test_only_aa_hl_gets_it() -> void:
	for course in ["aa-sl", "ai-sl", "ai-hl"]:
		check(QuestionEngine.cells(false, [TYPE], course).is_empty(), "%s offers %s" % [course, TYPE])
	check_eq(QuestionEngine.cells(false, [TYPE], "aa-hl").size(), CELLS, "%s on aa-hl" % TYPE)


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var only2: bool = c.angle.begins_with("gdc-") or c.unknown == "modulus-vs-curve"
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2] if only2 else [1, 2], c.key)
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in range(1, 7):
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "modulus-equation", c.key)
				# The exam's part is Paper 2, so every cell is asked there.
				check_eq(q.paper, 2, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check(q.solutions[0].angle == c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
					check(Step.texts(sol.steps)[-1].contains(q.answer_text), "%s: the last step doesn't say %s" % [c.key, q.answer_text])
				check((q.graph != null) == (c.rep == "graph"), c.key + ": a graph on the graph rep, and only there")


func test_same_seed_same_question_and_seeds_vary() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(_make(c, 7).prompt, _make(c, 7).prompt, c.key)
		var answers := {}
		for seed in range(1, 13):
			answers[_make(c, seed).answer_text] = true
		check(answers.size() > 3, "%s: only %d different answers in 12 seeds" % [c.key, answers.size()])


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 41):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	var ty := QuestionEngine.type_of(TYPE)
	var ms: Array = ty.misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never comes up" % ref)
	for ref in seen:
		check(QuestionEngine.misconception_text(ty, ref) != "", "%s has no text" % ref)


func test_the_four_solutions_part_shows_the_graph_of_the_modulus() -> void:
	# The exam's part reads the k for four solutions off y = |f(x)|: the graph rep draws it,
	# with the hump's top marked and no line for the unknown k.
	var found := false
	for seed in range(1, 60):
		var q := _make({"unknown": "count-solutions", "rep": "graph", "angle": "graph-intersections"}, seed)
		if not q.asked.contains("exactly four"):
			continue
		found = true
		check_eq(q.graph.curves.size(), 1, "seed %d: only |f(x)| is drawn" % seed)
		var s: Dictionary = q.situation
		check(q.graph.points.any(func(p): return absf(p.x - s.h) < 1e-9 and absf(p.y - s.dtop) < 1e-9), "seed %d: the top is marked" % seed)
		for pt in q.graph.curves[0]:
			check(pt[1] >= 0.0, "seed %d: |f(x)| below the axis at x = %s" % [seed, pt[0]])
		check_eq(q.answer_text, "0 < k < %d" % s.dtop, "seed %d" % seed)
	check(found, "no four-solutions question in 60 seeds")


func test_typed_roots_are_marked_in_either_order() -> void:
	var c := {"unknown": "modulus-equals-modulus", "rep": "equation", "angle": "split-into-cases"}
	for seed in range(1, 6):
		var q := _make(c, seed, "value")
		var v: Dictionary = q.answer.values
		var a := Fmt.num(Q.of(v.x0))
		var b := Fmt.num(Q.of(v.x1))
		check(QuestionEngine.mark(q, {"x0": a, "x1": b}).correct, q.answer_text)
		check(QuestionEngine.mark(q, {"x0": b, "x1": a}).correct, q.answer_text + " the other way round")
		check(not QuestionEngine.mark(q, {"x0": a, "x1": Fmt.num(Q.of(v.x1).neg())}).correct, "a root's sign changed")


func test_roots_by_hand() -> void:
	# |x − 3| = 5: x = −2 or 8.
	var sh := S.generate(Seeded.new("modeq|shift"), {"kind": "shift"})
	check(sh.roots[0].eq(Q.new(sh.a - sh.k)) and sh.roots[1].eq(Q.new(sh.a + sh.k)), "a − k and a + k")
	# |x + 4| = |3x − 2|: x + 4 = 3x − 2 gives 3, x + 4 = −(3x − 2) gives −1/2.
	check_eq(V.squared(1, 4, 3, -2), ["8x² − 20x − 12 = 0, that is 2x² − 5x − 3 = 0", "x − 3", "2x + 1"])
	# |x − 5| = 3x − 7: 1 makes the line −4, so only x = 3.
	for i in 200:
		var s := S.generate(Seeded.new("modeq|ml|%d" % i), {"kind": "ml"})
		var at_good: Q = s.good.mul(s.m).add(s.c)
		var at_bad: Q = s.bad.mul(s.m).add(s.c)
		check(at_good.sign() > 0 and at_bad.sign() < 0, "draw %d: one root makes the line negative" % i)
		check(Q.new(s.a).mul(s.good).add(s.b).abs_q().eq(at_good), "draw %d: |ax + b| = mx + c at the good root" % i)
	check_eq(V.solve_lin(1, 5), "gives x = 5")
	check_eq(V.solve_lin(-2, -6), "gives −2x = −6, so x = 3")


func test_counts_by_hand() -> void:
	# f(x) = (x + 1)(x − 3): the hump's top is (1, 4).
	var s := {"A": 1, "p": -1, "q": 3, "h": 1, "dtop": 4}
	check_eq(V.f_text(s), "x² − 2x − 3")
	# f(x) = k meets twice above −4, once at it and never below; |f(x)| = 2 has four.
	check_eq(V.f_meets(s, 2), 2)
	check_eq(V.f_meets(s, -4), 1)
	check_eq(V.f_meets(s, -5), 0)
	var down := {"A": -1, "p": 2, "q": 6, "h": 4, "dtop": 4}
	check_eq(V.f_text(down), "−x² + 8x − 12")
	check_eq(V.f_meets(down, 2), 2)
	check_eq(V.f_meets(down, 4), 1)
	check_eq(V.f_meets(down, 5), 0)


func test_sets_by_hand() -> void:
	check_eq(S.set_text(S.between(Q.new(-4, 3), Q.new(2, 3), false)), "−4/3 < x < 2/3")
	check_eq(S.set_text(S.outside(Q.new(-5), Q.new(11), true)), "x ≤ −5 or x ≥ 11")
	var d0 := {"v": 0.0, "t": "0"}
	var d1 := {"v": TAU, "t": "2π"}
	var piece := [{"lo": d0, "hi": S.cross_end(3.43039), "lo_in": true, "hi_in": false}]
	check_eq(S.set_text(piece), "0 ≤ x < 3.43")
	check_eq(S.set_text(S.complement(piece, d0, d1)), "3.43 ≤ x ≤ 2π")
	# |x² − 4| < 3 for −0.5 ≤ x ≤ 4: the crossings at 1 and √7, the set between them.
	var q := {"fam": "quad", "B": 0, "C": -4, "m": Q.new(0), "c": 3, "rel": "<"}
	var xs := S.crossings(q, -0.5, 4.0)
	check_eq(xs.size(), 2, "two crossings")
	if xs.size() == 2:
		check(absf(xs[0] - 1.0) < 1e-9 and absf(xs[1] - sqrt(7.0)) < 1e-9, "1 and √7: %s" % [xs])
		var set := S.solve_on(q, -0.5, 4.0, xs, {"v": -0.5, "t": "−0.5"}, {"v": 4.0, "t": "4"})
		check_eq(S.set_text(set), "1.00 < x < 2.65")
