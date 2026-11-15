extends "res://tests/test_case.gd"
## The correlation situation (FAL-778): t4-ext-describe-correlation is built with every cell, each
## point set's r is in its band (shown to 2 d.p. inside it too), a curve's points fit a parabola
## while r stays near 0, the scatter cards each differ from the data, and every tag shows up. The
## SymPy checker (tools/check-answers) works r out again from every plotted point.

const TYPE := "t4-ext-describe-correlation"
const CELLS := 9
const S := preload("res://engine/situations/correlation.gd")


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
				if not q.has("error") and f == "mcq":
					check_eq(q.graph != null, c.rep == "graph", c.key)


func test_points_are_in_their_band() -> void:
	for band in S.BANDS:
		for dir in ([0] if band in ["none", "curve"] else [1, -1]):
			for i in 10:
				var p := S.points(Seeded.new("%s|%d|%d" % [band, dir, i]), band, dir)
				var r := S.pearson(p[0], p[1])
				var lim: Array = S.BANDS[band]
				check(absf(r) >= lim[0] and absf(r) <= lim[1] and absf(snappedf(r, 0.01)) <= lim[1], "%s %d: r = %f" % [band, dir, r])
				check(dir == 0 or signf(r) == dir, "%s %d: r = %f" % [band, dir, r])
				if band == "curve":
					check(S.fit_curve(p[0], p[1]) >= 0.85, "a curve that doesn't fit a parabola")


func test_pearson_by_hand() -> void:
	check(absf(S.pearson([1, 2, 3], [2, 4, 6]) - 1.0) < 1e-12)
	check(absf(S.pearson([1, 2, 3, 4], [1, 3, 2, 4]) - 0.8) < 1e-12)


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
