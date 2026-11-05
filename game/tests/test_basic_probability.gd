extends "res://tests/test_case.gd"
## The basic-probability situation (FAL-728): t4-probability-basic is built with every catalogue
## cell and its three skills, every cell makes four options with one right on both papers, every
## option is a probability, the counts match hand values, the figures are drawn, a running relative
## frequency comes from real counts, Paper 1 is exact, and every misconception shows up as an
## option. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t4-probability-basic"
const CELLS := 37


func _make(c: Dictionary, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var view := {"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func _value(text: String) -> Q:
	return Answer.parse_number(text.split(" = ")[-1].replace("−", "-")).q


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	var skills := {}
	for u in t.unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 3, "every listed skill has a question")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for paper in [1, 2]:
				for seed in [1, 2, 3, 4]:
					var q := _make(c, seed, f, paper)
					check(not q.has("error"), "%s as %s seed %d: %s" % [c.key, f, seed, q.get("error")])
					if q.has("error"):
						break
					check_eq(q.paper, paper, c.key)
					check_eq(q.situation_id, "basic-probability", c.key)
					check_eq(q.choices.size(), 4, c.key)
					check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
					var texts := {}
					for o in q.choices:
						texts[o.text] = true
					check_eq(texts.size(), 4, "%s: two options read the same" % c.key)
					check(q.solutions[0].angle == c.angle, "%s: the asked method is the first worked solution" % c.key)


func test_every_option_is_a_probability() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 21):
			var q := _make(c, seed)
			for o in q.choices:
				var v: float = Q.of(o.values.v).to_float()
				check(v > 0.0 and v < 1.0, "%s seed %d: option %s" % [c.key, seed, o.text])


func test_paper_1_is_exact_and_paper_2_counts_are_rounded() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 11):
			var one := _make(c, seed, "mcq", 1)
			check(one.answer.get("exact", false), "%s seed %d: Paper 1 is exact" % [c.key, seed])
			var two := _make(c, seed, "mcq", 2)
			if two.situation.form == "sf":
				check(Answer.needs_rounding(two.answer.values.v), "%s seed %d: 3 s.f. needs rounding" % [c.key, seed])
				check(Answer.rounds_clearly(two.answer.values.v.to_float(), BasicProbabilitySituation.EDGE), "%s seed %d: on a rounding edge" % [c.key, seed])


func test_the_numbers_match_hand_values() -> void:
	check_eq(BasicProbabilitySituation.totals({"xs": [1, 2], "ys": [3, 4]}), [4, 5, 5, 6])
	check_eq(BasicProbabilitySituation.distinct([4, 5, 5, 6]), [4, 5, 6])
	var s := {"vals": [2, 5, 5, 8], "op": "least", "k": 5}
	check_eq(BasicProbabilitySituation.list_hits(s), 3)
	s.op = "more"
	check_eq(BasicProbabilitySituation.list_hits(s), 1)
	s.op = "less"
	check_eq(BasicProbabilitySituation.list_hits(s), 1)
	check_eq(BasicProbabilitySituation.card_numbers({"digits": [1, 2, 3]}), [123, 132, 213, 231, 312, 321])
	var half := Q.new(1, 2)
	var third := Q.new(1, 3)
	check(BasicProbabilitySituation.none_of([half, third]).eq(third), "1/2 × 2/3")
	check(BasicProbabilitySituation.exactly_one([half, third]).eq(half), "1/2 × 2/3 + 1/2 × 1/3")
	check(BasicProbabilitySituation.total_of([half, third]).eq(Q.new(5, 6)), "1/2 + 1/3")
	check_eq(BasicProbabilitySituation.rule_counts({"rule": "gap", "d": 1, "lo": 0, "hi": 0, "xs": [1, 2, 3], "ys": [1, 2, 3]}), [3, 4])
	check_eq(BasicProbabilitySituation.rule_counts({"rule": "ends", "d": 0, "lo": 3, "hi": 6, "xs": [1, 2, 3], "ys": [1, 2, 3]}), [3, 1])
	check(BasicProbabilitySituation.after_change({"counts": [3, 5], "target": 0, "changed": 0, "mode": "out", "m": 1}).eq(Q.new(2, 7)), "2/7")
	check(BasicProbabilitySituation.after_change({"counts": [3, 5], "target": 1, "changed": 0, "mode": "in", "m": 2}).eq(Q.new(1, 2)), "5/10")


func test_the_figures_are_shown() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var q := _make(c, 3)
		match c.unknown + "/" + c.rep:
			"two-way-whole/table":
				check_eq(q.table.rows[3][0], "Total", c.key)
				check_eq(q.table.rows.size(), 4, "a two-way table with its totals")
			"rf-from-table/graph":
				check_eq(q.graph.kind, "bars", c.key)
			"rf-graph-estimate/graph":
				check_eq(q.graph.kind, "cumfreq", c.key)
			"at-least-one-same/diagram", "at-least-one-different/diagram":
				check_eq(q.graph.kind, "tree", c.key)
			"grid-total-equals/diagram", "grid-total-at-least/diagram", "complement-count/diagram", "complement-two-rules/diagram":
				check(q.table != null and q.table.rows.size() >= 4, c.key + " shows its sample space")


func test_a_running_relative_frequency_is_real_counts() -> void:
	for i in 200:
		var s := BasicProbabilitySituation.generate(Seeded.new("curve|%d" % i), {"ask": "rf-graph-estimate", "rep": "graph", "paper": 1 + i % 2})
		check(not s.is_empty(), "seed %d makes a curve" % i)
		var hits := 0
		var step: int = s.curve[0][0]
		for p in s.curve:
			var now := roundi(float(p[1]) * float(p[0]))
			check(now >= hits and now - hits <= step, "seed %d: hits fall, or outrun the trials" % i)
			hits = now
		var last: float = s.curve[-1][1]
		check(absf(last - s.settle.to_float()) < 0.02, "seed %d: the curve doesn't reach %s" % [i, s.settle.text()])


func test_a_complement_differs_from_its_event() -> void:
	for u in ["complement-given", "complement-table"]:
		for i in 200:
			var s := BasicProbabilitySituation.generate(Seeded.new("%s|%d" % [u, i]), {"ask": u, "rep": "table", "paper": 1 + i % 2})
			if u == "complement-given":
				check(not s.p.eq(Q.new(1, 2)), "%s seed %d" % [u, i])
			else:
				check(int(s.counts[s.target]) * 2 != int(s.unit), "%s seed %d" % [u, i])


func test_every_misconception_shows_up_as_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var refs := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 41):
			for o in _make(c, seed).choices:
				if o.ref != "":
					refs[o.ref] = true
	for i in t.misconceptions.size():
		var ref: String = t.misconceptions[i].get("ref", "%s#%d" % [TYPE, i])
		check(refs.has(ref), "%s is never offered" % ref)
		check(not QuestionEngine.misconception_text(t, ref).is_empty(), "%s has no text" % ref)


func test_same_seed_same_question_and_seeds_vary() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(_make(c, 7).prompt, _make(c, 7).prompt, c.key)
		var answers := {}
		for seed in range(1, 25):
			var q := _make(c, seed)
			answers[q.prompt + q.answer_text + str(q.lines)] = true
		check(answers.size() > 3, "%s: only %d different questions in 24 seeds" % [c.key, answers.size()])
