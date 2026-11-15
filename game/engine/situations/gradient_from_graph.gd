class_name GradientFromGraphSituation
extends RefCounted
## The `gradient-from-graph` situation (curriculum/question-types.json): a curve and the tangent
## at one point, for t5-ext-gradient-from-graph (FAL-777). The tangent at P(a, y₀) has a whole
## gradient m, so it runs through the grid points two units either side of P; y₀ is not m, and
## y₀ ÷ a is not m, so the slips that read the height or the line from the origin go wrong.
##
## generate() returns ask, paper and:
##   tangent-drawn, pick-tangent  deg (2 or 3), c (a fraction), a, y0, m: the curve is
##                                f(x) = c(x − a)^deg + m(x − a) + y₀
##   chord-table                  the same with deg 3 and c a whole number, so the chord over
##                                a ± 0.1 has gradient m + 0.01c
##   compare-two                  the same with deg 2, and xa, xb: two whole x-values whose
##                                gradients differ and whose heights are in the other order;
##                                way ("mixed", "up" or "down") says how the tangents slope
##   gdc-gradient                 family ("exp": e^x − bx² + d, "log": c ln x − bx + d), b, c,
##                                d, a (to 1 d.p.), fp = f′(a) and fa = f(a) as floats. Paper 2.
##
## The clean limits are the checker's too (E14GG_*).

const TRIES := 800
const HALF := 3


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "tangent-drawn")
	for i in TRIES:
		var s := _try(ask, rng)
		if not s.is_empty():
			s.ask = ask
			s.paper = 2 if ask == "gdc-gradient" else 1
			return s
	push_error("GradientFromGraphSituation: no clean situation for %s" % need)
	return {}


## f(x) for the polynomial curves, exactly.
static func value(s: Dictionary, x: Variant) -> Q:
	var u := Q.of(x).sub(Q.new(s.a))
	var p := Q.new(1)
	for k in int(s.deg):
		p = p.mul(u)
	return Q.of(s.c).mul(p).add(Q.new(s.m).mul(u)).add(Q.new(s.y0))


## f′(x) for the polynomial curves, exactly.
static func slope(s: Dictionary, x: Variant) -> Q:
	var u := Q.of(x).sub(Q.new(s.a))
	var p := Q.new(int(s.deg))
	for k in int(s.deg) - 1:
		p = p.mul(u)
	return Q.of(s.c).mul(p).add(Q.new(s.m))


static func fn(s: Dictionary) -> Callable:
	var c: float = Q.of(s.c).to_float()
	return func(x: float) -> float: return c * pow(x - s.a, s.deg) + s.m * (x - s.a) + s.y0


## Whether the curve stays in a readable window on [a − 3, a + 3].
static func _fits(s: Dictionary) -> bool:
	for k in range(-HALF, HALF + 1):
		if absf(value(s, s.a + k).to_float()) > 12.0:
			return false
	return true


static func _try(ask: String, rng: Seeded) -> Dictionary:
	match ask:
		"tangent-drawn", "pick-tangent":
			var deg: int = rng.pick([2, 3])
			var c := Q.new(rng.pick([-1, 1]), rng.pick([2, 4]) if deg == 2 else rng.pick([4, 8]))
			var s := {"deg": deg, "c": c, "a": rng.pick([-2, -1, 1, 2, 3]), "y0": rng.int_in(-5, 5), "m": ExtensionViews.nonzero(rng, -3, 3)}
			if s.y0 == s.m or s.y0 == 0 or Q.new(s.y0, s.a).eq(Q.new(s.m)) or not _fits(s):
				return {}
			# The tangent's grid points stay on the grid's window.
			if absi(s.y0) + 2 * absi(s.m) > 10:
				return {}
			# The four lines through P of pick-tangent are four different lines: the tangent,
			# the line from the origin, the gradient y₀ and the chord to x = a + 2.
			var g := [Q.new(s.m), Q.new(s.y0, s.a), Q.new(s.y0), chord(s)]
			for i in g.size():
				for j in range(i + 1, g.size()):
					if g[i].eq(g[j]):
						return {}
			return s
		"chord-table":
			var s := {"deg": 3, "c": Q.new(ExtensionViews.nonzero(rng, -3, 3)), "a": rng.int_in(1, 5), "y0": rng.int_in(-9, 9), "m": ExtensionViews.nonzero(rng, -6, 6)}
			if s.y0 == s.m or s.y0 == 0:
				return {}
			return s
		"compare-two":
			var s := {"deg": 2, "c": Q.new(rng.pick([-1, 1]), 2), "a": rng.int_in(-1, 1), "y0": rng.int_in(-3, 3), "m": rng.int_in(-2, 2)}
			var xa := rng.int_in(s.a - HALF, s.a + HALF)
			var xb := rng.int_in(s.a - HALF, s.a + HALF)
			if xa >= xb or xa == 0 or xb == 0 or not _fits(s):
				return {}
			var ga := slope(s, xa)
			var gb := slope(s, xb)
			var ya := value(s, xa)
			var yb := value(s, xb)
			if ga.eq(gb) or ya.eq(yb) or ga.lt(gb) == ya.lt(yb):
				return {}
			# Each gradient is clearly up or down, and the steeper one clearly steeper.
			if absf(ga.to_float()) < 1.0 or absf(gb.to_float()) < 1.0 or absf(ga.sub(gb).to_float()) < 1.5:
				return {}
			# The lines from the origin have different gradients.
			if ya.div(Q.new(xa)).eq(yb.div(Q.new(xb))):
				return {}
			s.xa = xa
			s.xb = xb
			s.way = "mixed" if ga.sign() != gb.sign() else ("up" if ga.sign() > 0 else "down")
			return s
		"gdc-gradient":
			var s := {"family": rng.pick(["exp", "log"]), "b": rng.int_in(1, 4), "c": rng.int_in(2, 6), "d": rng.int_in(-5, 5)}
			s.a = rng.int_in(5, 30) / 10.0
			if absf(s.a - roundf(s.a)) < 0.05:
				return {}
			s.fp = fp_of(s, s.a)
			s.fa = fa_of(s, s.a)
			var h := 0.001
			var chord := (fa_of(s, s.a + h) - fa_of(s, s.a - h)) / (2.0 * h)
			if absf(s.fp) < 0.1 or absf(s.fa) < 0.1 or not GdcKit.fair(s.fp) or not GdcKit.fair(s.fa) or not GdcKit.fair(s.fa / s.a):
				return {}
			if GdcKit.S(chord) != GdcKit.S(s.fp):
				return {}
			if GdcKit.S(s.fa) == GdcKit.S(s.fp) or GdcKit.S(s.fa / s.a) == GdcKit.S(s.fp) or GdcKit.S(s.fa) == GdcKit.S(s.fa / s.a):
				return {}
			return s
	return {}


## The gradient of the chord from P to the curve's point at x = a + 2.
static func chord(s: Dictionary) -> Q:
	return value(s, s.a + 2).sub(Q.new(s.y0)).div(Q.new(2))


static func fa_of(s: Dictionary, x: float) -> float:
	if s.family == "exp":
		return exp(x) - s.b * x * x + s.d
	return s.c * log(x) - s.b * x + s.d


static func fp_of(s: Dictionary, x: float) -> float:
	if s.family == "exp":
		return exp(x) - 2.0 * s.b * x
	return s.c / x - s.b


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
