class_name BasicRestrictedSituation
extends RefCounted
## The `basic-restricted` situation (curriculum/question-types.json), which extends
## basic-function: a rule with a stated domain, a reflection, a second function to compose
## with or an inverse, so the range has to be worked out (FAL-424). fn-domain-range is
## built on it. Rules are BasicFunctionSituation's. x is the letter, f the name.
##
## generate() returns, by need.kind:
##   any-quad  a parabola: f, a, h, k (the vertex), opening up when a > 0
##   rat       (ax + b)/(cx + d): f, A (the horizontal asymptote), hv (the vertical one)
##   arc       a parabola on lo ≤ x ≤ hi with its vertex inside: f, lo, hi, fa, fb, k, ymin, ymax
##   compose   f and its bound m, form "root" or "ln" (g), kind of f "quad" (y ≥ m) or "exp" (y > m)
##   exp       A·b^x + c or A·e^x + c: f, c (the asymptote), up (A > 0)
##   root      A√(mx + n) + k: f, c (where the root starts), left (x ≤ c)
##   logfrac   ln(mx + n) + k or b/(x − c): f, c, form "log" or "frac"
##   piece     a line or a parabola on a domain with open or filled ends: f, lo, hi, lo_open,
##             hi_open, ylo, yhi, ylo_open, yhi_open, and its dots
##   line      mx + c on lo ≤ x ≤ hi: f, m, lo, hi, p, q (the range)
##   inverse   a one-to-one rule and its domain: f, form "root", "half" or "line", with
##             the ends d1, d2 of the domain and r1, r2 of the range (null: no end)
##   split     a parabola and a point on it: f, a, h, k, px, py
##
## Paper 1 ends and turning values are whole numbers. Paper 2 (need.paper, except with
## need.grid, for a graph to read) has decimal coefficients, and values to 3 s.f.
## The clean limits are the checker's too (tools/check_answers.py, BR_*).

const TRIES := 800


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var paper: int = need.get("paper", 1)
	for i in TRIES:
		var s := _draw(rng, need, paper)
		if not s.is_empty():
			s.paper = paper
			s.merge({"name": "f", "v": "x", "kind": need.get("kind", "any-quad")})
			return s
	push_error("BasicRestrictedSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, need: Dictionary, paper: int) -> Dictionary:
	var whole: bool = paper == 1 or need.get("grid", false)
	match need.get("kind", "any-quad"):
		"quad", "any-quad":
			return _quad(rng, whole)
		"rat":
			return _rat(rng, whole)
		"arc":
			return _arc(rng, whole)
		"compose":
			return _compose(rng, whole)
		"exp":
			return _exp(rng)
		"root":
			return _root(rng)
		"logfrac":
			return _logfrac(rng)
		"piece":
			return _piece(rng)
		"line":
			return _line(rng)
		"inverse":
			return _inverse(rng)
		"split":
			var s := _quad(rng, true)
			if not s.is_empty():
				var d: int = ExtensionViews.nonzero(rng, -3, 3)
				s.px = s.h.add(d)
				s.py = s.k.add(s.a.mul(d * d))
				if s.h.is_zero() or s.px.is_zero():
					return {}
			return s
	return {}


static func _quad(rng: Seeded, whole: bool) -> Dictionary:
	if whole:
		var a: int = [1, 1, -1, -1, 2, -2][rng.int_in(0, 5)]
		var h := ExtensionViews.nonzero(rng, -4, 4)
		var k := ExtensionViews.nonzero(rng, -6, 8)
		return {"f": BasicFunctionSituation.poly([a * h * h + k, -2 * a * h, a]), "a": Q.new(a), "h": Q.new(h), "k": Q.new(k)}
	var a2 := BasicFunctionSituation.tenths(rng, -25, 25)
	var b2 := BasicFunctionSituation.tenths(rng, -60, 60)
	var c2 := BasicFunctionSituation.tenths(rng, -60, 60)
	var k2 := c2.sub(b2.sq().div(a2.mul(4)))
	var h2 := b2.neg().div(a2.mul(2))
	if not BasicFunctionSituation.fair(k2):
		return {}
	return {"f": BasicFunctionSituation.poly([c2, b2, a2]), "a": a2, "h": h2, "k": k2}


static func _rat(rng: Seeded, whole: bool) -> Dictionary:
	var f: Dictionary
	if whole:
		var c: int = [1, 1, 2][rng.int_in(0, 2)]
		var a := ExtensionViews.nonzero(rng, -6, 6)
		var b := ExtensionViews.nonzero(rng, -7, 7)
		var d := ExtensionViews.nonzero(rng, -6, 6) * c
		if a * d == b * c:
			return {}
		f = {"fam": "rat", "a": Q.new(a), "b": Q.new(b), "c": Q.new(c), "d": Q.new(d)}
	else:
		f = {"fam": "rat", "a": BasicFunctionSituation.tenths(rng, 11, 79), "b": Q.new(rng.int_in(1, 9)), "c": BasicFunctionSituation.tenths(rng, 11, 39), "d": Q.new(ExtensionViews.nonzero(rng, -9, 9))}
		if f.a.mul(f.d).eq(f.b.mul(f.c)):
			return {}
	var big_a: Q = f.a.div(f.c)
	if not whole and not BasicFunctionSituation.fair(big_a):
		return {}
	return {"f": f, "A": big_a, "hv": f.d.neg().div(f.c)}


static func _arc(rng: Seeded, whole: bool) -> Dictionary:
	var s := _quad(rng, whole)
	if s.is_empty():
		return {}
	var hf: float = s.h.to_float()
	var lo := floori(hf) - rng.int_in(1, 3)
	var hi := ceili(hf) + rng.int_in(1, 3)
	if lo == hi or floori(hf) == ceili(hf) and hi - ceili(hf) == floori(hf) - lo:
		return {}
	var fa := BasicFunctionSituation.at(s.f, lo)
	var fb := BasicFunctionSituation.at(s.f, hi)
	if fa.eq(fb):
		return {}
	var near := fa if fa.lt(fb) else fb
	var far := fb if fa.lt(fb) else fa
	var low: Q = s.k if s.a.sign() > 0 else near
	var top: Q = far if s.a.sign() > 0 else s.k
	s.merge({"lo": Q.new(lo), "hi": Q.new(hi), "fa": fa, "fb": fb, "ymin": low, "ymax": top})
	if not whole and not (BasicFunctionSituation.fair(s.k) and absf(top.to_float()) < 500.0):
		return {}
	return s


static func _compose(rng: Seeded, whole: bool) -> Dictionary:
	var form: String = ["root", "ln"][rng.int_in(0, 1)]
	if rng.chance(0.3):
		var m := rng.int_in(-5, 7)
		var f := {"fam": "expe", "A": Q.new(rng.int_in(1, 4)), "k": Q.new(1), "c": Q.new(m)}
		return {"f": f, "m": Q.new(m), "of": "exp", "form": form}
	var s := _quad(rng, whole)
	if s.is_empty() or s.a.sign() < 0:
		return {}
	s.merge({"m": s.k, "of": "quad", "form": form})
	return s


static func _exp(rng: Seeded) -> Dictionary:
	var c := ExtensionViews.nonzero(rng, -6, 7)
	var big: int = [1, 1, 2, 3, -1, -2][rng.int_in(0, 5)]
	var f: Dictionary = {"fam": "expe", "A": Q.new(big), "k": Q.new(1), "c": Q.new(c)} if rng.chance(0.5) \
		else {"fam": "exp", "A": Q.new(big), "b": Q.new(rng.int_in(2, 3)), "c": Q.new(c)}
	return {"f": f, "c": Q.new(c), "up": big > 0, "y_int": Q.new(big + c)}


static func _root(rng: Seeded) -> Dictionary:
	var c := ExtensionViews.nonzero(rng, -6, 7)
	var m: int = [1, 1, 2, 3, -1][rng.int_in(0, 4)]
	var f := {"fam": "root", "A": Q.new([1, 2, 3][rng.int_in(0, 2)]), "m": Q.new(m), "n": Q.new(-m * c), "k": Q.new(rng.int_in(-4, 4))}
	return {"f": f, "c": Q.new(c), "left": m < 0}


static func _logfrac(rng: Seeded) -> Dictionary:
	var c := ExtensionViews.nonzero(rng, -6, 7)
	if rng.chance(0.5):
		var m: int = [1, 2, 3][rng.int_in(0, 2)]
		return {"f": {"fam": "ln", "A": Q.new(1), "m": Q.new(m), "n": Q.new(-m * c), "k": Q.new(rng.int_in(-3, 3))}, "c": Q.new(c), "form": "log"}
	return {"f": {"fam": "rat", "a": Q.new(0), "b": Q.new(ExtensionViews.nonzero(rng, -6, 6)), "c": Q.new(1), "d": Q.new(-c)}, "c": Q.new(c), "form": "frac"}


## A line or a parabola on a domain; each end open or filled at random, and never both
## ends of the same height.
static func _piece(rng: Seeded) -> Dictionary:
	var lo := rng.int_in(-5, -1)
	var hi := rng.int_in(1, 5)
	var f: Dictionary
	var turn: Variant = null
	if rng.chance(0.5):
		f = BasicFunctionSituation.poly([rng.int_in(-3, 3), ExtensionViews.nonzero(rng, -2, 2)])
	else:
		var a: int = [1, -1][rng.int_in(0, 1)]
		var h := rng.int_in(lo + 1, hi - 1)
		var k := rng.int_in(-4, 4)
		f = BasicFunctionSituation.poly([a * h * h + k, -2 * a * h, a])
		turn = [Q.new(h), Q.new(k), a]
	var fa := BasicFunctionSituation.at(f, lo)
	var fb := BasicFunctionSituation.at(f, hi)
	if fa.eq(fb) or absi(fa.n) > 14 or absi(fb.n) > 14:
		return {}
	var lo_open := rng.chance(0.5)
	var hi_open := rng.chance(0.5)
	# Each y-end comes from a domain end, or from the turning point, which is on the graph.
	var low := [fa, lo_open] if fa.lt(fb) else [fb, hi_open]
	var top := [fb, hi_open] if fa.lt(fb) else [fa, lo_open]
	if turn != null:
		if turn[2] > 0:
			low = [turn[1], false]
		else:
			top = [turn[1], false]
	var dots: Array = [[lo, fa.to_float(), lo_open], [hi, fb.to_float(), hi_open]]
	return {"f": f, "lo": Q.new(lo), "hi": Q.new(hi), "lo_open": lo_open, "hi_open": hi_open, "ylo": low[0], "yhi": top[0],
		"ylo_open": low[1], "yhi_open": top[1], "dots": dots}


static func _line(rng: Seeded) -> Dictionary:
	var m: int = ExtensionViews.nonzero(rng, -4, 4)
	var c := rng.int_in(-6, 6)
	var lo := rng.int_in(-4, 2)
	var hi := lo + rng.int_in(2, 6)
	var f := BasicFunctionSituation.poly([c, m])
	var fa := m * lo + c
	var fb := m * hi + c
	return {"f": f, "m": Q.new(m), "c": Q.new(c), "lo": Q.new(lo), "hi": Q.new(hi), "p": Q.new(mini(fa, fb)), "q": Q.new(maxi(fa, fb))}


static func _inverse(rng: Seeded) -> Dictionary:
	match ["root", "half", "line"][rng.int_in(0, 2)]:
		"root":
			var c := ExtensionViews.nonzero(rng, -6, 6)
			var k := ExtensionViews.nonzero(rng, -5, 5)
			return {"f": {"fam": "root", "A": Q.new(1), "m": Q.new(1), "n": Q.new(-c), "k": Q.new(k)}, "form": "root", "d1": Q.new(c), "d2": null, "r1": Q.new(k), "r2": null}
		"half":
			var h := ExtensionViews.nonzero(rng, -4, 4)
			var k := ExtensionViews.nonzero(rng, -5, 5)
			return {"f": BasicFunctionSituation.poly([h * h + k, -2 * h, 1]), "form": "half", "d1": Q.new(h), "d2": null, "r1": Q.new(k), "r2": null}
	var s := _line(rng)
	s.merge({"form": "line", "d1": s.lo, "d2": s.hi, "r1": s.p, "r2": s.q})
	return s


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
