extends "res://tests/test_case.gd"
## The reading pass on fn-discriminant (quadratic-parameter) and
## fn-curve-intersection-quadratic (curve-and-line), FAL-1055 / GitHub #193: each test
## pins one fixed finding, over seeds 1..30 and every cell of the unknown it is about.

const DISC := "fn-discriminant"
const CL := "fn-curve-intersection-quadratic"
const SEEDS := 30


func _cells(type: String, unknown: String) -> Array:
	return QuestionEngine.cells(false, [type]).filter(func(c): return c.unknown == unknown)


## Every question of an unknown, for each cell, seed and paper the cell has.
func _each(type: String, unknown: String, format: String = "mcq") -> Array:
	var out: Array = []
	for c in _cells(type, unknown):
		for paper in [1, 2]:
			for seed in range(1, SEEDS + 1):
				var q := QuestionEngine.make({"type": type, "unknown": unknown, "rep": c.rep, "angle": c.angle, "seed": seed,
					"format": format, "paper": paper})
				if q.has("error"):
					break
				if paper == 2 and q.paper != 2:
					break
				out.append(q)
	return out


func _texts(q: Dictionary) -> Array:
	var out: Array = [q.prompt]
	for sol in q.solutions:
		for st in sol.steps:
			out.append(Step.text(st))
	return out


func _qk(v: Variant) -> Q:
	var s := str(v)
	if s.contains("/"):
		var p := s.split("/")
		return Q.new(int(p[0]), int(p[1]))
	return Q.new(int(s))


func _no_equal_options(q: Dictionary, label: String) -> void:
	var seen := {}
	for o in q.choices:
		check(not seen.has(o.text), "%s: two options read %s" % [label, o.text])
		seen[o.text] = true
	check_eq(q.choices.filter(func(o): return o.correct).size(), 1, label + ": one correct option")


# ── fn-discriminant ──────────────────────────────────────────

## k-for-equal-roots: the options were all fillers round the key. b² + 4ac = 0 solved for
## k is now a named slip (SL2.7.discriminant#2), and each such option really is that.
func test_equal_roots_offers_the_plus_4ac_slip() -> void:
	var named := 0
	for q in _each(DISC, "k-for-equal-roots"):
		var label := "%s seed %d" % [q.cell, q.view.seed]
		_no_equal_options(q, label)
		var g: Dictionary = q.given
		var a0 := _qk(g.get("a0", "1"))
		var b0 := _qk(g.get("b0", "0"))
		var b1 := _qk(g.get("b1", "0"))
		var c0 := _qk(g.get("c0", "0"))
		var c1 := _qk(g.get("c1", "0"))
		for o in q.choices.filter(func(o): return o.ref == "SL2.7.discriminant#2"):
			named += 1
			check(not o.correct, label + ": the slip is the key")
			var ks: Array = [o.values.v] if o.values.has("v") else [o.values.r1, o.values.r2]
			for k in ks:
				var b := b0.add(b1.mul(k))
				var c := c0.add(c1.mul(k))
				check(b.sq().add(a0.mul(c).mul(4)).is_zero(), "%s: %s is not a zero of b² + 4ac" % [label, o.text])
				check(not b.sq().sub(a0.mul(c).mul(4)).is_zero(), "%s: %s is a zero of Δ" % [label, o.text])
	check(named >= 20, "only %d k-for-equal-roots questions carry the b² + 4ac slip" % named)


## The 4 forgotten in b² − 4ac (fn-discriminant#12): b² − ac = 0 solved for k, never
## sharing a value with the key, and it gives the two-value cells a named wrong too.
func test_equal_roots_offers_the_forgotten_4_slip() -> void:
	var two := 0
	for q in _each(DISC, "k-for-equal-roots"):
		var label := "%s seed %d" % [q.cell, q.view.seed]
		var g: Dictionary = q.given
		var a0 := _qk(g.get("a0", "1"))
		var key: Array = [q.answer.values.v] if q.answer.values.has("v") else [q.answer.values.r1, q.answer.values.r2]
		for o in q.choices.filter(func(o): return o.ref == "fn-discriminant#12"):
			var ks: Array = [o.values.v] if o.values.has("v") else [o.values.r1, o.values.r2]
			if ks.size() == 2:
				two += 1
			for k in ks:
				var b := _qk(g.get("b0", "0")).add(_qk(g.get("b1", "0")).mul(k))
				var c := _qk(g.get("c0", "0")).add(_qk(g.get("c1", "0")).mul(k))
				check(b.sq().sub(a0.mul(c)).is_zero(), "%s: %s is not a zero of b² − ac" % [label, o.text])
				check(not key.any(func(x): return x.eq(k)), "%s: %s shares a value with the key" % [label, o.text])
	check(two >= 10, "only %d two-value questions carry the forgotten-4 slip" % two)


## The wording of the interval steps: the condition is an inequality, and Δ = 0 is only
## its boundary; a linear Δ names the region the condition asks for.
func test_interval_steps_set_the_boundary_not_the_condition() -> void:
	for u in ["k-interval", "always-positive"]:
		for q in _each(DISC, u, "value"):
			for t in _texts(q):
				for bad in ["Δ > 0: ", "Δ < 0: ", "Δ ≥ 0: "]:
					check(not t.begins_with(bad), "%s seed %d: %s" % [q.cell, q.view.seed, t])
				if t.contains("is a straight line in k"):
					var cond: String = q.given.cond
					var want: String = {"two": "positive", "none": "negative", "real": "positive or zero"}[cond]
					check(t.contains("so it is %s for k" % want), "%s seed %d (%s): %s" % [q.cell, q.view.seed, cond, t])


## delta-in-k only computes Δ, so its method name doesn't say "solve for k".
func test_delta_in_k_method_name_matches_its_steps() -> void:
	for q in _each(DISC, "delta-in-k", "value"):
		check(not q.prompt.contains("solve for k"), q.prompt)
		check(q.prompt.contains("Compute Δ"), q.prompt)


## A critical value of 0 gives the factor k, not (k + 0).
func test_no_k_plus_zero_factor() -> void:
	for u in ["k-for-equal-roots", "k-interval", "always-positive", "same-sign-roots"]:
		for q in _each(DISC, u, "value"):
			for t in _texts(q):
				check(not (t.contains("(k + 0)") or t.contains("(k − 0)")), "%s seed %d: %s" % [q.cell, q.view.seed, t])


## test-point tests one k in every region and gives each its sign.
func test_test_point_tests_every_region() -> void:
	for u in ["k-interval", "same-sign-roots"]:
		for q in _each(DISC, u, "value"):
			var sol: Dictionary = q.solutions.filter(func(x): return x.angle == "test-point")[0]
			var t := " ".join(sol.steps.map(func(st): return Step.text(st)))
			var regions := 3
			if u == "k-interval" and q.answer.kind == "bound":
				regions = 2
			check(t.count("Test k = ") + t.count("; k = ") >= regions, "%s seed %d: %s" % [q.cell, q.view.seed, t])


## IB command terms on the graph-and-sign prompts.
func test_sign_prompts_use_command_terms() -> void:
	for q in _each(DISC, "delta-sign-from-graph"):
		check(q.prompt.begins_with("Write down the sign of a and the sign of the discriminant Δ."), q.prompt)
	for q in _each(DISC, "graph-from-delta"):
		check(q.prompt.begins_with("State which description fits the graph of y = ax² + bx + c."), q.prompt)


# ── fn-curve-intersection-quadratic ──────────────────────────

## The Δy-unsquared chord slip is given in simplest form, as the key is.
func test_chord_slip_is_in_simplest_form() -> void:
	var seen := 0
	for q in _each(CL, "chord-length"):
		_no_equal_options(q, "%s seed %d" % [q.cell, q.view.seed])
		for o in q.choices.filter(func(o): return o.ref == CL + "#12"):
			seen += 1
			var m: int = o.values.m.n
			var r: int = o.values.r.n
			check_eq(CurveLineViews.simplify_surd(m, r), [m, r], "%s seed %d: %s" % [q.cell, q.view.seed, o.text])
	check(seen > 0, "no chord question shows the slip")


## Meeting x: no option is a repeated root (the sketch shows two points), and four
## distinct options even when the roots are ±x.
func test_meeting_x_options_are_two_distinct_roots() -> void:
	var opposite := 0
	for q in _each(CL, "meeting-x"):
		var label := "%s seed %d" % [q.cell, q.view.seed]
		_no_equal_options(q, label)
		check_eq(q.choices.size(), 4, label)
		for o in q.choices:
			check(not o.values.r1.eq(o.values.r2), "%s: %s" % [label, o.text])
		if q.answer.values.r1.eq(q.answer.values.r2.neg()):
			opposite += 1
	check(opposite > 0, "no meeting-x question with roots ±x")


func test_count_from_sketch_uses_command_terms() -> void:
	for q in _each(CL, "count-from-sketch"):
		check(q.prompt.begins_with("Write down the number of points where the line meets the curve. Use the discriminant to confirm your answer."), q.prompt)


## The line through two points: no doubled minus, the gradient bracketed, n named.
func test_line_from_points_step_reads_cleanly() -> void:
	for q in _each(CL, "line-from-meeting-points", "value"):
		for t in _texts(q):
			check(not t.contains("− −") and not t.contains("+ −"), "%s seed %d: %s" % [q.cell, q.view.seed, t])
		check(" ".join(_texts(q)).contains("y = mx + n"), "%s seed %d: n is never defined" % [q.cell, q.view.seed])


## Completing the square with the midpoint at 0.
func test_chord_complete_square_at_zero() -> void:
	for q in _each(CL, "chord-length", "value"):
		for t in _texts(q):
			check(not t.contains("(x)²") and not t.contains("= 0 ±"), "%s seed %d: %s" % [q.cell, q.view.seed, t])


## equate-to-quadratic rearranges; it doesn't solve.
func test_equate_to_quadratic_method_name() -> void:
	for q in _each(CL, "equate-to-quadratic", "value"):
		if q.view.angle == "equate-and-solve":
			check(not q.prompt.contains("and solve"), q.prompt)


## normal-meets-again by factorising equates the curve and the normal first.
func test_normal_factorise_equates_first() -> void:
	for q in _each(CL, "normal-meets-again", "value"):
		var sol: Dictionary = q.solutions.filter(func(x): return x.angle == "factorise")[0]
		check(Step.text(sol.steps[0]).begins_with("Where they meet"), Step.text(sol.steps[0]))
