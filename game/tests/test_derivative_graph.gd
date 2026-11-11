extends "res://tests/test_case.gd"
## The derivative-graph situation (FAL-754): t5-derivative-graph is built with every cell and
## both skills, on Paper 1. Every feature drawn sits on a whole number, the areas given are
## the areas under the curve drawn, each question shows its figure, and every tag shows up
## as an option. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t5-derivative-graph"
const CELLS := 29


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _draw(ask: String, i: int) -> Dictionary:
	return DerivativeGraphSituation.generate(Seeded.new("%s|%d" % [ask, i]), {"ask": ask})


func test_the_type_is_built_with_every_cell_on_paper_1() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	var skills := {}
	for u in t.unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 2, "both skills have a question")
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [1], c.key)


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "derivative-graph", c.key)
				check_eq(q.paper, 1, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.solutions[0].angle, c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps in %s" % [c.key, sol.steps.size(), sol.name])


func test_the_sums_match_hand_values() -> void:
	# f′(x) = 2(x − 1)(x + 2)²: 2 × 1 × 16 at x = 2, and its other turning point is x = 0.
	var t := {"fam": "touch", "k": 2, "a": 1, "b": -2, "c": 0}
	check_eq(DerivativeGraphSituation.at(t, 2), 32)
	check_eq(DerivativeGraphSituation.slope(t, 0), 0)
	check_eq(DerivativeGraphSituation.slope(t, -2), 0)
	check_eq(DerivativeGraphSituation.slope(t, 1), 18)
	# The parabola 3(x − 1)(x − 3) turns at its vertex, x = 2.
	check_eq(DerivativeGraphSituation.slope({"fam": "quad", "k": 3, "a": 1, "b": 3}, 2), 0)


func test_the_features_are_whole_numbers() -> void:
	for i in 60:
		var s := _draw("inflexion-from-derivative", i)
		if s.fam == "touch":
			check_eq(absi(s.b - s.a), 3, "draw %d" % i)
			check_eq(DerivativeGraphSituation.slope(s, s.c), 0, "draw %d" % i)
		else:
			check_eq(DerivativeGraphSituation.slope(s, s.h), 0, "draw %d" % i)


## The areas given are the areas between the curve and the axis, by the trapezium rule.
func test_the_areas_are_the_areas_under_the_curve() -> void:
	for i in 40:
		var s := _draw("value-from-areas", i)
		check(not s.is_empty(), "draw %d" % i)
		var f := DerivativeGraphSituation.fn(s)
		for part in [[s.lo, s.m, s.A1, s.s1], [s.m, s.hi, s.A2, s.s2]]:
			var sum := 0.0
			var n := 2000
			var w := float(part[1] - part[0]) / n
			for j in n:
				var x0: float = part[0] + j * w
				sum += (f.call(x0) + f.call(x0 + w)) * w / 2.0
			check(absf(sum - part[3] * part[2]) < 1e-3, "draw %d: %f is not %d" % [i, sum, part[3] * part[2]])
		check(s.A1 != s.A2, "draw %d" % i)


func test_each_question_shows_its_figure() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var q := _make(c, 2)
		if c.rep == "graph":
			check(q.graph != null and not q.graph.curves.is_empty(), c.key + " has no figure")
		else:
			check(q.graph == null, c.key + " draws a figure it doesn't need")
		if c.unknown in ["compare-from-areas", "value-from-areas"] and c.rep == "graph":
			check_eq(q.graph.shade.size(), 2, c.key)
		if c.unknown == "pick-f-from-derivative":
			check_eq(q.graphs.size(), 4, c.key)


func test_every_tag_shows_up_as_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 16):
			var q := _make(c, seed)
			for o in q.choices:
				if o.ref != "":
					seen[o.ref] = true
	for m in t.misconceptions:
		check(seen.has(m.ref), "%s never shows" % m.ref)
