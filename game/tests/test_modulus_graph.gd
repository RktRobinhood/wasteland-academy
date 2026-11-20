extends "res://tests/test_case.gd"
## The modulus-graph situation (FAL-1008): fn-ahl-modulus-graphs is built with every cell and
## all four AA HL 2.16 skills, on AA HL only; a GDC method is Paper 2 and every other cell
## either paper; every cell makes four options with one right and the answer in each
## working's last step; every tagged slip shows up, and only on the unknowns it lists; pick
## the graph shows f and four cards, each wrong card one named transformation, 1/f drawn
## branch by branch; typed answers are marked by their value; hand-worked features. The
## SymPy checker (tools/check-answers, modgr_check) checks the maths.

const TYPE := "fn-ahl-modulus-graphs"
const CELLS := 31
const SKILLS := ["AHL2.16.modulus-graphs", "AHL2.16.reciprocal-graph", "AHL2.16.square-graph", "AHL2.16.modulus-inequality"]
const S := preload("res://engine/situations/modulus_graph.gd")
const V := preload("res://engine/situations/modulus_graph_views.gd")
const PICK := ["modulus-of-f", "f-of-modulus", "modulus-of-both", "pick-reciprocal", "pick-square"]


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
				check_eq(q.situation_id, "modulus-graph", c.key)
				check_eq(q.format == "pick-the-graph", c.unknown in PICK, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check(q.solutions[0].angle == c.angle, c.key)
				if c.rep == "graph":
					check(q.graph != null, c.key + ": no graph of f")
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
					check(Step.texts(sol.steps)[-1].contains(q.answer_text), "%s: the last step doesn't say %s" % [c.key, q.answer_text])
					if q.paper == 1:
						check(not sol.angle.begins_with("gdc-"), c.key + ": a GDC tab on Paper 1")


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


func test_pick_the_graph_cards_are_their_transformations() -> void:
	for u in PICK:
		var angle: String = QuestionEngine.angles_for(QuestionEngine.type_of(TYPE), u)[0]
		for seed in range(1, 16):
			var q := _make({"unknown": u, "rep": "graph", "angle": angle}, seed)
			check_eq(q.format, "pick-the-graph", u)
			check_eq(q.graphs.size(), 4, u)
			var right: int = q.choices.map(func(o): return o.correct).find(true)
			var g: Dictionary = q.graphs[right]
			check(g.card, u)
			# The right card is the transformation PICKS names: each point lies on it.
			var name: String = V.PICKS[u][0]
			for c in g.curves:
				for p in c:
					var want := V.card_y(_sit(q), name, p[0])
					check(absf(want - p[1]) < 1e-6 * maxf(1.0, absf(p[1])), "%s seed %d: (%s, %s) is off the right card" % [u, seed, p[0], p[1]])
					break
			if u == "pick-reciprocal":
				# One branch more than there are asymptotes, and none crosses one.
				check_eq(g.curves.size(), 3, "%s seed %d: the branches of 1/f" % [u, seed])
				check_eq(g.vlines.size(), 2, u)
			for o in q.choices:
				if not o.correct:
					check(o.why != "", "%s: a wrong card says nothing" % u)


## The situation back from its export, for the card functions (Q from "p/q" text).
func _sit(q: Dictionary) -> Dictionary:
	var s: Dictionary = q.situation.duplicate(true)
	if s.has("coef"):
		s.coef = s.coef.map(func(c): return _q(c))
	if s.has("a"):
		s.a = _q(s.a)
	return s


func _q(v: Variant) -> Q:
	if v is Q:
		return v
	var t := str(v)
	if "/" in t:
		var parts := t.split("/")
		return Q.new(int(parts[0]), int(parts[1]))
	return Q.new(int(t))


func test_a_typed_answer_is_marked_by_its_value() -> void:
	for seed in range(1, 8):
		var q := _make({"unknown": "vertex-image", "rep": "equation", "angle": "reflect-negative-part"}, seed, "value")
		var x: Q = q.answer.values.x
		var yv: Q = q.answer.values.y
		check(QuestionEngine.mark(q, {"x": x.key(), "y": yv.key()}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"x": x.key(), "y": yv.neg().key()}).correct, "the sign changed is wrong")
		var r := _make({"unknown": "f-of-modulus-intercepts", "rep": "equation", "angle": "keep-right-reflect"}, seed, "value")
		var resp := {}
		var n := int(str(r.answer.values.n))
		# Any order is right.
		for i in n:
			resp["x%d" % i] = r.answer.values["x%d" % (n - 1 - i)].key()
		check(QuestionEngine.mark(r, resp).correct, r.answer_text)


func test_hand_worked_values() -> void:
	# x² − 2x − 8 = (x + 2)(x − 4): vertex (1, −9), so |f| moves it to (1, 9).
	var s := S.quad(Q.new(1), 1, -9)
	check_eq(s.zs, [-2, 4])
	check_eq(V.rule(s), "x² − 2x − 8")
	# ½(x + 1)(x − 2)²: zeros −1 and 2, touching at 2; the other turning point (0, 2).
	var c := S.cubic(Q.new(1, 2), -1, 2)
	check_eq(c.t, 0)
	check(c.v.eq(2), "the cubic's turning value is %s" % c.v)
	check(absf(S.y(c, 0.0) - 2.0) < 1e-12, "f(0) = 2")
	check_eq(V.factored(c), "½(x + 1)(x − 2)²")
	# The cards at x = −3 on (x + 2)(x − 4): f(−3) = 7, f(3) = −5.
	check(absf(V.card_y(s, "fabs", -3.0) - (-5.0)) < 1e-12, "f(|−3|) = f(3)")
	check(absf(V.card_y(s, "fnegabs", 3.0) - 7.0) < 1e-12, "f(−|3|) = f(−3)")
	check(absf(V.card_y(s, "absabs", -3.0) - 5.0) < 1e-12, "|f(|−3|)| = 5")
	check(absf(V.card_y(s, "sgnsq", 3.0) - (-25.0)) < 1e-12, "f|f| at 3 is −25")
	check(absf(V.card_y(s, "recipmid", 0.0) - 1.0 / 8.0) < 1e-12, "the middle branch flipped: −1/f(0) = 1/8")
	check(absf(V.card_y(s, "k2recip", 1.0) - (-9.0)) < 1e-12, "k²/f at the vertex is k")
	# The period of [3 sin(2x)]² is π/2.
	var w := {"fam": "sine", "a": Q.new(3), "A": 3, "b": 2, "zs": []}
	check_eq(V.rule(w), "3 sin(2x)")
	var q := V.new()._square_period(w)
	check_eq(q.answer.values.text, "π/2")
