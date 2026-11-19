extends "res://tests/test_case.gd"
## The odd-even situation (FAL-1007): fn-ahl-odd-even is built with every cell and its three
## AHL2.14 skills, only for AA HL, on both papers; every cell makes four options with one right
## and the answer in each working's last step; every tagged slip shows up; a typed answer is
## marked by its value; the hand-worked parities, values and integrals hold. The SymPy checker
## (tools/check-answers, r9oe_check) checks the maths.

const TYPE := "fn-ahl-odd-even"
const CELLS := 22
const SKILLS := ["AHL2.14.odd-even-test", "AHL2.14.odd-even-graph", "AHL2.14.odd-even-combine"]
const S := preload("res://engine/situations/odd_even.gd")
const V := preload("res://engine/situations/odd_even_views.gd")


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
	for s in SKILLS:
		check(skills.has(s), "no unknown tests %s" % s)


func test_only_aa_hl_gets_it() -> void:
	for course in ["aa-sl", "ai-sl", "ai-hl"]:
		check(QuestionEngine.cells(false, [TYPE], course).is_empty(), "%s offers %s" % [course, TYPE])
	check_eq(QuestionEngine.cells(false, [TYPE], "aa-hl").size(), CELLS, "aa-hl")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		check_eq(QuestionEngine.cell_papers(QuestionEngine.type_of(TYPE), c.unknown, c.rep, c.angle), [1, 2], c.key)
		for f in ["value", "mcq"]:
			for seed in range(1, 7):
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "odd-even", c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check(q.solutions[0].angle == c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
					check(Step.texts(sol.steps)[-1].contains(q.answer_text), "%s: the last step doesn't say %s" % [c.key, q.answer_text])


func test_both_papers_and_paper_1_has_no_calculator() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for p in [1, 2]:
			var q := _make(c, 3, "mcq", p)
			check(not q.has("error") and q.paper == p, "%s on Paper %d" % [c.key, p])
	# An integral given from 0 to a is a whole number on Paper 1 and may be a decimal on Paper 2.
	var c := {"unknown": "symmetric-integral", "rep": "equation", "angle": "symmetric-area"}
	var decimals := 0
	for seed in range(1, 80):
		var q := _make(c, seed, "mcq", 1)
		if q.situation.mode == "given":
			check(RegEx.create_from_string("dx = −?\\d+\\.$").search(q.lines[0]) != null, "Paper 1: %s" % q.lines[0])
		var q2 := _make(c, seed, "mcq", 2)
		if q2.situation.mode == "given" and q2.lines[0].contains("."):
			decimals += 1
	check(decimals > 0, "no Paper 2 decimal")


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 61):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	var ty := QuestionEngine.type_of(TYPE)
	var ms: Array = ty.misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never comes up" % ref)
	for ref in seen:
		check(QuestionEngine.misconception_text(ty, ref) != "", "%s has no text" % ref)


func test_a_typed_answer_is_marked_by_its_value() -> void:
	var c := {"unknown": "symmetry-coefficient", "rep": "equation", "angle": "substitute-minus-x"}
	for seed in range(1, 8):
		var q := _make(c, seed, "value")
		var k: Q = q.answer.values.v
		check(QuestionEngine.mark(q, {"v": k.text().replace("−", "-")}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v": k.add(1).text().replace("−", "-")}).correct, "one more")
	var d := {"unknown": "symmetric-integral", "rep": "equation", "angle": "sign-rule"}
	for seed in range(1, 8):
		var q := _make(d, seed, "value")
		var v: Q = q.answer.values.v
		check(QuestionEngine.mark(q, {"v": Fmt.dec(v).replace("−", "-")}).correct, q.answer_text)


func test_hand_worked_parities() -> void:
	# x³ − 4x is odd, x² cos x even, x³ + x² neither, e^x + e^(−x) even, 2e^x − e^(−x) neither.
	check_eq(S.parity([S.term(1, 3), S.term(-4, 1)]), "odd")
	check_eq(S.parity([S.term(1, 2, "cos")]), "even")
	check_eq(S.parity([S.term(1, 3), S.term(1, 2)]), "neither")
	check_eq(S.parity([S.term(1, 0, "exp"), S.term(1, 0, "nexp")]), "even")
	check_eq(S.parity([S.term(3, 0, "exp"), S.term(-3, 0, "nexp")]), "odd")
	check_eq(S.parity([S.term(2, 0, "exp"), S.term(-1, 0, "nexp")]), "neither")
	# x² sin x is odd: (−x)² sin(−x) = −x² sin x.
	check_eq(S.parity([S.term(1, 2, "sin")]), "odd")
	check_eq(V.ftext(S.at_minus([S.term(1, 2, "sin"), S.term(-3, 1)])), "−x² sin x + 3x")
	check_eq(V.raw_minus([S.term(2, 3, "sin"), S.term(-1, 1)]), "2(−x)³ sin(−x) − (−x)")
	# h(x) = x² + 3x: h(1) = 4, h(−1) = −2, so 1 is a counterexample.
	var s := {"terms": [S.term(1, 2), S.term(3, 1)], "parity": "neither"}
	check(S._counter(s) and s.ctr == 1, str(s))
	# x³ − x + 2: f(1) = f(−1) = 2, so 1 is no counterexample; 2 is.
	var t := {"terms": [S.term(1, 3), S.term(-1, 1), S.term(2, 0)], "parity": "neither"}
	check(S._counter(t) and t.ctr == 2, str(t))


func test_hand_worked_combinations_and_integrals() -> void:
	check_eq(S.combined("odd", "odd", "product"), "even")
	check_eq(S.combined("odd", "even", "product"), "odd")
	check_eq(S.combined("odd", "even", "sum"), "neither")
	check_eq(S.combined("odd", "even", "fg"), "even")
	check_eq(S.combined("odd", "odd", "fg"), "odd")
	check_eq(S.combined("even", "odd", "gf"), "even")
	# ∫ from 0 to 2 of (3x² + 1) dx = 8 + 2 = 10.
	check(S.half_integral([S.term(3, 2), S.term(1, 0)], 2).eq(10))
	# The polyline (0, 0), (2, 4), (3, 1): area 4 + 2.5 = 6.5.
	check(S.poly_area([[0, 0], [2, 4], [3, 1]]).eq(Q.new(13, 2)))


func test_a_counterexample_is_asked_of_a_function_that_is_neither() -> void:
	for u in ["classify-polynomial", "classify-mixed"]:
		for seed in range(1, 15):
			var q := _make({"unknown": u, "rep": "equation", "angle": "counterexample"}, seed)
			check_eq(q.situation.parity, "neither", u)
	for seed in range(1, 15):
		var q := _make({"unknown": "combine-parity", "rep": "equation", "angle": "sign-rule"}, seed)
		check_eq(q.situation.op, "product", "the sign rule is asked of a product")
