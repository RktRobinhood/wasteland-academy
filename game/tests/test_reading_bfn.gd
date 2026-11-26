extends "res://tests/test_case.gd"
## The reading pass on fn-evaluate-function and fn-concept-function-notation (basic-function)
## and fn-domain-range (basic-restricted), FAL-1605 / GitHub #193: each test pins one fixed
## finding, over seeds 1..30 and every cell of the unknown it is about.

const EV := "fn-evaluate-function"
const CN := "fn-concept-function-notation"
const DR := "fn-domain-range"
const SEEDS := 30


## Every question of an unknown, for each cell, seed and paper the cell has.
func _each(type: String, unknown: String, format: String = "mcq") -> Array:
	var out: Array = []
	for c in QuestionEngine.cells(false, [type]):
		if c.unknown != unknown:
			continue
		for paper in [1, 2]:
			for seed in range(1, SEEDS + 1):
				var q := QuestionEngine.make({"type": type, "unknown": unknown, "rep": c.rep, "angle": c.angle, "seed": seed,
					"format": format, "paper": paper})
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if q.has("error") or q.paper != paper:
					break
				q.cell_rep = c.rep
				q.cell_angle = c.angle
				out.append(q)
	return out


static func _q(v: Variant) -> Q:
	if v is Q:
		return v
	var t := str(v)
	if "/" in t:
		var p := t.split("/")
		return Q.new(int(p[0]), int(p[1]))
	return Q.new(int(t))


func _steps(sol: Dictionary) -> Array:
	return sol.steps.map(func(st): return Step.text(st))


func _all_steps(q: Dictionary) -> Array:
	var out: Array = []
	for sol in q.solutions:
		out.append_array(_steps(sol))
	return out


func _label(q: Dictionary) -> String:
	return "%s seed %d paper %d" % [q.cell, q.view.seed, q.paper]


func _distinct(q: Dictionary) -> void:
	var seen := {}
	for o in q.choices:
		check(not seen.has(o.text), "%s: two options read %s" % [_label(q), o.text])
		seen[o.text] = true


# ── fn-concept-function-notation ─────────────────────────────

## 2f(a) with f(a) negative was written "2 × −9": a substituted negative is bracketed.
func test_scale_working_brackets_a_negative_output() -> void:
	var re := RegEx.create_from_string("× −")
	for q in _each(CN, "inside-or-outside-scale"):
		for t in _all_steps(q):
			check(re.search(t) == null, "%s: %s" % [_label(q), t])


## f(a) = 0 made 2f(a) = f(a), so the slip "stops at f(a)" was the key and was dropped.
func test_scale_output_is_never_zero() -> void:
	for q in _each(CN, "inside-or-outside-scale"):
		check(not _q(q.given.y0).is_zero(), "%s: f(a) = 0" % _label(q))


## f(a) = ±1 made 1/f(a) = f(a): the "stops at f(a)" slip was the key and was dropped.
func test_inverse_question_has_no_unit_output() -> void:
	for q in _each(CN, "inverse-or-reciprocal"):
		check(not _q(q.given.y0).abs_q().eq(1), "%s: f(a) = %s" % [_label(q), q.given.y0])


## The table shows no rule, so solving f(x) = a reads the table, not 2x + 7 = 3.
func test_inverse_table_working_uses_no_unseen_rule() -> void:
	var re := RegEx.create_from_string("\\dx [+−] \\d")
	var n := 0
	for q in _each(CN, "inverse-or-reciprocal"):
		if q.cell_rep != "table":
			continue
		n += 1
		for t in _all_steps(q):
			check(re.search(t) == null, "%s: %s" % [_label(q), t])
	check(n > 0, "no table questions")


## Equation rep: f⁻¹(a) is found by solving, with the division shown.
func test_inverse_equation_solves_for_the_input() -> void:
	for q in _each(CN, "inverse-or-reciprocal"):
		if q.cell_rep != "equation":
			continue
		for t in _all_steps(q):
			if t.begins_with("Solve f(x) ="):
				check(t.contains(", so ") and t.contains(" and x = "), "%s: %s" % [_label(q), t])


## a = 1 made f(a + 1) and f(2a) both "f(2)": two options read the same. Every method
## now works out the value the answer names, 1/f(a) and 2f(a) included.
func test_match_expressions_options_distinct_and_each_found() -> void:
	var re := RegEx.create_from_string("the value (\\S+)\\?")
	for q in _each(CN, "match-expressions"):
		_distinct(q)
		var val: String = re.search(q.prompt).get_string(1)
		for sol in q.solutions:
			var body: Array = _steps(sol)
			body.pop_back()
			var want := "%s = %s" % [q.answer_text, val]
			check(" || ".join(body).contains(want), "%s %s: never works out %s" % [_label(q), sol.angle, want])


## d = −h made m = d/h equal h/d (−1), and d² = h made h/d equal d: the slips were the
## key or each other. The prompt uses an IB command term.
func test_when_equal_slips_are_other_values() -> void:
	for q in _each(CN, "when-equal"):
		var h: int = int(q.given.h)
		var d: int = int(q.given.d)
		check(d != -h and d * d != h and d != h, "%s: h %d d %d" % [_label(q), h, d])
		check(q.prompt.begins_with("Find the value of m"), "%s: %s" % [_label(q), q.prompt])
		check(" || ".join(_all_steps(q)).contains("Divide"), "%s: m is not found by dividing" % _label(q))


# ── fn-evaluate-function ─────────────────────────────────────

## Paper 1 is exact: f(−3) = 19/6, not 3.16667.
func test_above_or_below_is_exact_on_paper_1() -> void:
	for q in _each(EV, "above-or-below"):
		if q.paper != 1:
			continue
		var y := _q(q.given.y0)
		check(q.answer_text.contains("= %s," % Fmt.num(y)), "%s: %s for %s" % [_label(q), q.answer_text, Fmt.num(y)])


## The working showed no expansion: "Expand the brackets and collect like terms".
func test_expression_input_shows_the_expansion() -> void:
	for q in _each(EV, "expression-input"):
		for sol in q.solutions:
			var body: Array = _steps(sol)
			body.pop_back()
			var shown := body.any(func(t): return t.contains("= ") and not t.get_slice("= ", t.count("= ")).contains("("))
			check(shown, "%s: %s" % [_label(q), " || ".join(body)])


## f(x) = k with k one of the solutions made "x = k" both the output slip and a correct
## partial answer.
func test_input_from_output_target_is_not_a_solution() -> void:
	for q in _each(EV, "input-from-output"):
		var k := _q(q.given.k)
		for z in q.given.zs:
			check(not _q(z).eq(k), "%s: f(x) = %s has x = %s" % [_label(q), Fmt.num(k), z])


## A graph or a table shows no rule, so no working writes the quadratic out.
func test_reading_reps_use_no_unseen_rule() -> void:
	for u in ["input-from-output", "zeros"]:
		for q in _each(EV, u):
			if q.cell_rep == "equation":
				continue
			for t in _all_steps(q):
				check(not t.contains("x²") and not t.contains("x³"), "%s: %s" % [_label(q), t])


## Equation rep: the quadratic is factorised or put into the formula, not "Factorise or use
## the formula".
func test_solving_a_quadratic_shows_how() -> void:
	for u in ["input-from-output", "zeros"]:
		for q in _each(EV, u):
			if q.cell_rep != "equation":
				continue
			for t in _all_steps(q):
				check(not t.contains("Factorise or use the formula") and not t.ends_with("solve the quadratic"), "%s: %s" % [_label(q), t])


## On a graph the zeros are read off, so their signs can't be misread from factors; the
## zeros are listed with "and".
func test_zeros_graph_has_no_sign_slip_and_lists_use_and() -> void:
	for q in _each(EV, "zeros"):
		if q.cell_rep == "graph":
			check(not q.choices.any(func(o): return o.ref == "SL2.4.zeros-intercepts#1"), "%s: a sign slip on a graph" % _label(q))
		for t in _all_steps(q):
			if t.begins_with("The zeros are"):
				check(t.contains(" and x = "), "%s: %s" % [_label(q), t])


## The coefficient of x is not on a graph, so it is no slip there.
func test_y_intercept_graph_has_no_coefficient_slip() -> void:
	for q in _each(EV, "y-intercept"):
		if q.cell_rep == "graph":
			check(not q.choices.any(func(o): return o.ref == EV + "#12"), "%s: the x-coefficient slip on a graph" % _label(q))


## A filler printed f(x0) to 9 decimal places ("P(0) = 954.800922284"); the working puts 0 in.
func test_value_at_zero_options_are_rounded_and_zero_is_put_in() -> void:
	var re := RegEx.create_from_string("\\.\\d{4,}")
	for q in _each(EV, "value-at-zero"):
		for o in q.choices:
			check(re.search(o.text) == null, "%s: %s" % [_label(q), o.text])
		check(" || ".join(_all_steps(q)).contains("(0)"), "%s: 0 is never put in" % _label(q))


## A Paper 1 ball at the input t_end − r is as high as at the start, so the f(0) slip was
## the key and was dropped.
func test_ball_input_is_not_level_with_the_start() -> void:
	var n := 0
	for q in _each(EV, "value-at-input"):
		if q.given.get("ctx", "") == "ball" and q.paper == 1:
			n += 1
			check(not _q(q.given.y0).eq(_q(q.given.y_int)), "%s: h(x0) = h(0)" % _label(q))
	check(n > 0, "no Paper 1 ball")


## The output slip was written 135/2 for a target of $67.50; the domain check came before
## the value it checks; the working now solves the equation.
func test_time_for_target_reads_and_solves() -> void:
	for q in _each(EV, "time-for-target"):
		for o in q.choices:
			check(not o.text.contains("/"), "%s: %s" % [_label(q), o.text])
		var v: String = q.given.v
		for sol in q.solutions:
			var body: Array = _steps(sol)
			if sol.angle in ["solve-model", "solve-for-input", "context-domain"]:
				check(" || ".join(body).contains(", so %s = " % v), "%s %s: %s" % [_label(q), sol.angle, " || ".join(body)])
			for i in body.size() - 1:
				if body[i].contains("has to be 0 or more"):
					check(not body[i + 1].begins_with("This gives"), "%s %s: checked before it is found" % [_label(q), sol.angle])


# ── fn-domain-range ──────────────────────────────────────────

## b/(x − c) was written "(−6)/(x − 2)".
func test_a_number_over_a_bracket_has_no_brackets_on_top() -> void:
	var re := RegEx.create_from_string("= \\(−?\\d+\\)/")
	for q in _each(DR, "domain-log-or-fraction"):
		for t in q.lines:
			check(re.search(t) == null, "%s: %s" % [_label(q), t])


## Words give the vertex only, so the y-intercept is no slip there, and no working graphs
## a rule the card does not show.
func test_range_quadratic_uses_what_is_given() -> void:
	for q in _each(DR, "range-quadratic"):
		if q.cell_rep == "words":
			check(not q.choices.any(func(o): return o.ref == DR + "#11"), "%s: the y-intercept slip from words" % _label(q))
		if q.cell_rep != "equation":
			for t in _all_steps(q):
				check(not t.begins_with("Graph y = f(x)"), "%s: %s" % [_label(q), t])


## The vertex was stated, not found: on the equation it is x = −b/(2a).
func test_the_vertex_is_found_from_the_rule() -> void:
	for u in ["range-quadratic", "range-restricted", "range-reflected", "restrict-for-inverse"]:
		for q in _each(DR, u):
			if q.cell_rep != "equation":
				continue
			check(" || ".join(_all_steps(q)).contains("−b/(2a)"), "%s: the vertex is not found" % _label(q))


## "Solve it" solved nothing: the inequality is now solved on the page.
func test_domains_are_solved() -> void:
	for u in ["domain-root", "domain-log-or-fraction"]:
		for q in _each(DR, u):
			for sol in q.solutions:
				if sol.angle == "restriction-rules":
					check(" || ".join(_steps(sol)).contains(", so x "), "%s: %s" % [_label(q), " || ".join(_steps(sol))])


## The range of f was stated: it is now worked out from f at the end of the domain.
func test_inverse_domain_works_out_the_range_of_f() -> void:
	for q in _each(DR, "inverse-domain"):
		for t in _all_steps(q):
			if t.begins_with("The range of f is"):
				check(t.contains("f("), "%s: %s" % [_label(q), t])


## IB command terms: "Find the values of c", not "For which values of c".
func test_composite_condition_prompt_uses_a_command_term() -> void:
	for q in _each(DR, "composite-condition"):
		check(q.prompt.begins_with("Find the values of c"), "%s: %s" % [_label(q), q.prompt])
