class_name LinearInputSituation
extends RefCounted
## The `linear-input` situation (curriculum/question-types.json), for fn-ext-linear-input
## (FAL-1008): y = f(x) and y = f(ax + b), or y = f(b − x), with a point of f and its image.
## The graph of f, where one is drawn, is transformation-chain's `pts` base: straight pieces
## through five grid corners, with no rule, so that the views can reuse its cards.
##
## generate() returns:
##   kind   "lin" for f(ax + b), "refl" for f(b − x) (a = −1)
##   a, b   the input's numbers, as Q: a is 2, 3, ½ or ⅓ (½ or 2 when a graph is drawn), b a
##          nonzero whole number
##   p, q   a point of y = f(x), whole numbers, q nonzero
##   x0     its image's x-coordinate, (p − b)/a, a whole number
##   map    transformation-chain's g(x) = A·f(B(x − C)) + D for the move: A 1, B a, C −b/a, D 0
##   fam, nodes, key, win   the drawn base (fam "pts"), the two corners marked on it (P is
##          key[0], the point (p, q)) and a window, when need.rep is "graph"
##   paper  1: nothing needs a calculator
##
## need: kind ("lin" or "refl") and rep ("graph" draws f).

const TC := preload("res://engine/situations/transform_chain.gd")
const A_EQ := [[2, 1], [3, 1], [1, 2], [1, 3]]
const A_GRAPH := [[2, 1], [1, 2]]
## The widest window, in units, a graph may need (transformation-chain's SPAN).
const SPAN := 26


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var drawn: bool = need.get("rep", "equation") == "graph"
	var refl: bool = need.get("kind", "lin") == "refl"
	for i in 500:
		var s := _try(rng, refl, drawn)
		if not s.is_empty():
			return s
	return {}


static func _try(rng: Seeded, refl: bool, drawn: bool) -> Dictionary:
	var s := {"kind": "refl" if refl else "lin", "paper": 1, "fam": "pts"}
	var a: Q
	var b: Q
	if refl:
		a = Q.new(-1)
		b = Q.new(ExtensionViews.nonzero(rng, -5, 5))
	else:
		var pick: Array = rng.pick(A_GRAPH if drawn else A_EQ)
		a = Q.new(pick[0], pick[1])
		if drawn:
			# On a grid: a = 2 takes an even b, so (x − b)/2 is whole at even corners.
			b = Q.new(2 * ExtensionViews.nonzero(rng, -2, 2)) if a.eq(2) else Q.new(ExtensionViews.nonzero(rng, -1, 1))
		else:
			b = Q.new(ExtensionViews.nonzero(rng, -6, 6))
	s.a = a
	s.b = b
	s.map = {"A": Q.new(1), "B": a, "C": b.neg().div(a), "D": Q.new(0)}
	if drawn:
		s.nodes = TC._nodes(rng)
		var pts: Array = s.nodes.filter(func(n): return not n[0].is_zero() and not n[1].is_zero())
		if pts.size() < 2:
			return {}
		pts = rng.shuffled(pts)
		var key: Array = TC.two_apart(pts)
		if key.is_empty():
			return {}
		s.key = key
		s.p = key[0][0]
		s.q = key[0][1]
	else:
		if refl:
			s.p = Q.new(ExtensionViews.nonzero(rng, -6, 6))
		else:
			# The image first, so it is whole, then the point it came from.
			var x0 := Q.new(ExtensionViews.nonzero(rng, -5, 5))
			s.p = a.mul(x0).add(b)
		s.q = Q.new(ExtensionViews.nonzero(rng, -6, 6))
	var p: Q = s.p
	if not p.is_int() or p.abs_q().to_float() > 9.0 or p.is_zero():
		return {}
	s.x0 = p.sub(b).div(a)
	if not s.x0.is_int() or s.x0.is_zero():
		return {}
	# f(b − x): the point is not its own image, so the reflection shows.
	if refl and b.eq(p.mul(2)):
		return {}
	if drawn:
		# Both marked points move, so following them tells the graphs apart.
		for kp in s.key:
			if TC.image(s.map, kp[0], kp[1])[0].eq(kp[0]):
				return {}
		s.win = window(s, all_maps(s))
		if s.win[1] - s.win[0] > SPAN or s.win[3] - s.win[2] > SPAN:
			return {}
	return s


## The maps the views draw: the answer's and, for f(ax + b), the three slips' (stretch first
## by −b, scale factor a, the wrong way). Every card shares one window.
static func all_maps(s: Dictionary) -> Array:
	var maps: Array = [s.map]
	if s.kind == "lin":
		var a: Q = s.a
		var b: Q = s.b
		maps += [slip_map(a, b.neg()), slip_map(Q.new(1).div(a), a.mul(b).neg()), slip_map(a, b.div(a))]
	return maps


## x -> x/B + C as transformation-chain's map.
static func slip_map(B: Q, C: Q) -> Dictionary:
	return {"A": Q.new(1), "B": B, "C": C, "D": Q.new(0)}


## A window in whole units round every corner of f and of each map's image, and the origin.
static func window(s: Dictionary, maps: Array) -> Array:
	var xs: Array = [0.0]
	var ys: Array = [0.0]
	for n in s.nodes:
		xs.append(n[0].to_float())
		ys.append(n[1].to_float())
		for m in maps:
			xs.append(TC.image(m, n[0], n[1])[0].to_float())
	return [mini(floori(xs.min()) - 1, -4), maxi(ceili(xs.max()) + 1, 4), mini(floori(ys.min()) - 1, -4), maxi(ceili(ys.max()) + 1, 4)]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
