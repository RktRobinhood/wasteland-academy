extends "res://tests/test_case.gd"
## The ai-quadratic-model situation (FAL-1001): fn-ai-quadratic-model is built with every cell and
## its AI SL 2.5 skill, only for the AI courses, Paper 2 throughout; every cell makes four options
## with one right and says its answer in each working's last step; the figure is shown on every
## graph and diagram cell; every tagged slip shows up; a typed value is marked by its value; the
## vertex, the crossings, the widths and the pen's area against values worked by hand. The SymPy
## checker (tools/check-answers) checks the maths.

const TYPE := "fn-ai-quadratic-model"
const CELLS := 28
const SKILLS := ["AI-SL2.5.quadratic-model"]
const S := preload("res://engine/situations/ai_quadratic_model.gd")
const V := preload("res://engine/situations/ai_quadratic_model_views.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS, TYPE)
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
		check_eq(QuestionEngine.cells(false, [TYPE], course).size(), CELLS, "%s on %s" % [TYPE, course])


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
				check_eq(q.situation_id, "ai-quadratic-model", c.key)
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
				# The figure the question depends on is shown.
				if c.rep in ["graph", "diagram"]:
					check(q.graph != null, c.key + " shows no figure")
				else:
					check(q.graph == null, c.key + " shows a figure it doesn't need")


func test_the_midpoint_of_the_zeros_is_only_for_a_flight_from_the_ground() -> void:
	for rep in ["equation", "graph"]:
		var c := {"unknown": "time-of-vertex", "rep": rep, "angle": "midpoint-of-roots"}
		for seed in range(1, 9):
			var q := _make(c, seed)
			check(q.situation.c == "0", "%s seed %d: launched above the ground" % [rep, seed])
		var d := {"unknown": "time-of-vertex", "rep": rep, "angle": "axis-formula"}
		for seed in range(1, 9):
			var q := _make(d, seed)
			check(not q.solutions.any(func(sol): return sol.angle == "midpoint-of-roots") or q.situation.c == "0",
				"%s seed %d: the midpoint of the zeros worked on a flight from above the ground" % [rep, seed])


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


func test_a_typed_value_is_marked_by_its_value() -> void:
	var c := {"unknown": "initial-height", "rep": "equation", "angle": "any"}
	for seed in range(1, 6):
		var q := _make(c, seed, "value")
		var v: Q = q.answer.values.v
		check(QuestionEngine.mark(q, {"v": Fmt.dec(v)}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v": Fmt.dec(v.add(1))}).correct, "one more")
	var d := {"unknown": "landing-time", "rep": "words", "angle": "gdc-poly-solver"}
	for seed in range(1, 6):
		var q := _make(d, seed, "value")
		check(QuestionEngine.mark(q, {"v": Fmt.sf(q.answer.values.v)}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v": Fmt.sf(q.answer.values.v.neg())}).correct, "the negative zero")


func test_a_flight_by_hand() -> void:
	# h(t) = −5t² + 20t + 25: the top at t = 2, h = 45; h = 0 at t = −1 and t = 5; h = 40 at 1 and 3.
	var s := {"a": Q.new(-5), "b": Q.new(20), "c": Q.new(25)}
	var v := S.vertex(s)
	check_eq(Fmt.dec(v[0]), "2")
	check_eq(Fmt.dec(v[1]), "45")
	var z := S.crossings(s)
	check(absf(z[0] + 1.0) < 1e-9 and absf(z[1] - 5.0) < 1e-9, str(z))
	z = S.crossings(s, 40.0)
	check(absf(z[0] - 1.0) < 1e-9 and absf(z[1] - 3.0) < 1e-9, str(z))
	# The slip t = b/(2a) = −2 gives h(−2) = −20 − 40 + 25 = −35.
	check_eq(Fmt.dec(S.value(s, v[0].neg())), "−35")


func test_an_arch_and_a_pen_by_hand() -> void:
	# y = −0.25(x − 2)(x − 10) = −0.25x² + 3x − 5: the top 4 m at x = 6; 3 m up at x = 4 and 8,
	# so 4 m wide there, half of it 2, the span 8 and the drop 1.
	var s := {"a": Q.new(-1, 4), "b": Q.new(3), "c": Q.new(-5), "p": 2, "q": 10, "form": 2, "level": Q.new(3)}
	var o: Array = S.width_slips(s)
	check_eq(o.map(func(x): return Fmt.dec(x)), ["2", "8", "1", "8"])
	check_eq(V.model(s, "x"), "−0.25x² + 3x − 5")
	# A pen against a wall with 40 m of fence: y = 40 − 2x, A = −2x² + 40x; all round, A = −x² + 20x.
	check_eq(S.pen_area({"wall": true, "F": 40}).map(func(x): return Fmt.dec(x)), ["−2", "40"])
	check_eq(S.pen_area({"wall": false, "F": 40}).map(func(x): return Fmt.dec(x)), ["−1", "20"])
