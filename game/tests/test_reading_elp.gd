extends "res://tests/test_case.gd"
## Reading pass fixes on the exp-log-pair situation (FAL-1055): the worked steps of
## fn-exp-log-inverse-composite and fn-ext-exp-graph find the answer rather than assume
## it, say only true things, and read cleanly (no "+ −4", "x^(2)", "−2.0").

const EL := "fn-exp-log-inverse-composite"
const EG := "fn-ext-exp-graph"
const SEEDS := 30


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "mcq", paper: int = 1) -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format, "paper": paper})


## Every question of a type's cells with this unknown and angle, seeds 1..30.
func _each(type: String, unknown: String, angle: String, paper: int = 1) -> Array:
	var out: Array = []
	for c in QuestionEngine.cells(false, [type]):
		if c.unknown != unknown or c.angle != angle:
			continue
		for seed in range(1, SEEDS + 1):
			var q := _make(type, unknown, c.rep, angle, seed, "mcq", paper)
			check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
			if not q.has("error"):
				out.append(q)
	check(not out.is_empty(), "no %s/%s/%s questions" % [type, unknown, angle])
	return out


## A of the situation, which export() writes as its key ("2", "-1", "1/2").
func _A(q: Dictionary) -> float:
	var k: String = str(q.situation.A)
	if "/" in k:
		return float(k.get_slice("/", 0)) / float(k.get_slice("/", 1))
	return float(k)


func _sol(q: Dictionary, angle: String) -> Dictionary:
	for sol in q.solutions:
		if sol.angle == angle:
			return sol
	return {}


func _texts(q: Dictionary, angle: String) -> Array:
	return Step.texts(_sol(q, angle).get("steps", []))


func _all_text(q: Dictionary) -> String:
	var t: String = q.prompt + " " + " ".join(q.get("lines", []))
	for sol in q.solutions:
		t += " " + " ".join(Step.texts(sol.steps))
	return t


func test_evaluate_inverse_identities_derive_then_check() -> void:
	for q in _each(EL, "evaluate-inverse", "inverse-identities"):
		var st := _texts(q, "inverse-identities")
		var s: Dictionary = q.situation
		# It starts from g(x) = a, not from g at the answer.
		check(st[0].contains("is the x with g(x) ="), "starts by assuming: " + st[0])
		check(not st[0].begins_with("g(g⁻¹"), st[0])
		# No false chain such as "log₂(2) = 1 − 4": a log's value is not followed by "= m + c".
		var b: int = s.b
		var m: int = s.m
		check(not " ".join(st).contains("%s(%d) = %d " % [Answer.log_name(b), ExpLogPairViews.ipow(b, m), m]), " ".join(st))
		# The final line is said once.
		for i in st.size() - 1:
			check(st[i] != st[st.size() - 1], "duplicated: " + st[i])
		check(st[st.size() - 2].contains("Check: g("), st[st.size() - 2])


func test_paper_2_inverse_identity_names_its_argument() -> void:
	for q in _each(EL, "evaluate-inverse", "inverse-identities", 2):
		if int(q.situation.get("paper", 1)) != 2:
			continue
		var st := _texts(q, "inverse-identities")
		check(st[1].contains(" A) = A with A = "), st[1])


func test_simplify_composite_check_separates_power_from_multiple() -> void:
	for q in _each(EL, "simplify-composite", "numeric-check"):
		var s: Dictionary = q.situation
		var n: float = float(s.i) / s.j
		var x: float = float(s.b2 * s.b2)
		var st := _texts(q, "numeric-check")
		check(st[1].contains("x = %d" % (s.b2 * s.b2)), st[1])
		# x^n and the slip n·x differ at the check point.
		check(absf(pow(x, n) - n * x) > 1e-6, "x = %d does not separate x^n from nx" % x)
		check(absf(pow(x, n) - float(s.b1 * s.b1)) < 1e-6, "the check value is wrong")
		check(not _all_text(q).contains("x^(2)") and not _all_text(q).contains("x^(3)"), _all_text(q))
		check(not _all_text(q).contains(")^(2)") and not _all_text(q).contains(")^(3)"), _all_text(q))
		# It derives the rule before checking.
		check(st[0].contains("f(g(x)) ="), st[0])


func test_composite_order_derives_then_checks_with_exact_values() -> void:
	for q in _each(EL, "composite-order", "numeric-check"):
		var st := _texts(q, "numeric-check")
		check(st[0].begins_with("Work out each"), st[0])
		check(st[1].begins_with("Check at x ="), st[1])
		check(not RegEx.create_from_string("\\d\\.0\\b").search(st[1]), st[1])
		check(not st[1].contains("0.0"), st[1])
		if not q.situation.equal:
			check(st[1].contains("which differ"), st[1])


func test_moves_from_parent_wording_follows_the_signs() -> void:
	var bad := RegEx.create_from_string("[+−-] [−-]|x − 0|moves it −|moves it 0|up −|stretches the y-value 1 to −")
	for q in _each(EG, "moves-from-parent", "transform-parent"):
		var t := " ".join(_texts(q, "transform-parent"))
		check(not bad.search(t), t)
		var s: Dictionary = q.situation
		if _A(q) < 0:
			check(t.contains("reflects it in the x-axis"), t)
		if s.h < 0:
			check(t.contains("to the left"), t)
		if s.c < 0:
			check(t.contains("down %d" % -s.c), t)


func test_asymptote_wording() -> void:
	for q in _each(EG, "asymptote", "transform-parent"):
		var t := " ".join(_texts(q, "transform-parent"))
		check(not t.contains("+ −"), t)
		if _A(q) < 0:
			check(t.contains("reflection"), t)
		if _A(q) == 1.0:
			check(not t.contains("stretch"), t)


func test_equation_from_graph_transforms_the_parent() -> void:
	for q in _each(EG, "equation-from-graph", "transform-parent"):
		var t := " ".join(_texts(q, "transform-parent"))
		check(t.contains("Start from y = b^x"), t)
		check(not t.contains("+ −") and not t.contains("1·b") and not t.contains("−1·b"), t)
		var b := int(str(q.situation.b))
		check(not t.contains("b = %d, so b = %d" % [b, b]), t)
	for q in _each(EG, "equation-from-graph", "asymptote-first"):
		var t := " ".join(_texts(q, "asymptote-first"))
		check(not t.contains("+ −"), t)


func test_method_labels_match_the_question() -> void:
	for q in _each(EL, "solve-exp-equation", "gdc-intersect", 2):
		check(not q.prompt.contains("e^(2x) with y = 7"), q.prompt)
		check_eq(_sol(q, "gdc-intersect").name, "Intersect the two sides on a GDC")
	for q in _each(EL, "inverse-of-exponential", "take-logs"):
		var name: String = _sol(q, "take-logs").name
		check_eq(name, "Take %s of both sides" % Answer.log_name(q.situation.b))


func test_no_zero_steps_or_coefficient_one() -> void:
	var bad := RegEx.create_from_string("subtract 0|add 0|adds 0|subtracts 0|add −|subtract −|adds −|subtracts −|\\(1 l|/1\\)|\\(\\d/1\\)|x\\^\\(\\d\\)|log \\d¹")
	for u in ["evaluate-inverse", "inverse-awkward-base", "simplify-composite", "inverse-of-exponential", "inverse-of-log"]:
		for c in QuestionEngine.cells(false, [EL]):
			if c.unknown != u:
				continue
			for seed in range(1, SEEDS + 1):
				var q := _make(EL, u, c.rep, c.angle, seed)
				if q.has("error"):
					continue
				var t := _all_text(q)
				var m := bad.search(t)
				check(m == null, "%s seed %d: '%s' in %s" % [c.key, seed, m.get_string() if m else "", t])
				check(not t.contains(", so x = x"), t)
