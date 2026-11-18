extends "res://tests/test_case.gd"
## The tvm situation (FAL-999): t1-ai-amortization and t1-ai-annuity are built with every cell and
## all six AI SL 1.7 skills, only for the AI courses, Paper 2 throughout; every cell makes four
## options with one right; every tagged slip shows up; the solver's sums agree with known values.
## The SymPy checker (tools/check-answers) works every value out again at 50 digits.

const TYPES := {"t1-ai-amortization": 13, "t1-ai-annuity": 12}
const SKILLS := ["AI-SL1.7.loan-repayment", "AI-SL1.7.loan-term-or-rate", "AI-SL1.7.outstanding-balance",
	"AI-SL1.7.total-interest-compare", "AI-SL1.7.savings-annuity", "AI-SL1.7.payout-annuity"]
const S := preload("res://engine/situations/tvm.gd")


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
					check_eq(q.situation_id, "tvm", c.key)
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


func test_the_solver_sums() -> void:
	# $20 000 at 6% compounded monthly over 5 years: about $386.66 a month.
	var p := S.payment(20000.0, S.rate(6.0, 12), 60)
	check(absf(p - 386.6560306) < 1e-6, "payment %f" % p)
	check(absf(S.balance(20000.0, 0.005, p, 60)) < 1e-6, "the loan is cleared")
	check(absf(S.periods(20000.0, 0.005, p) - 60.0) < 1e-9, "N")
	check(absf(S.solve_rate(20000.0, 60, p) - 6.0) < 1e-6, "the rate")
	# $200 a month at 3% compounded monthly for 10 years: about $27 948.
	check(absf(S.saved(0.0, 0.0025, 200.0, 120) - 27948.29) < 0.01, "savings")
	# Compounded quarterly, the monthly rate is 1.015^(1/3) − 1.
	check(absf(S.rate(6.0, 4) - (pow(1.015, 1.0 / 3.0) - 1.0)) < 1e-12, "quarterly")
	check(absf(S.payment_inverse(1500.0, S.rate(4.0, 12), 240) - 247533.0) < 1.0, "a fund")


func test_a_typed_amount_is_marked_to_the_cent() -> void:
	var c := {"unknown": "loan-payment", "rep": "words", "angle": "tvm-pmt"}
	for seed in range(1, 6):
		var q := _make("t1-ai-amortization", c, seed, "value")
		var v: Q = q.answer.values.v
		check(QuestionEngine.mark(q, {"v": Fmt.money(v)}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v": Fmt.money(v.add(Q.new(1, 100)))}).correct, "a cent more")


func test_the_cheaper_loan_has_the_higher_payment() -> void:
	for seed in range(1, 21):
		var s := S.generate(Seeded.new("compare|%d" % seed), {"ask": "compare-loans"})
		var L: float = s.L.to_float()
		var pa := S.payment(L, s.r.to_float() / 1200.0, 12 * s.n)
		var pb := S.payment(L, s.rb.to_float() / 1200.0, 12 * s.nb)
		var cheaper_a := S.interest_of(L, s.r.to_float(), s.n) < S.interest_of(L, s.rb.to_float(), s.nb)
		check_eq(cheaper_a, s.cheap == "A")
		check_eq(pa > pb, cheaper_a)
