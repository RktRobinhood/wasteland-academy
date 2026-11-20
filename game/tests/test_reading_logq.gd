extends "res://tests/test_case.gd"
## The reading pass on log-quadratic (#193, FAL-1055): one right option, method labels
## that match the steps, steps written as a student writes them, and named slips before
## fillers near the key.

const LQ := "fn-log-of-quadratic"
const SEEDS := 30


func _cells(unknown: String) -> Array:
	return QuestionEngine.cells(false, [LQ]).filter(func(c): return c.unknown == unknown)


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": LQ, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


## Every question of an unknown, both formats, seeds 1..SEEDS.
func _each(unknown: String, f: Callable, formats: Array = ["mcq", "value"]) -> void:
	var cells := _cells(unknown)
	check(cells.size() > 0, "no cells for " + unknown)
	for c in cells:
		for format in formats:
			for seed in range(1, SEEDS + 1):
				var q := _make(c, seed, format)
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if not q.has("error"):
					f.call(q, c, seed)


static func _steps(q: Dictionary, angle: String) -> Array:
	for sol in q.solutions:
		if sol.angle == angle:
			return sol.steps.map(func(st): return Step.text(st))
	return []


static func _all_text(q: Dictionary) -> String:
	var out: String = q.prompt + " ## " + " ## ".join(q.lines) + " ## "
	for sol in q.solutions:
		out += " || ".join(sol.steps.map(func(st): return Step.text(st))) + " ## "
	for o in q.choices:
		out += o.text + " ## "
	return out


## A Q from the situation's export ("−3/2" is written "-3/2" there).
static func _gq(v: Variant) -> Q:
	if v is int:
		return Q.new(v)
	var parts := str(v).split("/")
	return Q.new(int(parts[0]), 1 if parts.size() == 1 else int(parts[1]))


static func _key(q: Dictionary) -> Dictionary:
	return q.choices.filter(func(o): return o.correct)[0]


static func _wrong(q: Dictionary) -> Array:
	return q.choices.filter(func(o): return not o.correct)


## The pair of numbers in "x = −8 and x = 8", sorted, or [] for any other option.
static func _x_pair(text: String) -> Array:
	var m := RegEx.create_from_string("^x = (−?\\d+) and x = (−?\\d+)$").search(text)
	if m == null:
		return []
	var out := [int(m.get_string(1).replace("−", "-")), int(m.get_string(2).replace("−", "-"))]
	out.sort()
	return out


static func _square_free(r: int) -> bool:
	for f in range(2, 20):
		if r % (f * f) == 0:
			return false
	return true


# ── One right option ─────────────────────────────────────────

## f(x) = log₄(−x² + 64): "x = 8 and x = −8" (the sign-flip slip) is the answer again.
func test_asymptotes_have_one_option_with_the_right_pair() -> void:
	_each("asymptotes", func(q, c, seed):
		var key := _x_pair(_key(q).text)
		check(key.size() == 2, "%s seed %d: key %s" % [c.key, seed, _key(q).text])
		for o in _wrong(q):
			check(_x_pair(o.text) != key, "%s seed %d: '%s' is the answer %s again" % [c.key, seed, o.text, _key(q).text]))


# ── Notation ─────────────────────────────────────────────────

## "a(x − −3)²", "a(x)(x − 8)", "−(x + 6)x" and "Δ = (4)²" read as nobody writes them.
func test_no_double_signs_bare_x_brackets_or_bracketed_positive_squares() -> void:
	var trailing_x := RegEx.create_from_string("\\)x(?![²\\w])")
	var paren_sq := RegEx.create_from_string("\\(\\d+\\)²")
	for u in QuestionEngine.type_of(LQ).unknowns:
		_each(u.id, func(q, c, seed):
			var t := _all_text(q)
			for bad in ["− −", "+ −", "a(x)", "(x)(", "(x − 0)", "(x + 0)"]:
				check(not bad in t, "%s seed %d: '%s' in %s" % [c.key, seed, bad, t])
			check(trailing_x.search(t) == null, "%s seed %d: a factor x written last in %s" % [c.key, seed, t])
			check(paren_sq.search(t) == null, "%s seed %d: a positive number bracketed before ² in %s" % [c.key, seed, t]), ["mcq"])


## "(8 − 1)/1/2 = 14" is 3.5 as written, and "(9 − 1)/1" divides by 1.
func test_complete_the_square_divides_by_a_bracketed_fraction_and_never_by_1() -> void:
	_each("zeros", func(q, c, seed):
		var st := _steps(q, "complete-square")
		check(st.size() > 0, "%s seed %d: no complete-square tab" % [c.key, seed])
		if st.size() == 0:
			return
		check(not "/1/" in st[0] and not ")/1 " in st[0], "%s seed %d: %s" % [c.key, seed, st[0]])
		var a := _gq(q.given.a)
		if not a.eq(Q.new(-1)):
			check(")/(" in st[0], "%s seed %d: the fraction isn't bracketed: %s" % [c.key, seed, st[0]]))


# ── Method labels that match the steps ───────────────────────

## key-points is "Use (1, 0), (a, 1) and the asymptote x = 0" in the catalogue; here no step
## uses the asymptote, and base-from-max uses (k, 1) and its powers.
func test_key_points_names_the_points_its_steps_use() -> void:
	for u in ["zeros", "sign-of-f", "base-from-max"]:
		_each(u, func(q, c, seed):
			if c.angle != "key-points":
				return
			check(not "(a, 1)" in q.prompt and not "asymptote x = 0" in q.prompt, "%s seed %d: %s" % [c.key, seed, q.prompt])
			var t := " ".join(_steps(q, "key-points"))
			if u == "base-from-max":
				check("(k, 1)" in q.prompt and "(k, 1)" in t, "%s seed %d: %s / %s" % [c.key, seed, q.prompt, t])
			else:
				# log y is 0 only at y = 1, and negative for 0 < y < 1: the key point (1, 0).
				check("(1, 0)" in q.prompt and ("y = 1" in t or "0 < y < 1" in t), "%s seed %d: %s / %s" % [c.key, seed, q.prompt, t]), ["mcq"])


func test_restriction_rules_names_one_restriction() -> void:
	_each("domain-from-inequality", func(q, c, seed):
		if c.angle == "restriction-rules":
			check(not "three restrictions" in q.prompt and "positive" in q.prompt, "%s seed %d: %s" % [c.key, seed, q.prompt]), ["mcq"])


## The line of symmetry needs no y value, so nothing is substituted.
func test_axis_methods_do_not_promise_a_substitution() -> void:
	_each("axis-of-graph", func(q, c, seed):
		check(not "substitute" in q.prompt.to_lower(), "%s seed %d: %s" % [c.key, seed, q.prompt])
		for sol in q.solutions:
			check(not "substitute" in sol.name.to_lower(), "%s seed %d: %s" % [c.key, seed, sol.name]), ["mcq"])


## "Test a point in each interval" tests each one; sign-of-f tests the middle only, and says so.
func test_test_point_tests_what_its_name_says() -> void:
	var at := RegEx.create_from_string("[Aa]t x = (−?[\\d/]+), g = (−?[\\d/]+) ([<>]) 0")
	_each("domain-from-inequality", func(q, c, seed):
		var st := _steps(q, "test-point")
		check(st.size() == 3, "%s seed %d: test-point tab %s" % [c.key, seed, st])
		if st.size() < 2:
			return
		var hits := at.search_all(st[1])
		check_eq(hits.size(), 3, "%s seed %d: %s" % [c.key, seed, st[1]])
		if hits.size() == 3:
			check_eq([hits[0].get_string(3), hits[1].get_string(3), hits[2].get_string(3)], ["<", ">", "<"], "%s seed %d" % [c.key, seed]), ["mcq"])
	_each("sign-of-f", func(q, c, seed):
		if c.angle == "test-point":
			check(not "each interval" in q.prompt and "between the zeros" in q.prompt, "%s seed %d: %s" % [c.key, seed, q.prompt]), ["mcq"])


# ── Steps that derive the answer ─────────────────────────────

func test_the_quadratic_formula_for_the_zeros_shows_delta_and_the_formula() -> void:
	_each("zeros", func(q, c, seed):
		var t := " ".join(_steps(q, "quadratic-formula"))
		check("Δ = " in t and ")/(2 × " in t, "%s seed %d: %s" % [c.key, seed, t]), ["mcq"])


## log₆ 36 is 2: the what-power method has nothing to do when g(0) is a power of the base,
## and "log₂ 15/2" reads as (log₂ 15)/2.
func test_the_y_intercept_is_a_whole_number_that_is_no_power_of_the_base() -> void:
	_each("y-intercept", func(q, c, seed):
		var cq := _gq(q.given.c)
		check(cq.is_int() and cq.n > 1, "%s seed %d: g(0) = %s" % [c.key, seed, q.given.c])
		var lg: float = log(cq.to_float()) / log(float(q.given.base))
		for den in range(1, 7):
			check(absf(lg * den - roundf(lg * den)) > 1e-9, "%s seed %d: log_%d %s = %f is rational" % [c.key, seed, q.given.base, q.given.c, lg])
		check("power of" in " ".join(_steps(q, "what-power")), "%s seed %d: what-power asks no power" % [c.key, seed]))


# ── Named slips before fillers near the key ──────────────────

## |pq| = c when a = −1, and |a| + c is c + 1: the old fillers were nudges of the key.
func test_y_intercept_offers_the_vertex_slip_and_no_nudges() -> void:
	_each("y-intercept", func(q, c, seed):
		var cq := _gq(q.given.c)
		var G := _gq(q.given.k)
		var refs := {}
		for o in _wrong(q):
			var v := Q.of(o.values.v)
			refs[o.ref] = true
			if o.ref == "fn-log-of-quadratic#25":
				check(v.eq(G), "%s seed %d: #25 is %s, not g's top %s" % [c.key, seed, o.text, q.given.k])
			if o.ref == "":
				check(v.sub(cq).abs_q().to_float() > 2.0 and not v.eq(cq.mul(Q.new(2))), "%s seed %d: filler %s sits by the key %s" % [c.key, seed, o.text, _key(q).text])
		check(refs.has("fn-log-of-quadratic#25"), "%s seed %d: no vertex slip in %s" % [c.key, seed, _wrong(q).map(func(o): return o.text)]))


func test_base_from_max_names_the_top_and_the_power_slips() -> void:
	_each("base-from-max", func(q, c, seed):
		var G := _gq(q.given.k)
		var n: int = q.given.n
		var seen := 0
		for o in _wrong(q):
			var v := Q.of(o.values.v)
			if v.eq(G):
				check_eq(o.ref, "fn-log-of-quadratic#26", "%s seed %d: k = %s" % [c.key, seed, q.given.k])
				seen += 1
			if v.eq(Q.new(n)):
				check_eq(o.ref, "fn-log-of-quadratic#27", "%s seed %d: k = %d" % [c.key, seed, n])
				seen += 1
		check_eq(seen, 2, "%s seed %d: %s" % [c.key, seed, _wrong(q).map(func(o): return o.text)]))


## Whether a filler is the key nudged by 1 in one of its numbers.
static func _nudged(unknown: String, key: Dictionary, o: Dictionary) -> bool:
	var kv: Dictionary = key.values
	var ov: Dictionary = o.values
	match unknown:
		"argument-roots":
			var a := [Q.of(kv.r1).to_float(), Q.of(kv.r2).to_float()]
			var b := [Q.of(ov.r1).to_float(), Q.of(ov.r2).to_float()]
			a.sort()
			b.sort()
			return (a[0] == b[0] and absf(a[1] - b[1]) == 1.0) or (a[1] == b[1] and absf(a[0] - b[0]) == 1.0)
		"max-value":
			var d0 := absf(Q.of(kv.v0).to_float() - Q.of(ov.v0).to_float())
			var d1 := absf(Q.of(kv.v1).to_float() - Q.of(ov.v1).to_float())
			return (d0 == 1.0 and d1 == 0.0) or (d0 == 0.0 and d1 == 1.0)
		"zeros":
			var kr := Q.of(kv.m).sq().mul(kv.r).to_float()
			var orr := Q.of(ov.m).sq().mul(ov.r).to_float()
			return Q.of(kv.h).eq(ov.h) and absf(kr - orr) == 1.0
	return false


func test_fillers_do_not_sit_next_to_the_key() -> void:
	for u in ["argument-roots", "max-value", "zeros"]:
		_each(u, func(q, c, seed):
			for o in _wrong(q):
				if o.ref == "":
					check(not _nudged(u, _key(q), o), "%s seed %d: filler %s is the key %s nudged" % [c.key, seed, o.text, _key(q).text]))


## "x = −3 ± √9", "x = 2 ± √64", "x = 2 ± 3√8" are wrong at a glance; g(x) = 0 for
## g(x) = 1 is a named slip, written as the roots of g.
func test_zeros_options_are_simplest_surds_and_name_the_log_slips() -> void:
	_each("zeros", func(q, c, seed):
		var refs := {}
		for o in q.choices:
			refs[o.ref] = o
			var m := Q.of(o.values.m)
			var r := Q.of(o.values.r)
			check(m.is_int() and m.n > 0 and r.is_int() and _square_free(r.n), "%s seed %d: %s is not in simplest form" % [c.key, seed, o.text])
		check(refs.has("SL1.5.exp-log-form#2"), "%s seed %d: no g(x) = 0 slip in %s" % [c.key, seed, q.choices.map(func(o): return o.text)])
		if refs.has("SL1.5.exp-log-form#2"):
			var o: Dictionary = refs["SL1.5.exp-log-form#2"]
			check(Q.of(o.values.m).eq(Q.new(q.given.w)) and Q.of(o.values.r).eq(Q.new(1)), "%s seed %d: %s are not the roots of g" % [c.key, seed, o.text])
		if refs.has("fn-log-of-quadratic#28"):
			# (x − h)² = (G − k)/(−a): g(x) = k.
			var o: Dictionary = refs["fn-log-of-quadratic#28"]
			var want := _gq(q.given.k).sub(Q.new(q.given.base)).div(_gq(q.given.a).neg())
			check(Q.of(o.values.m).sq().mul(o.values.r).eq(want), "%s seed %d: %s doesn't solve g(x) = %d" % [c.key, seed, o.text, q.given.base]))
