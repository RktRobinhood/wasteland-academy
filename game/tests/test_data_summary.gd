extends "res://tests/test_case.gd"
## The data-summary situation (FAL-695): t4-summary-statistics is built with every catalogue
## cell, the GDC cells are Paper 2 and the by-hand ones Paper 1, every list is shown out of
## order, a mode is unique, a Paper 1 mean ends in one decimal place and a Paper 2 mean
## needs 3 s.f., the quartiles are the medians of the halves, the missing value and
## frequency fit their mean, a combined mean is not the mean of the means, an outlier
## drags the mean, every distractor misconception shows up as an option, and answers are
## marked exactly (or to 3 s.f. for a Paper 2 mean). The SymPy checker
## (tools/check-answers) checks the maths.

const TYPE := "t4-summary-statistics"
## Cells, counted as tools/pedagogy.mjs counts them.
const CELLS := 30
const BY_HAND := ["missing-value-from-mean", "missing-frequency-from-mean", "combined-mean", "choose-average", "choose-spread"]
const CHOICES := ["choose-average", "choose-spread"]


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "value", paper: int = 0) -> Dictionary:
	var view := {"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format}
	if paper > 0:
		view["paper"] = paper
	return QuestionEngine.make(view)


func _ints(xs: Array) -> Array:
	return xs.map(func(x): return Q.new(x))


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	check_eq(t.unknowns.size(), 11)
	var skills := {}
	for u in t.unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 4, "every SL4.3 skill of the type has a question")


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
				check_eq(q.situation_id, "data-summary", c.key)
				check_eq(q.choices.size(), 4, "%s as %s: options" % [c.key, f])
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, "%s as %s: right options" % [c.key, f])
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s as %s: two options read the same" % [c.key, f])
				check(not q.solutions.is_empty() and (c.angle == "any" or q.solutions[0].angle == c.angle), "%s: the asked method is the first worked solution" % c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps in %s" % [c.key, sol.steps.size(), sol.name])


func test_the_gdc_is_paper_2_and_the_by_hand_unknowns_paper_1() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var papers := QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle)
		if c.angle == "gdc-1var":
			check_eq(papers, [2], c.key)
		elif c.unknown in BY_HAND:
			check_eq(papers, [1], c.key)
		else:
			check_eq(papers, [1, 2], c.key)
		for seed in range(1, 9):
			var q := _make(c.unknown, c.rep, c.angle, seed, "mcq")
			check(q.paper in papers, "%s seed %d: Paper %d" % [c.key, seed, q.paper])


func test_both_papers_are_asked_where_a_cell_can_make_both() -> void:
	for unknown in ["mean-of-data", "median-of-data", "quartiles-of-data"]:
		var seen := {}
		for seed in range(1, 60):
			seen[_make(unknown, "terms", "median-of-halves" if unknown == "quartiles-of-data" else ("sum-over-n" if unknown == "mean-of-data" else "ordered-position"), seed, "mcq").paper] = true
		check(seen.has(1) and seen.has(2), "%s makes both papers" % unknown)


func test_same_seed_same_question_and_seeds_vary() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var a := _make(c.unknown, c.rep, c.angle, 7, "mcq")
		var b := _make(c.unknown, c.rep, c.angle, 7, "mcq")
		check_eq(a.prompt, b.prompt, c.key)
		check_eq(a.answer_text, b.answer_text, c.key)
		check_eq(a.lines, b.lines, c.key)
		var seen := {}
		for seed in range(1, 13):
			var q := _make(c.unknown, c.rep, c.angle, seed, "mcq")
			seen[q.answer_text + "|" + str(q.lines) + "|" + str(q.table)] = true
		check(seen.size() > 3, "%s: only %d different questions in 12 seeds" % [c.key, seen.size()])


func test_summaries_match_hand_values() -> void:
	var odd := _ints([2, 4, 4, 5, 7, 9, 10])
	check(DataSummarySituation.median_of(odd).eq(Q.new(5)), "median of 7 values")
	var qs := DataSummarySituation.quartiles(odd)
	check(qs[0].eq(Q.new(4)) and qs[1].eq(Q.new(9)), "the median is left out of the halves when n is odd")
	var even := _ints([1, 2, 3, 4, 5, 6, 7, 8])
	check(DataSummarySituation.median_of(even).eq(Q.new(9, 2)), "median of 8 values")
	qs = DataSummarySituation.quartiles(even)
	check(qs[0].eq(Q.new(5, 2)) and qs[1].eq(Q.new(13, 2)), "the halves of 8 values")
	var m := DataSummarySituation.mode_of(_ints([3, 5, 3, 7]), [])
	check(m.value.eq(Q.new(3)) and m.count == 2 and m.unique, "mode of a list")
	var tie := DataSummarySituation.mode_of(_ints([3, 5, 3, 5]), [])
	check(not tie.unique, "two modes are not unique")
	var xs := _ints([1, 2, 3])
	var table := DataSummarySituation.expand(xs, [2, 5, 3])
	check_eq(table.size(), 10, "a table's total frequency")
	check(DataSummarySituation.median_of(table).eq(Q.new(2)), "median of a table")
	check(DataSummarySituation.mode_of(xs, [2, 5, 3]).value.eq(Q.new(2)), "mode of a table")
	check(DataSummarySituation.combined_mean({"n1": 10, "m1": 60, "n2": 30, "m2": 80}).eq(Q.new(75)), "the combined mean is not 70")
	check(DataSummarySituation.range_of(odd).eq(Q.new(8)), "range")
	check(absf(DataSummarySituation.sd_of(_ints([2, 4, 4, 4, 5, 5, 7, 9])) - 2.0) < 1e-12, "the standard deviation of the classic eight")


func _draw(ask: String, rep: String, paper: int, i: int) -> Dictionary:
	return DataSummarySituation.generate(Seeded.new("%s|%s|%d|%d" % [ask, rep, paper, i]), {"ask": ask, "rep": rep, "paper": paper})


func test_every_list_is_shown_out_of_order() -> void:
	for ask in ["mean-of-data", "median-of-data", "mode-of-data", "range-of-data", "quartiles-of-data", "iqr-of-data"]:
		for paper in [1, 2]:
			for i in 60:
				var s := _draw(ask, "terms", paper, i)
				check(not s.is_empty(), "%s Paper %d draw %d" % [ask, paper, i])
				if s.is_empty():
					continue
				var in_order := true
				for j in s.xs.size():
					if not s.xs[j].eq(s.data[j]):
						in_order = false
				check(not in_order, "%s Paper %d draw %d: the list is already in order" % [ask, paper, i])


func test_the_mean_is_by_hand_on_paper_1_and_to_3_sf_on_paper_2() -> void:
	for rep in ["terms", "table"]:
		for i in 80:
			var a := _draw("mean-of-data", rep, 1, i)
			check(DataSummarySituation.ends_in_one_place(a.mean), "%s draw %d: Paper 1 mean %s" % [rep, i, a.mean.text()])
			check(a.n <= 24, "%s draw %d: Paper 1 has %d values" % [rep, i, a.n])
			var b := _draw("mean-of-data", rep, 2, i)
			check(Answer.needs_rounding(b.mean), "%s draw %d: Paper 2 mean %s needs rounding" % [rep, i, b.mean.text()])
			check(Answer.rounds_clearly(b.mean.to_float(), DataSummarySituation.EDGE), "%s draw %d: Paper 2 mean is on a rounding edge" % [rep, i])
	var p1 := _make("mean-of-data", "terms", "sum-over-n", 3, "value", 1)
	check(p1.answer.get("exact", false) and p1.answer.show == "dec", "a Paper 1 mean is exact")
	var p2 := _make("mean-of-data", "terms", "sum-over-n", 3, "value", 2)
	check_eq(p2.answer.show, "sf", "a Paper 2 mean is to 3 s.f.")
	check(not p2.answer.get("exact", false), "and not exact")
	check(p2.asked.contains("to 3 s.f."), "and the question says so")


func test_a_mode_is_unique_and_not_its_own_count() -> void:
	for rep in ["terms", "table"]:
		for paper in [1, 2]:
			for i in 60:
				var s := _draw("mode-of-data", rep, paper, i)
				check(not s.is_empty(), "%s Paper %d draw %d" % [rep, paper, i])
				if s.is_empty():
					continue
				var m := DataSummarySituation.mode_of(s.xs, s.fs)
				check(m.unique and m.count >= 2, "%s Paper %d draw %d: a unique mode occurring twice or more" % [rep, paper, i])
				check(m.value.eq(s.mode) and m.count == s.mode_count, "%s Paper %d draw %d: the situation's mode" % [rep, paper, i])
				check(not Q.new(m.count).eq(m.value), "%s Paper %d draw %d: the count is not the mode" % [rep, paper, i])


func test_the_quartiles_are_the_medians_of_the_halves() -> void:
	for rep in ["terms", "table"]:
		for paper in [1, 2]:
			for i in 60:
				var s := _draw("quartiles-of-data", rep, paper, i)
				var d: Array = s.data
				var n := d.size()
				var h := n / 2
				var lower: Array = d.slice(0, h)
				var upper: Array = d.slice(h + (n % 2), n)
				check(s.q1.eq(DataSummarySituation.median_of(lower)) and s.q3.eq(DataSummarySituation.median_of(upper)), "%s Paper %d draw %d" % [rep, paper, i])
				check(s.q1.lt(s.q3), "%s Paper %d draw %d: Q1 < Q3" % [rep, paper, i])
				# At least a quarter of the values are at or below Q1, and at or above Q3.
				check(d.filter(func(x): return not x.lt(s.q1)).size() >= n * 3 / 4 - 1, "%s draw %d: three quarters are at least Q1" % [rep, i])


func test_the_median_has_an_odd_and_an_even_count() -> void:
	var odd := 0
	var even := 0
	for i in 80:
		var s := _draw("median-of-data", "terms", 1, i)
		if s.n % 2 == 1:
			odd += 1
		else:
			even += 1
	check(odd > 15 and even > 15, "median counts: %d odd, %d even" % [odd, even])


func test_the_missing_value_and_frequency_fit_the_mean() -> void:
	for i in 80:
		var s := _draw("missing-value-from-mean", "terms", 1, i)
		check(DataSummarySituation.mean_of(s.xs).eq(s.mean), "draw %d: the mean of the list with k in it" % i)
		check(DataSummarySituation.ends_in_one_place(s.mean) and not s.k.eq(s.mean), "draw %d: a clean mean, and k is not the mean" % i)
		var f := _draw("missing-frequency-from-mean", "table", 1, i)
		check(DataSummarySituation.mean_of(f.data).eq(f.mean), "draw %d: the mean of the table with p in it" % i)
		check(f.p.is_int() and f.n <= 40 and not f.mean.eq(f.xs[f.at]), "draw %d: p a whole number, a small table, M not the missing column's value" % i)
		check(f.xs[0].lt(f.mean) and f.mean.lt(f.xs[f.xs.size() - 1]), "draw %d: M is between the least and greatest value" % i)


func test_a_combined_mean_is_not_the_mean_of_the_means() -> void:
	for i in 80:
		var s := _draw("combined-mean", "words", 1, i)
		check(s.n1 != s.n2 and s.m1 != s.m2, "draw %d: different sizes and means" % i)
		check(not s.mean.eq(Q.new(s.m1 + s.m2, 2)), "draw %d: the combined mean differs from the mean of the means" % i)
		check(DataSummarySituation.ends_in_one_place(s.mean), "draw %d: a clean combined mean" % i)
		var q := _make("combined-mean", "words", "total-from-mean", i, "mcq")
		check(q.choices.any(func(o): return o.ref == DataSummaryViews.R_AVERAGE_MEANS), "draw %d: the mean of the means is an option" % i)


func test_the_outlier_drags_the_mean_and_the_measures_are_named() -> void:
	for i in 60:
		var s := _draw("choose-average", "words", 1, i)
		check(s.mean.to_float() >= 1.4 * s.median.to_float(), "draw %d: the mean %s is not well above the median %s" % [i, s.mean.text(), s.median.text()])
		var seen := {}
		for x in s.xs:
			seen[x.key()] = true
		check_eq(seen.size(), 8, "draw %d: the eight values are all different" % i)
		var a := _make("choose-average", "words", "outlier-skew-check", i, "mcq")
		check_eq(a.answer_text, "the median", "draw %d" % i)
		check_eq(a.choices.size(), 4, "draw %d" % i)
		var b := _make("choose-spread", "words", "outlier-skew-check", i, "mcq")
		check_eq(b.answer_text, "the interquartile range", "draw %d" % i)
		check(b.prompt.contains("outlier"), "draw %d: the question names the outlier" % i)


func test_a_missing_value_is_k_in_a_list_and_a_named_one_in_a_story() -> void:
	var a := _make("missing-value-from-mean", "terms", "total-from-mean", 4, "value", 1)
	check(a.answer_text.begins_with("k = "), a.answer_text)
	check(a.lines[0].contains("k"), "the list has a k")
	var b := _make("missing-value-from-mean", "words", "total-from-mean", 4, "value", 1)
	check(b.answer_text.begins_with("missing "), b.answer_text)
	check(b.lines[0].begins_with("The mean of "), b.lines[0])


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


func test_answers_are_marked_exactly_and_a_paper_2_mean_to_3_sf() -> void:
	var q := _make("median-of-data", "terms", "ordered-position", 3, "value", 1)
	var v: Q = q.answer.values.v
	check(QuestionEngine.mark(q, {"v": Fmt.dec(v)}).correct, "the median")
	check(not QuestionEngine.mark(q, {"v": Fmt.dec(v.add(Q.new(1, 2)))}).correct, "half a unit off")
	var done := 0
	for seed in range(1, 30):
		var m := _make("mean-of-data", "terms", "sum-over-n", seed, "value", 2)
		var x: float = Q.of(m.answer.values.v).to_float()
		check(QuestionEngine.mark(m, {"v": Fmt.sf(x, 3)}).correct, "seed %d: %s is right" % [seed, Fmt.sf(x, 3)])
		var two := Fmt.sf(x, 2)
		if absf(float(two) - float(Fmt.sf(x, 3))) > 1e-9:
			var r := QuestionEngine.mark(m, {"v": two})
			check(not r.correct and r.glancing, "seed %d: %s is a glancing hit" % [seed, two])
			done += 1
		check(not QuestionEngine.mark(m, {"v": Fmt.sf(x * 1.1, 3)}).correct, "seed %d: 10%% off is wrong" % seed)
	check(done > 10, "only %d 2 s.f. answers were tried" % done)
	# Both quartiles are needed.
	var qa := _make("quartiles-of-data", "terms", "median-of-halves", 5, "value", 1)
	var vals: Dictionary = qa.answer.values
	check(QuestionEngine.mark(qa, {"v0": Fmt.dec(vals.v0), "v1": Fmt.dec(vals.v1)}).correct, "both quartiles")
	check(not QuestionEngine.mark(qa, {"v0": Fmt.dec(vals.v1), "v1": Fmt.dec(vals.v0)}).correct, "the quartiles the wrong way round")


func test_probes_are_served() -> void:
	var mine := QuestionEngine.probes().filter(func(x): return x.type == TYPE)
	check_eq(mine.size(), 3)
	check_eq(QuestionEngine.probe(TYPE, 0).verdict, "Sometimes")
	check_eq(QuestionEngine.probe(TYPE, 1).verdict, "False")
	check_eq(QuestionEngine.probe(TYPE, 2).verdict, "False")


func test_the_type_is_in_every_course_that_shares_sl4_3() -> void:
	# SL4.3 is on all four syllabuses, so every course has every cell.
	for course in Courses.ids():
		check_eq(QuestionEngine.cells(false, [TYPE], course).size(), CELLS, course)
		check(TYPE in QuestionEngine.built_types(course), course)
