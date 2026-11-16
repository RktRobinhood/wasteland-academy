extends "res://tests/test_case.gd"
## The conditional-diagram situation (FAL-777): t4-ext-conditional-diagram is built with every
## cell. The answer divides by the given group only, every tag shows up on each unknown it names,
## and method-pick and error-spot keep their rules. The SymPy checker (tools/check-answers) reads
## the table, the Venn diagram, the tree or the bag back and works every answer out again.

const TYPE := "t4-ext-conditional-diagram"
const CELLS := 8
const S := preload("res://engine/situations/conditional_diagram.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)


func test_every_cell_and_format_makes_a_question() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var fmts: Array = ["mcq"] + QuestionEngine.extra_formats(TYPE, c.unknown, c.angle)
		check(fmts.has("method-pick"), c.key + ": method-pick")
		check_eq(fmts.has("error-spot"), c.unknown in ["from-table", "from-venn"], c.key + ": error-spot")
		for f in fmts + ["value"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.paper, 1, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.graph != null, c.rep == "diagram", c.key + ": a figure on the diagram view")
				check_eq(q.table != null, c.rep == "table", c.key + ": a table on the table view")


func test_the_answer_divides_by_the_given_group() -> void:
	for i in 40:
		var s := S.generate(Seeded.new("t|%d" % i), {"ask": "from-table"})
		var q := QuestionEngine.make({"type": TYPE, "unknown": "from-table", "rep": "table", "angle": "restrict-table", "seed": i + 1, "format": "mcq"})
		var g: Dictionary = q.given
		var n: int = g.i + (g.b if g.given == "B" else g.a)
		check(Q.of(q.answer.values.v).eq(Q.new(g.i, n)), "seed %d" % (i + 1))
		check(s.u == s.a + s.i + s.b + s.o, "draw %d: the total" % i)
	# A bag of 4 red and 5 blue: after a red, 3 red of 8 are left.
	var b := {"r": 4, "g": 5, "same": true, "ctx": 0, "ask": "second-draw", "paper": 1}
	var v := ConditionalDiagramViews.new()
	var out := v.build("second-draw", "words", b, Seeded.new("x"))
	check(Q.of(out.answer.values.v).eq(Q.new(3, 8)), "3/8")


func test_every_tag_shows_up_on_each_unknown_it_names() -> void:
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		if ms[i].as != "distractor":
			continue
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


func test_error_spot_and_method_pick_keep_their_rules() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 6):
			var mp := _make(c, seed, "method-pick")
			var right: Array = mp.choices.filter(func(o): return o.correct)
			check_eq(right[0].text, QuestionEngine.method_name(QuestionEngine.type_of(TYPE), c.unknown, c.angle, {}, c.angle), c.key)
			if not c.unknown in ["from-table", "from-venn"]:
				continue
			var es := _make(c, seed, "error-spot")
			check_eq(es.spot.lines.size(), 4, c.key)
			check(es.choices[es.spot.bad].correct, c.key + ": the bad line")
