extends "res://tests/test_case.gd"
## The question engine on the distribution situation (FAL-396): the three Topic 4 types
## are built, every distribution adds to 1 inside its clean limits, answers are written
## the way the question writes probabilities, marking takes exact or 3 s.f., and every
## misconception shows up as an option. The SymPy checker (tools/check-answers) checks
## the maths.

const TYPES := ["t4-discrete-distribution", "t4-expected-value", "t4-expected-occurrences"]
## Cells per type, counted as tools/pedagogy.mjs counts them.
const CATALOGUE_CELLS := {"t4-discrete-distribution": 13, "t4-expected-value": 14, "t4-expected-occurrences": 5}


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func test_three_types_are_built() -> void:
	var built := QuestionEngine.built_types()
	for t in TYPES:
		check(t in built, "%s is not built" % t)
		check_eq(QuestionEngine.cells(false, [t]).size(), CATALOGUE_CELLS[t], t)


func test_every_distribution_is_clean() -> void:
	for c in QuestionEngine.cells(false, TYPES):
		for seed in range(1, 21):
			var q := QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed})
			if q.has("error"):
				fail("%s seed %d: %s" % [c.key, seed, q.error])
				return
			var s: Dictionary = q.situation
			var total := Q.new(0)
			for p in s.ps:
				var v := Answer.parse_number(p).q as Q
				total = total.add(v)
				check(v.sign() > 0 and v.lt(1), "%s seed %d: probability %s" % [c.key, seed, p])
				if s.style == "decimal":
					check(not v.lt(Q.new(1, 20)) and not Q.new(3, 5).lt(v), "%s seed %d: decimal %s out of range" % [c.key, seed, p])
			check(total.eq(1), "%s seed %d: probabilities add to %s" % [c.key, seed, total.key()])
			if s.style != "decimal":
				check(int(s.total) >= 6 and int(s.total) <= 60, "%s seed %d: k = 1/%s" % [c.key, seed, s.total])
			check_eq(q.choices.size(), 4, c.key)


func test_k_in_each_representation() -> void:
	var t := _make("t4-discrete-distribution", "k-from-sum", "table", "sum-to-one", 1)
	check(t.table != null and t.table.rows[1][0] == "P(X = x)", "a table question has a distribution table")
	check(t.table.rows[1][1].all(func(e): return e.ends_with("k")), "the entries are multiples of k: %s" % [t.table.rows[1][1]])
	check_eq(t.answer_text, "k = 1/%d" % t.situation.total)
	var f := _make("t4-discrete-distribution", "k-from-sum", "equation", "sum-to-one", 1)
	check(f.lines[1].begins_with("P(X = x) = k"), f.lines[1])
	check(f.solutions[0].steps[0].begins_with("Put each value of x into"), "a formula is tabulated first")
	var w := _make("t4-discrete-distribution", "k-from-sum", "words", "sum-to-one", 1)
	check(w.table == null and w.lines[0].begins_with("Let X be "), w.lines[0])


func test_probabilities_are_written_as_the_question_writes_them() -> void:
	for seed in range(1, 31):
		var m := _make("t4-discrete-distribution", "missing-probability", "table", "sum-to-one", seed)
		check(not m.answer_text.contains("/"), "a missing decimal is a decimal: %s" % m.answer_text)
		var k := _make("t4-discrete-distribution", "k-from-sum", "words", "sum-to-one", seed)
		check(k.answer_text.contains("/"), "k is a fraction: %s" % k.answer_text)
		var st := _make("t4-expected-value", "fair-stake", "table", "net-gain-table", seed)
		check(st.answer_text.begins_with("Stake = $"), st.answer_text)
		check(Q.of(st.answer.values.v).mul(100).is_int(), "the stake is whole cents: %s" % st.answer_text)


func test_marking_exact_or_three_figures() -> void:
	# Find a k that is not a decimal that ends, such as 1/15.
	for seed in range(1, 60):
		var q := _make("t4-discrete-distribution", "k-from-sum", "table", "sum-to-one", seed)
		var k: Q = q.answer.values.v
		if not Fmt.dec(k).contains("/"):
			continue
		check(QuestionEngine.mark(q, {"v": k.key()}).correct, "the exact fraction is right")
		check(QuestionEngine.mark(q, {"v": Fmt.sf(k, 3)}).correct, "%s to 3 s.f. is right" % Fmt.sf(k, 3))
		check(not QuestionEngine.mark(q, {"v": Fmt.sf(k, 1)}).correct, "%s to 1 s.f. is wrong" % Fmt.sf(k, 1))
		return
	fail("no k that is a recurring decimal in 60 seeds")


func test_p_and_q_are_two_slots() -> void:
	var q := _make("t4-expected-value", "probabilities-from-mean", "table", "two-equations", 3)
	check_eq(q.answer.kind, "pq")
	var p: Q = q.answer.values.p
	var r: Q = q.answer.values.q
	check(QuestionEngine.mark(q, {"p": Fmt.dec(p), "q": Fmt.dec(r)}).correct, "p and q typed as decimals are right")
	check(not QuestionEngine.mark(q, {"p": Fmt.dec(r), "q": Fmt.dec(p)}).correct, "p and q swapped are wrong")
	check(q.lines[-1].begins_with("E(X) = "), "E(X) is given")
	var t: Array = q.table.rows[1][1]
	check(t.has("p") and t.has("q"), "the table shows p and q")


func test_a_strict_event_leaves_its_end_out() -> void:
	var seen := false
	for seed in range(1, 80):
		var q := _make("t4-discrete-distribution", "event-probability", "table", "add-entries", seed, "mcq")
		var e: Dictionary = q.situation.event
		if e.op != ">":
			continue
		var want := Q.new(0)
		for i in q.situation.xs.size():
			if int(q.situation.xs[i]) > int(e.a):
				want = want.add(Answer.parse_number(q.situation.ps[i]).q)
		check(Q.of(q.answer.values.v).eq(want), "seed %d: P(X > %d)" % [seed, e.a])
		seen = true
	check(seen, "some event is X > a")


func test_every_misconception_appears_as_an_option() -> void:
	for id in TYPES:
		var t := QuestionEngine.type_of(id)
		for m in t.misconceptions:
			var found := false
			for u in m["in"]:
				var unk := QuestionEngine.unknown_of(t, u)
				for seed in range(1, 61):
					var q := QuestionEngine.make({"type": id, "unknown": u, "rep": unk.reps[0],
						"angle": QuestionEngine.angles_for(t, u)[0], "seed": seed, "format": "mcq"})
					if q.choices.any(func(c): return c.ref == m.ref):
						found = true
						break
				if found:
					break
			check(found, "%s: %s never shows up as an option" % [id, m.ref])
