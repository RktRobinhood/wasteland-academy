class_name EquivalentFormsSituation
extends RefCounted
## The `fn-link-equivalent-forms` situation (curriculum/question-types.json): one object
## in different forms, for the link type fn-link-equivalent-forms (FAL-459). Each form
## of the type picks its own numbers:
##
##   quad      a(x − p)(x − q) = ax² + bx + c = a(x − h)² + k, whole numbers throughout
##   identity  x² + bx + c ≡ (x + p)² + q with b even
##   same      two expressions that are or aren't one object (pair: log-sub, log-div,
##             log-pow, log-add, sq-sum, dos), with numbers m and n
##   law       a claimed log law (claim: add, sq, sub, pow, div), tested at a = m, b = n
##   cos2x     cos 2x + B·f(x) + C = 0 with f sin or cos, built from the roots r1, r2 of
##             the quadratic in f(x) it becomes
##   power     f(x) = A/x^m + 1/(B·x^n)
##   vroots    a(x − h)² + k with −k/a = d², so the roots are h ± d

const TRIES := 2000
const PAIRS := ["log-sub", "log-div", "log-pow", "log-add", "sq-sum", "dos"]
const CLAIMS := ["add", "sq", "sub", "pow", "div"]
## Values of sin x or cos x the cos 2x equations factorise to: on the unit circle, or
## outside [−1, 1] so that root gives nothing.
const ROOTS := [-2, -1, 0, 1, 2]
const HALF_ROOTS := [-3, -1, 1, 3]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	# The stream's first draw leans low (see quadratic_inequality.gd), so it is spent.
	rng.int_in(0, 1)
	var form: String = need.get("form", "quad")
	for i in TRIES:
		var s := _draw(rng, form, need)
		if not s.is_empty():
			s.form = form
			return s
	push_error("EquivalentFormsSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, form: String, need: Dictionary) -> Dictionary:
	match form:
		"quad":
			var a: int = rng.pick([2, 3, -2, -3])
			var p := ExtensionViews.nonzero(rng, -6, 6)
			var q := ExtensionViews.nonzero(rng, -6, 6)
			# A vertex off the y-axis, so the vertex form is not the general form.
			if p >= q or (p + q) % 2 != 0 or p + q == 0:
				return {}
			var h := (p + q) / 2
			var k := -a * ((q - p) / 2) * ((q - p) / 2)
			if need.get("graph", false) and absi(k) > 40:
				return {}
			return {"a": Q.new(a), "p": Q.new(p), "q": Q.new(q), "b": Q.new(-a * (p + q)), "c": Q.new(a * p * q), "h": Q.new(h), "k": Q.new(k)}
		"identity":
			var p := ExtensionViews.nonzero(rng, -6, 6)
			var c := ExtensionViews.nonzero(rng, -15, 15)
			return {"b": Q.new(2 * p), "c": Q.new(c), "p": Q.new(p), "q": Q.new(c - p * p)}
		"same":
			var pair: String = rng.pick(PAIRS)
			var m := rng.int_in(2, 9)
			var n := rng.int_in(2, 6)
			if m == n:
				return {}
			return {"pair": pair, "m": Q.new(m), "n": Q.new(n)}
		"law":
			var m := rng.int_in(2, 9)
			var n := rng.int_in(2, 9)
			if m == n:
				return {}
			return {"claim": rng.pick(CLAIMS), "m": Q.new(m), "n": Q.new(n)}
		"cos2x":
			var fn: String = "sin" if rng.chance(0.6) else "cos"
			var r1: Q = Q.new(rng.pick(HALF_ROOTS), 2) if rng.chance(0.6) else Q.new(rng.pick(ROOTS))
			var r2 := Q.new(rng.pick(ROOTS))
			if r1.eq(r2) or not r1.mul(r2).mul(2).is_int():
				return {}
			var sols := solutions(fn, [r1, r2])
			if sols.size() < 2 or sols.size() > 4:
				return {}
			# 2f² − 2(r1 + r2)f + 2r1r2 = 0, written back as cos 2x + B f + C = 0.
			var B: Q = r1.add(r2).mul(2) if fn == "sin" else r1.add(r2).mul(-2)
			var C: Q = r1.mul(r2).mul(-2).sub(1) if fn == "sin" else r1.mul(r2).mul(2).add(1)
			if B.is_zero():
				return {}
			return {"fn": fn, "r1": r1, "r2": r2, "B": B, "C": C, "sols": sols}
		"power":
			var m := rng.int_in(1, 3)
			var n := rng.int_in(1, 3)
			if m == n:
				return {}
			return {"A": Q.new(rng.int_in(2, 6)), "m": Q.new(m), "B": Q.new(rng.int_in(2, 5)), "n": Q.new(n)}
		"vroots":
			var a: int = rng.pick([1, 2, -1, -2, 3])
			var h := rng.int_in(-5, 5)
			var d := rng.int_in(1, 5)
			if h == 0 or absi(h) == d:
				return {}
			return {"a": Q.new(a), "h": Q.new(h), "d": Q.new(d), "k": Q.new(-a * d * d)}
	return {}


## The solutions in [0, 2π], as multiples of π, of f(x) = r for each r: sin or cos.
static func solutions(fn: String, rs: Array) -> Array:
	var out: Array = []
	for r in rs:
		for x in _one(fn, r):
			if not out.any(func(y): return y.eq(x)):
				out.append(x)
	out.sort_custom(func(x, y): return x.lt(y))
	return out


static func _one(fn: String, r: Q) -> Array:
	var key := r.key()
	if fn == "sin":
		return {"1": [Q.new(1, 2)], "-1": [Q.new(3, 2)], "0": [Q.new(0), Q.new(1), Q.new(2)], "1/2": [Q.new(1, 6), Q.new(5, 6)],
			"-1/2": [Q.new(7, 6), Q.new(11, 6)]}.get(key, [])
	return {"1": [Q.new(0), Q.new(2)], "-1": [Q.new(1)], "0": [Q.new(1, 2), Q.new(3, 2)], "1/2": [Q.new(1, 3), Q.new(5, 3)],
		"-1/2": [Q.new(2, 3), Q.new(4, 3)]}.get(key, [])


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
