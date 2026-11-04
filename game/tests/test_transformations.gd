extends "res://tests/test_case.gd"
## The Transformations region (FAL-424): its exam types and extension types are built with
## every catalogue cell, the distractor misconceptions show up as options, a chain's map
## is the moves walked in order, and the four graphs of a pick differ. The SymPy checker
## (tools/check-answers) checks the maths.

const TC := preload("res://engine/situations/transform_chain.gd")
## Cells per type (the catalogue's own count, every unknown × rep × method).
const CELLS := {"fn-transform-describe": 37, "fn-transform-apply": 47, "fn-concept-transform-order": 15}
const SITUATIONS := {"fn-transform-describe": "transform-chain", "fn-transform-apply": "transform-chain", "fn-concept-transform-order": "transform-chain"}


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func test_the_types_are_built_with_every_cell() -> void:
	var built := QuestionEngine.built_types()
	for t in CELLS:
		check(t in built, "%s is not built" % t)
		check_eq(QuestionEngine.cells(false, [t]).size(), CELLS[t], t)


func test_every_cell_makes_a_question_on_its_situation() -> void:
	for t in CELLS:
		for c in QuestionEngine.cells(false, [t]):
			for seed in [1, 2, 3, 4]:
				var q := _make(t, c.unknown, c.rep, c.angle, seed)
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, SITUATIONS[t], c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.solutions[0].angle, c.angle, c.key + ": the asked method comes first")
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
					check(q.answer_text in Step.text(sol.steps[sol.steps.size() - 1]), "%s: the last step doesn't state the answer" % c.key)
				if c.rep == "graph":
					check(q.graph != null or q.format == "pick-the-graph", c.key + ": no graph")
				if c.rep == "table":
					check(q.table != null, c.key + ": no table")


func test_exam_types_offer_no_extra_format() -> void:
	for t in CELLS:
		if QuestionEngine.type_of(t).source != "exam":
			continue
		for c in QuestionEngine.cells(false, [t]):
			check(QuestionEngine.extra_formats(t, c.unknown, c.angle).is_empty(), c.key)


func test_every_distractor_misconception_is_an_option() -> void:
	for t in CELLS:
		var ty := QuestionEngine.type_of(t)
		for i in ty.misconceptions.size():
			var m: Dictionary = ty.misconceptions[i]
			var ref: String = m.get("ref", "%s#%d" % [t, i])
			if m.as != "distractor":
				continue
			for u in m.in:
				var found := false
				for c in QuestionEngine.cells(false, [t]).filter(func(x): return x.unknown == u):
					for seed in range(1, 120):
						var q := _make(t, u, c.rep, c.angle, seed, "mcq")
						if not q.has("error") and q.choices.any(func(o): return o.ref == ref):
							found = true
							break
					if found:
						break
				check(found, "%s never offers %s" % [u, ref])


func test_same_seed_same_question() -> void:
	for t in CELLS:
		for c in QuestionEngine.cells(false, [t]):
			var a := _make(t, c.unknown, c.rep, c.angle, 7)
			var b := _make(t, c.unknown, c.rep, c.angle, 7)
			check_eq(a.prompt + str(a.lines) + a.answer_text, b.prompt + str(b.lines) + b.answer_text, c.key)


func test_the_three_directions_are_all_asked() -> void:
	var cases := [["fn-transform-apply", "rule-from-moves"], ["fn-transform-describe", "describe-from-graphs"], ["fn-transform-apply", "undo-moves"]]
	for w in cases:
		var c: Dictionary = QuestionEngine.cells(false, [w[0]]).filter(func(x): return x.unknown == w[1])[0]
		var q := _make(w[0], w[1], c.rep, c.angle, 3)
		check(not q.has("error"), w[1])
	var u := _make("fn-transform-apply", "undo-moves", "equation", "substitute", 5)
	check(u.answer_text.begins_with("f(x) = "), "undo-moves asks for f: " + u.answer_text)


func test_the_map_is_the_moves_in_order() -> void:
	var v := {"k": "vs", "a": Q.new(2)}
	var t := TC.slide(1, 3)
	var first := TC.compose([v, t])
	check(first.A.eq(2) and first.D.eq(3), "stretch then up 3 is 2f + 3")
	var second := TC.compose([t, v])
	check(second.A.eq(2) and second.D.eq(6), "up 3 then stretch is 2f + 6")
	var h := TC.compose([{"k": "hs", "a": Q.new(1, 2)}, TC.slide(3, 0)])
	check(h.B.eq(2) and h.C.eq(3), "f(2(x − 3))")
	var back := TC.compose([v, t] + TC.undo([v, t]))
	check(back.A.eq(1) and back.B.eq(1) and back.C.is_zero() and back.D.is_zero(), "undoing a chain gives f")
	var p := TC.image(first, 4, 5)
	check(p[0].eq(5) and p[1].eq(13), "the image of (4, 5)")
	var o := TC.source(first, p[0], p[1])
	check(o[0].eq(4) and o[1].eq(5), "and back")


func test_the_four_graphs_of_a_pick_are_different() -> void:
	for unknown in ["sketch-stretch-shift", "sketch-reflection", "sketch-horizontal"]:
		var c: Dictionary = QuestionEngine.cells(false, ["fn-transform-apply"]).filter(func(x): return x.unknown == unknown)[0]
		for seed in range(1, 30):
			var q := _make("fn-transform-apply", unknown, c.rep, c.angle, seed)
			check_eq(q.format, "pick-the-graph", unknown)
			check_eq(q.graphs.size(), 4, unknown)
			var seen := {}
			for g in q.graphs:
				seen[str(g.curves)] = true
			check_eq(seen.size(), 4, "%s seed %d: two graphs are the same" % [unknown, seed])


func test_paper_1_has_two_moves_and_grid_images() -> void:
	for seed in range(1, 40):
		var q := QuestionEngine.make({"type": "fn-transform-apply", "unknown": "rule-from-moves", "rep": "equation",
			"angle": "track-a-point", "seed": seed, "paper": 1})
		check_eq(q.paper, 1, "paper")
		check(q.situation.moves.size() <= 2, "%d moves" % q.situation.moves.size())


func test_paper_2_has_decimals_and_three_moves() -> void:
	var three := 0
	for seed in range(1, 40):
		var q := QuestionEngine.make({"type": "fn-transform-apply", "unknown": "rule-from-moves", "rep": "equation",
			"angle": "track-a-point", "seed": seed, "paper": 2})
		check_eq(q.paper, 2, "paper")
		if q.situation.moves.size() == 3:
			three += 1
	check(three > 0, "no three-move chain")
	var m := QuestionEngine.make({"type": "fn-transform-describe", "unknown": "relate-two-models", "rep": "equation",
		"angle": "scale-rule", "seed": 5, "paper": 2})
	check_eq(m.answer.get("show", ""), "sf", "two waves are to 3 s.f.")
	check(m.choices.any(func(o): return o.get("trap", false)), "the rounding trap")


func test_a_half_on_a_reciprocal_reads_properly() -> void:
	var s := {"fam": "recip", "paper": 1}
	check_eq(TC.rule(s, {"A": Q.new(1, 2), "B": Q.new(1), "C": Q.new(3), "D": Q.new(0)}), "1/(2(x − 3))", "a half folds in")
	check_eq(TC.rule(s, {"A": Q.new(2), "B": Q.new(1), "C": Q.new(3), "D": Q.new(1)}), "2/(x − 3) + 1", "a whole number sits on top")


func test_a_boss_chain_is_one_situation() -> void:
	for id in ["fn-transform-describe", "fn-transform-apply"]:
		var windows := Dungeon.chain_windows(id)
		check(not windows.is_empty(), id + " has no boss chain")
		for steps in windows:
			for seed in [1, 2, 3]:
				var c := QuestionEngine.make_chain(steps, seed)
				check(not c.has("error"), "%s: %s" % [id, c.get("error")])
