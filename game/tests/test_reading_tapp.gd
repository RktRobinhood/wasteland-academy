extends "res://tests/test_case.gd"
## The reading pass on fn-transform-apply (transform-chain), FAL-1605 / GitHub #193: each
## test pins one fixed finding, over seeds 1..30 and every cell of the unknown it is about.

const TA := "fn-transform-apply"
const SEEDS := 30


func _cells(unknown: String) -> Array:
	return QuestionEngine.cells(false, [TA]).filter(func(c): return unknown == "" or c.unknown == unknown)


## Every question of an unknown ("" for all), for each cell, seed and paper the cell has.
func _each(unknown: String, format: String = "mcq") -> Array:
	var out: Array = []
	for c in _cells(unknown):
		for paper in [1, 2]:
			for seed in range(1, SEEDS + 1):
				var q := QuestionEngine.make({"type": TA, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed,
					"format": "pick-the-graph" if c.unknown.begins_with("sketch") else format, "paper": paper})
				if q.has("error"):
					break
				if paper == 2 and q.paper != 2:
					break
				out.append(q)
	return out


func _steps(q: Dictionary, angle: String) -> Array:
	for sol in q.solutions:
		if sol.angle == angle:
			return sol.steps.map(func(st): return Step.text(st))
	return []


func _all_steps(q: Dictionary) -> Array:
	var out: Array = []
	for sol in q.solutions:
		for st in sol.steps:
			out.append(Step.text(st))
	return out


func _label(q: Dictionary) -> String:
	return "%s seed %d paper %d" % [q.cell, q.view.seed, q.paper]


func _num(t: String) -> float:
	var u := t.replace("−", "-")
	if u.contains("/"):
		var p := u.split("/")
		return float(p[0]) / float(p[1])
	return float(u)


# ── Findings ─────────────────────────────────────────────────

## order-changes-rule: when both orders give the same graph, a filler read "stretch first,
## g(x) = R; translation first, g(x) = R" with R the key's rule, a second right answer
## (seed 1, f(x) = x², vertical stretch 2 and translation (−5, 0)).
func test_order_filler_never_restates_the_same_rule() -> void:
	var same := 0
	for q in _each("order-changes-rule"):
		var key: String = q.answer_text
		if not key.begins_with("the same graph either way, g(x) = "):
			continue
		same += 1
		var rule := key.trim_prefix("the same graph either way, g(x) = ")
		var twice := "stretch first, g(x) = %s; translation first, g(x) = %s" % [rule, rule]
		for o in q.choices:
			check(o.correct or o.text != twice, "%s: %s is the key in other words" % [_label(q), o.text])
	check(same >= 20, "only %d order-changes-rule questions have the same graph either way" % same)


## sketch-stretch-shift track-a-point: "Only one graph passes through it" was false when the
## followed point was on an axis: f(x/2) − 1 keeps (0, −1), and 1/a·f(x) + d keeps (p, d).
## Each card's map is rebuilt from its mistake, as the checker does, and the curve is
## evaluated exactly.
func test_sketch_track_point_fits_one_graph() -> void:
	var seen := 0
	var TC := preload("res://engine/situations/transform_chain.gd")
	for q in _each("sketch-stretch-shift"):
		var steps := _steps(q, "track-a-point")
		seen += 1
		var re := RegEx.create_from_string("goes to \\((−?[0-9./]+), (−?[0-9./]+)\\)")
		var pts: Array = re.search_all(steps[0]).map(func(m): return [_num(m.get_string(1)), _num(m.get_string(2))])
		check(not pts.is_empty(), "%s: no point followed in %s" % [_label(q), steps[0]])
		var g: Dictionary = q.given
		var s := {"fam": g.fam, "paper": q.paper}
		if g.has("nodes"):
			s.nodes = g.nodes.map(func(n): return [_q(n[0]), _q(n[1])])
		if g.has("u"):
			s.u = _q(g.u)
			s.v = _q(g.v)
		var a := _q(g.moves[0].a)
		var d := _q(g.moves[1].d)
		var maps := {"": [a, Q.new(1), d], "bracket": [a, Q.new(1), a.mul(d)], "wrong-way": [a, Q.new(1), d.neg()],
			"sideways": [Q.new(1), Q.new(1).div(a), d], "inverted": [Q.new(1).div(a), Q.new(1), d]}
		for o in q.choices:
			var m: Array = maps[o.get("mistake", "")]
			var map := {"A": m[0], "B": m[1], "C": Q.new(0), "D": m[2]}
			var on_all: bool = pts.all(func(p): return absf(TC.at(s, map, p[0]) - p[1]) < 1e-6)
			if o.correct:
				check(on_all, "%s: the key graph misses %s" % [_label(q), steps[0]])
			else:
				check(not on_all, "%s: %s (%s) also passes through the followed points (%s)" % [_label(q), o.text, o.mistake, steps[0]])
	check(seen >= 30, "only %d sketch-stretch-shift questions follow a point" % seen)


func _q(v: Variant) -> Q:
	var t := str(v)
	if t.contains("/"):
		var p := t.split("/")
		return Q.new(int(p[0]), int(p[1]))
	return Q.new(int(t))


## reflect-translate-rule: the copied domain of a log carried SL2.2.domain#1, "Copying the
## domain of √x without the shift". A log's copy is the type's own slip, fn-transform-apply#19.
func test_copied_domain_ref_names_the_family() -> void:
	var logs := 0
	for q in _each("reflect-translate-rule"):
		var root: bool = q.given.fam == "root"
		for o in q.choices:
			if o.ref == "SL2.2.domain#1":
				check(root, "%s: %s names √x for %s" % [_label(q), o.text, q.given.fam])
			if o.ref == TA + "#19":
				logs += 1
				check(not root, "%s: a root's copied domain should name √x" % _label(q))
	check(logs >= 20, "only %d copied log domains carry fn-transform-apply#19" % logs)


## original-point: "(−4 − (−5)) ÷ 1/2 = 2" reads as divide by 1 then halve. A fraction or a
## negative number multiplied or divided by is now in brackets.
func test_no_bare_fraction_after_times_or_divide() -> void:
	var re := RegEx.create_from_string("[÷×] −?[0-9]+/[0-9]+")
	var lines := 0
	for q in _each(""):
		for t in _all_steps(q):
			lines += 1
			check(re.search(t) == null, "%s: a bare fraction in %s" % [_label(q), t])
	check(lines > 1000, "only %d step lines read" % lines)


## reflect-translate-rule: "replace x by x + 2.3 and add −1.8". A negative d is subtracted.
func test_no_add_a_negative() -> void:
	for q in _each("reflect-translate-rule"):
		for t in _all_steps(q):
			check(not t.contains("add −"), "%s: %s" % [_label(q), t])


## image-point and original-point: "Move the point one transformation at a time" repeated
## the mapping rule's lines. The point now moves one change at a time, named.
func test_point_step_by_step_moves_one_change_at_a_time() -> void:
	var seen := 0
	for u in ["image-point", "original-point"]:
		for q in _each(u):
			var sbs := _steps(q, "step-by-step")
			var rule := _steps(q, "mapping-rule")
			if sbs.is_empty() or rule.is_empty():
				continue
			seen += 1
			check(sbs[1] != rule[1] and sbs[2] != rule[2], "%s: step-by-step is the mapping rule again: %s" % [_label(q), sbs[1]])
			var named: bool = sbs[1].contains("(the ") or sbs[1].contains("undo ") or sbs[1].contains("nothing acts")
			check(named, "%s: no change named in %s" % [_label(q), sbs[1]])
	check(seen >= 60, "only %d point questions have both methods" % seen)


## image-point: a point with x = 0 loses two slips, and the options were filled with the
## key nudged by 1 ((5, 0) for the key (4, 0)). Named fillers fill them now.
func test_image_point_has_no_nudged_option() -> void:
	for f in ["mcq", "value"]:
		for q in _each("image-point", f):
			for o in q.choices:
				check(o.get("src", "") != "nudge", "%s: %s is the key nudged" % [_label(q), o.text])


## Lists of a, b, c and d ended ", c = 1.2, d = 4.4": the last item now takes "and".
func test_parameters_listed_with_and() -> void:
	var re := RegEx.create_from_string("c = [^,.]+, d = ")
	for q in _each(""):
		for t in _all_steps(q):
			check(re.search(t) == null, "%s: %s" % [_label(q), t])


## moved-asymptote: "x = 0 goes to x = 3.1." stated the answer. The line now works it out,
## and shift-features no longer repeats move-key-points.
func test_asymptote_moves_are_worked() -> void:
	var re := RegEx.create_from_string("goes to [xy] = [^=]+ = ")
	for q in _each("moved-asymptote"):
		var a := _steps(q, "move-key-points")
		var b := _steps(q, "shift-features")
		check(a[0] != b[0], "%s: the two methods open the same way" % _label(q))
		for t in a:
			if t.contains("goes to"):
				check(re.search(t) != null, "%s: %s is not worked" % [_label(q), t])


## rule-from-moves: stretch-then-translate-form stated b = 1.25 for a horizontal stretch with
## scale factor 0.8. b is now found as 1 ÷ 0.8, and track-a-point follows the point move by move.
func test_rule_from_moves_finds_b() -> void:
	var hs := 0
	for q in _each("rule-from-moves"):
		if not q.given.moves.any(func(m): return m.k == "hs"):
			continue
		hs += 1
		var st := _steps(q, "stretch-then-translate-form")
		if not st.is_empty():
			check(st[1].contains("b = 1 ÷ ") or st[1].contains("b = −1 ÷ "), "%s: b is not found in %s" % [_label(q), st[1]])
		var tr := _steps(q, "track-a-point")
		if not tr.is_empty():
			check(tr[0].contains(" after a horizontal stretch"), "%s: the point is not followed through the stretch: %s" % [_label(q), tr[0]])
	check(hs >= 20, "only %d rule-from-moves questions have a horizontal stretch" % hs)


## order-changes-rule: the working stated both final rules. It now shows each order's
## graph after the first move.
func test_order_working_shows_the_first_move() -> void:
	for q in _each("order-changes-rule"):
		var st := _steps(q, "step-by-step-substitution")
		if st.is_empty():
			continue
		check(st[0].contains(", then y = "), "%s: no in-between rule in %s" % [_label(q), st[0]])


## undo-moves: "Replace x with x − a, then add b" opened with the same lines as the other
## method. It now substitutes into the rule.
func test_undo_substitute_substitutes() -> void:
	for q in _each("undo-moves"):
		var st := _steps(q, "substitute")
		if st.is_empty():
			continue
		var subs: bool = st.slice(1, -1).all(func(t): return t.contains("replace x by") or t.contains("multiply the rule") or t.contains("add") or t.contains("subtract"))
		check(subs, "%s: not a substitution: %s" % [_label(q), str(st)])
		check(st != _steps(q, "step-by-step-substitution"), "%s: the two methods are the same" % _label(q))


## reflect-rule: "Do that to every term of e^x." The working now writes g out.
func test_reflect_rule_writes_g_out() -> void:
	for q in _each("reflect-rule"):
		var st := _steps(q, "negate-output-or-input")
		if st.is_empty():
			continue
		var g: String = q.answer_text.trim_prefix("g(x) = ")
		check(st[1].contains(g), "%s: %s does not reach %s" % [_label(q), st[1], g])
		check(not st[1].contains("every term of"), "%s: %s" % [_label(q), st[1]])
