class_name BasicOneToOneSituation
extends RefCounted
## The `basic-one-to-one` situation (curriculum/question-types.json), which extends
## basic-function: a one-to-one function with key points on grid points, so its inverse
## comes from swapping coordinates (FAL-424). fn-inverse-reflection is built on it.
##
## generate() returns, by need.kind:
##   curve     a line, a root, an exponential or half a parabola: f, form, keys [[x, y]] (grid
##             points on it), p, q (one of them, off y = x and off the axes), lo, hi (its stretch)
##   area      a·x² for x ≥ 0: a, m (it meets y = x at (m, m)), area (between f and f⁻¹)
##   table     a line with a value a among its outputs and its inputs: f, xs, a, inv
##   rule      a rule and a value: f, a, inv (f(inv) = a). Paper 2 is a line with decimals
##   cross     a line through (p, 0) and (0, q)
##   asym      b/(x − h) + A, or 2^x + c: form, h, A or c, f
##   meet      an increasing rule that meets y = x at (p, p): form "line" or "root"
##   self      a rule, its own inverse or not: form, f, inverse (bool), p, q (a point on it)
##
## Key points are whole numbers. The clean limits are the checker's too (tools/check_answers.py, BO_*).

const TRIES := 600
const WIN := [-8, 8, -8, 8]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var paper: int = need.get("paper", 1)
	for i in TRIES:
		var s: Dictionary
		match need.get("kind", "curve"):
			"area":
				s = _area(rng, paper)
			"table":
				s = _table(rng)
			"rule":
				s = _rule(rng, paper)
			"cross":
				s = _cross(rng)
			"asym":
				s = _asym(rng)
			"meet":
				s = _meet(rng)
			"self":
				s = _self_inverse(rng)
			_:
				s = _curve(rng)
		if not s.is_empty():
			s.paper = paper
			s.merge({"name": "f", "v": "x", "kind": need.get("kind", "curve")})
			return s
	push_error("BasicOneToOneSituation: no clean situation for %s" % need)
	return {}


static func _pick_key(rng: Seeded, s: Dictionary) -> Dictionary:
	var ok: Array = s.keys.filter(func(k): return k[0] != k[1] and k[0] != 0 and k[1] != 0 and k[0] != -k[1] and absi(k[0]) <= 8 and absi(k[1]) <= 8)
	if ok.is_empty():
		return {}
	var k: Array = rng.pick(ok)
	s.p = k[0]
	s.q = k[1]
	return s


static func _curve(rng: Seeded) -> Dictionary:
	var s: Dictionary
	match ["line", "root", "exp", "half"][rng.int_in(0, 3)]:
		"line":
			var m: int = [2, 3, -2, -3][rng.int_in(0, 3)]
			var c := ExtensionViews.nonzero(rng, -4, 4)
			s = {"f": BasicFunctionSituation.poly([c, m]), "form": "line", "keys": [[-1, c - m], [0, c], [1, c + m], [2, c + 2 * m]], "lo": -8.0, "hi": 8.0}
		"root":
			var a := rng.int_in(-4, 2)
			var b := rng.int_in(-3, 3)
			s = {"f": {"fam": "root", "A": Q.new(1), "m": Q.new(1), "n": Q.new(-a), "k": Q.new(b)}, "form": "root", "keys": [[a, b], [a + 1, b + 1], [a + 4, b + 2]], "lo": float(a), "hi": 8.0}
		"exp":
			var c := rng.int_in(-3, 2)
			s = {"f": {"fam": "exp", "A": Q.new(1), "b": Q.new(2), "c": Q.new(c)}, "form": "exp", "keys": [[0, 1 + c], [1, 2 + c], [2, 4 + c]], "lo": -8.0, "hi": 3.5}
		_:
			var a := rng.int_in(-4, 2)
			var b := rng.int_in(-3, 3)
			s = {"f": BasicFunctionSituation.poly([a * a + b, -2 * a, 1]), "form": "half", "keys": [[a, b], [a + 1, b + 1], [a + 2, b + 4]], "lo": float(a), "hi": float(a) + 3.5}
	return _pick_key(rng, s)


## The points of f on its stretch inside the window, so every reflection stays inside it.
static func points(s: Dictionary) -> Array:
	return Plot.sample(func(x): return BasicFunctionSituation.fl(s.f, x), s.lo, s.hi).filter(func(p): return absf(p[0]) <= 8.0 and absf(p[1]) <= 8.0)


static func _area(rng: Seeded, paper: int) -> Dictionary:
	var a: Q = Q.new(rng.int_in(2, 9), 10) if paper == 2 else Q.new(1, [2, 4, 5, 10][rng.int_in(0, 3)])
	if paper == 2 and a.d == 5 and a.n == 1:
		return {}
	var m: Q = Q.new(1).div(a)
	return {"f": BasicFunctionSituation.poly([0, 0, a]), "a": a, "m": m, "area": m.sq().div(3), "half": m.sq().div(6)}


static func _table(rng: Seeded) -> Dictionary:
	var m: int = [1, 2, 3, -1, -2][rng.int_in(0, 4)]
	var c := rng.int_in(-3, 4)
	var xs: Array = range(-2, 4)
	var f := BasicFunctionSituation.poly([c, m])
	var both: Array = xs.filter(func(x): return (x - c) % m == 0 and (x - c) / m in xs and (x - c) / m != x)
	if both.is_empty():
		return {}
	var a: int = rng.pick(both)
	return {"f": f, "xs": xs, "a": a, "inv": (a - c) / m}


static func _rule(rng: Seeded, paper: int) -> Dictionary:
	if paper == 2:
		var m := BasicFunctionSituation.tenths(rng, 11, 49)
		var c := BasicFunctionSituation.tenths(rng, -60, 60)
		var a := Q.new(ExtensionViews.nonzero(rng, -9, 12))
		var v := a.sub(c).div(m)
		var w := BasicFunctionSituation.poly([c, m])
		if not BasicFunctionSituation.fair(v) or BasicFunctionSituation.at(w, a).is_zero():
			return {}
		return {"f": w, "form": "line", "a": a, "inv": v}
	var s := _curve(rng)
	if s.is_empty():
		return {}
	s.a = s.q
	s.inv = s.p
	return s


static func _cross(rng: Seeded) -> Dictionary:
	var p := ExtensionViews.nonzero(rng, -6, 6)
	var q := ExtensionViews.nonzero(rng, -6, 6)
	if absi(p) == absi(q):
		return {}
	return {"f": BasicFunctionSituation.poly([q, Q.new(-q, p)]), "form": "line", "p": p, "q": q}


static func _asym(rng: Seeded) -> Dictionary:
	if rng.chance(0.3):
		var c := ExtensionViews.nonzero(rng, -4, 4)
		return {"f": {"fam": "exp", "A": Q.new(1), "b": Q.new(2), "c": Q.new(c)}, "form": "exp", "c": c}
	var h := ExtensionViews.nonzero(rng, -4, 4)
	var big := ExtensionViews.nonzero(rng, -4, 4)
	var b := ExtensionViews.nonzero(rng, -5, 5)
	if h == big:
		return {}
	return {"f": {"fam": "rat", "a": Q.new(big), "b": Q.new(b - big * h), "c": Q.new(1), "d": Q.new(-h)}, "form": "rat", "h": h, "A": big, "B": b}


static func _meet(rng: Seeded) -> Dictionary:
	var p := ExtensionViews.nonzero(rng, -5, 6)
	if rng.chance(0.7):
		var m: Q = [Q.new(2), Q.new(3), Q.new(1, 2)][rng.int_in(0, 2)]
		var c: Q = Q.new(p).mul(Q.new(1).sub(m))
		return {"f": BasicFunctionSituation.poly([c, m]), "form": "line", "p": p, "c": c}
	# √(2x + 3) style: the root is p at x = p, for p > 0.
	var r := rng.int_in(2, 6)
	var m2 := rng.int_in(1, r - 1) if r > 1 else 1
	var n := r * r - m2 * r
	return {"f": {"fam": "root", "A": Q.new(1), "m": Q.new(m2), "n": Q.new(n), "k": Q.new(0)}, "form": "root", "p": r, "c": Q.new(0)}


static func _self_inverse(rng: Seeded) -> Dictionary:
	match rng.int_in(0, 3):
		0:
			var c := ExtensionViews.nonzero(rng, -6, 6)
			var p := ExtensionViews.nonzero(rng, -3, 3)
			if 2 * p == c or c - p == 0:
				return {}
			return {"f": BasicFunctionSituation.poly([c, -1]), "form": "flip", "inverse": true, "p": p, "q": c - p}
		1:
			var k: int = [2, 4, 6, -4, -6][rng.int_in(0, 4)]
			var p: int = [1, 2, -1, -2][rng.int_in(0, 3)]
			if k % p != 0 or k / p == p:
				return {}
			return {"f": {"fam": "rat", "a": Q.new(0), "b": Q.new(k), "c": Q.new(1), "d": Q.new(0)}, "form": "recip", "inverse": true, "k": k, "p": p, "q": k / p}
		2:
			var m: int = [2, 3][rng.int_in(0, 1)]
			var c := ExtensionViews.nonzero(rng, -3, 3)
			var p := rng.int_in(1, 3)
			var q := m * p + c
			if q == p or m * q + c == p:
				return {}
			return {"f": BasicFunctionSituation.poly([c, m]), "form": "line", "inverse": false, "p": p, "q": q}
	var c := ExtensionViews.nonzero(rng, -4, 4)
	var p: int = [1, 2, -1, -2][rng.int_in(0, 3)]
	var f := {"fam": "rat", "a": Q.new(c), "b": Q.new(4), "c": Q.new(1), "d": Q.new(0)}
	var q := Q.new(c).add(Q.new(4, p))
	# The swapped point has to be off the curve, and off the asymptote x = 0.
	if q.is_zero() or q.eq(p) or BasicFunctionSituation.at(f, q).eq(p):
		return {}
	return {"f": f, "form": "recip-up", "inverse": false, "c": c, "p": p, "q": q}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
