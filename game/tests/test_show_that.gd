extends "res://tests/test_case.gd"
## The show-that-value situation (FAL-780): t1-ext-numerical-show-that is built with every cell, each
## stated result is true (exactly, or to the nearest cent), the one right working ends at the given
## value, its slips don't, and every tag shows up. The SymPy checker (tools/check-answers) reads each
## statement back, checks it, and writes the valid working again from the givens.

const TYPE := "t1-ext-numerical-show-that"
const CELLS := 8
const S := preload("res://engine/situations/show_that.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	for c in QuestionEngine.cells(false, [TYPE]):
		for f in ["mcq"] + QuestionEngine.extra_formats(TYPE, c.unknown, c.angle):
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
				if not q.has("error"):
					check_eq(q.paper, 2 if c.unknown == "interest-value" else 1, c.key)
					check(not q.prompt.contains(".."), q.prompt)


func test_each_stated_result_is_true() -> void:
	for i in 60:
		var l := S.generate(Seeded.new("log|%d" % i), {"ask": "log-difference"})
		check_eq(l.P, l.Q * S.ipow(l.b, l.k))
		var s := S.generate(Seeded.new("sum|%d" % i), {"ask": "series-sum"})
		var total := 0
		for t in s.n:
			total += s.u1 + t * s.d
		check_eq(s.V, total)
		var d := S.generate(Seeded.new("diff|%d" % i), {"ask": "common-difference"})
		check_eq((d.B - d.A) / (d.q - d.p), d.D)
		var m := S.generate(Seeded.new("money|%d" % i), {"ask": "interest-value"})
		check(absf(m.V.to_float() - m.exact) <= 0.005, "$%s is not %f to the cent" % [m.V.text(), m.exact])
		var v := S.generate(Seeded.new("verify|%d" % i), {"ask": "verify-solution"})
		check_eq(v.a * v.r * v.r + v.bb * v.r + v.cc, 0)


func test_the_answer_is_the_only_working_that_reaches_it() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 6):
			var q := _make(c, seed)
			check_eq(q.choices.filter(func(o): return o.correct).size(), 1)
			check(q.solutions[0].steps[-1] == q.answer_text, "%s: the working doesn't end with the answer" % c.key)


func test_every_tag_shows_up_as_an_option() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 15):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
			for f in QuestionEngine.extra_formats(TYPE, c.unknown, c.angle):
				var q := _make(c, seed, f)
				if q.has("spot"):
					seen[q.spot.ref] = true
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never shows" % ref)
