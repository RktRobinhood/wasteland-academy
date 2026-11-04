class_name LinearEquationSituation
extends RefCounted
## The `fn-pre-linear-equations` situation (curriculum/question-types.json): a linear equation
## with a known solution, for the prior-learning type fn-pre-linear-equations (FAL-424). The
## shapes built from x use its coefficients as they fall; both sides and brackets draw their
## coefficients and keep them only if x comes out clean, a simple fraction a quarter of the time.
##
## generate() returns, by need.form:
##   "two"       ax + b = c, solution x (whole; a > 0 and x > 0 in words)
##   "both"      ax + b = cx + d, solution x
##   "brackets"  p(x + q) = r(x + s), solution x
##   "fractions" shape "sum": x/p + x/q = r; shape "eq": (x + a)/p = (x − b)/q (a, b > 0);
##               L is the lowest common multiple of p and q; solution x
##   "y"         ax + by = k, as y = mx + c with c whole
##   "missing"   ax + b = c with blank "a", "b" or "c" hidden, solution x
##
## The clean limits are the checker's too (tools/check_answers.py, LE_*).

const TRIES := 4000
const LIM := 9
const MAX_DEN := 6


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var form: String = need.get("form", "two")
	var frac: bool = form in ["both", "brackets"] and rng.chance(0.25)
	for i in TRIES:
		var s := _draw(rng, form, need.get("rep", "equation"), frac)
		if not s.is_empty():
			s.form = form
			s.paper = 1
			return s
	push_error("LinearEquationSituation: no clean situation for %s" % need)
	return {}


static func _small(rng: Seeded) -> int:
	return ExtensionViews.nonzero(rng, -LIM, LIM)


## ±2 to ±9.
static func _coef(rng: Seeded) -> int:
	return rng.pick([-9, -8, -7, -6, -5, -4, -3, -2, 2, 3, 4, 5, 6, 7, 8, 9])


## Whether x is small and nonzero, and whole or a simple fraction, as drawn.
static func _clean(x: Q, frac: bool) -> bool:
	return not x.is_zero() and x.abs_q().to_float() <= LIM and (x.d > 1 and x.d <= MAX_DEN if frac else x.is_int())


static func _draw(rng: Seeded, form: String, rep: String, frac: bool) -> Dictionary:
	match form:
		"two":
			var a: int = rng.int_in(2, LIM) if rep == "words" else _coef(rng)
			var x: int = rng.int_in(1, LIM) if rep == "words" else _small(rng)
			var b := _small(rng)
			return {"a": a, "b": b, "c": a * x + b, "x": Q.new(x)}
		"both":
			var a := _small(rng)
			var c := _small(rng)
			if a == c:
				return {}
			var b := _small(rng)
			var d := _small(rng)
			var x := Q.new(d - b, a - c)
			return {"a": a, "b": b, "c": c, "d": d, "x": x} if _clean(x, frac) else {}
		"brackets":
			var p := _coef(rng)
			var r := _coef(rng)
			if p == r:
				return {}
			var q := _small(rng)
			var t := _small(rng)
			if q == t:
				return {}
			var x := Q.new(r * t - p * q, p - r)
			return {"p": p, "q": q, "r": r, "t": t, "x": x} if _clean(x, frac) else {}
		"fractions":
			var p := rng.int_in(2, MAX_DEN)
			var q := rng.int_in(2, MAX_DEN)
			if p == q:
				return {}
			var L := p * q / Q.gcd(p, q)
			if rng.chance(0.5):
				var x: int = L * ExtensionViews.nonzero(rng, -3, 3)
				var r: int = x / p + x / q
				return {"shape": "sum", "p": p, "q": q, "r": r, "L": L, "x": Q.new(x)} if absi(r) <= LIM else {}
			var a := rng.int_in(1, LIM)
			var b := rng.int_in(1, LIM)
			var x := Q.new(p * b + q * a, p - q)
			return {"shape": "eq", "p": p, "q": q, "a": a, "b": b, "L": L, "x": x} if x.is_int() and absi(x.n) <= 30 else {}
		"y":
			var a := _small(rng)
			var b := _coef(rng)
			var c := ExtensionViews.nonzero(rng, -6, 6)
			var m := Q.new(-a, b)
			return {"a": a, "b": b, "k": b * c, "m": m, "c": c} if m.d <= MAX_DEN else {}
		"missing":
			var blank: String = rng.pick(["a", "b", "c"])
			var x: int = _coef(rng)
			var a: int = rng.int_in(2, LIM) if blank == "a" else _coef(rng)
			var b := _small(rng)
			return {"a": a, "b": b, "c": a * x + b, "x": Q.new(x), "blank": blank}
	return {}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
