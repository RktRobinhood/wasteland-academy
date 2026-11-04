extends "res://tests/test_case.gd"
## The sampling situation (FAL-726): t4-sampling is built with every cell and both skills, every
## cell makes four options with one right on both papers, each group is a whole multiple of the
## interval, a disadvantage is true of its technique, every misconception shows up, and SL4.1 is in
## every course. The SymPy checker (tools/check-answers) checks the answers.

const TYPE := "t4-sampling"
const CELLS := 26


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
	check_eq(skills.size(), 2, "both listed skills have a question")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for paper in [1, 2]:
			for seed in range(1, 8):
				var q := _make(c, seed, "mcq", paper)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					continue
				check_eq(q.paper, paper, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.solutions[0].angle, c.angle, c.key)


func test_every_group_is_a_whole_multiple_of_the_interval() -> void:
	for i in 80:
		for paper in [1, 2]:
			var s := SamplingSituation.generate(Seeded.new("g|%d" % i), {"ask": "quota-number", "paper": paper})
			check_eq(s.N, s.n * s.k, "draw %d" % i)
			var total := 0
			for j in 3:
				check_eq(s.G[j], s.q[j] * s.k, "draw %d" % i)
				total += s.q[j]
			check_eq(total, s.n, "draw %d" % i)


func test_a_wrong_disadvantage_is_false_of_the_technique() -> void:
	for tech in SamplingViews.MAIN_FLAW:
		check(not SamplingViews.MAIN_FLAW[tech] in SamplingViews.FALSE_FLAWS[tech], tech)
		check(SamplingViews.FALSE_FLAWS[tech].size() >= 3, tech)


func test_the_most_under_represented_group_is_not_the_smallest_count() -> void:
	for i in 60:
		var s := SamplingSituation.generate(Seeded.new("u|%d" % i), {"ask": "under-represented", "paper": 1 + i % 2})
		var total := 0
		for v in s.got:
			total += v
		check_eq(total, s.n, "draw %d" % i)
		check(s.got[s.g] != s.got.min(), "draw %d: the raw counts give it away" % i)


func test_paper_2_has_larger_numbers() -> void:
	for i in 40:
		var one := SamplingSituation.generate(Seeded.new("p|%d" % i), {"ask": "name-technique", "paper": 1})
		var two := SamplingSituation.generate(Seeded.new("p|%d" % i), {"ask": "name-technique", "paper": 2})
		check(one.n <= 40 and two.n >= 40, "draw %d" % i)


func test_every_distractor_misconception_is_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for m in t.misconceptions:
		for u in m["in"]:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 60):
					if _make(c, seed).choices.any(func(o): return o.ref == m.ref):
						found = true
						break
			check(found, "%s never appears on %s" % [m.ref, u])


func test_the_type_is_in_every_course() -> void:
	for course in Courses.ids():
		check(TYPE in QuestionEngine.built_types(course), course)
