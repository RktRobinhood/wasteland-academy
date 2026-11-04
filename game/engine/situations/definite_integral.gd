class_name DefiniteIntegralSituation
extends RefCounted
## The `definite-integral` situation (curriculum/question-types.json): an integrand and
## limits, a region, an integral with one letter left to find, or a rate in a story
## (SL5.11 and SL5.5, FAL-724). Polynomials are held as coefficients, highest power first,
## and worked out exactly. Paper 2 cells ask to 3 s.f., and a function with e or sin is
## integrated numerically here and again by the SymPy checker (tools/check_answers.py).
##
## need.ask is the unknown. generate() returns a Dictionary with ask and paper, plus the
## numbers its builder reads (see definite_integral_views.gd).

const TRIES := 400
## Simpson panels: far past the 9 decimal places the engine keeps.
const PANELS := 2000
const NICE_D := [3, 4, 6]


static func nz(rng: Seeded, lo: int, hi: int) -> int:
	return ExtensionViews.nonzero(rng, lo, hi)


## The exact value of the integral of a polynomial from lo to hi.
static func integral(coeffs: Array, lo: Variant, hi: Variant) -> Q:
	var out := Q.new(0)
	var n := coeffs.size()
	for i in n:
		var p: int = n - i
		var c := Q.of(coeffs[i]).div(p)
		out = out.add(c.mul(_pow(Q.of(hi), p).sub(_pow(Q.of(lo), p))))
	return out


static func _pow(x: Q, n: int) -> Q:
	var out := Q.new(1)
	for i in n:
		out = out.mul(x)
	return out


static func at(coeffs: Array, x: Variant) -> Q:
	var out := Q.new(0)
	for c in coeffs:
		out = out.mul(Q.of(x)).add(Q.of(c))
	return out


## Simpson's rule on [a, b].
static func simpson(f: Callable, a: float, b: float) -> float:
	var h := (b - a) / PANELS
	var total: float = f.call(a) + f.call(b)
	for i in range(1, PANELS):
		total += (4.0 if i % 2 == 1 else 2.0) * f.call(a + i * h)
	return total * h / 3.0


## a(x − r)(x − t) as coefficients.
static func quad(a: int, r: int, t: int) -> Array:
	return [a, -a * (r + t), a * r * t]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "evaluate-polynomial")
	var paper := int(need.get("paper", 1))
	var s := {"ask": ask, "paper": paper, "fam": ""}
	for i in TRIES:
		var d := _try(ask, paper, rng)
		if not d.is_empty():
			return s.merged(d, true)
	return {}


static func _try(ask: String, paper: int, rng: Seeded) -> Dictionary:
	match ask:
		"evaluate-polynomial":
			var lo := rng.int_in(-2, 3)
			var d := {"coeffs": [nz(rng, -6, 6), nz(rng, -7, 7), nz(rng, -9, 9)], "lo": lo, "hi": lo + rng.int_in(1, 4)}
			var v := integral(d.coeffs, d.lo, d.hi)
			if v.is_zero() or (paper == 2 and not GdcKit.fair(v.to_float())):
				return {}
			return d
		"evaluate-roots":
			var m := rng.int_in(1, 3)
			return {"a": 3 * nz(rng, -3, 3), "b": nz(rng, -6, 6), "m": m, "n": m + rng.int_in(1, 3)}
		"evaluate-trig":
			var fam: String = rng.pick(["sin", "sin", "cos"])
			return {"fam": fam, "a": 2 * nz(rng, -5, 5), "b": nz(rng, -6, 6), "top": 2 if fam == "cos" else rng.pick([1, 2])}
		"evaluate-log":
			var lo := rng.int_in(0, 3)
			var c := rng.int_in(1 - lo, 4)
			var hi := lo + rng.int_in(1, 6)
			return {"k": nz(rng, -5, 6), "c": c, "lo": lo, "hi": hi} if c != 0 else {}
		"evaluate-exp":
			var a: int = rng.pick([1, 2, 3])
			return {"a": a, "k": a * rng.pick([1, 1, 2, 3]) if rng.chance(0.7) else rng.int_in(1, 5), "n": rng.int_in(1, 3)}
		"evaluate-odd-even":
			return {"p": nz(rng, -4, 4), "q": 3 * nz(rng, -3, 3), "r": nz(rng, -6, 6), "t": nz(rng, -5, 5), "a": rng.int_in(1, 3)}
		"evaluate-linear":
			var lo := rng.int_in(0, 4)
			var hi := lo + rng.int_in(2, 6)
			var m := nz(rng, -3, 4)
			var c := rng.int_in(1, 12)
			return {"m": m, "c": c, "lo": lo, "hi": hi} if m * lo + c > 0 and m * hi + c > 0 else {}
		"area-above-axis", "area-below-axis":
			var r := rng.int_in(-4, 2)
			var t := r + rng.int_in(2, 6)
			var a: int = rng.pick([1, 1, 2, 3, 6])
			return {"r": r, "t": t, "a": -a if ask == "area-above-axis" else a}
		"area-across-root":
			var r := rng.int_in(-3, 2)
			var t := r + 2 * rng.int_in(1, 3)
			return {"r": r, "t": t, "a": rng.pick([1, 1, 2, 3, -1, -2, 6]), "hi": t + rng.int_in(1, 3)}
		"area-gdc":
			return _area_gdc(rng)
		"area-symmetry":
			var sym: String = rng.pick(["sin", "cubic"])
			if sym == "sin":
				return {"fam": sym, "k": rng.int_in(2, 9)}
			return {"fam": sym, "k": rng.pick([1, 2, 4]), "a": rng.int_in(1, 3)}
		"unknown-upper-limit":
			var a := 2 * rng.int_in(1, 3)
			var b := a * rng.int_in(-2, 3)
			var p := rng.int_in(-1, 3)
			var k := p + rng.int_in(2, 6)
			return {"a": a, "b": b, "p": p, "k": k} if -2 * b / a - k < p and b != 0 else {}
		"unknown-limit-log":
			return {"a": rng.int_in(1, 9), "k": rng.int_in(1, 6)}
		"unknown-limit-trig":
			var dd: int = rng.pick(NICE_D)
			var ns: Array = [1, 2, 3, 4] if dd == 6 else [1, 3, 5]
			return {"d": dd, "n": rng.pick(ns)}
		"unknown-stretch":
			var lo: int = rng.pick([0, 0, 1])
			return {"k": rng.pick([1, 2, 3, 4, 5, 6]), "lo": lo, "hi": lo + rng.int_in(1, 3)}
		"region-tangent":
			return {"a": rng.pick([1, 1, 2, 3]), "r": rng.int_in(0, 3), "p": 2 * rng.int_in(1, 2)}
		"region-line-curve":
			var p: int = rng.pick([1, 2, 2, 3])
			var m: int = rng.pick([1, 2, 3])
			var q: int = p * rng.pick([2, 3]) if rng.chance(0.6) else p + rng.int_in(1, 3)
			return {"p": p, "m": m, "q": q}
		"total-from-rate", "amount-with-start", "interpret-integral":
			return _rate(paper, rng)
		"total-from-rate-graph":
			var ts: Array = [0]
			var ys: Array = [rng.int_in(0, 4) * 2]
			for j in rng.int_in(3, 4):
				ts.append(ts[-1] + rng.pick([2, 2, 4]))
				ys.append(rng.int_in(1, 6) * 2)
			var c := rng.int_in(0, 3)
			return {"ctx": c, "ts": ts, "ys": ys}
		"time-to-reach":
			var c := rng.int_in(0, 3)
			var a := 2 * rng.int_in(1, 4)
			return {"ctx": c, "a": a, "b": rng.int_in(1, 9), "T": rng.int_in(2, 12)}
	return {}


## f(x) = A sin(wx)e^(−kx), or ax + b − c e^(px): a region above and one below the axis.
static func _area_gdc(rng: Seeded) -> Dictionary:
	var fam: String = rng.pick(["wave", "line"])
	var d := {"fam": fam}
	if fam == "wave":
		d.A = rng.int_in(2, 9)
		d.w = rng.pick([Q.new(4, 5), Q.new(1), Q.new(6, 5), Q.new(3, 2)])
		d.k = rng.pick([Q.new(1, 10), Q.new(1, 5), Q.new(3, 10)])
		d.lo = 0
		d.hi = rng.int_in(4, 6)
	else:
		d.a = rng.int_in(1, 4)
		d.b = rng.int_in(1, 5)
		d.c = rng.int_in(1, 3)
		d.p = rng.pick([Q.new(2, 5), Q.new(1, 2), Q.new(3, 5)])
		d.lo = 0
		d.hi = rng.int_in(3, 6)
	var f := curve(d)
	var zs := GdcKit.zeros(f, float(d.lo) + 0.001, float(d.hi) - 0.001)
	if zs.size() != 1 or zs[0] - d.lo < 0.5 or d.hi - zs[0] < 0.5:
		return {}
	d.z = zs[0]
	var a1: float = simpson(f, float(d.lo), zs[0])
	var a2: float = simpson(f, zs[0], float(d.hi))
	d.area = absf(a1) + absf(a2)
	d.net = absf(a1 + a2)
	if not GdcKit.fair(d.area) or not GdcKit.fair(d.net) or absf(a1) < 0.3 or absf(a2) < 0.3:
		return {}
	return d


static func curve(d: Dictionary) -> Callable:
	if d.fam == "wave":
		var A := float(d.A)
		var w: float = d.w.to_float()
		var k: float = d.k.to_float()
		return func(x: float) -> float: return A * sin(w * x) * exp(-k * x)
	var a := float(d.a)
	var b := float(d.b)
	var c := float(d.c)
	var p: float = d.p.to_float()
	return func(x: float) -> float: return a * x + b - c * exp(p * x)


## A rate on [0, T]: a positive polynomial on Paper 1, a model on Paper 2.
static func _rate(paper: int, rng: Seeded) -> Dictionary:
	var d := {"ctx": rng.int_in(0, 3), "T": rng.int_in(2, 6), "start": 10 * rng.int_in(2, 30)}
	if paper == 1:
		d.fam = "poly"
		d.coeffs = [3 * rng.int_in(0, 2), 2 * rng.int_in(1, 5), rng.int_in(1, 9)]
		if d.coeffs[0] == 0:
			d.coeffs = d.coeffs.slice(1)
		return d
	d.fam = rng.pick(["sin", "exp"])
	d.A = rng.int_in(10, 40)
	d.B = rng.int_in(2, 9)
	d.w = rng.pick([Q.new(2, 5), Q.new(1, 2), Q.new(4, 5)])
	var f := rate_fn(d)
	d.total = simpson(f, 0.0, float(d.T))
	d.end = f.call(float(d.T))
	return d if GdcKit.fair(d.total) and GdcKit.fair(d.end) else {}


## The rate as a function of t on Paper 2.
static func rate_fn(d: Dictionary) -> Callable:
	var A := float(d.A)
	var B := float(d.B)
	var w: float = d.w.to_float()
	if d.fam == "sin":
		return func(t: float) -> float: return A + B * sin(w * t)
	return func(t: float) -> float: return A * exp(-w * t) + B


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
