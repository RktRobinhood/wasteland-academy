extends "res://tests/test_case.gd"
## The z-score situation (FAL-777): t4-ext-z-scores is built with every cell. z = (x − μ)/σ and
## x = μ + zσ agree, a comparison's better value really has the larger z (the smaller, for a
## time) while both slips point at the other, every tag shows up on each unknown it names, and
## error-spot and true-false-reason keep their rules. The SymPy checker (tools/check-answers)
## works every answer out again from what the question shows.

const TYPE := "t4-ext-z-scores"
const CELLS := 16
const S := preload("res://engine/situations/z_score.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)


func test_every_cell_and_format_makes_a_question() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var fmts: Array = ["mcq"] + QuestionEngine.extra_formats(TYPE, c.unknown, c.angle)
		check(fmts.has("true-false-reason"), c.key + ": true-false-reason")
		check_eq(fmts.has("error-spot"), c.unknown in ["z-from-x", "x-from-z"], c.key + ": error-spot")
		for f in fmts:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.paper, 2 if c.unknown.begins_with("compare-") else 1, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.graph != null, c.rep == "graph", c.key + ": the curve on the graph view only")


func test_z_and_x_agree() -> void:
	for ask in ["z-from-x", "x-from-z", "interpret-z"]:
		for i in 40:
			var s := S.generate(Seeded.new("%s|%d" % [ask, i]), {"ask": ask})
			check(s.x.eq(Q.new(s.mu).add(s.z.mul(Q.new(s.sg)))), "%s %d" % [ask, i])
			check(not s.z.is_zero() and s.x.is_int(), "%s %d: z or x" % [ask, i])
	# X ~ N(60, 8²): x = 72 is 1.5 standard deviations above.
	var v := ZScoreViews.new()
	var out := v.build("z-from-x", "equation", {"ctx": 0, "mu": 60, "sg": 8, "z": Q.new(3, 2), "x": Q.new(72), "paper": 1, "ask": "z-from-x"}, Seeded.new("x"))
	check(Q.of(out.answer.values.v).eq(Q.new(3, 2)), "z = 1.5")


func test_the_better_value_has_the_more_extreme_z() -> void:
	for ask in ["compare-scores", "compare-times"]:
		for i in 40:
			var s := S.generate(Seeded.new("%s|%d" % [ask, i]), {"ask": ask})
			var times: bool = ask == "compare-times"
			check(s.z2.lt(s.z1) if not times else s.z1.lt(s.z2), "%s %d: the z-values" % [ask, i])
			check(s.x1.lt(s.x2) if not times else s.x2.lt(s.x1), "%s %d: the raw values point the other way" % [ask, i])
			check(s.x1.sub(Q.new(s.mu1)).abs_q().lt(s.x2.sub(Q.new(s.mu2)).abs_q()), "%s %d: the gaps point the other way" % [ask, i])


func test_every_tag_shows_up_on_each_unknown_it_names() -> void:
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		if ms[i].as != "distractor":
			continue
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


func test_error_spot_marks_the_slip() -> void:
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown in ["z-from-x", "x-from-z"]):
		for seed in range(1, 6):
			var es := _make(c, seed, "error-spot")
			check_eq(es.spot.lines.size(), 4, c.key)
			check(es.choices[es.spot.bad].correct, c.key + ": the bad line")


func test_the_measure_in_the_key_is_not_the_only_one_named() -> void:
	# #193: only the key said "z-value" (or gave a percentage), which gave it away.
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == "compare-scores"):
		var cue := "%" if c.angle == "compare-percentiles" else "z-value"
		for seed in range(1, 10):
			var q := _make(c, seed)
			check(q.choices.filter(func(o): return o.correct)[0].text.contains(cue), c.key)
			check(q.choices.any(func(o): return not o.correct and o.text.contains(cue)), "%s seed %d: only the key names %s" % [c.key, seed, cue])
