extends "res://tests/test_case.gd"
## The rate-of-rate situation (FAL-777): t5-ext-interpret-second-derivative is built with every
## cell. The sentence follows f′ for the direction and f′ × f″ for the speed; a cubic model's
## marked moment is clear of its turning points and point of inflexion; every tag shows up on
## each unknown it names. The SymPy checker (tools/check-answers) works every sign out again.

const TYPE := "t5-ext-interpret-second-derivative"
const CELLS := 7
const S := preload("res://engine/situations/rate_of_rate.gd")
const V := preload("res://engine/situations/rate_of_rate_views.gd")


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
				check_eq(q.paper, 1, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				if c.rep == "graph":
					check(q.graph != null, "%s: no figure" % c.key)


func test_the_sentence_reads_both_layers() -> void:
	var st: Dictionary = S.STORIES[2]
	check_eq(V.sentence(st, 1, false), "The water level in a tank is rising, but more and more slowly.")
	check_eq(V.right_sentence({"story": 2, "s1": -1, "s2": 1}), "The water level in a tank is falling, but more and more slowly.")
	check_eq(V.right_sentence({"story": 2, "s1": -1, "s2": -1}), "The water level in a tank is falling more and more quickly.")
	# h(t) = −t³ + 6t² + 2t + 30 at t = 4: h′(4) = −48 + 48 + 2 = 2 and h″(4) = −24 + 12 = −12.
	check(S.d1([-1, 6, 2, 30], 4).eq(Q.new(2)))
	check(S.d2([-1, 6, 2, 30], 4).eq(Q.new(-12)))


func test_a_model_moment_has_the_signs_it_says() -> void:
	for i in 40:
		var s := S.generate(Seeded.new("m|%d" % i), {"ask": "from-model"})
		check_eq(S.d1(s.c, s.t0).sign(), s.s1, "draw %d" % i)
		check_eq(S.d2(s.c, s.t0).sign(), s.s2, "draw %d" % i)


func test_every_tag_shows_up_on_each_unknown_it_names() -> void:
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		for u in ms[i].in:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 40):
					if _make(c, seed).choices.any(func(o): return o.ref == ref):
						found = true
						break
				if found:
					break
			check(found, "%s never shows on %s" % [ref, u])
