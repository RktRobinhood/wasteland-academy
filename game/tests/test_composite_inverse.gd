extends "res://tests/test_case.gd"
## The Composite and inverse region (FAL-422): its three exam types, and the one extension
## type built so far (fn-pre-rearrange), are built with every
## catalogue cell on their situations, their distractor misconceptions show up as options,
## and the region's answers mark the way a student would give them (an expression as a
## polynomial, a constant or a pair of them, an x-value, a function picked from four).
## The SymPy checker (tools/check-answers) checks the maths.

## Cells per type, counted as tools/pedagogy.mjs counts them.
const CELLS := {"fn-composite": 31, "fn-graph-table-composite-inverse": 75, "fn-inverse-algebraic": 63, "fn-pre-rearrange": 17}
const SITUATION := {"fn-composite": "composite-pair", "fn-graph-table-composite-inverse": "composite-graph-table",
	"fn-inverse-algebraic": "inverse-rule", "fn-pre-rearrange": "fn-pre-rearrange"}
## Distractor misconceptions no option can carry yet ("type|ref"), and why.
const NOT_BUILT := {
	"fn-composite|SL2.7.solve-equation#2": "only one k of a ± pair is a pair answer with one value, which no option can show",
	"fn-graph-table-composite-inverse|SL2.2.evaluate-notation#0": "f(3) = 6 read as f × 3 gives 2a: no whole-number option, because a graph or table has no f to divide out",
	"fn-graph-table-composite-inverse|SL2.3.read-graph#2": "a scale other than 1 unit per square is not drawn",
	"fn-inverse-algebraic|SL2.5.inverse-domain-range#2": "\"no restriction is needed\" is a sentence, and the restriction is asked as a number k",
	"fn-inverse-algebraic|SL2.8.rational-inverse#2": "\"no value works: only 1/x is its own inverse\" is a sentence, and the constant is asked as a number k",
}


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func _first(type: String, unknown: String, format: String = "value", seed: int = 1) -> Dictionary:
	var c: Dictionary = QuestionEngine.cells(false, [type]).filter(func(x): return x.unknown == unknown)[0]
	return _make(type, unknown, c.rep, c.angle, seed, format)


func test_the_types_are_built_with_every_cell() -> void:
	var built := QuestionEngine.built_types()
	for t in CELLS:
		check(t in built, "%s is not built" % t)
		check_eq(QuestionEngine.cells(false, [t]).size(), CELLS[t], t)


func test_every_cell_makes_a_question_on_its_situation() -> void:
	for t in CELLS:
		for c in QuestionEngine.cells(false, [t]):
			for seed in [1, 2, 3]:
				var q := _make(t, c.unknown, c.rep, c.angle, seed)
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, SITUATION[t], c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.solutions[0].angle, c.angle, c.key + ": the asked method comes first")
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
					check(q.answer_text in Step.text(sol.steps[sol.steps.size() - 1]), "%s: the last step doesn't state the answer" % c.key)
				if c.rep == "graph" and t != "fn-composite":
					check(q.graph != null, c.key + ": no graph")
				if c.rep == "table":
					check(q.table != null, c.key + ": no table")


func test_exam_types_offer_no_extra_format() -> void:
	for t in CELLS:
		if QuestionEngine.type_of(t).source != "exam":
			continue
		for c in QuestionEngine.cells(false, [t]):
			check(QuestionEngine.extra_formats(t, c.unknown, c.angle).is_empty(), c.key)


func test_rearranging_offers_error_spot_and_method_pick() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, ["fn-pre-rearrange"]):
		for f in QuestionEngine.extra_formats("fn-pre-rearrange", c.unknown, c.angle):
			seen[f] = true
			var q := _make("fn-pre-rearrange", c.unknown, c.rep, c.angle, 3, f)
			check(not q.has("error"), "%s as %s: %s" % [c.key, f, q.get("error")])
			if not q.has("error"):
				check_eq(q.choices.size(), 4, "%s as %s" % [c.key, f])
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, "%s as %s" % [c.key, f])
	check(seen.has("error-spot") and seen.has("method-pick"), "both extra formats are offered")


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
					for seed in range(1, 60):
						var q := _make(t, u, c.rep, c.angle, seed, "mcq")
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


func test_a_composite_is_typed_as_a_polynomial() -> void:
	var q := _first("fn-composite", "expression")
	var v: Dictionary = q.answer.values
	var typed := {}
	for k in v:
		typed[k] = (v[k] as Q).key()
	check(QuestionEngine.mark(q, typed).correct, q.answer_text)
	var wrong_typed := typed.duplicate()
	wrong_typed["c0"] = (v.c0 as Q).add(1).key()
	check(not QuestionEngine.mark(q, wrong_typed).correct, "the leading coefficient matters")


func test_a_parameter_pair_is_marked_in_either_order() -> void:
	var q := _first("fn-composite", "parameter-from-coefficients")
	var v: Dictionary = q.answer.values
	check(QuestionEngine.mark(q, {"r1": v.r1.key(), "r2": v.r2.key()}).correct)
	check(QuestionEngine.mark(q, {"r1": v.r2.key(), "r2": v.r1.key()}).correct, "k = ±n in either order")
	check(not QuestionEngine.mark(q, {"r1": v.r1.key(), "r2": v.r1.key()}).correct, "one value twice is not the pair")


func test_the_solutions_of_a_composite_equation_come_in_any_order() -> void:
	for seed in range(1, 40):
		var q := _make("fn-composite", "solve-composite", "equation", "substitute-whole", seed)
		var v: Dictionary = q.answer.values
		if int(str(v.n)) == 2:
			check(QuestionEngine.mark(q, {"x0": v.x1.key(), "x1": v.x0.key()}).correct, "x in either order")
			return
	fail("no two-solution composite equation in 40 seeds")


func test_a_function_is_picked_from_four() -> void:
	var q := _first("fn-inverse-algebraic", "inverse-linear", "mcq")
	check_eq(q.choices.filter(func(o): return o.correct)[0].text, q.answer_text)
	var typed := _first("fn-inverse-algebraic", "inverse-linear", "value")
	check(QuestionEngine.mark(typed, {"v": typed.answer_text}).correct, "the right option, picked")
	var other: String = typed.answer.fixed.options.filter(func(o): return o != typed.answer_text)[0]
	check(not QuestionEngine.mark(typed, {"v": other}).correct, "another option")


func test_a_reading_is_marked_exactly() -> void:
	var q := _first("fn-graph-table-composite-inverse", "read-value")
	var v: Q = q.answer.values.v
	check(QuestionEngine.mark(q, {"v": v.key()}).correct)
	check(not QuestionEngine.mark(q, {"v": v.add(1).key()}).correct)
	check_eq(q.paper, 1, "a graph or table reading is Paper 1")


func test_the_inverse_of_a_graph_is_read_by_swapping() -> void:
	for seed in range(1, 30):
		var q := _make("fn-graph-table-composite-inverse", "inverse-points", "graph", "swap-coordinates", seed)
		var v: Dictionary = q.answer.values
		var labelled: Array = q.graph.points.filter(func(p): return p.label != "")
		check_eq(labelled.size(), 2, "points A and B")
		for p in labelled:
			var found := false
			for j in 2:
				if int(v["x%d" % j].n) == int(p.y) and int(v["y%d" % j].n) == int(p.x):
					found = true
			check(found, "(%s, %s) swaps to a point of the answer" % [p.x, p.y])


func test_a_graph_that_turns_back_has_no_inverse_but_a_restriction() -> void:
	for seed in range(1, 20):
		var q := _make("fn-graph-table-composite-inverse", "restrict-from-graph", "graph", "horizontal-line", seed)
		var ys: Array = q.graph.points.map(func(p): return p.y)
		var xs: Array = q.graph.points.map(func(p): return p.x)
		var turn: int = xs[ys.find(ys.max() if ys[3] > ys[0] else ys.min())]
		check_eq(int(q.answer.values.v.n), turn, "the turning point")
