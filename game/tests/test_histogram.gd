extends "res://tests/test_case.gd"
## The histogram situation (FAL-778): t4-ext-frequency-histogram is built with every cell, the
## histogram's bars touch, share one width and stand at the frequencies, the missing bar is marked,
## the four histogram cards differ from the data by one change each, and every tag shows up. The
## SymPy checker (tools/check-answers) reads every bar back and adds the counts up again.

const TYPE := "t4-ext-frequency-histogram"
const CELLS := 11
const V := preload("res://engine/situations/histogram_views.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	for c in QuestionEngine.cells(false, [TYPE]):
		for f in ["value", "mcq"]:
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
				if not q.has("error"):
					check_eq(q.graph != null, c.rep == "graph", c.key)


func test_the_bars_touch_at_their_frequencies() -> void:
	var s := {"w": 10, "k": 4, "f": [3, 8, 5, 2], "story": 0}
	var g := V.figure(s)
	check_eq(g.shade, [[[0.0, 0.0, 3.0], [10.0, 0.0, 3.0]], [[10.0, 0.0, 8.0], [20.0, 0.0, 8.0]],
		[[20.0, 0.0, 5.0], [30.0, 0.0, 5.0]], [[30.0, 0.0, 2.0], [40.0, 0.0, 2.0]]])
	check_eq(g.x_ticks.map(func(t): return t[1]), ["0", "10", "20", "30", "40"])
	check(g.y1 > 8)
	var hidden := V.figure(s, [], 1)
	check_eq(hidden.shade.size(), 3)
	check_eq(hidden.points.filter(func(p): return p.label == "?").size(), 1)


func test_each_card_changes_one_thing() -> void:
	for seed in range(1, 20):
		var q := QuestionEngine.make({"type": TYPE, "unknown": "pick-histogram", "rep": "table", "angle": "read-bars", "seed": seed})
		check_eq(q.format, "pick-the-graph")
		var mistakes: Array = q.choices.filter(func(o): return not o.correct).map(func(o): return o.mistake)
		mistakes.sort()
		check_eq(mistakes, ["gaps", "height", "swap"])


func test_every_tag_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 15):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		check(seen.has(ms[i].get("ref", "%s#%d" % [TYPE, i])), "%s never shows" % ms[i].get("ref", i))
