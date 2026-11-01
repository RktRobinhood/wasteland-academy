class_name InverseRuleSituation
extends RefCounted
## The `inverse-rule` situation (curriculum/question-types.json): a rule f from a family
## with a domain that makes it one-to-one, then its inverse and the swapped domain and
## range (FAL-422). `fn-pre-rearrange` and `fn-link-inverses` build on the same ideas.
##
## A rule is {"fam": family, ...}:
##   lin    a·x + b                     all x, all y
##   rat    (a·x + b)/(c·x + d)         x ≠ −d/c, y ≠ a/c (c ≠ 0, ad − bc ≠ 0); the
##                                      asymptotes are whole numbers
##   root   √(p·x + q) + r              x ≥ x0 = −q/p (a whole number), y ≥ r
##   rquad  (x − h)² + k on x ≥ h (dir ≥) or x ≤ h (dir ≤): y ≥ k
##   exp    base^x + q                  all x, y > q (base 2, 3 or e)
##
## generate() returns by mode (need.mode); every mode has `f`:
##   lin, rat, root, rquad, exp   the family asked for
##   any      a rat, root, rquad or exp rule (domain, range and asymptotes of the inverse)
##   solve    lin, rat or root, a whole number c0 with x = f(c0) whole: f⁻¹(x) = c0
##   ident    any family and a whole number n for (f∘f⁻¹)(n)
##   funcinv  lin, rat or exp: f⁻¹ is given and f asked
##   asym     rat or exp: the asymptotes of f⁻¹ from those of f
##   selfinv  rat with d = −a (its own inverse), `slot` ("a" or "d") hidden as k
##   refl     rat with d = a, so f⁻¹(x) = −f(−x)
##   pair     lin f and a candidate g: the inverse, or off by a sign, or undone in the
##            wrong order (kind)
##   restrict a quadratic a(x − h)² + k with a = ±1 or ±2, in the direction dir
##
## The clean limits are the checker's too (tools/check_answers.py, IR_*).

const TRIES := 2000
const LIN_A := [2, 3, 4, 5, -2, -3, -1]
const BASES := [2, 3, "e"]


static func pick(rng: Seeded, xs: Array) -> Variant:
	return xs[rng.int_in(0, xs.size() - 1)]


static func nonzero(rng: Seeded, lo: int, hi: int) -> int:
	var v := 0
	while v == 0:
		v = rng.int_in(lo, hi)
	return v


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var mode: String = need.get("mode", "lin")
	for i in TRIES:
		var s := _draw(rng, mode)
		if not s.is_empty():
			s.mode = mode
			return s
	push_error("InverseRuleSituation: no clean situation for %s" % need)
	return {}


static func lin(rng: Seeded) -> Dictionary:
	var a: int = pick(rng, LIN_A)
	var b := rng.int_in(-6, 6)
	# −x is its own inverse, a poor first question.
	if a == -1 and b == 0:
		b = nonzero(rng, -6, 6)
	return {"fam": "lin", "a": a, "b": b}


static func rat(rng: Seeded) -> Dictionary:
	while true:
		var c: int = pick(rng, [1, 1, -1, 2])
		var a: int = c * rng.int_in(-3, 3)
		var d: int = c * rng.int_in(-3, 3)
		var b := rng.int_in(-6, 6)
		if a * d - b * c != 0 and not (a == 0 and b == 0):
			return {"fam": "rat", "a": a, "b": b, "c": c, "d": d}
	return {}


static func root(rng: Seeded) -> Dictionary:
	var p: int = pick(rng, [1, 1, 2, 3, 4])
	var x0 := rng.int_in(-4, 4)
	return {"fam": "root", "p": p, "q": -p * x0, "r": rng.int_in(-4, 4)}


static func rquad(rng: Seeded) -> Dictionary:
	return {"fam": "rquad", "h": nonzero(rng, -4, 4), "k": rng.int_in(-5, 5), "dir": "≥" if rng.chance(0.65) else "≤"}


static func exp_rule(rng: Seeded) -> Dictionary:
	return {"fam": "exp", "base": pick(rng, BASES), "q": rng.int_in(-4, 4)}


static func _draw(rng: Seeded, mode: String) -> Dictionary:
	var s := {}
	match mode:
		"lin":
			s.f = lin(rng)
		"rat":
			s.f = rat(rng)
		"root":
			s.f = root(rng)
		"rquad":
			s.f = rquad(rng)
		"exp":
			s.f = exp_rule(rng)
		"any":
			s.f = _family(rng, ["rat", "root", "rquad", "exp"])
		"solve":
			s.f = _family(rng, ["lin", "lin", "rat", "root"])
			s.c0 = rng.int_in(-5, 6)
			var y = value(s.f, Q.new(s.c0))
			if y == null or not y.is_int() or y.abs_q().lt(41) == false:
				return {}
		"ident":
			s.f = _family(rng, ["lin", "rat", "root", "exp"])
			s.n = nonzero(rng, -9, 9)
			# n must be in the range of f, so in the domain of f⁻¹.
			if s.f.fam == "root":
				s.n = s.f.r + rng.int_in(1, 9)
			elif s.f.fam == "exp":
				s.n = s.f.q + rng.int_in(1, 9)
			elif s.f.fam == "rat" and s.n * s.f.c == s.f.a:
				return {}
		"funcinv":
			s.f = _family(rng, ["lin", "rat", "exp"])
		"asym":
			s.f = _family(rng, ["rat", "exp"])
		"selfinv":
			var c: int = pick(rng, [1, 1, -1, 2])
			var a: int = c * nonzero(rng, -3, 3)
			var b := rng.int_in(-6, 6)
			if -a * a - b * c == 0 or b == 0:
				return {}
			s.f = {"fam": "rat", "a": a, "b": b, "c": c, "d": -a}
			s.slot = "d" if rng.chance(0.5) else "a"
		"refl":
			var c: int = pick(rng, [1, 1, -1, 2])
			var a: int = c * nonzero(rng, -3, 3)
			var b := nonzero(rng, -6, 6)
			if a * a - b * c == 0:
				return {}
			s.f = {"fam": "rat", "a": a, "b": b, "c": c, "d": a}
		"pair":
			s.f = lin(rng)
			if s.f.a == -1 and rng.chance(0.5):
				return {}
			s.kind = pick(rng, ["inverse", "inverse", "sign", "order"])
			if s.f.b == 0 and s.kind != "inverse":
				return {}
		"restrict":
			var a: int = pick(rng, [1, 1, -1, 2, -2])
			s.f = {"fam": "quad", "a": a, "h": nonzero(rng, -5, 5), "k": rng.int_in(-6, 6), "dir": "≥" if rng.chance(0.6) else "≤"}
			var co := quad_co(s.f)
			if co[2].is_zero() or absi(co[1].n) > 24 or absi(co[0].n) > 40 or s.f.h == 0:
				return {}
	return {} if s.f.is_empty() else s


static func _family(rng: Seeded, fams: Array) -> Dictionary:
	match pick(rng, fams):
		"lin":
			return lin(rng)
		"rat":
			return rat(rng)
		"root":
			return root(rng)
		"rquad":
			return rquad(rng)
		_:
			return exp_rule(rng)


## a x² + b x + c of a restrict rule, as [c, b, a] (low power first).
static func quad_co(f: Dictionary) -> Array:
	var a := Q.new(f.a)
	var h := Q.new(f.h)
	return [a.mul(h.mul(h)).add(f.k), a.mul(h).mul(-2), a]


## f(x) as a Q, or null where it isn't a rational number (a root of a non-square) or
## outside the domain.
static func value(f: Dictionary, x: Q) -> Variant:
	match f.fam:
		"lin":
			return Q.new(f.a).mul(x).add(f.b)
		"rat":
			var den := Q.new(f.c).mul(x).add(f.d)
			if den.is_zero():
				return null
			return Q.new(f.a).mul(x).add(f.b).div(den)
		"root":
			var inside := Q.new(f.p).mul(x).add(f.q)
			if inside.sign() < 0:
				return null
			var r := roundi(sqrt(inside.to_float()))
			if r * r != inside.n or inside.d != 1:
				return null
			return Q.new(r + f.r)
		"rquad":
			var dx := x.sub(f.h)
			if (f.dir == "≥" and dx.sign() < 0) or (f.dir == "≤" and dx.sign() > 0):
				return null
			return dx.mul(dx).add(f.k)
	return null


# ── Writing a rule ───────────────────────────────────────────

const SUBS := "₀₁₂₃₄₅₆₇₈₉"


static func base_text(b: Variant) -> String:
	return "e" if str(b) == "e" else str(b)


static func log_name(b: Variant) -> String:
	if str(b) == "e":
		return "ln"
	var out := "log"
	for ch in str(b):
		out += SUBS[int(ch)]
	return out


static func rule_text(f: Dictionary) -> String:
	match f.fam:
		"lin":
			return Fmt.poly([f.a, f.b])
		"rat":
			return frac(Fmt.poly([f.a, f.b]), Fmt.poly([f.c, f.d]))
		"root":
			var inside := Fmt.poly([f.p, f.q])
			return "%s%s" % ["√x" if inside == "x" else "√(%s)" % inside, "" if f.r == 0 else Fmt.plus(f.r)]
		"rquad":
			return "%s²%s" % [Fmt.factor(f.h), "" if f.k == 0 else Fmt.plus(f.k)]
		"exp":
			return "%s^x%s" % [base_text(f.base), "" if f.q == 0 else Fmt.plus(f.q)]
		"quad":
			return Fmt.poly([f.a, quad_co(f)[1], quad_co(f)[0]])
	return "?"


## top/bottom, with the top bracketed unless it is a plain number.
static func frac(top: String, bottom: String) -> String:
	return "%s/(%s)" % [top if not top.contains("x") else "(%s)" % top, bottom]


## f(x) = … with the domain a restricted rule needs.
static func rule_line(f: Dictionary, name: String = "f") -> String:
	var out := "%s(x) = %s" % [name, rule_text(f)]
	if f.fam == "rquad":
		out += ", for x %s %s" % [f.dir, Fmt.num(f.h)]
	return out


## The steps of a rule in words, innermost first: ["multiply by 3", "subtract 4"].
static func rule_steps(f: Dictionary) -> Array:
	var out: Array = []
	match f.fam:
		"lin":
			var a := int(f.a)
			if a == -1:
				out.append("negate")
			elif a == 2:
				out.append("double")
			elif a == 3:
				out.append("treble")
			else:
				out.append("multiply by %s" % Fmt.num(a))
			if f.b != 0:
				out.append(("add %d" if f.b > 0 else "subtract %d") % absi(f.b))
		"root":
			if f.p != 1:
				out.append("multiply by %d" % f.p)
			if f.q != 0:
				out.append(("add %d" if f.q > 0 else "subtract %d") % absi(f.q))
			out.append("take the square root")
			if f.r != 0:
				out.append(("add %d" if f.r > 0 else "subtract %d") % absi(f.r))
		"exp":
			out.append("raise %s to that power" % base_text(f.base))
			if f.q != 0:
				out.append(("add %d" if f.q > 0 else "subtract %d") % absi(f.q))
	return out


# ── Inverses ─────────────────────────────────────────────────

## The inverse as the game writes it, after "f⁻¹(x) = ".
static func inverse_text(f: Dictionary) -> String:
	match f.fam:
		"lin":
			var a := int(f.a)
			var b := int(f.b)
			if a == -1 or a == 1:
				return Fmt.poly([a, -b * a])
			var sgn := 1 if a > 0 else -1
			var top := Fmt.poly([sgn, -b * sgn])
			if top == "x":
				return "x/%d" % absi(a)
			return "(%s)/%d" % [top, absi(a)]
		"rat":
			return frac(Fmt.poly([f.d, -f.b]), Fmt.poly([-f.c, f.a]))
		"root":
			var sq := "x²" if f.r == 0 else Fmt.factor(f.r) + "²"
			if f.q == 0:
				return sq if f.p == 1 else "%s/%d" % [sq, f.p]
			var top: String = sq + Fmt.plus(-f.q)
			return top if f.p == 1 else "(%s)/%d" % [top, f.p]
		"rquad":
			var root_part := "√x" if f.k == 0 else "√(x%s)" % Fmt.plus(-f.k)
			var sign := "+" if f.dir == "≥" else "−"
			if f.h == 0:
				return root_part if sign == "+" else "−" + root_part
			return "%s %s %s" % [Fmt.num(f.h), sign, root_part]
		"exp":
			var inside := "x" if f.q == 0 else "(x%s)" % Fmt.plus(-f.q)
			if f.q == 0:
				return "%s x" % log_name(f.base)
			return log_name(f.base) + inside
	return "?"


## The domain of f as a condition on x, and the range as one on y. "" where all reals.
static func domain_text(f: Dictionary) -> String:
	match f.fam:
		"rat":
			return "x ≠ %s" % Fmt.num(Q.new(-f.d, f.c))
		"root":
			return "x ≥ %s" % Fmt.num(Q.new(-f.q, f.p))
		"rquad":
			return "x %s %s" % [f.dir, Fmt.num(f.h)]
	return "all real x"


static func range_text(f: Dictionary) -> String:
	match f.fam:
		"rat":
			return "y ≠ %s" % Fmt.num(Q.new(f.a, f.c))
		"root":
			return "y ≥ %s" % Fmt.num(f.r)
		"rquad":
			return "y ≥ %s" % Fmt.num(f.k)
		"exp":
			return "y > %s" % Fmt.num(f.q)
	return "all real y"


## The domain of f⁻¹ is the range of f (as a condition on x), the range of f⁻¹ the
## domain of f (as a condition on y).
static func inv_domain_text(f: Dictionary) -> String:
	return range_text(f).replace("y", "x") if f.fam != "lin" else "all real x"


static func inv_range_text(f: Dictionary) -> String:
	match f.fam:
		"rat":
			return "y ≠ %s" % Fmt.num(Q.new(-f.d, f.c))
		"root":
			return "y ≥ %s" % Fmt.num(Q.new(-f.q, f.p))
		"rquad":
			return "y %s %s" % [f.dir, Fmt.num(f.h)]
	return "all real y"


## f⁻¹(v) as a Q, or null where it is not defined or not rational.
static func inverse_value(f: Dictionary, v: Q) -> Variant:
	match f.fam:
		"lin":
			return v.sub(f.b).div(Q.new(f.a))
		"rat":
			var den := Q.new(-f.c).mul(v).add(f.a)
			if den.is_zero():
				return null
			return Q.new(f.d).mul(v).sub(f.b).div(den)
		"root":
			var w := v.sub(f.r)
			if w.sign() < 0:
				return null
			return w.mul(w).sub(f.q).div(Q.new(f.p))
	return null


static func lin_rule(a: int, b: int) -> Dictionary:
	return {"fam": "lin", "a": a, "b": b}


## The inverse of a·x + b undone in the original order, x/a − b: the classic slip.
static func order_text(a: int, b: int) -> String:
	var head := "−x" if a == -1 else ("x/%d" % absi(a) if a > 0 else "−x/%d" % absi(a))
	return head + ("" if b == 0 else Fmt.plus(-b))


## A candidate g for f = a·x + b: its inverse, off by a sign, or undone in the wrong
## order. {"text", "g1", "g0"} is g written, and its gradient and constant.
static func pair_g(f: Dictionary, kind: String) -> Dictionary:
	var a := Q.new(f.a)
	var b := int(f.b)
	match kind:
		"sign":
			return {"text": inverse_text(lin_rule(f.a, -b)), "g1": Q.new(1).div(a), "g0": Q.new(b).div(a)}
		"order":
			return {"text": order_text(f.a, b), "g1": Q.new(1).div(a), "g0": Q.new(-b)}
	return {"text": inverse_text(f), "g1": Q.new(1).div(a), "g0": Q.new(-b).div(a)}


## f(g(x)) = a·g + b, written: "x", "x + 6".
static func pair_composite(f: Dictionary, g: Dictionary) -> String:
	var a := Q.new(f.a)
	return Fmt.poly([a.mul(g.g1), a.mul(g.g0).add(f.b)])


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
