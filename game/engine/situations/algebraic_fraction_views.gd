class_name AlgebraicFractionViews
extends ExtensionViews
## The views on the `fn-pre-algebraic-fractions` situation: one builder per unknown of
## fn-pre-algebraic-fractions (FAL-423). Students can't type an expression, so what is
## simplified, added or filled in is picked from four written options (the `choice` kind),
## and the checker works each one out with SymPy; an equation's solution is a number. The
## catalogue gives these misconceptions no ref, so they are logged as
## "fn-pre-algebraic-fractions#<index>".

const T := "fn-pre-algebraic-fractions"
const R_CANCEL_TERMS := T + "#0"
const R_ADD_TOPS_BOTTOMS := T + "#1"
const R_PARTIAL_MULTIPLY := T + "#2"
const R_ZERO_DIVISION := T + "#3"
const ZERO_WORDS := "no value: dividing by 0 gives 0"


func needs() -> Dictionary:
	return {
		"excluded-value": {"mode": "excluded"},
		"simplify-by-cancelling": {"mode": "simplify"},
		"add-fractions": {"mode": "add"},
		"clear-and-solve": {"mode": "clear"},
		"missing-numerator": {"mode": "missing"},
	}


func extra() -> Dictionary:
	return {"clear-and-solve": ["error-spot"]}


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = AlgebraicFractionSituation.export(s)
	return out


static func pick(right: String, bad: Array, plain: Array) -> Dictionary:
	return InverseRuleViews.choose(right, bad, plain)


static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


static func N(v: Variant) -> String:
	return Fmt.num(v)


## (x + a)(x + b) written from the two numbers.
static func product(a: int, b: int) -> String:
	return "(%s)(%s)" % [Fmt.poly([1, a]), Fmt.poly([1, b])]


# ── excluded-value ───────────────────────────────────────────

func u_excluded_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: Q = s.h
	var top := Fmt.poly([s.p, s.q])
	var bottom := AlgebraicFractionSituation.lin(s.c, s.d)
	var frac := AlgebraicFractionSituation.over(top, bottom)
	var right := "x ≠ %s, because the bottom would be 0" % N(h)
	var out := {"asked": "Which value of x can the fraction not take, and why?"}
	out.lines = [frac] if rep == "equation" else ["A fraction has %s on the top and %s on the bottom." % [top, bottom]]
	out.merge(pick(right, [tag(ZERO_WORDS, R_ZERO_DIVISION)], ["x ≠ %s, because the top would be 0" % N(Q.new(-s.q, s.p)), "x ≠ %s, because the bottom would be 0" % N(h.neg()),
		"x ≠ 0, because the bottom would be 0"]))
	var fin := "So %s." % right
	out.methods = {"number-check": method(["Put x = %s into the bottom: %s = %s." % [N(h), bottom.replace("x", Fmt.paren(h)), "0"], "A fraction with 0 on the bottom is undefined, so x can't be %s." % N(h), fin], {"v": right})}
	return out


# ── simplify-by-cancelling ───────────────────────────────────

func u_simplify_by_cancelling(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := {"asked": "Write the fraction in its simplest form. Say which value of x is excluded."}
	var right: String
	var bad: Array = []
	var plain: Array = []
	var frac: String
	var steps: Array
	var ex: int
	match s.kind:
		"factor":
			var num := Fmt.poly([1, s.p + s.q, s.p * s.q])
			frac = AlgebraicFractionSituation.over(num, Fmt.poly([1, s.p]))
			right = "%s (x ≠ %s)" % [Fmt.poly([1, s.q]), N(-s.p)]
			plain = ["%s (x ≠ %s)" % [Fmt.poly([1, s.p]), N(-s.q)], "%s (x ≠ %s)" % [Fmt.poly([1, s.q]), N(s.p)], "%s (x ≠ %s)" % [Fmt.poly([1, s.p + s.q]), N(-s.p)], "x%s (x ≠ %s)" % [Fmt.plus(s.p * s.q), N(-s.p)]]
			steps = ["Factorise the top: %s = %s." % [num, product(s.p, s.q)], "Cancel the common factor %s: what is left is %s." % [Fmt.poly([1, s.p]), Fmt.poly([1, s.q])], "The bottom is 0 when x = %s, so x ≠ %s. " % [N(-s.p), N(-s.p)] + "So %s." % right]
			ex = -s.p
		"scale":
			frac = AlgebraicFractionSituation.over(Fmt.poly([s.m, s.m * s.a]), Fmt.poly([1, s.a]))
			right = "%d (x ≠ %s)" % [s.m, N(-s.a)]
			plain = ["%s (x ≠ %s)" % [Fmt.poly([s.m, s.a]), N(-s.a)], "%d (x ≠ %s)" % [s.m, N(s.a)], "%s (x ≠ %s)" % [Fmt.poly([1, s.m * s.a]), N(-s.a)], "%d (x ≠ %s)" % [s.m * s.a, N(-s.a)]]
			steps = ["Take out the common factor on the top: %s = %d(%s)." % [Fmt.poly([s.m, s.m * s.a]), s.m, Fmt.poly([1, s.a])], "Cancel %s: what is left is %d." % [Fmt.poly([1, s.a]), s.m], "The bottom is 0 when x = %s, so x ≠ %s. " % [N(-s.a), N(-s.a)] + "So %s." % right]
			ex = -s.a
		_:
			frac = AlgebraicFractionSituation.over(Fmt.poly([1, s.a]), Fmt.poly([1, s.b]))
			right = "it cannot be simplified"
			bad = [tag(N(Q.new(s.a, s.b)), R_CANCEL_TERMS)]
			plain = ["x (x ≠ %s)" % N(-s.b), "%s (x ≠ %s)" % [Fmt.poly([1, s.a - s.b]), N(-s.b)], "%s" % N(Q.new(s.b, s.a))]
			steps = ["The top %s and the bottom %s have no common factor: they are different brackets." % [Fmt.poly([1, s.a]), Fmt.poly([1, s.b])],
				"Cancelling the x's would be cancelling terms, which is not allowed (it would give %s)." % N(Q.new(s.a, s.b)), "So the fraction %s." % right]
			ex = -s.b
	out.lines = [frac]
	out.merge(pick(right, bad, plain))
	var x2 := 2 if ex != 2 else 3
	var top_t: String = frac.split("/")[0].trim_prefix("(").trim_suffix(")")
	var bot_t: String = frac.split("/")[1].trim_prefix("(").trim_suffix(")")
	var fin := "So %s." % right
	out.methods = {
		"number-check": method(["Try x = %d in the fraction: (%s)/(%s)." % [x2, top_t.replace("x", Fmt.paren(x2)), bot_t.replace("x", Fmt.paren(x2))], "Check which simplified form gives the same value at x = %d." % x2, fin], {"v": right}),
	}
	if s.kind != "none":
		out.methods["cancel-factors"] = method(steps, {"v": right})
	else:
		out.methods["cancel-factors"] = method(steps, {"v": right})
	return out


# ── add-fractions ────────────────────────────────────────────

func u_add_fractions(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var a: int = s.a
	var b: int = s.b
	var bot := "(%s)" % product(a, b)
	var right := "%s/%s" % [_wrap(Fmt.poly([p + q, p * b + q * a])), bot]
	var wrong_sum := "%s/%s" % [N(p + q), _wrap(Fmt.poly([2, a + b]))]
	var left := "%s/(%s) + %s/(%s)" % [N(p), Fmt.poly([1, a]), N(q), Fmt.poly([1, b])]
	var out := {"asked": "Write as a single fraction.", "lines": [left]}
	out.merge(pick(right, [tag(wrong_sum, R_ADD_TOPS_BOTTOMS)], ["%s/%s" % [_wrap(Fmt.poly([p + q, p * a + q * b])), bot], "%s/%s" % [_wrap(Fmt.poly([p * q, p * b + q * a])), bot],
		"%s/(%s)" % [_wrap(Fmt.poly([p + q, p * b - q * a])), Fmt.poly([1, a + b])] if a + b != 0 else "%s/%s" % [_wrap(Fmt.poly([p + q, p * b - q * a])), bot],
		"%s/%s" % [_wrap(Fmt.poly([p + q, p * b + q * a + 1])), bot], "%s/%s" % [_wrap(Fmt.poly([p + q + 1, p * b + q * a])), bot]]))
	var x2 := 1 if (a != -1 and b != -1) else 2
	if x2 == -a or x2 == -b:
		x2 += 1
	var val := Q.new(p, x2 + a).add(Q.new(q, x2 + b))
	var fin := "So %s." % right
	out.methods = {
		"common-denominator": method(["The common denominator is %s." % product(a, b), "%s(%s) + %s(%s) = %s" % [N(p), Fmt.poly([1, b]), N(q), Fmt.poly([1, a]), Fmt.poly([p + q, p * b + q * a])], fin], {"v": right}),
		"number-check": method(["Try x = %d: %s." % [x2, "%s + %s = %s" % [N(Q.new(p, x2 + a)), N(Q.new(q, x2 + b)), N(val)]],
			"%s gives %s at x = %d, so it is the same." % [right, N(val), x2], fin], {"v": right}),
	}
	return out


static func _wrap(t: String) -> String:
	return t if not " " in t else "(%s)" % t


# ── clear-and-solve ──────────────────────────────────────────

func u_clear_and_solve(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var k: int = s.k
	var h: int = s.h
	var c: int = s.c
	var bracket := Fmt.poly([1, -h])
	var ans := Answer.make("xval", {"v": Q.new(s.x)})
	ans.exact = true
	var wrong_x := Q.new(h).add(Q.new(k + a, c))
	var eq := "%s%s/(%s) = %s" % [N(a), Fmt.plus(k), bracket, N(c)]
	var fin := "So " + Answer.text(ans) + "."
	var slip_rhs := "%s(%s)" % [N(c), bracket]
	var spot := {
		"lines": ["%s %s %s = %s" % [N(a), "+" if k > 0 else "−", N(absi(k)), slip_rhs], "%s = %s" % [N(a + k), Fmt.poly([c, -c * h])],
			"%s = %sx" % [N(a + k + c * h), Fmt.lead(c)], "x = %s" % N(wrong_x)],
		"bad": 0, "ref": R_PARTIAL_MULTIPLY,
		"why": "every term has to be multiplied by %s: %s(%s) + %s = %s" % [bracket, N(a), bracket, N(k), slip_rhs]}
	var left := "%s(%s)%s" % [N(a), bracket, Fmt.plus(k)]
	var out := {
		"asked": "Solve the equation.", "lines": [eq], "answer": ans, "spot": spot,
		"wrongs": [{"values": {"v": wrong_x}, "ref": R_PARTIAL_MULTIPLY}],
		"generic": [{"v": Q.new(s.x).neg()}, {"v": Q.new(h)}, {"v": Q.new(s.x + 1)}],
		"methods": {
			"multiply-through": method(["Multiply every term by (%s): %s = %s." % [bracket, left, slip_rhs], "Expand and collect: %s = %s." % [Fmt.poly([a, -a * h + k]), Fmt.poly([c, -c * h])], "So %s." % ("x = " + N(s.x)), fin], ans.values),
			"isolate-fraction": method(["Take %s from both sides: %s/(%s) = %s." % [N(a), N(k), bracket, N(c - a)], "So %s = %s/%s, which is %s." % [bracket, N(k), Fmt.paren(c - a), N(s.t)], "x = %s%s = %s." % [N(h), Fmt.plus(s.t), N(s.x)], fin], ans.values),
		},
	}
	return out


# ── missing-numerator ────────────────────────────────────────

func u_missing_numerator(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var k: int = s.k
	var h: int = s.h
	var bracket := Fmt.poly([1, -h])
	var right := Fmt.poly([a, k - a * h])
	var left := "%s%s/(%s)" % [N(a), Fmt.plus(k), bracket]
	var out := {"asked": "Fill in the numerator: %s = (□)/(%s)." % [left, bracket], "lines": [left]}
	out.merge(pick(right, [], [N(a + k), Fmt.poly([a, k]), Fmt.poly([a, k + a * h]), Fmt.poly([a, k - h]), Fmt.poly([1, k - a * h])]))
	var x2 := h + 1
	var val := Q.new(a).add(Q.new(k, x2 - h))
	var fin := "So the numerator is %s." % right
	out.methods = {
		"common-denominator": method(["Write %s over the bottom: %s = %s(%s)/(%s)." % [N(a), N(a), N(a), bracket, bracket], "%s(%s) + %s = %s." % [N(a), bracket, N(k), right], fin], {"v": right}),
		"number-check": method(["Try x = %d: the left side is %s." % [x2, N(val)], "The numerator %s gives %s/%s = %s at x = %d, the same." % [right, N(Q.of(a).mul(Q.new(x2)).add(Q.new(k - a * h))), N(x2 - h), N(val), x2], fin], {"v": right}),
	}
	return out
