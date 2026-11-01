class_name RationalModelSituation
extends RefCounted
## The `rational-model` situation (curriculum/question-types.json): a linear-over-linear model
## in a context, f(x) = (αx + β)/(x + γ), for fn-ext-rational-model (FAL-423). The long-run
## value α is its horizontal asymptote; x = −γ (0 or negative) is outside the sensible domain.
##
## generate() returns:
##   ctx    "cost"   average cost per item A(n) = (F + vn)/n: α = v, β = F, γ = 0 (falls to v)
##          "mix"    concentration after x litres are added C(x) = (s + px)/(V + x): α = p,
##                   β = s = V·c₀, γ = V (rises from c₀ to p)
##          "settle" a level that settles P(t) = (Lt + P₀k)/(t + k): α = L, β = P₀k, γ = k
##   al, be, ga (whole), and the context's own numbers: F, v | V, c0, p, s | L, P0, k
##   x0      an input where f(x0) is a decimal that ends (to evaluate at)
##   xs      four inputs for a table, x0 not among them
##   xstar   a whole input and tstar = f(xstar), a decimal that ends (input-for-value)
##   tgt     a target T (a decimal that ends) between the start and the long-run value, with
##           nstar = (Tγ − β)/(α − T) not whole and n = ceil(nstar): the least whole input that
##           passes it (least-n-for-target)
##   x1, y1  one data point, y1 = f(x1) ending (parameters-from-data)
## Every answer is exact (paper 1): the Paper 2 versions of the catalogue, to 3 s.f., are not built.
##
## need: words (a context that can be told without its formula: cost or mix); ctx.
## The clean limits are the checker's too (tools/check_answers.py, RM_*).

const TRIES := 800
const SMOOTH := [5, 10, 20, 25, 40, 50, 80, 100, 125, 200]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	for i in TRIES:
		var s := _draw(rng, need)
		if not s.is_empty():
			s.paper = 1
			return s
	push_error("RationalModelSituation: no clean situation for %s" % need)
	return {}


static func _pick(rng: Seeded, xs: Array) -> Variant:
	return xs[rng.int_in(0, xs.size() - 1)]


## Whether q is a decimal that ends.
static func terminates(q: Q) -> bool:
	var d := q.d
	while d % 2 == 0:
		d /= 2
	while d % 5 == 0:
		d /= 5
	return d == 1


static func at(s: Dictionary, x: Variant) -> Q:
	var xq := Q.of(x)
	return xq.mul(Q.new(s.al)).add(Q.new(s.be)).div(xq.add(Q.new(s.ga)))


static func _draw(rng: Seeded, need: Dictionary) -> Dictionary:
	var ctxs := ["cost", "mix"] if need.get("words", false) else ["cost", "mix", "settle"]
	var ctx: String = need.get("ctx", "any")
	if ctx == "any":
		ctx = ctxs[rng.int_in(0, ctxs.size() - 1)]
	var s := {"ctx": ctx}
	match ctx:
		"cost":
			s.v = _pick(rng, [2, 3, 4, 5, 6, 8, 10])
			s.F = _pick(rng, [200, 300, 400, 500, 600, 800, 1000, 1200, 2000])
			s.al = s.v
			s.be = s.F
			s.ga = 0
		"mix":
			s.V = _pick(rng, [20, 40, 50, 100])
			s.c0 = _pick(rng, [2, 4, 5])
			s.p = _pick(rng, [10, 12, 15, 20])
			s.s = s.V * s.c0
			s.al = s.p
			s.be = s.s
			s.ga = s.V
		_:
			s.L = _pick(rng, [400, 600, 800, 1000])
			s.P0 = _pick(rng, [100, 200, 300])
			s.k = _pick(rng, [2, 4, 5])
			s.al = s.L
			s.be = s.P0 * s.k
			s.ga = s.k
			s.story = _pick(rng, AsymptoteGallerySituation.STORIES)
	var start: Q = at(s, 0) if ctx != "cost" else Q.new(0)
	# x0, where f ends as a decimal.
	var xs: Array = []
	for x in range(1, 201):
		if (ctx == "cost" and x in SMOOTH or ctx != "cost" and x % 5 == 0) and terminates(at(s, x)):
			xs.append(x)
	if xs.size() < 6:
		return {}
	s.x0 = _pick(rng, xs)
	var others: Array = xs.filter(func(x): return x != s.x0)
	var table: Array = []
	for x in rng.shuffled(others).slice(0, 4):
		table.append(x)
	table.sort()
	s.xs = table
	s.xstar = _pick(rng, others)
	s.tstar = at(s, s.xstar)
	# The target: a decimal that ends, strictly between f's start and its long-run value
	# (cost falls to v, so above it), with a x* that is not whole.
	var far: Q = Q.new(s.al)
	var tries: Array = []
	for j in range(1, 80):
		var t := far.add(Q.new(j, 4)) if ctx == "cost" else far.sub(Q.new(j, 4))
		tries.append(t)
	for t in rng.shuffled(tries):
		if ctx != "cost" and not start.lt(t):
			continue
		var nstar := Q.new(s.ga).mul(t).sub(Q.new(s.be)).div(Q.new(s.al).sub(t))
		if nstar.sign() > 0 and not nstar.is_int() and nstar.to_float() < 400.0 and nstar.to_float() > 2.0:
			s.tgt = t
			s.nstar = nstar
			s.n = int(ceil(nstar.to_float()))
			break
	if not s.has("tgt"):
		return {}
	s.x1 = _pick(rng, others)
	s.y1 = at(s, s.x1)
	return s


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
