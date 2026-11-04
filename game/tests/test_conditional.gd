extends "res://tests/test_case.gd"
## The conditional situation (FAL-725): t4-conditional-probability is built with every cell and
## all four skills, each cell makes four options with one right, the ratios match hand values,
## normal and binomial conditionals are Paper 2, tree and shaded figures are drawn, every option
## is a probability, and every misconception shows up. The SymPy checker (tools/check-answers)
## checks the maths.

const TYPE := "t4-conditional-probability"
const CELLS := 46


func _make(c: Dictionary, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var view := {"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 4, "every listed skill has a question")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check(q.solutions[0].angle == c.angle, c.key)


func test_the_paper_follows_the_skill() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var want: Array = [2] if c.unknown in ["conditional-normal", "conditional-binomial"] else [1, 2]
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), want, c.key)


func test_a_tree_gives_the_reversed_conditional() -> void:
	for i in 60:
		var s: Dictionary = ConditionalSituation.generate(Seeded.new("t|%d" % i), {"ask": "reverse-from-tree", "paper": 1})
		var both: Q = s.pa.mul(s.pba)
		var rest: Q = Q.new(1).sub(s.pa).mul(s.pbn)
		check(s.v.eq(both.div(both.add(rest))), "draw %d" % i)
	var q := QuestionEngine.make({"type": TYPE, "unknown": "reverse-from-tree", "rep": "diagram", "angle": "path-over-paths", "seed": 2})
	check_eq(q.graph.kind, "tree")
	check_eq(q.graph.q.size(), 2, "two second stages")


func test_two_draws_match_a_hand_value() -> void:
	var s := {"paper": 1, "r": 3, "g": 2}
	# 3 red, 2 blue: RR is 6 ordered pairs, BB is 2, so 6 of 8.
	var top: int = s.r * (s.r - 1)
	check(Q.new(top, top + s.g * (s.g - 1)).eq(Q.new(3, 4)), "3/4")


func test_a_normal_conditional_is_a_ratio_of_areas() -> void:
	for i in 60:
		var s: Dictionary = ConditionalSituation.generate(Seeded.new("n|%d" % i), {"ask": "conditional-normal", "paper": 2})
		check(s.num < s.den, "draw %d: the wanted region is inside the given one" % i)
		check(absf(s.v - s.num / s.den) < 1e-12, "draw %d" % i)
	var q := QuestionEngine.make({"type": TYPE, "unknown": "conditional-normal", "rep": "diagram", "angle": "shade-regions", "seed": 2})
	check_eq(q.graph.shade.size(), 2, "the given and the wanted are both shaded")


func test_every_option_is_a_probability() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.unknown == "unknown-from-conditional":
			continue
		for seed in range(1, 20):
			for o in _make(c, seed).choices:
				var v: float = Q.of(o.values.v).to_float()
				check(v > 0.0 and v < 1.0, "%s seed %d: option %s" % [c.key, seed, o.text])


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
	check(not TYPE in QuestionEngine.built_types("ai-sl"), "SL4.11 is not on AI SL")
