extends "res://tests/test_case.gd"
## t1-ext-sigma-arithmetic on the arithmetic-sequence situation (FAL-779): built with every cell,
## each Σ (r = a to b) (pr + q) is the arithmetic sequence it says (u₁ = pa + q, d = p, b − a + 1
## terms), an upper limit found from the total solves its quadratic with a negative whole second
## root, the skill map's examples are left out, the exam type's cells are untouched, and every tag
## shows up. The SymPy checker (tools/check-answers) sums every Σ again from its line.

const TYPE := "t1-ext-sigma-arithmetic"
const CELLS := 13
const S := preload("res://engine/situations/arithmetic_sequence.gd")
const KINDS := ["count", "one", "shifted", "write", "upper"]


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
					check_eq(q.situation_id, "arithmetic-sequence", c.key)
					check_eq(q.paper, 2 if c.angle == "gdc-sigma" else 1, c.key)


## The sum is Σ (pr + q) term by term, and the second root of an upper limit is negative and whole.
func test_each_sigma_is_its_sequence() -> void:
	for kind in KINDS:
		for i in 60:
			var s := S.generate(Seeded.new("%s|%d" % [kind, i]), {"n": "sum", "sigma": kind})
			check(not s.is_empty(), "%s draw %d failed" % [kind, i])
			if s.is_empty():
				continue
			var total := Q.new(0)
			for r in range(s.lower.n, s.upper.n + 1):
				total = total.add(s.p.mul(r).add(s.q))
			check(total.eq(s.sn), "%s: Σ = %s, not %s" % [kind, total.text(), s.sn.text()])
			check(s.u1.eq(s.p.mul(s.lower).add(s.q)) and s.d.eq(s.p) and s.n.eq(s.upper.sub(s.lower).add(1)), kind)
			check(not s.q.is_zero(), kind + ": q is 0")
			if kind == "upper":
				var o: Q = s.other
				check(o.is_int() and o.sign() < 0, "the other root %s" % o.text())
				# p k² + (p + 2q) k − 2T vanishes at both roots.
				for root in [s.upper, o]:
					check(s.p.mul(root.sq()).add(s.p.add(s.q.mul(2)).mul(root)).sub(s.sn.mul(2)).is_zero(), "root %s" % root.text())


func test_the_skill_map_examples_are_left_out() -> void:
	for i in 300:
		var one := S.generate(Seeded.new("one|%d" % i), {"n": "sum", "sigma": "one"})
		check(not (one.p.eq(3) and one.q.eq(2) and one.upper.eq(20)), "Σ(3r + 2) to 20 is the map's example")
		var count := S.generate(Seeded.new("count|%d" % i), {"n": "sum", "sigma": "count"})
		check(not (count.lower.eq(5) and count.upper.eq(30)), "r = 5 to 30 is the map's example")


func test_the_exam_type_keeps_its_cells() -> void:
	for c in QuestionEngine.cells(false, ["t1-arithmetic-sequence"]):
		check(not c.unknown in ["count-terms", "evaluate-sigma", "evaluate-shifted", "write-sigma", "upper-from-total"], c.key)
		check(QuestionEngine.extra_formats("t1-arithmetic-sequence", c.unknown, c.angle).is_empty(), c.key)


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
