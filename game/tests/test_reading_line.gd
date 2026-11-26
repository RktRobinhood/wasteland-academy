extends "res://tests/test_case.gd"
## The reading pass on the `line-conditions` situation (fn-line-from-conditions and the probe
## fn-concept-gradient-meaning), FAL-1605 / GitHub #193: each test pins one fixed finding over
## seeds 1..30 and every cell of the unknowns it is about.

const LINE := "fn-line-from-conditions"
const PROBE := "fn-concept-gradient-meaning"
const SEEDS := 30
## −(3)/(2) for −3/2; a fraction multiplied with no brackets ("5/3(x − 3)", "5/3 × 3"); a
## coefficient of −1 written out ("−1(x"); a step "−3 up" or "−1 across".
const BAD_NOTATION := "(−\\(\\d+\\)/|\\d/\\d+\\(x|(^|[ (=:])−?\\d+/\\d+ × |−1\\(x|−\\d+ up\\b|−\\d+ across\\b)"


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var v := {"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format}
	if paper > 0:
		v.paper = paper
	return QuestionEngine.make(v)


## Every question of the unknowns' cells (all of the type's for none), over the seeds and both
## papers, with no errors.
func _each(type: String, unknowns: Array = [], format: String = "mcq") -> Array:
	var out: Array = []
	for c in QuestionEngine.cells(false, [type]):
		if not unknowns.is_empty() and not c.unknown in unknowns:
			continue
		for paper in [1, 2]:
			for seed in range(1, SEEDS + 1):
				var q := _make(type, c.unknown, c.rep, c.angle, seed, format, paper)
				if paper == 2 and (q.has("error") or q.paper != 2):
					break
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if not q.has("error"):
					q.cell_unknown = c.unknown
					q.cell_rep = c.rep
					q.cell_angle = c.angle
					out.append(q)
	return out


func _steps(sol: Dictionary) -> Array:
	return sol.steps.map(func(st): return Step.text(st))


func _sol(q: Dictionary, angle: String) -> Array:
	for sol in q.solutions:
		if sol.angle == angle:
			return _steps(sol)
	return []


func _label(q: Dictionary) -> String:
	return "%s seed %d" % [q.cell, q.view.seed]


# ── the working finds what it uses ───────────────────────────

## An ax + by + d = 0 answer was written straight after y = mx + c ("Expand and collect:
## y = (1/4)x + 33/4. So x − 4y + 33 = 0."), with nothing to clear the fractions or move the
## terms. Every solution now shows that step.
func test_a_general_form_answer_shows_how_it_is_reached() -> void:
	var seen := 0
	for q in _each(LINE):
		if q.answer.kind != "gline":
			continue
		for sol in q.solutions:
			seen += 1
			var st := " || ".join(_steps(sol))
			check("to one side" in st or "to the other side" in st or "is already" in st, "%s, %s: no step reaches ax + by + d = 0: %s" % [_label(q), sol.angle, st])
	check(seen > 500, "only %d general-form solutions" % seen)


## The working stated a gradient it never found: "The gradient is 5/3." from A and B,
## "The gradient of the first line is 4/3." from 4x − 3y + 13 = 0, "L₂ has gradient 2/3." from
## 2x − 3y + 12 = 0, a parallel line put "the gradient −1/3" through P without reading it off L₁,
## and "The first line is 3x − y + 31 = 0." from two points.
func test_the_working_finds_each_gradient_it_uses() -> void:
	var bare := RegEx.create_from_string("^(The gradient is |The gradient of the first line is |L₂ has gradient |A step along the first line )")
	for q in _each(LINE, ["equation-two-points", "perpendicular-gradient", "parallel-through-point", "perpendicular-through-point", "check-perpendicular", "k-for-perpendicular"]):
		for sol in q.solutions:
			var st := _steps(sol)
			for line in st:
				check(bare.search(line) == null, "%s, %s: a gradient stated, not found: %s" % [_label(q), sol.angle, line])
			if q.cell_unknown == "parallel-through-point":
				check(not st[0].begins_with("Put the point") and not st[0].begins_with("Put ("), "%s, %s: P goes in before L₁'s gradient is found: %s" % [_label(q), sol.angle, st[0]])
			if q.cell_unknown.ends_with("-through-point") and q.cell_rep != "equation" and sol.angle == "keep-coefficients":
				check("(" in st[0] and "/" in st[0], "%s: AB's equation is not found from A and B: %s" % [_label(q), st[0]])


## Setting x = 0 in 2x + 3y + 20 = 0 jumped to "y = −20/3", and setting y = 0 used a y = mx + c
## the question never showed. A general-form line is now worked as given.
func test_setting_zero_works_on_the_line_as_given() -> void:
	var seen := 0
	for q in _each(LINE, ["intercepts-from-equation", "triangle-area"]):
		var shown: String = q.lines[0]
		if not shown.ends_with("= 0") and not shown.ends_with("= 0."):
			continue
		var st: Array = _sol(q, "set-zero")
		if st.is_empty():
			continue
		seen += 1
		var re := RegEx.create_from_string("^Set x = 0: −?\\d*y [−+] \\d+ = 0, so y = ")
		check(re.search(st[0]) != null, "%s: %s" % [_label(q), st[0]])
	check(seen > 50, "only %d general-form set-zero solutions" % seen)


## The rise (or run) from A to B came out of nowhere: "From A to B the rise = 2/5 × (−5) = −2".
## The other leg is now worked first.
func test_a_missing_coordinate_states_the_known_leg_first() -> void:
	for q in _each(LINE, ["missing-coordinate-from-gradient"]):
		var st: Array = _sol(q, "rise-over-run")
		check("the run is" in st[0] or "the rise is" in st[0], "%s: %s" % [_label(q), st[0]])


## The quarter-turn's "Use m₁ × m₂ = −1" working began "The gradients are 2 and −1/2." with no
## working: they now come from the two steps.
func test_the_quarter_turn_product_finds_both_gradients() -> void:
	for q in _each(PROBE, ["perpendicular-why"]):
		var st: Array = _sol(q, "product-minus-one")
		check(st.size() > 1 and "quarter-turn" in st[0] and st[1].count("÷") == 2, "%s: %s" % [_label(q), st])


# ── each method is the one its label names ──────────────────

## A table or two points in words were told to "Count rise over run on the graph"; "Use
## constant differences in a table" had no table; the intercept form x/p + y/q = 1 was called
## the cover-up method; a given y = mx + c was cleared under "Point-gradient form", and a given
## equation took a coordinate under "Substitute the point ... to find c".
func test_no_method_names_what_the_question_does_not_have() -> void:
	for q in _each(LINE) + _each(PROBE):
		var names: Array = q.solutions.map(func(sol): return sol.name)
		var text: String = q.prompt + " || " + " || ".join(names)
		var label := _label(q)
		if q.cell_rep != "graph":
			check(not "on the graph" in text, "%s: no graph: %s" % [label, text])
		if q.cell_rep != "table":
			check(not "in a table" in text, "%s: no table: %s" % [label, text])
		if q.cell_unknown == "equation-from-intercepts":
			check(not "Cover-up" in text, "%s: the intercept form is not the cover-up: %s" % [label, text])
		if q.cell_unknown == "general-form" and q.cell_rep == "equation":
			check(not "Point-gradient" in text, "%s: no point is put in: %s" % [label, text])
		if q.cell_unknown == "unknown-coordinate" and q.cell_rep == "equation":
			check(not "to find c" in text, "%s: c is given: %s" % [label, text])


## A parallel k question still had a "Use m₁ × m₂ = −1" working, which set −k/2 = −1/2 and never
## multiplied. Only a perpendicular pair has it now.
func test_a_parallel_k_has_no_product_working() -> void:
	var para := 0
	for q in _each(LINE, ["k-for-perpendicular"]):
		var parallel: bool = "parallel" in q.asked
		para += 1 if parallel else 0
		var st: Array = _sol(q, "product-minus-one")
		if parallel:
			check(st.is_empty(), "%s: a parallel pair worked by m₁ × m₂ = −1: %s" % [_label(q), st])
		else:
			check(" × " in " ".join(st) and "= −1" in " ".join(st), "%s: %s" % [_label(q), st])
	check(para > 20, "only %d parallel k questions" % para)


## "Use m₁ × m₂ = −1" on a pair that isn't perpendicular worked out 9/4 and said "Parallel" with
## no reason; it now says the product isn't −1 and compares the gradients.
func test_the_product_test_says_why_a_pair_is_not_perpendicular() -> void:
	for q in _each(LINE, ["check-perpendicular"]):
		var st: Array = _sol(q, "product-minus-one")
		if q.answer_text.begins_with("Perpendicular"):
			check(not "not −1" in st[1], "%s: %s" % [_label(q), st[1]])
		else:
			check("not −1" in st[1] and "gradients are" in st[1], "%s: %s" % [_label(q), st[1]])


# ── notation ─────────────────────────────────────────────────

## "m = −(3)/(2)", "y − (−4) = 5/3(x − 3)", "c = −4 − 5/3 × 3", "y − (−9) = −1(x − (−8))",
## "5 across and −3 up" and "−1 across and −3 up" are gone from every line.
func test_coefficients_and_steps_are_written_properly() -> void:
	var re := RegEx.create_from_string(BAD_NOTATION)
	for q in _each(LINE) + _each(PROBE):
		var texts: Array = [q.prompt]
		texts.append_array(q.lines)
		for sol in q.solutions:
			texts.append_array(_steps(sol))
		for t in texts:
			check(re.search(t) == null, "%s: %s" % [_label(q), t])
