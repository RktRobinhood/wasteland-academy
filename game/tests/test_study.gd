extends "res://tests/test_case.gd"
## The study situation (FAL-778): t4-ext-population-sample is built with every cell, the sample is
## under a quarter of the population, only a numbered draw from everyone is called random, and every
## tag shows up. The SymPy checker (tools/check-answers) reads the study again and writes each answer.

const TYPE := "t4-ext-population-sample"
const CELLS := 4


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	for c in QuestionEngine.cells(false, [TYPE]):
		for f in ["mcq"] + QuestionEngine.extra_formats(TYPE, c.unknown, c.angle):
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])


func test_the_sample_is_small_and_random_only_from_a_full_draw() -> void:
	for u in ["is-random", "make-random", "name-sample"]:
		for i in 60:
			for paper in [1, 2]:
				var s := StudySituation.generate(Seeded.new("%s|%d" % [u, i]), {"ask": u, "paper": paper})
				check(4 * s.n < s.N and s.n >= 10, "%s draw %d: %d of %d" % [u, i, s.n, s.N])
				check(u != "make-random" or s.how != "draw", "make-random on a random sample")
	for seed in range(1, 30):
		var q := QuestionEngine.make({"type": TYPE, "unknown": "is-random", "rep": "words", "angle": "definition-check", "seed": seed})
		check_eq(q.answer_text.begins_with("Yes"), q.situation.how == "draw", "seed %d" % seed)


func test_every_tag_shows_up_as_an_option() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 15):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		check(seen.has(ms[i].get("ref", "%s#%d" % [TYPE, i])), "%s never shows" % ms[i].get("ref", i))
