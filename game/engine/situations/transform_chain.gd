class_name TransformChainSituation
extends RefCounted
## The `transform-chain` situation (curriculum/question-types.json): a base graph and a
## chain of up to three moves, for fn-transform-describe, fn-transform-apply and
## fn-concept-transform-order (FAL-424). The moves are picked first and everything else
## is derived from them, so f, g, the moves or a point can each be the thing hidden: f and
## the moves give g, f and g give the moves, g and the moves give f.
##
## generate() returns:
##   fam     the base: sq x², cube x³, root √x, recip 1/x, exp e^x, ln ln x, log2 log₂ x,
##           sin sin x, vert (x − u)² + v, poly x² + ux + v, or pts: a graph in straight
##           pieces through grid points, with no rule
##   u, v    vert's and poly's numbers, as Q
##   nodes   pts's corners [[x, y], ...], as Q
##   moves   in order: {"k": "vs", "a"}, {"k": "hs", "a"}, {"k": "rx"}, {"k": "ry"} or
##           {"k": "tr", "c", "d"}, the numbers as Q
##   map     g(x) = A·f(B(x − C)) + D, as Q: {"A", "B", "C", "D"}
##   key     key points of f on the grid [[x, y], ...] (with their images on the grid on
##           Paper 1), and win, a window [x0, x1, y0, y1] that holds f and g
##   paper   1, or 2: decimal moves and three-move chains, worked with a calculator
##
## need: fams (the bases allowed), pat (the shape of the chain, see _moves), rep and paper.
## A graph or table needs two key points, so only a base with grid points can show one.
## A reflection is only asked of a base that is neither even nor odd (`ASYM`), or −f and
## f(−x) would be the same graph. A horizontal stretch isn't asked of 1/x or a log, where
## it is also a vertical stretch or a translation; describe-log-rewrite is about just that.

const ALL := ["sq", "cube", "root", "recip", "exp", "ln", "log2", "sin"]
const ASYM := ["root", "exp", "ln", "log2", "vert", "pts"]
const GRID := ["pts", "sq", "cube", "root", "recip", "log2", "vert"]
const NO_HS := ["recip", "ln", "log2"]
const STRETCH_P1 := [[2, 1], [3, 1], [1, 2]]
const V_P2 := [[3, 2], [5, 2], [2, 5], [3, 5], [6, 5]]
const H_P2 := [[5, 2], [2, 5], [4, 5], [5, 4]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var paper := maxi(int(need.get("paper", 1)), 1)
	var fams: Array = need.get("fams", ALL)
	var rep: String = need.get("rep", "equation")
	if rep in ["graph", "table"]:
		var on_grid: Array = fams.filter(func(f): return f in GRID)
		fams = on_grid if not on_grid.is_empty() else ["pts"]
	for i in 500:
		var s := _try(rng, fams, str(need.get("pat", "tr")), paper)
		if s.is_empty() or (rep in ["graph", "table"] and two_apart(s.key).is_empty()):
			continue
		return s
	return {}


static func _try(rng: Seeded, fams: Array, pat: String, paper: int) -> Dictionary:
	var s := {"fam": rng.pick(fams), "paper": paper, "pat": pat}
	match s.fam:
		"vert":
			s.u = Q.new(ExtensionViews.nonzero(rng, -3, 3))
			s.v = Q.new(ExtensionViews.nonzero(rng, -3, 3))
		"poly":
			s.u = Q.new(ExtensionViews.nonzero(rng, -5, 5))
			s.v = Q.new(ExtensionViews.nonzero(rng, -5, 5))
		"pts":
			s.nodes = _nodes(rng)
	s.moves = _moves(rng, s, pat)
	if s.moves.is_empty():
		return {}
	s.map = compose(s.moves)
	s.key = _key(s)
	if s.key.is_empty():
		return {}
	s.win = window(s, [s.map])
	return s


## Five corners on even grid points, so a stretch by ½ still lands on the grid. No graph
## is its own mirror image, and neighbouring corners differ.
static func _nodes(rng: Seeded) -> Array:
	for i in 100:
		var ys: Array = []
		for j in 5:
			ys.append(2 * rng.int_in(-2, 2))
		var flat := false
		for j in 4:
			flat = flat or ys[j] == ys[j + 1]
		if flat or ys == [ys[4], ys[3], ys[2], ys[1], ys[0]] or ys == [-ys[4], -ys[3], -ys[2], -ys[1], -ys[0]]:
			continue
		var out: Array = []
		for j in 5:
			out.append([Q.new(2 * j - 4), Q.new(ys[j])])
		return out
	return [[Q.new(-4), Q.new(0)], [Q.new(-2), Q.new(2)], [Q.new(0), Q.new(-2)], [Q.new(2), Q.new(4)], [Q.new(4), Q.new(2)]]


static func _frac(rng: Seeded, pool: Array) -> Q:
	var p: Array = rng.pick(pool)
	return Q.new(p[0], p[1])


## A vertical scale factor, a horizontal one, and one part of a translation. Nothing is ±1.
static func v_factor(rng: Seeded, paper: int) -> Q:
	return _frac(rng, STRETCH_P1 if paper == 1 else V_P2)


static func h_factor(rng: Seeded, paper: int) -> Q:
	return _frac(rng, STRETCH_P1 if paper == 1 else H_P2)


static func shift(rng: Seeded, paper: int) -> Q:
	if paper == 1:
		return Q.new(ExtensionViews.nonzero(rng, -5, 5))
	var t := 0
	while t % 10 == 0:
		t = rng.int_in(-45, 45)
	return Q.new(t, 10)


static func vs(rng: Seeded, paper: int) -> Dictionary:
	return {"k": "vs", "a": v_factor(rng, paper)}


static func hs(rng: Seeded, paper: int) -> Dictionary:
	return {"k": "hs", "a": h_factor(rng, paper)}


static func tr(c: Variant, d: Variant) -> Dictionary:
	return {"k": "tr", "c": Q.of(c), "d": Q.of(d)}


## pat -> the chain:
##   tr, vt (up or down only), ht (across only), vs, hs, stretch (either), hz (hs or ht)
##   hs-vt, vs-vt, vs-tr, hs-ht  two moves, in that order
##   ref, ref-one (and one other move), ref-tr
##   chain   two moves on Paper 1, three on Paper 2, stretches before the translation
static func _moves(rng: Seeded, s: Dictionary, pat: String) -> Array:
	var p: int = s.paper
	var can_hs: bool = not s.fam in NO_HS
	var refl: Dictionary = {"k": "ry" if rng.chance(0.5) else "rx"}
	var both := tr(shift(rng, p), shift(rng, p))
	var up := tr(0, shift(rng, p))
	var across := tr(shift(rng, p), 0)
	match pat:
		"tr":
			return [both]
		"vt":
			return [up]
		"ht":
			return [across]
		"vs":
			return [vs(rng, p)]
		"hs":
			return [hs(rng, p)] if can_hs else []
		"stretch":
			return [hs(rng, p)] if can_hs and rng.chance(0.5) else [vs(rng, p)]
		"hz":
			return [hs(rng, p)] if can_hs and rng.chance(0.5) else [across]
		"hs-vt":
			return [hs(rng, p), up] if can_hs else []
		"vs-vt":
			return [vs(rng, p), up]
		"vs-tr":
			return [vs(rng, p), both]
		"hs-ht":
			return [hs(rng, p), across] if can_hs else []
		"ref":
			return [refl]
		"ref-tr":
			return [refl, both]
		"ref-one":
			var other: Array = [vs(rng, p), both]
			if can_hs:
				other.append(hs(rng, p))
			return [refl, rng.pick(other)]
		"chain":
			var stretch: Dictionary = hs(rng, p) if can_hs and rng.chance(0.5) else vs(rng, p)
			if p == 1:
				return [stretch, both]
			var second: Dictionary = refl if s.fam in ASYM else (vs(rng, p) if stretch.k == "hs" else (hs(rng, p) if can_hs else {}))
			return [stretch, second, both] if not second.is_empty() else [stretch, both]
	return []


# ── The chain as one map ─────────────────────────────────────

## The chain's map (x, y) -> (px·x + qx, py·y + qy), as g(x) = A·f(B(x − C)) + D.
static func compose(moves: Array) -> Dictionary:
	var px := Q.new(1)
	var qx := Q.new(0)
	var py := Q.new(1)
	var qy := Q.new(0)
	for m in moves:
		match m.k:
			"vs":
				py = py.mul(m.a)
				qy = qy.mul(m.a)
			"hs":
				px = px.mul(m.a)
				qx = qx.mul(m.a)
			"rx":
				py = py.neg()
				qy = qy.neg()
			"ry":
				px = px.neg()
				qx = qx.neg()
			"tr":
				qx = qx.add(m.c)
				qy = qy.add(m.d)
	return {"A": py, "B": Q.new(1).div(px), "C": qx, "D": qy}


## The map that undoes a chain: each move's inverse, last one first.
static func undo(moves: Array) -> Array:
	var out: Array = []
	for m in moves:
		out.push_front(inverse(m))
	return out


static func inverse(m: Dictionary) -> Dictionary:
	match m.k:
		"vs", "hs":
			return {"k": m.k, "a": Q.new(1).div(m.a)}
		"tr":
			return tr(m.c.neg(), m.d.neg())
	return m


## Where (x, y) lands under a map: [x / B + C, A·y + D].
static func image(map: Dictionary, x: Variant, y: Variant) -> Array:
	return [Q.of(x).div(map.B).add(map.C), map.A.mul(Q.of(y)).add(map.D)]


## Where (x, y) came from.
static func source(map: Dictionary, x: Variant, y: Variant) -> Array:
	return [Q.of(x).sub(map.C).mul(map.B), Q.of(y).sub(map.D).div(map.A)]


## Key points of f, as Q. On Paper 1 only those whose images are on the grid.
static func _key(s: Dictionary) -> Array:
	var c: Array = []
	match s.fam:
		"sq":
			c = [[0, 0], [1, 1], [2, 4], [-1, 1], [-2, 4]]
		"cube":
			c = [[0, 0], [1, 1], [2, 8], [-1, -1], [-2, -8]]
		"root":
			c = [[0, 0], [1, 1], [4, 2], [9, 3]]
		"recip":
			c = [[1, 1], [-1, -1]]
		"exp":
			c = [[0, 1]]
		"ln":
			c = [[1, 0]]
		"log2":
			c = [[1, 0], [2, 1], [4, 2], [8, 3]]
		"sin":
			c = [[0, 0]]
		"vert":
			c = [[s.u, s.v], [s.u.add(1), s.v.add(1)], [s.u.add(2), s.v.add(4)]]
		"poly":
			c = [[0, s.v]]
		"pts":
			c = s.nodes
	var out: Array = []
	for p in c:
		var q := [Q.of(p[0]), Q.of(p[1])]
		var im := image(s.map, q[0], q[1])
		if s.paper == 2 or (im[0].is_int() and im[1].is_int()):
			out.append(q)
	return out


## Two key points that differ in x and in y, the ones a graph marks. [] if none do.
static func two_apart(key: Array) -> Array:
	for i in key.size():
		for j in range(i + 1, key.size()):
			if not key[i][0].eq(key[j][0]) and not key[i][1].eq(key[j][1]):
				return [key[i], key[j]]
	return []


## A window, in whole units, that holds the key points of f and of every map's image, and
## the origin, with room round them.
static func window(s: Dictionary, maps: Array) -> Array:
	var xs: Array = [0.0]
	var ys: Array = [0.0]
	for p in s.key:
		xs.append(p[0].to_float())
		ys.append(p[1].to_float())
		for m in maps:
			var im := image(m, p[0], p[1])
			xs.append(im[0].to_float())
			ys.append(im[1].to_float())
	return [mini(floori(xs.min()) - 2, -4), maxi(ceili(xs.max()) + 2, 4), mini(floori(ys.min()) - 2, -4), maxi(ceili(ys.max()) + 2, 4)]


# ── The functions as numbers ─────────────────────────────────

static func base(s: Dictionary, x: float) -> float:
	match s.fam:
		"sq":
			return x * x
		"cube":
			return x * x * x
		"root":
			return sqrt(x) if x >= 0.0 else NAN
		"recip":
			return 1.0 / x if x != 0.0 else NAN
		"exp":
			return exp(x)
		"ln":
			return log(x) if x > 0.0 else NAN
		"log2":
			return log(x) / log(2.0) if x > 0.0 else NAN
		"sin":
			return sin(x)
		"vert":
			return (x - s.u.to_float()) ** 2 + s.v.to_float()
		"poly":
			return x * x + s.u.to_float() * x + s.v.to_float()
		"pts":
			var ns: Array = s.nodes
			for i in ns.size() - 1:
				var x0: float = ns[i][0].to_float()
				var x1: float = ns[i + 1][0].to_float()
				if x >= x0 and x <= x1:
					var y0: float = ns[i][1].to_float()
					return y0 + (ns[i + 1][1].to_float() - y0) * (x - x0) / (x1 - x0)
	return NAN


static func at(s: Dictionary, map: Dictionary, x: float) -> float:
	return map.A.to_float() * base(s, map.B.to_float() * (x - map.C.to_float())) + map.D.to_float()


## A map's curve in the window, in pieces: one each side of a vertical asymptote, and from
## the edge of a root's or a log's domain. A graph in straight pieces is its corners.
static func curves(s: Dictionary, map: Dictionary, win: Array) -> Array:
	if s.fam == "pts":
		var pts: Array = s.nodes.map(func(n):
			var im := image(map, n[0], n[1])
			return [im[0].to_float(), im[1].to_float()])
		pts.sort_custom(func(a, b): return a[0] < b[0])
		return [pts]
	var f := func(x: float) -> float: return at(s, map, x)
	var edge: float = map.C.to_float()
	var lo: float = win[0]
	var hi: float = win[1]
	if s.fam == "recip":
		return [GdcKit.curve(f, lo, edge - 0.02), GdcKit.curve(f, edge + 0.02, hi)]
	if s.fam in ["root", "ln", "log2"]:
		var gap := 0.0 if s.fam == "root" else 0.004
		return [GdcKit.curve(f, edge + gap, hi) if map.B.sign() > 0 else GdcKit.curve(f, lo, edge - gap)]
	return [GdcKit.curve(f, lo, hi)]


# ── Writing it ───────────────────────────────────────────────

## A number as this paper writes it: a fraction on Paper 1, a decimal on Paper 2.
static func n(s: Dictionary, v: Variant) -> String:
	return Fmt.dec(v) if s.get("paper", 1) == 2 else Fmt.num(v)


static func pt(s: Dictionary, x: Variant, y: Variant) -> String:
	return "(%s, %s)" % [n(s, x), n(s, y)]


static func lead(s: Dictionary, v: Variant) -> String:
	var q := Q.of(v)
	if s.get("paper", 1) == 2 and not q.is_int():
		return Fmt.dec(q)
	return Fmt.lead(q)


## " + 4", " − 2.5", "".
static func plus(s: Dictionary, v: Variant) -> String:
	var q := Q.of(v)
	if q.is_zero():
		return ""
	return " %s %s" % ["+" if q.sign() > 0 else "−", n(s, q.abs_q())]


static func x_minus(s: Dictionary, c: Variant, letter: String = "x") -> String:
	return letter + plus(s, Q.of(c).neg())


## B(x − C) as written: "x − 3", "2x", "½(x + 1)", "−x".
static func inner(s: Dictionary, map: Dictionary) -> String:
	var c: Q = map.C
	if map.B.eq(1):
		return x_minus(s, c)
	if c.is_zero():
		return lead(s, map.B) + "x"
	return "%s(%s)" % [lead(s, map.B), x_minus(s, c)]


## The base with its input written in: f_of(s, "x − 3") is "(x − 3)²".
static func f_of(s: Dictionary, x: String) -> String:
	var plain := x == "x"
	var wrapped := x if plain else "(%s)" % x
	match s.fam:
		"sq":
			return "%s²" % wrapped
		"cube":
			return "%s³" % wrapped
		"root":
			return "√" + wrapped
		"recip":
			return "1/" + wrapped
		"exp":
			return "e^" + wrapped
		"ln":
			return "ln x" if plain else "ln" + wrapped
		"log2":
			return "log₂ x" if plain else "log₂" + wrapped
		"sin":
			return "sin x" if plain else "sin" + wrapped
		"vert":
			return "(%s%s)²%s" % [x, plus(s, s.u.neg()), plus(s, s.v)]
		"poly":
			return "%s² %s %s%s" % [wrapped, "+" if s.u.sign() > 0 else "−", (Fmt.lead(s.u.abs_q()) + wrapped), plus(s, s.v)]
	return "f(%s)" % x


## A·f(B(x − C)) + D with the rule written in, for any map.
static func rule(s: Dictionary, map: Dictionary) -> String:
	var body := f_of(s, inner(s, map))
	var a: Q = map.A
	if s.fam == "pts":
		return lead(s, a) + body + plus(s, map.D)
	if a.eq(1):
		return body + plus(s, map.D)
	if s.fam in ["vert", "poly"]:
		return "%s(%s)%s" % [lead(s, a), body, plus(s, map.D)]
	if s.fam == "recip":
		var num := n(s, a)
		return num + body.trim_prefix("1") + plus(s, map.D)
	var gap := " " if s.fam in ["ln", "log2", "sin"] else ""
	var head := lead(s, a)
	return head + (gap if head != "−" else "") + body + plus(s, map.D)


static func f_rule(s: Dictionary) -> String:
	return f_of(s, "x")


static func g_rule(s: Dictionary) -> String:
	return rule(s, s.map)


static func tr_text(s: Dictionary, c: Variant, d: Variant) -> String:
	return "a translation by the vector %s" % pt(s, c, d)


static func vs_text(s: Dictionary, a: Variant) -> String:
	return "a vertical stretch with scale factor %s" % n(s, a)


static func hs_text(s: Dictionary, a: Variant) -> String:
	return "a horizontal stretch with scale factor %s" % n(s, a)


const RX := "a reflection in the x-axis"
const RY := "a reflection in the y-axis"


static func move_text(s: Dictionary, m: Dictionary) -> String:
	match m.k:
		"vs":
			return vs_text(s, m.a)
		"hs":
			return hs_text(s, m.a)
		"rx":
			return RX
		"ry":
			return RY
	return tr_text(s, m.c, m.d)


## "a vertical stretch with scale factor 2, then a translation by the vector (1, 3)".
static func chain_text(s: Dictionary, moves: Array) -> String:
	return ", then ".join(PackedStringArray(moves.map(func(m): return move_text(s, m))))


## A sentence: "A vertical stretch ...".
static func cap(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1)


# ── Domains and ranges ───────────────────────────────────────
# A set of reals is {"lo", "hi", "lo_in", "hi_in", "hole"}: an end is null when it is
# open-ended, lo_in says the end is included, and hole is one number left out.

static func f_domain(s: Dictionary) -> Dictionary:
	match s.fam:
		"root":
			return {"lo": Q.new(0), "lo_in": true}
		"recip":
			return {"hole": Q.new(0)}
		"ln", "log2":
			return {"lo": Q.new(0), "lo_in": false}
		"pts":
			return {"lo": s.nodes[0][0], "hi": s.nodes[-1][0], "lo_in": true, "hi_in": true}
	return {}


static func f_range(s: Dictionary) -> Dictionary:
	match s.fam:
		"sq":
			return {"lo": Q.new(0), "lo_in": true}
		"root":
			return {"lo": Q.new(0), "lo_in": true}
		"recip":
			return {"hole": Q.new(0)}
		"exp":
			return {"lo": Q.new(0), "lo_in": false}
		"sin":
			return {"lo": Q.new(-1), "hi": Q.new(1), "lo_in": true, "hi_in": true}
		"vert":
			return {"lo": s.v, "lo_in": true}
		"pts":
			var ys: Array = s.nodes.map(func(p): return p[1])
			ys.sort_custom(func(a, b): return a.to_float() < b.to_float())
			return {"lo": ys[0], "hi": ys[-1], "lo_in": true, "hi_in": true}
	return {}


## The set under t -> m·t + q.
static func moved_set(set: Dictionary, m: Q, q: Q) -> Dictionary:
	var out := {}
	if set.has("hole"):
		out.hole = m.mul(set.hole).add(q)
	var lo: Variant = m.mul(set.lo).add(q) if set.has("lo") else null
	var hi: Variant = m.mul(set.hi).add(q) if set.has("hi") else null
	var flip := m.sign() < 0
	var new_lo: Variant = hi if flip else lo
	var new_hi: Variant = lo if flip else hi
	if new_lo != null:
		out.lo = new_lo
		out.lo_in = set.get("hi_in" if flip else "lo_in", false)
	if new_hi != null:
		out.hi = new_hi
		out.hi_in = set.get("lo_in" if flip else "hi_in", false)
	return out


static func g_domain(s: Dictionary) -> Dictionary:
	return moved_set(f_domain(s), Q.new(1).div(s.map.B), s.map.C)


static func g_range(s: Dictionary) -> Dictionary:
	return moved_set(f_range(s), s.map.A, s.map.D)


## "x ≥ 3", "−1 ≤ x ≤ 3", "x ≠ 2", "all real x".
static func set_text(s: Dictionary, set: Dictionary, letter: String) -> String:
	if set.has("hole"):
		return "%s ≠ %s" % [letter, n(s, set.hole)]
	var has_lo := set.has("lo")
	var has_hi := set.has("hi")
	if has_lo and has_hi:
		return "%s %s %s %s %s" % [n(s, set.lo), "≤" if set.lo_in else "<", letter, "≤" if set.hi_in else "<", n(s, set.hi)]
	if has_lo:
		return "%s %s %s" % [letter, "≥" if set.lo_in else ">", n(s, set.lo)]
	if has_hi:
		return "%s %s %s" % [letter, "≤" if set.hi_in else "<", n(s, set.hi)]
	return "all real " + letter


## The vertical and horizontal asymptotes of f, as numbers (null where it has none).
static func f_asymptotes(s: Dictionary) -> Dictionary:
	match s.fam:
		"recip":
			return {"x": Q.new(0), "y": Q.new(0)}
		"exp":
			return {"y": Q.new(0)}
		"ln", "log2":
			return {"x": Q.new(0)}
	return {}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
