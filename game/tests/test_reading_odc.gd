extends "res://tests/test_case.gd"
## The reading pass on the `basic-one-to-one`, `distribution` and `cubic` situations
## (FAL-1605, GitHub #193): the defects a person found reading fn-inverse-reflection,
## t4-expected-occurrences, t4-expected-value, t4-discrete-distribution,
## t5-differentiate-polynomial, t5-tangent-condition, t5-tangent-normal-equation and
## t5-stationary-points stay fixed.

const INV := "fn-inverse-reflection"
const DIST := "t4-discrete-distribution"
const DIFF := "t5-differentiate-polynomial"
const COND := "t5-tangent-condition"
const TN := "t5-tangent-normal-equation"
const SEEDS := 30


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


## Every question of an unknown's cells over the seeds, with no errors.
func _each(type: String, unknown: String, format: String = "mcq", seeds: int = SEEDS) -> Array:
	var out: Array = []
	for c in QuestionEngine.cells(false, [type]):
		if c.unknown != unknown:
			continue
		for seed in range(1, seeds + 1):
			var q := _make(type, unknown, c.rep, c.angle, seed, format)
			check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
			if not q.has("error"):
				q.cell_rep = c.rep
				q.cell_angle = c.angle
				out.append(q)
	return out


func _steps(sol: Dictionary) -> Array:
	return sol.steps.map(func(st): return Step.text(st))


func _sol(q: Dictionary, angle: String) -> String:
	for sol in q.solutions:
		if sol.angle == angle:
			return " || ".join(_steps(sol))
	return ""


func _all_steps(q: Dictionary) -> String:
	var out: Array = []
	for sol in q.solutions:
		out.append_array(_steps(sol))
	return " || ".join(out)


func _texts(q: Dictionary) -> Array:
	var out: Array = [q.prompt]
	out.append_array(q.lines)
	for o in q.choices:
		out.append(o.text)
	for sol in q.solutions:
		out.append_array(_steps(sol))
	return out


## "−2.5" or "0.2604" as a float.
static func _num(t: String) -> float:
	return float(t.replace("−", "-"))


# ── fn-inverse-reflection ────────────────────────────────────

func test_the_doubled_area_matches_its_working() -> void:
	# Paper 2 gave the half as 0.260, then doubled it to the key 0.521, not 0.520.
	var re := RegEx.create_from_string("twice that: 2 × ([0-9.]+) = ([0-9.]+)")
	var seen := 0
	for q in _each(INV, "area-by-symmetry", "value"):
		if int(q.paper) != 2:
			continue
		for sol in q.solutions:
			var st := " || ".join(_steps(sol))
			var m := re.search(st)
			check(m != null, "no doubling step: " + st)
			if m == null:
				continue
			seen += 1
			var half := _num(m.get_string(1))
			var whole := _num(m.get_string(2))
			# Six figures each side: 2 × 0.666667 = 1.33333 is a GDC's reading, not a slip.
			check(absf(2.0 * half - whole) <= 1e-5 * whole, "2 × %s is not %s" % [m.get_string(1), m.get_string(2)])
			check(Fmt.sf(whole) == Fmt.sf(_qf(q.situation.area)), "doubling %s does not round to the key %s" % [m.get_string(1), q.answer_text])
	check(seen > 0, "no Paper 2 area question")


func test_a_sketch_swaps_points_that_move() -> void:
	# "(0, 0) and (1, 1) are on f, so (0, 0) and (1, 1) are on f⁻¹" picks out no graph.
	var re := RegEx.create_from_string("The points \\((−?\\d+), (−?\\d+)\\) and \\((−?\\d+), (−?\\d+)\\) are on f,")
	for q in _each(INV, "sketch-inverse", "pick-the-graph"):
		var m := re.search(_all_steps(q))
		check(m != null, "no swapped points: " + _all_steps(q))
		if m != null:
			check(m.get_string(1) != m.get_string(2) or m.get_string(3) != m.get_string(4), "both points are on y = x: " + m.get_string(0))


func test_a_reciprocal_rule_has_no_brackets_round_one_term() -> void:
	for q in _each(INV, "is-self-inverse", "mcq"):
		for line in _texts(q):
			check(not "/(x)" in line and not RegEx.create_from_string("\\(−?\\d+\\)/").search(line), "%s: %s" % [q.cell_rep, line])


func test_the_self_inverse_verdict_is_worked() -> void:
	for q in _each(INV, "is-self-inverse", "mcq"):
		var st := _all_steps(q)
		check(not "Every swapped point is on the graph too" in st or "Swap x and y" in st, "the yes verdict is stated, not shown: " + st)
		check(not "it does not give" in st, "the no verdict is stated, not shown: " + st)
		if q.cell_rep == "equation" and not q.situation.inverse:
			check(RegEx.create_from_string("f\\(.+\\) = .+, not ").search(st) != null, "no value at the image: " + st)


func test_a_self_inverse_graph_keeps_both_points_in_its_window() -> void:
	for q in _each(INV, "is-self-inverse", "mcq", 60):
		if q.cell_rep != "graph":
			continue
		var p: float = _qf(q.situation.p)
		var r: float = _qf(q.situation.q)
		check(absf(p) <= 8.0 and absf(r) <= 8.0, "(%s, %s) is off the graph's window" % [str(q.situation.p), str(q.situation.q)])


static func _qf(v: Variant) -> float:
	var t := str(v)
	if "/" in t:
		var p := t.split("/")
		return float(p[0]) / float(p[1])
	return float(t)


func test_meeting_on_y_equals_x_is_solved() -> void:
	for q in _each(INV, "meeting-on-y-equals-x", "value"):
		if q.cell_rep == "graph":
			continue
		for sol in q.solutions:
			var st := " || ".join(_steps(sol))
			check(not "Find where the curve crosses" in st, "an equation read as a graph: " + st)
			if q.situation.form == "root":
				check("Square both sides" in st and "never negative" in st, "the root equation is not solved: " + st)
			else:
				check(RegEx.create_from_string("so x = −?\\d|^x = |\\|\\| x = ").search(st) != null, "the line equation is not solved: " + st)


func test_solving_f_equals_a_shows_the_working() -> void:
	for q in _each(INV, "inverse-from-rule", "value"):
		var st := _sol(q, "solve-f-equals")
		check(not "Solve it: x =" in st, "the solution is stated: " + st)
		check(st.split(" || ").size() >= 4, "too few steps: " + st)


# ── t4-discrete-distribution ─────────────────────────────────

func test_a_lone_strict_end_left_out_reads_right() -> void:
	# "X < 7 leaves out x = 7 (x = 7 too, as the inequality is strict)".
	var re := RegEx.create_from_string("leaves out (x = −?\\d+) \\(\\1 too")
	for q in _each(DIST, "event-probability", "value"):
		var st := _all_steps(q)
		check(re.search(st) == null, st)


# ── t5-differentiate-polynomial ──────────────────────────────

func test_a_named_gradient_says_its_x_once() -> void:
	for q in _each(DIFF, "gradient-at-point", "value"):
		var st := _all_steps(q)
		if q.cell_rep != "words":
			check(not RegEx.create_from_string("f′\\((−?\\d+)\\) = −?\\d+ at x = ").search(st), st)
		else:
			check(" at x = " in st, "dy/dx with no x: " + st)


# ── t5-tangent-condition ─────────────────────────────────────

func test_the_gradient_with_k_shows_the_substitution() -> void:
	for q in _each(COND, "coefficient-from-tangent", "value"):
		var st := _all_steps(q)
		var x0 := str(q.situation.x0).replace("-", "−")
		# "f′(3) = k" named x₀ but never put it in: the x² term shows it squared.
		check(("(%s)²" % x0) in st, "x₀ = %s is never put into the derivative: %s" % [x0, st])


# ── t5-tangent-normal-equation ───────────────────────────────

func test_point_gradient_form_is_multiplied_out() -> void:
	for pair in [["tangent-at-point", "point-gradient"], ["normal-at-point", "negative-reciprocal"]]:
		for q in _each(TN, pair[0], "value"):
			var steps: Array = []
			for sol in q.solutions:
				if sol.angle == pair[1]:
					steps = _steps(sol)
			var at := -1
			for i in steps.size():
				if steps[i].begins_with("y − ") or "; y − " in steps[i]:
					at = i
			check(at >= 0, "no point-gradient step: %s" % str(steps))
			if at < 0:
				continue
			var line: String = q.answer_text.trim_prefix("y = ")
			var worked: String = steps[at] if ", so y = " in steps[at] else (steps[at + 1] if at + 1 < steps.size() else "")
			check(worked.begins_with("y = ") or ", so y = " in worked, "the point-gradient form is never multiplied out: %s" % str(steps))
			if int(q.paper) == 1:
				check(worked.ends_with(" " + line) or worked == "y = " + line, "the working never reaches %s: %s" % [line, worked])
