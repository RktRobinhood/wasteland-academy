extends "res://tests/test_case.gd"
## The two standard-form extension types on the standard-form situation (FAL-780):
## t1-ext-standard-form-add and t1-ext-standard-form-powers are built with every cell, each sum,
## difference, power and root is exact and in standard form, a carry or a drop happens only where
## its unknown asks for one, the exam type's cells are untouched, and every tag shows up. The SymPy
## checker (tools/check-answers) works every answer out again from the numbers shown.

const TYPES := {"t1-ext-standard-form-add": 15, "t1-ext-standard-form-powers": 11}
const S := preload("res://engine/situations/standard_form.gd")


func _make(t: String, c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": t, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_types_are_built_with_every_cell() -> void:
	for t in TYPES:
		check(t in QuestionEngine.built_types(), "%s is not built" % t)
		check_eq(QuestionEngine.cells(false, [t]).size(), TYPES[t])
		for c in QuestionEngine.cells(false, [t]):
			for f in ["mcq", "value"] + QuestionEngine.extra_formats(t, c.unknown, c.angle):
				for seed in [1, 2, 3]:
					var q := _make(t, c, seed, f)
					check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])


## Exact checks without big numbers: a coefficient and a power, never 10^17 as an int.
func _ten(k: int) -> Q:
	return Q.new(int(pow(10.0, k))) if k >= 0 else Q.new(1, int(pow(10.0, -k)))


func test_sums_and_differences_are_exact() -> void:
	for u in StandardFormViews.ADD:
		for i in 40:
			var s := S.generate(Seeded.new("%s|%d" % [u, i]), {"ask": u, "paper": 1 + i % 2})
			check(not s.is_empty(), "%s draw %d failed" % [u, i])
			var minus: bool = u.begins_with("subtract") or u == "difference-context"
			# Both numbers at the larger power: c = a ± b/10^gap there, and r × 10^k is c × 10^big.
			var a_big: Q = s.a.mul(_ten(s.m - s.big))
			var b_big: Q = s.b.mul(_ten(s.n - s.big))
			var c: Q = a_big.sub(b_big) if minus else a_big.add(b_big)
			check(c.eq(s.c), "%s: %s" % [u, s])
			check(s.r.mul(_ten(s.k - s.big)).eq(c), "%s: %s × 10^%d is not %s × 10^%d" % [u, s.r.text(), s.k, c.text(), s.big])
			check(not s.r.lt(Q.new(1)) and s.r.lt(Q.new(10)), "%s: r = %s" % [u, s.r.text()])
			check(absi(s.m - s.n) in [1, 2], "%s: powers %d and %d" % [u, s.m, s.n])
			check_eq(not s.c.lt(Q.new(10)), u == "add-carry")
			check_eq(s.c.lt(Q.new(1)), u == "subtract-renormalise")


func test_powers_and_roots_are_exact() -> void:
	for u in StandardFormViews.POWERS:
		for i in 40:
			var s := S.generate(Seeded.new("%s|%d" % [u, i]), {"ask": u})
			check(not s.is_empty(), "%s draw %d failed" % [u, i])
			match u:
				"square-form", "cube-form":
					var v: Q = s.a.mul(s.a) if s.pw == 2 else s.a.mul(s.a).mul(s.a)
					check(s.r.mul(_ten(s.k - s.pw * s.m)).eq(v), "%s: %s" % [u, s])
				_:
					var deg := 3 if u == "cube-root" else 2
					var power: Q = s.c.mul(s.c) if deg == 2 else s.c.mul(s.c).mul(s.c)
					check(power.eq(s.a.mul(_ten(s.sh))) and s.m == deg * s.j + s.sh, "%s: %s" % [u, s])
					check(s.r.eq(s.c) and s.k == s.j, "%s: the answer is not c × 10^j" % u)
					if deg == 2:
						check_eq(s.sh, 1 if u == "root-odd" else 0)


func test_the_exam_type_keeps_its_cells() -> void:
	for c in QuestionEngine.cells(false, ["t1-standard-form"]):
		check(not c.unknown in StandardFormViews.ADD + StandardFormViews.POWERS, c.key)
		check(QuestionEngine.extra_formats("t1-standard-form", c.unknown, c.angle).is_empty(), c.key)


func test_every_tag_shows_up_as_an_option() -> void:
	for t in TYPES:
		var seen := {}
		for c in QuestionEngine.cells(false, [t]):
			for seed in range(1, 25):
				for o in _make(t, c, seed).choices:
					if o.ref != "":
						seen[o.ref] = true
				for f in QuestionEngine.extra_formats(t, c.unknown, c.angle):
					var q := _make(t, c, seed, f)
					if q.has("spot"):
						seen[q.spot.ref] = true
		var ms: Array = QuestionEngine.type_of(t).misconceptions
		for i in ms.size():
			var ref: String = ms[i].get("ref", "%s#%d" % [t, i])
			check(seen.has(ref), "%s never shows" % ref)
