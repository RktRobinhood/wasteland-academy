extends "res://tests/test_case.gd"
## The sequence-proof situation (FAL-753): t1-sequence-proof is built with every cell, on Paper 1,
## and every method of SL1.6.series-proof has questions. Every cell makes four different options,
## claims and relations match sums done by hand, a hidden or spoiled line is the line its chain
## says, the dot figures count what they say, and every misconception shows up as an option. The
## SymPy checker (tools/check-answers) proves each line again for general n.

const TYPE := "t1-sequence-proof"
## Cells, counted as tools/pedagogy.mjs counts them.
const CELLS := 51
const PICKED := ["next-line", "valid-proof", "particular-terms"]
const METHODS := ["general-difference", "series-formula", "forwards-backwards", "dot-diagram"]


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _draw(ask: String, angle: String, i: int) -> Dictionary:
	return SequenceProofSituation.generate(Seeded.new("%s|%s|%d" % [ask, angle, i]), {"ask": ask, "angle": angle})


func test_the_type_is_built_with_every_cell_and_method_on_paper_1() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	check_eq(t.unknowns.size(), 21)
	check_eq([int(t.paper.p1), int(t.paper.p2)], [4, 0], "the bank's parts are kept")
	var methods := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		methods[c.angle] = true
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [1], c.key)
	for m in METHODS:
		check(methods.has(m), "no cell by %s" % m)


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in range(1, 9):
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s as %s seed %d: %s" % [c.key, f, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "sequence-proof", c.key)
				check_eq(q.paper, 1, c.key)
				check_eq(q.choices.size(), 4, "%s seed %d: options" % [c.key, seed])
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, "%s: right options" % c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s seed %d: two options read the same" % [c.key, seed])
				check_eq(q.solutions[0].angle, c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps in %s" % [c.key, sol.steps.size(), sol.name])
				check(q.answer_text in Step.texts(q.solutions[0].steps).back(), "%s: the working ends on the answer" % c.key)


func test_only_a_choice_of_arguments_is_pick_only() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(_make(c, 2, "value").format == "mcq", c.unknown in PICKED, c.key)


func test_a_diagram_cell_shows_its_dots() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var q := _make(c, 3)
		check_eq(q.graph != null, c.rep == "diagram", c.key)
		if q.graph != null:
			check_eq(q.graph.kind, "dots", c.key)


func test_same_seed_same_question() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var a := _make(c, 7)
		var b := _make(c, 7)
		check_eq(a.lines, b.lines, c.key)
		check_eq(a.answer_text, b.answer_text, c.key)


## The chains' numbers can't be parsed here, so these are worked out by hand: u₃ of a linked
## claim, for one a, against the middle of its geometric terms.
func test_linked_terms_are_geometric_by_hand() -> void:
	for i in 100:
		var s := _draw("difference-in-a", "series-formula", i)
		var k: int = (s.j - 2 * s.i) / (s.i * s.i)
		for a in [1, 3, -2]:
			var d: int = k * a
			var mid: int = a + s.i * d
			check_eq(mid * mid, a * (a + s.j * d), "draw %d" % i)
	# 1st, 2nd and 4th terms: (a + d)² = a(a + 3d) gives d = a.
	check_eq(SequenceProofViews.lines_of({"fam": "linked", "i": 1, "j": 3}, "series-formula").back().text, "d = a")
	check_eq(SequenceProofViews.lines_of({"fam": "linked", "i": 2, "j": 8}, "series-formula").back().text, "d = a")
	check_eq(SequenceProofViews.lines_of({"fam": "linked", "i": 2, "j": 12}, "series-formula").back().text, "d = 2a")


func test_the_sums_match_hand_values() -> void:
	# 2 + 5 + 8 + 11 = 26, and n = 4 in (n/2)(3n + 1).
	var s := {"fam": "sum-list", "p": 3, "q": -1}
	check_eq(SequenceProofViews.lines_of(s, "series-formula").back().text, "Sₙ = (n/2)(3n + 1)")
	check_eq(SequenceProofViews.lines_of(s, "forwards-backwards").back().text, "Sₙ = (n/2)(3n + 1)")
	check_eq(SequenceProofViews.sum_at(s, 3), 15)
	# Sₙ = 2n² + 3n: S₁ = 5, S₂ = 14, so u₂ = 9 and uₙ = 4n + 1.
	var t := {"fam": "sum-term", "A": 2, "B": 3}
	check_eq(SequenceProofViews.lines_of(t, "general-difference").back().text, "uₙ = 4n + 1")
	# The second bracket, with its sign wrong: 2n² + 3n − 2n² − 4n + 2 + 3n − 3 = 2n − 1.
	check_eq(SequenceProofViews.lines_of(t, "general-difference", 2).back().text, "uₙ = 2n − 1")
	# (3(n + 1) + 2) − (3n + 2) is 3.
	check_eq(SequenceProofViews.lines_of({"fam": "ap-term", "p": 3, "q": 2}, "general-difference").back().text, "uₙ₊₁ − uₙ = 3")
	# log₂ 8 is 3 and log₂(1/8) is −3.
	check_eq(SequenceProofViews.lines_of({"fam": "log-geo", "b": 2, "p": 1, "q": 3}, "general-difference").back().text, "vₙ₊₁ − vₙ = 3")
	check_eq(SequenceProofViews.lines_of({"fam": "log-geo", "b": 2, "p": 1, "q": -3}, "general-difference").back().text, "vₙ₊₁ − vₙ = −3")


func test_a_cubic_has_two_equal_gaps_and_then_a_different_one() -> void:
	for i in 100:
		var s := _draw("particular-terms", "general-difference", i)
		var u := func(n: int) -> int: return (n - 1) * (n - 2) * (n - 3) + s.p * n + s.q
		check_eq(u.call(2) - u.call(1), s.p, "draw %d" % i)
		check_eq(u.call(3) - u.call(2), s.p, "draw %d" % i)
		check(u.call(4) - u.call(3) != s.p, "draw %d: the next gap differs" % i)


func test_the_terms_in_k_are_geometric_at_k() -> void:
	for i in 200:
		var s := _draw("common-ratio-check", "general-difference", i)
		var a: int = s.c1 * s.k0 + s.d1
		var b: int = s.c2 * s.k0 + s.d2
		var c: int = s.c3 * s.k0 + s.d3
		check(a != 0 and b != 0 and c != 0, "draw %d: a zero term" % i)
		check_eq(b * b, a * c, "draw %d" % i)
		check_eq(Q.new(b, a).key(), Q.new(s.r_top, s.r_den).key(), "draw %d" % i)
		check(not [s.c1, s.d1, s.c2, s.d2, s.c3, s.d3] in [SequenceProofSituation.KTERM_SKIP], "draw %d: the exam's terms" % i)


func test_relations_never_use_evenly_spaced_terms() -> void:
	for i in 200:
		check(_draw("arithmetic-relation", "general-difference", i).e >= 2, "draw %d" % i)
		var g := _draw("geometric-relation", "general-difference", i)
		check(g.g != g.h, "draw %d" % i)
		var b := _draw("second-term-bound", "series-formula", i)
		check(b.w >= 2, "draw %d" % i)


func test_a_rectangle_of_layers_counts_each_term() -> void:
	for i in 100:
		var s := _draw("dot-layer", "dot-diagram", i)
		var rows := SequenceProofViews.layer_rows(s, 4)
		check_eq(rows.size(), 4, "draw %d" % i)
		var counts := [0, 0, 0, 0]
		for row in rows:
			check_eq(row.size(), 4 * s.p + s.q, "draw %d: one width" % i)
			for c in row:
				counts[c] += 1
		for k in range(1, 5):
			check_eq(counts[k - 1], 2 * s.p * k - s.p + s.q, "draw %d: layer %d" % [i, k])


func test_two_staircases_make_a_rectangle() -> void:
	for i in 100:
		var s := _draw("dot-rectangle", "dot-diagram", i)
		var rows := SequenceProofViews.stair_rows(s)
		check_eq(rows.size(), s.m, "draw %d" % i)
		for row in rows:
			check_eq(row.size(), SequenceProofViews.term_at(s.p, s.q, 1) + SequenceProofViews.term_at(s.p, s.q, s.m), "draw %d" % i)


func test_a_hidden_or_spoiled_line_is_its_own_number() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 12):
			var q := _make(c, seed)
			if c.unknown == "missing-line":
				var hide: int = q.given.hide
				check(q.lines.has("Line %d: ?" % (hide + 1)), "%s seed %d" % [c.key, seed])
				check(q.answer_text.begins_with("Line %d: " % (hide + 1)), q.answer_text)
			elif c.unknown == "flawed-line":
				check(q.answer_text.begins_with("Line %d should read: " % (int(q.given.at) + 1)), q.answer_text)


func test_every_tag_shows_up_as_an_option() -> void:
	var seen := {}
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 41):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	for m in t.misconceptions:
		check(seen.has(m.ref), "no option is tagged %s" % m.ref)
