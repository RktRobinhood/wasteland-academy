class_name RationalQuadraticViews
extends ExtensionViews
## The views on the `rational-quadratic` situation (FAL-1007): one builder per unknown of
## fn-ahl-rational-quadratic (AA HL 2.13). Builders return what QuadraticViews' builders
## return (see quadratic_views.gd).
##
## Every cell can be Paper 1 or Paper 2, except the GDC methods' (Paper 2 only), and the
## type lands on the bank's share of Paper 2 (almost all of it). Asymptotes, intercepts and
## constants are whole numbers or simple fractions on both papers, marked exactly. A range
## is exact on Paper 1 (its turning values are whole numbers or simple fractions) and to
## 3 s.f. on Paper 2, where the discriminant is not a square.
##
## A sketch is "which of four graphs" (GdcKit.pick), each card with its asymptotes dashed
## (an oblique one as a dashed sand line) and its intercepts marked. Each wrong card changes
## one thing: the numerator's zero dropped (AHL2.13.sketch#0), the oblique asymptote's
## constant dropped (AHL2.13.oblique-asymptote#0), and untagged ones with a `why`.

const SK := "AHL2.13."
const R_VA_NUM := SK + "vertical-asymptotes#0"
const R_VA_SIGNS := SK + "vertical-asymptotes#1"
const R_VA_TWO := SK + "vertical-asymptotes#2"
const R_HA_LEAD := SK + "horizontal-asymptote#0"
const R_HA_NEVER := SK + "horizontal-asymptote#1"
const R_HA_CONST := SK + "horizontal-asymptote#2"
const R_OA_LEAD := SK + "oblique-asymptote#0"
const R_OA_BY_X := SK + "oblique-asymptote#1"
const R_RANGE_NOT_HA := SK + "range-turning-points#0"
const R_RANGE_GAP := SK + "range-turning-points#1"
const R_SK_NO_ZERO := SK + "sketch#0"
const R_SK_YINT := SK + "sketch#1"
## fn-ahl-rational-quadratic's own slips.
const T := "fn-ahl-rational-quadratic#"
const R_E_SIGN := T + "12"
const R_REM_SIGN := T + "13"
const R_XINT_SIGN := T + "14"
const R_HA_IS_VA := T + "15"

const WIN := [-8, 8, -8, 8]
const SAMPLES := 240


func needs() -> Dictionary:
	return {
		"vertical-asymptotes-lq": {"form": "lq", "den": "any"},
		"vertical-asymptote-ql": {"form": "ql", "roots": true},
		"denominator-from-asymptote": {"form": "any", "den": "two"},
		"horizontal-asymptote": {"form": "lq", "den": "two"},
		"crosses-horizontal": {"form": "lq", "den": "two"},
		"x-intercepts-ql": {"form": "ql", "roots": true},
		"oblique-asymptote": {"form": "ql"},
		"coefficient-from-oblique": {"form": "ql"},
		"range-lq": {"form": "lq", "den": "none", "range": true},
		"range-ql": {"form": "ql", "turns": true, "range": true},
		"sketch-lq": {"form": "lq", "den": "two", "graph": true},
		"sketch-ql": {"form": "ql", "roots": true, "graph": true},
	}


## A graph shows whole asymptotes and intercepts inside the plot.
func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	if rep == "graph":
		n.graph = true
		if n.get("form", "") == "any":
			n.roots = true
	return n


## Every cell can be either paper; QuestionEngine makes the GDC methods' Paper 2.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1, 2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	var own: Dictionary = out.get("given", {}) if out.get("given") != null else {}
	out.given = RationalQuadraticSituation.export(s)
	out.given.merge(ExtensionViews.export(own), true)
	return out


# ── Writing f ────────────────────────────────────────────────

static func bracket(t: String) -> String:
	return t if not " " in t else "(%s)" % t


static func lq_num(s: Dictionary) -> String:
	return Fmt.poly([s.a, s.b])


static func lq_den(s: Dictionary) -> String:
	return Fmt.poly([1, s.p, s.q])


static func ql_num(s: Dictionary) -> String:
	return Fmt.poly([s.m, s.b, s.c])


static func ql_den(s: Dictionary) -> String:
	return Fmt.poly([1, s.e])


static func text(s: Dictionary) -> String:
	if s.form == "lq":
		return "%s/%s" % [bracket(lq_num(s)), bracket(lq_den(s))]
	return "%s/%s" % [bracket(ql_num(s)), bracket(ql_den(s))]


static func fx(s: Dictionary) -> String:
	return "f(x) = " + text(s)


static func y_at(s: Dictionary, x: float) -> float:
	return RationalQuadraticSituation.lq_y(s, x) if s.form == "lq" else RationalQuadraticSituation.ql_y(s, x)


## A value as the answer writes it: exact, or to 3 s.f.
static func V(v: Variant) -> String:
	return Fmt.num(v) if v is Q else Fmt.sf(v)


## A value as the working writes it: exact, or to 6 s.f. as a GDC shows it.
static func Wv(v: Variant) -> String:
	return Fmt.num(v) if v is Q else GdcKit.W(v)


static func F(v: Variant) -> float:
	return v.to_float() if v is Q else float(v)


## "x = −2 and x = 3".
static func xs_and(xs: Array) -> String:
	var sorted := xs.duplicate()
	sorted.sort_custom(func(p, q): return F(p) < F(q))
	return " and ".join(sorted.map(func(x): return "x = " + Fmt.num(x)))


## The denominator of an lq with two zeros (or one, repeated) as factors.
static func den_factors(s: Dictionary) -> String:
	if s.zs.size() == 1:
		return "%s²" % Fmt.factor(s.zs[0])
	return Fmt.factor(s.zs[0]) + Fmt.factor(s.zs[1])


## A choice answer: the right text and the slips' texts as its options, then the fillers.
static func choice(right: String, wrongs: Array, fillers: Array) -> Dictionary:
	var opts: Array = [right]
	var ws: Array = []
	for w in wrongs:
		if not w.values.v in opts:
			opts.append(w.values.v)
			ws.append(w)
	var fs: Array = []
	for f in fillers:
		if not f in opts:
			opts.append(f)
			fs.append({"v": f})
	var ans := Answer.make("choice", {"v": right}, {"options": opts})
	return {"answer": ans, "wrongs": ws, "fillers": fs}


static func cw(t: String, ref: String) -> Dictionary:
	return wrong({"v": t}, ref)


static func axis_ans(v: String, q: Variant) -> Dictionary:
	var ans := Answer.make("axis", {"var": v, "h": Q.of(q)})
	ans.exact = true
	return ans


static func _axis(v: String, q: Variant) -> Dictionary:
	return {"var": v, "h": Q.of(q)}


static func num_ans(label: String, q: Variant) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.of(q)}, {}, label)
	ans.exact = true
	return ans


## A range written as an inequality on f(x).
static func between(lo: Variant, hi: Variant, strict: bool = false) -> String:
	var r := "<" if strict else "≤"
	return "%s %s f(x) %s %s" % [V(lo), r, r, V(hi)]


static func outside(lo: Variant, hi: Variant, strict: bool = false) -> String:
	return "f(x) %s %s or f(x) %s %s" % ["<" if strict else "≤", V(lo), ">" if strict else "≥", V(hi)]


## f near x = r on a GDC's table: "f(2.99) = −700 and f(3.01) = 700".
static func near(s: Dictionary, r: int) -> String:
	var lo := Q.new(r * 1000 - 1, 1000)
	var hi := Q.new(r * 1000 + 1, 1000)
	return "f(%s) = %s and f(%s) = %s" % [Fmt.dec(lo), Fmt.sf(y_at(s, lo.to_float())), Fmt.dec(hi), Fmt.sf(y_at(s, hi.to_float()))]


static func p2(s: Dictionary) -> bool:
	return s.get("paper", 1) == 2


# ── Vertical asymptotes ──────────────────────────────────────

func u_vertical_asymptotes_lq(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var zs: Array = s.zs
	var right: String
	var wrongs: Array = [cw("x = " + Fmt.num(s.z), R_VA_NUM)]
	var fillers: Array = []
	match zs.size():
		2:
			right = xs_and(zs)
			wrongs.append(cw(xs_and([-zs[0], -zs[1]]), R_VA_SIGNS))
			fillers = ["no vertical asymptotes", xs_and([zs[0], s.z]), "x = " + Fmt.num(zs[1])]
		1:
			right = "x = " + Fmt.num(zs[0])
			wrongs.append(cw("x = " + Fmt.num(-zs[0]), R_VA_SIGNS))
			fillers = ["no vertical asymptotes", xs_and([zs[0], s.z])]
		_:
			right = "no vertical asymptotes"
			wrongs.append(cw(xs_and(s.fake), R_VA_TWO))
			fillers = ["x = " + Fmt.num(s.z.neg()), "x = " + Fmt.num(-s.p / 2) if s.p != 0 else "x = " + Fmt.num(s.q)]
	var out := choice(right, wrongs, fillers)
	out.asked = "Find the equations of any vertical asymptotes of the graph of y = f(x)."
	out.lines = [fx(s)]
	var fin := "So the graph has %s." % right if zs.is_empty() else "So the vertical %s %s." % ["asymptotes are" if zs.size() == 2 else "asymptote is", right]
	var dd: int = s.p * s.p - 4 * s.q
	var disc := "The denominator's discriminant is %s² − 4 × 1 × %s = %s." % [Fmt.paren(s.p), Fmt.paren(s.q), Fmt.num(dd)]
	var num_ok := ""
	if zs.size() == 2:
		num_ok = "The numerator %s is not zero at either, so each is a vertical asymptote." % lq_num(s)
	elif zs.size() == 1:
		num_ok = "The numerator %s is not zero there, so it is a vertical asymptote." % lq_num(s)
	out.methods = {}
	match zs.size():
		2:
			out.methods["factorise-denominator"] = method(["Factorise the denominator: %s = %s." % [lq_den(s), den_factors(s)],
				"It is zero at %s. %s" % [xs_and(zs), num_ok], fin], out.answer.values)
			out.methods["discriminant-count"] = method([disc,
				"%s > 0, so the denominator has two real zeros: x = (%s ± %s)/2 gives %s." % [Fmt.num(dd), Fmt.num(-s.p), Fmt.num(zs[1] - zs[0]), xs_and(zs)],
				num_ok, fin], out.answer.values)
			out.methods["gdc-table-near"] = method(["Graph y = f(x) on the GDC: the curve runs off the screen near x = %s and near x = %s." % [Fmt.num(zs[0]), Fmt.num(zs[1])],
				"A table near each: %s; %s. The values grow without bound." % [near(s, zs[0]), near(s, zs[1])], fin], out.answer.values)
		1:
			out.methods["factorise-denominator"] = method(["Factorise the denominator: %s = %s." % [lq_den(s), den_factors(s)],
				"It is zero only at x = %s. %s" % [Fmt.num(zs[0]), num_ok], fin], out.answer.values)
			out.methods["discriminant-count"] = method([disc,
				"The discriminant is 0, so the denominator has one repeated zero, x = %s/2 = %s." % [Fmt.num(-s.p), Fmt.num(zs[0])],
				num_ok, fin], out.answer.values)
		_:
			out.methods["discriminant-count"] = method([disc,
				"%s < 0, so %s = 0 has no real roots: the denominator is never zero." % [Fmt.num(dd), lq_den(s)],
				"f is defined for every x. " + fin], out.answer.values)
	return out


func u_vertical_asymptote_ql(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var h := -int(s.e)
	var ans := axis_ans("x", h)
	var root: int = s.roots[rng.int_in(0, 1)]
	var fin := "So the vertical asymptote is %s." % Answer.text(ans)
	var num_at := "At x = %s the numerator %s is %s, not 0, so f(x) grows without bound there." % [Fmt.num(h), ql_num(s), Fmt.num(s.R)]
	return {
		"asked": "Write down the equation of the vertical asymptote of the graph of y = f(x).", "lines": [fx(s)], "answer": ans,
		"wrongs": [wrong(_axis("x", root), R_VA_NUM), wrong(_axis("x", s.e), R_E_SIGN)],
		"fillers": [_axis("y", h), _axis("x", s.k), _axis("y", s.e)],
		"methods": {
			"factorise-denominator": method(["The denominator %s is zero at x = %s." % [ql_den(s), Fmt.num(h)], num_at, fin], ans.values),
			"gdc-table-near": method(["Graph y = f(x) on the GDC: the curve runs off the screen near x = %s." % Fmt.num(h),
				"A table near it: %s. The values grow without bound." % near(s, h), fin], ans.values),
		},
	}


func u_denominator_from_asymptote(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var graph: Variant = null
	var shown := "The graph of y = f(x) is shown, with its asymptotes dashed."
	if s.form == "lq":
		var r: int = s.zs[rng.int_in(0, 1)]
		var other: int = s.zs[1] if r == s.zs[0] else s.zs[0]
		var ans := num_ans("k = ", s.p)
		var lines := ["f(x) = %s/(x² + kx %s %s), where k is a constant." % [bracket(lq_num(s)), "+" if s.q > 0 else "−", Fmt.num(absi(s.q))]]
		var read := "The graph has a vertical asymptote x = %s, so the denominator is zero there." % Fmt.num(r)
		if rep == "graph":
			lines.append(shown)
			graph = plot(s)
		else:
			lines.append("The graph of y = f(x) has a vertical asymptote x = %s." % Fmt.num(r))
			read = "x = %s is a vertical asymptote, so the denominator is zero there." % Fmt.num(r)
		var fin := "So %s." % Answer.text(ans)
		var solved := "%sk = %s and k = %s" % [Fmt.lead(r), Fmt.num(-(r * r + s.q)), Fmt.num(s.p)] if r != 1 else "k = %s" % Fmt.num(s.p)
		return {"asked": "Find the value of k.", "lines": lines, "answer": ans, "graph": graph, "given": {"at": r},
			"wrongs": [wrong({"v": Q.new(-s.p)}, R_E_SIGN)],
			"fillers": [{"v": Q.new(r)}, {"v": Q.new(-r)}, {"v": Q.new(other)}, {"v": Q.new(s.p + 1)}],
			"methods": {"factorise-denominator": method([read,
				"Put x = %s: %s %s %sk %s %s = 0, so %s." % [Fmt.num(r), Fmt.num(r * r), "+" if r > 0 else "−", Fmt.lead(absi(r)),
					"+" if s.q > 0 else "−", Fmt.num(absi(s.q)), solved],
				"Then the denominator is %s = %s, and the numerator %s is not zero at x = %s or x = %s." % [lq_den(s), den_factors(s), lq_num(s), Fmt.num(s.zs[0]), Fmt.num(s.zs[1])],
				fin], ans.values)}}
	var h := -int(s.e)
	var ans := num_ans("k = ", s.e)
	var lines := ["f(x) = %s/(x + k), where k is a constant." % bracket(ql_num(s))]
	var read := "The graph has the vertical asymptote x = %s, so the denominator x + k is zero at x = %s." % [Fmt.num(h), Fmt.num(h)]
	if rep == "graph":
		lines.append(shown)
		graph = plot(s)
	else:
		lines.append("The graph of y = f(x) has a vertical asymptote x = %s." % Fmt.num(h))
		read = "x = %s is a vertical asymptote, so the denominator x + k is zero at x = %s." % [Fmt.num(h), Fmt.num(h)]
	var fin := "So %s." % Answer.text(ans)
	return {"asked": "Find the value of k.", "lines": lines, "answer": ans, "graph": graph, "given": {"at": h},
		"wrongs": [wrong({"v": Q.new(h)}, R_E_SIGN)],
		"fillers": [{"v": Q.new(s.c)}, {"v": Q.new(s.k)}, {"v": Q.new(s.e + 1)}, {"v": Q.new(s.e - 1)}],
		"methods": {"factorise-denominator": method([read,
			"%s + k = 0, so k = %s." % [Fmt.num(h), Fmt.num(s.e)],
			"Check: at x = %s the numerator %s is %s, not 0, so x = %s is an asymptote and not a gap. %s" % [Fmt.num(h), ql_num(s), Fmt.num(s.R), Fmt.num(h), fin]],
			ans.values)}}


# ── The horizontal asymptote ─────────────────────────────────

## c/xⁿ joined on with its sign: " + 2/x", " − 6/x²"; the first term "2/x", "−3/x".
static func over_x(c: int, power: int, first: bool) -> String:
	var body := "%d/x%s" % [absi(c), "²" if power == 2 else ""]
	if first:
		return ("−" if c < 0 else "") + body
	return (" − " if c < 0 else " + ") + body


func u_horizontal_asymptote(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := axis_ans("y", 0)
	var r: int = s.zs[rng.int_in(0, 1)]
	var fin := "So the horizontal asymptote is y = 0."
	var top := over_x(s.a, 1, true) + over_x(s.b, 2, false)
	var bottom := "1" + (over_x(s.p, 1, false) if s.p != 0 else "") + over_x(s.q, 2, false)
	return {
		"asked": "Write down the equation of the horizontal asymptote of the graph of y = f(x).", "lines": [fx(s)], "answer": ans,
		"wrongs": [wrong(_axis("y", s.a), R_HA_LEAD), wrong(_axis("y", Q.new(s.b, s.q)), R_HA_CONST), wrong(_axis("y", r), R_HA_IS_VA)],
		"fillers": [_axis("x", 0), _axis("y", s.z)],
		"methods": {
			"degree-comparison": method(["The numerator %s has degree 1 and the denominator %s has degree 2." % [lq_num(s), lq_den(s)],
				"The denominator has the higher degree, so f(x) → 0 as x → ±∞.", fin], ans.values),
			"divide-by-x-squared": method(["Divide the numerator and the denominator by x²: f(x) = (%s)/(%s)." % [top, bottom],
				"As x → ±∞ every term with x in its denominator tends to 0, so f(x) tends to 0/1 = 0.", fin], ans.values),
			"gdc-large-x": method(["Make a table of f on the GDC at large x: f(1000) = %s and f(−1000) = %s." % [Fmt.sf(y_at(s, 1000.0)), Fmt.sf(y_at(s, -1000.0))],
				"The values get closer and closer to 0 as x grows either way.", fin], ans.values),
		},
	}


func u_crosses_horizontal(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := Fmt.point(s.z, 0)
	var out := choice(right, [cw("it never crosses its horizontal asymptote", R_HA_NEVER)],
		[Fmt.point(0, s.yi), Fmt.point(s.z.neg(), 0), Fmt.point(s.zs[0], 0)])
	out.asked = "Find the coordinates of any point where the graph of y = f(x) crosses its horizontal asymptote."
	out.lines = [fx(s)]
	out.methods = {"solve-f-equals-zero": method([
		"The denominator has the higher degree, so the horizontal asymptote is y = 0.",
		"f(x) = 0 where the numerator is zero: %s = 0 gives x = %s, and the denominator is not zero there." % [lq_num(s), Fmt.num(s.z)],
		"So the graph crosses its horizontal asymptote at %s." % right], out.answer.values)}
	return out


# ── Intercepts ───────────────────────────────────────────────

func u_x_intercepts_ql(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	if rng.chance(0.5):
		var ans := Answer.make("yint", {"y": s.yi})
		ans.exact = true
		var fin := "So the graph meets the y-axis at %s." % Answer.text(ans)
		var shown := Fmt.dec(s.yi)
		if "/" in shown:
			shown = GdcKit.W(s.yi.to_float())
		var gdc := "The GDC gives f(0) = %s%s." % [shown, "" if s.yi.is_int() else ", which is " + Fmt.num(s.yi)]
		return {"asked": "Find the coordinates of the point where the graph of y = f(x) meets the y-axis.", "lines": [fx(s)], "answer": ans,
			"given": {"ask": "y"},
			"wrongs": [wrong({"y": Q.new(s.m)}, R_SK_YINT)],
			"fillers": [{"y": Q.new(s.c)}, {"y": s.yi.neg()}, {"y": Q.new(s.k)}, {"y": Q.new(s.e, s.c)}],
			"methods": {
				"asymptotes-intercepts-signs": method(["The graph meets the y-axis where x = 0.",
					"f(0) = %s/%s = %s." % [Fmt.num(s.c), Fmt.num(s.e), Fmt.num(s.yi)], fin], ans.values),
				"gdc-transfer": method(["Graph y = f(x) on the GDC and read the value at x = 0.", gdc, fin], ans.values),
			}}
	var r: Array = s.roots
	var ans := pts_ans(r)
	var fin := "So the graph meets the x-axis at %s." % Answer.text(ans)
	return {"asked": "Find the coordinates of the points where the graph of y = f(x) meets the x-axis.", "lines": [fx(s)], "answer": ans,
		"given": {"ask": "x"},
		"wrongs": [wrong(pts_values([-r[0], -r[1]]), R_XINT_SIGN)],
		"fillers": [pts_values([r[0], -s.e]), pts_values([-s.e, r[1]]), pts_values([-r[0], r[1]])],
		"methods": {
			"asymptotes-intercepts-signs": method(["The graph meets the x-axis where the numerator is zero, as long as the denominator is not zero there.",
				"%s = %s = 0 gives %s, and neither is x = %s." % [ql_num(s), Fmt.lead(s.m) + Fmt.factor(r[0]) + Fmt.factor(r[1]), xs_and(r), Fmt.num(-s.e)], fin], ans.values),
			"gdc-transfer": method(["Graph y = f(x) on the GDC and find where it meets the x-axis.", "The GDC gives the zeros %s." % xs_and(r), fin], ans.values),
		}}


static func pts_values(xs: Array) -> Dictionary:
	return {"n": 2, "x0": Q.of(xs[0]), "y0": Q.new(0), "x1": Q.of(xs[1]), "y1": Q.new(0)}


static func pts_ans(xs: Array) -> Dictionary:
	var ans := Answer.make("pts", pts_values(xs))
	ans.exact = true
	return ans


# ── The oblique asymptote ────────────────────────────────────

## "f(x) − 2x", "f(x) + x".
static func minus_mx(m: int) -> String:
	return "f(x) %s %sx" % ["−" if m > 0 else "+", Fmt.lead(absi(m))]


## "2x(x − 1) = 2x² − 2x".
static func times(m: int, s: Dictionary) -> String:
	return "%sx(%s) = %s" % [Fmt.lead(m), ql_den(s), Fmt.poly([m, m * s.e, 0])]


func u_oblique_asymptote(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: int = s.m
	var k: int = s.k
	var ans := Answer.make("line", {"m": Q.new(m), "c": Q.new(k)})
	ans.exact = true
	var fin := "So the oblique asymptote is %s." % Answer.text(ans)
	var split := "f(x) = %s%s/(%s)" % [Fmt.poly([m, k]), " + %d" % s.R if s.R > 0 else " − %d" % -s.R, ql_den(s)]
	return {
		"asked": "Find the equation of the oblique asymptote of the graph of y = f(x).", "lines": [fx(s)], "answer": ans,
		"wrongs": [wrong({"m": Q.new(m), "c": Q.new(0)}, R_OA_LEAD), wrong({"m": Q.new(m), "c": Q.new(s.b)}, R_OA_BY_X),
			wrong({"m": Q.new(m), "c": Q.new(s.b + m * s.e)}, R_REM_SIGN)],
		"fillers": [{"m": Q.new(-m), "c": Q.new(k)}, {"m": Q.new(m), "c": Q.new(-k)}, {"m": Q.new(m), "c": Q.new(k + 1)}],
		"methods": {
			"polynomial-division": method([
				"Divide %s by %s. The quotient starts %s, and %s leaves %s." % [ql_num(s), ql_den(s), Fmt.lead(m) + "x", times(m, s), Fmt.poly([k, s.c])],
				"The next term is %s: %s × (%s) = %s leaves %s, so %s." % [Fmt.num(k), Fmt.num(k), ql_den(s), Fmt.poly([k, k * s.e]), Fmt.num(s.R), split],
				"%s/(%s) → 0 as x → ±∞. %s" % [Fmt.num(s.R), ql_den(s), fin]], ans.values),
			"compare-coefficients": method([
				"Write %s = (%sx + A)(%s) + B for constants A and B." % [ql_num(s), Fmt.lead(m), ql_den(s)],
				"Compare the x terms: %s = %s + A, so A = %s. Compare the constants: %s = %sA + B, so B = %s." % [Fmt.num(s.b), Fmt.num(m * s.e), Fmt.num(k), Fmt.num(s.c), Fmt.lead(s.e), Fmt.num(s.R)],
				"So %s, and the fraction tends to 0 for large x. %s" % [split, fin]], ans.values),
			"large-x-behaviour": method([
				"%s = (%s − (%s))/(%s) = %s/(%s)." % [minus_mx(m), ql_num(s), Fmt.poly([m, m * s.e, 0]), ql_den(s), bracket(Fmt.poly([k, s.c])), ql_den(s)],
				"As x → ±∞ that fraction tends to %s, so f(x) gets closer and closer to %s." % [Fmt.num(k), Fmt.poly([m, k])],
				fin], ans.values),
		},
	}


func u_coefficient_from_oblique(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: int = s.m
	var k: int = s.k
	var b: int = s.b
	var me: int = m * s.e
	var ans := num_ans("k = ", b)
	var line := "y = " + Fmt.poly([m, k])
	var shown := "%sx² + kx %s %s" % [Fmt.lead(m), "+" if s.c > 0 else "−", Fmt.num(absi(s.c))]
	var fin := "So %s." % Answer.text(ans)
	return {
		"asked": "Find the value of k.", "answer": ans,
		"lines": ["f(x) = (%s)/(%s), where k is a constant." % [shown, ql_den(s)], "The graph of y = f(x) has the oblique asymptote %s." % line],
		"wrongs": [wrong({"v": Q.new(k - me)}, R_REM_SIGN)],
		"fillers": [{"v": Q.new(k)}, {"v": Q.new(-b)}, {"v": Q.new(b + m)}, {"v": Q.new(me)}],
		"methods": {
			"polynomial-division": method([
				"Divide %s by %s: %s leaves (k %s %s)x %s %s." % [shown, ql_den(s), times(m, s), "−" if me > 0 else "+", Fmt.num(absi(me)), "+" if s.c > 0 else "−", Fmt.num(absi(s.c))],
				"So the quotient is %sx + (k %s %s), and the oblique asymptote is y = %sx + k %s %s." % [Fmt.lead(m), "−" if me > 0 else "+", Fmt.num(absi(me)), Fmt.lead(m), "−" if me > 0 else "+", Fmt.num(absi(me))],
				"It is %s, so k %s %s = %s and k = %s." % [line, "−" if me > 0 else "+", Fmt.num(absi(me)), Fmt.num(k), Fmt.num(b)]], ans.values),
			"compare-coefficients": method([
				"The oblique asymptote is %s, so %s = (%s)(%s) + r for a constant r." % [line, shown, Fmt.poly([m, k]), ql_den(s)],
				"(%s)(%s) = %s." % [Fmt.poly([m, k]), ql_den(s), Fmt.poly([m, me + k, k * s.e])],
				"Compare the x terms: k = %s%s." % [Fmt.num(me), Fmt.plus(k)], fin], ans.values),
		},
	}


# ── The range ────────────────────────────────────────────────

func u_range_lq(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var lo: Variant = s.ylo
	var hi: Variant = s.yhi
	var right := between(lo, hi)
	var out := choice(right, [cw("f(x) ≠ 0", R_RANGE_NOT_HA)],
		[between(lo, hi, true), between(s.xlo, s.xhi) if F(s.xlo) < F(s.xhi) else between(s.xhi, s.xlo), between(-F(hi) if not hi is Q else hi.neg(), -F(lo) if not lo is Q else lo.neg())])
	out.asked = "Find the range of f."
	out.lines = [fx(s)]
	var a: int = s.a
	var b: int = s.b
	var p: int = s.p
	var q: int = s.q
	var dd: int = p * p - 4 * q
	var fin := "So the range is %s." % right
	var exact := lo is Q
	var where := "x = %s and x = %s" % [Wv(s.xlo), Wv(s.xhi)]
	var vals := "f(%s) = %s is the least value and f(%s) = %s the greatest" % [Wv(s.xlo), Wv(lo), Wv(s.xhi), Wv(hi)]
	# ax² + 2bx + (bp − aq) = 0, written with a positive x² term: x = (−b ± √E)/a.
	var sg := 1 if a > 0 else -1
	var turn_eq := Fmt.poly([sg * a, sg * 2 * b, sg * (b * p - a * q)]) + " = 0"
	var surd := "√%s" % Fmt.num(s.E) if not exact else Fmt.num(RationalQuadraticSituation.isqrt(s.E))
	var turn_x := "%s ± %s" % [Fmt.num(-sg * b), surd] if sg * b != 0 else "±" + surd
	if absi(a) != 1:
		turn_x = "(%s)/%s" % [turn_x, Fmt.num(absi(a))]
	var turn_solve := "%s, so x = %s, that is %s." % [turn_eq, turn_x, where]
	var y_quad := Fmt.poly([dd, 4 * b - 2 * a * p, a * a], "y") + " ≥ 0"
	var y_zeros := "Its zeros are y = %s and y = %s%s, and it is negative outside them (its y² coefficient is negative)." % [Wv(lo), Wv(hi), "" if exact else " (6 s.f.)"]
	out.methods = {
		"degree-comparison": method([
			"The denominator has the higher degree, so f(x) → 0 at both ends; its discriminant is %s < 0, so there is no vertical asymptote and f is one unbroken curve." % Fmt.num(dd),
			"f′(x) = 0 where %s" % turn_solve,
			vals + ", since f(x) → 0 at both ends.",
			fin], out.answer.values),
		"discriminant-in-x": method([
			"Let y = f(x): y(%s) = %s, so yx² + (%sy %s %s)x + (%sy %s %s) = 0." % [lq_den(s), lq_num(s), Fmt.lead(p) if p != 0 else "0", "−" if a > 0 else "+", Fmt.num(absi(a)), Fmt.lead(q), "−" if b > 0 else "+", Fmt.num(absi(b))],
			"x is real when the discriminant is at least 0: %s." % y_quad,
			y_zeros, fin], out.answer.values),
		"stationary-points": method([
			"f′(x) = (%s(%s) − (%s)(%s))/(%s)² = (%s)/(%s)²." % [Fmt.lead(a), lq_den(s), lq_num(s), Fmt.poly([2, p]), lq_den(s), Fmt.poly([-a, -2 * b, a * q - b * p]), lq_den(s)],
			"f′(x) = 0 where %s" % turn_solve,
			vals + ", since f(x) → 0 at both ends.", fin], out.answer.values),
		"gdc-max-min": method([
			"Graph y = f(x) on the GDC: one unbroken curve that tends to 0 at both ends.",
			"The GDC's minimum is (%s, %s) and its maximum is (%s, %s)." % [GdcKit.W(F(s.xlo)), GdcKit.W(F(lo)), GdcKit.W(F(s.xhi)), GdcKit.W(F(hi))],
			fin], out.answer.values),
	}
	if p == 0:
		out.methods["discriminant-in-x"].steps[0] = "Let y = f(x): y(%s) = %s, so yx² %s %sx + (%sy %s %s) = 0." % [lq_den(s), lq_num(s), "−" if a > 0 else "+", Fmt.lead(absi(a)), Fmt.lead(q), "−" if b > 0 else "+", Fmt.num(absi(b))]
	return out


func u_range_ql(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: Variant = s.L
	var U: Variant = s.U
	var never := rng.chance(0.5)
	var out: Dictionary
	var fin: String
	if never:
		var right := between(L, U, true)
		out = choice(right, [], [outside(L, U), between(L, U), outside(L, U, true), between(s.xL, s.xU, true) if F(s.xL) < F(s.xU) else between(s.xU, s.xL, true)])
		out.asked = "Find the set of values that f(x) never takes."
		fin = "So f(x) never takes the values %s." % right
	else:
		var right := outside(L, U)
		out = choice(right, [cw(between(L, U, true), R_RANGE_GAP)], [between(L, U), outside(L, U, true), outside(s.xL, s.xU) if F(s.xL) < F(s.xU) else outside(s.xU, s.xL)])
		out.asked = "Find the range of f."
		fin = "So the range is %s." % right
	out.given = {"ask": "never" if never else "range"}
	out.lines = [fx(s)]
	var m: int = s.m
	var e: int = s.e
	var exact := L is Q
	var sq := "√(%s)" % Fmt.num(Q.new(s.R, m)) if not Q.new(s.R, m).is_int() else "√%s" % Fmt.num(Q.new(s.R, m))
	var y_quad := Fmt.poly([1, 4 * m * e - 2 * s.b, s.b * s.b - 4 * m * s.c], "y") + " ≥ 0"
	var c_ey := "%s %s %sy" % [Fmt.num(s.c), "−" if e > 0 else "+", Fmt.lead(absi(e))]
	var turns := "f has a local maximum (%s, %s) and a local minimum (%s, %s), on the two branches." % [Wv(s.xL), Wv(L), Wv(s.xU), Wv(U)]
	out.methods = {
		"discriminant-in-x": method([
			"Let y = f(x): y(%s) = %s, so %sx² + (%s − y)x + (%s) = 0." % [ql_den(s), ql_num(s), Fmt.lead(m), Fmt.num(s.b), c_ey],
			"x is real when (%s − y)² − 4 × %s × (%s) ≥ 0, that is %s." % [Fmt.num(s.b), Fmt.paren(m), c_ey, y_quad],
			"Its zeros are y = %s and y = %s%s, and it is at least 0 outside them." % [Wv(L), Wv(U), "" if exact else " (6 s.f.)"],
			fin], out.answer.values),
		"stationary-points": method([
			"Divide: f(x) = %s%s/(%s), so f′(x) = %s %s %s/(%s)²." % [Fmt.poly([m, s.k]), " + %d" % s.R if s.R > 0 else " − %d" % -s.R, ql_den(s), Fmt.num(m), "−" if s.R > 0 else "+", Fmt.num(absi(s.R)), ql_den(s)],
			"f′(x) = 0 where (%s)² = %s, so x = %s ± %s." % [ql_den(s), Fmt.num(Q.new(s.R, m)), Fmt.num(-e), sq],
			turns, fin], out.answer.values),
		"gdc-max-min": method([
			"Graph y = f(x) on the GDC: two branches, either side of x = %s." % Fmt.num(-e),
			"The GDC gives a local maximum of %s at x = %s and a local minimum of %s at x = %s." % [GdcKit.W(F(L)), GdcKit.W(F(s.xL)), GdcKit.W(F(U)), GdcKit.W(F(s.xU))],
			"Each branch runs off to infinity, so the curve takes every value except those between them. " + fin], out.answer.values),
	}
	return out


# ── Graphs ───────────────────────────────────────────────────

## The pieces of y = g(x) inside the window, between the breaks (its vertical asymptotes):
## each a polyline [[x, y], ...] that runs to the window's edge where it leaves, found by
## bisection, so no piece is drawn across an asymptote. With `across`, the pieces joined.
static func trace(g: Callable, breaks: Array, across: bool = false) -> Array:
	var cuts: Array = [float(WIN[0])]
	for x in breaks:
		if x > WIN[0] and x < WIN[1]:
			cuts.append(float(x))
	cuts.append(float(WIN[1]))
	var out: Array = []
	for i in cuts.size() - 1:
		var x0: float = cuts[i] + (1e-4 if i > 0 else 0.0)
		var x1: float = cuts[i + 1] - (1e-4 if i < cuts.size() - 2 else 0.0)
		var line: Array = []
		var prev := []
		for j in SAMPLES + 1:
			var x := x0 + (x1 - x0) * float(j) / SAMPLES
			var y: float = g.call(x)
			var inside := y >= WIN[2] and y <= WIN[3]
			if not prev.is_empty() and prev[2] != inside:
				var edge: float = WIN[3] if (y > WIN[3] or prev[1] > WIN[3]) else WIN[2]
				var xe := _edge(g, prev[0], x, edge)
				line.append([xe, edge])
				if not inside:
					out.append(line)
					line = []
			if inside:
				line.append([x, y])
			prev = [x, y, inside]
		if line.size() > 1:
			out.append(line)
	out = out.filter(func(l): return l.size() > 1)
	if across and out.size() > 1:
		var joined: Array = []
		for l in out:
			joined += l
		return [joined]
	return out


## Where g crosses y = edge between xa and xb (one side in the window, the other out).
static func _edge(g: Callable, xa: float, xb: float, edge: float) -> float:
	var fa: float = g.call(xa) - edge
	for i in 60:
		var xm := (xa + xb) / 2.0
		var fm: float = g.call(xm) - edge
		if (fm < 0.0) == (fa < 0.0):
			xa = xm
			fa = fm
		else:
			xb = xm
	return (xa + xb) / 2.0


## The line y = mx + k as dashes inside the window: an oblique asymptote.
static func dashes(m: float, k: float) -> Array:
	var out: Array = []
	var step := 0.6 / sqrt(1.0 + m * m)
	var x := float(WIN[0])
	while x < WIN[1]:
		var xb := minf(x + step * 0.5, float(WIN[1]))
		var ya := m * x + k
		var yb := m * xb + k
		if ya >= WIN[2] and ya <= WIN[3] and yb >= WIN[2] and yb <= WIN[3]:
			out.append([[x, ya], [xb, yb]])
		x += step
	return out


## A card's function: "lq" {n1, n0, v} is (n1·x + n0)/((x − v₀)(x − v₁)); "ql" {M, K, R, v} is
## Mx + K + R/(x − v).
static func g_of(c: Dictionary) -> Callable:
	if c.kind == "lq":
		return func(x: float) -> float: return (c.n1 * x + c.n0) / ((x - c.v[0]) * (x - c.v[1]))
	return func(x: float) -> float: return c.M * x + c.K + c.R / (x - c.v[0])


## Its intercepts inside the window: [[x, y, ""]].
static func dots(c: Dictionary) -> Array:
	var out: Array = []
	var xs: Array = []
	if c.kind == "lq":
		if c.n1 != 0:
			xs.append(-float(c.n0) / c.n1)
	else:
		# Mx² + (K − Mv)x + (R − Kv) = 0
		var A: float = c.M
		var B: float = c.K - c.M * c.v[0]
		var C: float = c.R - c.K * c.v[0]
		var d := B * B - 4.0 * A * C
		if d >= 0.0:
			for sg in ([-1.0, 1.0] if d > 0.0 else [0.0]):
				xs.append((-B + sg * sqrt(d)) / (2.0 * A))
	for x in xs:
		if absf(x) <= WIN[1] - 0.5 and not c.v.any(func(v): return absf(x - v) < 1e-9):
			out.append([x, 0.0, ""])
	if not c.v.any(func(v): return absf(v) < 1e-9):
		var y: float = g_of(c).call(0.0)
		if absf(y) <= WIN[3] - 0.5:
			out.append([0.0, y, ""])
	return out


## The card of g: its pieces, its asymptotes dashed and its intercepts marked.
static func card_of(c: Dictionary, across: bool = false) -> Dictionary:
	var curves := trace(g_of(c), c.v, across)
	var g := GdcKit.card(curves, dots(c), WIN, c.v.map(func(v): return [v, ""]), [[0.0, ""]] if c.kind == "lq" else [])
	g.one_colour = true
	if c.kind == "ql":
		var d := dashes(c.M, c.K)
		g.sand_from = curves.size()
		g.curves = curves + d
	return g


static func card_lq(s: Dictionary) -> Dictionary:
	return {"kind": "lq", "n1": float(s.a), "n0": float(s.b), "v": [float(s.zs[0]), float(s.zs[1])]}


static func card_ql(s: Dictionary) -> Dictionary:
	return {"kind": "ql", "M": float(s.m), "K": float(s.k), "R": float(s.R), "v": [float(-s.e)]}


## The graph a question shows (not a card).
static func plot(s: Dictionary) -> Dictionary:
	var c := card_lq(s) if s.form == "lq" else card_ql(s)
	var g := card_of(c)
	g.erase("card")
	g.points = []
	return g


func _pick(asked: String, s: Dictionary, wrongs: Array, rng: Seeded, methods: Dictionary, c: Dictionary) -> Dictionary:
	var p := GdcKit.pick(card_of(c), wrongs, rng)
	var fin := "So the graph is %s." % p.answer.values.v
	var out := {"asked": asked, "lines": [fx(s)], "answer": p.answer, "graphs": p.graphs, "methods": {}}
	for a in methods:
		var steps: Array = methods[a].duplicate()
		steps.append(fin)
		out.methods[a] = method(steps, p.answer.values)
	return out


func u_sketch_lq(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := card_lq(s)
	var r0: int = s.zs[0]
	var r1: int = s.zs[1]
	var pool: Array = []
	var flipped := c.duplicate(true)
	flipped.n1 = -c.n1
	flipped.n0 = -c.n0
	pool.append({"graph": card_of(flipped), "ref": "", "mistake": "flipped",
		"why": "it is the graph of −f: every branch is on the wrong side of the x-axis"})
	var vs := c.duplicate(true)
	vs.v = [float(-r1), float(-r0)]
	pool.append({"graph": card_of(vs), "ref": "", "mistake": "va-sign",
		"why": "its vertical asymptotes are x = %s and x = %s, not x = %s and x = %s" % [Fmt.num(-r1), Fmt.num(-r0), Fmt.num(r0), Fmt.num(r1)]})
	var zsg := c.duplicate(true)
	zsg.n0 = -c.n0
	pool.append({"graph": card_of(zsg), "ref": "", "mistake": "zero-sign",
		"why": "it crosses the x-axis at %s, not %s" % [Fmt.point(s.z.neg(), 0), Fmt.point(s.z, 0)]})
	var nz := c.duplicate(true)
	nz.n1 = 0.0
	var wrongs: Array = [{"graph": card_of(nz), "ref": R_SK_NO_ZERO, "mistake": "no-zero",
		"why": "it never crosses the x-axis, but f(x) = 0 at x = %s" % Fmt.num(s.z)}]
	wrongs += rng.shuffled(pool).slice(0, 2)
	var sign_right := "positive" if s.a > 0 else "negative"
	var methods := {
		"asymptotes-intercepts-signs": [
			"The vertical asymptotes are x = %s and x = %s, and the horizontal asymptote is y = 0, since the denominator has the higher degree." % [Fmt.num(r0), Fmt.num(r1)],
			"It crosses the x-axis at %s and the y-axis at %s." % [Fmt.point(s.z, 0), Fmt.point(0, s.yi)],
			"For large x, f(x) has the sign of %s/x, so it is %s on the right; it changes sign at each zero and each vertical asymptote." % [Fmt.num(s.a), sign_right]],
		"gdc-transfer": [
			"Graph y = f(x) on the GDC with −8 ≤ x ≤ 8 and −8 ≤ y ≤ 8.",
			"It has the vertical asymptotes x = %s and x = %s, tends to 0 at both ends, and crosses the axes at %s and %s." % [Fmt.num(r0), Fmt.num(r1), Fmt.point(s.z, 0), Fmt.point(0, s.yi)]],
		"reciprocal-of-quadratic": [
			"Start from y = %s = %s: 1/(%s) has vertical asymptotes at its zeros, x = %s and x = %s, and is negative between them and positive outside." % [lq_den(s), den_factors(s), lq_den(s), Fmt.num(r0), Fmt.num(r1)],
			"Multiplying by %s keeps those asymptotes and y = 0, and changes the sign again where %s = 0, at x = %s." % [lq_num(s), lq_num(s), Fmt.num(s.z)]],
	}
	return _pick("Which graph is y = %s?" % text(s), s, wrongs, rng, methods, c)


func u_sketch_ql(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := card_ql(s)
	var h := -int(s.e)
	var line := "y = " + Fmt.poly([s.m, s.k])
	var pool: Array = []
	var fl := c.duplicate(true)
	fl.R = -c.R
	pool.append({"graph": card_of(fl), "ref": "", "mistake": "remainder-flipped",
		"why": "its branches are on the wrong sides of the oblique asymptote: the remainder has the wrong sign"})
	var mv := c.duplicate(true)
	mv.v = [float(s.e)]
	pool.append({"graph": card_of(mv), "ref": "", "mistake": "va-mirrored",
		"why": "its vertical asymptote is x = %s, not x = %s" % [Fmt.num(s.e), Fmt.num(h)]})
	pool.append({"graph": card_of(c, true), "ref": "", "mistake": "through",
		"why": "a line is drawn across the vertical asymptote x = %s" % Fmt.num(h)})
	var lead := c.duplicate(true)
	lead.K = 0.0
	var wrongs: Array = [{"graph": card_of(lead), "ref": R_OA_LEAD, "mistake": "no-constant",
		"why": "its oblique asymptote is y = %s, not %s" % [Fmt.poly([s.m, 0]), line]}]
	wrongs += rng.shuffled(pool).slice(0, 2)
	var split := "f(x) = %s%s/(%s)" % [Fmt.poly([s.m, s.k]), " + %d" % s.R if s.R > 0 else " − %d" % -s.R, ql_den(s)]
	var side := "above" if s.R > 0 else "below"
	var other := "below" if s.R > 0 else "above"
	var methods := {
		"polynomial-division": [
			"Divide: %s." % split,
			"The vertical asymptote is x = %s and the oblique asymptote is %s. The fraction is %s for x > %s, so the curve is %s the line on the right of x = %s and %s it on the left." % [
				Fmt.num(h), line, "positive" if s.R > 0 else "negative", Fmt.num(h), side, Fmt.num(h), other]],
		"asymptotes-intercepts-signs": [
			"The vertical asymptote is x = %s, and dividing gives the oblique asymptote %s." % [Fmt.num(h), line],
			"It crosses the x-axis at %s and %s, and the y-axis at %s." % [Fmt.point(s.roots[0], 0), Fmt.point(s.roots[1], 0), Fmt.point(0, s.yi)]],
		"gdc-transfer": [
			"Graph y = f(x) on the GDC with −8 ≤ x ≤ 8 and −8 ≤ y ≤ 8.",
			"Two branches either side of x = %s, each running along the line %s, crossing the axes at %s, %s and %s." % [Fmt.num(h), line, Fmt.point(s.roots[0], 0), Fmt.point(s.roots[1], 0), Fmt.point(0, s.yi)]],
	}
	return _pick("Which graph is y = %s?" % text(s), s, wrongs, rng, methods, c)
