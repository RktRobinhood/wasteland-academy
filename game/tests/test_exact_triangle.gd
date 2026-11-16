extends "res://tests/test_case.gd"
## The exact-triangle situation (FAL-778): t3-ext-exact-triangle is built with every cell, all on
## Paper 1, the areas, sides, cosines and heights are exact as their unknowns need, the height's
## sketch has its foot on AB with the right angle there, and every tag shows up. The SymPy checker
## (tools/check-answers) works every value out again from sin and cos of the angle.

const TYPE := "t3-ext-exact-triangle"
const CELLS := 14
const S := preload("res://engine/situations/exact_triangle.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell_on_paper_1() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [1], c.key)
		for f in ["value", "mcq"] + QuestionEngine.extra_formats(TYPE, c.unknown, c.angle):
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
				if not q.has("error"):
					check_eq(q.paper, 1, c.key)
					check_eq(q.diagram != null, c.rep == "diagram" and c.unknown != "exact-height", c.key)


func test_exact_values_by_hand() -> void:
	# √112 = 4√7, and ½ × 8 × 12 × sin 120° = 24√3.
	var e := S.simplify(112)
	check_eq([e[0].key(), e[1]], ["4", 7])
	check_eq(S.simplify(103)[1], 103)
	var s := S.generate(Seeded.new("side|1"), {"ask": "exact-side"})
	var c2: int = s.a * s.a + s.b * s.b + (s.a * s.b if s.C == 120 else -s.a * s.b)
	check_eq(s.c2, c2)
	check(not S.is_square(c2))


func test_the_height_lands_on_ab() -> void:
	for seed in range(1, 20):
		var q := QuestionEngine.make({"type": TYPE, "unknown": "exact-height", "rep": "diagram", "angle": "exact-substitution", "seed": seed})
		var p: Dictionary = q.graph.pts
		check(p.H[0] > 0.0 and p.H[0] < p.B[0] and is_equal_approx(p.H[0], p.C[0]), "seed %d" % seed)
		check_eq(q.graph.right, ["H"])


func test_every_tag_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 15):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
			for f in QuestionEngine.extra_formats(TYPE, c.unknown, c.angle):
				seen[_make(c, seed, f).spot.ref] = true
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		check(seen.has(ms[i].get("ref", "%s#%d" % [TYPE, i])), "%s never shows" % ms[i].get("ref", i))


func test_the_foot_of_the_perpendicular_is_placed_right() -> void:
	# #193: with C = 60°, CH = b/2 from C along CB. b > 2a puts H past B, b = 2a puts it at B.
	var v := ExactTriangleViews.new()
	for row in [[5, 4, "between B and C, so HB = 5 − 2 = 3"], [3, 10, "beyond B, so HB = 5 − 3 = 2"], [4, 8, "at B itself, so HB = 0"]]:
		var a: int = row[0]
		var b: int = row[1]
		var c2: int = a * a + b * b - a * b
		var s := {"a": a, "b": b, "C": 60, "c2": c2, "side": S.simplify(c2)}
		var steps: Array = v.u_exact_side("words", s, Seeded.new("foot")).methods["drop-perpendicular"].steps
		check(steps[1].contains(row[2]), "a = %d, b = %d: %s" % [a, b, steps[1]])
		check(not steps[1].contains("beyond C"), "a = %d, b = %d: H is not beyond C" % [a, b])
	# C = 120°: H is on BC extended past C.
	var s := {"a": 3, "b": 4, "C": 120, "c2": 37, "side": S.simplify(37)}
	check(v.u_exact_side("words", s, Seeded.new("foot")).methods["drop-perpendicular"].steps[1].contains("beyond C, so HB = 3 + 2 = 5"))
