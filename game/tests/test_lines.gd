extends "res://tests/test_case.gd"
## The Lines region (FAL-424): each type is built with every catalogue cell, its distractor
## misconceptions show up as options, and the extra formats keep their rules. The SymPy checker
## (tools/check-answers) checks the maths.

## Cells per type: every catalogue cell (the type's unknown × rep × method).
const CELLS := {"fn-line-from-conditions": 102}
## Distractor misconceptions no option can carry ("type|ref"), and why.
const NOT_BUILT := {}


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func test_the_types_are_built_with_every_cell() -> void:
	var built := QuestionEngine.built_types()
	for t in CELLS:
		check(t in built, "%s is not built" % t)
		check_eq(QuestionEngine.cells(false, [t]).size(), CELLS[t], t)


func test_every_cell_makes_a_question_on_its_situation() -> void:
	for t in CELLS:
		for c in QuestionEngine.cells(false, [t]):
			for seed in [1, 2, 3, 4]:
				var q := _make(t, c.unknown, c.rep, c.angle, seed)
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, QuestionEngine.type_of(t).situation, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				if c.angle != "any":
					check_eq(q.solutions[0].angle, c.angle, c.key + ": the asked method comes first")
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
					check(q.answer_text in Step.text(sol.steps[sol.steps.size() - 1]), "%s: the last step doesn't state the answer" % c.key)
				if c.rep == "graph":
					check(q.graph != null, c.key + ": no graph")
				if c.rep == "table":
					check(q.table != null, c.key + ": no table")


func test_exam_types_offer_no_extra_format() -> void:
	for t in CELLS:
		if QuestionEngine.type_of(t).source != "exam":
			continue
		for c in QuestionEngine.cells(false, [t]):
			check(QuestionEngine.extra_formats(t, c.unknown, c.angle).is_empty(), c.key)


func test_every_distractor_misconception_is_an_option() -> void:
	for t in CELLS:
		var ty := QuestionEngine.type_of(t)
		for i in ty.misconceptions.size():
			var m: Dictionary = ty.misconceptions[i]
			var ref: String = m.get("ref", "%s#%d" % [t, i])
			if m.as != "distractor" or NOT_BUILT.has("%s|%s" % [t, ref]):
				continue
			for u in m.in:
				var found := false
				for c in QuestionEngine.cells(false, [t]).filter(func(x): return x.unknown == u):
					for seed in range(1, 80):
						var q := _make(t, u, c.rep, c.angle, seed, "mcq")
						if q.has("error"):
							continue
						if q.choices.any(func(o): return o.ref == ref):
							found = true
							break
					if found:
						break
				check(found, "%s never offers %s" % [u, ref])


func test_same_seed_same_question() -> void:
	for t in CELLS:
		for c in QuestionEngine.cells(false, [t]):
			var a := _make(t, c.unknown, c.rep, c.angle, 7)
			var b := _make(t, c.unknown, c.rep, c.angle, 7)
			check_eq(a.prompt + str(a.lines) + a.answer_text, b.prompt + str(b.lines) + b.answer_text, c.key)


func test_gdc_regression_is_paper_2_and_answers_to_3_sf() -> void:
	var t := "fn-line-from-conditions"
	for c in QuestionEngine.cells(false, [t]).filter(func(x): return x.angle == "gdc-regression"):
		for seed in range(1, 20):
			var q := _make(t, c.unknown, c.rep, c.angle, seed)
			check_eq(q.paper, 2, c.key)
			check_eq(q.answer.get("show", ""), "sf", c.key)


func test_a_paper_2_equation_offers_the_rounding_trap() -> void:
	var seen := 0
	for seed in range(1, 40):
		var q := QuestionEngine.make({"type": "fn-line-from-conditions", "unknown": "equation-two-points", "rep": "words", "angle": "gdc-regression", "seed": seed, "format": "mcq"})
		var trap: Array = q.choices.filter(func(o): return o.get("trap", false))
		check_eq(trap.size(), 1, "seed %d: one rounding trap" % seed)
		seen += trap.size()
		check(QuestionEngine.mark(q, {"choice": q.choices.find(trap[0])}).glancing, "picking it is a glancing hit")
	check(seen > 0, "no trap")


func test_the_boss_chain_is_one_line() -> void:
	var steps := Dungeon.chain_steps("fn-line-from-conditions")
	check_eq(steps.size(), 5)
	var c := QuestionEngine.make_chain(steps, 11)
	check(not c.has("error"), str(c.get("error")))
	check_eq(c.parts.size(), 5)
	for q in c.parts:
		check_eq(q.paper, 1, "the chain is Paper 1")


func test_a_paper_1_equation_is_exact() -> void:
	var t := "fn-line-from-conditions"
	for seed in range(1, 40):
		var q := QuestionEngine.make({"type": t, "unknown": "equation-two-points", "rep": "words", "angle": "point-gradient", "seed": seed, "paper": 1})
		check_eq(q.paper, 1, "paper")
		check(q.answer.get("exact", false), "a Paper 1 equation is exact")


func test_general_form_takes_any_whole_multiple_with_a_positive() -> void:
	var ans := Answer.make("gline", {"a": Q.new(2), "b": Q.new(-3), "d": Q.new(6)})
	ans.exact = true
	check_eq(Answer.text(ans), "2x − 3y + 6 = 0")
	check(Answer.mark(ans, {"a": "2", "b": "-3", "d": "6"}).correct, "the line")
	check(Answer.mark(ans, {"a": "4", "b": "-6", "d": "12"}).correct, "a multiple")
	check(not Answer.mark(ans, {"a": "-2", "b": "3", "d": "-6"}).correct, "a > 0 was asked")
	check(not Answer.mark(ans, {"a": "1", "b": "-3/2", "d": "3"}).correct, "fractions were not asked")
	check(not Answer.mark(ans, {"a": "2", "b": "-3", "d": "-6"}).correct, "another line")
	check_eq(Answer.gline_text(1, -2, 0), "x − 2y = 0")
