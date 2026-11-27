extends "res://tests/test_case.gd"

const ID := "t3-ahl-vector-basics"
const CELL := {"type": ID, "unknown": "basis-vector-to-components", "rep": "equation", "angle": "read-axis-labels"}
const SKILL := "AHL3.12.components-displacement"

func test_native_course_and_difficulty() -> void:
	for course in ["aa-sl", "aa-hl", "ai-sl", "ai-hl"]:
		var expected: bool = course == "aa-hl"
		check_eq(ID in QuestionEngine.built_types(course), expected, course)
		var requests := MathsEngine.requests(course, false, [ID])
		check_eq(requests.size(), int(expected), course)
		if expected and not requests.is_empty():
			check_eq(requests[0].level, 1)
		check(MathsEngine.requests(course, true, [ID]).is_empty(), "not exam style")
		var probes := QuestionEngine.probes(false, course).filter(func(p): return p.type == ID)
		check_eq(probes.size(), int(expected), "one mandatory static concept for the same skill")
		if expected and not probes.is_empty():
			check_eq(probes[0].level, 3)
			var probe := MathsEngine.generate({"format": "probe", "type": ID, "probe": probes[0].index})
			check_eq(probe.verdict, "False")
			check(probe.reveal.contains("missing y-component 0"))

func test_visible_signed_terms_through_exact_and_mcq_marking() -> void:
	var parser := RegEx.create_from_string("^Vector: (−?)([0-9]*)([ijk]) ([+−]) ([0-9]*)([ijk])$")
	var seen := {}
	var omitted := {}
	for seed in range(1, 451):
		var req := CELL.duplicate()
		req.seed = seed
		req.format = "value"
		var q := MathsEngine.generate(req)
		if q.has("error"):
			fail(str(q.error))
			return
		check_eq(q.level, 1)
		check_eq(q.paper, 1)
		check_eq(MathsEngine.question_skills(q), [SKILL])
		var m := parser.search(q.lines[-1])
		if m == null:
			fail("display has no readable vector expression")
			return
		var coords := {"x": "0", "y": "0", "z": "0"}
		var a := "xyz".substr("ijk".find(m.get_string(3)), 1)
		var b := "xyz".substr("ijk".find(m.get_string(6)), 1)
		var v := m.get_string(2) if m.get_string(2) != "" else "1"
		var w := m.get_string(5) if m.get_string(5) != "" else "1"
		coords[a] = ("-" if m.get_string(1) == "−" else "") + v
		coords[b] = ("-" if m.get_string(4) == "−" else "") + w
		var zero_axis := ""
		for axis in coords:
			if coords[axis] == "0":
				zero_axis = axis
		check(not zero_axis.is_empty() and a != b and v != w)
		omitted[zero_axis] = true
		seen[m.get_string(0)] = true
		var wrong := coords.duplicate()
		wrong[a] = coords[b]
		wrong[b] = coords[a]
		check(MathsEngine.mark(q, coords).correct)
		check_eq(MathsEngine.mark(q, wrong).misconception, ID + "#0")
		wrong = coords.duplicate()
		wrong[zero_axis] = ""
		check(not MathsEngine.mark(q, wrong).complete, "an omitted coefficient is entered as zero, not blank")
		req.format = "mcq"
		var pick := MathsEngine.generate(req)
		check_eq(pick.lines[-1], q.lines[-1], "formats use same problem")
		check_eq(pick.choices.size(), 4)
		var success := 0
		for i in pick.choices.size():
			var values: Dictionary = pick.choices[i].values
			var expected := true
			for axis in coords:
				expected = expected and Q.of(values[axis]).eq(Q.new(int(coords[axis])))
			var marked := MathsEngine.mark(pick, {"choice": i})
			check_eq(marked.correct, expected)
			success += int(expected)
		check_eq(success, 1, "exactly one choice matches printed basis coefficients")
	check(seen.size() >= 300, "visible expressions vary substantially")
	check_eq(omitted.size(), 3)
