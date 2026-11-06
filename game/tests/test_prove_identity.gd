extends "res://tests/test_case.gd"
## The prove-identity situation (FAL-753): t3-prove-identity is built with every cell, every method
## of its skill and both representations, all on Paper 1. Every cell makes a question with four
## different options, values match sums done by hand, a proof's lines are the ones its chain says, a
## hidden or spoiled line is where it should be, typed answers are marked with the slip detected,
## no statement is an exam's, and every tag shows up as an option. The SymPy checker
## (tools/check-answers) proves each line again.

const TYPE := "t3-prove-identity"
const CELLS := 34
const PICKED := ["next-line", "missing-line", "flawed-line", "valid-argument", "start-side", "true-identity", "cos2-form", "factor-structure"]


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _cells(unknown: String) -> Array:
	return QuestionEngine.cells(false, [TYPE]).filter(func(c): return c.unknown == unknown)


func test_the_type_is_built_with_every_cell_on_paper_1() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	check_eq(t.unknowns.size(), 16)
	var methods := {}
	for a in t.angles:
		methods[a.method] = true
	check_eq(methods.size(), 3, "all three methods have questions")
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [1], c.key)


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3, 4]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "prove-identity", c.key)
				check_eq(q.paper, 1, c.key)
				check_eq(q.format == "mcq", f == "mcq" or c.unknown in PICKED, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s seed %d: two options read the same" % [c.key, seed])
				check_eq(q.solutions[0].angle, c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps in %s" % [c.key, sol.steps.size(), sol.name])
				check(q.answer_text in Step.texts(q.solutions[0].steps).back(), "%s: the working ends on the answer" % c.key)


func test_same_seed_same_question_and_seeds_vary() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var a := _make(c, 7)
		check_eq(a.prompt, _make(c, 7).prompt, c.key)
		var shown := {}
		for seed in range(1, 25):
			var q := _make(c, seed)
			shown[str(q.lines) + q.answer_text] = true
		check(shown.size() > 3, "%s: only %d statements in 24 seeds" % [c.key, shown.size()])


func test_the_sums_match_hand_values() -> void:
	# 3 tan(2 · π/6) = 3√3.
	var v := ProveIdentityViews.right_value({"fam": "half-tan", "k": 3, "w": 2}, Q.new(1, 6))
	check_eq(TrigKit.text(v), "3√3")
	# 2(1 + sin(2 · π/12)) = 2(3/2) = 3.
	v = ProveIdentityViews.right_value({"fam": "square", "k": 2, "w": 1, "minus": false}, Q.new(1, 12))
	check_eq(TrigKit.text(v), "3")
	# 5 sin 2u at u = π/4: −5 cos(π/2) = 0 for the flipped difference.
	v = ProveIdentityViews.right_value({"fam": "quartic-diff", "k": 5, "w": 1, "flip": true}, Q.new(1, 4))
	check_eq(TrigKit.text(v), "0")
	# 2 · 3/sin(π/3) = 12/√3 = 4√3.
	v = ProveIdentityViews.right_value({"fam": "reciprocal-sum", "k": 3, "w": 1}, Q.new(1, 6))
	check_eq(TrigKit.text(v), "4√3")
	# 4 · 2 · (1/2)⁴ = 1/2, at x = π/6.
	v = ProveIdentityViews.right_value({"fam": "perfect-square", "k": 2, "w": 1, "base": "sin"}, Q.new(1, 6))
	check_eq(TrigKit.text(v), "1/2")
	check_eq(ProveIdentityViews.ratio_value({"fam": "square", "k": 2, "r": Q.new(1, 5), "minus": true}).key(), "8/5")
	check_eq(ProveIdentityViews.ratio_value({"fam": "quartic-sin", "k": 3, "r": Q.new(2, 3)}).key(), "4/3")
	check_eq(ProveIdentityViews.range_of({"fam": "product", "n": 7})[1].key(), "7/2")
	check_eq(ProveIdentityViews.range_of({"fam": "square", "k": 4, "minus": false})[1].key(), "8")


func test_a_line_reads_as_it_is_written() -> void:
	check_eq(ProveIdentityViews.lead(3, "sin x"), "3 sin x")
	check_eq(ProveIdentityViews.lead(1, "sin x"), "sin x")
	check_eq(ProveIdentityViews.lead(-1, "sin x"), "−sin x")
	check_eq(ProveIdentityViews.lead(Q.new(3, 2), "sin x"), "(3/2) sin x")
	check_eq(ProveIdentityViews.lead(3, "(1 − sin x)"), "3(1 − sin x)")
	check_eq(ProveIdentityViews.whole(1, "1 − sin x"), "1 − sin x")
	var s := {"fam": "half-tan", "k": 3, "w": 2, "letter": "x"}
	check_eq(ProveIdentityViews.left(s), "3(1 − cos 4x)/sin 4x")
	check_eq(ProveIdentityViews.right(s), "3 tan 2x")
	check_eq(ProveIdentityViews.chain(s)[2].text, "6 sin²2x/(2 sin 2x cos 2x)")
	check_eq(ProveIdentityViews.chain({"fam": "square", "k": 2, "w": 1, "letter": "θ", "minus": true}).back().text, "2(1 − sin 2θ)")


func test_no_statement_is_an_exams_or_uses_hl_ratios() -> void:
	var rx := RegEx.create_from_string("\\b(sec|cosec|cot)\\b|(?<!\\d)3[xθ]")
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 12):
			var q := _make(c, seed)
			var g: Dictionary = q.given
			check(not ProveIdentitySituation.exam_like(g), "%s seed %d" % [c.key, seed])
			for text in q.lines + q.choices.map(func(o): return o.text):
				check(rx.search(text) == null, "%s: %s" % [c.key, text])


func test_a_chain_ends_on_the_right_side_and_each_slip_differs() -> void:
	var fams: Array = ProveIdentityViews.SLIPS.keys()
	for f in fams:
		var s := {"fam": f, "k": 2, "w": 2, "letter": "x", "n": 5, "minus": false, "flip": false, "base": "sin"}
		var c := ProveIdentityViews.chain(s)
		check(c.size() >= 3 and c.size() <= 5, "%s: %d lines" % [f, c.size()])
		for i in range(1, c.size()):
			check(c[i].why != "", "%s line %d says nothing" % [f, i + 1])
		for slip in ProveIdentityViews.slips_of(s):
			var bad := ProveIdentityViews.chain(s, slip)
			check_eq(bad[0].text, c[0].text, f)
			check(bad.back().text != c.back().text, "%s: %s changes nothing" % [f, slip])


func test_a_hidden_line_is_the_lines_own_number() -> void:
	for c in _cells("missing-line"):
		for seed in range(1, 15):
			var q := _make(c, seed)
			var hide: int = q.given.hide
			check(q.lines.has("Line %d: ?" % (hide + 1)), "%s seed %d" % [c.key, seed])
			check(q.answer_text.begins_with("Line %d: " % (hide + 1)), q.answer_text)
			check_eq(q.answer_text, "Line %d: %s" % [hide + 1, ProveIdentityViews.chain(q.given)[hide].text], c.key)


func test_the_spoiled_line_is_the_first_that_differs() -> void:
	for c in _cells("flawed-line"):
		for seed in range(1, 25):
			var q := _make(c, seed)
			var at: int = q.given.at
			var good := ProveIdentityViews.chain(q.given)
			var bad := ProveIdentityViews.chain(q.given, q.given.slip)
			for i in at:
				check_eq(bad[i].text, good[i].text, "%s seed %d: line %d" % [c.key, seed, i + 1])
			check(bad[at].text != good[at].text, "%s seed %d: line %d is the slip" % [c.key, seed, at + 1])
			check_eq(q.answer_text, "Line %d should read: %s" % [at + 1, good[at].text], c.key)


func test_a_start_goes_to_the_busier_side() -> void:
	var swaps := {}
	for c in _cells("start-side"):
		for seed in range(1, 40):
			var q := _make(c, seed)
			var g: Dictionary = q.given
			swaps[g.swap] = true
			check(ProveIdentityViews.busy(ProveIdentityViews.left(g)) > ProveIdentityViews.busy(ProveIdentityViews.right(g)), "%s: %s" % [c.key, g.fam])
			check(q.answer_text.begins_with("Start from the %s side" % ("right" if g.swap else "left")), q.answer_text)
	check_eq(swaps.size(), 2, "the busier side is on either side")


func test_a_typed_form_is_marked_in_slots_and_a_slip_detected() -> void:
	var seen := 0
	for c in _cells("simplified-result") + _cells("half-form"):
		for seed in range(1, 15):
			var q := _make(c, seed, "value")
			var right := {}
			for id in q.answer.values:
				if id != "text":
					right[id] = q.answer.values[id].key()
			check(QuestionEngine.mark(q, right).correct, "%s seed %d: the answer typed" % [c.key, seed])
			for o in q.choices:
				if not o.correct and o.ref != "" and Answer.typable(q.answer, o.values):
					var typed := {}
					for id in o.values:
						if id != "text":
							typed[id] = o.values[id].key()
					var r := QuestionEngine.mark(q, typed)
					check(not r.correct, "%s seed %d: %s" % [c.key, seed, o.text])
					check_eq(r.misconception, o.ref, "%s seed %d: %s" % [c.key, seed, o.text])
					seen += 1
	check(seen > 20, "only %d slips typed" % seen)


## "Another way" keeps the numbers, and where a method doesn't suit them the working says so.
func test_another_way_keeps_the_numbers() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		for other in QuestionEngine.angles_for(t, c.unknown):
			if other == c.angle:
				continue
			for seed in range(1, 6):
				var q := QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": other, "same_angle": c.angle, "seed": seed, "format": "mcq"})
				check(not q.has("error"), "%s as %s seed %d" % [c.key, other, seed])
				check_eq(q.lines, _make(c, seed).lines, "%s as %s seed %d" % [c.key, other, seed])
				check(not q.solutions.is_empty() and q.solutions[0].angle == other, "%s as %s seed %d: the working" % [c.key, other, seed])


func test_every_tag_shows_up_as_an_option() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 200):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen["%s|%s" % [o.ref, c.unknown]] = true
	for m in t.misconceptions:
		for u in m["in"]:
			check(seen.has("%s|%s" % [m.ref, u]), "%s never shows on %s" % [m.ref, u])


func test_probes_are_served() -> void:
	var mine := QuestionEngine.probes().filter(func(x): return x.type == TYPE)
	check_eq(mine.size(), 3)
	check_eq(QuestionEngine.probe(TYPE, 0).verdict, "False")
	check_eq(QuestionEngine.probe(TYPE, 1).verdict, "Sometimes")
	check_eq(QuestionEngine.probe(TYPE, 2).verdict, "False")
