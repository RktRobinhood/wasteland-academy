extends "res://tests/test_case.gd"
## The question engine on the triangle situation (FAL-395): both Topic 3 types are
## built, every triangle is well shaped, marking to 3 s.f. has no false failures, and
## every misconception shows up as an option. Paper 2 (a calculator, 3 s.f.) and
## Paper 1 (nice angles, exact answers) both (FAL-419). The SymPy checker
## (tools/check-answers) checks the maths.

const TYPES := ["t3-sine-cosine-rule", "t3-triangle-area"]
## Cells per type, counted as tools/pedagogy.mjs counts them.
const CATALOGUE_CELLS := {"t3-sine-cosine-rule": 16, "t3-triangle-area": 14}


## A question on Paper 2 (3 s.f. measures) unless another paper is asked for.
func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "value", paper: int = 2) -> Dictionary:
	var type := "t3-triangle-area" if unknown.contains("area") else "t3-sine-cosine-rule"
	return QuestionEngine.make({"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format,
		"paper": paper})


func _papers(c: Dictionary) -> Array:
	return QuestionEngine.cell_papers(QuestionEngine.type_of(c.type), c.unknown, c.rep, c.angle)


func test_both_types_are_built() -> void:
	var built := QuestionEngine.built_types()
	for t in TYPES:
		check(t in built, "%s is not built" % t)
		check_eq(QuestionEngine.cells(false, [t]).size(), CATALOGUE_CELLS[t], t)


func test_every_triangle_is_well_shaped() -> void:
	for c in QuestionEngine.cells(false, TYPES):
		for paper in _papers(c):
			for seed in range(1, 21):
				var q := QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed,
					"paper": paper})
				if q.has("error"):
					fail("%s seed %d: %s" % [c.key, seed, q.error])
					return
				var total := 0.0
				for L in ["A", "B", "C"]:
					var a := float(q.situation.angles[L])
					total += a
					check(a >= 20.0 and a <= 140.0, "%s seed %d: angle %s = %s" % [c.key, seed, L, a])
				check(absf(total - 180.0) < 1e-6, "%s seed %d: angles add to %s" % [c.key, seed, total])
				check_eq(q.paper, paper, c.key)
				if paper == 2:
					check(Answer.rounds_clearly(q.answer.values.v.to_float()), "%s seed %d: answer on a rounding edge" % [c.key, seed])


func test_the_papers_of_each_cell() -> void:
	for c in QuestionEngine.cells(false, TYPES):
		check_eq(_papers(c), [2] if c.unknown == "angle-sine-rule" else [1, 2], c.key)


func test_paper_2_needs_a_calculator() -> void:
	for c in QuestionEngine.cells(false, TYPES):
		for seed in range(1, 11):
			var q := QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "paper": 2})
			check_eq(q.answer.kind, "measure", c.key)
			check(not q.answer.get("exact", false), "%s: a Paper 2 measure is marked to 3 s.f." % c.key)
			var v: float = q.answer.values.v.to_float()
			check(not TriangleSituation._rational(v), "%s seed %d: %s needs no calculator" % [c.key, seed, q.answer_text])
			check(q.answer_text.contains(Fmt.sf(v)), "%s: %s is not to 3 s.f." % [c.key, q.answer_text])


func test_paper_1_is_exact() -> void:
	var kinds := {}
	for c in QuestionEngine.cells(false, TYPES):
		if not 1 in _papers(c):
			continue
		for seed in range(1, 16):
			var q := QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "paper": 1})
			var ans: Dictionary = q.answer
			kinds[ans.kind] = true
			check(ans.kind in ["number", "surd"] and ans.get("exact", false), "%s: %s answer" % [c.key, ans.kind])
			for L in q.given.angles:
				check(int(q.given.angles[L]) in TriangleSituation.NICE, "%s seed %d: angle %s°" % [c.key, seed, q.given.angles[L]])
			for v in ans.values.values():
				check(v.is_int() and v.sign() > 0, "%s seed %d: %s" % [c.key, seed, q.answer_text])
			check(not q.answer_text.contains("."), "%s: %s" % [c.key, q.answer_text])
			for sol in q.solutions:
				check(Answer.values_right(ans, sol.result), "%s: %s ends at %s" % [c.key, sol.name, sol.result])
				check(sol.steps[-1].contains(q.answer_text), "%s: %s last step %s" % [c.key, sol.name, sol.steps[-1]])
			# Exact marking: the exact value is right, a 3 s.f. decimal of a surd is not.
			var typed := {}
			for k in ans.values:
				typed[k] = ans.values[k].text()
			check(QuestionEngine.mark(q, typed).correct, "%s: exact answer marked wrong" % c.key)
			if ans.kind == "surd":
				var x: float = ans.values.m.to_float() * sqrt(ans.values.r.to_float())
				check(not QuestionEngine.mark(q, {"m": Fmt.sf(x), "r": "1"}).correct, "%s: a decimal for %s is right" % [c.key, q.answer_text])
	check(kinds.has("number") and kinds.has("surd"), "whole-number and surd answers: %s" % [kinds.keys()])


func test_paper_1_nice_triangles() -> void:
	# 3, 5, 7 with 120° and the like: the cosine rule's side is whole.
	for seed in range(1, 21):
		var q := _make("side-cosine-rule", "words", "cosine-rule", seed, "value", 1)
		var ang := int(q.given.angles.values()[0])
		var ys: Array = q.given.sides.values().map(func(v): return int(v))
		var x: int = q.answer.values.v.n
		check(ang in [60, 120], "seed %d: %d°" % [seed, ang])
		var x2: int = ys[0] * ys[0] + ys[1] * ys[1] + (ys[0] * ys[1] if ang == 120 else -ys[0] * ys[1])
		check_eq(x * x, x2, "seed %d" % seed)
	# The area's angle: obtuse and acute, from a whole or surd area.
	var obtuse := {}
	for seed in range(1, 41):
		var q := _make("angle-from-area", "words", "reverse-two-angles", seed, "mcq", 1)
		obtuse[q.given.obtuse] = true
		check(q.lines[0].contains("is obtuse" if q.given.obtuse else "is acute"), q.lines[0])
		check_eq(q.answer.values.v.n > 90, q.given.obtuse, q.answer_text)
	check_eq(obtuse.size(), 2, "both acute and obtuse angles on Paper 1")


func test_sine_rule_angle_has_one_triangle() -> void:
	for seed in range(1, 41):
		var q := _make("angle-sine-rule", "words", "sines-on-top", seed)
		var g: Dictionary = q.given
		var X: String = q.situation.X
		var Y: String = q.situation.Y
		check(int(g.sides[X.to_lower()]) > int(g.sides[Y.to_lower()]), "seed %d: the side opposite the given angle is not the longer one" % seed)
		check(float(q.situation.angles[Y]) < 90.0, "seed %d: the asked angle is obtuse" % seed)


func test_angle_from_area_says_acute_or_obtuse() -> void:
	var kinds := {}
	for seed in range(1, 41):
		var q := _make("angle-from-area", "words", "reverse-two-angles", seed)
		var obtuse: bool = q.given.obtuse
		kinds[obtuse] = true
		check(q.lines[0].contains("is obtuse" if obtuse else "is acute"), "seed %d: %s" % [seed, q.lines[0]])
		var x: float = q.answer.values.v.to_float()
		check(x > 100.0 if obtuse else x < 80.0, "seed %d: %s" % [seed, q.answer_text])
	check_eq(kinds.size(), 2, "both acute and obtuse angles are asked")


func test_words_and_diagram() -> void:
	var w := _make("side-cosine-rule", "words", "cosine-rule", 3)
	check(w.diagram == null, "words come without a diagram")
	check(w.lines[0].begins_with("In triangle ABC, "), w.lines[0])
	var d := _make("side-cosine-rule", "diagram", "cosine-rule", 3)
	check(d.diagram != null, "a diagram question has a diagram")
	var asked: Array = d.diagram.sides.filter(func(s): return s.label == "?")
	check_eq(asked.size(), 1, "one side is asked")
	check_eq(asked[0].side, d.given.ask)
	var labelled: Array = d.diagram.sides.filter(func(s): return s.label.ends_with(" cm"))
	check_eq(labelled.size(), 2, "two sides are given")


func test_three_significant_figures_without_false_failures() -> void:
	var q := _make("side-cosine-rule", "words", "cosine-rule", 5)
	var v: float = q.answer.values.v.to_float()
	var three := Fmt.sf(v)
	var four := Fmt.sf(v, 4)
	var five := Fmt.sf(v, 5)
	for typed in [three, four, five, String.num(v, 6)]:
		check(QuestionEngine.mark(q, {"v": typed}).correct, "%s for %s" % [typed, v])
	check(not QuestionEngine.mark(q, {"v": Fmt.sf(v, 2)}).correct or Fmt.sf(v, 2) == three, "2 s.f. %s" % Fmt.sf(v, 2))
	var unit := pow(10.0, floori(log(v) / log(10.0)) - 2)
	check(not QuestionEngine.mark(q, {"v": Fmt.sf(v + unit)}).correct, "one more in the 3rd figure is wrong")
	check(not QuestionEngine.mark(q, {"v": Fmt.sf(v - unit)}).correct, "one less in the 3rd figure is wrong")


func test_more_figures_rounded_right_are_right() -> void:
	# 12.35 is 12.3456 to 4 s.f.; it rounds to 12.4 itself, but it is right.
	var exact := Q.new(123456, 10000)
	check(Answer.number_right(Answer.parse_number("12.3").q, exact))
	check(Answer.number_right(Answer.parse_number("12.35").q, exact))
	check(Answer.number_right(Answer.parse_number("12.346").q, exact))
	check(not Answer.number_right(Answer.parse_number("12.4").q, exact))
	check(not Answer.number_right(Answer.parse_number("12.36").q, exact))
	check(not Answer.number_right(Answer.parse_number("12").q, exact))
	# 100 has three digits, but for 99.94 it is coarser than 3 s.f. (stress seed 327).
	check(not Answer.number_right(Q.new(100), Q.new(9994, 100)))
	check(Answer.number_right(Answer.parse_number("99.94").q, Q.new(99939, 1000)))
	check(Answer.number_right(Q.new(100), Q.new(99960, 1000)))


func test_significant_figures_format() -> void:
	var cases := {6.9993: "7.00", 1234.5: "1230", 0.012345: "0.0123", 999.7: "1000", 47.23: "47.2", 108.4: "108", 5.0: "5.00"}
	for x in cases:
		check_eq(Fmt.sf(x), cases[x], str(x))
	check_eq(Fmt.sf(12.3456, 4), "12.35")


func test_every_distractor_misconception_is_an_option() -> void:
	for id in TYPES:
		var t := QuestionEngine.type_of(id)
		for m in t.misconceptions:
			for u in m.in:
				var found := false
				for c in QuestionEngine.cells(false, [id]).filter(func(x): return x.unknown == u):
					for seed in range(1, 40):
						var q := QuestionEngine.make({"type": id, "unknown": u, "rep": c.rep, "angle": c.angle, "seed": seed, "format": "mcq",
							"paper": 2})
						if q.choices.any(func(o): return o.ref == m.ref):
							found = true
							break
					if found:
						break
				check(found, "%s: %s never appears on %s" % [id, m.ref, u])


func test_a_typed_misconception_is_recognised() -> void:
	# a² instead of a: typing the square of the side is named as forgetting the root.
	var q := _make("side-cosine-rule", "words", "cosine-rule", 2)
	var v: float = q.answer.values.v.to_float()
	var r := QuestionEngine.mark(q, {"v": Fmt.sf(v * v, 5)})
	check(not r.correct)
	check_eq(r.misconception, "SL3.2.cosine-rule-side#1")


func test_every_method_ends_at_the_answer() -> void:
	for c in QuestionEngine.cells(false, TYPES):
		var q := QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": 7, "paper": 2})
		var want: float = q.answer.values.v.to_float()
		for s in q.solutions:
			check(absf(s.result.v.to_float() - want) < 1e-6 * want, "%s: %s gives %s" % [c.key, s.name, s.result.v.to_float()])
			check(s.steps[-1].contains(q.answer_text), "%s: %s last step %s" % [c.key, s.name, s.steps[-1]])


func test_the_cosine_rule_angle_method_names_the_asked_angle() -> void:
	# FAL-412: "Substitute, then solve for cos B" when B is asked, not always cos A.
	var asked := {}
	for paper in [1, 2]:
		for seed in range(1, 31):
			var q := _make("angle-cosine-rule", "words", "substitute-then-solve", seed, "value", paper)
			var X: String = q.given.ask
			asked[X] = true
			var title := "Substitute, then solve for cos %s" % X
			check(q.prompt.contains("Method: %s." % title), "seed %d: %s" % [seed, q.prompt])
			var names: Array = q.solutions.map(func(s): return s.name)
			check(title in names, "seed %d: %s" % [seed, names])
	check(asked.size() > 1, "only angle %s is asked" % [asked.keys()])


func test_a_fraction_in_lowest_terms_is_written_once() -> void:
	# FAL-412: "103 / 392", not "103 / 392 = 103/392"; "301 / 364 = 43/52" still simplifies.
	check_eq(TriangleViews.over(103, 392), "103 / 392")
	check_eq(TriangleViews.over(-103, 392), "−103 / 392")
	check_eq(TriangleViews.over(301, 364), "301 / 364 = 43/52")
	check_eq(TriangleViews.over(24, 48), "24 / 48 = 1/2")


func test_working_figures_reach_the_next_step() -> void:
	# FAL-412: h = 10.47 cm made ½ × 16 × 10.47 = 83.76, not the 83.7 shown. More
	# figures are shown where four would be off; a tie (0.609375) takes them all.
	var half_base := func(xs: Array) -> float: return 0.5 * 16.0 * xs[0]
	check_eq(TriangleViews.figs([10.4651], half_base, 3), 5, "10.465")
	check_eq(TriangleViews.figs([12.0], half_base, 3), 4, "12.00 is enough")
	check(not TriangleViews.clear(39.0 / 64.0, 5, Fmt.sf(39.0 / 64.0, 5)), "0.609375 is a tie to 5 figures")
	check(TriangleViews.clear(39.0 / 64.0, 6, "0.609375"), "and clear to 6")
