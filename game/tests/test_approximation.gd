extends "res://tests/test_case.gd"
## The approximation situation (FAL-999): t1-ai-percentage-error and t1-ai-approx-bounds are built
## with every cell and all five AI SL 1.6 skills, only for the AI courses, Paper 2 throughout; every
## cell makes four options with one right; every tagged slip shows up; a rounded answer keeps its
## zeros; a bound is half a unit away. The SymPy checker (tools/check-answers) checks the maths.

const TYPES := {"t1-ai-percentage-error": 13, "t1-ai-approx-bounds": 7}
const SKILLS := ["AI-SL1.6.round-accuracy", "AI-SL1.6.percentage-error", "AI-SL1.6.estimate-reasonableness",
	"AI-SL1.6.bounds", "AI-SL1.6.max-percentage-error"]
const S := preload("res://engine/situations/approximation.gd")


func _make(t: String, c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": t, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_types_are_built_with_every_cell() -> void:
	var skills := {}
	for t in TYPES:
		check(t in QuestionEngine.built_types(), "%s is not built" % t)
		check_eq(QuestionEngine.cells(false, [t]).size(), TYPES[t], t)
		for u in QuestionEngine.type_of(t).unknowns:
			for s in u.skills:
				skills[s] = true
	for s in SKILLS:
		check(skills.has(s), "no unknown tests %s" % s)


func test_only_the_ai_courses_get_them() -> void:
	for t in TYPES:
		for course in ["aa-sl", "aa-hl"]:
			check(QuestionEngine.cells(false, [t], course).is_empty(), "%s offers %s" % [course, t])
		for course in ["ai-sl", "ai-hl"]:
			check_eq(QuestionEngine.cells(false, [t], course).size(), TYPES[t], "%s on %s" % [t, course])


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for t in TYPES:
		for c in QuestionEngine.cells(false, [t]):
			check(QuestionEngine.extra_formats(t, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
			check_eq(QuestionEngine.cell_papers(QuestionEngine.type_of(t), c.unknown, c.rep, c.angle), [2], c.key)
			for f in ["value", "mcq"]:
				for seed in range(1, 7):
					var q := _make(t, c, seed, f)
					check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
					if q.has("error"):
						break
					check_eq(q.situation_id, "approximation", c.key)
					check_eq(q.paper, 2, c.key)
					check_eq(q.choices.size(), 4, c.key)
					check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
					var texts := {}
					for o in q.choices:
						texts[o.text] = true
					check_eq(texts.size(), 4, c.key + ": two options read the same")
					check(q.solutions[0].angle == c.angle, c.key)
					for sol in q.solutions:
						check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
						check(Step.texts(sol.steps)[-1].contains(q.answer_text), "%s: the last step doesn't say %s" % [c.key, q.answer_text])


func test_every_distractor_shows_up() -> void:
	for t in TYPES:
		var seen := {}
		for c in QuestionEngine.cells(false, [t]):
			for seed in range(1, 61):
				for o in _make(t, c, seed).choices:
					if o.ref != "":
						seen[o.ref] = true
		var ty := QuestionEngine.type_of(t)
		var ms: Array = ty.misconceptions
		for i in ms.size():
			var ref: String = ms[i].get("ref", "%s#%d" % [t, i])
			check(seen.has(ref), "%s never comes up" % ref)
		for ref in seen:
			check(QuestionEngine.misconception_text(ty, ref) != "", "%s has no text" % ref)


func test_a_rounded_value_keeps_its_zeros() -> void:
	check_eq(S.round_to(Q.new(29962, 10000), 2).text(), "3")
	check_eq(ApproximationViews.written(S.round_to(Q.new(29962, 10000), 2), 2), "3.00")
	check_eq(ApproximationViews.written(S.round_to(Q.new(4567, 1000000), 5), 5), "0.00457")
	check_eq(S.round_to(Q.new(1234), -2).text(), "1200")
	# Rounding in stages carries a 4 up: 2.346 → 2.35 → 2.4, where 2.346 to 1 d.p. is 2.3.
	check_eq(Fmt.dec(S.staged(Q.new(2346, 1000), 3, 1)), "2.4")
	check_eq(Fmt.dec(S.round_to(Q.new(2346, 1000), 1)), "2.3")
	check_eq(Fmt.dec(S.cut_to(Q.new(2389, 1000), 2)), "2.38")


func test_a_typed_value_is_marked_by_its_value() -> void:
	var c := {"unknown": "round-figures", "rep": "words", "angle": "look-at-next-digit"}
	for seed in range(1, 6):
		var q := _make("t1-ai-percentage-error", c, seed, "value")
		var v: Q = q.answer.values.v
		check(QuestionEngine.mark(q, {"v": q.answer.values.text}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v": Fmt.dec(v.add(1))}).correct, "one more")


func test_bounds_are_half_a_unit_away() -> void:
	check_eq(Fmt.dec(S.bound(Q.new(73, 10), Q.new(1, 10), "lower")), "7.25")
	check_eq(Fmt.dec(S.bound(Q.new(73, 10), Q.new(1, 10), "upper")), "7.35")
	check_eq(Fmt.dec(S.bound(Q.new(3400), Q.new(100), "lower")), "3350")
	for seed in range(1, 21):
		var s := S.generate(Seeded.new("bound|%d" % seed), {"ask": "measurement-bound"})
		var b := S.bound(s.v, s.unit, s.side)
		check_eq(b.sub(s.v).abs_q().text(), s.unit.div(2).text(), str(s))


func test_the_largest_error_is_from_the_lower_bound() -> void:
	# A 2 cm side measured to the nearest cm: from 1.5, the area 4 is 4/2.25 − 1 = 77.8% too big.
	var s := {"shape": "square", "x": Q.new(2), "u": Q.new(1)}
	var e := S.max_error_slips(s)
	check(absf(e[0] - 77.7777778) < 1e-5, str(e))
	check(e[0] > e[2], "the upper bound gives the larger error")
	check(absf(S.error_of(Q.new(12), Q.new(10)) - 20.0) < 1e-9, "12 for 10 is a 20% error")
