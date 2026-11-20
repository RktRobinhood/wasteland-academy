extends "res://tests/test_case.gd"
## The reading pass on graph-from-features, gdc-context-equation and composite-pair (#193,
## FAL-1055 batch 2): working that derives what it states and stays on one route, a
## sketch description that only the right graph fits, a count that varies, named slips
## before fillers next to the key, method labels that fit the question, and the wording
## and bracket glitches the readers found.

const SKETCH := "fn-sketch-from-features"
const GDC := "fn-gdc-solve-equation"
const COMP := "fn-composite"
const SEEDS := 30


func _cells(type: String, unknown: String) -> Array:
	return QuestionEngine.cells(false, [type]).filter(func(c): return c.unknown == unknown)


func _make(type: String, c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


## Every question of an unknown, both formats, seeds 1..SEEDS.
func _each(type: String, unknown: String, f: Callable, formats: Array = ["mcq", "value"]) -> void:
	var cells := _cells(type, unknown)
	check(not cells.is_empty(), "%s has no cells for %s" % [type, unknown])
	for c in cells:
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


## A Q from its key: "3", "-3/2".
static func _q(key: String) -> Q:
	var p := key.split("/")
	return Q.new(int(p[0]), 1 if p.size() == 1 else int(p[1]))


# ── fn-sketch-from-features ──────────────────────────────────

## −A sin x crosses the axis where A sin x does, so the words give the maximum too, and
## the flipped card no longer fits them.
func test_trig_words_say_which_way_up_the_wave_is() -> void:
	_each(SKETCH, "sketch-trig-on-interval", func(q, c, seed):
		if c.rep != "words":
			return
		var line: String = q.lines[0]
		var sin: bool = line.begins_with("A sin")
		check("maximum value" in line and ("x = π/2" in line if sin else "x = 0 and x = 2π" in line), "%s seed %d: %s" % [c.key, seed, line])
		var t := " ".join(_steps(q, "plot-constraints"))
		check("maximum" in t, "%s seed %d: %s" % [c.key, seed, t]), ["mcq"])


## Each wrong trig graph names its slip: sin and cos swapped, the wrong amplitude, or the
## wave upside down.
func test_every_wrong_trig_graph_names_its_slip() -> void:
	_each(SKETCH, "sketch-trig-on-interval", func(q, c, seed):
		for o in q.choices:
			if not o.correct:
				check(o.ref in [SKETCH + "#8", SKETCH + "#9", SKETCH + "#10"], "%s seed %d: a wrong graph has ref '%s'" % [c.key, seed, o.ref]), ["mcq"])


## y = −½(x − h)² + k is y = x² reflected, stretched by ½ and moved, not just reflected.
func test_features_from_sketch_transform_names_the_stretch() -> void:
	var stretched := [0]
	_each(SKETCH, "features-from-sketch", func(q, c, seed):
		if c.angle != "transform-x-squared":
			return
		var a := _q(str(q.given.a))
		var t: String = _steps(q, "transform-x-squared")[0]
		check(("reflected in the x-axis" in t) == (a.sign() < 0), "%s seed %d: %s" % [c.key, seed, t])
		if not a.abs_q().eq(1):
			stretched[0] += 1
			check("stretched vertically by factor %s" % Fmt.num(a.abs_q()) in t, "%s seed %d: a = %s: %s" % [c.key, seed, a.text(), t])
		else:
			check(not "stretched" in t, "%s seed %d: %s" % [c.key, seed, t]))
	check(stretched[0] > 0, "no features-from-sketch with |a| ≠ 1 was tried")


## The working says what the sketch gets wrong, and sets it against the fact it breaks.
func test_judge_a_sketch_working_names_the_flaw() -> void:
	_each(SKETCH, "judge-a-sketch", func(q, c, seed):
		var flaw: String = q.given.flaw
		var step: String = _steps(q, "features-then-join")[1]
		check("but the sketch" in step, "%s seed %d: %s" % [c.key, seed, step])
		if flaw == "flipped":
			check("opens" in step and ("maximum" in step or "minimum" in step), "%s seed %d: %s" % [c.key, seed, step])
		else:
			check("sharp point" in step, "%s seed %d: %s" % [c.key, seed, step])
		var check_step: String = _steps(q, "plot-constraints")[1]
		check(check_step != "Check the sketch against each fact.", "%s seed %d: %s" % [c.key, seed, check_step]))


## The vertex form and the midpoint are written with their signs worked out, in fractions,
## and a negative a is a reflection, not a stretch by a negative number.
func test_sketch_quadratic_working_writes_signs_and_fractions() -> void:
	var decimal := RegEx.create_from_string("\\d\\.\\d")
	_each(SKETCH, "sketch-quadratic", func(q, c, seed):
		var t := _all_steps(q)
		for bad in ["+ −", "− −", "stretched by −", "(x − −", "(x − 0)", "(("]:
			check(not bad in t, "%s seed %d: %s in %s" % [c.key, seed, bad, t])
		check(decimal.search(t) == null, "%s seed %d: a decimal in %s" % [c.key, seed, t])
		if c.angle == "midpoint-of-roots":
			check(not RegEx.create_from_string("\\+ −\\d").search(t), "%s seed %d: %s" % [c.key, seed, t]), ["mcq"])


# ── fn-gdc-solve-equation ────────────────────────────────────

## How many solutions is not always 2: x = k sin x has three, a falling line meets an
## exponential once, a rising one twice.
func test_count_roots_answer_varies() -> void:
	var keys := {}
	_each(GDC, "count-roots", func(q, c, seed):
		keys[q.answer_text] = true
		var t := _all_steps(q)
		var n := int(q.answer_text)
		check(("1 solution " in t) == (n == 1), "%s seed %d: %s" % [c.key, seed, t])
		if c.angle == "table-sign-change" and n == 3:
			check("It is 0 at x = 0" in t, "%s seed %d: %s" % [c.key, seed, t]), ["mcq"])
	check(keys.size() >= 3, "count-roots answers: %s" % str(keys.keys()))


## The method's "h(x) = 0" would read as the height model h(t) being 0.
func test_zero_of_difference_label_fits_a_height_or_a_time() -> void:
	for u in ["first-time", "root-in-interval"]:
		_each(GDC, u, func(q, c, seed):
			if c.angle != "zero-of-difference" or (u == "root-in-interval" and c.rep != "words"):
				return
			check(not "h(x) = 0" in q.prompt and "one side is 0" in q.prompt, "%s seed %d: %s" % [c.key, seed, q.prompt]), ["mcq"])


## Simple interest is the slip offered beside the key, before the key + 1 filler.
func test_smallest_whole_number_offers_simple_interest() -> void:
	var counts := [0, 0, 0]
	_each(GDC, "smallest-whole-number", func(q, c, seed):
		counts[0] += 1
		if q.choices.any(func(o): return o.ref == GdcContextEquationViews.OWN + "13"):
			counts[1] += 1
		var key := int(q.answer_text.trim_prefix("n = "))
		if q.choices.any(func(o): return not o.correct and o.text == "n = %d" % (key + 1) and o.ref == ""):
			counts[2] += 1, ["mcq"])
	check(counts[1] * 10 >= counts[0] * 9, "simple interest offered in %d of %d" % [counts[1], counts[0]])
	check(counts[2] * 10 <= counts[0], "n + 1 filler in %d of %d" % [counts[2], counts[0]])


## x = 1.5 sin x has x = 1.50, the 1.5 printed in the equation: no such k is drawn.
func test_mixed_equation_root_is_not_its_k() -> void:
	_each(GDC, "solve-mixed-equation", func(q, c, seed):
		var line: String = q.lines[0]
		if not line.begins_with("x = "):
			return
		var k := float(line.trim_prefix("x = ").trim_suffix("sin x"))
		check(q.answer_text != "x = " + Fmt.sf(k), "%s seed %d: %s and %s" % [c.key, seed, line, q.answer_text]))


func test_mixed_equation_window_is_worded_once() -> void:
	_each(GDC, "solve-mixed-equation", func(q, c, seed):
		var t := _all_steps(q)
		check(not "Over a wide window, the x-window" in t, "%s seed %d: %s" % [c.key, seed, t]), ["mcq"])


## The words give a line and a curve: they meet where x/k = sin x. The degree-mode k is a
## named slip, not a blank filler.
func test_constant_from_root_words_meet_first_and_degrees_are_named() -> void:
	var degrees := [0]
	_each(GDC, "constant-from-root", func(q, c, seed):
		var first: String = _steps(q, "apply-inverse")[0]
		if c.rep == "words":
			check("/k = sin" in first, "%s seed %d: %s" % [c.key, seed, first])
		var x0 := float(RegEx.create_from_string("x = ([\\d.]+)\\.").search(" ".join(q.lines)).get_string(1))
		var deg := "k = " + Fmt.sf(x0 / sin(deg_to_rad(x0)))
		for o in q.choices:
			if o.text == deg:
				degrees[0] += 1
				check(o.ref == GdcContextEquationViews.OWN + "12", "%s seed %d: %s has no ref" % [c.key, seed, deg]), ["mcq"])
	check(degrees[0] > 0, "the degree-mode k never showed")


# ── fn-composite ─────────────────────────────────────────────

## The check-with-a-number working substitutes first, so the expansion it checks is derived.
func test_expression_numeric_check_substitutes_first() -> void:
	_each(COMP, "expression", func(q, c, seed):
		if c.angle != "numeric-check":
			return
		var first: String = _steps(q, "numeric-check")[0]
		check(first.begins_with("Replace x in") and first.count(" = ") >= 2, "%s seed %d: %s" % [c.key, seed, first]))


## The pair is read off h before the one number checks it.
func test_decompose_numeric_check_reads_the_pair_off_h() -> void:
	_each(COMP, "decompose", func(q, c, seed):
		if c.angle != "numeric-check":
			return
		var st := _steps(q, "numeric-check")
		check(not st[0].begins_with("Try"), "%s seed %d: %s" % [c.key, seed, st[0]])
		check(("bracket" in st[0]) if c.rep == "equation" else ("first steps" in st[0]), "%s seed %d: %s" % [c.key, seed, st[0]])
		check(st[2].begins_with("h(1) = ") and st[2].count(" = ") >= 2, "%s seed %d: %s" % [c.key, seed, st[2]]))


## (x² + 3)² + 3 is multiplied out in the working before it is checked at x = 1.
func test_self_composite_working_expands_the_bracket() -> void:
	_each(COMP, "self-composite", func(q, c, seed):
		var key: String = q.answer_text.trim_prefix("(f∘f)(x) = ")
		var inside: Array = _steps(q, "inside-out")
		if not inside.is_empty():
			check(inside[0].count(" = ") >= 3 and inside[0].ends_with(key), "%s seed %d: %s" % [c.key, seed, inside[0]])
		var whole: Array = _steps(q, "substitute-whole")
		check(whole[1].count(" = ") >= 1 and whole[1].ends_with(key), "%s seed %d: %s" % [c.key, seed, whole[1]]))


## f∘f has no g: the method label says f(x).
func test_self_composite_label_names_f() -> void:
	_each(COMP, "self-composite", func(q, c, seed):
		if c.angle == "substitute-whole":
			check("with f(x)" in q.prompt and not "g(x)" in q.prompt, "%s seed %d: %s" % [c.key, seed, q.prompt]), ["mcq"])


## Substituting the whole rule expands and solves that equation; it doesn't switch to
## undoing g halfway. A cube keeps its bracket.
func test_solve_composite_substitute_whole_stays_on_one_route() -> void:
	_each(COMP, "solve-composite", func(q, c, seed):
		if c.angle != "substitute-whole":
			return
		var st := _steps(q, "substitute-whole")
		var f: Dictionary = q.given.f
		check(not "→" in st[2], "%s seed %d: %s" % [c.key, seed, st[2]])
		if f.t == "sq":
			check(st[1].ends_with("= 0") and st[2].contains("= 0, so x = "), "%s seed %d: %s" % [c.key, seed, " || ".join(st)])
		elif f.t == "lin":
			check(st[1].contains(", so ") and st[2].contains("÷"), "%s seed %d: %s" % [c.key, seed, " || ".join(st)])
		else:
			check(not "x³ " in st[0] and st[2].contains("∛"), "%s seed %d: %s" % [c.key, seed, " || ".join(st)]))


## One x: the slips are named (g∘f solved, f undone in the wrong order, stopped at g(x),
## g's shift left out), not ±1 fillers.
func test_solve_composite_with_one_x_offers_named_slips() -> void:
	var tried := [0]
	_each(COMP, "solve-composite", func(q, c, seed):
		if int(q.answer.values.n.to_float()) != 1:
			return
		tried[0] += 1
		var named: Array = q.choices.filter(func(o): return not o.correct and o.ref != "")
		# A linear f has four slips to offer; a cube's g∘f and wrong-order undo are rarely
		# rational, so it has two, which can meet.
		check(named.size() >= (2 if q.given.f.t == "lin" else 1), "%s seed %d: %s" % [c.key, seed, str(q.choices.map(func(o): return [o.text, o.ref]))])
		if q.given.f.t == "lin":
			check(q.choices.any(func(o): return o.ref == "SL2.5.composite-expression#0") or q.choices.any(func(o): return o.ref == "SL2.5.find-inverse#1"),
				"%s seed %d: no order slip" % [c.key, seed]), ["mcq"])
	check(tried[0] > 0, "no one-x composite equation was tried")


## Two values can't fix a quadratic g: three inputs, and the degree said.
func test_inner_from_composite_numeric_check_uses_enough_inputs() -> void:
	var quad := [0]
	_each(COMP, "inner-from-composite", func(q, c, seed):
		if c.angle != "numeric-check":
			return
		var t := " || ".join(_steps(q, "numeric-check"))
		if q.given.g.t == "poly":
			quad[0] += 1
			check("x = −1: g(−1)" in t and "three values" in t, "%s seed %d: %s" % [c.key, seed, t])
		else:
			check("two values" in t, "%s seed %d: %s" % [c.key, seed, t])
		check("(f∘g)(x)" in t and not "(h −" in t and not "(h +" in t, "%s seed %d: %s" % [c.key, seed, t]))
	check(quad[0] > 0, "no quadratic g was tried")


## Negative divisors are bracketed, and undoing "add −4" is written + 4.
func test_inner_from_composite_brackets_and_signs() -> void:
	_each(COMP, "inner-from-composite", func(q, c, seed):
		var t := _all_steps(q)
		check(not "÷ −" in t, "%s seed %d: %s" % [c.key, seed, t])
		check(not "− (−" in t, "%s seed %d: %s" % [c.key, seed, t]))


## No composite working divides by a bare negative: "84 ÷ (−14)", not "84 ÷ −14".
func test_composite_working_brackets_a_negative_divisor() -> void:
	var units := {}
	for c in QuestionEngine.cells(false, [COMP]):
		units[c.unknown] = true
	for u in units:
		_each(COMP, u, func(q, c, seed):
			var t := _all_steps(q)
			check(not "÷ −" in t, "%s seed %d: %s" % [c.key, seed, t]), ["mcq"])


## Where a named slip exists, the key with 1 added or doubled is no option: the bracket
## slips and the fillers with no route come first.
func test_composite_fillers_beside_the_key_give_way() -> void:
	for u in ["expression", "self-composite"]:
		var counts := [0, 0, 0]
		_each(COMP, u, func(q, c, seed):
			counts[0] += 1
			var v: Dictionary = q.answer.values
			var plus1 := v.duplicate()
			var last := "c%d" % (v.size() - 1)
			plus1[last] = v[last].add(1)
			var twice := {}
			for k in v:
				twice[k] = v[k].mul(2)
			for o in q.choices:
				if o.correct:
					continue
				if Answer.canon(q.answer, o.values) == Answer.canon(q.answer, plus1) or Answer.canon(q.answer, o.values) == Answer.canon(q.answer, twice):
					counts[1] += 1
			if q.choices.any(func(o): return o.ref in [COMP + "#21", COMP + "#22"]):
				counts[2] += 1, ["mcq"])
		check(counts[1] * 20 <= counts[0], "%s: key + 1 or 2 × key in %d of %d" % [u, counts[1], counts[0]])
		check(counts[2] * 2 >= counts[0], "%s: a bracket slip in only %d of %d" % [u, counts[2], counts[0]])
