extends "res://tests/test_case.gd"
## The hence-integral situation (FAL-776): t5-ext-hence-integral is built with every cell on Paper 1.
## Each family's derivative result and integral are as worked by hand, every tag shows up, the
## right option ends in + C where the integral is indefinite, and error-spot and method-pick keep
## their rules. The SymPy checker (tools/check-answers) differentiates and integrates every option.

const TYPE := "t5-ext-hence-integral"
const CELLS := 7
const V := preload("res://engine/situations/hence_integral_views.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell_on_paper_1() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	for c in QuestionEngine.cells(false, [TYPE]):
		for f in ["mcq"] + QuestionEngine.extra_formats(TYPE, c.unknown, c.angle):
			for seed in [1, 2, 3, 4]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.paper, 1, c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)


func test_the_families_match_hand_working() -> void:
	# x e^(2x): F′ = e^(2x) + 2x e^(2x), so ∫ x e^(2x) dx = ½x e^(2x) − (1/4)e^(2x) + C.
	var p := V.product("xekx", 2)
	check_eq(V.SUM(p.uv + p.udv), "e^(2x) + 2x e^(2x)")
	check_eq(V.SUM(V.scaled(p.tt_int, Q.new(1, 2))), "½x e^(2x) − (1/4)e^(2x)")
	# x cos x: F′ = cos x − x sin x, so ∫ x sin x dx = sin x − x cos x + C.
	p = V.product("xcos", 1)
	check_eq(V.SUM(p.uv + p.udv), "cos x − x sin x")
	check_eq(V.SUM(p.tt_int), "sin x − x cos x")
	# (x² + 3)⁴: F′ = 8x(x² + 3)³.
	var c := V.composite({"fam": "pow", "c": 3, "n": 4, "p": 1})
	check_eq(V.T(c.factor, c.core), "8x(x² + 3)³")


func test_an_indefinite_answer_has_its_constant() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if not c.unknown in ["adjust-factor", "move-extra-term"]:
			continue
		for seed in range(1, 10):
			check(_make(c, seed).answer_text.ends_with(" + C"), c.key)


func test_every_tag_shows_up_as_an_option() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 12):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		if ms[i].as == "distractor":
			check(seen.has(ms[i].get("ref", "%s#%d" % [TYPE, i])), "%s never shows" % ms[i].get("ref", ms[i].text))


func test_error_spot_shows_the_slip_line() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if not "error-spot" in QuestionEngine.extra_formats(TYPE, c.unknown, c.angle):
			continue
		for seed in range(1, 8):
			var q := _make(c, seed, "error-spot")
			check_eq(q.spot.lines.size(), 4, c.key)
			check(q.choices[q.spot.bad].correct, c.key)
