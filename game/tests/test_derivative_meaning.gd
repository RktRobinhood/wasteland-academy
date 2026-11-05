extends "res://tests/test_case.gd"
## The derivative-meaning situation (FAL-723): t5-derivative-meaning is built with every
## catalogue cell, every question is Paper 2, a reading in words is multiple choice with its
## units, and a limit graph has a gap. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t5-derivative-meaning"
const CELLS := 26
const SKILLS := 2


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), SKILLS, "every SL5.1 skill the catalogue lists has a question")


func test_every_cell_is_paper_2_with_four_different_options() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in range(1, 7):
				var q := _make(c.unknown, c.rep, c.angle, seed, f)
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.paper, 2, c.key)
				check_eq(q.choices.size(), 4, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s: two options read the same" % c.key)


func test_a_rate_keeps_its_sign_and_its_units() -> void:
	for seed in range(1, 25):
		var q := _make("rate-at-time", "words", "units-ratio", seed, "value")
		check(q.answer_text.contains(" per "), q.answer_text)
		check_eq(q.answer_text.contains("−"), q.situation.r < 0.0, q.answer_text)


func test_a_limit_graph_has_a_gap_at_the_point() -> void:
	for seed in range(1, 25):
		var q := _make("limit-from-graph", "graph", "graph-read", seed)
		var a: int = q.situation.a
		check_eq(q.graph.curves.size(), 1, "the two sides are one curve, so one colour")
		for p in q.graph.curves[0]:
			if p[1] <= float(q.graph.y1):
				check(absf(p[0] - a) > 0.1, "seed %d: the curve runs through the gap" % seed)
		check(q.situation.y != DerivativeMeaningSituation.limit_value(q.situation).n, "the dot is not at the limit")


func test_does_not_exist_can_be_picked_but_never_typed() -> void:
	var q := _make("limit-from-table", "table", "table-approach", 3)
	var dne: Array = q.choices.filter(func(o): return o.text == "The limit does not exist")
	check_eq(dne.size(), 1)
	check_eq(dne[0].ref, DerivativeMeaningViews.R_DNE)
	check(not Answer.typable(q.answer, dne[0].values), "it has no number to type")
