class_name PolynomialConditionsSituation
extends RefCounted
## The `polynomial-conditions` situation (curriculum/question-types.json): a polynomial with one or
## two coefficients left as letters, and the conditions that fix them (FAL-776). It serves
## t5-ext-unknown-coefficients (a gradient, a point, a tangent) and t5-ext-stationary-conditions (a
## stationary point, a point of inflexion, two stationary x-values). The letters' values are picked
## first, whole numbers, and the conditions worked out from them, so the equations a student forms
## always solve to the picked values.
##
## need.ask is the unknown. generate() returns:
##   ask, paper    the unknown, and Paper 2 where the GDC's solver is the method
##   terms         the polynomial: [{"c": Q, "l": letter or "", "p": power}], highest power first
##   vals          letter -> its value (Q)
##   x0            the x-value of the condition (a nonzero whole number)
##   m, y0         f′(x0) and f(x0), from the picked values
##   x1, m1        a second x-value and f′ there (two-gradients)
##   tm, tc        the tangent y = tm·x + tc at x0 (from-tangent)
##   p, q          the two stationary x-values (two-from-two-stationary)
##   wrong         letter -> value of the tagged slip (see polynomial_conditions_views.gd)
##
## Coefficients stay from −30 to 30 and the letters from −9 to 9, nonzero. The clean limits are the
## checker's too (E13PC_*).

const TRIES := 400
const LIMIT := 30


static func nz(rng: Seeded, lo: int, hi: int) -> int:
	return ExtensionViews.nonzero(rng, lo, hi)


static func T(c: Variant, l: String, p: int) -> Dictionary:
	return {"c": Q.of(c), "l": l, "p": p}


## d/dx of a polynomial with letters, term by term (a letter is a constant).
static func deriv(terms: Array) -> Array:
	var out: Array = []
	for t in terms:
		if t.p > 0:
			out.append(T(t.c.mul(t.p), t.l, t.p - 1))
	return out


## At x: letter -> its coefficient there, and "" -> the number left over.
static func at(terms: Array, x: Variant) -> Dictionary:
	var out := {}
	for t in terms:
		var v: Q = t.c.mul(_pow(Q.of(x), t.p))
		out[t.l] = out.get(t.l, Q.new(0)).add(v)
	return out


## The value at x with the letters put in.
static func value(terms: Array, x: Variant, vals: Dictionary) -> Q:
	var out := Q.new(0)
	var lin := at(terms, x)
	for l in lin:
		out = out.add(lin[l] if l == "" else lin[l].mul(vals[l]))
	return out


static func _pow(x: Q, n: int) -> Q:
	var out := Q.new(1)
	for i in n:
		out = out.mul(x)
	return out


## Solves c00·u + c01·v = r0, c10·u + c11·v = r1; [] when there is no single solution.
static func solve2(c00: Q, c01: Q, r0: Q, c10: Q, c11: Q, r1: Q) -> Array:
	var det := c00.mul(c11).sub(c01.mul(c10))
	if det.is_zero():
		return []
	return [r0.mul(c11).sub(c01.mul(r1)).div(det), c00.mul(r1).sub(r0.mul(c10)).div(det)]


## Two conditions, each [terms, x, right-hand side], solved for two letters.
static func solve_pair(conds: Array, letters: Array) -> Array:
	var rows: Array = []
	for c in conds:
		var lin := at(c[0], c[1])
		rows.append([lin.get(letters[0], Q.new(0)), lin.get(letters[1], Q.new(0)), Q.of(c[2]).sub(lin.get("", Q.new(0)))])
	return solve2(rows[0][0], rows[0][1], rows[0][2], rows[1][0], rows[1][1], rows[1][2])


## One condition solved for one letter, or null when the letter drops out.
static func solve_one(terms: Array, x: Variant, rhs: Variant, letter: String) -> Variant:
	var lin := at(terms, x)
	var c: Q = lin.get(letter, Q.new(0))
	if c.is_zero():
		return null
	return Q.of(rhs).sub(lin.get("", Q.new(0))).div(c)


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "k-from-gradient")
	for i in TRIES:
		var s := _try(ask, rng)
		if not s.is_empty():
			s.ask = ask
		if not s.is_empty() and _clean(s):
			s.paper = 2 if str(need.get("angle", "")).begins_with("gdc-") else 1
			return s
	push_error("PolynomialConditionsSituation: no clean situation for %s" % need)
	return {}


static func _clean(s: Dictionary) -> bool:
	for t in s.terms:
		if t.c.is_zero() or not t.c.is_int() or absi(t.c.n) > LIMIT:
			return false
	for l in s.vals:
		if s.vals[l].is_zero() or not s.vals[l].is_int() or absi(s.vals[l].n) > 9:
			return false
	# Givens a student can work with by hand, and no gradient of 0 where none is asked.
	for key in ["m", "y0", "m1", "tm", "tc"]:
		if s.has(key) and absi(Q.of(s[key]).n) > 99:
			return false
	if s.ask in ["two-from-gradient-and-point", "two-gradients", "k-from-gradient"] and (s.m.is_zero() or (s.has("m1") and s.m1.is_zero())):
		return false
	# A slip that lands on the answer, or on nothing, is no wrong option.
	var w: Dictionary = s.get("wrong", {})
	if w.is_empty():
		return false
	var same := true
	for l in s.vals:
		if not w.has(l) or w[l] == null:
			return false
		if not w[l].eq(s.vals[l]):
			same = false
		if absf(w[l].to_float()) > 999.0 or w[l].d > 99:
			return false
	return not same


static func _try(ask: String, rng: Seeded) -> Dictionary:
	var s := {"x0": nz(rng, -3, 3)}
	var x0: int = s.x0
	match ask:
		"k-from-gradient":
			var cubic := rng.chance(0.4)
			var b := nz(rng, -9, 9)
			var c := nz(rng, -9, 9)
			s.terms = [T(1, "k", 3 if cubic else 2), T(b, "", 1), T(c, "", 0)]
			s.vals = {"k": Q.new(nz(rng, -5, 5))}
			s.m = value(deriv(s.terms), x0, s.vals)
			s.wrong = {"k": solve_one(s.terms, x0, s.m, "k")}
		"two-from-gradient-and-point":
			var cubic := rng.chance(0.6)
			s.terms = [T(1, "a", 3 if cubic else 2), T(1, "b", 1)]
			if not cubic:
				s.terms.append(T(nz(rng, -9, 9), "", 0))
			s.vals = {"a": Q.new(nz(rng, -5, 5)), "b": Q.new(nz(rng, -6, 6))}
			s.m = value(deriv(s.terms), x0, s.vals)
			s.y0 = value(s.terms, x0, s.vals)
			# SL5.3.unknown-coefficients#0: the gradient into f, the point's y into f′.
			s.wrong = _pair(solve_pair([[s.terms, x0, s.m], [deriv(s.terms), x0, s.y0]], ["a", "b"]))
			if s.m.eq(s.y0):
				return {}
		"two-gradients":
			var cubic := rng.chance(0.5)
			s.terms = [T(1, "a", 3 if cubic else 2), T(1, "b", 2 if cubic else 1), T(nz(rng, -9, 9), "", 0)]
			s.vals = {"a": Q.new(nz(rng, -4, 4)), "b": Q.new(nz(rng, -6, 6))}
			s.x1 = nz(rng, -3, 3)
			if s.x1 == x0:
				return {}
			var d := deriv(s.terms)
			s.m = value(d, x0, s.vals)
			s.m1 = value(d, s.x1, s.vals)
			if solve_pair([[d, x0, s.m], [d, s.x1, s.m1]], ["a", "b"]).is_empty():
				return {}
			s.wrong = _pair(solve_pair([[s.terms, x0, s.m], [s.terms, s.x1, s.m1]], ["a", "b"]))
		"from-tangent":
			var cubic := rng.chance(0.5)
			s.terms = [T(1, "a", 3 if cubic else 2), T(1, "b", 1)]
			s.vals = {"a": Q.new(nz(rng, -4, 4)), "b": Q.new(nz(rng, -6, 6))}
			s.tm = value(deriv(s.terms), x0, s.vals)
			s.y0 = value(s.terms, x0, s.vals)
			s.tc = s.y0.sub(s.tm.mul(x0))
			if s.tm.is_zero() or s.tc.is_zero():
				return {}
			# The tangent's y-intercept taken as f(x0).
			s.wrong = _pair(solve_pair([[deriv(s.terms), x0, s.tm], [s.terms, x0, s.tc]], ["a", "b"]))
		"k-from-stationary-x":
			var a: int = rng.pick([1, 1, 2, -1, -2, 3])
			var k := nz(rng, -6, 6)
			var b := -3 * a * x0 * x0 - 2 * k * x0
			if b == 0:
				return {}
			s.terms = [T(a, "", 3), T(1, "k", 2), T(b, "", 1), T(nz(rng, -9, 9), "", 0)]
			s.vals = {"k": Q.new(k)}
			s.wrong = {"k": solve_one(s.terms, x0, 0, "k")}
		"two-from-stationary-point":
			var a := nz(rng, -3, 3)
			if (3 * a * x0) % 2 != 0:
				return {}
			var b := -3 * a * x0 / 2
			var d := nz(rng, -9, 9)
			s.terms = [T(1, "a", 3), T(1, "b", 2), T(d, "", 0)]
			s.vals = {"a": Q.new(a), "b": Q.new(b)}
			s.y0 = value(s.terms, x0, s.vals)
			if s.y0.is_zero() or s.y0.eq(x0):
				return {}
			# SL5.8.stationary-point-conditions#2: f′(y0) = 0 with f(x0) = y0.
			s.wrong = _pair(solve_pair([[deriv(s.terms), s.y0, 0], [s.terms, x0, s.y0]], ["a", "b"]))
		"k-from-inflexion":
			var a: int = rng.pick([1, 1, 2, -1, -2])
			var p := -3 * a * x0
			var b := nz(rng, -9, 9)
			s.terms = [T(a, "", 3), T(1, "p", 2), T(b, "", 1), T(nz(rng, -9, 9), "", 0)]
			s.vals = {"p": Q.new(p)}
			# f′(x0) = 0 instead of f″(x0) = 0.
			s.wrong = {"p": solve_one(deriv(s.terms), x0, 0, "p")}
		"two-from-two-stationary":
			var a: int = rng.pick([1, 1, 2])
			s.p = nz(rng, -4, 4)
			s.q = nz(rng, -4, 4)
			if s.p >= s.q or (3 * a * (s.p + s.q)) % 2 != 0:
				return {}
			var b: int = -3 * a * (s.p + s.q) / 2
			var c: int = 3 * a * s.p * s.q
			if b == 0:
				return {}
			s.terms = [T(a, "", 3), T(1, "b", 2), T(1, "c", 1), T(nz(rng, -9, 9), "", 0)]
			s.vals = {"b": Q.new(b), "c": Q.new(c)}
			s.x0 = s.p
			s.x1 = s.q
			# f′ = a(x − p)(x − q), without the 3.
			s.wrong = {"b": Q.new(-a * (s.p + s.q), 2), "c": Q.new(a * s.p * s.q)}
	if not s.has("terms"):
		return {}
	return s


static func _pair(sol: Array) -> Dictionary:
	return {} if sol.is_empty() else {"a": sol[0], "b": sol[1]}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
