extends "res://tests/test_case.gd"
## The binomial situation (FAL-695): t4-binomial is built with every catalogue cell, every
## question is Paper 2, every probability and option is a probability, the numbers match
## hand values, the least n is the first that works, n and p from E(X) and Var(X) are
## exact, every distractor misconception shows up as an option, and answers are marked to
## 3 s.f. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t4-binomial"
## Cells, counted as tools/pedagogy.mjs counts them.
const CELLS := 33
## The unknowns whose answer is a probability (3 s.f.), so every option is between 0 and 1.
const PROBABILITIES := ["exact-probability", "at-most-probability", "at-least-probability", "between-probability",
	"kth-success-trial", "conditional-probability"]


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	check_eq(t.unknowns.size(), 12)
	var skills := {}
	for u in t.unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 6, "every SL4.8 skill has a question")


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		# An exam type offers no extra format (test_extension.gd holds that rule).
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3, 4, 5]:
				var q := _make(c.unknown, c.rep, c.angle, seed, f)
				check(not q.has("error"), "%s as %s seed %d: %s" % [c.key, f, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "binomial", c.key)
				check_eq(q.choices.size(), 4, "%s as %s: options" % [c.key, f])
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, "%s as %s: right options" % [c.key, f])
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s as %s: two options read the same" % [c.key, f])
				check(not q.solutions.is_empty() and q.solutions[0].angle == c.angle, "%s: the asked method is the first worked solution" % c.key)


func test_every_question_is_paper_2() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2], c.key)
		var q := _make(c.unknown, c.rep, c.angle, 3, "mcq")
		check_eq(q.paper, 2, c.key)


func test_same_seed_same_question_and_seeds_vary() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var a := _make(c.unknown, c.rep, c.angle, 7, "mcq")
		var b := _make(c.unknown, c.rep, c.angle, 7, "mcq")
		check_eq(a.prompt, b.prompt, c.key)
		check_eq(a.answer_text, b.answer_text, c.key)
		var answers := {}
		for seed in range(1, 13):
			answers[_make(c.unknown, c.rep, c.angle, seed, "mcq").answer_text] = true
		check(answers.size() > 3, "%s: only %d different answers in 12 seeds" % [c.key, answers.size()])


## p as the situation exports it ("7/20") written as a decimal ("0.35").
func _p_text(s: Dictionary) -> String:
	var parts: PackedStringArray = String(s.p).split("/")
	var v := float(parts[0]) / (float(parts[1]) if parts.size() > 1 else 1.0)
	return Fmt.dec(Q.new(roundi(v * 100.0), 100))


func test_the_stories_say_n_and_p() -> void:
	for seed in range(1, 25):
		var q := _make("exact-probability", "words", "gdc-binompdf", seed, "mcq")
		var s: Dictionary = q.situation
		check(q.lines[0].contains("%d " % int(s.n)), "seed %d: the story gives n = %s: %s" % [seed, s.n, q.lines[0]])
		check(q.lines[0].contains(" " + _p_text(s)), "seed %d: the story gives p = %s: %s" % [seed, _p_text(s), q.lines[0]])
		var e := _make("exact-probability", "equation", "gdc-binompdf", seed, "mcq")
		check_eq(e.lines[0], "X ~ B(%d, %s)" % [int(e.situation.n), _p_text(e.situation)], "seed %d" % seed)


func test_probabilities_match_hand_values() -> void:
	check(absf(BinomialSituation.pmf(10, 0.5, 5) - 0.24609375) < 1e-12, "10C5 / 1024")
	check(absf(BinomialSituation.pmf(4, 0.25, 0) - 0.31640625) < 1e-12, "0.75^4")
	check(absf(BinomialSituation.cdf(3, 0.5, 1) - 0.5) < 1e-12, "half of B(3, 0.5) is at most 1")
	check(absf(BinomialSituation.cdf(5, 0.3, 5) - 1.0) < 1e-12, "the whole distribution adds to 1")
	check(BinomialSituation.cdf(5, 0.3, -1) == 0.0, "nothing is below 0")
	check(absf(BinomialSituation.comb(20, 10) - 184756.0) < 1e-6, "20C10")
	# The third success on the 5th trial: 4C2 p^3 q^2.
	var s := {"p": Q.new(1, 2), "k": 3, "m": 5}
	check(absf(BinomialSituation.kth_prob(s) - 6.0 / 32.0) < 1e-12, "4C2 / 32")
	# P(X = 1 | X >= 1) for B(2, 0.5) = 0.5 / 0.75.
	var c := {"n": 2, "p": Q.new(1, 2), "k": 1}
	check(absf(BinomialSituation.cond_prob(c) - 2.0 / 3.0) < 1e-12, "2/3")


func test_every_probability_and_option_is_a_probability() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if not c.unknown in PROBABILITIES and c.unknown != "std-deviation":
			continue
		for seed in range(1, 25):
			var q := _make(c.unknown, c.rep, c.angle, seed, "mcq")
			for o in q.choices:
				var v: float = Q.of(o.values.v).to_float()
				if c.unknown == "std-deviation":
					check(v > 0.0, "%s seed %d: option %s" % [c.key, seed, o.text])
				else:
					check(v > 0.0 and v < 1.0, "%s seed %d: option %s is not a probability" % [c.key, seed, o.text])


func test_the_least_n_is_the_first_that_works() -> void:
	for i in 200:
		var s: Dictionary = BinomialSituation.generate(Seeded.new("least|%d" % i), {"ask": "least-trials"})
		check(not s.is_empty(), "draw %d" % i)
		if s.is_empty():
			continue
		var q: float = s.q.to_float()
		var c: float = s.c.to_float()
		check(1.0 - pow(q, s.nn) > c, "draw %d: n = %d reaches %s" % [i, s.nn, s.c.text()])
		check(1.0 - pow(q, s.nn - 1) < c, "draw %d: n = %d does not" % [i, s.nn - 1])
		var x := BinomialSituation.least_x(s)
		check(absf(x - roundf(x)) >= BinomialSituation.LEAST_GAP - 1e-9, "draw %d: the quotient %s is clear of a whole number" % [i, x])


func test_n_and_p_from_the_mean_and_variance_are_exact() -> void:
	for i in 100:
		var s: Dictionary = BinomialSituation.generate(Seeded.new("np|%d" % i), {"ask": "n-and-p-from-mean-variance"})
		check(s.mean.eq(s.p.mul(Q.new(s.n))), "draw %d: E(X) = np" % i)
		check(s.variance.eq(s.p.mul(s.q).mul(Q.new(s.n))), "draw %d: Var(X) = npq" % i)
		check(s.variance.lt(s.mean), "draw %d: Var(X) < E(X)" % i)
		check(s.p.mul(Q.new(10)).is_int(), "draw %d: p is a multiple of 0.1" % i)
		var back: Q = s.mean.div(Q.new(1).sub(s.variance.div(s.mean)))
		check(back.eq(Q.new(s.n)), "draw %d: n = E(X) / (1 - Var(X)/E(X))" % i)


func test_the_mean_and_variance_ask_exact_and_the_deviation_3_sf() -> void:
	for seed in range(1, 15):
		var m := _make("mean-from-parameters", "equation", "np-npq", seed)
		check(m.answer.get("exact", false), "E(X) is exact")
		var v := _make("variance-from-parameters", "words", "np-npq", seed)
		check(v.answer.get("exact", false), "Var(X) is exact")
		var d := _make("std-deviation", "equation", "np-npq", seed)
		check_eq(d.answer.show, "sf", "the deviation is to 3 s.f.")
		check(not d.answer.get("exact", false), "and not exact")


func test_every_distractor_misconception_is_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for m in t.misconceptions:
		check_eq(m.as, "distractor", m.ref)
		for u in m["in"]:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 40):
					var q := _make(u, c.rep, c.angle, seed, "mcq")
					if q.choices.any(func(o): return o.ref == m.ref):
						found = true
						break
				if found:
					break
			check(found, "%s never appears on %s" % [m.ref, u])


func test_a_typed_answer_is_marked_to_3_sf_and_2_sf_is_glancing() -> void:
	var done := 0
	for seed in range(1, 30):
		var q := _make("exact-probability", "equation", "gdc-binompdf", seed, "value")
		var x: float = Q.of(q.answer.values.v).to_float()
		var right := QuestionEngine.mark(q, {"v": Fmt.sf(x, 3)})
		check(right.correct, "seed %d: %s is right" % [seed, Fmt.sf(x, 3)])
		var two := Fmt.sf(x, 2)
		# 0.180 and 0.18 are the same number: only a 2 s.f. answer that differs is glancing.
		if absf(float(two) - float(Fmt.sf(x, 3))) > 1e-9 and Answer.needs_rounding(Q.of(q.answer.values.v)):
			var r := QuestionEngine.mark(q, {"v": two})
			check(not r.correct and r.glancing, "seed %d: %s is a glancing hit" % [seed, two])
			done += 1
		check(not QuestionEngine.mark(q, {"v": Fmt.sf(x * 1.1, 3)}).correct, "seed %d: 10%% off is wrong" % seed)
	check(done > 10, "only %d 2 s.f. answers were tried" % done)


func test_exact_answers_are_marked_exactly() -> void:
	var q := _make("mean-from-parameters", "equation", "np-npq", 3)
	var v: Q = q.answer.values.v
	check(QuestionEngine.mark(q, {"v": Fmt.dec(v)}).correct, "the exact mean")
	check(not QuestionEngine.mark(q, {"v": Fmt.dec(v.add(Q.new(1, 10)))}).correct, "a tenth off")
	var swapped := 0
	for seed in range(1, 12):
		var np := _make("n-and-p-from-mean-variance", "equation", "divide-var-by-mean", seed)
		var vals: Dictionary = np.answer.values
		check(QuestionEngine.mark(np, {"v0": Fmt.dec(vals.v0), "v1": Fmt.dec(vals.v1)}).correct, "seed %d: n and p" % seed)
		# p = 0.5 is its own 1 - p.
		if not vals.v1.eq(Q.new(1, 2)):
			swapped += 1
			check(not QuestionEngine.mark(np, {"v0": Fmt.dec(vals.v0), "v1": Fmt.dec(Q.new(1).sub(vals.v1))}).correct, "seed %d: p and 1 - p swapped" % seed)
	check(swapped > 5, "only %d seeds with p other than 0.5" % swapped)


func test_probes_are_served() -> void:
	var mine := QuestionEngine.probes().filter(func(x): return x.type == TYPE)
	check_eq(mine.size(), 3)
	check_eq(QuestionEngine.probe(TYPE, 0).verdict, "False")
	check_eq(QuestionEngine.probe(TYPE, 1).verdict, "Sometimes")
	check_eq(QuestionEngine.probe(TYPE, 2).verdict, "True")


func test_the_binomial_is_in_the_courses_that_share_sl4_8() -> void:
	# SL4.8 is on all four syllabuses, so every course has every cell.
	for course in Courses.ids():
		check_eq(QuestionEngine.cells(false, [TYPE], course).size(), CELLS, course)
		check(TYPE in QuestionEngine.built_types(course), course)
