extends "res://tests/test_case.gd"
## The area-between situation (FAL-751): t5-area-between-curves is built with every catalogue
## cell, every cell makes four different options, a GDC method and a curve that needs one are
## Paper 2 and the rest Paper 1, a figure shades the region between its two curves, and the exact
## pieces match hand values. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t5-area-between-curves"
const CELLS := 50
const REF := "SL5.11.area-between-curves#"


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var methods := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		methods[c.angle] = true
	for m in ["top-minus-bottom", "split-at-crossings", "gdc-abs-difference", "difference-of-areas"]:
		check(methods.has(m), m + " is not a method of any cell")


func test_every_cell_makes_a_question_with_four_different_options() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in range(1, 6):
				var q := _make(c.unknown, c.rep, c.angle, seed, f)
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s: two options read the same" % c.key)


func test_the_papers_follow_the_curves() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var want := [2] if c.angle.begins_with("gdc-") or c.unknown in AreaBetweenViews.P2_ONLY else [1]
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), want, c.key)


func test_a_figure_shades_the_region_between_two_curves() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.rep == "equation":
			continue
		for seed in range(1, 4):
			var q := _make(c.unknown, c.rep, c.angle, seed)
			check(q.graph != null and not q.graph.shade.is_empty(), c.key + " has no shaded region")
			if c.unknown != "derivative-areas":
				check(q.graph.curves.size() >= 2, c.key + " shows one curve")
			for region in q.graph.shade:
				check(region.size() >= 3, c.key)
				for st in region:
					check(st[1] <= st[2], c.key + ": a strip is upside down")


func test_a_figure_with_no_equations_marks_what_fixes_them() -> void:
	for seed in range(1, 12):
		var q := _make("area-line-curve", "diagram", "top-minus-bottom", seed)
		check(not " ".join(q.lines).contains("="), "the diagram's stem gives an equation")
		var marked: Array = q.graph.points.filter(func(p): return p.label.begins_with("("))
		check(marked.size() >= 3, "a parabola needs three marked points")


func test_each_method_is_shown_first_on_its_own_cell() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var q := _make(c.unknown, c.rep, c.angle, 2)
		check_eq(q.solutions[0].angle, c.angle, c.key)


func test_the_named_slips_show_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 13):
			for o in _make(c.unknown, c.rep, c.angle, seed).choices:
				seen[o.ref] = true
	for i in 15:
		check(seen.has(REF + str(i)), "no option shows %s%d" % [REF, i])


func test_the_exact_pieces_against_hand_values() -> void:
	# (−x² + 4x) from 0 to 4 is 32/3, and x² − 1 minus 2x − 1 is x² − 2x.
	check_eq(AreaBetweenSituation.integ([-1, 4, 0], 0, 4).text(), "32/3")
	check_eq(AreaBetweenSituation.minus([1, 0, -1], [2, -1]).map(func(c): return c.text()), ["1", "−2", "0"])
	# (x − 1)(x − 2)(x − 3)
	check_eq(AreaBetweenSituation.cubic(1, 1, 2, 3), [1, -6, 11, -6])


func test_simpson_against_a_hand_value() -> void:
	var f := func(x: float) -> float: return 2.0 * x
	var g := func(_x: float) -> float: return 0.0
	check(absf(AreaBetweenSituation.between(f, g, 0.0, 3.0) - 9.0) < 1e-9, "∫ 2x from 0 to 3")


func test_a_curve_writes_as_the_checker_reads_it() -> void:
	check_eq(AreaBetweenSituation.text({"k": "exp", "A": Q.new(2), "w": Q.new(-1, 2), "c": Q.new(0)}), "2e^(−0.5x)")
	check_eq(AreaBetweenSituation.text({"k": "sin", "A": Q.new(3), "w": Q.new(1), "c": Q.new(1)}), "3 sin x + 1")
	check_eq(AreaBetweenSituation.text({"k": "unroot", "a": 5, "b": -3}), "(x² + 3)/5")
	check_eq(AreaBetweenSituation.text({"k": "rat", "a": 3, "b": 2, "c": 4}), "(3x + 2)/(x + 4)")


func test_a_wrong_area_keeps_its_minus_sign() -> void:
	var q := _make("area-line-curve", "equation", "top-minus-bottom", 3)
	check(q.choices.any(func(o): return o.ref == REF + "0" and o.text.begins_with("Area = −")), "no negative area")
