class_name IntegralGdcViews
extends ExtensionViews
## The views on the `integral-gdc` situation: one builder per unknown of t5-ext-integral-gdc
## (FAL-776). Every question is Paper 2. A value is DefiniteIntegralViews' `form` answer to 3 s.f.;
## wrong values are the GDC entry slips the map lists: limits the wrong way round, degree mode on a
## trig integrand, and a bracket that closes before the + c. Which entry is right is a pick of four
## written entries. Error-spot shows a student's GDC working with one slip.
##
## Representations: "equation" (the integral written out) and "graph" (the curve with the region
## of the integral shaded, and its equation).

const SK := "SL5.5.definite-integral-gdc#"
const R_DEGREES := SK + "0"
const R_SWAPPED := SK + "1"
const R_BRACKETS := SK + "2"
const R_SPOT_BRACKETS := "t5-ext-integral-gdc#3"
const R_SPOT_DEGREES := "t5-ext-integral-gdc#4"
const UNKNOWNS := ["gdc-value", "which-entry", "polynomial-check"]
const S := preload("res://engine/situations/integral_gdc.gd")
const DV := preload("res://engine/situations/definite_integral_views.gd")


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	return {"gdc-value": ["error-spot"]}


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


## The integrand as the question writes it.
static func f_text(s: Dictionary) -> String:
	var c: int = s.c
	match s.fam:
		"esin":
			return "e^x sin x"
		"sinx2":
			return "sin(x²)"
		"eshift":
			return "e^(x + %d)" % c
		"sqrt":
			return "√(x³ + %d)" % c
		"lnq":
			return "ln(x² + %d)" % c
		"recip":
			return "1/(x² + %d)" % c
	return Fmt.poly(s.coeffs)


## The integrand as it is typed into the GDC, and with its bracket closed too soon.
static func entry(s: Dictionary, slip: bool = false) -> String:
	var c: int = s.c
	match s.fam:
		"esin":
			return "e^x×sin(x)"
		"sinx2":
			return "sin(x^2)"
		"eshift":
			return "e^x+%d" % c if slip else "e^(x+%d)" % c
		"sqrt":
			return "√(x^3)+%d" % c if slip else "√(x^3+%d)" % c
		"lnq":
			return "ln(x^2)+%d" % c if slip else "ln(x^2+%d)" % c
		_:
			return "1/x^2+%d" % c if slip else "1/(x^2+%d)" % c


static func trig(s: Dictionary) -> bool:
	return s.fam in S.TRIG


static func W(x: float) -> String:
	return GdcKit.W(x)


func u_gdc_value(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var ans := DV.val(s.v, true)
	var it := DV.integral_text(f_text(s), a, b)
	var wr: Array = [DV.like(ans, -s.v, R_SWAPPED)]
	wr.append(DV.like(ans, s.deg, R_DEGREES) if trig(s) else DV.like(ans, s.slip, R_BRACKETS))
	var mode := ", in radian mode" if trig(s) else ""
	var methods := {
		"gdc-fnint": ["Enter %s in the GDC's ∫dx template, with lower limit %d and upper limit %d%s." % [entry(s), a, b, mode], "The GDC gives %s." % W(s.v)],
		"gdc-graph-integral": ["Graph y = %s on the GDC%s." % [entry(s), mode], "Use the graph's ∫f(x)dx tool from x = %d to x = %d: it shades the region and gives %s." % [a, b, W(s.v)]],
	}
	var lines: Array = [it]
	var asked := "Find the value of the integral, to 3 s.f."
	var graph: Variant = null
	if rep == "graph":
		lines = ["The graph of y = %s is shown, with the region from x = %d to x = %d shaded." % [f_text(s), a, b]]
		asked = "Find %s, to 3 s.f." % it
		graph = DV.figure(S.f(s), a - 0.5, b + 0.5, [[float(a), float(b)]], [])
	var out := DV.pack(lines, asked, ans, wr, [], methods, graph)
	# Error-spot: degree mode, or the bracket closed too soon.
	var got: float = s.deg if trig(s) else s.slip
	var slip_line := "Mode: degrees" if trig(s) else "Entered: %s" % entry(s, true)
	var other := "Entered: %s" % entry(s) if trig(s) else "Limits: lower %d, upper %d" % [a, b]
	var result := "The GDC gives %s, so the integral is %s" % [GdcKit.S(got), GdcKit.S(got)]
	var spot_lines := ["The integral is " + it, slip_line, other, result]
	var bad := 1
	if rng.chance(0.5):
		spot_lines = ["The integral is " + it, other, slip_line, result]
		bad = 2
	var why := "%s has a trig function, so the GDC must be in radian mode" % f_text(s) if trig(s) \
		else "the bracket has to close after the + %d: %s" % [s.c, entry(s)]
	out.spot = {"lines": spot_lines, "bad": bad, "ref": R_SPOT_DEGREES if trig(s) else R_SPOT_BRACKETS, "why": why}
	return out


func u_which_entry(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var mode := ", radian mode" if trig(s) else ""
	var form := func(e: String, lo: int, hi: int, m: String) -> String: return "Function %s, lower limit %d, upper limit %d%s" % [e, lo, hi, m]
	var right: String = form.call(entry(s), a, b, mode)
	var tagged: Array = [InverseRuleViews.tag(form.call(entry(s), b, a, mode), R_SWAPPED)]
	if trig(s):
		tagged.append(InverseRuleViews.tag(form.call(entry(s), a, b, ", degree mode"), R_DEGREES))
	else:
		tagged.append(InverseRuleViews.tag(form.call(entry(s, true), a, b, mode), R_BRACKETS))
	var plain: Array = [form.call(entry(s), a, b + 1, mode), form.call(entry(s), a + 1 if a + 1 < b else a - 1, b, mode)]
	var out := {"asked": "Which GDC entry gives this integral?", "lines": [DV.integral_text(f_text(s), a, b)]}
	out.merge(InverseRuleViews.choose(right, tagged, plain))
	var steps := ["The function is %s: typed into the GDC it is %s." % [f_text(s), entry(s)],
		"The lower limit %d goes first, then the upper limit %d%s." % [a, b, ", and %s has a trig function, so the GDC must be in radian mode" % f_text(s) if trig(s) else ""],
		right + "."]
	out.methods = {"gdc-fnint": method(steps, {"v": right})}
	return out


func u_polynomial_check(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var co: Array = s.coeffs
	var a: int = s.a
	var b: int = s.b
	var v := DefiniteIntegralSituation.integral(co, a, b)
	var ans := DV.val(s.v, true)
	var up := DefiniteIntegralSituation.integral(co, 0, b)
	var dn := DefiniteIntegralSituation.integral(co, 0, a)
	var gen := DV.vals(ans, [up, up.add(dn), DefiniteIntegralSituation.at(co, b).sub(DefiniteIntegralSituation.at(co, a))])
	var methods := {
		"gdc-fnint": ["Enter f(x) = %s in the GDC's ∫dx template, with lower limit %d and upper limit %d." % [Fmt.poly(co), a, b], "The GDC gives %s." % W(s.v)],
		"analytic-check": ["F(x) = %s." % DV.anti(co), "F(%d) − F(%d) = %s − %s = %s." % [b, a, N(up), P(dn), N(v)], "That agrees with the GDC's %s." % W(s.v)],
	}
	return DV.pack([DV.integral_text(Fmt.poly(co), a, b)], "Find the value of the integral, to 3 s.f.", ans, [DV.like(ans, -s.v, R_SWAPPED)], gen, methods)
