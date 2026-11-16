extends "res://tests/test_case.gd"
## t1-ext-partial-vs-infinite on the geometric-sequence situation (FAL-779): built with every
## cell, all Paper 2, the least n is the first whole number past the crossing (S∞ − Sₙ below the
## gap, or Sₙ past the percentage), the share and the gap after k terms are exact, the exam types'
## cells are untouched, and every tag shows up. The SymPy checker (tools/check-answers) works every
## answer out again from the question's lines.

const TYPE := "t1-ext-partial-vs-infinite"
const CELLS := 22
const S := preload("res://engine/situations/geometric_sequence.gd")


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
					check_eq(q.paper, 2, c.key)
					check_eq(q.situation_id, "geometric-sequence", c.key)
					check_eq(q.choices.size(), 4, c.key)


## The least n meets the condition and n − 1 doesn't, worked in floats from u₁ and r.
func test_the_least_n_is_the_first_past_the_crossing() -> void:
	for u in ["least-n-gap", "least-n-percent"]:
		for i in 80:
			var s := S.generate(Seeded.new("%s|%d" % [u, i]), {"ask": u})
			check(not s.is_empty(), "%s draw %d failed" % [u, i])
			if s.is_empty():
				continue
			var r: float = s.r.to_float()
			check(r > 0.0 and r < 1.0, "r = %s" % s.r.text())
			var sinf: float = s.u1.to_float() / (1.0 - r)
			var tol: float = s.eps.to_float() if u == "least-n-gap" else (1.0 - s.pct.to_float() / 100.0) * sinf
			check(sinf * pow(r, s.n) < tol and sinf * pow(r, s.n - 1) > tol, "%s: n = %d" % [u, s.n])
			check(s.n >= 4 and s.n <= 40 and absf(s.real - roundf(s.real)) >= 0.1, "%s: crossing %f" % [u, s.real])
			check(s.u1.to_float() * pow(r, s.term_n - 1) < tol and (s.term_n == 1 or s.u1.to_float() * pow(r, s.term_n - 2) > tol), "%s: one-term slip %d" % [u, s.term_n])


func test_the_share_and_the_gap_are_exact() -> void:
	for u in ["share-of-sinf", "gap-after-n"]:
		for i in 60:
			var s := S.generate(Seeded.new("%s|%d" % [u, i]), {"ask": u})
			check(not s.is_empty(), "%s draw %d failed" % [u, i])
			if s.is_empty():
				continue
			var sinf: Q = S.to_infinity(s.u1, s.r)
			var part: Q = S.partial(s.u1, s.r, s.k)
			var want: Q = part.div(sinf).mul(100) if u == "share-of-sinf" else sinf.sub(part)
			check(want.eq(s.v), "%s: %s" % [u, s.v.text()])


func test_the_exam_types_keep_their_cells() -> void:
	for t in ["t1-geometric-sequence", "t1-sum-to-infinity"]:
		for c in QuestionEngine.cells(false, [t]):
			check(not c.unknown in S.PVI, c.key)
			check(QuestionEngine.extra_formats(t, c.unknown, c.angle).is_empty(), c.key)


func test_every_tag_shows_up_as_an_option() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 15):
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
