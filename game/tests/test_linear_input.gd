extends "res://tests/test_case.gd"
## The linear-input situation (FAL-1008): fn-ext-linear-input (AHL2.16.linear-input) is built
## with every catalogue cell, every question on Paper 1 (nothing needs a calculator); four distinct
## options with one right, the asked method first and the answer in every working's last step;
## a graph on every graph cell and four different cards on pick the graph; error-spot offered
## only on the image of a point and on f(b − x), with its first wrong line marked; every
## distractor misconception shows up as an option; a typed point is marked by its value; and
## images, inputs and a student's solving lines against hand values. The SymPy checker
## (tools/check-answers) checks the maths.

const TYPE := "fn-ext-linear-input"
## Cells, counted as tools/pedagogy.mjs counts them.
const CELLS := 12
const TC := preload("res://engine/situations/transform_chain.gd")
## The unknowns that offer error-spot: a student solving ax + b = p.
const SPOTS := ["image-point", "reflect-inside"]


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	check_eq(t.source, "extension")
	check_eq(t.unknowns.size(), 5)
	for u in t.unknowns:
		check_eq(u.skills, ["AHL2.16.linear-input"], u.id)


func test_every_cell_makes_a_question_in_both_formats() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3, 4, 5, 6]:
				var q := _make(c.unknown, c.rep, c.angle, seed, f)
				check(not q.has("error"), "%s as %s seed %d: %s" % [c.key, f, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "linear-input", c.key)
				check_eq(q.paper, 1, c.key)
				check_eq(q.choices.size(), 4, "%s as %s: options" % [c.key, f])
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, "%s as %s: right options" % [c.key, f])
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, "%s as %s seed %d: two options read the same" % [c.key, f, seed])
				check_eq(q.solutions[0].angle, c.angle, c.key + ": the asked method comes first")
				for sol in q.solutions:
					check(q.answer_text in Step.text(sol.steps[sol.steps.size() - 1]), "%s: the last step doesn't state the answer" % c.key)
				if c.rep == "graph":
					check(q.graph != null, c.key + ": no graph of f")


func test_same_seed_same_question_and_seeds_vary() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var a := _make(c.unknown, c.rep, c.angle, 7, "mcq")
		var b := _make(c.unknown, c.rep, c.angle, 7, "mcq")
		check_eq(a.prompt + str(a.lines) + a.answer_text, b.prompt + str(b.lines) + b.answer_text, c.key)
		var prompts := {}
		for seed in range(1, 13):
			var q := _make(c.unknown, c.rep, c.angle, seed, "mcq")
			prompts[q.prompt + str(q.lines) + (str(q.graph.curves) if q.graph != null else "")] = true
		check(prompts.size() > 6, "%s: only %d different questions in 12 seeds" % [c.key, prompts.size()])


func test_extra_formats_are_error_spot_on_the_solving_unknowns() -> void:
	var made := 0
	for c in QuestionEngine.cells(false, [TYPE]):
		var fs := QuestionEngine.extra_formats(TYPE, c.unknown, c.angle)
		if not c.unknown in SPOTS:
			check(fs.is_empty(), c.key + " offers an extra format")
			continue
		check_eq(fs, ["error-spot"], c.key)
		for seed in range(1, 9):
			var q := _make(c.unknown, c.rep, c.angle, seed, "error-spot")
			check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
			if q.has("error"):
				continue
			check_eq(q.format, "error-spot", c.key)
			check_eq(q.choices.size(), 4, c.key)
			var right: Array = q.choices.filter(func(o): return o.correct)
			check_eq(right.size(), 1, c.key)
			# The marked line is line 3 (b kept its sign) or line 4 (multiplied by a).
			check(right[0].text in ["Line 3", "Line 4"], "%s: %s" % [c.key, right[0].text])
			if c.unknown == "reflect-inside":
				check_eq(right[0].text, "Line 3", c.key + ": f(b − x) has only the sign slip")
			made += 1
	check(made > 0, "no error-spot question was made")


func test_every_distractor_misconception_is_an_option() -> void:
	var ty := QuestionEngine.type_of(TYPE)
	for i in ty.misconceptions.size():
		var m: Dictionary = ty.misconceptions[i]
		var ref: String = m.get("ref", "%s#%d" % [TYPE, i])
		if m.as != "distractor":
			continue
		for u in m.in:
			var found := false
			for c in QuestionEngine.cells(false, [TYPE]).filter(func(x): return x.unknown == u):
				for seed in range(1, 40):
					var q := _make(u, c.rep, c.angle, seed, "mcq")
					if q.has("error"):
						continue
					if q.choices.any(func(o): return o.get("ref", "") == ref):
						found = true
						break
				if found:
					break
			check(found, "%s never offers %s" % [u, ref])


func test_the_four_graphs_of_a_pick_are_different() -> void:
	for seed in range(1, 30):
		var q := _make("pick-graph", "graph", "translate-then-stretch", seed)
		check_eq(q.format, "pick-the-graph")
		check(q.graph != null, "seed %d: the graph of f is shown" % seed)
		check_eq(q.graphs.size(), 4)
		var seen := {}
		for g in q.graphs:
			seen[str(g.curves)] = true
		check_eq(seen.size(), 4, "seed %d: two graphs are the same" % seed)


func test_f_of_b_minus_x_marks_p_on_the_graph() -> void:
	for seed in range(1, 20):
		var q := _make("reflect-inside", "graph", "solve-for-image", seed)
		check(q.graph != null, "seed %d: no graph" % seed)
		check_eq(q.graph.points.size(), 1, "seed %d: only P is marked" % seed)
		check(String(q.graph.points[0].label).begins_with("P("), "seed %d: %s" % [seed, q.graph.points[0]])


func test_a_typed_point_is_marked_by_its_value() -> void:
	for u in ["image-point", "original-point", "reflect-inside"]:
		var q := _make(u, "equation", "solve-for-image", 3)
		var x: Q = q.answer.values.x
		var y: Q = q.answer.values.y
		check(QuestionEngine.mark(q, {"x": x.key(), "y": y.key()}).correct, "%s: %s" % [u, q.answer_text])
		check(not QuestionEngine.mark(q, {"x": x.key(), "y": y.neg().key()}).correct, u + ": the height changed is wrong")
		check(not QuestionEngine.mark(q, {"x": x.add(1).key(), "y": y.key()}).correct, u + ": another x is wrong")


func test_images_against_hand_values() -> void:
	# f(2x + 6): x -> (x − 6)/2, so (4, 1) goes to (−1, 1).
	var m := LinearInputSituation.slip_map(Q.new(2), Q.new(-3))
	var im := _image(m, 4, 1)
	check(im[0].eq(-1) and im[1].eq(1), "f(2x + 6) takes (4, 1) to (−1, 1): %s" % str(im))
	# f(½x − 2): x -> 2(x + 2), so (−1, 2) goes to (2, 2).
	m = LinearInputSituation.slip_map(Q.new(1, 2), Q.new(4))
	im = _image(m, -1, 2)
	check(im[0].eq(2), "f(½x − 2) takes (−1, 2) to (2, 2): %s" % str(im))
	var s := {"kind": "lin", "a": Q.new(2), "b": Q.new(6), "p": Q.new(4), "q": Q.new(1), "x0": Q.new(-1)}
	check_eq(LinearInputViews.inside(s), "2x + 6")
	check_eq(LinearInputViews.factored(s), "2(x + 3)")
	check_eq(LinearInputViews.solving_lines(s, "")[2], "2x = −2")
	check_eq(LinearInputViews.solving_lines(s, "")[3], "x = −1, so the image is (−1, 1).")
	check_eq(LinearInputViews.solving_lines(s, LinearInputViews.R_SIGN)[2], "2x = 10")
	check_eq(LinearInputViews.solving_lines(s, LinearInputViews.R_MUL)[3], "x = −4, so the image is (−4, 1).")
	# f(3 − x): (5, 2) goes to (−2, 2).
	var r := {"kind": "refl", "a": Q.new(-1), "b": Q.new(3), "p": Q.new(5), "q": Q.new(2), "x0": Q.new(-2)}
	check_eq(LinearInputViews.inside(r), "3 − x")
	check_eq(LinearInputViews.solving_lines(r, "")[3], "x = −2, so the image is (−2, 2).")


func test_the_situation_maps_p_onto_its_image() -> void:
	for kind in ["lin", "refl"]:
		for rep in ["equation", "graph"]:
			for i in 60:
				var s := LinearInputSituation.generate(Seeded.new("li|%s|%s|%d" % [kind, rep, i]), {"kind": kind, "rep": rep})
				check(not s.is_empty(), "%s %s %d: no situation" % [kind, rep, i])
				if s.is_empty():
					continue
				var a: Q = s.a
				var b: Q = s.b
				var x0: Q = s.x0
				check(a.mul(x0).add(b).eq(s.p), "%s: a·x0 + b is p" % kind)
				check(x0.is_int() and not x0.is_zero(), "%s: the image is whole and off the y-axis" % kind)
				check(not x0.eq(s.p) or kind == "lin", "f(b − x): P is not its own image")
				if kind == "refl":
					check(a.eq(-1), "f(b − x) has a = −1")


static func _image(m: Dictionary, x: Variant, y: Variant) -> Array:
	return TC.image(m, x, y)
