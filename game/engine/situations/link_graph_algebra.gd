class_name LinkGraphAlgebraSituation
extends RefCounted
## The `fn-link-graph-vs-algebra` situation (curriculum/question-types.json): two
## functions f and g picked first, so that f(x) = g(x) is where their graphs meet (FAL-420).
## fn-link-graph-vs-algebra is built on it. Exact answers where algebra works (Paper 1),
## a GDC's to 3 s.f. where it doesn't (Paper 2).
##
## generate() returns, by need.kind:
##   "method"  solvable: e^(kx) = c, x = (ln c)/k; else e^x = a − x or ln x = a − x (form "exp"
##             or "ln"), one meeting point x0 found numerically
##   "meet"    e^x = bx + a, two meeting points xs (one far to the left)
##   "trig"    A·fn x = ±A/2 (fn "cos" or "sin") on 0 ≤ x ≤ U, U = N·π/2: the solutions sols
##             and the next one past U, as multiples of π (Q)
##   "kcount"  a cubic with whole turning points (LinkExtremesSituation's) and count 1 to 3,
##             the number of solutions of f(x) = k asked about
##   "area"    y = (x − u)(x − v) and y = mx + n meeting at p < 0 < q; area, and the areas
##             wrong_limits (from u to v, the parabola's zeros) and one_limit (from 0 to q)
##   "log"     ln x + ln(x + a) = ln b with b = r(r + a): x = r, and −(r + a) rejected
##   "exp"     e^(kx) = c, x = (ln c)/k
## plus kind and paper.

const TRIES := 2000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var kind: String = need.get("kind", "method")
	var s: Dictionary
	match kind:
		"meet":
			s = _meet(rng)
		"trig":
			s = _trig(rng)
		"kcount":
			s = LinkExtremesSituation._cubic(rng)
			if not s.is_empty():
				s.count = rng.int_in(1, 3)
		"area":
			s = _area(rng)
		"log":
			s = _log(rng)
		"exp":
			s = _exp(rng, [1, 2])
		_:
			s = _method(rng)
	if s.is_empty():
		return {}
	s.kind = kind
	s.paper = 2 if kind in ["method", "meet", "exp"] else 1
	return s


## Whether a GDC value shows cleanly to 3 s.f. and to 2 s.f. (the rounding trap).
static func clear(x: float) -> bool:
	return Answer.rounds_clearly(x, 0.05) and Answer.rounds_clearly(x / 10.0, 0.05) and absf(x) > 0.05


static func _exp(rng: Seeded, ks: Array) -> Dictionary:
	for i in TRIES:
		var k: int = ks[rng.int_in(0, ks.size() - 1)]
		var c := rng.int_in(2, 50)
		var x := log(float(c)) / k
		if clear(x) and clear(log(float(c)) / log(10.0) / k) and clear(c / exp(1.0)) and clear(log(float(c) / k) if k > 1 else log(float(c)) / 2.0):
			return {"k": k, "c": c, "x0": x, "solvable": true}
	return {}


static func _method(rng: Seeded) -> Dictionary:
	if rng.chance(0.5):
		var s := _exp(rng, [1, 2, 3])
		if not s.is_empty() and clear(log(float(s.c))):
			return s
	for i in TRIES:
		var form: String = "exp" if rng.chance(0.5) else "ln"
		var a := rng.int_in(2, 7)
		var s := {"form": form, "a": a, "solvable": false}
		var zs := GdcKit.zeros(func(x: float) -> float: return h_method(s, x), 0.01 if form == "ln" else -3.0, float(a) + 1.0)
		if zs.size() == 1 and clear(zs[0]) and clear(log(float(a))):
			s.x0 = zs[0]
			return s
	return {}


## The unsolvable equation's two sides, f − g.
static func h_method(s: Dictionary, x: float) -> float:
	return (exp(x) if s.form == "exp" else log(x)) - (s.a - x)


static func _meet(rng: Seeded) -> Dictionary:
	for i in TRIES:
		var s := {"b": rng.int_in(1, 2), "a": rng.int_in(2, 5)}
		var zs := GdcKit.zeros(func(x: float) -> float: return h_meet(s, x), -float(s.a) - 3.0, 4.0)
		if zs.size() == 2 and zs.all(func(z): return clear(z)):
			s.xs = zs
			return s
	return {}


static func h_meet(s: Dictionary, x: float) -> float:
	return exp(x) - (s.b * x + s.a)


## The solutions of fn x = sign·½ in [0, 2π), as multiples of π.
const BASE := {"cos+": [[1, 3], [5, 3]], "cos-": [[2, 3], [4, 3]], "sin+": [[1, 6], [5, 6]], "sin-": [[7, 6], [11, 6]]}


static func _trig(rng: Seeded) -> Dictionary:
	for i in TRIES:
		var s := {"fn": "cos" if rng.chance(0.5) else "sin", "sign": 1 if rng.chance(0.5) else -1, "A": [2, 4][rng.int_in(0, 1)],
			"N": rng.int_in(5, 7)}
		var U := Q.new(s.N, 2)
		var all: Array = []
		for turn in 4:
			for b in BASE["%s%s" % [s.fn, "+" if s.sign > 0 else "-"]]:
				all.append(Q.new(b[0], b[1]).add(Q.new(2 * turn)))
		all.sort_custom(func(x, y): return x.lt(y))
		s.sols = all.filter(func(x): return not U.lt(x))
		s.next = all.filter(func(x): return U.lt(x))[0]
		if s.sols.size() >= 3 and s.sols.any(func(x): return Q.new(2).lt(x)):
			return s
	return {}


static func _area(rng: Seeded) -> Dictionary:
	for i in TRIES:
		var p := rng.int_in(-3, -1)
		var q := rng.int_in(1, 4)
		var u := rng.int_in(-4, 2)
		var v := u + rng.int_in(1, 5)
		var m := p + q - u - v
		var n := u * v - p * q
		if m == 0 or absi(n) > 12 or (u == p and v == q):
			continue
		var s := {"p": p, "q": q, "u": u, "v": v, "m": m, "n": n}
		s.area = between(s, p, q)
		s.wrong_limits = between(s, u, v).abs_q()
		s.one_limit = between(s, 0, q).abs_q()
		var seen := [s.area.key(), s.area.neg().key()]
		if s.wrong_limits.is_zero() or s.one_limit.is_zero() or s.wrong_limits.key() in seen or s.one_limit.key() in seen:
			continue
		return s
	return {}


## ∫ from lo to hi of (line − parabola), exactly.
static func between(s: Dictionary, lo: int, hi: int) -> Q:
	var F := func(x: int) -> Q:
		# mx²/2 + nx − (x³/3 − (u + v)x²/2 + uv·x)
		return Q.new(s.m * x * x, 2).add(Q.new(s.n * x)).sub(Q.new(x * x * x, 3)).add(Q.new((s.u + s.v) * x * x, 2)).sub(Q.new(s.u * s.v * x))
	return F.call(hi).sub(F.call(lo))


static func _log(rng: Seeded) -> Dictionary:
	var r := rng.int_in(1, 5)
	var a := rng.int_in(1, 6)
	return {"r": r, "a": a, "b": r * (r + a)}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
