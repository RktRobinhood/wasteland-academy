class_name RationalFunctionSituation
extends RefCounted
## The `rational-function` situation (curriculum/question-types.json): one
## linear-over-linear function in all its forms (FAL-423). The asymptotes and the stretch
## are picked first, so f(x) = (ax + b)/(cx + d) = A + B/(x − h) has every asymptote,
## intercept and branch known before anything is hidden.
##
## generate() returns:
##   a, b, c, d   the coefficients, whole numbers (c = 1, 2 or 3; ad − bc ≠ 0)
##   h, A, B      Q: the vertical asymptote x = h = −d/c, the horizontal one y = A = a/c, and
##                the stretch B = (bc − ad)/c², so f(x) = A + B/(x − h)
##   xi, yi       Q: the x-intercept −b/a and the y-intercept b/d (never none: a, d ≠ 0)
##   paper        1 (exact numbers) or 2 (a, b, c, d that need a calculator: every
##                asymptote and intercept is a decimal that does not end)
## and, where the view's need asks for it:
##   line    m, n (whole), lcount (0, 1 or 2): y = mx + n meets f that many times, 1 when it
##           is a tangent
##   curve   p, q, r (whole): the parabola y = px² + qx + r, ccount (its meeting points with
##           f), dom ("" or "x > 0"/"x < 0": ccount then counts that part only) and count_all
##   hline   hk (Q, whole): the line y = hk, hequal when hk = A
##   ineq    rel (one of > < ≥ ≤) and k (Q): f(x) rel k; k is 0, or a value whose boundary
##           h + t is a whole number (k_zero: always 0)
##   parent  pk: the 1, 2 or 3 of y = pk/x
##
## need: mode "split" (f = A + k/(cx + d) with A, k whole, c = 2 or 3: kk is k), "monic" (c = 1, the default), "scaled" (c = 2 or 3), "any" (either, mostly monic); graph
## (monic, h, A and both intercepts whole and inside the plot); card (graph, and A ≠ h so the
## swapped graph is another one); no_origin (b ≠ 0); line, curve, hline, ineq, parent;
## k_nonzero (ineq); paper (1 or 2).
##
## The clean limits are the checker's too (tools/check_answers.py, RF_*).

const TRIES := 6000
## Paper 1 intercepts are whole numbers, halves or thirds.
const DEN_MAX := 3
const PLOT := 6


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var paper: int = need.get("paper", 0)
	for i in TRIES:
		var s := _draw(rng, need, paper)
		if s.is_empty():
			continue
		if need.get("line", false) and not _line(rng, s):
			continue
		if need.get("curve", false) and not _curve(rng, s):
			continue
		if need.get("hline", false):
			var equal: bool = rng.chance(0.5) and s.A.is_int()
			var k: int = s.A.n if equal else rng.int_in(-5, 5)
			if not equal and s.A.eq(k):
				continue
			s.hk = Q.new(k)
			s.hequal = equal
		if need.get("ineq", false) and not _ineq(rng, s, need):
			continue
		if need.get("parent", false):
			s.pk = rng.int_in(1, 3)
		s.paper = 2 if paper == 2 else 1
		return s
	push_error("RationalFunctionSituation: no clean situation for %s" % need)
	return {}


static func _nonzero(rng: Seeded, lo: int, hi: int) -> int:
	var v := 0
	while v == 0:
		v = rng.int_in(lo, hi)
	return v


## The Q parts of f from its coefficients.
static func _fill(a: int, b: int, c: int, d: int) -> Dictionary:
	var h := Q.new(-d, c)
	var A := Q.new(a, c)
	return {"a": a, "b": b, "c": c, "d": d, "h": h, "A": A, "B": Q.new(b * c - a * d, c * c), "xi": Q.new(-b, a), "yi": Q.new(b, d)}


static func _draw(rng: Seeded, need: Dictionary, paper: int) -> Dictionary:
	var graph: bool = need.get("graph", false) or need.get("card", false)
	if paper == 2:
		return _draw_paper2(rng, graph)
	if need.get("mode", "") == "split":
		return _draw_split(rng)
	var mode: String = need.get("mode", "monic")
	if graph:
		mode = "monic"
	elif mode == "any":
		mode = "scaled" if rng.chance(0.3) else "monic"
	var s := {}
	if mode == "scaled":
		var c := rng.int_in(2, 3)
		var a := _nonzero(rng, -7, 7)
		var d := _nonzero(rng, -7, 7)
		var b := rng.int_in(-7, 7) if not need.get("no_origin", false) else _nonzero(rng, -7, 7)
		if a * d == b * c or Q.gcd(Q.gcd(absi(a), absi(b)), Q.gcd(c, absi(d))) != 1:
			return {}
		s = _fill(a, b, c, d)
	else:
		var A := _nonzero(rng, -3, 3)
		var h := _nonzero(rng, -4, 4)
		var B := _nonzero(rng, -4, 4)
		if not need.get("no_origin", false) and not graph and rng.chance(0.1):
			B = A * h
		if B == A * h and (need.get("no_origin", false) or graph):
			return {}
		s = _fill(A, B - A * h, 1, -h)
	if s.xi.d > DEN_MAX or s.yi.d > DEN_MAX:
		return {}
	if graph and not (s.xi.is_int() and s.yi.is_int() and absi(s.xi.n) <= PLOT and absi(s.yi.n) <= PLOT and s.b != 0):
		return {}
	if need.get("card", false) and s.A.eq(s.h):
		return {}
	return s


## f = A + k/(cx + d) with A, k, d whole and c = 2 or 3, so f = (Acx + (Ad + k))/(cx + d)
## splits as a whole number plus a whole-number fraction (fn-ext-transformed-reciprocal's
## split-scaled). kk is that k. The intercepts are not limited: it is an extension type.
static func _draw_split(rng: Seeded) -> Dictionary:
	var c := rng.int_in(2, 3)
	var A := _nonzero(rng, -4, 4)
	var kk := _nonzero(rng, -5, 5)
	var d := _nonzero(rng, -5, 5)
	var a := A * c
	var b := A * d + kk
	if Q.gcd(Q.gcd(absi(a), absi(b)), Q.gcd(c, absi(d))) != 1 or b == 0 or a * d == b * c:
		return {}
	var s := _fill(a, b, c, d)
	s.kk = Q.new(kk)
	return s


## Paper 2: a, b, c, d that need a calculator, so each asymptote and intercept is a decimal
## that does not end and rounds clearly to 3 s.f. A graph (the reciprocal's card) keeps
## the asymptotes and intercepts inside the plot instead.
static func _draw_paper2(rng: Seeded, graph: bool) -> Dictionary:
	var c := rng.int_in(2, 3 if graph else 9)
	var a := _nonzero(rng, -8 if graph else -12, 8 if graph else 12)
	var d := _nonzero(rng, -8 if graph else -12, 8 if graph else 12)
	var b := _nonzero(rng, -8 if graph else -12, 8 if graph else 12)
	if absi(a) < 2 or absi(d) < 2 or absi(b) < 2 or a * d == b * c:
		return {}
	var s := _fill(a, b, c, d)
	if graph:
		for q in [s.h, s.A]:
			if absf(q.to_float()) > 4.0:
				return {}
		return s if absf(s.xi.to_float()) <= PLOT and absf(s.yi.to_float()) <= PLOT else {}
	for q in [s.h, s.A, s.xi, s.yi]:
		var x: float = q.to_float()
		if not Answer.needs_rounding(q) or not Answer.rounds_clearly(x) or absf(x) > 99.0 or absf(x) < 0.05:
			return {}
	return s


## y = mx + n against f: (mx + n)(cx + d) = ax + b is mc x² + (md + nc − a)x + (nd − b) = 0.
## The meeting points (and a tangent's touching point) are inside the plot.
static func _line(rng: Seeded, s: Dictionary) -> bool:
	var want := rng.int_in(0, 3)
	want = [0, 1, 2, 2][want]
	var tries: Array = []
	for m in [-2, -1, 1, 2]:
		for n in range(-5, 6):
			tries.append([m, n])
	for pair in rng.shuffled(tries):
		var m: int = pair[0]
		var n: int = pair[1]
		var qa: int = m * s.c
		var qb: int = m * s.d + n * s.c - s.a
		var qc: int = n * s.d - s.b
		var disc := qb * qb - 4 * qa * qc
		var count := 2 if disc > 0 else (1 if disc == 0 else 0)
		if count != want:
			continue
		var ok := true
		if count > 0:
			for sign in ([-1, 1] if count == 2 else [0]):
				var x: float = (-qb + sign * sqrt(float(disc))) / (2.0 * qa)
				if absf(x) > 7.0 or absf(m * x + n) > 7.0 or absf(x - s.h.to_float()) < 0.2:
					ok = false
		if ok:
			s.m = m
			s.n = n
			s.lcount = count
			return true
	return false


## y = px² + qx + r against f: the cubic (px² + qx + r)(cx + d) − (ax + b) = 0, whose real
## roots are counted exactly (its discriminant) and found again numerically. dom limits
## the count to one side of x = 0 where that changes it.
static func _curve(rng: Seeded, s: Dictionary) -> bool:
	var p: int = [-1, 1][rng.int_in(0, 1)]
	var q := rng.int_in(-4, 4)
	var r := rng.int_in(-5, 5)
	var c3: int = p * s.c
	var c2: int = p * s.d + q * s.c
	var c1: int = q * s.d + r * s.c - s.a
	var c0: int = r * s.d - s.b
	var disc := 18 * c3 * c2 * c1 * c0 - 4 * c2 * c2 * c2 * c0 + c2 * c2 * c1 * c1 - 4 * c3 * c1 * c1 * c1 - 27 * c3 * c3 * c0 * c0
	if disc == 0:
		return false
	var f := func(x: float) -> float: return ((c3 * x + c2) * x + c1) * x + c0
	var roots := GdcKit.zeros(f, -12.0, 12.0, 2400)
	var want := 3 if disc > 0 else 1
	if roots.size() != want:
		return false
	for x in roots:
		var y: float = p * x * x + q * x + r
		if absf(x) > 7.0 or absf(y) > 7.0 or absf(x - s.h.to_float()) < 0.2 or absf(x) < 0.25:
			return false
	var dom := ""
	var count: int = roots.size()
	if rng.chance(0.4):
		dom = "x > 0" if rng.chance(0.5) else "x < 0"
		count = roots.filter(func(x): return x > 0.0 if dom == "x > 0" else x < 0.0).size()
		if count == roots.size():
			dom = ""
	s.p = p
	s.q = q
	s.r = r
	s.dom = dom
	s.ccount = count
	s.count_all = roots.size()
	return true


## f(x) rel k, with the boundary of k at a whole number: k = A + B/t for a whole t that
## divides B (so the boundary h + t is whole), or 0.
static func _ineq(rng: Seeded, s: Dictionary, need: Dictionary) -> bool:
	s.rel = [">", "<", "≥", "≤"][rng.int_in(0, 3)]
	s.k = Q.new(0)
	if not need.get("k_zero", false) and (need.get("k_nonzero", false) or rng.chance(0.3)):
		if not s.B.is_int() or s.c != 1:
			return false
		var t := _nonzero(rng, -3, 3)
		if s.B.n % t != 0:
			return false
		s.k = s.A.add(s.B.div(Q.new(t)))
		s.t = t
		if s.k.is_zero() or not s.k.is_int():
			return false
	return true


# ── Writing f ────────────────────────────────────────────────

## The coefficients' fraction: "(3x − 2)/(x − 2)", "x/(2x + 1)".
static func frac(a: Variant, b: Variant, c: Variant, d: Variant) -> String:
	return "%s/%s" % [_wrap(Fmt.poly([a, b])), _wrap(Fmt.poly([c, d]))]


static func _wrap(t: String) -> String:
	return t if not " " in t else "(%s)" % t


static func text(s: Dictionary) -> String:
	return frac(s.a, s.b, s.c, s.d)


## f in the form A + B/(x − h): "3 + 2/(x − 2)", "−1 − 4/(x + 3)".
static func split(A: Variant, B: Variant, h: Variant) -> String:
	var aq := Q.of(A)
	var bq := Q.of(B)
	var base := "" if aq.is_zero() else aq.text()
	var den := "x" if Q.of(h).is_zero() else "x %s %s" % ["+" if Q.of(h).sign() < 0 else "−", Q.of(h).abs_q().text()]
	var head := "" if base == "" else base + (" − " if bq.sign() < 0 else " + ")
	if base == "":
		head = "−" if bq.sign() < 0 else ""
	return "%s%s/(%s)" % [head, bq.abs_q().text(), den]


## f(x) as a float (NAN at the asymptote).
static func y_at(s: Dictionary, x: float) -> float:
	var den: float = s.c * x + s.d
	return NAN if den == 0.0 else (s.a * x + s.b) / den


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
