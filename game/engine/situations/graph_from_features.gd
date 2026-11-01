class_name GraphFromFeaturesSituation
extends RefCounted
## The `graph-from-features` situation (curriculum/question-types.json): exact features
## found without a calculator (intercepts, a vertex, a maximum, an asymptote, endpoints),
## and the sketch that shows them (FAL-420). fn-sketch-from-features is built on it.
## Paper 1: every feature is exact.
##
## generate() returns:
##   fam   "quadratic" a(x − r1)(x − r2); "interval" a model on 0 ≤ t ≤ T: kind "height"
##         h(t) = a·t(T − t) or "velocity" v(t) = (t − p)(t − q); "levels" kind "texp"
##         y = a·xe^(−x) (a zero at 0, a maximum at (1, a/e), the long-run level 0) or
##         "cooling" T(t) = R + De^(−kt); "trig" y = A sin x or A cos x on 0 ≤ x ≤ 2π;
##         "conditions" a curve through (0, y0) with a zero at z < 0, increasing
##   a, r1, r2, h, k, c (quadratic: the vertex (h, k) and y-intercept c); T, p, q
##   (interval); R, D, kk (cooling); A, fn (trig); y0, z (conditions); all Q
##   x0, x1   where the graph is drawn (floats)
##   paper    1
##
## need (all optional): fam, kind, a_neg (a < 0, for "opens upwards for a < 0").

const TRIES := 400


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	# The stream's first draw leans low (FAL-460), so it is spent first.
	rng.int_in(0, 1)
	var fam: String = need.get("fam", "quadratic")
	for i in TRIES:
		var s := _draw(rng, fam, need)
		if not s.is_empty():
			s.fam = fam
			s.paper = 1
			return s
	push_error("GraphFromFeaturesSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, fam: String, need: Dictionary) -> Dictionary:
	var s := {}
	match fam:
		"quadratic":
			var a: Q = [Q.new(1), Q.new(-1), Q.new(2), Q.new(-2), Q.new(1, 2), Q.new(-1, 2)][rng.int_in(0, 5)]
			if need.get("a_neg", false) and a.sign() > 0:
				a = a.neg()
			var r1 := rng.int_in(-5, 3)
			var r2 := r1 + rng.int_in(2, 6)
			if r1 == 0 or r2 == 0 or (r1 + r2) == 0:
				return {}
			s.a = a
			s.r1 = Q.new(r1)
			s.r2 = Q.new(r2)
			s.h = Q.new(r1 + r2, 2)
			s.k = a.mul(s.h.sub(s.r1)).mul(s.h.sub(s.r2))
			s.c = a.mul(Q.new(r1 * r2))
			# Distinct features in a window about 20 high.
			var ys := [s.k.to_float(), s.c.to_float(), 0.0]
			if ys.max() - ys.min() > 18.0 or absf(s.k.to_float()) < 1.0 or s.c.eq(s.k):
				return {}
			s.x0 = minf(r1, 0.0) - 1.5
			s.x1 = maxf(r2, 0.0) + 1.5
		"interval":
			var kind: String = need.get("kind", "height" if rng.chance(0.5) else "velocity")
			s.kind = kind
			if kind == "height":
				s.T = Q.new([2, 4, 6][rng.int_in(0, 2)])
				s.a = Q.new([1, 2, 5][rng.int_in(0, 2)] if s.T.n < 6 else [1, 2][rng.int_in(0, 1)])
				var top: float = s.a.to_float() * pow(s.T.to_float() / 2.0, 2)
				if top > 20.0:
					return {}
			else:
				s.p = Q.new(rng.int_in(1, 2))
				s.q = s.p.add(Q.new(rng.int_in(2, 4)))
				s.T = s.q.add(Q.new(rng.int_in(1, 2)))
			s.x0 = 0.0
			s.x1 = s.T.to_float()
		"levels":
			var kind: String = need.get("kind", "texp")
			s.kind = kind
			if kind == "texp":
				s.a = Q.new([2, 3, 4, 5, 6, 8][rng.int_in(0, 5)])
				s.x0 = 0.0
				s.x1 = 6.0
			else:
				s.R = Q.new([15, 18, 20, 22][rng.int_in(0, 3)])
				s.D = Q.new(rng.int_in(4, 7) * 10)
				s.kk = Q.new([1, 2, 1, 5][rng.int_in(0, 3)], 10)
				s.x0 = 0.0
				s.x1 = 40.0 if s.kk.to_float() < 0.15 else 25.0
		"trig":
			s.A = Q.new(rng.int_in(1, 3))
			s.fn = "sin" if rng.chance(0.5) else "cos"
			s.x0 = 0.0
			s.x1 = TAU
		"conditions":
			s.y0 = Q.new(rng.int_in(1, 4))
			s.z = Q.new(-rng.int_in(1, 3))
			s.x0 = s.z.to_float() - 2.0
			s.x1 = 3.0
	return s


## The function at x.
static func at(s: Dictionary, x: float) -> float:
	match s.fam:
		"quadratic":
			return s.a.to_float() * (x - s.r1.to_float()) * (x - s.r2.to_float())
		"interval":
			if s.kind == "height":
				return s.a.to_float() * x * (s.T.to_float() - x)
			return (x - s.p.to_float()) * (x - s.q.to_float())
		"levels":
			if s.kind == "texp":
				return s.a.to_float() * x * exp(-x)
			return s.R.to_float() + s.D.to_float() * exp(-s.kk.to_float() * x)
		"trig":
			return s.A.to_float() * (sin(x) if s.fn == "sin" else cos(x))
		"conditions":
			# y0 (e^(x/2) − e^(z/2)) / (1 − e^(z/2)): through (0, y0), zero at z, increasing.
			var ez := exp(s.z.to_float() / 2.0)
			return s.y0.to_float() * (exp(x / 2.0) - ez) / (1.0 - ez)
	return NAN


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
