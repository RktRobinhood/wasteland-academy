class_name CompositePairViews
extends ExtensionViews
## The views on the `composite-pair` situation: one builder per unknown of fn-composite
## (FAL-422). Rules are written as f(x) = … or said in steps ("double, then subtract 3");
## an expression is the poly kind, a value the number kind, a constant k or a list of
## x-values their own kinds. Every Paper 1 answer is exact; the one Paper 2 view is
## (f∘g)(x₀) with f = sin x, to 3 s.f.

const T := "fn-composite"
const R_VAL_ORDER := "SL2.5.composite-value#0"
const R_VAL_PRODUCT := "SL2.5.composite-value#1"
const R_VAL_TWICE := "SL2.5.composite-value#2"
const R_EXPR_ORDER := "SL2.5.composite-expression#0"
const R_EQUAL := "SL2.5.composite-expression#2"
const R_UNDO_ORDER := "SL2.5.find-inverse#1"
const R_NO_PM := "SL2.7.solve-equation#2"


func needs() -> Dictionary:
	return {
		"value-inside-out": {"mode": "forward", "sine": true},
		"expression": {"mode": "forward"},
		"parameter-from-value": {"mode": "param"},
		"parameter-from-coefficients": {"mode": "coef"},
		"solve-composite": {"mode": "solve"},
		"self-composite": {"mode": "self"},
		"compare-orders": {"mode": "compare"},
		"build-from-words": {"mode": "chain"},
		"decompose": {"mode": "decompose"},
		"inner-from-composite": {"mode": "inner"},
		"outer-from-composite": {"mode": "outer"},
	}


## Paper 2 is a composite with a trig rule evaluated on the calculator (the catalogue's one
## Paper 2 part), or a constant k from (a·x₀ + k)² = r with r not a square; every other cell
## is Paper 1.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1, 2] if unknown in ["value-inside-out", "parameter-from-value"] else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = CompositePairSituation.export(s)
	return out


# ── Helpers ──────────────────────────────────────────────────

## A polynomial from coefficients as the game writes it: "2x² − 3x + 1".
static func ptext(co: Array) -> String:
	return Fmt.poly(CompositePairSituation.high(co, CompositePairSituation.degree(co)))


static func rt(r: Dictionary) -> String:
	return CompositePairSituation.rule_text(r)


static func fx(name: String, r: Dictionary) -> String:
	return "%s(x) = %s" % [name, rt(r)]


static func ev(r: Dictionary, x: Q) -> Q:
	return CompositePairSituation.ev(r, x)


static func comp(outer: Dictionary, inner: Dictionary) -> Array:
	return CompositePairSituation.composite(outer, inner)


## The rule lines of a view, as f(x) = … (equation) or in steps (words).
static func rule_lines(rep: String, pairs: Array) -> Array:
	var out: Array = []
	for p in pairs:
		if rep == "words":
			out.append("%s: %s." % [p[0], CompositePairSituation.steps_text(CompositePairSituation.rule_steps(p[1]))])
		else:
			out.append(fx(p[0], p[1]))
	return out


## An answer written as a polynomial in x with every power from the degree down to 0.
static func poly_ans(co: Array, label: String, deg: int = -1) -> Dictionary:
	var d := CompositePairSituation.degree(co) if deg < 0 else deg
	var vals := {}
	var hi := CompositePairSituation.high(co, d)
	for i in hi.size():
		vals["c%d" % i] = hi[i]
	var powers: Array = range(d, -1, -1)
	return Answer.make("poly", vals, {"powers": powers}, label)


## Values for a wrong polynomial in the shape of ans.
static func poly_vals(ans: Dictionary, co: Array) -> Dictionary:
	var d: int = ans.fixed.powers.size() - 1
	var vals := {}
	var hi := CompositePairSituation.high(co, d)
	for i in hi.size():
		vals["c%d" % i] = hi[i]
	return vals


static func fits(ans: Dictionary, co: Array) -> bool:
	return CompositePairSituation.degree(co) <= ans.fixed.powers.size() - 1


## wrong() for a polynomial, or nothing when it doesn't fit the answer's powers.
static func pw(ans: Dictionary, co: Array, ref: String = "") -> Array:
	if not fits(ans, co):
		return []
	return [wrong(poly_vals(ans, co), ref)]


static func pg(ans: Dictionary, co: Array) -> Array:
	if not fits(ans, co):
		return []
	return [poly_vals(ans, co)]


static func letter(order_fg: bool) -> String:
	return "f∘g" if order_fg else "g∘f"


# ── value-inside-out ─────────────────────────────────────────

func u_value_inside_out(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var g: Dictionary = s.g
	var x0: Q = s.x0
	var gx := ev(g, x0)
	var v: Q = s.v
	var sine: bool = s.get("sine", false)
	var ans := Answer.make("number", {"v": v}, {}, "(f∘g)(%s) = " % N(x0))
	if sine:
		ans.show = "sf"
	else:
		ans.exact = true
	var lines := rule_lines(rep, [["f", f], ["g", g]])
	if sine:
		lines.append("x is in radians.")
	var fshow := (Fmt.sf(v, 4) if sine else N(v))
	var h := comp(f, g)
	var out := {"asked": "Find (f∘g)(%s)." % N(x0), "lines": lines, "answer": ans, "wrongs": [], "generic": []}
	# The classic slips: g first (the wrong order), the product, one rule twice.
	var swapped := ev(g, ev(f, x0))
	out.wrongs.append(wrong({"v": swapped}, R_VAL_ORDER))
	out.wrongs.append(wrong({"v": ev(f, x0).mul(gx)}, R_VAL_PRODUCT))
	out.wrongs.append(wrong({"v": ev(f, ev(f, x0)) if not sine else ev(g, gx)}, R_VAL_TWICE))
	out.generic = [{"v": gx}, {"v": ev(f, x0)}, {"v": v.add(1)}]
	var final := "So " + Answer.text(ans) + "."
	var inside := [
		"g(%s) = %s = %s" % [N(x0), CompositePairSituation.sub_in(g, N(x0)), N(gx)],
		"f(%s) = %s = %s" % [N(gx), CompositePairSituation.sub_in(f, N(gx)), fshow],
		final]
	var built: Array
	if sine:
		built = ["(f∘g)(x) = sin(%s)" % rt(g), "(f∘g)(%s) = sin(%s) = sin %s = %s" % [N(x0), CompositePairSituation.sub_in(g, N(x0)), N(gx), fshow], final]
	else:
		built = ["(f∘g)(x) = %s = %s" % [CompositePairSituation.sub_in(f, rt(g)), ptext(h)], "(f∘g)(%s) = %s = %s" % [N(x0), _at(h, x0), N(v)], final]
	out.methods = {"inside-out": method(inside, {"v": v}), "build-then-substitute": method(built, {"v": v})}
	return out


## A polynomial with x replaced by a number, as written: "2(−3)² − 3(−3) + 1".
static func _at(co: Array, x: Q) -> String:
	return CompositePairSituation.put(ptext(co), N(x))


# ── expression ───────────────────────────────────────────────

func u_expression(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var g: Dictionary = s.g
	var order_fg := rng.chance(0.7)
	var outer := f if order_fg else g
	var inner := g if order_fg else f
	var other_outer := g if order_fg else f
	var other_inner := f if order_fg else g
	var h := comp(outer, inner)
	var wrong_h := comp(other_outer, other_inner)
	var lab := letter(order_fg)
	var ans := poly_ans(h, "(%s)(x) = " % lab)
	var out := {"asked": "Find (%s)(x), simplified." % lab, "lines": rule_lines(rep, [["f", f], ["g", g]]), "answer": ans,
		"wrongs": pw(ans, wrong_h, R_EXPR_ORDER), "generic": []}
	# The product f(x)·g(x) and the sum are the other tempting slips.
	out.generic.append_array(pg(ans, CompositePairSituation.pmul(f.co, g.co)))
	out.generic.append_array(pg(ans, CompositePairSituation.padd(f.co, g.co)))
	out.generic.append_array(pg(ans, CompositePairSituation.padd(h, [Q.new(1)])))
	out.methods = _expression_methods(f, g, outer, inner, h, order_fg, ans)
	return out


func _expression_methods(f: Dictionary, g: Dictionary, outer: Dictionary, inner: Dictionary, h: Array, order_fg: bool, ans: Dictionary) -> Dictionary:
	var lab := letter(order_fg)
	var final := "So %s." % Answer.text(ans)
	var on := "f" if order_fg else "g"
	var inn := "g" if order_fg else "f"
	var whole := ["Replace x in %s(x) with %s(x): (%s)(x) = %s" % [on, inn, lab, CompositePairSituation.sub_in(outer, rt(inner))],
		"Expand and simplify: %s" % ptext(h), final]
	var flow := ["Follow x through %s first: %s" % [inn, CompositePairSituation.steps_text(CompositePairSituation.rule_steps(inner))],
		"then through %s: %s" % [on, CompositePairSituation.steps_text(CompositePairSituation.rule_steps(outer))],
		"Together: %s = %s" % [CompositePairSituation.sub_in(outer, rt(inner)), ptext(h)], final]
	# Check an expanded answer with one number, worked inside-out.
	var x1 := Q.new(1)
	var gx1 := ev(inner, x1)
	var v1 := ev(outer, gx1)
	var numeric := ["Expand: (%s)(x) = %s" % [lab, ptext(h)],
		"Check x = 1 inside-out: %s(1) = %s, then %s(%s) = %s" % [inn, N(gx1), on, N(gx1), N(v1)],
		"The expansion gives %s = %s at x = 1, so the two agree." % [_at(h, x1), N(v1)], final]
	var flowed: Dictionary = {}
	if not CompositePairSituation.rule_steps(f).is_empty() and not CompositePairSituation.rule_steps(g).is_empty():
		flowed = {"flow-diagram": method(flow, ans.values)}
	var out := {"substitute-whole": method(whole, ans.values), "numeric-check": method(numeric, ans.values)}
	out.merge(flowed)
	return out


# ── parameter-from-value ─────────────────────────────────────

func u_parameter_from_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	if s.mode == "pm":
		return _param_pm(s)
	return _param_lin(s)


func _param_pm(s: Dictionary) -> Dictionary:
	var a: int = s.a
	var c: int = s.c
	var x0: Q = s.x0
	var v: Q = s.v
	var ans := Answer.make("kvals", {"r1": s.k1, "r2": s.k2}, {"var": "k"})
	# n: the whole number whose ± is a·x₀ + k, or r, the number under the root (Paper 2).
	var n: int = s.r if s.has("r") else s.n
	var awkward: bool = s.get("awkward", false)
	if awkward:
		ans.show = "sf"
	var shown := Q.new(a).mul(x0)
	var out := {"asked": "Given that (f∘g)(%s) = %s, find the possible values of k." % [N(x0), N(v)],
		"lines": ["f(x) = %s" % Fmt.poly([1, 0, c]), "g(x) = %sx + k" % Fmt.lead(a)], "answer": ans, "wrongs": [], "generic": []}
	if awkward:
		var root := Q.new(roundi(sqrt(float(s.r)) * 1e9), 1000000000)
		out.generic = [{"r1": root, "r2": root.neg()}, {"r1": root.add(shown), "r2": root.neg().add(shown)},
			{"r1": s.k1.add(1), "r2": s.k2.add(1)}, {"r1": root.sub(shown).add(1), "r2": root.neg().sub(shown).add(1)}]
	else:
		out.generic = [{"r1": Q.new(n), "r2": Q.new(-n)}, {"r1": Q.new(n).add(shown), "r2": Q.new(-n).add(shown)},
			{"r1": s.k1, "r2": s.k1.neg()}, {"r1": s.k1.add(1), "r2": s.k2.add(1)}]
	var final := "So %s." % Answer.text(ans)
	var gx_text := "k" if shown.is_zero() else ("%s + k" % N(shown) if shown.sign() > 0 else "k − %s" % shown.abs_q().text())
	var plus_c := "%s %s" % ["+" if c >= 0 else "−", absi(c)]
	var power := "(%s)² %s = %s" % [gx_text, plus_c, N(v)]
	var root_text := "√%d" % n if awkward else str(n)
	var solved := "(%s)² = %s, so %s = ±%s" % [gx_text, N(v.sub(c)), gx_text, root_text]
	var composite := "(f∘g)(x) = (%sx + k)² %s" % [Fmt.lead(a), plus_c]
	var finish := "k = %s or k = %s" % [N(s.k1), N(s.k2)]
	if awkward:
		finish = "√%d = %s, so k = %s or k = %s" % [n, Fmt.sf(sqrt(float(n)), 4), Fmt.sf(s.k1, 4), Fmt.sf(s.k2, 4)]
	out.methods = {
		"inside-out": method(["g(%s) = %s" % [N(x0), gx_text], "f(g(%s)) = %s" % [N(x0), power], solved, finish, final], ans.values),
		"build-then-substitute": method([composite, "Put x = %s: %s" % [N(x0), power], solved, finish, final], ans.values),
		"substitute-whole": method([composite, "Set x = %s and the value equal to %s: %s" % [N(x0), N(v), power], solved, finish, final], ans.values),
	}
	return out


func _param_lin(s: Dictionary) -> Dictionary:
	var g: Dictionary = s.g
	var x0: Q = s.x0
	var gx := ev(g, x0)
	var ans := Answer.make("number", {"v": s.k}, {}, "k = ")
	ans.exact = true
	var f_text := "f(x) = kx %s" % ("+ %s" % N(s.d) if s.d.sign() >= 0 else "− %s" % s.d.abs_q().text())
	var out := {"asked": "Given that (f∘g)(%s) = %s, find k." % [N(x0), N(s.v)], "lines": [f_text, fx("g", g)], "answer": ans, "wrongs": [], "generic": []}
	# g(f(x₀)) = v read the other way round, or forgetting the +d.
	var gm: Q = g.co[1]
	var sv: Q = s.v
	var sd: Q = s.d
	var swapped: Q = sv.sub(g.co[0]).div(gm).sub(sd).div(x0)
	out.wrongs.append(wrong({"v": swapped}, R_EXPR_ORDER))
	out.generic = [{"v": s.v.div(gx)}, {"v": s.v.add(s.d).div(gx)}, {"v": s.k.neg()}, {"v": s.v.sub(s.d)}]
	var final := "So %s." % Answer.text(ans)
	var d_part := ("+ %s" % N(s.d)) if s.d.sign() >= 0 else ("− %s" % s.d.abs_q().text())
	var eq := "%sk %s = %s" % [Fmt.lead(gx), d_part, N(s.v)]
	var inside := ["g(%s) = %s = %s" % [N(x0), CompositePairSituation.sub_in(g, N(x0)), N(gx)],
		"f(%s) = %s, so %s" % [N(gx), "%sk %s" % [Fmt.lead(gx), d_part], eq],
		"%sk = %s, so k = %s ÷ %s" % [Fmt.lead(gx), N(s.v.sub(s.d)), N(s.v.sub(s.d)), N(gx)], final]
	var build := ["(f∘g)(x) = k(%s) %s" % [rt(g), d_part],
		"Put x = %s: k(%s) %s = %s, so %s" % [N(x0), N(gx), d_part, N(s.v), eq],
		"%sk = %s, so k = %s ÷ %s" % [Fmt.lead(gx), N(s.v.sub(s.d)), N(s.v.sub(s.d)), N(gx)], final]
	out.methods = {"inside-out": method(inside, ans.values), "build-then-substitute": method(build, ans.values), "substitute-whole": method(build, ans.values)}
	return out


# ── parameter-from-coefficients ──────────────────────────────

func u_parameter_from_coefficients(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var d: int = s.d
	var c: int = s.c
	var ans := Answer.make("kvals", {"r1": Q.new(n), "r2": Q.new(-n)}, {"var": "k"})
	var f_text := "f(x) = %s" % Fmt.poly([1, 0, c])
	var g_text := "g(x) = kx %s" % [("+ %d" % d) if d > 0 else ("− %d" % -d)]
	var out := {"asked": "The composite (f∘g)(x) can be written as %dx² + qx + r. Find the possible values of k." % s.p.n,
		"lines": [f_text, g_text], "answer": ans, "wrongs": [], "generic": []}
	out.generic = [{"r1": s.p, "r2": s.p.neg()}, {"r1": Q.new(n * n / 2), "r2": Q.new(-n * n / 2)},
		{"r1": Q.new(n + 1), "r2": Q.new(-n - 1)}, {"r1": Q.new(n).add(Q.new(d)), "r2": Q.new(-n).add(Q.new(d))}]
	var final := "So %s." % Answer.text(ans)
	var inner_sq := "(kx %s)²" % [("+ %d" % d) if d > 0 else ("− %d" % -d)]
	var expanded := "k²x² %s %skx %s" % [("+" if d > 0 else "−"), "2" if absi(d) == 1 else N(2 * absi(d)), ("+ %d" % (d * d + c)) if d * d + c >= 0 else ("− %d" % -(d * d + c))]
	out.methods = {"substitute-whole": method([
		"(f∘g)(x) = %s %s = %s" % [inner_sq, ("+ %d" % c) if c >= 0 else ("− %d" % -c), expanded],
		"Equate the coefficient of x²: k² = %d" % s.p.n,
		"k = ±%d, so k = %d or k = %s" % [n, n, N(-n)], final], ans.values)}
	return out


# ── solve-composite ──────────────────────────────────────────

func u_solve_composite(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var g: Dictionary = s.g
	var xs: Array = s.xs
	var vals := {"n": Q.new(xs.size())}
	for i in xs.size():
		vals["x%d" % i] = xs[i]
	var ans := Answer.make("xs", vals, {"var": "x"})
	var h := comp(f, g)
	var out := {"asked": "Solve (f∘g)(x) = %s." % N(s.t), "lines": [fx("f", f), fx("g", g)], "answer": ans, "wrongs": [], "generic": []}
	var final := "So %s." % Answer.text(ans)
	# Wrong options have the same number of x-values.
	var gm: Q = g.co[1]
	var gb: Q = g.co[0]
	if xs.size() == 2:
		# Only the positive root of the square, or g inverted without the shift.
		var n: Q = s.t.sub(f.co[0]).abs_q()
		var r := Q.new(roundi(sqrt(n.to_float())))
		var plus := r.sub(gb).div(gm)
		var minus := r.neg().sub(gb).div(gm)
		out.generic = [{"n": Q.new(2), "x0": plus, "x1": plus.add(1)}, {"n": Q.new(2), "x0": r.div(gm), "x1": r.neg().div(gm)},
			{"n": Q.new(2), "x0": plus.add(1), "x1": minus.add(1)}, {"n": Q.new(2), "x0": plus.neg(), "x1": minus.neg()}]
		if xs.size() == 2 and gb.is_zero():
			out.generic.append({"n": Q.new(2), "x0": r, "x1": r.neg()})
	else:
		var x: Q = xs[0]
		out.generic = [{"n": Q.new(1), "x0": x.add(1)}, {"n": Q.new(1), "x0": x.neg()}, {"n": Q.new(1), "x0": x.sub(1)}, {"n": Q.new(1), "x0": s.t}]
	var whole := ["(f∘g)(x) = %s = %s" % [CompositePairSituation.sub_in(f, rt(g)), ptext(h)],
		"Set it equal to %s: %s = %s" % [N(s.t), ptext(h), N(s.t)], _solve_last(f, g, s), final]
	var flow := ["Undo f first: from %s, the value of g(x) is %s" % [N(s.t), _g_values(f, g, s)],
		"Then undo g: %s" % _solve_last(f, g, s), final]
	var rev := ["f(g(x)) = %s, so work backwards from %s through f" % [N(s.t), N(s.t)],
		"g(x) = %s" % _g_values(f, g, s), _solve_last(f, g, s), final]
	out.methods = {"substitute-whole": method(whole, ans.values), "flow-diagram": method(flow, ans.values), "reverse-operations": method(rev, ans.values)}
	return out


## "3 or −3": the value(s) g(x) takes.
static func _g_values(f: Dictionary, g: Dictionary, s: Dictionary) -> String:
	var gs: Array = []
	for x in s.xs:
		var v := ev(g, x)
		if not gs.any(func(e): return e.eq(v)):
			gs.append(v)
	return " or ".join(gs.map(func(v): return N(v)))


static func _solve_last(_f: Dictionary, g: Dictionary, s: Dictionary) -> String:
	var parts: Array = []
	for x in s.xs:
		parts.append("%s = %s → x = %s" % [rt(g), N(ev(g, x)), N(x)])
	return "; ".join(parts)


# ── self-composite ───────────────────────────────────────────

func u_self_composite(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var h := comp(f, f)
	var ans := poly_ans(h, "(f∘f)(x) = ")
	var out := {"asked": "Find (f∘f)(x), simplified.", "lines": rule_lines(rep, [["f", f]]), "answer": ans, "wrongs": [], "generic": []}
	# The classic slip: replace only one of the x's, or square the rule.
	out.wrongs.append_array(pw(ans, CompositePairSituation.pmul(f.co, f.co), ""))
	out.generic.append_array(pg(ans, CompositePairSituation.padd(f.co, f.co)))
	out.generic.append_array(pg(ans, CompositePairSituation.padd(h, [Q.new(1)])))
	out.generic.append_array(pg(ans, CompositePairSituation.pscale(h, Q.new(2))))
	var final := "So %s." % Answer.text(ans)
	var whole := ["Replace x in f(x) with f(x): (f∘f)(x) = %s" % CompositePairSituation.sub_in(f, rt(f)), "Expand and simplify: %s" % ptext(h), final]
	var x1 := Q.new(1)
	var f1 := ev(f, x1)
	var inside := ["Work out %s" % ["(f∘f)(x) = %s" % CompositePairSituation.sub_in(f, rt(f))],
		"Check x = 1: f(1) = %s, then f(%s) = %s" % [N(f1), N(f1), N(ev(f, f1))],
		"%s at x = 1 is %s, which agrees" % [_at(h, x1), N(ev(f, f1))], final]
	out.methods = {"substitute-whole": method(whole, ans.values), "inside-out": method(inside, ans.values)}
	return out


# ── compare-orders ───────────────────────────────────────────

func u_compare_orders(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var g: Dictionary = s.g
	var fg := comp(f, g)
	var gf := comp(g, f)
	var a := "f∘g = %s and g∘f = %s: not equal" % [ptext(fg), ptext(gf)]
	var b := "f∘g = %s and g∘f = %s: not equal" % [ptext(gf), ptext(fg)]
	var c := "f∘g = %s and g∘f = %s: equal" % [ptext(fg), ptext(fg)]
	var d := "f∘g = %s and g∘f = %s: equal" % [ptext(gf), ptext(gf)]
	var opts: Array = [a, b, c, d]
	var ans := Answer.make("choice", {"v": a}, {"options": opts})
	var out := {"asked": "Find f∘g and g∘f, and say whether they are equal.", "lines": rule_lines(rep, [["f", f], ["g", g]]), "answer": ans,
		"wrongs": [wrong({"v": b}, R_EXPR_ORDER), wrong({"v": c}, R_EQUAL)], "generic": [{"v": d}]}
	var final := "So %s." % a
	var x1 := Q.new(1)
	var v_fg := ev(f, ev(g, x1))
	var v_gf := ev(g, ev(f, x1))
	out.methods = {
		"substitute-whole": method(["f(g(x)) = %s = %s" % [CompositePairSituation.sub_in(f, rt(g)), ptext(fg)],
			"g(f(x)) = %s = %s" % [CompositePairSituation.sub_in(g, rt(f)), ptext(gf)], "The two expressions are different", final], ans.values),
		"numeric-check": method(["Try x = 1: g(1) = %s, then f(%s) = %s, so (f∘g)(1) = %s" % [N(ev(g, x1)), N(ev(g, x1)), N(v_fg), N(v_fg)],
			"Also f(1) = %s, then g(%s) = %s, so (g∘f)(1) = %s" % [N(ev(f, x1)), N(ev(f, x1)), N(v_gf), N(v_gf)],
			"%s ≠ %s, so the order matters" % [N(v_fg), N(v_gf)], "Expanding gives %s and %s" % [ptext(fg), ptext(gf)], final], ans.values),
	}
	return out


# ── build-from-words ─────────────────────────────────────────

func u_build_from_words(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var steps: Array = s.steps
	var h := CompositePairSituation.chain_co(steps)
	var ans := poly_ans(h, "h(x) = ")
	var out := {"asked": "A rule takes x and does this: %s. Write it as one expression, h(x)." % CompositePairSituation.steps_text(steps),
		"lines": [], "answer": ans, "wrongs": [], "generic": []}
	# The steps taken in the opposite order, and each bracket left out.
	var rev := steps.duplicate()
	rev.reverse()
	out.wrongs.append_array(pw(ans, CompositePairSituation.chain_co(rev), R_EXPR_ORDER))
	var no_sq := steps.filter(func(st): return st != "square")
	out.generic.append_array(pg(ans, CompositePairSituation.chain_co(no_sq)))
	out.generic.append_array(pg(ans, CompositePairSituation.padd(h, [Q.new(2)])))
	out.generic.append_array(pg(ans, CompositePairSituation.pscale(h, Q.new(-1))))
	out.generic.append_array(pg(ans, CompositePairSituation.pmul(h, [Q.new(0), Q.new(1)])))
	var final := "So %s." % Answer.text(ans)
	var st: Array = []
	var cur := "x"
	for step in steps:
		cur = _apply(cur, step)
		st.append("%s: %s" % [step, cur])
	st.append(final)
	var lines := st.slice(0, st.size() - 1)
	var flow: Array = ["Start with x"]
	flow.append_array(lines)
	flow.append("Expand: h(x) = %s" % ptext(h))
	flow.append(final)
	out.methods = {"flow-diagram": method(flow.slice(0, 5) if flow.size() > 5 else flow, ans.values)}
	if flow.size() > 5:
		var tight := lines.duplicate()
		tight.append("Expand: h(x) = %s" % ptext(h))
		tight.append(final)
		out.methods = {"flow-diagram": method(tight, ans.values)}
	return out


## One step applied to an expression text, as the game writes a rule's composite.
static func _apply(cur: String, step: String) -> String:
	var w: PackedStringArray = step.split(" ")
	var wrapped := cur if cur == "x" else "(" + cur + ")"
	match w[0]:
		"add":
			return "%s + %s" % [cur, w[1]]
		"subtract":
			return "%s − %s" % [cur, w[1]]
		"square":
			return wrapped + "²"
		"double":
			return "2" + wrapped
		"treble":
			return "3" + wrapped
		_:
			return w[2] + wrapped


# ── decompose ────────────────────────────────────────────────

func u_decompose(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var g: Dictionary = s.g
	var h := comp(f, g)
	var shown := CompositePairSituation.sub_in(f, rt(g))
	var rule_g := "g(x) = %s" % rt(g)
	var rule_f := "f(x) = %s" % rt(f)
	var right := "%s and %s" % [rule_g, rule_f]
	var swapped := "g(x) = %s and f(x) = %s" % [rt(f), rt(g)]
	var no_shift := "g(x) = %s and f(x) = %s" % [rt(lin(g.co[1], 0)), rt(f)]
	var no_const := "g(x) = %s and f(x) = %s" % [rt(g), rt({"t": "poly", "co": [Q.new(0)] + f.co.slice(1)})]
	var sign := "g(x) = %s and f(x) = %s" % [rt(lin(g.co[1], g.co[0].neg())), rt(f)]
	var opts: Array = [right, swapped, no_shift, no_const, sign]
	var ans := Answer.make("choice", {"v": right}, {"options": opts})
	var lines: Array = []
	if rep == "words":
		lines = ["h: %s." % CompositePairSituation.steps_text(CompositePairSituation.rule_steps(g) + CompositePairSituation.rule_steps(f))]
	else:
		lines = ["h(x) = %s" % shown]
	var out := {"asked": "Write h as f(g(x)) for two simpler rules: choose g, the first step, and f.", "lines": lines, "answer": ans,
		"wrongs": [wrong({"v": swapped}, R_EXPR_ORDER)], "generic": [{"v": no_shift}, {"v": no_const}, {"v": sign}]}
	var final := "So %s." % right
	var x1 := Q.new(1)
	var gx := ev(g, x1)
	out.methods = {
		"flow-diagram": method(["Follow x through h: first %s, then %s" % [CompositePairSituation.steps_text(CompositePairSituation.rule_steps(g)), CompositePairSituation.steps_text(CompositePairSituation.rule_steps(f))],
			"The inner rule is g(x) = %s" % rt(g), "The outer rule is f(x) = %s" % rt(f), final], ans.values),
		"numeric-check": method(["Try g(x) = %s and f(x) = %s" % [rt(g), rt(f)],
			"At x = 1: g(1) = %s and f(%s) = %s" % [N(gx), N(gx), N(ev(f, gx))],
			"h(1) = %s, which agrees" % N(ev({"t": "poly", "co": h}, x1)), final], ans.values),
	}
	return out


static func lin(m: Variant, c: Variant) -> Dictionary:
	return CompositePairSituation.lin(m, c)


# ── inner-from-composite ─────────────────────────────────────

func u_inner_from_composite(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var g: Dictionary = s.g
	var h := comp(f, g)
	var ans := poly_ans(g.co, "g(x) = ", 2 if g.t == "poly" else 1)
	var m: Q = f.co[1]
	var c: Q = f.co[0]
	var out := {"asked": "Find g(x).", "lines": [fx("f", f), "(f∘g)(x) = %s" % ptext(h)], "answer": ans, "wrongs": [], "generic": []}
	# Undoing f's steps in the original order: h ÷ m − c instead of (h − c) ÷ m.
	out.wrongs.append_array(pw(ans, CompositePairSituation.padd(CompositePairSituation.pscale(h, Q.new(1).div(m)), [c.neg()]), R_UNDO_ORDER))
	out.generic.append_array(pg(ans, CompositePairSituation.padd(h, [c.neg()])))
	out.generic.append_array(pg(ans, CompositePairSituation.pscale(h, Q.new(1).div(m))))
	out.generic.append_array(pg(ans, CompositePairSituation.pscale(CompositePairSituation.padd(h, [c]), Q.new(1).div(m))))
	var final := "So %s." % Answer.text(ans)
	var minus := "%s = %s" % [CompositePairSituation.sub_in(lin(m, 0), "g(x)"), ptext(CompositePairSituation.padd(h, [c.neg()]))]
	var whole := ["f(g(x)) = %s = %s" % [rt_g(f), ptext(h)], minus, "g(x) = (%s) ÷ %s" % [ptext(CompositePairSituation.padd(h, [c.neg()])), N(m)], final]
	var rev := ["f does two things to g(x): %s" % CompositePairSituation.steps_text(CompositePairSituation.rule_steps(f)),
		"Undo them in reverse order: %s" % _undo_text(f),
		"g(x) = (%s − %s) ÷ %s" % [ptext(h), Fmt.paren(c), Fmt.paren(m)], final]
	var vals: Array = []
	for x in [Q.new(0), Q.new(1)]:
		vals.append("x = %s: g = (%s − %s) ÷ %s = %s" % [N(x), N(peval(h, x)), Fmt.paren(c), Fmt.paren(m), N(peval(g.co, x))])
	var numeric := ["Undo f at some inputs: g = (h − %s) ÷ %s" % [Fmt.paren(c), Fmt.paren(m)], vals[0], vals[1],
		"The expression through these values is %s" % ptext(g.co), final]
	out.methods = {"substitute-whole": method(whole, ans.values), "numeric-check": method(numeric, ans.values), "reverse-operations": method(rev, ans.values)}
	return out


static func peval(co: Array, x: Q) -> Q:
	return CompositePairSituation.peval(co, x)


static func rt_g(f: Dictionary) -> String:
	return CompositePairSituation.sub_in(f, "g(x)")


static func _undo_text(f: Dictionary) -> String:
	var steps := CompositePairSituation.rule_steps(f)
	var out: Array = []
	for i in range(steps.size() - 1, -1, -1):
		var w: PackedStringArray = steps[i].split(" ")
		match w[0]:
			"add":
				out.append("subtract %s" % w[1])
			"subtract":
				out.append("add %s" % w[1])
			"double":
				out.append("halve")
			"treble":
				out.append("divide by 3")
			"negate":
				out.append("negate")
			_:
				out.append("divide by %s" % w[2])
	return ", then ".join(out)


# ── outer-from-composite ─────────────────────────────────────

func u_outer_from_composite(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.f
	var g: Dictionary = s.g
	var h := comp(f, g)
	var ans := poly_ans(f.co, "f(x) = ", 2)
	var a: Q = g.co[1]
	var b: Q = g.co[0]
	var out := {"asked": "Find f(x).", "lines": [fx("g", g), "(f∘g)(x) = %s" % ptext(h)], "answer": ans, "wrongs": [], "generic": []}
	# h itself, or f with g's x and constant left in (f(x) = h(x) with x not replaced).
	out.wrongs.append_array(pw(ans, h if CompositePairSituation.degree(h) <= 2 else []))
	var inv := lin(Q.new(1).div(a), b.neg().div(a))
	out.generic.append_array(pg(ans, CompositePairSituation.pcompose(h, [b, a])))
	out.generic.append_array(pg(ans, CompositePairSituation.pcompose(h, [b.neg(), a])))
	out.generic.append_array(pg(ans, CompositePairSituation.pcompose(f.co, [Q.new(0), a])))
	out.generic.append_array(pg(ans, CompositePairSituation.padd(f.co, [Q.new(1)])))
	var final := "So %s." % Answer.text(ans)
	var shift := ("− %s" % N(b)) if b.sign() >= 0 else ("+ %s" % N(b.neg()))
	var ginv := CompositePairSituation.pcompose(h, inv.co)
	var in_u := "f(u) = %s" % Fmt.poly(CompositePairSituation.high(ginv, 2), "u")
	var x_of_u := "x = (u %s) ÷ %s" % [shift, Fmt.paren(a)]
	out.methods = {
		"substitute-whole": method(["Let u = %s, so %s" % [rt(g), x_of_u], "Put x = (u %s) ÷ %s into (f∘g)(x) = %s" % [shift, Fmt.paren(a), ptext(h)],
			"Simplify: %s, so f(x) = %s" % [in_u, ptext(ginv)], final], ans.values),
		"swap-then-solve": method(["Find g⁻¹: y = %s, so %s" % [rt(g), x_of_u.replace("x =", "x =").replace("u", "y")],
			"f(x) = (f∘g)(g⁻¹(x)): put (x %s) ÷ %s into %s" % [shift, Fmt.paren(a), ptext(h)],
			"Simplify: f(x) = %s" % ptext(ginv), final], ans.values),
	}
	return out
