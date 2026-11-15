extends "res://tests/test_case.gd"
## The always-increasing situation (FAL-776): t5-ext-always-increasing is built with every cell. f′
## really keeps one sign, the right argument is the asked method's, the GDC's least value is the
## least value, every tag shows up, and error-spot and method-pick are offered where built. The
## SymPy checker (tools/check-answers) writes every argument again from its own f′.

const TYPE := "t5-ext-always-increasing"
const CELLS := 8
const S := preload("res://engine/situations/always_increasing.gd")
const V := preload("res://engine/situations/always_increasing_views.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)


func test_every_cell_and_format_makes_a_question() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var fmts: Array = ["mcq"] + QuestionEngine.extra_formats(TYPE, c.unknown, c.angle)
		check(fmts.has("true-false-reason") and fmts.has("method-pick"), c.key + ": formats " + str(fmts))
		check_eq(fmts.has("error-spot"), c.unknown != "gdc-minimum", c.key + ": error-spot")
		for f in fmts:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.paper, 2 if c.unknown == "gdc-minimum" else 1, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.graph != null, c.rep == "graph", c.key + ": a graph on the graph view only")


func test_the_derivative_keeps_one_sign() -> void:
	for ask in ["quadratic-derivative", "decreasing-quadratic"]:
		for i in 40:
			var s := S.generate(Seeded.new("%s|%d" % [ask, i]), {"ask": ask})
			var c := V.fp_coeffs(s)
			check(c[1] * c[1] - 4 * c[0] * c[2] < 0, "%s %d: f′ has a root" % [ask, i])
			check_eq(c[0] > 0, ask == "quadratic-derivative", "%s %d: the sign" % [ask, i])
	for i in 40:
		var s := S.generate(Seeded.new("gdc|%d" % i), {"ask": "gdc-minimum"})
		check(s.v > 0.0, "draw %d: the least value is not above 0" % i)
		for k in 60:
			var x: float = s.xm - 3.0 + k * 0.1
			check(S.fp(s, x) >= s.v - 1e-9, "draw %d: f′(%f) is below the least value" % [i, x])


func test_the_sums_match_hand_values() -> void:
	# f′ = 3(x − 1)² + 2 = 3x² − 6x + 5: Δ = 36 − 60 = −24.
	var s := {"a": 1, "h": 1, "k": 2, "sg": 1, "d": 0}
	check_eq(V.fp_coeffs(s), [3, -6, 5])
	check_eq(V.vertex(s, 2), "3(x − 1)² + 2")
	# f′ = e^x − 2x + 1: least value at x = ln 2, 2 − 2 ln 2 + 1 = 1.6137.
	check(absf(S.fp({"A": 1, "m": 2, "n": 1}, log(2.0)) - 1.6137056) < 1e-6)


func test_every_tag_shows_up_as_an_option() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 6):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		if ms[i].as == "distractor":
			check(seen.has(ref), "%s never shows" % ref)


func test_error_spot_and_method_pick_keep_their_rules() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 6):
			var mp := _make(c, seed, "method-pick")
			var right: Array = mp.choices.filter(func(o): return o.correct)
			var named := QuestionEngine.method_name(QuestionEngine.type_of(TYPE), c.unknown, c.angle, {}, c.angle)
			check_eq(right[0].text, named.replace("f′", "g′") if c.unknown == "decreasing-quadratic" else named, c.key)
			if c.unknown == "gdc-minimum":
				continue
			var es := _make(c, seed, "error-spot")
			check_eq(es.spot.lines.size(), 4, c.key)
			check(es.choices[es.spot.bad].correct, c.key + ": the bad line")


## A decreasing question calls the function g: its method names, wrong methods and lines
## never switch to f (FAL-815).
func test_a_decreasing_question_says_g() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(c): return c.unknown == "decreasing-quadratic"):
		for seed in range(1, 6):
			for fmt in ["mcq", "method-pick", "true-false-reason", "error-spot"]:
				var q := _make(c, seed, fmt)
				var texts: Array = [q.prompt, q.get("reason", "")]
				for o in q.choices:
					texts.append(o.text)
					texts.append(QuestionEngine.misconception_text(QuestionEngine.type_of(TYPE), o.ref, q))
				for t in texts:
					check(not (t.contains("f′") or t.contains("f(") or t.contains("f is") or t.contains(" f ")), "%s %s: %s" % [c.key, fmt, t])
