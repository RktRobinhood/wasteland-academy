extends "res://tests/test_case.gd"
## The algebraic-proof situation (FAL-728): t1-algebraic-proof is built with every cell, both
## skills and both representations; every cell makes a question with four different options;
## the paper split follows the bank; identities and divisibility claims hold when worked out
## here by hand; a hidden, next or spoiled line is the line its chain says; typed answers are
## marked, in slots, with the slip detected; and every misconception shows up as an option. The
## SymPy checker (tools/check-answers) proves each statement again.

const TYPE := "t1-algebraic-proof"
## Cells, counted as tools/pedagogy.mjs counts them.
const CELLS := 31
const PICKED := ["next-step", "valid-proof", "finish-divisibility", "represent-integers"]


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


## n is an integer value of the statement's letter.
func _gen(ask: String, rep: String, angle: String, i: int) -> Dictionary:
	return AlgebraicProofSituation.generate(Seeded.new("%s|%s|%d" % [ask, angle, i]), {"ask": ask, "rep": rep, "angle": angle})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	check_eq(t.unknowns.size(), 14)
	check_eq([int(t.paper.p1), int(t.paper.p2)], [8, 1], "the bank's parts are kept")
	var skills := {}
	for u in t.unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 2, "both skills have questions")
	for u in t.unknowns:
		check(not QuestionEngine.angles_for(t, u.id).is_empty(), u.id)


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in range(1, 9):
				var q := _make(c.unknown, c.rep, c.angle, seed, f)
				check(not q.has("error"), "%s as %s seed %d: %s" % [c.key, f, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "algebraic-proof", c.key)
				check_eq(q.choices.size(), 4, "%s seed %d: options" % [c.key, seed])
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, "%s: right options" % c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s seed %d: two options read the same" % [c.key, seed])
				check(not q.solutions.is_empty() and q.solutions[0].angle == c.angle, "%s: the asked method comes first" % c.key)
				check(q.answer_text in Step.texts(q.solutions[0].steps).back(), "%s: the working ends on the answer" % c.key)


func test_only_a_proof_chosen_from_lines_is_pick_only() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var q := _make(c.unknown, c.rep, c.angle, 2, "value")
		check_eq(q.format == "mcq", c.unknown in PICKED, c.key)


func test_identities_are_paper_1_or_2_and_integer_proofs_paper_1() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var both: bool = c.unknown in AlgebraicProofViews.BOTH_PAPERS and c.angle != "algebraic-form"
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [1, 2] if both else [1], c.key)


func test_same_seed_same_question_and_seeds_vary() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var a := _make(c.unknown, c.rep, c.angle, 7, "mcq")
		var b := _make(c.unknown, c.rep, c.angle, 7, "mcq")
		check_eq(a.prompt, b.prompt, c.key)
		check_eq(a.answer_text, b.answer_text, c.key)
		var answers := {}
		for seed in range(1, 25):
			answers[_make(c.unknown, c.rep, c.angle, seed, "mcq").answer_text] = true
		check(answers.size() > 3, "%s: only %d different answers in 24 seeds" % [c.key, answers.size()])


## The value of "2(n² + 3n + 4) + 1" and the like can't be parsed here, so these are worked out
## by hand against the situation's numbers: the checker reads the lines themselves.
func test_a_difference_of_squares_is_a_multiple_for_every_n() -> void:
	for i in 100:
		var s := _gen("multiple-k", "equation", "algebraic-form", i)
		var total: int = 4 * s.p * s.q
		check_eq(total % int(s.m), 0, "draw %d: m divides 4pq" % i)
		check(s.m > 2 and s.m < total, "draw %d: m = %d" % [i, s.m])
		for n in range(1, 8):
			var e: int = (s.p * n + s.q) * (s.p * n + s.q) - (s.p * n - s.q) * (s.p * n - s.q)
			check_eq(e, total * n, "draw %d, n = %d" % [i, n])


func test_a_sum_of_a_list_is_its_big_and_tail() -> void:
	for i in 200:
		var s := _gen("consecutive-sum", "equation", "algebraic-form", i)
		for n in range(1, 6):
			var total := 0
			for t in s.c:
				total += s.u * n + s.v + t * s.w
			check_eq(total, s.big * n + s.tail, "draw %d" % i)
			check_eq(total % int(s.m), 0, "draw %d: m divides it" % i)
		check(s.m > 1, "draw %d: a divisor" % i)
		var gap := _gen("greatest-divisor", "equation", "algebraic-form", i)
		check(gap.m < gap.big, "draw %d: taking out the leading number leaves a fraction" % i)


func test_a_sum_of_squares_has_its_remainder_for_every_n() -> void:
	for i in 100:
		var s := _gen("remainder-form", "equation", "algebraic-form", i)
		for n in range(-6, 7):
			var total: int = n * n + (n + s.d) * (n + s.d)
			if s.shape == "three":
				total += (n - s.d) * (n - s.d)
			check_eq(posmod(total, s.m), s.r, "draw %d, n = %d" % [i, n])
		check(s.r > 0 and s.r < s.m, "draw %d: r = %d" % [i, s.r])


func test_the_quadratics_are_even_for_every_n() -> void:
	for i in 100:
		var s := _gen("case-bracket", "equation", "cases", i)
		var p := _gen("consecutive-factors", "equation", "consecutive-product", i)
		for n in range(-9, 10):
			check_eq(posmod(n * n + s.a * n + s.b, 2), 0, "draw %d, n = %d" % [i, n])
			check_eq(n * n + (2 * p.m + 1) * n + p.m * (p.m + 1), (n + p.m) * (n + p.m + 1), "draw %d, n = %d" % [i, n])


func test_no_statement_uses_the_exams_numbers() -> void:
	for i in 300:
		var a := _gen("multiple-k", "equation", "algebraic-form", i)
		check(not [a.p, a.q] in AlgebraicProofSituation.SYM_SKIP, "draw %d" % i)
		var b := _gen("simplify-left-side", "equation", "expand-simplify", i)
		if b.fam == "triple":
			check(b.k >= 2, "draw %d: k" % i)
		if b.fam == "square-diff":
			check(b.d >= 2, "draw %d: d" % i)


func test_a_hidden_line_is_the_lines_own_number() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == "missing-line"):
		for seed in range(1, 15):
			var q := _make(c.unknown, c.rep, c.angle, seed, "mcq")
			var hide: int = q.given.hide
			check(q.lines.has("Line %d: ?" % (hide + 1)), "%s seed %d" % [c.key, seed])
			check(q.answer_text.begins_with("Line %d: " % (hide + 1)), q.answer_text)
			check(q.lines.filter(func(l): return String(l).ends_with(": ?")).size() == 1, "one hidden line")


func test_the_spoiled_line_is_the_first_that_differs() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == "flawed-step"):
		for seed in range(1, 25):
			var q := _make(c.unknown, c.rep, c.angle, seed, "value")
			var at: int = q.given.at
			var good := AlgebraicProofViews.chain(q.given)
			var bad := AlgebraicProofViews.chain(q.given, q.given.slip)
			for i in at:
				check_eq(bad[i].text, good[i].text, "%s seed %d: line %d" % [c.key, seed, i + 1])
			check(bad[at].text != good[at].text, "%s seed %d: line %d is the slip" % [c.key, seed, at + 1])
			check_eq(q.answer.values.line, "Line %d" % (at + 1), c.key)
			var typed: Dictionary = {"line": "Line %d" % (at + 1)}
			var wrong_line: Dictionary = {"line": "Line %d" % (at + 2 if at + 2 <= bad.size() else at)}
			for id in good[at].v:
				typed[id] = good[at].v[id].key()
				wrong_line[id] = good[at].v[id].key()
			check(QuestionEngine.mark(q, typed).correct, "%s seed %d: the right line typed" % [c.key, seed])
			check(not QuestionEngine.mark(q, wrong_line).correct, "%s seed %d: the fix on another line" % [c.key, seed])


func test_every_distractor_misconception_is_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for m in t.misconceptions:
		check_eq(m.as, "distractor", m.text)
		var ref: String = m.get("ref", "%s#%d" % [TYPE, t.misconceptions.find(m)])
		for u in m["in"]:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 300):
					if _make(u, c.rep, c.angle, seed, "mcq").choices.any(func(o): return o.ref == ref):
						found = true
						break
				if found:
					break
			check(found, "%s never appears on %s" % [ref, u])


func test_a_typed_form_is_marked_in_slots_and_a_slip_detected() -> void:
	var seen := 0
	for seed in range(1, 40):
		var q := _make("simplify-left-side", "equation", "expand-simplify", seed)
		var right := {}
		for id in q.answer.values:
			if id != "text":
				right[id] = q.answer.values[id].key()
		check(QuestionEngine.mark(q, right).correct, "seed %d: the answer typed" % seed)
		for o in q.choices:
			if not o.correct and o.ref != "" and Answer.typable(q.answer, o.values):
				var typed := {}
				for id in o.values:
					if id != "text":
						typed[id] = o.values[id].key()
				var r := QuestionEngine.mark(q, typed)
				check(not r.correct, "seed %d: %s" % [seed, o.text])
				check_eq(r.misconception, o.ref, "seed %d: %s" % [seed, o.text])
				seen += 1
	check(seen > 20, "only %d slips typed" % seen)


func test_the_factors_can_be_typed_in_either_order() -> void:
	var q := _make("consecutive-factors", "equation", "consecutive-product", 3)
	var p: Q = q.answer.values.p
	var r: Q = q.answer.values.q
	check(QuestionEngine.mark(q, {"p": p.key(), "q": r.key()}).correct, "in order")
	check(QuestionEngine.mark(q, {"p": r.key(), "q": p.key()}).correct, "swapped")


## "Another way" keeps the numbers, and where a method doesn't suit them the working says so.
func test_another_way_keeps_the_numbers() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var t := QuestionEngine.type_of(TYPE)
		for other in QuestionEngine.angles_for(t, c.unknown):
			if other == c.angle:
				continue
			for seed in range(1, 12):
				var q := QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": other, "same_angle": c.angle, "seed": seed, "format": "mcq"})
				var first := _make(c.unknown, c.rep, c.angle, seed, "mcq")
				check(not q.has("error"), "%s as %s seed %d" % [c.key, other, seed])
				check_eq(q.lines[0], first.lines[0], "%s as %s seed %d" % [c.key, other, seed])
				check(not q.solutions.is_empty() and q.solutions[0].angle == other, "%s as %s seed %d: the working" % [c.key, other, seed])


func test_probes_are_served() -> void:
	var mine := QuestionEngine.probes().filter(func(x): return x.type == TYPE)
	check_eq(mine.size(), 3)
	check_eq(QuestionEngine.probe(TYPE, 0).verdict, "False")
	check_eq(QuestionEngine.probe(TYPE, 1).verdict, "Sometimes")
	check_eq(QuestionEngine.probe(TYPE, 2).verdict, "False")
