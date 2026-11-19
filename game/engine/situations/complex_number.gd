class_name ComplexNumberSituation
extends RefCounted
## The `complex-number` situation (curriculum/question-types.json, FAL-1004): one or two complex
## numbers in Cartesian form with whole-number parts, for t1-ahl-complex-cartesian (AHL1.12) and,
## as `complex-number-ai`, t1-ai-complex-cartesian (AI-AHL1.12). A complex number is an Array
## [re, im] of Q, and everything here is exact; an argument on Paper 2 is a float.
##
## need.ask is the unknown (see ComplexNumberViews). generate() returns a Dictionary:
##   ask, paper    the unknown; 1 or 2 where the engine says, else 1
##   z, w          the numbers asked about, [re, im]
##   n, k          a power, and the number in front of i in (ki)ⁿ
##   mode          the unknown's own variant: the product asked (zw, z², zz*, zw*), the
##                 condition on k, the equation's form, the number asked from a diagram
##   m             real-parameter: the imaginary part beside k; root-substitute: the root
##   alpha, beta   equate-conjugate: αz + βz* or αz + βiz*
##   special       argument on Paper 1: [reference angle as a share of π, quadrant, scale]
##   h, kq         quadratic-roots: the roots h ± (kq)i

const TRIES := 4000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "product")
	for i in TRIES:
		var s := {"ask": ask, "paper": int(need.get("paper", 1)), "n_max": int(need.get("n_max", 4))}
		var ok := false
		match ask:
			"power-of-i":
				ok = _power_of_i(rng, s)
			"product":
				ok = _product(rng, s)
			"quotient", "solve-linear":
				ok = _quotient(rng, s)
			"power":
				ok = _power(rng, s)
			"real-parameter":
				ok = _real_parameter(rng, s)
			"equate-conjugate":
				ok = _equate_conjugate(rng, s)
			"square-root":
				ok = _square_root(rng, s)
			"root-substitute":
				ok = _root_substitute(rng, s)
			"modulus":
				s.z = c(_nz(rng, -6, 6), _nz(rng, -6, 6))
				ok = true
			"argument":
				ok = _argument(rng, s)
			"argand-read":
				s.z = c(_nz(rng, -5, 5), _nz(rng, -5, 5))
				# Reflecting or turning has nothing to do when z itself is asked.
				s.mode = rng.pick(["conj", "neg", "iz"] if need.get("angle", "") == "transformations" else ["z", "conj", "neg", "iz"])
				ok = absi(s.z[0].n) != absi(s.z[1].n)
			"argand-sum":
				s.z = c(_nz(rng, -4, 4), _nz(rng, -4, 4))
				s.w = c(_nz(rng, -4, 4), _nz(rng, -4, 4))
				s.mode = "sum" if rng.chance(0.5) else "diff"
				var t: Array = add(s.z, s.w) if s.mode == "sum" else sub(s.w, s.z)
				ok = not same(s.z, s.w) and _inside(t, 7) and not t[0].is_zero() and not t[1].is_zero()
			"distance":
				s.z = c(_nz(rng, -5, 5), _nz(rng, -5, 5))
				s.w = c(_nz(rng, -5, 5), _nz(rng, -5, 5))
				var d := sub(s.w, s.z)
				ok = not d[0].is_zero() and not d[1].is_zero() and not add(s.z, s.w)[0].is_zero()
			"quadratic-roots":
				s.h = _nz(rng, -5, 5)
				s.kq = rng.int_in(1, 6)
				ok = s.kq != absi(s.h)
		if ok:
			return s
	return {}


# ── Complex arithmetic, exact ─────────────────────────────────

static func c(a: Variant, b: Variant) -> Array:
	return [Q.of(a), Q.of(b)]


static func add(z: Array, w: Array) -> Array:
	return [z[0].add(w[0]), z[1].add(w[1])]


static func sub(z: Array, w: Array) -> Array:
	return [z[0].sub(w[0]), z[1].sub(w[1])]


static func mul(z: Array, w: Array) -> Array:
	return [z[0].mul(w[0]).sub(z[1].mul(w[1])), z[0].mul(w[1]).add(z[1].mul(w[0]))]


## The product worked with i² = +1: the slip AHL1.12.cartesian-arithmetic#0.
static func mul_plus(z: Array, w: Array) -> Array:
	return [z[0].mul(w[0]).add(z[1].mul(w[1])), z[0].mul(w[1]).add(z[1].mul(w[0]))]


static func scale(z: Array, q: Variant) -> Array:
	return [z[0].mul(q), z[1].mul(q)]


static func conj(z: Array) -> Array:
	return [z[0], z[1].neg()]


static func neg(z: Array) -> Array:
	return [z[0].neg(), z[1].neg()]


## i × z: a quarter turn anticlockwise.
static func times_i(z: Array) -> Array:
	return [z[1].neg(), z[0]]


## |z|², a whole number for whole parts.
static func norm(z: Array) -> Q:
	return z[0].sq().add(z[1].sq())


static func div(z: Array, w: Array) -> Array:
	return scale(mul(z, conj(w)), Q.new(1).div(norm(w)))


static func power(z: Array, n: int, plus := false) -> Array:
	var out := c(1, 0)
	for i in n:
		out = mul_plus(out, z) if plus else mul(out, z)
	return out


static func same(z: Array, w: Array) -> bool:
	return z[0].eq(w[0]) and z[1].eq(w[1])


static func is_real(z: Array) -> bool:
	return z[1].is_zero()


static func _inside(z: Array, r: int) -> bool:
	return absf(z[0].to_float()) <= r and absf(z[1].to_float()) <= r


## The principal argument, in −π < θ ≤ π.
static func arg(z: Array) -> float:
	return atan2(z[1].to_float(), z[0].to_float())


# ── Writing a complex number ──────────────────────────────────

## The imaginary part's size with its i: "i", "3i", "(3/5)i".
static func i_term(q: Q) -> String:
	var m := q.abs_q()
	if m.eq(1):
		return "i"
	if m.is_int():
		return m.text() + "i"
	return "(" + m.text() + ")i"


## a + bi as the IB writes it: "3 − 2i", "−i", "4", "1/2 + (3/2)i".
static func text(z: Array) -> String:
	var a: Q = z[0]
	var b: Q = z[1]
	if b.is_zero():
		return a.text()
	if a.is_zero():
		return ("−" if b.sign() < 0 else "") + i_term(b)
	return a.text() + (" − " if b.sign() < 0 else " + ") + i_term(b)


## In brackets when it has two terms or a minus, for a product: "(3 − 2i)", "4i", "(−2)".
static func bracket(z: Array) -> String:
	var t := text(z)
	if z[0].is_zero() and z[1].sign() > 0:
		return t
	if z[1].is_zero() and z[0].sign() > 0:
		return t
	return "(" + t + ")"


# ── The recipes ──────────────────────────────────────────────

static func _nz(rng: Seeded, lo: int, hi: int) -> int:
	var v := 0
	while v == 0:
		v = rng.int_in(lo, hi)
	return v


## iⁿ (k = 1) or (ki)ⁿ, with n from 5 to 99 for i alone and 3 to 6 with k.
static func _power_of_i(rng: Seeded, s: Dictionary) -> bool:
	s.k = 1 if rng.chance(0.6) else rng.int_in(2, 3)
	s.n = rng.int_in(5, 99) if s.k == 1 else rng.int_in(3, 6 if s.k == 2 else 4)
	return s.n % 4 != 0 or s.k > 1


## zw, z², zz* or zw*, with every part non-zero so the slips read differently.
static func _product(rng: Seeded, s: Dictionary) -> bool:
	s.mode = rng.pick(["zw", "zw", "square", "zconj", "zwconj"])
	s.z = c(_nz(rng, -6, 6), _nz(rng, -6, 6))
	s.w = c(_nz(rng, -5, 5), _nz(rng, -5, 5))
	if s.mode == "square":
		s.w = s.z.duplicate()
	elif s.mode == "zconj":
		s.w = conj(s.z)
	var w: Array = conj(s.w) if s.mode == "zwconj" else s.w
	var p := mul(s.z, w)
	return not same(p, mul_plus(s.z, w)) and not p[0].is_zero() and absi(s.z[0].n) != absi(s.w[0].n)


## z ÷ w = r, with r and w picked first so the division comes out whole. solve-linear asks
## for r from r × w; w may be i or a multiple of it there.
static func _quotient(rng: Seeded, s: Dictionary) -> bool:
	var r := c(_nz(rng, -5, 5), _nz(rng, -5, 5))
	s.w = c(_nz(rng, -4, 4), _nz(rng, -4, 4))
	if s.ask == "solve-linear" and rng.chance(0.2):
		s.w = c(0, _nz(rng, -3, 3))
	s.r = r
	s.z = mul(r, s.w)
	var w: Array = s.w
	return not s.z[0].is_zero() and not s.z[1].is_zero() and absi(w[0].n) != absi(w[1].n) and absi(r[0].n) != absi(r[1].n)


## (a + bi)ⁿ: n 2 to 4 with parts up to 3 by hand, up to 6 with small parts on the GDC.
static func _power(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(2, int(s.n_max))
	var top := 3 if s.n <= 3 else 2
	s.z = c(_nz(rng, -top, top), _nz(rng, -top, top))
	var p := power(s.z, s.n)
	return not p[0].is_zero() and not p[1].is_zero() and absi(s.z[0].n) != absi(s.z[1].n)


## (k + mi)(c + di): real, purely imaginary, or with argument π/4 (real part = imaginary part > 0).
## k is a whole number or a fraction with a small denominator, never 0.
static func _real_parameter(rng: Seeded, s: Dictionary) -> bool:
	s.mode = rng.pick(["real", "imaginary", "quarter"])
	s.m = _nz(rng, -5, 5)
	s.w = c(_nz(rng, -5, 5), _nz(rng, -5, 5))
	var m := Q.new(s.m)
	var cc: Q = s.w[0]
	var d: Q = s.w[1]
	if cc.eq(d) or cc.eq(d.neg()):
		return false
	var k: Q
	match s.mode:
		"real":
			k = m.mul(cc).neg().div(d)
		"imaginary":
			k = m.mul(d).div(cc)
		_:
			k = m.mul(cc.add(d)).div(cc.sub(d))
	s.k = k
	var p := mul([k, m], s.w)
	if k.is_zero() or k.d > 5 or absf(k.to_float()) > 12.0:
		return false
	return s.mode != "quarter" or p[0].sign() > 0


## αz + βz* = e + fi, or αz + βiz* = e + fi, with z whole and α ≠ ±β.
static func _equate_conjugate(rng: Seeded, s: Dictionary) -> bool:
	s.mode = "conj" if rng.chance(0.65) else "iconj"
	s.alpha = _nz(rng, -4, 4)
	s.beta = _nz(rng, -4, 4)
	s.z = c(_nz(rng, -5, 5), _nz(rng, -5, 5))
	if absi(s.alpha) == absi(s.beta):
		return false
	s.rhs = lhs(s, s.z)
	return not s.rhs[0].is_zero() and not s.rhs[1].is_zero()


## αz + βz* or αz + βiz* for a given z.
static func lhs(s: Dictionary, z: Array) -> Array:
	var other: Array = conj(z) if s.mode == "conj" else times_i(conj(z))
	return add(scale(z, s.alpha), scale(other, s.beta))


## A + Bi = (x + yi)², with x > 0, y ≠ 0 and |x| ≠ |y|, so its roots ±(x + yi) are whole.
static func _square_root(rng: Seeded, s: Dictionary) -> bool:
	s.r = c(rng.int_in(1, 6), _nz(rng, -6, 6))
	s.z = power(s.r, 2)
	return absi(s.r[0].n) != absi(s.r[1].n) and not s.z[0].is_zero()


## A root m + ni of z² + pz + q = 0: then p = −2m and q = m² + n².
static func _root_substitute(rng: Seeded, s: Dictionary) -> bool:
	s.z = c(_nz(rng, -5, 5), rng.int_in(1, 6))
	return absi(s.z[0].n) != absi(s.z[1].n)


## Paper 1: a point on a 30°, 45° or 60° line, the parts whole numbers or multiples of √3.
## Paper 2: whole parts, not on a 45° line, the argument clear of a 3 s.f. edge.
static func _argument(rng: Seeded, s: Dictionary) -> bool:
	if s.paper == 1:
		s.special = [rng.pick([Q.new(1, 6), Q.new(1, 4), Q.new(1, 3)]), rng.int_in(1, 4), rng.int_in(1, 3)]
		return true
	s.z = c(_nz(rng, -6, 6), _nz(rng, -6, 6))
	var th := arg(s.z)
	if absi(s.z[0].n) == absi(s.z[1].n):
		return false
	return Answer.rounds_clearly(th, 0.04) and Answer.rounds_clearly(atan(s.z[1].to_float() / s.z[0].to_float()), 0.04) \
		and Answer.rounds_clearly(atan(s.z[0].to_float() / s.z[1].to_float()), 0.04)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
