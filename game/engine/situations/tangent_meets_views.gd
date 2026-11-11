class_name TangentMeetsViews
extends ExtensionViews
## The views on the `tangent-meets-curve` situation: one builder per unknown of
## t5-normal-meets-curve (FAL-754). Every question is Paper 2, as every bank part is. A curve made
## of whole numbers has exact answers, written as decimals where they end; an e^(kx) curve, and
## any point the GDC's intersect finds, is answered to 3 s.f.
##
## Representations: "equation" (f(x) and x₀ in words), "graph" (the same, with the curve and the
## line drawn on a grid and P marked) and "diagram" (an exam's sketch, not to scale: no numbers on
## the axes, and the points lettered).

const SK := "SL5.4.tangent-meets-axes-or-curve#"
const R_CURVE := SK + "0"
const R_DOUBLE := SK + "1"
const R_NEGATIVE := SK + "2"
const R_P := SK + "3"
const R_SWAP := SK + "4"
const R_NORMAL := "SL5.4.normal-equation#0"
const UNKNOWNS := ["tangent-x-intercept", "tangent-y-intercept", "normal-x-intercept", "normal-y-intercept",
	"tangent-triangle-area", "normal-triangle-area", "tangent-meets-again", "tangent-meets-again-gdc", "normal-meets-again"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## Every cell is Paper 2: every part of this type in the bank is.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = TangentMeetsSituation.export(s)
	# An option that types as right is no wrong option: 961/24 to 2 s.f. is 40, which is
	# also 40.0, its 3 s.f., so that rounding trap is no trap.
	var ans: Dictionary = out.answer
	if not out.trap.is_empty() and Answer.values_right(ans, out.trap):
		out.trap = {}
	out.wrongs = out.wrongs.filter(func(w): return not Answer.values_right(ans, w.values, true))
	out.generic = out.generic.filter(func(g): return not Answer.values_right(ans, g, true))
	return out


# ── Writing things ───────────────────────────────────────────

## A number as the working writes it: exact as a decimal where it ends, else a GDC's 6 s.f.
static func T(v: Variant) -> String:
	return Fmt.dec(v) if v is Q else GdcKit.W(v)


## A coefficient in front of x: "", "−", "2.5", "(1/3)", "1.64872".
static func coef(v: Variant) -> String:
	if v is Q:
		if v.eq(1):
			return ""
		if v.eq(-1):
			return "−"
		var t := Fmt.dec(v)
		return t if not t.contains("/") else ("−" if v.sign() < 0 else "") + "(%s)" % Fmt.dec(v.abs_q())
	return GdcKit.W(v)


## y = mx + c as the working writes it.
static func line_text(m: Variant, c: Variant) -> String:
	var out := "y = %sx" % coef(m)
	var cf := TangentMeetsSituation.fl(c)
	if c is Q and c.is_zero():
		return out
	return out + (" − " if cf < 0.0 else " + ") + T(c.abs_q() if c is Q else absf(cf))


## The curve's rule, as f(x) = … shows it.
static func fn_text(s: Dictionary) -> String:
	var f: Dictionary = s.f
	match s.fam:
		"quad":
			return Fmt.poly([f.a, f.b, f.c])
		"cubic":
			return Fmt.poly([f.a, f.b, f.c, f.d])
		"recip":
			return "%sx²%s%s/x%s" % [Fmt.lead(f.p), " − " if f.A.sign() < 0 else " + ", f.A.abs_q().text(), Fmt.plus(f.q) if not f.q.is_zero() else ""]
	return GdcKit.first(f.A, "e^(%sx)" % GdcKit.lead(f.k)) + GdcKit.join(f.p, "x²") + GdcKit.join(f.q, "")


static func dfn_text(s: Dictionary) -> String:
	var f: Dictionary = s.f
	match s.fam:
		"quad":
			return Fmt.poly([f.a.mul(2), f.b])
		"cubic":
			return Fmt.poly([f.a.mul(3), f.b.mul(2), f.c])
		"recip":
			return "%sx%s%s/x²" % [Fmt.lead(f.p.mul(2)), " + " if f.A.sign() < 0 else " − ", f.A.abs_q().text()]
	return GdcKit.first(f.A.mul(f.k), "e^(%sx)" % GdcKit.lead(f.k)) + GdcKit.join(f.p.mul(2), "x")


static func rule_line(s: Dictionary) -> String:
	return "f(x) = %s%s" % [fn_text(s), ", for x ≠ 0" if s.fam == "recip" else ""]


static func shows(s: Dictionary) -> String:
	return "%s(x) = %s" % ["f", fn_text(s)]


## The value a slot holds: a Q as it is, a float as the engine keeps a GDC value.
static func V(v: Variant) -> Q:
	return v if v is Q else GdcKit.qf(v)


static func answer_of(s: Dictionary, kind: String, values: Dictionary, label: String = "") -> Dictionary:
	var vals := {}
	for k in values:
		vals[k] = V(values[k])
	var ans := Answer.make(kind, vals, {}, label)
	ans.show = "sf" if s.sf else "dec"
	return ans


static func wrong_of(values: Dictionary, ref: String = "") -> Dictionary:
	var vals := {}
	for k in values:
		vals[k] = V(values[k])
	return wrong(vals, ref)


static func line_word(s: Dictionary) -> String:
	return s.line


## The lines that say what the curve and P are, and what the figure shows.
static func lines_for(rep: String, s: Dictionary, sketch: String) -> Array:
	var out := [rule_line(s), "P is the point on the curve y = f(x) where x = %s." % Fmt.num(s.x0)]
	if rep == "graph":
		out.append("The graph shows y = f(x) and the %s to the curve at P." % s.line)
	elif rep == "diagram":
		out.append("The diagram, not to scale, shows the curve y = f(x) and the %s at P%s." % [s.line, sketch])
	return out


## The first step: P and the gradient there.
static func point_step(s: Dictionary) -> String:
	var x0 := Fmt.num(s.x0)
	return "f(%s) = %s, so P is (%s, %s). f′(x) = %s, so f′(%s) = %s." % [x0, T(s.y0), x0, T(s.y0), dfn_text(s), x0, T(s.m)]


## The second: the line through P.
static func line_step(s: Dictionary) -> String:
	if s.line == "tangent":
		return "The tangent at P has gradient %s, so it is %s." % [T(s.m), line_text(s.lm, s.lc)]
	var m := T(s.m)
	if TangentMeetsSituation.fl(s.m) < 0.0 or m.contains("/"):
		m = "(%s)" % m
	var g := "−1/" + m
	if g != T(s.lm):
		g += " = " + T(s.lm)
	return "The normal at P has gradient %s, so it is %s." % [g, line_text(s.lm, s.lc)]


## Where y = gm x + gc meets each axis.
static func x_cut(gm: Variant, gc: Variant) -> Variant:
	if gm is Q:
		return gc.neg().div(gm)
	return -float(gc) / float(gm)


## A line through P with the gradient g: its intercept.
static func through_p(s: Dictionary, g: Variant) -> Variant:
	if g is Q:
		return s.y0.sub(g.mul(s.x0))
	return TangentMeetsSituation.fl(s.y0) - float(g) * s.x0


## The wrong normal's gradient: −m, or 1/m when −m is the same line as the normal.
static func wrong_gradient(s: Dictionary, rng: Seeded) -> Variant:
	var m: Variant = s.m
	var neg: Variant = m.neg() if m is Q else -float(m)
	var inv: Variant = Q.new(1).div(m) if m is Q else 1.0 / float(m)
	var pick: Variant = neg if rng.chance(0.5) else inv
	if TangentMeetsSituation.fl(pick) == TangentMeetsSituation.fl(s.lm):
		pick = inv if pick == neg else neg
	return pick


# ── The figure ───────────────────────────────────────────────

## The curve and the line in a window holding P, the marks and (for an intercept) the origin.
## On the graph only P is marked; the diagram letters every mark and leaves the numbers off.
static func figure(rep: String, s: Dictionary, marks: Array, origin: bool, shade: bool = false) -> Variant:
	if rep == "equation":
		return null
	var x0 := float(s.x0)
	var y0 := TangentMeetsSituation.fl(s.y0)
	var xs: Array = [x0]
	var ys: Array = [y0]
	for mk in marks:
		xs.append(mk[0])
		ys.append(mk[1])
	if origin:
		xs.append(0.0)
		ys.append(0.0)
	var win := GdcKit.window(xs.min(), xs.max(), ys.min(), ys.max(), 1.2, 0.2)
	var lo := float(win[0])
	var hi := float(win[1])
	var curve := GdcKit.curve(func(x: float) -> float: return TangentMeetsSituation.fv(s, x), lo, hi)
	if s.fam == "recip":
		# Two branches, one curve: a point off the plot breaks the line across x = 0.
		var left: Array = curve.filter(func(p): return p[0] < 0.0)
		var right: Array = curve.filter(func(p): return p[0] > 0.0)
		curve = left + [[0.0, DerivativeMeaningViews.BREAK_Y]] + right
	var lm := TangentMeetsSituation.fl(s.lm)
	var lc := TangentMeetsSituation.fl(s.lc)
	var line := GdcKit.curve(func(x: float) -> float: return lm * x + lc, lo, hi)
	var points: Array = [[x0, y0, "P"]]
	if rep == "diagram":
		for mk in marks:
			points.append([mk[0], mk[1], mk[2]])
	var g := Plot.spec([curve, line], points, win[0], win[1], win[2], win[3])
	if rep == "diagram":
		g.y_bare = true
		g.x_ticks = [[0.0, ""]]
	if shade:
		var xa := TangentMeetsSituation.fl(s.xa)
		var strips: Array = []
		for i in 41:
			var x := xa * i / 40.0
			var y := lm * x + lc
			strips.append([x, minf(0.0, y), maxf(0.0, y)])
		if xa < 0.0:
			strips.reverse()
		g.shade = [strips]
	return g


# ── The axes ─────────────────────────────────────────────────

func _intercept(rep: String, s: Dictionary, rng: Seeded, axis: String) -> Dictionary:
	var word: String = s.line
	var on_x := axis == "x"
	var name := "A" if on_x else "B"
	var at: Variant = s.xa if on_x else s.yb
	var ans := answer_of(s, "xint" if on_x else "yint", {"x": at} if on_x else {"y": at})
	var key := "x" if on_x else "y"
	var wrongs: Array = []
	var generic: Array = []
	# Putting the other letter to 0 gives the other intercept.
	wrongs.append(wrong_of({key: s.yb if on_x else s.xa}, R_SWAP))
	if not on_x:
		wrongs.append(wrong_of({key: s.f.d if s.fam == "cubic" else (s.f.c if s.fam == "quad" else TangentMeetsSituation.fv(s, 0.0))}, R_CURVE))
	if word == "normal":
		var g: Variant = wrong_gradient(s, rng)
		var c: Variant = through_p(s, g)
		wrongs.append(wrong_of({key: x_cut(g, c) if on_x else c}, R_NORMAL))
	if at is Q:
		for v in [at.neg(), at.add(1), at.sub(1), at.mul(2)]:
			generic.append({key: v})
	else:
		for v in [-at, at + 1.0, at - 1.0, 2.0 * at]:
			generic.append({key: V(v)})
	var sketch := ", which meets the %s-axis at %s" % [axis, name]
	var asked := "The %s to the curve at P meets the %s-axis at %s. Find the coordinates of %s%s." % [word, axis, name, name, ", to 3 s.f" if s.sf else ""]
	var put := "Put %s = 0 in the %s: %s = %s." % ["y" if on_x else "x", word, "x" if on_x else "y", T(at)]
	var steps := [point_step(s), line_step(s), put, "So %s is %s." % [name, Answer.text(ans)]]
	var mark := [TangentMeetsSituation.fl(s.xa), 0.0, "A"] if on_x else [0.0, TangentMeetsSituation.fl(s.yb), "B"]
	var out := {"lines": lines_for(rep, s, sketch), "asked": asked, "answer": ans, "wrongs": wrongs, "generic": generic,
		"methods": {"set-axes-zero": method(steps, ans.values)}, "graph": figure(rep, s, [mark], true)}
	if word == "normal":
		out.titles = {"set-axes-zero": "Put x = 0 and y = 0 in the normal"}
	return out


func u_tangent_x_intercept(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _intercept(rep, s, rng, "x")


func u_tangent_y_intercept(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _intercept(rep, s, rng, "y")


func u_normal_x_intercept(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _intercept(rep, s, rng, "x")


func u_normal_y_intercept(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _intercept(rep, s, rng, "y")


# ── The triangle ─────────────────────────────────────────────

## ½ |x||y|, exactly or as a float.
static func half_area(x: Variant, y: Variant) -> Variant:
	if x is Q:
		return x.mul(y).abs_q().div(2)
	return absf(float(x) * float(y)) / 2.0


func _area(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var word: String = s.line
	var ans := answer_of(s, "number", {"v": s.area}, "area = ")
	var signed: Variant = s.xa.mul(s.yb).div(2) if s.xa is Q else s.xa * s.yb / 2.0
	var wrongs: Array = [wrong_of({"v": signed}, R_NEGATIVE)]
	if word == "normal":
		var g: Variant = wrong_gradient(s, rng)
		var c: Variant = through_p(s, g)
		if TangentMeetsSituation.fl(c) != 0.0:
			wrongs.append(wrong_of({"v": half_area(x_cut(g, c), c)}, R_NORMAL))
	var a: Variant = s.area
	var generic: Array = []
	if a is Q:
		generic = [{"v": a.mul(2)}, {"v": a.div(2)}, {"v": a.add(1)}]
	else:
		generic = [{"v": V(a * 2.0)}, {"v": V(a / 2.0)}, {"v": V(a + 1.0)}]
	var xa: Variant = s.xa
	var yb: Variant = s.yb
	var oa := T(xa.abs_q() if xa is Q else absf(xa))
	var ob := T(yb.abs_q() if yb is Q else absf(yb))
	var steps := [point_step(s), line_step(s),
		"Put y = 0: A is (%s, 0). Put x = 0: B is (0, %s)." % [T(xa), T(yb)],
		"A length is the size of an intercept, never negative: OA = %s and OB = %s." % [oa, ob],
		"½ × OA × OB = ½ × %s × %s, so %s." % [oa, ob, Answer.text(ans)]]
	var asked := "The %s to the curve at P meets the x-axis at A and the y-axis at B. Find the area of the triangle OAB, where O is the origin%s." % [word, ", to 3 s.f" if s.sf else ""]
	var marks := [[TangentMeetsSituation.fl(xa), 0.0, "A"], [0.0, TangentMeetsSituation.fl(yb), "B"]]
	var out := {"lines": lines_for(rep, s, ", which meets the axes at A and B"), "asked": asked, "answer": ans, "wrongs": wrongs,
		"generic": generic, "methods": {"set-axes-zero": method(steps, ans.values)}, "graph": figure(rep, s, marks, true, true)}
	if word == "normal":
		out.titles = {"set-axes-zero": "Put x = 0 and y = 0 in the normal"}
	return out


func u_tangent_triangle_area(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _area(rep, s, rng)


func u_normal_triangle_area(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _area(rep, s, rng)


# ── Meeting the curve again ──────────────────────────────────

## Curve minus tangent, as the working writes it, with = 0: times x for a reciprocal curve.
static func difference_text(s: Dictionary) -> String:
	var f: Dictionary = s.f
	if s.fam == "recip":
		return Fmt.poly([f.p, s.lm.neg(), f.q.sub(s.lc), f.A]) + " = 0"
	return Fmt.poly([f.a, f.b, f.c.sub(s.lm), f.d.sub(s.lc)]) + " = 0"


## The x² coefficient of curve minus tangent, and the leading one.
static func x2_lead(s: Dictionary) -> Array:
	if s.fam == "recip":
		return [s.lm.neg(), s.f.p]
	return [s.f.b, s.f.a]


func _again_points(s: Dictionary, x: Variant) -> Variant:
	var xf := TangentMeetsSituation.fl(x)
	if s.fam == "recip" and absf(xf) < 1e-9:
		return null
	if s.exact and x is Q and not s.sf:
		return {"x": x, "y": TangentMeetsSituation.fq(s, x)}
	return {"x": V(xf), "y": V(TangentMeetsSituation.fv(s, xf))}


func _again(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var word: String = s.line
	var ans := answer_of(s, "point", {"x": s.qx, "y": s.qy})
	var wrongs: Array = [wrong_of({"x": s.x0, "y": s.y0}, R_P)]
	if s.has("slip"):
		var sp: Variant = _again_points(s, s.slip)
		if sp != null:
			wrongs.append(wrong(sp, R_DOUBLE))
	if word == "normal":
		var g: Variant = wrong_gradient(s, rng)
		var c: Variant = through_p(s, g)
		var others := TangentMeetsSituation.meets(s, TangentMeetsSituation.fl(g), TangentMeetsSituation.fl(c))
		if others.size() == 1 and absf(others[0] - s.x0) >= TangentMeetsSituation.GAP and absf(others[0]) <= 4.0 * TangentMeetsSituation.X_MAX:
			wrongs.append(wrong(_again_points(s, others[0]), R_NORMAL))
	var generic: Array = []
	var qx := TangentMeetsSituation.fl(s.qx)
	var qy := TangentMeetsSituation.fl(s.qy)
	if s.exact and not s.sf:
		generic.append({"x": s.qx, "y": s.qy.neg()})
		for x in [s.qx.neg(), s.qx.add(1), s.qx.sub(1)]:
			var p: Variant = _again_points(s, x)
			if p != null:
				generic.append(p)
	else:
		generic.append({"x": V(qx), "y": V(-qy)})
		for x in [-qx, qx + 1.0, qx - 1.0]:
			var p: Variant = _again_points(s, x)
			if p != null:
				generic.append(p)
	var asked := "The %s to the curve at P meets the curve again at Q. Find the coordinates of Q%s." % [word, ", to 3 s.f" if s.sf else ""]
	var line := line_text(s.lm, s.lc)
	var methods := {}
	var meet := "Graph y = f(x) and %s, and use intersect: they meet at x = %s, %s, and at x = %s." % [line, Fmt.num(s.x0),
		"where the tangent touches" if word == "tangent" else "at P", T(s.qx)]
	methods["gdc-intersect"] = method([point_step(s), line_step(s), meet, "f(%s) = %s, so Q is %s." % [T(s.qx), T(s.qy), Answer.text(ans)]], ans.values)
	if s.ask == "tangent-meets-again":
		var x2: Array = x2_lead(s)
		var lead: Q = x2[1]
		var times := "Multiply f(x) = %s by x" % line.trim_prefix("y = ") if s.fam == "recip" else "Put f(x) = %s" % line.trim_prefix("y = ")
		methods["factor-repeated-root"] = method([point_step(s), line_step(s),
			"%s: %s. The tangent touches at P, so %s² is a factor: %s%s²(x − r)." % [times, difference_text(s), Fmt.factor(s.x0), Fmt.lead(lead), Fmt.factor(s.x0)],
			"Compare the x² terms: %s(2 × %s + r) = %s, so r = %s." % [Fmt.lead(lead.neg()), Fmt.paren(s.x0), Fmt.dec(x2[0]), T(s.qx)],
			"f(%s) = %s, so Q is %s." % [T(s.qx), T(s.qy), Answer.text(ans)]], ans.values)
	var sketch := ", which meets the curve again at Q"
	return {"lines": lines_for(rep, s, sketch), "asked": asked, "answer": ans, "wrongs": wrongs, "generic": generic,
		"methods": methods, "graph": figure(rep, s, [[qx, qy, "Q"]], false)}


func u_tangent_meets_again(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _again(rep, s, rng)


func u_tangent_meets_again_gdc(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _again(rep, s, rng)


func u_normal_meets_again(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _again(rep, s, rng)
