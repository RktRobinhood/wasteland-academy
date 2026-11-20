extends "res://tests/test_case.gd"
## The reading pass on inverse-rule (fn-inverse-algebraic, #193, FAL-1055): working that
## finds the inverse instead of stating it, a rational rule written in its lowest terms
## with no minus on top and bottom, options that differ in value, brackets round a
## number put in, the catalogue's coefficient pattern, and fillers away from the key.

const T := "fn-inverse-algebraic"
const SEEDS := 30
## The unknowns whose situation can be a rational rule.
const RATIONAL := ["inverse-rational", "rational-inverse-domain", "show-self-inverse", "self-inverse-constant",
	"inverse-as-reflections", "function-from-inverse", "inverse-domain", "inverse-range", "inverse-asymptotes",
	"identity-value", "solve-inverse-equals"]


func _cells(unknown: String) -> Array:
	return QuestionEngine.cells(false, [T]).filter(func(c): return c.unknown == unknown)


## Every question of an unknown, seeds 1..SEEDS, both formats, and one shared view a seed.
func _qs(unknown: String, formats: Array = ["mcq", "value"]) -> Array:
	var out: Array = []
	for c in _cells(unknown):
		for seed in range(1, SEEDS + 1):
			var views: Array = formats.map(func(f): return {"format": f})
			views.append({"format": "mcq", "shared": true})
			for v in views:
				var q := QuestionEngine.make(v.merged({"type": T, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed}))
				var name := "%s seed %d%s %s" % [c.key, seed, " shared" if v.has("shared") else "", v.format]
				check(not q.has("error"), "%s: %s" % [name, q.get("error")])
				if not q.has("error"):
					out.append({"q": q, "c": c, "name": name})
	return out


static func _steps(q: Dictionary, angle: String) -> Array:
	for sol in q.solutions:
		if sol.angle == angle:
			return sol.steps.map(func(st): return Step.text(st))
	return []


static func _all(q: Dictionary) -> Array:
	var out: Array = []
	for sol in q.solutions:
		out += sol.steps.map(func(st): return Step.text(st))
	return out


static func _is_rat(q: Dictionary) -> bool:
	return q.given.get("f", {}).get("fam", "") == "rat"


## A function the game writes ("(−3x + 2)/(x − 1)", "2x/(x − 3)", "(11x + 2(k + 3))/(…)")
## as a number at x (and k), by Godot's Expression.
static func _eval(text: String, x: float, k: float = 0.0) -> float:
	var t := text.replace("−", "-").replace("k²", "(k*k)").replace(" ", "")
	var out := ""
	for i in t.length():
		var ch := t[i]
		if i > 0 and (ch == "(" or ch == "x" or ch == "k") and ("0123456789)xk".contains(t[i - 1])):
			out += "*"
		out += ch
	var e := Expression.new()
	if e.parse(out, ["x", "k"]) != OK:
		return NAN
	var v = e.execute([x, k])
	return NAN if e.has_execute_failed() else float(v)


## The rule in an option: "f⁻¹(x) = (x + 3)/(x + 1) = −f(−x)" gives "(x + 3)/(x + 1)".
static func _rule_of(text: String) -> String:
	var body := text.substr(text.find(" = ") + 3)
	for sep in [" = ", ", which "]:
		if body.contains(sep):
			body = body.substr(0, body.find(sep))
	return body


static func _same_values(a: String, b: String) -> bool:
	for x in [0.37, 1.93, -2.71, 4.4]:
		if absf(_eval(a, x) - _eval(b, x)) > 1e-9:
			return false
	return true


## px + q as [p, q]: "−3x + 2", "x", "−5", "2x".
static func _lin(t: String) -> Array:
	var s := t.replace("−", "-").replace(" ", "")
	var xi := s.find("x")
	if xi < 0:
		return [0, int(s)]
	var head := s.substr(0, xi)
	var p := 1 if head == "" or head == "+" else (-1 if head == "-" else int(head))
	var rest := s.substr(xi + 1)
	return [p, 0 if rest == "" else int(rest)]


static func _gcd(a: int, b: int) -> int:
	a = absi(a)
	b = absi(b)
	while b != 0:
		var t := a % b
		a = b
		b = t
	return a


## Every (top)/(bottom) in a text: in its lowest terms, the bottom's leading coefficient
## positive, and a one-term top not bracketed. "" when it is, else what is wrong.
static func _fraction_fault(text: String) -> String:
	var re := RegEx.create_from_string("(\\(([^()]*)\\)|(−?\\d*x|−?\\d+))/\\(([^()]*)\\)")
	for m in re.search_all(text):
		var top: String = m.get_string(2) if m.get_string(2) != "" else m.get_string(3)
		if m.get_string(2) != "" and not " " in top:
			return "a one-term top in brackets: " + m.get_string()
		var t := _lin(top)
		var b := _lin(m.get_string(4))
		if _gcd(_gcd(t[0], t[1]), _gcd(b[0], b[1])) != 1:
			return "a common factor: " + m.get_string()
		if b[0] < 0 or (b[0] == 0 and b[1] < 0):
			return "a minus leading the bottom: " + m.get_string()
	return ""


# ── solve-inverse-equals ─────────────────────────────────────

func test_a_number_put_into_f_is_bracketed_after_a_coefficient() -> void:
	for e in _qs("solve-inverse-equals"):
		var q: Dictionary = e.q
		var f: Dictionary = q.given.f
		var c0 := int(q.given.c0)
		var line: String = _steps(q, "identity-property")[1]
		var coef: int = f.get("a", 1) if f.fam != "root" else f.p
		if absi(coef) != 1:
			check(line.contains("%d(%s)" % [absi(coef), Fmt.num(c0)]), "%s: %s" % [e.name, line])


func test_solve_inverse_equals_fillers_keep_away_from_the_key() -> void:
	for e in _qs("solve-inverse-equals"):
		var q: Dictionary = e.q
		var f: Dictionary = q.given.f
		var c0 := int(q.given.c0)
		var y := InverseRuleSituation.value(f, Q.new(c0)) as Q
		var far: Array = [y.neg(), Q.new(c0), Q.new(-c0)]
		var at_neg = InverseRuleSituation.value(f, Q.new(-c0))
		if at_neg != null:
			far.append(at_neg)
		if f.fam == "lin":
			far.append(Q.new(f.a * (c0 + f.b)))
		_check_far_first(e, y, far)


## A filler at the key ± 1 or ± 2, or twice the key, only once every far one is shown.
func _check_far_first(e: Dictionary, key: Q, candidates: Array) -> void:
	var q: Dictionary = e.q
	var shown: Array = q.choices.map(func(o): return Q.of(o.values.v).key())
	var near_filler := false
	for o in q.choices:
		if o.get("src", "") == "fillers":
			var v := Q.of(o.values.v)
			near_filler = near_filler or v.sub(key).abs_q().lt(3) or v.eq(key.mul(2))
	if not near_filler:
		return
	for v in candidates:
		var qv := Q.of(v)
		if qv.sub(key).abs_q().lt(3) or qv.eq(key.mul(2)):
			continue
		check(qv.key() in shown, "%s: a filler near %s while %s is unused: %s" % [e.name, key.text(), qv.text(), shown])


# ── self-inverse-constant ────────────────────────────────────

func test_self_inverse_constant_fillers_keep_away_from_the_key() -> void:
	for e in _qs("self-inverse-constant"):
		var f: Dictionary = e.q.given.f
		var k: int = f.d if e.q.given.slot == "d" else f.a
		_check_far_first(e, Q.new(k), [f.b, f.c, -f.b, -f.c, 0])


func test_self_inverse_constant_compose_writes_f_of_f_and_solves_a_plus_d() -> void:
	for e in _qs("self-inverse-constant"):
		var q: Dictionary = e.q
		var steps := _steps(q, "compose-and-simplify")
		check(not " ".join(steps).contains("simplifies only when"), "%s: %s" % [e.name, steps])
		var head: String = steps[0]
		var at := head.find("f(f(x)) = ")
		check(at >= 0, "%s: no f(f(x)) written: %s" % [e.name, head])
		if at < 0:
			continue
		var ff := head.substr(at + 10)
		var k := Q.of(q.answer.values.v).to_float()
		# With the key, f(f(x)) is x; with k one more, it is not.
		check(absf(_eval(ff, 0.73, k) - 0.73) < 1e-9, "%s: f(f(x)) is not x at k = %s: %s" % [e.name, k, ff])
		check(absf(_eval(ff, 0.73, k + 1.0) - 0.73) > 1e-6, "%s: f(f(x)) is x at k + 1: %s" % [e.name, ff])
		check(steps[1].ends_with("= 0"), "%s: %s" % [e.name, steps[1]])


# ── restrict-for-inverse ─────────────────────────────────────

func test_the_vertex_is_minus_b_over_2a_with_a_negative_bracketed() -> void:
	for e in _qs("restrict-for-inverse"):
		for st in _all(e.q):
			check(not st.contains("÷"), "%s: %s" % [e.name, st])
			check(not st.contains("/−"), "%s: a negative divisor unbracketed: %s" % [e.name, st])
		check(_steps(e.q, "restrict-at-vertex")[1].begins_with("x = −b/(2a) = "), e.name)


func test_restrict_for_inverse_fillers_keep_away_from_the_key() -> void:
	for e in _qs("restrict-for-inverse"):
		var f: Dictionary = e.q.given.f
		var co := InverseRuleSituation.quad_co({"fam": "quad", "a": f.a, "h": f.h, "k": f.k, "dir": f.dir})
		_check_far_first(e, Q.new(f.h), [co[0], co[1], co[1].neg(), Q.new(-f.k)])


# ── function-from-inverse ────────────────────────────────────

func test_function_from_inverse_has_no_empty_undo_and_no_reflection_without_working() -> void:
	for e in _qs("function-from-inverse"):
		var q: Dictionary = e.q
		for st in _all(q):
			check(not st.strip_edges().ends_with("does:"), "%s: an empty step: %s" % [e.name, st])
			check(not st.contains("f undoes the steps of f⁻¹ in reverse order"), "%s: %s" % [e.name, st])
			check(not st.contains("which gives"), "%s: %s" % [e.name, st])
		if _is_rat(q):
			check(_steps(q, "reverse-operations").is_empty(), "%s: a rational rule undone step by step" % e.name)
		var refl := _steps(q, "graph-reflection")
		if not refl.is_empty():
			check(refl[0].contains("swaps x and y: x = ") and refl[1].begins_with("Solve for y: "), "%s: %s" % [e.name, refl])
			if _is_rat(q):
				check(refl[1].contains("x(") and refl[1].contains(", so y("), "%s: no cross-multiplying: %s" % [e.name, refl[1]])
		if e.c.angle == "graph-reflection":
			check(q.prompt.contains("Reflect the graph of f⁻¹ in y = x"), "%s: %s" % [e.name, q.prompt])


func test_function_from_inverse_in_words_is_said_in_words() -> void:
	for u in ["function-from-inverse", "solve-inverse-equals"]:
		for e in _qs(u):
			if e.c.rep == "words":
				check(e.q.lines[0].begins_with("f⁻¹: " if u == "function-from-inverse" else "f: "), "%s: %s" % [e.name, e.q.lines])


func test_function_from_inverse_options_differ_in_value() -> void:
	for e in _qs("function-from-inverse"):
		var q: Dictionary = e.q
		check_eq(q.choices.size(), 4, e.name)
		if not _is_rat(q):
			continue
		var rules: Array = q.choices.map(func(o): return _rule_of(o.text))
		for i in rules.size():
			for j in range(i + 1, rules.size()):
				check(not _same_values(rules[i], rules[j]), "%s: %s and %s are the same function" % [e.name, rules[i], rules[j]])


func test_function_from_inverse_fillers_are_not_the_key_moved_by_one() -> void:
	for e in _qs("function-from-inverse"):
		var q: Dictionary = e.q
		var f: Dictionary = q.given.f
		var bad: Array = []
		if f.fam == "lin":
			bad = [Fmt.poly([f.a, f.b + 1]), Fmt.poly([f.a, f.b - 1]), Fmt.poly([f.a + 1, f.b]), Fmt.poly([f.a - 1, f.b])]
		elif f.fam == "exp":
			var base := InverseRuleSituation.base_text(f.base)
			bad = [1, -1].map(func(dq): return "%s^x%s" % [base, "" if f.q + dq == 0 else Fmt.plus(f.q + dq)])
		for o in q.choices:
			if o.get("src", "") == "fillers":
				check(not _rule_of(o.text) in bad, "%s: %s" % [e.name, o.text])


func test_no_slip_is_named_where_the_rule_has_no_constant() -> void:
	for e in _qs("function-from-inverse"):
		var f: Dictionary = e.q.given.f
		if (f.fam == "lin" and f.b == 0) or (f.fam == "exp" and f.q == 0):
			for o in e.q.choices:
				check(o.ref == "", "%s: %s is tagged %s" % [e.name, o.text, o.ref])


# ── rational rules ───────────────────────────────────────────

func test_rational_rules_are_written_in_lowest_terms() -> void:
	for u in RATIONAL:
		for e in _qs(u):
			var q: Dictionary = e.q
			if not _is_rat(q):
				continue
			for t in q.lines + [q.answer_text] + q.choices.map(func(o): return o.text):
				var fault := _fraction_fault(t)
				check(fault == "", "%s: %s in %s" % [e.name, fault, t])


func test_no_rule_is_its_own_inverse_where_the_inverse_is_asked() -> void:
	for u in RATIONAL:
		if u in ["show-self-inverse", "self-inverse-constant"]:
			continue
		for e in _qs(u):
			var f: Dictionary = e.q.given.f
			if f.fam == "rat":
				check(f.d != -f.a, "%s: f is its own inverse: %s" % [e.name, e.q.lines])
			elif u == "function-from-inverse" and f.fam == "lin":
				check(f.a != -1, "%s: f is its own inverse: %s" % [e.name, e.q.lines])


func test_rational_inverse_options_differ_in_value_and_only_the_key_is_the_inverse() -> void:
	for e in _qs("inverse-rational"):
		var q: Dictionary = e.q
		var f_text: String = q.lines[0].trim_prefix("f(x) = ")
		var rules: Array = q.choices.map(func(o): return _rule_of(o.text))
		check_eq(rules.size(), 4, e.name)
		for i in rules.size():
			var is_inv := true
			for x0 in [1.93, -2.71, 0.37]:
				is_inv = is_inv and absf(_eval(f_text, _eval(rules[i], x0)) - x0) < 1e-9
			check(is_inv == q.choices[i].correct, "%s: %s is %sthe inverse" % [e.name, rules[i], "" if is_inv else "not "])
			for j in range(i + 1, rules.size()):
				check(not _same_values(rules[i], rules[j]), "%s: %s and %s are the same function" % [e.name, rules[i], rules[j]])


func test_the_coefficient_pattern_is_the_catalogue_one() -> void:
	for u in ["inverse-rational", "show-self-inverse", "self-inverse-constant"]:
		for e in _qs(u):
			var text := " ".join(_all(e.q))
			check(not text.contains("(dx − b)/(−cx + a)"), "%s: %s" % [e.name, text])
			if e.c.angle == "coefficient-pattern" and u != "self-inverse-constant":
				check(text.contains("(−dx + b)/(cx − a)"), "%s: %s" % [e.name, text])
				check(e.q.prompt.contains("(−dx + b)/(cx − a)"), "%s: %s" % [e.name, e.q.prompt])


func test_show_self_inverse_writes_f_inverse_as_f_and_finds_it() -> void:
	for e in _qs("show-self-inverse"):
		var q: Dictionary = e.q
		var rule: String = q.lines[0].trim_prefix("f(x) = ")
		check_eq(q.answer_text, "f⁻¹(x) = %s, which is f(x)" % rule, e.name)
		for a in ["swap-then-solve", "swap-and-rearrange"]:
			var steps := _steps(q, a)
			check(" ".join(steps.slice(0, steps.size() - 1)).contains("y = " + rule), "%s %s: no y = line: %s" % [e.name, a, steps])
		var comp := _steps(q, "compose-and-simplify")
		check(comp[1].ends_with("= x") and comp[1].count("/") >= 2, "%s: %s" % [e.name, comp[1]])


func test_inverse_as_reflections_finds_the_inverse_in_every_method() -> void:
	for e in _qs("inverse-as-reflections"):
		var q: Dictionary = e.q
		var inv: String = q.answer_text.trim_prefix("f⁻¹(x) = ").trim_suffix(" = −f(−x)")
		for sol in q.solutions:
			var steps: Array = sol.steps.map(func(st): return Step.text(st))
			var body := " ".join(steps.slice(0, steps.size() - 1))
			check(body.contains("y(") and (body.contains("y = " + inv) or body.contains("so f⁻¹(x) = " + inv)), "%s %s: %s" % [e.name, sol.angle, steps])
			check(not body.contains("Compare with"), "%s %s: %s" % [e.name, sol.angle, steps])
			check(body.contains("−f(−x) = "), "%s %s: %s" % [e.name, sol.angle, steps])


func test_inverse_domain_and_range_of_a_rational_rule_offer_not_equal_options() -> void:
	for u in ["inverse-domain", "inverse-range"]:
		for e in _qs(u):
			if _is_rat(e.q):
				for o in e.q.choices:
					check(o.text.contains(" ≠ "), "%s: %s" % [e.name, e.q.choices.map(func(c): return c.text)])


func test_inverse_asymptotes_name_each_pair_once() -> void:
	for e in _qs("inverse-asymptotes"):
		var seen := {}
		for o in e.q.choices:
			var parts: Array = Array(o.text.split(" and "))
			parts.sort()
			var key := " and ".join(parts)
			check(not seen.has(key), "%s: %s twice" % [e.name, key])
			seen[key] = true


# ── root and restricted quadratic ────────────────────────────

func test_inverse_root_states_the_range_of_the_inverse_and_writes_y() -> void:
	for e in _qs("inverse-root"):
		var q: Dictionary = e.q
		for sol in q.solutions:
			var steps: Array = sol.steps.map(func(st): return Step.text(st))
			var body := " ".join(steps.slice(0, steps.size() - 1))
			check(body.contains("the range of f⁻¹ is the domain of f"), "%s %s: %s" % [e.name, sol.angle, steps])
			if sol.angle == "swap-then-solve":
				check(body.contains(", so y = "), "%s: %s" % [e.name, steps])


func test_restricted_quadratic_takes_its_root_from_the_range_of_the_inverse() -> void:
	for e in _qs("inverse-restricted-quadratic"):
		var q: Dictionary = e.q
		for sol in q.solutions:
			var body := " ".join(sol.steps.map(func(st): return Step.text(st)))
			check(not body.contains("puts f⁻¹") and not body.contains("on this domain"), "%s %s: %s" % [e.name, sol.angle, body])
			check(body.contains("is the range of f⁻¹, so y "), "%s %s: %s" % [e.name, sol.angle, body])
		# The GDC method is shown only on Paper 2.
		var gc := " ".join(_steps(q, "graph-check"))
		check(gc == "" or (gc.contains("Swap x and y") and gc.contains(" ± ") and gc.contains("GDC")), "%s: %s" % [e.name, gc])
		check(e.c.angle != "graph-check" or gc != "", e.name + ": no GDC working")
