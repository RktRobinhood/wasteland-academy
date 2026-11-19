extends "res://tests/test_case.gd"
## The inverse-restricted situation (FAL-1007): fn-ahl-inverse-restricted is built with every cell
## and all three AHL2.14 inverse skills, only for AA HL; a calculator method is Paper 2 and the rest
## can be either paper; every cell makes four distinct options with one right and says its answer
## in each working's last step; graphs are shown; every tagged slip shows up; a typed value is
## marked by its value; inverses, self-inverse checks and meeting points against values worked by
## hand. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "fn-ahl-inverse-restricted"
const CELLS := 30
const SKILLS := ["AHL2.14.restrict-domain-inverse", "AHL2.14.self-inverse", "AHL2.14.inverse-intersection"]
const S := preload("res://engine/situations/inverse_restricted.gd")
const V := preload("res://engine/situations/inverse_restricted_views.gd")


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


func test_only_aa_hl_gets_it() -> void:
	for course in ["aa-sl", "ai-sl", "ai-hl"]:
		check(QuestionEngine.cells(false, [TYPE], course).is_empty(), "%s offers %s" % [course, TYPE])
	check_eq(QuestionEngine.cells(false, [TYPE], "aa-hl").size(), CELLS, "%s on aa-hl" % TYPE)


func test_every_cell_makes_a_question_with_one_right_option() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var gdc: bool = c.angle.begins_with("gdc-")
		check_eq(QuestionEngine.cell_papers(QuestionEngine.type_of(TYPE), c.unknown, c.rep, c.angle), [2] if gdc else [1, 2], c.key)
		for f in ["value", "mcq"]:
			for seed in range(1, 7):
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s: %s" % [c.key, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, "inverse-restricted", c.key)
				if gdc:
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
					if q.paper == 1:
						check(not sol.angle.begins_with("gdc-"), c.key + ": a calculator working on Paper 1")
				if c.rep == "graph":
					check(q.graph != null, c.key + " shows no graph")


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
	for c in [{"unknown": "largest-domain", "rep": "equation", "angle": "complete-square-invert"},
			{"unknown": "self-inverse-constant", "rep": "equation", "angle": "compose-with-itself"}]:
		for seed in range(1, 6):
			var q := _make(c, seed, "value")
			var v: Q = q.answer.values.v
			check(QuestionEngine.mark(q, {"v": Fmt.num(v)}).correct, q.answer_text)
			check(not QuestionEngine.mark(q, {"v": Fmt.num(v.neg())}).correct, "the sign changed")


func test_inverses_by_hand() -> void:
	# 2(x − 3)² + 1 on x ≥ 3: x = 2(y − 3)² + 1, so f⁻¹(x) = 3 + √((x − 1)/2).
	check_eq(S.inv_text(2, 3, 1, "+"), "3 + √((x − 1)/2)")
	# −(x + 2)² + 4 on x ≤ −2: f⁻¹(x) = −2 − √(4 − x).
	check_eq(S.inv_text(-1, -2, 4, "−"), "−2 − √(4 − x)")
	check_eq(S.inv_text(1, 0, 0, "±"), "±√x")
	check_eq(S.branch({"side": "≤"}), "−")
	check_eq(S.trig_rule({"fn": "cos", "A": 2, "D": 1, "p": Q.new(1, 4)}), "2cos(x − π/4) + 1")
	check_eq(S.half_rule({"form": "general", "A": 1, "b": -6, "c": 4, "h": 3, "k": -5}), "x² − 6x + 4")


func test_self_inverse_by_hand() -> void:
	# (3x + 1)/(x − 3) is its own inverse: f(2) = −7 and f(−7) = 2.
	var s := {"form": "rat", "a": 3, "b": 1, "d": -3}
	check_eq(S.selfq_at(s, Q.new(2)).text(), "−7")
	check_eq(S.selfq_at(s, Q.new(-7)).text(), "2")
	check(S.selfq_at(s, Q.new(3)) == null, "f(3) is not defined")
	# 2x is odd but not its own inverse: f(f(1)) = 4.
	check_eq(S.selfq_at({"form": "odd", "m": 2}, S.selfq_at({"form": "odd", "m": 2}, Q.new(1))).text(), "4")
	check_eq(S.selfq_rule({"form": "root", "r": 3}), "f(x) = √(9 − x²), 0 ≤ x ≤ 3")
	check_eq(S.rat_text("k", 2, -4), "(kx + 2)/(x − 4)")


func test_meeting_points_by_hand() -> void:
	# (x² + 6)/5 = x gives (2, 2) and (3, 3); f(x) = 1 has no root on x ≥ 0, as x² = −1.
	var up := {"form": "quad", "n": 1, "m": 5, "c": 6, "exact": true, "xs": [Q.new(2), Q.new(3)]}
	check_eq(S.meetup_rule(up), "f(x) = (x² + 6)/5, x ≥ 0")
	check_eq(V._where_one(up), "The graphs do not meet: f(x) = ±1 has no solution.")
	# √(5x − 6) = 1 at x = 7/5.
	up.form = "root"
	check_eq(S.meetup_rule(up), "f(x) = √(5x − 6), x ≥ 6/5")
	check_eq(V._where_one(up), "(7/5, 1)")
	# −(1/4)x³ meets its inverse at (−2, 2), (0, 0) and (2, −2), since (1/4)x² = 1 at x = ±2.
	var down := {"A": Q.new(1, 4), "pw": 3, "exact": true, "s": Q.new(2)}
	check_eq(S.meetdown_rule(down), "f(x) = −(1/4)x³")
	check_eq(S.meetdown_inverse(down), "−(4x)^(1/3)")
	check_eq(V.pts([V.pt(Q.new(-2), Q.new(2)), V.pt(Q.new(0), Q.new(0)), V.pt(Q.new(2), Q.new(-2))]), "(−2, 2), (0, 0) and (2, −2)")
