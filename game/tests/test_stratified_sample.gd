extends "res://tests/test_case.gd"
## The stratified-sample situation (FAL-778): t4-ext-stratified-numbers is built with every cell,
## the shares are whole or clear of a half as the unknown needs, the last group's rounded share
## overshoots or falls short, an error-spot marks its slip, and every tag shows up. The SymPy checker
## (tools/check-answers) works every number out again with exact fractions.

const TYPE := "t4-ext-stratified-numbers"
const CELLS := 15
const S := preload("res://engine/situations/stratified_sample.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	for c in QuestionEngine.cells(false, [TYPE]):
		for f in ["value", "mcq"] + QuestionEngine.extra_formats(TYPE, c.unknown, c.angle):
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])


func test_shares_are_whole_or_clear_of_a_half() -> void:
	for paper in [1, 2]:
		for i in 60:
			var w := S.generate(Seeded.new("whole|%d" % i), {"ask": "stratum-count", "paper": paper})
			for j in 3:
				check(S.share(w, j).is_int(), "draw %d group %d" % [i, j])
			var r := S.generate(Seeded.new("round|%d" % i), {"ask": "stratum-count-rounded", "paper": paper})
			check(S.from_half(S.share(r, r.g)) >= 0.1 and not S.share(r, r.g).is_int(), "draw %d" % i)
			var l := S.generate(Seeded.new("last|%d" % i), {"ask": "last-stratum", "paper": paper})
			var sum := 0
			for j in 3:
				sum += S.rounded(S.share(l, j))
			check(sum != l.n, "draw %d: the rounded shares add to the sample" % i)


func test_a_hand_example() -> void:
	# 160 farmers, 50 guards, 30 cooks; a sample of 24: 16, 5 and 3.
	var s := {"G": [160, 50, 30], "N": 240, "n": 24}
	check_eq([S.share(s, 0).key(), S.share(s, 1).key(), S.share(s, 2).key()], ["16", "5", "3"])
	# 137 of 391 in a sample of 24 is 8.409..., which rounds to 8.
	check_eq(S.rounded(Q.new(137 * 24, 391)), 8)


func test_every_tag_shows_up() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 15):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
			for f in QuestionEngine.extra_formats(TYPE, c.unknown, c.angle):
				seen[_make(c, seed, f).spot.ref] = true
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		check(seen.has(ms[i].get("ref", "%s#%d" % [TYPE, i])), "%s never shows" % ms[i].get("ref", i))
