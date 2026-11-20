class_name CompoundInterestViews
extends ExtensionViews
## The views on the `compound-interest` situation: one builder per unknown of
## t1-compound-interest (FAL-695). A question is Paper 2 and works with the GDC's TVM solver
## or the formula, except a future value or interest by formula, which can be Paper 1. Money is answered to the nearest cent and exactly, a rate to 3 s.f.
## with the rounding trap, and a number of years as a whole number.
##
## Representations: "words" (a story, the account in a sentence) and, for two accounts,
## "table" (rate and compounding side by side). `given` holds what the student is shown.
##
## t1-ext-real-value (FAL-780) is built here too: an account compounded annually while prices rise
## by an inflation rate. It asks the real interest rate, the real value by the real rate (the IB's
## approximation) or by deflating, and whether the account keeps pace. Its wrong options are
## SL1.4.real-value's slips and the type's own; it builds method-pick on every cell and error-spot on
## the two values.

const SKILL := "SL1.4."
const R_ANNUAL_RATE := SKILL + "future-value#0"
const R_SIMPLE := SKILL + "future-value#1"
const R_TOTAL_INTEREST := SKILL + "future-value#2"
const R_ROOT_ONLY := SKILL + "find-rate-or-pv#0"
const R_SHARE := SKILL + "find-rate-or-pv#2"
const R_ROUND_NEAREST := SKILL + "find-time#0"
const R_NO_CONVERT := SKILL + "find-time#1"
const R_NOMINAL_ONLY := SKILL + "compare-options#0"
## The type's own misconceptions, by index (FAL-1149).
const R_TIMES_FACTOR := "t1-compound-interest#8"
const R_ROUND_DOWN := "t1-compound-interest#9"

const WHO := ["Kira", "Tomas", "The Guild", "A trader", "Ines", "The caravan fund"]
const FREQ := {1: "annually", 2: "half-yearly", 4: "quarterly", 12: "monthly"}
const UNKNOWNS := ["future-value", "interest-earned", "present-value", "interest-rate", "time-needed", "compare-options"]
const REAL := ["real-rate", "real-value-rate", "real-value-deflate", "keeps-pace"]
const RV := "SL1.4.real-value#"
const RO := "t1-ext-real-value#"
const R_ADD_RATES := RV + "0"
const R_ONCE := RV + "1"
const R_BALANCE := RV + "2"
const R_RATES_SWAP := RO + "3"
const R_NOMINAL := RO + "4"
const R_TIMES_F := RO + "5"
const R_ALWAYS_FALL := RO + "6"
const R_SPOT_ONCE := RO + "7"
const R_SPOT_ADD := RO + "8"
## Methods that don't work on any real-value question, for method-pick.
const RV_PICK_WRONGS := [
	{"name": "Add the inflation rate to the interest rate", "why": "inflation takes value away, so its rate comes off the interest rate"},
	{"name": "Divide by the inflation factor for one year", "why": "prices rise every year, so the factor is raised to the number of years"},
	{"name": "Use the interest rate alone", "why": "that is the balance, which leaves out the rise in prices"},
]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS + REAL:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	return {"real-rate": ["method-pick"], "real-value-rate": ["method-pick", "error-spot"], "real-value-deflate": ["method-pick", "error-spot"],
		"keeps-pace": ["method-pick"]}


## The GDC does the work, so a cell is Paper 2, but a future value or the interest earned by
## formula can also be a Paper 1 question (annual compounding at a round rate, exact by hand).
func papers(unknown: String, _rep: String, angle: String) -> Array:
	if not has(unknown):
		return []
	if unknown in ["future-value", "interest-earned"] and angle == "compound-formula":
		return [1, 2]
	return [2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = CompoundInterestSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## $5000 or $5432.10
static func M(v: Variant) -> String:
	return "$" + Fmt.money(v)


## A float to 4 decimal places, a GDC's screen.
static func F(x: float) -> String:
	return "%.4f" % x


static func qf(x: float) -> Q:
	return GdcKit.qf(x)


static func freq(k: int) -> String:
	return FREQ[k]


static func who(s: Dictionary) -> String:
	return WHO[s.ctx]


## The growth factor per period, 1 + r/(100k), to 6 decimal places.
static func factor(r: float, k: int) -> String:
	return "%.6f" % (1.0 + r / (100.0 * k))


## A money answer: exact, to the cent.
static func money_ans(label: String, x: float) -> Dictionary:
	var ans := Answer.make("number", {"v": CompoundInterestSituation.money(x)}, {}, label)
	ans.show = "money"
	ans.exact = true
	return ans


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## Wrong money options: each a cent value, as a {"v": Q}.
static func ms(xs: Array) -> Array:
	return xs.filter(func(x): return x > 0.0 and is_finite(x)).map(func(x): return {"v": CompoundInterestSituation.money(x)})


# ── Future value and interest earned ─────────────────────────

func _invested(s: Dictionary) -> Dictionary:
	return {"lines": ["%s invests %s in an account that pays %s%% per year, compounded %s." % [who(s), M(s.pv), D(s.r), freq(s.k)]], "table": null}


## The steps shared by the formula and the TVM solver for a future value.
func _fv_steps(s: Dictionary, fv: float, ans: Dictionary, interest: bool) -> Dictionary:
	var pv: float = s.pv.to_float()
	var r: float = s.r.to_float()
	var kn: int = s.k * s.n
	var formula := ["FV = PV(1 + r/(100k))^(kn): PV = %s, r = %s, k = %d and n = %d, so kn = %d periods." % [D(s.pv), D(s.r), s.k, s.n, kn],
		"FV = %s × (1 + %s/%d)^%d = %s × %s^%d = %s" % [D(s.pv), D(s.r), 100 * s.k, kn, D(s.pv), factor(r, s.k), kn, F(fv)]]
	var tvm := ["Open the TVM solver: N = %d, I%% = %s, PV = −%s, PMT = 0, P/Y = %d, C/Y = %d." % [kn, D(s.r), D(s.pv), s.k, s.k],
		"Solve for FV: FV = %s" % F(fv)]
	if interest:
		formula.append("Interest = FV − PV = %s − %s = %s" % [F(fv), D(s.pv), F(fv - pv)])
		tvm.append("Interest = FV − PV = %s − %s = %s" % [F(fv), D(s.pv), F(fv - pv)])
	formula.append(final_step(ans))
	tvm.append(final_step(ans))
	return {"compound-formula": method(formula, ans.values), "tvm": method(tvm, ans.values)}


func u_future_value(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pv: float = s.pv.to_float()
	var r: float = s.r.to_float()
	var fv := CompoundInterestSituation.value(pv, r, s.k, s.n)
	var ans := money_ans("value = $", fv)
	var out := _invested(s)
	out.asked = "Find the value of the investment after %d years, to the nearest cent." % s.n
	out.answer = ans
	out.wrongs = []
	var annual := CompoundInterestSituation.value(pv, r, 1, s.k * s.n)
	var simple: float = pv * (1.0 + s.n * r / 100.0)
	for w in [[annual, R_ANNUAL_RATE], [simple, R_SIMPLE], [fv - pv, R_TOTAL_INTEREST]]:
		out.wrongs.append(wrong({"v": CompoundInterestSituation.money(w[0])}, w[1]))
	out.fillers = ms([CompoundInterestSituation.value(pv, r, s.k, s.n - 1), CompoundInterestSituation.value(pv, r, s.k, s.n + 1), fv * 1.05])
	out.methods = _fv_steps(s, fv, ans, false)
	return out


func u_interest_earned(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pv: float = s.pv.to_float()
	var r: float = s.r.to_float()
	var fv := CompoundInterestSituation.value(pv, r, s.k, s.n)
	var ans := money_ans("interest = $", fv - pv)
	var out := _invested(s)
	out.asked = "Find the interest earned over the %d years, to the nearest cent." % s.n
	out.answer = ans
	out.wrongs = [wrong({"v": CompoundInterestSituation.money(fv)}, R_TOTAL_INTEREST)]
	# The annual rate over kn periods and simple interest, each less the PV.
	out.wrongs.append(wrong({"v": CompoundInterestSituation.money(CompoundInterestSituation.value(pv, r, 1, s.k * s.n) - pv)}, R_ANNUAL_RATE))
	out.wrongs.append(wrong({"v": CompoundInterestSituation.money(pv * s.n * r / 100.0)}, R_SIMPLE))
	out.fillers = ms([fv - pv - 100.0, (fv - pv) * 1.1])
	out.methods = _fv_steps(s, fv, ans, true)
	return out


# ── Present value and the rate ───────────────────────────────

func u_present_value(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: float = s.fv.to_float()
	var r: float = s.r.to_float()
	var kn: int = s.k * s.n
	var pv := f / pow(1.0 + r / (100.0 * s.k), kn)
	var ans := money_ans("PV = $", pv)
	var out := {"lines": ["%s wants an account to be worth %s after %d years. The account pays %s%% per year, compounded %s." % [who(s), M(s.fv), s.n, D(s.r), freq(s.k)]],
		"asked": "Find the amount to invest now, to the nearest cent.", "answer": ans, "table": null}
	# Compounding the wrong way, the annual rate over kn periods, and simple interest.
	out.wrongs = []
	for w in [[f * pow(1.0 + r / (100.0 * s.k), kn), R_TIMES_FACTOR], [f / pow(1.0 + r / 100.0, kn), R_ANNUAL_RATE], [f / (1.0 + s.n * r / 100.0), R_SIMPLE]]:
		out.wrongs.append(wrong({"v": CompoundInterestSituation.money(w[0])}, w[1]))
	out.fillers = ms([pv * 1.1])
	out.methods = {
		"rearrange": method(["FV = PV(1 + r/(100k))^(kn), so PV = FV ÷ (1 + r/(100k))^(kn), with kn = %d periods." % kn,
			"PV = %s ÷ %s^%d = %s ÷ %s = %s" % [D(s.fv), factor(r, s.k), kn, D(s.fv), "%.6f" % pow(1.0 + r / (100.0 * s.k), kn), F(pv)], final_step(ans)], ans.values),
		"tvm": method(["Open the TVM solver: N = %d, I%% = %s, FV = %s, PMT = 0, P/Y = %d, C/Y = %d." % [kn, D(s.r), D(s.fv), s.k, s.k],
			"Solve for PV: the GDC shows −%s; the amount to invest is its size." % F(pv), final_step(ans)], ans.values),
	}
	return out


func u_interest_rate(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var found := CompoundInterestSituation.rate_of(s)
	var ans := Answer.make("number", {"v": qf(found)}, {}, "rate = ", "%")
	ans.show = "sf"
	var kn: int = s.k * s.n
	var ratio: float = s.fv.to_float() / s.pv.to_float()
	var out := {"lines": ["%s invests %s in an account that pays interest compounded %s. After %d years the account is worth %s." % [who(s), M(s.pv), freq(s.k), s.n, M(s.fv)]],
		"asked": "Find the annual interest rate, as a percentage to 3 s.f.", "answer": ans, "table": null}
	out.wrongs = [wrong({"v": qf(CompoundInterestSituation.slip_root(s))}, R_ROOT_ONLY), wrong({"v": qf(CompoundInterestSituation.slip_share(s))}, R_SHARE)]
	out.fillers = [{"v": qf(found * 0.5)}, {"v": qf(found * 1.5)}, {"v": qf(found + 1.0)}, {"v": qf(found * s.k)}]
	out.methods = {
		"rearrange": method(["FV ÷ PV = (1 + r/(100k))^(kn), so r = 100k((FV ÷ PV)^(1/kn) − 1), with kn = %d." % kn,
			"FV ÷ PV = %s ÷ %s = %s" % [D(s.fv), D(s.pv), "%.6f" % ratio],
			"r = 100 × %d × (%s^(1/%d) − 1) = %s" % [s.k, "%.6f" % ratio, kn, "%.5f" % found], final_step(ans)], ans.values),
		"tvm": method(["Open the TVM solver: N = %d, PV = −%s, FV = %s, PMT = 0, P/Y = %d, C/Y = %d." % [kn, D(s.pv), D(s.fv), s.k, s.k],
			"Solve for I%%: I%% = %s" % ("%.5f" % found), final_step(ans)], ans.values),
	}
	return out


# ── Time needed ──────────────────────────────────────────────

func u_time_needed(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pv: float = s.pv.to_float()
	var r: float = s.r.to_float()
	var target: float = s.target.to_float()
	var x := CompoundInterestSituation.years_real(pv, target, r, s.k)
	var years: int = s.years
	var ans := Answer.make("number", {"v": Q.new(years)}, {}, "years = ")
	ans.show = "dec"
	ans.exact = true
	var out := {"lines": ["%s invests %s in an account that pays %s%% per year, compounded %s." % [who(s), M(s.pv), D(s.r), freq(s.k)]],
		"asked": "Find the number of complete years needed for the investment to be worth more than %s." % M(s.target), "answer": ans, "table": null}
	out.wrongs = []
	if roundi(x) != years:
		out.wrongs.append(wrong({"v": Q.new(roundi(x))}, R_ROUND_NEAREST))
	if s.k > 1:
		out.wrongs.append(wrong({"v": Q.new(int(ceilf(x * s.k)))}, R_NO_CONVERT))
	# The real number of years rounded down: the target not yet passed.
	if years > 1:
		out.wrongs.append(wrong({"v": Q.new(years - 1)}, R_ROUND_DOWN))
	out.fillers = [{"v": Q.new(years + 1)}, {"v": Q.new(years + 2)}, {"v": Q.new(maxi(1, years - 2))}]
	var ratio := target / pv
	var per: float = 1.0 + r / (100.0 * s.k)
	var periods: float = x * s.k
	out.methods = {
		"logs": method(["Need %s × %s^(%dn) > %s, so %s^(%dn) > %s ÷ %s = %s." % [D(s.pv), factor(r, s.k), s.k, D(s.target), factor(r, s.k), s.k, D(s.target), D(s.pv), "%.6f" % ratio],
			"Take logs: %dn × ln(%s) > ln(%s), so n > %s ÷ (%d × %s) = %s years." % [s.k, factor(r, s.k), "%.6f" % ratio, "%.6f" % log(ratio), s.k, "%.6f" % log(per), "%.4f" % x],
			"n is a whole number of years, so round up: n = %d." % years, final_step(ans)], ans.values),
		"tvm": method(["Open the TVM solver: I%% = %s, PV = −%s, FV = %s, PMT = 0, P/Y = %d, C/Y = %d." % [D(s.r), D(s.pv), D(s.target), s.k, s.k],
			"Solve for N: N = %s periods, which is %s ÷ %d = %s years." % ["%.4f" % periods, "%.4f" % periods, s.k, "%.4f" % x],
			"A complete number of years that passes the target: round up to n = %d." % years, final_step(ans)], ans.values),
	}
	return out


# ── Two accounts ─────────────────────────────────────────────

func u_compare_options(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pv: float = s.pv.to_float()
	var ra: float = s.r.to_float()
	var rb: float = s.rb.to_float()
	var a := CompoundInterestSituation.value(pv, ra, s.k, s.n)
	var b := CompoundInterestSituation.value(pv, rb, s.kb, s.n)
	var d := a - b
	var ans := money_ans("difference = $", d)
	var lines: Array = ["%s invests %s for %d years in one of two accounts." % [who(s), M(s.pv), s.n]]
	var table = null
	if rep == "table":
		table = {"rows": [["Account", ["A", "B"]], ["Rate (% per year)", [D(s.r), D(s.rb)]], ["Compounded", [freq(s.k), freq(s.kb)]]]}
	else:
		lines.append("Account A pays %s%% per year, compounded %s. Account B pays %s%% per year, compounded %s." % [D(s.r), freq(s.k), D(s.rb), freq(s.kb)])
	var out := {"lines": lines, "table": table, "asked": "How much more is account A worth than account B at the end of the %d years? Give your answer to the nearest cent." % s.n,
		"answer": ans}
	var a1 := CompoundInterestSituation.value(pv, ra, 1, s.n)
	var b1 := CompoundInterestSituation.value(pv, rb, 1, s.n)
	out.wrongs = [wrong({"v": CompoundInterestSituation.money(a1 - b1)}, R_NOMINAL_ONLY)]
	out.fillers = ms([d * 0.5, d * 1.5, d + 100.0, maxf(1.0, d - 100.0)])
	var fa := pow(1.0 + ra / (100.0 * s.k), s.k)
	var fb := pow(1.0 + rb / (100.0 * s.kb), s.kb)
	var both := ["Account A: %s × (1 + %s/%d)^%d = %s." % [D(s.pv), D(s.r), 100 * s.k, s.k * s.n, F(a)],
		"Account B: %s × (1 + %s/%d)^%d = %s." % [D(s.pv), D(s.rb), 100 * s.kb, s.kb * s.n, F(b)],
		"A − B = %s − %s = %s" % [F(a), F(b), F(d)], final_step(ans)]
	var factors := ["Yearly growth factors: A: (1 + %s/%d)^%d = %s and B: (1 + %s/%d)^%d = %s." % [D(s.r), 100 * s.k, s.k, "%.6f" % fa, D(s.rb), 100 * s.kb, s.kb, "%.6f" % fb],
		"A's factor is larger, so A is worth more after any number of years: A = %s × %s^%d = %s and B = %s × %s^%d = %s." % [D(s.pv), "%.6f" % fa, s.n, F(a), D(s.pv), "%.6f" % fb, s.n, F(b)],
		"A − B = %s − %s = %s" % [F(a), F(b), F(d)], final_step(ans)]
	out.methods = {"compute-both": method(both, ans.values), "annual-factor": method(factors, ans.values)}
	return out


# ── Real value (t1-ext-real-value) ───────────────────────────

func _saves(s: Dictionary) -> String:
	return "%s puts %s into an account that pays %s%% interest per year, compounded annually. Prices rise by %s%% per year." % [who(s), M(s.pv), D(s.r), D(s.f)]


## "2.5%", "−1.5%": a rate in per cent.
static func pc(v: Q) -> String:
	return v.text() + "%" if v.is_int() else Fmt.dec(v) + "%"


func _rv_pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {}, "table": null, "pick_wrongs": RV_PICK_WRONGS}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


func u_real_rate(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var real: Q = s.r.sub(s.f)
	var ans := Answer.make("number", {"v": real}, {}, "real rate = ", "%")
	ans.show = "dec"
	ans.exact = true
	var wr: Array = [wrong({"v": s.r.add(s.f)}, R_ADD_RATES), wrong({"v": s.f.sub(s.r)}, R_RATES_SWAP)]
	var fill: Array = [{"v": real.add(1)}, {"v": s.r.div(s.f)}, {"v": real.sub(1)}].filter(func(v): return not v.v.eq(real) and not v.v.eq(s.r.add(s.f)) and not v.v.eq(s.f.sub(s.r)))
	return _rv_pack(["%s puts money into an account that pays %s%% interest per year. Prices rise by %s%% per year." % [who(s), D(s.r), D(s.f)]],
		"Write down the real interest rate.", ans, wr, fill, {
		"real-rate-tvm": ["The real interest rate is the interest rate minus the inflation rate.", "%s − %s = %s" % [D(s.r), D(s.f), Fmt.dec(real)], final_step(ans)],
	})


## The value and slips of a real value, each to the cent.
func u_real_value_rate(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var pv: float = s.pv.to_float()
	var r: float = s.r.to_float()
	var f: float = s.f.to_float()
	var x: Q = s.r.sub(s.f)
	var real := CompoundInterestSituation.real_rate_value(s)
	var ans := money_ans("real value = $", real)
	var wr: Array = [wrong({"v": CompoundInterestSituation.money(CompoundInterestSituation.value(pv, r + f, 1, s.n))}, R_ADD_RATES),
		wrong({"v": CompoundInterestSituation.money(CompoundInterestSituation.value(pv, r, 1, s.n))}, R_NOMINAL)]
	var fill := ms([real + 100.0, real * 1.1, CompoundInterestSituation.value(pv, x.to_float(), 1, s.n + 1)])
	var g := 1.0 + x.to_float() / 100.0
	var out := _rv_pack([_saves(s)], "Using the real interest rate, find the real value of the investment after %d years, to the nearest cent." % s.n, ans, wr, fill, {
		"real-rate-tvm": ["Real rate = %s − %s = %s%%." % [D(s.r), D(s.f), Fmt.dec(x)],
			"Open the TVM solver: N = %d, I%% = %s, PV = −%s, PMT = 0, P/Y = 1, C/Y = 1." % [s.n, Fmt.dec(x), D(s.pv)], "Solve for FV: FV = %s" % F(real), final_step(ans)],
		"year-by-year": ["Real rate = %s − %s = %s%%, so each year the real value is multiplied by %s." % [D(s.r), D(s.f), Fmt.dec(x), "%.6f" % g],
			"Year 1: %s × %s = %s; year 2: %s × %s = %s." % [D(s.pv), "%.6f" % g, F(pv * g), F(pv * g), "%.6f" % g, F(pv * g * g)],
			"After %d years: %s × %s^%d = %s" % [s.n, D(s.pv), "%.6f" % g, s.n, F(real)], final_step(ans)],
	})
	var wrong_rate: Q = s.r.add(s.f)
	var bad_v := CompoundInterestSituation.value(pv, r + f, 1, s.n)
	var lines: Array = ["Real rate = %s + %s = %s%%" % [D(s.r), D(s.f), Fmt.dec(wrong_rate)], "Value = %s × (1 + %s/100)^%d" % [D(s.pv), Fmt.dec(wrong_rate), s.n],
		"= %s" % F(bad_v), "So the real value is %s." % M(CompoundInterestSituation.money(bad_v))]
	var bad := 0
	if rng.chance(0.5):
		lines = ["Use the real rate in the compound interest formula.", "Real rate = %s + %s = %s%%" % [D(s.r), D(s.f), Fmt.dec(wrong_rate)],
			"Value = %s × (1 + %s/100)^%d = %s" % [D(s.pv), Fmt.dec(wrong_rate), s.n, F(bad_v)], "So the real value is %s." % M(CompoundInterestSituation.money(bad_v))]
		bad = 1
	out.spot = {"lines": lines, "bad": bad, "ref": R_SPOT_ADD, "why": "inflation takes value away, so the real rate is %s − %s = %s%%" % [D(s.r), D(s.f), Fmt.dec(x)]}
	return out


func u_real_value_deflate(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var pv: float = s.pv.to_float()
	var r: float = s.r.to_float()
	var f: float = s.f.to_float()
	var nominal := CompoundInterestSituation.value(pv, r, 1, s.n)
	var prices := pow(1.0 + f / 100.0, s.n)
	var defl := nominal / prices
	var ans := money_ans("real value = $", defl)
	var wr: Array = [wrong({"v": CompoundInterestSituation.money(nominal / (1.0 + f / 100.0))}, R_ONCE), wrong({"v": CompoundInterestSituation.money(nominal)}, R_NOMINAL),
		wrong({"v": CompoundInterestSituation.money(nominal * prices)}, R_TIMES_F)]
	var fill := ms([defl + 100.0, defl * 0.9])
	var g := (1.0 + r / 100.0) / (1.0 + f / 100.0)
	var out := _rv_pack([_saves(s)], "By dividing by the rise in prices, find the value of the investment after %d years in today's money, to the nearest cent." % s.n, ans, wr, fill, {
		"deflate": ["Value after %d years: FV = %s × %s^%d = %s" % [s.n, D(s.pv), "%.4f" % (1.0 + r / 100.0), s.n, F(nominal)],
			"Prices rise by a factor of %s^%d = %s" % ["%.4f" % (1.0 + f / 100.0), s.n, "%.6f" % prices], "Real value = %s ÷ %s = %s" % [F(nominal), "%.6f" % prices, F(defl)], final_step(ans)],
		"year-by-year": ["Each year the money grows by %s and prices by %s, so its real value is multiplied by %s ÷ %s = %s." % ["%.4f" % (1.0 + r / 100.0), "%.4f" % (1.0 + f / 100.0), "%.4f" % (1.0 + r / 100.0), "%.4f" % (1.0 + f / 100.0), "%.6f" % g],
			"Year 1: %s × %s = %s; year 2: %s × %s = %s." % [D(s.pv), "%.6f" % g, F(pv * g), F(pv * g), "%.6f" % g, F(pv * g * g)],
			"After %d years: %s × %s^%d = %s" % [s.n, D(s.pv), "%.6f" % g, s.n, F(defl)], final_step(ans)],
	})
	var once := nominal / (1.0 + f / 100.0)
	var lines: Array = ["FV = %s × %s^%d = %s" % [D(s.pv), "%.4f" % (1.0 + r / 100.0), s.n, F(nominal)], "Prices rise by a factor of %s" % "%.4f" % (1.0 + f / 100.0),
		"Real value = %s ÷ %s = %s" % [F(nominal), "%.4f" % (1.0 + f / 100.0), F(once)], "So the real value is %s." % M(CompoundInterestSituation.money(once))]
	out.spot = {"lines": lines, "bad": 1, "ref": R_SPOT_ONCE, "why": "prices rise every year, so over %d years they rise by a factor of %s^%d" % [s.n, "%.4f" % (1.0 + f / 100.0), s.n]}
	if rng.chance(0.5):
		out.spot.lines = ["Divide the value after %d years by the rise in prices." % s.n] + [lines[1], lines[2], lines[3]]
		out.spot.lines[1] = "FV = %s × %s^%d = %s, and prices rise by a factor of %s" % [D(s.pv), "%.4f" % (1.0 + r / 100.0), s.n, F(nominal), "%.4f" % (1.0 + f / 100.0)]
	return out


func u_keeps_pace(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: Q = s.r.sub(s.f)
	var up: bool = x.sign() > 0
	var a: float = 1.0 + s.r.to_float() / 100.0
	var b: float = 1.0 + s.f.to_float() / 100.0
	var right := "Yes: the interest rate is more than the inflation rate, so its value in today's money rises." if up \
		else "No: the interest rate is less than the inflation rate, so its value in today's money falls, though its balance rises."
	var ws: Array
	if up:
		ws = [["No: prices rise every year, so its real value must fall.", R_ALWAYS_FALL], ["No: the real interest rate is negative.", ""],
			["No: the account would have to pay more than %s, twice the inflation rate." % pc(s.f.mul(2)), ""]]
	else:
		ws = [["Yes: its balance rises every year, so it keeps pace.", R_BALANCE], ["Yes: the real interest rate is positive.", ""],
			["Yes: the interest rate is more than 0%, so its value grows.", ""]]
	var built := SamplingViews.claims(right, ws)
	var verdict := "rises" if up else "falls"
	return _rv_pack(["%s puts money into an account that pays %s interest per year, compounded annually. Prices rise by %s per year." % [who(s), pc(s.r), pc(s.f)]],
		"Does the investment keep pace with inflation? Give a reason.", built.answer, built.wrongs, built.fillers, {
		"real-rate-tvm": ["The real interest rate is %s − %s = %s." % [pc(s.r), pc(s.f), pc(x)], "It is %s, so the value in today's money %s." % ["positive" if up else "negative", verdict], right],
		"deflate": ["Each year the money is multiplied by %s and prices by %s." % ["%.3f" % a, "%.3f" % b],
			"%s ÷ %s = %s, %s than 1, so the value in today's money %s." % ["%.3f" % a, "%.3f" % b, "%.6f" % (a / b), "more" if up else "less", verdict], right],
	})
