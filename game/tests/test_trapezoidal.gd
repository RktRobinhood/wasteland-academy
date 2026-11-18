extends "res://tests/test_case.gd"
## The trapezoidal situation (FAL-1000): t5-ai-trapezoidal is built with every cell and all five
## AI SL 5.8 skills, only for the AI courses, Paper 2 throughout; every cell makes four options
## with one right and says its answer in each working's last step; every tagged slip shows up; a
## typed value is marked by its value; the rule, the bend and a missing height against values
## worked by hand. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t5-ai-trapezoidal"
const CELLS := 33
const SKILLS := ["AI-SL5.8.trapezoid-from-function", "AI-SL5.8.trapezoid-from-data", "AI-SL5.8.compare-with-exact",
	"AI-SL5.8.over-or-under-estimate", "AI-SL5.8.find-missing-value"]
const S := preload("res://engine/situations/trapezoidal.gd")
const V := preload("res://engine/situations/trapezoidal_views.gd")


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
				check_eq(q.situation_id, "trapezoidal", c.key)
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
				if c.rep in ["graph", "diagram"]:
					check(q.graph != null or q.has("graphs"), c.key + " shows no figure")
				if c.rep == "table":
					check(q.table != null, c.key + " shows no table")


func test_pick_the_graph_shows_four_cards() -> void:
	var c := {"unknown": "pick-underestimate-graph", "rep": "graph", "angle": "chords-above-or-below"}
	for seed in range(1, 9):
		var q := _make(c, seed)
		check_eq(q.format, "pick-the-graph", "seed %d" % seed)
		check_eq(q.graphs.size(), 4, "seed %d" % seed)
		check(q.graphs.all(func(g): return g.get("card", false)), "seed %d: a graph is not a card" % seed)


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
	var c := {"unknown": "strip-width", "rep": "equation", "angle": "trapezoidal-formula"}
	for seed in range(1, 6):
		var q := _make(c, seed, "value")
		var v: Q = q.answer.values.v
		check(QuestionEngine.mark(q, {"v": Fmt.dec(v)}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v": Fmt.dec(v.add(1))}).correct, "one more")
	var d := {"unknown": "data-estimate", "rep": "table", "angle": "formula-with-data"}
	for seed in range(1, 6):
		var q := _make(d, seed, "value")
		check(QuestionEngine.mark(q, {"v": Fmt.sf(q.answer.values.v)}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v": Fmt.sf(q.answer.values.v.mul(2))}).correct, "no half")


func test_the_rule_by_hand() -> void:
	# y = x² on [0, 2] with 4 strips: (0.25)[0 + 4 + 2(0.25 + 1 + 2.25)] = 2.75, against 8/3: 3.125% over.
	var s := {"fam": "quad", "co": [Q.new(1), Q.new(0), Q.new(0)], "a": Q.new(0), "h": Q.new(1, 2), "n": 4, "b": Q.new(2)}
	check(absf(S.trap(s) - 2.75) < 1e-12, str(S.trap(s)))
	check(absf(S.exact(s) - 8.0 / 3.0) < 1e-12, str(S.exact(s)))
	var e: Array = S.percentage_slips(s)
	check(absf(e[0] - 3.125) < 1e-9, str(e))
	check_eq(S.bend(s, 0.0, 2.0), "up")
	# The h slip: (2 − 0)/5 = 0.4, so 2.75 × 4/5 = 2.2.
	check(absf(S.function_slips(s)[1] - 2.2) < 1e-12, "h from n + 1")
	# Widths 2, 4, 6, 4 every 10 m: 5 × (2 + 4 + 2 × 10) = 130; the ends doubled 160; no half 260.
	var ys := [Q.new(2), Q.new(4), Q.new(6), Q.new(4)]
	check_eq(S.rule_q(ys, Q.new(10)).text(), "130")
	check_eq(S.rule_q(ys, Q.new(10), 2, 2).text(), "160")
	var d := {"ys": ys, "h": Q.new(10), "n": 3}
	var vals: Array = S.data_slips(d)
	check_eq(vals[4].text(), "260")
	# The x-values 0, 10, 20, 30 as heights: 5 × (0 + 30 + 2 × 30) = 450.
	check_eq(vals[1].text(), "450")


func test_a_missing_height_by_hand() -> void:
	# Widths 3, k = 5, 4 every 4 m: area 2 × (3 + 4 + 10) = 34. With k inner, weight one gives 10,
	# and leaving out h/2 gives (34 − 7)/2 = 13.5.
	var s := {"ys": [Q.new(3), Q.new(5), Q.new(4)], "h": Q.new(4), "n": 2, "j": 1}
	var vals: Array = S.missing_slips(s)
	check_eq(vals.map(func(v): return Fmt.dec(v)), ["5", "10", "13.5"])
	# k at the end: 34 = 2(3 + 2 × 5 + k) gives k = 4; doubled as an end it is 2.
	s.j = 2
	vals = S.missing_slips(s)
	check_eq(Fmt.dec(vals[0]), "4")
	check_eq(Fmt.dec(vals[2]), "2")


func test_bends_and_how_functions_are_written() -> void:
	check_eq(S.bend({"fam": "sqrt", "m": Q.new(2), "c": Q.new(1)}, 0.0, 3.0), "down")
	check_eq(S.bend({"fam": "exp", "m": Q.new(3), "k": Q.new(-1, 5)}, 0.0, 3.0), "up")
	check_eq(S.bend({"fam": "recip", "m": Q.new(12), "c": Q.new(2)}, 0.0, 3.0), "up")
	check_eq(S.bend({"fam": "line", "co": [Q.new(2), Q.new(1)]}, 0.0, 3.0), "line")
	check_eq(S.slope({"fam": "exp", "m": Q.new(3), "k": Q.new(-1, 5)}, 0.0, 3.0), "falls")
	check_eq(V.f_text({"fam": "quad", "co": [Q.new(1, 2), Q.new(-2), Q.new(3)]}), "0.5x² − 2x + 3")
	check_eq(V.f_text({"fam": "sqrt", "m": Q.new(2), "c": Q.new(3)}), "2√(x + 3)")
	check_eq(V.f_text({"fam": "exp", "m": Q.new(3), "k": Q.new(-2, 5)}), "3e^(−0.4x)")
	check_eq(V.f_text({"fam": "recip", "m": Q.new(12), "c": Q.new(0)}), "12/x")
