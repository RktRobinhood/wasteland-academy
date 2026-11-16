extends "res://tests/test_case.gd"
## t3-ext-two-observations on the bearings-elevation situation (FAL-779): built with every cell, each
## question shows its side view to scale, the height from the sine rule agrees with the two tan
## equations, an exact height is Paper 1, the exam type's cells are untouched, and every tag shows
## up. The SymPy checker (tools/check-answers) works every answer out again from the words.

const TYPE := "t3-ext-two-observations"
const CELLS := 14
const S := preload("res://engine/situations/bearings_elevation.gd")


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
					check(q.graph != null and q.graph.kind == "sketch", "%s has no side view" % c.key)
					check_eq(q.situation_id, "bearings-elevation", c.key)
					check_eq(q.paper, 1 if c.unknown == "height-exact" else 2, c.key)


## The two routes give one height: h = BT sin β, and h = x tan β with x tan β = (x ± d) tan α.
func test_the_two_methods_agree() -> void:
	for u in S.TWO_OBS:
		for i in 60:
			var s := S.generate(Seeded.new("%s|%d" % [u, i]), {"ask": u})
			check(not s.is_empty(), "%s draw %d failed" % [u, i])
			if s.is_empty():
				continue
			var either: bool = u == "height-either-side"
			var t: Dictionary = BearingsViews.either_sides(s) if either else BearingsViews.two_sides(s)
			var al := deg_to_rad(float(s.al))
			var be := deg_to_rad(float(s.be))
			var d: float = s.d.to_float()
			var x := d * tan(al) / ((tan(al) + tan(be)) if either else (tan(be) - tan(al)))
			check(absf(x * tan(be) - t.h) < 1e-9 * t.h, "%s: the routes disagree" % u)
			check(absf(t.BF - x) < 1e-9 * x, "%s: BF" % u)
			if not either:
				check(s.be > s.al and s.be <= 75, "%s: β = %d" % [u, s.be])


func test_the_exam_type_keeps_its_cells() -> void:
	for c in QuestionEngine.cells(false, ["t3-bearings-elevation"]):
		check(not c.unknown in S.TWO_OBS, c.key)
		check(QuestionEngine.extra_formats("t3-bearings-elevation", c.unknown, c.angle).is_empty(), c.key)


func test_every_tag_shows_up_as_an_option() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 15):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never shows" % ref)
