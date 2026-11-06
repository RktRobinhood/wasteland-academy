extends "res://tests/test_case.gd"
## The log-laws situation (FAL-751): t1-log-laws is built with every cell, both skills and all eight
## methods, every cell makes four options with one right, calculator methods are Paper 2 and
## nowhere else, a GDC check says it is no proof, typed answers are marked by their numbers, and
## every misconception shows up. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t1-log-laws"
const CELLS := 32
const SKILLS := ["SL1.7.log-laws", "SL1.7.change-of-base"]
const CALCULATOR := ["gdc-check", "gdc-logbase"]


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
	check_eq(skills.keys(), SKILLS)
	check_eq(t.angles.map(func(a): return a.method), ["combine", "evaluate-separately", "expand", "gdc-check", "cob-formula",
		"common-base-power", "define-and-log", "gdc-logbase"], "every method of both skills is an angle")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "log-laws", c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check(q.solutions[0].angle == c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])


func test_only_a_calculator_cell_is_paper_2() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var twos := 0
	for c in QuestionEngine.cells(false, [TYPE]):
		var only2: bool = c.angle in CALCULATOR or c.unknown == "value-3sf"
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2] if only2 else [1], c.key)
		if only2:
			twos += 1
			continue
		for seed in range(1, 8):
			for sol in _make(c, seed).solutions:
				check(not sol.angle in CALCULATOR, "%s: a GDC method on Paper 1" % c.key)
	check_eq(twos, 4, "the gdc-check cells, and the 3 s.f. value's two")


func test_a_gdc_check_is_not_a_proof() -> void:
	for u in ["single-log-letters", "expand-letters"]:
		for seed in range(1, 21):
			var sol: Dictionary = _make(_cell(u, "gdc-check"), seed).solutions[0]
			var text := " ".join(sol.steps)
			check(text.contains("both forms show"), text)
			check(text.contains("a check, not a proof"), text)
			check(text.contains("the laws are the proof"), text)


func test_answers_are_marked_by_their_numbers() -> void:
	var one := _make(_cell("single-log-letters", "combine"), 3, "value")
	check(QuestionEngine.mark(one, {"c": one.answer.values.c.text()}).correct, "the number in the log, as a fraction")
	var q := _make(_cell("expand-letters", "expand"), 5, "value")
	var v: Dictionary = q.answer.values
	var typed := {"u": v.u.text(), "c": v.c.text()}
	if v.has("n"):
		typed.n = v.n.text()
	check(QuestionEngine.mark(q, typed).correct, "the coefficients of p and q")
	typed.c = v.c.neg().text()
	check(not QuestionEngine.mark(q, typed).correct, "the wrong sign")
	var k := _make(_cell("single-ln-k", "combine"), 2, "value")
	check(QuestionEngine.mark(k, {"k": k.answer.values.k.text()}).correct, "k")


func test_a_value_to_3_sf_has_the_trap() -> void:
	var traps := 0
	for seed in range(1, 21):
		var q := _make(_cell("value-3sf", "gdc-logbase"), seed)
		check_eq(q.paper, 2)
		check_eq(q.answer.show, "sf")
		for o in q.choices:
			if o.get("trap", false):
				traps += 1
	check(traps > 0, "no rounding trap")


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
	check_eq(LogLawsSituation.ipow(3, 5), 243)
	check(LogLawsSituation.is_power(343, 7) and not LogLawsSituation.is_power(40, 2), "powers")
	check_eq(LogLawsSituation.top_power(2, 1000), 9)
	# log₄ 32 = 5/2, as 4^(5/2) = 32.
	check(absf(LogLawsSituation.lg(4, 32.0) - 2.5) < 1e-12, "log₄ 32")
	check_eq(LogLawsViews.pq_text(Q.new(2), Q.new(-1, 2)), "2p − q/2")
	check_eq(LogLawsViews.pq_text(Q.new(-1), Q.new(1), Q.new(1)), "1 − p + q")
	check_eq(LogLawsViews.power_text(Q.new(3), Q.new(-2)), "p³ − q²")
	check_eq(LogLawsViews.ratio_text(Q.new(3, 2)), "3p/(2q)")
	check_eq(LogLawsViews.mono(Q.new(5, 2), "x²", ""), "5x²/2")
	check_eq(LogLawsViews.mono(Q.new(3), "x²", "y³"), "3x²/y³")
