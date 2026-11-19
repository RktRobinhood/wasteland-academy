class_name AiStationarySituation
extends RefCounted
## The `ai-stationary` situation (curriculum/question-types.json): a function and its stationary
## points, worked with technology, for t5-ai-stationary-points (AI-SL5.6, FAL-1000). Every AI
## paper allows a GDC, so every question is Paper 2.
##
## need.ask is the unknown (see AiStationaryViews), need.rep its representation. generate()
## returns a Dictionary with ask, rep and paper (2), and by family (fam):
##   cubic   co = [a, b, c, d] (Q): f(x) = ax³ + bx² + cx + d, with f′(x) = 3ax² + 2bx + c.
##           mode "whole": f′ = 3a(x − p)(x − q) with whole p < q, so differentiating and
##           factorising works; "gdc": one-decimal b, c, d, so only the formula or the GDC gives
##           the zeros, to 3 s.f.; "sym": b = 0, so f′ = 3ax² + c has zeros ±r
##   recip   ra, rb, rc (whole, ra, rb > 0): f(x) = ra·x + rb/x + rc on x > 0, its one stationary
##           point a minimum at x = √(rb/ra)
##   model   a story (model: still, track, turbine, reservoir, flare, drone), co as for a cubic
##           (a = 0 for the quadratic flare and drone), on the domain lo ≤ t ≤ hi
## and, by unknown:
##   want    "maximum" or "minimum" (the local extremum asked), or "greatest" / "least"
##   at      0 or 1: which stationary point a classify question is about
##   kat     2 or 1: which coefficient of a cubic is the letter k (x² or x), with xk its
##           stationary x
##   lo, hi  a domain (greatest-on-domain, local-not-greatest), and win = [x0, x1, y0, y1], the
##           GDC window of a local-extremum-point graph
##   case    greatest-on-domain: "local" (the answer is the stationary value), "end" (an end
##           beats it), "out" (the stationary point of the kind asked is outside the domain)
## The three f′-graph unknowns take DerivativeGraphSituation's curves (dg_ask names its
## unknown there), with paper set to 2.
##
## The numbers are drawn, not taken from any one exam question. The SymPy checker
## (tools/check_answers.py, r2sp_check) reads every value back from the text and works it out again.

const TRIES := 3000
## A 3 s.f. answer is at least this far (a fraction of its last place) from a rounding edge.
const EDGE := 0.04
const DG_ASK := {"extremum-from-gradient-graph": "extremum-from-derivative",
	"increasing-from-gradient-graph": "increasing-past-touch", "pick-f-from-gradient-graph": "pick-f-from-derivative"}
## Stories: [the sign of a (0 for a quadratic), the domain's end hi, lo].
const MODELS := ["still", "track", "turbine", "reservoir", "flare", "drone"]
const CUBIC_MODELS := ["still", "track", "turbine", "reservoir"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "gradient-zero-x")
	var rep: String = need.get("rep", "equation")
	if DG_ASK.has(ask):
		var d := DerivativeGraphSituation.generate(rng, {"ask": DG_ASK[ask]})
		if d.is_empty():
			return {}
		d.dg_ask = DG_ASK[ask]
		d.ask = ask
		d.rep = rep
		d.paper = 2
		return d
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep}
		if _draw(rng, s, str(need.get("angle", ""))):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary, angle: String) -> bool:
	match s.ask:
		"gradient-zero-x":
			return _gradient_zero(rng, s)
		"gradient-zero-given-derivative":
			return _given_derivative(rng, s)
		"coefficient-from-stationary":
			return _coefficient(rng, s)
		"local-extremum-point":
			return _extremum_point(rng, s)
		"extremum-value-in-context":
			return _value_in_context(rng, s, angle)
		"classify-stationary":
			return _classify(rng, s)
		"greatest-on-domain":
			return _on_domain(rng, s)
		"local-not-greatest":
			return _not_greatest(rng, s)
	return false


# ── The maths, shared with the views ─────────────────────────

static func ff(co: Array) -> Array:
	return co.map(func(c): return Q.of(c).to_float())


## f(x) for co = [a, b, c, d].
static func fv(co: Array, x: float) -> float:
	var c := ff(co)
	return ((c[0] * x + c[1]) * x + c[2]) * x + c[3]


## f′(x) = 3ax² + 2bx + c.
static func dv(co: Array, x: float) -> float:
	var c := ff(co)
	return (3.0 * c[0] * x + 2.0 * c[1]) * x + c[2]


## The coefficients of f′, highest power first: [3a, 2b, c] (a quadratic f gives [2b, c]).
static func dco(co: Array) -> Array:
	if Q.of(co[0]).is_zero():
		return [Q.of(co[1]).mul(2), Q.of(co[2])]
	return [Q.of(co[0]).mul(3), Q.of(co[1]).mul(2), Q.of(co[2])]


## The zeros of A x² + B x + C (or B x + C when A is 0), in order; [] when none are real.
static func quad_roots(A: float, B: float, C: float) -> Array:
	if A == 0.0:
		return [] if B == 0.0 else [-C / B]
	var disc := B * B - 4.0 * A * C
	if disc <= 0.0:
		return []
	var r := sqrt(disc)
	var out := [(-B - r) / (2.0 * A), (-B + r) / (2.0 * A)]
	out.sort()
	return out


## The stationary points of f (the zeros of f′), in order.
static func stat(co: Array) -> Array:
	var c := ff(co)
	return quad_roots(3.0 * c[0], 2.0 * c[1], c[2])


## The nature of f at a zero x of f′: "maximum" when f′ goes from + to −.
static func nature(co: Array, x: float) -> String:
	return "maximum" if dv(co, x - 1e-4) > 0.0 else "minimum"


## The x where f has the extremum `want`, from its stationary points.
static func extremum_x(co: Array, want: String) -> float:
	for x in stat(co):
		if nature(co, x) == want:
			return x
	return NAN


## The real zeros of the cubic or quadratic f on [lo, hi]: [] when they can't be found cleanly
## (a zero so close to a turning point that sampling could miss it).
static func f_roots(co: Array, lo: float, hi: float) -> Array:
	var fn := func(x: float) -> float: return fv(co, x)
	var zs := GdcKit.zeros(fn, lo, hi, 4000)
	for z in zs:
		if absf(dv(co, z)) < 0.05 or not clear(z):
			return []
	return zs


## Every real zero of f: [] when there is a clean doubt.
static func all_f_roots(co: Array) -> Array:
	var c := ff(co)
	var lead: float = c[0] if c[0] != 0.0 else c[1]
	var bound := 1.0
	for v in c:
		bound = maxf(bound, 1.0 + absf(v / lead))
	var zs := f_roots(co, -bound - 1.0, bound + 1.0)
	# The count the discriminant gives.
	if c[0] != 0.0:
		var a: float = c[0]
		var b: float = c[1]
		var cc: float = c[2]
		var d: float = c[3]
		var disc := 18.0 * a * b * cc * d - 4.0 * b * b * b * d + b * b * cc * cc - 4.0 * a * cc * cc * cc - 27.0 * a * a * d * d
		if absf(disc) < 1e-6 or zs.size() != (3 if disc > 0.0 else 1):
			return []
	else:
		var disc2: float = c[2] * c[2] - 4.0 * c[1] * c[3]
		if disc2 < 1e-6 or zs.size() != 2:
			return []
	return zs


## The zeros of f′ worked with the constant term kept: 3ax² + 2bx + (c + d) = 0.
static func kept_roots(co: Array) -> Array:
	var c := ff(co)
	if c[0] == 0.0:
		return quad_roots(0.0, 2.0 * c[1], c[2] + c[3])
	return quad_roots(3.0 * c[0], 2.0 * c[1], c[2] + c[3])


static func clear(x: float) -> bool:
	return is_finite(x) and Answer.rounds_clearly(x, EDGE)


## Whether a GDC value is a fair 3 s.f. answer: clear of a rounding edge, not a whole number.
static func fair(x: float) -> bool:
	return is_finite(x) and GdcKit.fair(x)


## x to 3 s.f., as a Q (the value an option shows).
static func q3(x: float) -> Q:
	var r := Answer.parse_number(Fmt.sf(x).replace("−", "-"))
	return r.q if r.ok else GdcKit.qf(x)


static func whole_list(xs: Array) -> bool:
	return xs.all(func(x): return absf(x - roundf(x)) < 1e-9)


## Whether the 3 s.f. texts of a list of lists of values are all different.
static func distinct(texts: Array) -> bool:
	var seen := {}
	for t in texts:
		if seen.has(t):
			return false
		seen[t] = true
	return true


static func xs_text(xs: Array) -> String:
	return ",".join(xs.map(func(x): return Fmt.sf(x)))


# ── The recip family: ra·x + rb/x + rc on x > 0 ──────────────

static func rv(s: Dictionary, x: float) -> float:
	return float(s.ra) * x + float(s.rb) / x + float(s.rc)


static func rmin(s: Dictionary) -> float:
	return sqrt(float(s.rb) / float(s.ra))


static func _recip(rng: Seeded, s: Dictionary) -> bool:
	s.fam = "recip"
	s.ra = rng.int_in(1, 6)
	if rng.chance(0.5):
		var m := rng.int_in(1, 5)
		s.rb = s.ra * m * m
	else:
		s.rb = rng.int_in(2, 60)
	s.rc = ExtensionViews.nonzero(rng, -20, 12)
	var x := rmin(s)
	if s.rb > 80 or x > 8.0:
		return false
	return absf(x - roundf(x)) < 1e-9 or fair(x)


# ── Cubics ───────────────────────────────────────────────────

static func _cubic(rng: Seeded, s: Dictionary, mode: String = "") -> bool:
	s.fam = "cubic"
	s.mode = mode if mode != "" else rng.pick(["whole", "whole", "gdc", "gdc", "sym"])
	match s.mode:
		"whole":
			var a: int = rng.pick([1, -1, 2, -2])
			var p := rng.int_in(-4, 3)
			var q := p + rng.int_in(2, 5)
			if (3 * a * (p + q)) % 2 != 0:
				return false
			s.co = [Q.new(a), Q.new(-3 * a * (p + q) / 2), Q.new(3 * a * p * q), Q.new(ExtensionViews.nonzero(rng, -12, 12))]
		"gdc":
			var a2: Q = rng.pick([Q.new(1, 2), Q.new(1), Q.new(3, 2), Q.new(2), Q.new(-1, 2), Q.new(-1), Q.new(-3, 2), Q.new(-2)])
			s.co = [a2, Q.new(ExtensionViews.nonzero(rng, -60, 60), 10), Q.new(rng.int_in(-120, 120), 10), Q.new(ExtensionViews.nonzero(rng, -90, 90), 10)]
		_:
			var a3: int = rng.pick([1, -1, 2, -2])
			var c: Q
			if rng.chance(0.5):
				var r := rng.int_in(1, 4)
				c = Q.new(-3 * a3 * r * r)
			else:
				c = Q.new(-a3 * rng.int_in(2, 40))
			s.co = [Q.new(a3), Q.new(0), c, Q.new(ExtensionViews.nonzero(rng, -12, 12))]
	var st := stat(s.co)
	if st.size() != 2 or st[1] - st[0] < 0.8 or st[0] < -6.0 or st[1] > 7.0:
		return false
	if s.mode == "gdc":
		return fair(st[0]) and fair(st[1]) and absf(st[0]) > 0.05 and absf(st[1]) > 0.05
	if s.mode == "sym":
		return whole_list(st) or (fair(st[0]) and fair(st[1]))
	return true


## The slips of gradient-zero-x: {"roots": the zeros of f, "kept": the constant kept,
## "pos": the positive zero only}, each a list of values, or absent where it doesn't apply.
static func zero_slips(s: Dictionary) -> Dictionary:
	var out := {}
	if s.fam == "recip":
		var a := float(s.ra)
		var b := float(s.rb)
		var c := float(s.rc)
		var rs := quad_roots(a, c, b).filter(func(x): return x > 0.0)
		if not rs.is_empty() and rs.all(func(x): return clear(x)):
			out.roots = rs
		if a + c > 0.0:
			out.kept = [sqrt(b / (a + c))]
		return out
	# A story's zeros of f from its start on: the time a flare lands, say.
	var rs2: Array = all_f_roots(s.co)
	if s.fam == "model":
		rs2 = rs2.filter(func(x): return x >= float(s.lo))
	if not rs2.is_empty():
		out.roots = rs2
	if not Q.of(s.co[3]).is_zero():
		var k := kept_roots(s.co)
		if not k.is_empty() and k.all(func(x): return clear(x)):
			out.kept = k
	if s.fam == "cubic" and s.mode == "sym":
		out.pos = [stat(s.co)[1]]
	return out


static func answer_xs(s: Dictionary) -> Array:
	if s.fam == "recip":
		return [rmin(s)]
	return stat(s.co)


static func _gradient_zero(rng: Seeded, s: Dictionary) -> bool:
	if s.rep == "words":
		if not _model(rng, s, rng.pick(MODELS)):
			return false
		var st := stat(s.co)
		if not st.all(func(x): return x > float(s.lo) + 0.3 and x < float(s.hi) - 0.3 and fair(x)):
			return false
	elif rng.chance(0.2):
		if not _recip(rng, s):
			return false
	elif not _cubic(rng, s):
		return false
	var ans := answer_xs(s)
	var texts: Array = [xs_text(ans)]
	var slips := zero_slips(s)
	for key in slips:
		for x in slips[key]:
			if not clear(x):
				return false
		texts.append(xs_text(slips[key]))
	return distinct(texts)


# ── f′ given ─────────────────────────────────────────────────

## equation: f′(x) = A x² + B x + C written out, sym (B = 0) a third of the time with the
## extremum asked at the negative zero; words: a cubic model's rate of change.
static func _given_derivative(rng: Seeded, s: Dictionary) -> bool:
	if s.rep == "words":
		if not _model(rng, s, rng.pick(CUBIC_MODELS)):
			return false
		var st := stat(s.co)
		if not st.all(func(x): return x > float(s.lo) + 0.3 and x < float(s.hi) - 0.3):
			return false
		s.want = rng.pick(["maximum", "minimum"])
		return fair(st[0]) and fair(st[1])
	if not _cubic(rng, s, "sym" if rng.chance(0.4) else rng.pick(["whole", "gdc"])):
		return false
	var st2 := stat(s.co)
	# f′ with no x term has zeros ±r, whatever drew it.
	if Q.of(s.co[1]).is_zero():
		s.mode = "sym"
	if s.mode == "sym":
		# The extremum at the negative zero, so the positive zero alone is the slip.
		s.want = nature(s.co, st2[0])
	else:
		s.want = rng.pick(["maximum", "minimum"])
	return Fmt.sf(st2[0]) != Fmt.sf(st2[1])


# ── A coefficient from a stationary point ────────────────────

## f(x) = ax³ + bx² + cx + d with b (kat 2) or c (kat 1) left as k, and f′(xk) = 0. k ends
## within one decimal place; the f(xk) = 0 slip is clear of a rounding edge and reads differently.
static func _coefficient(rng: Seeded, s: Dictionary) -> bool:
	s.fam = "cubic"
	s.mode = "k"
	var a: int = rng.pick([1, -1, 2, -2, 3])
	var b := rng.int_in(-9, 9)
	var c := rng.int_in(-24, 24)
	var d := ExtensionViews.nonzero(rng, -15, 15)
	s.xk = ExtensionViews.nonzero(rng, -4, 4)
	s.kat = 2 if rng.chance(0.5) else 1
	var x: int = s.xk
	var k: Q
	if s.kat == 2:
		# 3ax² + 2kx + c = 0
		k = Q.new(-(3 * a * x * x + c), 2 * x)
		s.co = [Q.new(a), k, Q.new(c), Q.new(d)]
	else:
		# 3ax² + 2bx + k = 0
		k = Q.new(-(3 * a * x * x + 2 * b * x))
		s.co = [Q.new(a), Q.new(b), k, Q.new(d)]
	if not k.mul(10).is_int() or k.is_zero() or absf(k.to_float()) > 40.0:
		return false
	s.k = k
	var st := stat(s.co)
	if st.size() != 2 or st[1] - st[0] < 0.5:
		return false
	var slip := root_slip_k(s)
	return is_finite(slip) and clear(slip) and Fmt.sf(slip) != Fmt.sf(k.to_float()) and absf(slip) < 1000.0


## k from f(xk) = 0 instead of f′(xk) = 0.
static func root_slip_k(s: Dictionary) -> float:
	var x := float(s.xk)
	var c := ff(s.co)
	if s.kat == 2:
		# a x³ + k x² + c x + d = 0
		return -(c[0] * x * x * x + c[2] * x + c[3]) / (x * x)
	return -(c[0] * x * x * x + c[1] * x * x + c[3]) / x


# ── A local maximum or minimum point ─────────────────────────

static func _extremum_point(rng: Seeded, s: Dictionary) -> bool:
	if s.rep == "equation" and rng.chance(0.25):
		if not _recip(rng, s):
			return false
		s.want = "minimum"
		var x := rmin(s)
		var y := rv(s, x)
		return (whole_list([x, y]) or (clear(x) and clear(y) and absf(y) > 0.05)) and absf(y) > 0.5
	if not _cubic(rng, s, rng.pick(["whole", "gdc"])):
		return false
	s.want = rng.pick(["maximum", "minimum"])
	var st := stat(s.co)
	var xe := extremum_x(s.co, s.want)
	var ye := fv(s.co, xe)
	if absf(ye) < 0.5 or (s.mode == "gdc" and not clear(ye)):
		return false
	if s.mode == "whole" and absf(ye) > 200.0:
		return false
	if s.rep != "graph":
		return true
	# A GDC window that shows both turning points, with the curve leaving it through the side
	# beyond the extremum's partner, higher than a maximum (or lower than a minimum).
	var x0 := floori(st[0]) - rng.int_in(1, 2)
	var x1 := ceili(st[1]) + rng.int_in(1, 2)
	var beyond: float = fv(s.co, float(x1)) if (Q.of(s.co[0]).sign() > 0) == (s.want == "maximum") else fv(s.co, float(x0))
	var better: bool = beyond > ye if s.want == "maximum" else beyond < ye
	if not better or absf(beyond - ye) < 0.05 * maxf(1.0, absf(ye)) or not clear(beyond):
		return false
	var ylo := INF
	var yhi := -INF
	for i in 201:
		var y2 := fv(s.co, x0 + (x1 - x0) * i / 200.0)
		ylo = minf(ylo, y2)
		yhi = maxf(yhi, y2)
	if yhi - ylo > 400.0:
		return false
	var pad := maxf(1.0, (yhi - ylo) * 0.1)
	s.win = [x0, x1, floori(ylo - pad), ceili(yhi + pad)]
	return true


# ── Stories ──────────────────────────────────────────────────

## A model's coefficients, built from f′ = 3a(t − p)(t − q) and then rounded, so its zeros are
## GDC values: [a, p range, q range, hi range, the lowest value wanted].
static func _model(rng: Seeded, s: Dictionary, model: String) -> bool:
	s.fam = "model"
	s.model = model
	s.lo = 0
	match model:
		"flare":
			var u := Q.new(rng.int_in(150, 400), 10)
			var h0 := Q.new(rng.int_in(5, 40), 10)
			s.co = [Q.new(0), Q.new(-49, 10), u, h0]
			var top := u.to_float() / 9.8
			s.hi = int(floorf(top * 2.0)) - rng.int_in(0, 1)
			return s.hi > top + 0.5 and fv(s.co, float(s.hi)) > 0.5
		"drone":
			s.lo = rng.int_in(1, 3) * 10
			var A := Q.new(rng.int_in(5, 30), 1000)
			var vm := float(rng.int_in(30, 80)) + rng.int_in(1, 9) / 10.0
			var B := Q.new(roundi(2.0 * A.to_float() * vm * 100.0), 100)
			var C := Q.new(rng.int_in(20, 90))
			s.co = [Q.new(0), A, B.neg(), C]
			s.hi = s.lo + rng.int_in(6, 10) * 10
			var v0: float = stat(s.co)[0]
			return v0 > s.lo + 3.0 and v0 < s.hi - 3.0 and fv(s.co, v0) > 3.0
	var a: float
	var p: float
	var q: float
	var floor_v: float
	match model:
		"still":
			a = rng.int_in(5, 30) / 100.0
			p = rng.int_in(12, 40) / 10.0
			q = p + rng.int_in(25, 60) / 10.0
			floor_v = float(rng.int_in(15, 40))
			s.hi = int(ceilf(q)) + rng.int_in(1, 4)
		"track":
			a = -rng.int_in(10, 60) / 100.0
			p = rng.int_in(8, 30) / 10.0
			q = p + rng.int_in(20, 50) / 10.0
			floor_v = float(rng.int_in(10, 40))
			s.hi = int(ceilf(q)) + rng.int_in(1, 3)
		"turbine":
			a = -rng.int_in(2, 8) / 100.0
			p = rng.int_in(10, 30) / 10.0
			q = p + rng.int_in(60, 110) / 10.0
			floor_v = float(rng.int_in(1, 6))
			s.hi = int(ceilf(q)) + rng.int_in(1, 5)
		_:
			a = rng.int_in(2, 12) / 100.0
			p = rng.int_in(15, 50) / 10.0
			q = p + rng.int_in(40, 70) / 10.0
			floor_v = float(rng.int_in(4, 15))
			s.hi = int(ceilf(q)) + rng.int_in(1, 4)
	var A2 := Q.new(roundi(a * 100.0), 100)
	var B2 := Q.new(roundi(-1.5 * a * (p + q) * 100.0), 100)
	var C2 := Q.new(roundi(3.0 * a * p * q * 100.0), 100)
	var co: Array = [A2, B2, C2, Q.new(0)]
	# d puts the lowest value on [lo, hi] at floor_v.
	var low := INF
	for i in 401:
		low = minf(low, fv(co, float(s.hi) * i / 400.0))
	co[3] = Q.new(roundi(floor_v - low))
	s.co = co
	var st := stat(co)
	return st.size() == 2 and st[0] > 0.3 and st[1] < float(s.hi) - 0.3 and fair(st[0]) and fair(st[1])


## Values of the model at its ends and stationary points, for the domain views.
static func model_ok(s: Dictionary) -> bool:
	for x in [float(s.lo), float(s.hi)] + stat(s.co):
		if not clear(fv(s.co, x)):
			return false
	return true


# ── The greatest or least value of a model ───────────────────

## A story whose stationary point of the kind asked is its greatest (or least) value on the
## domain, by a clear margin; the vertex method gets a quadratic story.
static func _value_in_context(rng: Seeded, s: Dictionary, angle: String) -> bool:
	var model: String
	if angle == "vertex-of-quadratic":
		model = rng.pick(["flare", "drone"])
	else:
		model = rng.pick(MODELS)
	if not _model(rng, s, model):
		return false
	match model:
		"flare":
			s.want = "greatest"
		"drone":
			s.want = "least"
		_:
			s.want = rng.pick(["greatest", "least"])
	var x := extremum_x(s.co, "maximum" if s.want == "greatest" else "minimum")
	if is_nan(x):
		return false
	var y := fv(s.co, x)
	var ends := [fv(s.co, float(s.lo)), fv(s.co, float(s.hi))]
	for e in ends:
		var beaten: bool = e < y if s.want == "greatest" else e > y
		if not beaten or absf(e - y) < 0.03 * absf(y):
			return false
	if not (fair(y) and fair(x) and clear(ends[1]) and y > 0.5):
		return false
	return Fmt.sf(x) != Fmt.sf(y) and Fmt.sf(ends[1]) != Fmt.sf(y) and Fmt.sf(ends[1]) != Fmt.sf(x)


# ── Classify a stationary point ──────────────────────────────

## A whole-mode cubic with its zeros of f′ at least 2 apart; the point asked (at), and test
## points either side where f is not zero.
static func _classify(rng: Seeded, s: Dictionary) -> bool:
	if not _cubic(rng, s, "whole"):
		return false
	var st := stat(s.co)
	if st[1] - st[0] < 1.99:
		return false
	s.at = rng.int_in(0, 1)
	var x: float = st[s.at]
	var h := 0.1 if s.rep == "table" else 1.0
	return absf(fv(s.co, x - h)) > 1e-9 and absf(fv(s.co, x + h)) > 1e-9


# ── The greatest or least value on a domain ──────────────────

## The candidates on the domain: [[x, f(x), "end" or "stationary"], ...].
static func candidates(s: Dictionary) -> Array:
	var out: Array = [[float(s.lo), fv(s.co, float(s.lo)), "end"], [float(s.hi), fv(s.co, float(s.hi)), "end"]]
	for x in stat(s.co):
		if x > float(s.lo) and x < float(s.hi):
			out.append([x, fv(s.co, x), "stationary"])
	return out


static func best(s: Dictionary, cands: Array) -> Array:
	var b: Array = cands[0]
	for c in cands:
		if (c[1] > b[1]) if s.want == "greatest" else (c[1] < b[1]):
			b = c
	return b


static func beats(s: Dictionary, y: float, than: float) -> bool:
	return y > than if s.want == "greatest" else y < than


## equation: a whole cubic on a whole domain; words: a cubic story on 0 ≤ t ≤ hi. case is drawn
## first: the stationary value ("local"), an end that beats it ("end") or, on the equation, the
## stationary point of the kind asked outside the domain ("out").
static func _on_domain(rng: Seeded, s: Dictionary) -> bool:
	var words: bool = s.rep == "words"
	if words:
		if not _model(rng, s, rng.pick(CUBIC_MODELS)):
			return false
		s.hi += rng.int_in(0, 4)
		s.case = "local" if rng.chance(0.5) else "end"
	else:
		if not _cubic(rng, s, "whole"):
			return false
		var r := rng.int_in(0, 9)
		s.case = "local" if r < 5 else ("end" if r < 8 else "out")
	s.want = rng.pick(["greatest", "least"])
	var st := stat(s.co)
	var xs := extremum_x(s.co, "maximum" if s.want == "greatest" else "minimum")
	var xo: float = st[0] if xs == st[1] else st[1]
	if not words:
		var span := rng.int_in(3, 6)
		if s.case == "out":
			# The domain holds the other stationary point, not the one of the kind asked.
			s.lo = int(floorf(xo)) - rng.int_in(1, 2)
			s.hi = s.lo + span
			if xs > s.lo and xs < s.hi:
				return false
		else:
			s.lo = int(floorf(xs)) - rng.int_in(1, span - 1)
			s.hi = s.lo + span
	if not (xs > float(s.lo) and xs < float(s.hi)) and s.case != "out":
		return false
	if not words and s.case != "out" and xo > float(s.lo) and xo < float(s.hi) and rng.chance(0.5):
		return false
	var cands := candidates(s)
	var b := best(s, cands)
	var at_end: bool = b[2] == "end"
	if at_end != (s.case != "local"):
		return false
	# The best is clear of every other candidate.
	for c in cands:
		if c != b and absf(c[1] - b[1]) < (1.0 if not words else 0.02 * maxf(1.0, absf(b[1]))):
			return false
	if words and (not model_ok(s) or absf(b[1] - fv(s.co, xs)) > 0.6 * absf(fv(s.co, xs)) + 5.0 or fv(s.co, float(s.hi)) <= 0.0):
		return false
	var slips := domain_slips(s)
	# Outside the domain, the stationary point asked would beat the answer: the slip to see.
	if s.case == "out" and not slips.has("out"):
		return false
	var texts: Array = [Fmt.sf(b[1])]
	for k in slips:
		texts.append(Fmt.sf(slips[k]))
	if not distinct(texts):
		return false
	if not words:
		return absf(b[1]) < 300.0
	return fair(b[1])


## The slips: "local" (#0 or #2: the stationary value of the kind asked, when an end beats it),
## "out" (#1: a stationary point outside the domain, when it would beat the answer), "inside"
## (#2: with the ends left out, the only stationary value inside), "end" (the other end).
static func domain_slips(s: Dictionary) -> Dictionary:
	var out := {}
	var cands := candidates(s)
	var b := best(s, cands)
	var st := stat(s.co)
	for x in st:
		var y := fv(s.co, x)
		var inside: bool = x > float(s.lo) and x < float(s.hi)
		var kind := nature(s.co, x)
		var asked_kind := "maximum" if s.want == "greatest" else "minimum"
		if inside and kind == asked_kind and b[2] == "end":
			out.local = y
		elif not inside and beats(s, y, b[1]):
			out.out = y
		elif inside and kind != asked_kind and s.case == "out":
			out.inside = y
	for c in cands:
		if c[2] == "end" and c != b:
			out.end = c[1]
	return out


# ── The local maximum is not the greatest ────────────────────

## A cubic (whole on the graph, a story in words) on lo ≤ x ≤ hi, with both stationary points
## inside and an end beyond the local extremum asked: higher than the maximum, or lower than the minimum.
static func _not_greatest(rng: Seeded, s: Dictionary) -> bool:
	var words: bool = s.rep == "words"
	if words:
		if not _model(rng, s, rng.pick(CUBIC_MODELS)):
			return false
		# The first whole end past the local extremum's value, or one more.
		s.want = rng.pick(["maximum", "minimum"])
		var tries := 0
		while far_end(s).is_empty() and tries < 15:
			s.hi += 1
			tries += 1
		s.hi += rng.int_in(0, 1)
	else:
		if not _cubic(rng, s, "whole"):
			return false
		var st0 := stat(s.co)
		s.lo = int(floorf(st0[0])) - rng.int_in(1, 3)
		s.hi = int(ceilf(st0[1])) + rng.int_in(1, 3)
	if not words:
		s.want = rng.pick(["maximum", "minimum"])
	var x := extremum_x(s.co, s.want)
	var y := fv(s.co, x)
	var st := stat(s.co)
	if not st.all(func(v): return v > float(s.lo) + 0.3 and v < float(s.hi) - 0.3):
		return false
	var e := far_end(s)
	if e.is_empty():
		return false
	var ye: float = e[1]
	var other: float = fv(s.co, float(s.hi if e[0] == float(s.lo) else s.lo))
	var margin := 0.03 * maxf(1.0, absf(y))
	if absf(ye - y) < maxf(margin, 1.0 if not words else 0.0) or absf(other - y) < margin:
		return false
	if words and (not model_ok(s) or absf(ye - y) > 0.6 * absf(y) + 5.0 or fv(s.co, float(s.hi)) <= 0.0 or s.hi > 30):
		return false
	return words or maxf(absf(ye), absf(y)) <= 300.0


## The end beyond the local extremum asked, as [x, f(x)], or [] when neither end is.
static func far_end(s: Dictionary) -> Array:
	var y := fv(s.co, extremum_x(s.co, s.want))
	var out: Array = []
	for x in [float(s.lo), float(s.hi)]:
		var v := fv(s.co, x)
		if (v > y) if s.want == "maximum" else (v < y):
			if not out.is_empty():
				return []
			out = [x, v]
	return out


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
