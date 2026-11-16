extends "res://tests/test_case.gd"
## t1-ext-real-value on the compound-interest situation (FAL-780): built with every cell, each value
## is the real-rate or deflated one the question names (and the two differ by a dollar or more), the
## keeps-pace answer follows the two rates, the exam type's cells are untouched, and every tag shows
## up. The SymPy checker (tools/check-answers) works every value out again with exact rationals.

const TYPE := "t1-ext-real-value"
const CELLS := 7
const S := preload("res://engine/situations/compound_interest.gd")


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


func test_each_method_gives_its_own_value() -> void:
	for u in ["real-value-rate", "real-value-deflate"]:
		for i in 40:
			var s := S.generate(Seeded.new("%s|%d" % [u, i]), {"ask": u})
			check(not s.is_empty() and s.f.lt(s.r), "%s draw %d" % [u, i])
			var pv: float = s.pv.to_float()
			var real := pv * pow(1.0 + (s.r.to_float() - s.f.to_float()) / 100.0, s.n)
			var defl := pv * pow(1.0 + s.r.to_float() / 100.0, s.n) / pow(1.0 + s.f.to_float() / 100.0, s.n)
			check(absf(S.real_rate_value(s) - real) < 1e-6 and absf(S.deflated(s) - defl) < 1e-6, "%s: %s" % [u, s])
			check(absf(real - defl) >= 1.0, "%s: the two values are %f and %f" % [u, real, defl])


## "9/2" or "4", as the export writes a Q.
func _q(t: Variant) -> Q:
	var parts := str(t).split("/")
	return Q.new(int(parts[0]), int(parts[1]) if parts.size() > 1 else 1)


func test_keeps_pace_follows_the_rates() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.unknown != "keeps-pace":
			continue
		for seed in range(1, 20):
			var q := _make(c, seed)
			var up: bool = _q(q.given.f).lt(_q(q.given.r))
			check_eq(q.answer_text.begins_with("Yes"), up)


func test_the_exam_type_keeps_its_cells() -> void:
	for c in QuestionEngine.cells(false, ["t1-compound-interest"]):
		check(not c.unknown in CompoundInterestViews.REAL, c.key)
		check(QuestionEngine.extra_formats("t1-compound-interest", c.unknown, c.angle).is_empty(), c.key)


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
