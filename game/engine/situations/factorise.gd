class_name FactoriseSituation
extends RefCounted
## The `fn-pre-factorise` situation (curriculum/question-types.json): an expression to
## factorise, for the prior-learning type fn-pre-factorise (FAL-459). It is built from
## its factors, so it always factorises over the integers (except the sum of two
## squares, which is the point of that question).
##
## generate() returns:
##   form   "common" gx(ax + b), "monic" (x + r)(x + s), "dos" (px − q)(px + q) or the
##          sum p²x² + q² (sum true), "nonmonic" (a1x + b1)(a2x + b2), "pair" two
##          numbers m and n from their product and sum, "missing" (x + r)(x + s) with s missing
##   A, B, C   the expression Ax² + Bx + C
##   and the factors: g, a, b; r, s; p, q; a1, b1, a2, b2; m, n

const TRIES := 1000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var form: String = need.get("form", "monic")
	for i in TRIES:
		var s := _draw(rng, form)
		if not s.is_empty():
			s.form = form
			return s
	push_error("FactoriseSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, form: String) -> Dictionary:
	match form:
		"common":
			var g := rng.int_in(2, 6)
			var a := rng.int_in(1, 6)
			var b := ExtensionViews.nonzero(rng, -9, 9)
			if Q.gcd(a, absi(b)) != 1 or g * a > 30:
				return {}
			return {"g": Q.new(g), "a": Q.new(a), "b": Q.new(b), "A": Q.new(g * a), "B": Q.new(g * b), "C": Q.new(0)}
		"monic", "missing":
			var r := ExtensionViews.nonzero(rng, -9, 9)
			var s := ExtensionViews.nonzero(rng, -9, 9)
			if r == s or r + s == 0:
				return {}
			return {"r": Q.new(r), "s": Q.new(s), "A": Q.new(1), "B": Q.new(r + s), "C": Q.new(r * s)}
		"dos":
			var p := rng.int_in(1, 5)
			var q := rng.int_in(1, 9)
			if Q.gcd(p, q) != 1 or (p == 1 and q == 1):
				return {}
			var sum := rng.chance(0.25)
			return {"p": Q.new(p), "q": Q.new(q), "sum": sum, "A": Q.new(p * p), "B": Q.new(0), "C": Q.new(q * q if sum else -q * q)}
		"nonmonic":
			var a1 := rng.int_in(1, 3)
			var a2 := rng.int_in(1, 3)
			var b1 := ExtensionViews.nonzero(rng, -7, 7)
			var b2 := ExtensionViews.nonzero(rng, -7, 7)
			var a := a1 * a2
			var b := a1 * b2 + a2 * b1
			var c := b1 * b2
			if a < 2 or b == 0 or Q.gcd(a1, absi(b1)) != 1 or Q.gcd(a2, absi(b2)) != 1 or absi(b) > 40:
				return {}
			# One factorisation only, written with the larger leading term first.
			if a1 < a2 or (a1 == a2 and b1 > b2):
				var t := a1
				a1 = a2
				a2 = t
				t = b1
				b1 = b2
				b2 = t
			return {"a1": Q.new(a1), "b1": Q.new(b1), "a2": Q.new(a2), "b2": Q.new(b2), "A": Q.new(a), "B": Q.new(b), "C": Q.new(c)}
		"pair":
			var m := ExtensionViews.nonzero(rng, -12, 12)
			var n := ExtensionViews.nonzero(rng, -12, 12)
			if m >= n or m + n == 0 or absi(m * n) > 72:
				return {}
			return {"m": Q.new(m), "n": Q.new(n), "P": Q.new(m * n), "S": Q.new(m + n)}
	return {}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
