extends "res://tests/test_case.gd"
## The reading pass on the `gdc-two-curves` and `gdc-combined` situations (FAL-1055, GitHub
## #193): the defects a person found reading fn-gdc-intersection,
## fn-concept-solutions-as-intersections and fn-gdc-optimise-combined stay fixed.

const GI := "fn-gdc-intersection"
const CS := "fn-concept-solutions-as-intersections"
const CB := "fn-gdc-optimise-combined"
const SEEDS := 30


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


## Every question of an unknown's cells over the seeds, with no errors.
func _each(type: String, unknown: String, format: String = "mcq") -> Array:
	var out: Array = []
	for c in QuestionEngine.cells(false, [type]):
		if c.unknown != unknown:
			continue
		for seed in range(1, SEEDS + 1):
			var q := _make(type, unknown, c.rep, c.angle, seed, format)
			check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
			if not q.has("error"):
				q.cell_rep = c.rep
				out.append(q)
	return out


func _steps(sol: Dictionary) -> Array:
	return sol.steps.map(func(st): return Step.text(st))


func _all_steps(q: Dictionary) -> String:
	var out: Array = []
	for sol in q.solutions:
		out.append_array(_steps(sol))
	return " || ".join(out)


func _sol(q: Dictionary, angle: String) -> Array:
	for sol in q.solutions:
		if sol.angle == angle:
			return _steps(sol)
	return []


func _method_line(q: Dictionary) -> String:
	for line in q.prompt.split("\n"):
		if line.begins_with("Method: "):
			return line
	return ""


## A Q's key ("−3", "3/2", as ExtensionViews.export writes it) back to a Q.
static func _q(key: String) -> Q:
	var parts := key.split("/")
	return Q.new(int(parts[0]), int(parts[1]) if parts.size() > 1 else 1)


## The domain as the question writes it, from its exported situation.
static func _dom(q: Dictionary, v: String = "x") -> String:
	return "%s ≤ %s ≤ %s" % [Fmt.num(_q(str(q.situation.d1))), v, Fmt.num(_q(str(q.situation.d2)))]


func _opt(q: Dictionary, ref: String) -> Array:
	return q.choices.filter(func(o): return o.ref == ref)


# ── fn-concept-solutions-as-intersections ────────────────────

## "What are the solutions of 2cos(2x) + 1 = 1.5x − 2?" had no domain, so its two meeting
## points were not every solution (x = 3.28 too); the domain is in the prompt and the lines.
func test_x_not_y_states_the_domain_its_meeting_points_are_on() -> void:
	for fmt in ["mcq", "value"]:
		for q in _each(CS, "x-not-y", fmt):
			var d := _dom(q)
			check(q.asked.ends_with("for %s?" % d), "%s: %s" % [q.cell, q.asked])
			check(q.lines[0].contains("or %s, " % d), "%s: %s" % [q.cell, q.lines[0]])
			check_eq(q.situation.crossings.size(), 2, q.cell)


## The y-values given as the solutions are the y-coordinates read off (the type's #3), not
## "gives only the x-coordinate when coordinates are asked for" (SL2.4.intersection#0).
func test_x_not_y_reads_the_y_values_as_reading_off_y() -> void:
	var seen := 0
	for q in _each(CS, "x-not-y"):
		for o in q.choices:
			if o.text.begins_with("y = "):
				seen += 1
				check_eq(o.ref, CS + "#3", "%s: %s" % [q.cell, o.text])
			if o.text.begins_with("("):
				check_eq(o.ref, "SL2.4.intersection#0", "%s: %s" % [q.cell, o.text])
	check(seen > 0, "no y-values option")


## The filler "Graph y = 2cos(2x) − 1.5 − −x − 4" brackets the side it subtracts, and the
## equation states its domain, so the x-values the working lists are every solution.
func test_graphs_for_equation_brackets_the_subtracted_side_and_states_the_domain() -> void:
	var seen := 0
	for fmt in ["mcq", "value"]:
		for q in _each(CS, "graphs-for-equation", fmt):
			var f: String = q.lines[0].get_slice(" = ", 0)
			var g: String = q.lines[0].get_slice(" = ", 1).get_slice(", for ", 0)
			check(q.lines[0].ends_with(", for %s" % _dom(q)), "%s: %s" % [q.cell, q.lines[0]])
			for o in q.choices:
				check(not o.text.contains("− −") and not o.text.contains("+ −"), "%s: %s" % [q.cell, o.text])
				if o.text.contains("crosses y = 1"):
					seen += 1
					check_eq(o.text, "Graph y = %s − (%s), and read where it crosses y = 1." % [f, g], q.cell)
			var steps := _sol(q, "intersect-two-graphs")
			check(steps[0].contains("for %s" % _dom(q)), "%s: %s" % [q.cell, steps[0]])
	check(seen > 0, "no subtracted-graph filler")


## Equation B and the student's claim are judged on a stated domain, so the zeros listed are
## every solution; the words rep, with no equations A and B, never names them.
func test_same_solutions_states_the_domain_and_the_words_rep_names_no_a_or_b() -> void:
	var ab := RegEx.create_from_string("\\b(A|B)\\b|B's")
	for fmt in ["mcq", "value", "true-false-reason"]:
		for q in _each(CS, "same-solutions-after-rearranging", fmt):
			var d := _dom(q)
			if q.cell_rep == "words":
				check(q.lines[0].contains(", for %s.\"" % d), "%s: %s" % [q.cell, q.lines[0]])
				var texts: Array = q.choices.map(func(o): return o.text) + q.get("base_choices", []).map(func(o): return o.text) + [_all_steps(q), q.asked,
					q.get("reason", "")]
				for t in texts:
					check(ab.search(t) == null, "%s %s: %s" % [q.cell, fmt, t])
				check(q.answer_text.begins_with("Yes: the zeros solve "), q.answer_text)
			else:
				check(q.asked.begins_with("For %s, " % d), "%s: %s" % [q.cell, q.asked])
			for sol in q.solutions:
				var listed: Array = _steps(sol).filter(func(st): return st.contains("x = "))
				check(not listed.is_empty() and listed.all(func(st): return st.contains(d)), "%s: %s" % [q.cell, _steps(sol)])


## k-for-count's method said "turning-point values and asymptotes" for a cubic, which has no
## asymptote, and its last step named an f the question never defines.
func test_k_for_count_names_no_asymptote_and_no_f() -> void:
	for fmt in ["mcq", "value"]:
		for q in _each(CS, "k-for-count", fmt):
			check(not _method_line(q).contains("asymptote"), "%s: %s" % [q.cell, _method_line(q)])
			var cubic: String = q.asked.get_slice("does ", 1).get_slice(" = k", 0)
			for sol in q.solutions:
				var last: String = _steps(sol)[-1]
				check(last.begins_with("So %s = k has three solutions" % cubic), "%s: %s" % [q.cell, last])


# ── fn-gdc-intersection ──────────────────────────────────────

## "Find k, and the x-coordinate of the other point" asks on the domain (a cosine or a cubic
## meets the line again further out), and the words rep names the line with its k.
func test_constant_from_crossing_asks_on_the_domain_and_names_k() -> void:
	for fmt in ["mcq", "value"]:
		for q in _each(GI, "constant-from-crossing", fmt):
			var d := _dom(q)
			check(q.asked.ends_with("meets the curve for %s." % d), "%s: %s" % [q.cell, q.asked])
			check(RegEx.create_from_string("^The line y = .*x \\+ k ").search(q.lines[0]) != null, "%s: %s" % [q.cell, q.lines[0]])
			check(not q.lines[0].contains("gradient"), "%s: %s" % [q.cell, q.lines[0]])


## A cubic through the line's point at x = 0 has x as a factor: the working solves the
## quadratic left over, and of its two roots exactly one, the other crossing, is on the domain.
## It said "mixes families, so the GDC solves it".
func test_a_cubic_crossing_is_solved_by_factorising() -> void:
	var views := GdcTwoCurvesViews.new()
	var num := RegEx.create_from_string("x = (−?[\\d.]+) or x = (−?[\\d.]+) from the quadratic; only x = (−?[\\d.]+) is in")
	var cubics := 0
	for i in 200:
		var rng := Seeded.new("gdctwo-cubic|%d" % i)
		var s := GdcTwoCurvesSituation.generate(rng, {"mode": "line", "at0": true, "crossings": 2})
		var b := views.build("constant-from-crossing", "equation", s, rng)
		var step: String = Step.text(b.methods["equate-and-solve"].steps[1])
		if s.f.fam != "cubic":
			check(step.contains("mixes families"), step)
			continue
		cubics += 1
		check(not step.contains("mixes families"), step)
		check(step.contains(" gives x("), step)
		var m := num.search(step)
		check(m != null, step)
		if m == null:
			continue
		var other: float = s.crossings.filter(func(c): return absf(c[0]) > 1e-9)[0][0]
		var rs := [float(m.get_string(1).replace("−", "-")), float(m.get_string(2).replace("−", "-"))]
		check_eq(m.get_string(3), GdcKit.W(other), step)
		var lo: float = s.d1.to_float()
		var hi: float = s.d2.to_float()
		var inside: Array = rs.filter(func(r): return r >= lo and r <= hi)
		check_eq(inside.size(), 1, step)
		for r in rs:
			# Each root solves f = g, to the 6 s.f. written.
			check(absf(GdcTwoCurvesSituation.h(s, r)) < 1e-3 * maxf(1.0, absf(r)) * 10.0, "%s: f − g at %s is %s" % [step, r, GdcTwoCurvesSituation.h(s, r)])
	check(cubics >= 10, "only %d cubics" % cubics)


## The inverse of e^(bx) + c is written with a decimal shift, 1.25ln(x + 1.5), not 3/2.
func test_the_inverse_log_shift_is_a_decimal() -> void:
	var seen := 0
	for q in _each(GI, "function-and-inverse"):
		var line: String = q.lines[0]
		check(not line.contains("/"), "%s: %s" % [q.cell, line])
		var c := _q(str(q.situation.d1))
		check(line.contains("ln(x + %s)" % Fmt.dec(c.neg())), "%s: %s" % [q.cell, line])
		if c.d != 1:
			seen += 1
	check(seen > 0, "no half-number shift")


## "Method: Reflect the graph in y = x." was answered by "this method fails for 3 s.f.": the
## method is named for what its working does, and the working doesn't call it a failure.
func test_the_reflection_method_is_named_for_its_working() -> void:
	var seen := 0
	for q in _each(GI, "function-and-inverse"):
		var steps := _sol(q, "reflect-in-y-equals-x")
		check(not " ".join(steps).contains("fails"), "%s: %s" % [q.cell, steps])
		if q.view.angle == "reflect-in-y-equals-x":
			seen += 1
			check_eq(_method_line(q), "Method: Reflect in y = x, then solve f(x) = x on the GDC.", q.cell)
	check(seen > 0, "no reflect cell")


## The graph lines read "The graphs of f(x) = … and g(x) = …, for −2 ≤ x ≤ 6, are shown."
func test_the_graph_lines_close_the_domain_with_a_comma() -> void:
	for spec in [[GI, "intersection-points"], [GI, "function-and-inverse"], [GI, "count-crossings"], [CB, "sum-zeros"]]:
		for q in _each(spec[0], spec[1]):
			if q.cell_rep == "graph":
				check(q.lines[0].ends_with(", are shown."), "%s: %s" % [q.cell, q.lines[0]])


## models-equal's fillers sat at the key + 1 (t = 6.08 for 5.08), beside the named slip.
func test_models_equal_has_no_option_at_the_time_plus_one() -> void:
	for fmt in ["mcq", "value"]:
		for q in _each(GI, "models-equal", fmt):
			var times: Array = q.situation.crossings.map(func(c): return c[0])
			var plus: Array = times.map(func(t): return "t = " + Fmt.sf(t + 1.0))
			# The height where they meet is a named slip, and can be t + 1 (B(t) = t + 1).
			for o in q.choices.filter(func(o): return o.get("src", "") == "fillers"):
				check(not o.text in plus, "%s: %s for %s" % [q.cell, o.text, q.answer_text])
				for t in times:
					check(not o.text.contains(Fmt.sf(t + 1.0)), "%s: %s for %s" % [q.cell, o.text, q.answer_text])


# ── fn-gdc-optimise-combined ─────────────────────────────────

## The towns' D(t) = q + rt − pe^(bt) has D′(t) = r − pbe^(bt), which ln solves: it said
## "D′(t) = 0 mixes families, so solve it on the GDC". The drugs' D′ needs the GDC.
func test_max_difference_solves_the_towns_derivative_with_ln() -> void:
	var views := GdcCombinedViews.new()
	var kinds := {}
	for i in 60:
		var rng := Seeded.new("gdctwo-maxdiff|%d" % i)
		var s := GdcCombinedSituation.generate(rng, {"mode": "difference"})
		var b := views.build("max-difference", "equation", s, rng)
		var step: String = Step.text(b.methods["derivative-zero"].steps[1])
		kinds[s.kind] = true
		check(not step.contains("mixes families"), step)
		if s.kind == "towns":
			var r: Q = s.g.m
			var pb: Q = s.f.A.mul(s.f.b)
			check(step.begins_with("D′(t) = %s − %se^(%st) = 0" % [Fmt.dec(r), GdcKit.lead(pb), GdcKit.lead(s.f.b)]), step)
			check(step.contains("t = ln(%s) ÷ %s = %s." % [Fmt.dec(r.div(pb)), Fmt.dec(s.f.b), GdcKit.W(s.ext.x)]), "%s (max at %s)" % [step, s.ext.x])
		else:
			check(step.contains("solve it on the GDC: t = %s." % GdcKit.W(s.ext.x)), step)
	check(kinds.size() == 2, "both kinds: %s" % str(kinds.keys()))


## The method names say what the working does: D′(t) = 0 and d′(x) = 0, not f′(x) = 0; D or
## d graphed as one function, not Y3 = Y1 + Y2; logs shown not to work, then the GDC.
func test_the_combined_method_names_match_their_working() -> void:
	var want := {"max-difference": {"derivative-zero": "Solve D′(t) = 0", "gdc-combine": "Graph D(t) on the GDC as one function"},
		"difference-zero": {"gdc-combine": "Graph D(t) on the GDC as one function", "analytic-logs": "Explain why logs can't solve it, then use the GDC"},
		"least-distance": {"derivative-zero": "Solve d′(x) = 0", "gdc-combine": "Graph d(x) on the GDC as one function"},
		"closest-point": {"gdc-combine": "Graph d(x) on the GDC as one function"},
		"sum-zeros": {"gdc-combine": "Define Y3 = Y1 + Y2 on the GDC"}}
	for u in want:
		for q in _each(CB, u):
			if want[u].has(q.view.angle):
				check_eq(_method_line(q), "Method: %s." % want[u][q.view.angle], q.cell)
			check(not _all_steps(q).contains("this method fails"), "%s: %s" % [q.cell, _all_steps(q)])


## "The one that is ahead comes first" was untrue (B can be ahead of A for part of the
## domain): the order comes from what D measures. The towns offer the reversed D as a slip.
func test_form_difference_orders_d_by_what_it_measures() -> void:
	var reversed := 0
	for fmt in ["mcq", "value"]:
		for q in _each(CB, "form-difference", fmt):
			var steps := _sol(q, "simplify-first")
			check(not steps[0].contains("ahead comes first"), "%s: %s" % [q.cell, steps[0]])
			check(steps[0] in ["D(t) is how far Q is ahead of P, so it is Q(t) − P(t).", "D(t) is how much higher A is than B, so it is A(t) − B(t)."],
				"%s: %s" % [q.cell, steps[0]])
			var texts := {}
			for o in q.choices:
				check(not texts.has(o.text), "%s: %s twice" % [q.cell, o.text])
				texts[o.text] = true
			if q.situation.kind == "towns" and not _opt(q, CB + "#9").is_empty():
				reversed += 1
	check(reversed > 0, "the towns never offer the reversed D")


## "−0.527 + −0.500" and "y = 2.5cos(1.5x) + −0.8x + 2": a negative addend is bracketed, and
## the sum as one function is written with its signs.
func test_a_negative_term_is_never_added_bare() -> void:
	var bare := RegEx.create_from_string("\\+ −")
	var bracketed := 0
	for u in ["sum-graph", "sum-zeros"]:
		for q in _each(CB, u):
			check(bare.search(_all_steps(q)) == null, "%s: %s" % [q.cell, _all_steps(q)])
			if _all_steps(q).contains("+ (−"):
				bracketed += 1
	check(bracketed > 0, "no negative addend bracketed")


## The distance working reads √(x² + (f(x))²) when P is on the y-axis, not √((x)² + …).
func test_the_distance_has_no_bracketed_bare_x() -> void:
	for u in ["least-distance", "closest-point"]:
		for q in _each(CB, u):
			check(not _all_steps(q).contains("(x)²"), "%s: %s" % [q.cell, _all_steps(q)])


## "Town Q's greatest lead over town P is 3.11 thousand people" was a true statement, offered
## as wrong: the 'how much' slip reads the time 5.11 as the size of the lead.
func test_interpret_extreme_offers_no_true_statement_as_wrong() -> void:
	for q in _each(CB, "interpret-extreme"):
		var e: Dictionary = q.situation.ext
		var lead := _opt(q, "SL2.10.context-apply#2")
		check_eq(lead.size(), 1, q.cell)
		for o in lead:
			check(o.text.contains(" %s " % Fmt.sf(e.x)), "%s: %s" % [q.cell, o.text])
			check(not o.text.contains(Fmt.sf(e.y)), "%s: %s (D's greatest value is %s)" % [q.cell, o.text, Fmt.sf(e.y)])


## first-whole-day's first filler sat at the key + 1 beside the named slip (key − 1): the
## fillers away from the key come first.
func test_first_whole_day_puts_its_far_fillers_first() -> void:
	var views := GdcCombinedViews.new()
	for i in 60:
		var rng := Seeded.new("gdctwo-wholeday|%d" % i)
		var s := GdcCombinedSituation.generate(rng, {"mode": "difference", "kind": "towns", "zero": true})
		var b := views.build("first-whole-day", "words", s, rng)
		var n: int = int(b.answer.values.v.n)
		var taken := [n, n - 1]
		var first := -1
		for f in b.fillers:
			var v: int = int(f.v.n)
			if not v in taken:
				first = v
				break
		check(first != -1, "no filler for t = %d" % n)
		check(not first in [n + 1, n + 2, 2 * n], "t = %d: the first filler shown is t = %d" % [n, first])
