extends "res://tests/test_case.gd"
## The reading pass on log-exp-form and log-function (#193, FAL-1055): method labels that
## match the steps, steps that derive the answer, named slips before fillers near the key,
## and the wording glitches the readers found.

const EXP := "t1-log-exp-form"
const LOGF := "fn-log-function-features"
const SEEDS := 30


func _cells(type: String, unknown: String) -> Array:
	return QuestionEngine.cells(false, [type]).filter(func(c): return c.unknown == unknown)


func _make(type: String, c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


## Every question of an unknown, both formats, seeds 1..SEEDS.
func _each(type: String, unknown: String, f: Callable, formats: Array = ["mcq", "value"]) -> void:
	for c in _cells(type, unknown):
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


# ── log-function ─────────────────────────────────────────────

func test_n_from_asymptote_reads_a_horizontal_shift() -> void:
	_each(LOGF, "n-from-asymptote", func(q, c, seed):
		check(not "vertical shift" in q.prompt, "%s seed %d: %s" % [c.key, seed, q.prompt])
		if c.angle == "asymptote-first":
			check("horizontal shift" in q.prompt, "%s seed %d: %s" % [c.key, seed, q.prompt]))


func test_n_from_asymptote_offers_the_base_before_n_plus_or_minus_one() -> void:
	var views := LogFunctionViews.new()
	for seed in range(1, SEEDS + 1):
		var rng := Seeded.new("logf-n|%d" % seed)
		var s := LogFunctionSituation.generate(rng, {"m1": true, "a1": true})
		var out := views.build("n-from-asymptote", "words", s, rng)
		check_eq(out.fillers[0].v.to_float(), float(s.b), "seed %d: the base is the first filler" % seed)


func test_n_from_asymptote_offers_the_x_intercept_slip() -> void:
	var views := LogFunctionViews.new()
	for seed in range(1, SEEDS + 1):
		var rng := Seeded.new("logf-n|%d" % seed)
		var s := LogFunctionSituation.generate(rng, {"m1": true, "a1": true})
		var out := views.build("n-from-asymptote", "words", s, rng)
		var refs: Array = out.wrongs.map(func(w): return w.ref)
		var xint: Q = s.x0.add(LogFunctionSituation.bpow(s.b, -s.c))
		if absi(s.c) <= 2 and absf(xint.to_float()) <= 40.0:
			check(LogFunctionViews.R_XINT_AS_N in refs, "seed %d: no x-intercept slip" % seed)
	# Lambdas capture by value, so the counts live in an array.
	var n := [0, 0]
	_each(LOGF, "n-from-asymptote", func(q, _c, _seed):
		n[0] += 1
		var key: float = Q.of(q.choices.filter(func(o): return o.correct)[0].values.v).to_float()
		if q.choices.any(func(o): return o.get("src", "") == "fillers" and absf(Q.of(o.values.v).to_float() - key) == 1.0):
			n[1] += 1, ["mcq"])
	check(n[1] * 3 <= n[0], "a filler sits at n ± 1 in %d of %d questions" % [n[1], n[0]])


func test_no_log_function_prompt_says_ln_x_unless_the_base_is_e() -> void:
	for u in QuestionEngine.type_of(LOGF).unknowns:
		_each(LOGF, u.id, func(q, c, seed):
			if "ln x" in q.prompt:
				check("ln(" in q.prompt + str(q.lines), "%s seed %d: %s" % [c.key, seed, q.prompt]), ["mcq"])


func test_the_transform_method_describes_any_base_and_a_reflection() -> void:
	var found := false
	for a in QuestionEngine.type_of(LOGF).angles:
		if a.method == "translate-parent":
			found = true
			check(not "ln x" in a.about and "log_b x" in a.about, a.about)
			check("reflect" in a.about, a.about)
			check(not a.name.begins_with("Translate"), a.name)
	check(found, "no translate-parent angle")


func test_restriction_rules_names_one_restriction() -> void:
	for u in ["domain-from-equation", "log-inequality", "sign-of-log-expression"]:
		_each(LOGF, u, func(q, c, seed):
			check(not "three restrictions" in q.prompt, "%s seed %d: %s" % [c.key, seed, q.prompt]), ["mcq"])


func test_key_points_steps_use_the_key_points() -> void:
	for u in ["x-intercept", "reflect-exponential", "log-inequality"]:
		_each(LOGF, u, func(q, c, seed):
			if c.angle == "key-points":
				var t := " ".join(_steps(q, "key-points"))
				check("(1, 0)" in t, "%s seed %d: %s" % [c.key, seed, t]), ["mcq"])


func test_translating_the_parent_states_the_shift_plainly() -> void:
	_each(LOGF, "asymptote-from-equation", func(q, c, seed):
		var t := _all_steps(q)
		check(not "1(" in t and not "(x)" in t, "%s seed %d: %s" % [c.key, seed, t])
		check(not "not the number in the bracket" in t, "%s seed %d: %s" % [c.key, seed, t])
		# A negative stretch sends y up at the asymptote, not down.
		if q.lines[0].begins_with("y = −log") or q.lines[0].begins_with("y = −"):
			check(not "plunges" in t, "%s seed %d: %s / %s" % [c.key, seed, q.lines[0], t]), ["mcq"])


func test_pick_graph_moves_have_no_double_signs_or_zero_shifts() -> void:
	_each(LOGF, "pick-graph", func(q, c, seed):
		var t := _all_steps(q)
		for bad in ["− −", "+ −", " 0 right", " 0 up", "moves the graph −", "moves it −", "x = 0 moves to x = 0"]:
			check(not bad in t, "%s seed %d: '%s' in %s" % [c.key, seed, bad, t]))


func test_log_inequality_solves_the_power_and_names_the_side() -> void:
	_each(LOGF, "log-inequality", func(q, c, seed):
		var rr: Array = _steps(q, "restriction-rules")
		check(rr.size() > 0 and (", so x " in rr[0] or " and x " in rr[0]), "%s seed %d: %s" % [c.key, seed, rr])
		var kp := " ".join(_steps(q, "key-points"))
		check(not "on one side" in kp, "%s seed %d: %s" % [c.key, seed, kp])
		check("to the right of" in kp or "to the left of" in kp, "%s seed %d: %s" % [c.key, seed, kp]), ["mcq"])


func test_log_inequality_offers_slips_before_moved_ends() -> void:
	var views := LogFunctionViews.new()
	var bounded := 0
	for seed in range(1, 200):
		var rng := Seeded.new("logf-ineq|%d" % seed)
		var s := LogFunctionSituation.generate(rng, {"a1": true, "ineq": true})
		if not s.rel in ["<", "≤"]:
			continue
		bounded += 1
		var out := views.build("log-inequality", "equation", s, rng)
		var refs: Array = out.wrongs.map(func(w): return w.ref)
		var v := LogFunctionSituation.bpow(s.b, s.k)
		var edge: Q = v.sub(s.n).div(Q.new(s.m))
		var open_v: bool = s.x0.lt(v) if s.m > 0 else v.lt(s.x0)
		if not v.eq(edge) and open_v:
			check(LogFunctionViews.R_INPUT_VALUE in refs, "seed %d: no unsolved-input slip for %s" % [seed, out.asked])
		if s.k > 0:
			check(LogFunctionViews.R_NO_POWER in refs, "seed %d: no no-power slip for %s" % [seed, out.asked])
		# The ends moved by one are the last two fillers.
		var n: int = out.fillers.size()
		check(n >= 2, "seed %d" % seed)
		var ends: Array = out.fillers.slice(n - 2)
		check(ends[0].lo.eq(out.answer.values.lo.sub(Q.new(1))) and ends[1].hi.eq(out.answer.values.hi.add(Q.new(1))), "seed %d: %s" % [seed, out.fillers])
	check(bounded > 20, "enough bounded inequalities")


func test_sign_of_log_does_not_restate_x_positive() -> void:
	_each(LOGF, "sign-of-log-expression", func(q, c, seed):
		var t := _all_steps(q)
		check(not "x > 0, so x > 0" in t, "%s seed %d: %s" % [c.key, seed, t]))


# ── log-exp-form ─────────────────────────────────────────────

func test_standard_form_keys_offer_their_named_slips() -> void:
	for u in ["acid-value", "ratio-two-readings"]:
		_each(EXP, u, func(q, c, seed):
			if not "×" in q.answer_text:
				return
			var fill: Array = q.choices.filter(func(o): return o.get("src", "") == "fillers")
			var named: Array = q.choices.filter(func(o): return o.get("src", "") == "wrongs")
			check(named.size() >= 2, "%s seed %d: %s" % [c.key, seed, q.choices.map(func(o): return "%s [%s]" % [o.text, o.get("src", "")])])
			check(fill.is_empty() or named.size() + q.choices.filter(func(o): return o.get("trap", false)).size() >= 2,
				"%s seed %d: fillers before slips" % [c.key, seed]), ["mcq"])


func test_acid_value_offers_its_minus_slips() -> void:
	_each(EXP, "acid-value", func(q, c, seed):
		var refs: Array = q.choices.map(func(o): return o.get("ref", ""))
		check(LogExpFormViews.R_MINUS_FRONT in refs or LogExpFormViews.R_NO_MINUS in refs or LogExpFormViews.R_LOG_KEY in refs,
			"%s seed %d: %s" % [c.key, seed, q.choices.map(func(o): return o.text)])
		check(q.choices.filter(func(o): return o.get("src", "") == "fillers").is_empty(), "%s seed %d: a filler is offered" % [c.key, seed]), ["mcq"])


func test_exact_values_keep_fillers_off_the_key() -> void:
	for u in ["value-whole-power", "value-fractional-power", "solve-log-base", "solve-log-x", "power-of-log", "log-of-power"]:
		_each(EXP, u, func(q, c, seed):
			var key: Dictionary = q.choices.filter(func(o): return o.correct)[0].values
			if not key.has("v") or not key.v is Q or key.v.abs_q().to_float() <= 1.0:
				return
			for o in q.choices.filter(func(o): return o.get("src", "") == "fillers"):
				var v: Variant = o.values.get("v")
				if v is Q:
					check(not v.eq(key.v.add(1)) and not v.eq(key.v.sub(1)), "%s seed %d: filler %s next to %s" % [c.key, seed, o.text, q.answer_text]), ["mcq"])


func test_bases_and_fractional_powers_are_derived() -> void:
	for u in ["solve-log-base", "value-fractional-power"]:
		_each(EXP, u, func(q, c, seed):
			var key: Dictionary = q.choices.filter(func(o): return o.correct)[0].values
			var k := Fmt.num(key.v)
			var t := _all_steps(q)
			# The answer is not put in as the power, or as the base, to check it.
			if u == "value-fractional-power":
				check(not ("^(%s) =" % k) in t and not ("^%s =" % k) in t, "%s seed %d: %s" % [c.key, seed, t])
			else:
				check(not ("(%s)^" % k) in t and not (" %s^" % k) in t, "%s seed %d: %s" % [c.key, seed, t])
				check("Raise both sides to the power" in t, "%s seed %d: %s" % [c.key, seed, t])
				check(not "log base x" in str(q.lines), "%s seed %d: %s" % [c.key, seed, q.lines]), ["mcq"])


func test_two_beacons_are_not_named_by_the_formula_letter() -> void:
	var seen := 0
	for c in _cells(EXP, "reading-after-multiple"):
		for seed in range(1, 120):
			var q := _make(EXP, c, seed)
			if q.has("error") or not "Glare" in q.prompt + str(q.lines):
				continue
			seen += 1
			var text: String = q.prompt + " " + str(q.lines) + " " + str(q.get("table"))
			check(not ", B," in text and not "of B." in text and not "\"B\"" in text, "%s seed %d: %s" % [c.key, seed, text])
	check(seen > 0, "a Glare class question was made")
