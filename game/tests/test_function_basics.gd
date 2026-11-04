extends "res://tests/test_case.gd"
## The Function basics region (FAL-424): its types are built with every catalogue cell on
## their situations, their distractor misconceptions show up as options, and the region's
## answers mark the way a student gives them (a typed value, a sentence, a graph picked from
## four). The SymPy checker (tools/check-answers) checks the maths.

## Cells per type, counted as tools/pedagogy.mjs counts them.
const CELLS := {"fn-evaluate-function": 54, "fn-concept-function-notation": 21, "fn-domain-range": 41,
	"fn-inverse-reflection": 35, "fn-ext-is-function": 13, "fn-pre-substitute": 24}
const SITUATION := {"fn-evaluate-function": "basic-function", "fn-concept-function-notation": "basic-function",
	"fn-domain-range": "basic-restricted", "fn-inverse-reflection": "basic-one-to-one",
	"fn-ext-is-function": "basic-relation", "fn-pre-substitute": "fn-pre-substitute"}
## Distractor misconceptions no option can carry yet ("type|ref"), and why.
const NOT_BUILT := {}
## The types the exam never asks: their recipes keep them on Paper 1.
const EXTENSION := ["fn-concept-function-notation", "fn-ext-is-function", "fn-pre-substitute"]
const PICKS := [["one-to-one", "graph", "horizontal-line-test"], ["make-it-a-function", "graph", "vertical-line-test"]]


func _make(type: String, c: Dictionary, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _cells(type: String, unknown: String = "") -> Array:
	return QuestionEngine.cells(false, [type]).filter(func(c): return unknown == "" or c.unknown == unknown)


func test_the_types_are_built_with_every_cell() -> void:
	var built := QuestionEngine.built_types()
	for t in CELLS:
		check(t in built, "%s is not built" % t)
		check_eq(_cells(t).size(), CELLS[t], t)


func test_every_cell_makes_a_question_on_its_situation() -> void:
	for t in CELLS:
		for c in _cells(t):
			for seed in [1, 2, 3]:
				var q := _make(t, c, seed)
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, SITUATION[t], c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				check_eq(q.solutions[0].angle, c.angle, c.key + ": the asked method comes first")
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
					check(q.answer_text in Step.text(sol.steps[sol.steps.size() - 1]), "%s: the last step doesn't state the answer" % c.key)
				if c.rep == "table" and t != "fn-domain-range":
					check(q.table != null, c.key + ": no table")


func test_every_option_is_different_on_every_seed() -> void:
	for t in ["fn-ext-is-function", "fn-pre-substitute"]:
		for c in _cells(t):
			for seed in range(1, 25):
				var q := _make(t, c, seed, "mcq")
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s seed %d" % [c.key, seed])


func test_every_distractor_misconception_is_an_option() -> void:
	for t in CELLS:
		var ty := QuestionEngine.type_of(t)
		for i in ty.misconceptions.size():
			var m: Dictionary = ty.misconceptions[i]
			var ref: String = m.get("ref", "%s#%d" % [t, i])
			if m.as != "distractor" or NOT_BUILT.has("%s|%s" % [t, ref]):
				continue
			for u in m.in:
				var found := false
				for c in _cells(t, u):
					for seed in range(1, 60):
						if _make(t, c, seed, "mcq").choices.any(func(o): return o.ref == ref):
							found = true
							break
					if found:
						break
				check(found, "%s never offers %s" % [u, ref])


func test_same_seed_same_question() -> void:
	for t in CELLS:
		for c in _cells(t):
			var a := _make(t, c, 7)
			var b := _make(t, c, 7)
			check_eq(a.prompt + str(a.lines) + a.answer_text, b.prompt + str(b.lines) + b.answer_text, c.key)


func test_extension_types_stay_on_paper_1() -> void:
	for t in EXTENSION:
		for c in _cells(t):
			check_eq(_make(t, c, 5).paper, 1, c.key)


func test_the_inverse_type_makes_both_papers() -> void:
	var seen := {}
	for c in _cells("fn-inverse-reflection"):
		for seed in range(1, 12):
			seen[_make("fn-inverse-reflection", c, seed).paper] = true
	check(seen.has(1) and seen.has(2), "both papers")


func test_exam_types_offer_no_extra_format() -> void:
	for t in CELLS:
		if QuestionEngine.type_of(t).source != "exam":
			continue
		for c in _cells(t):
			check(QuestionEngine.extra_formats(t, c.unknown, c.angle).is_empty(), c.key)


func test_the_extension_types_offer_their_extra_formats() -> void:
	var want := {"fn-ext-is-function": "true-false-reason", "fn-pre-substitute": "error-spot"}
	for t in want:
		var seen := false
		for c in _cells(t):
			for f in QuestionEngine.extra_formats(t, c.unknown, c.angle):
				check_eq(f, want[t], c.key)
				seen = true
				for seed in range(1, 10):
					var q := _make(t, c, seed, f)
					check_eq(q.format, f, c.key)
					check_eq(q.choices.size(), 4, "%s as %s" % [c.key, f])
					check_eq(q.choices.filter(func(o): return o.correct).size(), 1, "%s as %s" % [c.key, f])
		check(seen, "%s offers %s" % [t, want[t]])


func test_a_substitution_marks_a_typed_value_and_logs_the_slip() -> void:
	for seed in range(1, 40):
		var c: Dictionary = _cells("fn-pre-substitute", "negative-into-square")[0]
		var q := _make("fn-pre-substitute", c, seed)
		check(QuestionEngine.mark(q, {"v": q.answer.values.v.key()}).correct, q.answer_text)
		var slip: Array = q.choices.filter(func(o): return o.ref == "fn-pre-substitute#0")
		if not slip.is_empty():
			var r := QuestionEngine.mark(q, {"v": slip[0].values.v.key()})
			check(not r.correct, "the slip is wrong")
			check_eq(r.misconception, "fn-pre-substitute#0")
			return
	fail("no squaring slip in 40 seeds")


func test_a_function_verdict_is_a_sentence_picked_in_any_order() -> void:
	var c: Dictionary = _cells("fn-ext-is-function", "from-graph")[0]
	var firsts := {}
	for seed in range(1, 20):
		var q := _make("fn-ext-is-function", c, seed)
		check(QuestionEngine.mark(q, {"v": q.answer_text}).correct, q.answer_text)
		for item in q.answer.template:
			if item is Dictionary and item.has("pick"):
				firsts[item.options[0] == q.answer_text] = true
	check(firsts.has(true) and firsts.has(false), "the right sentence isn't always first")


func test_a_graph_cell_can_be_picked_from_four() -> void:
	for p in PICKS:
		var q := QuestionEngine.make({"type": "fn-ext-is-function", "unknown": p[0], "rep": p[1], "angle": p[2], "seed": 3})
		check_eq(q.format, "pick-the-graph", p[0])
		check_eq(q.graphs.size(), 4, p[0])
		check(q.reason != "", p[0] + ": wrong graphs say why")


func test_the_chains_hold_together() -> void:
	for t in ["fn-evaluate-function", "fn-domain-range", "fn-inverse-reflection"]:
		var steps: Array = Tuning.CHAINS[t].map(func(id): return {"type": t, "unknown": id})
		for seed in range(1, 12):
			var chain := QuestionEngine.make_chain(steps, seed)
			check(not chain.has("error"), "%s: %s" % [t, chain.get("error")])
			if not chain.has("error"):
				check_eq(chain.parts.size(), steps.size(), t)
