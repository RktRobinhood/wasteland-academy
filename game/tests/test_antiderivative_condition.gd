extends "res://tests/test_case.gd"
## The antiderivative-condition situation (FAL-740): t5-antiderivative-condition is built with every
## cell and both skills, every cell makes four options with one right, the papers follow the
## method and the family, a typed answer needs every slot, the constant is never 0, a family's
## curves are the options, the figures show their numbers, and every misconception shows up. The
## SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t5-antiderivative-condition"
const CELLS := 29
const P1_ONLY := ["trig-chain", "trig-shift", "trig-and-exp", "log-inspection", "log-given-log"]
const P2_ONLY := ["poly-decimal-point", "exp-linear-decimal", "rate-model"]


func _make(c: Dictionary, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var view := {"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	var t := QuestionEngine.type_of(TYPE)
	for u in t.unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 2, "both listed skills have a question")
	var methods := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		methods[c.angle] = true
	for m in ["integrate-then-substitute", "accumulate-from-point", "pick-from-family", "integrate-and-fit", "gdc-start-plus-change"]:
		check(methods.has(m), m + " has no cell")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "antiderivative-condition", c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check(q.solutions[0].angle == c.angle, c.key)


func test_the_paper_follows_the_method_and_the_family() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var want: Array = [1, 2]
		if c.unknown in P1_ONLY:
			want = [1]
		elif c.unknown in P2_ONLY or c.angle == "gdc-start-plus-change":
			want = [2]
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), want, c.key)


func test_the_answer_marks_itself_and_c_is_never_left_in() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 6):
			var q := _make(c, seed, "value")
			check(not String(Answer.text(q.answer)).ends_with("+ C"), c.key)
			var typed := {}
			for id in q.answer.values:
				if id != "text":
					typed[id] = q.answer.values[id].text()
			check(QuestionEngine.mark(q, typed).correct, "%s seed %d: the answer itself" % [c.key, seed])


func test_a_typed_slip_logs_its_misconception() -> void:
	var c := {"unknown": "poly-function", "rep": "equation", "angle": "integrate-then-substitute"}
	var seen := 0
	for seed in range(1, 60):
		var q := _make(c, seed, "value")
		for o in q.choices:
			if o.ref == "SL5.5.boundary-condition#4":
				var typed := {}
				for id in o.values:
					if id != "text":
						typed[id] = o.values[id].text()
				var m := QuestionEngine.mark(q, typed)
				check(not m.correct, "seed %d: no constant" % seed)
				check_eq(m.misconception, "SL5.5.boundary-condition#4", "seed %d" % seed)
				seen += 1
	check(seen >= 5, "the slip came up %d times" % seen)


func test_the_constant_is_never_0() -> void:
	for ask in ["poly-function", "negative-power", "trig-chain", "trig-shift", "exp-and-power", "trig-and-exp", "parameter-from-gradient", "family-pick"]:
		for i in 120:
			var s: Dictionary = AntiderivativeConditionSituation.generate(Seeded.new("%s|%d" % [ask, i]), {"ask": ask, "paper": 1})
			check(not s.k.is_zero(), "%s draw %d" % [ask, i])


func test_a_familys_curves_are_its_options() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.unknown != "family-pick":
			continue
		for seed in range(1, 21):
			var q := _make(c, seed)
			check_eq(q.graph.curves.size(), 4, c.key)
			var labels: Array = q.graph.points.slice(1).map(func(p): return p.label)
			for o in q.choices:
				check(o.text in labels, "%s: %s is not a curve on the figure" % [c.key, o.text])


func test_the_graph_of_the_derivative_shows_its_corners() -> void:
	var c := {"unknown": "accumulate-graph", "rep": "graph", "angle": "accumulate-from-point"}
	for seed in range(1, 21):
		var q := _make(c, seed)
		check_eq(q.graph.points.size(), 4)
		check_eq(q.graph.curves[0].size(), 4)
		check(String(q.graph.y_name).ends_with("′"), "the axis names the derivative")
		for p in q.graph.points:
			check(p.label != "", "a corner has no label")


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 61):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen["%s|%s" % [c.unknown, o.ref]] = true
	for m in QuestionEngine.type_of(TYPE).misconceptions:
		for u in m.in:
			check(seen.has("%s|%s" % [u, m.ref]), "%s never comes up on %s" % [m.ref, u])


func test_hand_values() -> void:
	# f′ = 3x² − 2, f(1) = 5: x³ − 2x + C, 1 − 2 + C = 5, so C = 6.
	var s := {"fp": [[3, 2], [-2, 0]]}
	var F := AntiderivativeConditionSituation.anti(s.fp)
	check(AntiderivativeConditionSituation.val(F, 1).eq(-1))
	check(AntiderivativeConditionSituation.val(F, 3).eq(21))
	# f′ on corners (0, 2), (2, −2), (3, −2), (4, 2): the pieces are 0, −2 and 0.
	var p := {"from": 0, "xs": [0, 2, 3, 4], "ys": [2, -2, -2, 2]}
	check(AntiderivativeConditionSituation.signed_area(p, false).eq(-2))
	# All positive: 1 + 1 + 2 + 1/2 + 1/2 = 5.
	check(AntiderivativeConditionSituation.signed_area(p, true).eq(5))
