extends "res://tests/test_case.gd"
## The normal-properties situation (FAL-740): t4-normal-properties is built with every cell and
## all three skills, every cell makes four options with one right, the papers follow the method
## (no GDC on Paper 1), the figures show their numbers, pick-the-graph cards are drawn to the numbers
## and every distractor shows up. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t4-normal-properties"
const CELLS := 127
const P2_ONLY := ["beyond-sd", "tail-from-band", "central-k", "central-endpoints", "central-k-sd"]
const PICK := ["pick-two-curves", "pick-shaded"]
## A tag that needs a case too rare for 8 seeds is not listed: the sweep runs 60.
const SEEDS := 60


func _make(c: Dictionary, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var view := {"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var skills := {}
	for u in QuestionEngine.type_of(TYPE).unknowns:
		for s in u.skills:
			skills[s] = true
	check_eq(skills.size(), 3, "all three listed skills have a question")


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "normal-properties", c.key)
				check_eq(q.choices.size(), 4, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				var texts := {}
				for o in q.choices:
					texts[o.text] = true
				check_eq(texts.size(), 4, c.key + ": two options read the same")
				check(q.solutions[0].angle == c.angle, c.key)


func test_the_paper_follows_the_method() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var want: Array = [2] if c.unknown in P2_ONLY else [1, 2]
		check_eq(QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle), want, c.key)


func test_paper_1_has_no_calculator_work() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.unknown in P2_ONLY:
			continue
		var q := _make(c, 5, "mcq", 1)
		check_eq(q.paper, 1, c.key)
		for sol in q.solutions:
			for step in sol.steps:
				check(not ("normalcdf" in String(step) or "invNorm" in String(step)), "%s: %s" % [c.key, step])


func test_figures_show_the_numbers() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.rep != "diagram" or c.unknown in PICK:
			continue
		for seed in range(1, 6):
			var q := _make(c, seed)
			check(q.graph != null, c.key + ": no figure")
			check_eq(q.graph.kind, "normal", c.key)
			check(not q.graph.marks.is_empty(), c.key + ": no numbers under the curve")


func test_four_curves_share_two_means_and_two_spreads() -> void:
	var c := {"unknown": "match-curve", "rep": "diagram", "angle": "parameter-effect"}
	for seed in range(1, 21):
		var q := _make(c, seed)
		var mus := {}
		var sgs := {}
		var labels := {}
		for k in q.graph.curves:
			mus[k.mu] = true
			sgs[k.sigma] = true
			labels[k.label] = true
		check_eq(mus.size(), 2)
		check_eq(sgs.size(), 2)
		check_eq(labels.size(), 4)


func test_pick_cards_are_bare_and_differ() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if not c.unknown in PICK:
			continue
		for seed in range(1, 11):
			var q := _make(c, seed)
			check_eq(q.format, "pick-the-graph", c.key)
			check_eq(q.graphs.size(), 4, c.key)
			for g in q.graphs:
				check(g.card and g.y_bare, c.key + ": a card has numbers on its height axis")
			var seen := {}
			for g in q.graphs:
				seen[str(g.curves) + str(g.get("shade", []))] = true
			check_eq(seen.size(), 4, c.key + ": two cards are the same")


func test_hand_values() -> void:
	check_eq(NormalPropertiesSituation.share(1).key(), "17/25")
	check_eq(NormalPropertiesSituation.half_share(-2).key(), "-19/40")
	# X ~ N(10, σ²) and P(X > 13) = 0.2: the middle is 0.6, the mirror tail 0.2, the half 0.3.
	var views := NormalPropertiesViews.new()
	var s0 := {"paper": 1, "ctx": 0, "rep": "equation", "mu": Q.new(10), "a": Q.new(3), "lo": Q.new(7), "hi": Q.new(13), "p": Q.new(1, 5), "up": true, "muf": 10.0, "sgf": 3.5}
	var rng := Seeded.new("hand")
	check_eq(views.build("middle-from-tail", "equation", s0, rng).answer.values.v.key(), "3/5")
	check_eq(views.build("mirror-tail", "equation", s0, rng).answer.values.v.key(), "1/5")
	check_eq(views.build("mean-to-point", "equation", s0, rng).answer.values.v.key(), "3/10")
	for seed in range(1, 21):
		var s: Dictionary = NormalPropertiesSituation.generate(Seeded.new("h|%d" % seed), {"ask": "central-k", "rep": "equation", "paper": 2})
		var back: float = NormalPropertiesSituation.phi(s.z) - NormalPropertiesSituation.phi(-s.z)
		check(absf(back - s.level.to_float()) < 1e-6, "seed %d: the central area" % seed)


func test_every_distractor_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, SEEDS):
			var q := _make(c, seed)
			for o in q.choices:
				if o.ref != "":
					seen[o.ref] = true
	var t := QuestionEngine.type_of(TYPE)
	var ms: Array = t.misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [t.id, i])
		check(seen.has(ref), "%s (%s) is never an option" % [ref, ms[i].text])
