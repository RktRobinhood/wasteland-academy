extends "res://tests/test_case.gd"
## The Rational functions region (FAL-423): its two exam types, and the extension type
## fn-ext-transformed-reciprocal built so far, are built with every
## catalogue cell on the `rational-function` situation, their distractor misconceptions show
## up as options, the graphs have a gap at each vertical asymptote, and the answers mark the
## way a student would give them. The SymPy checker (tools/check-answers) checks the maths.

## Cells per type: the catalogue lists the method gdc-table twice for asymptotes-from-table
## (under two skills), and the engine counts it once, so the first type has 38.
const CELLS := {"fn-rational-asymptotes-intercepts": 38, "fn-rational-sketch": 40, "fn-ext-transformed-reciprocal": 12}
const SITUATION := "rational-function"
## Distractor misconceptions no option can carry yet ("type|ref"), and why.
const NOT_BUILT := {}


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
			for seed in [1, 2, 3, 4]:
				var q := _make(t, c.unknown, c.rep, c.angle, seed)
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, SITUATION, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.solutions[0].angle, c.angle, c.key + ": the asked method comes first")
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
					check(q.answer_text in Step.text(sol.steps[sol.steps.size() - 1]), "%s: the last step doesn't state the answer" % c.key)
				if c.rep == "graph":
					check(q.graph != null or q.format == "pick-the-graph", c.key + ": no graph")
				if c.rep == "table":
					check(q.table != null or q.format == "pick-the-graph", c.key + ": no table")


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


func test_paper_2_numbers_need_a_calculator() -> void:
	var seen := 0
	for unknown in ["va-from-equation", "ha-from-equation", "x-intercept", "y-intercept"]:
		for seed in range(1, 40):
			var q := QuestionEngine.make({"type": "fn-rational-asymptotes-intercepts", "unknown": unknown, "rep": "equation",
				"angle": QuestionEngine.angles_for(QuestionEngine.type_of("fn-rational-asymptotes-intercepts"), unknown)[0], "seed": seed, "paper": 2})
			check_eq(q.paper, 2, unknown)
			check(q.answer.get("show", "") == "sf", "%s: a Paper 2 answer is to 3 s.f." % unknown)
			seen += 1
			# Paper 2 offers the rounding trap.
			check(q.choices.any(func(o): return o.get("trap", false)), "%s seed %d: no rounding trap" % [unknown, seed])
	check(seen > 0, "no Paper 2 questions")


func test_paper_1_numbers_are_exact() -> void:
	for unknown in ["va-from-equation", "ha-from-equation", "x-intercept", "y-intercept"]:
		for seed in range(1, 40):
			var q := QuestionEngine.make({"type": "fn-rational-asymptotes-intercepts", "unknown": unknown, "rep": "equation",
				"angle": QuestionEngine.angles_for(QuestionEngine.type_of("fn-rational-asymptotes-intercepts"), unknown)[0], "seed": seed, "paper": 1})
			check_eq(q.paper, 1, unknown)
			check(q.answer.get("exact", false), "%s: a Paper 1 answer is exact" % unknown)


func test_a_graph_has_a_gap_at_the_vertical_asymptote() -> void:
	for t in [[2.0, 3.0, 1.0], [-1.0, 2.0, -3.0], [1.0, -4.0, 0.0], [3.0, 1.0, 2.5]]:
		var curves := RationalCards.branches(t)
		check_eq(curves.size(), 2, "two branches %s" % str(t))
		var left_end: float = curves[0][curves[0].size() - 1][0]
		var right_start: float = curves[1][0][0]
		check(left_end < t[2] and right_start > t[2], "the branches stay on their sides of x = %s" % str(t[2]))
		var across := RationalCards.branches(t, true)
		check_eq(across.size(), 1, "the wrong card is one curve")
		for c in curves:
			for p in c:
				check(absf(p[1] - RationalCards.y_at(t, p[0])) < 1e-9, "points are on the curve")
				check(p[1] >= RationalCards.WIN[2] and p[1] <= RationalCards.WIN[3], "points are inside the plot")


func test_the_four_graphs_of_a_pick_are_different() -> void:
	for unknown in ["sketch-from-equation", "sketch-from-transformed", "reciprocal-of-f"]:
		for seed in range(1, 30):
			var c: Dictionary = QuestionEngine.cells(false, ["fn-rational-sketch"]).filter(func(x): return x.unknown == unknown)[0]
			var q := _make("fn-rational-sketch", unknown, c.rep, c.angle, seed)
			check_eq(q.format, "pick-the-graph", unknown)
			check_eq(q.graphs.size(), 4, unknown)
			var seen := {}
			for g in q.graphs:
				seen[str(g.curves)] = true
			check_eq(seen.size(), 4, "%s seed %d: two graphs are the same" % [unknown, seed])


func test_an_asymptote_is_typed_as_an_equation() -> void:
	var q := _first("fn-rational-asymptotes-intercepts", "va-from-equation")
	var typed := {"var": "x", "h": (q.answer.values.h as Q).key()}
	check(QuestionEngine.mark(q, typed).correct, q.answer_text)
	typed.var = "y"
	check(not QuestionEngine.mark(q, typed).correct, "the other axis is wrong")


func test_the_x_intercept_is_typed_as_a_point() -> void:
	var q := _first("fn-rational-asymptotes-intercepts", "x-intercept")
	check(q.answer_text.ends_with(", 0)"), q.answer_text)
	check(QuestionEngine.mark(q, {"x": (q.answer.values.x as Q).key()}).correct, q.answer_text)


func test_splitting_a_fraction_offers_error_spot() -> void:
	var seen := 0
	for c in QuestionEngine.cells(false, ["fn-ext-transformed-reciprocal"]):
		var fs := QuestionEngine.extra_formats("fn-ext-transformed-reciprocal", c.unknown, c.angle)
		if c.unknown == "split-to-form":
			check(fs.has("error-spot"), c.key)
			var q := _make("fn-ext-transformed-reciprocal", c.unknown, c.rep, c.angle, 5, "error-spot")
			check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
			if not q.has("error"):
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.format, "error-spot", c.key)
				seen += 1
		else:
			check(fs.is_empty(), c.key)
	check(seen > 0, "no error-spot question was made")


func test_the_scaled_split_has_whole_numbers() -> void:
	for seed in range(1, 40):
		var q := _make("fn-ext-transformed-reciprocal", "split-scaled", "equation", "split-numerator", seed)
		check(not q.has("error"), "seed %d" % seed)
		var v: Dictionary = q.answer.values
		check((v.v0 as Q).is_int() and (v.v1 as Q).is_int(), "A and k are whole: " + q.answer_text)


# ── fn-pre-algebraic-fractions ───────────────────────────────

func test_algebraic_fractions_are_built_with_every_cell() -> void:
	var t := "fn-pre-algebraic-fractions"
	check(t in QuestionEngine.built_types(), "%s is not built" % t)
	check_eq(QuestionEngine.cells(false, [t]).size(), 10, t)
	for c in QuestionEngine.cells(false, [t]):
		for seed in [1, 2, 3, 4]:
			var q := _make(t, c.unknown, c.rep, c.angle, seed)
			check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
			if q.has("error"):
				break
			check_eq(q.situation_id, t, c.key)
			check_eq(q.choices.size(), 4, c.key)
			check_eq(q.solutions[0].angle, c.angle, c.key + ": the asked method comes first")
			for sol in q.solutions:
				check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
				check(q.answer_text in Step.text(sol.steps[sol.steps.size() - 1]), "%s: the last step doesn't state the answer" % c.key)


func test_an_equation_is_solved_by_typing_a_number() -> void:
	var q := _make("fn-pre-algebraic-fractions", "clear-and-solve", "equation", "multiply-through", 3)
	check(QuestionEngine.mark(q, {"v": (q.answer.values.v as Q).key()}).correct, q.answer_text)
	check(not QuestionEngine.mark(q, {"v": (q.answer.values.v as Q).add(1).key()}).correct, "another x is wrong")


func test_clearing_an_equation_offers_error_spot() -> void:
	var t := "fn-pre-algebraic-fractions"
	var made := 0
	for c in QuestionEngine.cells(false, [t]).filter(func(x): return x.unknown == "clear-and-solve"):
		check(QuestionEngine.extra_formats(t, c.unknown, c.angle).has("error-spot"), c.key)
		var q := _make(t, c.unknown, c.rep, c.angle, 4, "error-spot")
		check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
		if not q.has("error"):
			check_eq(q.choices.size(), 4, c.key)
			made += 1
	check(made > 0, "no error-spot question")


func test_every_slip_of_algebraic_fractions_is_an_option() -> void:
	var t := "fn-pre-algebraic-fractions"
	var ty := QuestionEngine.type_of(t)
	for i in ty.misconceptions.size():
		var m: Dictionary = ty.misconceptions[i]
		if m.as != "distractor":
			continue
		var ref := "%s#%d" % [t, i]
		for u in m.in:
			var found := false
			for c in QuestionEngine.cells(false, [t]).filter(func(x): return x.unknown == u):
				for seed in range(1, 80):
					var q := _make(t, u, c.rep, c.angle, seed, "mcq")
					if q.choices.any(func(o): return o.ref == ref):
						found = true
						break
				if found:
					break
			check(found, "%s never offers %s" % [u, ref])


# ── fn-concept-asymptote-meaning ─────────────────────────────

func test_the_asymptote_gallery_is_built_and_plays_true_false_reason() -> void:
	var t := "fn-concept-asymptote-meaning"
	check(t in QuestionEngine.built_types(), "%s is not built" % t)
	check_eq(QuestionEngine.cells(false, [t]).size(), 18, t)
	var tf := 0
	for c in QuestionEngine.cells(false, [t]):
		for seed in [1, 2, 3, 4]:
			var q := _make(t, c.unknown, c.rep, c.angle, seed)
			check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
			if q.has("error"):
				break
			check_eq(q.situation_id, "rational-asymptote-gallery", c.key)
			check_eq(q.choices.size(), 4, c.key)
			check_eq(q.solutions[0].angle, c.angle, c.key + ": the asked method comes first")
			for sol in q.solutions:
				check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
				check(q.answer_text in Step.text(sol.steps[sol.steps.size() - 1]), "%s: the last step doesn't state the answer" % c.key)
		if QuestionEngine.extra_formats(t, c.unknown, c.angle).has("true-false-reason"):
			var q := _make(t, c.unknown, c.rep, c.angle, 5, "true-false-reason")
			check(not q.has("error") and q.format == "true-false-reason", "%s as true-false-reason: %s" % [c.key, q.get("error")])
			tf += 1
	check(tf > 0, "true-false-reason is offered")


func test_every_slip_of_the_gallery_is_an_option() -> void:
	var t := "fn-concept-asymptote-meaning"
	var ty := QuestionEngine.type_of(t)
	for i in ty.misconceptions.size():
		var m: Dictionary = ty.misconceptions[i]
		if m.as != "distractor":
			continue
		for u in m.in:
			var found := false
			for c in QuestionEngine.cells(false, [t]).filter(func(x): return x.unknown == u):
				for seed in range(1, 80):
					var q := _make(t, u, c.rep, c.angle, seed, "mcq")
					if q.choices.any(func(o): return o.ref == m.ref):
						found = true
						break
				if found:
					break
			check(found, "%s never offers %s" % [u, m.ref])


# ── fn-ext-rational-model ────────────────────────────────────

func test_the_rational_model_is_built_with_every_cell() -> void:
	var t := "fn-ext-rational-model"
	check(t in QuestionEngine.built_types(), "%s is not built" % t)
	check_eq(QuestionEngine.cells(false, [t]).size(), 25, t)
	for c in QuestionEngine.cells(false, [t]):
		for seed in [1, 2, 3, 4]:
			var q := _make(t, c.unknown, c.rep, c.angle, seed)
			check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
			if q.has("error"):
				break
			check_eq(q.situation_id, "rational-model", c.key)
			check_eq(q.choices.size(), 4, c.key)
			check_eq(q.solutions[0].angle, c.angle, c.key + ": the asked method comes first")
			for sol in q.solutions:
				check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
				check(q.answer_text in Step.text(sol.steps[sol.steps.size() - 1]), "%s: the last step doesn't state the answer" % c.key)
			if c.rep == "graph":
				check(q.graph != null, c.key + ": no graph")
			if c.rep == "table":
				check(q.table != null, c.key + ": no table")


func test_every_slip_of_the_rational_model_is_an_option() -> void:
	var t := "fn-ext-rational-model"
	var ty := QuestionEngine.type_of(t)
	for i in ty.misconceptions.size():
		var m: Dictionary = ty.misconceptions[i]
		if m.as != "distractor":
			continue
		for u in m["in"]:
			var found := false
			for c in QuestionEngine.cells(false, [t]).filter(func(x): return x.unknown == u):
				for seed in range(1, 80):
					var q := _make(t, u, c.rep, c.angle, seed, "mcq")
					if q.choices.any(func(o): return o.ref == m.ref):
						found = true
						break
				if found:
					break
			check(found, "%s never offers %s" % [u, m.ref])


func test_the_least_whole_number_rounds_up() -> void:
	for seed in range(1, 30):
		var q := _make("fn-ext-rational-model", "least-n-for-target", "equation", "solve-algebraically", seed)
		var s: Dictionary = q.situation
		check(str(s.nstar).contains("/"), "the exact input is not whole")
		var typed := {"v": Q.new(int(s.n)).key()}
		check(QuestionEngine.mark(q, typed).correct, "n = %s is right" % str(s.n))
		var down := {"v": Q.new(int(s.n) - 1).key()}
		check(not QuestionEngine.mark(q, down).correct, "rounding down is wrong")
