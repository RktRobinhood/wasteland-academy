extends "res://tests/test_case.gd"
## The reading pass on gdc-curve (#193, FAL-1055): fn-sketch-gdc and fn-gdc-features.
## Steps that rule out every wrong graph, method labels that match the steps and the
## representation, no repeated value in an option, signs and brackets in the working,
## "and" for lists of facts, IB command terms, and fillers away from the key.

const SK := "fn-sketch-gdc"
const GF := "fn-gdc-features"
const SEEDS := 30


func _cells(type: String, unknown: String) -> Array:
	return QuestionEngine.cells(false, [type]).filter(func(c): return c.unknown == unknown)


func _make(type: String, c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


## Every question of an unknown, seeds 1..SEEDS, in each format given.
func _each(type: String, unknown: String, f: Callable, formats: Array = ["mcq", "value"]) -> void:
	var cs := _cells(type, unknown)
	check(not cs.is_empty(), "%s has no cell for %s" % [type, unknown])
	for c in cs:
		for format in formats:
			for seed in range(1, SEEDS + 1):
				var q := _make(type, c, seed, format)
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if not q.has("error"):
					f.call(q, c, seed)


static func _steps(q: Dictionary, angle: String) -> Array:
	for sol in q.solutions:
		if sol.angle == angle:
			return sol.steps.map(func(st): return Step.text(st))
	return []


static func _all_steps(q: Dictionary) -> String:
	var out := ""
	for sol in q.solutions:
		out += " || ".join(sol.steps.map(func(st): return Step.text(st))) + " ## "
	return out


## The values an "x = a, b or c" option lists.
static func _xs(text: String) -> Array:
	return text.trim_prefix("x = ").replace(" or ", ", ").split(", ")


# ── fn-sketch-gdc ────────────────────────────────────────────

func test_undefined_input_rules_out_every_wrong_graph() -> void:
	_each(SK, "sketch-with-asymptote", func(q, c, seed):
		if c.angle != "undefined-input":
			return
		var step: String = _steps(q, "undefined-input")[1]
		for o in q.choices:
			check((o.text in step) != o.correct, "%s seed %d: %s is %s in %s" % [c.key, seed, o.text,
				"named" if o.correct else "not ruled out", step])
		check("stop at the endpoint" in step and "local m" in step, "%s seed %d: %s" % [c.key, seed, step]), ["mcq"])


func test_sketch_from_table_by_zeros_also_checks_turns_and_ends() -> void:
	_each(SK, "sketch-from-table", func(q, c, seed):
		if c.angle != "gdc-zero":
			return
		var step: String = _steps(q, "gdc-zero")[1]
		check("local m" in step and "endpoints at (" in step and "where it stops" in step, "%s seed %d: %s" % [c.key, seed, step]), ["mcq"])


func test_judge_a_sketch_asks_for_a_wrong_or_rough_label() -> void:
	_each(SK, "judge-a-sketch", func(q, c, seed):
		check(q.prompt.begins_with("A student sketched y = f(x) and labelled its features. Identify the label that is wrong or not given to 3 s.f."),
			"%s seed %d: %s" % [c.key, seed, q.prompt])
		# A label to 2 s.f. has the right values, too roughly: it is "not given to 3 s.f.", not "wrong".
		var last: String = _steps(q, c.angle).back()
		check(last.count(":") == 1, "%s seed %d: %s" % [c.key, seed, last])
		check((" is not given to 3 s.f.: " in last) != (" is wrong: " in last), "%s seed %d: %s" % [c.key, seed, last]))


func test_transform_parent_names_the_stretch() -> void:
	_each(SK, "sketch-with-asymptote", func(q, c, seed):
		if c.angle != "transform-parent":
			return
		var step: String = _steps(q, "transform-parent")[0]
		check("stretched vertically by factor " in step and not "·ln" in step, "%s seed %d: %s" % [c.key, seed, step]), ["mcq"])


func test_k_for_count_boundaries_name_no_asymptote() -> void:
	_each(SK, "k-for-count", func(q, c, seed):
		if c.angle == "turning-point-boundaries":
			check("Method: Use turning-point and endpoint values as boundaries" in q.prompt, "%s seed %d: %s" % [c.key, seed, q.prompt])
		# The levels are a list of facts, and a count of one is "once".
		var all := _all_steps(q)
		check(not " time," in all and not " time." in all and " and f(" in all, "%s seed %d: %s" % [c.key, seed, all]))


func test_count_solutions_lists_features_with_and() -> void:
	_each(SK, "count-solutions-from-sketch", func(q, c, seed):
		check(q.prompt.begins_with("Write down the number of solutions of f(x) = ") or q.prompt.begins_with("Let k be the local "),
			"%s seed %d: %s" % [c.key, seed, q.prompt])
		var all := _all_steps(q)
		check(not "1 time" in all, "%s seed %d: %s" % [c.key, seed, all])
		# The line y = k is written as the question writes k (1.4, not 1.40).
		var m := RegEx.create_from_string("solutions of f\\(x\\) = (−?[\\d.]+) on the domain").search(q.prompt)
		if m != null:
			check(("the line y = %s across" % m.get_string(1)) in all and ("and y = %s on" % m.get_string(1)) in all,
				"%s seed %d: %s" % [c.key, seed, all])
		if c.rep == "words":
			var l: String = q.lines[0]
			check(not ", an endpoint at" in l and " and " in l and not " or " in l, "%s seed %d: %s" % [c.key, seed, l]))


func test_sketch_from_table_lists_intervals_with_and() -> void:
	_each(SK, "sketch-from-table", func(q, c, seed):
		var step: String = _steps(q, c.angle)[0 if c.angle != "graph-read" else 1]
		check(not " or " in step, "%s seed %d: %s" % [c.key, seed, step])
		if step.count("between") == 1:
			check("in that interval" in step, "%s seed %d: %s" % [c.key, seed, step])
		if c.angle == "graph-read":
			check("Method: Plot the rows and read the crossings" in q.prompt, "%s seed %d: %s" % [c.key, seed, q.prompt]), ["mcq"])


func test_window_prompt_is_a_command_term() -> void:
	_each(SK, "window-for-domain", func(q, c, seed):
		check(q.prompt.begins_with("Write down a suitable GDC window"), "%s seed %d: %s" % [c.key, seed, q.prompt]), ["mcq"])


# ── Both types ───────────────────────────────────────────────

func test_zero_options_never_list_a_value_twice() -> void:
	for tu in [[SK, "label-zeros"], [GF, "zeros-gdc"]]:
		_each(tu[0], tu[1], func(q, c, seed):
			for o in q.choices:
				var xs := _xs(o.text)
				for i in xs.size():
					check(xs.find(xs[i]) == i, "%s seed %d: %s" % [c.key, seed, o.text]), ["mcq"])


func test_graph_read_without_a_graph_graphs_on_the_gdc() -> void:
	for tu in [[SK, "label-zeros"], [GF, "zeros-gdc"], [GF, "y-intercept"], [SK, "greatest-on-domain"], [GF, "greatest-on-domain"]]:
		_each(tu[0], tu[1], func(q, c, seed):
			if c.angle != "graph-read":
				return
			var steps: Array = _steps(q, "graph-read")
			var all := " ".join(steps)
			check(not "fails" in all and not "Reading the sketch" in all and not "Its label gives" in all and not "1 s.f." in all,
				"%s seed %d: %s" % [c.key, seed, all])
			if c.rep != "graph":
				check(not "given graph" in q.prompt and "GDC graph" in q.prompt, "%s seed %d: %s" % [c.key, seed, q.prompt])
				check(steps[0].begins_with("Graph y = "), "%s seed %d: %s" % [c.key, seed, steps[0]])
			if tu[1] != "y-intercept" and tu[1] != "greatest-on-domain":
				check(("near those estimates" in steps[1] or "near that estimate" in steps[1]) and "x ≈ " in steps[0],
					"%s seed %d: %s" % [c.key, seed, all]))


func test_set_equal_zero_label_fits_the_unknown() -> void:
	for tu in [[SK, "label-y-intercept"], [GF, "y-intercept"], [GF, "zeros-with-x-factor"]]:
		_each(tu[0], tu[1], func(q, c, seed):
			if c.angle != "set-equal-zero":
				return
			var want := "Method: Solve f(x) = 0." if tu[1] == "zeros-with-x-factor" else "Method: Substitute x = 0."
			check(want in q.prompt and not "evaluate f(0)" in q.prompt, "%s seed %d: %s" % [c.key, seed, q.prompt]))


func test_f_of_zero_has_no_double_space_or_times_one() -> void:
	for tu in [[SK, "label-y-intercept"], [GF, "y-intercept"], [SK, "label-turning-point"], [GF, "extreme-value-only"],
			[GF, "turning-point-coordinates"]]:
		_each(tu[0], tu[1], func(q, c, seed):
			var all := _all_steps(q)
			check(not "  " in all and not "1 × 1" in all and not "f(0) = 1 ×" in all, "%s seed %d: %s" % [c.key, seed, all]))


# ── fn-gdc-features ──────────────────────────────────────────

func test_zeros_gdc_claims_no_false_algebra_and_one_window() -> void:
	_each(GF, "zeros-gdc", func(q, c, seed):
		var all := _all_steps(q)
		check(not "no algebraic solution" in all, "%s seed %d: %s" % [c.key, seed, all])
		if c.angle == "zero-of-difference":
			check("Method: Solve f(x) = 0 on the GDC" in q.prompt and not "Rearrange" in q.prompt, "%s seed %d: %s" % [c.key, seed, q.prompt])
		var gdc: Array = _steps(q, "gdc-zero")
		check(not "Set the x-window" in " ".join(gdc) and "with a little room each side" in gdc[1], "%s seed %d: %s" % [c.key, seed, " || ".join(gdc)])
		check(not " or x = " in gdc[2], "%s seed %d: %s" % [c.key, seed, gdc[2]]))


func test_count_zeros_wording() -> void:
	_each(GF, "count-zeros", func(q, c, seed):
		check(q.prompt.begins_with("Find the number of zeros of f on the domain."), "%s seed %d: %s" % [c.key, seed, q.prompt])
		check(not "Rearrange" in q.prompt, "%s seed %d: %s" % [c.key, seed, q.prompt])
		var all := _all_steps(q)
		check(not " or " in all and not "1 time" in all, "%s seed %d: %s" % [c.key, seed, all]))


func test_count_zeros_fillers_start_away_from_the_key() -> void:
	# Lambdas capture by value, so the counts live in an array: [with a named slip, clustered].
	var n := [0, 0]
	_each(GF, "count-zeros", func(q, _c, _seed):
		var key: int = int(Q.of(q.choices.filter(func(o): return o.correct)[0].values.v).to_float())
		# One zero leaves no count to offer but 0, 2 and 3: only a key of 2 or more has room.
		if key < 2 or not q.choices.any(func(o): return o.get("src", "") == "wrongs"):
			return
		n[0] += 1
		var near: Array = q.choices.filter(func(o): return o.get("src", "") == "fillers" and int(Q.of(o.values.v).to_float()) - key in [-1, 1, 2])
		if near.size() > 1:
			n[1] += 1, ["mcq"])
	check(n[0] > 0, "no count-zeros question showed a named slip")
	check_eq(n[1], 0, "questions with a named slip and two fillers next to the key")


func test_constant_from_max_brackets_a_negative_subtracted() -> void:
	var seen := [false]
	_each(GF, "constant-from-max", func(q, c, seed):
		var all := _all_steps(q)
		check(not "− −" in all, "%s seed %d: %s" % [c.key, seed, all])
		if "− (−" in all:
			seen[0] = true)
	check(seen[0], "no constant-from-max seed has a negative maximum to bracket")


func test_solve_as_zeros_adds_a_negative_k() -> void:
	var seen := [false]
	_each(GF, "solve-as-zeros", func(q, c, seed):
		var all := _all_steps(q)
		check(not "Subtract −" in all, "%s seed %d: %s" % [c.key, seed, all])
		if "Add " in all:
			seen[0] = true)
	check(seen[0], "no solve-as-zeros seed has a negative k")


func test_use_stored_zeros_brackets_only_a_negative() -> void:
	var re := RegEx.create_from_string("− \\(\\d")
	_each(GF, "use-stored-zeros", func(q, c, seed):
		var all := _all_steps(q)
		check(re.search(all) == null, "%s seed %d: %s" % [c.key, seed, all]))
