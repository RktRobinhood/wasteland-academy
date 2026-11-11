extends "res://tests/test_case.gd"
## The polynomial-conditions situation (FAL-776): t5-ext-unknown-coefficients and
## t5-ext-stationary-conditions are built with every cell. The picked letters meet every condition,
## the GDC's solver is Paper 2 and the rest Paper 1, every tag shows up as an option, error-spot is
## offered where the views build it, and no wrong option types as right. The SymPy checker
## (tools/check-answers) solves every question again.

const TYPES := {"t5-ext-unknown-coefficients": 14, "t5-ext-stationary-conditions": 14}
const S := preload("res://engine/situations/polynomial_conditions.gd")


func _make(t: String, c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": t, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _draw(ask: String, i: int, angle: String = "") -> Dictionary:
	return S.generate(Seeded.new("%s|%d" % [ask, i]), {"ask": ask, "angle": angle})


func test_both_types_are_built_with_every_cell() -> void:
	var built := QuestionEngine.built_types()
	for t in TYPES:
		check(t in built, "%s is not built" % t)
		check_eq(QuestionEngine.cells(false, [t]).size(), TYPES[t], t)


func test_every_cell_makes_a_question_on_its_paper() -> void:
	for t in TYPES:
		for c in QuestionEngine.cells(false, [t]):
			for f in ["value", "mcq"] + QuestionEngine.extra_formats(t, c.unknown, c.angle):
				for seed in [1, 2, 3]:
					var q := _make(t, c, seed, f)
					check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
					if q.has("error"):
						break
					check_eq(q.situation_id, "polynomial-conditions", c.key)
					check_eq(q.paper, 2 if c.angle == "gdc-solver" else 1, c.key)
					check_eq(q.choices.size(), 4, c.key)
					check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
					check_eq(q.solutions[0].angle, c.angle, c.key)
					for sol in q.solutions:
						check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])


func test_the_picked_letters_meet_the_conditions() -> void:
	for ask in PolynomialConditionsViews.UNKNOWNS:
		for i in 30:
			var s := _draw(ask, i)
			check(not s.is_empty(), "%s draw %d" % [ask, i])
			var d := S.deriv(s.terms)
			var x0: int = s.x0
			match ask:
				"k-from-gradient":
					check(S.value(d, x0, s.vals).eq(s.m), "%s %d: f′(x0)" % [ask, i])
				"two-from-gradient-and-point", "from-tangent":
					check(S.value(s.terms, x0, s.vals).eq(s.y0), "%s %d: f(x0)" % [ask, i])
				"two-gradients":
					check(S.value(d, s.x1, s.vals).eq(s.m1), "%s %d: f′(x1)" % [ask, i])
				"k-from-stationary-x", "two-from-stationary-point":
					check(S.value(d, x0, s.vals).is_zero(), "%s %d: not stationary" % [ask, i])
				"k-from-inflexion":
					check(S.value(S.deriv(d), x0, s.vals).is_zero(), "%s %d: f″(x0)" % [ask, i])
				"two-from-two-stationary":
					check(S.value(d, s.p, s.vals).is_zero() and S.value(d, s.q, s.vals).is_zero(), "%s %d: not stationary twice" % [ask, i])
			for l in s.vals:
				check(s.vals[l].is_int() and not s.vals[l].is_zero(), "%s %d: %s" % [ask, i, l])


func test_the_sums_match_hand_values() -> void:
	# f(x) = ax³ + bx with a = 2, b = −1: f′(1) = 6 − 1 = 5 and f(1) = 2 − 1 = 1.
	var terms := [S.T(1, "a", 3), S.T(1, "b", 1)]
	var vals := {"a": Q.new(2), "b": Q.new(-1)}
	check_eq(S.value(S.deriv(terms), 1, vals).text(), "5")
	check_eq(S.value(terms, 1, vals).text(), "1")
	# 3a + b = 5 and a + b = 1 give a = 2, b = −1.
	var sol := S.solve_pair([[S.deriv(terms), 1, 5], [terms, 1, 1]], ["a", "b"])
	check_eq([sol[0].text(), sol[1].text()], ["2", "−1"])


func test_every_tag_shows_up_as_an_option() -> void:
	for t in TYPES:
		var seen := {}
		for c in QuestionEngine.cells(false, [t]):
			for seed in range(1, 8):
				for o in _make(t, c, seed).choices:
					if o.ref != "":
						seen[o.ref] = true
		for m in QuestionEngine.type_of(t).misconceptions:
			if m.as == "distractor":
				check(seen.has(m.get("ref", "")) or seen.has(_own_ref(t, m)), "%s: %s never shows" % [t, m.get("ref", m.text)])


func _own_ref(t: String, m: Dictionary) -> String:
	var ms: Array = QuestionEngine.type_of(t).misconceptions
	return "%s#%d" % [t, ms.find(m)]


func test_error_spot_shows_one_slip_and_its_line() -> void:
	for t in TYPES:
		for c in QuestionEngine.cells(false, [t]):
			if not "error-spot" in QuestionEngine.extra_formats(t, c.unknown, c.angle):
				continue
			for seed in range(1, 6):
				var q := _make(t, c, seed, "error-spot")
				check_eq(q.spot.lines.size(), 4, c.key)
				check(q.choices[q.spot.bad].correct, c.key + ": the bad line is not the right option")


func test_no_wrong_option_types_as_right() -> void:
	for t in TYPES:
		for c in QuestionEngine.cells(false, [t]):
			for seed in range(1, 6):
				var q := _make(t, c, seed, "value")
				for o in q.choices:
					if not o.correct:
						check(not Answer.values_right(q.answer, o.values, true), "%s: %s types as right" % [c.key, o.text])
