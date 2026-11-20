extends "res://tests/test_case.gd"
## The reading pass on the `quadratic` situation (FAL-1055, GitHub #193): the defects a
## person found reading fn-quadratic-features, fn-quadratic-from-conditions and
## fn-concept-quadratic-forms stay fixed.

const FEATURES := "fn-quadratic-features"
const CONDITIONS := "fn-quadratic-from-conditions"
const FORMS := "fn-concept-quadratic-forms"
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


func _is_square(v: Q) -> bool:
	if v.sign() < 0:
		return false
	var n := int(round(sqrt(float(v.n))))
	var d := int(round(sqrt(float(v.d))))
	return n * n == v.n and d * d == v.d


func test_missing_form_options_do_not_contradict_themselves() -> void:
	var re := RegEx.create_from_string("Δ = (\\d+), which is not a square")
	for q in _each(FORMS, "missing-form"):
		for o in q.choices:
			var m: RegExMatch = re.search(o.text)
			if m != null:
				check(not _is_square(Q.new(int(m.get_string(1)))), "%s seed %d: %s" % [q.cell, q.view.seed, o.text])


func test_match_three_forms_has_no_majority_vote() -> void:
	for q in _each(FORMS, "match-three-forms"):
		var key: String = ""
		for o in q.choices:
			if o.correct:
				key = o.text
		var parts: PackedStringArray = key.split(",  ")
		check_eq(parts.size(), 3, q.cell)
		# The general form is the same in every option; the other two parts must not
		# show the key by a majority.
		for i in [1, 2]:
			var n: int = q.choices.filter(func(o): return o.text.split(",  ")[i] == parts[i]).size()
			check(n <= 2, "%s seed %d: %s is in %d options" % [q.cell, q.view.seed, parts[i], n])


## The option wrong in both forms makes one slip in both, not two different slips:
## the roots' signs in both brackets, or a left out of both forms (FAL-1055 batch 2).
func test_match_three_forms_double_wrong_option_is_one_slip() -> void:
	var one := Q.new(1).key()
	for q in _each(FORMS, "match-three-forms"):
		var k: Dictionary = q.choices.filter(func(o): return o.correct)[0].values
		var seen := 0
		for o in q.choices:
			var v: Dictionary = o.values
			var f_wrong: bool = v.fa.key() != k.fa.key() or v.fp.key() != k.fp.key() or v.fq.key() != k.fq.key()
			var v_wrong: bool = v.va.key() != k.va.key() or v.vh.key() != k.vh.key()
			if not (f_wrong and v_wrong):
				continue
			seen += 1
			var signs: bool = v.fa.key() == k.fa.key() and v.fp.key() == k.fp.neg().key() and v.fq.key() == k.fq.neg().key() \
				and v.va.key() == k.va.key() and v.vh.key() == k.vh.neg().key()
			var no_a: bool = v.fa.key() == one and v.va.key() == one and v.fp.key() == k.fp.key() and v.fq.key() == k.fq.key() \
				and v.vh.key() == k.vh.key()
			check(signs or no_a, "%s seed %d: %s mixes two slips" % [q.cell, q.view.seed, o.text])
		check_eq(seen, 1, "%s seed %d: options wrong in both forms" % [q.cell, q.view.seed])


func test_match_three_forms_working_finds_the_forms() -> void:
	for q in _each(FORMS, "match-three-forms"):
		for sol in q.solutions:
			var all := " || ".join(_steps(sol))
			check(not all.contains("Expand the vertex form: "), "%s %s seed %d expands the key's own forms: %s" % [q.cell, sol.angle, q.view.seed, all])
			if q.cell_rep == "graph":
				check(all.contains("so a = "), "%s %s seed %d never finds a: %s" % [q.cell, sol.angle, q.view.seed, all])
				if sol.angle == "roots-to-factors":
					check(not all.contains("Solve "), "%s seed %d solves for roots it read off: %s" % [q.cell, q.view.seed, all])


func test_form_for_feature_key_is_not_the_only_option_of_its_form() -> void:
	for u in ["form-for-feature", "form-for-task"]:
		for q in _each(FORMS, u):
			var key: Dictionary = q.choices.filter(func(o): return o.correct)[0]
			var form: String = key.text.split(":")[0]
			var n: int = q.choices.filter(func(o): return o.text.split(":")[0] == form).size()
			check(n >= 2, "%s seed %d: %s is the only %s option" % [q.cell, q.view.seed, key.text, form])


func test_method_labels_match_the_working() -> void:
	for u in ["form-for-feature", "form-for-task"]:
		for q in _each(FORMS, u):
			check(not _method_line(q).contains("(h, k)"), "%s: %s" % [q.cell, _method_line(q)])
	for u in ["axis-from-equal-outputs", "vertex-from-table"]:
		for q in _each(FEATURES, u):
			var m: String = _method_line(q)
			check(not m.contains("intercepts") and not m.contains("roots"), "%s: %s" % [q.cell, m])
	for u in ["coefficient-from-point", "coefficients-from-two-points-and-axis", "a-from-vertex-and-point"]:
		for q in _each(CONDITIONS, u):
			check(not _method_line(q).contains("three points"), "%s: %s" % [q.cell, _method_line(q)])
	for u in ["coefficients-from-roots", "vertex-form-from-vertex-and-a"]:
		for q in _each(CONDITIONS, u):
			check(not _method_line(q).contains("use a point"), "%s: %s" % [q.cell, _method_line(q)])
	for u in ["a-from-roots-and-point", "equation-from-vertex-and-root"]:
		for q in _each(CONDITIONS, u):
			if q.cell_rep == "graph":
				continue
			check(not _method_line(q).contains("graph"), "%s: %s" % [q.cell, _method_line(q)])
			for sol in q.solutions:
				check(not sol.name.contains("graph"), "%s: solution %s" % [q.cell, sol.name])
				check(not " ".join(_steps(sol)).contains("Read the x-intercepts"), "%s: %s" % [q.cell, " ".join(_steps(sol))])


func test_factorised_from_vertex_form_has_no_repeated_step() -> void:
	for q in _each(FEATURES, "factorised-from-vertex-form"):
		check(not _method_line(q).contains("Complete the square"), "%s: %s" % [q.cell, _method_line(q)])
		for sol in q.solutions:
			var st: Array = _steps(sol)
			for i in range(1, st.size()):
				check(not st[i].ends_with(st[i - 1].get_slice(": ", 1)) or st[i - 1].get_slice(": ", 1) == "", "%s seed %d: %s" % [q.cell, q.view.seed, " || ".join(st)])
				check(st[i] != st[i - 1], "%s seed %d repeats a step: %s" % [q.cell, q.view.seed, st[i]])


func test_conditions_steps_have_no_format_glitches() -> void:
	var bad := [
		RegEx.create_from_string("[ (=]−?1[a-c]\\b"),
		RegEx.create_from_string("\\b([abc]) = (\\S+), so \\1 = \\2\\b"),
		RegEx.create_from_string("divided by 1:"),
		RegEx.create_from_string(" 0 × |× 0( |,|$)|× \\(0\\)"),
	]
	for u in ["equation-from-vertex-and-root", "a-from-vertex-and-point", "coefficients-from-two-points-and-axis",
			"coefficients-from-three-points", "a-from-roots-and-point", "range-after-finding"]:
		for q in _each(CONDITIONS, u, "value"):
			for sol in q.solutions:
				for st in _steps(sol):
					for re in bad:
						check(re.search(st) == null, "%s %s seed %d: %s" % [q.cell, sol.angle, q.view.seed, st])


func test_h_k_from_vertex_asks_for_the_equation_it_gives() -> void:
	for q in _each(FEATURES, "h-k-from-vertex"):
		check(not q.asked.contains("Find h and k"), "%s: %s" % [q.cell, q.asked])
		check(q.asked.contains("in the form"), "%s: %s" % [q.cell, q.asked])
