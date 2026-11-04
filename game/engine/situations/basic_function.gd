class_name BasicFunctionSituation
extends RefCounted
## The `basic-function` situation (curriculum/question-types.json): one function, its inputs
## and its outputs (FAL-424). fn-evaluate-function and fn-concept-function-notation are built
## on it, and basic-restricted and basic-one-to-one use its rules.
##
## A rule is a Dictionary (at(), fl() and text() read it):
##   {"fam": "poly", "co": [c₀, c₁, c₂, c₃]}       a polynomial, low power first
##   {"fam": "root", "A", "m", "n", "k"}           A√(mx + n) + k
##   {"fam": "rat", "a", "b", "c", "d"}            (ax + b)/(cx + d)
##   {"fam": "exp", "A", "b", "c"}                 A(b)^x + c
##   {"fam": "expe", "A", "k", "c"}                A·e^(kx) + c
##   {"fam": "ln", "A", "m", "n", "k"}             A ln(mx + n) + k
##
## generate() returns, by need.kind:
##   plain     rule f; x0 an input, y0 = f(x0), y_int = f(0)
##   grid      rule f (a line or a parabola) that fits the window GRID, x0 and y0 whole
##   roots     rule f with zeros zs (sorted), offset k (f(x) = k has solutions zs; 0 for zeros),
##             y_int = f(0). Paper 1: a(x − p)(x − q) + k or x³ − p²x, on whole numbers
##   model     a context: ctx "ball", "cost", "pop" or "cool", name, v (the input's letter), rule f,
##             x0, y0, y_int = the start value, target, tstar (the input that reaches it),
##             tneg (a ball's other, negative root), dom_end (when a ball lands; 0 otherwise)
##   notation  rule f (a whole-number line or parabola), a (the value to put in)
## Paper 1 outputs are whole numbers or simple fractions (exact Qs). Paper 2 (a calculator)
## has decimal coefficients and inputs; a value is a Q, exact for a polynomial, and to 9 d.p.
## otherwise. It is on no rounding edge, and is answered to 3 s.f.
##
## need: kind ("any" is plain or model), fams (plain), ctx, offset (roots: k ≠ 0), linear
## (notation), paper. A type with no paper counts gets Paper 1. The clean limits are the
## checker's too (tools/check_answers.py, BF_*).

const TRIES := 600
const GRID := [-6, 6, -10, 10]
const PLAIN := ["line", "quad", "cubic", "root", "rat", "exp"]
const CTXS := ["ball", "cost", "pop", "cool"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var paper: int = need.get("paper", 1)
	for i in TRIES:
		var s := _draw(rng, need, paper)
		if not s.is_empty():
			s.paper = paper
			return s
	push_error("BasicFunctionSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, need: Dictionary, paper: int) -> Dictionary:
	var kind: String = need.get("kind", "any")
	if kind == "any":
		kind = "plain" if rng.chance(0.5) else "model"
	var s: Dictionary
	match kind:
		"grid":
			s = _grid(rng)
		"roots":
			s = _roots(rng, paper, need.get("offset", false))
		"model":
			s = _model(rng, paper, need.get("ctx", "any"))
		"notation":
			s = _notation(rng, need.get("linear", false))
		_:
			var fams: Array = need.get("fams", PLAIN)
			s = _plain(rng, paper, rng.pick(fams))
	if not s.is_empty():
		s.kind = kind
		s.merge({"name": "f", "v": "x"})
	return s


# ── Rules ────────────────────────────────────────────────────

static func poly(co: Array) -> Dictionary:
	var c: Array = co.map(func(x): return Q.of(x))
	while c.size() < 4:
		c.append(Q.new(0))
	return {"fam": "poly", "co": c}


## A rule's value as a float, NAN outside its domain.
static func fl(r: Dictionary, x: float) -> float:
	match r.fam:
		"poly":
			var y := 0.0
			for i in range(3, -1, -1):
				y = y * x + r.co[i].to_float()
			return y
		"root":
			var u: float = r.m.to_float() * x + r.n.to_float()
			return NAN if u < 0.0 else r.A.to_float() * sqrt(u) + r.k.to_float()
		"rat":
			var bot: float = r.c.to_float() * x + r.d.to_float()
			return NAN if absf(bot) < 1e-12 else (r.a.to_float() * x + r.b.to_float()) / bot
		"exp":
			return r.A.to_float() * pow(r.b.to_float(), x) + r.c.to_float()
		"expe":
			return r.A.to_float() * exp(r.k.to_float() * x) + r.c.to_float()
		"ln":
			var u: float = r.m.to_float() * x + r.n.to_float()
			return NAN if u <= 0.0 else r.A.to_float() * log(u) + r.k.to_float()
	return NAN


static func pow_q(b: Q, n: int) -> Q:
	var out := Q.new(1)
	for i in absi(n):
		out = out.mul(b)
	return out if n >= 0 else Q.new(1).div(out)


## A rule's value as a Q: exact for a polynomial, a rational, a whole power or a square root
## that comes out, and to 9 d.p. otherwise.
static func at(r: Dictionary, x: Variant) -> Q:
	var q := Q.of(x)
	match r.fam:
		"poly":
			var y := Q.new(0)
			for i in range(3, -1, -1):
				y = y.mul(q).add(r.co[i])
			return y
		"rat":
			return r.a.mul(q).add(r.b).div(r.c.mul(q).add(r.d))
		"exp":
			if q.is_int() and absi(q.n) <= 12:
				return r.A.mul(pow_q(r.b, q.n)).add(r.c)
		"root":
			var u: Q = r.m.mul(q).add(r.n)
			var top := roundi(sqrt(float(u.n)))
			var bot := roundi(sqrt(float(u.d)))
			if top * top == u.n and bot * bot == u.d:
				return r.A.mul(Q.new(top, bot)).add(r.k)
		"expe":
			if q.is_zero():
				return r.A.add(r.c)
	return GdcKit.qf(fl(r, q.to_float()))


## A rule's right-hand side as the game writes it, with v as its letter.
static func text(r: Dictionary, v: String = "x") -> String:
	match r.fam:
		"poly":
			return Fmt.terms([r.co[3], r.co[2], r.co[1], r.co[0]], [3, 2, 1, 0], v, true)
		"root":
			return "%s√(%s)%s" % [GdcKit.lead(r.A), Fmt.terms([r.m, r.n], [1, 0], v, true), GdcKit.join(r.k, "")]
		"rat":
			return "(%s)/(%s)" % [Fmt.terms([r.a, r.b], [1, 0], v, true), Fmt.terms([r.c, r.d], [1, 0], v, true)]
		"exp":
			var base: String = "%s(%s)^%s" % [GdcKit.lead(r.A), Fmt.dec(r.b), v]
			if r.A.eq(1) and r.b.is_int():
				base = "%s^%s" % [Fmt.dec(r.b), v]
			return base + GdcKit.join(r.c, "")
		"expe":
			var up: String = "e^" + v if r.k.eq(1) else "e^(%s%s)" % [GdcKit.lead(r.k), v]
			return GdcKit.lead(r.A) + up + GdcKit.join(r.c, "")
		"ln":
			return "%sln(%s)%s" % [GdcKit.lead(r.A), Fmt.terms([r.m, r.n], [1, 0], v, true), GdcKit.join(r.k, "")]
	return ""


## f(x) = ... with the situation's own name and letter.
static func eqn(s: Dictionary) -> String:
	return "%s(%s) = %s" % [s.name, s.v, text(s.f, s.v)]


## A number from lo to hi in tenths, not a whole number.
static func tenths(rng: Seeded, lo: int, hi: int) -> Q:
	var v := 0
	while v % 10 == 0:
		v = rng.int_in(lo, hi)
	return Q.new(v, 10)


## Whether a Paper 2 value is fair: it needs rounding, clear of a rounding edge.
static func fair(v: Q) -> bool:
	return Answer.needs_rounding(v) and Answer.rounds_clearly(v.to_float(), 0.04) and absf(v.to_float()) < 5000.0


## Whether a Paper 1 value is simple: a whole number or a fraction over at most 12.
static func simple(v: Q) -> bool:
	return v.d <= 12 and absi(v.n) <= 400


# ── plain, grid, notation ────────────────────────────────────

static func _plain(rng: Seeded, paper: int, fam: String) -> Dictionary:
	var f: Dictionary
	var x0: Q
	if paper == 2:
		x0 = tenths(rng, -30, 45)
		match fam:
			"line", "quad":
				f = poly([tenths(rng, -60, 80), tenths(rng, -50, 50), Q.new(0) if fam == "line" else tenths(rng, -25, 25)])
			"cubic":
				f = poly([tenths(rng, -60, 60), tenths(rng, -30, 30), Q.new(0), tenths(rng, 3, 19)])
			"root":
				f = {"fam": "root", "A": tenths(rng, 11, 39), "m": tenths(rng, 11, 39), "n": Q.new(rng.int_in(5, 14)), "k": tenths(rng, -40, 40)}
			"rat":
				f = {"fam": "rat", "a": tenths(rng, 11, 39), "b": Q.new(rng.int_in(1, 9)), "c": Q.new(1), "d": tenths(rng, -55, 55)}
			"exp":
				f = {"fam": "exp", "A": tenths(rng, 11, 45), "b": Q.new(rng.int_in(11, 18), 10), "c": tenths(rng, -30, 30)}
		if fam == "exp" and rng.chance(0.5):
			f = {"fam": "expe", "A": tenths(rng, 11, 45), "k": tenths(rng, 2, 9), "c": tenths(rng, -30, 30)}
	else:
		match fam:
			"line":
				f = poly([rng.int_in(-9, 9), ExtensionViews.nonzero(rng, -6, 6)])
				x0 = Q.new(rng.int_in(-5, 6))
			"quad":
				f = poly([rng.int_in(-6, 8), rng.int_in(-5, 5), [1, -1, -1, 2, -2][rng.int_in(0, 4)]])
				x0 = Q.new(ExtensionViews.nonzero(rng, -4, 4))
			"cubic":
				f = poly([rng.int_in(-6, 6), rng.int_in(-4, 4), 0, 1])
				x0 = Q.new(ExtensionViews.nonzero(rng, -3, 3))
			"root":
				var r := rng.int_in(1, 5)
				var m := rng.int_in(1, 4)
				x0 = Q.new(rng.int_in(-3, 6))
				var n: int = r * r - m * x0.n
				if n == 0 or n * n > 625:
					return {}
				f = {"fam": "root", "A": Q.new([1, 1, 2, 3][rng.int_in(0, 3)]), "m": Q.new(m), "n": Q.new(n), "k": Q.new(rng.int_in(-4, 4))}
			"rat":
				var d := ExtensionViews.nonzero(rng, -6, 6)
				f = {"fam": "rat", "a": Q.new(rng.int_in(1, 4)), "b": Q.new(ExtensionViews.nonzero(rng, -7, 7)), "c": Q.new(1), "d": Q.new(d)}
				x0 = Q.new(rng.int_in(-4, 6))
				if x0.add(Q.new(d)).is_zero():
					return {}
			"exp":
				f = {"fam": "exp", "A": Q.new([1, 2, 3, 5][rng.int_in(0, 3)]), "b": Q.new(rng.int_in(2, 3)), "c": Q.new(rng.int_in(-4, 4))}
				x0 = Q.new(rng.int_in(-1, 3))
				if x0.is_zero():
					x0 = Q.new(2)
	if is_nan(fl(f, x0.to_float())) or is_nan(fl(f, 0.0)):
		return {}
	var y0 := at(f, x0)
	var y_int := at(f, 0)
	if paper == 2 and not (fair(y0) and (not Answer.needs_rounding(y_int) or fair(y_int))):
		return {}
	if paper == 1 and not (simple(y0) and simple(y_int)):
		return {}
	return {"f": f, "x0": x0, "y0": y0, "y_int": y_int, "fam": fam}


static func _grid(rng: Seeded) -> Dictionary:
	var f := poly([rng.int_in(-4, 4), ExtensionViews.nonzero(rng, -3, 3)]) if rng.chance(0.4) \
		else poly([rng.int_in(-4, 6), rng.int_in(-2, 2), [1, -1][rng.int_in(0, 1)]])
	var x0 := Q.new(ExtensionViews.nonzero(rng, -4, 4))
	var y0 := at(f, x0)
	if absi(y0.n) > 9:
		return {}
	return {"f": f, "x0": x0, "y0": y0, "y_int": at(f, 0), "fam": "grid"}


static func _notation(rng: Seeded, linear: bool) -> Dictionary:
	var f: Dictionary
	if linear or rng.chance(0.5):
		f = poly([ExtensionViews.nonzero(rng, -7, 7), [2, 3, 4, 5, -2, -3][rng.int_in(0, 5)]])
	else:
		f = poly([rng.int_in(-5, 6), ExtensionViews.nonzero(rng, -4, 4), 1])
	var a := rng.int_in(1, 3)
	return {"f": f, "a": Q.new(a), "x0": Q.new(a), "y0": at(f, a), "y_int": at(f, 0), "fam": "notation"}


# ── roots ────────────────────────────────────────────────────

static func _roots(rng: Seeded, paper: int, offset: bool) -> Dictionary:
	var f: Dictionary
	var zs: Array
	var k := Q.new(0)
	if paper == 2:
		var a := tenths(rng, -25, 25)
		var b := tenths(rng, -60, 60)
		var c := tenths(rng, -60, 60)
		if offset:
			k = Q.new(ExtensionViews.nonzero(rng, -6, 9))
		var disc: float = b.to_float() * b.to_float() - 4.0 * a.to_float() * (c.to_float() - k.to_float())
		if a.is_zero() or disc < 1.0:
			return {}
		var rt := sqrt(disc)
		var r1 := (-b.to_float() - rt) / (2.0 * a.to_float())
		var r2 := (-b.to_float() + rt) / (2.0 * a.to_float())
		zs = [GdcKit.qf(minf(r1, r2)), GdcKit.qf(maxf(r1, r2))]
		if not (fair(zs[0]) and fair(zs[1])) or zs[1].sub(zs[0]).to_float() < 0.5 or c.is_zero():
			return {}
		f = poly([c, b, a])
		return {"f": f, "zs": zs, "k": k, "y_int": c, "fam": "quad", "x0": zs[0], "y0": k}
	var a := [1, 1, -1, 2, -2][rng.int_in(0, 4)]
	if not offset and rng.chance(0.25):
		var p := rng.int_in(1, 4)
		return {"f": poly([0, -p * p, 0, 1]), "zs": [Q.new(-p), Q.new(0), Q.new(p)], "k": k, "y_int": Q.new(0), "fam": "cubic", "p": p, "x0": Q.new(p), "y0": k}
	var p := ExtensionViews.nonzero(rng, -5, 5)
	var q := ExtensionViews.nonzero(rng, -5, 6)
	if p >= q:
		return {}
	if offset:
		k = Q.new(ExtensionViews.nonzero(rng, -6, 9))
	f = poly([a * p * q + k.n, -a * (p + q), a])
	return {"f": f, "zs": [Q.new(p), Q.new(q)], "k": k, "y_int": at(f, 0), "fam": "quad", "a": Q.new(a), "p": Q.new(p), "q": Q.new(q), "x0": Q.new(p), "y0": k}


## a(x − p)(x − q) as written: "2(x + 1)(x − 3)".
static func factorised(s: Dictionary) -> String:
	if s.fam == "cubic":
		return "%s(%s)(%s)" % [s.v, Answer.x_minus(Q.new(-s.p)), Answer.x_minus(Q.new(s.p))]
	return Fmt.factorised(s.a, s.p, s.q)


# ── model ────────────────────────────────────────────────────

static func _model(rng: Seeded, paper: int, want: String) -> Dictionary:
	var ctx: String = want if want != "any" else rng.pick(CTXS)
	var s := {"ctx": ctx, "dom_end": Q.new(0), "tneg": null}
	s.merge({"ball": {"name": "h", "v": "t"}, "cost": {"name": "C", "v": "n"}, "pop": {"name": "P", "v": "t"}, "cool": {"name": "T", "v": "t"}}[ctx])
	match ctx:
		"ball":
			if not _ball(rng, paper, s):
				return {}
		"cost":
			var f0: Q = Q.new(rng.int_in(4, 30) * 5, 2 if paper == 2 else 1)
			var v0: Q = Q.new(rng.int_in(5, 19), 4) if paper == 2 else Q.new(rng.int_in(2, 12))
			s.f = poly([f0, v0])
			s.x0 = Q.new(rng.int_in(8, 40))
			s.tstar = Q.new(rng.int_in(12, 60))
			s.target = at(s.f, s.tstar)
			if s.tstar.eq(s.x0):
				return {}
		"pop":
			if paper == 2:
				s.f = {"fam": "exp", "A": Q.new(rng.int_in(12, 95) * 10), "b": Q.new(rng.int_in(102, 135), 100), "c": Q.new(0)}
				s.x0 = tenths(rng, 15, 85)
				s.target = Q.new(roundi(s.f.A.to_float() * rng.int_in(21, 45) / 100.0) * 10)
				s.tstar = GdcKit.qf(log(s.target.to_float() / s.f.A.to_float()) / log(s.f.b.to_float()))
			else:
				var b: int = [2, 3][rng.int_in(0, 1)]
				s.f = {"fam": "exp", "A": Q.new([50, 100, 200, 300][rng.int_in(0, 3)]), "b": Q.new(b), "c": Q.new(0)}
				s.x0 = Q.new(rng.int_in(1, 3))
				s.tstar = Q.new(rng.int_in(2, 4))
				s.target = at(s.f, s.tstar)
				if s.tstar.eq(s.x0):
					return {}
		"cool":
			var room: int = rng.int_in(16, 24)
			if paper == 2:
				var kk := Q.new(rng.int_in(2, 9), 100)
				s.f = {"fam": "expe", "A": Q.new(rng.int_in(50, 72)), "k": kk.neg(), "c": Q.new(room)}
				s.x0 = Q.new(rng.int_in(3, 25))
				s.target = Q.new(room + rng.int_in(12, 40))
				s.tstar = GdcKit.qf(log(s.f.A.to_float() / (s.target.to_float() - room)) / kk.to_float())
			else:
				s.f = {"fam": "exp", "A": Q.new([40, 60, 64, 80][rng.int_in(0, 3)]), "b": Q.new(1, 2), "c": Q.new(room)}
				s.x0 = Q.new(rng.int_in(1, 2))
				s.tstar = Q.new(3)
				s.target = at(s.f, s.tstar)
	s.y0 = at(s.f, s.x0)
	s.y_int = at(s.f, 0)
	s.fam = "model"
	if paper == 2 and ctx != "cost" and not (fair(s.y0) and fair(s.tstar)):
		return {}
	return s


## h(t) = −at² + bt + c: Paper 1 is −5(t − T)(t + r), Paper 2 has a = 4.9, a target
## below the start, and the positive root to find.
static func _ball(rng: Seeded, paper: int, s: Dictionary) -> bool:
	if paper == 2:
		var b := tenths(rng, 62, 195)
		var c := tenths(rng, 13, 290)
		s.f = poly([c, b, Q.new(-49, 10)])
		var land := _ball_roots(s.f, Q.new(0))
		s.dom_end = GdcKit.qf(land[1])
		s.target = Q.new(0) if rng.chance(0.5) else Q.new(floori(c.to_float() * 0.6))
		var r := _ball_roots(s.f, s.target)
		s.tstar = GdcKit.qf(r[1])
		s.tneg = GdcKit.qf(r[0])
		s.x0 = tenths(rng, 3, maxi(4, floori(land[1] * 9.0)))
		if not (fair(s.tneg) and fair(s.dom_end)) or s.tneg.to_float() >= 0.0 or s.x0.to_float() >= land[1]:
			return false
		return true
	var t_end := rng.int_in(2, 6)
	var r := rng.int_in(1, 3)
	if t_end <= r:
		return false
	s.f = poly([5 * t_end * r, 5 * (t_end - r), -5])
	s.dom_end = Q.new(t_end)
	var t1 := rng.int_in(t_end - r + 1, t_end)
	s.tstar = Q.new(t1)
	s.tneg = Q.new(t_end - r - t1)
	s.target = at(s.f, t1)
	s.x0 = Q.new(rng.int_in(1, t_end - 1))
	return s.tneg.sign() < 0


## The two roots of h(t) = y, smaller first.
static func _ball_roots(f: Dictionary, y: Q) -> Array:
	var a: float = f.co[2].to_float()
	var b: float = f.co[1].to_float()
	var c: float = f.co[0].to_float() - y.to_float()
	var rt := sqrt(b * b - 4.0 * a * c)
	var r1 := (-b + rt) / (2.0 * a)
	var r2 := (-b - rt) / (2.0 * a)
	return [minf(r1, r2), maxf(r1, r2)]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
