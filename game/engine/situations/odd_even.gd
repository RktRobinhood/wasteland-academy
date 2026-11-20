class_name OddEvenSituation
extends RefCounted
## The `odd-even` situation (curriculum/question-types.json), FAL-1007: fn-ahl-odd-even
## (AHL2.14). One function, or a pair, or half a graph, and whether it is odd, even or
## neither. Every number is whole or a fraction of whole numbers; the SymPy checker
## (tools/check_answers.py, r9oe_check) reads each question back and works it again.
##
## A function is a list of terms {c, p, g}: c·x^p·g(x), c a whole number, g one of
##   ""      1, so the term is c·x^p
##   "sin"   sin x          "cos"  cos x
##   "exp"   e^x (p = 0)    "nexp" e^(−x) (p = 0)
## A term's parity is (−1)^p times g's (sin odd, cos even). e^x and e^(−x) swap under
## x -> −x, so a e^x + b e^(−x) is even when a = b, odd when a = −b, else neither.
##
## need.ask is the unknown, and decides what is drawn:
##   classify-polynomial   terms (powers only); parity; oddconst (odd powers plus a constant)
##   classify-mixed        terms with sin, cos or e^x; parity; at_pi (f(−π) = f(π) though f
##                         is not even: the odd part is all x^(2k) sin x terms)
##   symmetry-coefficient  target odd or even; terms (fixed); kt: the two coefficients
##                         with k in them, [{p, r}] for (k − r)x^p, the first of the wrong
##                         kind (so k = its r), the second of the right kind
##   value-from-symmetry   parity; a, b: f(a) = b; m: asked f(−a) + m·f(a); form (the rule's
##                         shape, equation) or half (graph)
##   complete-graph        parity; half: key points [[x, y]] for x ≥ 0; k: the slip's centre
##   which-graph           parity; halves: four halves, one per card; k, h: the shifts
##   combine-parity        pf, pg: f's and g's parity; op: product, sum, fg (f(g(x))), gf
##   symmetric-integral    mode "given" (f odd or even, ∫ from 0 to a given as I), "poly"
##                         (odd + even terms written out) or "graph" (half of a polyline);
##                         a; I; odd, even (terms, poly mode); half (graph)
## ctr: the counterexample input (classify, where the function is neither).

const TRIES := 400
const CO := 9
const X_MAX := 7
const Y_MAX := 5
const PARITIES := ["odd", "even", "neither"]
const OPS := ["product", "sum", "fg", "gf"]
## The rule shapes for a value from an equation: [text with p, q (r), parity].
const FORMS := [
	["px³ + qx", "odd"], ["px⁵ + qx³", "odd"], ["p sin x + qx", "odd"], ["px³ + q sin x", "odd"],
	["px⁴ + qx² + r", "even"], ["p cos x + qx²", "even"], ["px⁴ + q cos x", "even"], ["px³ + qx cos x", "odd"],
]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "classify-polynomial")
	var angle: String = need.get("angle", "any")
	var paper: int = int(need.get("paper", 1))
	for i in TRIES:
		var s := {"ask": ask, "paper": paper}
		var ok := false
		match ask:
			"classify-polynomial":
				ok = _polynomial(rng, s, angle)
			"classify-mixed":
				ok = _mixed(rng, s, angle)
			"symmetry-coefficient":
				ok = _coefficient(rng, s)
			"value-from-symmetry":
				ok = _value(rng, s, need.get("rep", "equation"))
			"complete-graph":
				ok = _complete(rng, s)
			"which-graph":
				ok = _which(rng, s)
			"combine-parity":
				ok = _combine(rng, s, angle)
			"symmetric-integral":
				ok = _integral(rng, s, need.get("rep", "equation"))
		if ok:
			return s
	return {}


# ── Functions as terms ───────────────────────────────────────

static func term(c: int, p: int, g: String = "") -> Dictionary:
	return {"c": c, "p": p, "g": g}


## +1 even, −1 odd, 0 for e^x or e^(−x) alone.
static func term_parity(t: Dictionary) -> int:
	var sign := 1 if int(t.p) % 2 == 0 else -1
	match t.g:
		"sin":
			return -sign
		"exp", "nexp":
			return 0
	return sign


## "odd", "even" or "neither" for a list of terms, none of them zero.
static func parity(terms: Array) -> String:
	var odd := false
	var even := false
	var ea := 0
	var eb := 0
	for t in terms:
		match t.g:
			"exp":
				ea += int(t.c)
			"nexp":
				eb += int(t.c)
			_:
				if term_parity(t) > 0:
					even = true
				else:
					odd = true
	if ea != 0 or eb != 0:
		if ea + eb != 0:
			even = true
		if ea - eb != 0:
			odd = true
	if odd and even:
		return "neither"
	return "odd" if odd else "even"


## The odd part (sign −1) or even part (+1) of the terms, an exp pair split into halves
## is not needed here: only terms of one parity, for the polynomial and trig pieces.
static func part(terms: Array, sign: int) -> Array:
	return terms.filter(func(t): return t.g not in ["exp", "nexp"] and term_parity(t) == sign)


## f(−x) as terms: each sign flipped by its parity, e^x and e^(−x) swapped.
static func at_minus(terms: Array) -> Array:
	var out: Array = []
	for t in terms:
		match t.g:
			"exp":
				out.append(term(t.c, 0, "nexp"))
			"nexp":
				out.append(term(t.c, 0, "exp"))
			_:
				out.append(term(int(t.c) * term_parity(t), t.p, t.g))
	return out


## f(a) for a whole a, as a combination of 1, sin a, cos a, e^a and e^(−a): a Dictionary
## basis -> whole coefficient ("1", "sin", "cos", "exp", "nexp").
static func value_at(terms: Array, a: int) -> Dictionary:
	var v := {"1": 0, "sin": 0, "cos": 0, "exp": 0, "nexp": 0}
	for t in terms:
		var k: int = int(t.c) * int(pow(a, int(t.p)))
		match t.g:
			"sin":
				# sin(−a) = −sin a: the basis is sin |a|.
				v.sin += k * (1 if a >= 0 else -1)
			"cos":
				v.cos += k
			"exp":
				if a >= 0:
					v.exp += k
				else:
					v.nexp += k
			"nexp":
				if a >= 0:
					v.nexp += k
				else:
					v.exp += k
			_:
				v["1"] += k
	return v


static func nonzero(v: Dictionary) -> bool:
	return v.values().any(func(c): return int(c) != 0)


static func plus(u: Dictionary, w: Dictionary, sign: int) -> Dictionary:
	var out := {}
	for k in u:
		out[k] = int(u[k]) + sign * int(w[k])
	return out


# ── classify-polynomial ──────────────────────────────────────

static func _polynomial(rng: Seeded, s: Dictionary, angle: String) -> bool:
	var want: String = "neither" if angle == "counterexample" else PARITIES[rng.int_in(0, 2)]
	var powers: Array
	s.oddconst = false
	match want:
		"odd":
			powers = _some(rng, [1, 3, 5], rng.int_in(2, 3))
		"even":
			powers = _some(rng, [2, 4], rng.int_in(1, 2))
			if powers.size() == 1 or rng.chance(0.6):
				powers.append(0)
		_:
			if rng.chance(0.5):
				powers = _some(rng, [1, 3, 5], rng.int_in(1, 2)) + [0]
				s.oddconst = true
			else:
				powers = _some(rng, [1, 3, 5], rng.int_in(1, 2)) + _some(rng, [0, 2, 4], rng.int_in(1, 2))
	powers.sort()
	powers.reverse()
	var terms: Array = []
	for i in powers.size():
		var c := ExtensionViews.nonzero(rng, -CO, CO)
		if i == 0 and rng.chance(0.6):
			c = absi(c) if absi(c) <= 4 else rng.int_in(1, 3)
		terms.append(term(c, powers[i]))
	s.terms = terms
	s.parity = parity(terms)
	if s.parity != want:
		return false
	return _counter(s)


## Up to n of the items, in a random order.
static func _some(rng: Seeded, items: Array, n: int) -> Array:
	return rng.shuffled(items).slice(0, mini(n, items.size()))


## The counterexample input for a function that is neither: the least whole a from 1 to 3
## with f(−a) ≠ f(a) and f(−a) ≠ −f(a).
static func _counter(s: Dictionary) -> bool:
	s.ctr = 0
	if s.parity != "neither":
		return true
	for a in [1, 2, 3]:
		var up := value_at(s.terms, a)
		var down := value_at(s.terms, -a)
		if nonzero(plus(up, down, -1)) and nonzero(plus(up, down, 1)):
			s.ctr = a
			return true
	return false


# ── classify-mixed ───────────────────────────────────────────

## The pieces of a mixed function: [terms, parity, kind] with kind "trig", "exp" or "poly".
static func _piece(rng: Seeded, want: String) -> Array:
	var c := ExtensionViews.nonzero(rng, -6, 6)
	if want == "odd":
		match rng.int_in(0, 5):
			0:
				return [[term(c, rng.pick([1, 3]))], "poly"]
			1:
				return [[term(c, 0, "sin")], "trig"]
			2:
				return [[term(c, 2, "sin")], "trig"]
			3:
				return [[term(c, rng.pick([1, 3]), "cos")], "trig"]
			4:
				var k := rng.int_in(1, 4)
				return [[term(k, 0, "exp"), term(-k, 0, "nexp")], "exp"]
			_:
				return [[term(c, 0, "sin")], "trig"]
	match rng.int_in(0, 5):
		0:
			return [[term(c, rng.pick([0, 2, 4]))], "poly"]
		1:
			return [[term(c, 0, "cos")], "trig"]
		2:
			return [[term(c, 2, "cos")], "trig"]
		3:
			return [[term(c, 1, "sin")], "trig"]
		4:
			var k := rng.int_in(1, 4)
			return [[term(k, 0, "exp"), term(k, 0, "nexp")], "exp"]
	return [[term(c, 1, "sin")], "trig"]


static func _mixed(rng: Seeded, s: Dictionary, angle: String) -> bool:
	var want: String = "neither" if angle == "counterexample" else PARITIES[rng.int_in(0, 2)]
	var kinds: Array = []
	var pieces: Array = []
	match want:
		"odd", "even":
			for i in rng.int_in(2, 3):
				pieces.append(_piece(rng, want))
		_:
			if rng.chance(0.25):
				# a e^x + b e^(−x) with a ≠ ±b, and maybe a power.
				var a := rng.int_in(1, 4)
				var b := rng.int_in(1, 4)
				if a == b:
					return false
				pieces.append([[term(a, 0, "exp"), term(b if rng.chance(0.5) else -b, 0, "nexp")], "exp"])
				if rng.chance(0.5):
					pieces.append(_piece(rng, rng.pick(["odd", "even"])))
			else:
				pieces.append(_piece(rng, "odd"))
				pieces.append(_piece(rng, "even"))
	# The f(−π) = f(π) slip: an odd part of x^(2k) sin x terms alone, as sin π = 0.
	if want != "even" and rng.chance(0.4):
		var sins: Array = [[[term(ExtensionViews.nonzero(rng, -6, 6), 2, "sin")], "trig"], [[term(ExtensionViews.nonzero(rng, -6, 6), 0, "sin")], "trig"]]
		if want == "odd":
			pieces = sins if rng.chance(0.6) else [sins[rng.int_in(0, 1)], [[term(ExtensionViews.nonzero(rng, -6, 6), 1, "cos")], "trig"]]
		else:
			var ev := _piece(rng, "even")
			if ev[1] == "exp":
				return false
			pieces = [ev, sins[rng.int_in(0, 1)]]
	var terms: Array = []
	var seen := {}
	var exps := 0
	for pc in pieces:
		kinds.append(pc[1])
		if pc[1] == "exp":
			exps += 1
		for t in pc[0]:
			var key := "%d%s" % [t.p, t.g]
			if seen.has(key):
				return false
			seen[key] = true
			terms.append(t)
	if exps > 1 or not ("trig" in kinds or "exp" in kinds):
		return false
	if angle == "unit-circle" and not "trig" in kinds:
		return false
	if terms.size() > 4:
		return false
	terms = _ordered(terms)
	s.terms = terms
	s.parity = parity(terms)
	if s.parity != want:
		return false
	# Odd functions and those that are neither: does f(−π) = f(π)? (sin π = 0)
	s.at_pi = s.parity != "even" and part(terms, -1).all(func(t): return t.g == "sin") and not terms.any(func(t): return t.g in ["exp", "nexp"])
	return _counter(s)


## Powers first (highest first), then the trig terms, then e^x and e^(−x), then a constant.
static func _ordered(terms: Array) -> Array:
	var rank := func(t: Dictionary) -> int:
		var g := {"": 0, "sin": 1, "cos": 2, "exp": 3, "nexp": 4}
		return 99 if t.g == "" and int(t.p) == 0 else int(g[t.g]) * 10 + (9 - int(t.p))
	var out := terms.duplicate()
	out.sort_custom(func(a, b): return rank.call(a) < rank.call(b))
	return out


# ── symmetry-coefficient ─────────────────────────────────────

static func _coefficient(rng: Seeded, s: Dictionary) -> bool:
	var odd := rng.chance(0.5)
	s.target = "odd" if odd else "even"
	var right: Array = [1, 3, 5] if odd else [0, 2, 4]
	var wrong_kind: Array = [0, 2, 4] if odd else [1, 3]
	var pw: int = rng.pick(wrong_kind)
	var pr: int = rng.pick(right)
	var r := ExtensionViews.nonzero(rng, -6, 6)
	var w := ExtensionViews.nonzero(rng, -6, 6)
	if r == w:
		return false
	var fixed: Array = _some(rng, right.filter(func(p): return p != pr and p != 0), rng.int_in(1, 2))
	var terms: Array = []
	for p in fixed:
		terms.append(term(ExtensionViews.nonzero(rng, -CO, CO), p))
	s.terms = terms
	s.kt = [{"p": pw, "r": r}, {"p": pr, "r": w}]
	# Every power shown, highest first, and the highest a fixed one or k's of the right kind.
	var all: Array = fixed + [pw, pr]
	if all.max() == pw:
		return false
	return true


## The whole function for a k: the fixed terms and the two with k in them.
static func with_k(s: Dictionary, k: int) -> Array:
	var terms: Array = s.terms.duplicate()
	for t in s.kt:
		if k - int(t.r) != 0:
			terms.append(term(k - int(t.r), t.p))
	terms.sort_custom(func(a, b): return int(a.p) > int(b.p))
	return terms


# ── value-from-symmetry ──────────────────────────────────────

static func _value(rng: Seeded, s: Dictionary, rep: String) -> bool:
	s.m = rng.pick([0, 0, 1, -1, 2])
	s.b = ExtensionViews.nonzero(rng, -12, 12)
	if rep == "graph":
		s.parity = rng.pick(["odd", "even"])
		s.half = _half(rng, s.parity == "odd")
		var pts: Array = s.half.filter(func(p): return int(p[0]) > 0 and int(p[1]) != 0)
		if pts.is_empty():
			return false
		var pt: Array = rng.pick(pts)
		s.a = int(pt[0])
		s.b = int(pt[1])
	else:
		var f: Array = FORMS[rng.int_in(0, FORMS.size() - 1)]
		s.form = f[0]
		s.parity = f[1]
		s.a = rng.int_in(1, 5)
	return true


## Half a graph, x ≥ 0: four key points from x = 0, whole numbers, through the origin
## for an odd function (defined at 0), not flat.
static func _half(rng: Seeded, odd: bool, low: int = -Y_MAX) -> Array:
	var xs := [0]
	var x := 0
	for i in 3:
		x += rng.int_in(1, 3)
		xs.append(x)
	if x > X_MAX:
		return _half(rng, odd, low)
	var pts: Array = []
	for i in xs.size():
		var y := rng.int_in(low, Y_MAX)
		if i == 0 and odd:
			y = 0
		pts.append([xs[i], y])
	# Not flat, no two neighbours level, and some point off the x-axis.
	for i in range(1, pts.size()):
		if pts[i][1] == pts[i - 1][1]:
			return _half(rng, odd, low)
	if pts.all(func(p): return p[1] == 0) or (not odd and pts.all(func(p): return p[1] == pts[0][1])):
		return _half(rng, odd, low)
	return pts


## The half's image for x ≤ 0: (−x, y) mirrored for even, (−x, −y) turned for odd,
## from x = 0 out.
static func other_half(half: Array, odd: bool) -> Array:
	return half.map(func(p): return [-int(p[0]), -int(p[1]) if odd else int(p[1])])


# ── complete-graph and which-graph ───────────────────────────

static func _complete(rng: Seeded, s: Dictionary) -> bool:
	s.parity = rng.pick(["odd", "even"])
	s.half = _half(rng, s.parity == "odd")
	s.k = ExtensionViews.nonzero(rng, -2, 2)
	# The half-turn about (0, k) stays on the grid.
	return s.half.all(func(p): return absi(2 * int(s.k) - int(p[1])) <= Y_MAX + 3)


static func _which(rng: Seeded, s: Dictionary) -> bool:
	s.parity = rng.pick(["odd", "even"])
	var odd: bool = s.parity == "odd"
	s.halves = [_half(rng, odd), _half(rng, not odd), _half(rng, odd, -3), _half(rng, false)]
	s.k = rng.pick([-2, -1, 1, 2]) if odd else 0
	s.h = rng.pick([-2, -1, 1, 2]) if not odd else 0
	# The fourth card's left half: another half's mirror, so the card is neither.
	var four: Array = s.halves[3]
	var left := _half(rng, false)
	left[0][1] = four[0][1]
	if int(left[1][1]) == int(left[0][1]):
		return false
	s.left = left
	# Neither: some point's mirror and half-turn are both off the card.
	var even_ok := true
	var odd_ok := true
	for i in four.size():
		if int(left[i][0]) != int(four[i][0]) or int(left[i][1]) != int(four[i][1]):
			even_ok = false
		if int(left[i][0]) != int(four[i][0]) or int(left[i][1]) != -int(four[i][1]):
			odd_ok = false
	if even_ok or odd_ok:
		return false
	# The shifted card stays on the grid.
	if odd:
		return s.halves[2].all(func(p): return absi(int(p[1])) + absi(int(s.k)) <= Y_MAX + 1)
	return s.halves[2][-1][0] + absi(int(s.h)) <= X_MAX + 1


# ── combine-parity ───────────────────────────────────────────

static func _combine(rng: Seeded, s: Dictionary, angle: String) -> bool:
	s.op = "product" if angle == "sign-rule" else OPS[rng.weighted([4, 3, 2, 2])]
	var pair: Array = rng.pick([["odd", "even"], ["even", "odd"], ["odd", "odd"], ["even", "even"]])
	# The two slips: odd × odd, and a sum of an odd and an even function.
	if s.op == "product" and rng.chance(0.35):
		pair = ["odd", "odd"]
	if s.op == "sum" and rng.chance(0.5):
		pair = rng.pick([["odd", "even"], ["even", "odd"]])
	s.pf = pair[0]
	s.pg = pair[1]
	s.parity = combined(s.pf, s.pg, s.op)
	return true


## The parity of h from f's, g's and the way they are put together.
static func combined(pf: String, pg: String, op: String) -> String:
	var sg := func(p: String) -> int: return -1 if p == "odd" else 1
	match op:
		"product":
			return "even" if sg.call(pf) * sg.call(pg) > 0 else "odd"
		"sum":
			return pf if pf == pg else "neither"
		"fg":
			return "even" if pg == "even" else pf
		"gf":
			return "even" if pf == "even" else pg
	return ""


# ── symmetric-integral ───────────────────────────────────────

static func _integral(rng: Seeded, s: Dictionary, rep: String) -> bool:
	s.a = rng.int_in(1, 3)
	if rep == "graph":
		s.mode = "graph"
		s.parity = rng.pick(["odd", "even"])
		s.half = _half(rng, s.parity == "odd", 0)
		s.a = int(s.half[-1][0])
		s.I = poly_area(s.half)
		return not s.I.is_zero() and s.half.slice(1).all(func(p): return int(p[1]) > 0)
	if rng.chance(0.45):
		s.mode = "given"
		s.parity = rng.pick(["odd", "even"])
		s.a = rng.int_in(1, 6)
		if s.paper == 2:
			s.I = Q.new(ExtensionViews.nonzero(rng, -900, 900), 100)
			if absi(s.I.n) < 50 or s.I.is_int():
				return false
		else:
			s.I = Q.new(ExtensionViews.nonzero(rng, -12, 12))
		return true
	s.mode = "poly"
	var odd: Array = []
	var even: Array = []
	var shape := rng.weighted([3, 5, 2])
	if shape <= 1:
		var pool: Array = [term(1, 1), term(1, 3)] + ([term(1, 5)] if s.a <= 2 else []) + [term(1, 0, "sin"), term(1, 2, "sin"), term(1, 1, "cos"), term(1, 3, "cos")]
		for t in _some(rng, pool, rng.int_in(1, 2)):
			odd.append(term(ExtensionViews.nonzero(rng, -6, 6), t.p, t.g))
	if shape >= 1:
		for p in _some(rng, [0, 2, 4] if s.a <= 2 else [0, 2], rng.int_in(1, 2)):
			even.append(term(ExtensionViews.nonzero(rng, -6, 6), p))
	s.odd = _ordered(odd)
	s.even = _ordered(even)
	s.I = half_integral(s.even, s.a)
	s.parity = parity(odd + even)
	# A purely even integrand's integral isn't 0 by accident.
	return not (even.size() > 0 and s.I.is_zero())


## ∫ from 0 to a of a polynomial's terms, exactly.
static func half_integral(terms: Array, a: int) -> Q:
	var total := Q.new(0)
	for t in terms:
		total = total.add(Q.new(int(t.c) * int(pow(a, int(t.p) + 1)), int(t.p) + 1))
	return total


## The area under a polyline between its first and last x, as trapezia (y ≥ 0).
static func poly_area(pts: Array) -> Q:
	var total := Q.new(0)
	for i in range(1, pts.size()):
		total = total.add(Q.new((int(pts[i][0]) - int(pts[i - 1][0])) * (int(pts[i][1]) + int(pts[i - 1][1])), 2))
	return total


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
