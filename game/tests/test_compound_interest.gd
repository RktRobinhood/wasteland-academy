extends "res://tests/test_case.gd"
## The compound-interest situation (FAL-695): t1-compound-interest is built with every
## catalogue cell, the GDC cells are Paper 2 (a value by formula can be Paper 1), money answers are whole cents and clear of the
## half-cent rounding edge, the least years is the first that works, a rate is a quarter of a
## per cent, every distractor misconception shows up as an option, and answers are marked
## exactly (money, years) or to 3 s.f. (a rate). The SymPy checker (tools/check-answers)
## checks the maths.

const TYPE := "t1-compound-interest"
## Cells, counted as tools/pedagogy.mjs counts them.
const CELLS := 14


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "value", paper: int = 0) -> Dictionary:
	var view := {"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format}
	if paper > 0:
		view["paper"] = paper
	return QuestionEngine.make(view)


func _draw(ask: String, i: int) -> Dictionary:
	return CompoundInterestSituation.generate(Seeded.new("%s|%d" % [ask, i]), {"ask": ask})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	check_eq(t.unknowns.size(), 6)
	var skills := {}
	for u in t.unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 4, "every SL1.4 skill of the type has a question")


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		# An exam type offers no extra format (test_extension.gd holds that rule).
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3, 4, 5, 6]:
				var q := _make(c.unknown, c.rep, c.angle, seed, f)
				check(not q.has("error"), "%s as %s seed %d: %s" % [c.key, f, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "compound-interest", c.key)
				check(q.paper in [1, 2], c.key)
				check_eq(q.choices.size(), 4, "%s as %s: options" % [c.key, f])
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, "%s as %s: right options" % [c.key, f])
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s as %s: two options read the same" % [c.key, f])
				check(not q.solutions.is_empty() and q.solutions[0].angle == c.angle, "%s: the asked method is the first worked solution" % c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps in %s" % [c.key, sol.steps.size(), sol.name])


func test_the_gdc_cells_are_paper_2_and_the_formula_cells_for_a_value_can_be_paper_1() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var both: bool = c.unknown in ["future-value", "interest-earned"] and c.angle == "compound-formula"
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [1, 2] if both else [2], c.key)
		for seed in range(1, 9):
			var q := _make(c.unknown, c.rep, c.angle, seed, "mcq")
			check(q.paper in ([1, 2] if both else [2]), "%s seed %d: Paper %d" % [c.key, seed, q.paper])


func test_a_paper_1_value_is_annual_round_and_exact_by_hand() -> void:
	var seen := {}
	for unknown in ["future-value", "interest-earned"]:
		for i in 60:
			var s := CompoundInterestSituation.generate(Seeded.new("p1|%s|%d" % [unknown, i]), {"ask": unknown, "paper": 1})
			check(not s.is_empty(), "%s draw %d" % [unknown, i])
			if s.is_empty():
				continue
			check_eq(s.paper, 1)
			check_eq(s.k, 1, "annual compounding")
			check(s.n >= 2 and s.n <= 4, "n = %d" % s.n)
			# The value is exact in Q: PV (1 + r/100)^n has at most two decimal places.
			var factor := Q.new(1).add(s.r.div(Q.new(100)))
			var fv: Q = s.pv
			for j in s.n:
				fv = fv.mul(factor)
			check(Q.new(100).mul(fv).is_int(), "%s draw %d: %s is a whole number of cents" % [unknown, i, fv.text()])
			seen["%s|%d" % [s.r.text(), s.n]] = true
	check(seen.size() >= 6, "only %d different rates and years" % seen.size())
	var q := _make("future-value", "words", "compound-formula", 5, "value", 1)
	check_eq(q.paper, 1)
	check(q.answer.get("exact", false), "a Paper 1 value is exact")
	check(QuestionEngine.mark(q, {"v": Fmt.dec(q.answer.values.v)}).correct, "marked exactly")


func test_same_seed_same_question_and_seeds_vary() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var a := _make(c.unknown, c.rep, c.angle, 7, "mcq")
		var b := _make(c.unknown, c.rep, c.angle, 7, "mcq")
		check_eq(a.prompt, b.prompt, c.key)
		check_eq(a.answer_text, b.answer_text, c.key)
		check_eq(a.lines, b.lines, c.key)
		var seen := {}
		for seed in range(1, 13):
			seen[_make(c.unknown, c.rep, c.angle, seed, "mcq").answer_text] = true
		check(seen.size() > 3, "%s: only %d different answers in 12 seeds" % [c.key, seen.size()])


func test_the_value_matches_hand_values() -> void:
	check(absf(CompoundInterestSituation.value(1200.0, 5.0, 1, 3) - 1389.15) < 1e-9, "1200 at 5% for 3 years is 1389.15")
	check(absf(CompoundInterestSituation.value(2000.0, 4.0, 4, 5) - 2000.0 * pow(1.01, 20)) < 1e-9, "2000 at 4% quarterly")
	check(absf(CompoundInterestSituation.years_real(1000.0, 2000.0, 7.0, 1) - log(2.0) / log(1.07)) < 1e-12, "doubling at 7%")
	check_eq(CompoundInterestSituation.money(1389.1500000001).text(), "27783/20", "to the cent")
	check_eq(Fmt.money(CompoundInterestSituation.money(1389.15)), "1389.15")
	check_eq(Fmt.money(CompoundInterestSituation.money(1020.0)), "1020")
	# 12347.10 grown from 7500 at 7.25% half-yearly over 7 years: the rate comes back.
	var s := {"pv": Q.new(7500), "fv": Q.new(1234710, 100), "k": 2, "n": 7}
	check(absf(CompoundInterestSituation.rate_of(s) - 7.25) < 1e-3, "the rate from the shown numbers")


func test_every_money_value_is_clear_of_the_half_cent_edge() -> void:
	for ask in ["future-value", "interest-earned", "present-value", "compare-options"]:
		for i in 80:
			var s := _draw(ask, i)
			check(not s.is_empty(), "%s draw %d" % [ask, i])
			if s.is_empty():
				continue
			var xs: Array = []
			match ask:
				"future-value", "interest-earned":
					var fv := CompoundInterestSituation.value(s.pv.to_float(), s.r.to_float(), s.k, s.n)
					xs = [fv, fv - s.pv.to_float()]
				"present-value":
					xs = [s.fv.to_float() / pow(1.0 + s.r.to_float() / (100.0 * s.k), s.k * s.n)]
				"compare-options":
					var a := CompoundInterestSituation.value(s.pv.to_float(), s.r.to_float(), s.k, s.n)
					var b := CompoundInterestSituation.value(s.pv.to_float(), s.rb.to_float(), s.kb, s.n)
					xs = [a, b, a - b]
					check(a - b >= CompoundInterestSituation.DIFF_MIN, "%s draw %d: A is worth at least 20 more" % [ask, i])
			for x in xs:
				var c: float = x * 100.0
				check(absf(c - floorf(c) - 0.5) >= CompoundInterestSituation.CENT_EDGE - 1e-9, "%s draw %d: %s leaves %s of a cent" % [ask, i, x, c - floorf(c)])


func test_the_least_years_is_the_first_that_works() -> void:
	for i in 120:
		var s := _draw("time-needed", i)
		check(not s.is_empty(), "draw %d" % i)
		if s.is_empty():
			continue
		var pv: float = s.pv.to_float()
		var r: float = s.r.to_float()
		var target: float = s.target.to_float()
		check(CompoundInterestSituation.value(pv, r, s.k, s.years) > target, "draw %d: %d years pass %s" % [i, s.years, s.target.text()])
		check(CompoundInterestSituation.value(pv, r, s.k, s.years - 1) <= target, "draw %d: %d years do not" % [i, s.years - 1])
		var x := CompoundInterestSituation.years_real(pv, target, r, s.k)
		check(x - floorf(x) >= CompoundInterestSituation.YEAR_GAP - 1e-9 and x - floorf(x) <= 1.0 - CompoundInterestSituation.YEAR_GAP + 1e-9, "draw %d: %s is clear of a whole number" % [i, x])
		check(s.target.to_float() >= 1.2 * pv, "draw %d: the target is well above the amount" % i)


func test_a_rate_is_a_quarter_and_reads_differently_from_its_slips() -> void:
	for i in 100:
		var s := _draw("interest-rate", i)
		check(not s.is_empty(), "draw %d" % i)
		if s.is_empty():
			continue
		check(Q.new(4).mul(s.r).sub(Q.new(4).mul(s.r).mul(Q.new(1))).is_zero() and Q.new(400).mul(s.r).is_int(), "draw %d: the rate is a whole number of hundredths" % i)
		var found := CompoundInterestSituation.rate_of(s)
		check(absf(found - s.r.to_float()) < 0.01 and absf(found - s.r.to_float()) >= 1e-6, "draw %d: %s is a hair off the quarter %s" % [i, found, s.r.text()])
		var shown := {Fmt.sf(found): true, Fmt.sf(CompoundInterestSituation.slip_root(s)): true, Fmt.sf(CompoundInterestSituation.slip_share(s)): true}
		check_eq(shown.size(), 3, "draw %d: the answer and the two slips read differently" % i)


func test_two_accounts_differ_and_rounding_first_changes_nothing() -> void:
	for i in 100:
		var s := _draw("compare-options", i)
		check(not (s.r.eq(s.rb) and s.k == s.kb), "draw %d: the accounts differ" % i)
		var a := CompoundInterestSituation.value(s.pv.to_float(), s.r.to_float(), s.k, s.n)
		var b := CompoundInterestSituation.value(s.pv.to_float(), s.rb.to_float(), s.kb, s.n)
		check_eq(roundi(a * 100.0) - roundi(b * 100.0), roundi((a - b) * 100.0), "draw %d: the difference in cents" % i)
		var q := _make("compare-options", "words", "compute-both", i, "mcq")
		check(q.choices.any(func(o): return o.ref == CompoundInterestViews.R_NOMINAL_ONLY), "draw %d: the nominal-rate slip is an option" % i)


func test_a_table_shows_both_accounts() -> void:
	var q := _make("compare-options", "table", "compute-both", 4, "value")
	check(q.table != null and q.table.rows.size() == 3, "a table of two accounts")
	check_eq(q.table.rows[0], ["Account", ["A", "B"]])
	var w := _make("compare-options", "words", "compute-both", 4, "value")
	check(w.table == null and w.lines.size() == 2, "the words version has no table")


func test_every_distractor_misconception_is_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for m in t.misconceptions:
		check_eq(m.as, "distractor", m.ref)
		for u in m["in"]:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 60):
					var q := _make(u, c.rep, c.angle, seed, "mcq")
					if q.choices.any(func(o): return o.ref == m.ref):
						found = true
						break
				if found:
					break
			check(found, "%s never appears on %s" % [m.ref, u])


func test_money_and_years_are_marked_exactly_and_a_rate_to_3_sf() -> void:
	var m := _make("future-value", "words", "compound-formula", 3, "value")
	var v: Q = m.answer.values.v
	check(QuestionEngine.mark(m, {"v": Fmt.dec(v)}).correct, "the value to the cent")
	check(not QuestionEngine.mark(m, {"v": Fmt.dec(v.add(Q.new(1, 100)))}).correct, "a cent off")
	var y := _make("time-needed", "words", "logs", 3, "value")
	var n: Q = y.answer.values.v
	check(QuestionEngine.mark(y, {"v": Fmt.dec(n)}).correct, "the years")
	check(not QuestionEngine.mark(y, {"v": Fmt.dec(n.add(Q.new(1)))}).correct, "a year off")
	var done := 0
	for seed in range(1, 30):
		var q := _make("interest-rate", "words", "rearrange", seed, "value")
		var x: float = Q.of(q.answer.values.v).to_float()
		check_eq(q.answer.show, "sf", "a rate is to 3 s.f.")
		check(QuestionEngine.mark(q, {"v": Fmt.sf(x, 3)}).correct, "seed %d: %s is right" % [seed, Fmt.sf(x, 3)])
		var two := Fmt.sf(x, 2)
		if absf(float(two) - float(Fmt.sf(x, 3))) > 1e-9:
			var r := QuestionEngine.mark(q, {"v": two})
			check(not r.correct and r.glancing, "seed %d: %s is a glancing hit" % [seed, two])
			done += 1
		check(not QuestionEngine.mark(q, {"v": Fmt.sf(x * 1.1, 3)}).correct, "seed %d: 10%% off is wrong" % seed)
	check(done > 20, "only %d 2 s.f. answers were tried" % done)


func test_probes_are_served() -> void:
	var mine := QuestionEngine.probes().filter(func(x): return x.type == TYPE)
	check_eq(mine.size(), 3)
	check_eq(QuestionEngine.probe(TYPE, 0).verdict, "Always")
	check_eq(QuestionEngine.probe(TYPE, 1).verdict, "False")
	check_eq(QuestionEngine.probe(TYPE, 2).verdict, "True")


func test_the_type_is_in_every_course_that_shares_sl1_4() -> void:
	# SL1.4 is on all four syllabuses, so every course has every cell.
	for course in Courses.ids():
		check_eq(QuestionEngine.cells(false, [TYPE], course).size(), CELLS, course)
		check(TYPE in QuestionEngine.built_types(course), course)
