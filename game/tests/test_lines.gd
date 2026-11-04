extends "res://tests/test_case.gd"
## The Lines region (FAL-424): each type is built with every catalogue cell, its distractor
## misconceptions show up as options, and the extra formats keep their rules. The SymPy checker
## (tools/check-answers) checks the maths.

## Cells per type: every catalogue cell (the type's unknown × rep × method).
const CELLS := {"fn-line-from-conditions": 102, "fn-ext-intersection-lines": 21, "fn-ext-line-model": 22, "fn-concept-gradient-meaning": 16,
	"fn-pre-linear-equations": 13, "fn-pre-simultaneous": 13, "fn-link-rate-of-change": 66}
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


func test_a_wrong_option_can_stop_at_x() -> void:
	var ans := Answer.make("point", {"x": Q.new(3), "y": Q.new(-2)})
	ans.exact = true
	var alone := {"x": Q.new(3), "y": Q.new(0), "alone": true}
	check_eq(Answer.text(ans, alone), "x = 3")
	check(not Answer.typable(ans, alone), "it can only be picked")
	check(Answer.canon(ans, alone) != Answer.canon(ans, {"x": Q.new(3), "y": Q.new(0)}), "and is not the point (3, 0)")


func test_the_gdc_meeting_point_is_paper_2_and_the_rest_paper_1() -> void:
	var t := "fn-ext-intersection-lines"
	for c in QuestionEngine.cells(false, [t]):
		for seed in range(1, 12):
			var q := _make(t, c.unknown, c.rep, c.angle, seed)
			check_eq(q.paper, 2 if c.angle == "gdc-intersect" else 1, c.key)


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


func test_a_filling_tank_states_where_it_is_full() -> void:
	var seen := 0
	for seed in range(1, 200):
		var q := _make("fn-ext-line-model", "domain-sense", "words", "substitute-interpret", seed)
		if "being filled" in q.lines[0]:
			seen += 1
			check(q.lines.size() == 3 and q.lines[2].begins_with("The tank is full at "), str(q.lines))
	check(seen > 0, "no tank")


func test_the_prior_learning_is_paper_1_and_exact() -> void:
	for t in ["fn-pre-linear-equations", "fn-pre-simultaneous"]:
		for c in QuestionEngine.cells(false, [t]):
			for seed in range(1, 12):
				var q := _make(t, c.unknown, c.rep, c.angle, seed)
				check_eq(q.paper, 1, c.key)
				if q.answer.kind != "choice":
					check(q.answer.get("exact", false), c.key + ": exact")


func test_an_error_spot_names_a_misconception_on_a_wrong_line() -> void:
	var cases := {"fn-pre-linear-equations": ["fractions"], "fn-pre-simultaneous": ["scale-one", "scale-both"]}
	for t in cases:
		var refs := {}
		for u in cases[t]:
			for seed in range(1, 40):
				var q := _make(t, u, "equation", QuestionEngine.angles_for(QuestionEngine.type_of(t), u)[0], seed, "error-spot")
				check(not q.has("error"), "%s: %s" % [u, q.get("error")])
				check_eq(q.choices.size(), 4, u)
				check(q.choices[q.spot.bad].correct, u + ": the first wrong line is the right option")
				refs[q.spot.ref] = true
		check_eq(refs.size(), 1 if t == "fn-pre-linear-equations" else 2, t + ": every error-spot misconception shows up")


func test_stopping_at_x_can_be_picked_but_not_typed() -> void:
	for seed in range(1, 30):
		var q := _make("fn-pre-simultaneous", "word-problem", "words", "elimination", seed, "mcq")
		var stop: Array = q.choices.filter(func(o): return o.ref == "fn-pre-simultaneous#2")
		check_eq(stop.size(), 1, "seed %d" % seed)
		check(stop[0].text.begins_with("x = "), stop[0].text)
		check(not Answer.typable(q.answer, stop[0].values), "it can only be picked")


func test_the_gdc_tangent_is_paper_2_to_3_sf_and_the_rest_paper_1() -> void:
	var t := "fn-link-rate-of-change"
	var trapped := 0
	for c in QuestionEngine.cells(false, [t]):
		for seed in range(1, 12):
			var q := _make(t, c.unknown, c.rep, c.angle, seed, "mcq")
			check_eq(q.paper, 2 if c.angle == "gdc-dydx" else 1, c.key)
			if c.angle == "gdc-dydx":
				check_eq(q.answer.get("show", ""), "sf", c.key)
				trapped += q.choices.filter(func(o): return o.get("trap", false)).size()
	check(trapped > 0, "no rounding trap on Paper 2")


func test_a_chord_never_reaches_the_tangent_in_the_failing_method() -> void:
	var t := "fn-link-rate-of-change"
	check(not "method-pick" in QuestionEngine.extra_formats(t, "tangent-gradient-methods", "chord-sequence"), "chords fail for the exact gradient")
	check("method-pick" in QuestionEngine.extra_formats(t, "tangent-gradient-methods", "differentiate-substitute"), "the power rule works")
	var q := _make(t, "tangent-gradient-methods", "equation", "chord-sequence", 3)
	check("no chord reaches it" in Step.text(q.solutions[0].steps[1]), "the working says where the method stops")


func test_the_matching_is_one_pick_of_all_four_kinds() -> void:
	var t := "fn-link-rate-of-change"
	for rep in ["equation", "words"]:
		for seed in range(1, 30):
			var q := _make(t, "match-rate-kind", rep, "rate-and-start", seed)
			check_eq(q.format, "mcq", "the match format isn't built")
			check_eq(q.lines.size(), 4, rep)
			for kind in [LinkRateViews.KIND_WHOLE, LinkRateViews.KIND_ALL, LinkRateViews.KIND_FIT, LinkRateViews.KIND_NOW]:
				check_eq(q.answer_text.count(kind), 1, kind)


func test_the_bare_gradient_slip_is_logged_though_the_type_has_no_error_spot() -> void:
	var seen := false
	for seed in range(1, 30):
		var q := _make("fn-link-rate-of-change", "interpret-regression-gradient", "equation", "rate-and-start", seed, "mcq")
		seen = seen or q.choices.any(func(o): return o.ref == "SL4.4.interpret-ab#1")
	check(seen, "SL4.4.interpret-ab#1 never shows up")
