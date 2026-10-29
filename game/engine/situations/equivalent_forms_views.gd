class_name EquivalentFormsViews
extends ExtensionViews
## The views on the `fn-link-equivalent-forms` situation: one builder per unknown of
## fn-link-equivalent-forms (FAL-459). Every unknown also plays as true-false-reason and
## method-pick.

const MP := ["true-false-reason", "method-pick"]


func needs() -> Dictionary:
	return {
		"form-for-feature": {"form": "quad"},
		"identity-constants": {"form": "identity"},
		"same-or-not": {"form": "same"},
		"log-law-check": {"form": "law"},
		"cos2x-form": {"form": "cos2x"},
		"power-form-first": {"form": "power"},
		"roots-from-vertex-form": {"form": "vroots"},
	}


func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	if rep == "graph":
		n.graph = true
	return n


func extra() -> Dictionary:
	var out := {}
	for u in needs():
		out[u] = MP
	return out


static func pick(name: String, why: String) -> Dictionary:
	return {"name": name, "why": why}


# ── form-for-feature ─────────────────────────────────────────

static func features(c: Q, r1: Q, r2: Q, h: Q, k: Q) -> Dictionary:
	return {"c": c, "r1": r1, "r2": r2, "h": h, "k": k}


func u_form_for_feature(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var vals := features(s.c, s.p, s.q, s.h, s.k)
	var ans := Answer.make("features", vals)
	var final := "So %s." % Answer.text(ans)
	var gen := Fmt.general(s.a, s.b, s.c)
	var fac := Fmt.factorised(s.a, s.p, s.q)
	var ver := Fmt.vertex(s.a, s.h, s.k)
	var forms := "f(x) = %s = %s = %s" % [gen, fac, ver]
	var out := {"asked": "Read the y-intercept, the roots and the vertex, each from the form that shows it.", "lines": ["One quadratic in three forms: " + forms + "."],
		"given": {"a": s.a.key(), "b": s.b.key(), "c": s.c.key(), "p": s.p.key(), "q": s.q.key(), "h": s.h.key(), "k": s.k.key()}, "answer": ans}
	if rep == "graph":
		out.graph = QuadraticViews.graph(s, [])
		out.lines = ["The graph of y = f(x) is shown, and its three forms: " + forms + "."]
	var yint := "General form: f(0) = %s" % N(s.c)
	var roots := "Factorised form: f(x) = 0 at x = %s and x = %s" % [N(s.p), N(s.q)]
	var cs := QuadraticViews.cs_steps(s.a, s.b, s.c)
	out.methods = {
		"complete-square": method([yint, roots, "Complete the square on %s: %s, so the vertex is %s" % [gen, Fmt.vertex(s.a, cs.h, cs.k), Fmt.point(cs.h, cs.k)], final], vals),
		"compare-coefficients": method([yint + "; " + roots.to_lower(),
			"a(x − h)² + k = ax² − 2ahx + ah² + k. Compare with %s: −2 × %s × h = %s, so h = %s" % [gen, P(s.a), N(s.b), N(s.h)],
			"%s × %s² + k = %s, so k = %s" % [N(s.a), P(s.h), N(s.c), N(s.k)], final], vals),
		"vertex-first": method(["Vertex: x = −b/(2a) = %s/%s = %s, and f(%s) = %s" % [N(s.b.neg()), P(s.a.mul(2)), N(s.h), N(s.h), N(s.k)], roots + "; " + yint.to_lower(), final], vals),
		"factorise": method(["Factorise: %s = %s, so the roots are %s and %s" % [gen, fac, N(s.p), N(s.q)],
			"The vertex is midway between them: x = (%s + %s)/2 = %s, and f(%s) = %s" % [N(s.p), N(s.q), N(s.h), N(s.h), N(s.k)], yint, final], vals),
	}
	out.wrongs = [wrong(features(s.c, s.p, s.q, s.h, s.c.sub(s.h.sq())), "SL2.6.complete-square#1"),
		wrong(features(s.c, s.p.neg(), s.q.neg(), s.h, s.k), "SL2.6.factorised-form#0"),
		wrong(features(s.p.mul(s.q), s.p, s.q, s.h, s.k), "SL2.6.factorised-form#2")]
	out.generic = [features(s.c, s.p, s.q, s.h.neg(), s.k), features(s.k, s.p, s.q, s.h, s.c), features(s.c, s.p, s.q, s.h, s.k.neg())]
	out.pick_wrongs = [pick("Read the vertex off the factorised form", "that form shows the roots, not the vertex"),
		pick("Read the roots off the general form", "the general form shows only the y-intercept c"),
		pick("Put x = 1 into each form", "that checks the forms agree but finds no feature")]
	return out


# ── identity-constants ───────────────────────────────────────

func u_identity_constants(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("named", {"v0": s.p, "v1": s.q}, {"names": ["p", "q"]})
	var final := "So %s." % Answer.text(ans)
	var left := Fmt.general(1, s.b, s.c)
	var sq := "(x%s)²" % Fmt.plus(s.p)
	return {"asked": "Find p and q.", "lines": ["%s ≡ (x + p)² + q" % left], "given": {"b": s.b.key(), "c": s.c.key()}, "answer": ans,
		"methods": {
			"complete-square": method(["Half of %s is %s: %s = %s − %s" % [N(s.b), N(s.p), Fmt.poly([1, s.b, 0]), sq, N(s.p.sq())],
				"%s = %s − %s%s = %s%s" % [left, sq, N(s.p.sq()), Fmt.plus(s.c), sq, Fmt.plus(s.q)], final], ans.values),
			"compare-coefficients": method(["(x + p)² + q = x² + 2px + p² + q",
				"≡ means the coefficients match: 2p = %s, so p = %s; p² + q = %s, so q = %s − %s = %s" % [N(s.b), N(s.p), N(s.c), N(s.c), N(s.p.sq()), N(s.q)], final], ans.values),
			"substitute-values": method(["≡ holds for every x. x = 0: %s = p² + q. x = 1: %s = (1 + p)² + q" % [N(s.c), N(s.b.add(s.c).add(1))],
				"Subtract: %s = 1 + 2p, so p = %s" % [N(s.b.add(1)), N(s.p)], "q = %s − %s = %s" % [N(s.c), N(s.p.sq()), N(s.q)], final], ans.values),
		},
		"wrongs": [wrong({"v0": s.p, "v1": s.c}, "SL2.6.complete-square#0"), wrong({"v0": s.p.neg(), "v1": s.q}, "SL2.6.complete-square#2")],
		"generic": [{"v0": s.b, "v1": s.c.sub(s.b.sq())}, {"v0": s.p, "v1": s.c.add(s.p.sq())}, {"v0": s.p.neg(), "v1": s.c}],
		"pick_wrongs": [pick("Solve x² + bx + c = 0", "≡ is an identity to match, not an equation to solve"),
			pick("Put in x = 0 only", "one value gives one equation, and there are two unknowns"),
			pick("Read p as b", "the x term is 2px, so p is half of b")]}


# ── same-or-not ──────────────────────────────────────────────

## The two expressions of a pair, and whether they are one object.
static func pair_of(s: Dictionary) -> Dictionary:
	var m: int = s.m.n
	var n: int = s.n.n
	match s.pair:
		"log-sub":
			return {"x": "ln %d − ln %d" % [m * n, n], "y": "ln %d" % m, "same": true}
		"log-div":
			return {"x": "ln %d / ln %d" % [m * n, n], "y": "ln %d" % m, "same": false}
		"log-pow":
			return {"x": "2 ln %d" % m, "y": "ln %d" % (m * m), "same": true}
		"log-add":
			return {"x": "ln %d + ln %d" % [m, n], "y": "ln %d" % (m + n), "same": false}
		"sq-sum":
			return {"x": "(x + %d)²" % m, "y": "x² + %d" % (m * m), "same": false}
	return {"x": "(x + %d)(x − %d)" % [m, m], "y": "x² − %d" % (m * m), "same": true}


func u_same_or_not(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: int = s.m.n
	var n: int = s.n.n
	var pr := pair_of(s)
	var opts: Array
	var refs := {}
	var law := ""
	var check := ""
	match s.pair:
		"log-sub":
			law = "ln a − ln b = ln(a/b), so %s = ln(%d/%d) = %s" % [pr.x, m * n, n, pr.y]
			opts = ["The same: " + law, "Not the same: a log law changes the value", "Not the same: %s = ln %d" % [pr.x, m * n - n], "The same only to 3 decimal places"]
			check = "%s ≈ %s and %s ≈ %s" % [pr.x, Fmt.sf(log(m * n) - log(n)), pr.y, Fmt.sf(log(m))]
		"log-div":
			law = "%s ≈ %s, but %s ≈ %s" % [pr.x, Fmt.sf(log(m * n) / log(n)), pr.y, Fmt.sf(log(m))]
			opts = ["Not the same: " + law, "The same: ln a/ln b = ln(a/b)", "The same: both are about %s" % Fmt.sf(log(m)), "Not the same: %s = ln %d" % [pr.x, m * n - n]]
			refs[opts[1]] = "SL1.7.log-laws#1"
			check = law
		"log-pow":
			law = "n ln a = ln a^n, so %s = ln %d² = %s" % [pr.x, m, pr.y]
			opts = ["The same: " + law, "Not the same: %s = ln %d" % [pr.x, 2 * m], "Not the same: %s = (ln %d)²" % [pr.x, m], "The same only to 3 decimal places"]
			check = "%s ≈ %s and %s ≈ %s" % [pr.x, Fmt.sf(2 * log(m)), pr.y, Fmt.sf(log(m * m))]
		"log-add":
			law = "ln a + ln b = ln(ab), so %s = ln %d, not %s" % [pr.x, m * n, pr.y]
			opts = ["Not the same: " + law, "The same: ln a + ln b = ln(a + b)", "The same: both are about %s" % Fmt.sf(log(m + n)), "Not the same: %s = ln %d" % [pr.x, absi(m - n)]]
			check = "%s ≈ %s, but %s ≈ %s" % [pr.x, Fmt.sf(log(m) + log(n)), pr.y, Fmt.sf(log(m + n))]
		"sq-sum":
			law = "(x + %d)² = x² + %dx + %d, which is x² + %d only at x = 0" % [m, 2 * m, m * m, m * m]
			opts = ["Not the same: " + law, "The same: they agree when x = 0", "The same: each term can be squared", "Not the same: they never agree"]
			refs[opts[1]] = "SL1.6.identity-constants#0"
			check = "x = 0 gives %d and %d, but x = 1 gives %d and %d" % [m * m, m * m, (1 + m) * (1 + m), 1 + m * m]
		_:
			law = "(x + %d)(x − %d) = x² − %dx + %dx − %d = x² − %d for every x" % [m, m, m, m, m * m, m * m]
			opts = ["The same: " + law, "Not the same: (x + %d)(x − %d) = x² + %d" % [m, m, m * m], "Not the same: they agree only when x = 0", "The same only when x = %d" % m]
			check = "x = 1 gives %d and %d; x = 2 gives %d and %d" % [(1 + m) * (1 - m), 1 - m * m, (2 + m) * (2 - m), 4 - m * m]
	var ans := Answer.make("choice", {"v": opts[0]}, {"options": opts})
	var final := "So: %s." % Answer.text(ans)
	var lines := ["%s   and   %s" % [pr.x, pr.y]]
	if rep == "words":
		lines = ["Is %s the same %s as %s?" % [pr.x, "number" if s.pair.begins_with("log") else "expression", pr.y]]
	var sub_end := "They differ, so they are not the same" if not pr.same else "They agree here, but values that agree can't prove two forms are equal; the law can"
	return {"asked": "Are these the same object? Choose the answer and its reason.", "lines": lines, "given": export(s), "answer": ans,
		"wrongs": opts.filter(func(o): return refs.has(o)).map(func(o): return wrong({"v": o}, refs[o])),
		"generic": opts.slice(1).filter(func(o): return not refs.has(o)).map(func(o): return {"v": o}),
		"methods": {
			"substitute-values": method(["Work both out: " + check, sub_end, final], ans.values),
			"combine": method(["Use the law: " + law if pr.same else "Combine: " + law, final], ans.values),
			"gdc-check": method(["On the GDC: " + check, "The law agrees: " + law if pr.same else "So they differ", final], ans.values),
		},
		"pick_wrongs": [pick("Compare the numbers inside", "ln 12/ln 3 has 12 and 3 in it, but is not ln 4"),
			pick("Check that both have the same letters", "the same letters don't make the same value"),
			pick("Cancel the logs", "ln is a function, not a factor to cancel")]}


# ── log-law-check ────────────────────────────────────────────

const CLAIM := {
	"add": ["log(a + b) = log a + log b", false, "log(ab) = log a + log b"],
	"sq": ["(log a)² = 2 log a", false, "log(a²) = 2 log a"],
	"sub": ["log a − log b = log(a/b)", true, "it is the quotient law"],
	"pow": ["log(a^n) = n log a", true, "it is the power law"],
	"div": ["log(a/b) = log a / log b", false, "log(a/b) = log a − log b"],
}


## The two sides of a claim at a = m, b = n (n = 2 for a^n), each as base-10 logs.
static func claim_sides(claim: String, m: float, n: float) -> Array:
	var lg := func(x: float) -> float: return log(x) / log(10.0)
	match claim:
		"add":
			return [lg.call(m + n), lg.call(m) + lg.call(n)]
		"sq":
			return [pow(lg.call(m), 2), 2 * lg.call(m)]
		"sub":
			return [lg.call(m) - lg.call(n), lg.call(m / n)]
		"pow":
			return [lg.call(pow(m, 2)), 2 * lg.call(m)]
	return [lg.call(m / n), lg.call(m) / lg.call(n)]


func u_log_law_check(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Array = CLAIM[s.claim]
	var right: String = ("True: " if c[1] else "False: ") + c[2]
	var opts: Array
	var refs := {}
	match s.claim:
		"add":
			opts = [right, "True", "False: log(a + b) = log a × log b", "True, but only when a = b"]
			refs["True"] = "SL1.7.log-laws#0"
		"sq":
			opts = [right, "True", "False: (log a)² = log(2a)", "True, but only when a > 1"]
			refs["True"] = "SL1.7.log-laws#2"
		"sub":
			opts = [right, "False: log a − log b = log(a − b)", "False: log a − log b = log a / log b", "True, but only when a > b"]
		"pow":
			opts = [right, "False: log(a^n) = (log a)^n", "False: log(a^n) = log(na)", "True, but only for whole numbers n"]
		_:
			opts = [right, "True", "False: log(a/b) = log(a − b)", "True, but only when a > b"]
	var ans := Answer.make("choice", {"v": right}, {"options": opts})
	var final := "So: %s." % Answer.text(ans)
	var m: int = s.m.n
	var n: int = s.n.n if s.claim != "pow" else 2
	var sides := claim_sides(s.claim, m, n)
	var at := "a = %d, b = %d" % [m, n] if s.claim != "pow" else "a = %d, n = 2" % m
	var test := "With %s: the left side is %s and the right side is %s" % [at, Fmt.sf(sides[0]), Fmt.sf(sides[1])]
	var verdict: String = "They agree, and the law holds for every value, not just these" if c[1] else "They differ, so the claim is false. The law that holds: " + c[2]
	var lines := ["Claim: " + c[0]]
	if rep == "words":
		lines = ["A student writes this log law in their notes: %s." % c[0]]
	return {"asked": "Is the claim true? Choose the answer and the law that is actually true.", "lines": lines, "given": export(s), "answer": ans,
		"wrongs": opts.filter(func(o): return refs.has(o)).map(func(o): return wrong({"v": o}, refs[o])),
		"generic": opts.slice(1).filter(func(o): return not refs.has(o)).map(func(o): return {"v": o}),
		"methods": {
			"combine": method(["Test it with numbers: " + test, verdict, final], ans.values),
			"gdc-check": method(["On the GDC, " + test.substr(0, 1).to_lower() + test.substr(1), verdict, final], ans.values),
		},
		"pick_wrongs": [pick("Check that both sides have the same letters", "the same letters don't make the same value"),
			pick("Expand the brackets", "log(a + b) is a function of a + b, not log times (a + b)"),
			pick("Cancel the logs", "log is a function, not a factor to cancel")]}


# ── cos2x-form ───────────────────────────────────────────────

## "3 sin x", "− sin x": a term of the equation.
static func trig_term(c: Q, fn: String, first: bool) -> String:
	var mag := "" if c.abs_q().eq(1) else c.abs_q().text() + " "
	if first:
		return ("−" if c.sign() < 0 else "") + mag + fn + " x"
	return (" − " if c.sign() < 0 else " + ") + mag + fn + " x"


static func equation(s: Dictionary) -> String:
	return "cos 2x%s%s = 0" % [trig_term(s.B, s.fn, false), Fmt.plus(s.C) if not s.C.is_zero() else ""]


## The quadratic in f(x) it becomes, and its factors.
static func quad_in_f(s: Dictionary) -> Array:
	var f: String = s.fn + " x"
	var sq: String = s.fn + "²x"
	var r1: Q = s.r1
	var r2: Q = s.r2
	var b: Q = r1.add(r2).mul(-2)
	var c: Q = r1.mul(r2).mul(2)
	var quad := "2%s%s%s = 0" % [sq, trig_term(b, s.fn, false), Fmt.plus(c) if not c.is_zero() else ""]
	# 2(f − r1)(f − r2), with the 2 taken into the bracket of a half.
	var f1 := "(2 %s%s)" % [f, Fmt.plus(r1.mul(-2))] if not r1.is_int() else ("2 " + f if r1.is_zero() else "2(%s%s)" % [f, Fmt.plus(r1.neg())])
	var f2 := f if r2.is_zero() else "(%s%s)" % [f, Fmt.plus(r2.neg())]
	return [quad, f1 + f2 + " = 0"]


static func solve_line(s: Dictionary) -> String:
	var parts: Array = []
	for r in [s.r1, s.r2]:
		var xs := EquivalentFormsSituation.solutions(s.fn, [r])
		if xs.is_empty():
			parts.append("%s x = %s has no solution" % [s.fn, N(r)])
		else:
			parts.append("%s x = %s gives x = %s" % [s.fn, N(r), ", ".join(xs.map(func(x): return Fmt.pi(x)))])
	return "; ".join(parts)


func u_cos2x_form(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sols: Array = s.sols
	var vals := {}
	for i in sols.size():
		vals["a%d" % i] = sols[i]
	var ans := Answer.make("angles", vals, {"n": sols.size()})
	var final := "So %s." % Answer.text(ans)
	var ident := "1 − 2sin²x" if s.fn == "sin" else "2cos²x − 1"
	var other := "2cos²x − 1" if s.fn == "sin" else "1 − 2sin²x"
	var qf := quad_in_f(s)
	var into := "cos 2x = %s turns it into %s" % [ident, qf[0]]
	var fact := "Factorise: %s, so %s x = %s or %s x = %s" % [qf[1], s.fn, N(s.r1), s.fn, N(s.r2)]
	var decimals := ", ".join(sols.map(func(x): return Fmt.sf(x.to_float() * PI)))
	var steps_gdc := ["Graph y = %s for 0 ≤ x ≤ 2π: it crosses the x-axis at x ≈ %s" % [equation(s).replace(" = 0", ""), decimals],
		"Those are decimals, not exact values; the identity shows %s x = %s or %s, the exact angles" % [s.fn, N(s.r1), N(s.r2)], final]
	var out := {"asked": "Solve for 0 ≤ x ≤ 2π, giving exact answers.", "lines": [equation(s) + ", for 0 ≤ x ≤ 2π"], "given": export(s), "answer": ans,
		"methods": {
			"identity-then-factorise": method([into, fact, solve_line(s), final], vals),
			"gdc-graph": method(steps_gdc, vals),
			"pick-cos2-form": method(["The rest of the equation is in %s x, so pick cos 2x = %s; %s would leave two different functions" % [s.fn, ident, other],
				"That gives %s. %s" % [qf[0], fact], solve_line(s), final], vals),
		},
		"pick_wrongs": [pick("Use cos 2x = 2 cos x", "that is not an identity"), pick("Divide through by %s x" % s.fn, "that loses solutions and still leaves cos 2x"),
			pick("Use cos 2x = %s" % other, "that leaves %s x and %s x in one equation" % ["cos" if s.fn == "sin" else "sin", s.fn])]}
	# SL3.6.double-angle-values#1 (cos 2x = 1 − sin²x) gives a quadratic whose roots are
	# not sines of special angles, so its answers are no multiples of π: no option.
	out.generic = _angle_slips(sols)
	return out


## Wrong solution sets the same size as the right one: one angle swapped for its
## partner in the wrong quadrant (π − x, π + x, 2π − x).
static func _angle_slips(sols: Array) -> Array:
	var out: Array = []
	for i in sols.size():
		for f in [func(x: Q) -> Q: return Q.new(1).sub(x), func(x: Q) -> Q: return Q.new(1).add(x), func(x: Q) -> Q: return Q.new(2).sub(x)]:
			var y: Q = f.call(sols[i])
			if y.lt(0) or Q.new(2).lt(y) or sols.any(func(z): return z.eq(y)):
				continue
			var v := {}
			for j in sols.size():
				v["a%d" % j] = y if j == i else sols[j]
			out.append(v)
	return out


# ── power-form-first ─────────────────────────────────────────

static func recip(c: Q, power: Q, first: bool) -> String:
	var body := "%s/x%s" % [N(c), Fmt.sup(power.n)] if c.d == 1 else "1/(%sx%s)" % [N(Q.new(c.d)), Fmt.sup(power.n)]
	return body if first else " + " + body


func u_power_form_first(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k1: Q = s.A
	var p1: Q = s.m.neg()
	var k2: Q = Q.new(1).div(s.B)
	var p2: Q = s.n.neg()
	var d1: Q = k1.mul(p1)
	var d2: Q = k2.mul(p2)
	var vals := {"c0": d1, "e0": p1.sub(1), "c1": d2, "e1": p2.sub(1)}
	var ans := Answer.make("poly", vals, {"powers": [0, 0], "typed_powers": true}, "f′(x) = ")
	var final := "So %s." % Answer.text(ans)
	var shown := "f(x) = %s%s" % [recip(s.A, s.m, true), recip(Q.new(1, s.B.n), s.n, false)]
	var index := "f(x) = " + Fmt.terms([k1, k2], [p1.n, p2.n])
	var dterm := func(k: Q, p: Q) -> String: return "%s × %s%s = %s" % [P(k), P(p), "x" + Fmt.sup(p.n - 1), Fmt.terms([k.mul(p)], [p.n - 1])]
	var quot := func(c: int, d: int, m: int) -> String:
		return "d/dx(%d/(%sx%s)) = (0 − %d × %s)/(%sx%s)² = %s" % [c, "" if d == 1 else str(d), Fmt.sup(m), c, Fmt.terms([Q.new(d * m)], [m - 1]), "" if d == 1 else str(d), Fmt.sup(m), Fmt.terms([Q.new(-c * m, d)], [-m - 1])]
	return {"asked": "Write f(x) as a sum of powers of x, then find f′(x).", "lines": [shown], "given": export(s), "answer": ans,
		"methods": {
			"index-form": method(["Write each term as a power of x: " + index, "Differentiate each term: %s and %s" % [dterm.call(k1, p1), dterm.call(k2, p2)], final], vals),
			"reciprocal-rule": method(["1/x^n = x^(−n), so " + index, "Bring each power down and take 1 off it: %s and %s" % [dterm.call(k1, p1), dterm.call(k2, p2)], final], vals),
			"quotient-rule": method([quot.call(s.A.n, 1, s.m.n), quot.call(1, s.B.n, s.n.n), final], vals),
		},
		"wrongs": [
			# 1/(Bx^n) written as Bx^(−n).
			wrong({"c0": d1, "e0": p1.sub(1), "c1": s.B.mul(p2), "e1": p2.sub(1)}, "SL1.5.zero-negative#2"),
			# The denominator differentiated: A/x^m -> A/(m·x^(m−1)).
			wrong({"c0": k1.div(s.m), "e0": p1.add(1), "c1": d2, "e1": p2.sub(1)}, "SL5.3.negative-powers#0"),
			# The new power one up, not one down.
			wrong({"c0": d1, "e0": p1.add(1), "c1": d2, "e1": p2.sub(1)}, "SL5.3.negative-powers#1"),
		],
		"generic": [{"c0": d1.neg(), "e0": p1.sub(1), "c1": d2.neg(), "e1": p2.sub(1)}, {"c0": k1, "e0": p1.sub(1), "c1": k2, "e1": p2.sub(1)}],
		"pick_wrongs": [pick("Differentiate the denominator", "d/dx(1/x²) is not 1/(2x)"), pick("Differentiate the top and the bottom separately", "a quotient doesn't differentiate term by term"),
			pick("Multiply the fractions out first", "there is nothing to multiply; write each term as a power of x")]}


# ── roots-from-vertex-form ───────────────────────────────────

func u_roots_from_vertex_form(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r1: Q = s.h.sub(s.d)
	var r2: Q = s.h.add(s.d)
	var ans := Answer.make("factorised", {"a": s.a, "p": r1, "q": r2})
	var sq := "(x%s)²" % Fmt.plus(s.h.neg())
	var first := "f(x) = 0: %s = %s" % [sq, N(s.d.sq())] if s.a.eq(1) else "f(x) = 0: %s%s = %s, so %s = %s" % [Fmt.lead(s.a), sq, N(s.k.neg()), sq, N(s.d.sq())]
	var steps := [first,
		"x%s = ±%s, so x = %s or x = %s" % [Fmt.plus(s.h.neg()), N(s.d), N(r1), N(r2)],
		"Each root r gives a factor (x − r), with a = %s in front" % N(s.a), "So %s." % Answer.text(ans)]
	return {"asked": "Write f in factorised form, and so give its roots.", "lines": ["f(x) = " + Fmt.vertex(s.a, s.h, s.k)], "given": export(s), "answer": ans,
		"methods": {"roots-to-factors": method(steps, ans.values)},
		"generic": [{"a": s.a, "p": r1.neg(), "q": r2.neg()}, {"a": s.a, "p": s.h.sub(s.d.sq()), "q": s.h.add(s.d.sq())}, {"a": Q.new(1) if not s.a.eq(1) else Q.new(2), "p": r1, "q": r2},
			{"a": s.a, "p": s.h, "q": s.k}],
		"pick_wrongs": [pick("Read the roots as h and k", "(h, k) is the vertex, not the roots"), pick("Take the square root of k", "the square root is of −k/a, after moving k across"),
			pick("Expand and read the roots from c", "c is the y-intercept, not a root")]}
