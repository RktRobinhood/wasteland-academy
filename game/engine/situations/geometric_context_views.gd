class_name GeometricContextViews
extends ExtensionViews
## The views on the `geometric-context` situation (FAL-752): one builder per unknown of
## t1-geometric-in-context. Most cells are Paper 2, with values to 3 s.f. and the rounding trap, and
## a whole n or year marked exactly. Paper 1 has the bank's frames (areas scaled from the last, and
## their mean as p(b^a − 1)), and exact questions that need no calculator: r from a percentage, the
## indexing of "after t", a rebound and uₙ by tabulating, and an exact-power count of terms.
##
## Representations: "words" (a story), "table" (the first rounds, r read from them), "graph" (dots
## with the target as a line, or the two rivals as curves, labelled at the right-hand end), "diagram"
## (PlotView's `bounce`) and "notation" (u₁ and r, the terms, or a Σ). `given` holds the situation
## as plain strings.

const M := "SL1.3.model#"
const F := "SL1.3.find-n#"
const R_RATE := M + "0"
const R_FACTOR := M + "1"
const R_ONE_FEW := M + "2"
const R_LINEAR := M + "3"
const R_LAST := M + "4"
const R_BEHIND := M + "5"
const R_LENGTH := M + "6"
const R_TOTAL_MEAN := M + "7"
const R_NO_FLIP := F + "0"
const R_ROUND_DOWN := F + "1"
const R_VALUE_AS_N := F + "2"
const R_SHORT := F + "3"
const R_POWER_AS_N := F + "4"
const R_WRONG_TEST := F + "5"
const R_N_FOR_T := F + "6"
const R_T_FOR_N := F + "7"
const R_POWER_N := "SL1.3.nth-term#0"
const R_POWER_ALL := "SL1.3.nth-term#1"
const R_SUM_POWER := "SL1.3.sum#0"
const R_ARITH := "SL1.3.find-r-u1#0"
const R_ROOT := "SL1.3.find-r-u1#2"

const UNKNOWNS := ["factor-from-percent", "value-after-years", "value-in-round", "term-number-after", "rebound-height",
	"nth-expression", "total-over-rounds", "total-two-deals", "overtake-first-round", "scaled-area-term", "mean-of-areas",
	"least-n-term", "least-rounds-after", "least-n-sum", "least-n-two-terms", "first-below", "gap-to-limit", "count-terms-power"]
## Below this an option's value reads as nothing at all.
const TINY := 0.01


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## The bank has one Paper 1 part in six: the rectangles. So they, r, the indexing, working by hand
## (tabulate) and an exact power are Paper 1. A value, a rebound or uₙ by the multiplier makes both
## papers, with small powers on Paper 1. Everything else needs a calculator's powers and is Paper 2.
func papers(unknown: String, _rep: String, method_id: String) -> Array:
	if not has(unknown):
		return []
	if unknown in GeometricContextSituation.P1_ONLY:
		return [1]
	if unknown in ["rebound-height", "nth-expression"]:
		return [1] if method_id == "tabulate" else [1, 2]
	if unknown in ["value-after-years", "value-in-round"]:
		return [1, 2] if method_id == "multiplier" else [2]
	if unknown == "count-terms-power":
		return [1] if method_id == "exact-power" else [2]
	return [2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = GeometricContextSituation.export(s)
	# ln of a big whole number is calculator work, so it isn't another way on Paper 1.
	if s.paper == 1:
		out.methods.erase("logs")
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A GDC's screen: 6 significant figures.
static func W(x: float) -> String:
	return BinomialViews.W(x)


## A total to 2 d.p.: a difference of two then follows from what is written.
static func P2(x: float) -> String:
	return "%.2f" % x


## An exact value on Paper 1 reads as a fraction, and on Paper 2 as a decimal.
static func X(s: Dictionary, v: Variant) -> String:
	return Fmt.num(v) if s.paper == 1 and s.get("frac", true) else Fmt.dec(v)


## The same, ready for a power or a product: "(3/2)", "1.05".
static func B(s: Dictionary, v: Q) -> String:
	var t := X(s, v)
	return "(%s)" % t if t.contains("/") else t


static func sub(k: int) -> String:
	var out := ""
	for ch in str(k):
		out += GeometricSequenceViews.SUBS[ch]
	return out


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func stock(s: Dictionary) -> Dictionary:
	return GeometricContextSituation.STOCKS[s.ctx]


static func flow(s: Dictionary) -> Dictionary:
	return GeometricContextSituation.FLOWS[s.ctx]


static func plural(round_name: String, k: int) -> String:
	return "%d %s" % [k, round_name if k == 1 else round_name + "s"]


## "rises by 6%", "halves"
static func change(s: Dictionary) -> String:
	if s.get("word", "") != "":
		return s.word
	return "%s by %d%%" % ["rises" if s.sign > 0 else "falls", s.p]


static func stock_lines(s: Dictionary) -> Array:
	var c := stock(s)
	return [c.now % D(s.start), "%s %s each %s." % [c.subj, change(s), c.round]]


static func flow_lines(s: Dictionary) -> Array:
	var c := flow(s)
	return [c.first % D(s.u1), "%s %s each %s." % [c.subj, change(s), c.round]]


## "A rise of 6% multiplies by 1 + 0.06 = 1.06 each month."
static func factor_line(s: Dictionary, round_name: String) -> String:
	match s.get("word", ""):
		"doubles":
			return "Doubling multiplies by 2 each %s." % round_name
		"triples":
			return "Tripling multiplies by 3 each %s." % round_name
		"halves":
			return "Halving multiplies by %s each %s." % [X(s, s.r), round_name]
	var part := Q.new(s.p, 100)
	if s.sign > 0:
		return "A rise of %d%% multiplies by 1 + %s = %s each %s." % [s.p, D(part), X(s, s.r), round_name]
	return "A fall of %d%% multiplies by 1 − %s = %s each %s." % [s.p, D(part), X(s, s.r), round_name]


static func ratio_line(s: Dictionary, first: Q, round_name: String) -> String:
	return "Each value is the one before × r: r = %s ÷ %s = %s each %s." % [D(first.mul(s.r)), D(first), X(s, s.r), round_name]


static func listed(first: Q, r: Q, k: int) -> Array:
	var out: Array = []
	var v := first
	for i in k:
		out.append(D(v))
		v = v.mul(r)
	return out


## Time from now in one row, the values in the next.
static func stock_table(s: Dictionary) -> Dictionary:
	var c := stock(s)
	return {"rows": [["%ss from now" % String(c.round).capitalize(), ["0", "1", "2"]], [c.head, listed(s.start, s.r, 3)]]}


static func flow_table(s: Dictionary) -> Dictionary:
	var c := flow(s)
	return {"rows": [[String(c.round).capitalize(), ["1", "2", "3"]], [c.head, listed(s.u1, s.r, 3)]]}


static func stock_shown(rep: String, s: Dictionary) -> Dictionary:
	if rep == "table":
		var c := stock(s)
		return {"lines": ["The table shows the %s. It changes by the same percentage each %s." % [c.thing, c.round]], "table": stock_table(s)}
	return {"lines": stock_lines(s), "table": null}


static func flow_shown(rep: String, s: Dictionary) -> Dictionary:
	if rep == "table":
		var c := flow(s)
		return {"lines": ["The table shows the %s in the first three %ss. It changes by the same percentage each %s." % [c.thing, c.round, c.round]], "table": flow_table(s)}
	return {"lines": flow_lines(s), "table": null}


## A worded value: exact on Paper 1, else 3 s.f. x is a Q on Paper 1 and a float on Paper 2.
static func value_ans(s: Dictionary, x: Variant, unit: String) -> Dictionary:
	if s.paper == 1:
		var ans := Answer.make("number", {"v": x}, {}, "", unit)
		ans.exact = true
		ans.show = "dec"
		return ans
	var out := Answer.make("number", {"v": GdcKit.qf(x)}, {}, "", unit)
	out.show = "sf"
	return out


## A number marked exactly, as a decimal: n, t, a year or r.
static func whole_ans(label: String, k: Variant, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": Q.of(k)}, {}, label, unit)
	ans.show = "dec"
	ans.exact = true
	return ans


## A method's title in the story's own steps: the map's is about percentages and years.
static func titles_for(round_name: String, plain: bool) -> Dictionary:
	var out := {"tabulate": "Build a %s-by-%s table" % [round_name, round_name]}
	if plain:
		out.multiplier = "Find the multiplier r for each %s" % round_name
	return out


static func fv(v: Variant) -> float:
	return v.to_float() if v is Q else float(v)


static func to_3sf(s: Dictionary) -> String:
	return "" if s.paper == 1 else " Give your answer to 3 s.f."


static func wv(x: float) -> Dictionary:
	return {"v": GdcKit.qf(x)}


## Wrong values worth showing, each [value, ref]; a shuffle lets every slip come up.
static func wrongs_of(pairs: Array, rng: Seeded) -> Array:
	var out: Array = []
	for p in rng.shuffled(pairs):
		if p[0] >= TINY:
			out.append(wrong(wv(p[0]), p[1]))
	return out


static func generic_of(x: float) -> Array:
	return [wv(x * 1.1), wv(x * 0.9), wv(x * 1.25), wv(x * 0.8)]


static func whole_wrongs(pairs: Array, rng: Seeded) -> Array:
	var out: Array = []
	for p in rng.shuffled(pairs):
		out.append(wrong({"v": Q.new(p[0])}, p[1]))
	return out


static func near_n(n: int) -> Array:
	return [{"v": Q.new(n + 1)}, {"v": Q.new(n + 2)}, {"v": Q.new(n - 2)}, {"v": Q.new(n + 3)}]


# ── Percentage change ────────────────────────────────────────

func u_factor_from_percent(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := whole_ans("r = ", s.r)
	var rate := Q.new(s.p, 100)
	var wrongs := [wrong({"v": rate}, R_RATE)]
	if s.sign < 0:
		wrongs.append(wrong({"v": Q.new(100 + s.p, 100)}, R_FACTOR))
	var generic := [{"v": Q.new(100 - s.sign * s.p, 100)}, {"v": Q.new(s.p)}, {"v": Q.new(s.p + 1)}, {"v": Q.new(s.p, 10)}]
	var c := stock(s)
	var steps: Array = ["Each %s the %s is %d%% %s %d%% = %d%% of what it was." % [c.round, c.thing, 100, "+" if s.sign > 0 else "−", s.p, 100 + s.sign * s.p],
		"As a decimal, %d%% is %s." % [100 + s.sign * s.p, D(s.r)], say(ans)]
	return {"lines": stock_lines(s), "table": null,
		"asked": "The %s after each %s is r times what it was. Write down the value of r." % [c.thing, c.round],
		"answer": ans, "wrongs": wrongs, "generic": generic, "methods": {"multiplier": method(steps, ans.values)}}


func u_value_after_years(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := stock(s)
	var u: float = s.start.to_float()
	var r: float = s.r.to_float()
	var t: int = s.t
	var rate: float = s.p / 100.0
	var worth := fv(s.v)
	var ans := value_ans(s, s.v, c.unit)
	var pairs: Array = [[u * pow(r, t - 1), R_ONE_FEW], [u * pow(r, t + 1), R_POWER_N], [u * pow(rate, t), R_RATE]]
	if s.sign > 0:
		pairs.append([u * (1.0 + t * rate), R_LINEAR])
	else:
		pairs.append([u * pow(1.0 + rate, t), R_FACTOR])
		pairs.append([u * (1.0 - t * rate), R_FACTOR])
	var out := stock_shown(rep, s)
	var first := ratio_line(s, s.start, c.round) if rep == "table" else factor_line(s, c.round)
	var row: Array = ["Today: %s" % D(s.start)]
	var at := u
	for i in range(1, t + 1):
		at *= r
		row.append("after %s: %s" % [plural(c.round, i), W(at)])
	out.asked = "Find the %s after %s." % [c.thing, plural(c.round, t)] + to_3sf(s)
	out.answer = ans
	out.wrongs = wrongs_of(pairs, rng)
	out.generic = generic_of(worth)
	out.titles = titles_for(c.round, false)
	out.methods = {
		"multiplier": method([first, "After 1 %s it is %s × %s, so after %s it has been multiplied %d times." % [c.round, D(s.start), X(s, s.r), plural(c.round, t), t],
			"%s × %s^%d = %s" % [D(s.start), X(s, s.r), t, W(worth)], say(ans)], ans.values),
		"tabulate": method([first, "Multiply once for each %s. %s" % [c.round, "; ".join(row)], "The row for %s gives %s." % [plural(c.round, t), W(worth)], say(ans)], ans.values)}
	return out


func u_value_in_round(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := flow(s)
	var u: float = s.u1.to_float()
	var r: float = s.r.to_float()
	var n: int = s.n
	var rate: float = s.p / 100.0
	var worth := fv(s.v)
	var ans := value_ans(s, s.v, c.unit)
	var pairs: Array = [[u * pow(r, n), R_POWER_N], [u * pow(rate, n - 1), R_RATE]]
	if s.sign > 0:
		pairs.append([u * (1.0 + (n - 1) * rate), R_LINEAR])
	else:
		pairs.append([u * pow(1.0 + rate, n - 1), R_FACTOR])
		pairs.append([u * (1.0 - (n - 1) * rate), R_FACTOR])
	var out := flow_shown(rep, s)
	var first := ratio_line(s, s.u1, c.round) if rep == "table" else factor_line(s, c.round)
	var row: Array = ["%s 1: %s" % [String(c.round).capitalize(), D(s.u1)]]
	var at := u
	for i in range(2, n + 1):
		at *= r
		row.append("%s %d: %s" % [c.round, i, W(at)])
	out.asked = "Find the %s %s %s %d." % [c.thing, c.at, c.round, n] + to_3sf(s)
	out.answer = ans
	out.wrongs = wrongs_of(pairs, rng)
	out.generic = generic_of(worth)
	out.titles = titles_for(c.round, false)
	out.methods = {
		"multiplier": method([first, "%s %d is %s on from %s 1, so u%s = %s × %s^%d." % [String(c.round).capitalize(), n, plural("step", n - 1), c.round, sub(n), D(s.u1), X(s, s.r), n - 1],
			"%s × %s^%d = %s" % [D(s.u1), X(s, s.r), n - 1, W(worth)], say(ans)], ans.values),
		"tabulate": method([first, "Multiply once for each %s after the first. %s" % [c.round, "; ".join(row)], "The row for %s %d gives %s." % [c.round, n, W(worth)], say(ans)], ans.values)}
	return out


func u_term_number_after(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := stock(s)
	var t: int = s.t
	var ans := whole_ans("n = ", t + 1)
	var out := stock_shown(rep, s)
	if rep == "table":
		var rows: Array = [["Term", ["u₁", "u₂", "u₃"]]]
		rows.append_array(stock_table(s).rows)
		out.table = {"rows": rows}
	out.asked = "Let u₁ be the %s today, u₂ the %s after 1 %s, and so on. Find the value of n for which uₙ is the %s after %s." % [c.thing, c.thing, c.round, c.thing, plural(c.round, t)]
	out.answer = ans
	out.wrongs = whole_wrongs([[t, R_T_FOR_N]], rng)
	out.generic = [{"v": Q.new(t + 2)}, {"v": Q.new(t - 1)}, {"v": Q.new(2 * t)}, {"v": Q.new(t + 3)}]
	out.titles = titles_for(c.round, false)
	out.methods = {"tabulate": method(["List the terms: u₁ is today, u₂ is after 1 %s, and u₃ is after 2 %ss." % [c.round, c.round],
		"The term number is always one more than the number of %ss, so after %s it is %d + 1." % [c.round, plural(c.round, t), t], say(ans)], ans.values)}
	return out


# ── A rebound ────────────────────────────────────────────────

static func rate_text(s: Dictionary) -> String:
	return X(s, s.r) if s.paper == 1 else "%d%%" % roundi(s.r.to_float() * 100.0)


static func ball_figure(s: Dictionary) -> Dictionary:
	var r: float = s.r.to_float()
	var peaks: Array = []
	for i in 7:
		peaks.append(pow(r, i))
	return {"kind": "bounce", "peaks": peaks, "h_label": D(s.h) + s.hu}


func u_rebound_height(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var k: int = s.k
	var h: float = s.h.to_float()
	var r: float = s.r.to_float()
	var one_more: float = h * pow(r, k + 1)
	var one_less: float = h * pow(r, k - 1)
	var steps_down: float = h * (1.0 - k * (1.0 - r))
	var ans := value_ans(s, s.v, s.hu)
	var line := "A %s is dropped from a height of %s%s. Each time it lands it rebounds to %s of the height it fell from." % [GeometricContextSituation.BALLS[s.ctx], D(s.h), s.hu, rate_text(s)]
	var out := {"lines": [line], "table": null, "graph": ball_figure(s) if rep == "diagram" else null}
	out.asked = "Find the height it reaches after the %s bounce." % BinomialViews.ordinal(k) + to_3sf(s)
	out.answer = ans
	if s.paper == 1:
		var wrongs: Array = []
		for p in rng.shuffled([[s.v.div(s.r), R_ONE_FEW], [s.v.mul(s.r), R_POWER_N], [s.h.sub(s.h.sub(s.h.mul(s.r)).mul(k)), R_FACTOR]]):
			if p[0].sign() > 0:
				wrongs.append(wrong({"v": p[0]}, p[1]))
		out.wrongs = wrongs
		out.generic = [{"v": s.h.mul(s.r)}, {"v": s.v.add(s.h)}, {"v": s.h}, {"v": s.v.mul(2)}]
	else:
		out.wrongs = wrongs_of([[one_less, R_ONE_FEW], [one_more, R_POWER_N], [steps_down, R_FACTOR]], rng)
		out.generic = generic_of(s.v)
	var mult := "Each bounce multiplies the height by r = %s." % X(s, s.r)
	var worked := "%s × %s^%d = %s" % [D(s.h), B(s, s.r), k, X(s, s.v) if s.paper == 1 else W(s.v)]
	var row: Array = []
	var at: Q = s.h
	for i in range(1, k + 1):
		at = at.mul(s.r)
		row.append("%s bounce %d: %s" % ["After" if i == 1 else "after", i, D(at)])
	out.titles = titles_for("bounce", true)
	out.methods = {
		"multiplier": method([mult, "After the first bounce it reaches %s × %s, so after the %s it has been multiplied %d times." % [D(s.h), B(s, s.r), BinomialViews.ordinal(k), k], worked, say(ans)], ans.values)}
	# Only Paper 1 tabulates, where each height is exact.
	if s.paper == 1:
		out.methods["tabulate"] = method([mult, "Multiply once for each bounce. %s" % "; ".join(row), say(ans)], ans.values)
	return out


# ── uₙ as an expression ──────────────────────────────────────

static func rule(s: Dictionary, a: Q, b: Q, tail: String) -> String:
	return "%s × %s^%s" % [X(s, a), B(s, b), tail]


func u_nth_expression(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := flow(s)
	var a: Q = s.u1
	var r: Q = s.r
	var parts: Array = ["uₙ = ", {"slot": "a"}, " × ", {"slot": "b"}, "^(n − 1)"]
	var ans := Answer.make("form", {"a": a, "b": r, "text": rule(s, a, r, "(n − 1)")}, {"parts": parts}, "uₙ = ")
	ans.exact = true
	var shape := func(t: String): return {"a": a, "b": r, "text": t, "shape": "other"}
	var step: Q = a.mul(r.sub(1))
	var wrongs: Array = [wrong(shape.call(rule(s, a, r, "n")), R_POWER_N), wrong(shape.call("%s^(n − 1)" % B(s, a.mul(r))), R_POWER_ALL),
		wrong(shape.call("%s %s %s(n − 1)" % [X(s, a), "+" if s.sign > 0 else "−", X(s, step.abs_q())]), R_LINEAR if s.sign > 0 else R_FACTOR)]
	if s.get("word", "") == "":
		wrongs.append(wrong({"a": a, "b": Q.new(s.p, 100), "text": rule(s, a, Q.new(s.p, 100), "(n − 1)")}, R_RATE))
	var out := flow_shown(rep, s)
	if rep == "table":
		out.lines = ["The table shows the %s in the first three %ss. Each value is the same multiple of the one before." % [c.thing, c.round]]
	var ask := "Let uₙ be the %s %s %s n. Find an expression for uₙ in terms of n." % [c.thing, c.at, c.round]
	var generic: Array = [{"a": r, "b": a, "text": rule(s, r, a, "(n − 1)")}, shape.call(rule(s, a, r, "(n + 1)")),
		{"a": a, "b": r.add(1), "text": rule(s, a, r.add(1), "(n − 1)")}, {"a": a.mul(2), "b": r, "text": rule(s, a.mul(2), r, "(n − 1)")}]
	out.asked = ask
	out.answer = ans
	out.wrongs = rng.shuffled(wrongs)
	out.generic = generic
	var first: String
	if rep == "table":
		first = ratio_line(s, a, c.round)
	else:
		first = factor_line(s, c.round)
	var cap := String(c.round).capitalize()
	out.titles = titles_for(c.round, s.get("word", "") != "")
	out.methods = {
		"multiplier": method([first, "uₙ = u₁r^(n − 1), with u₁ = %s and r = %s." % [X(s, a), X(s, r)], say(ans)], ans.values)}
	if s.paper == 1:
		out.methods["tabulate"] = method([first, "%s 1 is %s, %s 2 is %s × %s, and %s 3 is %s × %s^2." % [cap, X(s, a), c.round, X(s, a), B(s, r), c.round, X(s, a), B(s, r)],
			"The power is one less than the %s's number, so in %s n it is n − 1." % [c.round, c.round], say(ans)], ans.values)
	return out


# ── Totals ───────────────────────────────────────────────────

static func sum_line(u: String, r: String, n: int, rising: bool) -> String:
	if rising:
		return "S%s = %s × (%s^%d − 1) ÷ (%s − 1)" % [sub(n), u, r, n, r]
	return "S%s = %s × (1 − %s^%d) ÷ (1 − %s)" % [sub(n), u, r, n, r]


func u_total_over_rounds(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := flow(s)
	var u: float = s.u1.to_float()
	var r: float = s.r.to_float()
	var n: int = s.n
	var rate: float = s.p / 100.0
	var ans := value_ans(s, s.v, c.unit)
	var last := GeometricContextSituation.term(u, r, n)
	var pairs: Array = [[last, R_LAST], [u * (1.0 - pow(r, n - 1)) / (1.0 - r), R_SUM_POWER], [u * (1.0 - pow(rate, n)) / (1.0 - rate), R_RATE]]
	if s.sign > 0:
		pairs.append([n * u + u * rate * n * (n - 1) / 2.0, R_LINEAR])
	else:
		pairs.append([u * (pow(1.0 + rate, n) - 1.0) / rate, R_FACTOR])
	var out := flow_shown(rep, s)
	var first := ratio_line(s, s.u1, c.round) if rep == "table" else factor_line(s, c.round)
	var amounts: Array = []
	for i in range(1, n + 1):
		amounts.append(Fmt.money(Q.new(roundi(GeometricContextSituation.term(u, r, i) * 100.0), 100)))
	out.asked = "Find the %s over the first %s. Give your answer to 3 s.f." % [c.total, plural(c.round, n)]
	out.answer = ans
	out.wrongs = wrongs_of(pairs, rng)
	out.generic = generic_of(s.v)
	out.titles = titles_for(c.round, false)
	out.methods = {
		"multiplier": method([first, "The amounts form a geometric series: u₁ = %s, r = %s and n = %d." % [D(s.u1), X(s, s.r), n],
			"%s = %s" % [sum_line(D(s.u1), X(s, s.r), n, s.sign > 0), W(s.v)], say(ans)], ans.values),
		"tabulate": method([first, "List the amounts, to 2 d.p.: %s" % ", ".join(amounts),
			"Add them: %s ≈ %s" % [" + ".join(amounts), Fmt.money(GdcKit.qf(s.listed))], say(ans)], ans.values)}
	return out


func u_total_two_deals(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c: Dictionary = GeometricContextSituation.DEALS[s.ctx]
	var n: int = s.n
	var u: float = s.u1.to_float()
	var r: float = s.r.to_float()
	var a: float = s.a.to_float()
	var flat := a * n
	var rate: float = s.p / 100.0
	var ans := value_ans(s, s.v, c.unit)
	var out := {"lines": [c.who % n], "table": null}
	if rep == "table":
		out.lines.append("The table shows the first three of each deal's %ss. Deal A's stay the same, and Deal B's rise by the same percentage each %s." % [c.pay, c.round])
		out.table = {"rows": [[String(c.round).capitalize(), ["1", "2", "3"]], ["Deal A (%s)" % c.head, [D(s.a), D(s.a), D(s.a)]], ["Deal B (%s)" % c.head, listed(s.u1, s.r, 3)]]}
	else:
		out.lines.append("Deal A: every %s is %s%s." % [c.pay, D(s.a), c.unit])
		out.lines.append("Deal B: the first %s is %s%s, and each one after it is %d%% more than the one before." % [c.pay, D(s.u1), c.unit, s.p])
	out.asked = "Find the difference between the totals of the two deals. Give your answer to 3 s.f."
	out.answer = ans
	var last := GeometricContextSituation.term(u, r, n)
	var short: float = GeometricContextSituation.sum(u, r, n - 1)
	var low: float = u * (1.0 - pow(rate, n)) / (1.0 - rate)
	out.wrongs = wrongs_of([[absf(last - a), R_LAST], [absf(short - flat), R_SUM_POWER], [absf(low - flat), R_RATE]], rng)
	out.generic = generic_of(s.v)
	var first := "Deal B multiplies by %s each %s, from u₁ = %s, for n = %d." % [X(s, s.r), c.round, D(s.u1), n]
	if rep == "table":
		first = ratio_line(s, s.u1, c.round) + " Deal B has u₁ = %s and n = %d." % [D(s.u1), n]
	var deal_b: float = snappedf(s.total_b, 0.01)
	var totals := "Deal A: %d × %s = %s. Deal B: %s = %s" % [n, D(s.a), P2(flat), sum_line(D(s.u1), X(s, s.r), n, true), P2(deal_b)]
	var gap := "The difference is %s − %s = %s." % [P2(maxf(flat, deal_b)), P2(minf(flat, deal_b)), P2(absf(flat - deal_b))]
	out.methods = {
		"multiplier": method([first, totals, gap, say(ans)], ans.values),
		"gdc-table-compare": method([first, "In the GDC's table enter the running totals: Y1 = %s × X and Y2 = sum(seq(%s × %s^(k − 1), k, 1, X))." % [D(s.a), D(s.u1), X(s, s.r)],
			"At X = %d: Y1 = %s and Y2 = %s." % [n, P2(flat), P2(deal_b)], gap, say(ans)], ans.values)}
	return out


# ── One model overtaking another ─────────────────────────────

static func rival_lines(s: Dictionary) -> Array:
	var c: Dictionary = GeometricContextSituation.RIVALS[s.ctx]
	return ["%s %s %s%s in %s 1, then %s%s more each %s." % [c.a, c.verb, D(s.a), c.unit, c.round, D(s.d), c.unit, c.round],
		"%s %s %s%s in %s 1, then %d%% more each %s than the %s before." % [c.b, c.verb, D(s.b), c.unit, c.round, s.p, c.round, c.round]]


static func rival_graph(s: Dictionary) -> Dictionary:
	var c: Dictionary = GeometricContextSituation.RIVALS[s.ctx]
	var a: float = s.a.to_float()
	var d: float = s.d.to_float()
	var b: float = s.b.to_float()
	var r: float = s.r.to_float()
	var x1: int = s.n + 2
	var f := func(x: float) -> float: return a + (x - 1.0) * d
	var g := func(x: float) -> float: return b * pow(r, x - 1.0)
	var top := Plot.nice_top(maxf(f.call(x1), g.call(x1)))
	var spec := Plot.spec([Plot.sample(f, 1.0, x1), Plot.sample(g, 1.0, x1)],
		[[x1, f.call(x1), c.a], [x1, g.call(x1), c.b]], 0, x1, 0, top)
	spec.x_name = c.round
	spec.y_name = c.head
	return spec


func u_overtake_first_round(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c: Dictionary = GeometricContextSituation.RIVALS[s.ctx]
	var cap := String(c.round).capitalize()
	var n: int = s.n
	var ans := whole_ans(cap + " ", n)
	var a2: Q = s.a.add(s.d)
	var out := {"lines": rival_lines(s), "table": null, "graph": null}
	if rep == "table":
		out.lines = ["The table shows two rivals in the first three %ss. %s goes up by the same amount each %s, and %s by the same percentage." % [c.round, c.a, c.round, c.b]]
		out.table = {"rows": [[cap, ["1", "2", "3"]], ["%s (%s)" % [c.a, c.unit.strip_edges()], [D(s.a), D(a2), D(a2.add(s.d))]], ["%s (%s)" % [c.b, c.unit.strip_edges()], listed(s.b, s.r, 3)]]}
	elif rep == "graph":
		out.lines.append("The graph shows both over the first %s." % plural(c.round, n + 2))
		out.graph = rival_graph(s)
	out.asked = "Find the first %s in which %s %s more than %s." % [c.round, c.b, c.verb, c.a]
	out.answer = ans
	var pairs: Array = [[n - 1, R_BEHIND]]
	if s.slip_n != n and s.slip_n > 0:
		pairs.append([s.slip_n, R_LINEAR])
	out.wrongs = whole_wrongs(pairs, rng)
	out.generic = near_n(n)
	var model := "In %s n, %s has %s + %s(n − 1) and %s has %s × %s^(n − 1)." % [c.round, c.a, D(s.a), D(s.d), c.b, D(s.b), X(s, s.r)]
	out.methods = {
		"gdc-table-compare": method([model, "In the GDC's table enter Y1 = %s + %s(X − 1) and Y2 = %s × %s^(X − 1), and scroll to where Y2 passes Y1." % [D(s.a), D(s.d), D(s.b), X(s, s.r)],
			"X = %d: Y1 = %s and Y2 = %s. X = %d: Y1 = %s and Y2 = %s." % [n - 1, W(s.before_a), W(s.before_b), n, W(s.after_a), W(s.after_b)], say(ans)], ans.values),
		"graph-intersect": method([model, "Graph y = %s + %s(x − 1) and y = %s × %s^(x − 1), and find where they cross for x > 1: x = %s." % [D(s.a), D(s.d), D(s.b), X(s, s.r), W(s.x)],
			"%s is behind until there and ahead after, and a %s is a whole number, so take the next whole number." % [c.b, c.round], say(ans)], ans.values)}
	return out


# ── Rectangles (Paper 1) ─────────────────────────────────────

static func sheet_lines(s: Dictionary) -> Array:
	var c: Dictionary = GeometricContextSituation.SHEETS[s.ctx]
	var first: String = c.L + "₁"
	return [c.maker % [s.parts, first, c.L + sub(s.parts)], "%s is %d cm wide and %d cm tall." % [first, s.w, s.ht],
		"The width and the height of each %s are both %s times those of the %s before." % [c.item, Fmt.num(s.kq), c.item]]


static func sheet_factor(s: Dictionary) -> String:
	return "Each side is multiplied by %s, so each area is multiplied by %s² = %s." % [Fmt.num(s.kq), B(s, s.kq), Fmt.num(s.b2)]


func u_scaled_area_term(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c: Dictionary = GeometricContextSituation.SHEETS[s.ctx]
	var a: Q = s.area
	var b: Q = s.b2
	var label: String = "area of %sₙ = " % c.L
	var parts: Array = [label, {"slot": "a"}, " × ", {"slot": "b"}, "^(n − 1) cm²"]
	var said := func(x: Q, y: Q, tail: String) -> String: return "%s cm²" % rule(s, x, y, tail)
	var ans := Answer.make("form", {"a": a, "b": b, "text": said.call(a, b, "(n − 1)")}, {"parts": parts}, label)
	ans.exact = true
	var shape := func(t: String): return {"a": a, "b": b, "text": t, "shape": "other"}
	var wrongs: Array = [wrong({"a": a, "b": s.kq, "text": said.call(a, s.kq, "(n − 1)")}, R_LENGTH), wrong(shape.call(said.call(a, b, "n")), R_POWER_N),
		wrong(shape.call("%s^(n − 1) cm²" % B(s, a.mul(b))), R_POWER_ALL)]
	var out := {"lines": sheet_lines(s), "table": null, "asked": "Find an expression for the area of %sₙ in terms of n." % c.L, "answer": ans,
		"wrongs": rng.shuffled(wrongs),
		"generic": [{"a": a, "b": s.kq.mul(2), "text": said.call(a, s.kq.mul(2), "(n − 1)")}, {"a": b, "b": a, "text": said.call(b, a, "(n − 1)")},
			shape.call(said.call(a, b, "(n + 1)")), {"a": a.mul(2), "b": b, "text": said.call(a.mul(2), b, "(n − 1)")}]}
	out.titles = titles_for(c.item, true)
	out.methods = {"multiplier": method([sheet_factor(s), "%s₁ has area %d × %d = %s cm²." % [c.L, s.w, s.ht, X(s, a)],
		"So the areas are geometric, with u₁ = %s and r = %s, and uₙ = u₁r^(n − 1)." % [X(s, a), Fmt.num(b)], say(ans)], ans.values)}
	return out


static func mean_text(s: Dictionary, p: Q, a: int) -> String:
	return "%s × (%s^%d − 1) cm²" % [B(s, p), B(s, s.b2), a]


func u_mean_of_areas(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c: Dictionary = GeometricContextSituation.SHEETS[s.ctx]
	var parts_n: int = s.parts
	var p: Q = s.p_q
	var total: Q = p.mul(parts_n)
	var b: Q = s.b2
	var a: Q = s.area
	var parts: Array = ["mean = ", {"slot": "p"}, " × (%s^" % B(s, b), {"slot": "a"}, " − 1) cm²"]
	var ans := Answer.make("form", {"p": p, "a": Q.new(parts_n), "text": mean_text(s, p, parts_n)}, {"parts": parts}, "mean = ")
	ans.exact = true
	var v := func(x: Q, y: int) -> Dictionary: return {"p": x, "a": Q.new(y), "text": mean_text(s, x, y)}
	var wrongs: Array = [wrong(v.call(total, parts_n), R_TOTAL_MEAN), wrong(v.call(p, parts_n - 1), R_SUM_POWER)]
	var generic: Array = [v.call(a.div(parts_n), parts_n), v.call(p, parts_n + 1), v.call(a.div(b).div(parts_n), parts_n), v.call(p.mul(2), parts_n)]
	var out := {"lines": sheet_lines(s), "table": null, "asked": "Find the mean area of the %d %s, in the form p × (%s^a − 1) cm², where a is a whole number." % [parts_n, c.items, B(s, b)],
		"answer": ans, "wrongs": rng.shuffled(wrongs), "generic": generic}
	out.titles = titles_for(c.item, true)
	out.methods = {"multiplier": method([sheet_factor(s) + " The first area is %d × %d = %s cm²." % [s.w, s.ht, X(s, a)],
		"S%s = %s × (%s^%d − 1) ÷ (%s − 1) = %s × (%s^%d − 1)" % [sub(parts_n), X(s, a), B(s, b), parts_n, B(s, b), B(s, total), B(s, b), parts_n],
		"The mean is S%s ÷ %d: %s ÷ %d = %s." % [sub(parts_n), parts_n, X(s, total), parts_n, X(s, p)], say(ans)], ans.values)}
	return out


# ── Find n ───────────────────────────────────────────────────

## The dots of a term or a running total: the first three labelled, for reading u₁ and r.
static func dots(s: Dictionary, totals: bool) -> Dictionary:
	var u: float = s.u1.to_float()
	var r: float = s.r.to_float()
	var last: int = s.n + 1
	var pts: Array = []
	var top := 0.0
	for i in range(1, last + 1):
		var y: float = GeometricContextSituation.sum(u, r, i) if totals else GeometricContextSituation.term(u, r, i)
		pts.append([i, y, D(_exact(s, i, totals)) if i <= 3 else ""])
		top = maxf(top, y)
	top = maxf(top, s.target.to_float())
	var spec := Plot.spec([], pts, 0, last + 1, 0, Plot.nice_top(top), [[s.target.to_float(), "y = %s" % D(s.target)]])
	spec.x_name = "n"
	spec.y_name = "Sₙ" if totals else "uₙ"
	return spec


static func _exact(s: Dictionary, i: int, totals: bool) -> Q:
	if not totals:
		return s.u1.mul(GeometricSequenceSituation.power(s.r, i - 1))
	var total := Q.new(0)
	for k in range(1, i + 1):
		total = total.add(_exact(s, k, false))
	return total


## What the student sees of a sequence: its rule, or a story, or the first values.
static func seq_shown(rep: String, s: Dictionary, totals: bool) -> Dictionary:
	var c := flow(s)
	var said: String = ("Let Sₙ be the %s of the first %s." % [c.total, "n %ss" % c.round]) if totals else ("Let uₙ be the %s %s %s n." % [c.thing, c.at, c.round])
	match rep:
		"notation":
			var line: String = "A geometric sequence has u₁ = %s and r = %s." % [D(s.u1), D(s.r)]
			return {"lines": [line, "Sₙ is the sum of its first n terms."] if totals else [line], "table": null, "graph": null}
		"table":
			var t := flow_shown(rep, s)
			t.lines.append(said)
			t.graph = null
			return t
		"graph":
			var word: String = "running total Sₙ, the %s of the first n %ss" % [c.total, c.round] if totals else "%s uₙ %s %s n" % [c.thing, c.at, c.round]
			return {"lines": ["The dots show the %s. The %s changes by the same percentage each %s, and the line is the target." % [word, c.thing, c.round]],
				"table": null, "graph": dots(s, totals)}
	var words := flow_shown(rep, s)
	words.lines.append(said)
	words.graph = null
	return words


## How u₁ and r are read: the first step of working on any representation.
static func read_line(rep: String, s: Dictionary, totals: bool, tail: String) -> String:
	var r_text: String = D(s.r)
	match rep:
		"table":
			return "u₁ = %s and r = %s ÷ %s = %s, so %s." % [D(s.u1), D(s.u1.mul(s.r)), D(s.u1), r_text, tail]
		"graph":
			if totals:
				var u2: Q = s.u1.mul(s.r)
				return "S₁ = u₁ = %s, u₂ = S₂ − S₁ = %s and r = %s ÷ %s = %s, so %s." % [D(s.u1), D(u2), D(u2), D(s.u1), r_text, tail]
			return "u₁ = %s and r = %s ÷ %s = %s, so %s." % [D(s.u1), D(s.u1.mul(s.r)), D(s.u1), r_text, tail]
	return "u₁ = %s and r = %s, so %s." % [D(s.u1), r_text, tail]


## The three working routes of a find-n question. v: the letter; expr: the model in X, for the GDC;
## sol: the logs steps, the first of which reads the model; test: the words for the table.
func routes(s: Dictionary, ans: Dictionary, first: String, v: String, expr: String, sol: Array, what: String) -> Dictionary:
	var target: String = D(s.target)
	var n: int = s.n
	var e_x: String = expr.replace("X", "x")
	var round_up := "The curve meets the line at x = %s, and %s must be whole, so take the next whole number." % [W(s.x), v]
	var logs: Array = [first]
	logs.append_array(sol)
	logs.append(say(ans))
	return {
		"logs": method(logs, ans.values),
		"gdc-table": method([first, "In the GDC's table enter Y1 = %s and scroll to where %s." % [expr, what], "X = %d gives %s, and X = %d gives %s." % [n - 1, W(s.before), n, W(s.after)], say(ans)], ans.values),
		"graph-intersect": method([first, "Graph y = %s and y = %s, and find where they meet: x = %s." % [e_x, target, W(s.x)], round_up, say(ans)], ans.values)}


## The slip of stopping one short: what it is depends on the working asked for.
func short_ref(rising: bool) -> String:
	match angle:
		"logs":
			return R_ROUND_DOWN if rising else R_NO_FLIP
		"gdc-table":
			return R_SHORT
	return R_ROUND_DOWN


func u_least_n_term(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var ans := whole_ans("n = ", n)
	var q: float = s.target.to_float() / s.u1.to_float()
	var out := seq_shown(rep, s, false)
	var u := "%s × %s^(n − 1)" % [D(s.u1), D(s.r)]
	out.asked = "Find the least value of n for which uₙ > %s." % D(s.target)
	out.answer = ans
	var pairs: Array = [[n - 1, short_ref(true)]]
	if s.other_n > 0 and s.other_n != n:
		pairs.append([s.other_n, R_WRONG_TEST])
	out.wrongs = whole_wrongs(pairs, rng)
	out.wrongs.append(wrong({"v": GeometricContextSituation.fig(s.after, 3)}, R_VALUE_AS_N))
	out.generic = near_n(n)
	out.methods = routes(s, ans, read_line(rep, s, false, "uₙ = " + u), "n", "%s × %s^(X − 1)" % [D(s.u1), D(s.r)],
		["Solve %s > %s: %s^(n − 1) > %s" % [u, D(s.target), D(s.r), W(q)],
		"Take ln of both sides: (n − 1) ln %s > ln %s, so n − 1 > %s" % [D(s.r), W(q), W(s.x - 1.0)],
		"So n > %s, and n is whole, so take the next whole number." % W(s.x)], "it passes %s" % D(s.target))
	return out


func u_first_below(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var ans := whole_ans("n = ", n)
	var q: float = s.target.to_float() / s.u1.to_float()
	var out := seq_shown(rep, s, false)
	var u := "%s × %s^(n − 1)" % [D(s.u1), D(s.r)]
	out.asked = "Find the least value of n for which uₙ < %s." % D(s.target)
	out.answer = ans
	out.wrongs = whole_wrongs([[n - 1, short_ref(false)]], rng)
	out.wrongs.append(wrong({"v": GeometricContextSituation.fig(s.after, 3)}, R_VALUE_AS_N))
	out.generic = near_n(n)
	out.methods = routes(s, ans, read_line(rep, s, false, "uₙ = " + u), "n", "%s × %s^(X − 1)" % [D(s.u1), D(s.r)],
		["Solve %s < %s: %s^(n − 1) < %s" % [u, D(s.target), D(s.r), W(q)],
		"Take ln of both sides: (n − 1) ln %s < ln %s. ln %s is negative, so dividing by it flips the sign: n − 1 > %s" % [D(s.r), W(q), D(s.r), W(s.x - 1.0)],
		"So n > %s, and n is whole, so take the next whole number." % W(s.x)], "it drops below %s" % D(s.target))
	return out


func u_least_rounds_after(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := stock(s)
	var rising: bool = s.sign > 0
	var n: int = s.n
	var ans := whole_ans("t = ", n)
	var q: float = s.target.to_float() / s.start.to_float()
	var word := "more" if rising else "less"
	var rel := ">" if rising else "<"
	var out := stock_shown(rep, s)
	var u := "%s × %s^t" % [D(s.start), D(s.r)]
	out.asked = "Find the least whole number of %ss t after which the %s is %s than %s%s." % [c.round, c.thing, word, D(s.target), c.unit]
	out.answer = ans
	out.wrongs = whole_wrongs([[n + 1, R_N_FOR_T], [n - 1, short_ref(rising)]], rng)
	out.wrongs.append(wrong({"v": GeometricContextSituation.fig(s.after, 3)}, R_VALUE_AS_N))
	out.generic = near_n(n)
	var first := "After t %ss the %s is %s, with r = %s." % [c.round, c.thing, u, D(s.r)]
	if rep == "table":
		first = "r = %s ÷ %s = %s, and after t %ss the %s is %s." % [D(s.start.mul(s.r)), D(s.start), D(s.r), c.round, c.thing, u]
	var take := "Take ln of both sides: t ln %s %s ln %s, so t %s %s" % [D(s.r), rel, W(q), rel, W(s.x)]
	if not rising:
		take = "Take ln of both sides: t ln %s < ln %s. ln %s is negative, so dividing by it flips the sign: t > %s" % [D(s.r), W(q), D(s.r), W(s.x)]
	out.methods = routes(s, ans, first, "t", "%s × %s^X" % [D(s.start), D(s.r)],
		["Solve %s %s %s: %s^t %s %s" % [u, rel, D(s.target), D(s.r), rel, W(q)], take,
		"t is whole, so take the next whole number above %s." % W(s.x)], "it %s %s" % ["passes" if rising else "drops below", D(s.target)])
	return out


## The logs steps for Sₙ > T when r > 1.
static func sum_steps(s: Dictionary, shown_sum: String) -> Array:
	var r: float = s.r.to_float()
	var q: float = 1.0 + s.target.to_float() * (r - 1.0) / s.u1.to_float()
	var minus := D(s.r.sub(1))
	return ["Solve %s > %s: %s^n − 1 > %s × %s ÷ %s, so %s^n > %s" % [shown_sum, D(s.target), D(s.r), D(s.target), minus, D(s.u1), D(s.r), W(q)],
		"Take ln of both sides: n ln %s > ln %s, so n > %s" % [D(s.r), W(q), W(s.x)],
		"n is whole, so take the next whole number above %s." % W(s.x)]


func u_least_n_sum(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var ans := whole_ans("n = ", n)
	var out := seq_shown(rep, s, true)
	var minus := D(s.r.sub(1))
	var shown_sum := "%s × (%s^n − 1) ÷ %s" % [D(s.u1), D(s.r), minus]
	out.asked = "Find the least value of n for which Sₙ > %s." % D(s.target)
	out.answer = ans
	out.wrongs = whole_wrongs([[n - 1, short_ref(true)], [s.other_n, R_WRONG_TEST]], rng)
	out.wrongs.append(wrong({"v": GeometricContextSituation.fig(s.after, 3)}, R_VALUE_AS_N))
	out.generic = near_n(n)
	out.methods = routes(s, ans, read_line(rep, s, true, "Sₙ = " + shown_sum), "n", "%s × (%s^X − 1) ÷ %s" % [D(s.u1), D(s.r), minus],
		sum_steps(s, shown_sum), "it passes %s" % D(s.target))
	return out


func u_least_n_two_terms(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := flow(s)
	var n: int = s.n
	var m: int = s.m
	var ans := whole_ans("n = ", n)
	var out := {"lines": [], "table": null}
	if rep == "words":
		out.lines = [c.first % D(s.u1), "The %s %s %s %d is %s%s, and the %s forms a geometric sequence in which each term is more than the last." % [c.thing, c.at, c.round, m, D(s.um), c.unit, c.thing],
			"Let Sₙ be the %s of the first %s." % [c.total, "n %ss" % c.round]]
	else:
		out.lines = ["A geometric sequence of positive terms has u₁ = %s and u%s = %s." % [D(s.u1), sub(m), D(s.um)], "Sₙ is the sum of its first n terms."]
	var minus := D(s.r.sub(1))
	var shown_sum := "%s × (%s^n − 1) ÷ %s" % [D(s.u1), D(s.r), minus]
	out.asked = "Find the least value of n for which Sₙ > %s." % D(s.target)
	out.answer = ans
	var pairs: Array = [[n - 1, short_ref(true)]]
	if s.wrong_r > 0 and s.wrong_r != n:
		pairs.append([s.wrong_r, R_ROOT])
	if s.arith_n > 0 and s.arith_n != n:
		pairs.append([s.arith_n, R_ARITH])
	out.wrongs = whole_wrongs(pairs, rng)
	out.generic = near_n(n)
	var first := "u%s = u₁r^%d, so r^%d = %s ÷ %s = %s and r = %s. So Sₙ = %s." % [sub(m), m - 1, m - 1, D(s.um), D(s.u1), D(s.r_q), D(s.r), shown_sum]
	out.methods = routes(s, ans, first, "n", "%s × (%s^X − 1) ÷ %s" % [D(s.u1), D(s.r), minus],
		sum_steps(s, shown_sum), "it passes %s" % D(s.target))
	return out


func u_gap_to_limit(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var ans := whole_ans("n = ", n)
	var out := {"lines": [], "table": null}
	if rep == "notation":
		out.lines = ["The sum of the first n terms of a geometric sequence is Sₙ = Σ (k = 1 to n) %s(%s)^k." % [D(s.c), D(s.r)]]
	else:
		var c := flow(s)
		out.lines = flow_lines(s)
		out.lines.append("Let Sₙ be the %s of the first %s, and S∞ the amount it settles towards." % [c.total, "n %ss" % c.round])
	var f: Q = s.sinf
	var q: float = s.target.to_float() / f.to_float()
	var rest := Q.new(1).sub(s.r)
	var gap := "%s × %s^n" % [D(f), D(s.r)]
	out.asked = "Find the least value of n for which S∞ − Sₙ < %s." % D(s.target)
	out.answer = ans
	out.wrongs = whole_wrongs([[n - 1, short_ref(false)], [s.other_n, R_WRONG_TEST]], rng)
	out.wrongs.append(wrong({"v": GeometricContextSituation.fig(f.to_float() - s.after, 3)}, R_VALUE_AS_N))
	out.generic = near_n(n)
	var u_text := "u₁ = %s and r = %s" % [D(s.u1), D(s.r)]
	if rep == "notation":
		u_text = "Put k = 1: u₁ = %s × %s = %s, and r = %s" % [D(s.c), D(s.r), D(s.u1), D(s.r)]
	var first := "%s, so S∞ = %s ÷ %s = %s." % [u_text, D(s.u1), D(rest), D(f)]
	out.methods = routes(s, ans, first, "n", "%s × %s^X" % [D(f), D(s.r)],
		["S∞ − Sₙ = u₁r^n ÷ (1 − r) = %s. Solve %s < %s: %s^n < %s" % [gap, gap, D(s.target), D(s.r), W(q)],
		"Take ln of both sides: n ln %s < ln %s. ln %s is negative, so dividing by it flips the sign: n > %s" % [D(s.r), W(q), D(s.r), W(s.x)],
		"n is whole, so take the next whole number above %s." % W(s.x)], "it drops below %s" % D(s.target))
	out.titles = {"gdc-table": "Scroll a GDC table of S∞ − Sₙ"}
	return out


func u_count_terms_power(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = GeometricContextSituation.SPREADS[s.ctx]
	var n: int = s.n
	var r: int = int(s.r.to_float())
	var u: String = D(s.u1)
	var last: String = D(s.last)
	var q: String = D(s.total)
	var ans := whole_ans("", n, " " + c.unit) if rep == "words" else whole_ans("n = ", n)
	var u3: Q = s.u1.mul(s.r).mul(s.r)
	var out := {"lines": [], "table": null}
	match rep:
		"words":
			out.lines = [c.open % u, c.next % r, c.end % last]
			out.asked = String(c.ask)
		"notation":
			out.lines = ["The numbers %s, %s, %s, …, %s form a finite geometric sequence." % [u, D(s.u1.mul(s.r)), D(u3), last]]
			out.asked = "How many terms does the sequence have?"
		_:
			out.lines = ["The table shows the start of a finite geometric sequence, and its last term."]
			out.table = {"rows": [["n", ["1", "2", "3", "…", "?"]], ["uₙ", [u, D(s.u1.mul(s.r)), D(u3), "…", last]]]}
			out.asked = "How many terms does the sequence have?"
	out.answer = ans
	var d: Q = s.u1.mul(s.r.sub(1))
	var arith: Q = s.last.sub(s.u1).div(d).add(1)
	out.wrongs = [wrong({"v": Q.new(n - 1)}, R_POWER_AS_N), wrong({"v": arith}, R_ARITH)]
	out.generic = [{"v": Q.new(n + 1)}, {"v": s.total}, {"v": Q.new(n + 2)}, {"v": Q.new(n - 2)}]
	var first := "u₁ = %s and r = %d, so with n %s the last term is %s × %d^(n − 1)." % [u, r, c.unit if rep == "words" else "terms", u, r]
	var solve := "Set %s × %d^(n − 1) = %s: %d^(n − 1) = %s ÷ %s = %s" % [u, r, last, r, last, u, q]
	var powers: Array = []
	for i in range(1, n):
		powers.append(D(GeometricSequenceSituation.power(s.r, i)))
	var powers_of := "Powers of %d: %s. So %s = %d^%d, and n − 1 = %d." % [r, ", ".join(powers), q, r, n - 1, n - 1]
	out.methods = {"exact-power": method([first, solve, powers_of, say(ans)], ans.values),
		"logs": method([first, solve, "Take ln of both sides: (n − 1) ln %d = ln %s, so n − 1 = %d." % [r, q, n - 1], say(ans)], ans.values),
		"gdc-table": method([first, "In the GDC's table enter Y1 = %s × %d^(X − 1) and scroll to where it reaches %s." % [u, r, last], "X = %d gives %s." % [n, last], say(ans)], ans.values)}
	return out
