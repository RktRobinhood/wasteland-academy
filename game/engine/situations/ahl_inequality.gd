class_name AhlInequalitySituation
extends RefCounted
## The `ahl-inequality` situation (curriculum/question-types.json), for fn-ahl-inequalities
## (FAL-1008): an inequality g(x) ≥ f(x), solved from the critical values of h = g − f (its
## zeros and, for a rational h, its vertical asymptote). The critical values are picked
## first and the functions built around them, so every solution set is known exactly (whole
## numbers or simple fractions) or found on the GDC and written to 3 s.f.
##
## need.form picks the family; generate() returns {"form", "rel", ...} with
##   cubic3  a(x − p)(x − q)(x − r) rel 0:  a (±1, ±2), roots [p, q, r] (whole, in order)
##   kx      x³ rel k²x:  k (2 to 6), swap (written k²x rel′ x³)
##   factor  the expanded a(x − p)(x − q)(x − r) rel 0 with (x − p) given:  a, p, roots [3]
##   double  (x − p)(x − q)² rel 0:  p, q, first ("p" or "q": which factor is written first);
##           rel always keeps the side of q away from p, so the repeated root matters
##   graphs  a curve f and a line g(x) = m(x − z) crossing at whole xs; f = g + c·Π(x − xᵢ):
##           m, z, c, xs (2 or 3), rel (the question is g(x) rel f(x))
##   band    f(x) = a(x − h)² + k and one or two lines y = k + a·d²:  a, h, k, ds, rel
##           (two lines: lo rel f(x) rel hi, rel "<" or "≤")
##   tech    an exponential or log against a line, its crossings from the GDC:  fam ("exp":
##           A·e^(sx), s = ±1 or ±1/2; "ln": A·ln(x + d)), the line m, n (Q), xs (floats)
##   ratk    (ax + b)/(x − c) rel k:  a, b, c, k, x0 (Q, the crossing)
##   ratl    (ax + b)/(x − c) rel mx + n:  a, b, c, m, n, xs (the crossings: Q on Paper 1,
##           floats on Paper 2), exact
##   models  two models for t ≥ 0:  fam "poly" (A(t) = p + qt, B(t) = A(t) + cc(t + r)(s − t))
##           or "exp" (A(t) = P·g^t, B(t) = p + qt); who ("A" or "B": the one asked to
##           exceed), ts (the crossings, one negative), names
##   whole   a formula in n and a target:  fam ("grow", "decay", "quad"), its numbers, nstar
##           (the crossing, a float) and n (the least whole number)
## Every form keeps `paper`. The checker's own copy of these limits is in
## tools/check_answers.py (AHLINEQ_*).

const TRIES := 4000
const RELS := [">", "≥", "<", "≤"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var paper: int = 2 if int(need.get("paper", 1)) == 2 else 1
	var form: String = need.get("form", "cubic3")
	for i in TRIES:
		var s := _make(form, rng, need, paper)
		if s.is_empty():
			continue
		s.form = form
		s.paper = paper
		return s
	push_error("AhlInequalitySituation: no clean situation for %s" % need)
	return {}


static func _make(form: String, rng: Seeded, need: Dictionary, paper: int) -> Dictionary:
	match form:
		"cubic3":
			return _cubic3(rng, need, paper)
		"kx":
			return _kx(rng, need, paper)
		"factor":
			return _factor(rng, need, paper)
		"double":
			return _double(rng, need, paper)
		"graphs":
			return _graphs(rng, need, paper)
		"band":
			return _band(rng, need, paper)
		"tech":
			return _tech(rng, need, paper)
		"ratk":
			return _ratk(rng, need, paper)
		"ratl":
			return _ratl(rng, need, paper)
		"models":
			return _models(rng, need, paper)
		"whole":
			return _whole(rng, need, paper)
	return {}


static func strict(rel: String) -> bool:
	return rel == ">" or rel == "<"


static func flip_ends(rel: String) -> String:
	return {">": "≥", "≥": ">", "<": "≤", "≤": "<"}[rel]


## The opposite inequality: where rel fails.
static func opposite(rel: String) -> String:
	return {">": "≤", "≥": "<", "<": "≥", "≤": ">"}[rel]


static func F(v: Variant) -> float:
	return v.to_float() if v is Q else float(v)


static func cubic_at(a: Variant, roots: Array, x: float) -> float:
	var y := F(a)
	for r in roots:
		y *= x - F(r)
	return y


# ── Cubics ───────────────────────────────────────────────────

static func _cubic3(rng: Seeded, need: Dictionary, _paper: int) -> Dictionary:
	var a: int = rng.pick([1, 1, -1, -1, 2, -2])
	var rs: Array = []
	while rs.size() < 3:
		var r := rng.int_in(-5, 5)
		if not r in rs:
			rs.append(r)
	rs.sort()
	if need.get("graph", false):
		if rs[1] - rs[0] < 2 or rs[2] - rs[1] < 2 or rs[2] - rs[0] > 8:
			return {}
		if _peak(a, rs) > 40.0:
			return {}
	return {"a": a, "roots": rs, "rel": rng.pick(RELS)}


## The largest |f| between the outer roots.
static func _peak(a: Variant, rs: Array) -> float:
	var top := 0.0
	var lo := F(rs[0])
	var hi := F(rs[rs.size() - 1])
	for j in 101:
		top = maxf(top, absf(cubic_at(a, rs, lo + (hi - lo) * j / 100.0)))
	return top


static func _kx(rng: Seeded, _need: Dictionary, _paper: int) -> Dictionary:
	return {"k": rng.int_in(2, 6), "rel": rng.pick(RELS), "swap": rng.chance(0.3)}


static func _factor(rng: Seeded, _need: Dictionary, _paper: int) -> Dictionary:
	var a: int = rng.pick([1, 1, -1, -1, 2, -2])
	var rs: Array = []
	while rs.size() < 3:
		var r := ExtensionViews.nonzero(rng, -5, 5)
		if not r in rs:
			rs.append(r)
	var p: int = rs[0]
	var c := coeffs(a, rs)
	for v in c:
		if absi(v) > 60:
			return {}
	if c[1] == 0 or c[2] == 0:
		return {}
	rs.sort()
	return {"a": a, "p": p, "roots": rs, "coeffs": c, "rel": rng.pick(RELS)}


## a(x − p)(x − q)(x − r) expanded: [a, b, c, d].
static func coeffs(a: int, rs: Array) -> Array:
	var p: int = rs[0]
	var q: int = rs[1]
	var r: int = rs[2]
	return [a, -a * (p + q + r), a * (p * q + p * r + q * r), -a * p * q * r]


static func _double(rng: Seeded, need: Dictionary, _paper: int) -> Dictionary:
	var p := rng.int_in(-5, 5)
	var q := rng.int_in(-5, 5)
	if p == q:
		return {}
	if need.get("graph", false):
		if absi(p - q) < 2 or absi(p - q) > 6 or _peak(1, [p, q, q]) > 40.0:
			return {}
	# (x − p)(x − q)² has the sign of x − p. Beyond q (away from p) that is the sign of q − p,
	# and the inequality asked keeps that side.
	var rel: String = rng.pick([">", "≥"] if q > p else ["<", "≤"])
	return {"p": p, "q": q, "rel": rel, "first": rng.pick(["p", "q"])}


# ── Two graphs ───────────────────────────────────────────────

static func _graphs(rng: Seeded, _need: Dictionary, _paper: int) -> Dictionary:
	var n := 2 if rng.chance(0.65) else 3
	var xs: Array = []
	while xs.size() < n:
		var x := rng.int_in(-3, 3) if n == 3 else rng.int_in(-4, 4)
		if not x in xs:
			xs.append(x)
	xs.sort()
	for i in n - 1:
		if xs[i + 1] - xs[i] < 2:
			return {}
	var m: int = rng.pick([1, -1, 2, -2])
	var z := rng.int_in(-3, 3)
	if z in xs:
		return {}
	var c: int = rng.pick([1, -1])
	var s := {"m": m, "z": z, "c": c, "xs": xs, "rel": rng.pick(RELS)}
	for x in xs:
		if absi(m * (x - z)) > 8:
			return {}
	# The heights at the crossings differ from the crossings themselves, so reading them
	# for the x-values gives another set.
	var hs: Array = xs.map(func(x): return m * (x - z))
	hs.sort()
	if hs == xs:
		return {}
	if _peak(c, xs) > 10.0:
		return {}
	return s


static func graph_f(s: Dictionary, x: float) -> float:
	return graph_g(s, x) + cubic_at(s.c, s.xs, x)


static func graph_g(s: Dictionary, x: float) -> float:
	return s.m * (x - s.z)


static func _band(rng: Seeded, _need: Dictionary, _paper: int) -> Dictionary:
	var a: int = rng.pick([1, -1])
	var h := rng.int_in(-3, 3)
	var k := rng.int_in(-4, 4)
	var ds: Array = []
	var rel: String
	if rng.chance(0.5):
		ds = [rng.int_in(1, 3)]
		rel = rng.pick(RELS)
	else:
		var d1 := rng.int_in(1, 2)
		var d2 := rng.int_in(d1 + 1, 3)
		ds = [d1, d2]
		rel = rng.pick(["<", "≤"])
	for d in ds:
		var c: int = k + a * d * d
		if absi(c) > 10 or c == 0:
			return {}
	# The lines' heights read as x-values give another set.
	return {"a": a, "h": h, "k": k, "ds": ds, "rel": rel}


static func band_f(s: Dictionary, x: float) -> float:
	return s.a * (x - s.h) * (x - s.h) + s.k


# ── On the GDC ───────────────────────────────────────────────

static func _tech(rng: Seeded, need: Dictionary, _paper: int) -> Dictionary:
	var fam: String = rng.pick(["exp", "ln"])
	var s := {"fam": fam}
	if fam == "exp":
		s.A = rng.pick([1, 2, 3])
		s.sx = rng.pick([Q.new(1), Q.new(1, 2), Q.new(-1), Q.new(-1, 2)])
		s.m = Q.new(rng.int_in(-3, 3))
		if s.m.is_zero():
			return {}
		s.n = Q.new(rng.int_in(1, 7))
		# A·e^(sx) − (mx + n) is convex: above the line outside the crossings.
		s.rel = rng.pick([">", "≥", ">", "≥", ">", "≥", "<", "≤"])
	else:
		s.A = rng.pick([1, 2, 3])
		s.d = rng.pick([0, 1, 2])
		s.m = rng.pick([Q.new(1, 2), Q.new(1), Q.new(2)])
		s.n = Q.new(rng.int_in(-3, 2))
		# A·ln(x + d) is concave: below the line outside the crossings.
		s.rel = rng.pick(["<", "≤", "<", "≤", "<", "≤", ">", "≥"])
	var lo := -8.0 if fam == "exp" else -float(s.d) + 1e-6
	var xs := GdcKit.zeros(func(x: float) -> float: return tech_h(s, x), lo, 8.0, 800)
	if xs.size() != 2:
		return {}
	for x in xs:
		if not GdcKit.fair(x):
			return {}
	if xs[1] - xs[0] < 0.8:
		return {}
	if fam == "ln" and xs[0] < -float(s.d) + 0.08:
		return {}
	# Both crossings sit on a readable screen, for the graph and the GDC alike.
	for x in xs:
		if absf(tech_f(s, x)) > 12.0:
			return {}
	s.xs = xs
	return s


static func tech_f(s: Dictionary, x: float) -> float:
	if s.fam == "exp":
		return s.A * exp(s.sx.to_float() * x)
	return s.A * log(x + s.d) if x + s.d > 0.0 else NAN


static func tech_line(s: Dictionary, x: float) -> float:
	return s.m.to_float() * x + s.n.to_float()


## f − line, the difference whose sign the inequality asks for.
static func tech_h(s: Dictionary, x: float) -> float:
	return tech_f(s, x) - tech_line(s, x)


# ── Rational functions ───────────────────────────────────────

static func _ratk(rng: Seeded, need: Dictionary, _paper: int) -> Dictionary:
	var a := ExtensionViews.nonzero(rng, -3, 3)
	var b := ExtensionViews.nonzero(rng, -9, 9)
	var c := rng.int_in(-4, 4)
	var k := rng.int_in(-4, 4)
	if k == a or a * c + b == 0:
		return {}
	var x0 := Q.new(k * c + b, k - a)
	if x0.d > 6 or absf(x0.to_float()) > 7.0 or absf(x0.to_float() - c) < 1.0:
		return {}
	if need.get("graph", false) and (absi(a) > 5 or absi(k) > 6 or absi(k - a) < 1):
		return {}
	return {"a": a, "b": b, "c": c, "k": k, "x0": x0, "rel": rng.pick(RELS)}


static func ratk_y(s: Dictionary, x: float) -> float:
	return (s.a * x + s.b) / (x - s.c)


static func _ratl(rng: Seeded, need: Dictionary, paper: int) -> Dictionary:
	var m: int = rng.pick([1, -1, 1, -1, 2, -2])
	var n := rng.int_in(-4, 4)
	var c := rng.int_in(-4, 4)
	var s := {"m": m, "n": n, "c": c, "rel": rng.pick(RELS), "exact": paper == 1}
	if paper == 1:
		var r1 := rng.int_in(-5, 5)
		var r2 := rng.int_in(-5, 5)
		if r1 == r2 or r1 == c or r2 == c:
			return {}
		s.a = m * (r1 + r2) - m * c + n
		s.b = -m * r1 * r2 - n * c
		s.xs = [Q.new(mini(r1, r2)), Q.new(maxi(r1, r2))]
	else:
		s.a = rng.int_in(-6, 6)
		s.b = rng.int_in(-12, 12)
		# N(x) = −mx² + (a + mc − n)x + (b + nc), the numerator of f − line.
		var A := -m
		var B: int = s.a + m * c - n
		var C: int = s.b + n * c
		var D := B * B - 4 * A * C
		if D <= 0:
			return {}
		var rt := int(sqrt(float(D)))
		if rt * rt == D or (rt + 1) * (rt + 1) == D:
			return {}
		var x1 := (-B - sqrt(float(D))) / (2.0 * A)
		var x2 := (-B + sqrt(float(D))) / (2.0 * A)
		var xs := [minf(x1, x2), maxf(x1, x2)]
		for x in xs:
			if not GdcKit.fair(x) or absf(x - c) < 0.3 or absf(x) > 7.0:
				return {}
		s.xs = xs
	if s.a == 0 or absi(s.a) > 6 or absi(s.b) > 12 or s.a * c + s.b == 0:
		return {}
	if F(s.xs[1]) - F(s.xs[0]) < 0.5:
		return {}
	if need.get("graph", false):
		for x in s.xs:
			if absf(F(x)) > 6.5 or absf(m * F(x) + n) > 7.0:
				return {}
		if absi(c) > 5:
			return {}
	return s


static func ratl_y(s: Dictionary, x: float) -> float:
	return (s.a * x + s.b) / (x - s.c)


static func ratl_line(s: Dictionary, x: float) -> float:
	return s.m * x + s.n


## The numerator of f − line over x − c: −mx² + (a + mc − n)x + (b + nc).
static func ratl_num(s: Dictionary) -> Array:
	return [-s.m, s.a + s.m * s.c - s.n, s.b + s.n * s.c]


# ── In context ───────────────────────────────────────────────

static func _models(rng: Seeded, need: Dictionary, paper: int) -> Dictionary:
	var angle: String = need.get("angle", "")
	var poly := angle == "algebraic-polynomial-model" or (angle != "gdc-intersections-context" and paper == 1)
	var s := {"who": rng.pick(["A", "B"]), "ctx": rng.int_in(0, 2)}
	if poly:
		s.fam = "poly"
		var r := rng.int_in(1, 4)
		var t := rng.int_in(5, 12)
		var cc: int = rng.pick([1, 2])
		var p := rng.int_in(20, 60)
		var q := rng.int_in(2, 8)
		s.p = p
		s.q = q
		s.cc = cc
		s.r = r
		s.s = t
		# B(t) = p + qt + cc(rs + (s − r)t − t²).
		s.B = [-cc, q + cc * (t - r), p + cc * r * t]
		if s.B[1] <= 0:
			return {}
		s.ts = [Q.new(-r), Q.new(t)]
	else:
		s.fam = "exp"
		var P := rng.int_in(10, 40)
		var g := Q.new(rng.int_in(105, 130), 100)
		var p := rng.int_in(P + 5, P + 40)
		var q := rng.int_in(2, 9)
		s.P = P
		s.g = g
		s.p = p
		s.q = q
		var ts := GdcKit.zeros(func(x: float) -> float: return models_h(s, x), -40.0, 60.0, 1000)
		if ts.size() != 2 or ts[0] >= -0.3 or ts[1] <= 0.5 or ts[1] > 40.0:
			return {}
		for x in ts:
			if not GdcKit.fair(x):
				return {}
		if not GdcKit.fair(models_a(s, ts[1])):
			return {}
		s.ts = ts
	return s


static func models_a(s: Dictionary, t: float) -> float:
	if s.fam == "poly":
		return s.p + s.q * t
	return s.P * pow(s.g.to_float(), t)


static func models_b(s: Dictionary, t: float) -> float:
	if s.fam == "poly":
		return s.B[0] * t * t + s.B[1] * t + s.B[2]
	return s.p + s.q * t


## A − B: negative between the crossings.
static func models_h(s: Dictionary, t: float) -> float:
	return models_a(s, t) - models_b(s, t)


static func _whole(rng: Seeded, _need: Dictionary, _paper: int) -> Dictionary:
	var fam: String = rng.pick(["grow", "decay", "quad"])
	var s := {"fam": fam}
	var nstar: float
	match fam:
		"grow":
			s.P = rng.int_in(10, 50) * 100
			s.r = Q.new(rng.int_in(102, 109), 100)
			s.T = s.P * rng.int_in(13, 25) / 10
			nstar = log(float(s.T) / s.P) / log(s.r.to_float())
		"decay":
			s.P = rng.int_in(20, 80) * 10
			s.r = Q.new(rng.int_in(75, 95), 100)
			s.T = rng.int_in(2, 8) * 10
			if s.T * 2 > s.P:
				return {}
			nstar = log(float(s.T) / s.P) / log(s.r.to_float())
		_:
			s.b = rng.int_in(1, 9)
			s.T = rng.int_in(20, 90) * 10
			# n² + bn = T at n = (−b + √(b² + 4T))/2.
			nstar = (-s.b + sqrt(float(s.b * s.b + 4 * s.T))) / 2.0
	var frac := nstar - floorf(nstar)
	if frac < 0.1 or frac > 0.9 or nstar < 3.0 or nstar > 60.0 or not GdcKit.fair(nstar):
		return {}
	s.nstar = nstar
	s.n = int(ceilf(nstar))
	return s


static func whole_at(s: Dictionary, n: float) -> float:
	if s.fam == "quad":
		return n * n + s.b * n
	return s.P * pow(s.r.to_float(), n)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
