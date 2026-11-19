class_name InverseRestrictedSituation
extends RefCounted
## The `inverse-restricted` situation (curriculum/question-types.json), FAL-1007: a function
## that needs a restricted domain for an inverse, for fn-ahl-inverse-restricted (AHL2.14).
## The vertex, the side, the phase shift or the constants are picked first; the boundary,
## the branch of the root and the range of f follow, so every answer is exact.
##
## generate() returns, by need.kind:
##   domain    a quadratic A x² + b x + c, or √(x² + b x + c), with vertex (h, k): form
##             ("monic", "scaled" or "root"), A, b, c, h, k, side ("≤": the largest a, "≥":
##             the smallest), roots (the quadratic's rational roots, [] if none), top (f(h))
##   trig      A cos(x − p) + D or A sin(x − p) + D: fn, A, D, p, s (the start of the domain,
##             a turning point), end (s + π), all multiples of π as Q
##   half      A(x − h)² + k on x ≥ h or x ≤ h, written as given (form "vertex") or expanded
##             ("general"): A, b, c, h, k, side
##   selfk     (ax + b)/(x + d) with d = −a, one of a and d the unknown k: a, b, d, slot
##   selfq     a function that is its own inverse or not: form (rat, lin, root, odd, cube),
##             inverse (bool) and its numbers; fixed (a point with f(p) = p, or null), v and
##             ffv (f(f(v)) ≠ v, for a function that is not)
##   meetup    (n x² + c)/m on x ≥ 0, or √((m x − c)/n) on x ≥ c/m, increasing: form ("quad"
##             or "root"), n, m, c, exact, xs (where f meets y = x: Q, or floats when not exact)
##   meetdown  −A x^pw (pw 3 or 5), decreasing: A, pw, exact, s (the meeting points are (0, 0)
##             and (±s, ∓s)), s a Q, or a float when not exact
##
## A calculator method (need.angle "gdc-intersect") gets meeting points that need a GDC (3 s.f.);
## every other question is exact. The clean limits are the checker's too (tools/check_answers.py,
## R9IR_*).

const TRIES := 600
## (kx + 2)/(x − 4), (3x + 1)/(x − 3), x² − 4x + 1 and (x² + 6)/5 are the map's own examples.
const MAP_SELF := [[4, 2, -4], [3, 1, -3]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var paper: int = need.get("paper", 1)
	var gdc: bool = str(need.get("angle", "")) == "gdc-intersect"
	var rep: String = str(need.get("rep", "equation"))
	for i in TRIES:
		var s: Dictionary
		match str(need.get("kind", "domain")):
			"trig":
				s = _trig(rng)
			"half":
				s = _half(rng, rep, bool(need.get("apart", false)))
			"selfk":
				s = _selfk(rng)
			"selfq":
				s = _selfq(rng)
			"meetup":
				s = _meetup(rng, rep, gdc)
			"meetdown":
				s = _meetdown(rng, rep, gdc)
			_:
				s = _domain(rng, rep)
		if not s.is_empty():
			s.paper = paper
			s.kind = str(need.get("kind", "domain"))
			return s
	push_error("InverseRestrictedSituation: no clean situation for %s" % need)
	return {}


static func pick(rng: Seeded, xs: Array) -> Variant:
	return xs[rng.int_in(0, xs.size() - 1)]


# ── Recipes ──────────────────────────────────────────────────

static func _domain(rng: Seeded, rep: String) -> Dictionary:
	var form: String = pick(rng, ["monic", "monic", "scaled", "root"])
	var graph := rep == "graph"
	var h := ExtensionViews.nonzero(rng, -3 if graph else -5, 3 if graph else 5)
	var A: int = 1
	var k: int
	if form == "scaled":
		A = pick(rng, [2, 3, -1, -2] if not graph else [2, -1, -1, -2])
	if form == "root":
		k = pick(rng, [1, 4, 9, 16])
	elif rng.chance(0.5):
		# Roots that come out: k = −A m².
		k = -A * rng.int_in(1, 2) * rng.int_in(1, 2)
		if absi(k) > 8 or k == -A * 2:
			return {}
	else:
		k = rng.int_in(-6, 6)
	var b := -2 * A * h
	var c := A * h * h + k
	if c == 0 or k == h or (graph and absi(c) > 12):
		return {}
	# The map's own example.
	if form == "monic" and b == -4 and c == 1:
		return {}
	var roots: Array = []
	if form != "root":
		var sq := Q.new(-k, A)
		var r := _rational_sqrt(sq)
		if r != null:
			roots = [Q.new(h).sub(r), Q.new(h).add(r)]
	var top: Q = Q.new(k) if form != "root" else Q.new(roundi(sqrt(float(k))))
	return {"form": form, "A": A, "b": b, "c": c, "h": h, "k": k, "side": pick(rng, ["≤", "≥"]), "roots": roots, "top": top}


## √q as a Q when it comes out, else null.
static func _rational_sqrt(q: Q) -> Variant:
	if q.sign() < 0:
		return null
	var n := roundi(sqrt(float(q.n)))
	var d := roundi(sqrt(float(q.d)))
	if n * n == q.n and d * d == q.d:
		return Q.new(n, d)
	return null


static func _trig(rng: Seeded) -> Dictionary:
	var fn: String = pick(rng, ["cos", "cos", "sin"])
	var den: int = pick(rng, [6, 4, 3, 2])
	var p := Q.new(rng.int_in(-den + 1, den), den)
	if p.is_zero():
		return {}
	var A: int = pick(rng, [1, 1, 2, 3, -1, -2])
	var D: int = pick(rng, [0, 0, 1, -1, 2, -3])
	var s := p
	if fn == "sin":
		s = p.add(Q.new(1, 2)) if rng.chance(0.5) else p.sub(Q.new(1, 2))
		if s.is_zero() or not (s.to_float() > -1.0 and s.to_float() <= 1.0):
			return {}
	var end := s.add(1)
	return {"fn": fn, "A": A, "D": D, "p": p, "s": s, "end": end}


static func _half(rng: Seeded, rep: String, apart: bool) -> Dictionary:
	var graph := rep == "graph"
	var form: String = pick(rng, ["vertex", "general", "general"])
	var A: int = pick(rng, [1, 1, 1, 2, 3, -1, -2] if not graph else [1, 1, 2, -1])
	var h := rng.int_in(-4 if graph else -5, 4 if graph else 5)
	var k := rng.int_in(-5, 5)
	if h == k or (h == 0 and k == 0):
		return {}
	if apart and (h == -k):
		return {}
	var b := -2 * A * h
	var c := A * h * h + k
	if form == "general" and A == 1 and b == -4 and c == 1:
		return {}
	return {"form": form, "A": A, "b": b, "c": c, "h": h, "k": k, "side": pick(rng, ["≥", "≤"])}


static func _selfk(rng: Seeded) -> Dictionary:
	var a := ExtensionViews.nonzero(rng, -6, 6)
	var b := ExtensionViews.nonzero(rng, -6, 6)
	var d := -a
	# Not a constant (ad ≠ b), so f(f(x)) = x really needs d = −a; and not the map's examples.
	if a * d == b or absi(a) == 1 and rng.chance(0.5):
		return {}
	if [a, b, d] in MAP_SELF:
		return {}
	var slot: String = pick(rng, ["a", "d"])
	# k + 1 and the slip −k must read apart from b.
	return {"a": a, "b": b, "d": d, "slot": slot}


## f(x) for a selfq rule, exactly; null where it is not defined.
static func selfq_at(s: Dictionary, x: Q) -> Variant:
	match str(s.form):
		"rat":
			var den := x.add(s.d)
			if den.is_zero():
				return null
			return x.mul(s.a).add(s.b).div(den)
		"lin":
			return Q.new(s.c).sub(x)
		"odd":
			return x.mul(s.m)
		"cube":
			return x.mul(x).mul(x)
	return null


static func _selfq(rng: Seeded) -> Dictionary:
	var inverse := rng.chance(0.5)
	var s: Dictionary
	if inverse:
		match rng.int_in(0, 2):
			0:
				var a := ExtensionViews.nonzero(rng, -5, 5)
				var b := ExtensionViews.nonzero(rng, -6, 6)
				if b == -a * a or [a, b, -a] in MAP_SELF:
					return {}
				s = {"form": "rat", "a": a, "b": b, "d": -a}
			1:
				s = {"form": "lin", "c": ExtensionViews.nonzero(rng, -8, 8)}
			_:
				s = {"form": "root", "r": rng.int_in(2, 6)}
		s.inverse = true
		s.fixed = null
		return s
	match rng.int_in(0, 2):
		0:
			# Fixed points p and q: x² + (d − a)x − b = (x − p)(x − q).
			var p := rng.int_in(-4, 4)
			var q := rng.int_in(-4, 4)
			var a := ExtensionViews.nonzero(rng, -4, 4)
			var d := a - (p + q)
			var b := -p * q
			if p == q or b == 0 or d == -a or a * d == b or d == 0:
				return {}
			s = {"form": "rat", "a": a, "b": b, "d": d, "fixed": Q.new(p if p != 0 else q)}
		1:
			s = {"form": "odd", "m": pick(rng, [2, 3, -2, -3, 4]), "fixed": Q.new(0)}
		_:
			s = {"form": "cube", "fixed": Q.new(0)}
	s.inverse = false
	# A value that f(f(v)) moves: whole, with whole steps where possible.
	var best: Variant = null
	for v in [1, 2, -1, 3, -2, 0, 4, -3]:
		var fv: Variant = selfq_at(s, Q.new(v))
		if fv == null:
			continue
		var ffv: Variant = selfq_at(s, fv)
		if ffv == null or ffv.eq(v) or absi(ffv.n) > 999 or ffv.d > 12:
			continue
		if best == null or (fv.is_int() and ffv.is_int() and not (best[1].is_int() and best[2].is_int())):
			best = [Q.new(v), fv, ffv]
		if fv.is_int() and ffv.is_int():
			break
	if best == null:
		return {}
	s.v = best[0]
	s.fv = best[1]
	s.ffv = best[2]
	return s


static func _meetup(rng: Seeded, rep: String, gdc: bool) -> Dictionary:
	var form: String = pick(rng, ["quad", "quad", "root"])
	var graph := rep == "graph"
	if gdc:
		var m := rng.int_in(4, 9)
		var c := rng.int_in(1, m * m / 4)
		var disc := m * m - 4 * c
		var r := roundi(sqrt(float(disc)))
		if disc <= 0 or r * r == disc:
			return {}
		var x1 := (m - sqrt(float(disc))) / 2.0
		var x2 := (m + sqrt(float(disc))) / 2.0
		if not GdcKit.fair(x1) or not GdcKit.fair(x2) or x2 > 8.0:
			return {}
		return {"form": form, "n": 1, "m": m, "c": c, "exact": false, "xs": [x1, x2]}
	var n: int = 1 if graph else pick(rng, [1, 1, 1, 2])
	var xs: Array
	var m: int
	var c: int
	if n == 1:
		var p := rng.int_in(1, 5)
		var q := rng.int_in(p + 1, 6)
		# (x² + 6)/5 is the map's own example.
		if p == 2 and q == 3:
			return {}
		m = p + q
		c = p * q
		xs = [Q.new(p), Q.new(q)]
	else:
		var r: int = pick(rng, [1, 3, 5])
		var q := rng.int_in(1, 5)
		if r == 2 * q:
			return {}
		m = r + 2 * q
		c = r * q
		xs = [Q.new(r, 2), Q.new(q)]
		if xs[0].to_float() > xs[1].to_float():
			xs = [xs[1], xs[0]]
	return {"form": form, "n": n, "m": m, "c": c, "exact": true, "xs": xs}


static func _meetdown(rng: Seeded, rep: String, gdc: bool) -> Dictionary:
	if gdc:
		var A: Q = pick(rng, [Q.new(2), Q.new(3), Q.new(5), Q.new(1, 2), Q.new(1, 3)])
		return {"A": A, "pw": 3, "exact": false, "s": 1.0 / sqrt(A.to_float())}
	var opts: Array = [[Q.new(1), 3, Q.new(1)], [Q.new(1, 4), 3, Q.new(2)], [Q.new(1, 9), 3, Q.new(3)], [Q.new(1, 16), 5, Q.new(2)]]
	if rep != "graph":
		opts += [[Q.new(4), 3, Q.new(1, 2)], [Q.new(9), 3, Q.new(1, 3)], [Q.new(16), 5, Q.new(1, 2)], [Q.new(1), 5, Q.new(1)]]
	var o: Array = pick(rng, opts)
	return {"A": o[0], "pw": o[1], "exact": true, "s": o[2]}


# ── Text ─────────────────────────────────────────────────────

static func N(v: Variant) -> String:
	return Fmt.num(v)


## A x² + b x + c, or its root.
static func domain_rule(s: Dictionary) -> String:
	var quad := Fmt.poly([s.A, s.b, s.c])
	return "√(%s)" % quad if s.form == "root" else quad


## A(x − h)² + k, or A x² + b x + c, as the question gives it.
static func half_rule(s: Dictionary) -> String:
	return Fmt.vertex(s.A, s.h, s.k) if s.form == "vertex" else Fmt.poly([s.A, s.b, s.c])


## A multiple of π as an angle in a bracket: "x − π/4", "x + 2π/3".
static func shift(p: Q) -> String:
	return "x − " + Fmt.pi(p) if p.sign() > 0 else "x + " + Fmt.pi(p.neg())


static func trig_rule(s: Dictionary) -> String:
	var out := "%s%s(%s)" % [Fmt.lead(s.A), s.fn, shift(s.p)]
	if int(s.D) != 0:
		out += Fmt.plus(s.D)
	return out


## The root of the inverse: √(x − k), √((x − k)/A), √(k − x) for A < 0.
static func inv_root(A: int, k: int) -> String:
	var top: String
	if A > 0:
		top = "x" if k == 0 else "x" + Fmt.plus(-k)
	else:
		top = "−x" if k == 0 else "%s − x" % N(k)
	if absi(A) == 1:
		return "√x" if top == "x" else "√(%s)" % top
	return "√((%s)/%d)" % [top, absi(A)]


## h + √(…), h − √(…) or h ± √(…): sign "+", "−" or "±".
static func inv_text(A: int, h: int, k: int, sign: String) -> String:
	var root := inv_root(A, k)
	if h == 0:
		return root if sign == "+" else sign + root
	return "%s %s %s" % [N(h), sign, root]


## The sign of the root on the inverse: + on x ≥ h, − on x ≤ h.
static func branch(s: Dictionary) -> String:
	return "+" if s.side == "≥" else "−"


## (ax + b)/(x + d), with "k" for the unknown slot.
static func rat_text(a: Variant, b: Variant, d: Variant) -> String:
	var top: String = ("kx" + Fmt.plus(b)) if str(a) == "k" else Fmt.poly([a, b])
	var bottom: String = "x + k" if str(d) == "k" else Fmt.poly([1, d])
	return "(%s)/(%s)" % [top, bottom]


static func selfq_rule(s: Dictionary) -> String:
	match str(s.form):
		"rat":
			return "f(x) = %s, x ≠ %s" % [rat_text(s.a, s.b, s.d), N(-int(s.d))]
		"lin":
			return "f(x) = %s − x" % N(s.c)
		"root":
			return "f(x) = √(%d − x²), 0 ≤ x ≤ %d" % [int(s.r) * int(s.r), s.r]
		"odd":
			return "f(x) = %sx" % Fmt.lead(s.m)
		"cube":
			return "f(x) = x³"
	return "?"


## (n x² + c)/m, or √(m x − c) (n = 1) and √((m x − c)/2).
static func meetup_rule(s: Dictionary) -> String:
	if s.form == "quad":
		return "f(x) = (%s)/%d, x ≥ 0" % [Fmt.poly([s.n, 0, s.c]), s.m]
	var inside := Fmt.poly([s.m, -int(s.c)])
	var root := "√(%s)" % inside if int(s.n) == 1 else "√((%s)/%d)" % [inside, s.n]
	return "f(x) = %s, x ≥ %s" % [root, N(Q.new(s.c, s.m))]


## −A x^pw: "−4x³", "−(1/9)x³", "−x⁵".
static func meetdown_rule(s: Dictionary) -> String:
	return "f(x) = %sx%s" % [Fmt.lead(Q.of(s.A).neg()), Fmt.sup(s.pw)]


## The inverse of −A x^pw: −(x/A)^(1/pw), written so a fraction A reads as a product.
static func meetdown_inverse(s: Dictionary) -> String:
	var A: Q = Q.of(s.A)
	var inner: String
	if A.eq(1):
		return "−x^(1/%d)" % int(s.pw)
	if A.is_int():
		inner = "x/%s" % N(A)
	elif A.n == 1:
		inner = "%sx" % N(A.d)
	else:
		inner = "%sx/%s" % [N(A.d), N(A.n)]
	return "−(%s)^(1/%d)" % [inner, int(s.pw)]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
