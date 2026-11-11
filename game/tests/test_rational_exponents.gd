extends "res://tests/test_case.gd"
## The rational-exponents situation (FAL-754): t1-rational-exponents is built with every cell,
## the skill's four methods and the type's index-laws, every cell makes four options with one
## right, everything is Paper 1, typed answers are marked by their numbers, and every
## misconception shows up. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t1-rational-exponents"
const CELLS := 23
const SKILL := "SL1.7.rational-exponents"


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _cell(unknown: String, angle: String) -> Dictionary:
	return {"unknown": unknown, "rep": "equation", "angle": angle}


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	for u in t.unknowns:
		check_eq(u.skills, [SKILL], u.id)
	check_eq(t.angles.map(func(a): return a.method), ["root-then-power", "power-then-root", "prime-base", "split-terms", "index-laws"],
		"every method of the skill is an angle, and the type's own")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "rational-exponents", c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check(q.solutions[0].angle == c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])


func test_every_cell_is_paper_1() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [1], c.key)
		for seed in range(1, 6):
			check_eq(_make(c, seed).paper, 1, c.key)


func test_answers_are_marked_by_their_numbers() -> void:
	var v := _make(_cell("value-negative", "prime-base"), 4, "value")
	check(QuestionEngine.mark(v, {"v": v.answer.values.v.text()}).correct, "a value, typed as a fraction")
	check(not QuestionEngine.mark(v, {"v": v.answer.values.v.neg().text()}).correct, "a negative value is wrong")
	var p := _make(_cell("root-as-power", "power-then-root"), 2, "value")
	check(QuestionEngine.mark(p, {"e": p.answer.values.e.text()}).correct, "the power of x")
	var b := _make(_cell("bracket-power", "prime-base"), 3, "value")
	check(QuestionEngine.mark(b, {"c": b.answer.values.c.text(), "e": b.answer.values.e.text()}).correct, "the number and the power")
	var sp := _make(_cell("split-three", "split-terms"), 5, "value")
	var typed := {}
	for k in sp.answer.values:
		if k != "text":
			typed[k] = sp.answer.values[k].text()
	check(QuestionEngine.mark(sp, typed).correct, "every number of a split")
	typed.e0 = sp.answer.values.e0.add(1).text()
	check(not QuestionEngine.mark(sp, typed).correct, "a wrong power")


func test_a_wrong_option_that_is_typed_logs_its_slip() -> void:
	var q := _make(_cell("product-x", "index-laws"), 2, "value")
	for o in q.choices:
		if o.correct or o.ref == "" or o.values.has("shape"):
			continue
		var typed := {}
		for k in o.values:
			if k != "text":
				typed[k] = o.values[k].text()
		var m := QuestionEngine.mark(q, typed)
		check(not m.correct, o.text)
		check_eq(m.misconception, o.ref, o.text)


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 41):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	var t := QuestionEngine.type_of(TYPE)
	for m in t.misconceptions:
		check(seen.has(m.ref), "%s never comes up" % m.ref)
	for ref in seen:
		check(QuestionEngine.misconception_text(t, ref) != "", "%s has no text" % ref)


func test_the_maps_examples_are_left_out() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 61):
			var line: String = _make(c, seed).lines[0]
			check(not line in ["8^(2/3)", "27^(−1/3)", "√x", "1/√x", "1/(x√x)", "(16x⁴)^(3/4)", "(x² − 2)/√x", "x^(2/3) = 4"], line)


func test_hand_values() -> void:
	check_eq(RationalExponentsSituation.ipow(3, 5), 243)
	check_eq(RationalExponentsSituation.prime_of(8), [2, 3])
	check_eq(RationalExponentsSituation.prime_of(9), [3, 2])
	check(RationalExponentsSituation.qpow(Q.new(2, 3), -2).eq(Q.new(9, 4)), "(2/3)⁻² = 9/4")
	check_eq(RationalExponentsViews.pw(64, Q.new(2, 3)), "64^(2/3)")
	check_eq(RationalExponentsViews.pw(Q.new(3, 2), -3), "(3/2)⁻³")
	check_eq(RationalExponentsViews.XQ(Q.new(-1, 2)), "x^(−1/2)")
	check_eq(RationalExponentsViews.XQ(Q.new(3)), "x³")
	check_eq(RationalExponentsViews.term(Q.new(5, 2), Q.new(4, 3)), "(5/2)x^(4/3)")
	check_eq(RationalExponentsViews.SUM([[Q.new(3), Q.new(5, 2)], [Q.new(-2), Q.new(-1, 2)]]), "3x^(5/2) − 2x^(−1/2)")
	check_eq(RationalExponentsViews.frac_sum(Q.new(1, 2), Q.new(2, 3), false), "1/2 + 2/3 = 3/6 + 4/6 = 7/6")
	check_eq(RationalExponentsViews.frac_sum(Q.new(-1, 3), Q.new(1, 5), true), "−1/3 − 1/5 = −5/15 − 3/15 = −8/15")
