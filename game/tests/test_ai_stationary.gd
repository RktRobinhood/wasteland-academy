extends "res://tests/test_case.gd"
## The ai-stationary situation (FAL-1000): t5-ai-stationary-points is built with every cell and all
## five AI SL 5.6 skills, only for the AI courses, Paper 2 throughout; every cell makes four options
## with one right and the answer in each working's last step; every tagged slip shows up; a typed
## answer is marked by its value; the f′-graph views carry this type's refs, not SL5.7's. The SymPy
## checker (tools/check-answers, r2sp_check) checks the maths.

const TYPE := "t5-ai-stationary-points"
const CELLS := 39
const SKILLS := ["AI-SL5.6.solve-gradient-zero", "AI-SL5.6.locate-local-extrema", "AI-SL5.6.classify-by-gradient-sign",
	"AI-SL5.6.greatest-least-on-domain", "AI-SL5.6.read-from-gradient-graph"]
const S := preload("res://engine/situations/ai_stationary.gd")


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


func test_only_the_ai_courses_get_it() -> void:
	for course in ["aa-sl", "aa-hl"]:
		check(QuestionEngine.cells(false, [TYPE], course).is_empty(), "%s offers %s" % [course, TYPE])
	for course in ["ai-sl", "ai-hl"]:
		check_eq(QuestionEngine.cells(false, [TYPE], course).size(), CELLS, course)


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
				check_eq(q.situation_id, "ai-stationary", c.key)
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
		check(not ref.begins_with("SL5."), "%s is the derivative-graph type's ref" % ref)


func test_the_vertex_working_is_only_on_a_quadratic() -> void:
	for seed in range(1, 21):
		var q := _make({"unknown": "extremum-value-in-context", "rep": "words", "angle": "solve-then-substitute"}, seed)
		var cubic: bool = str(q.situation.co[0]) != "0"
		var has_vertex: bool = q.solutions.any(func(s): return s.angle == "vertex-of-quadratic")
		check_eq(has_vertex, not cubic, "seed %d: %s" % [seed, q.lines[0]])
		var v := _make({"unknown": "extremum-value-in-context", "rep": "words", "angle": "vertex-of-quadratic"}, seed)
		check(not v.has("error"), str(v.get("error")))
		check_eq(str(v.situation.co[0]), "0", "the vertex method gets a quadratic story")


func test_a_typed_answer_is_marked_by_its_value() -> void:
	var c := {"unknown": "local-extremum-point", "rep": "equation", "angle": "solve-then-substitute"}
	for seed in range(1, 8):
		var q := _make(c, seed, "value")
		var x: Q = q.answer.values.x
		var y: Q = q.answer.values.y
		check(QuestionEngine.mark(q, {"x": Fmt.sf(x).replace("−", "-"), "y": Fmt.sf(y).replace("−", "-")}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"x": Fmt.sf(x).replace("−", "-"), "y": "0"}).correct, "y = 0 is wrong")
	var d := {"unknown": "gradient-zero-given-derivative", "rep": "words", "angle": "gdc-equation-solver"}
	for seed in range(1, 6):
		var q := _make(d, seed, "value")
		var v: Q = q.answer.values.v
		check(QuestionEngine.mark(q, {"v": Fmt.sf(v).replace("−", "-")}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v": Fmt.dec(v.add(1))}).correct, "one more")


func test_hand_worked_values() -> void:
	# f(x) = x³ − 6x² + 9x + 1: f′ = 3(x − 1)(x − 3), a maximum f(1) = 5 and a minimum f(3) = 1.
	var co: Array = [Q.new(1), Q.new(-6), Q.new(9), Q.new(1)]
	var st := S.stat(co)
	check(absf(st[0] - 1.0) < 1e-9 and absf(st[1] - 3.0) < 1e-9, str(st))
	check_eq(S.nature(co, 1.0), "maximum")
	check_eq(S.nature(co, 3.0), "minimum")
	check(absf(S.fv(co, 1.0) - 5.0) < 1e-9, "f(1) = 5")
	# The constant kept: 3x² − 12x + 10 = 0, x = 2 ± √(2/3) = 1.18350 and 2.81650.
	var kept := S.kept_roots(co)
	check(absf(kept[0] - 1.183503) < 1e-5 and absf(kept[1] - 2.816497) < 1e-5, str(kept))
	# 2x + 18/x − 5 on x > 0: its minimum is at x = 3, where f = 6 + 6 − 5 = 7.
	var r := {"ra": 2, "rb": 18, "rc": -5}
	check(absf(S.rmin(r) - 3.0) < 1e-9 and absf(S.rv(r, 3.0) - 7.0) < 1e-9, "the reciprocal's minimum")
	# x³ + kx² − 9x + 4 stationary at x = 3: 27 + 6k − 9 = 0, k = −3; f(3) = 0 gives 9k + 4 = 0, k = −0.444.
	var s := {"co": [Q.new(1), Q.new(-3), Q.new(-9), Q.new(4)], "kat": 2, "xk": 3}
	check(absf(S.root_slip_k(s) + 4.0 / 9.0) < 1e-9, str(S.root_slip_k(s)))
	# x³ − 3x² on −1 ≤ x ≤ 4: the local maximum f(0) = 0 loses to the end f(4) = 16.
	var dm := {"co": [Q.new(1), Q.new(-3), Q.new(0), Q.new(0)], "lo": -1, "hi": 4, "want": "greatest", "case": "end"}
	var b := S.best(dm, S.candidates(dm))
	check(absf(b[0] - 4.0) < 1e-9 and absf(b[1] - 16.0) < 1e-9 and b[2] == "end", str(b))
	check(absf(S.domain_slips(dm).local) < 1e-9, "the local maximum's value, 0, is the slip")


func test_the_gradient_graph_views_are_the_derivative_graph_ones() -> void:
	for u in ["extremum-from-gradient-graph", "increasing-from-gradient-graph", "pick-f-from-gradient-graph"]:
		for seed in range(1, 6):
			var q := _make({"unknown": u, "rep": "graph", "angle": "sign-of-gradient-graph"}, seed)
			check(not q.has("error"), str(q.get("error")))
			check_eq(q.situation.dg_ask, S.DG_ASK[u], u)
			check(q.graph != null, u + " draws the graph of f′")
			check(q.lines[0].begins_with("The graph shows y = f′(x)"), q.lines[0])
