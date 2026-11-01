class_name CompositePairSituation
extends RefCounted
## The `composite-pair` situation (curriculum/question-types.json): two rules chained
## together (FAL-422). An inner rule g and an outer rule f are picked, then both
## composites, a value, a target and any hidden constant are derived, so either rule or the
## composite can be hidden. `inverse-order-undo` (the order-and-undo concept type) builds
## on this recipe.
##
## A rule is {"t": kind, "co": [c0, c1, ...] (low power first, as Q), ...}:
##   lin   m·x + c       sq    x² + c       sqs   (x − h)²
##   cube  x³ + c        poly  any polynomial of degree 2 (an outer rule to find)
##   sin   sin x         (Paper 2, x in radians)
## rule_text() writes it, rule_steps() says it in words ("double", "subtract 3").
##
## generate() returns, by mode (need.mode):
##   forward  f, g, x0 and v = (f∘g)(x0): every composite, and a value when asked. A
##            Paper 2 value (need.paper = 2) is f = sin x
##   param    pm or lin, drawn here
##   pm       k in g = a·x + k, f = x² + c: (f∘g)(x0) = v gives a·x0 + k = ±n, so k = k1 or k2
##   lin      k in f = k·x + d: (f∘g)(x0) = v gives k = (v − d) ÷ g(x0)
##   coef     f = x² + c, g = k·x + d: the x² coefficient of f∘g is p = k², so k = ±n
##   solve    f, g and a target t: (f∘g)(x) = t has the x-values xs (two when f squares)
##   self     f = lin or sq: f∘f
##   compare  f, g with f∘g ≠ g∘f
##   chain    steps (words): a chain of steps; the composite is a polynomial
##   decompose  g = a·x + b and f = sq or cube: h = f∘g, shown as one rule
##   inner    f = m·x + c and g (a polynomial): h = f∘g, g to find
##   outer    g = a·x + b and f (a quadratic): h = f∘g, f to find
##
## The clean limits are the checker's too (tools/check_answers.py, CP_*).

const TRIES := 2000
const G_M := [2, 3, 4, 5, -1, -2, -3]
const F_M := [2, 3, 4, 5, -1, -2, -3]
const X0 := [-3, -2, -1, 1, 2, 3, 4]
const V_MAX := 200
const COEF_MAX := 60


static func lin(m: Variant, c: Variant) -> Dictionary:
	return {"t": "lin", "co": [Q.of(c), Q.of(m)]}


static func sq(c: Variant) -> Dictionary:
	return {"t": "sq", "co": [Q.of(c), Q.new(0), Q.new(1)]}


static func sqs(h: Variant) -> Dictionary:
	var q := Q.of(h)
	return {"t": "sqs", "h": q, "co": [q.mul(q), q.mul(2).neg(), Q.new(1)]}


static func cube(c: Variant) -> Dictionary:
	return {"t": "cube", "co": [Q.of(c), Q.new(0), Q.new(0), Q.new(1)]}


static func general(co: Array) -> Dictionary:
	return {"t": "poly", "co": co}


static func pick(rng: Seeded, xs: Array) -> Variant:
	return xs[rng.int_in(0, xs.size() - 1)]


static func nonzero(rng: Seeded, lo: int, hi: int) -> int:
	var v := 0
	while v == 0:
		v = rng.int_in(lo, hi)
	return v


## A random rule of the families in `kinds`.
static func draw_rule(rng: Seeded, kinds: Array) -> Dictionary:
	match kinds[rng.int_in(0, kinds.size() - 1)]:
		"lin":
			return lin(pick(rng, F_M), rng.int_in(-6, 6))
		"sq":
			return sq(nonzero(rng, -6, 6))
		"sqs":
			return sqs(nonzero(rng, -5, 5))
		_:
			return cube(nonzero(rng, -6, 6))


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var mode: String = need.get("mode", "forward")
	# A parameter from a value: k in the inner rule (a ± pair) or in the outer one.
	if mode == "param":
		mode = "pm" if rng.chance(0.7) else "lin"
	for i in TRIES:
		var s := _draw(rng, mode, need)
		if not s.is_empty() and _clean(s, mode):
			s.mode = mode
			if need.get("paper", 0) > 0:
				s.paper = 2 if s.has("sine") else 1
			return s
	push_error("CompositePairSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, mode: String, need: Dictionary) -> Dictionary:
	var s := {}
	match mode:
		"forward":
			s.g = lin(pick(rng, G_M), rng.int_in(-5, 5))
			s.x0 = Q.new(pick(rng, X0))
			if need.get("paper", 0) == 2 and need.get("sine", false):
				s.f = {"t": "sin", "co": []}
				s.sine = true
				s.v = ev(s.f, ev(s.g, s.x0))
				var v: float = s.v.to_float()
				if absf(v) < 0.05 or not Answer.rounds_clearly(v):
					return {}
				return s
			s.f = draw_rule(rng, ["lin", "lin", "sq", "sq", "sqs", "cube"])
			s.v = ev(s.f, ev(s.g, s.x0))
		"pm":
			s.a = pick(rng, G_M)
			s.c = rng.int_in(-6, 6)
			s.x0 = Q.new(pick(rng, X0))
			s.n = rng.int_in(1, 6)
			s.v = Q.new(s.n * s.n + s.c)
			s.k1 = Q.new(s.n - s.a * s.x0.n)
			s.k2 = Q.new(-s.n - s.a * s.x0.n)
		"lin":
			s.g = lin(pick(rng, G_M), rng.int_in(-5, 5))
			s.x0 = Q.new(pick(rng, X0))
			s.k = Q.new(nonzero(rng, -6, 6))
			s.d = Q.new(rng.int_in(-8, 8))
			var gx: Q = ev(s.g, s.x0)
			if gx.is_zero():
				return {}
			s.v = s.k.mul(gx).add(s.d)
		"coef":
			s.c = rng.int_in(-6, 6)
			s.d = nonzero(rng, -5, 5)
			s.n = rng.int_in(2, 7)
			s.p = Q.new(s.n * s.n)
		"solve":
			var kind: String = pick(rng, ["lin", "sq", "sq", "sq", "cube"])
			s.g = lin(pick(rng, [2, 3, 4, 5, -2, -3]), 0)
			if kind == "sq":
				var x1 := rng.int_in(-4, 4)
				var x2 := rng.int_in(-4, 4)
				if x1 == x2:
					return {}
				var a: int = s.g.co[1].n
				if (a * (x1 + x2)) % 2 != 0:
					return {}
				s.g = lin(a, -a * (x1 + x2) / 2)
				s.f = sq(rng.int_in(-6, 6))
				var t: Q = ev(s.f, ev(s.g, Q.new(x1)))
				s.t = t
				s.xs = [Q.new(mini(x1, x2)), Q.new(maxi(x1, x2))]
			else:
				s.g = lin(s.g.co[1], rng.int_in(-5, 5))
				s.f = lin(pick(rng, F_M), rng.int_in(-6, 6)) if kind == "lin" else cube(nonzero(rng, -6, 6))
				var x1 := rng.int_in(-4, 4)
				s.t = ev(s.f, ev(s.g, Q.new(x1)))
				s.xs = [Q.new(x1)]
		"self":
			s.f = lin(pick(rng, [2, 3, 4, 5, -2, -3]), rng.int_in(-6, 6)) if rng.chance(0.55) else sq(nonzero(rng, -5, 5))
		"compare":
			s.g = lin(pick(rng, G_M), rng.int_in(-5, 5))
			s.f = draw_rule(rng, ["lin", "sq", "sq", "sqs"])
		"chain":
			s.steps = _chain(rng)
		"decompose":
			s.g = lin(pick(rng, G_M), nonzero(rng, -5, 5))
			s.f = sq(nonzero(rng, -6, 6)) if rng.chance(0.65) else cube(nonzero(rng, -6, 6))
		"inner":
			s.f = lin(pick(rng, [2, 3, 4, 5, -2, -3]), nonzero(rng, -6, 6))
			if rng.chance(0.5):
				s.g = lin(pick(rng, G_M), rng.int_in(-5, 5))
			else:
				s.g = general([Q.new(rng.int_in(-5, 5)), Q.new(rng.int_in(-4, 4)), Q.new(nonzero(rng, -3, 3))])
		"outer":
			s.g = lin(pick(rng, G_M), rng.int_in(-5, 5))
			s.f = general([Q.new(rng.int_in(-6, 6)), Q.new(rng.int_in(-4, 4)), Q.new(nonzero(rng, -3, 3))])
	return s


## A chain of two or three steps with at most one power: ["subtract 1", "square", "double"].
static func _chain(rng: Seeded) -> Array:
	var n := rng.int_in(2, 3)
	var steps: Array = []
	var powered := false
	for i in n:
		var kind := rng.int_in(0, 3)
		if kind == 3 and powered:
			kind = rng.int_in(0, 2)
		match kind:
			0:
				steps.append("add %d" % rng.int_in(1, 7))
			1:
				steps.append("subtract %d" % rng.int_in(1, 7))
			2:
				steps.append(pick(rng, ["double", "treble", "multiply by 4", "multiply by 5", "multiply by −2", "multiply by −3"]))
			_:
				steps.append("square")
				powered = true
	# Two steps in a row that cancel or merge (add then subtract) read as a trick: avoid.
	for i in range(1, steps.size()):
		var a: String = steps[i - 1]
		var b: String = steps[i]
		if a.split(" ")[0] in ["add", "subtract"] and b.split(" ")[0] in ["add", "subtract"]:
			return _chain(rng)
	return steps


static func _clean(s: Dictionary, mode: String) -> bool:
	match mode:
		"forward":
			if s.has("sine"):
				return true
			return s.v.abs_q().lt(V_MAX + 1) and _small(composite(s.f, s.g)) and _small(composite(s.g, s.f))
		"pm":
			return s.k1.abs_q().lt(21) and s.k2.abs_q().lt(21)
		"lin":
			return true
		"self":
			return _small(composite(s.f, s.f))
		"compare":
			var a := composite(s.f, s.g)
			var b := composite(s.g, s.f)
			return _small(a) and _small(b) and not same(a, b)
		"chain":
			return _small(chain_co(s.steps))
		"decompose", "inner", "outer":
			return _small(composite(s.f, s.g))
		"solve":
			return s.t.abs_q().lt(V_MAX + 1)
	return true


static func _small(co: Array) -> bool:
	for c in co:
		if not c.is_int() or c.abs_q().lt(COEF_MAX + 1) == false:
			return false
	return true


# ── Polynomials, as arrays of Q, lowest power first ──────────

static func trim(co: Array) -> Array:
	var out := co.duplicate()
	while out.size() > 1 and out[out.size() - 1].is_zero():
		out.pop_back()
	return out


static func same(a: Array, b: Array) -> bool:
	var x := trim(a)
	var y := trim(b)
	if x.size() != y.size():
		return false
	for i in x.size():
		if not x[i].eq(y[i]):
			return false
	return true


static func padd(a: Array, b: Array) -> Array:
	var out: Array = []
	for i in maxi(a.size(), b.size()):
		out.append((a[i] if i < a.size() else Q.new(0)).add(b[i] if i < b.size() else Q.new(0)))
	return out


static func pmul(a: Array, b: Array) -> Array:
	var out: Array = []
	for i in a.size() + b.size() - 1:
		out.append(Q.new(0))
	for i in a.size():
		for j in b.size():
			out[i + j] = out[i + j].add(a[i].mul(b[j]))
	return out


static func pscale(a: Array, k: Q) -> Array:
	return a.map(func(c): return c.mul(k))


## outer(inner(x)) as coefficients.
static func pcompose(outer: Array, inner: Array) -> Array:
	var out: Array = [Q.new(0)]
	var power: Array = [Q.new(1)]
	for c in outer:
		out = padd(out, pscale(power, c))
		power = pmul(power, inner)
	return trim(out)


static func composite(outer: Dictionary, inner: Dictionary) -> Array:
	return pcompose(outer.co, inner.co)


static func peval(co: Array, x: Q) -> Q:
	var out := Q.new(0)
	for i in range(co.size() - 1, -1, -1):
		out = out.mul(x).add(co[i])
	return out


static func ev(r: Dictionary, x: Q) -> Q:
	if r.t == "sin":
		# A GDC value, kept to nine decimal places like the Graphs region's.
		return Q.new(roundi(sin(x.to_float()) * 1e9), 1000000000)
	return peval(r.co, x)


## The polynomial a chain of steps makes: x goes through each step in turn.
static func chain_co(steps: Array) -> Array:
	var co: Array = [Q.new(0), Q.new(1)]
	for st in steps:
		co = pcompose(step_co(st), co)
	return co


static func step_co(st: String) -> Array:
	var w: PackedStringArray = st.split(" ")
	match w[0]:
		"add":
			return [Q.new(int(w[1])), Q.new(1)]
		"subtract":
			return [Q.new(-int(w[1])), Q.new(1)]
		"double":
			return [Q.new(0), Q.new(2)]
		"treble":
			return [Q.new(0), Q.new(3)]
		"square":
			return [Q.new(0), Q.new(0), Q.new(1)]
		"cube":
			return [Q.new(0), Q.new(0), Q.new(0), Q.new(1)]
		"negate":
			return [Q.new(0), Q.new(-1)]
		_:
			return [Q.new(0), Q.new(int(w[2].replace("−", "-")))]


## High power first, with `deg` + 1 entries (zeros where a power is missing).
static func high(co: Array, deg: int) -> Array:
	var out: Array = []
	for p in range(deg, -1, -1):
		out.append(co[p] if p < co.size() else Q.new(0))
	return out


static func degree(co: Array) -> int:
	return trim(co).size() - 1


# ── Words ────────────────────────────────────────────────────

static func rule_text(r: Dictionary) -> String:
	match r.t:
		"lin":
			return Fmt.poly([r.co[1], r.co[0]])
		"sq":
			return Fmt.poly([1, 0, r.co[0]])
		"sqs":
			return Fmt.factor(r.h) + "²"
		"cube":
			return Fmt.poly([1, 0, 0, r.co[0]])
		"sin":
			return "sin x"
	return Fmt.poly(high(r.co, r.co.size() - 1))


## The rule with its x replaced by `inner`: "3(2x − 1) + 2", "(2x − 1)² + 4".
static func sub_in(r: Dictionary, inner: String) -> String:
	return put(rule_text(r), inner)


## `text` with each x replaced by `inner`, bracketed where that reads better: a negative
## or longer expression always, a number after a digit ("2(4)", not "24").
static func put(text: String, inner: String) -> String:
	var bare := inner == "x" or inner.is_valid_int() or inner.length() <= 4 and inner.ends_with("(x)")
	var out := ""
	for i in text.length():
		var ch := text[i]
		if ch != "x":
			out += ch
			continue
		var after_digit := i > 0 and text[i - 1].is_valid_int()
		var plain := inner == "x" or (inner.is_valid_int() and not after_digit) or inner.ends_with("(x)")
		out += inner if plain and bare else "(" + inner + ")"
	return out


## A rule said in steps: ["double", "subtract 3"]. A polynomial has none.
static func rule_steps(r: Dictionary) -> Array:
	var out: Array = []
	match r.t:
		"lin":
			var m: Q = r.co[1]
			var c: Q = r.co[0]
			if m.eq(-1):
				out.append("negate")
			elif m.eq(2):
				out.append("double")
			elif m.eq(3):
				out.append("treble")
			elif not m.eq(1):
				out.append("multiply by %s" % m.text())
			if not c.is_zero():
				out.append(("add %s" if c.sign() > 0 else "subtract %s") % c.abs_q().text())
		"sq":
			out = ["square"]
			if not r.co[0].is_zero():
				out.append(("add %s" if r.co[0].sign() > 0 else "subtract %s") % r.co[0].abs_q().text())
		"cube":
			out = ["cube"]
			if not r.co[0].is_zero():
				out.append(("add %s" if r.co[0].sign() > 0 else "subtract %s") % r.co[0].abs_q().text())
		"sqs":
			out = [("subtract %s" if r.h.sign() > 0 else "add %s") % r.h.abs_q().text(), "square"]
	return out


static func steps_text(steps: Array) -> String:
	return ", then ".join(steps)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
