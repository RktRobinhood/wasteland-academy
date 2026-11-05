extends "res://tests/test_case.gd"
## The binomial-expansion situation (FAL-728): t1-binomial-term is built with every catalogue cell
## and all three skills, every option differs, the GDC is Paper 2 only, nCr and the coefficients
## match hand values, the triangle is drawn staggered with no row numbers, a typed expansion is
## marked term by term, every misconception shows up as an option, and the type is on the AA
## courses only. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t1-binomial-term"
## Cells, counted as tools/pedagogy.mjs counts them.
const CELLS := 56
const UNKNOWNS := 28
const SKILLS := 3


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	check_eq(t.unknowns.size(), UNKNOWNS)
	var skills := {}
	for u in t.unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), SKILLS, "every skill has a question")


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3, 4, 5]:
				var q := _make(c.unknown, c.rep, c.angle, seed, f)
				check(not q.has("error"), "%s as %s seed %d: %s" % [c.key, f, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "binomial-expansion", c.key)
				check_eq(q.choices.size(), 4, "%s as %s: options" % [c.key, f])
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, "%s as %s: right options" % [c.key, f])
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s as %s: two options read the same" % [c.key, f])
				check(not q.solutions.is_empty() and q.solutions[0].angle == c.angle, "%s: the asked method is the first worked solution" % c.key)


func test_the_gdc_is_paper_2_and_the_rest_is_both() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2] if c.angle == "gdc-ncr" else [1, 2], c.key)


func test_same_seed_same_question() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var a := _make(c.unknown, c.rep, c.angle, 7, "mcq")
		var b := _make(c.unknown, c.rep, c.angle, 7, "mcq")
		check_eq(a.prompt, b.prompt, c.key)
		check_eq(a.answer_text, b.answer_text, c.key)


func test_the_numbers_match_hand_values() -> void:
	check_eq(BinomialExpansionSituation.ncr(8, 3), 56)
	check_eq(BinomialExpansionSituation.ncr(12, 6), 924)
	check_eq(BinomialExpansionSituation.ncr(5, 0), 1)
	check_eq(BinomialExpansionSituation.ncr(5, 6), 0)
	check_eq(BinomialExpansionSituation.row(4), [1, 4, 6, 4, 1])
	# (2x − 3)^4: the x³ term is 4 × 8 × (−3).
	var s := {"n": 4, "a": 2, "b": -3, "p": 1, "over": false}
	check_eq(BinomialExpansionSituation.coef(s, 3), -96)
	check_eq(BinomialExpansionSituation.coef(s, 0), 81)
	# (x + 2/x)^4: the term with one x and three 2/x is 4 × 8 × x⁻².
	var r := {"n": 4, "a": 1, "b": 2, "p": 1, "over": true}
	check_eq(BinomialExpansionSituation.coef(r, 1), 32)
	check_eq(BinomialExpansionSituation.power_of(r, 1), -2)


func test_the_bracket_is_written_as_the_exam_writes_it() -> void:
	var s := {"a": 2, "b": -3, "p": 1, "first": false, "over": false, "letter": "", "n": 5}
	check_eq(BinomialExpansionViews.bracket(s), "(2x − 3)")
	check_eq(BinomialExpansionViews.power_text(s), "(2x − 3)⁵")
	s.merge({"a": -2, "b": 3, "first": true}, true)
	check_eq(BinomialExpansionViews.bracket(s), "(3 − 2x)")
	s.merge({"a": 1, "b": -2, "first": false, "over": true}, true)
	check_eq(BinomialExpansionViews.bracket(s), "(x − 2/x)")


func test_a_negative_is_only_in_the_second_term_and_no_bracket_has_a_common_factor() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 13):
			var s: Dictionary = _make(c.unknown, c.rep, c.angle, seed, "mcq").situation
			check(s.b > 0 if s.first else int(s.a) > 0, "%s seed %d: a negative is first" % [c.key, seed])
			check(not (s.a % 2 == 0 and s.b % 2 == 0) and not (s.a % 3 == 0 and s.b % 3 == 0), "%s seed %d: a common factor" % [c.key, seed])


func test_the_triangle_is_staggered_with_no_row_numbers() -> void:
	var t := BinomialExpansionViews.triangle(3)
	check_eq(t.rows, [["", ["", "", "", "1", "", "", ""]], ["", ["", "", "1", "", "1", "", ""]],
		["", ["", "1", "", "2", "", "1", ""]], ["", ["1", "", "3", "", "3", "", "1"]]])
	for seed in range(1, 25):
		var q := _make("coefficient-from-triangle", "table", "pascal-select", seed, "mcq")
		check_eq(q.table.rows.size(), int(q.situation.n) + 1, "seed %d: the triangle stops at row n" % seed)
		check(int(q.situation.n) <= BinomialExpansionSituation.ROW, "seed %d: the row is too long to draw" % seed)


func test_a_term_asked_is_a_term_and_a_coefficient_is_a_number() -> void:
	for seed in range(1, 30):
		var q := _make("specific-term", "equation", "general-term", seed, "mcq")
		check(q.answer_text.contains("x"), "seed %d: the term %s has no x" % [seed, q.answer_text])
		var t: Array = q.choices.filter(func(o): return o.ref == BinomialExpansionViews.R_TERM)
		if not t.is_empty():
			check(not t[0].text.contains("x"), "seed %d: the slip is the number alone" % seed)
		var c := _make("coefficient-raised", "equation", "general-term", seed, "mcq")
		check(not c.answer_text.contains("x"), "seed %d: the coefficient %s has an x" % [seed, c.answer_text])


func test_a_typed_expansion_is_marked_term_by_term() -> void:
	var q := _make("expand-raised", "equation", "pascal-row", 5)
	var typed := {}
	for key in q.answer.values:
		if key != "text":
			typed[key] = Fmt.num(q.answer.values[key])
	check(QuestionEngine.mark(q, typed).correct, "the expansion typed in")
	typed.c1 = Fmt.num(Q.of(q.answer.values.c1).add(1))
	check(not QuestionEngine.mark(q, typed).correct, "one coefficient out")


func test_a_row_is_typed_without_its_ends() -> void:
	var q := _make("pascal-row", "equation", "pascal-build", 2)
	var n: int = q.situation.n
	check_eq(Answer.slots(q.answer).size(), n - 1)
	var typed := {}
	for r in range(1, n):
		typed["v%d" % r] = str(BinomialExpansionSituation.ncr(n, r))
	check(QuestionEngine.mark(q, typed).correct, "the row typed in")


func test_every_distractor_misconception_is_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var ms: Array = t.misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		check_eq(ms[i].as, "distractor", ref)
		for u in ms[i]["in"]:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 60):
					var q := _make(u, c.rep, c.angle, seed, "mcq")
					if q.choices.any(func(o): return o.ref == ref):
						found = true
						break
				if found:
					break
			check(found, "%s never appears on %s" % [ref, u])


func test_the_tags_in_code_are_the_catalogue_s_own() -> void:
	var t := QuestionEngine.type_of(TYPE)
	check_eq(QuestionEngine.misconception_text(t, BinomialExpansionViews.R_NO_R), "Leaving out the r! in the formula for nCr")
	check(QuestionEngine.misconception_text(t, BinomialExpansionViews.R_NEG_ROOT).begins_with("Keeping the negative root"))
	check(QuestionEngine.misconception_text(t, BinomialExpansionViews.R_N_TERMS).begins_with("Counting n terms"))
	check(QuestionEngine.misconception_text(t, BinomialExpansionViews.R_PLACE).begins_with("Using the place"))
	check(QuestionEngine.misconception_text(t, BinomialExpansionViews.R_OVER).begins_with("Forgetting that (1/x)^r"))


func test_probes_are_served() -> void:
	var mine := QuestionEngine.probes().filter(func(x): return x.type == TYPE)
	check_eq(mine.size(), 3)
	check_eq(QuestionEngine.probe(TYPE, 0).verdict, "False")
	check_eq(QuestionEngine.probe(TYPE, 1).verdict, "Always")
	check_eq(QuestionEngine.probe(TYPE, 2).verdict, "True")


func test_the_type_is_on_the_aa_courses_only() -> void:
	# SL1.9 is an AA subtopic.
	for course in ["aa-sl", "aa-hl"]:
		check_eq(QuestionEngine.cells(false, [TYPE], course).size(), CELLS, course)
	for course in ["ai-sl", "ai-hl"]:
		check_eq(QuestionEngine.cells(false, [TYPE], course).size(), 0, course)
