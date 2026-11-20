extends "res://tests/test_case.gd"
## The ahl-inequality situation (FAL-1008): fn-ahl-inequalities is built with every cell and its
## five AHL2.15 skills, only for AA HL; every cell makes four options with one right and the
## answer in each working's last step; the GDC unknowns are Paper 2; every tagged slip shows up;
## a graph question shows its figure; the hand-worked sets hold. The SymPy checker
## (tools/check-answers, ahlinq_check) checks the maths.

const TYPE := "fn-ahl-inequalities"
const CELLS := 44
const SKILLS := ["AHL2.15.polynomial-inequality", "AHL2.15.read-from-graphs", "AHL2.15.technology-inequality",
	"AHL2.15.rational-inequality", "AHL2.15.context-inequality"]
## The unknowns that can't be read without their figure.
const FIGURE := ["read-from-graphs", "horizontal-band"]
const S := preload("res://engine/situations/ahl_inequality.gd")
const V := preload("res://engine/situations/ahl_inequality_views.gd")


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
	for s in SKILLS:
		check(skills.has(s), "no unknown tests %s" % s)


func test_only_aa_hl_gets_it() -> void:
	for course in ["aa-sl", "ai-sl", "ai-hl"]:
		check(QuestionEngine.cells(false, [TYPE], course).is_empty(), "%s offers %s" % [course, TYPE])
	check_eq(QuestionEngine.cells(false, [TYPE], "aa-hl").size(), CELLS, "aa-hl")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in range(1, 7):
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "ahl-inequality", c.key)
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


func test_the_gdc_unknowns_are_paper_2_and_the_rest_both() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var ps := QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle)
		if c.unknown in ["technology-inequality", "least-whole-number"] or QuestionEngine.gdc_method(t, c.unknown, c.angle) \
				or (c.unknown == "context-models" and c.angle != "algebraic-polynomial-model"):
			check_eq(ps, [2], c.key)
		else:
			check_eq(ps, [1, 2], c.key)
		for p in ps:
			var q := _make(c, 3, "mcq", p)
			check(not q.has("error") and q.paper == p, "%s on Paper %d" % [c.key, p])
			if p == 1:
				# Paper 1's ends are exact: no decimal in the answer.
				check(not q.answer_text.contains("."), "%s: Paper 1 answer %s" % [c.key, q.answer_text])


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


func test_a_figure_question_shows_its_figure() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.rep != "graph":
			continue
		for seed in range(1, 6):
			var q := _make(c, seed)
			check(q.graph != null and not q.graph.curves.is_empty(), "%s seed %d: no graph" % [c.key, seed])
			if c.unknown in FIGURE:
				# The figure is the only place the crossings are given.
				check(q.graph.points.size() >= 2, "%s seed %d: the crossings are not marked" % [c.key, seed])
				for p in q.graph.points:
					check(p.label != "", "%s seed %d: a crossing has no label" % [c.key, seed])


func test_the_least_whole_number_is_typed_and_marked_by_value() -> void:
	var c := {"unknown": "least-whole-number", "rep": "words", "angle": "interpret-domain"}
	for seed in range(1, 10):
		var q := _make(c, seed, "value")
		var n: Q = q.answer.values.v
		check(QuestionEngine.mark(q, {"v": n.text()}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v": n.sub(1).text()}).correct, "one less")
	for i in 100:
		var s := S.generate(Seeded.new("whole|%d" % i), {"form": "whole"})
		var n: int = s.n
		var now: float = S.whole_at(s, float(n))
		var before: float = S.whole_at(s, float(n - 1))
		if s.fam == "decay":
			check(now < s.T and before >= s.T, "draw %d: n = %d is the first below %s" % [i, n, s.T])
		else:
			check(now > s.T and before <= s.T, "draw %d: n = %d is the first above %s" % [i, n, s.T])


func test_hand_worked_sets() -> void:
	# x(x + 1)(x − 2) ≤ 0: x ≤ −1 or 0 ≤ x ≤ 2.
	check_eq(V.set_text(V.cubic_set(1, [-1, 0, 2], "≤")), "x ≤ −1 or 0 ≤ x ≤ 2")
	# −(x + 2)(x − 1)(x − 2) ≥ 0: x ≤ −2 or 1 ≤ x ≤ 2.
	check_eq(V.set_text(V.cubic_set(-1, [-2, 1, 2], "≥")), "x ≤ −2 or 1 ≤ x ≤ 2")
	# x³ > 9x keeps −3 < x < 0.
	check_eq(V.set_text(V.cubic_set(1, [-3, 0, 3], ">")), "−3 < x < 0 or x > 3")
	# (x + 3)(x − 1)² > 0: the repeated root is left out of one piece, written x ≠ 1.
	var h := func(x: float) -> float: return (x + 3) * (x - 1) * (x - 1)
	var ps := V.solve(V.zeros_crit([-3, 1], ">"), func(x: float) -> bool: return V.holds(">", h.call(x)))
	check_eq(V.set_text(ps), "x > −3, x ≠ 1")
	ps = V.solve(V.zeros_crit([-3, 1], "≥"), func(x: float) -> bool: return V.holds("≥", h.call(x)))
	check_eq(V.set_text(ps), "x ≥ −3")
	# (x − 5)/x ≥ −4: x < 0 or x ≥ 1, the asymptote left out.
	var r := func(x: float) -> float: return (x - 5) / x + 4
	ps = V.solve([[Q.new(0), false], [Q.new(1), true]], func(x: float) -> bool: return V.holds("≥", r.call(x)))
	check_eq(V.set_text(ps), "x < 0 or x ≥ 1")
	# With a domain: t ≥ 0 and t < 5.
	ps = V.solve([[Q.new(-2), false], [Q.new(5), false]], func(t: float) -> bool: return (t + 2) * (5 - t) > 0.0, Q.new(0), true)
	check_eq(V.set_text(ps, "t"), "0 ≤ t < 5")


func test_a_double_root_keeps_the_far_side() -> void:
	for i in 100:
		var s := S.generate(Seeded.new("double|%d" % i), {"form": "double"})
		check(not s.is_empty(), "draw %d" % i)
		var beyond: float = s.q + (1.0 if s.q > s.p else -1.0)
		check(V.holds(s.rel, (beyond - s.p) * (beyond - s.q) * (beyond - s.q)), "draw %d: the far side of x = %d fails" % [i, s.q])


func test_the_gdc_crossings_are_crossings() -> void:
	for i in 60:
		var s := S.generate(Seeded.new("tech|%d" % i), {"form": "tech"})
		check(not s.is_empty(), "draw %d" % i)
		for x in s.xs:
			check(absf(S.tech_h(s, x)) < 1e-7, "draw %d: h(%s) = %s" % [i, x, S.tech_h(s, x)])
		var m := S.generate(Seeded.new("models|%d" % i), {"form": "models", "angle": "gdc-intersections-context"})
		for t in m.ts:
			check(absf(S.models_h(m, V.F(t))) < 1e-6, "draw %d: A(%s) − B(%s) = %s" % [i, t, t, S.models_h(m, V.F(t))])
