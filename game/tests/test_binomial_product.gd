extends "res://tests/test_case.gd"
## t1-ext-binomial-product on the binomial-expansion situation (FAL-779): built with every cell,
## the coefficient asked is the sum of two pairs of terms, neither 0, k is a whole number, the
## exam type's cells are untouched, and every tag shows up. The SymPy checker
## (tools/check-answers) multiplies every product out again from its text.

const TYPE := "t1-ext-binomial-product"
const CELLS := 12
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


## Two pairs of terms give the power asked, and the answer is their sum.
func test_the_answer_is_two_pairs_added() -> void:
	for u in S.PRODUCT:
		for i in 80:
			var s := S.generate(Seeded.new("%s|%d" % [u, i]), {"ask": u})
			check(not s.is_empty(), "%s draw %d failed" % [u, i])
			if s.is_empty():
				continue
			var p: Array = S.pr_pairs(s)
			check(p[0] != 0 and p[1] != 0 and p[0] + p[1] != 0, "%s: a pair or the answer is 0" % u)
			if u == "pr-reciprocal":
				check(s.n % 2 == 0, u)
				continue
			# Multiplied out the long way: every term of each bracket.
			var total := 0
			for i0 in 2:
				for j in s.n + 1:
					var power: int = (s.d if i0 == 1 else 0) + j
					if power == s.m:
						total += (s.fb if i0 == 1 else s.fa) * S.ncr(s.n, j) * S.power(s.ea, s.n - j) * S.power(s.eb, j)
			check_eq(S.pr_answer(s), total, u)
			check(not [s.fa, s.fb, s.d, s.ea, s.eb, s.n, s.m] in S.PR_MAP, "%s: the skill map's example" % u)
			if u == "pr-find-k":
				check_eq(s.V, total, u)
				check(s.fa == 1 and absi(s.fb) >= 2, u)
			if u == "pr-small":
				check(s.n <= 4, u)


func test_the_exam_type_keeps_its_cells() -> void:
	for c in QuestionEngine.cells(false, ["t1-binomial-term"]):
		check(not c.unknown in S.PRODUCT, c.key)


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
