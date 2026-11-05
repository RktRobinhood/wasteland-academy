extends "res://tests/test_case.gd"
## The tree-diagram situation (FAL-739): t4-tree-diagram is built with every cell and its skill,
## on the exam's mix of papers, with one right option; a tree draws the question's own numbers,
## forks add to 1, a tin's branches are the recount, k keeps one root, and every misconception
## shows up. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t4-tree-diagram"
const CELLS := 37


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _ask(ask: String, rep: String, seed: int, paper: int = 1) -> Dictionary:
	return TreeDiagramSituation.generate(Seeded.new("%s|%d" % [ask, seed]), {"ask": ask, "rep": rep, "paper": paper})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	check_eq(QuestionEngine.type_of(TYPE).unknowns.size(), 14)
	check(TYPE in QuestionEngine.built_types("aa-sl"), "AA SL")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.solutions[0].angle, c.angle, c.key)
				check(q.solutions[0].steps.size() >= 2 and q.solutions[0].steps.size() <= 5, c.key)
				if c.rep == "diagram":
					check_eq(q.graph.kind, "tree", c.key)
				if c.rep == "table":
					check(q.table != null, c.key)


func test_the_shares_situation_is_conditional() -> void:
	check(TreeDiagramViews.new() is ExtensionViews)
	check_eq(QuestionEngine.type_of(TYPE).situation, "tree-diagram")
	check_eq(QuestionEngine.catalogue().situations["tree-diagram"].extends, "conditional")


func test_paper_only_unknowns_stay_on_their_paper() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 6):
			var q := _make(c, seed)
			if c.unknown in TreeDiagramSituation.P1_ONLY:
				check_eq(q.paper, 1, c.key)
			elif c.unknown in TreeDiagramSituation.P2_ONLY:
				check_eq(q.paper, 2, c.key)


func test_forks_add_to_one() -> void:
	for i in 80:
		for paper in [1, 2]:
			var s := _ask("total-over-paths", "diagram", i, paper)
			check_eq(s.first.reduce(func(a, b): return a.add(b), Q.new(0)).key(), "1", "first fork")
			for row in s.second:
				check_eq(row.reduce(func(a, b): return a.add(b), Q.new(0)).key(), "1", "later fork")


func test_a_tree_has_two_or_three_branches_and_its_own_labels() -> void:
	var sizes := {}
	for i in 120:
		var s := _ask("complete-branch", "diagram", i)
		sizes["%dx%d" % [s.n1, s.n2]] = true
		var q := TreeDiagramViews.tree(s, {"0": "x"})
		check_eq(q.p[0], "x")
		check_eq(q.p.size(), s.n1)
		check_eq(q.q[0].size(), s.n2)
		check(q.has("heads"), "stage names")
	check_eq(sizes.size(), 4, "every shape of tree comes up")


func test_a_tin_tree_is_the_recount() -> void:
	for i in 80:
		var s := _ask("branch-after-draw", "diagram", i)
		var t := TreeDiagramSituation.total(s)
		var d: int = s.counts[0] - 1 if s.mode == "wo" else s.counts[0] + 1
		var after: int = t - 1 if s.mode == "wo" else t + 1
		check(s.second[0][0].eq(Q.new(d, after)), "draw %d" % i)


func test_a_missing_branch_shows_a_letter_not_its_value() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == "complete-branch"):
		for seed in range(1, 15):
			var q := _make(c, seed)
			var labels: Array = q.graph.p.duplicate()
			for row in q.graph.q:
				labels.append_array(row)
			check_eq(labels.filter(func(l): return l == "x").size(), 1, "one x")


func test_only_one_k_keeps_every_branch() -> void:
	for i in 80:
		var s := _ask("parameter-on-branch", "diagram", i)
		var one := Q.new(1)
		check(s.v.sign() > 0 and s.v.lt(one) and s.a2.mul(s.v).lt(one), "draw %d" % i)
		check(not s.other.lt(one) or not s.a2.mul(s.other).lt(one), "draw %d: the other root is rejected" % i)
		check(one.sub(s.v).mul(one.sub(s.a2.mul(s.v))).eq(s.r), "draw %d" % i)


func test_a_growing_tin_gives_its_n_back() -> void:
	for i in 40:
		var s := _ask("selections-find-n", "words", i)
		var red: int = s.r0
		var p := Q.new(1)
		for k in s.n - 1:
			p = p.mul(Q.new(red + k, red + k + 1))
		p = p.mul(Q.new(1, red + s.n))
		check(p.eq(s.chance), "draw %d" % i)


func test_a_game_only_wins_two_ways() -> void:
	for i in 40:
		var s := _ask("rounds-exceed-total", "words", i, 2)
		var a: Q = s.a
		var top := TreeDiagramSituation.power(a, s.rounds)
		var once := TreeDiagramSituation.power(a, s.rounds - 1).mul(s.b).mul(Q.new(s.rounds))
		check(top.add(once).eq(s.v), "draw %d" % i)


func test_past_paper_numbers_are_left_out() -> void:
	for i in 400:
		var s := _ask("parameter-on-branch", "diagram", i)
		check(not (s.a2.eq(Q.new(1, 2)) and s.v.eq(Q.new(1, 3))), "draw %d" % i)
		check(_ask("selections-find-n", "words", i).r0 != 3, "draw %d" % i)
		check(_ask("draws-in-terms-of-n", "words", i, 2).big != 10, "draw %d" % i)


func test_every_distractor_misconception_is_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for i in t.misconceptions.size():
		var m: Dictionary = t.misconceptions[i]
		var ref: String = m.get("ref", "%s#%d" % [TYPE, i])
		for u in m["in"]:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 80):
					if _make(c, seed).choices.any(func(o): return o.ref == ref):
						found = true
						break
				if found:
					break
			check(found, "%s never appears on %s" % [ref, u])
