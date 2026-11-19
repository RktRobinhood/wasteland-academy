class_name ComplexPolarSituation
extends RefCounted
## The complex numbers in polar and Euler form (curriculum/question-types.json, FAL-1005): one
## recipe for four types. `complex-polar` is t1-ahl-complex-polar (AHL1.13), `de-moivre` is
## t1-ahl-de-moivre and `conjugate-roots` t1-ahl-conjugate-roots (AHL1.14), and
## `complex-polar-ai` is t1-ai-complex-polar (AI-AHL1.13).
##
## Exact numbers on Paper 1 use the standard angles, multiples of π/6 and π/4, so every part is
## a whole number times 1, √2, √3 or √6. A surd here is an Array [coef: Q, root: int], m√r with
## r square-free; a modulus is a surd and an argument is a Q c, the angle cπ in −π < θ ≤ π.
##
## need.ask is the unknown. generate() returns a Dictionary:
##   ask, paper    the unknown; 1 or 2
##   style         "euler" (re^(iθ)) or "cis" (r cis θ), as the question writes polar form
##   r, c          a number's modulus (a surd) and argument; r2, c2 a second number's
##   mode          the unknown's own variant (product or quotient, the condition, the target)
##   n             a power, or the number of roots
##   k, h, kq      a multiplier, a root h ± (kq)i
##   a, b          Cartesian parts (whole numbers) on Paper 2, or a cubic's coefficients
##   letter        the angle's letter in an identity or a proof

const TRIES := 4000
const STYLES := ["euler", "cis"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "to-polar")
	for i in TRIES:
		var s := {"ask": ask, "paper": int(need.get("paper", 1)), "angle": str(need.get("angle", "any")), "style": rng.pick(STYLES)}
		if need.get("ai", false):
			s.ai = true
		var ok := false
		match ask:
			"to-polar", "to-cartesian":
				ok = _ai_point(rng, s) if need.get("ai", false) else _special_point(rng, s, ask == "to-polar")
			"polar-product":
				ok = _polar_product(rng, s)
			"product-cartesian":
				ok = _product_cartesian(rng, s)
			"rotate-point":
				ok = _rotate_point(rng, s)
			"describe-map":
				ok = _describe_map(rng, s)
			"euler-sum":
				ok = _euler_sum(rng, s)
			"euler-trig":
				s.k = rng.int_in(1, 4)
				s.n = rng.int_in(1, 4)
				s.mode = rng.pick(["plus", "minus", "reverse"])
				s.letter = rng.pick(["θ", "x"])
				ok = true
			"exact-trig":
				ok = _exact_trig(rng, s)
			"power-polar":
				ok = _power_polar(rng, s)
			"power-cartesian":
				ok = _power_cartesian(rng, s)
			"least-power":
				ok = _least_power(rng, s)
			"nth-root", "all-roots":
				ok = _nth_roots(rng, s)
			"roots-polygon":
				ok = _roots_polygon(rng, s)
			"multiple-angle":
				ok = _multiple_angle(rng, s)
			"power-reduction":
				s.mode = rng.pick(["cos3", "cos4", "sin3", "sin4", "cos5"])
				s.letter = rng.pick(["θ", "x"])
				ok = true
			"induction-gap", "induction-flaw":
				s.letter = rng.pick(["θ", "α", "x"])
				ok = true
			"solve-quadratic", "quadratic-from-root", "other-root":
				s.h = nonzero(rng, -5, 5)
				s.kq = rng.int_in(1, 6)
				s.mode = rng.pick(["quadratic", "cubic"]) if ask == "other-root" else "quadratic"
				ok = s.kq != absi(s.h)
			"real-root", "cubic-coefficients":
				ok = _cubic(rng, s)
			"add-sinusoids":
				ok = _add_sinusoids(rng, s)
		if ok:
			return s
	return {}


static func nonzero(rng: Seeded, lo: int, hi: int) -> int:
	var v := 0
	while v == 0:
		v = rng.int_in(lo, hi)
	return v


# ── Surds m√r ─────────────────────────────────────────────────

static func sd(m: Variant, r: int = 1) -> Array:
	return [Q.of(m), r]


## √n as [m, r], r square-free.
static func root_of(n: int) -> Array:
	var m := 1
	var r := n
	var f := 2
	while f * f <= r:
		while r % (f * f) == 0:
			r /= f * f
			m *= f
		f += 1
	return [m, r]


static func smul(a: Array, b: Array) -> Array:
	var rr := root_of(int(a[1]) * int(b[1]))
	return [a[0].mul(b[0]).mul(rr[0]), rr[1]]


static func sscale(a: Array, q: Variant) -> Array:
	return [a[0].mul(Q.of(q)), a[1]]


static func sneg(a: Array) -> Array:
	return [a[0].neg(), a[1]]


static func szero(a: Array) -> bool:
	return a[0].is_zero()


static func sval(a: Array) -> float:
	return a[0].to_float() * sqrt(float(a[1]))


## a + b for two surds with the same root (or one of them 0); [] when they don't add to one surd.
static func sadd(a: Array, b: Array) -> Array:
	if szero(a):
		return b
	if szero(b):
		return a
	if int(a[1]) != int(b[1]):
		return []
	return [a[0].add(b[0]), a[1]]


static func ssame(a: Array, b: Array) -> bool:
	if szero(a) and szero(b):
		return true
	return a[0].eq(b[0]) and int(a[1]) == int(b[1])


## The surd's power n: (m√r)ⁿ.
static func spow(a: Array, n: int) -> Array:
	var out := sd(1)
	for i in n:
		out = smul(out, a)
	return out


## m√r as written: "2√3", "−√2", "3/2", "3√2/2".
static func stext(a: Array) -> String:
	var m: Q = a[0]
	var r := int(a[1])
	if r == 1:
		return m.text()
	var sign := "−" if m.sign() < 0 else ""
	var am := m.abs_q()
	var top := ("" if am.n == 1 else str(am.n)) + "√%d" % r
	return sign + top + ("" if am.d == 1 else "/%d" % am.d)


## The i-term's size: "i", "3i", "√3 i", "2√3 i", "(3/2)i".
static func iterm(a: Array) -> String:
	var m: Q = a[0].abs_q()
	var r := int(a[1])
	if r == 1:
		if m.eq(1):
			return "i"
		return (m.text() if m.is_int() else "(" + m.text() + ")") + "i"
	return stext([m, r]) + " i"


# ── Complex numbers [re, im], parts surds ────────────────────

## a + bi as the IB writes it: "−2√3 + 2i", "3√2 − 3√2 i", "−4i", "√3".
static func ctext(z: Array) -> String:
	var a: Array = z[0]
	var b: Array = z[1]
	if szero(b):
		return stext(a)
	if szero(a):
		return ("−" if b[0].sign() < 0 else "") + iterm(b)
	return stext(a) + (" − " if b[0].sign() < 0 else " + ") + iterm(b)


static func cx(a: Variant, b: Variant) -> Array:
	return [a if a is Array else sd(a), b if b is Array else sd(b)]


static func csame(z: Array, w: Array) -> bool:
	return ssame(z[0], w[0]) and ssame(z[1], w[1])


# ── The standard angles ──────────────────────────────────────

## c in −1 < c ≤ 1, for the angle cπ.
static func principal(c: Q) -> Q:
	var out := c
	while not out.lt(1) and not out.eq(1):
		out = out.sub(2)
	while not Q.new(-1).lt(out):
		out = out.add(2)
	return out


static func is_principal(c: Q) -> bool:
	return Q.new(-1).lt(c) and (c.lt(1) or c.eq(1))


## Whether cπ is a multiple of π/6 or π/4.
static func is_special(c: Q) -> bool:
	return c.mul(12).is_int() and (posmod(int(c.mul(12).n), 2) == 0 or posmod(int(c.mul(12).n), 3) == 0)


## cos cπ and sin cπ for a standard angle, as surds.
static func cos_sin(c: Q) -> Array:
	var deg := posmod(int(c.mul(180).n), 360)
	var first := [[sd(1), sd(0)], [sd(Q.new(1, 2), 3), sd(Q.new(1, 2))], [sd(Q.new(1, 2), 2), sd(Q.new(1, 2), 2)],
		[sd(Q.new(1, 2)), sd(Q.new(1, 2), 3)], [sd(0), sd(1)]]
	var ref := deg % 90
	var quarter := deg / 90
	var idx: int = {0: 0, 30: 1, 45: 2, 60: 3}[ref]
	var cs: Array = first[idx]
	match quarter:
		0:
			return cs
		1:
			return [sneg(cs[1]), cs[0]]
		2:
			return [sneg(cs[0]), sneg(cs[1])]
	return [cs[1], sneg(cs[0])]


## r cis cπ in Cartesian form, exactly.
static func cart(r: Array, c: Q) -> Array:
	var cs := cos_sin(c)
	return [smul(r, cs[0]), smul(r, cs[1])]


## The angle cπ as an exponent: "πi/3", "5πi/6", "−πi/4", "πi".
static func pi_i(c: Q) -> String:
	if c.is_zero():
		return "0"
	var top := "πi" if absi(c.n) == 1 else "%dπi" % absi(c.n)
	return ("−" if c.n < 0 else "") + top + ("" if c.d == 1 else "/%d" % c.d)


## A number in polar form: "2e^(5πi/6)", "√2 e^(−πi/4)", "4 cis(2π/3)", "cis(π/6)".
static func ptext(r: Array, c: Q, style: String) -> String:
	var rt := "" if ssame(r, sd(1)) else stext(r)
	if style == "euler":
		return rt + (" " if rt.contains("√") else "") + "e^(%s)" % pi_i(c)
	return (rt + " " if rt != "" else "") + "cis(%s)" % Fmt.pi(c)


# ── The recipes ──────────────────────────────────────────────

## The standard angles cπ in −π < θ ≤ π but 0, each with its family: 4 for a multiple of π/4
## only, 6 for a multiple of π/6 only, 2 for a multiple of π/2.
static func specials() -> Array:
	var out: Array = []
	for n in range(-11, 13):
		var c := Q.new(n, 12)
		if n != 0 and is_special(c):
			out.append(c)
	return out


static func family(c: Q) -> int:
	if c.mul(2).is_int():
		return 2
	return 4 if c.mul(4).is_int() else 6


## A modulus that makes a standard angle's parts whole: m√2 at π/4, 2m at π/6, any on an axis.
static func clean_r(rng: Seeded, c: Q, top: int = 3) -> Array:
	match family(c):
		4:
			return sd(rng.int_in(1, top), 2)
		6:
			return sd(2 * rng.int_in(1, top))
	return sd(rng.int_in(2, 2 * top))


## A point on a standard line with whole or √3 parts. to-polar: one on an axis now and then,
## a negative real among them, where a negative modulus is the slip.
static func _special_point(rng: Seeded, s: Dictionary, polar: bool) -> bool:
	var cs := specials()
	if polar and rng.chance(0.2):
		s.c = rng.pick([Q.new(1), Q.new(1), Q.new(1, 2), Q.new(-1, 2)])
	else:
		s.c = rng.pick(cs.filter(func(c): return family(c) != 2))
	s.r = clean_r(rng, s.c)
	return true


## AI Paper 2: whole parts off the standard lines, the argument clear of a 3 s.f. edge; for
## to-cartesian r cis θ with θ to one decimal place.
static func _ai_point(rng: Seeded, s: Dictionary) -> bool:
	if s.ask == "to-polar":
		s.a = nonzero(rng, -7, 7)
		s.b = nonzero(rng, -7, 7)
		if absi(s.a) == absi(s.b):
			return false
		var th := atan2(float(s.b), float(s.a))
		var r := sqrt(float(s.a * s.a + s.b * s.b))
		return Answer.rounds_clearly(th, 0.04) and Answer.rounds_clearly(r, 0.04) and Answer.rounds_clearly(atan(float(s.b) / float(s.a)), 0.04) \
			and Answer.rounds_clearly(float(s.a * s.a + s.b * s.b), 0.04)
	s.rr = rng.int_in(2, 9)
	s.t = Q.new(nonzero(rng, -30, 30), 10)
	var t: float = s.t.to_float()
	if absf(absf(t) - PI / 2.0) < 0.15 or absf(absf(t) - PI) < 0.15 or absf(t) < 0.15:
		return false
	var x: float = s.rr * cos(t)
	var y: float = s.rr * sin(t)
	var dx: float = s.rr * cos(deg_to_rad(t))
	var dy: float = s.rr * sin(deg_to_rad(t))
	for v in [x, y, dx, dy]:
		if not Answer.rounds_clearly(v, 0.04) or absf(v) < 0.05:
			return false
	return absf(absf(x) - absf(y)) > 0.05


## z₁z₂, z₁/z₂ or z₁²: argument-adjust takes an argument past ±π back; the rest may or may not.
static func _polar_product(rng: Seeded, s: Dictionary) -> bool:
	s.mode = rng.pick(["product", "product", "quotient", "quotient", "square"]) if not s.has("ai") else rng.pick(["product", "quotient"])
	var cs := specials()
	s.c = rng.pick(cs)
	s.c2 = rng.pick(cs)
	s.r2 = sd(rng.int_in(2, 5) if s.mode == "quotient" else rng.int_in(1, 4))
	# A quotient's modulus is whole: |z₁| is a multiple of |z₂|.
	s.r = sd(s.r2[0].mul(rng.int_in(2, 3))) if s.mode == "quotient" else sd(rng.int_in(2, 6))
	var raw: Q
	match s.mode:
		"product":
			raw = s.c.add(s.c2)
		"quotient":
			raw = s.c.sub(s.c2)
		_:
			raw = s.c.mul(2)
	s.raw = raw
	var out := principal(raw)
	if out.is_zero() or s.c.eq(s.c2) or s.r[0].eq(s.r2[0]):
		return false
	if s.mode == "quotient" and (s.c2.is_zero() or s.c.eq(s.c2.neg())):
		return false
	var outside := not is_principal(raw)
	if s.angle == "argument-adjust":
		return outside
	return not outside or rng.chance(0.4)


## z₁z₂ or z₁/z₂ in Cartesian form: the answer's argument a standard one and its parts whole.
static func _product_cartesian(rng: Seeded, s: Dictionary) -> bool:
	s.mode = rng.pick(["product", "product", "quotient"])
	var cs := specials()
	s.c = rng.pick(cs)
	s.c2 = rng.pick(cs)
	s.r = sd(rng.int_in(2, 6))
	s.r2 = sd(rng.int_in(1, 3))
	var c: Q = principal(s.c.add(s.c2) if s.mode == "product" else s.c.sub(s.c2))
	var r: Q = s.r[0].mul(s.r2[0]) if s.mode == "product" else s.r[0].div(s.r2[0])
	if not is_special(c) or c.is_zero() or s.c.eq(s.c2) or not r.is_int():
		return false
	var z := cart(sd(r), c)
	return z[0][0].is_int() and z[1][0].is_int()


## A point with whole parts turned through a quarter or half turn, and maybe enlarged.
static func _rotate_point(rng: Seeded, s: Dictionary) -> bool:
	s.z = cx(nonzero(rng, -4, 4), nonzero(rng, -4, 4))
	if absi(s.z[0][0].n) == absi(s.z[1][0].n):
		return false
	if s.has("ai"):
		s.w = rng.pick([cx(0, 1), cx(0, 1), cx(0, -1), cx(0, 2), cx(1, 1), cx(1, -1), cx(-2, 0)])
	else:
		s.c = rng.pick([Q.new(1, 2), Q.new(1, 2), Q.new(-1, 2), Q.new(1)])
		s.k = rng.pick([1, 1, 2, 3])
		s.w = cart(sd(s.k), s.c)
	return true


## z ↦ wz (a rotation and an enlargement about 0), or z ↦ z + w (a translation): the
## translation for the sum methods, the multiplication for the rest.
static func _describe_map(rng: Seeded, s: Dictionary) -> bool:
	if s.angle in ["parallelogram", "vector-add"]:
		s.mode = "translate"
	elif s.angle in ["rotation-enlargement", "polar-reading", "compute-and-plot"]:
		s.mode = "multiply"
	else:
		s.mode = "translate" if rng.chance(0.3) else "multiply"
	if s.mode == "translate":
		s.w = cx(nonzero(rng, -5, 5), nonzero(rng, -5, 5))
		return true
	var cs := specials()
	s.c = rng.pick(cs)
	if s.has("ai"):
		s.c = rng.pick([Q.new(1, 2), Q.new(1, 4), Q.new(-1, 4), Q.new(3, 4), Q.new(1, 3), Q.new(-1, 2), Q.new(2, 3), Q.new(1, 6)])
	s.r = clean_r(rng, s.c, 2) if rng.chance(0.75) else sd(1)
	s.w = cart(s.r, s.c)
	return not s.c.eq(1)


## e^(iα) + e^(iβ) with α − β a third, a half or two thirds of π, so the modulus is √3, √2
## or 1; or 1 + e^(iθ).
static func _euler_sum(rng: Seeded, s: Dictionary) -> bool:
	s.mode = "one" if rng.chance(0.35) else "two"
	var d: Q = rng.pick([Q.new(1, 3), Q.new(1, 2), Q.new(2, 3)])
	if rng.chance(0.5):
		d = d.neg()
	var cs := specials()
	if s.mode == "one":
		s.c = d
		s.c2 = Q.new(0)
	else:
		s.c = rng.pick(cs)
		s.c2 = s.c.sub(d)
		if not is_principal(s.c2) or s.c2.is_zero() or not is_special(s.c2):
			return false
	var mean: Q = s.c.add(s.c2).div(2)
	return not mean.is_zero() and is_principal(mean) and not principal(s.c.add(s.c2)).eq(mean)


## Two numbers on standard lines, one at a multiple of π/6 off the axes and one at an odd
## multiple of π/4, so their product or quotient has an odd multiple of π/12 for its argument.
static func _exact_trig(rng: Seeded, s: Dictionary) -> bool:
	s.mode = rng.pick(["product", "quotient"])
	s.target = rng.pick(["cos", "sin"])
	s.c = rng.pick(specials().filter(func(c): return family(c) == 6))
	s.c2 = rng.pick([Q.new(1, 4), Q.new(-1, 4), Q.new(3, 4), Q.new(-3, 4)])
	s.r = sd(2)
	s.r2 = sd(1, 2)
	var phi := principal(s.c.add(s.c2) if s.mode == "product" else s.c.sub(s.c2))
	s.phi = phi
	return not phi.mul(6).is_int() and not phi.mul(4).is_int()


## (r cis θ)ⁿ with a small modulus, the answer's argument not 0.
static func _power_polar(rng: Seeded, s: Dictionary) -> bool:
	s.c = rng.pick(specials())
	s.r = rng.pick([sd(1), sd(2), sd(2), sd(1, 2), sd(3)])
	s.n = rng.int_in(3, 8 if s.r[0].eq(1) or int(s.r[1]) == 2 else (4 if s.r[0].eq(3) else 6))
	var raw: Q = s.c.mul(s.n)
	s.raw = raw
	var out := principal(raw)
	return not out.is_zero() and not raw.eq(s.c) and not principal(s.c).eq(out)


## (a + bi)ⁿ for a point on a standard line: k(1 ± i), k(√3 ± i), k(1 ± √3 i). A GDC shows
## the answer's parts as decimals, so its cells keep them whole.
static func _power_cartesian(rng: Seeded, s: Dictionary) -> bool:
	s.c = rng.pick(specials().filter(func(c): return family(c) != 2))
	s.r = sd(1, 2) if family(s.c) == 4 else sd(2)
	s.n = rng.int_in(3, 10 if family(s.c) == 4 else 8)
	var out := principal(s.c.mul(s.n))
	if out.is_zero() and rng.chance(0.5):
		return false
	var p := cart(spow(s.r, s.n), out)
	if s.angle in ["gdc-power", "repeated-squaring"]:
		if int(p[0][1]) != 1 or int(p[1][1]) != 1:
			return false
	if s.angle == "repeated-squaring" and s.n not in [4, 8, 3, 6, 5]:
		return false
	return true


## The least n for which zⁿ is real, purely imaginary, a positive or a negative real.
static func _least_power(rng: Seeded, s: Dictionary) -> bool:
	s.c = rng.pick(specials().filter(func(c): return not c.eq(1)))
	s.mode = rng.pick(["real", "real", "imaginary", "positive", "negative"])
	s.r = rng.pick([sd(2), sd(1, 2), sd(3)]) if not s.has("ai") else sd(rng.int_in(2, 5))
	s.form = "polar" if s.has("ai") or rng.chance(0.4) or family(s.c) == 2 else "cartesian"
	if s.form == "cartesian":
		s.r = clean_r(rng, s.c)
	var n := least_n(s.c, s.mode)
	return n > 1


## The least positive n with n·c of the asked kind, or 0 when there is none.
static func least_n(c: Q, mode: String) -> int:
	for n in range(1, 25):
		var v := c.mul(n)
		match mode:
			"real":
				if v.is_int():
					return n
			"imaginary":
				if v.add(Q.new(1, 2)).is_int():
					return n
			"positive":
				if v.is_int() and posmod(v.n, 2) == 0:
					return n
			"negative":
				if v.is_int() and posmod(v.n, 2) == 1:
					return n
	return 0


## zⁿ = w with |w| = ρⁿ, w on a standard line; all-roots in Cartesian form when every root is
## on one too.
static func _nth_roots(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(2, 6) if s.ask == "nth-root" else rng.int_in(2, 4)
	s.rho = rng.int_in(1, 3) if s.n <= 4 else rng.int_in(1, 2)
	if s.rho == 1 and rng.chance(0.6):
		s.rho = 2 if s.n <= 4 else 1
	if s.angle == "factorise":
		s.n = rng.int_in(3, 4)
		s.phi = Q.new(0)
		s.rho = rng.int_in(1, 2)
	else:
		s.phi = rng.pick(specials() + [Q.new(0)])
	s.big = sd(int(pow(s.rho, s.n)))
	s.wform = "cartesian" if rng.chance(0.5) and (s.phi.is_zero() or family(s.phi) == 2 or int(pow(s.rho, s.n)) % 2 == 0) else "polar"
	if s.angle == "factorise":
		s.wform = "cartesian"
	if s.ask == "nth-root":
		s.mode = rng.pick(["least-positive", "greatest", "quadrant"])
		var roots := root_args(s.phi, s.n)
		if s.mode == "quadrant":
			var qs: Array = []
			for c in roots:
				var qd := quadrant(c)
				if qd > 0 and roots.filter(func(o): return quadrant(o) == qd).size() == 1:
					qs.append(qd)
			if qs.is_empty():
				return false
			s.quad = rng.pick(qs)
		return chosen_root(s) != null
	s.out = "cartesian" if root_args(s.phi, s.n).all(func(c): return is_special(c)) and rng.chance(0.5) else "polar"
	if s.angle == "factorise":
		s.out = "cartesian"
	return true


## The arguments of the n roots of zⁿ = |w| cis φ, in −π < θ ≤ π, least first.
static func root_args(phi: Q, n: int) -> Array:
	var out: Array = []
	for k in n:
		out.append(principal(phi.add(Q.new(2 * k)).div(n)))
	out.sort_custom(func(a, b): return a.lt(b))
	return out


## 1 to 4 for a point off the axes, 0 on one.
static func quadrant(c: Q) -> int:
	if c.mul(2).is_int():
		return 0
	if Q.new(0).lt(c):
		return 1 if c.lt(Q.new(1, 2)) else 2
	return 4 if Q.new(-1, 2).lt(c) else 3


## The root the question asks for, as its argument.
static func chosen_root(s: Dictionary) -> Variant:
	var roots := root_args(s.phi, s.n)
	match s.mode:
		"least-positive":
			for c in roots:
				if Q.new(0).lt(c):
					return c
			return null
		"greatest":
			return roots[-1]
	for c in roots:
		if quadrant(c) == s.quad:
			return c
	return null


## The regular polygon the roots of zⁿ = w make: a triangle, square or hexagon.
static func _roots_polygon(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.pick([3, 4, 6])
	s.mode = rng.pick(["side", "area", "perimeter"])
	s.rho = rng.pick([1, 2, 2, 3]) if s.n == 4 else rng.pick([2, 2, 4]) if s.n == 3 else 2
	if s.n == 6 and s.mode == "side":
		s.mode = "area"
	s.phi = rng.pick(specials() + [Q.new(0)])
	s.big = sd(int(pow(s.rho, s.n)))
	s.wform = "polar"
	return int(pow(s.rho, s.n)) <= 256


## cos nθ in powers of cos θ (n = 2 to 5), or sin nθ in powers of sin θ (n = 3 or 5). The
## compound-angle route is only short for n up to 4.
static func _multiple_angle(rng: Seeded, s: Dictionary) -> bool:
	s.fn = "cos" if rng.chance(0.7) else "sin"
	s.n = rng.int_in(2, 5) if s.fn == "cos" else rng.pick([3, 5])
	s.letter = rng.pick(["θ", "x"])
	return s.angle != "compound-angle-route" or s.n <= 4


## A real cubic z³ + az² + bz + d with roots h ± ki and a whole t, t ≠ 0, and no coefficient 0.
static func _cubic(rng: Seeded, s: Dictionary) -> bool:
	s.h = nonzero(rng, -3, 3)
	s.kq = rng.int_in(1, 4)
	s.t = nonzero(rng, -4, 4)
	var m: int = s.h * s.h + s.kq * s.kq
	s.a = -(2 * s.h + s.t)
	s.b = m + 2 * s.h * s.t
	s.d = -s.t * m
	return s.a != 0 and s.b != 0 and s.kq != absi(s.h) and absi(s.t) != m and 2 * s.h != s.a


## A cos(ωt + α) + B cos(ωt + β), the phases in radians, the answer clear of 3 s.f. edges and
## each slip reading differently.
static func _add_sinusoids(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(["cos", "sin"])
	s.amp = rng.int_in(2, 9)
	s.amp2 = rng.int_in(2, 9)
	s.w = rng.int_in(2, 6)
	s.p1 = Q.new(rng.int_in(-12, 12), 10) if rng.chance(0.6) else Q.new(0)
	s.p2 = Q.new(nonzero(rng, -25, 25), 10)
	s.context = rng.pick(["voltage", "wave", "current"])
	var d: float = absf(s.p1.to_float() - s.p2.to_float())
	if d < 0.4 or absf(d - PI) < 0.4 or s.amp == s.amp2:
		return false
	var sum := phasor(s.amp, s.p1.to_float(), s.amp2, s.p2.to_float())
	var deg := phasor(s.amp, deg_to_rad(s.p1.to_float()), s.amp2, deg_to_rad(s.p2.to_float()))
	var avg: float = (s.p1.to_float() + s.p2.to_float()) / 2.0
	for v in [sum[0], sum[1], deg[0], rad_to_deg(deg[1]), avg]:
		if not Answer.rounds_clearly(v, 0.04):
			return false
	return absf(sum[1]) > 0.05 and absf(sum[1] - avg) > 0.05


## A e^(iα) + B e^(iβ) as [modulus, argument].
static func phasor(a: float, p: float, b: float, q: float) -> Array:
	var x := a * cos(p) + b * cos(q)
	var y := a * sin(p) + b * sin(q)
	return [sqrt(x * x + y * y), atan2(y, x)]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
