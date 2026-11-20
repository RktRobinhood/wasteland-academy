class_name InverseRuleViews
extends ExtensionViews
## The views on the `inverse-rule` situation: one builder per unknown of
## fn-inverse-algebraic (FAL-422). Students can't type a function of x, so an inverse, a
## domain or an asymptote pair is picked from four written options (the `choice` kind);
## a constant, a value or a k is a typed number. The checker reads each option back with
## SymPy: the right one is checked as maths, and every wrong one is shown to be wrong.

const T := "fn-inverse-algebraic"
const R_RECIPROCAL := "SL2.5.find-inverse#0"
const R_ORDER := "SL2.5.find-inverse#1"
const R_PM := "SL2.5.find-inverse#2"
const R_DOMAIN_OF_F := "SL2.5.inverse-domain-range#0"
const R_Y_INTERCEPT := "SL2.5.inverse-domain-range#1"
const R_NO_RESTRICTION := "SL2.5.inverse-domain-range#2"
const R_EXCLUDED := "SL2.8.rational-inverse#1"
const R_ONLY_RECIPROCAL := "SL2.8.rational-inverse#2"
const R_ONE := "SL2.5.identity#0"
const R_SOLVE_INVERSE := "SL2.5.identity#1"
const R_ANY_F := "SL2.5.identity#2"
const R_REFLECT := "SL2.11.reflect#1"
## fn-inverse-algebraic's own slips (FAL-820).
const R_SAME_SIGN := "fn-inverse-algebraic#13"
const R_TIMES := "fn-inverse-algebraic#14"
const R_ONE_SIGN := "fn-inverse-algebraic#15"
const R_NO_SWAP := "fn-inverse-algebraic#16"
const R_HK := "fn-inverse-algebraic#17"
const R_NO_LOG := "fn-inverse-algebraic#18"
const R_ASYMPTOTE_IN := "fn-inverse-algebraic#19"
const R_MINUS := "fn-inverse-algebraic#20"
const R_VERTEX_SIGN := "fn-inverse-algebraic#21"
const R_VERTEX_Y := "fn-inverse-algebraic#22"
const R_SELF_PLUS := "fn-inverse-algebraic#23"
const R_F_ONLY := "fn-inverse-algebraic#24"


func needs() -> Dictionary:
	return {
		"inverse-linear": {"mode": "lin"},
		"inverse-rational": {"mode": "rat"},
		"inverse-root": {"mode": "root"},
		"inverse-restricted-quadratic": {"mode": "rquad"},
		"inverse-exponential": {"mode": "exp"},
		"inverse-domain": {"mode": "any"},
		"inverse-range": {"mode": "any"},
		"rational-inverse-domain": {"mode": "rat"},
		"restrict-for-inverse": {"mode": "restrict"},
		"show-self-inverse": {"mode": "selfinv"},
		"self-inverse-constant": {"mode": "selfinv"},
		"inverse-as-reflections": {"mode": "refl"},
		"compose-to-identity": {"mode": "pair"},
		"identity-value": {"mode": "ident"},
		"solve-inverse-equals": {"mode": "solve"},
		"function-from-inverse": {"mode": "funcinv"},
		"inverse-asymptotes": {"mode": "asym"},
	}


## Every cell can be asked on either paper: the algebra is exact on both (the calculator is
## there on Paper 2); the exam's four Paper 2 parts to one Paper 1 part set the ratio.
func papers(_unknown: String, _rep: String, _angle: String) -> Array:
	return [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = InverseRuleSituation.export(s)
	return out


# ── Helpers ──────────────────────────────────────────────────

static func rt(f: Dictionary) -> String:
	return InverseRuleSituation.rule_text(f)


static func inv(f: Dictionary) -> String:
	return InverseRuleSituation.inverse_text(f)


static func finv(f: Dictionary) -> String:
	return "f⁻¹(x) = " + inv(f)


static func final(text: String) -> String:
	return "So %s." % text


## A question's four options: the right one, then misconception options (each tagged),
## then plain wrong ones. Returns the Answer plus the wrongs and generics to put in `out`.
## `bad` is [{"text", "ref"}], `plain` a list of texts. Texts equal to another are dropped.
static func choose(right: String, bad: Array, plain: Array) -> Dictionary:
	var seen := {right: true}
	var opts: Array = [right]
	var wrongs: Array = []
	var generic: Array = []
	for b in bad:
		if not seen.has(b.text):
			seen[b.text] = true
			wrongs.append({"values": {"v": b.text}, "ref": b.ref})
			opts.append(b.text)
	for p in plain:
		if not seen.has(p):
			seen[p] = true
			generic.append({"v": p})
			opts.append(p)
	var ans := Answer.make("choice", {"v": right}, {"options": opts.slice(0, 4)})
	return {"answer": ans, "wrongs": wrongs, "generic": generic}


## choose() for this type's own options: the untagged ones are fillers (FAL-820).
static func pick_of(right: String, bad: Array, plain: Array) -> Dictionary:
	var out := choose(right, bad, plain)
	out.fillers = out.generic
	out.erase("generic")
	return out


static func tag(text: String, ref: String) -> Dictionary:
	return {"text": text, "ref": ref}


## A number answer, exact.
static func number(label: String, v: Variant) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.of(v)}, {}, label)
	ans.exact = true
	return ans


## The lines a view shows: the rule as an equation, or said in steps (words).
static func rule_lines(rep: String, f: Dictionary, name: String = "f") -> Array:
	if rep == "words" and not InverseRuleSituation.rule_steps(f).is_empty():
		return ["%s: %s." % [name, ", then ".join(InverseRuleSituation.rule_steps(f))]]
	return [InverseRuleSituation.rule_line(f, name)]


static func N(v: Variant) -> String:
	return Fmt.num(v)


## y = f(x) with each of its steps, for a derivation.
static func yline(f: Dictionary) -> String:
	return "y = " + (InverseRuleSituation.rule_text(f))


## The pattern for the inverse of a rational rule, in the catalogue's form (the
## coefficient-pattern method's name).
const PATTERN := "For (ax + b)/(cx + d) the inverse is (−dx + b)/(cx − a)"


## A rational rule swapped and cross-multiplied, x(cy + d) = ay + b, and its y terms
## collected, y(cx − a) = −dx + b: the steps that find its inverse.
static func _cross(f: Dictionary) -> String:
	return "x(%s) = %s" % [Fmt.poly([f.c, f.d]).replace("x", "y"), Fmt.poly([f.a, f.b]).replace("x", "y")]


static func _collect(f: Dictionary) -> String:
	return "y(%s) = %s" % [Fmt.poly([f.c, -f.a]), Fmt.poly([-f.d, f.b])]


## A rule with x put in as a number: "5(6) − 2", "√(2(3) + 3) + 1", "(6 + 3)". A number
## after a coefficient is always bracketed, so 5 × 6 is never written 56.
static func sub_x(text: String, v: Variant) -> String:
	var out := ""
	for i in text.length():
		var ch := text[i]
		if ch != "x":
			out += ch
		elif i > 0 and "0123456789".contains(text[i - 1]):
			out += "(%s)" % N(v)
		else:
			out += Fmt.paren(v)
	return out


## Wrong whole numbers for a typed answer, the ones far from the key first: a filler at
## the key ± 1 or ± 2, or twice it, is easy to rule out by guessing round the key.
static func far_first(key: Variant, vals: Array) -> Array:
	var kq := Q.of(key)
	var near: Array = []
	var far: Array = []
	for v in vals:
		var q := Q.of(v)
		var d := q.sub(kq)
		if d.abs_q().lt(3) or q.eq(kq.mul(2)):
			near.append({"v": q})
		else:
			far.append({"v": q})
	return far + near


## The graph of f with y = x and what marks it: an endpoint, asymptotes.
static func graph_of(f: Dictionary) -> Dictionary:
	var curves: Array = []
	var points: Array = []
	var hl: Array = []
	var vl: Array = []
	match f.fam:
		"lin":
			curves.append(clip(func(x): return f.a * x + f.b, -8.0, 8.0))
			points.append([0, f.b, Fmt.point(0, f.b)])
		"rat":
			var xa: float = float(-f.d) / f.c
			curves.append(clip(func(x): return (f.a * x + f.b) / (f.c * x + f.d), -8.0, xa - 0.04))
			curves.append(clip(func(x): return (f.a * x + f.b) / (f.c * x + f.d), xa + 0.04, 8.0))
			vl.append([xa, "x = %s" % N(Q.new(-f.d, f.c))])
			hl.append([float(f.a) / f.c, "y = %s" % N(Q.new(f.a, f.c))])
		"root":
			var x0: float = float(-f.q) / f.p
			curves.append(clip(func(x): return sqrt(f.p * x + f.q) + f.r, x0, 8.0))
			points.append([x0, f.r, Fmt.point(Q.new(-f.q, f.p), f.r)])
		"rquad":
			var lo: float = f.h if f.dir == "≥" else -8.0
			var hi: float = 8.0 if f.dir == "≥" else f.h
			curves.append(clip(func(x): return (x - f.h) * (x - f.h) + f.k, lo, hi))
			points.append([f.h, f.k, Fmt.point(f.h, f.k)])
		"exp":
			var b: float = exp(1.0) if str(f.base) == "e" else float(f.base)
			curves.append(clip(func(x): return pow(b, x) + f.q, -8.0, 8.0))
			hl.append([f.q, "y = %s" % N(f.q)])
		"quad":
			curves.append(clip(func(x): return f.a * (x - f.h) * (x - f.h) + f.k, -8.0, 8.0))
			var co := InverseRuleSituation.quad_co(f)
			points.append([0, co[0].n, Fmt.point(0, co[0].n)])
	curves.append([[-8.0, -8.0], [8.0, 8.0]])
	return Plot.spec(curves, points, -8, 8, -8, 8, hl, vl)


## A curve sampled between x0 and x1, keeping the points inside the window.
static func clip(fn: Callable, x0: float, x1: float) -> Array:
	return Plot.sample(fn, x0, x1).filter(func(p): return absf(p[1]) <= 9.5)


## The working that gets to f⁻¹ by one of the catalogue's methods: every step but the
## last statement, which each builder adds.
static func derive(f: Dictionary, angle: String) -> Array:
	var rule := InverseRuleSituation.rule_text(f)
	var y := "y = " + rule
	var swapped := "Swap x and y: x = " + rule.replace("x", "y")
	var back := inv(f).replace("x", "y")
	if angle == "solve-then-swap":
		return [y, "Solve for x: x = " + back, "Swap x and y to get the inverse"]
	if angle == "reverse-operations":
		return ["f does: " + ", then ".join(InverseRuleSituation.rule_steps(f)), "Undo in reverse order: " + _undo(f)]
	match f.fam:
		"lin":
			return [y, swapped, "Solve for y: y = " + inv(f)]
		"rat":
			if angle == "coefficient-pattern":
				return [PATTERN + ": swap a and d, and change both their signs",
					"Here a = %s, b = %s, c = %s and d = %s, so −d = %s and −a = %s" % [N(f.a), N(f.b), N(f.c), N(f.d), N(-f.d), N(-f.a)]]
			return [y + ", swap x and y, then cross-multiply: " + _cross(f), "Collect the y terms: " + _collect(f), "Divide by the bracket: y = " + inv(f)]
		"root":
			var sq := "x²" if f.r == 0 else Fmt.factor(f.r) + "²"
			if angle == "swap-domain-range":
				return [swapped, "Isolate the root and square: %s = %s, so y = %s" % [sq, Fmt.poly([f.p, f.q]).replace("x", "y"), inv(f)],
					"The domain of f⁻¹ is the range of f: x ≥ %s" % N(f.r)]
			return [y, swapped, "Isolate the root and square: %s = %s, so y = %s" % [sq, Fmt.poly([f.p, f.q]).replace("x", "y"), inv(f)]]
		"rquad":
			var under := "x" if f.k == 0 else "x" + Fmt.plus(-f.k)
			var root := "√x" if f.k == 0 else "√(%s)" % under
			var yh := "y" + Fmt.plus(-f.h) if f.h != 0 else "y"
			var pm := ("%s ± %s" % [N(f.h), root]) if f.h != 0 else "±" + root
			var up: bool = f.dir == "≥"
			# After the swap, x is the input of f⁻¹: f's domain is the range of f⁻¹, a condition on y.
			var ranged := "domain x %s %s of f is the range of f⁻¹, so y %s %s" % [f.dir, N(f.h), f.dir, N(f.h)]
			var which := "positive" if up else "negative"
			if angle == "graph-check":
				return [swapped + ", so (%s)² = %s and y = %s" % [yh, under, pm],
					"The %s: take the %s root, y = %s. On the GDC, the graphs of y = f(x) and y = %s are mirror images in y = x" % [ranged, which, inv(f), inv(f)]]
			if angle == "restrict-at-vertex":
				return ["x %s %s is one side of the vertex, so f is one-to-one" % [f.dir, N(f.h)], swapped + ", so (%s)² = %s" % [yh, under],
					"The %s and %s %s 0: %s = %s%s" % [ranged, yh, f.dir, yh, "" if up else "−", root]]
			return [y, swapped + ", so (%s)² = %s" % [yh, under],
				"%s = ±%s, and the %s: take the %s root" % [yh, root, ranged, which]]
		"exp":
			var isolate := "x" if f.q == 0 else "x" + Fmt.plus(-f.q)
			var power := "%s^y = %s" % [InverseRuleSituation.base_text(f.base), isolate]
			return [y, swapped, "Isolate the power: %s, then take %s" % [power, "natural logs" if str(f.base) == "e" else "log base %s" % f.base]]
	return [y]


static func _undo(f: Dictionary) -> String:
	var steps := InverseRuleSituation.rule_steps(f)
	var out: Array = []
	for i in range(steps.size() - 1, -1, -1):
		var st: String = steps[i]
		if st.begins_with("add "):
			out.append("subtract " + st.substr(4))
		elif st.begins_with("subtract "):
			out.append("add " + st.substr(9))
		elif st == "double":
			out.append("halve")
		elif st == "treble":
			out.append("divide by 3")
		elif st == "negate":
			out.append("negate")
		elif st.begins_with("multiply by "):
			out.append("divide by " + st.substr(12))
		elif st == "take the square root":
			out.append("square")
		else:
			out.append("take the natural log" if str(f.base) == "e" else "take log base %s" % f.base)
	return ", then ".join(out)


## The methods of an unknown: each angle's derivation, then the closing statement.
static func methods(f: Dictionary, angles: Array, closing: String, answer: Dictionary) -> Dictionary:
	var out := {}
	for a in angles:
		out[a] = method(derive(f, a) + [closing], answer.values)
	return out


func _angles(unknown: String) -> Array:
	var t := QuestionEngine.type_of(T)
	var out: Array = []
	for a in t.get("angles", []):
		if unknown in a.suits and not out.has(a.method):
			out.append(a.method)
	return out


## Different conditions on x or y from a right one: "x ≥ 3" gives "x ≤ 3", "x > 3", ...
static func cond_variants(right: String) -> Array:
	var parts := right.split(" ")
	if parts.size() != 3:
		return ["x ≥ 0", "x ≤ 0", "x > 0"]
	var v: String = parts[0]
	var n: String = parts[2]
	var neg: String = n.trim_prefix("−") if n.begins_with("−") else ("−" + n if n != "0" else "1")
	return ["%s %s %s" % [v, "≤" if parts[1] == "≥" else "≥", n], "%s %s %s" % [v, "≥" if parts[1] == "≥" else "≥", neg],
		"%s ≠ %s" % [v, n], "%s > %s" % [v, n], "%s %s %s" % [v, parts[1], neg]]


## k as an answer slot: "(ax + b)/(cx + k)" or "(kx + b)/(cx + d)".
static func with_k(f: Dictionary, slot: String) -> String:
	if slot == "d":
		return "(%s)/(%sx + k)" % [Fmt.poly([f.a, f.b]), Fmt.lead(f.c)]
	var top := "kx" + ("" if f.b == 0 else Fmt.plus(f.b))
	return "(%s)/(%s)" % [top, Fmt.poly([f.c, f.d])]


## (ax + b)/(cx + d) in its lowest terms with the bottom's leading coefficient positive,
## so two options that are the same function read the same, and choose() drops one.
static func rat_text(a: int, b: int, c: int, d: int) -> String:
	return InverseRuleSituation.rat_frac(a, b, c, d)


## A slip's (ax + b)/(cx + d) as a tagged option, or none when it cancels to a number,
## as (x − 1)/(x − 1) does: that is no rule a student would write.
static func rat_tag(a: int, b: int, c: int, d: int, ref: String, label: String = "f⁻¹(x) = %s") -> Array:
	return [] if a * d == b * c else [tag(label % rat_text(a, b, c, d), ref)]


## Plain wrong f⁻¹(x) options from [a, b, c, d] coefficients: none that cancels to a
## number, and none that is the right [a, b, c, d] written another way (a multiple of it).
static func rat_plain(right: Array, coeffs: Array, label: String = "f⁻¹(x) = %s") -> Array:
	var out: Array = []
	for k in coeffs:
		var same := true
		for i in 4:
			for j in range(i + 1, 4):
				same = same and k[i] * right[j] == k[j] * right[i]
		if k[0] * k[3] != k[1] * k[2] and not same:
			out.append(label % rat_text(k[0], k[1], k[2], k[3]))
	return out


# ── The unknowns ─────────────────────────────────────────────

func u_inverse_linear(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var a: int = f.a
	var b: int = f.b
	var right := finv(f)
	var order := InverseRuleSituation.order_text(a, b)
	var pick := pick_of(right, [tag("f⁻¹(x) = 1/(%s)" % rt(f), R_RECIPROCAL), tag("f⁻¹(x) = " + order, R_ORDER),
		tag(finv(InverseRuleSituation.lin_rule(a, -b)), R_SAME_SIGN)] + ([] if absi(a) == 1 else [tag("f⁻¹(x) = %s(x%s)" % [Fmt.lead(a), Fmt.plus(-b)], R_TIMES)]),
		[finv(InverseRuleSituation.lin_rule(-a, b)), finv(InverseRuleSituation.lin_rule(a, b + 1))])
	var out := {"asked": "Find f⁻¹(x).", "lines": rule_lines(rep, f)}
	out.merge(pick)
	out.methods = methods(f, _angles("inverse-linear"), final(right), pick.answer)
	return out


func u_inverse_rational(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var a: int = f.a
	var b: int = f.b
	var c: int = f.c
	var d: int = f.d
	var right := finv(f)
	var pick := pick_of(right, rat_tag(d, b, -c, a, R_ONE_SIGN) + rat_tag(d, -b, c, a, R_ONE_SIGN) + rat_tag(a, -b, -c, d, R_NO_SWAP),
		rat_plain([d, -b, -c, a], [[d, -b, -c, -a], [d, b + 1, -c, a], [b, -d, -c, a], [d, -b, c, -a], [d, b, c, a]]))
	var out := {"asked": "Find f⁻¹(x).", "lines": [InverseRuleSituation.rule_line(f)]}
	out.merge(pick)
	out.methods = methods(f, _angles("inverse-rational"), final(right), pick.answer)
	return out


func u_inverse_root(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var x0 := Q.new(-f.q, f.p)
	var right := "%s, domain x ≥ %s, range y ≥ %s" % [finv(f), N(f.r), N(x0)]
	var sq := "(x%s)²" % Fmt.plus(f.r) if f.r != 0 else "x²"
	var slip := finv({"fam": "root", "p": f.p, "q": f.q, "r": -f.r}) if f.r != 0 else "f⁻¹(x) = " + inv(f) + Fmt.plus(1)
	var flipq := finv({"fam": "root", "p": f.p, "q": -f.q if f.q != 0 else f.p, "r": f.r})
	var dom := ", domain x ≥ %s, range y ≥ %s" % [N(f.r), N(x0)]
	# r (or q) undone with its own sign is a slip; with r (or q) zero the stand-in is a filler.
	var bad: Array = [tag("%s, domain x ≥ %s, range y ≥ %s" % [finv(f), N(x0), N(f.r)], R_DOMAIN_OF_F)]
	var plain: Array = []
	if f.r != 0:
		bad.append(tag(slip + dom, R_SAME_SIGN))
	else:
		plain.append(slip + dom)
	if f.q != 0:
		bad.append(tag(flipq + dom, R_SAME_SIGN))
	else:
		plain.append(flipq + dom)
	var pick := pick_of(right, bad, plain + ["f⁻¹(x) = " + inv(f) + Fmt.plus(f.r if f.r != 0 else 1) + dom,
		finv({"fam": "root", "p": f.p + 1, "q": f.q, "r": f.r}) + dom])
	var out := {"asked": "Find f⁻¹(x), with its domain and range.", "lines": [InverseRuleSituation.rule_line(f)], "answer": pick.answer}
	out.merge(pick)
	if rep == "graph":
		out.graph = graph_of(f)
		out.lines = [InverseRuleSituation.rule_line(f), "The graph of y = f(x) is shown with the line y = x."]
	var tail := ["The domain of f⁻¹ is the range of f, y ≥ %s, so x ≥ %s; the range of f⁻¹ is the domain of f, x ≥ %s, so y ≥ %s" % [N(f.r), N(f.r), N(x0), N(x0)]]
	var out_methods := {}
	for a in _angles("inverse-root"):
		var steps := derive(f, a)
		if a == "swap-domain-range":
			steps = steps.slice(0, 2)
		out_methods[a] = method(steps + tail + [final(right)], pick.answer.values)
	out.methods = out_methods
	return out


func u_inverse_restricted_quadratic(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var h: int = f.h
	var k: int = f.k
	var under := "x" if k == 0 else "x" + Fmt.plus(-k)
	var root := "√x" if k == 0 else "√(%s)" % under
	var pm_text := ("%s ± %s" % [N(h), root]) if h != 0 else "±" + root
	var flip := finv({"fam": "rquad", "h": h, "k": k, "dir": "≤" if f.dir == "≥" else "≥"})
	var right := finv(f)
	var bad: Array = [tag("f⁻¹(x) = " + pm_text, R_PM), tag(flip, R_PM)]
	var plain: Array = []
	var hk := finv({"fam": "rquad", "h": k if k != 0 else 1, "k": h, "dir": f.dir})
	if k != 0 and k != h:
		bad.append(tag(hk, R_HK))
	else:
		plain.append(hk)
	if h != 0:
		bad.append(tag(finv({"fam": "rquad", "h": -h, "k": k, "dir": f.dir}), R_SAME_SIGN))
	if k != 0:
		bad.append(tag(finv({"fam": "rquad", "h": h, "k": -k, "dir": f.dir}), R_SAME_SIGN))
	var pick := pick_of(right, bad, plain + ["f⁻¹(x) = (x%s)²%s" % [Fmt.plus(-k), Fmt.plus(h)]])
	var out := {"asked": "Find f⁻¹(x).", "lines": [InverseRuleSituation.rule_line(f)]}
	out.merge(pick)
	if rep == "graph":
		out.graph = graph_of(f)
		out.lines = [InverseRuleSituation.rule_line(f), "The graph of y = f(x) is shown with the line y = x."]
	out.methods = methods(f, _angles("inverse-restricted-quadratic"), final(right), pick.answer)
	return out


func u_inverse_exponential(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var q: int = f.q
	var right := "%s, domain x > %s" % [finv(f), N(q)]
	# Up to four slips for three places: shuffled, so each one is shown.
	var pick := pick_of(right, rng.shuffled([tag("%s, domain all real x" % finv(f), R_DOMAIN_OF_F),
		tag("%s, domain x > %s" % [finv({"fam": "exp", "base": f.base, "q": -q}), N(-q)], R_SAME_SIGN) if q != 0 else tag("f⁻¹(x) = 1/%s^x, domain x > 0" % InverseRuleSituation.base_text(f.base), R_RECIPROCAL),
		tag("%s, domain x ≥ %s" % [finv(f), N(q)], R_ASYMPTOTE_IN)] + ([tag("%s, domain x > %s" % ["f⁻¹(x) = %s^x%s" % [InverseRuleSituation.base_text(f.base), Fmt.plus(-q)], N(q)], R_NO_LOG)] if q != 0 else [])),
		[] if q != 0 else ["f⁻¹(x) = %s^x, domain x > 0" % InverseRuleSituation.base_text(f.base)])
	var out := {"asked": "Find f⁻¹(x) and its domain.", "lines": [InverseRuleSituation.rule_line(f)]}
	out.merge(pick)
	var tail := ["The domain of f⁻¹ is the range of f, y > %s, so x > %s" % [N(q), N(q)]]
	var out_methods := {}
	for a in _angles("inverse-exponential"):
		out_methods[a] = method(derive(f, a).slice(0, 3) + tail + [final(right)], pick.answer.values)
	out.methods = out_methods
	return out


## Wrong conditions of the same kind as the right one: for a rational f, whose domain and
## range each leave out one value, other "≠" values (the signs of a/c and −d/c changed,
## where f is zero), so the key is not the only "≠" option.
static func cond_fillers(f: Dictionary, right: String, swap: bool) -> Array:
	if f.fam != "rat":
		return cond_variants(right)
	var v: String = right.substr(0, 1)
	var a := Q.new(f.a, f.c)
	var d := Q.new(-f.d, f.c)
	var vals: Array = [a.neg(), d.neg()] if not swap else [d.neg(), a.neg()]
	vals += [Q.new(-f.b, f.a), Q.new(0)]
	return vals.map(func(q): return "%s ≠ %s" % [v, N(q)])


func u_inverse_domain(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var right := InverseRuleSituation.inv_domain_text(f)
	var pick := pick_of(right, [tag(InverseRuleSituation.domain_text(f), R_DOMAIN_OF_F)], cond_fillers(f, right, false))
	var out := {"asked": "Find the domain of f⁻¹.", "lines": [InverseRuleSituation.rule_line(f)]}
	out.merge(pick)
	if rep == "graph":
		out.graph = graph_of(f)
		out.lines = [InverseRuleSituation.rule_line(f), "The graph of y = f(x) is shown with the line y = x."]
	out.methods = {"swap-domain-range": method(["f has domain %s and range %s" % [InverseRuleSituation.domain_text(f), InverseRuleSituation.range_text(f)],
		"Swapping x and y swaps the domain and the range, so the domain of f⁻¹ is the range of f", "So the domain of f⁻¹ is %s." % right], pick.answer.values)}
	return out


func u_inverse_range(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var right := InverseRuleSituation.inv_range_text(f)
	var pick := pick_of(right, [tag(InverseRuleSituation.range_text(f), R_DOMAIN_OF_F)], cond_fillers(f, right, true))
	var out := {"asked": "Find the range of f⁻¹.", "lines": [InverseRuleSituation.rule_line(f)]}
	out.merge(pick)
	if rep == "graph":
		out.graph = graph_of(f)
		out.lines = [InverseRuleSituation.rule_line(f), "The graph of y = f(x) is shown with the line y = x."]
	out.methods = {"swap-domain-range": method(["f has domain %s and range %s" % [InverseRuleSituation.domain_text(f), InverseRuleSituation.range_text(f)],
		"Swapping x and y swaps the domain and the range, so the range of f⁻¹ is the domain of f", "So the range of f⁻¹ is %s." % right], pick.answer.values)}
	return out


func u_rational_inverse_domain(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var xa := Q.new(f.a, f.c)
	var ya := Q.new(-f.d, f.c)
	var right := "domain x ≠ %s, range y ≠ %s" % [N(xa), N(ya)]
	var pick := pick_of(right, [tag("domain x ≠ %s, range y ≠ %s" % [N(ya), N(xa)], R_EXCLUDED), tag("domain x ≠ %s, range y ≠ %s" % [N(xa), N(ya.neg())], R_MINUS)],
		["domain x ≠ %s, range y ≠ %s" % [N(ya.neg()), N(xa.neg())], "domain x ≠ %s, range y ≠ %s" % [N(xa.neg()), N(ya)]])
	var out := {"asked": "Find the domain and range of f⁻¹.", "lines": [InverseRuleSituation.rule_line(f)]}
	out.merge(pick)
	if rep == "graph":
		out.graph = graph_of(f)
		out.lines = [InverseRuleSituation.rule_line(f), "The graph of y = f(x) is shown with its asymptotes and the line y = x."]
	var asy := "f has the asymptotes x = %s and y = %s" % [N(ya), N(xa)]
	out.methods = {
		"swap-asymptotes": method([asy, "Swapping x and y swaps the asymptotes: f⁻¹ has x = %s and y = %s" % [N(xa), N(ya)], final(right)], pick.answer.values),
		"swap-domain-range": method(["f has domain x ≠ %s and range y ≠ %s" % [N(Q.new(-f.d, f.c)), N(xa)],
			"The domain of f⁻¹ is the range of f, and the range of f⁻¹ is the domain of f", final(right)], pick.answer.values),
	}
	return out


func u_restrict_for_inverse(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var h: int = f.h
	var co := InverseRuleSituation.quad_co(f)
	var least: bool = f.dir == "≥"
	var ans := number("k = ", h)
	var asked := ("Find the least value of k for which f has an inverse on the domain x ≥ k." if least
		else "Find the greatest value of k for which f has an inverse on the domain x ≤ k.")
	var out := {"asked": asked, "lines": ["f(x) = %s" % rt(f)], "answer": ans,
		"wrongs": [wrong({"v": Q.new(0)}, R_Y_INTERCEPT), wrong({"v": Q.new(-h)}, R_VERTEX_SIGN), wrong({"v": Q.new(f.k)}, R_VERTEX_Y)],
		# Used only where two slips agree (k is 0, h or −h): the value of f at 0, and b.
		"fillers": far_first(h, [co[0], co[1], co[1].neg(), Q.new(-f.k)])}
	if rep == "graph":
		out.graph = graph_of(f)
		out.lines = ["f(x) = %s" % rt(f), "The graph of y = f(x) is shown."]
	var b: Q = co[1]
	var a: Q = co[2]
	var final_text := "So %s." % Answer.text(ans)
	# −b/(2a) with the numbers in: −8/(−4), −(−4)/4.
	var vertex := "x = −b/(2a) = %s/%s = %s" % [N(b.neg()) if b.sign() > 0 else "−" + P(b), P(a.mul(2)), N(h)]
	out.methods = {
		"restrict-at-vertex": method(["f is one-to-one on one side of its vertex, so k is the x-coordinate of the vertex",
			vertex, final_text], ans.values),
		"horizontal-line": method(["A horizontal line cuts the graph twice, one point either side of the vertex, so f needs a domain that stays on one side",
			"The vertex is at " + vertex, "Take the domain x %s %s: %s" % [f.dir, N(h), final_text.trim_prefix("So ").trim_suffix(".")], final_text], ans.values),
	}
	return out


func u_show_self_inverse(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var a: int = f.a
	var b: int = f.b
	var c: int = f.c
	var d: int = f.d
	var right := finv(f) + ", which is f(x)"
	var slip := rat_tag(d, b, -c, a, R_ONE_SIGN, "f⁻¹(x) = %s, which is not f(x)")
	var plain := [finv(f) + ", which is not f(x)", "f⁻¹(x) = %s, which is f(x)" % rat_text(d, -b, c, a)]
	# With the slip gone (a² = bc), a third filler keeps four options: it cancels only when a² = −bc.
	if slip.is_empty():
		plain.append("f⁻¹(x) = %s, which is not f(x)" % rat_text(a, b, -c, a))
	var pick := pick_of(right, slip, plain)
	var out := {"asked": "Find f⁻¹(x), and show that f is its own inverse.", "lines": [InverseRuleSituation.rule_line(f)]}
	out.merge(pick)
	var swapped := "Swap x and y: x = " + rt(f).replace("x", "y")
	var rearranged := derive(f, "swap-then-solve")
	# a(ax + b) + b(cx + d) on top and c(ax + b) + d(cx + d) below: with d = −a the x terms
	# below cancel, and so do the numbers on top.
	var n := a * a + b * c
	var top := _times(a, rt_top(f), true) + _times(b, rt_bottom(f), false)
	var bottom := _times(c, rt_top(f), true) + _times(d, rt_bottom(f), false)
	var compose := ["f(f(x)) = " + _ff(f),
		"Multiply top and bottom by (%s): f(f(x)) = (%s)/(%s) = %s/%s = x" % [rt_bottom(f), top, bottom, Fmt.poly([n, 0]), P(n)]]
	var same := "The inverse is the same expression as f(x)"
	var methods := {
		"swap-then-solve": method(rearranged + [same, final(right)], pick.answer.values),
		"swap-and-rearrange": method([swapped + ", cross-multiply and collect the y terms", "%s, so y = %s" % [_collect(f), inv(f)], same, final(right)], pick.answer.values),
		"coefficient-pattern": method([PATTERN, "Here a = %s, b = %s, c = %s and d = %s = −a, so −d = a and −a = d: the inverse is %s" % [N(a), N(b), N(c), N(d), inv(f)], same, final(right)], pick.answer.values),
		"compose-and-simplify": method(compose + [same, final(right)], pick.answer.values),
	}
	out.methods = methods
	return out


## m(text) as a term of a sum: "6(6x − 1)", " − (2x − 6)", " + 2(x + 3)".
static func _times(m: int, text: String, first: bool) -> String:
	var head := ("−" if m < 0 else "") if first else (" − " if m < 0 else " + ")
	return head + Fmt.lead(absi(m)) + "(%s)" % text


## The top and the bottom of a rational rule: "6x − 1", "2x − 6".
static func rt_top(f: Dictionary) -> String:
	return Fmt.poly([f.a, f.b])


static func rt_bottom(f: Dictionary) -> String:
	return Fmt.poly([f.c, f.d])


## f(f(x)) written out: (a·f + b)/(c·f + d) with f(x) put in.
static func _ff(f: Dictionary) -> String:
	var inner := "(" + rt(f) + ")"
	return "(%s)/(%s)" % [Fmt.poly([f.a, f.b]).replace("x", inner), Fmt.poly([f.c, f.d]).replace("x", inner)]


func u_self_inverse_constant(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var slot: String = s.slot
	var k: int = f.d if slot == "d" else f.a
	var ans := number("k = ", k)
	var shown := with_k(f, slot)
	# b or c in k's place, their negatives, or 0; the ones near k last (FAL-1055).
	var out := {"asked": "Find the value of k for which f is its own inverse.", "lines": ["f(x) = " + shown], "answer": ans,
		"wrongs": [wrong({"v": Q.new(-k)}, R_SELF_PLUS)], "fillers": far_first(k, [f.b, f.c, -f.b, -f.c, 0])}
	var fin := "So %s." % Answer.text(ans)
	# k is d (= −a) or a (= −d): the other one of the pair is known.
	var known: int = f.a if slot == "d" else f.d
	var letter := "a" if slot == "d" else "d"
	var a_is := N(f.a) if slot == "d" else "k"
	var d_is := "k" if slot == "d" else N(f.d)
	var solved := "k = −%s = −%s%s" % [letter, P(known), "" if known > 0 else " = " + N(k)]
	# f(f(x)) = ((a² + bc)x + b(a + d))/(c(a + d)x + bc + d²) with k in for a or d.
	var sum := "k" + Fmt.plus(known)
	var bc: int = f.b * f.c
	var n: int = f.a * f.a + bc
	var ff: String
	var k_bottom: String
	if slot == "d":
		ff = "(%sx%s)/(%s(%s)x + k²%s)" % [Fmt.lead(n), _times(f.b, sum, false), Fmt.lead(f.c), sum, Fmt.plus(bc)]
		k_bottom = Fmt.lead(f.c) + "x + k"
	else:
		ff = "((k²%s)x%s)/(%s(%s)x%s)" % [Fmt.plus(bc), _times(f.b, sum, false), Fmt.lead(f.c), sum, Fmt.plus(n)]
		k_bottom = rt_bottom(f)
	out.methods = {
		"swap-and-rearrange": method(["Swap x and y and rearrange for y: the inverse of (ax + b)/(cx + d) is (−dx + b)/(cx − a)",
			"For f to be its own inverse the two must be equal, so −d = a: d = −a", "Here a = %s and d = %s, so %s" % [a_is, d_is, solved], fin], ans.values),
		"coefficient-pattern": method(["A function (ax + b)/(cx + d) is its own inverse when d = −a",
			"Here a = %s and d = %s" % [a_is, d_is], solved, fin], ans.values),
		"compose-and-simplify": method(["Put f(x) into f and multiply top and bottom by (%s): f(f(x)) = %s" % [k_bottom, ff],
			"f(f(x)) = x for every x only if the bottom has no x term and the top no number added: %s = 0" % sum,
			"%s, and then f(f(x)) = %s/%s = x" % [solved, Fmt.poly([n, 0]), P(n)], fin], ans.values),
	}
	return out


func u_inverse_as_reflections(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var a: int = f.a
	var b: int = f.b
	var c: int = f.c
	var right := finv(f) + " = −f(−x)"
	var pick := pick_of(right, [tag(finv(f) + " = f(−x)", R_REFLECT), tag(finv(f) + " = −f(x)", R_REFLECT)],
		["f⁻¹(x) = %s = −f(−x)" % rat_text(a, b, -c, a), "f⁻¹(x) = %s = −f(−x)" % rat_text(a, -b, c, -a), "f⁻¹(x) = %s = −f(−x)" % rat_text(-a, b, c, a)])
	var out := {"asked": "Find f⁻¹(x), and show that its graph is the graph of f reflected in the y-axis and then in the x-axis.", "lines": [InverseRuleSituation.rule_line(f)]}
	out.merge(pick)
	if rep == "graph":
		out.graph = graph_of(f)
		out.lines = [InverseRuleSituation.rule_line(f), "The graph of y = f(x) is shown with its asymptotes and the line y = x."]
	# f(−x) = (−ax + b)/(−cx + a) (d = a), and −f(−x) puts the minus on the bottom:
	# (−ax + b)/(cx − a), which is f⁻¹(x) as the swap gives it.
	var f_neg := "f(−x) = (%s)/(%s)" % [Fmt.poly([-a, b]), Fmt.poly([-c, a])]
	var minus := "−f(−x) = −(%s)/(%s) = %s" % [Fmt.poly([-a, b]), Fmt.poly([-c, a]), _neg_out(f)]
	var steps_inv := derive(f, "swap-then-solve")
	var found := "%s, so f⁻¹(x) = %s" % [_collect(f), inv(f)]
	out.methods = {
		"swap-then-solve": method(steps_inv + [minus + ", which is f⁻¹(x)", final(right)], pick.answer.values),
		"graph-check": method(["y = %s; swap x and y, then cross-multiply: %s" % [rt(f), _cross(f)], "Collect the y terms: " + found,
			"Reflecting in the y-axis and then the x-axis gives %s, the same as f⁻¹(x): on the GDC the two graphs lie on top of each other" % minus, final(right)], pick.answer.values),
		"negate-output-or-input": method(["Replace x by −x: " + f_neg, "Negate the output (reflect in the x-axis): " + minus,
			"Find f⁻¹: swap x and y in y = f(x), cross-multiply and collect the y terms: %s, the same as −f(−x)" % found, final(right)], pick.answer.values),
	}
	return out


## −f(−x) for f(x) = (ax + b)/(cx + a), written as f⁻¹ is: (−ax + b)/(cx − a).
static func _neg_out(f: Dictionary) -> String:
	return rat_text(-f.a, f.b, f.c, -f.a)


func u_compose_to_identity(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var a: int = f.a
	var b: int = f.b
	var g := InverseRuleSituation.pair_g(f, s.kind)
	var comp := InverseRuleSituation.pair_composite(f, g)
	var is_inv: bool = s.kind == "inverse"
	var right := "(f∘g)(x) = x: g is the inverse of f" if is_inv else "(f∘g)(x) = %s: g is not the inverse of f" % comp
	var fake := ["(f∘g)(x) = x: g is the inverse of f", "(f∘g)(x) = %s: g is the inverse of f" % comp]
	var pick := pick_of(right, [], [fake[1] if is_inv else fake[0], "(f∘g)(x) = %s: g is not the inverse of f" % Fmt.poly([a, 0]) if is_inv else "(f∘g)(x) = %s: g is not the inverse of f" % Fmt.poly([a, b]),
		"(f∘g)(x) = %s: g is not the inverse of f" % Fmt.poly([1, 1]), "(f∘g)(x) = %s: g is not the inverse of f" % Fmt.poly([1, b + 2]),
		"(f∘g)(x) = %s: g is not the inverse of f" % Fmt.poly([1, b + 3]), "(f∘g)(x) = %s: g is not the inverse of f" % Fmt.poly([a, 1])])
	var out := {"asked": "Find (f∘g)(x) and say whether g is the inverse of f.", "lines": [InverseRuleSituation.rule_line(f), "g(x) = " + g.text]}
	out.merge(pick)
	var put := rt(f).replace("x", "(" + g.text + ")")
	out.methods = {"compose-and-simplify": method(["(f∘g)(x) = %s" % put, "Simplify: (f∘g)(x) = %s" % comp,
		"g is the inverse of f only if this is x" , final(right)], pick.answer.values)}
	return out


func u_identity_value(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var n: int = s.n
	var ans := number("(f∘f⁻¹)(%s) = " % N(n), n)
	var fn = InverseRuleSituation.value(f, Q.new(n))
	var out := {"asked": "Given that f has an inverse, find (f∘f⁻¹)(%s)." % N(n), "lines": [InverseRuleSituation.rule_line(f)], "answer": ans,
		"wrongs": [wrong({"v": Q.new(1)}, R_ONE)] + ([] if fn == null else [wrong({"v": fn}, R_F_ONLY)]),
		"fillers": [{"v": Q.new(0)}, {"v": Q.new(-n)}, {"v": Q.new(n + 1)}]}
	out.methods = {"identity-property": method(["f⁻¹ undoes f, so f(f⁻¹(x)) = x for every x in the domain of f⁻¹",
		"There is no need to find f⁻¹: (f∘f⁻¹)(%s) = %s" % [N(n), N(n)], "So %s." % Answer.text(ans)], ans.values)}
	return out


func u_solve_inverse_equals(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var c0: int = s.c0
	var y: Q = InverseRuleSituation.value(f, Q.new(c0))
	var ans := number("x = ", y)
	var slip = InverseRuleSituation.inverse_value(f, Q.new(c0))
	# f(c0) with its sign changed, f at −c0, a·(c0 + b) for a line (b added before
	# multiplying), c0 itself and −c0, the ones near the key last; f(c0) ± 1 only as a
	# last resort.
	var vals: Array = [y.neg()]
	var at_neg = InverseRuleSituation.value(f, Q.new(-c0))
	if at_neg != null:
		vals.append(at_neg)
	if f.fam == "lin":
		vals.append(Q.new(f.a * (c0 + f.b)))
	vals += [Q.new(c0), Q.new(-c0)]
	var out := {"asked": "Solve f⁻¹(x) = %s." % N(c0), "lines": rule_lines(rep, f), "answer": ans,
		"wrongs": [], "fillers": far_first(y, vals) + [{"v": y.add(1)}, {"v": y.sub(1)}]}
	if slip != null:
		out.wrongs.append(wrong({"v": slip}, R_SOLVE_INVERSE))
	var put := sub_x(rt(f), c0)
	out.methods = {"identity-property": method(["f⁻¹(x) = %s means x = f(%s), because f undoes f⁻¹" % [N(c0), N(c0)],
		"f(%s) = %s = %s" % [N(c0), put, N(y)], "So %s." % Answer.text(ans)], ans.values)}
	return out


func u_function_from_inverse(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var right := "f(x) = " + rt(f)
	var wrongs: Array = []
	var plain: Array = []
	match f.fam:
		"lin":
			# With b = 0 there is no order to get wrong and no sign to keep: no slip.
			if f.b != 0:
				wrongs.append(tag("f(x) = %s(x%s)" % [Fmt.lead(f.a), Fmt.plus(f.b)], R_ORDER))
				wrongs.append(tag("f(x) = " + Fmt.poly([f.a, -f.b]), R_SAME_SIGN))
			# The gradient's sign changed, or the division by a kept instead of undone.
			plain = ["f(x) = " + Fmt.poly([-f.a, f.b]), "f(x) = " + InverseRuleSituation.order_text(f.a, -f.b),
				"f(x) = " + Fmt.poly([-f.a, -f.b]), "f(x) = " + InverseRuleSituation.order_text(-f.a, -f.b)]
		"rat":
			# A sign changed, a and d swapped, or f⁻¹ itself; a b out by one only as a last resort.
			plain = rat_plain([f.a, f.b, f.c, f.d], [[f.a, -f.b, f.c, f.d], [f.a, f.b, -f.c, f.d], [f.d, f.b, f.c, f.a],
				[f.a, f.b, f.c, -f.d], [f.d, -f.b, -f.c, f.a], [-f.a, f.b, f.c, f.d], [f.a, f.b + 1, f.c, f.d]], "f(x) = %s")
		_:
			var base := InverseRuleSituation.base_text(f.base)
			# With q = 0 there is no order to get wrong and no sign to keep: no slip.
			if f.q != 0:
				wrongs.append(tag("f(x) = %s^(x%s)" % [base, Fmt.plus(f.q)], R_ORDER))
				wrongs.append(tag("f(x) = %s^x%s" % [base, Fmt.plus(-f.q)], R_SAME_SIGN))
				plain = ["f(x) = %s^(x%s)" % [base, Fmt.plus(-f.q)], "f(x) = %s^(−x)%s" % [base, Fmt.plus(f.q)], "f(x) = %s^x" % base]
			else:
				plain = ["f(x) = %s^(−x)" % base, "f(x) = −%s^x" % base, "f(x) = %s^(x + 1)" % base]
	var pick := pick_of(right, wrongs, plain)
	var steps_back := InverseRuleSituation.rule_steps(f)
	var lines: Array = ["f⁻¹(x) = " + inv(f)]
	if rep == "words" and not steps_back.is_empty():
		var undo_words := _undo(f)
		lines = ["f⁻¹: %s." % undo_words]
	var out := {"asked": "Find f(x).", "lines": lines, "titles": {"graph-reflection": "Reflect the graph of f⁻¹ in y = x"}}
	out.merge(pick)
	var swap := "swap x and y: x = " + inv(f).replace("x", "y")
	# y from x = f⁻¹(y): for a rational rule, cross-multiplied and its y terms collected.
	var solve := "Solve for y: y = " + rt(f)
	if f.fam == "rat":
		var g := {"fam": "rat", "a": -f.d, "b": f.b, "c": f.c, "d": -f.a}
		solve = "Solve for y: %s, so %s and y = %s" % [_cross(g), _collect(g), rt(f)]
	var pt := check_point(f)
	var check := "" if pt.is_empty() else ". Check: %s is on the graph of f⁻¹, and its reflection %s is on the graph of f" % [Fmt.point(pt[1], pt[0]), Fmt.point(pt[0], pt[1])]
	out.methods = {
		"swap-then-solve": method(["Write y = f⁻¹(x) and " + swap, solve, final(right)], pick.answer.values),
		"graph-reflection": method(["Reflecting the graph of f⁻¹ in y = x swaps x and y: x = " + inv(f).replace("x", "y"), solve + check, final(right)], pick.answer.values),
	}
	# A rational rule is no chain of steps, so it has no working by undoing them.
	if not steps_back.is_empty():
		out.methods["reverse-operations"] = method(["f⁻¹ does: %s" % _undo(f), "f undoes that, in reverse order: %s" % ", then ".join(steps_back), final(right)], pick.answer.values)
	return out


## A point (x, f(x)) with whole coordinates, for checking a reflection: [x, f(x)], or []
## when no small whole x gives one.
static func check_point(f: Dictionary) -> Array:
	for x0 in [1, 2, 0, -1, 3, -2]:
		var v = InverseRuleSituation.value(f, Q.new(x0))
		if f.fam == "exp" and (x0 == 1 or x0 == 0):
			# e^1 is no whole number, so e is checked at 0.
			v = null if str(f.base) == "e" and x0 == 1 else Q.new((1 if x0 == 0 else int(f.base)) + f.q)
		if v != null and v.is_int() and not v.eq(x0):
			return [Q.new(x0), v]
	return []


func u_inverse_asymptotes(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var right: String
	var bad: Array = []
	var plain: Array = []
	var f_asy: String
	if f.fam == "rat":
		var xa := Q.new(f.a, f.c)
		var ya := Q.new(-f.d, f.c)
		right = "x = %s and y = %s" % [N(xa), N(ya)]
		# f's own asymptotes once only: "y = a/c and x = −d/c" is the same pair as the key.
		bad.append(tag("x = %s and y = %s" % [N(ya), N(xa)], R_EXCLUDED))
		bad.append(tag("x = %s and y = %s" % [N(xa), N(ya.neg())], R_MINUS))
		plain = ["x = %s and y = %s" % [N(xa.neg()), N(ya.neg())], "x = %s and y = %s" % [N(xa.neg()), N(ya)],
			"x = %s and y = %s" % [N(ya.neg()), N(xa.neg())]]
		f_asy = "x = %s and y = %s" % [N(ya), N(xa)]
	else:
		right = "x = %s" % N(f.q)
		bad.append(tag("y = %s" % N(f.q), R_EXCLUDED))
		plain = ["x = %s" % N(-f.q), "y = %s" % N(-f.q), "x = %s and y = %s" % [N(f.q), N(f.q)], "x = %s" % N(f.q + 1), "y = %s" % N(f.q + 1)]
		f_asy = "y = %s" % N(f.q)
	var pick := pick_of(right, bad, plain)
	var out := {"asked": "Without finding f⁻¹, write down the equation of each asymptote of the graph of f⁻¹.", "lines": [InverseRuleSituation.rule_line(f)]}
	out.merge(pick)
	if rep == "graph":
		out.graph = graph_of(f)
		out.lines = [InverseRuleSituation.rule_line(f), "The graph of y = f(x) is shown with its asymptotes and the line y = x."]
	out.methods = {"swap-asymptotes": method(["f has the asymptote%s %s" % ["s" if f.fam == "rat" else "", f_asy],
		"Reflecting in y = x swaps x and y, so each x = a becomes y = a and each y = b becomes x = b", final(right)], pick.answer.values)}
	return out
