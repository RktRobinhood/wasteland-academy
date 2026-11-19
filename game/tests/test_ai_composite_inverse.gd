extends "res://tests/test_case.gd"
## The ai-composite-inverse situation (FAL-1007): fn-ai-composite-inverse is built with every cell and
## all four AI-AHL2.7 skills, only for AI HL, Paper 2 throughout; every cell makes four options with
## one right and the answer in each working's last step; every tagged slip shows up; the table and
## graph cells show their figure; a typed answer is marked by its value; hand-worked composites and
## inverses. The SymPy checker (tools/check-answers, r9ac_check) checks the maths.

const TYPE := "fn-ai-composite-inverse"
const CELLS := 35
const SKILLS := ["AI-AHL2.7.composite-context", "AI-AHL2.7.find-inverse", "AI-AHL2.7.restrict-domain",
	"AI-AHL2.7.inverse-identity"]
const S := preload("res://engine/situations/ai_composite_inverse.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	for s in SKILLS:
		check(skills.has(s), "no unknown tests %s" % s)


func test_only_ai_hl_gets_it() -> void:
	for course in ["aa-sl", "aa-hl", "ai-sl"]:
		check(QuestionEngine.cells(false, [TYPE], course).is_empty(), "%s offers %s" % [course, TYPE])
	check_eq(QuestionEngine.cells(false, [TYPE], "ai-hl").size(), CELLS, "ai-hl")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		check_eq(QuestionEngine.cell_papers(QuestionEngine.type_of(TYPE), c.unknown, c.rep, c.angle), [2], c.key)
		for f in ["value", "mcq"]:
			for seed in range(1, 7):
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "ai-composite-inverse", c.key)
				check_eq(q.paper, 2, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check(q.solutions[0].angle == c.angle, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
					check(Step.texts(sol.steps)[-1].contains(q.answer_text), "%s: the last step doesn't say %s" % [c.key, q.answer_text])
				if c.rep == "table":
					check(q.table != null, c.key + " has no table")
				if c.rep == "graph":
					check(q.graph != null, c.key + " has no graph")
				if c.unknown == "inverse-graph":
					check_eq(q.format, "pick-the-graph", c.key)
					check_eq(q.graphs.size(), 4, c.key)


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 61):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	var ty := QuestionEngine.type_of(TYPE)
	var ms: Array = ty.misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never comes up" % ref)
	for ref in seen:
		check(QuestionEngine.misconception_text(ty, ref) != "", "%s has no text" % ref)


func test_a_typed_answer_is_marked_by_its_value() -> void:
	var c := {"unknown": "composite-equation", "rep": "words", "angle": "inside-out"}
	for seed in range(1, 8):
		var q := _make(c, seed, "value")
		var v: Q = q.answer.values.v
		var typed: String = (Fmt.dec(v) if q.answer.get("exact", false) else Fmt.sf(v)).replace("−", "-")
		check(QuestionEngine.mark(q, {"v": typed}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v": Fmt.dec(v.add(1))}).correct, "one more")
	var d := {"unknown": "inverse-value", "rep": "equation", "angle": "solve-for-value"}
	for seed in range(1, 8):
		var q := _make(d, seed, "value")
		var v: Q = q.answer.values.v
		var typed: String = (Fmt.dec(v) if q.answer.get("exact", false) else Fmt.sf(v)).replace("−", "-")
		check(QuestionEngine.mark(q, {"v": typed}).correct, q.answer_text)


func test_the_order_slip_is_never_a_negative_time() -> void:
	for seed in range(1, 41):
		var q := _make({"unknown": "composite-equation", "rep": "words", "angle": "inside-out"}, seed)
		for o in q.choices:
			if o.ref == "AI-AHL2.7.composite-context#0":
				check(Q.of(o.values.v).sign() > 0, "seed %d: %s" % [seed, o.text])


func test_hand_worked_values() -> void:
	# n(t) = 35t + 20, C(n) = 2.5n + 400: C(n(3)) = 2.5 × 125 + 400 = 712.5, and C(n(t)) = 87.5t + 450.
	var g: Array = [Q.new(20), Q.new(35)]
	var f: Array = [Q.new(400), Q.new(5, 2)]
	check(S.ev(f, S.ev(g, 3)).eq(Q.new(1425, 2)), "C(n(3)) = 712.5")
	var h := S.comp(f, g)
	check(h[0].eq(450) and h[1].eq(Q.new(175, 2)), "C(n(t)) = 87.5t + 450")
	# The rule as written: a falling line starts with its constant.
	check_eq(AiCompositeInverseViews.ptext([Q.new(80), Q.new(-3, 25)], "d"), "80 − 0.12d")
	check_eq(AiCompositeInverseViews.ptext([Q.new(150), Q.new(3), Q.new(1, 50)], "n"), "0.02n² + 3n + 150")
	# F(d) = 2.2d + 4: F⁻¹(30.4) = 12; the steps undone in the original order give 30.4/2.2 − 4.
	var taxi := {"fam": "lin", "m": Q.new(11, 5), "b": Q.new(4)}
	check(absf(S.finv(taxi, 30.4) - 12.0) < 1e-9, "F⁻¹(30.4) = 12")
	check(absf(S.wrong_order(taxi, 30.4) - (30.4 / 2.2 - 4.0)) < 1e-9, "the wrong order")
	# A(n) = 2.5 + 600/n: A⁻¹(5) = 240.
	var avg := {"fam": "rat", "c": Q.new(5, 2), "k": Q.new(600)}
	check(absf(S.finv(avg, 5.0) - 240.0) < 1e-9, "A⁻¹(5) = 240")
	# S(p) = 4 + 2.5 ln p: S⁻¹(9) = e² = 7.389.
	var sig := {"fam": "log", "a": Q.new(4), "b": Q.new(5, 2)}
	check(absf(S.finv(sig, 9.0) - exp(2.0)) < 1e-9, "S⁻¹(9) = e²")
	# V(h) = 0.2h³ + 1.5h: V(5) = 32.5, so V⁻¹(32.5) = 5 by the solver.
	var tank := {"fam": "cubic", "a": Q.new(1, 5), "c": Q.new(3, 2)}
	check(absf(S.finv(tank, 32.5) - 5.0) < 1e-6, "V⁻¹(32.5) = 5")
	# 0.5(x − 6)² + 22 = 0.5x² − 6x + 40: the vertex is at x = 6.
	var pump := {"qa": Q.new(1, 2), "qh": Q.new(6), "qk": Q.new(22)}
	var co := S.quad_co(pump)
	check(co[0].eq(40) and co[1].eq(-6) and co[2].eq(Q.new(1, 2)), "0.5x² − 6x + 40")
