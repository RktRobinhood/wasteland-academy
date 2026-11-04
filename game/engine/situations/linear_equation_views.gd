class_name LinearEquationViews
extends ExtensionViews
## The views on the `fn-pre-linear-equations` situation: one builder per unknown of
## fn-pre-linear-equations (FAL-424). Solutions and missing numbers are exact typed numbers, a
## rearranged line is the `line` kind. The fractions misconception is an error-spot, but it is
## also a wrong option, so the save logs it either way.

const T := "fn-pre-linear-equations#"
const R_BRACKET := T + "0"
const R_SIGN := T + "1"
const R_FRACTION := T + "2"
const R_DIVIDE := T + "3"


func needs() -> Dictionary:
	return {"two-step": {"form": "two"}, "both-sides": {"form": "both"}, "brackets": {"form": "brackets"},
		"fractions": {"form": "fractions"}, "make-y-subject": {"form": "y"}, "missing-number": {"form": "missing"}}


func extra() -> Dictionary:
	return {"fractions": ["error-spot"]}


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = LinearEquationSituation.export(s)
	return out


static func xans(v: Variant) -> Dictionary:
	return InverseRuleViews.number("x = ", v)


static func fin(ans: Dictionary) -> String:
	return "So %s." % Answer.text(ans)


static func cx(c: Variant) -> String:
	return Fmt.term(Q.of(c), 1, true)


## "Subtract 3x from both sides" / "Add 3x to both sides" (for c = −3).
static func take_x(c: int) -> String:
	return ("Subtract %s from both sides" if c > 0 else "Add %s to both sides") % cx(absi(c))


static func take_n(v: int) -> String:
	return LinearInequalityViews.take(Q.new(v), "both sides")


## The last step to x: dividing by the coefficient, or nothing when it is 1.
static func divide(coef: int, x: Q) -> Array:
	return [] if coef == 1 else ["Divide both sides by %s: x = %s." % [N(coef), N(x)]]


## "3x = 12, so x = 4", or "x = 4" when the coefficient is 1.
static func solved(coef: int, rhs: int, x: Q) -> String:
	return "x = %s" % N(x) if coef == 1 else "%s = %s, so x = %s" % [cx(coef), N(rhs), N(x)]


## a × x + b, as a check shows it.
static func at(a: int, b: int, x: Q) -> String:
	return "%s × %s%s" % [N(a), P(x), Fmt.plus(b)]


# ── ax + b = c ───────────────────────────────────────────────

## "3 more than twice a number is 11." / "4 less than 5 times a number is 11."
static func words(s: Dictionary) -> String:
	var times: String = "twice" if s.a == 2 else "%d times" % s.a
	return "%d %s than %s a number is %s." % [absi(s.b), "more" if s.b > 0 else "less", times, N(s.c)]


func u_two_step(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := xans(s.x)
	var eq := "%s = %s" % [Fmt.poly([s.a, s.b]), N(s.c)]
	var out := {"asked": "Solve for x.", "lines": [eq], "answer": ans}
	if rep == "words":
		out.asked = "Call the number x. Find x."
		out.lines = [words(s)]
	var rest: int = s.c - s.b
	out.wrongs = [wrong({"v": Q.new(s.c + s.b, s.a)}, R_SIGN)]
	out.generic = [{"v": Q.new(rest)}, {"v": Q.new(s.c, s.a).sub(s.b)}, {"v": s.x.neg()}, {"v": Q.new(s.a * rest)}]
	var first: Array = ["Write it as an equation: %s." % eq] if rep == "words" else []
	var take: String = "%s: %s = %s." % [take_n(s.b), cx(s.a), N(rest)]
	var div: String = "Divide both sides by %s: x = %s." % [N(s.a), N(s.x)]
	out.methods = {
		"inverse-operations": method(first + [take, div, fin(ans)], ans.values),
		"substitute-check": method(first + ["Undo the operations: %s." % solved(s.a, rest, s.x), "Check: %s = %s, as it should." % [at(s.a, s.b, s.x), N(s.c)], fin(ans)], ans.values),
	}
	return out


# ── ax + b = cx + d ──────────────────────────────────────────

func u_both_sides(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := xans(s.x)
	var out := {"asked": "Solve for x.", "lines": ["%s = %s" % [Fmt.poly([s.a, s.b]), Fmt.poly([s.c, s.d])]], "answer": ans}
	var coef: int = s.a - s.c
	var rest: int = s.d - s.b
	# The x term carried across with its sign kept, or the number.
	out.wrongs = [wrong({"v": Q.new(s.d + s.b, coef)}, R_SIGN)]
	if s.a + s.c != 0:
		out.wrongs.append(wrong({"v": Q.new(rest, s.a + s.c)}, R_SIGN))
	out.generic = [{"v": s.x.neg()}, {"v": Q.new(rest)}, {"v": Q.new(s.d - s.b, s.c - s.a).add(1)}]
	var move := "%s: %s = %s." % [take_x(s.c), Fmt.poly([coef, s.b]), N(s.d)]
	var num := "%s: %s = %s." % [take_n(s.b), cx(coef), N(rest)]
	var right: Q = s.x.mul(s.c).add(s.d)
	out.methods = {
		"collect-terms": method([move, num] + divide(coef, s.x) + [fin(ans)], ans.values),
		"substitute-check": method(["Collect the x terms on the left and the numbers on the right: %s." % solved(coef, rest, s.x),
			"Check: the left side is %s and the right side is %s, both %s." % [at(s.a, s.b, s.x), at(s.c, s.d, s.x), N(right)], fin(ans)], ans.values),
	}
	return out


# ── p(x + q) = r(x + s) ──────────────────────────────────────

func u_brackets(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := xans(s.x)
	var left := "%s(%s)" % [N(s.p), Fmt.poly([1, s.q])]
	var right := "%s(%s)" % [N(s.r), Fmt.poly([1, s.t])]
	var out := {"asked": "Solve for x.", "lines": ["%s = %s" % [left, right]], "answer": ans}
	var pq: int = s.p * s.q
	var rt: int = s.r * s.t
	var coef: int = s.p - s.r
	var rest: int = rt - pq
	# The second term of a bracket left unmultiplied: on both sides, or on the left only.
	out.wrongs = [wrong({"v": Q.new(s.t - s.q, coef)}, R_BRACKET), wrong({"v": Q.new(rt - s.q, coef)}, R_BRACKET)]
	out.generic = [{"v": s.x.neg()}, {"v": Q.new(rest)}, {"v": Q.new(rt + pq, coef)}]
	var expanded := "%s = %s" % [Fmt.poly([s.p, pq]), Fmt.poly([s.r, rt])]
	var same: Q = s.x.add(s.q).mul(s.p)
	out.methods = {
		"collect-terms": method(["Multiply out: %s." % expanded, "Collect the x terms on one side and the numbers on the other: %s = %s." % [cx(coef), N(rest)]] + divide(coef, s.x) + [fin(ans)], ans.values),
		"expand-first": method(["Multiply out both brackets: %s." % expanded, "%s: %s = %s." % [take_x(s.r), Fmt.poly([coef, pq]), N(rt)], "%s: %s = %s." % [take_n(pq), cx(coef), N(rest)]] + divide(coef, s.x) + [fin(ans)], ans.values),
		"substitute-check": method(["Multiply out and collect: %s." % solved(coef, rest, s.x),
			"Check: %s(%s%s) and %s(%s%s) are both %s." % [N(s.p), N(s.x), Fmt.plus(s.q), N(s.r), N(s.x), Fmt.plus(s.t), N(same)], fin(ans)], ans.values),
	}
	return out


# ── Fractions ────────────────────────────────────────────────

func u_fractions(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := xans(s.x)
	var u: int = s.L / s.p
	var w: int = s.L / s.q
	var out := {"asked": "Solve for x.", "answer": ans}
	var lcm := "The lowest common multiple of %d and %d is %d" % [s.p, s.q, s.L]
	var eq: String
	var bad: String
	var slip: Q
	var steps: Array
	var check: String
	var collected: String
	if s.shape == "sum":
		eq = "x/%d + x/%d = %s" % [s.p, s.q, N(s.r)]
		var coef: int = u + w
		var rhs: int = s.L * s.r
		slip = Q.new(s.r, coef)
		bad = "%s + %s = %s" % [cx(u), cx(w), N(s.r)]
		collected = "%s = %s" % [cx(coef), N(s.r)]
		out.generic = [{"v": Q.new(s.r * (s.p + s.q))}, {"v": Q.new(s.r * s.L)}, {"v": s.x.neg()}]
		steps = ["%s, so multiply every term by %d: %s + %s = %s." % [lcm, s.L, cx(u), cx(w), N(rhs)], "Collect: %s = %s." % [cx(coef), N(rhs)]] + divide(coef, s.x)
		check = "Check: %s/%d + %s/%d = %s, as it should." % [P(s.x), s.p, P(s.x), s.q, N(s.r)]
	else:
		eq = "(%s)/%d = (%s)/%d" % [Fmt.poly([1, s.a]), s.p, Fmt.poly([1, -s.b]), s.q]
		var lhs := "%s + %d" % [cx(u), u * s.a]
		var rhs := "%s − %d" % [cx(w), w * s.b]
		var coef: int = u - w
		var rest: int = -w * s.b - u * s.a
		slip = Q.new(-s.b - s.a, coef)
		bad = "%s + %d = %s − %d" % [cx(u), s.a, cx(w), s.b]
		collected = "%s = %s" % [cx(coef), N(-s.b - s.a)]
		out.generic = [{"v": Q.new(s.b + s.a, coef)}, {"v": s.x.neg()}, {"v": Q.new(s.a * s.q + s.b * s.p, s.q - s.p).add(1)}]
		var cleared := "%s = %s" % [_times(u, Fmt.poly([1, s.a])), _times(w, Fmt.poly([1, -s.b]))]
		steps = ["%s, so multiply both sides by %d: %s." % [lcm, s.L, cleared], "Multiply out: %s = %s." % [lhs, rhs], "Collect: %s = %s." % [cx(coef), N(rest)]] + divide(coef, s.x)
		check = "Check: (%s%s)/%d and (%s%s)/%d are both %s." % [N(s.x), Fmt.plus(s.a), s.p, N(s.x), Fmt.plus(-s.b), s.q, N(s.x.add(s.a).div(s.p))]
	out.lines = [eq]
	out.wrongs = [wrong({"v": slip}, R_FRACTION)]
	out.methods = {
		"clear-fractions": method(steps + [fin(ans)], ans.values),
		"substitute-check": method(["Clear the fractions and solve: x = %s." % N(s.x), check, fin(ans)], ans.values),
	}
	var end := "x = %s" % N(slip)
	if rng.chance(0.5):
		out.spot = {"lines": [bad, collected, end, "So " + end], "bad": 0, "ref": R_FRACTION, "why": _why(s)}
	else:
		out.spot = {"lines": [eq, bad, collected, "So " + end], "bad": 1, "ref": R_FRACTION, "why": _why(s)}
	return out


static func _why(s: Dictionary) -> String:
	if s.shape == "sum":
		return "every term is multiplied, so the %s must be multiplied by %d too" % [N(s.r), s.L]
	return "each number in a bracket is multiplied too, not only the x terms"


## "3(x + 2)", or the bracket's insides when the multiplier is 1.
static func _times(k: int, inside: String) -> String:
	return inside if k == 1 else "%d(%s)" % [k, inside]


# ── ax + by = k ──────────────────────────────────────────────

func u_make_y_subject(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Q = s.m
	var ans := Answer.make("line", {"m": m, "c": Q.new(s.c)})
	ans.exact = true
	var out := {"asked": "Make y the subject: write the line in the form y = mx + c.", "lines": [LineCrossingViews.gk(s.a, s.b, s.k)], "answer": ans}
	out.wrongs = [wrong({"m": m, "c": Q.new(s.k)}, R_DIVIDE)]
	out.generic = [{"m": m.neg(), "c": Q.new(s.c)}, {"m": Q.new(s.a, s.b), "c": Q.new(-s.c)}, {"m": m, "c": Q.new(-s.c)}, {"m": m.neg(), "c": Q.new(s.k)}]
	var move := "%s: %s = %s." % [take_x(s.a), Fmt.term(Q.new(s.b), 1, true, "y"), Fmt.poly([-s.a, s.k])]
	var div := "Divide every term by %s: %s." % [N(s.b), Answer.text(ans)]
	out.methods = {"inverse-operations": method([move, div, fin(ans)], ans.values)}
	return out


# ── A missing number ─────────────────────────────────────────

const BOX := "□"


func u_missing_number(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans: Dictionary = InverseRuleViews.number(BOX + " = ", {"a": s.a, "b": s.b, "c": s.c}[s.blank])
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var x: int = s.x.n
	var out := {"asked": "Find the missing number.", "answer": ans}
	var ax := a * x
	var eq: String
	var steps: Array
	var wrongs: Array
	match s.blank:
		"a":
			eq = "%sx%s = %s" % [BOX, Fmt.plus(b), N(c)]
			steps = ["Put x = %s in: %s × %s%s = %s." % [N(x), BOX, P(x), Fmt.plus(b), N(c)], "%s: %s × %s = %s." % [take_n(b), BOX, P(x), N(c - b)], "Divide both sides by %s: %s = %s." % [P(x), BOX, N(a)]]
			wrongs = [Q.new(c + b, x), Q.new(c - b), Q.new(c, x), Q.new(-a)]
		"b":
			eq = "%s + %s = %s" % [cx(a), BOX, N(c)]
			steps = ["Put x = %s in: %s + %s = %s." % [N(x), N(ax), BOX, N(c)], "%s: %s = %s." % [take_n(ax), BOX, N(b)]]
			wrongs = [Q.new(c + ax), Q.new(-b), Q.new(c - x), Q.new(c - a)]
		_:
			eq = "%s = %s" % [Fmt.poly([a, b]), BOX]
			steps = ["Put x = %s in: %s × %s%s = %s." % [N(x), N(a), P(x), Fmt.plus(b), BOX], "Work out the left side: %s%s = %s." % [N(ax), Fmt.plus(b), N(c)]]
			wrongs = [Q.new(ax - b), Q.new(a + x + b), Q.new(ax), Q.new(-c)]
	out.lines = [eq, "The solution is x = %s." % N(x)]
	out.generic = wrongs.map(func(v): return {"v": v})
	out.methods = {"inverse-operations": method(steps + [fin(ans)], ans.values)}
	return out
