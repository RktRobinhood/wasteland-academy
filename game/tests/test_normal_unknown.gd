extends "res://tests/test_case.gd"
## The normal-unknown situation (FAL-725): t4-normal-unknown-parameter is built with every cell
## and all three skills, every question is Paper 2 with one right option, each parameter gives
## back the area it came from, a bound for Z is exact and the inequality can be typed, every
## misconception shows up, and it stays out of the AI courses. The SymPy checker
## (tools/check-answers) checks the maths.

const TYPE := "t4-normal-unknown-parameter"
const CELLS := 53


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 3, "every listed skill has a question")


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


func test_phi_and_inv_match_table_values() -> void:
	check(absf(NormalUnknownSituation.phi(1.0) - 0.8413447461) < 1e-9, "Φ(1)")
	check(absf(NormalUnknownSituation.inv(0.75) - 0.6744897502) < 1e-8, "the upper quartile")
	check(absf(NormalUnknownSituation.inv(0.975) - 1.9599639845) < 1e-8, "the 97.5th percentile")


func test_each_parameter_gives_back_its_area() -> void:
	for i in 80:
		var s: Dictionary = NormalUnknownSituation.generate(Seeded.new("sd|%d" % i), {"ask": "unknown-sd"})
		var below := NormalUnknownSituation.phi((s.x - s.mu) / s.sg)
		var area: float = s.p.to_float() if s.side == "lt" else 1.0 - s.p.to_float()
		check(absf(below - area) < 1e-9, "draw %d: σ" % i)
		var m: Dictionary = NormalUnknownSituation.generate(Seeded.new("mean|%d" % i), {"ask": "unknown-mean"})
		var low := NormalUnknownSituation.phi((m.x - m.mu) / m.sg)
		check(absf(low - (m.p.to_float() if m.side == "lt" else 1.0 - m.p.to_float())) < 1e-9, "draw %d: μ" % i)
		var b: Dictionary = NormalUnknownSituation.generate(Seeded.new("both|%d" % i), {"ask": "mean-and-sd"})
		check(absf(NormalUnknownSituation.phi((b.x1 - b.mu) / b.sg) - b.a1) < 1e-9, "draw %d: the first tail" % i)
		check(absf(NormalUnknownSituation.phi((b.x2 - b.mu) / b.sg) - b.a2) < 1e-9, "draw %d: the second tail" % i)


func test_a_bound_for_z_is_typed_with_its_inequality() -> void:
	var c := {"unknown": "standardise-event", "rep": "equation", "angle": "standardise-bounds"}
	for seed in range(1, 15):
		var q := _make(c, seed, "value")
		var v: Dictionary = q.answer.values
		check(QuestionEngine.mark(q, {"rel": v.rel, "v": Fmt.dec(v.v)}).correct, "seed %d: the answer" % seed)
		var flip := ">" if v.rel == "<" else "<"
		check(not QuestionEngine.mark(q, {"rel": flip, "v": Fmt.dec(v.v)}).correct, "seed %d: reversed is wrong" % seed)


func test_a_mean_from_equal_tails_is_exact() -> void:
	var c := {"unknown": "mean-from-equal-tails", "rep": "equation", "angle": "symmetric-tails"}
	for seed in range(1, 10):
		check(_make(c, seed).answer.get("exact", false), "seed %d" % seed)


func test_a_diagram_shades_what_is_given() -> void:
	for seed in range(1, 10):
		var q := QuestionEngine.make({"type": TYPE, "unknown": "unknown-sd", "rep": "diagram", "angle": "gdc-solver", "seed": seed})
		check_eq(q.graph.kind, "normal")
		check_eq(q.graph.shade.size(), 1, "one tail is shaded")
		check_eq(q.graph.marks.size(), 2, "x and μ are marked")


func test_every_distractor_misconception_is_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for m in t.misconceptions:
		for u in m["in"]:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 80):
					if _make(c, seed).choices.any(func(o): return o.ref == m.ref):
						found = true
						break
			check(found, "%s never appears on %s" % [m.ref, u])


func test_only_the_aa_courses_have_it() -> void:
	check(TYPE in QuestionEngine.built_types("aa-sl"), "AA SL")
	check(not TYPE in QuestionEngine.built_types("ai-sl"), "SL4.12 is not on AI SL")
