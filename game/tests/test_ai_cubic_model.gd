extends "res://tests/test_case.gd"
## The ai-cubic-model situation (FAL-1001): fn-ai-cubic-model is built with every cell and both
## of its skills (AI-SL2.5.cubic-model, AI-SL2.6.reasonable-domain), only for the AI courses,
## Paper 2 throughout; every cell makes four options with one right and says its answer in each
## working's last step; the card, the graphs and the four domain cards are shown; every tagged
## slip shows up; a typed value is marked by its value; the box, its turning points, the table's
## refining, the zeros and the negative stretches against values worked by hand. The SymPy
## checker (tools/check-answers) checks the maths.

const TYPE := "fn-ai-cubic-model"
const CELLS := 18
const SKILLS := ["AI-SL2.5.cubic-model", "AI-SL2.6.reasonable-domain"]
const S := preload("res://engine/situations/ai_cubic_model.gd")
const V := preload("res://engine/situations/ai_cubic_model_views.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS, TYPE)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	for s in SKILLS:
		check(skills.has(s), "no unknown tests %s" % s)


func test_only_the_ai_courses_get_it() -> void:
	for course in ["aa-sl", "aa-hl"]:
		check(QuestionEngine.cells(false, [TYPE], course).is_empty(), "%s offers %s" % [course, TYPE])
	for course in ["ai-sl", "ai-hl"]:
		check_eq(QuestionEngine.cells(false, [TYPE], course).size(), CELLS, "%s on %s" % [TYPE, course])


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		check_eq(QuestionEngine.cell_papers(QuestionEngine.type_of(TYPE), c.unknown, c.rep, c.angle), [2], c.key)
		for f in ["value", "mcq"]:
			for seed in range(1, 7):
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "ai-cubic-model", c.key)
				check_eq(q.paper, 2, c.key)
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
				# The figure the question depends on is shown: the card, or the graph.
				if c.rep in ["graph", "diagram"]:
					check(q.graph != null, c.key + " shows no figure")
				if c.rep == "diagram":
					check_eq(q.graph.get("kind", ""), "sketch", c.key + ": the card is not drawn")


func test_the_domain_can_be_picked_from_four_cards() -> void:
	var picks := 0
	for rep in ["diagram", "words"]:
		var c := {"unknown": "box-domain", "rep": rep, "angle": "physical-limits"}
		for seed in range(1, 31):
			var q := _make(c, seed)
			if q.format != "pick-the-graph":
				continue
			picks += 1
			check_eq(q.graphs.size(), 4, "seed %d" % seed)
			check(q.graphs.all(func(g): return g.get("card", false)), "seed %d: a graph is not a card" % seed)
			check_eq(q.choices.filter(func(o): return o.correct).size(), 1, "seed %d" % seed)
			# With a diagram the card is drawn above the four graphs.
			check_eq(q.graph != null, rep == "diagram", "%s seed %d: the card" % [rep, seed])
	check(picks >= 6, "pick the graph came up %d times" % picks)


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


func test_a_typed_value_is_marked_by_its_value() -> void:
	for c in [{"unknown": "evaluate", "rep": "equation", "angle": "gdc-table"},
			{"unknown": "box-max", "rep": "graph", "angle": "gdc-max"},
			{"unknown": "negative-total", "rep": "equation", "angle": "gdc-zero"}]:
		for seed in range(1, 6):
			var q := _make(c, seed, "value")
			var v: Q = q.answer.values.v
			check(QuestionEngine.mark(q, {"v": Fmt.sf(v)}).correct, q.answer_text)
			check(not QuestionEngine.mark(q, {"v": Fmt.sf(v.mul(2))}).correct, "twice " + q.answer_text)


func test_the_box_by_hand() -> void:
	# A 20 by 12 card: V(2) = 2 × 16 × 8 = 256 and V(5) = 5 × 10 × 2 = 100.
	check(absf(S.vol(20, 12, 2) - 256.0) < 1e-9, "V(2)")
	check(absf(S.vol(20, 12, 5) - 100.0) < 1e-9, "V(5)")
	# 12x² − 128x + 240 = 0: x = (32 ∓ √304)/6, 2.42734 and 7.97266, the second past x = 6.
	var t: Array = S.turning(20, 12)
	check(absf(t[0] - (32.0 - sqrt(304.0)) / 6.0) < 1e-12, str(t))
	check(absf(t[1] - (32.0 + sqrt(304.0)) / 6.0) < 1e-12, str(t))
	check(t[0] < 6.0 and t[1] > 6.0, "either side of half the shorter side")
	check_eq(Fmt.sf(t[0]), "2.43")
	# The expanded form: 4x³ − 64x² + 240x.
	check_eq(V.v_expanded({"L": 20, "W": 12}), "4x³ − 64x² + 240x")
	# The table: V(2) = 256 beats V(3) = 252; then 2.4 (V = 262.656) and 2.43 (V = 262.68...).
	var tb: Array = S.table_steps({"L": 20, "W": 12})
	check_eq(tb[0], 2.0)
	check(absf(tb[2] - 2.4) < 1e-9, str(tb))
	check(absf(tb[4] - 2.43) < 1e-9, str(tb))
	check(absf(tb[3] - 2.4 * 15.2 * 7.2) < 1e-9, str(tb))


func test_a_cubic_model_by_hand() -> void:
	# (x − 1)(x − 2)(x − 3) = x³ − 6x² + 11x − 6: zeros 1, 2 and 3, and f(4) = 6.
	var co := [Q.new(1), Q.new(-6), Q.new(11), Q.new(-6)]
	var z: Array = S.zeros(co)
	check_eq(z.size(), 3)
	for i in 3:
		check(absf(z[i] - (i + 1)) < 1e-9, str(z))
	check(absf(S.horner(co, 4.0) - 6.0) < 1e-12, "f(4)")
	# Rising (a > 0), negative on [0, 1) and (2, 3): 1 + 1 = 2. Falling, on (1, 2) and (3, 5]: 1 + 2 = 3.
	var s := {"co": co, "zeros": z, "sign": 1, "hi": 5}
	var parts: Array = S.negative_parts(s)
	check(absf(parts[0][1] - parts[0][0] + parts[1][1] - parts[1][0] - 2.0) < 1e-9, str(parts))
	s.sign = -1
	var vals: Array = S.negative_total_vals(s)
	check(absf(vals[0] - 3.0) < 1e-9 and absf(vals[1] - 1.0) < 1e-9 and absf(vals[2] - 2.0) < 1e-9, str(vals))
	check_eq(V.poly({"co": co, "kind": "temp"}), "t³ − 6t² + 11t − 6")
