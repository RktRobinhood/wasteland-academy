extends "res://tests/test_case.gd"
## The ai-optimisation situation (FAL-1000): t5-ai-optimisation is built with every cell and all
## four AI SL 5.7 skills, only for the AI courses, Paper 2 throughout; every cell makes four
## options with one right; the asked method's working comes first and every working ends on the
## answer; every tagged slip shows up; a vertex working is on a quadratic model only; the nearest
## whole number is never the best one; a typed answer is marked by its value; and a few values
## are worked by hand. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t5-ai-optimisation"
const CELLS := 50
const SKILLS := ["AI-SL5.7.optimise-given-model", "AI-SL5.7.build-model-from-constraint",
	"AI-SL5.7.optimise-container", "AI-SL5.7.interpret-optimum-in-context"]
const S := preload("res://engine/situations/ai_optimisation.gd")


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
				check_eq(q.situation_id, "ai-optimisation", c.key)
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
				# A figure where the representation is a diagram, a table where it is a table.
				check((q.graph != null) == (c.rep == "diagram"), c.key + ": the figure")
				check((q.table != null) == (c.rep == "table"), c.key + ": the table")


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


func test_a_vertex_working_is_on_a_quadratic_model_only() -> void:
	for u in ["optimal-input-given-model", "optimum-value-given-model"]:
		var kinds := {}
		for seed in range(1, 41):
			var q := _make({"unknown": u, "rep": "equation", "angle": "gdc-maximum"}, seed)
			var k: String = q.situation.kind
			kinds[k] = true
			var names: Array = q.solutions.map(func(sol): return sol.angle)
			check(("vertex-of-quadratic-model" in names) == (k == "quad"), "%s seed %d: a %s model" % [u, seed, k])
			# Only the GDC optimises an angle model.
			check(("derivative-zero" in names) != (k == "angle"), "%s seed %d: calculus on a %s model" % [u, seed, k])
		for k in ["quad", "cubic", "recip", "angle"]:
			check(kinds.has(k), "%s never draws a %s model" % [u, k])
		# Asked by the vertex, the model is a quadratic.
		for seed in range(1, 11):
			check_eq(_make({"unknown": u, "rep": "words", "angle": "vertex-of-quadratic-model"}, seed).situation.kind, "quad", u)


func test_the_nearest_whole_number_is_never_the_best() -> void:
	for seed in range(1, 41):
		var s := S.generate(Seeded.new("whole|%d" % seed), {"ask": "whole-number-optimum"})
		check(not s.is_empty(), "no whole-number model")
		var n: int = s.n
		check_eq(roundi(s.x), n, "x rounds to n")
		check(s.at_up.lt(s.at_n) != s.big, "n + 1 is not the better whole number: %s" % str(s))
		check(S.exact(s, Q.new(n + 1)).eq(s.at_up), "the value at n + 1")


func test_a_typed_value_is_marked_by_its_value() -> void:
	var c := {"unknown": "optimum-value-given-model", "rep": "equation", "angle": "gdc-maximum"}
	for seed in range(1, 6):
		var q := _make(c, seed, "value")
		var v: Q = q.answer.values.v
		check(QuestionEngine.mark(q, {"v": Fmt.sf(v)}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v": Fmt.sf(v.mul(2))}).correct, "twice the answer")
	var d := {"unknown": "profit-from-revenue-cost", "rep": "words", "angle": "derivative-zero"}
	for seed in range(1, 6):
		var q := _make(d, seed, "value")
		check(QuestionEngine.mark(q, {"v": Fmt.dec(q.answer.values.v)}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v": Fmt.dec(q.answer.values.v.add(1))}).correct, "one more")


func test_values_worked_by_hand() -> void:
	# P(x) = −0.4x² + 36x − 210: P′ = −0.8x + 36 = 0 at x = 45, and P(45) = −810 + 1620 − 210 = 600.
	var quad := {"kind": "quad", "big": true, "terms": [[Q.new(-2, 5), 2], [Q.new(36), 1], [Q.new(-210), 0]]}
	check(absf(S.value(quad, 45.0) - 600.0) < 1e-9, "P(45)")
	check(absf(S.slope(quad, 45.0)) < 1e-12, "P′(45)")
	check(S.exact_slope(quad, Q.new(30)).eq(Q.new(12)), "P′(30) = −24 + 36 = 12")
	# C(x) = 49.9x + 300/x + 120: C(2) = 99.8 + 150 + 120 = 369.8, C(3) = 149.7 + 100 + 120 = 369.7,
	# so 3 is the best whole number though x = √(300/49.9) = 2.45194 rounds to 2.
	var recip := {"kind": "recip", "big": false, "a": Q.new(499, 10), "b": Q.new(300), "c": Q.new(120)}
	check(S.exact(recip, Q.new(2)).eq(Q.new(3698, 10)), "C(2)")
	check(S.exact(recip, Q.new(3)).eq(Q.new(3697, 10)), "C(3)")
	check(absf(sqrt(300.0 / 49.9) - 2.45194) < 1e-5, "x for C")
	# Demand 600 − 8p, 12 scrap an item, 450 fixed: P = (p − 12)(600 − 8p) − 450 is greatest at
	# p = (600 + 96)/16 = 43.5, where P = 31.5 × 252 − 450 = 7488.
	var dem := {"kind": "demand", "A": 600, "B": 8, "cost": 12, "F": 450}
	check(absf(S.value(dem, 43.5) - 7488.0) < 1e-9, "the greatest profit")
	check(absf(S.slope(dem, 43.5)) < 1e-12, "P′ at the best price")
	# With the base as wide as the sides are long, A = sin θ (1 + cos θ) is greatest at 60°:
	# sin 60° × 1.5 = 1.29904.
	var ang := {"kind": "angle", "k": Q.new(1), "w": Q.new(1)}
	check(absf(S.value(ang, 60.0) - 1.29904) < 1e-5, "A(60°)")
	# A 30 km leg off the road and B 40 km along it, both at 50 km/h: √(900 + 1600) ÷ 50 = 1 hour.
	check(absf(S.one_speed({"a": 30, "b": 40, "back": 50, "cost": false}) - 1.0) < 1e-12, "one speed")
