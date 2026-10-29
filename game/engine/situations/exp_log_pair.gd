class_name ExpLogPairSituation
extends RefCounted
## The `exp-log-pair` situation (curriculum/question-types.json): an exponential function
## and its log inverse (FAL-418). A base and a translation are picked, then
## f(x) = b^(x − h) + c and its inverse log_b(x − c) + h are written (or the other way
## round), with inputs that give whole-number powers. Paper 1: every answer is exact.
##
## generate() returns, by mode (need.mode):
##   log      g(x) = log_b(x − h) + c: b, h, c; ns (the powers asked at, for a table or
##            to evaluate), n (one of them), x0 (an input where x − h ≤ 0), m (a − c, so
##            g⁻¹(a) = b^m + h) and a, d (= c + m, for log_b(x − h) + c = d)
##   exp      f(x) = b^(x − h) + c: b, h, c (h ≤ 0 for a graph, so the inverse's
##            x-intercept c + b^(−h) is whole)
##   family   two bases from one family p: b1 = p^i, b2 = p^j (i ≠ j), and k: f(x) = b1ˣ
##            at p^k gives f⁻¹(p^k) = k/i; f(log_b2 x) = x^(i/j)
##   esolve   e^(mx) + c = d: m, c, d, r = d − c, so x = (ln r)/m
##   ineq     f(x) = px + q, g(x) = log_b x and f(g(x)) rel d: p, q, b, rel, d, n = (d − q)/p
##   shift    f(x) = bˣ and g(x) = b^(x + p) + q: b, p, q
##   stretch  f(x) = bˣ and g(x) = (b^j)ˣ: b, j
##   (transform asks for shift or stretch, by the method: see generate())
##   compose  f(x) = bˣ and g(x) = x + p: b, p, equal (g = log_b x instead, so f∘g = g∘f)
##   square   g(x) = log_b((x − h)²) for x > h: b, h
##   expgraph f(x) = A·b^(x − h) + c (fn-ext-exp-graph): b, A (a Q), h, c, and flip (b^(−x)
##            in place of bˣ, for growth or decay)
##
## The clean limits are the checker's too (tools/check_answers.py, EL_*).

const TRIES := 2000
const BASES := [2, 3, 4, 5, 10]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	# The stream's first draw leans low, so it is spent first (as the quadratic recipes do).
	rng.int_in(0, 1)
	var mode: String = need.get("mode", "log")
	# A transformation between two exponentials is a translation or a stretch: common
	# bases make a stretch, rewriting in f a translation, key points either.
	if mode == "transform":
		match need.get("angle", ""):
			"common-base-power":
				mode = "stretch"
			"rewrite-in-f":
				mode = "shift"
			_:
				mode = "stretch" if rng.chance(0.5) else "shift"
	for i in TRIES:
		var s := _draw(rng, mode, need)
		if not s.is_empty():
			s.mode = mode
			return s
	push_error("ExpLogPairSituation: no clean situation for %s" % need)
	return {}


static func _pick(rng: Seeded, xs: Array) -> Variant:
	return xs[rng.int_in(0, xs.size() - 1)]


static func _nonzero(rng: Seeded, lo: int, hi: int) -> int:
	var v := 0
	while v == 0:
		v = rng.int_in(lo, hi)
	return v


static func _draw(rng: Seeded, mode: String, need: Dictionary) -> Dictionary:
	var s := {}
	match mode:
		"log":
			s.b = _pick(rng, BASES)
			s.h = rng.int_in(-5, 5)
			s.c = rng.int_in(-4, 4)
			# Powers whose b^n stays small enough to work out in the head.
			var top := 2 if s.b >= 5 else (3 if s.b >= 3 else 4)
			s.ns = [0, 1, 2, 3, 4].filter(func(n): return n <= top)
			s.n = rng.int_in(1, top)
			s.x0 = s.h - rng.int_in(0, 4)
			s.m = rng.int_in(1, mini(top, 3))
			s.a = s.c + s.m
			s.d = s.a
		"exp":
			s.b = _pick(rng, [2, 3, 4, 5])
			s.h = rng.int_in(-2, 0) if need.get("graph", false) else _nonzero(rng, -5, 5)
			s.c = _nonzero(rng, -4, 4) if not need.get("graph", false) else rng.int_in(-3, 3)
			if need.get("graph", false) and pow(s.b, -s.h) > 16:
				return {}
		"family":
			s.p = _pick(rng, [2, 3])
			var top := 3 if s.p == 2 else 2
			s.i = rng.int_in(1, top)
			s.j = rng.int_in(1, top)
			if s.i == s.j or (need.get("awkward", false) and s.i == 1):
				return {}
			s.b1 = int(pow(s.p, s.i))
			s.b2 = int(pow(s.p, s.j))
			s.k = rng.int_in(1, 6 if s.p == 2 else 4)
			if s.k % s.i == 0:
				return {}
		"esolve":
			s.m = _pick(rng, [2, 3, 4, 5])
			s.c = rng.int_in(-5, 5)
			s.r = _pick(rng, [2, 3, 5, 6, 7, 10, 11, 13])
			s.d = s.c + s.r
		"ineq":
			s.p = _pick(rng, [2, 3, 4, 5, -2, -3])
			s.q = rng.int_in(-6, 6)
			s.b = _pick(rng, [2, 3, 5, 10])
			s.n = rng.int_in(1, 3 if s.b <= 3 else 2)
			s.d = s.p * s.n + s.q
			s.rel = _pick(rng, ["<", ">", "≤", "≥"])
		"shift":
			s.b = _pick(rng, [2, 3, 4, 5])
			s.p = _nonzero(rng, -4, 4)
			s.q = rng.int_in(-4, 4)
		"stretch":
			s.b = _pick(rng, [2, 3])
			s.j = rng.int_in(2, 3)
		"compose":
			s.b = _pick(rng, [2, 3, 5, 10])
			s.p = _nonzero(rng, -5, 5)
			s.equal = rng.chance(0.25)
		"square":
			s.b = _pick(rng, [2, 3, 5, 10])
			s.h = rng.int_in(-5, 5)
		"expgraph":
			s.b = _pick(rng, [2, 3])
			s.A = _pick(rng, [Q.new(1), Q.new(1), Q.new(2), Q.new(3), Q.new(-1), Q.new(1, 2)])
			s.h = 0 if need.get("h0", false) else rng.int_in(-2, 2)
			s.c = _nonzero(rng, -4, 4) if need.get("c_nonzero", false) else rng.int_in(-4, 4)
			if need.get("h_nonzero", false) and s.h == 0:
				return {}
			if need.get("a_pos", false) and s.A.sign() < 0:
				return {}
			s.flip = rng.chance(0.5)
	return s


# ── The functions ────────────────────────────────────────────

## g(x) = log_b(x − h) + c at x, or NAN outside its domain.
static func log_at(s: Dictionary, x: float) -> float:
	if x - s.h <= 0.0:
		return NAN
	return log(x - s.h) / log(float(s.b)) + s.c


## f(x) = b^(x − h) + c at x.
static func exp_at(s: Dictionary, x: float) -> float:
	return pow(float(s.b), x - s.h) + s.c


static func export(s: Dictionary) -> Dictionary:
	var out := {}
	for key in s:
		var v = s[key]
		out[key] = v.key() if v is Q else (str(v) if v is float else v)
	return out
