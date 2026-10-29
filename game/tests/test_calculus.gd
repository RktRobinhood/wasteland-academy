extends "res://tests/test_case.gd"
## The question engine on the cubic situation (FAL-394): the four Topic 5 types are
## built, their misconceptions show up as options, and the new answer kinds mark the
## way the IB does. The SymPy checker (tools/check-answers) checks the maths.

const TYPES := ["t5-differentiate-polynomial", "t5-tangent-normal-equation", "t5-tangent-condition", "t5-stationary-points"]
## Cells per type, counted as tools/pedagogy.mjs counts them.
const CATALOGUE_CELLS := {"t5-differentiate-polynomial": 5, "t5-tangent-normal-equation": 10, "t5-tangent-condition": 6, "t5-stationary-points": 14}


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "value", paper: int = 0) -> Dictionary:
	var view := {"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func test_the_four_topic_5_types_are_built() -> void:
	var built := QuestionEngine.built_types()
	for t in TYPES:
		check(t in built, "%s is not built" % t)
		check_eq(QuestionEngine.cells(false, [t]).size(), CATALOGUE_CELLS[t], t)


## Every misconception the catalogue lists shows up as a wrong option, tagged with
## its ref, on the unknowns it names.
func test_every_distractor_misconception_is_an_option() -> void:
	for id in TYPES:
		var t := QuestionEngine.type_of(id)
		for m in t.misconceptions:
			check_eq(m.as, "distractor", m.ref)
			for u in m.in:
				var found := false
				for c in QuestionEngine.cells(false, [id]).filter(func(x): return x.unknown == u):
					for seed in range(1, 40):
						var q := _make(id, u, c.rep, c.angle, seed, "mcq")
						if q.choices.any(func(o): return o.ref == m.ref):
							found = true
							break
					if found:
						break
				check(found, "%s: %s never appears on %s" % [id, m.ref, u])


func test_the_stationary_points_are_whole_numbers() -> void:
	for seed in range(1, 31):
		var q := _make("t5-stationary-points", "stationary-points", "equation", "solve-f-prime-zero", seed, "value", 1)
		for k in ["x1", "y1", "x2", "y2"]:
			check(q.answer.values[k].is_int(), "seed %d: %s = %s" % [seed, k, q.answer.values[k]])


func test_stationary_points_in_either_order() -> void:
	var q := _make("t5-stationary-points", "stationary-points", "words", "solve-f-prime-zero", 3, "value", 1)
	var v: Dictionary = q.answer.values
	var swapped := {"x1": v.x2.key(), "y1": v.y2.key(), "x2": v.x1.key(), "y2": v.y1.key()}
	check(QuestionEngine.mark(q, swapped).correct, "the two points in the other order")
	var mixed := {"x1": v.x1.key(), "y1": v.y2.key(), "x2": v.x2.key(), "y2": v.y1.key()}
	check(not QuestionEngine.mark(q, mixed).correct, "the y-values swapped between the points")
	var zeros := {"x1": v.x1.key(), "y1": "0", "x2": v.x2.key(), "y2": "0"}
	var r := QuestionEngine.mark(q, zeros)
	check(not r.correct)
	check_eq(r.misconception, "SL5.8.find-stationary-points#2")


func test_nature_is_multiple_choice() -> void:
	var q := _make("t5-stationary-points", "nature", "equation", "second-derivative-test", 2, "value")
	check_eq(q.format, "mcq")
	check_eq(q.choices.size(), 4)
	var right: Array = q.choices.filter(func(o): return o.correct)
	check_eq(right.size(), 1)
	var a: Q = Q.of(q.situation.a.to_int())
	check_eq(right[0].values.k1, "local maximum" if a.sign() > 0 else "local minimum")
	var flipped: Array = q.choices.filter(func(o): return o.ref == "SL5.8.classify-stationary-points#0")
	check_eq(flipped.size(), 1)
	check(QuestionEngine.mark(q, {"choice": q.choices.find(flipped[0])}).misconception == "SL5.8.classify-stationary-points#0")


func test_the_derivative_is_marked_exactly() -> void:
	var q := _make("t5-differentiate-polynomial", "derivative", "equation", "power-rule", 7)
	var v: Dictionary = q.answer.values
	var typed := {"u2": v.u2.key(), "u1": v.u1.key(), "u0": v.u0.key()}
	check(QuestionEngine.mark(q, typed).correct)
	typed.u2 = "%s.001" % v.u2.key()
	check(not QuestionEngine.mark(q, typed).correct, "a coefficient off by 0.001 is wrong")


func test_the_normal_takes_three_significant_figures() -> void:
	var tried := 0
	for seed in range(1, 60):
		var q := _make("t5-tangent-normal-equation", "normal-at-point", "equation", "negative-reciprocal", seed)
		var m: Q = q.answer.values.m
		if m.is_int():
			continue
		tried += 1
		var c: Q = q.answer.values.c
		var typed := {"m": String.num(m.to_float(), 4), "c": String.num(c.to_float(), 4)}
		check(QuestionEngine.mark(q, typed).correct, "seed %d: %s" % [seed, typed])
		if tried >= 5:
			break
	check(tried > 0, "no normal with a fractional gradient in 60 seeds")


func test_the_normal_is_paper_1_friendly() -> void:
	for seed in range(1, 101):
		var q := _make("t5-tangent-normal-equation", "normal-at-point", "words", "rearranged-form", seed, "value", 1)
		check_eq(q.paper, 1)
		var v: Dictionary = q.answer.values
		check(v.m.d <= CubicSituation.NORMAL_DEN_MAX and v.c.d <= CubicSituation.NORMAL_DEN_MAX,
			"seed %d: y = %sx + %s" % [seed, v.m.key(), v.c.key()])


func test_words_ask_for_dy_dx() -> void:
	var q := _make("t5-differentiate-polynomial", "derivative", "words", "power-rule", 1)
	check(q.asked.contains("dy/dx"), q.asked)
	check(q.lines[0].begins_with("A curve has equation y = "), q.lines[0])
	check(q.answer_text.begins_with("dy/dx = "), q.answer_text)


func test_another_way_is_worked_too() -> void:
	var q := _make("t5-tangent-normal-equation", "tangent-at-point", "equation", "find-c", 4)
	check_eq(q.solutions.map(func(s): return s.angle), ["find-c", "point-gradient"])
	q = _make("t5-stationary-points", "nature", "words", "cubic-shape", 4)
	check_eq(q.solutions.size(), 3)


func test_the_tangent_condition_hides_a_coefficient() -> void:
	for seed in range(1, 21):
		var q := _make("t5-tangent-condition", "coefficient-from-tangent", "equation", "form-equations", seed)
		check(q.lines[0].contains("k"), q.lines[0])
		check(q.answer.get("exact", false), "k is marked exactly")
		var hid: String = q.situation.hidden
		check_eq(q.answer.values.v.key(), q.situation[hid], "seed %d" % seed)


# ── Paper 1 or 2 (FAL-419) ───────────────────────────────────

const PAPER_2_CELLS := [
	["t5-tangent-condition", "x-for-gradient", "equation", "solve-f-prime"],
	["t5-tangent-condition", "x-for-gradient", "words", "match-gradients"],
	["t5-tangent-normal-equation", "tangent-at-point", "words", "point-gradient"],
	["t5-tangent-normal-equation", "normal-at-point", "equation", "negative-reciprocal"],
	["t5-stationary-points", "stationary-points", "words", "solve-f-prime-zero"],
	["t5-stationary-points", "max-value", "equation", "derivative-zero-and-test"],
]


func test_which_cells_make_paper_2() -> void:
	var views := CubicViews.new()
	for u in ["derivative", "derivative-from-fraction", "gradient-at-point", "read-from-tangent", "coefficient-from-tangent", "nature", "inflexion-point"]:
		check_eq(views.papers(u, "equation", "any"), [1], u)
	for u in CubicViews.PAPER_2:
		check_eq(views.papers(u, "words", "any"), [1, 2], u)
	check_eq(QuestionEngine.cell_papers(QuestionEngine.type_of("t5-differentiate-polynomial"), "derivative", "equation", "power-rule"), [1])


## Paper 2: a decimal cubic, answers to 3 s.f. that need rounding, and GDC working.
func test_paper_2_needs_a_calculator() -> void:
	for c in PAPER_2_CELLS:
		for seed in range(1, 16):
			var q := _make(c[0], c[1], c[2], c[3], seed, "mcq", 2)
			var key := "%s seed %d" % [c[1], seed]
			check_eq(q.paper, 2, key)
			check_eq(q.situation.paper, 2, key)
			check(q.lines[0].contains("."), "%s: %s has no decimals" % [key, q.lines[0]])
			check(q.asked.contains("correct to 3 significant figures"), key)
			check_eq(q.answer.get("show", ""), "sf", key)
			check(not q.answer.get("exact", false), "%s is marked exactly" % key)
			check(q.answer.values.values().any(func(v): return v is Q and Answer.needs_rounding(v)), "%s: %s needs no rounding" % [key, q.answer_text])
			for sol in q.solutions:
				check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [key, sol.steps.size()])
				check(" ".join(sol.steps).contains("GDC"), "%s: the working doesn't use the GDC" % key)
			for o in q.choices:
				for v in o.values.values():
					if v is Q and not v.is_zero() and not o.get("trap", false):
						check(Answer.rounds_clearly(v.to_float()), "%s: option %s on a rounding edge" % [key, o.text])


## The answer typed to 3 s.f. is right; to 2 s.f. it is a glancing hit.
func test_paper_2_marks_three_significant_figures() -> void:
	var q := _make("t5-stationary-points", "stationary-points", "equation", "solve-f-prime-zero", 4, "value", 2)
	var typed := {}
	for k in q.answer.values:
		typed[k] = Fmt.sf(q.answer.values[k]).replace("−", "-")
	check(QuestionEngine.mark(q, typed).correct, str(typed))
	q = _make("t5-tangent-normal-equation", "normal-at-point", "words", "rearranged-form", 5, "value", 2)
	var v: Dictionary = q.answer.values
	check(QuestionEngine.mark(q, {"m": Fmt.sf(v.m).replace("−", "-"), "c": Fmt.sf(v.c).replace("−", "-")}).correct, q.answer_text)
	check(q.answer_text.begins_with("y = ") and q.answer_text.contains("x"), q.answer_text)


## Where one number is the answer (the local maximum), the rounding trap is an option.
func test_paper_2_has_the_rounding_trap() -> void:
	var traps := 0
	for seed in range(1, 21):
		var q := _make("t5-stationary-points", "max-value", "words", "derivative-zero-and-test", seed, "mcq", 2)
		var t: Array = q.choices.filter(func(o): return o.get("trap", false))
		if not t.is_empty():
			traps += 1
			check(not t[0].correct and t[0].ref == "")
			check(QuestionEngine.mark(q, {"choice": q.choices.find(t[0])}).glancing)
	check(traps >= 15, "the rounding trap on %d of 20" % traps)


## Paper 1 is today's cubic: the same numbers as with no paper at all.
func test_paper_1_keeps_its_numbers() -> void:
	for c in PAPER_2_CELLS:
		var t := QuestionEngine.type_of(c[0])
		for seed in range(1, 11):
			var q := _make(c[0], c[1], c[2], c[3], seed, "value", 1)
			check_eq(q.paper, 1)
			var need: Dictionary = CubicViews.new().need(c[1], c[2])
			need["angle"] = c[3]
			var s := CubicSituation.generate(Seeded.new("%s|%d" % [QuestionEngine.cell_key(t.id, c[1], c[2], c[3]), seed]), need)
			for k in ["a", "b", "c", "d"]:
				check_eq(q.situation[k], s[k].key(), "%s seed %d: %s" % [c[1], seed, k])
