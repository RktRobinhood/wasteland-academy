class_name DepreciationViews
extends ExtensionViews
## The views on the `depreciation` situation: one builder per unknown of t1-depreciation. Every
## question is Paper 2 (every bank part is) and works with the multiplier, the GDC's TVM solver
## with a negative rate, a year-by-year run, logs, a GDC table or a graph. Money is answered
## exactly to the dollar, a rate found to 3 s.f. with the rounding trap, and a time as a whole number.
##
## Representations: "words" (a story), "equation" (V = P(c)^t), "table" (the value at whole years,
## or a rate per stage) and "graph" (the curve and the target, with the crossing marked).
## `given` holds what the student is shown.

const DEP := "SL1.4.depreciation#"
const TIME := "SL1.4.find-time#"
const R_ONE_PLUS := DEP + "0"
const R_STRAIGHT := DEP + "1"
const R_REMAINING := DEP + "2"
const R_SO_FAR := DEP + "3"
const R_END_OF_YEAR := DEP + "4"
const R_ADD_BACK := DEP + "5"
const R_KEPT := DEP + "6"
const R_WHOLE_FALL := DEP + "7"
const R_LATER_RATE := DEP + "8"
const R_DATES := DEP + "9"
const R_ROUND_NEAREST := TIME + "0"
const R_NO_CONVERT := TIME + "1"
const R_NO_FLIP := TIME + "2"

const WHO := ["Kira", "Tomas", "The Guild", "A trader", "Ines", "The caravan fund"]
const ITEMS := ["water truck", "solar rig", "salvage crane", "wind pump", "fuel tanker", "generator", "drill rig", "cargo wagon"]
const UNIT := {1: "year", 4: "quarter", 12: "month"}
const LETTER := {1: "t", 4: "q", 12: "m"}
const UNKNOWNS := ["value-after", "total-loss", "loss-in-year", "original-value", "find-rate", "read-rate", "two-rate-value", "shortfall",
	"years-below", "years-fraction", "years-from-periods", "least-periods"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.wrongs = rng.shuffled(out.wrongs)
	out.given = DepreciationSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## $5000
static func M(v: Variant) -> String:
	return "$" + Fmt.money(v)


## Money in the working, to the cent.
static func C(x: float) -> String:
	return "%.2f" % x


## a − b as the working shows it, from the figures shown.
static func gap(a: float, b: float) -> String:
	return "%.2f" % ((roundi(a * 100.0) - roundi(b * 100.0)) / 100.0)


static func who(s: Dictionary) -> String:
	return WHO[s.ctx]


static func item(s: Dictionary) -> String:
	return ITEMS[s.item]


static func unit(s: Dictionary) -> String:
	return UNIT[s.k]


static func letter(s: Dictionary) -> String:
	return LETTER[s.k]


static func model(s: Dictionary) -> String:
	return "V = %s(%s)^%s" % [D(s.p), D(s.c), letter(s)]


static func V(s: Dictionary, n: int) -> float:
	return DepreciationSituation.value(s.p.to_float(), s.c.to_float(), n)


## A whole-dollar answer, exact.
static func dollars(label: String, x: float) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.new(roundi(x))}, {}, label)
	ans.show = "money"
	ans.exact = true
	return ans


static func count(label: String, n: int) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.new(n)}, {}, label)
	ans.show = "dec"
	ans.exact = true
	return ans


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func ms(xs: Array) -> Array:
	return xs.filter(func(x): return x >= 1.0 and is_finite(x)).map(func(x): return {"v": Q.new(roundi(x))})


static func money_wrong(x: float, ref: String) -> Dictionary:
	return wrong({"v": Q.new(roundi(x))}, ref)


## The value at t = from, from + 1 and from + 2, exact, as a table. A price of a multiple of 1000
## with a whole rate, or of 10000 with a rate in tenths, is exact to the cent here.
static func value_table(s: Dictionary, from: int, first: Q) -> Dictionary:
	var name := "%s (%ss)" % [letter(s), unit(s)]
	var ts: Array = []
	var vs: Array = []
	var v := first
	for i in 3:
		ts.append(str(from + i))
		vs.append(Fmt.money(v))
		v = v.mul(s.c)
	return {"rows": [[name, ts], ["V ($)", vs]]}


## What the student is shown when the price and the rate are known.
static func story(rep: String, s: Dictionary) -> Dictionary:
	match rep:
		"equation":
			return {"lines": ["%s buys a %s. Its value in dollars, %s %ss after it is bought, is %s." % [who(s), item(s), letter(s), unit(s), model(s)]], "table": null}
		"table":
			return {"lines": ["%s buys a %s, and its value falls by the same percentage each %s. The table shows its value, %s %ss after it is bought." % [who(s), item(s), unit(s), letter(s), unit(s)]],
				"table": value_table(s, 0, s.p)}
		"graph":
			return {"lines": ["%s buys a %s. The graph shows its value V dollars, t years after it is bought, where %s, and the line V = %s." % [who(s), item(s), model(s), D(s.target)]],
				"table": null, "graph": figure(s)}
	return {"lines": ["%s buys a %s for %s. Its value falls by %s%% each %s." % [who(s), item(s), M(s.p), D(s.r), unit(s)]], "table": null}


## The curve, the target and the crossing marked, as a GDC's intersect shows it.
static func figure(s: Dictionary) -> Dictionary:
	var c: float = s.c.to_float()
	var p: float = s.p.to_float()
	var t: float = s.target.to_float()
	var hi: int = s.least + 2
	var f := func(x: float) -> float: return DepreciationSituation.value(p, c, x)
	return Plot.spec([Plot.sample(f, 0.0, float(hi))], [[s.x, t, "(%s, %s)" % [Fmt.sf(s.x), D(s.target)]]], 0, hi, 0, ceili(p * 1.1 / 5000.0) * 5000,
		[[t, "V = %s" % D(s.target)]]).merged({"x_name": "t", "y_name": "V"})


## How the working gets the multiplier from what is shown.
static func keep_line(rep: String, s: Dictionary) -> String:
	match rep:
		"equation":
			return "The base of the power is the multiplier: %s each %s." % [D(s.c), unit(s)]
		"table":
			return "Each value ÷ the one before: %s ÷ %s = %s, so the multiplier is %s." % [Fmt.money(s.p.mul(s.c)), D(s.p), D(s.c), D(s.c)]
	return "A fall of %s%% keeps %s%%, so the multiplier is %s." % [D(s.r), D(Q.new(100).sub(s.r)), D(s.c)]


## How the working gets the rate from what is shown, for the TVM solver. Nothing in a story.
static func rate_lines(rep: String, s: Dictionary) -> Array:
	match rep:
		"words":
			return []
		"table":
			return ["Each value ÷ the one before: %s ÷ %s = %s, so the rate is 100(1 − %s) = %s%%." % [Fmt.money(s.p.mul(s.c)), D(s.p), D(s.c), D(s.c), D(s.r)]]
		"graph", "equation":
			return ["The multiplier is %s, so the rate is 100(1 − %s) = %s%%." % [D(s.c), D(s.c), D(s.r)]]
	return []


## The TVM line, with every entry but the one solved for.
static func tvm_line(entries: Array) -> String:
	return "Open the TVM solver: %s, PMT = 0, P/Y = 1, C/Y = 1." % ", ".join(entries)


## A year-by-year run from a start, multiplied (or divided) by c once a year, 5 years a line.
static func run(start: float, c: float, from: int, to: int) -> Array:
	var cells: Array = []
	var v := start
	for t in range(from + 1, to + 1):
		v *= c
		cells.append("year %d: %s" % [t, C(v)])
	var lines: Array = []
	var i := 0
	while i < cells.size():
		var bit := ", ".join(cells.slice(i, i + 5))
		lines.append(bit.substr(0, 1).to_upper() + bit.substr(1) + ".")
		i += 5
	return lines


# ── A value, and what it lost ────────────────────────────────

## The steps to V(n), by each method, before what the question does with it.
func _to_value(rep: String, s: Dictionary, n: int) -> Dictionary:
	var v := V(s, n)
	var a := [keep_line(rep, s), "V = %s × %s^%d = %s" % [D(s.p), D(s.c), n, C(v)]]
	var b: Array = rate_lines(rep, s)
	b.append(tvm_line(["N = %d" % n, "I%% = −%s" % D(s.r), "PV = −%s" % D(s.p)]))
	b.append("Solve for FV: FV = %s" % C(v))
	var c := [keep_line(rep, s)]
	c.append_array(run(s.p.to_float(), s.c.to_float(), 0, n))
	return {"decay-multiplier": a, "tvm-negative": b, "year-by-year": c}


func _methods(steps: Dictionary, tail: Array, ans: Dictionary) -> Dictionary:
	var out := {}
	for id in steps:
		var all: Array = steps[id].duplicate()
		all.append_array(tail)
		all.append(final_step(ans))
		out[id] = method(all, ans.values)
	return out


func u_value_after(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: float = s.p.to_float()
	var r: float = s.r.to_float()
	var v := V(s, s.n)
	var ans := dollars("value = $", v)
	var out := story(rep, s)
	out.asked = "Find its value after %d years, to the nearest dollar." % s.n
	if rep == "equation":
		out.lines = ["%s buys a %s on 1 January %d. Its value in dollars, t years after that date, is %s." % [who(s), item(s), s.date, model(s)]]
		out.asked = "Find its value on 1 January %d, to the nearest dollar." % (s.date + s.n)
	out.answer = ans
	out.wrongs = [money_wrong(DepreciationSituation.value(p, 1.0 + r / 100.0, s.n), R_ONE_PLUS),
		money_wrong(p * (1.0 - s.n * r / 100.0), R_STRAIGHT), money_wrong(p - v, R_REMAINING)]
	out.generic = ms([V(s, s.n - 1), V(s, s.n + 1), v * 1.05])
	out.methods = _methods(_to_value(rep, s, s.n), [], ans)
	return out


func u_total_loss(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: float = s.p.to_float()
	var r: float = s.r.to_float()
	var v := V(s, s.n)
	var ans := dollars("loss = $", p - v)
	var out := story(rep, s)
	out.asked = "Find the total loss in its value over the first %d years, to the nearest dollar." % s.n
	out.answer = ans
	out.wrongs = [money_wrong(v, R_REMAINING), money_wrong(p * s.n * r / 100.0, R_STRAIGHT),
		money_wrong(DepreciationSituation.value(p, 1.0 + r / 100.0, s.n) - p, R_ONE_PLUS)]
	out.generic = ms([p - V(s, s.n - 1), p - V(s, s.n + 1), (p - v) * 1.1])
	out.methods = _methods(_to_value(rep, s, s.n), ["Loss = %s − %s = %s" % [D(s.p), C(v), gap(p, v)]], ans)
	return out


func u_loss_in_year(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: float = s.p.to_float()
	var r: float = s.r.to_float()
	var a := V(s, s.n - 1)
	var b := V(s, s.n)
	var ans := dollars("loss = $", a - b)
	var out := story(rep, s)
	out.asked = "Find the loss in its value during year %d alone, between %d and %d years after it is bought, to the nearest dollar." % [s.n, s.n - 1, s.n]
	out.answer = ans
	out.wrongs = [money_wrong(p - b, R_SO_FAR), money_wrong(b * r / 100.0, R_END_OF_YEAR), money_wrong(p * r / 100.0, R_STRAIGHT), money_wrong(b, R_REMAINING)]
	out.generic = ms([(a - b) * 1.1, (a - b) * 0.9])
	var tail := ["Loss in year %d = %s − %s = %s" % [s.n, C(a), C(b), gap(a, b)]]
	var mult := [keep_line(rep, s), "After %d years V = %s × %s^%d = %s, and after %d years V = %s × %s^%d = %s" % [s.n - 1, D(s.p), D(s.c), s.n - 1, C(a), s.n, D(s.p), D(s.c), s.n, C(b)]]
	var tvm: Array = rate_lines(rep, s)
	tvm.append(tvm_line(["I%% = −%s" % D(s.r), "PV = −%s" % D(s.p)]))
	tvm.append("Solve for FV with N = %d and with N = %d: FV = %s and FV = %s" % [s.n - 1, s.n, C(a), C(b)])
	var yearly := [keep_line(rep, s)]
	yearly.append_array(run(p, s.c.to_float(), 0, s.n))
	out.methods = _methods({"decay-multiplier": mult, "tvm-negative": tvm, "year-by-year": yearly}, tail, ans)
	return out


# ── The price, and the rate ──────────────────────────────────

func u_original_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: float = s.r.to_float()
	var c: float = s.c.to_float()
	var v: float = s.v.to_float()
	var p := v / pow(c, s.n)
	var ans := dollars("price = $", p)
	var out := {"table": null}
	var keep := "A fall of %s%% keeps %s%%, so the multiplier is %s." % [D(s.r), D(Q.new(100).sub(s.r)), D(s.c)]
	var rate: Array = []
	match rep:
		"equation":
			out.lines = ["%s owns a %s. Its value in dollars, t years after it was bought, is V = P(%s)^t, and V = %s when t = %d." % [who(s), item(s), D(s.c), D(s.v), s.n]]
			keep = "The base of the power is the multiplier: %s each year." % D(s.c)
			rate = ["The multiplier is %s, so the rate is 100(1 − %s) = %s%%." % [D(s.c), D(s.c), D(s.r)]]
		"table":
			out.lines = ["%s owns a %s, and its value falls by the same percentage each year. The table shows its value, t years after it was bought." % [who(s), item(s)]]
			out.table = value_table(s, s.n, s.v)
			keep = "Each value ÷ the one before: %s ÷ %s = %s, so the multiplier is %s." % [Fmt.money(s.v.mul(s.c)), D(s.v), D(s.c), D(s.c)]
			rate = ["Each value ÷ the one before: %s ÷ %s = %s, so the rate is 100(1 − %s) = %s%%." % [Fmt.money(s.v.mul(s.c)), D(s.v), D(s.c), D(s.c), D(s.r)]]
		_:
			out.lines = ["%s owns a %s that is worth %s now. It was bought %d years ago, and its value has fallen by %s%% each year." % [who(s), item(s), M(s.v), s.n, D(s.r)]]
	out.asked = "Find the price it was bought for, to the nearest dollar."
	out.answer = ans
	out.wrongs = [money_wrong(v * pow(1.0 + r / 100.0, s.n), R_ADD_BACK), money_wrong(v / (1.0 - s.n * r / 100.0), R_STRAIGHT)]
	out.generic = ms([v * pow(c, s.n), v / pow(c, s.n - 1), v / pow(c, s.n + 1), p * 1.1])
	var tvm := rate.duplicate()
	tvm.append(tvm_line(["N = %d" % s.n, "I%% = −%s" % D(s.r), "FV = %s" % D(s.v)]))
	tvm.append("Solve for PV: the GDC shows −%s, and the price is its size." % C(p))
	var back := [keep, "Divide by %s once for each of the %d years back, from year %d." % [D(s.c), s.n, s.n]]
	var cells: Array = []
	var w := v
	for t in range(s.n - 1, -1, -1):
		w /= c
		cells.append("year %d: %s" % [t, C(w)])
	back.append(", ".join(cells).substr(0, 1).to_upper() + ", ".join(cells).substr(1) + ".")
	out.methods = _methods({"decay-multiplier": [keep, "%s × %s^%d = %s, so P = %s ÷ %s^%d = %s" % ["P", D(s.c), s.n, D(s.v), D(s.v), D(s.c), s.n, C(p)]],
		"tvm-negative": tvm, "year-by-year": back}, [], ans)
	return out


func u_find_rate(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var found := DepreciationSituation.rate_of(s)
	var ans := Answer.make("number", {"v": GdcKit.qf(found)}, {}, "rate = ", "%")
	ans.show = "sf"
	var out := {"table": null}
	match rep:
		"equation":
			out.lines = ["%s buys a %s. Its value in dollars, t years after it is bought, is V = %s(a)^t, where 0 < a < 1. When t = %d, V = %s." % [who(s), item(s), D(s.p), s.n, D(s.v)]]
		"table":
			out.lines = ["%s buys a %s, and its value falls by the same percentage each year. The table shows its value, t years after it is bought." % [who(s), item(s)]]
			out.table = {"rows": [["t (years)", ["0", str(s.n)]], ["V ($)", [D(s.p), D(s.v)]]]}
		_:
			out.lines = ["%s buys a %s for %s. %d years later it is worth %s, and it has lost the same percentage of its value each year." % [who(s), item(s), M(s.p), s.n, M(s.v)]]
	out.asked = "Find the yearly rate of depreciation, as a percentage to 3 s.f."
	out.answer = ans
	out.wrongs = [wrong({"v": GdcKit.qf(DepreciationSituation.kept(s))}, R_KEPT), wrong({"v": GdcKit.qf(DepreciationSituation.straight_rate(s))}, R_STRAIGHT),
		wrong({"v": GdcKit.qf(DepreciationSituation.whole_rate(s))}, R_WHOLE_FALL)]
	out.generic = [{"v": GdcKit.qf(found * 0.5)}, {"v": GdcKit.qf(found * 1.5)}, {"v": GdcKit.qf(found + 1.0)}]
	var ratio: float = s.v.to_float() / s.p.to_float()
	var c6 := snappedf(DepreciationSituation.root(s), 0.000001)
	out.methods = {
		"decay-multiplier": method(["V ÷ P = c^%d, where c is the multiplier: c^%d = %s ÷ %s = %.6f" % [s.n, s.n, D(s.v), D(s.p), ratio],
			"c = (%.6f)^(1/%d) = %.6f" % [ratio, s.n, c6],
			"The rate is 100(1 − c) = 100(1 − %.6f) = %.4f" % [c6, 100.0 * (1.0 - c6)], final_step(ans)], ans.values),
		"tvm-negative": method([tvm_line(["N = %d" % s.n, "PV = −%s" % D(s.p), "FV = %s" % D(s.v)]),
			"Solve for I%%: I%% = −%.4f, and the minus sign is the fall." % found, final_step(ans)], ans.values),
	}
	return out


func u_read_rate(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("number", {"v": s.r}, {}, "rate = ", "%")
	ans.show = "dec"
	ans.exact = true
	var out := story(rep, s)
	out.asked = "Write down the yearly rate of depreciation, as a percentage."
	out.answer = ans
	out.wrongs = [wrong({"v": s.c.mul(Q.new(100))}, R_KEPT)]
	out.generic = [{"v": s.c}, {"v": s.r.div(Q.new(100))}, {"v": s.r.add(Q.new(1))}, {"v": s.r.mul(Q.new(2))}]
	out.methods = {"decay-multiplier": method([keep_line(rep, s), "It keeps %s of its value, so it loses 1 − %s = %s, which is %s%%." % [D(s.c), D(s.c), D(s.r.div(Q.new(100))), D(s.r)], final_step(ans)], ans.values)}
	return out


# ── Two rates, and an account ────────────────────────────────

func u_two_rate_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: float = s.p.to_float()
	var c: float = s.c.to_float()
	var c2: float = s.c2.to_float()
	var v := DepreciationSituation.two_value(s)
	var ans := dollars("value = $", v)
	var out := {"table": null}
	if rep == "table":
		out.lines = ["%s buys a %s for %s. The table shows how far its value falls each year." % [who(s), item(s), M(s.p)]]
		out.table = {"rows": [["Year", ["1", "2 onward"]], ["Fall in value", [D(s.r) + "%", D(s.r2) + "%"]]]}
	else:
		out.lines = ["%s buys a %s for %s. Its value falls by %s%% in the first year, and by %s%% in each year after that." % [who(s), item(s), M(s.p), D(s.r), D(s.r2)]]
	out.asked = "Find its value %d years after it is bought, to the nearest dollar." % s.n
	out.answer = ans
	out.wrongs = [money_wrong(DepreciationSituation.value(p, c2, s.n), R_LATER_RATE), money_wrong(p - v, R_REMAINING)]
	out.generic = ms([v * c2, p * c * pow(c, s.n - 1), v * 1.05, p * (1.0 - (s.r.to_float() + (s.n - 1) * s.r2.to_float()) / 100.0)])
	var a := p * c
	var first := "The first year keeps %s: %s × %s = %s" % [D(s.c), D(s.p), D(s.c), C(a)]
	var yearly := [first, "Each later year keeps %s." % D(s.c2)]
	yearly.append_array(run(a, c2, 1, s.n))
	out.methods = _methods({
		"decay-multiplier": [first, "The other %d years keep %s each: V = %s × %s^%d = %s" % [s.n - 1, D(s.c2), C(a), D(s.c2), s.n - 1, C(v)]],
		"tvm-negative": [first, tvm_line(["N = %d" % (s.n - 1), "I%% = −%s" % D(s.r2), "PV = −%s" % C(a)]), "Solve for FV: FV = %s" % C(v)],
		"year-by-year": yearly}, [], ans)
	return out


func u_shortfall(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: float = s.p.to_float()
	var r: float = s.r.to_float()
	var v := V(s, s.n)
	var a := DepreciationSituation.account(s)
	var m := v - a
	var sv: float = s.save.to_float()
	var ans := dollars("M = $", m)
	var out := {"table": null}
	if rep == "equation":
		out.lines = ["%s plans to buy a %s in %d years' time. Its value in dollars, t years from now, is %s." % [who(s), item(s), s.n, model(s)]]
	else:
		out.lines = ["%s plans to buy a %s in %d years' time. It is worth %s now, and its value falls by %s%% each year." % [who(s), item(s), s.n, M(s.p), D(s.r)]]
	out.lines.append("The buyer puts %s in an account today, at %s%% per year compounded yearly, and adds nothing more." % [M(s.save), D(s.i)])
	out.lines.append("On the day, all the money in the account and an extra $M will pay exactly what the %s is worth then." % item(s))
	out.asked = "Find M, to the nearest dollar."
	out.answer = ans
	out.wrongs = [money_wrong(p - a, R_DATES), money_wrong(v - sv, R_DATES)]
	out.generic = ms([DepreciationSituation.value(p, 1.0 + r / 100.0, s.n) - a, m * 1.1, m * 0.9, m + 500.0])
	var tail := ["M = %s − %s = %s" % [C(v), C(a), gap(v, a)]]
	var rate := rate_lines(rep, s)
	var tvm: Array = rate.duplicate()
	tvm.append(tvm_line(["N = %d" % s.n, "I%% = −%s" % D(s.r), "PV = −%s" % D(s.p)]) + " Solve for FV: FV = %s" % C(v))
	tvm.append("Again with I%% = %s and PV = −%s: FV = %s" % [D(s.i), D(s.save), C(a)])
	out.methods = _methods({
		"decay-multiplier": [keep_line(rep, s), "Its value then: V = %s × %s^%d = %s" % [D(s.p), D(s.c), s.n, C(v)],
			"The account then: %s × %s^%d = %s" % [D(s.save), D(Q.new(1).add(s.i.div(Q.new(100)))), s.n, C(a)]],
		"tvm-negative": tvm}, tail, ans)
	return out


# ── The time to fall below a target ──────────────────────────

## From P × c^x < T to x > the real solution, by each method. `per` is what the answer's time is
## in, in periods: 1, or k when a rate per month or quarter is asked in years. `word` is that time.
func _time_methods(rep: String, s: Dictionary, ans: Dictionary, per: int, word: String) -> Dictionary:
	var x: float = s.x
	var y: float = x / per
	var w: String = letter(s)
	var least: int = s.least
	var ratio: float = s.target.to_float() / s.p.to_float()
	var open := "%d%% of %s is %s. " % [s.pct, D(s.p), D(s.target)] if s.has("pct") else ""
	var ups := "The answer is a whole number of %ss, so round up: %d." % [word, least]
	var conv := ["%.3f %ss is %.3f ÷ %d = %.3f years." % [x, unit(s), x, per, y]] if per > 1 else []
	var logs: Array = [open + "Need %s × %s^%s < %s, so %s^%s < %s ÷ %s = %.6f" % [D(s.p), D(s.c), w, D(s.target), D(s.c), w, D(s.target), D(s.p), ratio],
		"Take logs: %s ln(%s) < ln(%.6f). ln(%s) is negative, so dividing by it flips the sign: %s > %.3f" % [w, D(s.c), ratio, D(s.c), w, x]]
	logs.append_array(conv)
	logs.append(ups)
	var tvm: Array = rate_lines(rep, s)
	tvm.append(open + tvm_line(["I%% = −%s" % D(s.r), "PV = −%s" % D(s.p), "FV = %s" % D(s.target)]))
	tvm.append("Solve for N: N = %.3f %ss." % [x, unit(s)] if per == 1 else "Solve for N: N = %.3f, in %ss, which is %.3f ÷ %d = %.3f years." % [x, unit(s), x, per, y])
	tvm.append(ups)
	var step: int = per
	var low: int = (least - 1) * per
	var top: int = least * per
	var scan := [open + "Enter Y1 = %s × %s^X and read the table in steps of %d." % [D(s.p), D(s.c), step],
		"X = %d gives Y1 = %s, which is not yet below %s." % [low, C(V(s, low)), D(s.target)],
		"X = %d gives Y1 = %s, the first below %s." % [top, C(V(s, top)), D(s.target)]]
	if per > 1:
		scan.append("%d %ss is %d years." % [top, unit(s), least])
	var cross: Array = [open + "Graph y = %s × %s^x and y = %s." % [D(s.p), D(s.c), D(s.target)],
		"They meet at x = %.3f, and the curve is below the line after that." % x]
	cross.append_array(conv)
	cross.append(ups)
	return _methods({"logs": logs, "tvm": tvm, "gdc-table": scan, "graph-intersect": cross}, [], ans)


func _time_wrongs(s: Dictionary, real: float) -> Array:
	var out := [wrong({"v": Q.new(int(floorf(real)))}, R_NO_FLIP)]
	if roundi(real) != s.least:
		out.append(wrong({"v": Q.new(roundi(real))}, R_ROUND_NEAREST))
	return out


func _time_generic(least: int) -> Array:
	return [{"v": Q.new(least + 1)}, {"v": Q.new(least + 2)}, {"v": Q.new(maxi(1, least - 2))}, {"v": Q.new(least + 3)}]


func _years(rep: String, s: Dictionary, asked: String) -> Dictionary:
	var ans := count("years = ", s.least)
	var out := story(rep, s)
	out.asked = asked
	out.answer = ans
	out.wrongs = _time_wrongs(s, s.x)
	var line := DepreciationSituation.straight_years(s)
	if line != s.least:
		out.wrongs.append(wrong({"v": Q.new(line)}, R_STRAIGHT))
	out.generic = _time_generic(s.least)
	out.methods = _time_methods(rep, s, ans, 1, "year")
	return out


func u_years_below(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _years(rep, s, "Find the least number of complete years after which its value is less than %s." % M(s.target))


func u_years_fraction(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _years(rep, s, "Find the least number of complete years after which it is worth less than %d%% of the price paid." % s.pct)


func u_years_from_periods(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := count("years = ", s.least)
	var out := story(rep, s)
	out.asked = "Find the least number of complete years after which its value is less than %s." % M(s.target)
	out.answer = ans
	var y: float = s.x / s.k
	out.wrongs = _time_wrongs(s, y)
	out.wrongs.append(wrong({"v": Q.new(int(ceilf(s.x)))}, R_NO_CONVERT))
	out.generic = _time_generic(s.least)
	out.methods = _time_methods(rep, s, ans, s.k, "year")
	return out


func u_least_periods(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := count("%ss = " % unit(s), s.least)
	var out := story(rep, s)
	out.asked = "Find the least number of complete %ss after which its value is less than %s." % [unit(s), M(s.target)]
	out.answer = ans
	out.wrongs = _time_wrongs(s, s.x)
	out.generic = _time_generic(s.least)
	out.generic.push_front({"v": Q.new(int(ceilf(s.x / s.k)))})
	out.methods = _time_methods(rep, s, ans, 1, unit(s))
	return out
