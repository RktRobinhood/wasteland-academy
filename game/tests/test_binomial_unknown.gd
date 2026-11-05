extends "res://tests/test_case.gd"
## The binomial-unknown situation (FAL-740): t1-binomial-find-unknown is built with every cell, its
## one skill and all its methods, every cell makes four options with one right, the GDC is Paper 2
## and nowhere else, both signs come and go with the power, and every misconception shows up. The
## SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t1-binomial-find-unknown"
const CELLS := 31
const GDC := "gdc-search"


func _make(c: Dictionary, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var view := {"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func _cell(unknown: String, angle: String) -> Dictionary:
	return {"unknown": unknown, "rep": "equation", "angle": angle}


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	var skills := {}
	for u in t.unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.keys(), ["SL1.9.find-unknown"])
	check_eq(t.angles.map(func(a): return a.method), ["coefficient-equation", "simultaneous", GDC], "every method is an angle")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "binomial-unknown", c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check(q.solutions[0].angle == c.angle, c.key)


func test_the_gdc_is_paper_2_and_nowhere_else() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var only2: bool = c.angle == GDC
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2] if only2 else [1, 2], c.key)
		if only2:
			continue
		for seed in range(1, 11):
			for sol in _make(c, seed, "mcq", 1).solutions:
				check(sol.angle != GDC, "%s: a GDC method on Paper 1" % c.key)
				for st in sol.steps:
					check(not String(st).contains("Y1"), "%s: %s" % [c.key, st])


func test_a_power_with_n_in_it_has_only_the_gdc() -> void:
	check_eq(QuestionEngine.angles_for(QuestionEngine.type_of(TYPE), "n-from-power-bracket"), [GDC])


func test_both_signs_go_with_an_even_power() -> void:
	for seed in range(1, 31):
		var one := _make(_cell("k-odd-power", "coefficient-equation"), seed)
		check_eq(int(one.answer.values.n), 1, "an odd power has one real root")
		check(one.situation.e % 2 == 1)
		var two := _make(_cell("k-both-signs", "coefficient-equation"), seed)
		check_eq(int(two.answer.values.n), 2)
		check(two.answer.values.x0.eq(two.answer.values.x1.neg()), "the two values are k and −k")
		var plus := _make(_cell("k-positive-condition", GDC), seed)
		check(plus.lines[0].contains("k > 0"))
		check(plus.answer.values.x0.sign() > 0)


func test_a_surd_is_exact_on_paper_1_and_3_sf_on_paper_2() -> void:
	var c := _cell("k-surd-both-signs", "coefficient-equation")
	for seed in range(1, 13):
		var one := _make(c, seed, "value", 1)
		check_eq(one.answer.kind, "form")
		check(one.answer_text.contains("±√"), one.answer_text)
		var right := {"r": str(one.situation.d)}
		check(QuestionEngine.mark(one, right).correct, "seed %d: ±√d typed" % seed)
		var two := _make(c, seed, "value", 2)
		check_eq(two.answer.kind, "xs")
		check_eq(two.answer.show, "sf")


func test_either_order_of_two_values_is_right() -> void:
	var c := _cell("k-both-signs", "coefficient-equation")
	for seed in range(1, 11):
		var q := _make(c, seed, "value")
		var v: Dictionary = q.answer.values
		check(QuestionEngine.mark(q, {"x0": v.x0.text(), "x1": v.x1.text()}).correct, "seed %d" % seed)
		check(QuestionEngine.mark(q, {"x0": v.x1.text(), "x1": v.x0.text()}).correct, "seed %d swapped" % seed)


func test_the_paper_1_term_mean_has_rational_roots() -> void:
	for seed in range(1, 31):
		var q := _make(_cell("term-mean", "coefficient-equation"), seed, "mcq", 1)
		check(q.answer.get("exact", false), "seed %d" % seed)
		check(not q.answer_text.contains("."), q.answer_text)


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 41):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	var t := QuestionEngine.type_of(TYPE)
	var ms: Array = t.misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never comes up" % ref)
	for ref in seen:
		check(QuestionEngine.misconception_text(t, ref) != "", "%s has no text" % ref)


func test_hand_values() -> void:
	# (1 + kx)⁶: x² has 15k² and x³ has 20k³, and 15k² = 60 gives k = ±2.
	check_eq(BinomialUnknownSituation.ncr(6, 2) * 4, 60)
	# (2x + k)⁵ at x³: 10 × 8 × k² = 800 gives k = ±√10.
	var s := {"n": 5, "e": 2, "c": 2, "p": 1, "shape": "cxk", "d": 10, "val": Q.new(0)}
	BinomialUnknownSituation.fill(s)
	check(s.coef.eq(800), "the coefficient")
	check_eq(s.m, 3)
	# Neighbouring nCr: in (1 + kx)⁹ the coefficients of x and x² are 9k and 36k², equal at k = 1/4.
	check(Q.new(BinomialUnknownSituation.ncr(9, 1), BinomialUnknownSituation.ncr(9, 2)).eq(Q.new(1, 4)), "equal coefficients")
	# (x + c)⁷, third term the mean of the second and fourth: x²  − 6cx + 5c² = 0.
	var r := BinomialUnknownViews.mean_roots(7, 2, 2)
	check(absf(r[0] - 2.0) < 1e-9 and absf(r[1] - 10.0) < 1e-9, "the roots are c and 5c")
