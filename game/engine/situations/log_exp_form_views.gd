class_name LogExpFormViews
extends ExtensionViews
## The views on the `log-exp-form` situation: one builder per unknown of t1-log-exp-form (FAL-753).
##
## Paper 1 is SL1.5.exp-log-form: changing form, exact values and solving by hand. Every answer is
## the `form` kind, so a wrong option in another shape can be picked but never typed. Paper 2 is
## SL1.5.log-context: named scales and a log model, on a calculator, to 3 s.f. with the rounding
## trap. An amount outside 0.01 to 100000 is a `form` answer a × 10^k, as t1-standard-form types it.
##
## Representations: "equation" (a log, or a scale's formula), "words" (the rule in a sentence, or a
## story), "table" (readings at three places) and "graph" (the curve, the line, the crossing).
## Misconceptions are the map's first, then the type's own, which are "<type id>#<index>".

const FORM := "SL1.5.exp-log-form#"
const CTX := "SL1.5.log-context#"
const OWN := "t1-log-exp-form#"
const R_DIVIDE := FORM + "0"
const R_BASE_EXP := FORM + "1"
const R_NON_POSITIVE := FORM + "2"
const R_LINEAR := CTX + "0"
const R_NO_MINUS := CTX + "1"
const R_MINUS_FRONT := CTX + "2"
const R_SWAP_POWER := OWN + "6"
const R_SWAP_BASE := OWN + "7"
const R_LOST_MINUS := OWN + "8"
const R_RECIPROCAL := OWN + "9"
const R_FLIP := OWN + "10"
const R_NO_ROOT_TAKEN := OWN + "11"
const R_BASE_UP := OWN + "12"
const R_NOT_ALONE := OWN + "13"
const R_NO_LOG := OWN + "14"
const R_INSIDE_ZERO := OWN + "15"
const R_STOP_SQUARE := OWN + "16"
const R_NEG_ROOT := OWN + "17"
const R_NONE_SMALL := OWN + "18"
const R_NONE_ONE := OWN + "19"
const R_NONE_MINUS := OWN + "20"
const R_TIMES_BASE := OWN + "21"
const R_LEFT_RAISED := OWN + "22"
const R_POWER_ONLY := OWN + "23"
const R_LOG_KEY := OWN + "24"
const R_NO_CONSTANT := OWN + "25"
const R_NO_FACTOR := OWN + "26"
const R_NO_MULTIPLIER := OWN + "27"
const R_TEN_OUTSIDE := OWN + "28"
const R_ADD_FACTOR := OWN + "29"
const R_TIMES_FACTOR := OWN + "30"
const R_NOT_UNDONE := OWN + "31"
const R_FACTOR_WAY := OWN + "32"
const R_DIVIDE_AFTER := OWN + "33"
const R_DIFFERENCE := OWN + "34"
const R_WHOLE_PERCENT := OWN + "35"
const R_ONLY_POWER := OWN + "36"
const R_TIMES_LOG := OWN + "37"
const R_MINUS_LOG := OWN + "38"
const R_GROUPED := OWN + "39"
const R_NO_TERM := OWN + "40"
const R_KEPT_TERM := OWN + "41"
const R_ORDER := OWN + "42"

const POWER := "what-power"
const REWRITE := "rewrite-exponential"
const INVERSE := "inverse-identities"
const SUBSTITUTE := "substitute-evaluate"
const INVERT := "invert-formula"
const STEPS := "scale-steps"

const NO_REAL := "no real value"
const THREE := " Give your answer to 3 significant figures."
const PLACES := ["Ash Pass", "Salt Ridge", "Rust Gorge", "Cinder Bay", "Dry Lake", "Glass Flats"]
const SCALE := [
	{"name": "Howl rating", "y": "H", "x": "I", "amount": "sound power", "unit": " units", "thing": "dust storm"},
	{"name": "Rumble number", "y": "R", "x": "W", "amount": "ground swing", "unit": " microns", "thing": "tremor"},
	{"name": "Glare class", "y": "G", "x": "B", "amount": "brightness", "unit": " units", "thing": "beacon"},
	{"name": "Rad index", "y": "N", "x": "C", "amount": "count", "unit": " clicks a minute", "thing": "ruin"},
	{"name": "Bite", "y": "S", "x": "c", "amount": "acid content", "unit": " moles per litre", "thing": "water sample"},
]
const MODEL := [
	{"thing": "salt crust", "start": "the last flood", "what": "thickness", "unit": " mm"},
	{"thing": "lichen patch", "start": "the rains", "what": "width", "unit": " cm"},
	{"thing": "rust layer", "start": "the hull was scraped", "what": "depth", "unit": " mm"},
	{"thing": "dune", "start": "the storm", "what": "height", "unit": " m"},
]


func needs() -> Dictionary:
	var out := {}
	for u in LogExpFormSituation.PAPER_1 + ["reading-from-value", "reading-after-multiple", "value-from-reading", "acid-reading", "acid-value",
			"ratio-two-readings", "rise-for-factor", "value-after-steps", "percent-rise", "find-scale-constant", "model-value", "model-time"]:
		out[u] = {"ask": u}
	return out


## Changing form is Paper 1 and the scales are Paper 2, as the bank has them.
func papers(unknown: String, _rep: String, _angle_id: String) -> Array:
	if not has(unknown):
		return []
	return [1] if unknown in LogExpFormSituation.PAPER_1 else [2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.wrongs = rng.shuffled(out.wrongs)
	out.given = LogExpFormSituation.export(s)
	# A rounded a: the trap writes it to 2 s.f., as t1-standard-form does.
	if out.answer.kind == "form" and not out.answer.exact and Answer.needs_rounding(out.answer.values.a):
		var a: Q = out.answer.values.a
		var two: Q = Answer.parse_number(Fmt.sf(a, 2)).q
		if not Answer.number_right(two, a):
			var t: Array = out.answer.template
			out.trap = StandardFormViews.form_ans(two, int(out.answer.values.k.to_float()), true, t[0], t[-1] if t[-1] is String else "", 2).values
	return out


# ── Writing things ───────────────────────────────────────────

## log₃, ln for base 0.
static func name_of(b: int) -> String:
	return "ln" if b == 0 else Answer.log_name(b)


## A log's argument: a bracket round a fraction, a sign or a sum.
static func arg(v: Variant) -> String:
	var t: String = v if v is String else N(v)
	return "(%s)" % t if t.contains("/") or t.contains("−") or t.contains(" ") else t


## log₃ 81, log₂(1/8)
static func lg(b: int, v: Variant) -> String:
	var a := arg(v)
	return name_of(b) + (a if a.begins_with("(") else " " + a)


## log₃ 81 in a base that may not be a whole number above 1, as a slip can make it.
static func any_lg(base: Q, v: Variant) -> String:
	if base.is_int() and base.to_float() >= 2.0:
		return lg(int(base.to_float()), v)
	return "log base %s of %s" % [N(base), arg(v)]


## 3^4, 2^(−3), 4^(3/2), e^2. A base that isn't a whole number has a bracket.
static func pw(b: Variant, e: Q) -> String:
	var base: String = "e" if str(b) == "0" else N(b)
	if not Q.of(b).is_int() or Q.of(b).sign() < 0:
		base = "(%s)" % base
	return "%s^%s" % [base, N(e)] if e.is_int() and e.sign() > 0 else "%s^(%s)" % [base, N(e)]


static func say(ans: Dictionary) -> String:
	var t := Answer.text(ans)
	return "So %s." % t if t.contains("=") or t.contains(" ") else "So the value is %s." % t


## An exact number, as a `form` answer.
static func exact_ans(label: String, v: Q) -> Dictionary:
	return DifferentiationViews.form(label + N(v), [label, {"slot": "v"}], {"v": v})


static func wv(label: String, v: Q, ref: String = "") -> Dictionary:
	return wrong({"v": v, "text": label + N(v)}, ref)


static func gv(label: String, vs: Array) -> Array:
	return vs.map(func(v): return {"v": v, "text": label + N(v)})


## Fillers for an exact number.
static func near(v: Q) -> Array:
	return [v.add(1), v.sub(1), v.add(2), v.neg(), v.mul(2), v.add(3)].filter(func(x): return not x.eq(v))


## b^e = x, with its three numbers typed.
static func exp_form(b: Q, e: Q, x: Q) -> Dictionary:
	return {"a": b, "e": e, "x": x, "text": "%s = %s" % [pw(b, e), N(x)]}


## log_b x = e, with its three numbers typed.
static func log_form(b: Q, e: Q, x: Q) -> Dictionary:
	return {"a": b, "e": e, "x": x, "text": "%s = %s" % [any_lg(b, x), N(e)]}


# ── Writing a scale ──────────────────────────────────────────

static func sc(s: Dictionary) -> Dictionary:
	return SCALE[s.scale]


static func place(s: Dictionary, i: int = 0) -> String:
	return PLACES[(s.ctx + i) % PLACES.size()]


## What the scale's log is taken of, around xt: "I × 10⁹", "C/25", "W".
static func inside(s: Dictionary, xt: String) -> String:
	if s.ten != 0:
		return "%s × %s" % [xt, StandardFormViews.ten(s.ten)]
	return "%s/%d" % [xt, s.over] if s.over != 1 else xt


## log₁₀(I × 10⁹), ln(C/25), log₁₀ W: the scale's log around xt.
static func log_of(s: Dictionary, xt: String) -> String:
	var name := "ln" if s.nat else Answer.log_name(10)
	var inner := inside(s, xt)
	return name + ("(%s)" % inner if inner.contains(" ") or inner.contains("/") else " " + inner)


## The right side of the formula with xt in it.
static func right_side(s: Dictionary, xt: String) -> String:
	var A: Q = s.A
	var size := "" if A.abs_q().eq(1) else D(A.abs_q()) + " "
	if s.d.is_zero():
		return ("−" if A.sign() < 0 else "") + size + log_of(s, xt)
	return "%s %s %s%s" % [D(s.d), "−" if A.sign() < 0 else "+", size, log_of(s, xt)]


static func formula(s: Dictionary) -> String:
	return "%s = %s" % [sc(s).y, right_side(s, sc(s).x)]


## The formula told in a sentence.
static func rule_words(s: Dictionary) -> String:
	var A := D(s.A.abs_q())
	var c: Dictionary = sc(s)
	match s.scale:
		LogExpFormSituation.HOWL:
			return "The %s of a %s is %s times the base-10 log of I × %s, where I units is its %s." % [c.name, c.thing, A, StandardFormViews.ten(s.ten), c.amount]
		LogExpFormSituation.RUMBLE:
			return "The %s of a %s is %s plus the base-10 log of its %s in microns." % [c.name, c.thing, D(s.d), c.amount]
		LogExpFormSituation.GLARE:
			return "The %s of a %s is %s minus %s times the base-10 log of its %s in units." % [c.name, c.thing, D(s.d), A, c.amount]
		LogExpFormSituation.RAD:
			return "The %s of a %s is %s times the natural log of C/%d, where C clicks a minute is its %s." % [c.name, c.thing, A, s.over, c.amount]
	return "The %s of a %s is minus the base-10 log of its %s in moles per litre." % [c.name, c.thing, c.amount]


static func rule_line(rep: String, s: Dictionary) -> String:
	if rep == "words":
		return rule_words(s)
	var c: Dictionary = sc(s)
	return "The %s %s of a %s and its %s %s%s are linked by %s." % [c.name, c.y, c.thing, c.amount, c.x, c.unit, formula(s)]


## An answer's label: its letter, or in a sentence, which has no letter for it, its name.
static func y_label(rep: String, s: Dictionary) -> String:
	return (sc(s).name if rep == "words" else sc(s).y) + " = "


static func x_label(rep: String, s: Dictionary) -> String:
	return (sc(s).amount if rep == "words" else sc(s).x) + " = "


## How the working opens: a sentence's rule in symbols.
static func opening(rep: String, s: Dictionary) -> String:
	if rep != "words":
		return ""
	return "As a formula, %s, where %s is the %s. " % [formula(s), sc(s).x, sc(s).amount]


static func D(v: Variant) -> String:
	return Fmt.dec(v)


## An amount as the question writes it.
static func amt(x: Dictionary) -> String:
	var v := LogExpFormSituation.value(x)
	if v >= LogExpFormSituation.PLAIN_LOW and v < LogExpFormSituation.PLAIN_HIGH:
		return D(StandardFormViews.q_of(x.m, x.k))
	return StandardFormViews.sci(x.m, x.k)


## a and k of x = a × 10^k, with a below 10 once it is rounded.
static func sci_parts(x: float) -> Array:
	var k := floori(log(absf(x)) / log(10.0) + 1e-12)
	var a := x / pow(10.0, k)
	if absf(roundf(a * 100.0)) >= 1000.0:
		a /= 10.0
		k += 1
	return [a, k]


static func plain(x: float) -> bool:
	return absf(x) >= LogExpFormSituation.PLAIN_LOW and absf(x) < LogExpFormSituation.PLAIN_HIGH


## A value in the working, to 6 s.f.
static func w(x: float) -> String:
	if plain(x):
		return Fmt.work(x, 6)
	var p := sci_parts(x)
	return "%s × %s" % [Fmt.work(p[0], 6), StandardFormViews.ten(p[1])]


## A 3 s.f. value that can be big or small: a number, or a × 10^k.
static func amount_ans(label: String, x: float, unit: String = "") -> Dictionary:
	if plain(x):
		var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, label, unit)
		ans.show = "sf"
		return ans
	var p := sci_parts(x)
	return StandardFormViews.form_ans(GdcKit.qf(p[0]), p[1], true, label, unit)


## Wrong options in the answer's shape: [x, ref], left out if they are too big or small to read.
static func opts(ans: Dictionary, list: Array) -> Array:
	var out: Array = []
	for e in list:
		var x: float = e[0]
		if not is_finite(x) or x == 0.0:
			continue
		if ans.kind == "number":
			# Past this the exact value has too many digits for the keypad to take.
			if absf(x) < 0.001 or absf(x) >= 1.0e6:
				continue
			out.append(wrong({"v": GdcKit.qf(x)}, e[1]))
		elif absf(x) < 1e-40 or absf(x) > 1e40 or plain(x):
			continue
		else:
			var p := sci_parts(x)
			out.append_array(StandardFormViews.options(ans, [[GdcKit.qf(p[0]), p[1], e[1]]]))
	return out


## Fillers in the answer's shape.
static func spare(ans: Dictionary, x: float) -> Array:
	return opts(ans, [[x * 1.5, ""], [x * 0.5, ""], [x * 2.5, ""], [x * 0.2, ""]]).map(func(o): return o.values)


## The other log key.
static func other(s: Dictionary, v: float) -> float:
	return log(v) / log(10.0) if s.nat else log(v)


static func other_base(s: Dictionary) -> float:
	return 10.0 if s.nat else exp(1.0)


static func base_name(s: Dictionary) -> String:
	return "e" if s.nat else "10"


## The steps from a reading's formula to its value, once the log is known.
static func sum_text(s: Dictionary, lv: float) -> String:
	var A: Q = s.A
	var times := P_f(lv) if A.abs_q().eq(1) else "%s × %s" % [D(A.abs_q()), P_f(lv)]
	if s.d.is_zero():
		return ("−" if A.sign() < 0 else "") + times
	return "%s %s %s" % [D(s.d), "−" if A.sign() < 0 else "+", times]


## Put x in, and use the log key.
static func read_steps(rep: String, s: Dictionary, xt: String, x: float, ans: Dictionary) -> Array:
	var c: Dictionary = sc(s)
	var lv := LogExpFormSituation.lg(s, LogExpFormSituation.inner(s, x))
	return [opening(rep, s) + "Put %s = %s into the formula: %s = %s." % [c.x, xt, c.y, right_side(s, xt)],
		"Keep the signs and brackets as written and press the %s key: the log is %s." % ["ln" if s.nat else "log", w(lv)],
		"%s = %s = %s" % [c.y, sum_text(s, lv), w(LogExpFormSituation.reading(s, x))], say(ans)]


## Undo the multiplier and the constant, then the log, then the factor inside.
static func invert_steps(rep: String, s: Dictionary, y: Q, ans: Dictionary, lead: String = "") -> Array:
	var c: Dictionary = sc(s)
	var u := LogExpFormSituation.power_at(s, y.to_float())
	var inner_at: float = pow(LogExpFormSituation.base(s), u)
	var out := [opening(rep, s) + lead + "Put %s = %s into the formula: %s = %s." % [c.y, D(y), D(y), right_side(s, c.x)]]
	var top := D(y) if s.d.is_zero() else "%s − %s" % [D(y), D(s.d)]
	if s.A.eq(1):
		out.append("Take %s from both sides: %s = %s" % [D(s.d), log_of(s, c.x), w(u)])
	elif s.A.eq(-1):
		out.append("Change both signs: %s = −%s" % [log_of(s, c.x), D(y)])
	else:
		var over := "(%s)" % D(s.A) if s.A.sign() < 0 else D(s.A)
		out.append("%s: %s = %s ÷ %s = %s" % ["Divide by the multiplier" if s.d.is_zero() else "Undo the constant and the multiplier", log_of(s, c.x), "(%s)" % top if not s.d.is_zero() else top, over, w(u)])
	out.append("Undo the log with %s^x: %s = %s = %s" % [base_name(s), inside(s, c.x), "%s^(%s)" % [base_name(s), w(u)], w(inner_at)])
	if s.ten != 0:
		out.append("%s = %s ÷ %s = %s" % [c.x, w(inner_at), StandardFormViews.ten(s.ten), w(LogExpFormSituation.amount(s, y.to_float()))])
	elif s.over != 1:
		out.append("%s = %s × %d = %s" % [c.x, w(inner_at), s.over, w(LogExpFormSituation.amount(s, y.to_float()))])
	out.append(say(ans))
	return out


## Each step of the reading is one multiplication.
static func step_line(s: Dictionary) -> String:
	var c: Dictionary = sc(s)
	return "Each %s of %s in %s multiplies %s by %s." % ["fall" if s.A.sign() < 0 else "rise", D(s.A.abs_q()), c.y, c.x, base_name(s)]


# ── Changing form ────────────────────────────────────────────

func u_to_exponential_form(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := Q.new(s.b)
	var ans := DifferentiationViews.form(exp_form(b, s.e, s.x).text, [{"slot": "a"}, "^", {"slot": "e"}, " = ", {"slot": "x"}], {"a": b, "e": s.e, "x": s.x})
	var line := "%s = %s" % [lg(s.b, s.x), N(s.e)]
	var w_list: Array = [wrong(exp_form(s.x, s.e, b), R_SWAP_BASE), wrong(exp_form(b, s.x, s.e), R_SWAP_POWER)]
	if s.e.is_int() and s.e.sign() > 0:
		w_list.append(wrong(exp_form(s.e, b, s.x), R_BASE_EXP))
	return {"lines": [line if rep == "equation" else "The logarithm of %s to base %d is %s." % [N(s.x), s.b, N(s.e)]],
		"asked": "Write this in exponential form.", "answer": ans, "wrongs": w_list,
		"generic": [exp_form(b, s.e.add(1), s.x), exp_form(b, s.e.neg(), s.x), exp_form(s.e, s.x, b)],
		"methods": {REWRITE: method(["log_a b = c means exactly a^c = b: the log is the power.", "Here the base is %d, the power is %s and the number is %s." % [s.b, N(s.e), N(s.x)], say(ans)], ans.values)}}


func u_to_log_form(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := Q.new(s.b)
	var ans := DifferentiationViews.form(log_form(b, s.e, s.x).text, ["log base ", {"slot": "a"}, " of ", {"slot": "x"}, " = ", {"slot": "e"}], {"a": b, "e": s.e, "x": s.x})
	var w_list: Array = [wrong(log_form(s.x, s.e, b), R_SWAP_BASE), wrong(log_form(b, s.x, s.e), R_SWAP_POWER)]
	return {"lines": ["%s = %s" % [pw(s.b, s.e), N(s.x)] if rep == "equation" else "The power of %d that gives %s is %s." % [s.b, N(s.x), N(s.e)]],
		"asked": "Write this in logarithmic form.", "answer": ans, "wrongs": w_list,
		"generic": [log_form(b, s.e.neg(), s.x), log_form(b, s.e.add(1), s.x), log_form(b, s.e.mul(2), s.x)],
		"methods": {REWRITE: method(["a^c = b means exactly log_a b = c: the power is the log.", "Here the base is %d, the power is %s and the number is %s." % [s.b, N(s.e), N(s.x)], say(ans)], ans.values)}}


## x = log₃ 7, its base typed; x = ln 7, the number alone.
static func x_log(b: int, r: int) -> Dictionary:
	return {"x": Q.new(r), "text": "x = " + lg(b, r)} if b == 0 else {"a": Q.new(b), "x": Q.new(r), "text": "x = " + lg(b, r)}


func u_solve_exp_as_log(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var r: int = s.r
	var k: int = s.k
	var base := "e" if b == 0 else str(b)
	var eq := "%s^x = %d" % [base, r] if k == 1 else "%d × %s^x = %d" % [k, base, k * r]
	var parts: Array = ["x = ln ", {"slot": "x"}] if b == 0 else ["x = log base ", {"slot": "a"}, " of ", {"slot": "x"}]
	var v := x_log(b, r)
	var ans := DifferentiationViews.form(v.text, parts, v)
	var w_list: Array = [DifferentiationViews.alt("x = %s^%d" % [base, r], R_BASE_UP)]
	if b != 0:
		w_list.append(DifferentiationViews.alt("x = " + N(Q.new(r, b)), R_DIVIDE))
		w_list.append(wrong(x_log(r, b), R_SWAP_BASE))
	if k > 1:
		w_list.append(wrong(x_log(b, k * r), R_NOT_ALONE))
	var lines: Array = [eq]
	var asked := "Solve the equation, giving x as an exact logarithm."
	if rep == "words":
		lines = ["A patch of mould covers %d square metres. Its area is multiplied by %d each week, and after x weeks it covers %d square metres." % [k, b, k * r]]
		asked = "Find x, giving your answer as an exact logarithm."
	var first := "Divide by %d: %s = %d" % [k, "%s^x" % base, r]
	var steps: Array = [first] if k > 1 else ["The power x is alone: %s^x = %d." % [base, r]]
	steps.append("In log form, a^x = b means x = log_a b, so x is the power of %s that gives %d." % [base, r])
	steps.append(say(ans))
	return {"lines": lines, "asked": asked, "answer": ans, "wrongs": w_list,
		"generic": [x_log(b, r + 1), x_log(b, r + 2), x_log(b, r + 3)], "methods": {REWRITE: method(steps, ans.values)}}


# ── Exact values ─────────────────────────────────────────────

func u_value_whole_power(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var x: int = int(s.x.to_float())
	var e: int = int(s.e.to_float())
	var ans := exact_ans("", s.val)
	var w_list: Array = [wv("", Q.new(x, b), R_DIVIDE)]
	# Reading log_b x = y as y^b = x, where such a y is whole.
	var root := roundi(pow(float(x), 1.0 / b))
	if LogExpFormSituation.ipow(root, b) == x and root != e:
		w_list.append(wv("", Q.new(root), R_BASE_EXP))
	var line := "Find the exact value."
	var lines: Array = [lg(b, x)]
	if rep == "words":
		lines = ["Each relay on the line multiplies a signal's strength by %d. A signal arrives %d times as strong as it left." % [b, x]]
		line = "Find %s, the number of relays it passed through." % lg(b, x)
	return {"lines": lines, "asked": line, "answer": ans, "wrongs": w_list, "generic": gv("", near(s.val)),
		"methods": {
			POWER: method(["%s asks: what power of %d gives %d?" % [lg(b, x), b, x], "%s = %d" % [pw(b, s.e), x], say(ans)], ans.values),
			REWRITE: method(["Let y = %s. In exponential form, %d^y = %d." % [lg(b, x), b, x], "%d = %s, so y = %d." % [x, pw(b, s.e), e], say(ans)], ans.values)}}


func u_value_negative_power(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var xt := D(s.x) if b == 10 else N(s.x)
	var ans := exact_ans("", s.val)
	var k: Q = s.val.neg()
	var w_list: Array = [wv("", k, R_LOST_MINUS), wv("", Q.new(1).div(k), R_RECIPROCAL), wv("", s.x.div(Q.new(b)), R_DIVIDE)]
	return {"lines": [lg(b, xt)], "asked": "Find the exact value.", "answer": ans, "wrongs": w_list, "generic": gv("", near(s.val)),
		"methods": {
			POWER: method(["%s asks: what power of %d gives %s?" % [lg(b, xt), b, xt], "The number is below 1, so the power is negative: %s = %s" % [pw(b, s.val), xt], say(ans)], ans.values),
			REWRITE: method(["Let y = %s. In exponential form, %d^y = %s." % [lg(b, xt), b, xt], "%s = %s, so y = %s." % [pw(b, s.val), xt, N(s.val)], say(ans)], ans.values)}}


func u_value_fractional_power(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var val: Q = s.val
	var xt: String
	var note: String
	match s.shape:
		"family":
			xt = N(s.x)
			note = "%s = %s" % [pw(b, val), xt]
		"half":
			xt = "√%d" % b
			note = "%d^(1/2) is the square root of %d" % [b, b]
		"more":
			xt = "%d√%d" % [b, b]
			note = "%d√%d = %d × %d^(1/2) = %s" % [b, b, b, b, pw(b, val)]
		_:
			xt = "1/√%d" % b
			note = "1/√%d = 1/%d^(1/2) = %s" % [b, b, pw(b, val)]
	var ans := exact_ans("", val)
	var line := lg(b, xt)
	var w_list: Array = [wv("", Q.new(1).div(val), R_FLIP)]
	if s.shape == "family":
		w_list.append(wv("", s.x.div(Q.new(b)), R_DIVIDE))
	var gen: Array = [val.add(1), val.sub(1), val.neg(), val.mul(2), val.add(2)]
	return {"lines": [line], "asked": "Find the exact value.", "answer": ans, "wrongs": w_list, "generic": gv("", gen),
		"methods": {
			POWER: method(["%s asks: what power of %d gives %s?" % [line, b, xt], note, say(ans)], ans.values),
			REWRITE: method(["Let y = %s. In exponential form, %d^y = %s." % [line, b, xt], "%s, so y = %s." % [note, N(val)], say(ans)], ans.values)}}


func u_log_of_power(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var k: Q = s.k
	var inner := pw(b, k)
	var line := "%s(%s)" % [name_of(b), inner]
	var ans := exact_ans("", k)
	var w_list: Array = []
	if b != 0:
		w_list.append(wv("", k.mul(Q.new(b)), R_TIMES_BASE))
		if k.is_int() and k.to_float() >= 2.0 and b <= 3:
			w_list.append(wv("", Q.new(LogExpFormSituation.ipow(b, int(k.to_float()))), R_POWER_ONLY))
	else:
		w_list.append(DifferentiationViews.alt(N(k) + "e" if k.is_int() else "(%s)e" % N(k), R_TIMES_BASE))
	var word := "e" if b == 0 else str(b)
	return {"lines": [line], "asked": "Find the exact value.", "answer": ans, "wrongs": w_list, "generic": gv("", near(k)),
		"methods": {
			INVERSE: method(["A log and a power of the same base undo each other: log_a(a^x) = x.", "The base of both here is %s, and x = %s." % [word, N(k)], say(ans)], ans.values),
			POWER: method(["%s asks: what power of %s gives %s?" % [line, word, inner], "The power is written there already: %s." % N(k), say(ans)], ans.values)}}


func u_power_of_log(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var x: Q = s.x
	var word := "e" if b == 0 else str(b)
	var head: String = {"plain": lg(b, x), "minus": "−" + lg(b, x), "times": "%d %s" % [s.k, lg(b, x)]}[s.shape]
	var line := "%s^(%s)" % [word, head]
	var ans := exact_ans("", s.val)
	var w_list: Array = []
	w_list.append(DifferentiationViews.alt(N(x) + "e", R_TIMES_BASE) if b == 0 else wv("", x.mul(Q.new(b)), R_TIMES_BASE))
	var dropped: Q = x.mul(Q.new({"plain": 1, "minus": -1, "times": s.get("k", 1)}[s.shape]))
	w_list.append(DifferentiationViews.alt(pw(b, dropped), R_LEFT_RAISED))
	var steps: Array = ["A power and a log of the same base undo each other: a^(log_a x) = x."]
	match s.shape:
		"plain":
			steps.append("The base of both here is %s, and x = %s." % [word, N(x)])
		"minus":
			steps = ["The minus sign is a power of −1 in the log: −%s = %s." % [lg(b, x), lg(b, "1/" + N(x))],
				"A power and a log of the same base undo each other, so %s^(%s) = %s." % [word, lg(b, "1/" + N(x)), N(s.val)]]
		"times":
			steps = ["A multiple of a log is the log of a power: %s = %s." % [head, lg(b, N(s.val))],
				"A power and a log of the same base undo each other, so %s^(%s) = %s." % [word, lg(b, N(s.val)), N(s.val)]]
	steps.append(say(ans))
	return {"lines": [line], "asked": "Find the exact value.", "answer": ans, "wrongs": w_list, "generic": gv("", near(s.val)),
		"methods": {INVERSE: method(steps, ans.values)}}


# ── Solving ──────────────────────────────────────────────────

func u_solve_log_x(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	if s.shape == "natural":
		return _solve_ln(s)
	var b: int = s.b
	var c: Q = s.e
	var ans := exact_ans("x = ", s.x)
	var w_list: Array = [wv("x = ", c.mul(Q.new(b)), R_DIVIDE)]
	if c.is_int() and c.sign() > 0:
		w_list.append(wv("x = ", LogExpFormSituation.qpow(int(c.to_float()), b), R_BASE_EXP))
	if c.is_int() and c.sign() < 0:
		w_list.append(wv("x = ", LogExpFormSituation.qpow(b, int(-c.to_float())), R_LOST_MINUS))
	var line := "%s = %s" % [lg(b, "x"), N(c)]
	var body := "x = %s" % pw(b, c)
	return {"lines": [line if rep == "equation" else "The logarithm of x to base %d is %s." % [b, N(c)]], "asked": "Find the exact value of x.", "answer": ans,
		"wrongs": w_list, "generic": gv("x = ", [s.x.add(1), s.x.mul(2), s.x.add(2), s.x.sub(1)].filter(func(v): return not v.is_zero())),
		"methods": {REWRITE: method(["log_a x = c means a^c = x. Here that is %s." % body, "%s = %s" % [pw(b, c), N(s.x)], say(ans)], ans.values)}}


## ln x = c: the answer stays a power of e, with its power typed.
func _solve_ln(s: Dictionary) -> Dictionary:
	var c: Q = s.e
	var text := "x = " + pw(0, c)
	var ans := DifferentiationViews.form(text, ["x = e^", {"slot": "v"}], {"v": c})
	var w_list: Array = [DifferentiationViews.alt("x = %s" % ((N(c) + "e") if absi(c.n) != 1 else ("−e" if c.n < 0 else "e")), R_DIVIDE)]
	if c.sign() < 0:
		w_list.append(wrong({"v": c.neg(), "text": "x = " + pw(0, c.neg())}, R_LOST_MINUS))
	var gen: Array = [c.add(1), c.sub(1), c.add(2), c.neg()].filter(func(v): return not v.is_zero())
	return {"lines": ["ln x = %s" % N(c)], "asked": "Find the exact value of x.", "answer": ans, "wrongs": w_list,
		"generic": gen.map(func(v): return {"v": v, "text": "x = " + pw(0, v)}),
		"methods": {REWRITE: method(["ln is the log to base e, so ln x = c means e^c = x.", "Here c = %s." % N(c), say(ans)], ans.values)}}


func u_solve_log_linear(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var c: int = s.c
	var p: int = s.p
	var q: int = s.q
	var power := LogExpFormSituation.qpow(b, c)
	var ins := "%s%s" % ["x" if p == 1 else "%dx" % p, Answer.plus_q(q)]
	var ans := exact_ans("x = ", s.val)
	var by := func(top: Q) -> Q: return top.sub(Q.new(q)).div(Q.new(p))
	var w_list: Array = [wv("x = ", by.call(Q.new(c)), R_NO_LOG), wv("x = ", by.call(Q.new(b * c)), R_DIVIDE)]
	if c >= 1:
		w_list.append(wv("x = ", by.call(LogExpFormSituation.qpow(c, b)), R_BASE_EXP))
	var gen: Array = [power.add(Q.new(q)).div(Q.new(p)), by.call(power.add(1)), by.call(power.sub(1)), s.val.add(1), s.val.add(2)]
	var last := "x = %s − %s = %s" % [N(power), P(q), N(s.val)] if p == 1 else "x = (%s − %s) ÷ %d = %s" % [N(power), P(q), p, N(s.val)]
	var two := "%s = %s = %s" % [ins, pw(b, Q.new(c)), N(power)]
	return {"lines": ["%s(%s) = %d" % [name_of(b), ins, c]], "asked": "Find the exact value of x.", "answer": ans, "wrongs": w_list, "generic": gv("x = ", gen),
		"methods": {REWRITE: method(["In exponential form, log_a A = c means A = a^c: " + two, last, say(ans)], ans.values)}}


func u_solve_log_square(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var c: int = s.c
	var k: int = s.k
	var r: int = s.r
	var ins := "x² − %d" % k
	var graph := rep == "graph"
	var label := "a = " if graph else "x = "
	var ans := DifferentiationViews.form(label + "√%d" % r, [label + "√", {"slot": "r"}], {"r": Q.new(r)})
	var w_list: Array = [DifferentiationViews.alt("%s−√%d" % [label, r], R_NEG_ROOT), wrong(root_values(label, k), R_INSIDE_ZERO), DifferentiationViews.alt(label + str(r), R_STOP_SQUARE)]
	if c != 0:
		w_list.append(wrong(root_values(label, c + k), R_NO_LOG))
	var out := {"answer": ans, "wrongs": w_list, "generic": [r + 1, r + 2, r + 3].map(func(n): return root_values(label, n))}
	var power := 1 if c == 0 else LogExpFormSituation.ipow(b, c)
	var bound: String = root_values("", k).text
	var rewrite := "In exponential form: %s = %s = %d" % [ins, pw(b, Q.new(c)), power]
	if graph:
		out.lines = ["The graph shows part of y = %s for x > %s. It crosses the x-axis at A(a, 0)." % [lg(b, ins), bound]]
		out.asked = "Find the exact value of a."
		out.graph = _square_figure(s)
		rewrite = "y = 0 at A, so %s = 0. %s" % [lg(b, ins), rewrite]
	else:
		out.lines = ["%s = %d" % [lg(b, ins), c]]
		out.asked = "Solve the equation for x > %s, giving the exact value of x." % bound
	out.methods = {REWRITE: method([rewrite, "x² = %d + %d = %d" % [power, k, r], "x = ±√%d, and x > %s keeps the positive root." % [r, bound], say(ans)], ans.values)}
	return out


## A root as an option: its square under the sign, or the whole number that is.
static func root_values(label: String, n: int) -> Dictionary:
	var whole := roundi(sqrt(float(n)))
	return {"r": Q.new(n), "text": label + (str(whole) if whole * whole == n else "√%d" % n)}


static func _square_figure(s: Dictionary) -> Dictionary:
	var b: int = s.b
	var k: float = s.k
	var f := func(x: float) -> float: return log(x * x - k) / (1.0 if b == 0 else log(float(b)))
	var low: float = sqrt(k + (exp(-3.0) if b == 0 else pow(float(b), -3.0)))
	var top: int = s.h + 4
	return Plot.spec([Plot.sample(f, low, float(top))], [[sqrt(float(s.r)), 0.0, "A(a, 0)"]], 0, top, -3, 4, [], [[float(s.h), "x = %d" % s.h]])


func u_solve_log_base(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Q = s.c
	var n: Q = s.n
	var val: Q = s.val
	var ans := exact_ans("a = " if rep == "graph" else "x = ", val)
	var label := "a = " if rep == "graph" else "x = "
	var w_list: Array = [wv(label, n.div(c), R_DIVIDE)]
	if c.is_int() and c.sign() > 0 and c.to_float() <= 4.0 and n.to_float() <= 20.0:
		w_list.append(DifferentiationViews.alt(label + D(Q.new(roundi(pow(n.to_float(), c.to_float())))), R_NO_ROOT_TAKEN))
	var line := "log base x of %s = %s" % [N(n), N(c)]
	var letter := "x"
	var out := {"answer": ans, "wrongs": w_list, "generic": gv(label, [val.add(1), val.add(2), val.mul(2), val.add(3)])}
	if rep == "graph":
		letter = "a"
		out.lines = ["The graph shows y = log_a x, for a base a > 1. It passes through P(%s, %s)." % [N(n), N(c)]]
		out.asked = "Find the exact value of a."
		out.graph = _base_figure(s)
	else:
		out.lines = [line]
		out.asked = "Find the exact value of x, where x > 0."
	var one := "%s^%s = %s" % [letter, N(c), N(n)] if c.is_int() and c.sign() > 0 else "%s^(%s) = %s" % [letter, N(c), N(n)]
	out.methods = {REWRITE: method(["In exponential form: " + one, "%s = %s" % [pw(val, c), N(n)] + ", so the base is %s." % N(val), say(ans)], ans.values)}
	return out


static func _base_figure(s: Dictionary) -> Dictionary:
	var a: float = s.val.to_float()
	var n: float = s.n.to_float()
	var c: float = s.c.to_float()
	var top := ceili(n * 1.3) + 1
	var f := func(x: float) -> float: return log(x) / log(a)
	return Plot.spec([Plot.sample(f, pow(a, -2.0), float(top))], [[n, c, "P(%s, %s)" % [N(s.n), N(s.c)]]], 0, top, -2, ceili(c) + 2)


func u_no_real_log(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var b: int = s.b
	var top: int = s.top
	var small := lg(b, Q.new(1, top))
	var zero := lg(b, 0)
	var neg := lg(b, Q.new(-s.neg))
	var sum := lg(b, "%d − %d" % [s.gap, s.gap + top])
	var right: String
	var others: Array
	var steps: Array
	var asked: String
	if s.shape == "none":
		right = rng.pick([zero, neg, sum])
		others = [[small, R_NONE_SMALL], [lg(b, 1), R_NONE_ONE], ["−" + lg(b, top), R_NONE_MINUS]]
		asked = "Which of these has no real value?"
		steps = ["Every power of %d is positive, so a log has a real value only for a positive number." % b,
			"The number in %s is not positive. The other three are logs of positive numbers." % right]
	else:
		right = small
		others = [[zero, R_NON_POSITIVE], [neg, R_NON_POSITIVE], [sum, R_NON_POSITIVE]]
		asked = "Which of these has a real value?"
		steps = ["Every power of %d is positive, so a log has a real value only for a positive number." % b,
			"Only 1/%d is positive, and %s = 1/%d." % [top, pw(b, Q.new(-s.j)), top]]
	var options: Array = [right]
	options.append_array(others.map(func(o): return o[0]))
	options = rng.shuffled(options)
	var ans := Answer.make("choice", {"v": right}, {"options": options})
	ans.exact = true
	steps.append("So the answer is %s." % right)
	return {"lines": ["The four logs are " + ",  ".join(options) + "."], "asked": asked, "answer": ans,
		"wrongs": others.map(func(o): return wrong({"v": o[0]}, o[1])), "generic": [], "methods": {POWER: method(steps, ans.values)}}


# ── Scales: a reading from an amount ─────────────────────────

## What a question at one place shows: the rule, and the numbers in a line or a table.
func _table_of(s: Dictionary, head: String, cells: Array) -> Dictionary:
	var names: Array = range(cells.size()).map(func(i): return place(s, i))
	return {"rows": [["Place", names], [head, cells]]}


func u_reading_from_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = sc(s)
	var x := LogExpFormSituation.value(s.x)
	var xt := amt(s.x)
	var ans := amount_ans(y_label(rep, s), s.y)
	var u := LogExpFormSituation.lg(s, LogExpFormSituation.inner(s, x))
	var at := place(s, 2) if rep == "table" else place(s)
	var d: float = s.d.to_float()
	var A: float = s.A.to_float()
	var list: Array = [[d + A * other(s, LogExpFormSituation.inner(s, x)), R_LOG_KEY]]
	if absf(A) != 1.0:
		list.append([d + u * signf(A), R_NO_MULTIPLIER])
	if s.ten != 0 or s.over != 1:
		list.append([A * LogExpFormSituation.lg(s, x), R_NO_FACTOR])
	if s.ten != 0:
		list.append([A * LogExpFormSituation.lg(s, x) + s.ten, R_TEN_OUTSIDE])
	if d != 0.0:
		list.append([A * u, R_NO_CONSTANT])
	if A < 0.0:
		list.append([d - A * u, R_NO_MINUS])
	var out := {"answer": ans, "wrongs": opts(ans, list), "generic": spare(ans, s.y), "table": null, "lines": [rule_line(rep, s)]}
	if rep == "table":
		out.lines.append("The table shows the %s of a %s at each of three places." % [c.amount, c.thing])
		out.table = _table_of(s, "%s (%s)" % [c.x, c.unit.strip_edges()], [amt(s.rows[0]), amt(s.rows[1]), xt])
	else:
		out.lines.append("A %s at %s has a %s of %s%s." % [c.thing, at, c.amount, xt, c.unit])
	out.asked = "Find the %s at %s.%s" % [c.name, at, THREE]
	out.methods = {SUBSTITUTE: method(read_steps(rep, s, xt, x, ans), ans.values)}
	return out


func u_reading_after_multiple(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = sc(s)
	var y1: float = s.y.to_float()
	var m: float = s.m.to_float()
	var A: float = s.A.to_float()
	var x2 := LogExpFormSituation.value(s.x) * m
	var ans := amount_ans(y_label(rep, s), s.y2)
	var lm := log(m) / log(10.0)
	var list: Array = [[m * y1, R_LINEAR], [y1 + m, R_ADD_FACTOR], [y1 + A * log(m), R_LOG_KEY]]
	if absf(A) != 1.0:
		list.append([y1 + signf(A) * lm, R_NO_MULTIPLIER])
	var out := {"answer": ans, "wrongs": opts(ans, list), "generic": spare(ans, s.y2), "table": null, "lines": [rule_line(rep, s)]}
	var xt := w(x2)
	if rep == "table":
		out.lines.append("The table shows two of them, A and B.")
		out.table = {"rows": [[c.thing.substr(0, 1).to_upper() + c.thing.substr(1), ["A", "B"]], ["%s (%s)" % [c.x, c.unit.strip_edges()], [amt(s.x), xt]], [c.name, [D(s.y), "?"]]]}
		out.asked = "Find the %s of B.%s" % [c.name, THREE]
	else:
		out.lines.append("A %s, A, has a %s of %s%s and a %s of %s." % [c.thing, c.amount, amt(s.x), c.unit, c.name, D(s.y)])
		out.lines.append("A second %s, B, has %s times the %s of A." % [c.thing, D(s.m), c.amount])
		out.asked = "Find the %s of B.%s" % [c.name, THREE]
	var rise := A * lm
	out.methods = {
		SUBSTITUTE: method(read_steps(rep, s, xt, x2, ans), ans.values),
		STEPS: method([opening(rep, s) + step_line(s), "A factor of %s is log₁₀ %s = %s of a step of ten." % [D(s.m), D(s.m), w(lm)],
			"The change in %s is %s × %s = %s" % [c.y, P(s.A), w(lm), w(rise)], "%s = %s + %s = %s" % [c.y, D(s.y), P_f(rise), w(s.y2)], say(ans)], ans.values)}
	return out


## A float in the working, in a bracket if it is negative.
static func P_f(x: float) -> String:
	return w(x) if x >= 0.0 else "(−%s)" % w(-x)


func u_acid_reading(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = sc(s)
	var x := LogExpFormSituation.value(s.x)
	var xt := amt(s.x)
	var ans := amount_ans(y_label(rep, s), s.y)
	var at := place(s, 2) if rep == "table" else place(s)
	var list: Array = [[log(x) / log(10.0), R_NO_MINUS], [-log(x), R_LOG_KEY], [float(-s.x.k), R_ONLY_POWER]]
	var out := {"answer": ans, "wrongs": opts(ans, list), "generic": spare(ans, s.y), "table": null, "lines": [rule_line(rep, s)]}
	if rep == "table":
		out.lines.append("The table shows the acid content of three water samples.")
		out.table = _table_of(s, "c (moles per litre)", [amt(s.rows[0]), amt(s.rows[1]), xt])
	else:
		out.lines.append("A water sample from %s has an acid content of %s moles per litre." % [at, xt])
	out.asked = "Find the Bite of the sample from %s.%s" % [at, THREE]
	out.methods = {SUBSTITUTE: method(read_steps(rep, s, xt, x, ans), ans.values)}
	return out


# ── Scales: an amount from a reading ─────────────────────────

func u_value_from_reading(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = sc(s)
	var y: float = s.y.to_float()
	var d: float = s.d.to_float()
	var A: float = s.A.to_float()
	var x := LogExpFormSituation.amount(s, y)
	var u := LogExpFormSituation.power_at(s, y)
	var k: float = pow(10.0, s.ten) / s.over
	var b := LogExpFormSituation.base(s)
	var ans := amount_ans(x_label(rep, s), x, c.unit)
	var list: Array = [[pow(other_base(s), u) / k, R_LOG_KEY]]
	if plain(u):
		list.append([u, R_NOT_UNDONE])
	if k != 1.0:
		list.append([pow(b, u) * k, R_FACTOR_WAY])
		list.append([pow(b, u), R_NO_FACTOR])
	if absf(A) != 1.0:
		list.append([pow(b, y - d) / absf(A) / k, R_DIVIDE_AFTER])
	if d != 0.0:
		list.append([pow(b, y / A) / k, R_NO_CONSTANT])
	if A < 0.0:
		list.append([pow(b, -u) / k, R_NO_MINUS])
	var at := place(s, 2) if rep == "table" else place(s)
	var out := {"answer": ans, "wrongs": opts(ans, list), "generic": spare(ans, x), "table": null, "lines": [rule_line(rep, s)]}
	match rep:
		"table":
			out.lines.append("The table shows the %s at three places." % c.name)
			out.table = _table_of(s, c.name, [D(s.rows[0]), D(s.rows[1]), D(s.y)])
		"graph":
			out.lines.append("The graph shows %s against %s for a %s at %s, and the line %s = %s." % [c.y, c.x, c.thing, at, c.y, D(s.y)])
			out.graph = _rad_figure(s, x)
		_:
			out.lines.append("A %s at %s has a %s of %s." % [c.thing, at, c.name, D(s.y)])
	out.asked = "Find the %s at %s.%s" % [c.amount, at, THREE]
	out.methods = {INVERT: method(invert_steps(rep, s, s.y, ans), ans.values)}
	return out


## The curve of a Rad index, the line at the reading, and their crossing.
static func _rad_figure(s: Dictionary, x: float) -> Dictionary:
	var top: int = Plot.nice_top(x * 1.3)
	var y: float = s.y.to_float()
	var f := func(c: float) -> float: return LogExpFormSituation.reading(s, c)
	var low: float = maxf(LogExpFormSituation.amount(s, 0.0), 0.5)
	return Plot.spec([Plot.sample(f, low, float(top))], [[x, y, "P"]], 0, top, 0, ceili(f.call(float(top)) * 1.15 / 5.0) * 5,
		[[y, "N = %s" % D(s.y)]]).merged({"x_name": "C", "y_name": "N"})


func u_acid_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = sc(s)
	var y: float = s.y.to_float()
	var x := pow(10.0, -y)
	var ans := amount_ans(x_label(rep, s), x, c.unit)
	var at := place(s, 2) if rep == "table" else place(s)
	var list: Array = [[-pow(10.0, y), R_MINUS_FRONT], [pow(10.0, y), R_NO_MINUS], [exp(-y), R_LOG_KEY]]
	var out := {"answer": ans, "wrongs": opts(ans, list), "generic": spare(ans, x), "table": null, "lines": [rule_line(rep, s)]}
	if rep == "table":
		out.lines.append("The table shows the Bite of three water samples.")
		out.table = _table_of(s, "Bite", [D(s.rows[0]), D(s.rows[1]), D(s.y)])
	else:
		out.lines.append("A water sample from %s has a Bite of %s." % [at, D(s.y)])
	out.asked = "Find its acid content.%s" % THREE
	if rep == "table":
		out.asked = "Find the acid content of the sample from %s.%s" % [at, THREE]
	out.methods = {INVERT: method(invert_steps(rep, s, s.y, ans), ans.values)}
	return out


# ── Scales: steps on the scale ───────────────────────────────

func u_ratio_two_readings(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = sc(s)
	var y1: float = s.y.to_float()
	var y2: float = s.y2.to_float()
	var dy := y2 - y1
	var f := LogExpFormSituation.factor(s, dy)
	var A: float = absf(s.A.to_float())
	var u := absf(dy) / A
	var b := LogExpFormSituation.base(s)
	var ans := amount_ans("", f, " times")
	var list: Array = [[maxf(y1, y2) / minf(y1, y2), R_LINEAR], [absf(dy), R_DIFFERENCE], [pow(other_base(s), u), R_LOG_KEY]]
	if A != 1.0:
		list.append([pow(b, absf(dy)), R_NO_MULTIPLIER])
	var out := {"answer": ans, "wrongs": opts(ans, list), "generic": spare(ans, f), "table": null, "lines": [rule_line(rep, s)]}
	var first := place(s)
	var second := place(s, 1)
	if rep == "table":
		out.lines.append("The table shows the %s at three places." % c.name)
		out.table = _table_of(s, c.name, [D(s.y), D(s.y2), D(s.rows[0])])
	else:
		out.lines.append("A %s at %s has a %s of %s, and a %s at %s has a %s of %s." % [c.thing, first, c.name, D(s.y), c.thing, second, c.name, D(s.y2)])
	out.asked = "How many times greater is the %s at %s than at %s?%s" % [c.amount, second, first, THREE]
	var gap := "%s − %s" % [D(s.y2), D(s.y)] if dy > 0.0 else "%s − %s" % [D(s.y), D(s.y2)]
	var inv1 := LogExpFormSituation.amount(s, y1)
	var inv2 := LogExpFormSituation.amount(s, y2)
	var at_reading := func(y: Q, v: float) -> String:
		var power := "%s^(%s)" % [base_name(s), w(LogExpFormSituation.power_at(s, y.to_float()))]
		if s.ten != 0:
			power += " ÷ " + StandardFormViews.ten(s.ten)
		elif s.over != 1:
			power = "%d × %s" % [s.over, power]
		return "At %s = %s: %s = %s = %s" % [c.y, D(y), c.x, power, w(v)]
	var opens := "Undo the formula at each reading." if rep != "words" else opening(rep, s) + "Undo it at each reading."
	out.methods = {
		STEPS: method([opening(rep, s) + step_line(s), "The readings differ by %s = %s, which is %s ÷ %s = %s such steps." % [gap, D(Q.new(roundi(absf(dy) * 10.0), 10)), D(Q.new(roundi(absf(dy) * 10.0), 10)), D(s.A.abs_q()), w(u)],
			"The factor is %s^(%s) = %s" % [base_name(s), w(u), w(f)], say(ans)], ans.values),
		INVERT: method([opens, at_reading.call(s.y, inv1), at_reading.call(s.y2, inv2),
			"%s ÷ %s = %s" % [w(inv2), w(inv1), w(f)], say(ans)], ans.values)}
	return out


func u_rise_for_factor(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = sc(s)
	var m: float = s.m.to_float()
	var A: float = absf(s.A.to_float())
	var lm := LogExpFormSituation.lg(s, m)
	var size := A * lm
	var word := "fall" if s.A.sign() < 0 else "rise"
	var ans := amount_ans(word + " = ", size)
	var list: Array = [[A * m, R_TIMES_FACTOR], [lm, R_NO_MULTIPLIER], [A * other(s, m), R_LOG_KEY]]
	var out := {"answer": ans, "wrongs": opts(ans, list), "generic": spare(ans, size), "table": null, "lines": [rule_line(rep, s)]}
	out.lines.append("The %s of a %s is multiplied by %s." % [c.amount, c.thing, D(s.m)])
	out.asked = "Find the %s in its %s.%s" % [word, c.name, THREE]
	var name := "ln" if s.nat else Answer.log_name(10)
	var law := "Multiplying by %s adds %s %s to the log: %s(%s × %s) = %s %s + %s %s." % [D(s.m), name, D(s.m), name, D(s.m), c.x, name, D(s.m), name, c.x]
	var kv := "%s %s = %s" % [name, D(s.m), w(lm)]
	out.methods = {
		STEPS: method([opening(rep, s) + step_line(s), "A factor of %s is %s of those steps." % [D(s.m), kv], "%s × %s = %s" % [D(s.A.abs_q()), w(lm), w(size)], say(ans)], ans.values),
		SUBSTITUTE: method([opening(rep, s) + law, "Press the %s key: %s." % ["ln" if s.nat else "log", kv], "%s × %s = %s" % [D(s.A.abs_q()), w(lm), w(size)], say(ans)], ans.values)}
	return out


func u_value_after_steps(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = sc(s)
	var x1 := LogExpFormSituation.value(s.x)
	var dy: float = s.delta.to_float()
	var A: float = s.A.to_float()
	var f := LogExpFormSituation.factor(s, dy)
	var x2 := x1 * f
	var ans := amount_ans(x_label(rep, s), x2, c.unit)
	var y1: float = s.y.to_float()
	var y2: float = s.y2.to_float()
	var list: Array = [[x1 * (y2 / y1), R_LINEAR], [x1 * dy, R_DIFFERENCE], [x1 + f, R_ADD_FACTOR]]
	if absf(A) != 1.0:
		list.append([x1 * pow(10.0, dy), R_NO_MULTIPLIER])
	var out := {"answer": ans, "wrongs": opts(ans, list), "generic": spare(ans, x2), "table": null, "lines": [rule_line(rep, s)]}
	if rep == "table":
		out.lines.append("The table shows a %s at dawn and at noon." % c.thing)
		out.table = {"rows": [["Time", ["Dawn", "Noon"]], ["%s (%s)" % [c.x, c.unit.strip_edges()], [amt(s.x), "?"]], [c.name, [D(s.y), D(s.y2)]]]}
		out.asked = "Find the %s at noon.%s" % [c.amount, THREE]
	else:
		out.lines.append("At dawn a %s has a %s of %s%s and a %s of %s." % [c.thing, c.amount, amt(s.x), c.unit, c.name, D(s.y)])
		out.lines.append("By noon its %s has risen by %s." % [c.name, D(s.delta)])
		out.asked = "Find its %s at noon.%s" % [c.amount, THREE]
	var u := dy / A
	var back := "the change in the log is %s ÷ %s = %s" % [D(s.delta), P(s.A), w(u)]
	out.methods = {
		STEPS: method([opening(rep, s) + step_line(s), "A rise of %s: %s." % [D(s.delta), back], "The factor is 10^(%s) = %s" % [w(u), w(f)],
			"%s = %s × %s = %s" % [c.x, amt(s.x), w(f), w(x2)], say(ans)], ans.values),
		INVERT: method(invert_steps(rep, s, s.y2, ans, "At noon the %s is %s + %s = %s. " % [c.name, D(s.y), D(s.delta), D(s.y2)]), ans.values)}
	return out


func u_percent_rise(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = sc(s)
	var dy: float = s.delta.to_float()
	var f := LogExpFormSituation.factor(s, dy)
	var A: float = s.A.to_float()
	var pct := 100.0 * (f - 1.0)
	var ans := amount_ans("increase = ", pct, "%")
	var list: Array = [[100.0 * f, R_WHOLE_PERCENT], [100.0 * dy / s.y.to_float(), R_LINEAR]]
	if A != 1.0:
		list.append([100.0 * (pow(LogExpFormSituation.base(s), dy) - 1.0), R_NO_MULTIPLIER])
	list.append([100.0 * (pow(other_base(s), dy / A) - 1.0), R_LOG_KEY])
	var out := {"answer": ans, "wrongs": opts(ans, list), "generic": spare(ans, pct), "table": null, "lines": [rule_line(rep, s)]}
	out.lines.append("A %s has a %s of %s. Its %s rises by %s." % [c.thing, c.name, D(s.y), c.name, D(s.delta)])
	out.asked = "Find the percentage increase in its %s.%s" % [c.amount, THREE]
	var u := dy / A
	var y1: float = s.y.to_float()
	var x1 := LogExpFormSituation.amount(s, y1)
	var x2 := LogExpFormSituation.amount(s, y1 + dy)
	out.methods = {
		STEPS: method([opening(rep, s) + step_line(s), "A rise of %s is %s of those steps, a factor of %s^(%s) = %s." % [D(s.delta), w(u), base_name(s), w(u), w(f)],
			"The increase is (%s − 1) × 100 = %s" % [w(f), w(pct)], say(ans)], ans.values),
		INVERT: method([opening(rep, s) + "Undo the formula at %s and at %s: %s = %s, then %s = %s." % [D(s.y), w(y1 + dy), c.x, w(x1), c.x, w(x2)],
			"The factor is %s ÷ %s = %s" % [w(x2), w(x1), w(x2 / x1)], "The increase is (%s − 1) × 100 = %s" % [w(x2 / x1), w(pct)], say(ans)], ans.values)}
	return out


func u_find_scale_constant(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = sc(s)
	var x := LogExpFormSituation.value(s.x)
	var xt := amt(s.x)
	var inner := LogExpFormSituation.inner(s, x)
	var lv := LogExpFormSituation.lg(s, inner)
	var y: float = s.y.to_float()
	var ans := amount_ans("k = ", s.found)
	var list: Array = [[y * lv, R_TIMES_LOG], [y - lv, R_MINUS_LOG], [y / inner, R_NO_LOG], [y / other(s, inner), R_LOG_KEY]]
	var shape := "%s = k %s" % [c.y, log_of(s, c.x)]
	var out := {"answer": ans, "wrongs": opts(ans, list), "generic": spare(ans, s.found), "table": null}
	var words: String = {LogExpFormSituation.HOWL: "%s, where I units is its sound power" % ("The Howl rating of a dust storm is k times the base-10 log of I × " + StandardFormViews.ten(s.ten)),
		LogExpFormSituation.RAD: "The Rad index of a ruin is k times the natural log of C/%d, where C clicks a minute is its count" % s.over}[s.scale]
	out.lines = [(words + ".") if rep == "words" else "On an old chart, the %s %s of a %s and its %s %s%s are linked by %s, where k is a constant." % [c.name, c.y, c.thing, c.amount, c.x, c.unit, shape]]
	if rep == "table":
		out.lines.append("The table shows one %s from the chart." % c.thing)
		out.table = {"rows": [["Place", [place(s)]], ["%s (%s)" % [c.x, c.unit.strip_edges()], [xt]], [c.name, [D(s.y)]]]}
	else:
		out.lines.append("A %s at %s has a %s of %s%s and a %s of %s." % [c.thing, place(s), c.amount, xt, c.unit, c.name, D(s.y)])
	out.asked = "Find k.%s" % THREE
	var keyed := opening(rep, s).replace(formula(s), shape) if rep == "words" else ""
	out.methods = {SUBSTITUTE: method([keyed + "Put the reading in: %s = k %s." % [D(s.y), log_of(s, xt)], "Press the %s key: the log is %s." % ["ln" if s.nat else "log", w(lv)],
		"k = %s ÷ %s = %s" % [D(s.y), w(lv), w(s.found)], say(ans)], ans.values)}
	return out


# ── A model in time ──────────────────────────────────────────

static func model_text(s: Dictionary) -> String:
	var q: Q = s.q
	var r: Q = s.r
	return "h = %s + %s ln(%st + 1)" % [D(s.p), D(q), "" if r.eq(1) else D(r)]


static func model_line(rep: String, s: Dictionary) -> String:
	var m: Dictionary = MODEL[s.model]
	if rep == "words":
		return "The %s of a %s in%s, t days after %s, is %s plus %s times the natural log of (%st + 1)." % [m.what, m.thing, m.unit, m.start, D(s.p), D(s.q), "" if s.r.eq(1) else D(s.r)]
	return "The %s of a %s, h%s, t days after %s, is given by %s." % [m.what, m.thing, m.unit, m.start, model_text(s)]


func u_model_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Dictionary = MODEL[s.model]
	var t: float = s.t
	var r: float = s.r.to_float()
	var inner := r * t + 1.0
	var p: float = s.p.to_float()
	var q: float = s.q.to_float()
	var h := LogExpFormSituation.level(s, t)
	var ans := amount_ans((m.what if rep == "words" else "h") + " = ", h, m.unit)
	var list: Array = [[(p + q) * log(inner), R_GROUPED], [p + q * log(r * t), R_NO_TERM], [q * log(inner), R_NO_CONSTANT], [p + q * log(inner) / log(10.0), R_LOG_KEY]]
	var out := {"answer": ans, "wrongs": opts(ans, list), "generic": spare(ans, h), "table": null, "lines": [model_line(rep, s)]}
	if rep == "table":
		out.lines.append("The table shows the %s on three days." % m.what)
		out.table = {"rows": [["t (days)", [str(s.rows[0]), str(s.rows[1]), str(s.t)]], ["h (%s)" % m.unit.strip_edges(), [Fmt.sf(LogExpFormSituation.level(s, s.rows[0])), Fmt.sf(LogExpFormSituation.level(s, s.rows[1])), "?"]]]}
	out.asked = "Find its %s %d days after %s.%s" % [m.what, s.t, m.start, THREE]
	var open := "As a formula, %s. " % model_text(s) if rep == "words" else ""
	out.methods = {SUBSTITUTE: method([open + "Put t = %d into the model: h = %s + %s ln(%s)." % [s.t, D(s.p), D(s.q), w(inner)],
		"Press the ln key: ln(%s) = %s" % [w(inner), w(log(inner))], "h = %s + %s × %s = %s" % [D(s.p), D(s.q), w(log(inner)), w(h)], say(ans)], ans.values)}
	return out


func u_model_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Dictionary = MODEL[s.model]
	var T: float = s.T.to_float()
	var p: float = s.p.to_float()
	var q: float = s.q.to_float()
	var r: float = s.r.to_float()
	var u := (T - p) / q
	var t := LogExpFormSituation.time_to(s, T)
	var ans := amount_ans("t = ", t, " days")
	var list: Array = [[u, R_NOT_UNDONE], [(pow(10.0, u) - 1.0) / r, R_LOG_KEY], [exp(u) / r, R_KEPT_TERM], [exp(u) / r - 1.0, R_ORDER]]
	var out := {"answer": ans, "wrongs": opts(ans, list), "generic": spare(ans, t), "table": null, "lines": [model_line(rep, s)]}
	if rep == "graph":
		out.lines.append("The graph shows h against t, and the line h = %s." % D(s.T))
		out.graph = _model_figure(s, t)
	out.asked = "Find how many days after %s its %s reaches %s%s.%s" % [m.start, m.what, D(s.T), m.unit, THREE]
	var open := "As a formula, %s. " % model_text(s) if rep == "words" else ""
	var rt := "%st" % ("" if s.r.eq(1) else D(s.r))
	var steps: Array = [open + "Put h = %s into the model: %s = %s + %s ln(%s + 1)." % [D(s.T), D(s.T), D(s.p), D(s.q), rt],
		"ln(%s + 1) = (%s − %s) ÷ %s = %s" % [rt, D(s.T), D(s.p), D(s.q), w(u)],
		"Undo the ln with e^x: %s + 1 = e^(%s) = %s" % [rt, w(u), w(exp(u))]]
	steps.append("t = (%s − 1) ÷ %s = %s" % [w(exp(u)), D(s.r), w(t)] if not s.r.eq(1) else "t = %s − 1 = %s" % [w(exp(u)), w(t)])
	steps.append(say(ans))
	out.methods = {INVERT: method(steps, ans.values)}
	return out


static func _model_figure(s: Dictionary, t: float) -> Dictionary:
	var top: int = Plot.nice_top(t * 1.2)
	var T: float = s.T.to_float()
	var f := func(x: float) -> float: return LogExpFormSituation.level(s, x)
	return Plot.spec([Plot.sample(f, 0.0, float(top))], [[t, T, "P"]], 0, top, 0, ceili(f.call(float(top)) * 1.15 / 5.0) * 5,
		[[T, "h = %s" % D(s.T)]]).merged({"x_name": "t", "y_name": "h"})
