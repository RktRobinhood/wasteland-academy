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
const R_STOP_INNER := T + "#8"
const R_G_AS_K := T + "#9"
const R_SIGN_MOVE := T + "#10"
const R_NO_D := T + "#11"
const R_NO_DIVIDE := T + "#12"
const R_NO_ROOT := T + "#13"
const R_HALVE := T + "#14"
const R_SOLVE_NO_SHIFT := T + "#15"
const R_SOLVE_STOP := T + "#16"
const R_SQUARE := T + "#17"
const R_ONE_STEP := T + "#18"
const R_H_AS_F := T + "#19"
const R_G_NOT_INV := T + "#20"
const R_FIRST_TERM := T + "#21"
const R_TERM_BY_TERM := T + "#22"


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
	var out := {"asked": "Find (f∘g)(%s)." % N(x0), "lines": lines, "answer": ans, "wrongs": [], "fillers": []}
	# The classic slips: g first (the wrong order), the product, one rule twice.
	var swapped := ev(g, ev(f, x0))
	out.wrongs.append(wrong({"v": swapped}, R_VAL_ORDER))
	out.wrongs.append(wrong({"v": ev(f, x0).mul(gx)}, R_VAL_PRODUCT))
	out.wrongs.append(wrong({"v": ev(f, ev(f, x0)) if not sine else ev(g, gx)}, R_VAL_TWICE))
	out.wrongs.append(wrong({"v": gx}, R_STOP_INNER))
	out.fillers = [{"v": ev(f, x0)}, {"v": v.add(1)}]
	var final := "So " + Answer.text(ans) + "."
	var inside := [
		"g(%s) = %s" % [N(x0), Fmt.equals(CompositePairSituation.sub_in(g, N(x0)), N(gx))],
		"f(%s) = %s" % [N(gx), Fmt.equals(CompositePairSituation.sub_in(f, N(gx)), fshow)],
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


## outer(inner(x)) with only the first term of the bracket multiplied by a linear outer
## rule's coefficient: 3(2x − 5) + 1 read as 6x − 5 + 1 (fn-composite#21).
static func first_term(outer: Dictionary, inner: Dictionary) -> Array:
	var co := CompositePairSituation.trim(inner.co)
	var d := co.size() - 1
	co[d] = co[d].mul(outer.co[1])
	co[0] = co[0].add(outer.co[0])
	return co


## A power of a bracket taken term by term, with no middle terms: (3x − 2)² + 4 read as
## 9x² + 4 + 4, (x − 1)² of 2x + 3 as 4x² + 2², (x² + 3)² + 3 as x⁴ + 9 + 3
## (fn-composite#22). outer is (x − s)ⁿ + c, inner any polynomial.
static func term_by_term(outer: Dictionary, inner: Dictionary) -> Array:
	var n := CompositePairSituation.degree(outer.co)
	var s: Q = outer.h if outer.t == "sqs" else Q.new(0)
	var c: Q = Q.new(0) if outer.t == "sqs" else outer.co[0]
	var b := CompositePairSituation.trim(CompositePairSituation.padd(inner.co, [s.neg()]))
	var co: Array = []
	for i in (b.size() - 1) * n + 1:
		co.append(Q.new(0))
	for i in b.size():
		var p := Q.new(1)
		for j in n:
			p = p.mul(b[i])
		co[i * n] = co[i * n].add(p)
	co[0] = co[0].add(c)
	return co


## A bracket slip as a wrong option: only the first term multiplied (a linear outer rule),
## or a power taken term by term; nothing when the slip gives the answer itself.
static func bracket_slip(ans: Dictionary, outer: Dictionary, inner: Dictionary, h: Array) -> Array:
	var co := first_term(outer, inner) if outer.t == "lin" else term_by_term(outer, inner)
	var ref := R_FIRST_TERM if outer.t == "lin" else R_TERM_BY_TERM
	return [] if CompositePairSituation.same(co, h) else pw(ans, co, ref)


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
		"wrongs": pw(ans, wrong_h, R_EXPR_ORDER), "fillers": []}
	# Expanding the bracket badly: only its first term multiplied, or a power taken term
	# by term with no middle terms.
	out.wrongs.append_array(bracket_slip(ans, outer, inner, h))
	# The product f(x)·g(x) is of a higher degree than the answer, so pg drops it; the sum
	# and the inner rule's constant left out have no route. The answer + 1 is a last resort.
	out.fillers.append_array(pg(ans, CompositePairSituation.padd(f.co, g.co)))
	out.fillers.append_array(pg(ans, CompositePairSituation.pmul(f.co, g.co)))
	out.fillers.append_array(pg(ans, CompositePairSituation.pcompose(outer.co, [Q.new(0)] + CompositePairSituation.trim(inner.co).slice(1))))
	out.fillers.append_array(pg(ans, CompositePairSituation.padd(h, [Q.new(1)])))
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
	var numeric := ["Replace x in %s(x) with %s(x) and expand: (%s)(x) = %s = %s" % [on, inn, lab, CompositePairSituation.sub_in(outer, rt(inner)), ptext(h)],
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
		"lines": ["f(x) = %s" % Fmt.poly([1, 0, c]), "g(x) = %sx + k" % Fmt.lead(a)], "answer": ans, "wrongs": [], "fillers": []}
	if awkward:
		var root := Q.new(roundi(sqrt(float(s.r)) * 1e9), 1000000000)
		out.wrongs = [wrong({"r1": root, "r2": root.neg()}, R_G_AS_K), wrong({"r1": root.add(shown), "r2": root.neg().add(shown)}, R_SIGN_MOVE)]
		out.fillers = [{"r1": s.k1.add(1), "r2": s.k2.add(1)}, {"r1": root.sub(shown).add(1), "r2": root.neg().sub(shown).add(1)}]
	else:
		out.wrongs = [wrong({"r1": Q.new(n), "r2": Q.new(-n)}, R_G_AS_K), wrong({"r1": Q.new(n).add(shown), "r2": Q.new(-n).add(shown)}, R_SIGN_MOVE)]
		out.fillers = [{"r1": s.k1, "r2": s.k1.neg()}, {"r1": s.k1.add(1), "r2": s.k2.add(1)}]
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
	var out := {"asked": "Given that (f∘g)(%s) = %s, find k." % [N(x0), N(s.v)], "lines": [f_text, fx("g", g)], "answer": ans, "wrongs": [], "fillers": []}
	# g(f(x₀)) = v read the other way round, or forgetting the +d.
	var gm: Q = g.co[1]
	var sv: Q = s.v
	var sd: Q = s.d
	var swapped: Q = sv.sub(g.co[0]).div(gm).sub(sd).div(x0)
	out.wrongs.append(wrong({"v": swapped}, R_EXPR_ORDER))
	out.wrongs.append_array([wrong({"v": s.v.div(gx)}, R_NO_D), wrong({"v": s.v.add(s.d).div(gx)}, R_SIGN_MOVE), wrong({"v": s.v.sub(s.d)}, R_NO_DIVIDE)])
	out.fillers = [{"v": s.k.neg()}]
	var final := "So %s." % Answer.text(ans)
	var d_part := ("+ %s" % N(s.d)) if s.d.sign() >= 0 else ("− %s" % s.d.abs_q().text())
	var eq := "%sk %s = %s" % [Fmt.lead(gx), d_part, N(s.v)]
	var inside := ["g(%s) = %s" % [N(x0), Fmt.equals(CompositePairSituation.sub_in(g, N(x0)), N(gx))],
		"f(%s) = %s, so %s" % [N(gx), "%sk %s" % [Fmt.lead(gx), d_part], eq],
		"%sk = %s, so k = %s ÷ %s" % [Fmt.lead(gx), N(s.v.sub(s.d)), N(s.v.sub(s.d)), Fmt.paren(gx)], final]
	var build := ["(f∘g)(x) = k(%s) %s" % [rt(g), d_part],
		"Put x = %s: k(%s) %s = %s, so %s" % [N(x0), N(gx), d_part, N(s.v), eq],
		"%sk = %s, so k = %s ÷ %s" % [Fmt.lead(gx), N(s.v.sub(s.d)), N(s.v.sub(s.d)), Fmt.paren(gx)], final]
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
		"lines": [f_text, g_text], "answer": ans, "wrongs": [], "fillers": []}
	out.wrongs = [wrong({"r1": s.p, "r2": s.p.neg()}, R_NO_ROOT)]
	# Halving n² is the slip only when n² is even; with n odd the value is rounded down.
	var halved := {"r1": Q.new(n * n / 2), "r2": Q.new(-n * n / 2)}
	if n % 2 == 0:
		out.wrongs.append(wrong(halved, R_HALVE))
	else:
		out.fillers.append(halved)
	out.fillers.append_array([{"r1": Q.new(n + 1), "r2": Q.new(-n - 1)}, {"r1": Q.new(n).add(Q.new(d)), "r2": Q.new(-n).add(Q.new(d))}])
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
	var out := {"asked": "Solve (f∘g)(x) = %s." % N(s.t), "lines": [fx("f", f), fx("g", g)], "answer": ans, "wrongs": [], "fillers": []}
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
		out.wrongs.append(wrong({"n": Q.new(2), "x0": r.div(gm), "x1": r.neg().div(gm)}, R_SOLVE_NO_SHIFT))
		# The pair shifted by one is a last resort, so no repeated root ("x = 0 or 0") is nudged in.
		out.fillers = [{"n": Q.new(2), "x0": plus, "x1": plus.add(1)},
			{"n": Q.new(2), "x0": plus.add(1), "x1": minus.add(1)}, {"n": Q.new(2), "x0": plus.neg(), "x1": minus.neg()},
			{"n": Q.new(2), "x0": xs[0].sub(1), "x1": xs[1].sub(1)}, {"n": Q.new(2), "x0": xs[0].add(1), "x1": xs[1].add(1)}]
		if xs.size() == 2 and gb.is_zero():
			out.wrongs.append(wrong({"n": Q.new(2), "x0": r, "x1": r.neg()}, R_SOLVE_STOP))
	else:
		var x: Q = xs[0]
		var one := func(v: Q) -> Dictionary: return {"n": Q.new(1), "x0": v}
		var gv := ev(g, x)
		# (g∘f)(x) = t solved instead, and f undone in the order it works (t ÷ m − c, not
		# (t − c) ÷ m): a linear f only, where both stay rational. Then stopping at g(x),
		# and undoing g's multiplication but not its shift.
		if f.t == "lin":
			var fm: Q = f.co[1]
			var fc: Q = f.co[0]
			out.wrongs.append(wrong(one.call(s.t.sub(gb).div(gm).sub(fc).div(fm)), R_EXPR_ORDER))
			out.wrongs.append(wrong(one.call(s.t.div(fm).sub(fc).sub(gb).div(gm)), R_UNDO_ORDER))
		out.wrongs.append(wrong(one.call(gv), R_SOLVE_STOP))
		out.wrongs.append(wrong(one.call(gv.div(gm)), R_SOLVE_NO_SHIFT))
		out.fillers = [one.call(s.t), one.call(x.neg()), one.call(x.add(1)), one.call(x.sub(1))]
	var whole := _solve_whole(f, g, h, s)
	whole.append(final)
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


## The substitute-whole working, kept on one route: a linear or quadratic composite is
## expanded and that equation solved (9x + 15 = −12, so 9x = −27; 16x² + 64x = 0, so
## 16x(x + 4) = 0); a cube is solved with its bracket kept, as expanding it leads nowhere.
static func _solve_whole(f: Dictionary, g: Dictionary, h: Array, s: Dictionary) -> Array:
	var t: Q = s.t
	var shown := CompositePairSituation.sub_in(f, rt(g))
	if f.t == "cube":
		var bracket := CompositePairSituation.put("x³", rt(g))
		var x: Q = s.xs[0]
		return ["(f∘g)(x) = %s" % shown, "Set it equal to %s: %s = %s, so %s = %s" % [N(t), shown, N(t), bracket, N(t.sub(f.co[0]))],
			"%s = ∛%s = %s, so x = %s" % [rt(g), Fmt.paren(t.sub(f.co[0])), N(ev(g, x)), N(x)]]
	var first := "(f∘g)(x) = %s = %s" % [shown, ptext(h)]
	if f.t == "lin":
		var m: Q = h[1]
		var rhs := t.sub(h[0])
		return [first, "Set it equal to %s: %s = %s, so %sx = %s" % [N(t), ptext(h), N(t), Fmt.lead(m), N(rhs)],
			"x = %s ÷ %s = %s" % [N(rhs), Fmt.paren(m), N(s.xs[0])]]
	# A quadratic with whole roots x1 and x2: A(x − x1)(x − x2) = 0, a bare x first.
	var zero := CompositePairSituation.padd(h, [t.neg()])
	var fs: Array = s.xs.map(func(r): return Fmt.factor(r))
	fs.sort_custom(func(a, b): return a == "x" and b != "x")
	return [first, "Set it equal to %s: %s = %s, so %s = 0" % [N(t), ptext(h), N(t), ptext(zero)],
		"%s%s = 0, so x = %s or x = %s" % [Fmt.lead(h[2]), "".join(fs), N(s.xs[0]), N(s.xs[1])]]


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
	# The method is f put into itself, so its label names f, not g.
	var out := {"asked": "Find (f∘f)(x), simplified.", "lines": rule_lines(rep, [["f", f]]), "answer": ans, "wrongs": [], "fillers": [],
		"titles": {"substitute-whole": "Replace every x in f with f(x)"}}
	# The slips: square the rule (x² + c only: a linear rule's square is no linear option),
	# then the bracket expanded badly. The rule doubled, the inner constant left out and
	# f's constant added twice have no route; the answer + 1 and doubled are last resorts.
	out.wrongs.append_array(pw(ans, CompositePairSituation.pmul(f.co, f.co), R_SQUARE))
	out.wrongs.append_array(bracket_slip(ans, f, f, h))
	out.fillers.append_array(pg(ans, CompositePairSituation.padd(f.co, f.co)))
	out.fillers.append_array(pg(ans, CompositePairSituation.pcompose(f.co, [Q.new(0)] + CompositePairSituation.trim(f.co).slice(1))))
	out.fillers.append_array(pg(ans, CompositePairSituation.padd(f.co, [f.co[0]])))
	out.fillers.append_array(pg(ans, CompositePairSituation.padd(h, [Q.new(1)])))
	out.fillers.append_array(pg(ans, CompositePairSituation.pscale(h, Q.new(2))))
	var final := "So %s." % Answer.text(ans)
	# The bracket multiplied out, then f's constant added: (x² + 3)² + 3 = x⁴ + 6x² + 9 + 3.
	var c: Q = f.co[0]
	var bracket := CompositePairSituation.pmul(f.co, f.co) if f.t == "sq" else CompositePairSituation.pscale(f.co, f.co[1])
	var expand := "%s = %s%s = %s" % [CompositePairSituation.sub_in(f, rt(f)), ptext(bracket), "" if c.is_zero() else Fmt.plus(c), ptext(h)]
	var whole := ["Replace x in f(x) with f(x): (f∘f)(x) = %s" % CompositePairSituation.sub_in(f, rt(f)),
		"Expand and simplify: %s" % expand.split(" = ", true, 1)[1], final]
	var x1 := Q.new(1)
	var f1 := ev(f, x1)
	var inside := ["Inside first: f(x) = %s; then f of that: (f∘f)(x) = %s" % [rt(f), expand],
		"Check x = 1 inside-out: f(1) = %s, then f(%s) = %s" % [N(f1), N(f1), N(ev(f, f1))],
		"The expansion gives %s = %s at x = 1, which agrees" % [_at(h, x1), N(ev(f, f1))], final]
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
		"wrongs": [wrong({"v": b}, R_EXPR_ORDER), wrong({"v": c}, R_EQUAL)], "fillers": [{"v": d}]}
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
		"lines": [], "answer": ans, "wrongs": [], "fillers": []}
	# The steps taken in the opposite order, and each bracket left out.
	var rev := steps.duplicate()
	rev.reverse()
	out.wrongs.append_array(pw(ans, CompositePairSituation.chain_co(rev), R_EXPR_ORDER))
	var no_sq := steps.filter(func(st): return st != "square")
	out.fillers.append_array(pg(ans, CompositePairSituation.chain_co(no_sq)))
	out.fillers.append_array(pg(ans, CompositePairSituation.padd(h, [Q.new(2)])))
	out.fillers.append_array(pg(ans, CompositePairSituation.pscale(h, Q.new(-1))))
	out.fillers.append_array(pg(ans, CompositePairSituation.pmul(h, [Q.new(0), Q.new(1)])))
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
		"wrongs": [wrong({"v": swapped}, R_EXPR_ORDER)], "fillers": [{"v": no_shift}, {"v": no_const}, {"v": sign}]}
	var final := "So %s." % right
	var x1 := Q.new(1)
	var gx := ev(g, x1)
	var read_off := "The bracket is worked out first, so g(x) = %s; what h does to the bracket is f(x) = %s" % [rt(g), rt(f)]
	if rep == "words":
		read_off = "The first steps (%s) give g(x) = %s; the rest (%s) give f(x) = %s" % [CompositePairSituation.steps_text(CompositePairSituation.rule_steps(g)),
			rt(g), CompositePairSituation.steps_text(CompositePairSituation.rule_steps(f)), rt(f)]
	out.methods = {
		"flow-diagram": method(["Follow x through h: first %s, then %s" % [CompositePairSituation.steps_text(CompositePairSituation.rule_steps(g)), CompositePairSituation.steps_text(CompositePairSituation.rule_steps(f))],
			"The inner rule is g(x) = %s" % rt(g), "The outer rule is f(x) = %s" % rt(f), final], ans.values),
		# Read the pair off h, then check it with one number (a check, not the derivation).
		"numeric-check": method([read_off,
			"Check x = 1: g(1) = %s, then f(%s) = %s" % [N(gx), N(gx), N(ev(f, gx))],
			"h(1) = %s = %s, which agrees" % [CompositePairSituation.put(shown, "1"), N(ev({"t": "poly", "co": h}, x1))], final], ans.values),
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
	var out := {"asked": "Find g(x).", "lines": [fx("f", f), "(f∘g)(x) = %s" % ptext(h)], "answer": ans, "wrongs": [], "fillers": []}
	# Undoing f's steps in the original order: h ÷ m − c instead of (h − c) ÷ m.
	out.wrongs.append_array(pw(ans, CompositePairSituation.padd(CompositePairSituation.pscale(h, Q.new(1).div(m)), [c.neg()]), R_UNDO_ORDER))
	out.wrongs.append_array(pw(ans, CompositePairSituation.padd(h, [c.neg()]), R_ONE_STEP))
	out.wrongs.append_array(pw(ans, CompositePairSituation.pscale(h, Q.new(1).div(m)), R_ONE_STEP))
	out.fillers.append_array(pg(ans, CompositePairSituation.pscale(CompositePairSituation.padd(h, [c]), Q.new(1).div(m))))
	var final := "So %s." % Answer.text(ans)
	var minus := "%s = %s" % [CompositePairSituation.sub_in(lin(m, 0), "g(x)"), ptext(CompositePairSituation.padd(h, [c.neg()]))]
	var whole := ["f(g(x)) = %s = %s" % [rt_g(f), ptext(h)], minus, "g(x) = (%s) ÷ %s" % [ptext(CompositePairSituation.padd(h, [c.neg()])), Fmt.paren(m)], final]
	# Undoing "add c" is taking c away: written h − c, or h + 4 for c = −4.
	var undo_c := Fmt.plus(c.neg())
	var rev := ["f does two things to g(x): %s" % CompositePairSituation.steps_text(CompositePairSituation.rule_steps(f)),
		"Undo them in reverse order: %s" % _undo_text(f),
		"g(x) = (%s%s) ÷ %s" % [ptext(h), undo_c, Fmt.paren(m)], final]
	# g has the degree of f∘g (f is linear), so two inputs fix a linear g and three a
	# quadratic one.
	var quad := CompositePairSituation.degree(g.co) == 2
	var at := func(x: Q) -> String: return "x = %s: g(%s) = (%s%s) ÷ %s = %s" % [N(x), N(x), N(peval(h, x)), undo_c, Fmt.paren(m), N(peval(g.co, x))]
	var numeric := ["Undo f: g(x) = ((f∘g)(x)%s) ÷ %s. Work it out at some inputs" % [undo_c, Fmt.paren(m)], at.call(Q.new(0)),
		at.call(Q.new(1)) + ("; " + at.call(Q.new(-1)) if quad else ""),
		("f is linear, so g is a quadratic like f∘g: the quadratic through these three values is %s" if quad else
			"f is linear, so g is linear like f∘g: the line through these two values is %s") % ptext(g.co), final]
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
	var out := {"asked": "Find f(x).", "lines": [fx("g", g), "(f∘g)(x) = %s" % ptext(h)], "answer": ans, "wrongs": [], "fillers": []}
	# h itself, or f with g's x and constant left in (f(x) = h(x) with x not replaced).
	if CompositePairSituation.degree(h) <= 2:
		out.wrongs.append_array(pw(ans, h, R_H_AS_F))
	var inv := lin(Q.new(1).div(a), b.neg().div(a))
	out.wrongs.append_array(pw(ans, CompositePairSituation.pcompose(h, [b, a]), R_G_NOT_INV))
	out.fillers.append_array(pg(ans, CompositePairSituation.pcompose(h, [b.neg(), a])))
	out.fillers.append_array(pg(ans, CompositePairSituation.pcompose(f.co, [Q.new(0), a])))
	out.fillers.append_array(pg(ans, CompositePairSituation.padd(f.co, [Q.new(1)])))
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
