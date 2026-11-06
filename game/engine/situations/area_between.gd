class_name AreaBetweenSituation
extends RefCounted
## The `area-between` situation (curriculum/question-types.json): two curves and the region
## between them (FAL-751, t5-area-between-curves). Paper 1 keeps every meeting point whole, or a
## landmark angle, and works exactly in Q. Paper 2 has curves that need a calculator: the meeting
## points come from GdcKit.zeros and the areas from Simpson's rule, and the SymPy checker
## (tools/check_answers.py) finds both again with mpmath.
##
## need.ask is the unknown (see AreaBetweenViews). generate() returns a Dictionary:
##   ask, paper, rep
##   a, r, t, p, q, par, line, gap      a parabola a(x − r)(x − t) and the chord at x = p and x = q
##   par_top                            whether the parabola is the upper curve
##   top, bot, p, q, gap                two parabolas, as coefficients
##   f, g, a, b, c, hi, lo              curves that swap over: at a, b, c, or at b inside [lo, hi]
##   fam, A, B, m, n, k, w ...          the families of the other unknowns
##   cf, cg, lo, hi, z, area, ...       Paper 2: two curves as dictionaries (see text() and fn())
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 900
const PANELS := 1200
## Paper 2: meeting points this far apart, and this far from the ends of the domain.
const GAP := 0.8
const END_GAP := 0.25
const MIN_PIECE := 0.3
const MAX_COEFF := 40
const MAX_HEIGHT := 30

## A value is [c0, c1, r], which is c0 + c1√r, each c whole or [n, d]. Angles are [n, d], as nπ/d.
## A Paper 1 pair, for A = 1: F is the antiderivative of top − bot, and `wrong` is the size of the
## integral of top − bot between the x-intercepts x0 and x1 of the top curve.
const TRIG_PAIRS := [
	{"id": "sin-cos", "top": "sin x", "bot": "cos x", "lo": [1, 4], "hi": [5, 4], "F": "−cos x − sin x",
		"Fhi": [0, 1, 2], "Flo": [0, -1, 2], "x0": [0, 1], "x1": [1, 1], "wrong": [2, 0, 1]},
	{"id": "sin2-sin", "top": "sin(2x)", "bot": "sin x", "lo": [0, 1], "hi": [1, 3], "F": "−(1/2) cos(2x) + cos x",
		"Fhi": [[3, 4], 0, 1], "Flo": [[1, 2], 0, 1], "x0": [0, 1], "x1": [1, 2], "wrong": [0, 0, 1]},
	{"id": "sin-sin2", "top": "sin x", "bot": "sin(2x)", "lo": [1, 3], "hi": [1, 1], "F": "−cos x + (1/2) cos(2x)",
		"Fhi": [[3, 2], 0, 1], "Flo": [[-3, 4], 0, 1], "x0": [0, 1], "x1": [1, 1], "wrong": [2, 0, 1]},
	{"id": "sin-cos2", "top": "sin x", "bot": "cos(2x)", "lo": [1, 6], "hi": [5, 6], "F": "−cos x − (1/2) sin(2x)",
		"Fhi": [0, [3, 4], 3], "Flo": [0, [-3, 4], 3], "x0": [0, 1], "x1": [1, 1], "wrong": [2, 0, 1]},
	{"id": "cos-cos2", "top": "cos x", "bot": "cos(2x)", "lo": [0, 1], "hi": [2, 3], "F": "sin x − (1/2) sin(2x)",
		"Fhi": [0, [3, 4], 3], "Flo": [0, 0, 1], "x0": [1, 2], "x1": [3, 2], "wrong": [2, 0, 1]},
]
## Two pieces: `one` on top on the first, `two` on the second, with the size of each piece and
## |net| over the whole interval.
const TRIG_SPLITS := [
	{"id": "sin-cos-half", "one": "cos x", "two": "sin x", "lo": [0, 1], "cross": [1, 4], "hi": [1, 2],
		"p1": [-1, 1, 2], "p2": [-1, 1, 2], "total": [-2, 2, 2], "net": [0, 0, 1]},
	{"id": "sin-cos-pi", "one": "cos x", "two": "sin x", "lo": [0, 1], "cross": [1, 4], "hi": [1, 1],
		"p1": [-1, 1, 2], "p2": [1, 1, 2], "total": [0, 2, 2], "net": [2, 0, 1]},
	{"id": "sin2-sin-pi", "one": "sin(2x)", "two": "sin x", "lo": [0, 1], "cross": [1, 3], "hi": [1, 1],
		"p1": [[1, 4], 0, 1], "p2": [[9, 4], 0, 1], "total": [[5, 2], 0, 1], "net": [2, 0, 1]},
	{"id": "cos-cos2-pi", "one": "cos x", "two": "cos(2x)", "lo": [0, 1], "cross": [2, 3], "hi": [1, 1],
		"p1": [0, [3, 4], 3], "p2": [0, [3, 4], 3], "total": [0, [3, 2], 3], "net": [0, 0, 1]},
]
## A cubic f′ with roots u and v apart has areas u³(u + 2v)/12 and v³(2u + v)/12 times its scale,
## so a scale of 12 keeps both whole. These gaps keep them different and not too large.
const DERIV_GAPS := [[2, 1], [1, 2], [3, 1], [1, 3]]
const DERIV_SCALE := 12


static func nz(rng: Seeded, lo: int, hi: int) -> int:
	return ExtensionViews.nonzero(rng, lo, hi)


# ── Exact pieces ─────────────────────────────────────────────

static func integ(co: Array, lo: Variant, hi: Variant) -> Q:
	return DefiniteIntegralSituation.integral(co, lo, hi)


static func at(co: Array, x: Variant) -> Q:
	return DefiniteIntegralSituation.at(co, x)


## a − b as coefficients, highest power first.
static func minus(a: Array, b: Array) -> Array:
	var n := maxi(a.size(), b.size())
	var out: Array = []
	for i in n:
		var ai: int = i - (n - a.size())
		var bi: int = i - (n - b.size())
		var av := Q.of(a[ai]) if ai >= 0 else Q.new(0)
		var bv := Q.of(b[bi]) if bi >= 0 else Q.new(0)
		out.append(av.sub(bv))
	return out


## k(x − a)(x − b)(x − c) as coefficients.
static func cubic(k: int, a: int, b: int, c: int) -> Array:
	return [k, -k * (a + b + c), k * (a * b + a * c + b * c), -k * a * b * c]


static func small(co: Array) -> bool:
	return co.all(func(c): return absi(int(Q.of(c).to_float())) <= MAX_COEFF)


# ── Curves on Paper 2 ────────────────────────────────────────

## A curve: {"k": "poly", "c": [...]}, {"k": "exp", "A", "w", "c"} for A e^(wx) + c,
## {"k": "sin", "A", "w", "c"} for A sin(wx) + c, {"k": "root", "a", "b"} for √(ax + b), and
## {"k": "unroot", ...} for its inverse (x² − b)/a, and {"k": "rat", "a", "b", "c"} for
## (ax + b)/(x + c), {"k": "unrat", ...} for its inverse.
static func fn(c: Dictionary) -> Callable:
	match c.k:
		"poly":
			var co: Array = c.c.map(func(v): return Q.of(v).to_float())
			return func(x: float) -> float:
				var y := 0.0
				for v in co:
					y = y * x + v
				return y
		"exp":
			var A: float = Q.of(c.A).to_float()
			var w: float = Q.of(c.w).to_float()
			var d: float = Q.of(c.c).to_float()
			return func(x: float) -> float: return A * exp(w * x) + d
		"sin":
			var A: float = Q.of(c.A).to_float()
			var w: float = Q.of(c.w).to_float()
			var d: float = Q.of(c.c).to_float()
			return func(x: float) -> float: return A * sin(w * x) + d
		"root":
			var a := float(c.a)
			var b := float(c.b)
			return func(x: float) -> float: return sqrt(maxf(a * x + b, 0.0))
		"rat":
			var a := float(c.a)
			var b := float(c.b)
			var d := float(c.c)
			return func(x: float) -> float: return (a * x + b) / (x + d)
		"unroot":
			var a := float(c.a)
			var b := float(c.b)
			return func(x: float) -> float: return (x * x - b) / a
	var a := float(c.a)
	var b := float(c.b)
	var d := float(c.c)
	return func(x: float) -> float: return (b - d * x) / (x - a)


## The polynomial with decimals: "0.5x² − 2x + 1".
static func dec_poly(co: Array) -> String:
	var out := ""
	var n := co.size()
	for i in n:
		var p: int = n - 1 - i
		var body: String = "" if p == 0 else ("x" if p == 1 else "x" + Fmt.sup(p))
		if Q.of(co[i]).is_zero():
			continue
		out += GdcKit.first(co[i], body) if out == "" else GdcKit.join(co[i], body)
	return out


static func text(c: Dictionary) -> String:
	match c.k:
		"poly":
			return dec_poly(c.c)
		"exp":
			var w := Q.of(c.w)
			var head: String = "e^x" if w.eq(1) else "e^(%sx)" % Fmt.dec(w)
			return GdcKit.lead(c.A) + head + GdcKit.join(c.c, "")
		"sin":
			var lead: String = GdcKit.lead(c.A)
			var inner: String = "sin x" if Q.of(c.w).eq(1) else "sin(%sx)" % Fmt.dec(c.w)
			return "%s%s%s%s" % [lead, " " if lead != "" and lead != "−" else "", inner, GdcKit.join(c.c, "")]
		"root":
			return "√(%s)" % dec_poly([c.a, c.b])
		"rat":
			return "(%s)/(%s)" % [dec_poly([c.a, c.b]), dec_poly([1, c.c])]
		"unroot":
			return "(%s)/%d" % [dec_poly([1, 0, -c.b]), c.a]
	return "(%s)/(%s)" % [dec_poly([-c.c, c.b]), dec_poly([1, -c.a])]


static func simpson(f: Callable, a: float, b: float) -> float:
	var h := (b - a) / PANELS
	var total: float = f.call(a) + f.call(b)
	for i in range(1, PANELS):
		total += (4.0 if i % 2 == 1 else 2.0) * f.call(a + i * h)
	return total * h / 3.0


## ∫ (f − g) from a to b.
static func between(f: Callable, g: Callable, a: float, b: float) -> float:
	return simpson(func(x: float) -> float: return f.call(x) - g.call(x), a, b)


# ── Drawing the numbers ──────────────────────────────────────

static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "area-line-curve")
	var paper := int(need.get("paper", 1))
	var s := {"ask": ask, "paper": paper, "rep": need.get("rep", "equation")}
	for i in TRIES:
		var d := _try(ask, paper, rng)
		if not d.is_empty():
			return s.merged(d, true)
	return {}


static func _try(ask: String, paper: int, rng: Seeded) -> Dictionary:
	match ask:
		"meeting-limits", "integral-expression", "area-line-curve":
			return _line_curve(rng)
		"area-two-parabolas":
			return _two_parabolas(rng)
		"split-expression":
			return _gdc_swap(rng) if paper == 2 else _swap_cubic(rng)
		"area-split-cubic":
			return _swap_cubic(rng)
		"area-split-bounded":
			return _swap_bounded(rng)
		"area-trig":
			return {"pair": rng.pick(TRIG_PAIRS), "A": rng.int_in(1, 4)}
		"area-trig-split":
			return {"pair": rng.pick(TRIG_SPLITS), "A": rng.int_in(1, 4)}
		"area-exp-lines":
			return _exp_pair(rng)
		"find-shift":
			return _shift(rng)
		"find-parameter":
			return _parameter(rng)
		"derivative-areas":
			return _derivative(rng)
		"gdc-meeting-limits", "gdc-area":
			return _gdc_pair(rng)
		"gdc-area-split":
			return _gdc_swap(rng)
		"inverse-area":
			return _inverse(rng)
		"region-two-lines":
			return _two_lines(rng)
	return {}


## A parabola, and the chord between two of its points. It stays on or above the x-axis between
## them, so the areas under both curves are real areas, and its roots are not the meeting points.
static func _line_curve(rng: Seeded) -> Dictionary:
	var a: int = rng.pick([-1, -1, -2, -3, 1, 1, 2])
	var r := rng.int_in(-4, 1)
	var t := r + rng.int_in(2, 6)
	var p: int
	var q: int
	if a < 0:
		p = rng.int_in(r, t - 1)
		q = rng.int_in(p + 1, t)
	elif rng.chance(0.5):
		p = t + rng.int_in(0, 1)
		q = p + rng.int_in(1, 3)
	else:
		q = r - rng.int_in(0, 1)
		p = q - rng.int_in(1, 3)
	if p == r and q == t:
		return {}
	var m := a * (p + q - r - t)
	var n := a * (p - r) * (p - t) - m * p
	var par: Array = [a, -a * (r + t), a * r * t]
	if not small(par) or absi(m) > MAX_COEFF or absi(n) > MAX_COEFF:
		return {}
	# A tall window would leave the region a sliver.
	if absi(m * p + n) > MAX_HEIGHT or absi(m * q + n) > MAX_HEIGHT:
		return {}
	var top: Array = par if a < 0 else [m, n]
	var bot: Array = [m, n] if a < 0 else par
	return {"a": a, "r": r, "t": t, "p": p, "q": q, "par": par, "line": [m, n], "par_top": a < 0, "gap": minus(top, bot)}


static func _two_parabolas(rng: Seeded) -> Dictionary:
	var p := rng.int_in(-3, 1)
	var q := p + rng.int_in(2, 5)
	var k: int = rng.pick([1, 2, 3])
	var e := rng.int_in(-4, 2)
	var g := e + rng.int_in(1, 5)
	var u: int = rng.pick([1, 1, 2, -1])
	var bot: Array = [u, -u * (e + g), u * e * g]
	var top: Array = [u - k, -u * (e + g) + k * (p + q), u * e * g - k * p * q]
	if top[0] == 0 or not small(top) or not small(bot) or (e == p and g == q):
		return {}
	return {"p": p, "q": q, "e": e, "g": g, "top": top, "bot": bot, "gap": minus(top, bot)}


static func _swap_cubic(rng: Seeded) -> Dictionary:
	var a := rng.int_in(-3, 1)
	var b := a + rng.int_in(1, 3)
	var c := b + rng.int_in(1, 3)
	var k: int = rng.pick([1, 1, -1, 2, -2])
	var m := rng.int_in(-3, 3)
	var n := rng.int_in(-5, 5)
	var gap := cubic(k, a, b, c)
	var f := minus(gap, [-m, -n])
	if not small(f):
		return {}
	var p1 := integ(gap, a, b)
	var p2 := integ(gap, b, c)
	return {"a": a, "b": b, "c": c, "k": k, "f": f, "g": [m, n], "gap": gap, "p1": p1, "p2": p2}


static func _swap_bounded(rng: Seeded) -> Dictionary:
	var lo := rng.int_in(-2, 1)
	var hi := lo + rng.int_in(2, 5)
	var u := lo + rng.int_in(1, hi - lo - 1)
	var v := hi + rng.int_in(1, 3) if rng.chance(0.5) else lo - rng.int_in(1, 3)
	var a: int = rng.pick([1, 1, -1, 2])
	var m := rng.int_in(-3, 3)
	var n := rng.int_in(-4, 4)
	var gap: Array = [a, -a * (u + v), a * u * v]
	var f := minus(gap, [-m, -n])
	if not small(f):
		return {}
	return {"lo": lo, "hi": hi, "u": u, "v": v, "a": a, "f": f, "g": [m, n], "gap": gap, "p1": integ(gap, lo, u), "p2": integ(gap, u, hi)}


static func _exp_pair(rng: Seeded) -> Dictionary:
	var m := rng.int_in(-2, 1)
	var n := m + rng.int_in(1, 3)
	# Lines either side of the y-axis at equal distances are left out: that symmetry is one exam's.
	if n <= 0 or n == -m:
		return {}
	return {"A": rng.int_in(1, 5), "B": rng.int_in(1, 5), "k": rng.pick([1, 1, 2]), "m": m, "n": n}


static func _shift(rng: Seeded) -> Dictionary:
	var lo := rng.int_in(0, 2)
	var w := rng.int_in(2, 5)
	var k := Q.new(rng.int_in(1, 9), rng.pick([1, 2]))
	var d := {"lo": lo, "hi": lo + w, "k": k, "area": k.mul(w), "fam": rng.pick(["poly", "exp", "quot"])}
	d.x = nz(rng, -4, 4)
	d.y = nz(rng, -6, 6)
	d.z = rng.int_in(2, 6)
	return d


static func _parameter(rng: Seeded) -> Dictionary:
	if rng.chance(0.5):
		var a := rng.int_in(1, 3)
		var k := rng.int_in(2, 8)
		return {"fam": "slope", "a": a, "k": k, "area": Q.new(k * k * k, 6 * a * a)}
	var a2 := rng.int_in(1, 2)
	var k2 := rng.int_in(1, 5)
	return {"fam": "cap", "a": a2, "k": k2, "area": Q.new(4 * a2 * k2 * k2 * k2, 3)}


static func _derivative(rng: Seeded) -> Dictionary:
	var gaps: Array = rng.pick(DERIV_GAPS)
	var a := rng.int_in(-3, 0)
	var b: int = a + gaps[0]
	var c: int = b + gaps[1]
	var sign: int = rng.pick([1, -1])
	var co := cubic(sign * DERIV_SCALE, a, b, c)
	return {"fam": rng.pick(["sum", "two"]), "a": a, "b": b, "c": c, "sign": sign, "co": co, "a1": integ(co, a, b).abs_q(),
		"a2": integ(co, b, c).abs_q(), "mid": rng.int_in(4, 20), "name": rng.pick(["f", "g", "h"])}


## Two curves that meet twice on [lo, hi].
static func _gdc_pair(rng: Seeded) -> Dictionary:
	var fam: String = rng.pick(["quad-exp", "sin-line", "exp-line"])
	var cf: Dictionary
	var cg: Dictionary
	var lo: float
	var hi: float
	var roots: Array = []
	match fam:
		"quad-exp":
			var a: Q = rng.pick([Q.new(-1), Q.new(-1), Q.new(-2), Q.new(-1, 2)])
			var r := rng.int_in(-3, 0)
			var t := r + rng.int_in(3, 5)
			cf = {"k": "poly", "c": [a, a.mul(-(r + t)), a.mul(r * t)]}
			cg = {"k": "exp", "A": rng.pick([Q.new(1), Q.new(2), Q.new(1, 2)]), "w": rng.pick([Q.new(3, 10), Q.new(2, 5), Q.new(1, 2), Q.new(-1, 2), Q.new(-2, 5)]), "c": Q.new(0)}
			lo = float(r - 1)
			hi = float(t + 1)
			roots = [r, t]
		"sin-line":
			cf = {"k": "sin", "A": Q.new(rng.int_in(2, 6)), "w": rng.pick([Q.new(1, 2), Q.new(4, 5), Q.new(1), Q.new(6, 5)]), "c": Q.new(rng.int_in(0, 3))}
			cg = {"k": "poly", "c": [rng.pick([Q.new(1, 4), Q.new(1, 2), Q.new(-1, 2), Q.new(1)]), Q.new(rng.int_in(-1, 3))]}
			lo = 0.0
			hi = float(ceili(PI / Q.of(cf.w).to_float()))
		_:
			cf = {"k": "exp", "A": Q.new(rng.int_in(3, 9)), "w": rng.pick([Q.new(-3, 10), Q.new(-1, 2), Q.new(-4, 5)]), "c": Q.new(0)}
			cg = {"k": "poly", "c": [rng.pick([Q.new(-1, 4), Q.new(-1, 2), Q.new(-1)]), Q.new(rng.int_in(2, 7))]}
			lo = 0.0
			hi = 8.0
	var f := fn(cf)
	var g := fn(cg)
	var zs := GdcKit.zeros(func(x: float) -> float: return f.call(x) - g.call(x), lo, hi)
	if zs.size() != 2 or zs[1] - zs[0] < GAP or zs[0] - lo < END_GAP or hi - zs[1] < END_GAP:
		return {}
	var signed := between(f, g, zs[0], zs[1])
	var area := absf(signed)
	if area < 2.0 * MIN_PIECE or not GdcKit.fair(area) or not GdcKit.fair(zs[0]) or not GdcKit.fair(zs[1]):
		return {}
	var d := {"fam": fam, "cf": cf, "cg": cg, "lo": lo, "hi": hi, "z": zs, "area": area, "f_top": signed > 0.0,
		"yz": [f.call(zs[0]), f.call(zs[1])], "int_f": simpson(f, zs[0], zs[1]), "int_g": simpson(g, zs[0], zs[1]), "xint": 0.0}
	if not roots.is_empty():
		d.xint = absf(between(f, g, float(roots[0]), float(roots[1])))
		d.roots = roots
	return d


## Two curves that cross three times on [lo, hi].
static func _gdc_swap(rng: Seeded) -> Dictionary:
	var fam: String = rng.pick(["cubic-exp", "cubic-sin", "sin-line"])
	var cf: Dictionary
	var cg: Dictionary
	var lo: float
	var hi: float
	if fam == "sin-line":
		cf = {"k": "sin", "A": Q.new(rng.int_in(2, 6)), "w": rng.pick([Q.new(4, 5), Q.new(1), Q.new(6, 5), Q.new(3, 2)]), "c": Q.new(0)}
		cg = {"k": "poly", "c": [rng.pick([Q.new(1, 4), Q.new(1, 2), Q.new(1)]), Q.new(rng.int_in(-2, 2))]}
		lo = 0.0
		hi = 2.0 * ceili(PI / Q.of(cf.w).to_float())
	else:
		var r := rng.int_in(-3, 0)
		var t := r + rng.int_in(1, 2)
		var u := t + rng.int_in(1, 2)
		var k: Q = rng.pick([Q.new(1), Q.new(1, 2), Q.new(-1), Q.new(-1, 2)])
		var co: Array = [k, k.mul(-(r + t + u)), k.mul(r * t + r * u + t * u), k.mul(-r * t * u)]
		cf = {"k": "poly", "c": co}
		lo = float(r - 1)
		hi = float(u + 1)
		if fam == "cubic-exp":
			cg = {"k": "exp", "A": rng.pick([Q.new(1), Q.new(1, 2)]), "w": rng.pick([Q.new(1, 2), Q.new(-1, 2), Q.new(3, 10)]), "c": Q.new(0)}
		else:
			cg = {"k": "sin", "A": rng.pick([Q.new(1), Q.new(2)]), "w": rng.pick([Q.new(1, 2), Q.new(4, 5)]), "c": Q.new(0)}
	var f := fn(cf)
	var g := fn(cg)
	var zs := GdcKit.zeros(func(x: float) -> float: return f.call(x) - g.call(x), lo, hi)
	if zs.size() != 3 or zs[1] - zs[0] < 0.5 or zs[2] - zs[1] < 0.5 or zs[0] - lo < END_GAP or hi - zs[2] < END_GAP:
		return {}
	var p1 := between(f, g, zs[0], zs[1])
	var p2 := between(f, g, zs[1], zs[2])
	var area := absf(p1) + absf(p2)
	var net := absf(p1 + p2)
	if minf(absf(p1), absf(p2)) < MIN_PIECE or not GdcKit.fair(area) or not GdcKit.fair(net) or not GdcKit.fair(absf(p1)) or not GdcKit.fair(absf(p2)):
		return {}
	for z in zs:
		if not GdcKit.fair(z):
			return {}
	return {"fam": fam, "cf": cf, "cg": cg, "lo": lo, "hi": hi, "z": zs, "p1": p1, "p2": p2, "area": area, "net": net}


## f and its inverse, which meet twice on y = x.
static func _inverse(rng: Seeded) -> Dictionary:
	var fam: String = rng.pick(["root", "rat"])
	var cf: Dictionary
	var ci: Dictionary
	var disc: int
	var mid: int
	if fam == "root":
		var a := rng.int_in(3, 8)
		var b := -rng.int_in(1, 8)
		disc = a * a + 4 * b
		mid = a
		# The inverse of √(ax + b) on x ≥ 0 is (x² − b)/a.
		cf = {"k": "root", "a": a, "b": b}
		ci = {"k": "unroot", "a": a, "b": b}
	else:
		var a := rng.int_in(2, 7)
		var b := rng.int_in(1, 9)
		var c := rng.int_in(2, 7)
		if a == c:
			return {}
		disc = (c - a) * (c - a) + 4 * b
		mid = a - c
		cf = {"k": "rat", "a": a, "b": b, "c": c}
		ci = {"k": "unrat", "a": a, "b": b, "c": c}
	if disc <= 0:
		return {}
	var rt := roundi(sqrt(float(disc)))
	if rt * rt == disc:
		return {}
	var p := (mid - sqrt(float(disc))) / 2.0
	var q := (mid + sqrt(float(disc))) / 2.0
	if q - p < GAP:
		return {}
	if fam == "root":
		if p < float(-cf.b) / float(cf.a) + 0.05 or p < 0.1:
			return {}
	elif p <= float(-cf.c) + 0.3 or q >= float(cf.a) - 0.3:
		return {}
	var f := fn(cf)
	var half := simpson(func(x: float) -> float: return f.call(x) - x, p, q)
	var area := 2.0 * absf(half)
	if not GdcKit.fair(area) or not GdcKit.fair(p) or not GdcKit.fair(q) or absf(half) < MIN_PIECE:
		return {}
	return {"fam": fam, "cf": cf, "cg": ci, "z": [p, q], "area": area, "half": absf(half), "f_top": half > 0.0}


## y = A e^(wx), the line M: y = mx through the origin, and the line L across them. The top edge
## changes from M to the curve at P.
static func _two_lines(rng: Seeded) -> Dictionary:
	var cf := {"k": "exp", "A": Q.new(rng.int_in(4, 20)), "w": rng.pick([Q.new(-1, 2), Q.new(-3, 10), Q.new(-2, 5)]), "c": Q.new(0)}
	var m: Q = rng.pick([Q.new(1), Q.new(1, 2), Q.new(2)])
	var c: Q = rng.pick([Q.new(1), Q.new(1, 2), Q.new(3, 2)])
	var cm := {"k": "poly", "c": [m, Q.new(0)]}
	var f := fn(cf)
	var fm := fn(cm)
	var ps := GdcKit.zeros(func(x: float) -> float: return f.call(x) - fm.call(x), 0.0, 12.0)
	if ps.size() != 1:
		return {}
	var xp: float = ps[0]
	# L passes just under P, so it cuts M to the left of P and meets the curve to the right of it,
	# where the curve falls faster than L does.
	var b := Q.new(floori((m.to_float() + c.to_float()) * xp) - rng.int_in(0, 2))
	if b.sign() <= 0:
		return {}
	var cl := {"k": "poly", "c": [c.neg(), b]}
	var fl := fn(cl)
	var xr: float = b.to_float() / (m.to_float() + c.to_float())
	var qs := GdcKit.zeros(func(x: float) -> float: return f.call(x) - fl.call(x), xp, 14.0)
	if qs.is_empty():
		return {}
	var xq: float = qs[0]
	if xp - xr < 0.4 or xq - xp < 0.4 or xr < 0.2:
		return {}
	var p1: float = between(fm, fl, xr, xp)
	var p2: float = between(f, fl, xp, xq)
	var whole: float = between(f, fl, xr, xq)
	var area := p1 + p2
	if p1 < MIN_PIECE or p2 < MIN_PIECE or absf(whole - area) < 0.1 or not GdcKit.fair(area) or not GdcKit.fair(p2) or not GdcKit.fair(whole):
		return {}
	return {"cf": cf, "cm": cm, "cl": cl, "xr": xr, "xp": xp, "xq": xq, "p1": p1, "p2": p2, "area": area, "whole": whole}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
