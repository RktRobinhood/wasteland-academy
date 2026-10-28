extends "res://tests/test_case.gd"
## The question engine on the cubic situation (FAL-394): the four Topic 5 types are
## built, their misconceptions show up as options, and the new answer kinds mark the
## way the IB does. The SymPy checker (tools/check-answers) checks the maths.

const TYPES := ["t5-differentiate-polynomial", "t5-tangent-normal-equation", "t5-tangent-condition", "t5-stationary-points"]
## Cells per type, counted as tools/pedagogy.mjs counts them.
const CATALOGUE_CELLS := {"t5-differentiate-polynomial": 5, "t5-tangent-normal-equation": 10, "t5-tangent-condition": 6, "t5-stationary-points": 14}


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


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
		var q := _make("t5-stationary-points", "stationary-points", "equation", "solve-f-prime-zero", seed)
		for k in ["x1", "y1", "x2", "y2"]:
			check(q.answer.values[k].is_int(), "seed %d: %s = %s" % [seed, k, q.answer.values[k]])


func test_stationary_points_in_either_order() -> void:
	var q := _make("t5-stationary-points", "stationary-points", "words", "solve-f-prime-zero", 3)
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
		var q := _make("t5-tangent-condition", "coefficient-from-tangent", "equation", "gradient-match", seed)
		check(q.lines[0].contains("k"), q.lines[0])
		check(q.answer.get("exact", false), "k is marked exactly")
		var hid: String = q.situation.hidden
		check_eq(q.answer.values.v.key(), q.situation[hid], "seed %d" % seed)
