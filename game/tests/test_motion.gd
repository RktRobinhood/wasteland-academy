extends "res://tests/test_case.gd"
## The motion situation (FAL-724): t5-kinematics-motion is built with every catalogue cell,
## Paper 1 is whole numbers, Paper 2 asks a model to 3 s.f., and a graph's axes are named.
## The SymPy checker checks the maths.

const TYPE := "t5-kinematics-motion"
const CELLS := 47
const SKILLS := 4


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format, "paper": paper})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), SKILLS, "every skill the catalogue lists has a question")


func test_every_cell_makes_a_question_with_four_different_options() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in range(1, 7):
				var q := _make(c.unknown, c.rep, c.angle, seed, f)
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.choices.size(), 4, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s: two options read the same" % c.key)


func test_a_gdc_method_is_paper_2() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.angle.begins_with("gdc-"):
			check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), [2], c.key)


func test_paper_1_is_a_polynomial_and_paper_2_a_model() -> void:
	var one := _make("first-at-rest", "equation", "solve-v-zero", 3, "mcq", 1)
	check_eq(one.situation.fam, "poly")
	var two := _make("first-at-rest", "equation", "solve-v-zero", 3, "mcq", 2)
	check(two.situation.fam in ["pulse", "wave", "damped"], two.situation.fam)


func test_a_hand_case() -> void:
	# v(t) = 3(t − 1)(t − 3) = 3t² − 12t + 9, so a(t) = 6t − 12.
	var s := {"fam": "poly", "vc": [3, -12, 9], "T": 5}
	var v := MotionSituation.v_of(s)
	var a := MotionSituation.a_of(s)
	check_eq(v.call(2.0), -3.0)
	check_eq(a.call(3.0), 6.0)
	MotionSituation.features(s)
	check_eq(s.z.size(), 2)
	check(absf(s.z[1] - 3.0) < 1e-9, "the second rest")
	check_eq(s.smax, 24.0, "|v(5)| = 24 is greater than |v(2)| = 3")


func test_a_derivative_matches_its_function() -> void:
	for fam in ["pulse", "wave", "damped"]:
		var s := {"fam": fam, "A": 7, "B": 2, "k": Q.new(1, 5), "w": Q.new(4, 5)}
		var v := MotionSituation.v_of(s)
		var a := MotionSituation.a_of(s)
		var j := MotionSituation.j_of(s)
		var h := 1e-5
		for t in [0.5, 1.7, 3.2]:
			check(absf((v.call(t + h) - v.call(t - h)) / (2.0 * h) - a.call(t)) < 1e-6, fam + ": a is not dv/dt")
			check(absf((a.call(t + h) - a.call(t - h)) / (2.0 * h) - j.call(t)) < 1e-6, fam + ": j is not da/dt")


func test_a_motion_graph_names_its_axes() -> void:
	var q := _make("displacement-from-graph", "graph", "signed-area", 4)
	check_eq(q.graph.x_name, "t")
	check_eq(q.graph.y_name, "v")
	var r := _make("velocity-from-graph", "graph", "gradient-reading", 4)
	check_eq(r.graph.y_name, "s")


func test_no_wrong_option_on_speeding_up_states_the_right_verdict() -> void:
	# #193: "Speeding up: a is positive." was a wrong option even when v > 0, where it is right.
	var tagged := {true: 0, false: 0}
	for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == "speeding-up"):
		for paper in [1, 2]:
			if not paper in QuestionEngine.cell_papers(QuestionEngine.type_of(TYPE), c.unknown, c.rep, c.angle):
				continue
			for seed in range(1, 30):
				var q := _make(c.unknown, c.rep, c.angle, seed, "mcq", paper)
				check(q.asked.ends_with("Give a reason."), q.asked)
				var key: String = q.choices.filter(func(o): return o.correct)[0].text
				var verdict: String = key.split(":")[0]
				# "When t = 3, v = −4 and a = 6.": the sign of v as the question shows it.
				var v: float = -1.0 if q.lines[1].contains(", v = −") else 1.0
				for o in q.choices:
					if not o.correct:
						check(not o.text.begins_with(verdict + ":"), "%s seed %d: %s" % [c.key, seed, o.text])
					if o.ref == R_A_POSITIVE_REF:
						tagged[v < 0.0] += 1
	check_eq(tagged[false], 0, "the sign-of-a slip is offered when v > 0")
	check(tagged[true] > 0, "the sign-of-a slip never shows")


const R_A_POSITIVE_REF := "SL5.9.rest-and-direction#1"
