extends "res://tests/test_case.gd"
## The rational-quadratic situation (FAL-1007): fn-ahl-rational-quadratic is built with every cell
## and all five AA HL 2.13 skills, on AA HL only; a GDC method is Paper 2 and every other cell can be
## either paper, with exact turning values on Paper 1 and 3 s.f. ones on Paper 2; every cell makes
## four options with one right and the answer in each working's last step; every tagged slip shows
## up; pick the graph draws every branch, with each wrong card one mistake; typed answers are marked
## by their value; hand-worked ranges and asymptotes. The SymPy checker (tools/check-answers,
## r9rq_check) checks the maths.

const TYPE := "fn-ahl-rational-quadratic"
const CELLS := 31
const SKILLS := ["AHL2.13.vertical-asymptotes", "AHL2.13.horizontal-asymptote", "AHL2.13.oblique-asymptote",
	"AHL2.13.range-turning-points", "AHL2.13.sketch"]
const S := preload("res://engine/situations/rational_quadratic.gd")
const V := preload("res://engine/situations/rational_quadratic_views.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq", extra: Dictionary = {}) -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}.merged(extra))


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


func test_a_gdc_method_is_paper_2_and_the_rest_either() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var want := [2] if c.angle.begins_with("gdc-") else [1, 2]
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), want, c.key)
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for f in ["value", "mcq"]:
			for seed in range(1, 7):
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "rational-quadratic", c.key)
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
					if q.paper == 1:
						check(not sol.angle.begins_with("gdc-"), c.key + ": a GDC tab on Paper 1")


func test_paper_1_ranges_are_exact_and_paper_2_ones_to_3_sf() -> void:
	for u in ["range-lq", "range-ql"]:
		var c: Dictionary = QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u and x.angle == "discriminant-in-x")[0]
		for paper in [1, 2]:
			for seed in range(1, 9):
				var q := _make(c, seed, "mcq", {"paper": paper})
				check_eq(q.paper, paper, c.key)
				var lo: Variant = q.situation.ylo if u == "range-lq" else q.situation.L
				# Export writes an exact value as "p/q" text and a GDC value as a float.
				check_eq(lo is String, paper == 1, "%s Paper %d: %s" % [u, paper, lo])
				check_eq(q.answer_text.contains("."), paper == 2, "%s Paper %d: %s" % [u, paper, q.answer_text])


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


func test_a_tag_is_only_on_the_unknowns_it_lists() -> void:
	var ty := QuestionEngine.type_of(TYPE)
	var where := {}
	for i in ty.misconceptions.size():
		where[ty.misconceptions[i].get("ref", "%s#%d" % [TYPE, i])] = ty.misconceptions[i].in
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 21):
			for o in _make(c, seed).choices:
				if o.ref != "":
					check(c.unknown in where[o.ref], "%s tags %s" % [c.key, o.ref])


func test_pick_the_graph_shows_every_branch() -> void:
	for u in ["sketch-lq", "sketch-ql"]:
		for seed in range(1, 21):
			var q := _make({"unknown": u, "rep": "equation", "angle": "asymptotes-intercepts-signs"}, seed)
			check_eq(q.format, "pick-the-graph", u)
			check_eq(q.graphs.size(), 4, u)
			var right: int = q.choices.map(func(o): return o.correct).find(true)
			var g: Dictionary = q.graphs[right]
			var pieces: int = g.get("sand_from", g.curves.size())
			check_eq(pieces, 2 if u == "sketch-ql" else 3, "%s seed %d: the right card's branches" % [u, seed])
			var tagged: Array = q.choices.filter(func(o): return o.ref != "")
			check_eq(tagged.size(), 1, u)
			check_eq(tagged[0].mistake, "no-zero" if u == "sketch-lq" else "no-constant", u)
			if u == "sketch-ql":
				check(g.curves.size() > pieces, "the oblique asymptote is drawn")


func test_the_graph_view_shows_its_asymptotes() -> void:
	for seed in range(1, 11):
		var q := _make({"unknown": "denominator-from-asymptote", "rep": "graph", "angle": "factorise-denominator"}, seed)
		check(q.graph != null, "no graph")
		check(not q.graph.vlines.is_empty(), "no vertical asymptote drawn")


func test_a_typed_answer_is_marked_by_its_value() -> void:
	for seed in range(1, 8):
		var q := _make({"unknown": "oblique-asymptote", "rep": "equation", "angle": "polynomial-division"}, seed, "value")
		var m: Q = q.answer.values.m
		var c: Q = q.answer.values.c
		check(QuestionEngine.mark(q, {"m": m.key(), "c": c.key()}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"m": m.key(), "c": "0"}).correct, "the constant dropped is wrong")
		var v := _make({"unknown": "vertical-asymptote-ql", "rep": "equation", "angle": "factorise-denominator"}, seed, "value")
		var h: Q = v.answer.values.h
		check(QuestionEngine.mark(v, {"var": "x", "h": h.key()}).correct, v.answer_text)
		check(not QuestionEngine.mark(v, {"var": "x", "h": h.neg().key()}).correct, "the sign changed is wrong")


func test_hand_worked_values() -> void:
	# x/(x² + 1): E = 1, so the turning points are x = ±1 and the range −1/2 ≤ f(x) ≤ 1/2.
	var s := {"form": "lq", "a": 1, "b": 0, "p": 0, "q": 1, "zs": [], "nz": 0}
	check(S._lq_range(s, 1), "x/(x² + 1) has an exact range")
	check(s.ylo.eq(Q.new(-1, 2)) and s.yhi.eq(Q.new(1, 2)), "%s, %s" % [s.ylo, s.yhi])
	check(s.xlo.eq(-1) and s.xhi.eq(1), "%s, %s" % [s.xlo, s.xhi])
	# (x − 1)/(x² + 2x + 2): E = 1 + 2 + 2 = 5 is no square, so it is Paper 2, and
	# y = (2 + 2 ± 2√5)/(4 − 8) = −1 ∓ √5/2.
	var t := {"form": "lq", "a": 1, "b": -1, "p": 2, "q": 2, "zs": [], "nz": 0}
	check(not S._lq_range(t, 1), "√5 is not exact")
	check(S._lq_range(t, 2), "a Paper 2 range")
	check(absf(t.ylo - (-1.0 - sqrt(5.0) / 2.0)) < 1e-9 and absf(t.yhi - (-1.0 + sqrt(5.0) / 2.0)) < 1e-9, "%s, %s" % [t.ylo, t.yhi])
	# (x² + 1)/(x − 2) = x + 2 + 5/(x − 2): mR = 5, so L = 4 − 2√5 and U = 4 + 2√5, at x = 2 ∓ √5.
	var u := {"form": "ql", "m": 1, "e": -2, "k": 2, "R": 5, "b": 0, "c": 1}
	check(S._ql_turns(u, 2), "a Paper 2 quadratic over a linear")
	check(absf(u.L - (4.0 - 2.0 * sqrt(5.0))) < 1e-9 and absf(u.U - (4.0 + 2.0 * sqrt(5.0))) < 1e-9, "%s, %s" % [u.L, u.U])
	check(absf(u.xL - (2.0 - sqrt(5.0))) < 1e-9 and absf(u.xU - (2.0 + sqrt(5.0))) < 1e-9, "%s, %s" % [u.xL, u.xU])
	# −x − 1/x on the left of 0 has the local minimum 2 and on the right the local maximum −2.
	var w := {"form": "ql", "m": -1, "e": 0, "k": 0, "R": -1, "b": 0, "c": -1}
	check(S._ql_turns(w, 1), "an exact quadratic over a linear")
	check(w.L.eq(-2) and w.U.eq(2) and w.xL.eq(1) and w.xU.eq(-1), "%s at %s, %s at %s" % [w.L, w.xL, w.U, w.xU])
	# The oblique asymptote of (2x² − x + 5)/(x − 1) = 2x + 1 + 6/(x − 1).
	var o := {"form": "ql", "m": 2, "b": -1, "c": 5, "e": -1}
	check_eq(V.text(o), "(2x² − x + 5)/(x − 1)")
	check(absf(S.ql_y(o, 3.0) - (7.0 + 3.0)) < 1e-9, "f(3) = 2(3) + 1 + 6/2")
