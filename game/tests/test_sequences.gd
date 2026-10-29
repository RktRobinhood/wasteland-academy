extends "res://tests/test_case.gd"
## The arithmetic-sequence situation (FAL-392): t1-arithmetic-sequence is built with
## every catalogue cell, every distractor misconception shows up as an option, n from
## Sₙ offers the negative root as a wrong option, and answers are marked exactly. The
## SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t1-arithmetic-sequence"
## Cells, counted as tools/pedagogy.mjs counts them.
const CELLS := 51


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)


func test_every_cell_makes_a_question_in_its_representation() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in [1, 2, 3]:
			var q := _make(c.unknown, c.rep, c.angle, seed)
			check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
			if q.has("error"):
				break
			check_eq(q.situation_id, "arithmetic-sequence", c.key)
			match c.rep:
				"table":
					check(q.table != null and q.table.heads == ["n", "uₙ"], c.key + ": a table of n and uₙ")
				"terms":
					check(q.lines[0].ends_with(", …"), c.key + ": the first terms")
				"notation":
					check(q.lines[0].contains(" = ") and q.table == null, c.key + ": notation")


func test_every_distractor_misconception_is_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for m in t.misconceptions:
		check_eq(m.as, "distractor", m.ref)
		for u in m.in:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 25):
					var q := _make(u, c.rep, c.angle, seed, "mcq")
					if q.choices.any(func(o): return o.ref == m.ref):
						found = true
						break
				if found:
					break
			check(found, "%s never appears on %s" % [m.ref, u])


func test_n_from_the_sum_offers_the_negative_root() -> void:
	for seed in range(1, 31):
		var q := _make("n-from-sum", "notation", "quadratic-in-n", seed, "mcq")
		var other: Q = Q.of(q.situation.other.to_int())
		check(other.sign() < 0, "seed %d: the other root is not negative" % seed)
		var opt: Array = q.choices.filter(func(o): return o.ref == "SL1.2.sum-unknown#1")
		check(opt.size() == 1 and opt[0].values.v.eq(other), "seed %d: the negative root is not an option" % seed)
		check(q.answer.values.v.sign() > 0 and q.answer.values.v.is_int(), "seed %d: n is not a positive whole number" % seed)


func test_answers_are_marked_exactly() -> void:
	# A sum of 1807 typed as 1810 is right to 3 s.f. but not the exact answer IB wants.
	var checked := 0
	for seed in range(1, 60):
		var q := _make("sum-from-u1-d", "notation", "formula-d", seed)
		var v: Q = q.answer.values.v
		if absi(v.n) < 1000 or v.n % 10 == 0:
			continue
		check(QuestionEngine.mark(q, {"v": v.key()}).correct, "seed %d: the exact sum is right" % seed)
		var rounded := Q.new(roundi(v.n / 10.0) * 10)
		check(Answer.number_right(rounded, v), "seed %d: %s is %s to 3 s.f." % [seed, rounded.key(), v.key()])
		check(not QuestionEngine.mark(q, {"v": rounded.key()}).correct, "seed %d: %s is marked right for %s" % [seed, rounded.key(), v.key()])
		checked += 1
	check(checked >= 5, "only %d sums of 1000 or more" % checked)


func test_a_typed_misconception_is_recognised() -> void:
	var q := _make("term-from-u1-d", "notation", "nth-formula", 3)
	var s: Dictionary = q.situation
	var wrong := int(s.u1) + int(s.n) * int(s.d)
	var r := QuestionEngine.mark(q, {"v": str(wrong)})
	check(not r.correct)
	check_eq(r.misconception, "SL1.2.nth-term#0")


func test_same_seed_same_question_and_seeds_vary() -> void:
	var texts := {}
	for seed in range(1, 21):
		var v := {"type": TYPE, "unknown": "d-from-two-terms", "rep": "notation", "angle": "gap-count", "seed": seed, "format": "mcq"}
		var a := JSON.stringify(preload("res://tools/export_questions.gd").plain(QuestionEngine.make(v)))
		var b := JSON.stringify(preload("res://tools/export_questions.gd").plain(QuestionEngine.make(v.duplicate())))
		check_eq(a, b, "seed %d" % seed)
		texts[QuestionEngine.make(v).lines[0]] = true
	check(texts.size() >= 15, "only %d different questions from 20 seeds" % texts.size())


func test_probes_are_served() -> void:
	var mine := QuestionEngine.probes().filter(func(x): return x.type == TYPE)
	check_eq(mine.size(), 3)
	check_eq(QuestionEngine.probe(TYPE, 1).verdict, "True")
	check_eq(QuestionEngine.probe(TYPE, 2).verdict, "Sometimes")


func test_paper_2_is_a_decimal_context_in_words() -> void:
	# FAL-419: the words cells of four unknowns have a Paper 2 version, every other
	# cell is Paper 1 only.
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var both: bool = c.rep == "words" and c.unknown in ArithmeticSequenceViews.PAPER2
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [1, 2] if both else [1], c.key)
		if not both:
			continue
		for seed in range(1, 11):
			var q := QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed,
				"format": "mcq", "paper": 2})
			check_eq(q.paper, 2, c.key)
			check(q.situation.ctx in ["money", "km"], c.key)
			# u₁ and d are decimals, so the working needs a calculator, and the answer is
			# still exact: an amount that ends, or a whole n.
			check(not q.given.u1.is_valid_int() and not q.given.d.is_valid_int(), "%s seed %d: u₁ or d is whole" % [c.key, seed])
			check(q.answer.exact, c.key)
			var v: Q = q.answer.values.v
			check(v.mul(100).is_int(), "%s seed %d: %s doesn't end" % [c.key, seed, q.answer_text])
			if c.unknown.begins_with("n-from"):
				check(v.is_int() and v.sign() > 0, "%s seed %d: n is not a positive whole number" % [c.key, seed])
			check(q.solutions.all(func(sol): return sol.steps.any(func(st): return st.contains("GDC"))), c.key + ": no GDC step")
			var right: int = range(q.choices.size()).filter(func(i): return q.choices[i].correct)[0]
			check(QuestionEngine.mark(q, {"choice": right}).correct, c.key)


func test_paper_2_first_term_and_sum_over_a_threshold() -> void:
	for seed in range(1, 31):
		var s := ArithmeticSequenceSituation.generate(Seeded.new("sum|%d" % seed), {"n": "sum", "sum_root": true, "paper": 2})
		var n: int = s.n.n
		check(s.X.lt(ArithmeticSequenceSituation.sum(s, n)) and not s.X.lt(ArithmeticSequenceSituation.sum(s, n - 1)),
			"seed %d: S%d is not the first sum over %s" % [seed, n, s.X.key()])
		var t := ArithmeticSequenceSituation.generate(Seeded.new("term|%d" % seed), {"n": "term", "paper": 2})
		var m: int = t.n.n
		check(t.Y.lt(ArithmeticSequenceSituation.term(t, m)) and not t.Y.lt(ArithmeticSequenceSituation.term(t, m - 1)),
			"seed %d: u%d is not the first term over %s" % [seed, m, t.Y.key()])


func test_paper_1_numbers_do_not_change_with_the_paper() -> void:
	# Told Paper 1, the recipe draws exactly what it drew before papers existed.
	for need in [{"n": "term"}, {"n": "sum", "two_terms": true}, {"n": "sum", "sum_root": true}]:
		for seed in range(1, 21):
			var a := ArithmeticSequenceSituation.generate(Seeded.new("p|%d" % seed), need)
			var b := ArithmeticSequenceSituation.generate(Seeded.new("p|%d" % seed), need.merged({"paper": 1}))
			check_eq(b.paper, 1)
			b.erase("paper")
			check_eq(str(ArithmeticSequenceSituation.export(a)), str(ArithmeticSequenceSituation.export(b)), str(need))
