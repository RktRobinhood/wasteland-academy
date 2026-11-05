extends "res://tests/test_case.gd"
## The independence situation (FAL-739): t4-independence is built with every cell and all three
## skills, every cell makes four options with one right, a test is independent about half of the
## time and its options can't be told apart by their wording, a test's numbers are true, figures
## show the numbers, the quadratics are Paper 2, and every misconception shows up. The SymPy
## checker (tools/check-answers) checks the maths.

const TYPE := "t4-independence"
const CELLS := 44
const TESTS := ["test-from-probabilities", "test-from-venn", "test-from-table", "test-from-tree", "test-from-conditional"]


func _make(c: Dictionary, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var view := {"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 3, "all three listed skills have a question")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "independence", c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check(q.solutions[0].angle == c.angle, c.key)


func test_the_paper_follows_the_skill() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var want: Array = [2] if c.unknown in ["ratio-from-union", "overlap-from-only-regions"] else [1, 2]
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), want, c.key)


func test_both_verdicts_come_up_on_every_test_and_paper() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if not c.unknown in TESTS:
			continue
		for paper in [1, 2]:
			var yes := 0
			for seed in range(1, 121):
				if _make(c, seed, "mcq", paper).situation.indep:
					yes += 1
			check(yes >= 40 and yes <= 80, "%s Paper %d: independent %d times in 120" % [c.key, paper, yes])


func test_classify_makes_all_three_cases() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.unknown != "classify-events":
			continue
		var seen := {}
		for seed in range(1, 91):
			var k: String = _make(c, seed).situation.kind
			seen[k] = seen.get(k, 0) + 1
		for k in ["excl", "indep", "neither"]:
			check(seen.get(k, 0) >= 15, "%s: %s came up %d times in 90" % [c.key, k, seen.get(k, 0)])


func test_a_test_cant_be_guessed_from_the_wording() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if not c.unknown in TESTS:
			continue
		for seed in range(1, 21):
			var q := _make(c, seed)
			# The stem says nothing of the verdict.
			check_eq(q.asked, "Determine whether A and B are independent, with a valid reason.", c.key)
			var no := 0
			for o in q.choices:
				if String(o.text).ends_with("not independent"):
					no += 1
				else:
					check(String(o.text).ends_with(" independent"), "%s: %s" % [c.key, o.text])
			check_eq(no, 2, "%s seed %d: two options end in each verdict" % [c.key, seed])


func test_the_cases_share_their_margins() -> void:
	# Not independent moves the overlap, never P(A) or P(B), so the margins give nothing away.
	for i in 200:
		var s: Dictionary = IndependenceSituation.generate(Seeded.new("m|%d" % i), {"ask": "test-from-table", "rep": "table", "paper": 2})
		check_eq(s.a + s.i, s.na)
		check_eq(s.b + s.i, s.nb)
		check_eq((s.i == s.base), s.indep, "draw %d" % i)
		check_eq(s.a + s.b + s.i + s.o, s.u)
		check(mini(s.a, mini(s.b, mini(s.i, s.o))) >= 1, "draw %d: a region is empty" % i)


func test_a_typed_test_needs_the_numbers_and_the_verdict() -> void:
	var c := {"unknown": "test-from-probabilities", "rep": "equation", "angle": "product-test"}
	for seed in range(1, 11):
		var q := _make(c, seed, "value")
		var v: Dictionary = q.answer.values
		var right := {"l": v.l.text(), "r": v.r.text(), "verdict": v.verdict}
		check(QuestionEngine.mark(q, right).correct, "seed %d: the answer itself" % seed)
		var flipped := right.duplicate()
		flipped.verdict = "not independent" if v.verdict == "independent" else "independent"
		var m := QuestionEngine.mark(q, flipped)
		check(not m.correct, "seed %d: the wrong verdict" % seed)
		check_eq(m.misconception, "SL4.11.test-independence#3", "seed %d" % seed)


func test_figures_show_the_numbers() -> void:
	var venn := {"unknown": "test-from-venn", "rep": "diagram", "angle": "product-test"}
	var table := {"unknown": "test-from-table", "rep": "table", "angle": "product-test"}
	var tree := {"unknown": "test-from-tree", "rep": "diagram", "angle": "conditional-test"}
	var flat := {"unknown": "both-from-probabilities", "rep": "diagram", "angle": "multiply"}
	for seed in range(1, 13):
		check_eq(_make(venn, seed).graph.kind, "venn")
		check_eq(_make(table, seed).table.rows.size(), 4)
		var t: Dictionary = _make(tree, seed).graph
		check_eq(t.kind, "tree")
		var q := _make(tree, seed)
		check_eq(t.q[0][0], "%d/%d" % [q.situation.g1, q.situation.n1])
		var f: Dictionary = _make(flat, seed).graph
		check_eq(f.q[0], f.q[1], "independent: the second branches are the same")


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 41):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	for m in QuestionEngine.type_of(TYPE).misconceptions:
		check(seen.has(m.ref), "%s never comes up" % m.ref)


func test_hand_values() -> void:
	# P(A) = 3P(B) and P(A ∪ B) = 3x + x − 3x²: x = 0.1 gives 0.37, and the other root is above 1.
	var s := {"pa": Q.new(3, 10), "pb": Q.new(1, 10)}
	var u: Q = s.pa.add(s.pb).sub(s.pa.mul(s.pb))
	check(u.eq(Q.new(37, 100)), "the union")
	# t = 0.3: the regions 0.09 and 0.49 meet in x = 0.21, a repeated root of x = (a + x)(b + x).
	var a := Q.new(9, 100)
	var b := Q.new(49, 100)
	var x := Q.new(21, 100)
	check(a.add(x).mul(b.add(x)).eq(x), "the repeated root")
