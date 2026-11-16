extends "res://tests/test_case.gd"
## t1-ext-binomial-constant-term on the binomial-expansion situation (FAL-779): built with every
## cell, x is in both terms of the bracket and the r found makes the power asked, the coefficient
## is nCr a^(n − r) k^r, the middle term is asked only where the powers are symmetric, the exam
## type's cells are untouched, and every tag shows up. The SymPy checker (tools/check-answers)
## expands every bracket again from its text.

const TYPE := "t1-ext-binomial-constant-term"
const CELLS := 13
const S := preload("res://engine/situations/binomial_expansion.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	for c in QuestionEngine.cells(false, [TYPE]):
		for f in ["mcq", "value"] + QuestionEngine.extra_formats(TYPE, c.unknown, c.angle):
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
				if not q.has("error"):
					check_eq(q.situation_id, "binomial-expansion", c.key)
					check_eq(q.choices.size(), 4, c.key)
					check_eq(q.solutions[0].angle, c.angle, c.key)


## The r of the term asked gives its power, and both terms of the bracket carry x.
func test_the_r_found_gives_the_power_asked() -> void:
	for u in S.CONSTANT:
		for i in 80:
			var s := S.generate(Seeded.new("%s|%d" % [u, i]), {"ask": u})
			check(not s.is_empty(), "%s draw %d failed" % [u, i])
			if s.is_empty():
				continue
			check(s.p >= 1 and s.q >= 1 and absi(s.b) >= 2, "%s: x in both terms, k raised" % u)
			check(not [s.a, s.p, s.b, s.q, s.n, s.m] in S.CT_MAP, "%s: the skill map's example" % u)
			if u == "ct-power-of-x":
				continue
			check_eq(S.ct_power(s, s.r), s.m, u)
			check(s.r >= 1 and s.r <= s.n - 1, "%s: r = %d" % [u, s.r])
			check_eq(s.p == s.q, u == "ct-middle-constant", u + ": symmetric powers only for the middle term")
			check_eq(s.m == 0, u != "ct-given-power", u)
			var c := S.ncr(s.n, s.r) * S.power(s.a, s.n - s.r) * S.power(s.b, s.r)
			check_eq(S.ct_coef(s, s.r), c, u)
			# r alone is asked of ct-find-r, so its coefficient may be any size.
			check(absi(c) <= S.HAND or s.paper == 2 or u == "ct-find-r", u)


func test_the_numbers_match_hand_values() -> void:
	# (x² + 3/x)⁶: the constant term is 6C4 × 3⁴ = 1215.
	var s := {"n": 6, "a": 1, "p": 2, "b": 3, "q": 1}
	check_eq(S.ct_power(s, 4), 0)
	check_eq(S.ct_coef(s, 4), 1215)
	# (2x − 1/x²)⁶: x³ at r = 1, coefficient 6 × 32 × (−1).
	s = {"n": 6, "a": 2, "p": 1, "b": -1, "q": 2}
	check_eq(S.ct_power(s, 1), 3)
	check_eq(S.ct_coef(s, 1), -192)


func test_the_exam_type_keeps_its_cells() -> void:
	for c in QuestionEngine.cells(false, ["t1-binomial-term"]):
		check(not c.unknown in S.CONSTANT and not c.unknown in S.PRODUCT, c.key)
		check(QuestionEngine.extra_formats("t1-binomial-term", c.unknown, c.angle).is_empty(), c.key)


func test_every_tag_shows_up_as_an_option() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 25):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
			for f in QuestionEngine.extra_formats(TYPE, c.unknown, c.angle):
				var q := _make(c, seed, f)
				if q.has("spot"):
					seen[q.spot.ref] = true
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never shows" % ref)
