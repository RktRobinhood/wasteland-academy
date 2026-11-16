extends "res://tests/test_case.gd"
## The log-equation situation (FAL-956): t1-log-equation is built with every cell and all four
## skills, every cell makes four options with one right, it is Paper 1 throughout, every working
## checks the root in the arguments, a typed x is marked by its value, and every misconception
## shows up. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t1-log-equation"
const CELLS := 11
const SKILLS := ["SL1.7.log-equations", "SL1.7.log-laws", "SL1.5.exp-log-form", "SL1.7.change-of-base"]


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


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
	check_eq(t.angles.map(func(a): return a.method), ["combine-then-exponentiate", "match-arguments", "domain-first",
		"check-each-root", "cob-formula", "common-base-power"])


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in range(1, 9):
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "log-equation", c.key)
				check_eq(q.paper, 1, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check(q.solutions[0].angle == c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
					check(sol.steps[-1].contains(q.answer_text), "%s: the last step doesn't say %s" % [c.key, q.answer_text])


func test_every_cell_is_paper_1() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [1], c.key)


func test_a_rejected_root_is_named() -> void:
	for seed in range(1, 21):
		var q := _make(_cell("combine-quadratic", "combine-then-exponentiate"), seed)
		var bad: String = q.given.bad.replace("-", "−")
		var text := " ".join(q.solutions[0].steps)
		check(text.contains("x = %s" % bad) and text.contains("reject it"), text)
		var r := _make(_cell("reject-root", "check-each-root"), seed)
		check_eq(r.answer_text, "x = %s" % r.given.bad.replace("-", "−"))


func test_a_typed_x_is_marked_by_its_value() -> void:
	var q := _make(_cell("combine-linear", "match-arguments"), 4, "value")
	var v: Q = q.answer.values.v
	check(QuestionEngine.mark(q, {"v": v.text()}).correct, "x")
	check(not QuestionEngine.mark(q, {"v": v.add(1).text()}).correct, "x + 1")


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 61):
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
	# x² − 2x − 15 = (x − 5)(x + 3).
	var rs := LogEquationSituation.roots(1, -2, -15)
	check_eq(rs.map(func(r): return r.text()), ["−3", "5"])
	# 2x² + x − 6 = (2x − 3)(x + 2).
	check_eq(LogEquationSituation.roots(2, 1, -6).map(func(r): return r.text()), ["−2", "3/2"])
	check(LogEquationSituation.roots(1, 1, 1).is_empty(), "no real roots")
	check_eq(LogEquationViews.lin([3, -4]), "3x − 4")
	check_eq(LogEquationViews.lg("log₂", [1, 0]), "log₂ x")
	check_eq(LogEquationViews.prod([1, 3], [1, 0]), "x(x + 3)")
	check_eq(LogEquationViews.factors(2, [Q.new(-2), Q.new(3, 2)]), "(x + 2)(2x − 3)")
	check_eq(LogEquationViews.factors(2, [Q.new(-1), Q.new(3)]), "2(x + 1)(x − 3)")
	check_eq(LogEquationViews.poly(1, -1, -12), "x² − x − 12")
	check_eq(LogEquationViews.bound([[2, 3], [1, -1]]).text(), "1")
