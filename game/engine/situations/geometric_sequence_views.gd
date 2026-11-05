class_name GeometricSequenceViews
extends ExtensionViews
## The views on the `geometric-sequence` situation (FAL-728): one builder per unknown of
## t1-geometric-sequence and t1-sum-to-infinity.
##
## Paper 1 writes exact values: whole numbers and fractions, and every answer is marked exactly.
## Paper 2 writes decimals: a value that ends in at most three figures, or a whole number, is
## marked exactly, and any other is to 3 s.f. with the rounding trap. A GDC or partial-sums method
## is Paper 2 only.
##
## Representations: "notation" (u₁ = 5,  r = 3), "terms" (5, 15, 45, 135, …), "table" (n against uₙ
## or Sₙ), "graph" (dots, or the line r(x) in the band −1 < y < 1), "equation" (a Σ, a series or
## r in x), "words" and "diagram" (PlotView's `bounce` and `squares`, with the story in words).
## `given` holds the situation as plain strings, for the SymPy checker.

const S13 := "SL1.3."
const S18 := "SL1.8."
const R_POWER_N := S13 + "nth-term#0"
const R_POWER_ALL := S13 + "nth-term#1"
const R_R_FLIP := S13 + "nth-term#2"
const R_ARITHMETIC := S13 + "find-r-u1#0"
const R_ONE_ROOT := S13 + "find-r-u1#1"
const R_COUNT_TERMS := S13 + "find-r-u1#2"
const R_SUM_POWER := S13 + "sum#0"
const R_SUM_SIGN := S13 + "sum#1"
const R_SUM_COUNT := S13 + "sum#2"
const R_SIGMA_FIRST := S13 + "sigma#0"
const R_SIGMA_R := S13 + "sigma#1"
const R_SIGMA_COUNT := S13 + "sigma#2"
const R_R_BELOW_ONE := S18 + "convergence#0"
const R_ONE_SIDE := S18 + "convergence#1"
const R_ENDS := S18 + "convergence#2"
const R_PLUS_R := S18 + "sum-to-infinity#0"
const R_INF_FIRST := S18 + "sum-to-infinity#1"
const R_NO_LIMIT := S18 + "sum-to-infinity#2"
const R_INVERT := S18 + "find-unknown#0"
const R_KEEP_ROOT := S18 + "find-unknown#1"
const R_U2_AS_U1 := S18 + "find-unknown#2"
const R_DOUBLE_DROP := S18 + "applications#0"
const R_BLOCK := S18 + "applications#1"
const R_NO_CHECK := S18 + "applications#2"

## Methods with a calculator or a screen of partial sums: Paper 2 only.
const P2_ANGLES := ["gdc-seq", "gdc-solver", "gdc-sum-seq", "gdc-sigma", "partial-sums"]
const P1_ONLY := ["term-exact", "sum-exact", "sum-closed-form", "sum-of-sums", "sum-alternating", "x-from-log-series"]
const P2_ONLY := ["coefficients-geometric", "exists-table", "deposit-for-target"]

## The things dropped in a bounce question: what falls, and what it is.
const BALLS := ["rubber ball", "steel spring", "salvaged drone shell", "scrap tyre"]
## A running total that shrinks each round. item: what comes in, per: the round, each: its plural.
const STORIES := [
	{"open": "A well gives %s litres of water in its first week.", "next": "Each week it gives %s of what it gave the week before.", "unit": " litres", "per": "week"},
	{"open": "A salvage crew hauls %s kg of scrap on its first trip.", "next": "Each trip brings back %s of what the trip before brought.", "unit": " kg", "per": "trip"},
	{"open": "A rooftop farm yields %s kg of beans in its first season.", "next": "Each season yields %s of the season before.", "unit": " kg", "per": "season"},
	{"open": "A solar rig stores %s kWh on its first day.", "next": "Each day it stores %s of what it stored the day before.", "unit": " kWh", "per": "day"},
]
## A store that a scavenger adds to. who: the opening, per: the round.
const SAVERS := [
	{"who": "A scavenger hides %s scrap in a locked crate in the first year.", "next": "Each year she adds %s of what she added the year before.", "per": "year", "unit": " scrap"},
	{"who": "A bazaar trader banks %s scrap in the first month.", "next": "Each month he banks %s of what he banked the month before.", "per": "month", "unit": " scrap"},
	{"who": "A caravan caches %s litres of fuel on its first run.", "next": "Each run it caches %s of what it cached on the run before.", "per": "run", "unit": " litres"},
	{"who": "A clinic stockpiles %s doses in the first month.", "next": "Each month it adds %s of what it added the month before.", "per": "month", "unit": " doses"},
]
const SUBS := {"0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄", "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉"}


func needs() -> Dictionary:
	var out := {}
	for u in ["r-from-terms", "term-from-u1-r", "term-exact", "general-term", "r-odd-gap", "r-even-gap", "u1-from-two-terms",
			"term-choose-sign", "interior-terms", "k-consecutive", "coefficients-geometric", "sum-from-u1-r", "sum-exact",
			"sum-last-term", "sum-closed-form", "sum-of-sums", "sum-alternating", "bounce-before", "sigma-first-r",
			"sigma-evaluate", "sigma-write", "exists-claim", "exists-table", "x-interval", "sinf-value", "sinf-sigma",
			"sinf-shaded", "x-from-log-series", "u1-from-sinf", "r-from-sinf", "r-from-multiple", "r-from-u2-reject",
			"r-from-u2-both", "bounce-total", "bounce-multiple", "recurring-decimal", "nested-squares", "story-total",
			"story-target", "deposit-for-target"]:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, method_id: String) -> Array:
	if not has(unknown):
		return []
	if unknown in P1_ONLY:
		return [1]
	if unknown in P2_ONLY or method_id in P2_ANGLES:
		return [2]
	return [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = GeometricSequenceSituation.export(s)
	_tidy(out)
	# No calculator on Paper 1, so a calculator's working isn't shown there.
	if s.paper == 1:
		for m in P2_ANGLES:
			if m != angle:
				out.methods.erase(m)
	return out


## A Paper 2 option reads like the decimals beside it: 162/7 becomes 23.1, and 0.561231024 becomes 0.561.
static func _tidy(out: Dictionary) -> void:
	if out.answer.get("show", "") != "dec":
		return
	for w in out.wrongs:
		w.values = _decimals(w.values)
	out.generic = out.generic.map(func(g): return _decimals(g))


static func _decimals(values: Dictionary) -> Dictionary:
	var v := values.duplicate()
	for key in v:
		if v[key] is Q and not v[key].is_int() and (Fmt.dec(v[key]).contains("/") or Fmt.dec(v[key]).length() > 8):
			v[key] = Answer.parse_number(Fmt.sf(v[key]).replace("−", "-")).q
	return v


# ── Writing things ───────────────────────────────────────────

## A Q as the question writes it: exact on Paper 1; a decimal on Paper 2, or six figures.
static func X(s: Dictionary, v: Variant) -> String:
	var q := Q.of(v)
	if s.paper == 1:
		return q.text()
	var t := Fmt.dec(q)
	return t if t.length() <= 9 and not t.contains("/") else Fmt.work(q, 6)


## X, in brackets for a negative or a fraction: ready to be raised to a power.
static func B(s: Dictionary, v: Variant) -> String:
	var t := X(s, v)
	return "(%s)" % t if t.begins_with("−") or t.contains("/") else t


## A float to six figures: a GDC's screen.
static func W(x: float) -> String:
	return Fmt.work(x, 6)


static func pow_text(s: Dictionary, b: Variant, e: int) -> String:
	return B(s, b) + ("¹" if e == 1 else Fmt.sup(e))


static func sub(k: int) -> String:
	var out := ""
	for ch in str(k):
		out += SUBS[ch]
	return out


static func U(k: int) -> String:
	return "u" + sub(k)


static func SS(k: int) -> String:
	return "S" + sub(k)


static func ordinal(i: int) -> String:
	return BinomialViews.ordinal(i)


static func term(s: Dictionary, k: int) -> Q:
	return GeometricSequenceSituation.term(s, k)


static func power(b: Q, e: int) -> Q:
	return GeometricSequenceSituation.power(b, e)


static func partial(u1: Q, r: Q, k: int) -> Q:
	return GeometricSequenceSituation.partial(u1, r, k)


static func inf(u1: Q, r: Q) -> Q:
	return GeometricSequenceSituation.to_infinity(u1, r)


## A float-sized partial sum, for n too large for a Q.
static func far_sum(u1: Q, r: Q, n: int) -> float:
	return u1.to_float() * (1.0 - pow(r.to_float(), n)) / (1.0 - r.to_float())


static func notation(s: Dictionary) -> String:
	return "u₁ = %s,  r = %s" % [X(s, s.u1), X(s, s.r)]


## The first k terms and a … .
static func terms_line(s: Dictionary, k: int = 4) -> String:
	var bits: PackedStringArray = []
	for i in range(1, k + 1):
		bits.append(X(s, term(s, i)))
	return ", ".join(bits) + ", …"


## v₁ + v₂ − v₃ …, with its signs joined up.
static func series(s: Dictionary, vals: Array, tail: String = "") -> String:
	var out := ""
	for i in vals.size():
		var q: Q = vals[i]
		if i == 0:
			out = X(s, q)
		else:
			out += (" − " if q.sign() < 0 else " + ") + X(s, q.abs_q())
	return out + tail


## The sequence shown: its rep's lines, table or graph.
static func shown(rep: String, s: Dictionary, k: int = 4) -> Dictionary:
	match rep:
		"terms":
			return {"lines": [terms_line(s, k)]}
		"table":
			var ns: Array = []
			var us: Array = []
			for i in range(1, k + 1):
				ns.append(str(i))
				us.append(X(s, term(s, i)))
			return {"lines": ["A geometric sequence has these first terms."], "table": {"rows": [["n", ns], ["uₙ", us]]}}
		"graph":
			return {"lines": ["The dots show the first terms of a geometric sequence."], "graph": dots(s, k)}
	return {"lines": [notation(s)]}


## n across, uₙ up, each dot with its value.
static func dots(s: Dictionary, k: int) -> Dictionary:
	var pts: Array = []
	var top := 0.0
	for i in range(1, k + 1):
		var y := term(s, i)
		pts.append([i, y.to_float(), y.text()])
		top = maxf(top, y.to_float())
	var spec := Plot.spec([], pts, 0, k + 1, 0, Plot.nice_top(top))
	spec.x_name = "n"
	spec.y_name = "uₙ"
	return spec


## Merges a question's fields into what shown() gave.
static func with(base: Dictionary, more: Dictionary) -> Dictionary:
	var out := base.duplicate()
	out.merge(more, true)
	return out


## The 3 s.f. rule for a list of values on Paper 2: "sf" if any needs rounding, else "dec".
static func style(ans: Dictionary, s: Dictionary, vals: Array) -> Dictionary:
	if s.paper == 1:
		ans.exact = true
		return ans
	if vals.all(func(v): return v.is_int() or not Answer.needs_rounding(v)):
		ans.show = "dec"
		ans.exact = true
	else:
		ans.show = "sf"
	return ans


## One number. A rounded Paper 2 value keeps a GDC's nine places, so it can be typed back whole.
static func val(s: Dictionary, label: String, v: Q, unit: String = "") -> Dictionary:
	var ans := style(Answer.make("number", {"v": v}, {}, label, unit), s, [v])
	if ans.get("show", "") == "sf":
		ans.values.v = GeometricSequenceSituation.gdc(v.to_float())
	return ans


## An exact fraction on either paper (a recurring decimal is a fraction).
static func frac_ans(label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	ans.exact = true
	return ans


static func xs_ans(s: Dictionary, name: String, vals: Array) -> Dictionary:
	return style(Answer.make("xs", Answer.xs_of(vals), {"var": name}), s, vals)


static func named(s: Dictionary, names: Array, vals: Array) -> Dictionary:
	var values := {}
	for i in vals.size():
		values["v%d" % i] = vals[i]
	return style(Answer.make("named", values, {"names": names}), s, vals)


static func vals_of(vals: Array) -> Dictionary:
	var values := {}
	for i in vals.size():
		values["v%d" % i] = vals[i]
	return values


static func claim(tag: String, text: String) -> Dictionary:
	return {"form": tag, "vals": [], "text": text}


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## {"v": Q} for each value.
static func vs(xs: Array) -> Array:
	return xs.map(func(x): return {"v": x})


## A Q from a float, for an option or a GDC's answer.
static func qf(x: float) -> Q:
	return GdcKit.qf(x)


## The word for the root that undoes a power.
static func root_word(gap: int) -> String:
	match gap:
		2:
			return "square root"
		3:
			return "cube root"
	return "%s root" % ordinal(gap)


## The formula that keeps its top and bottom positive, with the numbers in.
static func sum_formula(s: Dictionary, u1: Q, r: Q, n: int) -> Array:
	var name := SS(n) if n > 0 else "S"
	if r.to_float() > 1.0:
		return ["Sₙ = u₁(r^n − 1)/(r − 1)",
			"%s = %s(%s − 1)/(%s − 1)" % [name, B(s, u1), pow_text(s, r, n), X(s, r)]]
	return ["Sₙ = u₁(1 − r^n)/(1 − r)",
		"%s = %s(1 − %s)/(1 − %s)" % [name, B(s, u1), pow_text(s, r, n), B(s, r)]]


## Adds the first terms and their total: "5 + 15 + 45 = 65".
static func add_line(s: Dictionary, u1: Q, r: Q, n: int) -> String:
	var vals: Array = []
	for i in n:
		vals.append(u1.mul(power(r, i)))
	return "%s = %s" % [series(s, vals), X(s, partial(u1, r, n))]


## "Enter sum(seq(…))": the GDC's line for a series.
static func gdc_sum(s: Dictionary, u1: Q, r: Q, n: int) -> String:
	return "sum(seq(%s × %s^(k − 1), k, 1, %d)) = %s" % [B(s, u1), B(s, r), n, X(s, partial(u1, r, n))]


## The steps of S − rS, in this order: both rows, the subtraction, the numbers.
## A sum's value, with the fractions worked on Paper 1, where there is no calculator.
static func sum_worked(s: Dictionary, u1: Q, r: Q, n: int) -> String:
	var total := X(s, partial(u1, r, n))
	if s.paper != 1 or r.is_int():
		return total
	var top := Q.new(1).sub(power(r, n))
	return "%s × %s ÷ %s = %s" % [B(s, u1), B(s, top), B(s, Q.new(1).sub(r)), total]


static func shift_steps(s: Dictionary, u1: Q, r: Q, n: int, final: String) -> Array:
	return ["Write Sₙ = u₁ + u₁r + … + u₁r^(n − 1) and rSₙ = u₁r + u₁r² + … + u₁r^n.",
		"Subtract: every middle term cancels, so Sₙ − rSₙ = u₁ − u₁r^n, and Sₙ = u₁(1 − r^n)/(1 − r).",
		"With n = %d: %s(1 − %s)/(1 − %s) = %s" % [n, B(s, u1), pow_text(s, r, n), B(s, r), sum_worked(s, u1, r, n)], final]


# ── Terms ────────────────────────────────────────────────────

func u_r_from_terms(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var u2 := term(s, 2)
	var u3 := term(s, 3)
	var ans := val(s, "r = ", s.r)
	var read := "Read u₁ = %s and u₂ = %s." % [X(s, s.u1), X(s, u2)]
	return with(shown(rep, s), {"asked": "Find the common ratio r.", "answer": ans,
		"wrongs": [wrong({"v": s.u1.div(u2)}, R_R_FLIP), wrong({"v": u2.sub(s.u1)}, R_R_FLIP)],
		"generic": vs([s.r.neg(), s.r.add(1), s.r.mul(2), u3.sub(u2)]),
		"methods": {
			"nth-formula": method([read, "Put n = 2 in uₙ = u₁r^(n − 1): u₂ = u₁r, so r = u₂ ÷ u₁ = %s ÷ %s = %s." % [X(s, u2), B(s, s.u1), X(s, s.r)], say(ans)], ans.values),
			"repeated-multiply": method([read, "u₁ × r = u₂, so try r = %s ÷ %s = %s." % [X(s, u2), B(s, s.u1), X(s, s.r)],
				"Check: %s × %s = %s, and again: %s × %s = %s. The factor stays the same." % [B(s, s.u1), B(s, s.r), X(s, u2), B(s, u2), B(s, s.r), X(s, u3)], say(ans)], ans.values),
		}})


## The ways to a term that the map lists, on the numbers shown.
func _term_methods(rep: String, s: Dictionary, n: int, ans: Dictionary) -> Dictionary:
	var v := term(s, n)
	var first := notation(s) if rep == "notation" else "r = u₂ ÷ u₁ = %s ÷ %s = %s" % [X(s, term(s, 2)), B(s, s.u1), X(s, s.r)]
	var steps_up: PackedStringArray = []
	for i in range(1, n + 1):
		steps_up.append(X(s, term(s, i)))
	var a: Q = s.u1.div(s.r)
	var power_v := power(s.r, n - 1)
	var out := {
		"nth-formula": method([first, "%s = u₁r^(%d − 1) = %s × %s" % [U(n), n, B(s, s.u1), pow_text(s, s.r, n - 1)],
			"%s × %s = %s" % [B(s, s.u1), B(s, power_v) if s.paper == 1 else pow_text(s, s.r, n - 1), X(s, v)], say(ans)], ans.values),
		"repeated-multiply": method([first, "Start at u₁ and multiply by %s, %d times: %s" % [B(s, s.r), n - 1, ", ".join(steps_up)], say(ans)], ans.values),
		"gdc-seq": method([first, "In sequence mode, enter u(n) = %s × %s^(n − 1)." % [B(s, s.u1), B(s, s.r)],
			"The table at n = %d shows %s." % [n, X(s, v)], say(ans)], ans.values),
	}
	if a.mul(20).is_int():
		out["exponential-form"] = method([first, "Rewrite uₙ = u₁r^(n − 1) as (u₁/r) × r^n: u₁/r = %s ÷ %s = %s" % [X(s, s.u1), B(s, s.r), X(s, a)],
			"%s = %s × %s = %s" % [U(n), B(s, a), pow_text(s, s.r, n), X(s, v)], say(ans)], ans.values)
	return out


func _term_wrongs(s: Dictionary, n: int) -> Array:
	var out := [wrong({"v": term(s, n + 1)}, R_POWER_N)]
	var product: Q = s.u1.mul(s.r)
	if pow(absf(product.to_float()), n - 1) < 5e8:
		out.append(wrong({"v": power(product, n - 1)}, R_POWER_ALL))
	return out


func _term_generic(s: Dictionary, n: int) -> Array:
	return vs([term(s, n - 1), s.u1.mul(s.r).mul(n - 1), term(s, n).neg(), term(s, n).mul(2)])


func u_term_from_u1_r(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := val(s, U(s.n) + " = ", s.v)
	return with(shown(rep, s), {"asked": "Find %s." % U(s.n), "answer": ans, "wrongs": _term_wrongs(s, s.n),
		"generic": _term_generic(s, s.n), "methods": _term_methods(rep, s, s.n, ans)})


func u_term_exact(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := val(s, U(s.n) + " = ", s.v)
	return with(shown(rep, s), {"asked": "Find the exact value of %s." % U(s.n), "answer": ans, "wrongs": _term_wrongs(s, s.n),
		"generic": _term_generic(s, s.n), "methods": _term_methods(rep, s, s.n, ans)})


## A term rule as text: "3 × 2^(n − 1)", "−4 × (1/2)^n".
static func rule(s: Dictionary, a: Q, b: Q, power_text: String) -> String:
	return "%s × %s^%s" % [X(s, a), B(s, b), power_text]


func u_general_term(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var nth: bool = angle != "exponential-form"
	var a: Q = s.u1 if nth else s.u1.div(s.r)
	var tail := "(n − 1)" if nth else "n"
	var parts: Array = ["uₙ = ", {"slot": "a"}, " × ", {"slot": "b"}, "^" + tail]
	var ans := Answer.make("form", {"a": a, "b": s.r, "text": rule(s, a, s.r, tail)}, {"parts": parts}, "uₙ = ")
	ans.exact = true
	var shape := func(t: String): return {"a": a, "b": s.r, "text": t, "shape": "other"}
	var product: Q = s.u1.mul(s.r)
	var wrongs := [wrong(shape.call(rule(s, s.u1, s.r, "n")), R_POWER_N)]
	wrongs.append(wrong(shape.call("%s^(n − 1)" % B(s, product)), R_POWER_ALL))
	var generic: Array = []
	var other: Q = s.u1 if not nth else s.u1.div(s.r)
	generic.append({"a": s.r, "b": s.u1, "text": rule(s, s.r, s.u1, tail)})
	generic.append({"a": a, "b": s.r.neg(), "text": rule(s, a, s.r.neg(), tail)})
	generic.append({"a": a.neg(), "b": s.r, "text": rule(s, a.neg(), s.r, tail)})
	generic.append(shape.call(rule(s, a, s.r, "(n + 1)")))
	if nth:
		generic.append(shape.call(rule(s, s.r, s.u1, "n")))
	else:
		generic.append(shape.call(rule(s, other.neg(), s.r, "(n − 1)")))
	var first := notation(s) if rep == "notation" else "u₁ = %s, and r = u₂ ÷ u₁ = %s" % [X(s, s.u1), X(s, s.r)]
	return with(shown(rep, s), {"asked": "Find an expression for uₙ in terms of n." if nth else "Find an expression for uₙ in the form a × b^n.",
		"answer": ans, "wrongs": wrongs, "generic": generic,
		"methods": {
			"nth-formula": method([first, "uₙ = u₁r^(n − 1), so put in u₁ and r.", say(ans)], ans.values),
			"exponential-form": method([first, "uₙ = u₁r^(n − 1) = (u₁/r) × r^n, and u₁/r = %s ÷ %s = %s." % [X(s, s.u1), B(s, s.r), X(s, s.u1.div(s.r))],
				"So uₙ = %s × %s^n." % [B(s, s.u1.div(s.r)), B(s, s.r)], say(ans)], ans.values),
		}})


# ── r and u₁ from given terms ────────────────────────────────

static func two_lines(rep: String, s: Dictionary) -> Array:
	if rep == "words":
		return ["The %s term of a geometric sequence is %s and the %s term is %s." % [ordinal(s.p), X(s, s.up), ordinal(s.q), X(s, s.uq)]]
	return ["%s = %s,  %s = %s" % [U(s.p), X(s, s.up), U(s.q), X(s, s.uq)]]


## "r³ = 96 ÷ 12 = 8", the same for both routes; the routes differ in how they get there.
static func ratio_line(s: Dictionary) -> String:
	var gap: int = s.q - s.p
	return "r%s = %s ÷ %s = %s" % [Fmt.sup(gap), X(s, s.uq), B(s, s.up), X(s, s.uq.div(s.up))]


static func divide_line(s: Dictionary) -> String:
	return "Divide: %s ÷ %s = u₁r%s ÷ u₁r%s, so the u₁ cancels." % [U(s.q), U(s.p), Fmt.sup(s.q - 1), "¹" if s.p == 2 else Fmt.sup(s.p - 1)]


static func step_line(s: Dictionary) -> String:
	return "From %s to %s is %d steps, so multiply by r %d times." % [U(s.p), U(s.q), s.q - s.p, s.q - s.p]


func u_r_odd_gap(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var gap: int = s.q - s.p
	var ans := val(s, "r = ", s.r)
	var ratio: Q = s.uq.div(s.up)
	var diff: Q = s.uq.sub(s.up).div(gap)
	var wrongs := [wrong({"v": diff}, R_ARITHMETIC)]
	if s.paper == 2 and ratio.sign() > 0:
		wrongs.append(wrong({"v": qf(pow(ratio.to_float(), 1.0 / (gap + 1)))}, R_COUNT_TERMS))
	var root := "r = the %s of %s = %s" % [root_word(gap), B(s, ratio), X(s, s.r)]
	return {"asked": "Find r.", "lines": two_lines(rep, s), "answer": ans, "wrongs": wrongs,
		"generic": vs([ratio, ratio.div(gap), s.r.neg(), s.r.add(1)]),
		"methods": {
			"divide-terms": method([divide_line(s), ratio_line(s), root, say(ans)], ans.values),
			"step-count": method([step_line(s), ratio_line(s), root, say(ans)], ans.values),
			"gdc-solver": method(["Solve x%s = %s on the GDC, with the solver or by graphing both sides." % [Fmt.sup(gap), X(s, ratio)],
				"The real solution is x = %s." % X(s, s.r), say(ans)], ans.values),
		}}


func u_r_even_gap(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var gap: int = s.q - s.p
	var ans := xs_ans(s, "r", [s.r.neg(), s.r])
	var ratio: Q = s.uq.div(s.up)
	var root := "An even power hides the sign, so r = ± the %s of %s = ±%s." % [root_word(gap), B(s, ratio), X(s, s.r)]
	return {"asked": "Find the possible values of r.", "lines": two_lines(rep, s), "answer": ans,
		"wrongs": [wrong(Answer.xs_of([s.r]), R_ONE_ROOT), wrong(Answer.xs_of([s.uq.sub(s.up).div(gap)]), R_ARITHMETIC)],
		"generic": [Answer.xs_of([s.r.neg()]), Answer.xs_of([ratio.neg(), ratio]), Answer.xs_of([ratio]), Answer.xs_of([s.r.add(1).neg(), s.r.add(1)])],
		"methods": {
			"divide-terms": method([divide_line(s), ratio_line(s), root, say(ans)], ans.values),
			"step-count": method([step_line(s), ratio_line(s), root, say(ans)], ans.values),
			"gdc-solver": method(["Solve x%s = %s on the GDC, with the solver or by graphing both sides." % [Fmt.sup(gap), X(s, ratio)],
				"The graphs cross twice: x = %s and x = %s." % [X(s, s.r.neg()), X(s, s.r)], say(ans)], ans.values),
		}}


func u_u1_from_two_terms(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := val(s, "u₁ = ", s.u1)
	var back := "%s = u₁r%s, so u₁ = %s ÷ %s = %s" % [U(s.p), "¹" if s.p == 2 else Fmt.sup(s.p - 1), X(s, s.up), pow_text(s, s.r, s.p - 1), X(s, s.u1)]
	var root := "%s, so r = %s." % [ratio_line(s), X(s, s.r)]
	return {"asked": "Find u₁.", "lines": two_lines(rep, s), "answer": ans,
		"wrongs": [wrong({"v": s.up.div(power(s.r, s.p))}, R_COUNT_TERMS)],
		"generic": vs([s.up.mul(power(s.r, s.p - 1)), s.up.div(s.r), s.r, s.u1.neg(), s.up.sub(s.r.mul(s.p - 1))]),
		"methods": {
			"divide-terms": method([divide_line(s), root, back, say(ans)], ans.values),
			"step-count": method([step_line(s), root, "Go back %d steps from %s to u₁: divide by r %d times." % [s.p - 1, U(s.p), s.p - 1], back, say(ans)], ans.values),
		}}


func u_term_choose_sign(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := val(s, U(s.n) + " = ", s.v)
	var neg: bool = s.r.sign() < 0
	var mark := "<" if neg else ">"
	var word := "negative" if neg else "positive"
	var lines: Array
	if rep == "words":
		lines = ["In a geometric sequence the %s term is %s, the %s term is %s and the %s term is %s." % [ordinal(s.p), X(s, s.up), ordinal(s.q), X(s, s.uq), ordinal(s.m), word]]
	else:
		lines = ["%s = %s,  %s = %s,  %s %s 0" % [U(s.p), X(s, s.up), U(s.q), X(s, s.uq), U(s.m), mark]]
	var mag: Q = s.r.abs_q()
	var pick := "%s is an odd number of steps past %s, and %s is positive, so r has the sign of %s: r = %s." % [U(s.m), U(s.p), U(s.p), U(s.m), X(s, s.r)]
	var last := "%s = %s × %s = %s" % [U(s.n), B(s, s.uq), B(s, s.r), X(s, s.v)]
	var wrongs: Array = []
	var other: Q = s.uq.mul(s.r.neg())
	if neg:
		wrongs.append(wrong({"v": other}, R_ONE_ROOT))
	return {"asked": "Find %s." % U(s.n), "lines": lines, "answer": ans, "wrongs": wrongs,
		"generic": vs([other, s.uq.add(s.uq.sub(s.up).div(s.q - s.p)), s.uq.mul(s.uq.div(s.up)), s.v.mul(s.r), s.v.div(2)]),
		"methods": {
			"divide-terms": method([divide_line(s), "%s, so r = ±%s." % [ratio_line(s), X(s, mag)], pick, last, say(ans)], ans.values),
			"step-count": method([step_line(s), "%s, so r = ±%s." % [ratio_line(s), X(s, mag)], pick, last, say(ans)], ans.values),
		}}


func u_interior_terms(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pv: Q = s.v[0]
	var qv: Q = s.v[1]
	var ans := named(s, ["p", "q"], [pv, qv])
	var ratio: Q = s.fourth.div(s.first)
	var a := X(s, s.first)
	var b := X(s, s.fourth)
	var lines: Array = ["%s, p, q, %s" % [a, b]]
	if rep == "words":
		lines = ["The numbers %s, p, q and %s are four consecutive terms of a geometric sequence." % [a, b]]
	var third: Q = s.fourth.sub(s.first).div(3)
	var wrongs := [wrong(vals_of([s.first.add(third), s.first.add(third.mul(2))]), R_ARITHMETIC)]
	if s.paper == 2:
		var r4 := pow(ratio.to_float(), 0.25)
		wrongs.append(wrong(vals_of([qf(s.first.to_float() * r4), qf(s.first.to_float() * r4 * r4)]), R_COUNT_TERMS))
	var cube := "r³ = %s ÷ %s = %s" % [b, a, X(s, ratio)]
	var root := "r = the cube root of %s = %s" % [B(s, ratio), X(s, s.r)]
	var finish := "p = %s × %s = %s and q = %s × %s = %s" % [a, B(s, s.r), X(s, pv), X(s, pv), B(s, s.r), X(s, qv)]
	return {"asked": "Find p and q." if rep == "words" else "These are four consecutive terms of a geometric sequence. Find p and q.",
		"lines": lines, "answer": ans, "wrongs": wrongs,
		"generic": [vals_of([qv, pv]), vals_of([pv, pv.mul(2)]), vals_of([pv.add(1), qv.add(1)]), vals_of([pv.sub(1), qv.add(2)])],
		"methods": {
			"step-count": method(["From %s to %s is 3 steps, so multiply by r 3 times." % [a, b], cube, root, finish, say(ans)], ans.values),
			"divide-terms": method(["Call the terms u₁ to u₄. u₄ ÷ u₁ = u₁r³ ÷ u₁, and the u₁ cancels.", cube, root, finish, say(ans)], ans.values),
		}}


static func expr(a: int, b: int) -> String:
	return Fmt.poly([a, b], "k")


func u_k_consecutive(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e: Array = s.e
	var t1 := expr(e[0], e[1])
	var t2 := expr(e[2], e[3])
	var t3 := expr(e[4], e[5])
	var ans := xs_ans(s, "k", s.v)
	var lines: Array = ["%s,  %s,  %s" % [t1, t2, t3]]
	if rep == "words":
		lines = ["The first three terms of a geometric sequence are %s, %s and %s." % [t1, t2, t3]]
	var big_a: int = e[2] * e[2] - e[0] * e[4]
	var big_b: int = 2 * e[2] * e[3] - e[0] * e[5] - e[4] * e[1]
	var big_c: int = e[3] * e[3] - e[1] * e[5]
	if big_a < 0:
		big_a = -big_a
		big_b = -big_b
		big_c = -big_c
	var quad := Fmt.poly([big_a, big_b, big_c], "k")
	var disc := big_b * big_b - 4 * big_a * big_c
	var left := Fmt.poly([e[2] * e[2], 2 * e[2] * e[3], e[3] * e[3]], "k")
	var right := Fmt.poly([e[0] * e[4], e[0] * e[5] + e[4] * e[1], e[1] * e[5]], "k")
	var k1: Q = s.v[0]
	var k2: Q = s.v[1]
	var wrongs: Array = []
	var lin_a: int = e[0] + e[4] - 2 * e[2]
	var lin_b: int = e[1] + e[5] - 2 * e[3]
	if lin_a != 0:
		wrongs.append(wrong(Answer.xs_of([Q.new(-lin_b, lin_a)]), R_ARITHMETIC))
	return {"asked": "Find the possible values of k." if rep == "words" else "These are the first three terms of a geometric sequence. Find the possible values of k.",
		"lines": lines, "answer": ans, "wrongs": wrongs,
		"generic": [Answer.xs_of([k1]), Answer.xs_of([k2]), Answer.xs_of([k1.neg(), k2.neg()]), Answer.xs_of([k1.add(1), k2.add(1)])],
		"methods": {
			"equal-ratios": method(["Consecutive terms share a ratio, so the middle term squared is the product of its neighbours: (%s)² = (%s)(%s)." % [t2, t1, t3],
				"Expand: %s = %s" % [left, right], "Collect the terms: %s = 0" % quad,
				_roots_line(disc, big_a, big_b), say(ans)], ans.values),
			"gdc-solver": method(["Consecutive terms share a ratio, so (%s)² = (%s)(%s)." % [t2, t1, t3],
				"Solve it on the GDC, or enter %s = 0 in the polynomial solver." % quad, "The solutions are k = %s and k = %s." % [X(s, k1), X(s, k2)], say(ans)], ans.values),
		}}


## The quadratic formula's line: "Δ = 1764 = 42², so k = (42 ± 42)/2", or with the surd left in.
static func _roots_line(disc: int, a: int, b: int) -> String:
	var root := roundi(sqrt(float(disc)))
	var top := Fmt.num(-b)
	if root * root == disc:
		return "Δ = %d = %d², so k = (%s ± %d)/%d" % [disc, root, top, root, 2 * a]
	return "Δ = %d, so k = (%s ± √%d)/%d" % [disc, top, disc, 2 * a]


func u_coefficients_geometric(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pows: Array = s.pow
	var c: Array = s.top
	var ans := val(s, "h = ", s.v)
	var a: int = pows[0]
	var b: int = pows[1]
	var d: int = pows[2]
	var e: int = 2 * b - a - d
	var lhs := "%sh%s" % [Fmt.num(c[1].sq()), Fmt.sup(2 * b)]
	var rhs := "%sh%s" % [Fmt.num(c[0].mul(c[2])), Fmt.sup(a + d)]
	var ratio: Q = c[0].mul(c[2]).div(c[1].sq()) if e > 0 else c[1].sq().div(c[0].mul(c[2]))
	var solve := "h%s = %s" % [Fmt.sup(absi(e)), X(s, ratio)]
	var flip: Q = Q.new(1).div(ratio)
	var gen: Array = vs([flip, ratio.mul(2), s.v.mul(2), s.v.div(2)])
	if absi(e) == 2:
		gen = vs([ratio, s.v.mul(2), s.v.div(2), qf(1.0 / s.v.to_float())])
	return {"asked": "The coefficients of x%s, x%s and x%s are the first three terms of a geometric sequence. Find h." % ["" if a == 1 else Fmt.sup(a), Fmt.sup(b), Fmt.sup(d)],
		"lines": ["(1 + hx)%s, where h > 0" % Fmt.sup(s.n)], "answer": ans, "generic": gen,
		"methods": {
			"equal-ratios": method(["The coefficients are %sC%d h%s = %sh%s, %sC%d h%s = %sh%s and %sC%d h%s = %sh%s." % [s.n, a, Fmt.sup(a), Fmt.num(c[0]), Fmt.sup(a), s.n, b, Fmt.sup(b), Fmt.num(c[1]), Fmt.sup(b), s.n, d, Fmt.sup(d), Fmt.num(c[2]), Fmt.sup(d)],
				"Middle term squared = product of its neighbours: %s = %s" % [lhs, rhs], "Divide by the lower power of h, and take the root if a power is left: %s" % solve, say(ans)], ans.values),
			"gdc-solver": method(["The coefficients are %sh%s, %sh%s and %sh%s." % [Fmt.num(c[0]), Fmt.sup(a), Fmt.num(c[1]), Fmt.sup(b), Fmt.num(c[2]), Fmt.sup(d)],
				"Geometric means %s = %s. Graph both sides for h > 0." % [lhs, rhs], "The graphs cross at h = %s." % X(s, s.v), say(ans)], ans.values),
		}}


# ── Finite sums ──────────────────────────────────────────────

## A sum of the first n terms, by each method the map lists.
func _sum_methods(s: Dictionary, n: int, ans: Dictionary, first: String) -> Dictionary:
	var f := sum_formula(s, s.u1, s.r, n)
	var total := partial(s.u1, s.r, n)
	return {
		"sum-formula": method([first, f[0], "%s = %s" % [f[1], sum_worked(s, s.u1, s.r, n)], say(ans)], ans.values),
		"shift-subtract": method(shift_steps(s, s.u1, s.r, n, say(ans)), ans.values),
		"direct-add": method([first, add_line(s, s.u1, s.r, n), say(ans)], ans.values),
		"gdc-sum-seq": method([first, gdc_sum(s, s.u1, s.r, n), say(ans)], ans.values),
	}


func _sum_wrongs(s: Dictionary, n: int, ref: String = R_SUM_POWER) -> Array:
	var out := [wrong({"v": partial(s.u1, s.r, n - 1)}, ref)]
	if s.r.sign() < 0 and n % 2 == 1:
		out.append(wrong({"v": s.u1.mul(Q.new(1).sub(power(s.r.abs_q(), n))).div(Q.new(1).sub(s.r))}, R_SUM_SIGN))
	return out


func _sum_generic(s: Dictionary, n: int) -> Array:
	return vs([partial(s.u1, s.r, n + 1), term(s, n), s.u1.mul(n), partial(s.u1, s.r, n).neg(), partial(s.u1, s.r, n).mul(2)])


func u_sum_from_u1_r(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := val(s, SS(s.n) + " = ", s.v)
	var first := notation(s) if rep == "notation" else "u₁ = %s and r = u₂ ÷ u₁ = %s" % [X(s, s.u1), X(s, s.r)]
	return with(shown(rep, s), {"asked": "Find %s, the sum of the first %d terms." % [SS(s.n), s.n], "answer": ans, "wrongs": _sum_wrongs(s, s.n),
		"generic": _sum_generic(s, s.n), "methods": _sum_methods(s, s.n, ans, first)})


func u_sum_exact(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := val(s, SS(s.n) + " = ", s.v)
	var first := notation(s) if rep == "notation" else "u₁ = %s and r = u₂ ÷ u₁ = %s" % [X(s, s.u1), X(s, s.r)]
	return with(shown(rep, s), {"asked": "Find the exact value of %s, the sum of the first %d terms." % [SS(s.n), s.n], "answer": ans, "wrongs": _sum_wrongs(s, s.n),
		"generic": _sum_generic(s, s.n), "methods": _sum_methods(s, s.n, ans, first)})


func u_sum_last_term(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := val(s, "Sum = ", s.v)
	var first := series(s, [s.u1, term(s, 2), term(s, 3)], " + … ") + ("− " if s.last.sign() < 0 else "+ ") + X(s, s.last.abs_q())
	var count := "r = %s. The last term is %s = %s × %s, so there are %d terms." % [X(s, s.r), X(s, s.last), B(s, s.u1), pow_text(s, s.r, s.n - 1), s.n]
	var methods := _sum_methods(s, s.n, ans, count)
	methods.erase("shift-subtract")
	return {"asked": "Find the sum of this geometric series.", "lines": [first], "answer": ans, "wrongs": _sum_wrongs(s, s.n, R_SUM_COUNT),
		"generic": _sum_generic(s, s.n), "methods": methods}


func u_sum_closed_form(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: Q = s.r
	var one: bool = s.u1.eq(1)
	var names: Array = ["a", "b"] if one else ["a", "k"]
	var second: Q = r.sub(1) if one else s.v
	var ans := named(s, names, [r, second])
	var shape := "(a^n − 1)/b" if one else "k(a^n − 1)"
	var line := "Sₙ = %s(%s^n − 1)/%s" % ["" if one else X(s, s.u1), X(s, r), X(s, r.sub(1))]
	var read := "Sₙ = (%s^n − 1)/%s" % [X(s, r), X(s, r.sub(1))] if one else "Sₙ = %s(%s^n − 1)" % [X(s, s.v), X(s, r)]
	if r.eq(2):
		line = "r − 1 = 1, so the bottom of the fraction goes."
	return {"asked": "Sₙ is the sum of the first n terms. Find %s and %s, where Sₙ = %s." % [names[0], names[1], shape],
		"lines": [notation(s)], "answer": ans,
		"generic": [vals_of([second, r]), vals_of([r, r if one else s.u1]), vals_of([r.add(1), second]), vals_of([r, second.add(1)]), vals_of([r, second.mul(2)])],
		"methods": {
			"sum-formula": method(["r > 1, so use Sₙ = u₁(r^n − 1)/(r − 1).", line, read, say(ans)], ans.values),
			"shift-subtract": method(["Write Sₙ = u₁ + u₁r + … + u₁r^(n − 1) and rSₙ = u₁r + … + u₁r^n.", "Subtract: rSₙ − Sₙ = u₁r^n − u₁, so Sₙ = u₁(r^n − 1)/(r − 1).", "Put in the numbers: " + line, read, say(ans)], ans.values),
		}}


func u_sum_of_sums(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: Q = s.r
	var d: Q = r.sub(1)
	var ans := named(s, ["a", "b", "c"], [r, d, d.sq()])
	var rt := X(s, r)
	var dt := X(s, d)
	return {"asked": "Sₙ is the sum of the first n terms. Find a, b and c, where S₁ + S₂ + … + Sₙ = (a(a^n − 1) − bn)/c.",
		"lines": [notation(s)], "answer": ans,
		"generic": [vals_of([r, d, d]), vals_of([r, Q.new(1), d.sq()]), vals_of([d, r, d.sq()]), vals_of([r, d, r.sq()])],
		"methods": {
			"sum-formula": method(["u₁ = 1, so each sum is Sₖ = (%s^k − 1)/%s, for k = 1 to n." % [rt, dt],
				"Add them: S₁ + … + Sₙ = ((%s + %s² + … + %s^n) − n)/%s, as −1 comes n times." % [rt, rt, rt, dt],
				"%s + %s² + … + %s^n is geometric, with first term %s: its sum is %s(%s^n − 1)/%s." % [rt, rt, rt, rt, rt, rt, dt],
				"So the total is (%s(%s^n − 1)/%s − n)/%s = (%s(%s^n − 1) − %sn)/%s." % [rt, rt, dt, dt, rt, rt, "" if d.eq(1) else dt, X(s, d.sq())], say(ans)], ans.values),
		}}


func u_sum_alternating(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Q = s.u1
	var count := "2m + 1" if s.odd else "2m"
	var ans := val(s, "Sum = ", s.v)
	var wrongs: Array = []
	if s.odd:
		wrongs.append(wrong({"v": Q.new(0)}, R_SUM_SIGN))
	var at := "(−1)^(%s) = %s" % [count, "−1, since the power is odd" if s.odd else "1, since the power is even"]
	var top := "2" if s.odd else "0"
	return {"asked": "Find the sum of the first %s terms, where m is a positive whole number." % count, "lines": [terms_line(s)], "answer": ans, "wrongs": wrongs,
		"generic": vs([a, a.neg(), a.mul(2), a.mul(-2), Q.new(1)]),
		"methods": {
			"sum-formula": method(["u₁ = %s and r = −1, so the sum is %s(1 − (−1)^(%s))/2." % [X(s, a), B(s, a), count], at, "The sum is %s × %s/2 = %s." % [B(s, a), top, X(s, s.v)], say(ans)], ans.values),
			"direct-add": method(["Pair the terms: (%s) + (%s) = 0, and every pair cancels." % [X(s, a), X(s, a.neg())],
				"%s terms make m pairs, with %s." % [count, "one term left over, the last, which is %s" % X(s, a) if s.odd else "nothing left over"], say(ans)], ans.values),
		}}


# ── A bouncing ball ──────────────────────────────────────────

## What the question shows: the story, and on a diagram the path of the first bounces.
static func ball_lines(s: Dictionary) -> Array:
	var thing: String = BALLS[s.ctx]
	var rate: String = X(s, s.r) if s.paper == 1 else "%s%%" % Fmt.dec(s.r.mul(100))
	if s.has("h"):
		return ["A %s is dropped from a height of %s m. Each time it lands it rebounds to %s of the height it fell from." % [thing, X(s, s.h), rate]]
	return ["A %s is dropped from a height of x metres. Each time it lands it rebounds to %s of the height it fell from." % [thing, rate]]


static func ball_figure(s: Dictionary) -> Dictionary:
	var r: float = s.r.to_float()
	var peaks: Array = []
	for i in 7:
		peaks.append(pow(r, i))
	return {"kind": "bounce", "peaks": peaks, "h_label": "%s m" % X(s, s.h) if s.has("h") else "x m"}


static func ball_frame(rep: String, s: Dictionary) -> Dictionary:
	return {"lines": ball_lines(s), "graph": ball_figure(s) if rep == "diagram" else null}


func u_bounce_before(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: Q = s.h
	var r: Q = s.r
	var n: int = s.n
	var ans := val(s, "Distance = ", s.v, " m")
	var u := h.mul(2).mul(r)
	var back := partial(u, r, n - 1)
	var f := sum_formula(s, u, r, n - 1)
	var first := "The drop is %s m. Each of the %d rebounds before that landing goes up and back down: 2 × %s × %s = %s m, and so on." % [X(s, h), n - 1, X(s, h), B(s, r), X(s, u)]
	var vals: Array = [h]
	for i in n - 1:
		vals.append(u.mul(power(r, i)))
	return with(ball_frame(rep, s), {"asked": "Find the total distance it has travelled at the moment it lands for the %s time." % ordinal(n), "answer": ans,
		"wrongs": [wrong({"v": back.add(h.mul(2))}, R_DOUBLE_DROP)],
		"generic": vs([h.add(partial(h.mul(r), r, n - 1)), h.add(partial(u, r, n)), back, h.mul(2).mul(partial(Q.new(1), r, n))]),
		"methods": {
			"sum-formula": method([first, "The rebounds are geometric: u₁ = %s, r = %s, %d terms. %s" % [X(s, u), X(s, r), n - 1, f[0]],
				"%s = %s" % [f[1], X(s, back)], "Add the drop: %s + %s = %s" % [X(s, h), X(s, back), X(s, s.v)], say(ans)], ans.values),
			"direct-add": method([first, "%s = %s" % [series(s, vals), X(s, s.v)], say(ans)], ans.values),
			"gdc-sum-seq": method([first, "%s + sum(seq(%s × %s^(k − 1), k, 1, %d)) = %s" % [X(s, h), X(s, u), B(s, r), n - 1, X(s, s.v)], say(ans)], ans.values),
		}})


# ── Sigma notation ───────────────────────────────────────────

## "Σ (k = 1 to 6) 5(2)^(k − 1)"
static func sigma_text(s: Dictionary) -> String:
	var tail := "k" if s.shift == 0 else ("(k − %d)" % -s.shift if s.shift < 0 else "(k + %d)" % s.shift)
	var top: String = "∞" if s.upper < 0 else str(s.upper)
	return "Σ (k = %d to %s) %s(%s)^%s" % [s.lower, top, X(s, s.c), X(s, s.b), tail]


## "Put k = 1: 5 × 2 = 10", the first term from the lower limit.
static func first_line(s: Dictionary) -> String:
	var e: int = s.lower + s.shift
	return "Put k = %d: u₁ = %s × %s = %s" % [s.lower, B(s, s.c), pow_text(s, s.b, e), X(s, s.u1)]


func u_sigma_first_r(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := named(s, ["u₁", "r"], [s.u1, s.r])
	var wrongs: Array = []
	if not s.u1.eq(s.c):
		wrongs.append(wrong(vals_of([s.c, s.r]), R_SIGMA_FIRST))
	wrongs.append(wrong(vals_of([s.u1, s.c]), R_SIGMA_R))
	return {"asked": "Write down u₁ and r for this series.", "lines": [sigma_text(s)], "answer": ans, "wrongs": wrongs,
		"generic": [vals_of([s.r, s.c]), vals_of([s.u1.mul(s.r), s.r]), vals_of([s.u1, s.r.neg()]), vals_of([s.u1.neg(), s.r]), vals_of([s.u1.add(1), s.r.add(1)])],
		"methods": {
			"list-and-formula": method([first_line(s), "Each step adds 1 to k, which multiplies the term by the base, so r = %s." % X(s, s.r), say(ans)], ans.values),
		}}


func u_sigma_evaluate(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var ans := val(s, "Sum = ", s.v)
	var count := "There are %d − %d + 1 = %d terms." % [s.upper, s.lower, n]
	var f := sum_formula(s, s.u1, s.r, n)
	var wrongs: Array = []
	if not s.u1.eq(s.c):
		wrongs.append(wrong({"v": partial(s.c, s.r, n)}, R_SIGMA_FIRST))
	wrongs.append(wrong({"v": partial(s.u1, s.r, n - 1)}, R_SIGMA_COUNT))
	var inner: Q = s.u1.div(s.c)
	var inner_sum := partial(inner, s.r, n)
	var fi := sum_formula(s, inner, s.r, n)
	var outer := "Take %s outside the Σ. What is left starts at %s, with r = %s." % [X(s, s.c), X(s, inner), X(s, s.r)]
	return {"asked": "Find the value of this sum.", "lines": [sigma_text(s)], "answer": ans, "wrongs": wrongs,
		"generic": vs([partial(s.u1, s.r, n + 1), s.u1.mul(power(s.r, n - 1)), s.c.mul(n), s.v.neg()]),
		"methods": {
			"list-and-formula": method(["%s, and r = %s." % [first_line(s), X(s, s.r)], count, "%s, so %s = %s" % [f[0], f[1], X(s, s.v)], say(ans)], ans.values),
			"factor-out": method([outer, count, "%s = %s" % [fi[1], X(s, inner_sum)], "%s × %s = %s" % [B(s, s.c), B(s, inner_sum), X(s, s.v)], say(ans)], ans.values),
			"gdc-sigma": method(["Type the Σ with k from %d to %d into the GDC, as it stands." % [s.lower, s.upper], "The GDC gives %s." % X(s, s.v), say(ans)], ans.values),
		}}


func u_sigma_write(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := named(s, ["a", "b", "n"], [s.u1, s.r, Q.new(s.n)])
	var line := series(s, [s.u1, term(s, 2), term(s, 3)], " + … ") + ("− " if s.last.sign() < 0 else "+ ") + X(s, s.last.abs_q())
	return {"asked": "Write this series as Σ (k = 1 to n) a(b)^(k − 1). Find a, b and n.", "lines": [line], "answer": ans,
		"generic": [vals_of([s.u1, s.r, Q.new(s.n - 1)]), vals_of([s.r, s.u1, Q.new(s.n)]), vals_of([s.u1, s.r, Q.new(s.n + 1)]), vals_of([s.u1, s.r.neg(), Q.new(s.n)])],
		"methods": {
			"list-and-formula": method(["At k = 1 the power is 0, so a is the first term: a = %s." % X(s, s.u1), "b is the common ratio: b = %s ÷ %s = %s." % [X(s, term(s, 2)), B(s, s.u1), X(s, s.r)],
				"The last term is %s = %s × %s, so k stops at n = %d." % [X(s, s.last), B(s, s.u1), pow_text(s, s.r, s.n - 1), s.n], say(ans)], ans.values),
		}}


# ── Does a sum to infinity exist? ────────────────────────────

## Sₙ at some n on a GDC's table, for the partial-sums methods.
static func table_line(s: Dictionary, u1: Q, r: Q, ns: Array) -> String:
	var bits: PackedStringArray = []
	for n in ns:
		bits.append("%s = %s" % [SS(n), W(far_sum(u1, r, n))])
	return ", ".join(bits)


func u_exists_claim(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: Q = s.r
	var mag := X(s, r.abs_q())
	var bad: Q = inf(s.u1, r) if not r.eq(1) else Q.new(0)
	var formula := claim("sum", "Yes: S∞ = u₁/(1 − r) = %s" % X(s, bad))
	var right: String
	var wrongs: Array = []
	var generic: Array = []
	match s.kind:
		"conv":
			right = "Yes: |r| = %s, which is less than 1" % mag
			generic = [claim("a", "No: |r| = %s, and |r| has to be more than 1" % mag), claim("b", "No: the terms never reach 0"), claim("c", "No: an infinite sum can't be finite")]
		"big", "neg-big":
			right = "No: |r| = %s, which is more than 1" % mag
			wrongs.append(wrong(formula, R_NO_LIMIT))
			if s.kind == "neg-big":
				wrongs.append(wrong(claim("below", "Yes: r = %s, which is less than 1" % X(s, r)), R_R_BELOW_ONE))
			generic = [claim("a", "Yes: r is not 1"), claim("b", "Yes: S∞ exists for any r except 1"), claim("c", "No: r is not a whole number")]
		_:
			right = "No: |r| = 1, and |r| has to be less than 1"
			wrongs.append(wrong(claim("ends", "Yes: |r| ≤ 1 is enough"), R_ENDS))
			if s.kind == "neg-one":
				wrongs.append(wrong(formula, R_NO_LIMIT))
			generic = [claim("a", "Yes: the terms stay the same size"), claim("b", "No: S∞ only exists when r is negative"), claim("c", "Yes: S∞ = %s" % X(s, s.u1))]
	var ans := Answer.make("claim", claim("right", right))
	var u2 := term(s, 2)
	var conv: bool = s.kind == "conv"
	var read := "r = u₂ ÷ u₁ = %s ÷ %s = %s" % [X(s, u2), B(s, s.u1), X(s, r)] if rep == "terms" else "r = %s" % X(s, r)
	var seen := "The sums settle." if conv else "The sums never settle."
	return with(shown(rep, s), {"asked": "Does the sum to infinity of this geometric series exist?", "answer": ans, "wrongs": wrongs, "generic": generic,
		"methods": {
			"test-ratio": method([read, "S∞ exists only when |r| < 1, and here |r| = %s." % mag, "%s." % right], ans.values),
			"partial-sums": method([read, "On the GDC: %s" % table_line(s, s.u1, r, [10, 20, 30]), seen, "%s." % right], ans.values),
		}})


func u_exists_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ns := [1, 2, 5, 10, 20, 30]
	var cells: Array = ns.map(func(n): return W(far_sum(s.u1, s.r, n)))
	var conv: bool = s.kind == "conv"
	var limit: Q = inf(s.u1, s.r)
	var settle := Fmt.sf(limit)
	var right: String
	var wrongs: Array = []
	var generic: Array
	if conv:
		right = "S∞ exists: the sums settle near %s" % settle
		generic = [claim("a", "S∞ does not exist: the sums keep changing"), claim("b", "S∞ = %s, the first sum" % W(far_sum(s.u1, s.r, 1))), claim("c", "S∞ does not exist: no term is 0")]
	else:
		right = "S∞ does not exist: the sums never settle"
		wrongs.append(wrong(claim("sum", "S∞ exists: u₁/(1 − r) = %s" % Fmt.sf(limit)), R_NO_LIMIT))
		generic = [claim("a", "S∞ exists: it is the last sum shown"), claim("b", "S∞ exists: it is the first sum shown"), claim("c", "S∞ = 0: the sums cancel in the end")]
	var ans := Answer.make("claim", claim("right", right))
	return {"asked": "The table shows partial sums of a geometric series. What does it show about S∞?", "lines": ["Sₙ on a GDC, to 6 s.f."],
		"table": {"rows": [["n", ns.map(func(n): return str(n))], ["Sₙ", cells]]}, "answer": ans, "wrongs": wrongs, "generic": generic,
		"methods": {
			"partial-sums": method(["Look down the table as n grows: %s, %s, %s." % [cells[3], cells[4], cells[5]],
				"The later sums %s." % ("agree more and more" if conv else "move further and further apart"), "%s." % right], ans.values),
		}}


## "(2x + 1)/3"
static func r_text(s: Dictionary) -> String:
	var top := Fmt.poly([s.ax, s.bx])
	if s.cx == 1:
		return top
	return "(%s)/%d" % [top, s.cx] if s.bx != 0 else "%s/%d" % [top, s.cx]


static func band_graph(s: Dictionary) -> Dictionary:
	var a: float = float(s.ax) / s.cx
	var c: float = float(s.bx) / s.cx
	var lo: float = s.lo.to_float()
	var hi: float = s.hi.to_float()
	var spread := hi - lo
	var x0 := floori(lo - spread / 2.0)
	var x1 := ceili(hi + spread / 2.0)
	var curve := Plot.sample(func(x): return a * x + c, x0, x1)
	var spec := Plot.spec([curve], [], x0, x1, -3, 3, [[1, "y = 1"], [-1, "y = −1"]])
	return spec


func u_x_interval(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var lo: String = Fmt.num(s.lo)
	var hi: String = Fmt.num(s.hi)
	var text := "%s < x < %s" % [lo, hi]
	var ans := Answer.make("form", {"lo": s.lo, "hi": s.hi, "text": text}, {"parts": [{"slot": "lo"}, " < x < ", {"slot": "hi"}]})
	ans.exact = true
	var shape := func(t: String): return {"lo": s.lo, "hi": s.hi, "text": t, "shape": "other"}
	# Solving r < 1 alone gives one end: x < hi for a rising line, x > lo for a falling one.
	var one: String = "x < %s" % Fmt.num(Q.new(s.cx - s.bx, s.ax)) if s.ax > 0 else "x > %s" % Fmt.num(Q.new(s.cx - s.bx, s.ax))
	var neg_lo: Q = s.hi.neg()
	var neg_hi: Q = s.lo.neg()
	var plain := "r = %s" % r_text(s)
	var graph_rep: bool = rep == "graph"
	var lines: Array = ["A geometric series has common ratio r = %s, where x is a real number." % r_text(s)]
	var asked := "Find the values of x for which the sum to infinity exists."
	var out := {"asked": asked, "answer": ans, "lines": lines,
		"wrongs": [wrong(shape.call(one), R_ONE_SIDE), wrong(shape.call("%s ≤ x ≤ %s" % [lo, hi]), R_ENDS)],
		"generic": [{"lo": neg_lo, "hi": neg_hi, "text": "%s < x < %s" % [Fmt.num(neg_lo), Fmt.num(neg_hi)]},
			shape.call("x < %s or x > %s" % [lo, hi]), shape.call("x > %s" % hi), shape.call("x < %s" % lo)],
	}
	if graph_rep:
		out.lines = ["The line shows the common ratio r of a geometric series as a function of x."]
		out.graph = band_graph(s)
		plain = "The line goes through (%s, %s) and (%s, %s), so r = %s." % [lo, "−1" if s.ax > 0 else "1", hi, "1" if s.ax > 0 else "−1", r_text(s)]
	var left := "−1 < %s < 1" % r_text(s)
	var times := "%s < %s < %s" % [Fmt.num(-s.cx), Fmt.poly([s.ax, s.bx]), Fmt.num(s.cx)]
	var shift := "" if s.bx == 0 else ("Add %d, then " % -s.bx if s.bx < 0 else "Subtract %d, then " % s.bx)
	var solved := "%s%s by %s%s." % [shift, "divide" if s.bx != 0 else "Divide", Fmt.num(s.ax), ", which flips both signs" if s.ax < 0 else ""]
	out.methods = {
		"double-inequality": method([plain, "S∞ exists when %s, so %s." % [left, times], solved, say(ans)], ans.values),
		"graph-band": method([plain if graph_rep else "Graph y = %s with the lines y = 1 and y = −1." % r_text(s), "The line is inside the band between x = %s and x = %s." % [lo, hi],
			"The ends are left out: |r| = 1 there, so the series has no sum to infinity.", say(ans)], ans.values),
	}
	return out


# ── The sum to infinity ──────────────────────────────────────

func _inf_methods(s: Dictionary, first: String, ans: Dictionary, u1: Q, r: Q) -> Dictionary:
	var v := inf(u1, r)
	var top := "S∞ = u₁/(1 − r) = %s/(1 − %s) = %s" % [B(s, u1), B(s, r), X(s, v)]
	var mag := "|r| = %s < 1, so S∞ exists." % X(s, r.abs_q())
	return {
		"formula": method([first, mag, top, say(ans)], ans.values),
		"limit-of-sn": method([first, "Sₙ = u₁(1 − r^n)/(1 − r), and |r| < 1, so r^n → 0 as n grows.", "Sₙ → u₁/(1 − r) = %s" % X(s, v), say(ans)], ans.values),
		"partial-sums": method([first, "On the GDC: %s" % table_line(s, u1, r, [20, 50, 100]), "They settle at the limit %s." % Fmt.work(v, 6), say(ans)], ans.values),
	}


func u_sinf_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := val(s, "S∞ = ", s.v)
	var first := notation(s) if rep == "notation" else "u₁ = %s and r = u₂ ÷ u₁ = %s" % [X(s, s.u1), X(s, s.r)]
	return with(shown(rep, s), {"asked": "Find the sum to infinity.", "answer": ans,
		"wrongs": [wrong({"v": s.u1.div(Q.new(1).add(s.r))}, R_PLUS_R)],
		"generic": vs([s.u1.div(s.r), s.u1.mul(s.r).div(Q.new(1).sub(s.r)), Q.new(1).div(Q.new(1).sub(s.r)), s.v.mul(2)]),
		"methods": _inf_methods(s, first, ans, s.u1, s.r)})


func u_sinf_sigma(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := val(s, "S∞ = ", s.v)
	var wrongs := [wrong({"v": s.u1.div(Q.new(1).add(s.r))}, R_PLUS_R)]
	if not s.u1.eq(s.c):
		wrongs.append(wrong({"v": s.c.div(Q.new(1).sub(s.r))}, R_INF_FIRST))
	var methods := _inf_methods(s, "%s, and r = %s." % [first_line(s), X(s, s.r)], ans, s.u1, s.r)
	methods.erase("partial-sums")
	return {"asked": "Find the sum to infinity of this series.", "lines": [sigma_text(s)], "answer": ans, "wrongs": wrongs,
		"generic": vs([s.r.mul(s.v), s.v.mul(2), s.v.div(2), s.c.div(s.r), s.v.add(1)]), "methods": methods}


func u_sinf_shaded(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := val(s, "Total shaded area = ", s.v)
	var cut2: int = s.cut * s.cut
	var grid := "%d by %d" % [s.cut, s.cut]
	var left := "%d" % (cut2 - s.shaded)
	var lines := ["A square of area %s is cut into a %s grid, and %d of the small squares are shaded." % [X(s, s.area), grid, s.shaded],
		"The top right square, which is not shaded, is then cut the same way, and so on for ever."]
	var first := "The first shading is %d/%d of %s = %s." % [s.shaded, cut2, X(s, s.area), X(s, s.u1)]
	return {"asked": "Find the total shaded area.", "lines": lines, "answer": ans,
		"graph": {"kind": "squares", "style": "shaded", "cut": s.cut, "shaded": s.shaded, "area": X(s, s.area)},
		"wrongs": [wrong({"v": s.u1.div(Q.new(1).add(s.r))}, R_PLUS_R)],
		"generic": vs([s.u1, s.area, s.area.mul(Q.new(s.shaded, s.cut)), s.u1.mul(2), s.v.mul(2)]),
		"methods": {
			"shaded-square": method([first, "Each new grid sits in one small square, 1/%d of the last square, so each shading is 1/%d of the one before." % [cut2, cut2],
				"The pieces add up to %s/(1 − 1/%d) = %s" % [X(s, s.u1), cut2, X(s, s.v)], say(ans)], ans.values),
			"formula": method([first, "r = 1/%d, as each grid is 1/%d the area of the last." % [cut2, cut2], "S∞ = %s/(1 − %s) = %s" % [B(s, s.u1), B(s, s.r), X(s, s.v)], say(ans)], ans.values),
		}}


func u_x_from_log_series(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: int = s.m2
	var b: int = s.base
	var ln: int = s.ln
	var log_name := Answer.log_name(b)
	var surd: bool = s.t > 0
	var target: String
	var ratio_text: String
	var solve: String
	if surd:
		var t: int = s.t
		target = "%s + %s√%d" % [t * m, "" if t == 1 else str(t), m]
		ratio_text = "p = 1/√%d" % m
		solve = "%s x = (%s)(1 − 1/√%d) = %d" % [log_name, target, m, ln]
	else:
		target = Fmt.num(s.sinf)
		ratio_text = "p = %s" % Fmt.num(s.r)
		solve = "%s x = %s × (1 − %s) = %d" % [log_name, target, Fmt.num(s.r), ln]
	var ans := Answer.make("number", {"v": s.v}, {}, "x = ")
	ans.exact = true
	return {"asked": "The series is geometric, with S∞ = %s. Find x." % target,
		"lines": ["%s x + p %s x + (1/%d) %s x + …, where x > 1 and p > 0" % [log_name, log_name, m, log_name]], "answer": ans,
		"generic": vs([Q.new(ln), s.v.mul(b), s.v.div(b), s.v.sq(), Q.new(b * ln)]),
		"methods": {
			"rearrange": method(["The first term is %s x. Equal ratios give p/1 = (1/%d)/p, so p² = 1/%d." % [log_name, m, m],
				"p > 0, so %s, and p is the common ratio." % ratio_text, "S∞ = (%s x)/(1 − p), so %s" % [log_name, solve],
				"Undo the log: x = %d^%d" % [b, ln], say(ans)], ans.values),
		}}


# ── Unknowns from a sum to infinity ──────────────────────────

static func inf_lines(rep: String, s: Dictionary, name: String, v: Q) -> Array:
	if rep == "words":
		return ["A geometric series has %s %s and sum to infinity %s." % ["common ratio" if name == "r" else "first term", X(s, v), X(s, s.sinf)]]
	return ["%s = %s,  S∞ = %s" % [name if name == "r" else "u₁", X(s, v), X(s, s.sinf)]]


func u_u1_from_sinf(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := val(s, "u₁ = ", s.u1)
	var gap: Q = Q.new(1).sub(s.r)
	return {"asked": "Find u₁.", "lines": inf_lines(rep, s, "r", s.r), "answer": ans,
		"wrongs": [wrong({"v": s.sinf.div(gap)}, R_INVERT)],
		"generic": vs([s.sinf.mul(s.r), s.sinf.mul(Q.new(1).add(s.r)), s.sinf.sub(s.r), s.u1.neg()]),
		"methods": {
			"rearrange": method(["S∞ = u₁/(1 − r), so u₁ = S∞(1 − r).", "u₁ = %s × (1 − %s) = %s × %s = %s" % [B(s, s.sinf), B(s, s.r), B(s, s.sinf), B(s, gap), X(s, s.u1)], say(ans)], ans.values),
			"gdc-solver": method(["Solve %s = x/(1 − %s) on the GDC." % [X(s, s.sinf), B(s, s.r)], "The solver gives x = %s." % X(s, s.u1), say(ans)], ans.values),
		}}


func u_r_from_sinf(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := val(s, "r = ", s.r)
	var share: Q = s.u1.div(s.sinf)
	return {"asked": "Find r.", "lines": inf_lines(rep, s, "u1", s.u1), "answer": ans,
		"wrongs": [wrong({"v": Q.new(1).sub(s.sinf.div(s.u1))}, R_INVERT)],
		"generic": vs([share, Q.new(1).add(share), s.r.neg(), s.sinf.div(s.u1)]),
		"methods": {
			"rearrange": method(["S∞ = u₁/(1 − r), so 1 − r = u₁/S∞ = %s ÷ %s = %s." % [X(s, s.u1), B(s, s.sinf), X(s, share)], "r = 1 − %s = %s" % [B(s, share), X(s, s.r)], say(ans)], ans.values),
			"gdc-solver": method(["Graph y = %s/(1 − x) and y = %s, for −1 < x < 1." % [B(s, s.u1), X(s, s.sinf)], "They cross at x = %s." % X(s, s.r), say(ans)], ans.values),
		}}


func u_r_from_multiple(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := val(s, "r = ", s.r)
	var k := X(s, s.mult)
	var lines: Array = ["S∞ = %s × u₁,  u₁ ≠ 0" % B(s, s.mult)]
	if rep == "words":
		lines = ["The sum to infinity of a geometric series is %s times its first term." % k]
	var flip: Q = Q.new(1).div(s.mult)
	return {"asked": "Find r.", "lines": lines, "answer": ans, "wrongs": [wrong({"v": Q.new(1).sub(s.mult)}, R_INVERT)],
		"generic": vs([flip, s.mult.sub(1), s.r.neg(), Q.new(1).add(flip)]),
		"methods": {
			"ratio-structure": method(["S∞/u₁ = 1/(1 − r), and S∞/u₁ = %s, with no need for u₁ itself." % k, "1 − r = 1 ÷ %s = %s" % [B(s, s.mult), X(s, flip)], "r = 1 − %s = %s" % [B(s, flip), X(s, s.r)], say(ans)], ans.values),
			"rearrange": method(["u₁/(1 − r) = %s × u₁. Divide both sides by u₁." % B(s, s.mult), "1/(1 − r) = %s, so 1 − r = %s" % [k, X(s, flip)], "r = 1 − %s = %s" % [B(s, flip), X(s, s.r)], say(ans)], ans.values),
		}}


## The quadratic in r from u₂ and S∞, as whole numbers where the numbers are.
static func quad_lines(rep: String, s: Dictionary) -> Array:
	if rep == "words":
		return ["The second term of a geometric series is %s and its sum to infinity is %s." % [X(s, s.u2), X(s, s.sinf)]]
	return ["u₂ = %s,  S∞ = %s" % [X(s, s.u2), X(s, s.sinf)]]


static func quad_text(s: Dictionary) -> String:
	return "%sr² − %sr %s = 0" % [X(s, s.sinf), X(s, s.sinf), ("− " if s.u2.sign() < 0 else "+ ") + X(s, s.u2.abs_q())]


func _quad_methods(s: Dictionary, ans: Dictionary, last: String) -> Dictionary:
	var sub := "u₁ = u₂/r = %s/r, so S∞ = %s/(r(1 − r)) = %s" % [X(s, s.u2), X(s, s.u2), X(s, s.sinf)]
	var roots: Array = s.roots
	var found := "The roots are r = %s and r = %s." % [X(s, roots[0]), X(s, roots[1])]
	return {
		"form-quadratic": method([sub, "Multiply by r(1 − r) and collect: %s" % quad_text(s), found, last, say(ans)], ans.values),
		"gdc-solver": method([sub, "Enter %s in the polynomial solver." % quad_text(s), found, last, say(ans)], ans.values),
	}


func u_r_from_u2_reject(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var roots: Array = s.roots
	var ans := xs_ans(s, "r", [roots[0]])
	var last := "S∞ exists only for |r| < 1, so reject r = %s." % X(s, roots[1])
	return {"asked": "Find r.", "lines": quad_lines(rep, s), "answer": ans,
		"wrongs": [wrong(Answer.xs_of([roots[0], roots[1]]), R_KEEP_ROOT), wrong(Answer.xs_of([roots[1]]), R_KEEP_ROOT), wrong(Answer.xs_of([Q.new(1).sub(s.u2.div(s.sinf))]), R_U2_AS_U1)],
		"generic": [Answer.xs_of([roots[0].neg()]), Answer.xs_of([roots[0].neg(), roots[1].neg()])], "methods": _quad_methods(s, ans, last)}


func u_r_from_u2_both(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var roots: Array = s.roots
	var ans := xs_ans(s, "r", roots)
	var last := "Both have |r| < 1, so both are possible."
	return {"asked": "Find the possible values of r.", "lines": quad_lines(rep, s), "answer": ans,
		"wrongs": [wrong(Answer.xs_of([Q.new(1).sub(s.u2.div(s.sinf))]), R_U2_AS_U1)],
		"generic": [Answer.xs_of([roots[0]]), Answer.xs_of([roots[1]]), Answer.xs_of([roots[0].neg(), roots[1].neg()]), Answer.xs_of([roots[0].mul(2), roots[1]])],
		"methods": _quad_methods(s, ans, last)}


# ── Applications ─────────────────────────────────────────────

func u_bounce_total(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: Q = s.h
	var r: Q = s.r
	var ans := val(s, "Total distance = ", s.v, " m")
	var one: Q = Q.new(1).sub(r)
	var u := h.mul(2).mul(r)
	var check_r := "|r| = %s < 1, so the rebounds have a sum to infinity." % X(s, r)
	var hr := h.mul(r)
	return with(ball_frame(rep, s), {"asked": "Find the total distance it travels before it comes to rest.", "answer": ans,
		"wrongs": [wrong({"v": h.mul(2).div(one)}, R_DOUBLE_DROP)],
		"generic": vs([h.div(one), u.div(one), h.mul(r).div(one), s.v.div(2)]),
		"methods": {
			"model-series": method(["The drop is %s m, then each rebound is up and back: %s m, %s m, and so on." % [X(s, h), X(s, u), X(s, u.mul(r))], check_r,
				"Rebounds: S∞ = %s/(1 − %s) = %s" % [X(s, u), B(s, r), X(s, u.div(one))], "%s + %s = %s" % [X(s, h), X(s, u.div(one)), X(s, s.v)], say(ans)], ans.values),
			"split-series": method(["Split the path: all the ups, and all the downs.", "Down: %s/(1 − %s) = %s" % [X(s, h), B(s, r), X(s, h.div(one))],
				"Up: %s/(1 − %s) = %s" % [X(s, hr), B(s, r), X(s, hr.div(one))], "%s + %s = %s" % [X(s, h.div(one)), X(s, hr.div(one)), X(s, s.v)], say(ans)], ans.values),
			"draw-stages": method(["Sketch the path: down %s, up %s, down %s, up %s, …" % [X(s, h), X(s, hr), X(s, hr), X(s, hr.mul(r))],
				"Only the first drop is alone: every height after it is travelled twice.", "Total = %s + 2(%s)/(1 − %s) = %s" % [X(s, h), X(s, hr), B(s, r), X(s, s.v)], say(ans)], ans.values),
			"partial-sums": method(["Distance after k rebounds = %s + 2(%s)(1 − %s^k)/(1 − %s)." % [X(s, h), X(s, hr), B(s, r), B(s, r)],
				"On the GDC, at k = 10, 30, 100: %s, %s, %s" % [W(_bounced(h, r, 10)), W(_bounced(h, r, 30)), W(_bounced(h, r, 100))], "They settle at %s." % Fmt.work(s.v, 6), say(ans)], ans.values),
		}})


static func _bounced(h: Q, r: Q, k: int) -> float:
	var x := r.to_float()
	return h.to_float() + 2.0 * h.to_float() * x * (1.0 - pow(x, k)) / (1.0 - x)


func u_bounce_multiple(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: Q = s.r
	var ans := val(s, "k = ", s.v)
	var one: Q = Q.new(1).sub(r)
	var top: Q = Q.new(1).add(r)
	return with(ball_frame(rep, s), {"asked": "The total distance it travels before it comes to rest is kx metres. Find k.", "answer": ans,
		"wrongs": [wrong({"v": Q.new(2).div(one)}, R_DOUBLE_DROP)],
		"generic": vs([Q.new(1).div(one), r.mul(2).div(one), top, s.v.mul(2)]),
		"methods": {
			"split-series": method(["Down: x/(1 − %s). Up: %sx/(1 − %s)." % [B(s, r), B(s, r), B(s, r)], "Total = x(1 + %s)/(1 − %s) = x × %s/%s" % [B(s, r), B(s, r), B(s, top), B(s, one)], "k = %s ÷ %s = %s" % [X(s, top), B(s, one), X(s, s.v)], say(ans)], ans.values),
			"model-series": method(["The path is x + 2 × %sx + 2 × %s²x + …: one drop, then a geometric series." % [B(s, r), B(s, r)], "|r| < 1, so the rebounds add to 2 × %sx/(1 − %s)." % [B(s, r), B(s, r)],
				"Total = x(1 + 2 × %s/%s) = %sx" % [B(s, r), B(s, one), X(s, s.v)], say(ans)], ans.values),
		}})


## A partial sum with the figures a recurring block needs.
static func _long(u1: Q, r: Q, n: int) -> String:
	return "%s = %s" % [SS(n), Fmt.dec(partial(u1, r, n))]


func u_recurring_decimal(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var block: String = str(s.digits).lpad(s.len, "0")
	var shown_digits := "0." + block.repeat(3) + "…"
	var top := int(pow(10.0, s.len))
	var ans := frac_ans("", s.v)
	var r: Q = s.r
	var wrongs: Array = []
	if s.len > 1:
		wrongs.append(wrong({"v": s.u1.div(Q.new(9, 10))}, R_BLOCK))
	var first := "Split it: 0.%s + 0.%s%s + …" % [block, "0".repeat(s.len), block]
	var firsts := "u₁ = %d/%d, r = 1/%d" % [s.digits, top, top]
	return {"asked": "Write this recurring decimal as a fraction.", "lines": [shown_digits], "answer": ans, "wrongs": wrongs,
		"generic": vs([s.u1, s.u1.mul(9).div(10), Q.new(s.digits, top + 1), s.v.mul(2), s.v.add(Q.new(1, top))]),
		"methods": {
			"model-series": method([first, firsts + ", and |r| < 1.", "S∞ = (%d/%d)/(1 − 1/%d) = %s" % [s.digits, top, top, s.v.text() if s.v.d == top - 1 else "%d/%d = %s" % [s.digits, top - 1, s.v.text()]], say(ans)], ans.values),
			"partial-sums": method([first, "On the GDC: %s, %s, %s" % [_long(s.u1, r, 1), _long(s.u1, r, 2), _long(s.u1, r, 3)], "The sums settle at %s, which the formula gives as %s." % [shown_digits, s.v.text()], say(ans)], ans.values),
		}}


func u_nested_squares(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: Q = s.t
	var r: Q = s.r
	var side: Q = s.h
	var ans := val(s, "Total area = ", s.v, " cm²")
	var away := Q.new(1).sub(t)
	var lines := ["A square has side %s cm. A second square is drawn inside it, with each corner %s of the way along a side." % [X(s, side), Fmt.num(t)],
		"A third square is drawn inside the second in the same way, and so on for ever."]
	var pyth := "Each new side is the long side of a right triangle, so its square is (%s)² + (%s)² = %s of the last side's square." % [Fmt.num(t), Fmt.num(away), Fmt.num(r)]
	var first := "The areas start at %s² = %s." % [X(s, side), X(s, s.u1)]
	var total := "S∞ = %s/(1 − %s) = %s" % [X(s, s.u1), B(s, r), X(s, s.v)]
	var angle_r: float = atan2(t.to_float(), away.to_float())
	return {"asked": "Find the total area of all the squares.", "lines": lines, "answer": ans,
		"graph": {"kind": "squares", "style": "nested", "t": t.to_float(), "turn": angle_r, "side": "%s cm" % X(s, side)},
		"generic": vs([s.u1, s.u1.div(Q.new(1).sub(t)), s.u1.div(Q.new(1).add(r)), s.v.mul(2), s.u1.mul(2)]),
		"methods": {
			"model-series": method([first, pyth, "The areas are geometric, with r = %s and |r| < 1." % Fmt.num(r), total, say(ans)], ans.values),
			"draw-stages": method(["Draw the first square inside: four right triangles sit in the corners.", pyth, first + " Next: %s, then %s." % [X(s, s.u1.mul(r)), X(s, s.u1.mul(r).mul(r))], total, say(ans)], ans.values),
		}}


## "75%" on Paper 2, "3/4" on Paper 1.
static func share_text(s: Dictionary, r: Q) -> String:
	return r.text() if s.paper == 1 else "%s%%" % Fmt.dec(r.mul(100))


static func story_lines(s: Dictionary, table: Array) -> Array:
	var c: Dictionary = table[s.ctx]
	var open: String = c.get("open", c.get("who", ""))
	return [open % X(s, s.u1) + " " + String(c.next) % share_text(s, s.r)]


func u_story_total(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = STORIES[s.ctx]
	var ans := val(s, "Total = ", s.v, c.unit)
	var one: Q = Q.new(1).sub(s.r)
	return {"asked": "Assume this goes on for ever. Find the total.", "lines": story_lines(s, STORIES), "answer": ans,
		"wrongs": [wrong({"v": s.u1.div(Q.new(1).add(s.r))}, R_PLUS_R)],
		"generic": vs([s.u1.div(s.r), s.u1.mul(s.r).div(one), s.v.mul(2), s.u1.mul(s.r)]),
		"methods": {
			"model-series": method(["The amounts are geometric: u₁ = %s, r = %s." % [X(s, s.u1), X(s, s.r)], "|r| < 1, so the total is a sum to infinity.", "S∞ = %s/(1 − %s) = %s" % [X(s, s.u1), B(s, s.r), X(s, s.v)], say(ans)], ans.values),
			"partial-sums": method(["The amounts are geometric: u₁ = %s, r = %s." % [X(s, s.u1), X(s, s.r)], "On the GDC: %s" % table_line(s, s.u1, s.r, [20, 50, 100]), "They settle at %s." % Fmt.work(s.v, 6), say(ans)], ans.values),
		}}


func u_story_target(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = SAVERS[s.ctx]
	var goal := "%s%s" % [X(s, s.target), c.unit]
	var limit: Q = s.sinf
	var lim := X(s, limit)
	var right: String
	var wrongs: Array = []
	var generic: Array
	var stops := claim("b", "No: the total stops once the amounts are small")
	if s.kind == "under":
		right = "No: the total stays below S∞ = %s, and that is less than %s" % [lim, goal]
		generic = [claim("a", "Yes: the total keeps rising, so it passes %s in the end" % goal), stops, claim("c", "Yes: an endless run of additions has no limit")]
	elif s.kind == "over":
		right = "Yes: S∞ = %s, which is more than %s" % [lim, goal]
		generic = [claim("a", "No: the amounts shrink, so the total can't pass %s" % X(s, s.u1)), stops, claim("c", "No: S∞ = %s, and the total never gets near it" % lim)]
	else:
		right = "Yes: r > 1, so the total grows without limit"
		wrongs.append(wrong(claim("sum", "No: S∞ = %s, so it stops there" % lim), R_NO_CHECK))
		generic = [claim("a", "No: the amounts added shrink"), claim("b", "No: the total can never pass %s" % goal), claim("c", "Yes: but only if the amounts stay the same")]
	var ans := Answer.make("claim", claim("right", right))
	var seen: String = "S∞ = %s/(1 − %s) = %s" % [X(s, s.u1), B(s, s.r), lim]
	var check_r := "|r| = %s, %s" % [X(s, s.r), "so a sum to infinity exists." if s.kind != "grow" else "more than 1, so there is no sum to infinity."]
	var step2 := seen if s.kind != "grow" else "The amounts grow, and so does the total."
	return {"asked": "Does the total ever reach %s?" % goal, "lines": story_lines(s, SAVERS), "answer": ans, "wrongs": wrongs, "generic": generic,
		"methods": {
			"model-series": method(["The amounts are geometric: u₁ = %s, r = %s." % [X(s, s.u1), X(s, s.r)], check_r, step2, "%s." % right], ans.values),
			"partial-sums": method(["The amounts are geometric: u₁ = %s, r = %s." % [X(s, s.u1), X(s, s.r)], "On the GDC: %s" % table_line(s, s.u1, s.r, [10, 20, 30]), "Compare those with %s." % goal, "%s." % right], ans.values),
		}}


func u_deposit_for_target(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = SAVERS[s.ctx]
	var ans := val(s, "First amount = ", s.v, c.unit)
	var goal := "%s%s" % [X(s, s.target), c.unit]
	var open: String = c.who
	var line: String = (open % "an amount").replace("an amount scrap", "an amount of scrap").replace("an amount litres of fuel", "some fuel").replace("an amount doses", "some doses")
	var r: Q = s.r
	var one: Q = Q.new(1).sub(r)
	var share: Q = one.div(Q.new(1).sub(power(r, s.n)))
	return {"asked": "The total after %d %ss is %s. Find the first amount, to 3 s.f." % [s.n, c.per, goal],
		"lines": [line + " " + String(c.next) % share_text(s, r)], "answer": ans,
		"wrongs": [],
		"generic": vs([s.target.mul(one), s.target.div(s.n), s.target.div(partial(Q.new(1), r, s.n + 1)), s.target.div(partial(Q.new(1), r, s.n - 1)), s.v.mul(2), s.v.div(2)]),
		"methods": {
			"model-series": method(["The amounts are geometric, with r = %s and %d terms." % [X(s, r), s.n],
				"S%s = u₁(1 − %s)/(1 − %s) = %s" % [sub(s.n), pow_text(s, r, s.n), B(s, r), X(s, s.target)],
				"u₁ = %s × (1 − %s)/(1 − %s) = %s" % [X(s, s.target), B(s, r), pow_text(s, r, s.n), X(s, s.v)], say(ans)], ans.values),
		}}
