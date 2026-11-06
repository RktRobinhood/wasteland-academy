extends "res://tests/test_case.gd"
## The distance-midpoint situation (FAL-751): t3-distance-midpoint is built with every cell and both
## skills, every cell makes four options with one right on both of its papers, Paper 1 is exact and
## Paper 2 is to 3 s.f., points and k come back right from hand values, figures hold the question's
## points, 2D has no Pythagoras twice, and every misconception shows up. The SymPy checker
## (tools/check-answers) checks the maths.

const TYPE := "t3-distance-midpoint"
const CELLS := 64
const SKILLS := 2
const UNKNOWNS := 15
const PAPER_1_ONLY := ["show-isosceles", "origin-to-curve"]
const FIGURED := ["distance-two-points", "distance-2d", "show-isosceles", "space-diagonal", "pyramid-edge", "radius-from-centre",
	"radius-from-diameter", "midpoint-3d", "midpoint-2d", "missing-endpoint", "missing-endpoint-2d", "centre-from-diameter"]


func _make(c: Dictionary, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var view := {"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	check_eq(t.unknowns.size(), UNKNOWNS)
	var skills := {}
	for u in t.unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), SKILLS, "both skills have a question")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3, 4]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "distance-midpoint", c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check(q.solutions[0].angle == c.angle, c.key + ": the asked method comes first")


func test_the_papers() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var want := [1] if c.unknown in PAPER_1_ONLY else [1, 2]
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), want, c.key)


func test_paper_1_is_exact_and_paper_2_is_rounded() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.unknown in PAPER_1_ONLY:
			continue
		var one := _make(c, 5, "mcq", 1)
		var two := _make(c, 5, "mcq", 2)
		check_eq(one.paper, 1, c.key)
		check_eq(two.paper, 2, c.key)
		check(one.answer.get("exact", false), c.key + ": Paper 1 is exact")
		if c.unknown in ["distance-two-points", "distance-2d", "space-diagonal", "pyramid-edge", "radius-from-centre", "radius-from-diameter", "find-k-surd"]:
			check_eq(two.answer.get("show", ""), "sf", c.key + ": Paper 2 is to 3 s.f.")
			check(two.asked.contains("3 significant figures"), c.key)
			check(one.asked.contains("exact form") or c.unknown == "find-k-two-values", c.key)


func test_lengths_midpoints_and_surds_by_hand() -> void:
	var dm := DistanceMidpointSituation
	check_eq(dm.root_of(49), 7)
	check_eq(dm.root_of(50), -1)
	check_eq(dm.surd(72), [6, 2])
	check_eq(dm.surd(61), [1, 61])
	check_eq(dm.surd(49), [7, 1])
	var a := dm.ints([1, 2, 3])
	var b := dm.ints([4, 6, 15])
	check_eq(dm.norm(dm.minus(b, a)), 169)
	var m := dm.midpoint(a, b)
	check(m[0].eq(Q.new(5, 2)) and m[1].eq(4) and m[2].eq(9), "the midpoint of whole points")


func test_the_midpoint_and_endpoint_sit_on_the_segment() -> void:
	for ask in ["midpoint-3d", "midpoint-2d", "missing-endpoint", "missing-endpoint-2d", "centre-from-diameter"]:
		for seed in range(1, 21):
			for paper in [1, 2]:
				var s := DistanceMidpointSituation.generate(Seeded.new("%s|%d" % [ask, seed]), {"ask": ask, "paper": paper})
				check(not s.is_empty(), ask)
				for i in s.A.size():
					check(s.A[i].add(s.B[i]).eq(s.M[i].mul(2)), "%s seed %d: M is not halfway" % [ask, seed])


func test_a_length_on_paper_2_needs_rounding() -> void:
	for ask in ["distance-two-points", "distance-2d", "space-diagonal", "pyramid-edge", "radius-from-centre"]:
		for seed in range(1, 41):
			var s := DistanceMidpointSituation.generate(Seeded.new("%s|%d" % [ask, seed]), {"ask": ask, "paper": 2, "rep": "equation"})
			check(DistanceMidpointSituation.root_of(s.sq) < 0, "%s seed %d: a whole length on Paper 2" % [ask, seed])


func test_k_has_two_values_and_both_work() -> void:
	for ask in ["find-k-two-values", "find-k-surd"]:
		for seed in range(1, 31):
			var s := DistanceMidpointSituation.generate(Seeded.new("%s|%d" % [ask, seed]), {"ask": ask, "paper": 1})
			var rest := 0
			for i in 3:
				if i != s.axis:
					rest += s.B[i].sub(s.A[i]).sq().n
			check_eq(rest + s.t, s.top, "%s seed %d" % [ask, seed])
			check(s.t > 0, "two different values")
			check_eq(DistanceMidpointSituation.root_of(s.t) > 0, ask == "find-k-two-values", "%s seed %d" % [ask, seed])


func test_a_triangle_is_isosceles_but_not_equilateral() -> void:
	var dm := DistanceMidpointSituation
	for seed in range(1, 41):
		var s := dm.generate(Seeded.new("tri|%d" % seed), {"ask": "show-isosceles", "paper": 1})
		var sides: Array = [dm.norm(dm.minus(s.A, s.B)), dm.norm(dm.minus(s.A, s.C)), dm.norm(dm.minus(s.B, s.C))]
		var uniq := {}
		for n in sides:
			uniq[n] = true
		check_eq(uniq.size(), 2, "seed %d: %s" % [seed, sides])
		check_eq(sides.count(s.sq), 2, "seed %d" % seed)


func test_a_diagram_has_its_figure_and_nothing_else_does() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var q := _make(c, 2)
		if c.rep == "diagram":
			check(c.unknown in FIGURED, c.key)
			check(q.graph != null and q.graph.kind == "space", c.key + ": no figure")
			for n in q.graph.labels:
				check(q.graph.pts.has(n), c.key + ": a label for no point")
			for ln in q.graph.lines:
				check(q.graph.pts.has(ln.a) and q.graph.pts.has(ln.b), c.key + ": a line to no point")
		else:
			check(q.graph == null, c.key + ": a figure with no diagram")


func test_2d_is_flat_and_has_one_length_method() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.unknown == "distance-2d":
			check_eq(c.angle, "distance-formula-2d", c.key)
		check(not (c.angle == "pythagoras-twice" and c.unknown.ends_with("2d")), c.key)


func test_every_misconception_shows_up() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 13):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	for i in t.misconceptions.size():
		var ref: String = t.misconceptions[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never shows up: %s" % [ref, t.misconceptions[i].text])


func test_a_typed_answer_is_marked() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var q := _make(c, 3, "value", 1 if c.unknown in PAPER_1_ONLY else 2)
		var r := {}
		for item in Answer.slots(q.answer):
			if item.has("slot"):
				r[item.slot] = Fmt.dec(q.answer.values[item.slot]).replace("−", "-")
			else:
				r[item.pick] = q.answer.values[item.pick]
		check(QuestionEngine.mark(q, r).correct, "%s: the right answer isn't marked right: %s" % [c.key, q.answer_text])
