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
				return ["For (ax + b)/(cx + d) the inverse is (dx − b)/(−cx + a): swap a and d, change the signs of b and c",
					"Here a = %s, b = %s, c = %s, d = %s" % [N(f.a), N(f.b), N(f.c), N(f.d)]]
			var cross := "x(%s) = %s" % [Fmt.poly([f.c, f.d]).replace("x", "y"), Fmt.poly([f.a, f.b]).replace("x", "y")]
			return [y + ", swap x and y, then cross-multiply: " + cross,
				"Collect the y terms: y(%s) = %s" % [Fmt.poly([f.c, -f.a]), Fmt.poly([-f.d, f.b])], "Divide by the bracket to get y"]
		"root":
			var sq := "x²" if f.r == 0 else Fmt.factor(f.r) + "²"
			if angle == "swap-domain-range":
				return [swapped, "Isolate the root and square: %s = %s, so y = %s" % [sq, Fmt.poly([f.p, f.q]).replace("x", "y"), inv(f)],
					"The domain of f⁻¹ is the range of f: x ≥ %s" % N(f.r)]
			return [y, swapped, "Isolate the root and square: %s = %s" % [sq, Fmt.poly([f.p, f.q]).replace("x", "y")]]
		"rquad":
			var under := "x" if f.k == 0 else "x" + Fmt.plus(-f.k)
			var side := "above" if f.dir == "≥" else "below"
			var yh := "y" + Fmt.plus(-f.h) if f.h != 0 else "y"
			if angle == "graph-check":
				return ["The graph is the %s of a parabola, so f is one-to-one and f⁻¹ is its reflection in y = x" % ("right half" if f.dir == "≥" else "left half"),
					"The reflection has y %s %s, so it takes the %s root: y = %s %s √(%s)" % [f.dir, N(f.h), "positive" if f.dir == "≥" else "negative", N(f.h), "+" if f.dir == "≥" else "−", under]]
			if angle == "restrict-at-vertex":
				return ["x %s %s is one side of the vertex, so f is one-to-one" % [f.dir, N(f.h)], swapped + ", so (%s)² = %s" % [yh, under],
					"y %s %s on this domain, so %s is %s: %s = %s√(%s)" % [f.dir, N(f.h), yh, "positive" if f.dir == "≥" else "negative", yh, "" if f.dir == "≥" else "−", under]]
			return [y, swapped + ", so (%s)² = %s" % [yh, under],
				"%s = ±√(%s), and x %s %s puts f⁻¹ %s y = %s, so take the %s root" % [yh, under, f.dir, N(f.h), side, N(f.h), "positive" if f.dir == "≥" else "negative"]]
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


static func rat_text(a: int, b: int, c: int, d: int) -> String:
	return InverseRuleSituation.frac(Fmt.poly([a, b]), Fmt.poly([c, d]))


# ── The unknowns ─────────────────────────────────────────────

func u_inverse_linear(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var a: int = f.a
	var b: int = f.b
	var right := finv(f)
	var order := InverseRuleSituation.order_text(a, b)
	var pick := choose(right, [tag("f⁻¹(x) = 1/(%s)" % rt(f), R_RECIPROCAL), tag("f⁻¹(x) = " + order, R_ORDER)],
		[finv(InverseRuleSituation.lin_rule(a, -b)), finv(InverseRuleSituation.lin_rule(-a, b)), finv(InverseRuleSituation.lin_rule(a, b + 1)), "f⁻¹(x) = %s(x%s)" % [Fmt.lead(a), Fmt.plus(-b)]])
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
	var pick := choose(right, [], ["f⁻¹(x) = " + rat_text(d, b, -c, a), "f⁻¹(x) = " + rat_text(d, -b, c, a), "f⁻¹(x) = " + rat_text(a, -b, -c, d),
		"f⁻¹(x) = " + rat_text(d, -b, -c, -a), "f⁻¹(x) = " + rat_text(d, b + 1, -c, a), "f⁻¹(x) = " + rat_text(b, -d, -c, a)])
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
	var pick := choose(right, [tag("%s, domain x ≥ %s, range y ≥ %s" % [finv(f), N(x0), N(f.r)], R_DOMAIN_OF_F)],
		[slip + dom, flipq + dom, "f⁻¹(x) = " + inv(f) + Fmt.plus(f.r if f.r != 0 else 1) + dom,
		finv({"fam": "root", "p": f.p + 1, "q": f.q, "r": f.r}) + dom])
	var out := {"asked": "Find f⁻¹(x), with its domain and range.", "lines": [InverseRuleSituation.rule_line(f)], "answer": pick.answer}
	out.merge(pick)
	if rep == "graph":
		out.graph = graph_of(f)
		out.lines = [InverseRuleSituation.rule_line(f), "The graph of y = f(x) is shown with the line y = x."]
	var tail := ["The domain of f⁻¹ is the range of f, y ≥ %s, so x ≥ %s" % [N(f.r), N(f.r)]]
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
	var pick := choose(right, [tag("f⁻¹(x) = " + pm_text, R_PM), tag(flip, R_PM)],
		[finv({"fam": "rquad", "h": k if k != 0 else 1, "k": h, "dir": f.dir}), finv({"fam": "rquad", "h": -h, "k": k, "dir": f.dir}),
		finv({"fam": "rquad", "h": h, "k": -k, "dir": f.dir}), "f⁻¹(x) = (x%s)²%s" % [Fmt.plus(-k), Fmt.plus(h)]])
	var out := {"asked": "Find f⁻¹(x).", "lines": [InverseRuleSituation.rule_line(f)]}
	out.merge(pick)
	if rep == "graph":
		out.graph = graph_of(f)
		out.lines = [InverseRuleSituation.rule_line(f), "The graph of y = f(x) is shown with the line y = x."]
	out.methods = methods(f, _angles("inverse-restricted-quadratic"), final(right), pick.answer)
	return out


func u_inverse_exponential(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var q: int = f.q
	var right := "%s, domain x > %s" % [finv(f), N(q)]
	var pick := choose(right, [tag("%s, domain all real x" % finv(f), R_DOMAIN_OF_F)],
		["%s, domain x > %s" % [finv({"fam": "exp", "base": f.base, "q": -q}), N(-q)] if q != 0 else "f⁻¹(x) = 1/%s^x, domain x > 0" % InverseRuleSituation.base_text(f.base),
			"%s, domain x > %s" % ["f⁻¹(x) = %s^x%s" % [InverseRuleSituation.base_text(f.base), Fmt.plus(-q) if q != 0 else ""], N(q)],
			"%s, domain x ≥ %s" % [finv(f), N(q)]])
	var out := {"asked": "Find f⁻¹(x) and its domain.", "lines": [InverseRuleSituation.rule_line(f)]}
	out.merge(pick)
	var tail := ["The domain of f⁻¹ is the range of f, y > %s, so x > %s" % [N(q), N(q)]]
	var out_methods := {}
	for a in _angles("inverse-exponential"):
		out_methods[a] = method(derive(f, a).slice(0, 3) + tail + [final(right)], pick.answer.values)
	out.methods = out_methods
	return out


func u_inverse_domain(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var right := InverseRuleSituation.inv_domain_text(f)
	var pick := choose(right, [tag(InverseRuleSituation.domain_text(f), R_DOMAIN_OF_F)], cond_variants(right))
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
	var pick := choose(right, [tag(InverseRuleSituation.range_text(f), R_DOMAIN_OF_F)], cond_variants(right))
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
	var pick := choose(right, [tag("domain x ≠ %s, range y ≠ %s" % [N(ya), N(xa)], R_EXCLUDED)],
		["domain x ≠ %s, range y ≠ %s" % [N(ya.neg()), N(xa.neg())], "domain x ≠ %s, range y ≠ %s" % [N(xa), N(ya.neg())], "domain x ≠ %s, range y ≠ %s" % [N(xa.neg()), N(ya)]])
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
		"wrongs": [wrong({"v": Q.new(0)}, R_Y_INTERCEPT)], "generic": [{"v": Q.new(-h)}, {"v": Q.new(f.k)}, {"v": Q.new(h + 1)}, {"v": Q.new(h - 1)}]}
	if rep == "graph":
		out.graph = graph_of(f)
		out.lines = ["f(x) = %s" % rt(f), "The graph of y = f(x) is shown."]
	var b: Q = co[1]
	var a: Q = co[2]
	var final_text := "So %s." % Answer.text(ans)
	out.methods = {
		"restrict-at-vertex": method(["f is one-to-one on one side of its vertex, so k is the x-coordinate of the vertex",
			"x = −b ÷ 2a = −(%s) ÷ %s = %s" % [N(b), N(a.mul(2)), N(h)], final_text], ans.values),
		"horizontal-line": method(["A horizontal line cuts the graph twice, one point either side of the vertex, so f needs a domain that stays on one side",
			"The vertex is at x = −b ÷ 2a = %s" % N(h), "Take the domain x %s %s: %s" % [f.dir, N(h), final_text.trim_prefix("So ").trim_suffix(".")], final_text], ans.values),
	}
	return out


func u_show_self_inverse(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var a: int = f.a
	var b: int = f.b
	var c: int = f.c
	var d: int = f.d
	var right := finv(f) + ", which is f(x)"
	var pick := choose(right, [], [finv(f) + ", which is not f(x)", "f⁻¹(x) = %s, which is not f(x)" % rat_text(d, b, -c, a), "f⁻¹(x) = %s, which is f(x)" % rat_text(d, -b, c, a)])
	var out := {"asked": "Find f⁻¹(x), and show that f is its own inverse.", "lines": [InverseRuleSituation.rule_line(f)]}
	out.merge(pick)
	var swapped := "Swap x and y: x = " + rt(f).replace("x", "y")
	var rearranged := derive(f, "swap-then-solve")
	var compose := ["f(f(x)) = " + _ff(f), "Multiply top and bottom by (%s) and simplify: f(f(x)) = x" % Fmt.poly([c, d])]
	var same := "The inverse is the same expression as f(x)"
	var methods := {
		"swap-then-solve": method(rearranged + [same, final(right)], pick.answer.values),
		"swap-and-rearrange": method([swapped + ", cross-multiply and collect the y terms", "y(%s) = %s" % [Fmt.poly([c, -a]), Fmt.poly([-d, b])], same, final(right)], pick.answer.values),
		"coefficient-pattern": method(["For (ax + b)/(cx + d) the inverse is (dx − b)/(−cx + a)", "Here d = −a, so the inverse is (−ax − b)/(−cx + a) = (ax + b)/(cx − a)", same, final(right)], pick.answer.values),
		"compose-and-simplify": method(compose + [same, final(right)], pick.answer.values),
	}
	out.methods = methods
	return out


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
	var out := {"asked": "Find the value of k for which f is its own inverse.", "lines": ["f(x) = " + shown], "answer": ans,
		"wrongs": [], "generic": [{"v": Q.new(-k)}, {"v": Q.new(f.b)}, {"v": Q.new(f.c)}, {"v": Q.new(k + 1)}]}
	var rule := "(ax + b)/(cx + d)"
	var fin := "So %s." % Answer.text(ans)
	out.methods = {
		"swap-and-rearrange": method(["Swap x and y and rearrange for y: the inverse of %s is %s" % [rule, "(dx − b)/(−cx + a)"],
			"For f to be its own inverse the two must be equal, so d = −a", "Here a = %s and d = %s, so %s" % [N(f.a) if slot == "d" else "k", "k" if slot == "d" else N(f.d), "k = %s" % N(k)], fin], ans.values),
		"coefficient-pattern": method(["A function (ax + b)/(cx + d) is its own inverse when d = −a",
			"Here a = %s and d = %s" % [N(f.a) if slot == "d" else "k", "k" if slot == "d" else N(f.d)], "So k = −(%s) = %s" % [N(f.a) if slot == "d" else N(f.d), N(k)], fin], ans.values),
		"compose-and-simplify": method(["Put f(x) into f and set f(f(x)) = x", "The denominator of f(f(x)) simplifies only when the coefficient of x in the bottom cancels the top: d = −a",
			"So k = %s" % N(k), fin], ans.values),
	}
	return out


func u_inverse_as_reflections(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var a: int = f.a
	var b: int = f.b
	var c: int = f.c
	var right := finv(f) + " = −f(−x)"
	var pick := choose(right, [tag(finv(f) + " = f(−x)", R_REFLECT), tag(finv(f) + " = −f(x)", R_REFLECT)],
		["f⁻¹(x) = %s = −f(−x)" % rat_text(a, b, -c, a), "f⁻¹(x) = %s = −f(−x)" % rat_text(a, -b, c, -a), "f⁻¹(x) = %s = −f(−x)" % rat_text(-a, b, c, a)])
	var out := {"asked": "Find f⁻¹(x), and show that its graph is the graph of f reflected in the y-axis and then in the x-axis.", "lines": [InverseRuleSituation.rule_line(f)]}
	out.merge(pick)
	if rep == "graph":
		out.graph = graph_of(f)
		out.lines = [InverseRuleSituation.rule_line(f), "The graph of y = f(x) is shown with its asymptotes and the line y = x."]
	var neg_in := Fmt.poly([-a, b]).replace("x", "x")
	var minus := "−f(−x) = −(%s)/(%s) = (%s)/(%s)" % [Fmt.poly([-a, b]), Fmt.poly([-c, a]), Fmt.poly([a, -b]), Fmt.poly([-c, a])]
	var steps_inv := derive(f, "swap-then-solve")
	out.methods = {
		"swap-then-solve": method(steps_inv + [minus, final(right)], pick.answer.values),
		"graph-check": method(["Reflecting y = f(x) in y = x gives the graph of f⁻¹",
			"Reflecting in the y-axis changes f(x) to f(−x), then in the x-axis changes it to −f(−x)", minus, final(right)], pick.answer.values),
		"negate-output-or-input": method(["Replace x by −x: f(−x) = (%s)/(%s)" % [Fmt.poly([-a, b]), Fmt.poly([-c, a])],
			"Negate the output (reflect in the x-axis): −f(−x) = " + _neg_out(f), "Compare with f⁻¹(x) = " + inv(f), final(right)], pick.answer.values),
	}
	return out


static func _neg_out(f: Dictionary) -> String:
	return rat_text(f.a, -f.b, -f.c, f.a)


func u_compose_to_identity(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var a: int = f.a
	var b: int = f.b
	var g := InverseRuleSituation.pair_g(f, s.kind)
	var comp := InverseRuleSituation.pair_composite(f, g)
	var is_inv: bool = s.kind == "inverse"
	var right := "(f∘g)(x) = x: g is the inverse of f" if is_inv else "(f∘g)(x) = %s: g is not the inverse of f" % comp
	var fake := ["(f∘g)(x) = x: g is the inverse of f", "(f∘g)(x) = %s: g is the inverse of f" % comp]
	var pick := choose(right, [], [fake[1] if is_inv else fake[0], "(f∘g)(x) = %s: g is not the inverse of f" % Fmt.poly([a, 0]) if is_inv else "(f∘g)(x) = %s: g is not the inverse of f" % Fmt.poly([a, b]),
		"(f∘g)(x) = %s: g is not the inverse of f" % Fmt.poly([1, 1]), "(f∘g)(x) = %s: g is not the inverse of f" % Fmt.poly([1, b + 2])])
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
		"wrongs": [wrong({"v": Q.new(1)}, R_ONE)], "generic": [{"v": fn if fn != null else Q.new(n + 1)}, {"v": Q.new(0)}, {"v": Q.new(-n)}, {"v": Q.new(n + 1)}]}
	out.methods = {"identity-property": method(["f⁻¹ undoes f, so f(f⁻¹(x)) = x for every x in the domain of f⁻¹",
		"There is no need to find f⁻¹: (f∘f⁻¹)(%s) = %s" % [N(n), N(n)], "So %s." % Answer.text(ans)], ans.values)}
	return out


func u_solve_inverse_equals(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var c0: int = s.c0
	var y: Q = InverseRuleSituation.value(f, Q.new(c0))
	var ans := number("x = ", y)
	var slip = InverseRuleSituation.inverse_value(f, Q.new(c0))
	var out := {"asked": "Solve f⁻¹(x) = %s." % N(c0), "lines": rule_lines(rep, f), "answer": ans,
		"wrongs": [], "generic": [{"v": Q.new(c0)}, {"v": y.neg()}, {"v": y.add(1)}, {"v": y.sub(1)}]}
	if slip != null:
		out.wrongs.append(wrong({"v": slip}, R_SOLVE_INVERSE))
	var put := rt(f).replace("x", Fmt.paren(c0))
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
			wrongs.append(tag("f(x) = %s(x%s)" % [Fmt.lead(f.a), Fmt.plus(f.b)] if f.b != 0 else "f(x) = %s" % Fmt.poly([f.a, 1]), R_ORDER))
			plain = ["f(x) = " + Fmt.poly([f.a, -f.b]), "f(x) = " + Fmt.poly([-f.a, f.b]), "f(x) = " + Fmt.poly([f.a, f.b + 1]), "f(x) = " + Fmt.poly([f.a + 1, f.b]),
				"f(x) = " + Fmt.poly([-f.a, -f.b])]
		"rat":
			plain = ["f(x) = " + rat_text(f.a, -f.b, f.c, f.d), "f(x) = " + rat_text(f.a, f.b, -f.c, f.d), "f(x) = " + rat_text(f.d, f.b, f.c, f.a),
				"f(x) = " + rat_text(f.a, f.b, f.c, -f.d), "f(x) = " + rat_text(f.a, f.b + 1, f.c, f.d), "f(x) = " + rat_text(f.d, -f.b, -f.c, f.a)]
		_:
			wrongs.append(tag("f(x) = %s^(x%s)" % [InverseRuleSituation.base_text(f.base), Fmt.plus(f.q)] if f.q != 0 else "f(x) = %s^(x + 1)" % InverseRuleSituation.base_text(f.base), R_ORDER))
			plain = ["f(x) = %s^x%s" % [InverseRuleSituation.base_text(f.base), Fmt.plus(-f.q) if f.q != 0 else Fmt.plus(1)], "f(x) = %s^x%s" % [InverseRuleSituation.base_text(f.base), Fmt.plus(f.q + 1)], "f(x) = %s^x%s" % [InverseRuleSituation.base_text(f.base), Fmt.plus(-f.q - 1)]]
	var pick := choose(right, wrongs, plain)
	var steps_back := InverseRuleSituation.rule_steps(f)
	var lines: Array = ["f⁻¹(x) = " + inv(f)]
	if rep == "words" and not steps_back.is_empty():
		var undo_words := _undo(f)
		lines = ["f⁻¹: %s." % undo_words]
	var out := {"asked": "Find f(x).", "lines": lines}
	out.merge(pick)
	var swapped := "y = %s, swap x and y: x = %s" % [inv(f), inv(f).replace("x", "y")]
	out.methods = {
		"swap-then-solve": method(["Write y = f⁻¹(x) and swap x and y: x = %s" % inv(f).replace("x", "y"), "Solve for y: y = " + rt(f), final(right)], pick.answer.values),
		"reverse-operations": method(["f⁻¹ does: %s" % _undo(f), "f undoes that, in reverse order: %s" % ", then ".join(steps_back) if not steps_back.is_empty() else "f undoes the steps of f⁻¹ in reverse order", final(right)], pick.answer.values),
		"graph-reflection": method(["The graph of f is the graph of f⁻¹ reflected in y = x", "Reflecting swaps x and y, which gives " + rt(f).replace("x", "x"), final(right)], pick.answer.values),
	}
	return out


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
		bad.append(tag("x = %s and y = %s" % [N(ya), N(xa)], R_EXCLUDED))
		plain = ["y = %s and x = %s" % [N(xa), N(ya)], "x = %s and y = %s" % [N(xa.neg()), N(ya.neg())], "x = %s and y = %s" % [N(xa), N(ya.neg())]]
		f_asy = "x = %s and y = %s" % [N(ya), N(xa)]
	else:
		right = "x = %s" % N(f.q)
		bad.append(tag("y = %s" % N(f.q), R_EXCLUDED))
		plain = ["x = %s" % N(-f.q), "y = %s" % N(-f.q), "x = %s and y = %s" % [N(f.q), N(f.q)]]
		f_asy = "y = %s" % N(f.q)
	var pick := choose(right, bad, plain)
	var out := {"asked": "Without finding f⁻¹, write down the equation of each asymptote of the graph of f⁻¹.", "lines": [InverseRuleSituation.rule_line(f)]}
	out.merge(pick)
	if rep == "graph":
		out.graph = graph_of(f)
		out.lines = [InverseRuleSituation.rule_line(f), "The graph of y = f(x) is shown with its asymptotes and the line y = x."]
	out.methods = {"swap-asymptotes": method(["f has the asymptote%s %s" % ["s" if f.fam == "rat" else "", f_asy],
		"Reflecting in y = x swaps x and y, so each x = a becomes y = a and each y = b becomes x = b", final(right)], pick.answer.values)}
	return out
