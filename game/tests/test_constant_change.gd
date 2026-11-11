extends "res://tests/test_case.gd"
## The constant-change situation (FAL-754): t4-constant-changes is built with every cell, every cell
## makes four options with one right and no two alike, every question is Paper 1 with no extra
## format, a box plot is drawn to scale on its ticks, the rules for a centre and a spread hold both
## ways, and every misconception shows up. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t4-constant-changes"
const CELLS := 99


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var asks := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		asks[c.unknown] = true
	check_eq(asks.size(), ConstantChangeViews.UNKNOWNS.size(), "every unknown has a cell")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3, 4]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "constant-change", c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check(q.solutions[0].angle == c.angle, c.key)


func test_every_question_is_paper_1() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [1], c.key)


func test_a_box_plot_is_drawn_on_its_ticks() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.rep != "graph":
			continue
		for seed in range(1, 9):
			var q := _make(c, seed)
			var g: Dictionary = q.graph
			check_eq(g.kind, "box", c.key)
			check_eq(g.boxes.size(), 1, c.key)
			var tick := float(g.tick)
			var five: Array = ["min", "q1", "med", "q3", "max"].map(func(k): return float(g.boxes[0][k]))
			for i in 5:
				check(is_equal_approx(fmod(five[i], tick), 0.0), "%s: %s is off the ticks" % [c.key, five[i]])
				if i > 0:
					check(five[i] - five[i - 1] >= 2 * tick - 0.001, c.key + ": two numbers less than two ticks apart")
			check(float(g.x0) < five[0] and five[4] < float(g.x1), c.key + ": the box plot runs off its axis")


func test_the_rules_run_both_ways() -> void:
	var a := Q.new(3, 2)
	var b := Q.new(-4)
	# A centre takes the whole change, a spread the factor, the variance its square.
	check(ConstantChangeSituation.forward("median", Q.new(10), a, b).eq(Q.new(11)), "1.5 × 10 − 4 = 11")
	check(ConstantChangeSituation.forward("range", Q.new(10), a, b).eq(Q.new(15)), "1.5 × 10 = 15")
	check(ConstantChangeSituation.forward("variance", Q.new(8), a, b).eq(Q.new(18)), "2.25 × 8 = 18")
	for name in ConstantChangeSituation.STATS:
		var v := Q.new(37, 2)
		check(ConstantChangeSituation.backward(name, ConstantChangeSituation.forward(name, v, a, b), a, b).eq(v), name + " undone")


func test_a_list_has_its_statistics() -> void:
	# 2, 3, 3, 7, 9, 10, 15: the median 7, the halves 2, 3, 3 and 9, 10, 15.
	var xs: Array = [2, 3, 3, 7, 9, 10, 15].map(func(x): return Q.new(x))
	var st := ConstantChangeSituation.list_stats(xs)
	check(st.mean.eq(Q.new(7)), "the mean")
	check(st.median.eq(Q.new(7)), "the median")
	check(st.mode.eq(Q.new(3)), "the mode")
	check(st["lower quartile"].eq(Q.new(3)), "the lower quartile")
	check(st["upper quartile"].eq(Q.new(10)), "the upper quartile")
	check(st["interquartile range"].eq(Q.new(7)), "the IQR")
	check(st.range.eq(Q.new(13)), "the range")


func test_a_list_changed_agrees_with_the_rules() -> void:
	for seed in range(1, 120):
		var rep := "terms"
		var ask: String = ["add-centre-spread", "multiply-centre-spread", "linear-centre-spread"][seed % 3]
		var s: Dictionary = ConstantChangeSituation.generate(Seeded.new("l|%d" % seed), {"ask": ask, "rep": rep})
		check(not s.is_empty(), ask)
		if s.is_empty():
			continue
		for name in s.asked:
			check(s.new[name].eq(ConstantChangeSituation.forward(name, s.old[name], s.a, s.b)), "%s: %s" % [ask, name])


func test_find_a_and_b_has_a_real_stretch_and_shift() -> void:
	for seed in range(1, 120):
		var s: Dictionary = ConstantChangeSituation.generate(Seeded.new("f|%d" % seed), {"ask": "find-a-and-b", "rep": ["equation", "words"][seed % 2]})
		check(not s.a.eq(Q.new(1)) and not s.b.is_zero(), "a ≠ 1 and b ≠ 0")
		check(s.a.sign() > 0, "a > 0")


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 31):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	for m in QuestionEngine.type_of(TYPE).misconceptions:
		check(seen.has(m.ref), "%s never comes up" % m.ref)
