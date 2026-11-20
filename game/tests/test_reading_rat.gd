extends "res://tests/test_case.gd"
## The reading pass on the `rational-function` situation (FAL-1055, GitHub #193): the defects a
## person found reading fn-rational-asymptotes-intercepts, fn-rational-sketch and
## fn-ext-transformed-reciprocal stay fixed.

const T1 := "fn-rational-asymptotes-intercepts"
const T2 := "fn-rational-sketch"
const T3 := "fn-ext-transformed-reciprocal"
const SEEDS := 30
## A negative number substituted, subtracted or added with no brackets ("k/−3", "× −3",
## "x − −1"), or a negative squared with none ("−2²").
const UNBRACKETED := "(/−\\d|× −|[−+] −\\d|(^|[ (=])−\\d+²)"
## A coefficient of 1 written out ("1(x + 1)", "−1(3x + 2)", "2x/1x"), or a coefficient
## spaced from its letter ("2 A = −6").
const SPELLED_ONE := "((^|[^0-9.])1\\(|(^|[^0-9.])1x|\\d A\\b)"


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var v := {"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format}
	if paper > 0:
		v.paper = paper
	return QuestionEngine.make(v)


## Every question of an unknown's cells over the seeds, with no errors.
func _each(type: String, unknown: String, format: String = "mcq", seeds: int = SEEDS, paper: int = 0) -> Array:
	var out: Array = []
	for c in QuestionEngine.cells(false, [type]):
		if c.unknown != unknown:
			continue
		for seed in range(1, seeds + 1):
			var q := _make(type, unknown, c.rep, c.angle, seed, format, paper)
			check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
			if not q.has("error"):
				q.cell_rep = c.rep
				q.cell_angle = c.angle
				out.append(q)
	return out


## A number as the export writes it ("3", "-3/2") as a Q.
static func _q(v: Variant) -> Q:
	if v is Q:
		return v
	var t := str(v)
	if "/" in t:
		var p := t.split("/")
		return Q.new(int(p[0]), int(p[1]))
	return Q.new(int(t))


func _method_line(q: Dictionary) -> String:
	for line in q.prompt.split("\n"):
		if line.begins_with("Method: "):
			return line
	return ""


func _steps(sol: Dictionary) -> Array:
	return sol.steps.map(func(st): return Step.text(st))


func _all_steps(q: Dictionary) -> String:
	var out: Array = []
	for sol in q.solutions:
		out.append_array(_steps(sol))
	return " || ".join(out)


func _sol(q: Dictionary, angle: String) -> String:
	for sol in q.solutions:
		if sol.angle == angle:
			return " || ".join(_steps(sol))
	return ""


func _texts(q: Dictionary) -> Array:
	var out: Array = [q.prompt]
	out.append_array(q.lines)
	for o in q.choices:
		out.append(o.text)
	for sol in q.solutions:
		out.append_array(_steps(sol))
	return out


# ── wrong-maths ──────────────────────────────────────────────

func test_the_reciprocal_has_the_horizontal_asymptote_c_over_a() -> void:
	var re := RegEx.create_from_string("asymptote is y = 1/")
	for q in _each(T2, "reciprocal-of-f", "value"):
		var s: Dictionary = q.situation
		var ha := Q.new(int(s.c), int(s.a))
		var st := _sol(q, "asymptotes-and-intercepts")
		check("horizontal asymptote is y = %s" % ha.text() in st, "1/f = %s: its horizontal asymptote is y = %s: %s" % [RationalFunctionSituation.frac(s.c, s.d, s.a, s.b), ha.text(), st])
		# Not "y = 1/8/3 = 2.67": 1 over A, with A's own decimal.
		check(re.search(st) == null or ("y = 1/%s" % _q(s.A).text()) == ("y = " + ha.text()), "the reciprocal's asymptote is written as 1/A: " + st)


func test_a_stretch_question_has_a_real_stretch() -> void:
	# B = 1 is drawn rarely (about one question in fifty), so this looks at many seeds.
	for u in ["transformation-sequence", "form-from-words", "form-from-graph"]:
		for q in _each(T3, u, "mcq", 200):
			check(not _q(q.situation.B).eq(1), "%s: a stretch by factor 1 is no stretch: %s" % [u, q.answer_text])
			check(q.choices.any(func(o): return o.ref == "SL2.8.transformed-reciprocal#1"), "%s: the no-stretch slip is not an option: %s" % [u, q.answer_text])


# ── defects ──────────────────────────────────────────────────

func test_a_self_inverse_distractor_finds_another_inverse() -> void:
	for q in _each(T2, "reciprocal-self-inverse"):
		var key: String = q.answer_text.split(", because")[0]
		for o in q.choices:
			if not o.correct:
				check(o.text.split(", because")[0] != key, "a wrong option has the key's inverse: " + o.text)
		check(not "say why" in q.prompt, q.prompt)


func test_the_split_error_spot_moves_its_mistake() -> void:
	var ty := QuestionEngine.type_of(T3)
	var refs := {}
	for i in ty.misconceptions.size():
		var m: Dictionary = ty.misconceptions[i]
		if m.as == "error-spot":
			refs[m.get("ref", "%s#%d" % [T3, i])] = true
	var bads := {}
	for q in _each(T3, "split-to-form", "error-spot"):
		bads[q.spot.bad] = true
		check(refs.has(q.spot.ref), "%s is not an error-spot misconception of %s" % [q.spot.ref, T3])
		check(q.choices[q.spot.bad].correct, "the first mistake is not the right option")
	check(bads.size() >= 2, "the first mistake is always on line %s" % str(bads.keys()))


func test_method_names_fit_the_question() -> void:
	for c in QuestionEngine.cells(false, [T3]):
		if c.angle != "compare-coefficients":
			continue
		var q := _make(T3, c.unknown, c.rep, c.angle, 1)
		check(not "B/(x − 3)" in _method_line(q), "%s: %s" % [c.key, _method_line(q)])
	for c in QuestionEngine.cells(false, [T1]):
		var q := _make(T1, c.unknown, c.rep, c.angle, 1)
		var m := _method_line(q)
		check(not "a/c" in m and not "cx + d" in m, "%s: %s" % [c.key, m])
		if c.unknown == "range-from-asymptote":
			check(not "vertex" in m, "%s: %s" % [c.key, m])
		if c.unknown == "y-intercept":
			check(not "f(x) = 0" in m, "%s: %s" % [c.key, m])
		if c.unknown == "x-intercept":
			check(not "f(0)" in m, "%s: %s" % [c.key, m])


func test_a_table_for_a_sketch_shows_large_x() -> void:
	var seen := 0
	for q in _each(T2, "sketch-from-description", "value"):
		if q.cell_rep != "table":
			continue
		seen += 1
		var h := _q(q.situation.h).to_float()
		var A := _q(q.situation.A).to_float()
		var xs: Array = q.table.rows[0][1]
		var ys: Array = q.table.rows[1][1]
		var far := 0
		for i in xs.size():
			var x := float(str(xs[i]).replace("−", "-"))
			var y := float(str(ys[i]).replace("−", "-"))
			if absf(x - h) >= 50.0 and absf(y - A) < 0.1:
				far += 1
		check(far >= 2, "the table has no large-x values close to y = %s: %s" % [str(A), str(q.table.rows)])
	check(seen > 0, "no table question")


func test_substituted_negatives_are_bracketed() -> void:
	var re := RegEx.create_from_string(UNBRACKETED)
	var targets := {T1: ["constant-from-intercept", "equation-from-features", "y-intercept"], T2: ["count-with-line"], T3: []}
	for t in [T1, T2, T3]:
		for c in QuestionEngine.cells(false, [t]):
			var seeds: int = SEEDS if c.unknown in targets[t] else 8
			for seed in range(1, seeds + 1):
				var q := _make(t, c.unknown, c.rep, c.angle, seed, "value")
				if q.has("error"):
					fail("%s seed %d: %s" % [c.key, seed, q.error])
					continue
				for line in _texts(q):
					check(re.search(line) == null, "%s seed %d: %s" % [c.key, seed, line])


func test_the_parent_graph_reasons_from_the_signs() -> void:
	for q in _each(T2, "parent-reciprocal", "value"):
		var st := _all_steps(q)
		check(not "opposite signs" in st, st)
		if q.cell_rep == "table":
			check("so k = %d" % int(q.given.k) in st, "the table's k is never found: " + st)


func test_the_letters_question_rules_out_a_constant_function() -> void:
	for q in _each(T1, "asymptotes-with-letters"):
		var g: Dictionary = q.given
		var bad: Array = []
		if g.form == "den":
			bad.append(Q.new(0))
			if int(g.b) != 0:
				bad.append(Q.new(int(g.a) * int(g.d), int(g.b)))
		else:
			bad.append(Q.new(int(g.b) * int(g.c), int(g.d)))
		var j := " ".join(q.lines)
		for v in bad:
			check("k ≠ %s" % v.text() in j, "%s: k = %s is not ruled out" % [j, v.text()])
		var st := _all_steps(q)
		check(not "a/c" in st and not "−d/k" in st and not "kx + d" in st, "the steps use letters the question doesn't have: " + st)


func test_coefficients_of_one_are_not_written() -> void:
	var re := RegEx.create_from_string(SPELLED_ONE)
	for t in [T1, T3]:
		for c in QuestionEngine.cells(false, [t]):
			for seed in range(1, 16):
				var q := _make(t, c.unknown, c.rep, c.angle, seed, "value", 1)
				if q.has("error"):
					fail("%s seed %d: %s" % [c.key, seed, q.error])
					continue
				for line in _texts(q):
					check(re.search(line) == null, "%s seed %d: %s" % [c.key, seed, line])


func test_the_equation_from_features_shows_how_b_is_found() -> void:
	var sub := RegEx.create_from_string("−?\\d+(/\\d+)? = −?\\d+(/\\d+)? [+] B/\\(−?\\d+(/\\d+)? − \\(?−?\\d+\\)?\\), so B = ")
	for q in _each(T1, "equation-from-features"):
		for a in ["divide-out", "move-parent-asymptote"]:
			var st := _sol(q, a)
			check(sub.search(st) != null, "%s: B is not worked out from the intercept: %s" % [a, st])
			check(not "fraction: So" in st and not "fraction. So" in st, "%s: %s" % [a, st])


func test_the_inequality_steps_say_above_or_below_and_test_points() -> void:
	var tested := RegEx.create_from_string("Test a point in each: f\\(.+\\) = .+, f\\(.+\\) = .+ and f\\(.+\\) = ")
	for q in _each(T2, "inequality-from-sketch"):
		var st := _all_steps(q)
		check(not "right side" in st and not "correct side" in st, st)
		check(tested.search(_sol(q, "analytic-boundary")) != null, "no point is tested: " + _sol(q, "analytic-boundary"))


# ── minor ────────────────────────────────────────────────────

func test_an_exact_value_is_not_marked_as_rounded() -> void:
	var re := RegEx.create_from_string("(−?\\d+)/(\\d+) = −?[\\d.]+ \\(3 s\\.f\\.\\)")
	var qs: Array = _each(T2, "reciprocal-of-f", "value")
	for u in ["va-from-equation", "ha-from-equation", "x-intercept", "y-intercept"]:
		qs.append_array(_each(T1, u, "mcq", SEEDS, 2))
	for q in qs:
		for m in re.search_all(_all_steps(q)):
			var v := Q.new(int(m.get_string(1).replace("−", "-")), int(m.get_string(2)))
			check(Answer.needs_rounding(v), "%s ends, so it is not rounded: %s" % [v.text(), m.get_string(0)])


func test_gdc_values_keep_four_places_and_ratios_are_bracketed() -> void:
	var far := RegEx.create_from_string("f\\(1000\\) = (−?[\\d.]+) and f\\(−1000\\) = (−?[\\d.]+)")
	var ratio := RegEx.create_from_string("≈ −?\\d*x/(\\d)")
	for q in _each(T1, "ha-from-equation", "mcq", SEEDS, 2) + _each(T1, "ha-from-equation", "mcq", 10, 1):
		var st := _all_steps(q)
		for m in far.search_all(st):
			for i in [1, 2]:
				var t := m.get_string(i)
				check(t.contains(".") and t.split(".")[1].length() == 4, "a GDC value is not to 4 decimal places: " + m.get_string(0))
		check(ratio.search(st) == null, "the ratio of the x-terms needs brackets: " + st)


func test_a_stretch_is_described_in_ib_words() -> void:
	for u in ["transformation-sequence", "form-from-words"]:
		for q in _each(T3, u):
			for t in _texts(q):
				check(not "factor −" in t and not "in the y-direction" in t, "%s: %s" % [u, t])
			var B := _q(q.situation.B)
			var j := " ".join(_texts(q))
			check("scale factor %s" % B.abs_q().text() in j or B.abs_q().eq(1), "%s: no scale factor: %s" % [u, q.answer_text])
			check(("reflect" in j) == (B.sign() < 0), "%s: B = %s and the reflection: %s" % [u, B.text(), q.answer_text])


func test_every_wrong_reciprocal_card_names_its_slip() -> void:
	for q in _each(T2, "reciprocal-of-f", "value"):
		for o in q.choices:
			if not o.correct:
				check(o.ref != "", "%s (%s) has no misconception" % [o.text, o.get("mistake", "")])


func test_no_filler_sits_next_to_the_key() -> void:
	for q in _each(T1, "constant-from-intercept"):
		var k: Q = q.answer.values.v
		for o in q.choices:
			if o.ref == "":
				check(o.text != "k = " + k.add(Q.new(1)).text() and o.text != "k = " + k.sub(Q.new(1)).text(), "%s next to %s (%s; %s)" % [o.text, q.answer_text, " / ".join(q.lines), str(q.choices.map(func(c): return "%s %s %s" % [c.text, c.get("src", ""), c.ref]))])
	for q in _each(T1, "equation-from-features"):
		var s: Dictionary = q.situation
		var near: Array = []
		for g in [[s.a, s.b + 1, s.d], [s.a, s.b - 1, s.d], [s.a + 1, s.b, s.d], [s.a, s.b + 2, s.d], [s.a + 2, s.b, s.d]]:
			near.append(RationalFunctionViews.eq_text(g[0], g[1], g[2]))
		# The fillers away from the answer: a filler next to it is shown only once they all are.
		var A := _q(s.A)
		var away: Array = []
		for g in [[s.a, A.mul(_q(s.h)).neg().sub(_q(s.B)), s.d], [-s.a, s.b, s.d], [s.a, -s.b, s.d], [-s.a, -s.b, s.d]]:
			var t := RationalFunctionViews.eq_text(g[0], g[1], g[2])
			if RationalFunctionViews.eq_ok(g[0], g[1], g[2]) and t != q.answer_text:
				away.append(t)
		var shown: Array = q.choices.map(func(o): return o.text)
		for o in q.choices:
			if o.ref == "" and o.text in near and not o.text in away:
				check(away.all(func(t): return t in shown), "%s next to %s while %s is not shown" % [o.text, q.answer_text, str(away)])
	for u in ["combine-to-single", "form-from-words"]:
		for q in _each(T3, u):
			var s: Dictionary = q.situation
			var near: Array = []
			for g in [[s.a, s.b + 1, s.d], [s.a, s.b - 1, s.d], [s.a + 1, s.b, s.d], [s.a, s.b + 2, s.d], [s.a + 2, s.b, s.d]]:
				near.append(RationalFunctionViews.single_text(g[0], g[1], g[2]))
			var away: Array = []
			for g in [[s.a, s.b, -s.d], [-s.a, s.b, s.d], [s.a, -s.b, s.d], [-s.a, -s.b, s.d]]:
				var t := RationalFunctionViews.single_text(g[0], g[1], g[2])
				if RationalFunctionViews.eq_ok(g[0], g[1], g[2]) and t != q.answer_text:
					away.append(t)
			var shown: Array = q.choices.map(func(o): return o.text)
			for o in q.choices:
				if o.ref == "" and o.text in near and not o.text in away:
					check(away.all(func(t): return t in shown), "%s: %s next to %s while %s is not shown" % [u, o.text, q.answer_text, str(away)])
	for q in _each(T1, "constants-from-asymptotes"):
		var s: Dictionary = q.situation
		var A := _q(s.A)
		var h := _q(s.h)
		var d := Q.new(int(s.d))
		# The answer, the two slips and the two fillers away from it: d × 2 is shown only when
		# fewer than three of the others are left.
		var cands := {}
		for v in [[A, h], [h, A.neg()], [Q.new(int(s.b)), d], [A.neg(), d]]:
			var t := "a = %s, d = %s" % [v[0].text(), v[1].text()]
			if t != q.answer_text:
				cands[t] = true
		if cands.size() >= 3:
			check(not q.choices.any(func(o): return o.text == "a = %s, d = %s" % [A.text(), d.mul(Q.new(2)).text()]), "the d × 2 filler is shown before the others: " + q.answer_text)
