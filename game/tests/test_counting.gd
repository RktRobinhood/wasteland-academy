extends "res://tests/test_case.gd"
## The counting situation (FAL-695): t1-ahl-counting, the first type built for AA HL only
## (AHL1.10). It is built with every catalogue cell, it is on AA HL's course and no other,
## the planner serves it to an AA HL student and never to an AA SL one, the counts match
## hand values, every distractor misconception shows up as an option, and answers are
## marked exactly. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t1-ahl-counting"
## Cells, counted as tools/pedagogy.mjs counts them.
const CELLS := 25
const NOW := 1_800_000_000


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	check_eq(t.source, "extension", "no AA SL exam part is about counting")
	check_eq(t.unknowns.size(), 11)
	var skills := {}
	for u in t.unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 4, "four of AHL1.10's six skills")


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3, 4, 5]:
				var q := _make(c.unknown, c.rep, c.angle, seed, f)
				check(not q.has("error"), "%s as %s seed %d: %s" % [c.key, f, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "counting", c.key)
				check_eq(q.choices.size(), 4, "%s as %s: options" % [c.key, f])
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, "%s as %s: right options" % [c.key, f])
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s as %s: two options read the same" % [c.key, f])
				check(q.solutions[0].angle == c.angle, "%s: the asked method is the first worked solution" % c.key)
				check(q.answer.get("exact", false), c.key + ": a count is exact")


func test_it_is_on_aa_hl_and_no_other_course() -> void:
	check_eq(QuestionEngine.cells(false, [TYPE], "aa-hl").size(), CELLS, "AA HL has every cell")
	check(TYPE in QuestionEngine.built_types("aa-hl"), "AA HL plays it")
	for course in ["aa-sl", "ai-sl", "ai-hl"]:
		check_eq(QuestionEngine.cells(false, [TYPE], course).size(), 0, "%s has none of AHL1.10" % course)
		check(not TYPE in QuestionEngine.built_types(course), "%s does not play it" % course)


func test_the_planner_serves_it_to_an_aa_hl_student_and_never_to_an_aa_sl_one() -> void:
	for course in ["aa-sl", "aa-hl"]:
		var s := SaveData.blank()
		SaveData.set_course(s, course)
		var seen := 0
		for i in 400:
			var v := Planner.next(s, NOW, {"probes": false})
			if v.get("type", "") == TYPE:
				seen += 1
				check(course == "aa-hl", "%s was planned a counting question" % course)
				check(not QuestionEngine.make(v).has("error"), "%s: the planned view makes a question" % course)
		if course == "aa-hl":
			check(seen > 0, "an AA HL student's 400 questions had no counting question")
		else:
			check_eq(seen, 0, "an AA SL student was planned one")


func test_the_counts_match_hand_values() -> void:
	check_eq(CountingSituation.comb(12, 4), 495)
	check_eq(CountingSituation.comb(10, 0), 1)
	check_eq(CountingSituation.comb(5, 6), 0)
	check_eq(CountingSituation.perm(10, 3), 720)
	check_eq(CountingSituation.perm(7, 7), 5040)
	check_eq(CountingSituation.fact(8), 40320)
	# 2 letters then 3 digits: 26² × 10³.
	check_eq(CountingSituation.count({"ask": "code-count", "a": 2, "b": 3}), 676000)
	# 4-digit numbers, no repeats, not starting with 0: 9 × 9 × 8 × 7 = 4536.
	check_eq(CountingSituation.count({"ask": "no-repeat-number", "d": 4}), 4536)
	# Even 3-digit numbers from 1 to 6, no repeats: 3 × 5 × 4 = 60.
	check_eq(CountingSituation.count({"ask": "even-numbers", "m": 6, "d": 3}), 60)
	# 4 chosen from 6 men and 5 women: exactly 2 women = 5C2 × 6C2 = 150; at least one = 11C4 − 6C4 = 315.
	check_eq(CountingSituation.count({"ask": "committee-mixed", "men": 6, "women": 5, "k": 4, "j": 2}), 150)
	check_eq(CountingSituation.count({"ask": "committee-at-least-one", "men": 6, "women": 5, "k": 4}), 315)
	# 6 people, two together 2 × 5! = 240, apart 6! − 240 = 480.
	check_eq(CountingSituation.count({"ask": "together", "n": 6}), 240)
	check_eq(CountingSituation.count({"ask": "apart", "n": 6}), 480)


func test_the_counts_are_whole_and_clean() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 40):
			var q := _make(c.unknown, c.rep, c.angle, seed, "mcq")
			var v: Q = q.answer.values.v
			check(v.is_int() and v.n > 0 and v.n < CountingSituation.COUNT_MAX, "%s seed %d: %s" % [c.key, seed, q.answer_text])
			for o in q.choices:
				check(Q.of(o.values.v).is_int() and Q.of(o.values.v).n > 0, "%s seed %d: option %s" % [c.key, seed, o.text])
	for seed in range(1, 40):
		var s: Dictionary = CountingSituation.generate(Seeded.new("n|%d" % seed), {"ask": "find-n-from-npr"})
		check_eq(CountingSituation.perm(s.n, 2), s.v, "seed %d: nP2" % seed)
		check(s.n >= 6 and s.n <= 15, "seed %d: n = %d" % [seed, s.n])
	for seed in range(1, 60):
		var m: Dictionary = CountingSituation.generate(Seeded.new("m|%d" % seed), {"ask": "committee-mixed"})
		check(m.j >= 2 and m.j < m.k and m.k - m.j <= m.men and m.j <= m.women, "seed %d: %s" % [seed, m])


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


func test_a_count_is_marked_exactly() -> void:
	for seed in range(1, 12):
		var q := _make("committee", "equation", "gdc-ncr", seed, "value")
		var v: Q = q.answer.values.v
		check(QuestionEngine.mark(q, {"v": str(v.n)}).correct, "seed %d: %s is right" % [seed, v.n])
		check(not QuestionEngine.mark(q, {"v": str(v.n + 1)}).correct, "seed %d: one more is wrong" % seed)
		check(not QuestionEngine.mark(q, {"v": str(v.n - 1)}).correct, "seed %d: one fewer is wrong" % seed)


func test_numbers_use_a_true_minus() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var q := _make(c.unknown, c.rep, c.angle, 3, "mcq")
		var texts: Array = [q.prompt] + q.lines + q.choices.map(func(o): return o.text)
		for sol in q.solutions:
			texts.append_array(sol.steps)
		for x in texts:
			check(not RegEx.create_from_string("(?<![A-Za-z0-9])-\\d").search(x), "%s: %s" % [c.key, x])


func test_probes_are_served() -> void:
	var mine := QuestionEngine.probes(false, "aa-hl").filter(func(x): return x.type == TYPE)
	check_eq(mine.size(), 2)
	check_eq(QuestionEngine.probe(TYPE, 0).verdict, "False")
	check_eq(QuestionEngine.probe(TYPE, 1).verdict, "Sometimes")
	check(QuestionEngine.probes(false, "aa-sl").filter(func(x): return x.type == TYPE).is_empty(), "an AA SL student has no counting probe")
