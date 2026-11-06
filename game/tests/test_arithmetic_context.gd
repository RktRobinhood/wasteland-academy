extends "res://tests/test_case.gd"
## The arithmetic-context situation (FAL-752): t1-arithmetic-in-context is built with every cell
## and both skills, on Paper 2. A target is never a term, the off-by-one cases really differ, data
## are nearly arithmetic and not exactly, and the figure is the sequence. The SymPy checker
## (tools/check-answers) checks the maths and judges every statement from the numbers.

const TYPE := "t1-arithmetic-in-context"
const CELLS := 88
const METHODS := ["identify-parameters", "tabulate", "average-difference", "gdc-regression",
	"solve-linear", "count-steps", "gdc-table", "graph-intersect"]
const CLAIMS := ["term-or-total", "comment-validity", "whole-n-test"]


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _draw(ask: String, i: int, rep: String = "words") -> Dictionary:
	return ArithmeticContextSituation.generate(Seeded.new("%s|%s|%d" % [ask, rep, i]), {"ask": ask, "rep": rep})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 2, "both skills have a question")


func test_every_method_the_map_lists_is_in_a_cell() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		seen[c.angle] = true
	for m in METHODS:
		check(seen.has(m), "%s has no cell" % m)


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2], c.key)
		for seed in [1, 2, 3]:
			var q := _make(c, seed)
			check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
			if q.has("error"):
				break
			check_eq(q.choices.size(), 4, c.key)
			check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
			check(q.solutions[0].angle == c.angle, c.key)


func test_only_a_judgement_is_multiple_choice_alone() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var q := _make(c, 3, "value")
		check_eq(q.format, "mcq" if c.unknown in CLAIMS else "value", c.key)


func test_a_target_is_not_a_term() -> void:
	for i in 40:
		var s := _draw("first-past", i)
		var before: Q = ArithmeticContextSituation.term(s, s.k - 1)
		var at: Q = ArithmeticContextSituation.term(s, s.k)
		check((before.lt(s.X) and s.X.lt(at)) or (at.lt(s.X) and s.X.lt(before)), "draw %d: the target is between two terms" % i)
		check(absf(s.real.to_float() - roundf(s.real.to_float())) >= ArithmeticContextSituation.EDGE, "draw %d" % i)


func test_a_running_total_passes_its_target_at_k() -> void:
	for i in 30:
		var s := _draw("first-total-past", i)
		check(ArithmeticContextSituation.total(s, s.k - 1).lt(s.X), "draw %d" % i)
		check(s.X.lt(ArithmeticContextSituation.total(s, s.k)), "draw %d" % i)


func test_after_n_is_one_term_on_from_in_n() -> void:
	var seen := {}
	for i in 40:
		var s := _draw("in-or-after", i)
		seen[s.case] = true
		var built: Dictionary = ArithmeticContextViews.new().build_view("in-or-after", "words", "identify-parameters", s, Seeded.new("after|%d" % i))
		var at: int = s.n + (1 if s.case == "after" else 0)
		check(built.answer.values.v.eq(ArithmeticContextSituation.term(s, at)), "draw %d: term %d" % [i, at])
	check_eq(seen.size(), 2, "both cases come up")


func test_a_value_is_a_term_or_it_is_not() -> void:
	var seen := {}
	for i in 40:
		var s := _draw("whole-n-test", i)
		seen[s.case] = true
		check_eq(s.real.is_int(), s.case == "yes", "draw %d" % i)
		check(not s.u1.div(s.d.abs_q()).is_int(), "draw %d: u₁ is not a multiple of d" % i)
		check_eq(s.v.div(s.d.abs_q()).is_int(), s.case == "no", "draw %d: the multiple test fails both ways" % i)
	check_eq(seen.size(), 2, "both cases come up")


func test_data_are_nearly_arithmetic() -> void:
	for i in 30:
		var s := _draw("estimate-d", i, "table")
		var c: Dictionary = ArithmeticContextSituation.DATA[s.ctx]
		var changes := {}
		for j in range(1, s.m):
			var ch: int = s.ys[j] - s.ys[j - 1]
			check(ch * c.sign > 0, "draw %d: every change has the story's sign" % i)
			changes[ch] = true
		check(changes.size() > 1, "draw %d: not exactly arithmetic" % i)
		check(s.avg.eq(Q.new(s.ys[s.m - 1] - s.ys[0], s.m - 1)), "draw %d" % i)


func test_a_comment_has_its_three_cases() -> void:
	var seen := {}
	for i in 60:
		var s := _draw("comment-validity", i, "table")
		seen[s.case] = true
		if s.case == "near":
			check(s.N - s.m <= 2, "draw %d" % i)
		if s.case == "far":
			check(s.N - s.m >= 3 * s.m, "draw %d" % i)
		if s.case == "capped":
			var c: Dictionary = ArithmeticContextSituation.DATA[s.ctx]
			if c.sign > 0:
				check(s.pa.to_float() > s.cap and s.pl.to_float() > s.cap, "draw %d: both pass the limit" % i)
			else:
				check(s.pa.sign() < 0 and s.pl.sign() < 0, "draw %d: both are below 0" % i)
	check_eq(seen.size(), 3, "every case comes up")


func test_the_peak_is_at_the_last_positive_term() -> void:
	for i in 30:
		var s := _draw("peak-total", i)
		check(ArithmeticContextSituation.term(s, s.k).sign() > 0, "draw %d" % i)
		check(ArithmeticContextSituation.term(s, s.k + 1).sign() <= 0, "draw %d" % i)


func test_the_figure_is_the_sequence() -> void:
	var c := {"unknown": "stack-total", "rep": "diagram", "angle": "identify-parameters"}
	for seed in range(1, 11):
		var q := _make(c, seed)
		var s: Dictionary = q.situation
		check_eq(q.graph.kind, "stages")
		check_eq(q.graph.stages.size(), 3)
		var biggest: Array = q.graph.stages[2]
		check_eq(biggest[0], Q.of(s.u1).n, "the top row is u₁")
		check_eq(biggest[1] - biggest[0], Q.of(s.d).n, "each row adds d")
		check_eq(q.graph.stages[1], biggest.slice(0, 2), "a row goes under the stack")


func test_the_figure_draws() -> void:
	var c := {"unknown": "stack-crates", "rep": "diagram", "angle": "gdc-table"}
	var view := PlotView.new()
	view.set_spec(_make(c, 1).graph)
	check_eq(view.custom_minimum_size.y, 300.0)
	view.free()


func test_a_crate_answer_is_the_first_multiple() -> void:
	for i in 30:
		var s := _draw("stack-crates", i)
		for k in range(1, s.k):
			check(ArithmeticContextSituation.total(s, k).n % s.c != 0, "draw %d: %d rows" % [i, k])
		check_eq(ArithmeticContextSituation.total(s, s.k).n % s.c, 0, "draw %d" % i)


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 25):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	for m in QuestionEngine.type_of(TYPE).misconceptions:
		check(seen.has(m.ref), "%s never comes up" % m.ref)
