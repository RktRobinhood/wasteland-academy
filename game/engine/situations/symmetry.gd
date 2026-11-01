class_name SymmetrySituation
extends RefCounted
## The `fn-link-symmetry` situation (curriculum/question-types.json): one mirror idea in
## four topics, for the link type fn-link-symmetry (FAL-459). Each form picks its own
## numbers:
##
##   idea      which facts share the mirror idea (fact: normal, trig or ncr)
##   parabola  y = a(x − h)² + k, with a point d left of the axis at height y, and two
##             roots r1, r2 or an equal pair x1, x2 (find-the-mirror)
##   normal    X ~ N(μ, σ²) with a tail p beyond μ + a (or below μ − a), or a central
##             probability q and its interval to nine decimal places
##   ncr       nCr with its mirror n − r, or nCa = nCb (find n)
##   angle     sin θ or cos θ for θ = π/6, π/4 or π/3

const TRIES := 2000
const TAILS := [5, 8, 10, 12, 15, 20, 25, 30, 35, 40]
const CENTRAL := [60, 70, 75, 80, 85, 90, 95, 98, 99]
const THETAS := [[1, 6], [1, 4], [1, 3]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var form: String = need.get("form", "parabola")
	for i in TRIES:
		var s := _draw(rng, form, need)
		if not s.is_empty():
			s.form = form
			return s
	push_error("SymmetrySituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, form: String, need: Dictionary) -> Dictionary:
	match form:
		"idea":
			return {"fact": need.get("fact", rng.pick(["normal", "trig", "ncr"]))}
		"parabola":
			var a: Q = rng.pick([Q.new(1), Q.new(-1), Q.new(2), Q.new(-2), Q.new(1, 2)])
			var h := rng.int_in(-4, 4)
			var k := rng.int_in(-8, 8)
			var d := rng.int_in(1, 4)
			var y := a.mul(d * d).add(k)
			if h == 0 or absi(h) == d or not y.is_int() or absi(y.n) > 16:
				return {}
			var s := {"a": a, "h": Q.new(h), "k": Q.new(k), "d": Q.new(d), "y": y}
			# Two roots on whole numbers: a(x − h)² + k = 0 at h ± w.
			var w2 := Q.new(-k).div(a)
			var w := roundi(sqrt(maxf(0.0, w2.to_float())))
			if need.get("roots", false):
				if w2.sign() <= 0 or not w2.eq(w * w):
					return {}
				s.r1 = Q.new(h - w)
				s.r2 = Q.new(h + w)
			return s
		"normal":
			var mu := 5 * rng.int_in(4, 40)
			var sigma := rng.int_in(2, 15)
			var a: int = rng.int_in(1, 3) * sigma + rng.pick([0, 0, sigma / 2])
			var s := {"mu": Q.new(mu), "sigma": Q.new(sigma), "a": Q.new(a), "p": Q.new(rng.pick(TAILS), 100)}
			if need.get("central", false):
				var q := Q.new(rng.pick(CENTRAL), 100)
				var z := inv_norm(0.5 + q.to_float() / 2.0)
				var z_wrong := inv_norm(q.to_float())
				var lo := mu - z * sigma
				var hi := mu + z * sigma
				for v in [lo, hi, mu - z_wrong * sigma, mu + z_wrong * sigma]:
					if v <= 0.0 or not Answer.rounds_clearly(v) or Fmt.sf(v).ends_with("0"):
						return {}
				s.q = q
				s.z = nine(z)
				s.lo = nine(lo)
				s.hi = nine(hi)
				s.wlo = nine(mu - z_wrong * sigma)
				s.whi = nine(mu + z_wrong * sigma)
			return s
		"mirror":
			# Every context find-the-mirror asks in: the method picks one (build_view).
			var par := _draw(rng, "parabola", {"roots": true})
			var nc := _draw(rng, "ncr", {})
			var nm := _draw(rng, "normal", {})
			if par.is_empty() or nc.is_empty() or nm.is_empty():
				return {}
			# An equal pair on the parabola that is not the roots: h ± e.
			var e := rng.int_in(1, 4)
			if e == par.r2.sub(par.h).n:
				return {}
			par.x1 = par.h.sub(e)
			par.x2 = par.h.add(e)
			par.y2 = par.a.mul(e * e).add(par.k)
			if absi(par.y2.n) > 20 or not par.y2.is_int():
				return {}
			return {"parabola": par, "ncr": nc, "normal": nm}
		"ncr":
			var n := rng.int_in(6, 12)
			var r := rng.int_in(2, n / 2 - 1) if n >= 6 else 2
			if r * 2 == n:
				return {}
			return {"n": Q.new(n), "r": Q.new(r), "value": Q.new(ncr(n, r))}
		"angle":
			var t: Array = rng.pick(THETAS)
			return {"fn": rng.pick(["sin", "cos"]), "theta": Q.new(t[0], t[1])}
	return {}


## A float as a Q to nine decimal places (the triangle situation keeps the same).
static func nine(x: float) -> Q:
	return Q.new(roundi(x * 1e9), 1000000000)


static func ncr(n: int, r: int) -> int:
	var out := 1
	for i in r:
		out = out * (n - i) / (i + 1)
	return out


## The standard normal cumulative probability, from the series for erf (|z| < 4).
static func phi(z: float) -> float:
	var x := z / sqrt(2.0)
	var term := x
	var total := x
	var n := 0
	while absf(term) > 1e-17 and n < 200:
		n += 1
		term *= -x * x / n
		total += term / (2 * n + 1)
	return 0.5 + total / sqrt(PI)


## The z with phi(z) = p, by bisection.
static func inv_norm(p: float) -> float:
	var lo := -6.0
	var hi := 6.0
	for i in 200:
		var mid := (lo + hi) / 2.0
		if phi(mid) < p:
			lo = mid
		else:
			hi = mid
	return (lo + hi) / 2.0


## sin θ or cos θ for θ = π/6, π/4, π/3, as written: "1/2", "√2/2", "√3/2".
static func exact_value(fn: String, theta: Q) -> String:
	var key := theta.key()
	var sinv := {"1/6": "1/2", "1/4": "√2/2", "1/3": "√3/2"}
	var cosv := {"1/6": "√3/2", "1/4": "√2/2", "1/3": "1/2"}
	return sinv[key] if fn == "sin" else cosv[key]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
