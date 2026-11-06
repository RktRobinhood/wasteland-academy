class_name ArithmeticContextViews
extends ExtensionViews
## The views on the `arithmetic-context` situation: one builder per unknown of
## t1-arithmetic-in-context. Every question is Paper 2. A count or an amount that ends is marked
## exactly, as the IB gives it; what comes from imperfect data is to 3 s.f.; a judgement is a
## picked statement (Answer's `claim`), and the checker judges each statement from the numbers.
##
## Representations: "words" (the story), "table" (the first terms, or the data), "graph" (the
## line of uₙ against n with two dots labelled and the target drawn, or the data's labelled
## dots) and "diagram" (three stacks of rows side by side, drawn by PlotView's "stages").

const MO := "SL1.2.model#"
const R_FOUND_TERM := MO + "0"
const R_AFTER := MO + "1"
const R_EXTRAPOLATE := MO + "2"
const R_ONE_DIFF := MO + "3"
const R_FROM_LAST := MO + "4"
const R_B_AS_D := MO + "5"
const R_NO_B := MO + "6"
const R_EXACT := MO + "7"
const R_ALL_BAD := MO + "8"
const R_PAST_LIMIT := MO + "9"
const R_COMPOUND := MO + "10"
const R_ONLY_INTEREST := MO + "11"
const R_ONE_AWAY := MO + "12"
const R_TOTALS_ARITH := MO + "13"
const FN := "SL1.2.find-n#"
const R_ROUND_DOWN := FN + "0"
const R_N_OR_TERM := FN + "1"
const R_NO_ONE := FN + "2"
const R_ROUND_TERM := FN + "3"
const R_MULTIPLE := FN + "4"
const R_ROWS_CRATE := FN + "5"
const R_N_D := "SL1.2.nth-term#0"
const R_SIGN := "SL1.2.nth-term#1"
const R_SUM_N := "SL1.2.sum#0"
const R_SUM_GAPS := "SL1.2.sum#1"
const R_BY_TERMS := "SL1.2.find-u1-d#0"

const UNKNOWNS := ["term-in-context", "total-in-context", "term-or-total", "in-or-after", "value-after", "simple-interest",
	"estimate-d", "fit-gradient", "predict-from-gaps", "predict-from-line", "comment-validity", "stack-total", "peak-total",
	"term-number", "zero-term", "count-terms", "first-past", "first-total-past", "whole-n-test", "stack-crates"]


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
	out.given = ArithmeticContextSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A number that may be negative, in a sum: "(−2.5)".
static func PD(v: Q) -> String:
	return "(%s)" % D(v) if v.sign() < 0 else D(v)


static func W(v: Variant) -> String:
	return RegressionViews.W(v)


static func U(k: int) -> String:
	return ArithmeticSequenceViews.u(k)


static func SS(k: int) -> String:
	return ArithmeticSequenceViews.S(k)


static func term(s: Dictionary, k: int) -> Q:
	return ArithmeticContextSituation.term(s, k)


static func total(s: Dictionary, k: int) -> Q:
	return ArithmeticContextSituation.total(s, k)


## "= 20.4", or "≈ 20.3333" where the decimal doesn't end there.
static func is_val(v: Q) -> String:
	return ("= " if v.mul(10000).is_int() else "≈ ") + W(v)


static func value(v: Q, unit: String) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, "", " " + unit)
	ans.show = "dec"
	ans.exact = true
	return ans


static func for_n(k: int) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.new(k)}, {}, "n = ")
	ans.show = "dec"
	ans.exact = true
	return ans


static func to_3sf(v: Q, label: String, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label, " " + unit if unit != "" else "")
	ans.show = "sf"
	return ans


static func so(ans: Dictionary) -> String:
	return "So %s." % Answer.text(ans)


static func nums(vs: Array) -> Array:
	return vs.map(func(v): return {"v": v})


static func n_wrongs(pairs: Array) -> Array:
	return pairs.map(func(p): return wrong({"v": p[0]}, p[1]))


static func story(s: Dictionary) -> Dictionary:
	return ArithmeticContextSituation.STORIES[s.ctx]


static func opening(c: Dictionary, s: Dictionary) -> String:
	return c.open % [D(s.u1), D(s.d.abs_q())]


static func first_terms(s: Dictionary, count: int = 4) -> Array:
	var out: Array = []
	for k in range(1, count + 1):
		out.append(D(term(s, k)))
	return out


static func ks(from: int, count: int) -> Array:
	var out: Array = []
	for k in range(from, from + count):
		out.append(str(k))
	return out


## A round top for a window, a little above y_max, so the line fills it.
static func roomy(y_max: float) -> int:
	return int(ceilf(y_max * 1.15 / 10.0)) * 10


## uₙ against n from 1, with the first two dots labelled and the target drawn.
static func line_graph(s: Dictionary, target: Q, upto: int) -> Dictionary:
	var u1: float = s.u1.to_float()
	var d: float = s.d.to_float()
	var hi := upto + 2
	var f := func(x: float) -> float: return u1 + (x - 1.0) * d
	var last := float(upto) if target.is_zero() else float(hi)
	var top := roomy(maxf(maxf(u1, u1 + (hi - 1.0) * d), target.to_float()))
	var points: Array = []
	for k in [1, 2]:
		points.append([k, term(s, k).to_float(), "(%d, %s)" % [k, D(term(s, k))]])
	var lines: Array = [] if target.is_zero() else [[target.to_float(), "y = %s" % D(target)]]
	var g := Plot.spec([Plot.sample(f, 1.0, last)], points, 0, hi, 0, top, lines)
	g.x_name = "n"
	g.y_name = "uₙ"
	return g


## What the student is shown of a STORIES sequence. target and upto are for a graph.
static func setup(rep: String, s: Dictionary, target: Q = Q.new(0), upto: int = 0) -> Dictionary:
	var c := story(s)
	match rep:
		"table":
			return {"lines": ["The table shows %s." % c.show],
				"table": {"rows": [[c.heads[0], ks(1, 4)], [c.heads[1], first_terms(s)]]}}
		"graph":
			return {"lines": ["The line through the dots shows %s: the %s number n across, the amount up." % [c.show, c.step]],
				"graph": line_graph(s, target, upto)}
	return {"lines": [opening(c, s)]}


## The step that reads u₁ and d from what is shown.
static func read_of(rep: String, s: Dictionary) -> String:
	var two := term(s, 2)
	match rep:
		"table":
			return "From the table, u₁ = %s and d = u₂ − u₁ = %s − %s = %s." % [D(s.u1), D(two), D(s.u1), D(s.d)]
		"graph":
			return "From the two dots, u₁ = %s and d = u₂ − u₁ = %s − %s = %s." % [D(s.u1), D(two), D(s.u1), D(s.d)]
	return "From the story, u₁ = %s and d = %s." % [D(s.u1), D(s.d)]


## "40 + 11 × 3", "40 − 11 × 3"
static func term_sum(s: Dictionary, k: int) -> String:
	return "%s %s %d × %s" % [D(s.u1), "−" if s.d.sign() < 0 else "+", k, D(s.d.abs_q())]


## "(12 ÷ 2) × (2 × 40 + 11 × 3)"
static func sum_sum(s: Dictionary, n: int, k: int) -> String:
	return "(%d ÷ 2) × (2 × %s %s %d × %s)" % [n, D(s.u1), "−" if s.d.sign() < 0 else "+", k, D(s.d.abs_q())]


# ── One term, or the total ───────────────────────────────────

func u_term_in_context(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var n: int = s.n
	var ans := value(s.v, c.unit)
	var out := setup(rep, s)
	out.asked = "Find %s." % (c.term % n)
	out.answer = ans
	out.wrongs = n_wrongs([[term(s, n + 1), R_N_D], [total(s, n), R_FOUND_TERM]])
	out.generic = nums([term(s, n - 1), s.d.mul(n), s.v.add(s.u1)])
	var solved := method([read_of(rep, s),
		"One %s is one term, so n = %d and this is uₙ = u₁ + (n − 1)d." % [c.step, n],
		"%s = %s = %s" % [U(n), term_sum(s, n - 1), D(s.v)], so(ans)], {"v": s.v})
	var listed := method(["%s 1, 2 and 3 are %s, %s and %s: each is one step of %s from the last." % [c.step.capitalize(), D(s.u1), D(term(s, 2)), D(term(s, 3)), D(s.d)],
		"%s 3 is %s + 2 × %s, so %s %d is %d steps from %s 1." % [c.step.capitalize(), D(s.u1), PD(s.d), c.step, n, n - 1, c.step],
		"%s = %s" % [term_sum(s, n - 1), D(s.v)], so(ans)], {"v": s.v})
	out.methods = {"identify-parameters": solved, "tabulate": listed}
	return out


func u_total_in_context(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var n: int = s.n
	var sum := total(s, n)
	var ans := value(sum, c.unit)
	var out := setup(rep, s)
	out.asked = "Find %s." % (c.sum % n)
	out.answer = ans
	out.wrongs = n_wrongs([[s.v, R_FOUND_TERM], [sum.add(s.d.mul(n).div(2)), R_SUM_N], [total(s, n - 1), R_SUM_GAPS]])
	out.generic = nums([total(s, n + 1), s.u1.mul(n), s.v.mul(n)])
	var solved := method([read_of(rep, s),
		"A total over %d %ss is a sum, so n = %d and Sₙ = (n ÷ 2)(2u₁ + (n − 1)d)." % [n, c.step, n],
		"%s = %s = %s" % [SS(n), sum_sum(s, n, n - 1), D(sum)], so(ans)], {"v": sum})
	var running: Array = [s.u1, total(s, 2), total(s, 3)].map(func(v): return D(v))
	var listed := method(["The running totals of the first %ss are %s, %s and %s." % [c.step, running[0], running[1], running[2]],
		"The first term is %s, and the last, %s %d, is %s = %s." % [D(s.u1), c.step, n, term_sum(s, n - 1), D(s.v)],
		"The %d terms average (%s + %s) ÷ 2, so the total is %d × (%s + %s) ÷ 2 = %s." % [n, D(s.u1), D(s.v), n, D(s.u1), D(s.v), D(sum)], so(ans)], {"v": sum})
	out.methods = {"identify-parameters": solved, "tabulate": listed}
	return out


func u_term_or_total(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := story(s)
	var n: int = s.n
	var is_term: bool = s.case == "term"
	var right: String = term_sum(s, n - 1) if is_term else sum_sum(s, n, n - 1)
	var wrongs: Array = [[sum_sum(s, n, n - 1), R_FOUND_TERM], [term_sum(s, n), R_N_D], ["%d × %s" % [n, D(s.u1)], ""]] if is_term \
		else [[term_sum(s, n - 1), R_FOUND_TERM], [sum_sum(s, n, n), R_SUM_N], ["%d × (%s)" % [n, term_sum(s, n - 1)], ""]]
	var made := DerivativeMeaningViews.claim_answer(right, rng.shuffled(wrongs))
	var out := setup(rep, s)
	var goal: String = c.term % n if is_term else c.sum % n
	out.asked = "Which calculation gives %s?" % goal
	out.answer = made.answer
	out.wrongs = made.wrongs
	out.methods = {"identify-parameters": method([read_of(rep, s),
		"This asks for %s, so it is %s." % ["one term, not a total" if is_term else "a total of %d terms, not one term" % n, U(n) if is_term else SS(n)],
		"uₙ = u₁ + (n − 1)d" if is_term else "Sₙ = (n ÷ 2)(2u₁ + (n − 1)d)", right], made.answer.values)}
	return out


func u_in_or_after(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var n: int = s.n
	var is_after: bool = s.case == "after"
	var at: int = n + 1 if is_after else n
	var v := term(s, at)
	var ans := value(v, c.unit)
	var out := setup(rep, s)
	out.asked = "Find the %s once %d full %ss have passed." % [c.what, n, c.step] if is_after \
		else "Find the %s %s %s %d." % [c.what, c.on, c.step, n]
	out.answer = ans
	out.wrongs = n_wrongs([[term(s, n), R_AFTER]]) if is_after else n_wrongs([[term(s, n + 1), R_N_D]])
	out.wrongs.append_array(n_wrongs([[total(s, n), R_FOUND_TERM]]))
	out.generic = nums([term(s, at + 1), term(s, at - 1), s.d.mul(n)])
	var where := "Once %d full %ss have passed, %s %d is under way, so this is %s." % [n, c.step, c.step, n + 1, U(at)] if is_after \
		else "%s %d is term %d, so this is %s." % [c.step.capitalize(), n, n, U(at)]
	var solved := method([read_of(rep, s), where, "%s = %s = %s" % [U(at), term_sum(s, at - 1), D(v)], so(ans)], {"v": v})
	var listed := method(["%s 1, 2 and 3 are %s, %s and %s." % [c.step.capitalize(), D(s.u1), D(term(s, 2)), D(term(s, 3))],
		"After 1 full %s, %s 2 is under way, so the term number is one more than the full %ss passed." % [c.step, c.step, c.step] if is_after \
			else "The term number is the %s number itself." % c.step,
		"%s = %s = %s" % [U(at), term_sum(s, at - 1), D(v)], so(ans)], {"v": v})
	out.methods = {"identify-parameters": solved, "tabulate": listed}
	return out


# ── An amount that starts, then changes each step ────────────

func u_value_after(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = ArithmeticContextSituation.STOCKS[s.ctx]
	var n: int = s.n
	var ans := value(s.v, c.unit)
	var out := {"lines": [opening_stock(c, s)]}
	if rep == "table":
		out = {"lines": ["The table shows %s." % c.show], "table": {"rows": [[c.heads[0], ks(0, 4)], [c.heads[1], [D(s.u1), D(term(s, 2)), D(term(s, 3)), D(term(s, 4))]]]}}
	out.asked = "Find the %s after %d %ss." % [c.what, n, c.step]
	out.answer = ans
	out.wrongs = n_wrongs([[term(s, n), R_AFTER]])
	out.generic = nums([term(s, n + 2), s.d.mul(n).abs_q(), s.u1.add(s.d.mul(n * 2))])
	var start := "The amount at the start is u₁ = %s, before any %s has passed, and d = %s." % [D(s.u1), c.step, D(s.d)]
	var solved := method([start, "After 1 %s it is u₂, so after %d %ss it is %s." % [c.step, n, c.step, U(n + 1)],
		"%s = %s = %s" % [U(n + 1), term_sum(s, n), D(s.v)], so(ans)], {"v": s.v})
	var listed := method(["After 0, 1 and 2 %ss the amount is %s, %s and %s." % [c.step, D(s.u1), D(term(s, 2)), D(term(s, 3))],
		"The number of steps of %s is the number of %ss passed." % [D(s.d), c.step],
		"After %d %ss: %s = %s" % [n, c.step, term_sum(s, n), D(s.v)], so(ans)], {"v": s.v})
	out.methods = {"identify-parameters": solved, "tabulate": listed}
	return out


static func opening_stock(c: Dictionary, s: Dictionary) -> String:
	return c.open % [D(s.u1), D(s.d.abs_q())]


func u_simple_interest(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var p: Q = s.u1
	var ans := value(s.v, "tokens")
	ans.show = "money"
	var grown := p.to_float() * pow(1.0 + s.rate.to_float() / 100.0, n)
	var compound := Q.new(roundi(grown * 100.0), 100)
	var out := {"lines": ["A scout leaves %s tokens with the Bazaar Bank at %s%% simple interest a year, and takes nothing out." % [D(p), D(s.rate)]]}
	if rep == "table":
		out = {"lines": ["The table shows the value of a scout's deposit at the Bazaar Bank, which earns simple interest and has nothing taken out."],
			"table": {"rows": [["Years passed", ks(0, 4)], ["Tokens", [Fmt.money(p), Fmt.money(term(s, 2)), Fmt.money(term(s, 3)), Fmt.money(term(s, 4))]]]}}
	out.asked = "Find the value of the deposit after %d years." % n
	out.answer = ans
	out.wrongs = n_wrongs([[term(s, n), R_AFTER], [compound, R_COMPOUND], [s.I.mul(n), R_ONLY_INTEREST]])
	out.generic = nums([term(s, n + 2), p.add(s.rate.mul(n))])
	var read := "The interest a year is %s%% of %s = %s tokens, the same every year." % [D(s.rate), D(p), Fmt.money(s.I)] if rep != "table" \
		else "The value goes up by %s − %s = %s tokens each year." % [Fmt.money(term(s, 2)), Fmt.money(p), Fmt.money(s.I)]
	var solved := method([read, "So u₁ = %s, the deposit before any year has passed, d = %s, and after %d years the value is %s." % [D(p), D(s.I), n, U(n + 1)],
		"%s = %s + %d × %s = %s" % [U(n + 1), D(p), n, D(s.I), Fmt.money(s.v)], so(ans)], {"v": s.v})
	var listed := method([read, "After 0, 1 and 2 years the value is %s, %s and %s." % [Fmt.money(p), Fmt.money(term(s, 2)), Fmt.money(term(s, 3))],
		"After %d years: %s + %d × %s = %s" % [n, D(p), n, D(s.I), Fmt.money(s.v)], so(ans)], {"v": s.v})
	out.methods = {"identify-parameters": solved, "tabulate": listed}
	return out


# ── Imperfect data ───────────────────────────────────────────

static func data_story(s: Dictionary) -> Dictionary:
	return ArithmeticContextSituation.DATA[s.ctx]


static func data_setup(rep: String, s: Dictionary) -> Dictionary:
	var c := data_story(s)
	var shown: Array = s.ys.map(func(y): return str(y))
	match rep:
		"table":
			return {"lines": [c.open], "table": {"rows": [["Year n", s.xs.map(func(x): return str(x))], [c.head, shown]]}}
		"graph":
			var dots: Array = []
			for i in s.m:
				dots.append([s.xs[i], s.ys[i], shown[i]])
			var g := Plot.spec([], dots, 0, s.m + 1, 0, roomy(float(s.ys.max())))
			g.x_name = "n"
			g.y_name = c.head
			return {"lines": [c.open, "The graph shows the data, with each dot's value beside it, for years n = 1 to %d." % s.m], "graph": g}
	return {"lines": [c.open, "For years 1 to %d in turn, the values were %s." % [s.m, ", ".join(shown)]]}


## The change from first to last, and the gaps.
static func gap_step(s: Dictionary) -> String:
	return "d ≈ (last − first) ÷ number of gaps = (%d − %d) ÷ %d %s" % [s.ys[s.m - 1], s.ys[0], s.m - 1, is_val(s.avg)]


static func signed_b(b: Q) -> String:
	return "%s %s" % ["−" if b.sign() < 0 else "+", W(b.abs_q())]


static func linreg(s: Dictionary) -> String:
	return "Enter n and the values in two lists and run LinReg (ax + b): a = %s and b = %s." % [W(s.a), W(s.b)]


func u_estimate_d(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := data_story(s)
	var ans := to_3sf(s.avg, "d ≈ ")
	var out := data_setup(rep, s)
	out.asked = "The %s is modelled by an arithmetic sequence. Estimate the common difference d from the first and last values, to 3 s.f." % c.what
	out.answer = ans
	out.wrongs = n_wrongs([[s.d1, R_ONE_DIFF], [Q.new(s.ys[s.m - 1] - s.ys[0], s.m), R_BY_TERMS]])
	if c.sign < 0:
		out.wrongs.append(wrong({"v": s.avg.neg()}, R_SIGN))
	out.generic = nums([Q.new(s.ys[s.m - 1] - s.ys[0]), s.a.mul(2), s.avg.add(1)])
	out.methods = {"average-difference": method(["The values do not change by the same amount each year, so d can only be estimated.",
		"%d values have %d gaps between them." % [s.m, s.m - 1], gap_step(s), so(ans)], {"v": s.avg})}
	return out


func u_fit_gradient(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := data_story(s)
	var ans := to_3sf(s.a, "d ≈ ")
	var out := data_setup(rep, s)
	out.asked = "The %s is modelled by an arithmetic sequence. Use the regression line of the values on n to estimate the common difference d, to 3 s.f." % c.what
	out.answer = ans
	out.wrongs = n_wrongs([[s.b, R_B_AS_D], [s.d1, R_ONE_DIFF]])
	out.generic = nums([s.avg, s.a.neg(), s.a.mul(2)])
	out.methods = {"gdc-regression": method([linreg(s),
		"a is the change in the value for one more year, so it plays the part of d.", so(ans)], {"v": s.a})}
	return out


func u_predict_from_gaps(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := data_story(s)
	var big_n: int = s.N
	var ans := to_3sf(s.pa, "", c.unit)
	var out := data_setup(rep, s)
	out.asked = "The %s is modelled by an arithmetic sequence with u₁ as the value in year 1. Estimate d from the first and last values, then predict the value in year %d, to 3 s.f." % [c.what, big_n]
	out.answer = ans
	out.wrongs = n_wrongs([[s.pa.add(s.avg), R_N_D], [Q.new(s.ys[s.m - 1]).add(s.avg.mul(big_n)), R_FROM_LAST],
		[Q.new(s.ys[0]).add(s.d1.mul(big_n - 1)), R_ONE_DIFF]])
	out.generic = nums([s.avg.mul(big_n), s.pa.sub(s.avg), s.pa.mul(2)])
	out.methods = {"average-difference": method([gap_step(s),
		"Year %d is %d steps on from year 1, so %s ≈ %d + %d × %s." % [big_n, big_n - 1, U(big_n), s.ys[0], big_n - 1, PDW(s.avg)],
		"%s %s" % [U(big_n), is_val(s.pa)], so(ans)], {"v": s.pa})}
	return out


## A 6 s.f. value that may be negative, in a sum.
static func PDW(v: Q) -> String:
	return "(%s)" % W(v) if v.sign() < 0 else W(v)


func u_predict_from_line(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := data_story(s)
	var big_n: int = s.N
	var ans := to_3sf(s.pl, "", c.unit)
	var out := data_setup(rep, s)
	out.asked = "The %s is modelled by the regression line of the values on n. Use it to predict the value in year %d, to 3 s.f." % [c.what, big_n]
	out.answer = ans
	out.wrongs = n_wrongs([[s.a.mul(big_n), R_NO_B], [s.pl.add(s.a), R_N_D]])
	out.generic = nums([s.pa, s.pl.sub(s.a), s.b.mul(big_n)])
	out.methods = {"gdc-regression": method([linreg(s),
		"Put n = %d into the line, keeping the GDC's values: y = %s × %d %s." % [big_n, W(s.a), big_n, signed_b(s.b)],
		"y %s" % is_val(s.pl), so(ans)], {"v": s.pl})}
	return out


func u_comment_validity(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := data_story(s)
	var big_n: int = s.N
	var m: int = s.m
	var line: bool = angle == "gdc-regression"
	var p: Q = s.pl if line else s.pa
	var rising: bool = c.sign > 0
	var said := Fmt.sf(p)
	var exact := "Valid and exact: the model gives the value in year %d with no error." % big_n
	var all_bad := "Not valid: data that are not exactly arithmetic can't be used to predict anything."
	var right := ""
	var wrongs: Array = []
	var verdict := ""
	var out := data_setup(rep, s)
	match s.case:
		"near":
			right = "Reasonable: year %d is close to the data, and the yearly changes all go the same way." % big_n
			wrongs = [[exact, R_EXACT], [all_bad, R_ALL_BAD], ["Not valid: year %d is far beyond the data, which end at year %d." % [big_n, m], ""]]
			verdict = "That is only %d past the data, and the yearly changes have all gone the same way." % (big_n - m)
			if rising:
				s.cap = int(ceilf(maxf(s.pa.to_float(), s.pl.to_float()) * 1.3 / 10.0)) * 10
				out.lines.append(c.cap % s.cap)
				wrongs.append(["Not valid: about %s is over the limit of %d." % [said, s.cap], ""])
		"far":
			right = "Doubtful: year %d is far beyond the data, which end at year %d, so the steady change may not last." % [big_n, m]
			wrongs = [["Valid: the change has been steady, so it will carry on for any number of years.", R_EXTRAPOLATE], [exact, R_EXACT], [all_bad, R_ALL_BAD]]
			verdict = "That is %d years past the data, far more than the %d years the data cover." % [big_n - m, m]
		_:
			if rising:
				out.lines.append(c.cap % s.cap)
				right = "Not valid: about %s is over the limit of %d, so the model has stopped applying." % [said, s.cap]
				verdict = "The story's limit is %d, and %s is over it." % [s.cap, said]
			else:
				out.lines.append("The %s can't be less than 0." % c.what)
				right = "Not valid: about %s is below 0, which is impossible, so the model has stopped applying." % said
				verdict = "The %s can't be less than 0, and %s is." % [c.what, said]
			wrongs = [["Valid: the data fit the model well, so the prediction can be trusted.", R_PAST_LIMIT], [exact, R_EXACT], [all_bad, R_ALL_BAD]]
	var made := DerivativeMeaningViews.claim_answer(right, rng.shuffled(wrongs))
	out.asked = "A scout uses the data to predict the %s in year %d, and gets about %s. Comment on the validity of this prediction." % [c.what, big_n, said]
	out.answer = made.answer
	out.wrongs = made.wrongs
	var changes: Array = []
	for i in range(1, m):
		changes.append(s.ys[i] - s.ys[i - 1])
	var spread := "The yearly changes run from %s to %s." % [D(Q.new(changes.min())), D(Q.new(changes.max()))]
	var steps: Array = [spread, "%s, so %s %s." % [gap_step(s), U(big_n), is_val(s.pa)]] if not line \
		else [linreg(s), "Pearson's r = %s, and at n = %d, y %s." % [W(GdcKit.qf(s.r)), big_n, is_val(s.pl)]]
	steps.append_array([verdict, right])
	var key: String = "gdc-regression" if line else "average-difference"
	out.methods = {key: method(steps, made.answer.values)}
	return out


# ── Stacks in rows ───────────────────────────────────────────

static func pile(s: Dictionary) -> Dictionary:
	return ArithmeticContextSituation.PILES[s.ctx]


## Stacks of 1, 2 and 3 rows, each row given by its length, top row first.
static func stages(s: Dictionary) -> Dictionary:
	var out: Array = []
	for rows in [1, 2, 3]:
		var one: Array = []
		for k in range(1, rows + 1):
			one.append(term(s, k).n)
		out.append(one)
	return {"kind": "stages", "stages": out, "names": ["n = 1", "n = 2", "n = 3"]}


static func t(k: int) -> String:
	return "t" + ArithmeticSequenceViews.sub(k)


static func pile_setup(rep: String, s: Dictionary) -> Dictionary:
	var c := pile(s)
	match rep:
		"diagram":
			return {"lines": ["The figure shows stacks of %s with 1, 2 and 3 rows. Each extra row goes under the stack." % c.thing], "graph": stages(s)}
		"table":
			return {"lines": ["%s are stacked in rows. Each extra row goes under the stack, and is longer than the row above it by the same number of %s. The table shows tₙ, the number of %s in a stack of n rows." % [c.thing.left(1).to_upper() + c.thing.substr(1), c.thing, c.thing]],
				"table": {"rows": [["Rows n", ks(1, 4)], ["tₙ", [D(total(s, 1)), D(total(s, 2)), D(total(s, 3)), D(total(s, 4))]]]}}
	return {"lines": [c.open % [D(s.u1), D(s.d)]]}


static func pile_read(rep: String, s: Dictionary) -> String:
	if rep == "table":
		return "The rows added are %s − %s = %s and %s − %s = %s, so u₁ = %s and d = %s." % [D(total(s, 2)), D(total(s, 1)), D(term(s, 2)),
			D(total(s, 3)), D(total(s, 2)), D(term(s, 3)), D(s.u1), D(s.d)]
	if rep == "diagram":
		return "The rows have %s, %s and %s %s, so u₁ = %s and d = %s." % [D(s.u1), D(term(s, 2)), D(term(s, 3)), pile(s).thing, D(s.u1), D(s.d)]
	return "The rows give u₁ = %s and d = %s." % [D(s.u1), D(s.d)]


func u_stack_total(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := pile(s)
	var n: int = s.n
	var ans := value(s.v, c.thing)
	var out := pile_setup(rep, s)
	out.asked = "Find %s, the number of %s in a stack of %d rows." % [t(n), c.thing, n]
	out.answer = ans
	var t1 := total(s, 1)
	var t2 := total(s, 2)
	out.wrongs = n_wrongs([[term(s, n), R_FOUND_TERM], [t1.add(t2.sub(t1).mul(n - 1)), R_TOTALS_ARITH],
		[total(s, n - 1), R_SUM_GAPS], [s.v.add(s.d.mul(n).div(2)), R_SUM_N]])
	out.generic = nums([total(s, n + 1), s.u1.mul(n)])
	var rows: Array = []
	var running: Array = []
	for k in range(1, n + 1):
		rows.append(D(term(s, k)))
		running.append(D(total(s, k)))
	var solved := method([pile_read(rep, s), "A stack of %d rows holds all %d rows, so %s = %s." % [n, n, t(n), SS(n)],
		"%s = %s = %s" % [SS(n), sum_sum(s, n, n - 1), D(s.v)], so(ans)], {"v": s.v})
	var listed := method([pile_read(rep, s), "Row by row: %s." % ", ".join(rows), "Running totals: %s." % ", ".join(running), so(ans)], {"v": s.v})
	out.methods = {"identify-parameters": solved, "tabulate": listed}
	return out


func u_stack_crates(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := pile(s)
	var k: int = s.k
	var ans := for_n(k)
	var out := pile_setup(rep, s)
	out.lines.append(c.crate % s.c)
	out.asked = "A stack uses only whole %s, with nothing left over. Find n, the smallest number of rows it can have." % c.pack
	out.answer = ans
	var wr: Array = [[Q.new(s.c), R_ROWS_CRATE]]
	if s.rowk > 0:
		wr.append([Q.new(s.rowk), R_FOUND_TERM])
	out.wrongs = n_wrongs(wr)
	out.generic = nums([Q.new(k + 1), Q.new(k - 1), Q.new(k * 2)])
	out.methods = {"gdc-table": method([pile_read(rep, s),
		"The total in n rows is Sₙ, so enter Y1 = X ÷ 2 × (2 × %s + (X − 1) × %s) ÷ %d and open the table." % [D(s.u1), D(s.d), s.c],
		"X = %d gives %s, which is not whole, and X = %d gives %s, the first whole value." % [k - 1, W(total(s, k - 1).div(s.c)), k, W(total(s, k).div(s.c))],
		so(ans)], {"v": Q.new(k)})}
	return out


# ── Greatest running total ───────────────────────────────────

func u_peak_total(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = ArithmeticContextSituation.NET[s.ctx]
	var k: int = s.k
	var ans := value(s.v, c.unit)
	var out := {"lines": [c.open % [D(s.u1), D(s.d.abs_q())]]}
	if rep == "table":
		out = {"lines": ["The table shows %s. The terms go on falling by the same amount." % c.show],
			"table": {"rows": [[c.heads[0], ks(1, 4)], [c.heads[1], first_terms(s)]]}}
	out.asked = c.ask
	out.answer = ans
	out.wrongs = n_wrongs([[total(s, k + 1) if term(s, k + 1).sign() < 0 else total(s, k + 2), R_ONE_AWAY], [total(s, k - 1), R_ONE_AWAY],
		[s.u1, R_FOUND_TERM], [Q.new(k), R_N_OR_TERM]])
	out.generic = nums([total(s, 2 * k), s.u1.mul(k)])
	var first := "From the %s, u₁ = %s and d = %s." % ["table" if rep == "table" else "story", D(s.u1), D(s.d)]
	var solved := method([first,
		"The total grows while the terms are above 0. The last is %s = %s, and %s = %s." % [U(k), D(term(s, k)), U(k + 1), D(term(s, k + 1))],
		"So the greatest total is %s." % SS(k),
		"%s = %s = %s" % [SS(k), sum_sum(s, k, k - 1), D(s.v)], so(ans)], {"v": s.v})
	var tab := method([first, "Enter Y1 = X ÷ 2 × (2 × %s + (X − 1) × %s), the running total, and open the table." % [D(s.u1), PD(s.d)],
		"X = %d, %d and %d give %s, %s and %s." % [k - 1, k, k + 1, D(total(s, k - 1)), D(total(s, k)), D(total(s, k + 1))],
		"The greatest value in the table is %s." % D(s.v), so(ans)], {"v": s.v})
	out.methods = {"identify-parameters": solved, "gdc-table": tab}
	return out


# ── Finding n ────────────────────────────────────────────────

static func gdc_enter(s: Dictionary) -> String:
	return "Enter Y1 = %s + (X − 1) × %s and open the table." % [D(s.u1), PD(s.d)]


static func graph_pair(s: Dictionary, target: Q) -> String:
	return "Graph y = %s + (x − 1) × %s and y = %s." % [D(s.u1), PD(s.d), D(target)]


## The four ways to a target that is a term.
static func to_term(rep: String, s: Dictionary, target: Q, k: int, ans: Dictionary) -> Dictionary:
	var read := read_of(rep, s)
	var r: Dictionary = {"v": Q.new(k)}
	var gap: Q = target.sub(s.u1).abs_q()
	return {
		"solve-linear": method([read, "%s + (n − 1) × %s = %s" % [D(s.u1), PD(s.d), D(target)],
			"n − 1 = (%s − %s) ÷ %s = %d" % [D(target), D(s.u1), PD(s.d), k - 1], "n = %d + 1 = %d" % [k - 1, k], so(ans)], r),
		"count-steps": method([read, "From %s to %s is a change of %s, and each step is %s, so that is %s ÷ %s = %d steps." % [D(s.u1), D(target), D(gap), D(s.d.abs_q()), D(gap), D(s.d.abs_q()), k - 1],
			"Term 1 comes before any step, so add one: %d + 1 = %d." % [k - 1, k], so(ans)], r),
		"gdc-table": method([read, gdc_enter(s), "The table gives %s at X = %d and %s at X = %d." % [D(term(s, k - 1)), k - 1, D(target), k], so(ans)], r),
		"graph-intersect": method([read, graph_pair(s, target), "They meet at x = %d, a whole number." % k, so(ans)], r),
	}


func u_term_number(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var k: int = s.k
	var ans := for_n(k)
	var out := setup(rep, s, s.v, k)
	out.asked = (c.find % D(s.v)) + " Give n, the %s number." % c.step
	out.answer = ans
	out.wrongs = n_wrongs([[Q.new(k - 1), R_NO_ONE], [s.v, R_N_OR_TERM]])
	out.generic = nums([Q.new(k + 1), Q.new(k + 2), Q.new(k - 2)])
	out.methods = to_term(rep, s, s.v, k, ans)
	return out


func u_zero_term(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var k: int = s.k
	var ans := for_n(k)
	var out := setup(rep, s, Q.new(0), k)
	out.asked = c.zero + " Give n, the %s number." % c.step
	out.answer = ans
	out.wrongs = n_wrongs([[Q.new(k - 1), R_NO_ONE]])
	out.generic = nums([Q.new(k + 1), Q.new(k + 2), Q.new(k - 2)])
	out.methods = to_term(rep, s, Q.new(0), k, ans)
	return out


func u_count_terms(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = ArithmeticContextSituation.LINES[s.ctx]
	var k: int = s.k
	var ans := for_n(k)
	var first: String = D(s.u1)
	var last: String = D(s.last)
	var out := {"lines": [c.open % [str(s.gap), first, last]]}
	if rep == "table":
		out = {"lines": ["The table shows %s." % c.show, c.end % last],
			"table": {"rows": [[c.head, ks(1, 4)], [c.unit, first_terms(s)]]}}
	out.asked = "Find n, the number of %s." % c.thing
	out.answer = ans
	out.wrongs = n_wrongs([[Q.new(k - 1), R_NO_ONE]])
	out.generic = nums([Q.new(k + 1), Q.new(k + 2), Q.new(k - 2)])
	var read := "From the table, u₁ = %s and d = %s − %s = %d." % [first, D(term(s, 2)), first, s.gap] if rep == "table" \
		else "u₁ = %s, d = %d and the last term is %s." % [first, s.gap, last]
	var gaps: Q = s.last.sub(s.u1)
	out.methods = {
		"count-steps": method([read, "From %s to %s is %s %s, which is %s ÷ %d = %d gaps." % [first, last, D(gaps), c.unit, D(gaps), s.gap, k - 1],
			"There is one more %s than gaps: %d + 1 = %d." % [c.one, k - 1, k], so(ans)], {"v": Q.new(k)}),
		"solve-linear": method([read, "%s + (n − 1) × %d = %s" % [first, s.gap, last], "n − 1 = (%s − %s) ÷ %d = %d" % [last, first, s.gap, k - 1],
			"n = %d + 1 = %d" % [k - 1, k], so(ans)], {"v": Q.new(k)})}
	return out


func u_first_past(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var k: int = s.k
	var x: Q = s.X
	var rising: bool = s.d.sign() > 0
	var ans := for_n(k)
	var out := setup(rep, s, x, k)
	out.asked = (c.past % D(x)) + " Give n, the %s number." % c.step
	out.answer = ans
	var by_sum := 0
	if rising:
		var j := 1
		while total(s, j).lt(x) or total(s, j).eq(x):
			j += 1
		by_sum = j
	out.wrongs = n_wrongs([[Q.new(k - 1), R_ROUND_DOWN], [s.v, R_N_OR_TERM]])
	if by_sum > 0:
		out.wrongs.append(wrong({"v": Q.new(by_sum)}, R_FOUND_TERM))
	out.generic = nums([Q.new(k + 1), Q.new(k + 2), Q.new(k - 2)])
	var gap: Q = x.sub(s.u1).abs_q()
	var step: Q = s.d.abs_q()
	var word := "more" if rising else "less"
	var sign := ">" if rising else "<"
	var r: Dictionary = {"v": Q.new(k)}
	out.methods = {
		"solve-linear": method([read_of(rep, s), "%s %s" % ["%s + (n − 1) × %s" % [D(s.u1), PD(s.d)], "%s %s" % [sign, D(x)]],
			"n − 1 > %s ÷ %s %s" % [D(gap), D(step), is_val(gap.div(step))],
			"n > %s, and n is whole, so round up to %d." % [W(s.real), k], so(ans)], r),
		"gdc-table": method([read_of(rep, s), gdc_enter(s), "The table gives %s at X = %d and %s at X = %d, the first %s than %s." % [D(term(s, k - 1)), k - 1, D(term(s, k)), k, word, D(x)], so(ans)], r),
		"graph-intersect": method([read_of(rep, s), graph_pair(s, x), "They meet at x %s, which is not whole." % is_val(s.real),
			"The first whole n past it is %d." % k, so(ans)], r)}
	return out


func u_first_total_past(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var k: int = s.k
	var x: Q = s.X
	var ans := for_n(k)
	var out := setup(rep, s)
	out.asked = (c.total % D(x)) + " Give n, the %s number." % c.step if c.step != "row" else (c.total % D(x)) + " Give n."
	out.answer = ans
	var j := 1
	while term(s, j).lt(x) or term(s, j).eq(x):
		j += 1
	out.wrongs = n_wrongs([[Q.new(k - 1), R_ROUND_DOWN], [s.v, R_N_OR_TERM], [Q.new(j), R_FOUND_TERM]])
	out.generic = nums([Q.new(k + 1), Q.new(k + 2), Q.new(k - 2)])
	var r: Dictionary = {"v": Q.new(k)}
	var expr := "%s ÷ 2 × (2 × %s + (%s − 1) × %s)"
	out.methods = {
		"gdc-table": method([read_of(rep, s), "The total of n terms is Sₙ, so enter Y1 = %s and open the table." % (expr % ["X", D(s.u1), "X", PD(s.d)]),
			"The table gives %s at X = %d and %s at X = %d, the first more than %s." % [D(total(s, k - 1)), k - 1, D(s.v), k, D(x)], so(ans)], r),
		"graph-intersect": method([read_of(rep, s), "Graph y = %s and y = %s." % [expr % ["x", D(s.u1), "x", PD(s.d)], D(x)],
			"They meet at x ≈ %s, which is not whole, and the total only rises." % W(s.real),
			"So round up to %d." % k, so(ans)], r)}
	return out


func u_whole_n_test(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := story(s)
	var v: Q = s.v
	var step: Q = s.d.abs_q()
	var real: Q = s.real
	var yes: bool = s.case == "yes"
	var vt := D(v)
	var right: String = "Yes: n = %s, a whole number." % D(real) if yes else "No: n = %s, which is not a whole number." % D(real)
	var wrongs: Array = []
	if yes:
		wrongs = [["Yes: n = %s, a whole number." % D(real.sub(1)), R_NO_ONE],
			["No: %s is not a multiple of %s, so it can't be a term." % [vt, D(step)], R_MULTIPLE],
			["No: %s is too far from the first term to be a term." % vt, ""]]
	else:
		wrongs = [["Yes: n = %s, which rounds to %d." % [D(real), roundi(real.to_float())], R_ROUND_TERM],
			["Yes: %s is a multiple of %s, so it must be a term." % [vt, D(step)], R_MULTIPLE],
			["No: n = %s, which is not a whole number." % D(real.sub(1)), R_NO_ONE]]
	var made := DerivativeMeaningViews.claim_answer(right, rng.shuffled(wrongs))
	var out := setup(rep, s)
	out.asked = (c.can % vt) + " Justify your answer."
	out.answer = made.answer
	out.wrongs = made.wrongs
	var gap: Q = v.sub(s.u1)
	var r: Dictionary = made.answer.values
	out.methods = {
		"solve-linear": method([read_of(rep, s), "%s + (n − 1) × %s = %s" % [D(s.u1), PD(s.d), vt],
			"n − 1 = (%s − %s) ÷ %s = %s" % [vt, D(s.u1), PD(s.d), D(gap.div(s.d))], "n = %s + 1 = %s" % [D(gap.div(s.d)), D(real)], right], r),
		"count-steps": method([read_of(rep, s), "From %s to %s is a change of %s, which is %s ÷ %s = %s steps." % [D(s.u1), vt, D(gap.abs_q()), D(gap.abs_q()), D(step), D(gap.abs_q().div(step))],
			"Term 1 comes before any step, so add one: n = %s." % D(real), right], r)}
	return out
