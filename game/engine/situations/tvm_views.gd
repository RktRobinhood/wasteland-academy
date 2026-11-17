class_name TvmViews
extends ExtensionViews
## The views on the `tvm` situation (FAL-999): one builder per unknown of t1-ai-amortization
## (a loan's payment, term, last payment, rate, balance, first month's interest, total interest,
## and two loans compared) and t1-ai-annuity (the value of monthly deposits, the deposit for a
## target, the months to pass it, the interest earned; a fund's start, its number of
## withdrawals, its balance and the largest withdrawal). Every question is Paper 2.
##
## Representations: "words" (a story) and, for two loans, "table" (rates and terms side by side).
## Money answers are exact to the cent; a rate is to 3 s.f.; a count is a whole number.

const LR := "AI-SL1.7.loan-repayment#"
const LT := "AI-SL1.7.loan-term-or-rate#"
const OB := "AI-SL1.7.outstanding-balance#"
const TI := "AI-SL1.7.total-interest-compare#"
const SA := "AI-SL1.7.savings-annuity#"
const PA := "AI-SL1.7.payout-annuity#"
const TA := "t1-ai-amortization#"
const TN := "t1-ai-annuity#"

const WHO := ["Kira", "Tomas", "Ines", "Ravi", "Lena", "Odo"]
const FREQ := {12: "monthly", 4: "quarterly", 2: "half-yearly"}
const LOANS := ["loan-payment", "loan-term", "final-payment", "loan-rate", "balance-after", "first-interest", "total-interest", "compare-loans"]
const SAVINGS := ["savings-fv", "savings-deposit", "savings-time", "savings-interest", "payout-pv", "payout-months", "payout-balance", "payout-withdrawal"]


func needs() -> Dictionary:
	var out := {}
	for u in LOANS + SAVINGS:
		out[u] = {"ask": u}
	return out


## Every AI paper allows a GDC: every cell is Paper 2.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = TvmSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## $24000 or $386.66
static func M(v: Variant) -> String:
	return "$" + Fmt.money(v)


## A GDC's screen: 4 decimal places.
static func F(x: float) -> String:
	return "%.4f" % x


## A rate a month: 8 decimal places, without trailing zeros.
static func I(x: float) -> String:
	var t := "%.8f" % x
	return t.rstrip("0").rstrip(".")


static func who(s: Dictionary) -> String:
	return WHO[s.ctx]


static func freq(c: int) -> String:
	return FREQ[c]


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func money_ans(label: String, x: float) -> Dictionary:
	return CompoundInterestViews.money_ans(label, x)


static func count_ans(label: String, n: int) -> Dictionary:
	return SamplingViews.count_ans(label, n)


static func cents(x: float) -> Dictionary:
	return {"v": TvmSituation.money(x)}


static func ms(xs: Array) -> Array:
	return xs.filter(func(x): return x > 0.0 and is_finite(x)).map(func(x): return cents(x))


static func pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary, table = null) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {}, "table": table}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


## The TVM solver's line: the values entered, the unknown one left out.
static func solver(n: Variant, r: Q, pv: String, pmt: String, fv: String, c: int) -> String:
	var parts: Array = []
	if n != null:
		parts.append("N = %s" % str(n))
	if r != null:
		parts.append("I% = " + D(r))
	for pair in [["PV", pv], ["PMT", pmt], ["FV", fv]]:
		if pair[1] != "":
			parts.append("%s = %s" % pair)
	parts.append("P/Y = 12")
	parts.append("C/Y = %d" % c)
	return "Open the TVM solver: " + ", ".join(parts) + "."


## The rate a month, in words and figures.
static func monthly(s: Dictionary) -> String:
	var i := TvmSituation.i_of(s)
	if s.c == 12:
		return "The rate a month is i = %s ÷ 1200 = %s." % [D(s.r), I(i)]
	return "The rate a month is i = (1 + %s ÷ %d)^(%d ÷ 12) − 1 = %s." % [D(s.r), 100 * s.c, s.c, I(i)]


# ── Loans ────────────────────────────────────────────────────

func u_loan_payment(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: float = s.L.to_float()
	var i := TvmSituation.i_of(s)
	var sl := TvmSituation.payment_slips(L, i, s.r.to_float(), s.c, s.n)
	var ans := money_ans("payment = $", sl[0])
	var lines: Array = []
	var dep_steps: Array = []
	if s.has("price"):
		lines.append("%s buys %s for %s, pays a deposit of %d%% and borrows the rest." % [who(s), "a house" if s.price.to_float() >= 80000.0 else "a cargo truck", M(s.price), s.dep])
		dep_steps.append("Amount borrowed: %s − %d%% of %s = %s." % [D(s.price), s.dep, D(s.price), D(s.L)])
	else:
		lines.append("%s takes out a loan of %s." % [who(s), M(s.L)])
	lines.append("The loan is repaid with equal monthly payments over %d years, at %s%% per year, compounded %s." % [s.n, D(s.r), freq(s.c)])
	# Four slips for three places: each question offers three of them.
	var wr: Array = rng.shuffled([wrong(cents(sl[1]), LR + "0"), wrong(cents(sl[2]), LR + "1"), wrong(cents(sl[3]), LR + "2"), wrong(cents(sl[4]), LR + "3")])
	return pack(lines, "Find the monthly payment, to the nearest cent.", ans, wr, ms([sl[0] * 1.1]), {
		"tvm-pmt": dep_steps + [solver(s.N, s.r, D(s.L), "", "0", s.c), "Solve for PMT: PMT = −%s, negative as it is paid out." % F(sl[0]), final_step(ans)],
		"annuity-formula": dep_steps + [monthly(s), "PMT = PV × i ÷ (1 − (1 + i)^−N), with PV = %s and N = %d." % [D(s.L), s.N],
			"PMT = %s × %s ÷ (1 − %s^−%d) = %s" % [D(s.L), I(i), "%.8f" % (1.0 + i), s.N, F(sl[0])], final_step(ans)],
	})


func _repays(s: Dictionary) -> String:
	return "%s borrows %s at %s%% per year, compounded monthly, and repays %s at the end of each month." % [who(s), M(s.L), D(s.r), M(s.pmt)]


func u_loan_term(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var L: float = s.L.to_float()
	var i := TvmSituation.i_of(s)
	var p: float = s.pmt.to_float()
	var x: float = s.x
	var m: int = s.m
	var ans := count_ans("payments = ", m + 1)
	var left := TvmSituation.balance(L, i, p, m)
	return pack([_repays(s)], "Find the number of monthly payments needed to repay the loan.", ans, [wrong({"v": Q.new(m)}, LT + "0")],
		[{"v": Q.new(m + 2)}, {"v": Q.new(maxi(1, m - 1))}], {
		"tvm-n-or-i": [solver(null, s.r, D(s.L), "−" + Fmt.money(s.pmt), "0", 12), "Solve for N: N = %s." % F(x),
			"%d payments leave some of the loan unpaid, so round up: %d payments, the last one smaller." % [m, m + 1], final_step(ans)],
		"spreadsheet-rows": ["Each row: new balance = balance × (1 + %s) − %s." % [I(i), Fmt.money(s.pmt)],
			"After %d payments the balance is %s, still owed." % [m, F(left)],
			"The next payment clears it, as %s × %s = %s is less than %s." % [F(left), "%.8f" % (1.0 + i), F(left * (1.0 + i)), Fmt.money(s.pmt)], final_step(ans)],
	})


func u_final_payment(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var L: float = s.L.to_float()
	var i := TvmSituation.i_of(s)
	var p: float = s.pmt.to_float()
	var x: float = s.x
	var m: int = s.m
	var left := TvmSituation.balance(L, i, p, m)
	var last := left * (1.0 + i)
	var ans := money_ans("last payment = $", last)
	var wr: Array = [wrong(cents(left), TA + "13"), wrong(cents((x - m) * p), TA + "14")]
	return pack([_repays(s), "The last payment is smaller than the others and clears the loan."], "Find the amount of the last payment, to the nearest cent.", ans, wr,
		ms([last + p * 0.25]), {
		"tvm-n-or-i": [solver(null, s.r, D(s.L), "−" + Fmt.money(s.pmt), "0", 12) + " Solve for N: N = %s." % F(x),
			"So %d full payments and a smaller last one. With N = %d, solve for FV: FV = −%s, still owed." % [m, m, F(left)],
			"The last payment is that and one more month's interest: %s × %s = %s" % [F(left), "%.8f" % (1.0 + i), F(last)], final_step(ans)],
		"spreadsheet-rows": ["Each row: new balance = balance × (1 + %s) − %s." % [I(i), Fmt.money(s.pmt)],
			"After %d payments the balance is %s, less than a full payment with its interest." % [m, F(left)],
			"The last payment is that and one more month's interest: %s × %s = %s" % [F(left), "%.8f" % (1.0 + i), F(last)], final_step(ans)],
	})


func u_loan_rate(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var found: float = s.found
	var ans := Answer.make("number", {"v": GdcKit.qf(found)}, {}, "rate = ", "%")
	ans.show = "sf"
	var L: float = s.L.to_float()
	var simple: float = (s.N * s.pmt.to_float() - L) / L / s.n * 100.0
	var wr: Array = [wrong({"v": GdcKit.qf(12.0 * found)}, LT + "2"), wrong({"v": GdcKit.qf(simple)}, TA + "11")]
	return pack(["%s borrows %s and repays it with %d monthly payments of %s. Interest is compounded monthly." % [who(s), M(s.L), s.N, M(s.pmt)]],
		"Find the annual interest rate, as a percentage to 3 s.f.", ans, wr, [{"v": GdcKit.qf(found + 1.0)}, {"v": GdcKit.qf(found / 12.0)}], {
		"tvm-n-or-i": [solver(s.N, null, D(s.L), "−" + Fmt.money(s.pmt), "0", 12), "Solve for I%%: I%% = %s, already the annual rate." % F(found), final_step(ans)],
	})


func _owes(s: Dictionary) -> String:
	return "%s borrows %s over %d years at %s%% per year, compounded %s. The monthly payment is %s." % [who(s), M(s.L), s.n, D(s.r), freq(s.c), M(s.pmt)]


func u_balance_after(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var L: float = s.L.to_float()
	var i := TvmSituation.i_of(s)
	var p: float = s.pmt.to_float()
	var b := TvmSituation.balance(L, i, p, s.k)
	var ans := money_ans("balance = $", b)
	return pack([_owes(s)], "Find the amount still owed after %d payments, to the nearest cent." % s.k, ans, [wrong(cents(L - s.k * p), OB + "0")],
		ms([b * 1.1, b * 0.9]), {
		"tvm-fv-after-k": [solver(s.k, s.r, D(s.L), "−" + Fmt.money(s.pmt), "", s.c), "Solve for FV: FV = −%s; its size is what is still owed." % F(b), final_step(ans)],
		"gdc-bal-function": [solver(s.N, s.r, D(s.L), "−" + Fmt.money(s.pmt), "", s.c) + " Solve for FV, to store the loan.",
			"bal(%d) = −%s" % [s.k, F(b)], "The balance after %d payments is its size." % s.k, final_step(ans)],
	})


func u_first_interest(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var L: float = s.L.to_float()
	var p: float = s.pmt.to_float()
	var i1: Q = s.L.mul(s.r).div(1200)
	var year: Q = s.L.mul(s.r).div(100)
	var avg: float = (s.N * p - L) / s.N
	var line := "Interest for the first month: %s × %s ÷ 1200 = %s." % [D(s.L), D(s.r), Fmt.money(i1)]
	if s.side == "interest":
		var ans := CompoundInterestViews.money_ans("interest = $", i1.to_float())
		return pack([_owes(s)], "Find how much of the first payment is interest.", ans, [wrong({"v": year}, OB + "1"), wrong(cents(avg), OB + "2")],
			[{"v": i1.mul(2)}, {"v": i1.div(2)}], {"amortization-table": [line, "This month's interest is found from the whole loan, as nothing has been paid off yet.", final_step(ans)]})
	var pr: Q = s.pmt.sub(i1)
	var ans2 := CompoundInterestViews.money_ans("reduction = $", pr.to_float())
	return pack([_owes(s)], "Find how much the first payment reduces the amount owed.", ans2, [wrong({"v": s.pmt.sub(year)}, OB + "1"), wrong(cents(L / s.N), OB + "2")],
		[{"v": pr.mul(2)}, {"v": pr.div(2)}], {"amortization-table": [line, "The rest of the payment pays off the loan: %s − %s = %s." % [Fmt.money(s.pmt), Fmt.money(i1), Fmt.money(pr)], final_step(ans2)]})


func u_total_interest(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var paid: Q = s.pmt.mul(s.N)
	var ans := CompoundInterestViews.money_ans("interest = $", paid.sub(s.L).to_float())
	var simple: Q = s.L.mul(s.r).mul(s.n).div(100)
	return pack([_owes(s)], "Find the total interest paid over the %d years." % s.n, ans, [wrong({"v": paid}, TI + "0"), wrong({"v": simple}, TA + "12")],
		[{"v": paid.sub(s.L).mul(Q.new(11, 10))}], {
		"n-times-pmt": ["Total repaid: %d payments × %s = %s." % [s.N, Fmt.money(s.pmt), Fmt.money(paid)],
			"Interest = total repaid − loan = %s − %s = %s." % [Fmt.money(paid), D(s.L), Fmt.money(paid.sub(s.L))], final_step(ans)],
	})


func u_compare_loans(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var L: float = s.L.to_float()
	var pa := TvmSituation.payment(L, s.r.to_float() / 1200.0, 12 * s.n)
	var pb := TvmSituation.payment(L, s.rb.to_float() / 1200.0, 12 * s.nb)
	var ia: float = 12 * s.n * pa - L
	var ib: float = 12 * s.nb * pb - L
	var d := roundi(absf(ia - ib))
	var cheap: String = s.cheap
	var dear := "B" if cheap == "A" else "A"
	var gap := roundi(absf(pa - pb))
	var built := SamplingViews.claims("Loan %s, by $%d." % [cheap, d], [["Loan %s, by $%d." % [dear, d], TI + "1"],
		["Loan %s, by $%d." % [cheap, gap], TA + "15"], ["Loan %s, by $%d." % [cheap, 2 * d], ""], ["Loan %s, by $%d." % [dear, 2 * d], ""]])
	var lines: Array = ["%s needs to borrow %s and is offered two loans, each repaid monthly with interest compounded monthly." % [who(s), M(s.L)]]
	var table = null
	if rep == "table":
		table = {"rows": [["Loan", ["A", "B"]], ["Rate (% per year)", [D(s.r), D(s.rb)]], ["Term (years)", [str(s.n), str(s.nb)]]]}
	else:
		lines.append("Loan A: %s%% per year over %d years. Loan B: %s%% per year over %d years." % [D(s.r), s.n, D(s.rb), s.nb])
	var right := "Loan %s, by $%d." % [cheap, d]
	return pack(lines, "Which loan costs less in total interest, and by how much? Give the amount to the nearest dollar.", built.answer, built.wrongs, built.fillers, {
		"n-times-pmt": ["Loan A: PMT = %s (N = %d, I%% = %s, PV = %s, FV = 0), so the interest is %d × %s − %s = %s." % [F(pa), 12 * s.n, D(s.r), D(s.L), 12 * s.n, F(pa), D(s.L), F(ia)],
			"Loan B: PMT = %s (N = %d, I%% = %s, PV = %s, FV = 0), so the interest is %d × %s − %s = %s." % [F(pb), 12 * s.nb, D(s.rb), D(s.L), 12 * s.nb, F(pb), D(s.L), F(ib)],
			"The difference is %s, so loan %s costs about $%d less, though its monthly payment is higher." % [F(absf(ia - ib)), cheap, d], right],
	}, table)


# ── Savings ──────────────────────────────────────────────────

func _deposits(s: Dictionary) -> String:
	if s.P0.is_zero():
		return "%s deposits %s at the end of every month into a savings account that pays %s%% per year, compounded %s." % [who(s), M(s.D), D(s.r), freq(s.c)]
	return "%s opens a savings account with %s and deposits %s at the end of every month. The account pays %s%% per year, compounded %s." % [who(s), M(s.P0), M(s.D), D(s.r), freq(s.c)]


static func pv_text(p0: Q) -> String:
	return "0" if p0.is_zero() else "−" + D(p0)


func _fv_steps(s: Dictionary, fv: float, ans: Dictionary, extra: Array) -> Dictionary:
	var i := TvmSituation.i_of(s)
	var g := pow(1.0 + i, s.N)
	var series: Array = [monthly(s), "FV = P₀(1 + i)^N + D((1 + i)^N − 1) ÷ i, with P₀ = %s, D = %s and N = %d." % [D(s.P0), D(s.D), s.N],
		"(1 + i)^%d = %s, so FV = %s × %s + %s × %s ÷ %s = %s" % [s.N, "%.8f" % g, D(s.P0), "%.8f" % g, D(s.D), "%.8f" % (g - 1.0), I(i), F(fv)]]
	if s.P0.is_zero():
		series = [monthly(s), "Each deposit grows for a different number of months: FV = D((1 + i)^N − 1) ÷ i, with D = %s and N = %d." % [D(s.D), s.N],
			"(1 + i)^%d = %s, so FV = %s × %s ÷ %s = %s" % [s.N, "%.8f" % g, D(s.D), "%.8f" % (g - 1.0), I(i), F(fv)]]
	return {"tvm-savings": [solver(s.N, s.r, pv_text(s.P0), "−" + Fmt.money(s.D), "", s.c), "Solve for FV: FV = %s" % F(fv)] + extra + [final_step(ans)],
		"geometric-series": series + extra + [final_step(ans)]}


func u_savings_fv(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var i := TvmSituation.i_of(s)
	var p0: float = s.P0.to_float()
	var d: float = s.D.to_float()
	var fv := TvmSituation.saved(p0, i, d, s.N)
	var ans := money_ans("value = $", fv)
	var paid: float = p0 + s.N * d
	var wr: Array = [wrong(cents(paid), SA + "0")]
	if p0 == 0.0:
		wr.append(wrong(cents(s.N * d * pow(1.0 + s.r.to_float() / (100.0 * s.c), s.c * s.n)), SA + "1"))
	return pack([_deposits(s)], "Find the value of the account after %d years, to the nearest cent." % s.n, ans, wr, ms([fv * 1.1, fv * 0.9]), _fv_steps(s, fv, ans, []))


func u_savings_interest(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var i := TvmSituation.i_of(s)
	var p0: float = s.P0.to_float()
	var d: float = s.D.to_float()
	var fv := TvmSituation.saved(p0, i, d, s.N)
	var paid: float = p0 + s.N * d
	var ans := money_ans("interest = $", fv - paid)
	var wr: Array = [wrong(cents(fv), TN + "7")]
	if p0 > 0.0:
		wr.append(wrong(cents(fv - p0), TN + "8"))
	var paid_line := "Paid in: %s + %d × %s = %s, so the interest is %s − %s = %s." % [D(s.P0), s.N, D(s.D), D(TvmSituation.money(paid)), F(fv), D(TvmSituation.money(paid)), F(fv - paid)]
	var steps := _fv_steps(s, fv, ans, [paid_line])
	steps.erase("geometric-series")
	return pack([_deposits(s)], "Find the interest earned over the %d years, to the nearest cent." % s.n, ans, wr, ms([(fv - paid) * 1.2, (fv - paid) * 0.8]), steps)


func u_savings_deposit(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var i := TvmSituation.i_of(s)
	var p0: float = s.P0.to_float()
	var t: float = s.T.to_float()
	var d := TvmSituation.deposit_for(t, p0, i, s.N)
	var ans := money_ans("deposit = $", d)
	var lines: Array = ["%s wants %s in a savings account after %d years, and will deposit the same amount at the end of every month. The account pays %s%% per year, compounded %s." % [who(s), M(s.T), s.n, D(s.r), freq(s.c)]]
	if p0 > 0.0:
		lines.append("The account already holds %s." % M(s.P0))
	var wr: Array = [wrong(cents((t - p0) / s.N), SA + "0"), wrong(cents(TvmSituation.deposit_for(t, p0, i, s.n)), TN + "5")]
	var g := pow(1.0 + i, s.N)
	return pack(lines, "Find the monthly deposit needed, to the nearest cent.", ans, wr, ms([d * 1.1]), {
		"tvm-savings": [solver(s.N, s.r, pv_text(s.P0), "", D(s.T), s.c), "Solve for PMT: PMT = −%s, paid in each month." % F(d), final_step(ans)],
		"geometric-series": [monthly(s), "The deposits must make up %s − %s(1 + i)^%d, and D((1 + i)^N − 1) ÷ i is what deposits of D make." % [D(s.T), D(s.P0), s.N],
			"(1 + i)^%d = %s, so D = (%s − %s × %s) × %s ÷ %s = %s" % [s.N, "%.8f" % g, D(s.T), D(s.P0), "%.8f" % g, I(i), "%.8f" % (g - 1.0), F(d)], final_step(ans)],
	})


func u_savings_time(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.x
	var m := int(floorf(x))
	var ans := count_ans("months = ", m + 1)
	return pack([_deposits(s)], "Find the number of months until the account first holds more than %s." % M(s.T), ans, [wrong({"v": Q.new(m)}, TN + "6")],
		[{"v": Q.new(m + 2)}, {"v": Q.new(int(ceilf(x / 12.0)))}], {
		"tvm-savings": [solver(null, s.r, pv_text(s.P0), "−" + Fmt.money(s.D), D(s.T), 12), "Solve for N: N = %s months." % F(x),
			"After %d months the account holds a little less than %s, so round up to %d." % [m, M(s.T), m + 1], final_step(ans)],
	})


# ── Funds that pay out ───────────────────────────────────────

func u_payout_pv(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var i := TvmSituation.i_of(s)
	var w: float = s.W.to_float()
	var pv := TvmSituation.payment_inverse(w, i, s.N)
	var ans := money_ans("fund = $", pv)
	var wr: Array = [wrong(cents(s.N * w), PA + "0"), wrong(cents(TvmSituation.saved(0.0, i, w, s.N)), PA + "1")]
	var g := pow(1.0 + i, -s.N)
	return pack(["%s wants to withdraw %s at the end of every month for %d years from a fund that pays %s%% per year, compounded %s. The fund is then empty." % [who(s), M(s.W), s.n, D(s.r), freq(s.c)]],
		"Find the amount the fund must hold at the start, to the nearest cent.", ans, wr, ms([pv * 1.1]), {
		"tvm-payout": [solver(s.N, s.r, "", Fmt.money(s.W), "0", s.c), "Solve for PV: PV = −%s, paid into the fund at the start." % F(pv), final_step(ans)],
		"present-value-formula": [monthly(s), "PV = W(1 − (1 + i)^−N) ÷ i, with W = %s and N = %d." % [D(s.W), s.N],
			"(1 + i)^−%d = %s, so PV = %s × %s ÷ %s = %s" % [s.N, "%.8f" % g, D(s.W), "%.8f" % (1.0 - g), I(i), F(pv)], final_step(ans)],
	})


func _fund(s: Dictionary) -> String:
	return "A fund of %s pays %s%% per year, compounded monthly. %s withdraws %s from it at the end of every month." % [M(s.L), D(s.r), who(s), M(s.W)]


func u_payout_months(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.x
	var m := int(floorf(x))
	var ans := count_ans("withdrawals = ", m)
	var wr: Array = [wrong({"v": Q.new(m + 1)}, PA + "2"), wrong({"v": Q.new(int(floorf(s.L.to_float() / s.W.to_float())))}, TN + "9")]
	return pack([_fund(s)], "Find the number of full withdrawals the fund can pay.", ans, wr, [{"v": Q.new(m - 1)}, {"v": Q.new(m + 12)}], {
		"tvm-payout": [solver(null, s.r, "−" + D(s.L), Fmt.money(s.W), "0", 12), "Solve for N: N = %s." % F(x),
			"Only %d withdrawals are full: the fund runs short before the next, so round down." % m, final_step(ans)],
	})


func u_payout_balance(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var i := TvmSituation.i_of(s)
	var L: float = s.L.to_float()
	var w: float = s.W.to_float()
	var b := TvmSituation.balance(L, i, w, s.N)
	var ans := money_ans("balance = $", b)
	return pack([_fund(s)], "Find the amount left in the fund after %d years, to the nearest cent." % s.n, ans, [wrong(cents(L - s.N * w), TN + "9")],
		ms([b * 1.1, b * 0.9]), {
		"tvm-payout": [solver(s.N, s.r, "−" + D(s.L), Fmt.money(s.W), "", 12), "Solve for FV: FV = %s, still in the fund." % F(b), final_step(ans)],
	})


func u_payout_withdrawal(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var i := TvmSituation.i_of(s)
	var L: float = s.L.to_float()
	var w := TvmSituation.payment(L, i, s.N)
	var ans := money_ans("withdrawal = $", w)
	var wr: Array = [wrong(cents(L / s.N), TN + "9"), wrong(cents(TvmSituation.payment(L, i, s.n)), TN + "5")]
	var g := pow(1.0 + i, -s.N)
	return pack(["A fund of %s pays %s%% per year, compounded %s. %s wants to withdraw the same amount at the end of every month for %d years, leaving the fund empty." % [M(s.L), D(s.r), freq(s.c), who(s), s.n]],
		"Find the largest monthly withdrawal, to the nearest cent.", ans, wr, ms([w * 1.1]), {
		"tvm-payout": [solver(s.N, s.r, "−" + D(s.L), "", "0", s.c), "Solve for PMT: PMT = %s, received each month." % F(w), final_step(ans)],
		"present-value-formula": [monthly(s), "The fund is the value now of every withdrawal: %s = W(1 − (1 + i)^−N) ÷ i, with N = %d." % [D(s.L), s.N],
			"(1 + i)^−%d = %s, so W = %s × %s ÷ %s = %s" % [s.N, "%.8f" % g, D(s.L), I(i), "%.8f" % (1.0 - g), F(w)], final_step(ans)],
	})
