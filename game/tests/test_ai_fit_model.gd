extends "res://tests/test_case.gd"
## The ai-fit-model situation (FAL-1001): fn-ai-fit-model is built with every cell and its
## AI SL 2.6 and 2.5 skills, only for the AI courses, Paper 2 throughout; every cell makes four
## options with one right and says its answer in each working's last step; tables and figures
## are shown; every tagged slip shows up; a typed value is marked by its value; the factor, the
## start, both constants, the quadratics, the cubic and the sinusoid against values worked by
## hand. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "fn-ai-fit-model"
const CELLS := 26
const SKILLS := ["AI-SL2.6.find-parameters", "AI-SL2.5.exponential-model", "AI-SL2.5.quadratic-model",
	"AI-SL2.5.sinusoidal-model"]
const S := preload("res://engine/situations/ai_fit_model.gd")
const V := preload("res://engine/situations/ai_fit_model_views.gd")


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
				check_eq(q.situation_id, "ai-fit-model", c.key)
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
				# The figure or table the question depends on is shown.
				if c.rep == "graph":
					check(q.graph != null and not q.graph.points.is_empty(), c.key + " shows no figure")
				if c.rep == "table":
					check(q.table != null, c.key + " shows no table")
				# The check-point method shows a further value to check against.
				if c.angle == "check-point":
					check(q.asked.contains("check"), c.key + " asks no check")


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 41):
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
	var c := {"unknown": "exp-factor-from-point", "rep": "words", "angle": "eliminate"}
	for seed in range(1, 6):
		var q := _make(c, seed, "value")
		var v: Q = q.answer.values.v
		check(QuestionEngine.mark(q, {"v": Fmt.sf(v)}).correct, q.answer_text)
		check(not QuestionEngine.mark(q, {"v": Fmt.sf(v.mul(2))}).correct, "twice")
	var d := {"unknown": "quadratic-three-points", "rep": "table", "angle": "simultaneous-gdc"}
	for seed in range(1, 6):
		var q := _make(d, seed, "value")
		var vals: Dictionary = q.answer.values
		var typed := {"v0": Fmt.dec(vals.v0), "v1": Fmt.dec(vals.v1), "v2": Fmt.dec(vals.v2)}
		check(QuestionEngine.mark(q, typed).correct, q.answer_text)
		typed.v1 = Fmt.dec(vals.v1.add(1))
		check(not QuestionEngine.mark(q, typed).correct, "b one more")


func test_the_exponentials_by_hand() -> void:
	# 500a^6 = 820: a = 1.64^(1/6) = 1.08594…; the ratio without the root is 1.64.
	var s := {"form": "factor", "k": Q.new(500), "V": Q.new(820), "T": 6}
	s.key = S.factor_key(s)
	check(absf(s.key - pow(1.64, 1.0 / 6.0)) < 1e-12, str(s.key))
	var vals: Array = S.factor_slips(s)
	check(absf(vals[1] - 1.64) < 1e-12, "the ratio")
	# Swapped: 500a^820 = 6, so a = (6/500)^(1/820) = 0.99462…
	check_eq(Fmt.sf(vals[2]), "0.995")
	# 500e^(6r) = 820: r = ln(1.64)/6 = 0.0824…
	s.form = "cont"
	s.key = S.factor_key(s)
	check_eq(Fmt.sf(s.key), "0.0824")
	# k(1.08)^5 = 735: k = 735/1.46933 = 500.23…, and once is 735/1.08 = 680.6.
	var t := {"a": Q.new(108, 100), "T": 5, "V": Q.new(735)}
	t.key = t.V.to_float() / pow(1.08, 5)
	var st: Array = S.start_slips(t)
	check_eq(Fmt.sf(st[0]), "500")
	check_eq(Fmt.sf(st[1]), "681")
	# k(0.8)^t + c with T(0) = 90 and T(3) = 55.84: k = 34.16/0.488 = 70, c = 20; with
	# k = 90, c = 55.84 − 90 × 0.512 = 9.76.
	var u := {"a": Q.new(4, 5), "T": 3, "k": Q.new(70), "c": Q.new(20), "P0": Q.new(90), "V": Q.new(5584, 100)}
	var opts: Array = S.two_options(u)
	check_eq(opts[1].map(func(v): return Fmt.dec(v)), ["90", "9.76"])


func test_the_quadratics_and_the_cubic_by_hand() -> void:
	# y = −0.5x² + 4x + 10 through x = 1, 4, 6: y = 13.5, 18, 16.
	var s := {"co": [Q.new(-1, 2), Q.new(4), Q.new(10)], "xs": [Q.new(1), Q.new(4), Q.new(6)]}
	check_eq(S.ys_of(s).map(func(y): return Fmt.dec(y)), ["13.5", "18", "16"])
	# Swapped: a·y² + b·y + c = x through (13.5, 1), (18, 4), (16, 6) has one solution.
	var opts: Array = S.quad_three_options(s)
	check_eq(opts.size(), 4)
	var a: Q = S.solve3([[Q.new(729, 4), Q.new(27, 2), Q.new(1)], [Q.new(324), Q.new(18), Q.new(1)],
		[Q.new(256), Q.new(16), Q.new(1)]], [Q.new(1), Q.new(4), Q.new(6)])[0]
	check(absf(a.to_float() - opts[1][0].to_float()) < 0.01 * absf(a.to_float()), "the swapped a")
	# Through (0, 2) with axis x = 3 and (5, 9.5): a(25 − 30) = 7.5, a = −1.5, b = 9.
	var q := {"co": [Q.new(-3, 2), Q.new(9), Q.new(2)], "h": 3, "p": 5}
	var qo: Array = S.quad_sym_options(q)
	# a·x for a·x²: a(5 − 30) = 7.5, a = −0.3, b = 1.8; the sign dropped: a(25 + 30) = 7.5,
	# a = 0.136…, b = 6a = 0.818…
	check_eq(qo[1].map(func(v): return Fmt.dec(v)), ["−0.3", "1.8", "2"])
	check_eq(qo[2].map(func(v): return Fmt.dec(v)), ["0.136", "0.818", "2"])
	# The cubic's coefficients in reverse.
	var c := {"co": [Q.new(1, 2), Q.new(-2), Q.new(3), Q.new(12)]}
	check_eq(S.cubic_options(c)[1].map(func(v): return Fmt.dec(v)), ["3", "−2", "0.5"])


func test_the_sinusoid_by_hand() -> void:
	# d = a sin(30t) + c with d(1) = 7 and d(9) = 2.5: 0.5a + c = 7, −a + c = 2.5, so a = 3, c = 5.5.
	var s := {"b": 30, "ts": [1, 9], "amp": Q.new(3), "mid": Q.new(11, 2)}
	check_eq(S.sin_ys(s).map(func(y): return Fmt.dec(y)), ["7", "2.5"])
	var opts: Array = S.sin_options(s)
	# In radians: sin 30 = −0.988…, sin 270 = −0.176…: a = 4.5/(−0.812…) = −5.54.
	var r1 := sin(30.0)
	var r2 := sin(270.0)
	check_eq(Fmt.dec(opts[1][0]), Fmt.sf(4.5 / (r1 - r2)))
	check_eq(V.lin([Q.new(1, 2), Q.new(1)], ["a", "c"]), "0.5a + c")
	check_eq(V.lin([Q.new(-1), Q.new(1)], ["a", "c"]), "−a + c")
