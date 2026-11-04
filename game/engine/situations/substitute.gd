class_name SubstituteSituation
extends RefCounted
## The `fn-pre-substitute` situation (curriculum/question-types.json): an expression and a
## value to put in, for the prior-learning type fn-pre-substitute (FAL-424). Extension, so
## always Paper 1, with results that are whole numbers or simple fractions.
##
## generate() returns, by need.kind (square, linear, power, fraction, rational or missing):
##   text    the expression as shown
##   x0      the input, value the result
##   poly    a polynomial: co, the coefficients from the top power down
##   rational (and a rational fraction input): top, bottom, each {"m", "c", "first"}: mx + c, with
##           the constant written first when first; `loose` names the part that can go wrong
##           left to right ("top" or "bottom", "" for none)
##   missing: co [a, b], the expression ax + b, or b − |a|x, with the value it reaches
##   xs      the inputs of a table around x0, where need.rep is "table"

const TRIES := 400
## Clean limits, the checker's own copy is SB_*.
const MAX_DENOM := 16
const INPUTS := [[1, 2], [-1, 2], [1, 3], [3, 2], [1, 4], [2, 3]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var kind: String = need.get("kind", "square")
	for i in TRIES:
		var s: Dictionary
		match kind:
			"linear":
				s = _linear(rng)
			"power":
				s = _power(rng)
			"fraction":
				s = _fraction(rng)
			"rational":
				s = _rational(rng, Q.new(ExtensionViews.nonzero(rng, -5, 5)), true)
			"missing":
				s = _missing(rng)
			_:
				s = _square(rng)
		if s.is_empty() or s.value.is_zero() or s.value.d > MAX_DENOM:
			continue
		s.kind = kind
		s.paper = 1
		if need.get("rep", "") == "table":
			s.xs = _inputs(s)
		return s
	push_error("SubstituteSituation: no clean situation for %s" % need)
	return {}


static func poly_at(co: Array, x: Q) -> Q:
	var out := Q.new(0)
	for c in co:
		out = out.mul(x).add(c)
	return out


static func lin_at(l: Dictionary, x: Q) -> Q:
	return x.mul(l.m).add(l.c)


## "2 + 3x", "x − 1", "5 − 2x".
static func lin_text(l: Dictionary) -> String:
	var term := Fmt.term(Q.new(absi(l.m)), 1, true)
	if l.first:
		return "%s %s %s" % [Fmt.num(l.c), "+" if l.m > 0 else "−", term]
	return Fmt.poly([l.m, l.c])


static func _poly(co: Array, x0: Q, text: String = "") -> Dictionary:
	return {"co": co, "x0": x0, "value": poly_at(co, x0), "text": text if text != "" else Fmt.poly(co)}


static func _square(rng: Seeded) -> Dictionary:
	var a: int = rng.pick([1, 1, 2, 3, -1, -1, -2])
	var b: int = rng.pick([0, 0, 2, 3, 4, -2, -3, -4])
	var c := rng.int_in(-6, 6)
	var x0 := Q.new(rng.int_in(-5, -1))
	if b == 0 and c == 0:
		return {}
	return _poly([a, b, c], x0)


static func _linear(rng: Seeded) -> Dictionary:
	var m: int = rng.pick([2, 3, 4, 5, -2, -3, -4, -5, -2, -3])
	var c := ExtensionViews.nonzero(rng, -9, 9)
	var x0 := Q.new(rng.int_in(-5, -1))
	var l := {"m": m, "c": c, "first": m < 0 and c > 0}
	return _poly([m, c], x0, lin_text(l))


static func _power(rng: Seeded) -> Dictionary:
	var a: int = rng.pick([2, 3, 4, 5, -1, -1, -2, -3])
	return _poly([a, 0, 0], Q.new(ExtensionViews.nonzero(rng, -5, 5)))


static func _fraction(rng: Seeded) -> Dictionary:
	var pair: Array = rng.pick(INPUTS)
	var x0 := Q.new(pair[0], pair[1])
	match rng.int_in(0, 3):
		0:
			return _poly([1, 0, rng.int_in(1, 5)], x0)
		1:
			return _poly([rng.pick([2, 3, 4, -2]), ExtensionViews.nonzero(rng, -5, 5)], x0)
		2:
			return _poly([1, 0, 0, -rng.int_in(1, 5)], x0)
	return _rational(rng, x0, false)


## (a + bx)/(x − r) or (x + p)/(a − bx). With `loose` one part is written with its constant
## first, so working it left to right gives another number; without, it is (x + p)/(x − q).
static func _rational(rng: Seeded, x0: Q, loose: bool) -> Dictionary:
	var top: Dictionary
	var bottom: Dictionary
	var part := ""
	if not loose:
		top = {"m": 1, "c": rng.int_in(1, 5), "first": false}
		bottom = {"m": 1, "c": -rng.int_in(1, 5), "first": false}
	elif rng.chance(0.5):
		part = "top"
		top = {"m": rng.int_in(2, 5), "c": rng.int_in(1, 9), "first": true}
		bottom = {"m": 1, "c": ExtensionViews.nonzero(rng, -5, 5), "first": false}
	else:
		part = "bottom"
		top = {"m": 1, "c": ExtensionViews.nonzero(rng, -5, 5), "first": false}
		bottom = {"m": -rng.int_in(2, 5), "c": rng.int_in(1, 9), "first": true}
	var t := lin_at(top, x0)
	var b := lin_at(bottom, x0)
	if b.is_zero() or t.is_zero():
		return {}
	var s := {"top": top, "bottom": bottom, "loose": part, "x0": x0, "t": t, "b": b, "value": t.div(b),
		"text": "(%s)/(%s)" % [lin_text(top), lin_text(bottom)]}
	if loose:
		var l: Dictionary = top if part == "top" else bottom
		var wrong: Q = left_to_right(l, x0)
		if wrong.eq(lin_at(l, x0)) or wrong.is_zero():
			return {}
		s.ltr = wrong
		s.ltr_value = wrong.div(b) if part == "top" else t.div(wrong)
		if s.ltr_value.d > MAX_DENOM:
			return {}
	return s


## c + mx worked left to right: (c + m) × x.
static func left_to_right(l: Dictionary, x0: Q) -> Q:
	return Q.new(l.c + l.m).mul(x0)


static func _missing(rng: Seeded) -> Dictionary:
	var a: int = rng.pick([2, 3, 4, 5, 2, 3, -2, -3])
	var b := ExtensionViews.nonzero(rng, -9, 9) if a > 0 else rng.int_in(1, 9)
	var x0 := Q.new(ExtensionViews.nonzero(rng, -6, 6))
	var l := {"m": a, "c": b, "first": a < 0}
	return {"co": [a, b], "x0": x0, "value": lin_at(l, x0), "text": lin_text(l)}


## Five inputs round x0, none where the expression has no value, for a table to complete.
static func _inputs(s: Dictionary) -> Array:
	var out: Array = []
	var x: int = s.x0.n - 2
	while out.size() < 5:
		if s.has("co") or not lin_at(s.bottom, Q.new(x)).is_zero():
			out.append(Q.new(x))
		x += 1
	return out


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
