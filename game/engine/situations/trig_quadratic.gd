class_name TrigQuadraticSituation
extends RefCounted
## The `trig-quadratic` situation (curriculum/question-types.json): one trig equation that is a
## quadratic in sin x, cos x or tan x, for t3-trig-quadratic (SL3.8.quadratic-in-trig, FAL-753). It is
## built forward from its roots in u, so it factorises cleanly, then disguised. Every question is
## Paper 1, with exact answers, but for the two GDC unknowns.
##
## need.ask is the unknown (see TrigQuadraticViews). generate() returns a Dictionary:
##   paper, ask, rep, form    "pi" or "deg"
##   fn, b, phi               u = fn(bx + phi·π), as in trig-equation; phi is always 0
##   lo, hi, open_hi          the interval, as multiples of π
##   p                        the quadratic in u, [a, b, c], whole numbers (surd-coefficient has `surd`)
##   lead, cons               the brackets (lead[0] u + cons[0])(lead[1] u + cons[1]) of p
##   us, kept, bad            its roots, those in fn's range and the one rejected: TrigKit values
##   dis                      how it is written: direct, pythag (cos²x for sin²x) or double (cos 2x)
##   sc                       what p is multiplied by so that cos 2x has a whole number in front
##   lay                      which term is on the right: 0 none, 1 the number, 2 the term in u
##   xs                       the solutions: Qs of π, or on Paper 2 Qs of x
##   spin                     where a question's slips start (TrigModelEquationViews.spun)
##   plus what one family needs: sq (a number equal to u²), tan_over, surd, e, top, kind, all, ...

const TRIES := 800
const MAX_SOLUTIONS := 8
const MAX_COUNT := 12
## Roots in u, [n, d]: in the range of sin and cos with landmark angles, then outside it.
const INSIDE := [[0, 1], [1, 2], [-1, 2], [1, 1], [-1, 1]]
const OUTSIDE := [[2, 1], [-2, 1], [3, 1], [-3, 1], [3, 2], [-3, 2]]
## u² = n/d with a landmark u.
const SQUARES := [[1, 4], [1, 2], [3, 4], [1, 1]]
const TAN_SQUARES := [[1, 1], [3, 1], [1, 3]]
const WHOLE_TURN := [[0, 2], [0, 2], [0, 2], [-1, 1], [0, 1]]
const WIDE := [[0, 2], [0, 1], [-1, 1], [0, 4], [-2, 2], [0, 3], [-1, 2]]
## The bank's and the map's own equations stay theirs: "fn|dis|a,b,c".
const TAKEN := ["sin|pythag|2,-5,2", "sin|pythag|2,5,2", "sin|double|2,1,-1", "sin|direct|2,-1,-1", "sin|pythag|2,-3,1", "sin|double|2,-3,1"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "all-solutions")
	var rep: String = need.get("rep", "equation")
	for i in TRIES:
		var s := {"paper": 2 if ask in TrigQuadraticViews.P2 else 1, "ask": ask, "rep": rep, "form": "pi", "fn": rng.pick(["sin", "cos"]), "b": Q.new(1), "phi": Q.new(0),
			"lo": Q.new(0), "hi": Q.new(2), "open_hi": false, "dis": "direct", "sc": 1, "lay": rng.int_in(0, 2), "spin": rng.int_in(0, 59), "bad": [], "xs": []}
		if new().call("_" + ask.replace("-", "_"), rng, s) and _clean(s):
			return s
	return {}


static func _clean(s: Dictionary) -> bool:
	if s.has("p") and "%s|%s|%d,%d,%d" % [s.fn, s.dis, s.p[0], s.p[1], s.p[2]] in TAKEN:
		return false
	if s.ask in TrigQuadraticViews.NO_LIST:
		return true
	var n: int = s.xs.size()
	if n < 1 or n > (MAX_COUNT if s.ask in TrigQuadraticViews.COUNTS else MAX_SOLUTIONS):
		return false
	return s.paper == 1 or s.ask == "gdc-count" or s.xs.all(func(x): return Answer.rounds_clearly(x.to_float(), 0.03) and absf(x.to_float()) > 0.05)


# ── The roots and the quadratic ──────────────────────────────

## (lead u + cons) with root n/d, in lowest terms. p is the product of two of them.
static func _set_roots(s: Dictionary, r1: Q, r2: Q) -> void:
	s.lead = [r1.d, r2.d]
	s.cons = [-r1.n, -r2.n]
	s.p = [r1.d * r2.d, -(r1.d * r2.n + r2.d * r1.n), r1.n * r2.n]
	s.us = [TrigKit.V(r1), TrigKit.V(r2)]
	s.kept = s.us.filter(func(v): return absf(TrigKit.fl(v)) <= 1.0)
	s.bad = s.us.filter(func(v): return absf(TrigKit.fl(v)) > 1.0)


## Two rational roots: both inside the range, or one inside and one to reject.
static func _rational(rng: Seeded, s: Dictionary, reject: bool, zero: bool = true) -> bool:
	var a: Array = rng.pick(INSIDE)
	var c: Array = rng.pick(OUTSIDE if reject else INSIDE)
	var r1 := Q.new(a[0], a[1])
	var r2 := Q.new(c[0], c[1])
	if r1.eq(r2) or r1.eq(r2.neg()) or (not zero and (r1.is_zero() or r2.is_zero())):
		return false
	_set_roots(s, r1, r2)
	return true


## How the quadratic is written. Every cos 2x needs an even number in front of u².
static func _disguise(rng: Seeded, s: Dictionary, kinds: Array) -> bool:
	s.dis = rng.pick(kinds)
	s.sc = 2 if s.dis == "double" and s.p[0] % 2 != 0 else 1
	return true


static func _turn(rng: Seeded, s: Dictionary, spans: Array = WHOLE_TURN) -> void:
	var w: Array = rng.pick(spans)
	s.lo = Q.new(w[0])
	s.hi = Q.new(w[1])
	s.open_hi = w[0] == 0 and w[1] == 2 and rng.chance(0.2)


static func on(s: Dictionary, fn: String, v: Array) -> Array:
	return TrigEquationSituation.solve(fn, v, s.b, s.phi, s.lo, s.hi, s.open_hi)


## The solutions of the roots that are in range.
static func _solve(s: Dictionary) -> void:
	s.xs = _all_of(s, s.kept)


static func _all_of(s: Dictionary, vs: Array) -> Array:
	var out: Array = []
	for v in vs:
		out = TrigEquationSituation._merge(out, on(s, s.fn, v))
	return out


# ── One step of the solution ─────────────────────────────────

static func _quadratic_in_u(rng: Seeded, s: Dictionary) -> bool:
	return _rational(rng, s, rng.chance(0.4), false) and _disguise(rng, s, ["pythag", "pythag", "double"])


static func _identity_to_use(rng: Seeded, s: Dictionary) -> bool:
	return _quadratic_in_u(rng, s)


static func _factorised_form(rng: Seeded, s: Dictionary) -> bool:
	s.lay = 0
	if not _rational(rng, s, rng.chance(0.4), false):
		return false
	if s.lead[0] < s.lead[1]:
		s.lead = [s.lead[1], s.lead[0]]
		s.cons = [s.cons[1], s.cons[0]]
	return true


static func _values_of_u(rng: Seeded, s: Dictionary) -> bool:
	return _rational(rng, s, rng.chance(0.4)) and _disguise(rng, s, ["direct", "pythag", "double"])


## A quadratic with no rational root: a root in range and a root outside it.
static func _formula_root(rng: Seeded, s: Dictionary) -> bool:
	var a: int = rng.int_in(1, 4)
	var b: int = ExtensionViews.nonzero(rng, -6, 6)
	var c: int = ExtensionViews.nonzero(rng, -5, 5)
	var d: int = b * b - 4 * a * c
	if d <= 0 or roundi(sqrt(d)) * roundi(sqrt(d)) == d:
		return false
	s.p = [a, b, c]
	_disguise(rng, s, ["direct", "pythag"])
	var root := TrigKit.root(d)
	var up := TrigKit.plus(TrigKit.V(Q.new(-b, 2 * a)), TrigKit.times(root, Q.new(1, 2 * a)))
	var down := TrigKit.plus(TrigKit.V(Q.new(-b, 2 * a)), TrigKit.times(root, Q.new(-1, 2 * a)))
	s.us = [up, down]
	s.kept = s.us.filter(func(v): return absf(TrigKit.fl(v)) < 0.95 and absf(TrigKit.fl(v)) > 0.05)
	s.bad = s.us.filter(func(v): return absf(TrigKit.fl(v)) > 1.05)
	return s.kept.size() == 1 and s.bad.size() == 1


static func _reject_root(rng: Seeded, s: Dictionary) -> bool:
	return _rational(rng, s, true) and _disguise(rng, s, ["direct", "pythag", "double"])


# ── Every solution ───────────────────────────────────────────

static func _full(rng: Seeded, s: Dictionary, kinds: Array, spans: Array = WHOLE_TURN, reject := 0.4) -> bool:
	if not _rational(rng, s, rng.chance(reject)):
		return false
	_disguise(rng, s, kinds)
	_turn(rng, s, spans)
	_solve(s)
	return true


static func _all_solutions(rng: Seeded, s: Dictionary) -> bool:
	return _full(rng, s, ["direct", "pythag", "pythag"])


static func _all_solutions_degrees(rng: Seeded, s: Dictionary) -> bool:
	s.form = "deg"
	return _full(rng, s, ["direct", "pythag", "double"])


static func _double_angle_solve(rng: Seeded, s: Dictionary) -> bool:
	return _full(rng, s, ["double"])


static func _plus_minus_root(rng: Seeded, s: Dictionary) -> bool:
	var q: Array = rng.pick(SQUARES)
	s.sq = Q.new(q[0], q[1])
	s.p = [q[1], 0, -q[0]]
	var k := TrigKit.sqrt_q(s.sq)
	s.us = [k, TrigKit.neg(k)]
	s.kept = s.us
	s.lead = [0, 0]
	s.cons = [0, 0]
	_turn(rng, s)
	_solve(s)
	return true


## q tan²x = n, or q tan x = n/tan x. The map's 3 tan²x = 1 on 0 to π stays the map's.
static func _tan_squared(rng: Seeded, s: Dictionary) -> bool:
	s.fn = "tan"
	var q: Array = rng.pick(TAN_SQUARES)
	var scale: int = rng.int_in(1, 3)
	s.sq = Q.new(q[0], q[1])
	s.p = [q[1] * scale, 0, -q[0] * scale]
	s.tan_over = s.rep != "graph" and rng.chance(0.4)
	s.lay = 1 if s.tan_over or rng.chance(0.6) else 0
	var k := TrigKit.sqrt_q(s.sq)
	s.us = [k, TrigKit.neg(k)]
	s.kept = s.us
	s.lead = [0, 0]
	s.cons = [0, 0]
	_turn(rng, s, [[0, 1], [0, 2], [-1, 1]])
	_solve(s)
	return not (s.p[0] == 3 and s.p[2] == -1 and s.hi.eq(1) and s.lo.is_zero())


static func _tan_zero_root(rng: Seeded, s: Dictionary) -> bool:
	s.fn = "tan"
	s.k = TrigEquationSituation.tan_value(rng)
	s.us = [TrigKit.V(0), s.k]
	s.kept = s.us
	_turn(rng, s, [[0, 1], [0, 2], [-1, 1]])
	_solve(s)
	return true


## (l u − a)(m u − c) with c a surd: its middle coefficient and its number are surds too.
static func _surd_coefficient(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(["sin", "cos", "tan"])
	var sign: int = rng.pick([1, -1])
	var c: Array = TrigKit.V(0, sign, 3) if s.fn == "tan" else TrigKit.V(0, Q.new(sign, 2), rng.pick([2, 3]))
	var a: Q
	var l: int
	var m: int = 1 if s.fn == "tan" else 2
	if s.fn == "tan":
		a = Q.new(rng.pick([1, -1]))
		l = 1
	else:
		var pick: Array = rng.pick([[1, 2, 2], [-1, 2, 2], [1, 1, 1], [-1, 1, 1], [2, 1, 1], [-2, 1, 1]])
		a = Q.new(pick[0], pick[1])
		l = pick[2]
	var av := TrigKit.V(a)
	# (l u − la)(m u − mc): the two numbers are whole or a surd.
	var left := TrigKit.times(av, l)
	var right := TrigKit.times(c, m)
	s.surd = {"a": l * m, "b": TrigKit.neg(TrigKit.plus(TrigKit.times(right, l), TrigKit.times(left, m))), "c": TrigKit.mul(left, right), "l": l, "m": m, "left": left, "right": right}
	s.us = [av, c]
	s.kept = s.us.filter(func(v): return absf(TrigKit.fl(v)) <= 1.0 or s.fn == "tan")
	s.bad = s.us.filter(func(v): return absf(TrigKit.fl(v)) > 1.0 and s.fn != "tan")
	_turn(rng, s)
	_solve(s)
	return true


## P(fn 2x) = 0, and more of the wave to look at.
static func _compound_quadratic(rng: Seeded, s: Dictionary) -> bool:
	s.b = Q.new(rng.pick([2, 2, 3]))
	if not _rational(rng, s, rng.chance(0.3)):
		return false
	_turn(rng, s, [[0, 1], [0, 1], [0, 2]])
	s.open_hi = false
	_solve(s)
	var first: Array = s.xs.filter(func(x): return not s.hi.lt(x.mul(s.b)))
	return s.xs.size() >= 2 and first.size() < s.xs.size()


## p u + q + top/(u − e) = 0, for u = fn(bx). Multiplying by (u − e) gives the quadratic.
static func _rational_disguise(rng: Seeded, s: Dictionary) -> bool:
	s.b = Q.new(rng.pick([1, 2, 2]))
	s.e = Q.new(rng.pick([1, -1]))
	var a: Array = rng.pick([[1, 2], [-1, 2], [0, 1]])
	var c: Array = rng.pick(OUTSIDE + [[1, 2], [-1, 2]])
	var r1 := Q.new(a[0], a[1])
	var r2 := Q.new(c[0], c[1])
	if r1.eq(r2) or r1.eq(r2.neg()):
		return false
	_set_roots(s, r1, r2)
	var e: int = s.e.n
	s.q = s.p[1] + s.p[0] * e
	s.top = s.p[2] + e * s.q
	_turn(rng, s, [[0, 1], [0, 2]] if s.b.eq(2) else [[0, 2], [-1, 1]])
	s.open_hi = false
	s.gaps = on(s, s.fn, TrigKit.V(s.e))
	_solve(s)
	var from_bank: bool = s.fn == "sin" and s.p == [2, -5, -3] and s.e.eq(1)
	return not from_bank and s.top != 0


## cos x times something that is 0: sin 2x = 2k cos²x gives tan x = k, and 4 sin²x cos x = n cos x
## gives sin²x = n/4.
static func _double_factor(rng: Seeded, s: Dictionary) -> bool:
	s.kind = rng.pick(["tan", "square"])
	_turn(rng, s, [[0, 2], [0, 2], [-1, 1]])
	var zeros := on(s, "cos", TrigKit.V(0))
	if s.kind == "tan":
		s.fn = "tan"
		s.k = TrigEquationSituation.tan_value(rng)
		s.us = [s.k]
		s.kept = s.us
		s.xs = TrigEquationSituation._merge(zeros, on(s, "tan", s.k))
		return true
	s.fn = "sin"
	s.n = rng.pick([1, 2, 3])
	var k := TrigKit.sqrt_q(Q.new(s.n, 4))
	s.us = [k, TrigKit.neg(k)]
	s.kept = s.us
	s.xs = TrigEquationSituation._merge(zeros, _all_of(s, s.us))
	return true


# ── One number from the solutions ────────────────────────────

static func _count_solutions(rng: Seeded, s: Dictionary) -> bool:
	return _full(rng, s, ["direct", "pythag", "double"], WIDE, 0.6)


static func _one_solution(rng: Seeded, s: Dictionary) -> bool:
	if not _full(rng, s, ["direct", "pythag", "double"]) or s.xs.size() < 2:
		return false
	s.all = s.xs
	var kinds: Array = ["largest", "smallest"]
	if s.lo.sign() < 0 and s.all[0].sign() < 0 and s.all.any(func(x): return x.sign() > 0):
		kinds.append("positive")
	s.kind = rng.pick(kinds)
	s.xs = [pick_from(s.all, s.kind)]
	return true


static func pick_from(xs: Array, kind: String) -> Q:
	if kind == "largest":
		return xs[xs.size() - 1]
	if kind == "smallest":
		return xs[0]
	return xs.filter(func(x): return x.sign() > 0)[0]


static func total(xs: Array) -> Q:
	var t := Q.new(0)
	for x in xs:
		t = t.add(x)
	return t


static func _sum_solutions(rng: Seeded, s: Dictionary) -> bool:
	s.form = "deg" if rng.chance(0.25) else "pi"
	return _full(rng, s, ["direct", "pythag", "double"], [[0, 2], [0, 2], [0, 1]]) and s.xs.size() >= 2 and not total(s.xs).is_zero()


## x is a solution, and one number of the quadratic is the letter k.
static func _constant_from_solution(rng: Seeded, s: Dictionary) -> bool:
	var a: Array = rng.pick(INSIDE)
	if a[0] == 0:
		return false
	var c: Array = rng.pick(OUTSIDE + INSIDE)
	var r1 := Q.new(a[0], a[1])
	var r2 := Q.new(c[0], c[1])
	if r1.eq(r2) or r1.eq(r2.neg()):
		return false
	_set_roots(s, r1, r2)
	if s.p[1] == 0 or s.p[2] == 0:
		return false
	s.shape = rng.pick(["c", "b"])
	var xs := on(s, s.fn, TrigKit.V(r1))
	s.sol = rng.pick(xs)
	s.root = r1
	return true


# ── Paper 2 ──────────────────────────────────────────────────

## No rational root: the solutions come from a graph or the formula, to 3 s.f.
static func _awkward(rng: Seeded, s: Dictionary) -> bool:
	var a: int = rng.int_in(1, 5)
	var b: int = ExtensionViews.nonzero(rng, -7, 7)
	var c: int = ExtensionViews.nonzero(rng, -6, 6)
	var d: int = b * b - 4 * a * c
	if d <= 0 or roundi(sqrt(d)) * roundi(sqrt(d)) == d:
		return false
	s.p = [a, b, c]
	_disguise(rng, s, ["direct", "pythag", "double"])
	var us: Array = [(-b - sqrt(d)) / (2.0 * a), (-b + sqrt(d)) / (2.0 * a)]
	if us.any(func(u): return absf(absf(u) - 1.0) < 0.05 or absf(u) < 0.06):
		return false
	s.u_dec = us.map(func(u): return GdcKit.qf(u))
	s.kept_dec = s.u_dec.filter(func(u): return absf(u.to_float()) < 1.0)
	s.bad_dec = s.u_dec.filter(func(u): return absf(u.to_float()) > 1.0)
	return not s.kept_dec.is_empty()


## Every x with fn x = u, for a decimal u, on an interval: Qs of x itself.
static func decimal_xs(s: Dictionary, u: Q, lo: float, hi: float) -> Array:
	var c: float = u.to_float()
	var base: Array = [asin(c), PI - asin(c)] if s.fn == "sin" else [acos(c), -acos(c)]
	var out: Array = []
	for t in base:
		for n in range(-3, 4):
			var x: float = t + n * TAU
			if x >= lo and x <= hi and not (s.open_hi and absf(x - hi) < 1e-9):
				out.append(x)
	out.sort()
	return out.map(func(x): return GdcKit.qf(x))


static func _gdc_solve(rng: Seeded, s: Dictionary) -> bool:
	if not _awkward(rng, s):
		return false
	_turn(rng, s)
	var lo: float = s.lo.to_float() * PI
	var hi: float = s.hi.to_float() * PI
	var all: Array = []
	for u in s.kept_dec:
		all += decimal_xs(s, u, lo, hi)
	all.sort_custom(func(p, q): return p.lt(q))
	s.xs = all
	return true


## A root on 1 or −1 makes the curve touch the axis instead of crossing it.
static func _gdc_count(rng: Seeded, s: Dictionary) -> bool:
	return _full(rng, s, ["direct", "pythag", "double"], WIDE, 0.5)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
