extends "res://tests/test_case.gd"
## The sample-space situation (FAL-752): t4-sample-space is built with every cell, every cell makes
## four options with one right, the grid and the figures are what the question says and fit a phone,
## symmetry cells have matching objects, Paper 1 is exact, and every misconception shows up. The
## SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t4-sample-space"
const CELLS := 76
## The narrowest card on a 390 × 844 phone, in the game's 1080-wide viewport: the fight's framed one.
const CARD := 900.0


func _make(c: Dictionary, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var view := {"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "not built")
	var cs := QuestionEngine.cells(false, [TYPE])
	check_eq(cs.size(), CELLS, "cells")
	var angles := {}
	var reps := {}
	for c in cs:
		angles[c.angle] = true
		reps[c.rep] = true
	check_eq(angles.size(), 3, "all three methods have cells")
	check_eq(reps.size(), 3, "all three representations have cells")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "sample-space", c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check(q.solutions[0].angle == c.angle, c.key)
				check(q.solutions.size() == QuestionEngine.angles_for(QuestionEngine.type_of(TYPE), c.unknown).size(), c.key + ": a method has no working")


func test_the_exam_parts_are_paper_1_but_for_the_grid_questions() -> void:
	var type := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var want: Array = [1, 2] if c.unknown in SampleSpaceViews.BOTH_PAPERS else [1]
		check_eq(QuestionEngine.cell_papers(type, c.unknown, c.rep, c.angle), want, c.key)


func test_paper_1_is_exact_and_paper_2_is_three_figures() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in [1, 2]:
			var one := _make(c, seed, "mcq", 1)
			check(one.answer.get("exact", false), c.key + ": a Paper 1 answer is exact")
			if c.unknown in SampleSpaceViews.BOTH_PAPERS:
				var two := _make(c, seed, "mcq", 2)
				check_eq(two.answer.get("show", ""), "sf", c.key)
				check(Answer.needs_rounding(two.answer.values.v), c.key + ": Paper 2 needs rounding")


func test_a_symmetry_cell_has_matching_objects() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.unknown in ["p-mirror-score", "p-mirror-at-least", "p-rule-points"]:
			for seed in range(1, 10):
				var s: Dictionary = _make(c, seed).given
				check_eq(s.xs, s.ys, c.key)
				check_eq(s.xs, range(1, s.xs.size() + 1), c.key)
				if c.unknown != "p-rule-points":
					check(s.k > s.xs.size() + 1, c.key + ": the sum is above the middle")


func test_another_way_keeps_the_numbers() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		for other in QuestionEngine.angles_for(t, c.unknown):
			var q := QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": other, "same_angle": c.angle, "seed": 4, "format": "mcq"})
			check(not q.has("error"), c.key)
			check_eq(q.solutions[0].angle, other, c.key)


func test_a_table_question_shows_a_grid_with_heads_that_fits_a_phone() -> void:
	var practice: Control = load("res://ui/practice.gd").new()
	# In the tree with the game's theme, so the cells are measured at the game's font.
	var holder := Control.new()
	holder.theme = UiTheme.make()
	(Engine.get_main_loop() as SceneTree).root.add_child(holder)
	var widest := 0.0
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.rep != "table":
			continue
		for seed in range(1, 8):
			var q := _make(c, seed)
			check(q.table != null, c.key + ": no table")
			if q.table == null:
				continue
			var wrap: Control = practice._table(q.table)
			holder.add_child(wrap)
			var w: float = wrap.get_child(0).get_combined_minimum_size().x
			widest = maxf(widest, w)
			check(w <= CARD, "%s: %d wide" % [c.key, w])
			wrap.free()
	holder.free()
	practice.free()
	print("widest table: ", widest)
	check(widest > 300.0, "the cells were measured at the game's font")


func test_a_figure_shows_the_faces() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.rep != "diagram":
			continue
		for seed in [1, 2, 3]:
			var q := _make(c, seed)
			check_eq(q.graph.kind, "spinners", c.key)
			for it in q.graph.items:
				check_eq(it.labels.size(), it.shares.size(), c.key)
				var total := 0.0
				for v in it.shares:
					total += v
				check(absf(total - 1.0) < 1e-9, c.key + ": the sectors make a circle")


func test_every_misconception_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 30):
			for o in _make(c, seed).choices:
				seen[o.ref] = true
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), ref + " never appears")
