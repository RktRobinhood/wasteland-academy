extends "res://tests/test_case.gd"
## The ai-linear-model situation (FAL-1001): fn-ai-piecewise-linear is built with every cell and
## both skills (AI-SL2.5.linear-model, AI-SL2.6.find-parameters), only for the AI courses, Paper 2
## throughout; every cell makes four options with one right and says its answer in each working's
## last step; a graph on every graph cell and a table on every table cell; every tagged slip shows
## up; a typed value is marked by its value; a two-piece cost, its rule, a tiered order and two
## bills against values worked by hand. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "fn-ai-piecewise-linear"
const CELLS := 32
const SKILLS := ["AI-SL2.5.linear-model", "AI-SL2.6.find-parameters"]
const S := preload("res://engine/situations/ai_linear_model.gd")
const V := preload("res://engine/situations/ai_linear_model_views.gd")


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
				check_eq(q.situation_id, "ai-linear-model", c.key)
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
				# The figure the question depends on is shown.
				if c.rep == "graph":
					check(q.graph != null, c.key + " shows no graph")
				else:
					check(q.graph == null, c.key + " shows a graph")
				if c.rep == "table":
					check(q.table != null, c.key + " shows no table")


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
	var c := {"unknown": "evaluate-model", "rep": "equation", "angle": "rate-and-start"}
	for seed in range(1, 6):
		var q := _make(c, seed, "value")
		var v: Q = q.answer.values.v
		check(QuestionEngine.mark(q, {"v": Fmt.money(v)}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v": Fmt.money(v.add(1))}).correct, "a dollar more")
	var d := {"unknown": "piecewise-input", "rep": "words", "angle": "piece-by-piece"}
	for seed in range(1, 6):
		var q := _make(d, seed, "value")
		var v: Q = q.answer.values.v
		check(QuestionEngine.mark(q, {"v": Fmt.dec(v)}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v": Fmt.dec(v.add(1))}).correct, "one more")
	var b := {"unknown": "two-bills", "rep": "table", "angle": "eliminate"}
	for seed in range(1, 6):
		var q := _make(b, seed, "value")
		var vs: Dictionary = q.answer.values
		check(QuestionEngine.mark(q, {"v0": Fmt.dec(vs.v0), "v1": Fmt.dec(vs.v1)}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v0": Fmt.dec(vs.v1), "v1": Fmt.dec(vs.v0)}).correct, "m and c swapped")


func test_a_two_piece_tariff_by_hand() -> void:
	# $20 with 4 GB included, then $4.50 a GB: 10 GB costs 20 + 4.5 × 6 = 47; 3 GB costs 20.
	var s := {"c": Q.new(20), "m1": Q.new(0), "x0": 4, "m2": Q.new(9, 2), "c0": Q.new(20)}
	check_eq(S.at(s, 10).text(), "47")
	check_eq(S.at(s, 3).text(), "20")
	check_eq(S.at(s, 4).text(), "20")
	# A first rate: $5 then $1.20 a m³ for the first 20 m³ (29 at the corner) and $2 after:
	# 25 m³ costs 29 + 2 × 5 = 39, and the rule past 20 is C = 2w − 11.
	var w := {"c": Q.new(5), "m1": Q.new(6, 5), "x0": 20, "m2": Q.new(2), "c0": Q.new(29)}
	check_eq(S.at(w, 25).text(), "39")
	check_eq(S.at(w, 10).text(), "17")
	check_eq(w.c0.sub(w.m2.mul(w.x0)).text(), "−11")


func test_a_tiered_order_by_hand() -> void:
	# Bands 1-19 at $24.50, 20-49 at $22, 50+ at $19.75; an order of 30 costs 30 × 22 = 660.
	# Each band's rate on its own items: 19 × 24.5 + 11 × 22 = 465.5 + 242 = 707.5.
	var s := {"edges": [1, 20, 50], "rates": [Q.new(49, 2), Q.new(22), Q.new(79, 4)], "n": 30, "band": 1}
	check_eq(S.marginal(s).text(), "1415/2")
	check_eq(Fmt.money(S.marginal(s)), "707.50")
	check_eq(V.band_text(s, 1), "20 to 49")
	check_eq(V.band_text(s, 2), "50 or more")


func test_two_bills_by_hand() -> void:
	# Each pair of bills on one line: m = (y2 − y1)/(x2 − x1), c = y1 − m x1, and the swapped
	# bills' line is x = (1/m) y − c/m.
	for i in range(1, 41):
		var s := S.generate(Seeded.new("bills|%d" % i), {"ask": "two-bills"})
		var m: Q = s.y2.sub(s.y1).div(s.x2 - s.x1)
		check(m.eq(s.m), "m from the two bills, %d" % i)
		check(s.y1.sub(m.mul(s.x1)).eq(s.c), "c from the first bill, %d" % i)
		check(s.y1.mul(Q.new(1).div(m)).sub(s.c.div(m)).eq(s.x1), "the swapped line, %d" % i)
	# $122 for 2 days and $194 for 4 days: 72/2 = 36 a day and 122 − 72 = 50.
	var t := {"x1": 2, "x2": 4, "y1": Q.new(122), "y2": Q.new(194)}
	var mm: Q = t.y2.sub(t.y1).div(t.x2 - t.x1)
	check_eq(mm.text(), "36")
	check_eq(t.y1.sub(mm.mul(t.x1)).text(), "50")
