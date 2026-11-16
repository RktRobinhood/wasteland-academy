extends "res://tests/test_case.gd"
## The mutually-exclusive situation (FAL-777): t4-ext-mutually-exclusive is built with every cell.
## A decision's verdict matches the events, a value is P(A) + P(B) or what is left of the union,
## every tag shows up on each unknown it names, and true-false-reason is offered everywhere. The
## SymPy checker (tools/check-answers) decides every pair of events again from what is shown.

const TYPE := "t4-ext-mutually-exclusive"
const CELLS := 8
const S := preload("res://engine/situations/mutually_exclusive.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)


func test_every_cell_and_format_makes_a_question() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var fmts: Array = ["mcq"] + QuestionEngine.extra_formats(TYPE, c.unknown, c.angle)
		check_eq(fmts, ["mcq", "true-false-reason"], c.key)
		for f in fmts:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.paper, 1, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.graph != null, c.rep == "diagram", c.key + ": a Venn diagram on the diagram view only")


func test_the_verdict_matches_the_events() -> void:
	for i in 40:
		var s := S.generate(Seeded.new("venn|%d" % i), {"ask": "decide-from-venn"})
		check_eq(s.me, s.i == 0, "venn %d" % i)
		check_eq(s.a + s.i + s.b + s.o, s.u, "venn %d: the regions add up" % i)
		var c := S.generate(Seeded.new("ctx|%d" % i), {"ask": "decide-in-context"})
		var n: int = S.DEVICES[c.dev].n
		var both := 0
		for x in range(1, n + 1):
			if x in c.A and x in c.B:
				both += 1
		check_eq(c.me, both == 0, "context %d" % i)
		var p := S.generate(Seeded.new("p|%d" % i), {"ask": "decide-from-probabilities"})
		check_eq(p.me, p.ki == 0, "probabilities %d" % i)
		check(p.ka + p.kb - p.ki <= 20, "probabilities %d: P(A ∪ B) > 1" % i)


func test_the_sums_match_hand_values() -> void:
	# A die: "a prime number" is 2, 3, 5 and "an odd number" is 1, 3, 5, so 3 is in both.
	check_eq(S.outcomes(6, "prime", 0), [2, 3, 5])
	check_eq(S.outcomes(12, "factor12", 0), [1, 2, 3, 4, 6, 12])
	check_eq(S.outcomes(8, "greater", 5), [6, 7, 8])
	var q := QuestionEngine.make({"type": TYPE, "unknown": "missing-exclusive", "rep": "equation", "angle": "intersection-zero", "seed": 4, "format": "mcq"})
	var pa := Q.of(q.given.ka).div(Q.new(20))
	var pu := Q.of(q.given.ku).div(Q.new(20))
	check(Q.of(q.answer.values.v).eq(pu.sub(pa)), "P(B) = P(A ∪ B) − P(A)")


func test_every_tag_shows_up_on_each_unknown_it_names() -> void:
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		for u in ms[i].in:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 25):
					if _make(c, seed).choices.any(func(o): return o.ref == ref):
						found = true
						break
				if found:
					break
			check(found, "%s never shows on %s" % [ref, u])
