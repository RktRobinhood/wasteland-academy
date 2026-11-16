extends "res://tests/test_case.gd"
## t1-ext-common-base on the solve-exponential situation (FAL-780): built with every cell, both
## sides of each equation are powers of one prime with the answer solving it exactly, a graph
## crosses at a whole x, the exam type's cells are untouched, and every tag shows up. The SymPy
## checker (tools/check-answers) solves every equation again from its line.

const TYPE := "t1-ext-common-base"
const CELLS := 12
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


## A^(x + c) = B^(kx + e) holds at the answer, on the common prime: i(x + c) = j(kx + e).
func test_each_answer_solves_its_equation() -> void:
	for u in ["fraction-power", "linear-exponents", "meet-on-graph"]:
		for i in 60:
			var s := S.generate(Seeded.new("%s|%d" % [u, i]), {"ask": u})
			check(not s.is_empty(), "%s draw %d failed" % [u, i])
			if s.is_empty():
				continue
			check_eq(S.ipow(s.t, s.i), s.A)
			var x: Q = s.x
			if u == "fraction-power":
				check(x.mul(s.i).eq(s.j) and not x.is_int(), "%s: %d^x = %d, x = %s" % [u, s.A, s.R, x.text()])
			else:
				check(x.add(s.c).mul(s.i).eq(x.mul(s.k).add(s.e).mul(s.j)), "%s: x = %s" % [u, x.text()])
				if u == "meet-on-graph":
					check(x.is_int() and s.k == 1, "the crossing is not at a whole x")


func test_the_whole_powers_leave_out_the_map_example() -> void:
	for i in 200:
		var s := S.generate(Seeded.new("whole|%d" % i), {"ask": "whole-power"})
		check(not (s.b == 2 and s.N == 32), "2^x = 32 is the skill map's example")
		check(S.ipow(s.b, s.j) == s.N and s.N <= 1000 and s.N / s.b != s.j, "%d^x = %d" % [s.b, s.N])


func test_the_exam_type_keeps_its_cells() -> void:
	for c in QuestionEngine.cells(false, ["t1-solve-exponential"]):
		check(not c.unknown in S.COMMON, c.key)
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
