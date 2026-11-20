extends "res://tests/test_case.gd"
## The reading pass on quadratic-equation and quadratic-inequality (FAL-1055, GitHub
## #193): the graph of an inequality-from-solution is the parabola through its roots,
## fillers don't cluster round the key where a slip exists, and the worked steps and
## method names say what they do.

const SEQ := "fn-solve-quadratic"
const INEQ := "fn-quadratic-inequality"
const SEEDS := 30


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format, "paper": paper})


## Every cell of `unknown`, on each paper it can be asked on.
func _views(type: String, unknown: String) -> Array:
	var out: Array = []
	for c in QuestionEngine.cells(false, [type]):
		if c.unknown != unknown:
			continue
		for paper in QuestionEngine.cell_papers(QuestionEngine.type_of(type), c.unknown, c.rep, c.angle):
			out.append({"rep": c.rep, "angle": c.angle, "paper": paper, "key": "%s p%d" % [c.key, paper]})
	check(not out.is_empty(), "%s has no cells" % unknown)
	return out


## A Q or its key ("−3", "1/2") as a float.
static func fv(v: Variant) -> float:
	if v is Q:
		return v.to_float()
	var parts := str(v).split("/")
	return parts[0].to_float() / (parts[1].to_float() if parts.size() > 1 else 1.0)


func _solution(q: Dictionary, angle: String) -> Dictionary:
	for s in q.solutions:
		if s.angle == angle:
			return s
	return {}


## The graph's parabola a(x − h)² + k: its vertex k is (h − p)(h − q) and it crosses
## the x-axis at both marked roots (the old k was the parabola's before a was reset to 1).
func test_inequality_from_solution_graph_is_the_parabola_through_the_roots() -> void:
	var graphs := 0
	for v in _views(INEQ, "inequality-from-solution"):
		if v.rep != "graph":
			continue
		for seed in range(1, SEEDS + 1):
			for format in ["mcq", "value"]:
				var q := _make(INEQ, "inequality-from-solution", v.rep, v.angle, seed, format, v.paper)
				check(not q.has("error"), "%s seed %d: %s" % [v.key, seed, q.get("error")])
				if q.has("error") or q.graph == null:
					continue
				graphs += 1
				var g: Dictionary = q.graph
				var p := fv(q.given.p)
				var r := fv(q.given.q)
				var h: float = g.h
				check(is_equal_approx(g.a, 1.0), "%s seed %d: a = %s" % [v.key, seed, g.a])
				check(is_equal_approx(h, (p + r) / 2.0), "%s seed %d: h = %s" % [v.key, seed, h])
				check(is_equal_approx(g.k, (h - p) * (h - r)), "%s seed %d: k = %s, want %s" % [v.key, seed, g.k, (h - p) * (h - r)])
				for x in [p, r]:
					var y: float = g.a * (x - h) * (x - h) + g.k
					check(is_zero_approx(y), "%s seed %d: the curve is at y = %s at x = %s, not on the axis" % [v.key, seed, y, x])
				# The curve is the answer's x² + bx + c.
				var b := fv(q.answer.values.b)
				var c := fv(q.answer.values.c)
				check(is_equal_approx(g.k, c - b * b / 4.0), "%s seed %d: k is not the answer's vertex" % [v.key, seed])
				check(absf(g.k) <= QuadraticSituation.GRAPH_Y_MAX and absf(c) <= QuadraticSituation.GRAPH_Y_MAX, "%s seed %d: off the graph" % [v.key, seed])
	check(graphs >= SEEDS, "only %d graphs" % graphs)


func _filler_values(q: Dictionary) -> Array:
	return q.choices.filter(func(o): return not o.correct and o.get("src", "") in ["fillers", "nudge", "generic"]).map(func(o): return fv(o.values.v))


func _ref_value(q: Dictionary, ref: String) -> Variant:
	for o in q.choices:
		if o.ref == ref:
			return fv(o.values.v)
	return null


## Twice the root is the "forgot ÷ 2a" slip, named; no filler sits at key ± 1 or × 2.
func test_solve_in_context_doubling_is_a_named_slip() -> void:
	var named := 0
	for v in _views(SEQ, "solve-in-context"):
		for seed in range(1, SEEDS + 1):
			var q := _make(SEQ, "solve-in-context", v.rep, v.angle, seed, "mcq", v.paper)
			if q.has("error"):
				fail("%s seed %d: %s" % [v.key, seed, q.error])
				continue
			var key := fv(q.answer.values.v)
			for f in _filler_values(q):
				for near in [key + 1.0, key - 1.0, key * 2.0, key + 2.0]:
					check(absf(f - near) > 1e-6, "%s seed %d: filler %s clusters round the key %s" % [v.key, seed, f, key])
			var twice: Variant = _ref_value(q, QuadraticEquationViews.R_NO_DIVIDE)
			if twice != null:
				named += 1
				check(is_equal_approx(twice, key * 2.0), "%s seed %d: the ÷ 2a slip is %s" % [v.key, seed, twice])
	check(named > 0, "the ÷ 2a slip never shows")


## The largest n: no option below the key (the old filler n − 1), and a filler within 2
## of the key only when fewer than two of the slip values are further off.
func test_largest_integer_fillers_are_slips_not_neighbours() -> void:
	var checked := 0
	for v in _views(INEQ, "largest-integer"):
		for seed in range(1, SEEDS + 1):
			var q := _make(INEQ, "largest-integer", v.rep, v.angle, seed, "mcq", v.paper)
			if q.has("error"):
				fail("%s seed %d: %s" % [v.key, seed, q.error])
				continue
			var best := fv(q.answer.values.v)
			var t := fv(q.given.T)
			var d := fv(q.given.d)
			var far := {}
			for x in [floorf(sqrt(t)), floorf(t / (d + 1.0)), floorf(t / d), best + d]:
				if absf(x - best) > 2.0:
					far[x] = true
			if far.size() < 2:
				continue
			checked += 1
			for o in q.choices:
				check(fv(o.values.v) >= best, "%s seed %d: option %s is below n = %s" % [v.key, seed, o.text, best])
			for f in _filler_values(q):
				check(absf(f - best) > 2.0, "%s seed %d: filler %s next to n = %s" % [v.key, seed, f, best])
	check(checked >= SEEDS, "only %d questions checked" % checked)


## Whole-number roots: the steps write the factors and expand, and the method is named so.
func test_equation_from_integer_roots_uses_factors() -> void:
	var seen := 0
	for v in _views(SEQ, "equation-from-roots"):
		for seed in range(1, SEEDS + 1):
			var q := _make(SEQ, "equation-from-roots", v.rep, v.angle, seed, "mcq", v.paper)
			if q.has("error"):
				fail("%s seed %d: %s" % [v.key, seed, q.error])
				continue
			var sol := _solution(q, v.angle)
			if q.situation.mode != "rational":
				check_eq(sol.name, "Complete the square and square-root", "%s seed %d" % [v.key, seed])
				continue
			seen += 1
			check_eq(sol.name, "Write the factors and expand", "%s seed %d" % [v.key, seed])
			var steps := " | ".join(sol.steps.map(func(x): return Step.text(x)))
			check(not steps.contains("±") and not steps.contains("Square both sides"), "%s seed %d: %s" % [v.key, seed, steps])
			check(steps.contains("gives a factor"), "%s seed %d: %s" % [v.key, seed, steps])
			var b := fv(q.answer.values.B)
			var c := fv(q.answer.values.C)
			for o in q.choices:
				if not o.correct:
					check(not (is_equal_approx(fv(o.values.B), b) and is_equal_approx(fv(o.values.C), c + 1.0)), "%s seed %d: c + 1 filler" % [v.key, seed])
	check(seen > 0, "no whole-number roots in %d seeds" % SEEDS)


## "1k" and "(−1)k" are written k and −k; the method says what the steps do.
func test_coefficient_from_root_reads_cleanly() -> void:
	var ones := 0
	for v in _views(SEQ, "coefficient-from-root"):
		for seed in range(1, SEEDS + 1):
			var q := _make(SEQ, "coefficient-from-root", v.rep, v.angle, seed, "mcq", v.paper)
			if q.has("error"):
				fail("%s seed %d: %s" % [v.key, seed, q.error])
				continue
			var sol := _solution(q, v.angle)
			check_eq(sol.name, "Substitute the root, then use the product of the roots", "%s seed %d" % [v.key, seed])
			var first := Step.text(sol.steps[0])
			check(not first.contains("1k") and not first.contains(")k"), "%s seed %d: %s" % [v.key, seed, first])
			var r := fv(q.given.root)
			if absf(r) == 1.0:
				ones += 1
				check(first.contains("² + k ") if r > 0 else first.contains("² − k "), "%s seed %d: %s" % [v.key, seed, first])
	check(ones > 0, "no root ±1 in %d seeds" % SEEDS)


func test_choose_substitution_final_step_reads_as_a_sentence() -> void:
	for v in _views(SEQ, "choose-substitution"):
		for seed in range(1, SEEDS + 1):
			var q := _make(SEQ, "choose-substitution", v.rep, v.angle, seed, "mcq", v.paper)
			var steps: Array = _solution(q, v.angle).steps
			var last := Step.text(steps[steps.size() - 1])
			check(last.begins_with("So, with u = ") and not last.contains("So With"), "%s seed %d: %s" % [v.key, seed, last])


## With 2a = ±1 there is no "√(1 × d)" step, and no wrong option is the answer in
## disguise; the b² + 4ac slip shows somewhere.
func test_solve_surd_with_unit_2a() -> void:
	var unit := 0
	var plus := 0
	for v in _views(SEQ, "solve-surd"):
		for seed in range(1, SEEDS * 2 + 1):
			var q := _make(SEQ, "solve-surd", v.rep, v.angle, seed, "mcq", v.paper)
			if q.has("error"):
				fail("%s seed %d: %s" % [v.key, seed, q.error])
				continue
			var steps := " | ".join(_solution(q, v.angle).steps.map(func(x): return Step.text(x)))
			check(not steps.contains("√(1 × "), "%s seed %d: %s" % [v.key, seed, steps])
			if absf(fv(q.situation.a)) == 0.5:
				unit += 1
			for o in q.choices:
				if o.ref == QuadraticEquationViews.R_PLUS_4AC:
					plus += 1
				if o.ref == QuadraticEquationViews.R_NO_2A:
					check(not is_equal_approx(fv(o.values.d), fv(q.answer.values.d)), "%s seed %d: the no-2a slip is the key's surd" % [v.key, seed])
	check(unit > 0, "no a = ±½ in %d seeds" % (SEEDS * 2))
	check(plus > 0, "the b² + 4ac slip never shows")


## The test-point steps test one point between the roots (or the whole numbers either
## side of the root), so the method name says that.
func test_test_point_names_match_the_steps() -> void:
	var names := {"solve-against-zero": "Test a point between the roots", "square-against-constant": "Test a point between the roots",
		"largest-integer": "Test the whole numbers either side of the root"}
	for u in names:
		for v in _views(INEQ, u):
			if v.angle != "test-point":
				continue
			for seed in range(1, 6):
				var q := _make(INEQ, u, v.rep, v.angle, seed, "mcq", v.paper)
				check_eq(_solution(q, "test-point").get("name", ""), names[u], "%s seed %d" % [v.key, seed])
