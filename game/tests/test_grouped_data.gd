extends "res://tests/test_case.gd"
## The grouped-data situation (FAL-740): t4-grouped-data is built with every cell and all four of
## its skills, every cell makes four options with one right, the GDC stays off Paper 1, tables show
## their numbers, the modal class is one class, and every misconception shows up. The SymPy checker
## (tools/check-answers) checks the maths.

const TYPE := "t4-grouped-data"
const CELLS := 34


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
	check_eq(skills.size(), 4, "all four listed skills have a question")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "grouped-data", c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check(q.solutions[0].angle == c.angle, c.key)


func test_the_gdc_is_paper_2_only() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var p2_only := ["estimate-sd", "estimate-variance", "sd-from-table", "variance-from-table"]
	for c in QuestionEngine.cells(false, [TYPE]):
		var want: Array = [2] if c.angle in ["gdc-lists", "gdc-sigma"] or c.unknown in p2_only else [1, 2]
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), want, c.key)
		if 1 in want:
			for seed in range(1, 6):
				var q := _make(c, seed, "mcq", 1)
				for sol in q.solutions:
					check(not sol.angle in ["gdc-lists", "gdc-sigma"], "%s: a GDC method on Paper 1" % c.key)


func test_a_table_shows_its_numbers() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.rep != "table":
			continue
		for seed in range(1, 6):
			var q := _make(c, seed)
			check(q.table != null, c.key + ": no table")
			var rows: Array = q.table.rows
			check(rows.size() >= 4, c.key)
			for row in rows:
				check(row[1].size() >= 1, c.key)
				for cell in row[1]:
					check(str(cell) != "", c.key + ": an empty cell")


func test_a_missing_row_is_hidden() -> void:
	var cases := {"missing-frequency-from-total": "p", "missing-frequency-from-estimate": "p", "missing-frequency-from-median": "x"}
	for c in QuestionEngine.cells(false, [TYPE]):
		if not cases.has(c.unknown):
			continue
		for seed in range(1, 9):
			var q := _make(c, seed)
			var cells: Array = []
			for row in q.table.rows:
				cells.append(row[1][0])
			check_eq(cells.count(cases[c.unknown]), 1, c.key)


func test_the_modal_class_is_the_greatest_frequency() -> void:
	for seed in range(1, 200):
		var s: Dictionary = GroupedDataSituation.generate(Seeded.new("m|%d" % seed), {"ask": "modal-class", "rep": "table", "paper": 1 + seed % 2})
		check_eq(GroupedDataSituation.top_row(s.fs), s.big)
		check(s.big != s.mid, "the class of the median is another class")


func test_the_hidden_frequency_is_the_modal_one_half_of_the_time() -> void:
	var yes := 0
	for seed in range(1, 201):
		var s: Dictionary = GroupedDataSituation.generate(Seeded.new("h|%d" % seed), {"ask": "modal-class-after-frequency", "rep": "table", "paper": 1})
		if s.at == s.big:
			yes += 1
	check(yes >= 70 and yes <= 130, "p is the greatest %d times in 200" % yes)


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 41):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	for m in QuestionEngine.type_of(TYPE).misconceptions:
		check(seen.has(m.ref), "%s never comes up" % m.ref)


func test_hand_values() -> void:
	# 2, 4, 4, 4, 5, 5, 7, 9: the mean is 5 and σ² = 32 ÷ 8 = 4.
	var s := {"xs": [Q.new(2), Q.new(4), Q.new(5), Q.new(7), Q.new(9)], "fs": [Q.new(1), Q.new(3), Q.new(2), Q.new(1), Q.new(1)]}
	GroupedDataSituation.stats(s)
	check(s.mean.eq(Q.new(5)), "the mean")
	check(s.variance.eq(Q.new(4)), "the variance")
	check(s.sd.eq(Q.new(2)), "the exact root")
	# Sx² divides by n − 1: 32 ÷ 7.
	check(GroupedDataSituation.sample_variance(s).eq(Q.new(32, 7)), "Sx²")
	# Classes 10 to 20 (f 3) and 20 to 40 (f 1): mid-values 15 and 30, mean 75 ÷ 4.
	var t := {"xs": [Q.new(15), Q.new(30)], "fs": [Q.new(3), Q.new(1)]}
	GroupedDataSituation.stats(t)
	check(t.mean.eq(Q.new(75, 4)), "the grouped mean")
