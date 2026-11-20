class_name ModulusGraphSituation
extends RefCounted
## The `modulus-graph` situation (curriculum/question-types.json), for fn-ahl-modulus-graphs
## (AA HL 2.16, FAL-1008): a function f, chosen from its zeros and turning points, and the
## graphs made from it, |f(x)|, f(|x|), |f(|x|)|, 1/f(x) and [f(x)]². Every feature is known
## before anything is hidden, so the views draw the right graph and each slip from the same f.
##
## Families (s.fam):
##   quad   f(x) = a(x − h)² + k, with whole h and k. With zeros (s.zs, two whole numbers
##          h ± d), a = −k/d². a is a whole number where the question gives the rule.
##   cubic  f(x) = a(x − p)(x − q)², touching the x-axis at q: whole p and q three apart, so
##          the other turning point (t, v) is whole too, t = (2p + q)/3 and v = −4a(p − q)³/27.
##   cubic3 f(x) = (x − r₀)(x − r₁)(x − r₂), three whole zeros (given as a rule only).
##   sine   f(x) = A sin(bx), for the period of [f(x)]².
##
## generate() returns fam, a (Q), coef (Q, highest power first, for quad and cubic families),
## zs (the zeros, ints, in order) and, by family: h, k (quad); p, q, t, v (cubic); A, b (sine).
## With `shape`:
##   "mod"     a graph for |f(x)|, f(|x|), |f(|x|)|: a quad or a cubic with a zero each side of
##             the y-axis, none at 0, and none the mirror image of another
##   "vertex"  a rule ±x² + bx + c, its vertex (h, k) above or below the axis; `cross` true when
##             the vertex is below the axis (|f(x)| reflects it)
##   "zeros"   a rule with whole zeros on each side of the y-axis (quad, or cubic3 for the
##             equation): r < 0 < r′, no two of them each other's mirror image
##   "ineq"    a quad ±(x − h)² + k and a line y = c it meets at h ± m (h > 0, m ≠ h); `rel`
##             the inequality asked of f(|x|) ("<", "≤", ">", "≥")
##   "recip"   a quad with two zeros and a vertex at height ±2, ±3 or ±4, for 1/f
##   "move"    a rule x² + bx + c with zeros h ± m, translated by the vector (mx, my) to a
##             g with zeros h + mx ± n (my = m² − n²); mx = my = 0 when not moved
##   "turn"    a rule a(x − h)² + k with a = ±1 or ±2 and k not 0 or ±1
##   "square"  a quad or cubic with a turning point at height ±2, for [f(x)]²
##   "sqfeat"  a rule a(x − r₀)(x − r₁) with a = ±1 or ±2 and the vertex at height ±2 to ±9;
##             or, with `sine` allowed, A sin(bx)
## `rep` "graph" keeps every feature inside the plot (ModulusGraphViews.WIN).
##
## The clean limits are the checker's too (tools/check_answers.py, MODGR_*).

const TRIES := 4000
## Features of a shown f stay this far inside the plot.
const PLOT := 6


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var shape: String = need.get("shape", "mod")
	var graph: bool = need.get("rep", "") == "graph"
	for i in TRIES:
		var s: Dictionary = {}
		match shape:
			"mod":
				s = _mod(rng)
			"vertex":
				s = _vertex(rng)
			"zeros":
				s = _zeros(rng, graph)
			"ineq":
				s = _ineq(rng)
			"recip":
				s = _recip(rng)
			"move":
				s = _move(rng)
			"turn":
				s = _turn(rng)
			"square":
				s = _square(rng)
			"sqfeat":
				s = _sqfeat(rng, not graph)
		if s.is_empty():
			continue
		s.shape = shape
		if s.has("coef") and not ModulusGraphViews.cards_differ(s, shape):
			continue
		return s
	push_error("ModulusGraphSituation: no clean situation for %s" % need)
	return {}


# ── Families ─────────────────────────────────────────────────

## a(x − h)² + k with zeros h ± d: a = −k/d².
static func quad_zeros(h: int, d: int, k: int) -> Dictionary:
	var a := Q.new(-k, d * d)
	return quad(a, h, k)


static func quad(a: Q, h: int, k: int) -> Dictionary:
	var s := {"fam": "quad", "a": a, "h": h, "k": k}
	# a(x² − 2hx + h²) + k
	s.coef = [a, a.mul(-2 * h), a.mul(h * h).add(k)]
	s.zs = []
	var r := Q.new(-k).div(a)
	if r.sign() > 0:
		var d := RationalQuadraticSituation.isqrt(r.n) if r.is_int() else -1
		if d > 0 and d * d == r.n:
			s.zs = [h - d, h + d]
	return s


## a(x − p)(x − q)², |p − q| = 3.
static func cubic(a: Q, p: int, q: int) -> Dictionary:
	var s := {"fam": "cubic", "a": a, "p": p, "q": q}
	# (x − p)(x² − 2qx + q²) = x³ − (2q + p)x² + (q² + 2pq)x − pq²
	s.coef = [a, a.mul(-(2 * q + p)), a.mul(q * q + 2 * p * q), a.mul(-p * q * q)]
	s.zs = [mini(p, q), maxi(p, q)]
	s.t = (2 * p + q) / 3
	s.v = a.mul(Q.new(-4 * (p - q) * (p - q) * (p - q), 27))
	return s


static func cubic3(r: Array) -> Dictionary:
	var zs := r.duplicate()
	zs.sort()
	var s := {"fam": "cubic3", "a": Q.new(1), "zs": zs}
	var e1: int = zs[0] + zs[1] + zs[2]
	var e2: int = zs[0] * zs[1] + zs[0] * zs[2] + zs[1] * zs[2]
	var e3: int = zs[0] * zs[1] * zs[2]
	s.coef = [Q.new(1), Q.new(-e1), Q.new(e2), Q.new(-e3)]
	return s


static func y(s: Dictionary, x: float) -> float:
	if s.fam == "sine":
		return s.A * sin(s.b * x)
	var out := 0.0
	for c in s.coef:
		out = out * x + c.to_float()
	return out


## Zeros on each side of the y-axis, none at 0, none the mirror image of another.
static func split_zeros(zs: Array) -> bool:
	var neg := false
	var pos := false
	for z in zs:
		if z == 0:
			return false
		neg = neg or z < 0
		pos = pos or z > 0
		if -z in zs:
			return false
	return neg and pos


# ── Shapes ───────────────────────────────────────────────────

## A graph quad (zeros h ± d, d 2 to 4, the vertex at height ±2 to ±4) or a touching cubic.
static func _graph_quad(rng: Seeded, kabs: Array = [2, 3, 4]) -> Dictionary:
	var d := rng.int_in(2, 4)
	var k: int = kabs[rng.int_in(0, kabs.size() - 1)] * (1 if rng.chance(0.5) else -1)
	var h := rng.int_in(-3, 3)
	var s := quad_zeros(h, d, k)
	if absi(s.zs[0]) > PLOT or absi(s.zs[1]) > PLOT:
		return {}
	return s


static func _graph_cubic(rng: Seeded, vabs: Array = [2, 3, 4]) -> Dictionary:
	var p := rng.int_in(-3, 3)
	var q := p + (3 if rng.chance(0.5) else -3)
	if absi(q) > 3:
		return {}
	var vv: int = vabs[rng.int_in(0, vabs.size() - 1)] * (1 if rng.chance(0.5) else -1)
	# v = −4a(p − q)³/27 = ∓4a for p − q = ±3, so a = ∓v/4.
	var a := Q.new(vv * (-1 if p > q else 1), 4)
	var s := cubic(a, p, q)
	assert(s.v.eq(vv))
	return s


static func _mod(rng: Seeded) -> Dictionary:
	var s := _graph_quad(rng) if rng.chance(0.6) else _graph_cubic(rng)
	if s.is_empty() or not split_zeros(s.zs):
		return {}
	return s


static func _vertex(rng: Seeded) -> Dictionary:
	var a := 1 if rng.chance(0.6) else -1
	var h := ExtensionViews.nonzero(rng, -5, 5)
	var k := ExtensionViews.nonzero(rng, -9, 9)
	var s := quad(Q.new(a), h, k)
	# The vertex is reflected when it is below the x-axis.
	s.cross = k < 0
	if absi(s.coef[2].n) > 30:
		return {}
	return s


static func _zeros(rng: Seeded, graph: bool) -> Dictionary:
	var s: Dictionary
	if graph:
		s = _mod(rng)
		return s
	if rng.chance(0.55):
		var r0 := rng.int_in(-6, -1)
		var r1 := rng.int_in(1, 6)
		if (r0 + r1) % 2 != 0:
			return {}
		var h := (r0 + r1) / 2
		var d := (r1 - r0) / 2
		s = quad(Q.new(1), h, -d * d)
	else:
		var r := [ExtensionViews.nonzero(rng, -5, 5), ExtensionViews.nonzero(rng, -5, 5), ExtensionViews.nonzero(rng, -5, 5)]
		if r[0] == r[1] or r[0] == r[2] or r[1] == r[2]:
			return {}
		s = cubic3(r)
		if absi(s.coef[3].n) > 40:
			return {}
	if not split_zeros(s.zs):
		return {}
	return s


static func _ineq(rng: Seeded) -> Dictionary:
	var a := 1 if rng.chance(0.6) else -1
	var h := rng.int_in(1, 4)
	var m := rng.int_in(1, 3)
	if m == h:
		return {}
	var k := rng.int_in(-5, 5)
	var c := k + a * m * m
	if c == 0 or absi(c) > PLOT - 1 or h + m > PLOT:
		return {}
	var s := quad(Q.new(a), h, k)
	s.m = m
	s.c = c
	s.rel = ["<", "≤", ">", "≥"][rng.int_in(0, 3)]
	return s


static func _recip(rng: Seeded) -> Dictionary:
	var s := _graph_quad(rng)
	if s.is_empty() or absi(s.h) > 2:
		return {}
	return s


static func _move(rng: Seeded) -> Dictionary:
	var h := rng.int_in(-4, 4)
	var m := rng.int_in(1, 3)
	var n := rng.int_in(1, 3)
	var mx := rng.int_in(-4, 4)
	var my := m * m - n * n
	if rng.chance(0.15):
		mx = 0
		n = m
		my = 0
	elif mx == 0 and my == 0:
		return {}
	if absi(my) > 4:
		return {}
	var s := quad(Q.new(1), h, -m * m)
	s.m = m
	s.mx = mx
	s.my = my
	s.n = n
	s.gzs = [h + mx - n, h + mx + n]
	# The zeros before and after the move read differently, and none is the other's mirror.
	if (mx != 0 or my != 0) and s.gzs == s.zs:
		return {}
	if s.gzs[0] == -s.gzs[1] or s.zs[0] == -s.zs[1]:
		return {}
	return s


static func _turn(rng: Seeded) -> Dictionary:
	var a: int = [1, 1, -1, -1, 2, -2][rng.int_in(0, 5)]
	var h := rng.int_in(-4, 4)
	var k: int = [2, 3, 4, 5, -2, -3, -4, -5][rng.int_in(0, 7)]
	return quad(Q.new(a), h, k)


static func _square(rng: Seeded) -> Dictionary:
	var s := _graph_quad(rng, [2]) if rng.chance(0.6) else _graph_cubic(rng, [2])
	return s


static func _sqfeat(rng: Seeded, sine: bool) -> Dictionary:
	if sine and rng.chance(0.4):
		var A := rng.int_in(1, 3)
		var b := rng.int_in(1, 4)
		return {"fam": "sine", "a": Q.new(A), "A": A, "b": b, "zs": []}
	var a: int = [1, 1, -1, -1, 2, -2][rng.int_in(0, 5)]
	var d := rng.int_in(1, 3)
	var k := -a * d * d
	if absi(k) < 2 or absi(k) > 9:
		return {}
	var h := rng.int_in(-3, 3)
	var s := quad(Q.new(a), h, k)
	if absi(s.zs[0]) > PLOT or absi(s.zs[1]) > PLOT or (not sine and absi(k) > PLOT - 1):
		return {}
	return s


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
