extends "res://tests/test_case.gd"
## Paper 1 or 2 on every question (FAL-419): each question carries its paper, a type
## the IB asks on both papers makes both in the exam's ratio, and the paper never
## changes a Paper 1 question's numbers.

const PER_TYPE := 1000
const WITHIN := 0.05
const SEEDS := 3
## What a calculator method looks like in words, on anything a Paper 1 question shows.
const CALCULATOR_WORDS := "(?i)\\b(gdc|calculators?|linreg\\w*|l1|l2|y1|y2|solver|nsolve|zoom|ti-\\w+|casio|fnint|nderiv|normalcdf|invnorm|binomcdf|binompdf|tvm)\\b"
## These types are Paper 1 only (or nearly) in the bank, and the catalogue teaches a GDC
## method on some of their cells. Those cells can't be Paper 1 (FAL-758), and no other
## cell can make up for them. The value is the most the type's Paper 2 share may be.
const OVER_SHARE := {"fn-sketch-from-features": 0.08, "fn-curve-intersection-quadratic": 0.07,
	"fn-log-of-quadratic": 0.12, "fn-rational-sketch": 0.24, "fn-log-function-features": 0.14, "t1-log-laws": 0.13, "t3-trig-quadratic": 0.13,
	"t3-trig-sketch": 0.24}


## The Paper 2 share of 1,000 questions of a type, across its cells in turn.
func _share(id: String) -> float:
	var cs := QuestionEngine.cells(false, [id])
	var p2 := 0
	for i in PER_TYPE:
		var c: Dictionary = cs[i % cs.size()]
		var q := QuestionEngine.make({"type": id, "unknown": c.unknown, "rep": c.rep, "angle": c.angle,
			"format": "value", "seed": 1 + i / cs.size()})
		if q.has("error"):
			fail("%s: %s" % [c.key, q.error])
			continue
		if q.paper == 2:
			p2 += 1
	return float(p2) / PER_TYPE


func test_every_question_has_a_paper() -> void:
	for id in QuestionEngine.built_types():
		for c in QuestionEngine.cells(false, [id]):
			var q := QuestionEngine.make({"type": id, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": 1})
			check(q.has("error") or q.get("paper") in [1, 2], "%s has no paper" % c.key)
			var forced := QuestionEngine.cell_papers(QuestionEngine.type_of(id), c.unknown, c.rep, c.angle)
			for p in forced:
				var f := QuestionEngine.make({"type": id, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": 2,
					"paper": p})
				check(f.has("error") or f.paper == p, "%s asked for Paper %d gives Paper %s" % [c.key, p, f.get("paper")])


func test_the_paper_ratio_matches_the_exam() -> void:
	for id in QuestionEngine.built_types():
		var t := QuestionEngine.type_of(id)
		var want := QuestionEngine.paper_share(t)
		if want < 0.0:
			continue
		var got := _share(id)
		if OVER_SHARE.has(id):
			check(got <= OVER_SHARE[id], "%s: %d%% Paper 2" % [id, roundi(got * 100)])
			continue
		check(absf(got - want) <= WITHIN, "%s: %d%% Paper 2, the exam has %d%%" % [id, roundi(got * 100), roundi(want * 100)])


func test_a_boss_chain_is_on_one_paper() -> void:
	var t := QuestionEngine.type_of("fn-exponential-model")
	var steps: Array = []
	for u in t.unknowns.slice(0, 2):
		steps.append({"type": t.id, "unknown": u.id})
	var chain := QuestionEngine.make_chain(steps, 4)
	if chain.has("error"):
		return
	for part in chain.parts:
		check_eq(part.paper, 2, "an exponential model is Paper 2")


## Every string in a value.
func _strings(v: Variant, out: Array) -> void:
	if v is String:
		out.append(v)
	elif v is Array:
		for e in v:
			_strings(e, out)
	elif v is Dictionary:
		for e in v.values():
			_strings(e, out)


## A question on Paper 1 with no method, tab, step or word of a calculator in it.
func _check_no_calculator(q: Dictionary, rx: RegEx, what: String) -> bool:
	if q.has("error") or q.paper != 1:
		return false
	for s in q.solutions:
		check(not QuestionEngine.gdc_method(QuestionEngine.type_of(q.view.type), q.view.unknown, s.angle), "%s: a %s tab" % [what, s.angle])
	var texts: Array = []
	_strings([q.prompt, q.lines, q.given, q.choices, q.get("reason", "")], texts)
	# A wrong option's feedback is a misconception, by reference.
	for o in q.choices:
		texts.append(QuestionEngine.misconception_text(QuestionEngine.type_of(q.view.type), o.get("ref", "")))
	for s in q.solutions:
		_strings([s.name, s.steps], texts)
	for s in texts:
		var m := rx.search(s)
		check(m == null, "%s says %s: %s" % [what, m.get_string() if m != null else "", s])
	return true


func test_paper_1_never_shows_a_calculator_method() -> void:
	# Fights make plain questions, and the explorer shared ones, so both are checked.
	var rx := RegEx.create_from_string(CALCULATOR_WORDS)
	var asked := 0
	for c in QuestionEngine.cells():
		for seed in range(1, SEEDS + 1):
			for shared in [false, true]:
				var view := {"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "format": "mcq", "seed": seed}
				if shared:
					view.shared = true
				if _check_no_calculator(QuestionEngine.make(view), rx, "%s seed %d%s" % [c.key, seed, " shared" if shared else ""]):
					asked += 1
			for f in QuestionEngine.extra_formats(c.type, c.unknown, c.angle):
				_check_no_calculator(QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "format": f, "seed": seed}),
					rx, "%s seed %d %s" % [c.key, seed, f])
		# No method picked: every tab the unknown has is on the card.
		_check_no_calculator(QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": "any", "seed": 1}), rx, c.key + " any")
	print("Paper 1 questions checked: %d" % asked)
	check(asked > 10000, "only %d Paper 1 questions" % asked)


func test_a_calculator_method_is_paper_2_on_any_view() -> void:
	for c in QuestionEngine.cells():
		if not QuestionEngine.gdc_method(QuestionEngine.type_of(c.type), c.unknown, c.angle):
			continue
		check_eq(QuestionEngine.cell_papers(QuestionEngine.type_of(c.type), c.unknown, c.rep, c.angle), [2], c.key)
		for view in [{}, {"shared": true}, {"paper": 1}]:
			var q := QuestionEngine.make(view.merged({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": 2}))
			check(q.has("error") or q.paper == 2, "%s %s is Paper %s" % [c.key, view, q.get("paper")])


func test_a_boss_chain_is_never_paper_1_with_a_calculator_part() -> void:
	# Fights' bosses are the one place the "no common paper" fallback can still be reached:
	# a calculator part next to a Paper 1-only part. The chain then goes to Paper 2.
	var rx := RegEx.create_from_string(CALCULATOR_WORDS)
	for id in QuestionEngine.built_types():
		for steps in Dungeon.chain_windows(id):
			var chain := QuestionEngine.make_chain(steps.map(func(st): return st.merged({"format": "mcq"})), 3)
			if chain.has("error"):
				continue
			for q in chain.parts:
				check_eq(q.paper, chain.parts[0].paper, "%s: one chain, one paper" % id)
				_check_no_calculator(q, rx, "%s chain" % id)


func test_a_paper_1_follow_up_is_not_a_calculator_method() -> void:
	var run := Run.new(SaveData.blank(), "quadratics", Tuning.ANOTHER_WAY_FLOOR, 5)
	run.floor_no = Tuning.ANOTHER_WAY_FLOOR
	for c in QuestionEngine.cells():
		var t := QuestionEngine.type_of(c.type)
		var q := QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": 3})
		if q.has("error") or q.paper != 1:
			continue
		run.question = q
		for n in 12:
			run.question_no = n
			var v := run._another_way_view()
			if not v.is_empty():
				check(not QuestionEngine.gdc_method(t, c.unknown, v.angle), "%s: another way is %s" % [c.key, v.angle])
				check_eq(QuestionEngine.make(v).paper, 1, c.key)


func test_concept_probes_are_paper_1() -> void:
	var q := QuestionEngine.probe("fn-quadratic-features", 0)
	check(q.has("error") or q.paper == 1)
