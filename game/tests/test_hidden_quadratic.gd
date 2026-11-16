extends "res://tests/test_case.gd"
## t1-ext-hidden-quadratic on the solve-exponential situation (FAL-779): built with every cell, each
## equation is a quadratic in u = b^x whose roots give the answer (a root u that is 0 or negative
## gives no x), the exam type's and t1-ext-common-base's cells are untouched, and every tag shows up.
## The SymPy checker (tools/check-answers) solves every equation again from its line.

const TYPE := "t1-ext-hidden-quadratic"
const CELLS := 18
const S := preload("res://engine/situations/solve_exponential.gd")


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
					check_eq(q.graph != null, c.rep == "graph", c.key)
					check_eq(q.situation_id, "solve-exponential", c.key)
					if c.angle == "graph-zeros":
						check_eq(q.paper, 2, c.key)


## a u² + B u + C has the drawn roots, and b^x = u holds at every whole x answer.
func test_the_roots_solve_the_quadratic_in_u() -> void:
	for u in S.HIDDEN:
		for i in 60:
			var s := S.generate(Seeded.new("%s|%d" % [u, i]), {"ask": u})
			check(not s.is_empty(), "%s draw %d failed" % [u, i])
			if s.is_empty():
				continue
			for r in s.u:
				var v: Q = r
				check(v.mul(v).mul(s.a).add(v.mul(s.B)).add(s.C).is_zero(), "%s: u = %s is no root" % [u, v.text()])
			check(not S.map_hidden(s), "%s: the skill map's example" % u)
			if u in ["two-powers", "reject-negative", "zero-root"]:
				for x in s.x:
					check(s.u.any(func(r): return r.eq(SolveExponentialViews.hq_value(s, x))), "%s: x = %s gives no root" % [u, x.text()])
			if u == "solution-count":
				var pos := {}
				for r in s.u:
					if r.sign() > 0:
						pos[r.key()] = true
				check_eq(pos.size(), s.n, "%s count" % u)


func test_the_other_types_keep_their_cells() -> void:
	for t in ["t1-solve-exponential", "t1-ext-common-base"]:
		for c in QuestionEngine.cells(false, [t]):
			check(not c.unknown in S.HIDDEN, c.key)
	check_eq(QuestionEngine.cells(false, ["t1-ext-common-base"]).size(), 12)
	for c in QuestionEngine.cells(false, ["t1-solve-exponential"]):
		check(QuestionEngine.extra_formats("t1-solve-exponential", c.unknown, c.angle).is_empty(), c.key)


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
