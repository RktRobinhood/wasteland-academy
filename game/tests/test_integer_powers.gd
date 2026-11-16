extends "res://tests/test_case.gd"
## The integer-powers situation (FAL-780): t1-ext-exponent-laws is built with every cell, each value
## and simplified term is the exact one, the error-spot working has one wrong line, and every tag
## shows up. The SymPy checker (tools/check-answers) works every value and term out again from the
## question's text.

const TYPE := "t1-ext-exponent-laws"
const CELLS := 12
const S := preload("res://engine/situations/integer_powers.gd")


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
					check_eq(q.paper, 1, c.key)


func test_values_and_terms_are_exact() -> void:
	for i in 60:
		var s := S.generate(Seeded.new("neg|%d" % i), {"ask": "negative-power"})
		check(s.v.mul(S.qpow(s.base, s.n)).eq(1), "%s^(−%d) is not %s" % [s.base.text(), s.n, s.v.text()])
		var z := S.generate(Seeded.new("zero|%d" % i), {"ask": "zero-and-negative"})
		check(z.v.eq(Q.new(1).add(S.qpow(z.b, -z.n))), "c^0 + b^(−n)")
		var p := S.generate(Seeded.new("prod|%d" % i), {"ask": "power-of-product"})
		check_eq(p.C, S.ipow(p.a, p.pp) * p.b)
		check(p.e == p.m * p.pp + p.n and p.e != 0 and p.e != 1, "exponent %d" % p.e)
		var k := S.generate(Seeded.new("prime|%d" % i), {"ask": "single-prime-power"})
		var sign := 1 if k.op == "×" else -1
		check(S.qpow(k.A, k.m).mul(S.qpow(k.B, sign * k.n)).eq(S.qpow(k.t, k.k)), "%d^%d %s %d^%d is not %d^%d" % [k.A, k.m, k.op, k.B, k.n, k.t, k.k])


func test_the_quotient_has_one_letter_on_each_line() -> void:
	for i in 60:
		var s := S.generate(Seeded.new("quot|%d" % i), {"ask": "two-letter-quotient"})
		check(s.ea * s.eb < 0, "a^%d b^%d" % [s.ea, s.eb])
		check(IntegerPowersViews.ab_text(s.ea, s.eb).contains("/"), IntegerPowersViews.ab_text(s.ea, s.eb))


func test_error_spot_raises_only_the_x() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		if c.unknown != "power-of-product":
			continue
		for seed in range(1, 8):
			var q := _make(c, seed, "error-spot")
			check_eq(q.spot.lines.size(), 4)
			check(q.spot.bad in [0, 1], "bad line %d" % q.spot.bad)


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
