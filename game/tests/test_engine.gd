extends "res://tests/test_case.gd"
## The question engine on the quadratic situation (FAL-322): every catalogue cell can
## be made, the same seed gives the same question, the format layer, wrong options
## and worked solutions. The SymPy checker (tools/check-answers) checks the maths.

const TYPES := ["fn-quadratic-features", "fn-quadratic-from-conditions", "fn-concept-quadratic-forms"]
## Cells per type, counted as tools/pedagogy.mjs counts them.
const CATALOGUE_CELLS := {"fn-quadratic-features": 41, "fn-quadratic-from-conditions": 45, "fn-concept-quadratic-forms": 8}
## Misconceptions whose format (error-spot) isn't built yet, so no option carries them.
const ERROR_SPOT := ["SL2.6.vertex#1", "SL2.6.find-equation#2"]


func _plain(v: Variant) -> Variant:
	return preload("res://tools/export_questions.gd").plain(v)


func test_the_three_quadratic_types_are_built() -> void:
	var built := QuestionEngine.built_types()
	for t in TYPES:
		check(t in built, "%s is not built" % t)


func test_every_catalogue_cell_is_a_cell() -> void:
	for t in TYPES:
		check_eq(QuestionEngine.cells(false, [t]).size(), CATALOGUE_CELLS[t], t)


func test_every_cell_makes_a_question() -> void:
	for c in QuestionEngine.cells():
		for seed in [1, 2, 3]:
			var q := QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed})
			check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
			if q.has("error"):
				break
			check_eq(q.cell, c.key)
			check(q.solutions.size() >= 1 and q.solutions[0].steps.size() >= 1, c.key + ": no working")
			if c.angle != "any":
				check_eq(q.solutions[0].angle, c.angle, c.key + ": the asked method comes first")
			check(q.prompt.contains(q.asked), c.key + ": prompt")


func test_every_suited_method_has_working() -> void:
	for c in QuestionEngine.cells():
		var t := QuestionEngine.type_of(c.type)
		var q := QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": 4})
		var have: Array = q.solutions.map(func(s): return s.angle)
		for a in QuestionEngine.angles_for(t, c.unknown):
			if a != "any":
				check(a in have, "%s: no working for %s" % [c.key, a])


func test_same_seed_same_question() -> void:
	for c in QuestionEngine.cells().slice(0, 94, 7):
		var v := {"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": 42, "format": "mcq"}
		var a := JSON.stringify(_plain(QuestionEngine.make(v)))
		var b := JSON.stringify(_plain(QuestionEngine.make(v.duplicate())))
		check_eq(a, b, c.key)


func test_seeds_vary_the_numbers() -> void:
	var texts := {}
	for seed in range(1, 21):
		var q := QuestionEngine.make({"type": "fn-quadratic-features", "unknown": "vertex-from-general", "rep": "equation",
			"angle": "complete-square", "seed": seed})
		texts[q.lines[0]] = true
	check(texts.size() >= 15, "only %d different questions from 20 seeds" % texts.size())


func test_format_does_not_change_the_numbers() -> void:
	var v := {"type": "fn-quadratic-from-conditions", "unknown": "a-from-roots-and-point", "rep": "graph",
		"angle": "intercept-form-plus-point", "seed": 9}
	v.format = "value"
	var a := QuestionEngine.make(v)
	v.format = "mcq"
	var b := QuestionEngine.make(v)
	check_eq(a.answer_text, b.answer_text)


func test_format_layer_names_all_eight() -> void:
	check_eq(QuestionEngine.FORMATS.size(), 8)
	for f in ["value", "mcq", "error-spot", "method-pick", "true-false-reason", "match", "order-steps", "pick-the-graph"]:
		check(f in QuestionEngine.FORMATS, f)
	var v := {"type": "fn-quadratic-features", "unknown": "axis-from-general", "rep": "equation", "angle": "minus-b-over-2a",
		"seed": 1, "format": "error-spot"}
	check(QuestionEngine.make(v).get("error", "").contains("not built yet"), "an unbuilt format says so")
	v.format = "nonsense"
	check(QuestionEngine.make(v).has("error"))


func test_views_outside_the_catalogue_are_refused() -> void:
	var base := {"type": "fn-quadratic-features", "unknown": "axis-from-general", "rep": "equation", "angle": "minus-b-over-2a", "seed": 1}
	for change in [{"rep": "table"}, {"angle": "factorise"}, {"unknown": "nope"}, {"type": "fn-solve-quadratic"}]:
		var v := base.duplicate()
		v.merge(change, true)
		check(QuestionEngine.make(v).has("error"), "%s should be refused" % change)


func test_concept_unknowns_are_multiple_choice() -> void:
	var q := QuestionEngine.make({"type": "fn-concept-quadratic-forms", "unknown": "missing-form", "rep": "equation",
		"angle": "roots-to-factors", "seed": 1, "format": "value"})
	check_eq(q.format, "mcq")


func test_four_different_options_one_right() -> void:
	for c in QuestionEngine.cells():
		for seed in [5, 6]:
			var q := QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": "mcq"})
			check_eq(q.choices.size(), 4, c.key)
			check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
			var texts := {}
			for o in q.choices:
				texts[o.text] = true
			check_eq(texts.size(), 4, c.key + ": options differ")


## Every misconception the catalogue lists as a distractor shows up as a wrong option,
## tagged with its ref, on the unknowns it names.
func test_every_distractor_misconception_is_an_option() -> void:
	for id in TYPES:
		var t := QuestionEngine.type_of(id)
		for m in t.misconceptions:
			if m.ref in ERROR_SPOT:
				check_eq(m.as, "error-spot", m.ref)
				continue
			check_eq(m.as, "distractor", m.ref)
			for u in m.in:
				var found := false
				for c in QuestionEngine.cells(false, [id]).filter(func(x): return x.unknown == u):
					for seed in range(1, 25):
						var q := QuestionEngine.make({"type": id, "unknown": u, "rep": c.rep, "angle": c.angle, "seed": seed, "format": "mcq"})
						if q.choices.any(func(o): return o.ref == m.ref):
							found = true
							break
					if found:
						break
				check(found, "%s: %s never appears on %s" % [id, m.ref, u])


func test_a_typed_misconception_is_recognised() -> void:
	var q := QuestionEngine.make({"type": "fn-quadratic-features", "unknown": "vertex-from-vertex-form", "rep": "equation",
		"angle": "read-vertex-form", "seed": 3, "format": "value"})
	var r := QuestionEngine.mark(q, {"x": Fmt.num(q.answer.values.x.neg()), "y": Fmt.num(q.answer.values.y)})
	check(not r.correct)
	check_eq(r.misconception, "SL2.6.vertex#0")


func test_probes() -> void:
	var probes := QuestionEngine.probes()
	check_eq(probes.size(), 8)
	check(QuestionEngine.probes(true).is_empty(), "exam-only leaves probes out")
	var tfr := QuestionEngine.probe("fn-quadratic-features", 2)
	check_eq(tfr.kind, "true-false-reason")
	check_eq(tfr.verdict, "False")
	check(QuestionEngine.mark_probe(tfr, "False").correct)
	check(not QuestionEngine.mark_probe(tfr, "True").correct)
	var asn := QuestionEngine.probe("fn-quadratic-features", 1)
	check_eq(asn.verdict, "Sometimes")
	var ip := QuestionEngine.probe("fn-quadratic-features", 0)
	check_eq(ip.verdict, "", "interpret-parameter is self-marked")
	check_eq(ip.options, QuestionEngine.SELF_MARK)
	var pc := QuestionEngine.probe("fn-quadratic-from-conditions", 0)
	check_eq(pc.kind, "predict-check")
	check_eq(pc.verdict, "Positive")


func test_exam_only_cells() -> void:
	var cells := QuestionEngine.cells(true)
	check(not cells.is_empty())
	for c in cells:
		check(c.exam, c.key)
		check(c.type != "fn-concept-quadratic-forms", c.key)
	# The same counts tools/pedagogy.mjs gives with "Exam-style only" on.
	check_eq(cells.filter(func(c): return c.type == "fn-quadratic-features").size(), 25)
	check_eq(cells.filter(func(c): return c.type == "fn-quadratic-from-conditions").size(), 32)


func test_no_engine_script_uses_expression() -> void:
	for dir in ["res://engine", "res://engine/situations", "res://ui"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				var src := FileAccess.get_file_as_string(dir.path_join(f))
				check(not src.contains("Expression.new") and not src.contains("Expression)"), "%s/%s uses Expression" % [dir, f])
