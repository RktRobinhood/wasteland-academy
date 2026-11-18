extends "res://tests/test_case.gd"
## The log-technology situation (FAL-999): t1-ext-logs-with-technology is built with every cell for
## SL1.5.evaluate-tech, on all four courses, Paper 2 throughout; every cell makes four options with
## one right and every slip shows up; method-pick is on every cell and error-spot on the two
## equations, with the first wrong line marked. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t1-ext-logs-with-technology"
const CELLS := 8
const S := preload("res://engine/situations/log_technology.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	for course in ["aa-sl", "aa-hl", "ai-sl", "ai-hl"]:
		check_eq(QuestionEngine.cells(false, [TYPE], course).size(), CELLS, course)
	for u in QuestionEngine.type_of(TYPE).unknowns:
		check_eq(u.skills, ["SL1.5.evaluate-tech"])


func test_every_cell_and_format_makes_four_options() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check_eq(QuestionEngine.cell_papers(QuestionEngine.type_of(TYPE), c.unknown, c.rep, c.angle), [2], c.key)
		var extra := QuestionEngine.extra_formats(TYPE, c.unknown, c.angle)
		check("method-pick" in extra, c.key + " has no method-pick")
		check(("error-spot" in extra) == (c.unknown in ["solve-ten-or-e", "solve-base"]), c.key + " error-spot")
		for f in ["value", "mcq"] + extra:
			for seed in range(1, 6):
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.paper, 2, c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)


func test_error_spot_marks_the_first_wrong_line() -> void:
	for u in ["solve-ten-or-e", "solve-base"]:
		var c := {"unknown": u, "rep": "equation", "angle": "log-key"}
		var at := {}
		for seed in range(1, 21):
			var q := _make(c, seed, "error-spot")
			at[q.spot.bad] = true
			check(q.choices[q.spot.bad].correct, "%s seed %d" % [u, seed])
		check_eq(at.size(), 2, u + ": the slip is on one line only")


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 61):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
			var q := _make(c, seed, "error-spot") if c.unknown in ["solve-ten-or-e", "solve-base"] else {}
			if q.has("spot"):
				seen[q.spot.ref] = true
	var t := QuestionEngine.type_of(TYPE)
	var ms: Array = t.misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never comes up" % ref)


func test_hand_values() -> void:
	check(absf(S.lg("log", 50.0) - 1.698970004) < 1e-9, "log 50")
	check(absf(S.lg("ln", 12.0) - 2.484906650) < 1e-9, "ln 12")
	# 3 ln 5 − log 2 = 4.828314 − 0.301030
	var s := {"form": "ln-log", "p": 3, "q": 5, "r": 2}
	check(absf(S.expression(s, false, false) - 4.527284) < 1e-6, "3 ln 5 − log 2")
	check(absf(S.expression(s, true, false) - (3.0 * S.lg("log", 5.0) - S.lg("ln", 2.0))) < 1e-12, "the keys swapped")
