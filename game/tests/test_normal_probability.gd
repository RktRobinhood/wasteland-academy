extends "res://tests/test_case.gd"
## The normal-probability situation (FAL-728): t4-normal-probability is built with every cell and
## its skill, every question is Paper 2 with one right option, it shares one normal distribution
## with normal-unknown, a diagram shades the region and the stem doesn't say it again, a variance
## is rooted, a recorded value is half a unit either side, a middle from two tails is exact, and
## every misconception shows up. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t4-normal-probability"
const CELLS := 99


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _ask(ask: String, seed: int) -> Dictionary:
	return NormalProbabilitySituation.generate(Seeded.new("%s|%d" % [ask, seed]), {"ask": ask})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	check_eq(QuestionEngine.type_of(TYPE).unknowns.size(), 13)


func test_every_cell_makes_a_paper_2_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.paper, 2, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check(q.solutions[0].angle == c.angle, c.key)


func test_there_is_one_normal_distribution() -> void:
	for z in [-1.7, 0.0, 0.4, 2.1]:
		check_eq(NormalProbabilitySituation.phi(z), NormalUnknownSituation.phi(z), "phi(%s)" % z)
	check_eq(NormalProbabilitySituation.clear(0.1234), NormalUnknownSituation.clear(0.1234))
	check(NormalProbabilityViews.new() is NormalUnknownViews, "the views extend the curve's")


func test_regions_add_up() -> void:
	for i in 60:
		var s := _ask("prob-between", i)
		var below := NormalUnknownSituation.phi((s.lo.to_float() - s.muf) / s.sgf)
		check(absf(s.upper - below - s.p) < 1e-9, "draw %d: a band is the upper area less the lower" % i)
		var t := _ask("outside-interval", i)
		check(absf(t.p + t.other - 1.0) < 1e-12, "draw %d" % i)
		check(t.p > t.one, "draw %d: two tails hold more than one" % i)


func test_a_band_leaves_room_for_its_labels() -> void:
	for i in 60:
		var s := _ask("prob-between", i)
		check(s.hi.to_float() - s.lo.to_float() >= s.sgf, "draw %d" % i)
		var t := _ask("outside-interval", i)
		check(t.hi.to_float() - t.lo.to_float() >= 0.9 * t.sgf, "draw %d" % i)


func test_a_diagram_shades_the_region_and_the_stem_does_not_say_it() -> void:
	for seed in range(1, 12):
		var q := QuestionEngine.make({"type": TYPE, "unknown": "outside-interval", "rep": "diagram", "angle": "gdc-normalcdf", "seed": seed})
		check_eq(q.graph.kind, "normal")
		check_eq(q.graph.shade.size(), 2, "two tails are shaded")
		check_eq(q.graph.marks.size(), 3, "μ and both bounds are marked")
		check(not "X <" in q.asked, "the question doesn't state the region again")
		var e := QuestionEngine.make({"type": TYPE, "unknown": "prob-below", "rep": "equation", "angle": "gdc-normalcdf", "seed": seed})
		check(e.get("graph") == null, "the equation has no figure")


func test_a_variance_is_rooted() -> void:
	for i in 60:
		var s := _ask("variance-given", i)
		check(absf(s.sgf * s.sgf - s.variance) < 1e-9, "draw %d" % i)
		check(Fmt.sf(s.slip) != Fmt.sf(s.p), "draw %d: the slip shows" % i)


func test_a_negative_variable_has_area_below_zero() -> void:
	for i in 60:
		var s := _ask("negative-lower-tail", i)
		check(s.neg, "draw %d" % i)
		check(s.hi.sign() > 0, "draw %d" % i)
		check(s.p - s.zero > 0.02, "draw %d: starting at 0 loses real area" % i)


func test_a_recorded_value_is_half_a_unit_either_side() -> void:
	for i in 60:
		var s := _ask("recorded-value", i)
		check(s.hi.sub(s.lo).eq(s.u), "draw %d" % i)
		check(s.v.sub(s.lo).eq(s.hi.sub(s.v)), "draw %d" % i)
		check(s.wide > s.p and s.half_up < s.p, "draw %d" % i)


func test_exactly_k_uses_the_area_as_p() -> void:
	for i in 60:
		var s := _ask("exactly-in-sample", i)
		check(absf(s.pmf - BinomialSituation.pmf(s.n, s.p, s.k)) < 1e-12, "draw %d" % i)
		check(s.cum > s.pmf and s.k >= 1 and s.k < s.n, "draw %d" % i)


func test_a_middle_from_two_tails_is_exact() -> void:
	var c := {"unknown": "between-from-tails", "rep": "equation", "angle": "sketch-check"}
	for seed in range(1, 15):
		var q := _make(c, seed)
		check(q.answer.get("exact", false), "seed %d" % seed)
		check(q.choices.all(func(o): return o.values.v.to_float() > 0.0 and o.values.v.to_float() < 1.0), "seed %d: every option is a probability" % seed)
		var s := _ask("between-from-tails", seed)
		var mid := NormalUnknownSituation.phi((s.x2 - s.muf) / s.sgf) - NormalUnknownSituation.phi((s.x1 - s.muf) / s.sgf)
		check(absf(mid - s.mid.to_float()) < 1e-9, "seed %d: μ and σ give back the middle" % seed)


func test_every_distractor_misconception_is_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for i in t.misconceptions.size():
		var m: Dictionary = t.misconceptions[i]
		# The type's own misconceptions are numbered by place: the map's have a ref.
		var ref: String = m.get("ref", "%s#%d" % [TYPE, i])
		for u in m["in"]:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 80):
					if _make(c, seed).choices.any(func(o): return o.ref == ref):
						found = true
						break
			check(found, "%s never appears on %s" % [ref, u])


func test_aa_sl_has_it() -> void:
	check(TYPE in QuestionEngine.built_types("aa-sl"), "AA SL")
