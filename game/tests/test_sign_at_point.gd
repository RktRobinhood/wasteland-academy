extends "res://tests/test_case.gd"
## The sign-at-point situation (FAL-777): t5-ext-sign-at-point is built with every cell. The
## direction follows the sign of f′(a), never of f(a), which always points the other way; the
## right reason is the asked method's; every tag shows up on each unknown it names. The SymPy
## checker (tools/check-answers) differentiates every f again.

const TYPE := "t5-ext-sign-at-point"
const CELLS := 6
const S := preload("res://engine/situations/sign_at_point.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)


func test_every_cell_and_format_makes_a_question() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var fmts: Array = ["mcq"] + QuestionEngine.extra_formats(TYPE, c.unknown, c.angle)
		check_eq(fmts, ["mcq", "true-false-reason"], c.key)
		for f in fmts:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.paper, 2 if c.unknown == "gdc-check" else 1, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)


func test_f_and_its_gradient_point_opposite_ways() -> void:
	for i in 40:
		var s := S.generate(Seeded.new("f|%d" % i), {"ask": "from-formula"})
		check(S.value(s.c, s.a).sign() == -S.slope(s.c, s.a).sign(), "draw %d" % i)
		var g := S.generate(Seeded.new("g|%d" % i), {"ask": "gdc-check"})
		check(signf(g.fa) == -signf(g.fp), "gdc draw %d" % i)
	# f(x) = x³ − 2x² + 1 at x = 2: f′(2) = 12 − 8 = 4 and f(2) = 1.
	check(S.slope([1, -2, 0, 1], 2).eq(Q.new(4)))
	check(S.value([1, -2, 0, 1], 2).eq(Q.new(1)))


func test_the_right_reason_is_the_asked_methods() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 6):
			var q := _make(c, seed)
			var t: String = q.answer_text
			if c.angle == "compare-neighbours":
				check(t.contains(".99)") and not t.contains("′"), "%s: %s" % [c.key, t])
			elif c.angle == "gdc-dydx":
				check(t.contains("the GDC gives"), "%s: %s" % [c.key, t])
			else:
				check(t.contains("′("), "%s: %s" % [c.key, t])


func test_every_tag_shows_up_on_each_unknown_it_names() -> void:
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		for u in ms[i].in:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 25):
					if _make(c, seed).choices.any(func(o): return o.ref == ref):
						found = true
						break
				if found:
					break
			check(found, "%s never shows on %s" % [ref, u])
