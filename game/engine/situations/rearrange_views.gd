class_name RearrangeViews
extends ExtensionViews
## The views on the `fn-pre-rearrange` situation: one builder per unknown of
## fn-pre-rearrange (FAL-422). Students can't type a formula, so the rearrangement (or the
## formula it came from) is picked from four written options; the checker solves each
## option's equation with SymPy and shows the right one is the rearrangement and every
## wrong one is not. The catalogue gives these misconceptions no ref, so they are logged
## as "fn-pre-rearrange#<index>".

const T := "fn-pre-rearrange"
const R_ORDER := T + "#0"
const R_TERM_BY_TERM := T + "#1"
const R_ONE_SIDE := T + "#2"
const R_BOTH_SIDES := T + "#3"
const R_NO_PM := T + "#4"


## Methods that don't change the subject, for a method-pick question's wrong options.
const WRONG_METHODS := [
	{"name": "Multiply both sides by x", "why": "x is still in the formula, so nothing has been made the subject"},
	{"name": "Add the same number to both sides", "why": "that alone doesn't get x on its own"},
	{"name": "Divide first, then add", "why": "the steps have to be undone in the reverse order they were done"},
]


func needs() -> Dictionary:
	return {
		"one-step": {"mode": "one"},
		"two-step": {"mode": "two"},
		"power-or-root": {"mode": "power"},
		"subject-in-denominator": {"mode": "denom"},
		"subject-twice": {"mode": "twice"},
		"subject-twice-linear": {"mode": "twicelin"},
		"which-original": {"mode": "original"},
	}


func extra() -> Dictionary:
	return {"subject-twice": ["error-spot", "method-pick"], "subject-in-denominator": ["method-pick"], "two-step": ["method-pick"]}


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = RearrangeSituation.export(s)
	return out


# ── Helpers ──────────────────────────────────────────────────

static func pick(right: String, bad: Array, plain: Array) -> Dictionary:
	return InverseRuleViews.choose(right, bad, plain)


static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


static func y_poly(co: Array) -> String:
	return Fmt.poly(co)


# ── one-step ─────────────────────────────────────────────────

func u_one_step(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Array = RearrangeSituation.FORMULAS[s.i]
	var right: String = f[2]
	var subject: String = f[1]
	var plain := _one_step_wrongs(s.i)
	var out := {"asked": "Make %s the subject of the formula." % subject, "lines": [f[0]] if rep == "equation" else [f[3]]}
	out.merge(pick(right, [], plain))
	var steps := ["In %s, %s is %s" % [f[0], subject, "added to something" if "+" in f[0] else "multiplied by something"],
		"Undo that on both sides: %s" % ("subtract" if "+" in f[0] else "divide"), "So %s." % right]
	out.methods = {"inverse-operations": method(steps, {"v": right})}
	return out


static func _one_step_wrongs(i: int) -> Array:
	match i:
		0:
			return ["u = v + at", "u = v − a + t", "u = (v − a)t", "u = vat"]
		1:
			return ["s = dt", "s = t/d", "s = d − t", "s = d/t²"]
		2:
			return ["m = Fa", "m = a/F", "m = F − a", "m = F/a²"]
		3:
			return ["l = Aw", "l = w/A", "l = A − w", "l = A/w²"]
		4:
			return ["x = y + 5", "x = 5 − y", "x = 5y", "x = y/5"]
	return ["d = Cπ", "d = π/C", "d = C − π", "d = C/π²"]


# ── two-step ─────────────────────────────────────────────────

func u_two_step(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var right := RearrangeSituation.solved_text("two", s)
	var order := "x = %s" % ("y/%s%s" % [Fmt.num(a), Fmt.plus(-b)] if a > 0 else "−y/%s%s" % [Fmt.num(-a), Fmt.plus(-b)])
	var wrongs := [tag(order, R_ORDER)]
	var plain := ["x = %s" % RearrangeSituation._over(Fmt.poly([1, b]).replace("x", "y"), a), "x = %s" % RearrangeSituation._over(Fmt.poly([1, -b]).replace("x", "y"), -a),
		"x = %s(y%s)" % [Fmt.lead(a), Fmt.plus(-b)], "x = y%s" % Fmt.plus(-b)]
	var out := {"asked": "Make x the subject of the formula."}
	if rep == "words":
		var word := "doubled" if a == 2 else ("trebled" if a == 3 else "multiplied by %s" % N(a))
		out.lines = ["x is %s, and then %s is %s, to give y." % [word, str(absi(b)), "added" if b > 0 else "subtracted"]]
	else:
		out.lines = ["y = %s" % Fmt.poly([a, b])]
	out.merge(pick(right, wrongs, plain))
	var final := "So %s." % right
	var x2 := 2
	var y2 := a * x2 + b
	out.methods = {
		"inverse-operations": method(["x is multiplied by %s, then %s is %s" % [N(a), str(absi(b)), "added" if b > 0 else "subtracted"],
			"Undo in reverse order: %s %s from both sides, then divide by %s" % ["subtract" if b > 0 else "add", str(absi(b)), N(a)], final], {"v": right}),
		"number-check": method(["Try x = %d: y = %s = %s" % [x2, Fmt.poly([a, b]).replace("x", "(%d)" % x2), N(y2)],
			"The formula %s must give %d back from y = %s" % [right, x2, N(y2)], final], {"v": right}),
	}
	out.pick_wrongs = WRONG_METHODS
	return out


static func N(v: Variant) -> String:
	return Fmt.num(v)


# ── power-or-root ────────────────────────────────────────────

func u_power_or_root(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: int = s.c
	var out := {"asked": "Make x the subject of the formula."}
	var right: String
	var bad: Array = []
	var plain: Array = []
	var under := "y%s" % Fmt.plus(-c) if c != 0 else "y"
	if s.kind == "sq":
		right = "x = ±√(%s)" % under
		var r := int(round(sqrt(absf(c))))
		bad = [tag("x = √y%s" % Fmt.plus(-r if c > 0 else r), R_TERM_BY_TERM), tag("x = √(%s)" % under, R_NO_PM)]
		plain = ["x = ±√(y%s)" % Fmt.plus(c), "x = ±(y%s)" % Fmt.plus(-c), "x = ±√y%s" % Fmt.plus(-c)]
		out.lines = ["y = x²%s" % Fmt.plus(c)] if rep == "equation" else ["y is x squared%s." % (" plus %d" % c if c > 0 else " minus %d" % -c)]
	else:
		right = "x = y²%s" % Fmt.plus(-c)
		plain = ["x = y²%s" % Fmt.plus(c), "x = ±y²%s" % Fmt.plus(-c), "x = √y%s" % Fmt.plus(-c), "x = (y%s)²" % Fmt.plus(c)]
		out.lines = ["y = √(%s)" % Fmt.poly([1, c])] if rep == "equation" else ["y is the square root of x%s." % (" plus %d" % c if c > 0 else " minus %d" % -c)]
	out.merge(pick(right, bad, plain))
	var steps: Array
	if s.kind == "sq":
		steps = ["x is squared, then %d is %s" % [absi(c), "added" if c > 0 else "subtracted"], "Undo in reverse order: %s %d, then take the square root, which has two signs: ±" % ["subtract" if c > 0 else "add", absi(c)], "So %s." % right]
	else:
		steps = ["%d is %s x, then the square root is taken" % [absi(c), "added to" if c > 0 else "subtracted from"], "Undo in reverse order: square both sides, then %s %d" % ["subtract" if c > 0 else "add", absi(c)], "So %s." % right]
	out.methods = {"inverse-operations": method(steps, {"v": right})}
	return out


# ── subject-in-denominator ───────────────────────────────────

func u_subject_in_denominator(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var right := RearrangeSituation.solved_text("denom", s)
	var wrongs := [tag("x = y/%s%s" % [N(a), Fmt.plus(b)] if a > 0 else "x = −y/%s%s" % [N(-a), Fmt.plus(b)], R_ONE_SIDE)]
	var plain := ["x = %s/y%s" % [N(a), Fmt.plus(-b)], "x = y/%s%s" % [N(a), Fmt.plus(-b)], "x = %s%s" % [N(a), Fmt.plus(b)], "x = %sy%s" % [Fmt.lead(a), Fmt.plus(b)]]
	var out := {"asked": "Make x the subject of the formula.", "lines": ["y = %s/(%s)" % [N(a), Fmt.poly([1, -b])]]}
	out.merge(pick(right, wrongs, plain))
	var final := "So %s." % right
	var x2 := b + 1
	out.methods = {
		"inverse-operations": method(["x is in a bracket under %s: take away %s, then %s divides by it" % [N(a), N(b), N(a)], "Undo in reverse order: the divide first (multiply both sides by the bracket and divide by y), then add %s" % N(b), final], {"v": right}),
		"clear-denominator": method(["Multiply both sides by (%s): y(%s) = %s" % [Fmt.poly([1, -b]), Fmt.poly([1, -b]), N(a)], "Divide both sides by y: %s = %s/y" % [Fmt.poly([1, -b]), N(a)], "Add %s to both sides" % N(b), final], {"v": right}),
		"number-check": method(["Try x = %s: y = %s/(%s) = %s" % [N(x2), N(a), N(x2 - b), N(Q.new(a, x2 - b))], "The formula %s must give %s back from y = %s" % [right, N(x2), N(Q.new(a, x2 - b))], final], {"v": right}),
	}
	out.pick_wrongs = WRONG_METHODS
	return out


# ── subject-twice ────────────────────────────────────────────

func u_subject_twice(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var d: int = s.d
	var right := RearrangeSituation.solved_text("twice", s)
	var plain := ["x = %s" % InverseRuleSituation.frac(Fmt.poly([d, b]).replace("x", "y"), Fmt.poly([-c, a]).replace("x", "y")),
		"x = %s" % InverseRuleSituation.frac(Fmt.poly([d, -b]).replace("x", "y"), Fmt.poly([c, a]).replace("x", "y")),
		"x = %s" % InverseRuleSituation.frac(Fmt.poly([a, -b]).replace("x", "y"), Fmt.poly([-c, d]).replace("x", "y")),
		"x = %s" % InverseRuleSituation.frac(Fmt.poly([d, -b]).replace("x", "y"), Fmt.poly([c, -a]).replace("x", "y")),
		"x = %s" % InverseRuleSituation.frac(Fmt.poly([d, -b - 1]).replace("x", "y"), Fmt.poly([-c, a]).replace("x", "y")),
		"x = %s" % InverseRuleSituation.frac(Fmt.poly([-d, b]).replace("x", "y"), Fmt.poly([-c, a + 1]).replace("x", "y"))]
	var out := {"asked": "Make x the subject of the formula.", "lines": ["y = %s" % InverseRuleSituation.frac(Fmt.poly([a, b]), Fmt.poly([c, d]))]}
	out.merge(pick(right, [], plain))
	var x2 := 2 if c * 2 + d != 0 else 3
	var cross := "y(%s) = %s" % [Fmt.poly([c, d]), Fmt.poly([a, b])]
	var expanded := "%s%s = %s" % [Fmt.poly([c, 0]).replace("x", "yx"), _y_term(d), Fmt.poly([a, b])]
	var collected := "x(%s%s) = %s" % [Fmt.poly([c, 0]).replace("x", "y"), Fmt.plus(-a), Fmt.poly([-d, b]).replace("x", "y")]
	var final := "So %s." % right
	out.methods = {
		"clear-denominator": method(["Multiply both sides by (%s): %s" % [Fmt.poly([c, d]), cross], "Expand: %s" % expanded, "Collect the x terms on one side and factor out x: %s" % collected, "Divide by the bracket", final], {"v": right}),
		"collect-and-factor": method(["Multiply out: %s" % cross, "Get every x term on one side: %s" % collected, "Divide both sides by the bracket", final], {"v": right}),
		"number-check": method(["Try x = %d: y = %s" % [x2, N(Q.new(a * x2 + b, c * x2 + d))], "Put this y into %s: it must give x = %d" % [right, x2], "The right-hand side works out to %d, so %s is the formula" % [x2, right], final], {"v": right}),
	}
	var top := Fmt.poly([a, b]) + (_y_term(-d) if d != 0 else "")
	var line_3 := "x = (%s)/%sy" % [top, Fmt.lead(c)]
	out.spot = {"lines": [cross, expanded, line_3, "So " + line_3], "bad": 2, "ref": R_BOTH_SIDES,
		"why": "x is on both sides: the x terms must be collected on one side and factored out before dividing"}
	out.pick_wrongs = WRONG_METHODS
	return out


## " + 3y" / " − 3y" as the term in y after expanding: the d of (cx + d) times y.
static func _y_term(d: int) -> String:
	return " %s %sy" % ["+" if d > 0 else "−", "" if absi(d) == 1 else str(absi(d))]


# ── subject-twice-linear ─────────────────────────────────────

func u_subject_twice_linear(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var n: int = s.n
	var right := "x = (m%s)/(k%s)" % [Fmt.plus(-p), Fmt.plus(-n)]
	var plain := ["x = (m%s)/(k%s)" % [Fmt.plus(p), Fmt.plus(-n)], "x = (m%s)/(k%s)" % [Fmt.plus(-p), Fmt.plus(n)], "x = (m%s)/(k%s)" % [Fmt.plus(-p), Fmt.plus(-n - 1)],
		"x = (m%s)/(%d − k)" % [Fmt.plus(p), n], "x = (k%s)/(m%s)" % [Fmt.plus(-n), Fmt.plus(-p)]]
	var out := {"asked": "Make x the subject of the formula.", "lines": ["kx%s = %dx + m" % [Fmt.plus(p), n]]}
	out.merge(pick(right, [], plain))
	var final := "So %s." % right
	var step_collect := "Get the x terms on the left and the others on the right: kx − %dx = m%s" % [n, Fmt.plus(-p)]
	out.methods = {
		"collect-and-factor": method([step_collect, "Factor out x: x(k%s) = m%s" % [Fmt.plus(-n), Fmt.plus(-p)], "Divide both sides by (k%s)" % Fmt.plus(-n), final], {"v": right}),
		"number-check": method(["Pick k = %d and m = 0 to test the formula" % (n + 2), "Then %dx%s = %dx gives 2x = %s, so x = %s" % [n + 2, Fmt.plus(p), n, N(-p), N(Q.new(-p, 2))],
			"The formula gives x = (0%s)/(%d%s) = %s, which agrees" % [Fmt.plus(-p), n + 2, Fmt.plus(-n), N(Q.new(-p, 2))], final], {"v": right}),
	}
	return out


# ── which-original ───────────────────────────────────────────

func u_which_original(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var src: String = s.src
	var inner: Dictionary = s.inner
	var shown := RearrangeSituation.solved_text(src, inner)
	var right := RearrangeSituation.formula_text(src, inner)
	var plain: Array = []
	match src:
		"two":
			plain = [RearrangeSituation.formula_text("two", {"a": inner.a, "b": -inner.b}), RearrangeSituation.formula_text("two", {"a": -inner.a, "b": inner.b}),
				RearrangeSituation.formula_text("two", {"a": inner.a + 1, "b": inner.b}), RearrangeSituation.formula_text("two", {"a": inner.a, "b": inner.b + 1})]
		"denom":
			plain = [RearrangeSituation.formula_text("denom", {"a": inner.a, "b": -inner.b}), RearrangeSituation.formula_text("denom", {"a": -inner.a, "b": inner.b}),
				RearrangeSituation.formula_text("denom", {"a": inner.a + 1, "b": inner.b}), RearrangeSituation.formula_text("denom", {"a": inner.a, "b": inner.b + 1})]
		_:
			plain = [RearrangeSituation.formula_text("twice", {"a": inner.d, "b": inner.b, "c": inner.c, "d": inner.a}),
				RearrangeSituation.formula_text("twice", {"a": inner.a, "b": -inner.b, "c": inner.c, "d": inner.d}),
				RearrangeSituation.formula_text("twice", {"a": inner.a, "b": inner.b, "c": -inner.c, "d": inner.d}),
				RearrangeSituation.formula_text("twice", {"a": inner.a, "b": inner.b + 1, "c": inner.c, "d": inner.d})]
	var out := {"asked": "Which formula did this come from?", "lines": [shown]}
	out.merge(pick(right, [], plain))
	var final := "So it came from %s." % right
	out.methods = {
		"inverse-operations": method(["Read the steps on x in the rearranged formula, then reverse them", "Reversed, they build the formula from x: %s" % right, final], {"v": right}),
		"number-check": method(["Put y = 1 into %s to get a value of x" % shown, "Put that value of x into each option: only one gives y = 1", "That is %s" % right, final], {"v": right}),
	}
	return out
