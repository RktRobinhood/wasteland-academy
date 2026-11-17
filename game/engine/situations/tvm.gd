class_name TvmSituation
extends RefCounted
## The `tvm` situation (curriculum/question-types.json): a loan, a savings plan or a fund with
## equal monthly payments at the end of each month (P/Y = 12), at a nominal annual rate r %
## compounded C/Y times a year, as the GDC's TVM solver takes them. For the AI SL 1.7 types
## t1-ai-amortization and t1-ai-annuity (FAL-999); it sits beside compound-interest, which has
## no payments. Every question is Paper 2: every AI paper allows a GDC.
##
## Values are floats, as a GDC computes them; money answers are whole cents and kept clear of
## the half-cent edge, and so is every slip offered beside them. The SymPy checker
## (tools/check_answers.py) finds each one again with exact rationals.
##
## need.ask is the unknown (see TvmViews). generate() returns a Dictionary:
##   paper, ask, ctx   always 2; the unknown; the story (an index into TvmViews.WHO)
##   r, c              the annual rate (Q, tenths) and the compounding periods a year (12, 4, 2)
##   L                 the amount borrowed, a fund, or an opening sum P0 (whole dollars, Q)
##   price, dep        a price and a deposit % where the loan follows a deposit (loan-payment)
##   n, N              the years and the monthly payments, N = 12n
##   pmt               the monthly payment as the question shows it, to the cent (Q)
##   k                 the payments made (balance-after)
##   D, W, T           a monthly deposit, a monthly withdrawal, a target (Q)
##   rb, nb            the second loan's rate and years (compare-loans)
##   side              "interest" or "principal" (first-interest); "A" or "B", the cheaper loan

const TRIES := 6000
const CENT_EDGE := 0.15
## A number of payments asked for is at least this far from a whole number.
const N_GAP := 0.1
const WHO := 6


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "loan-payment")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "ctx": rng.int_in(0, WHO - 1), "c": 12, "P0": Q.new(0)}
		if _draw(rng, s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"loan-payment":
			return _loan_payment(rng, s)
		"loan-term", "final-payment":
			return _loan_term(rng, s)
		"loan-rate":
			return _loan_rate(rng, s)
		"balance-after":
			return _balance_after(rng, s)
		"first-interest":
			return _first_interest(rng, s)
		"total-interest":
			return _total_interest(rng, s)
		"compare-loans":
			return _compare_loans(rng, s)
		"savings-fv", "savings-interest":
			return _savings_fv(rng, s)
		"savings-deposit":
			return _savings_deposit(rng, s)
		"savings-time":
			return _savings_time(rng, s)
		"payout-pv":
			return _payout_pv(rng, s)
		"payout-months":
			return _payout_months(rng, s)
		"payout-balance":
			return _payout_balance(rng, s)
		"payout-withdrawal":
			return _payout_withdrawal(rng, s)
	return false


# ── The solver's sums ────────────────────────────────────────

## The rate per month: (1 + r/(100 C/Y))^(C/Y ÷ 12) − 1.
static func rate(r: float, c: int) -> float:
	return pow(1.0 + r / (100.0 * c), c / 12.0) - 1.0


## The payment that clears pv over n periods at i a period: pv i ÷ (1 − (1 + i)^−n).
static func payment(pv: float, i: float, n: float) -> float:
	return pv * i / (1.0 - pow(1.0 + i, -n))


## What is owed (or held) after k payments of p: pv(1 + i)^k − p((1 + i)^k − 1) ÷ i.
static func balance(pv: float, i: float, p: float, k: float) -> float:
	var g := pow(1.0 + i, k)
	return pv * g - p * (g - 1.0) / i


## The value of an opening sum p0 and k deposits of d: p0(1 + i)^k + d((1 + i)^k − 1) ÷ i.
static func saved(p0: float, i: float, d: float, k: float) -> float:
	var g := pow(1.0 + i, k)
	return p0 * g + d * (g - 1.0) / i


## The real number of payments of p that clear pv: −ln(1 − pv i ÷ p) ÷ ln(1 + i).
static func periods(pv: float, i: float, p: float) -> float:
	return -log(1.0 - pv * i / p) / log(1.0 + i)


## The annual rate (compounded monthly) at which n payments of p clear pv, by halving.
static func solve_rate(pv: float, n: int, p: float) -> float:
	var lo := 1e-9
	var hi := 60.0
	for k in 200:
		var mid := (lo + hi) / 2.0
		if payment(pv, mid / 1200.0, n) < p:
			lo = mid
		else:
			hi = mid
	return (lo + hi) / 2.0


static func cents_clear(x: float) -> bool:
	if not is_finite(x) or x <= 0.0 or x > 5000000.0:
		return false
	var c := x * 100.0
	return absf(c - floorf(c) - 0.5) >= CENT_EDGE


static func money(x: float) -> Q:
	return CompoundInterestSituation.money(x)


## Every value clear of the half-cent edge, and no two the same to the cent.
static func all_clear(xs: Array) -> bool:
	var seen := {}
	for x in xs:
		if not cents_clear(x):
			return false
		var k := roundi(x * 100.0)
		if seen.has(k):
			return false
		seen[k] = true
	return true


static func i_of(s: Dictionary) -> float:
	return rate(s.r.to_float(), s.c)


static func _rate_and_term(rng: Seeded, s: Dictionary, lo: int, hi: int, compounding: Array) -> void:
	s.r = Q.new(rng.int_in(20, 95), 10)
	s.c = rng.pick(compounding)
	s.n = rng.int_in(lo, hi)
	s.N = 12 * s.n


# ── Loans ────────────────────────────────────────────────────

## A loan, after a deposit or not; the payment and its four slips (N the years, I% the monthly
## rate, simple interest, no interest) are clear of a cent edge and different.
static func _loan_payment(rng: Seeded, s: Dictionary) -> bool:
	_rate_and_term(rng, s, 2, 30, [12, 12, 4, 2])
	if rng.chance(0.4):
		s.price = Q.new(rng.int_in(16, 400) * 500)
		s.dep = rng.pick([10, 15, 20, 25])
		s.L = s.price.mul(Q.new(100 - s.dep, 100))
		if not s.L.is_int():
			return false
	else:
		s.L = Q.new(rng.int_in(6, 300) * 1000)
	var L: float = s.L.to_float()
	var i := i_of(s)
	var r: float = s.r.to_float()
	return all_clear(payment_slips(L, i, r, s.c, s.n))


## [the payment, N the years, I% the monthly rate, simple interest, no interest].
static func payment_slips(L: float, i: float, r: float, c: int, n: int) -> Array:
	var N := 12 * n
	return [payment(L, i, N), payment(L, i, n), payment(L, rate(r / 12.0, c), N), L * (1.0 + r * n / 100.0) / N, L / N]


## A loan with a whole-dollar payment a little above the payment for a round term, compounded
## monthly; the real number of payments is clear of a whole number.
static func _loan_term(rng: Seeded, s: Dictionary) -> bool:
	_rate_and_term(rng, s, 2, 25, [12])
	s.L = Q.new(rng.int_in(6, 300) * 1000)
	var L: float = s.L.to_float()
	var i := i_of(s)
	var step: int = rng.pick([5, 10, 25, 50])
	var p := ceilf(payment(L, i, s.N) * (1.0 + rng.int_in(2, 30) / 100.0) / step) * step
	var x := periods(L, i, p)
	if not is_finite(x) or x < 12.0 or x > 360.0:
		return false
	var f := x - floorf(x)
	if f < N_GAP or f > 1.0 - N_GAP:
		return false
	s.pmt = Q.new(int(p))
	s.x = x
	s.m = int(floorf(x))
	var left := balance(L, i, p, s.m)
	var last := left * (1.0 + i)
	return all_clear([left, last, f * p]) and last < p


## n monthly payments, to the cent, of a loan at a rate in tenths. The rate solved from the
## payment shown is clear of a 3 s.f. edge and reads as the rate drawn; so do its slips.
static func _loan_rate(rng: Seeded, s: Dictionary) -> bool:
	s.r = Q.new(rng.int_in(30, 99), 10)
	s.n = rng.int_in(2, 25)
	s.N = 12 * s.n
	s.L = Q.new(rng.int_in(6, 300) * 1000)
	var L: float = s.L.to_float()
	var p := payment(L, s.r.to_float() / 1200.0, s.N)
	if not cents_clear(p):
		return false
	s.pmt = money(p)
	var found := solve_rate(L, s.N, s.pmt.to_float())
	s.found = found
	var simple: float = (s.N * s.pmt.to_float() - L) / L / s.n * 100.0
	var texts := {}
	for x in [found, 12.0 * found, simple]:
		if not Answer.rounds_clearly(x, 0.04):
			return false
		texts[Fmt.sf(x)] = true
	return texts.size() == 3 and Fmt.sf(found) == Fmt.sf(s.r)


## The balance after k payments of the payment to the cent, and the slip (the loan less the
## payments made), each clear of a cent edge.
static func _balance_after(rng: Seeded, s: Dictionary) -> bool:
	_rate_and_term(rng, s, 3, 30, [12, 12, 4])
	s.L = Q.new(rng.int_in(6, 300) * 1000)
	var L: float = s.L.to_float()
	var i := i_of(s)
	var p := payment(L, i, s.N)
	if not cents_clear(p):
		return false
	s.pmt = money(p)
	s.k = rng.int_in(1, s.n - 1) * 12 if rng.chance(0.6) else rng.int_in(6, s.N - 6)
	var pm: float = s.pmt.to_float()
	var b := balance(L, i, pm, s.k)
	return all_clear([b, L - s.k * pm, s.k * pm]) and b > 0.0


## A loan of a multiple of 1200 at a rate in tenths, compounded monthly, so a month's interest is
## a whole number of cents. The slips (a year's interest, the interest shared equally) are clear.
static func _first_interest(rng: Seeded, s: Dictionary) -> bool:
	_rate_and_term(rng, s, 3, 30, [12])
	s.L = Q.new(rng.int_in(5, 250) * 1200)
	s.side = "interest" if rng.chance(0.55) else "principal"
	var L: float = s.L.to_float()
	var i := i_of(s)
	var p := payment(L, i, s.N)
	if not cents_clear(p):
		return false
	s.pmt = money(p)
	var pm: float = s.pmt.to_float()
	var i1: float = s.L.mul(s.r).div(1200).to_float()
	var avg: float = (s.N * pm - L) / s.N
	var year: float = s.L.mul(s.r).div(100).to_float()
	if s.side == "interest":
		return all_clear([avg, i1, year]) and absf(avg - i1) >= 1.0
	return pm - year > 1.0 and all_clear([pm - i1, pm - year, L / s.N]) and absf(L / s.N - (pm - i1)) >= 1.0


## The interest over the loan, from the payment to the cent: exact. The loan is a multiple of 100,
## so simple interest is exact cents too.
static func _total_interest(rng: Seeded, s: Dictionary) -> bool:
	_rate_and_term(rng, s, 2, 30, [12, 12, 4])
	s.L = Q.new(rng.int_in(60, 3000) * 100)
	var L: float = s.L.to_float()
	var p := payment(L, i_of(s), s.N)
	if not cents_clear(p):
		return false
	s.pmt = money(p)
	return s.pmt.mul(s.N).sub(s.L).sign() > 0


## Two loans of L compounded monthly: the shorter (higher payment) costs less interest, by at least
## 50 dollars, the same to the dollar from the payments to the cent, clear of the half-dollar edge.
static func _compare_loans(rng: Seeded, s: Dictionary) -> bool:
	s.L = Q.new(rng.int_in(5, 300) * 1000)
	var terms := [3, 4, 5, 6, 8, 10, 12, 15, 20, 25]
	var a: int = rng.int_in(0, terms.size() - 2)
	var b: int = rng.int_in(a + 1, terms.size() - 1)
	var short: int = terms[a]
	var long_: int = terms[b]
	var r_short := Q.new(rng.int_in(30, 95), 10)
	var r_long := r_short.add(Q.new(rng.int_in(-15, 10), 10))
	if r_long.to_float() < 2.0:
		return false
	var cheap_first := rng.chance(0.5)
	# Loan A is the first in the story; cheap_first puts the shorter loan first.
	s.r = r_short if cheap_first else r_long
	s.n = short if cheap_first else long_
	s.rb = r_long if cheap_first else r_short
	s.nb = long_ if cheap_first else short
	s.cheap = "A" if cheap_first else "B"
	var L: float = s.L.to_float()
	var ia: float = interest_of(L, s.r.to_float(), s.n)
	var ib: float = interest_of(L, s.rb.to_float(), s.nb)
	var d := absf(ia - ib)
	var pa := payment(L, s.r.to_float() / 1200.0, 12 * s.n)
	var pb := payment(L, s.rb.to_float() / 1200.0, 12 * s.nb)
	if (ia < ib) != cheap_first or d < 50.0 or not cents_clear(pa) or not cents_clear(pb):
		return false
	var f := d - floorf(d)
	if absf(f - 0.5) < 0.15:
		return false
	var dr := absf((12 * s.n * money(pa).to_float() - L) - (12 * s.nb * money(pb).to_float() - L))
	return roundi(dr) == roundi(d) and roundi(absf(pa - pb)) != roundi(d)


static func interest_of(L: float, r: float, n: int) -> float:
	return 12 * n * payment(L, r / 1200.0, 12 * n) - L


# ── Savings and funds ────────────────────────────────────────

## An opening sum (none half the time) and monthly deposits; the value, the interest and the slips
## (no interest, every deposit made at the start) are clear of a cent edge.
static func _savings_fv(rng: Seeded, s: Dictionary) -> bool:
	_rate_and_term(rng, s, 3, 30, [12, 12, 4])
	s.r = Q.new(rng.int_in(15, 70), 10)
	s.P0 = Q.new(0) if rng.chance(0.5) else Q.new(rng.int_in(1, 40) * 500)
	s.D = Q.new(rng.int_in(2, 60) * 25)
	var i := i_of(s)
	var p0: float = s.P0.to_float()
	var d: float = s.D.to_float()
	var fv := saved(p0, i, d, s.N)
	var paid: float = p0 + s.N * d
	var grown: float = s.N * d * pow(1.0 + s.r.to_float() / (100.0 * s.c), s.c * s.n)
	var xs: Array = [fv, fv - paid, paid, grown] if p0 == 0.0 else [fv, fv - paid, paid, fv - p0]
	return all_clear(xs) and fv - paid >= 1.0


## A target in thousands, with an opening sum or not: the monthly deposit and its slips (no
## interest, N the years) are clear of a cent edge.
static func _savings_deposit(rng: Seeded, s: Dictionary) -> bool:
	_rate_and_term(rng, s, 3, 30, [12, 12, 4])
	s.r = Q.new(rng.int_in(15, 70), 10)
	s.P0 = Q.new(0) if rng.chance(0.6) else Q.new(rng.int_in(1, 20) * 500)
	s.T = Q.new(rng.int_in(5, 400) * 1000)
	var i := i_of(s)
	var p0: float = s.P0.to_float()
	var t: float = s.T.to_float()
	var d := deposit_for(t, p0, i, s.N)
	var yrs := deposit_for(t, p0, i, s.n)
	return d > 5.0 and yrs > 0.0 and all_clear([d, (t - p0) / s.N, yrs])


## The deposit that takes p0 to t in k months: (t − p0(1 + i)^k) i ÷ ((1 + i)^k − 1).
static func deposit_for(t: float, p0: float, i: float, k: float) -> float:
	var g := pow(1.0 + i, k)
	return (t - p0 * g) * i / (g - 1.0)


## Monthly deposits towards a target: the real number of months is clear of a whole number.
static func _savings_time(rng: Seeded, s: Dictionary) -> bool:
	s.r = Q.new(rng.int_in(15, 70), 10)
	s.c = 12
	s.P0 = Q.new(0) if rng.chance(0.5) else Q.new(rng.int_in(1, 20) * 500)
	s.D = Q.new(rng.int_in(2, 60) * 25)
	var i := i_of(s)
	var p0: float = s.P0.to_float()
	var d: float = s.D.to_float()
	s.T = Q.new(int(roundf(saved(p0, i, d, rng.int_in(24, 300)) / 1000.0)) * 1000)
	var t: float = s.T.to_float()
	if t <= p0 + d:
		return false
	var x := months_to(t, p0, i, d)
	var f := x - floorf(x)
	s.x = x
	return x >= 12.0 and x <= 480.0 and f >= N_GAP and f <= 1.0 - N_GAP


## The real number of months for p0 and deposits of d to reach t.
static func months_to(t: float, p0: float, i: float, d: float) -> float:
	return log((t + d / i) / (p0 + d / i)) / log(1.0 + i)


## A monthly withdrawal for n years: the fund and its slips (no interest, the future value)
## are clear of a cent edge.
static func _payout_pv(rng: Seeded, s: Dictionary) -> bool:
	_rate_and_term(rng, s, 5, 30, [12, 12, 4])
	s.r = Q.new(rng.int_in(15, 70), 10)
	s.W = Q.new(rng.int_in(4, 100) * 50)
	var i := i_of(s)
	var w: float = s.W.to_float()
	var pv := payment_inverse(w, i, s.N)
	return all_clear([pv, s.N * w, saved(0.0, i, w, s.N)])


## The fund that pays w a month for k months: w(1 − (1 + i)^−k) ÷ i.
static func payment_inverse(w: float, i: float, k: float) -> float:
	return w * (1.0 - pow(1.0 + i, -k)) / i


## A fund and a monthly withdrawal more than a month's interest: the real number of withdrawals
## is clear of a whole number, and ignoring interest gives another count.
static func _payout_months(rng: Seeded, s: Dictionary) -> bool:
	s.r = Q.new(rng.int_in(15, 70), 10)
	s.c = 12
	s.L = Q.new(rng.int_in(10, 500) * 1000)
	var i := i_of(s)
	var L: float = s.L.to_float()
	s.W = Q.new(int(ceilf(L * i * (1.2 + rng.int_in(0, 30) / 10.0) / 50.0)) * 50)
	var w: float = s.W.to_float()
	if w <= L * i:
		return false
	var x := periods(L, i, w)
	var f := x - floorf(x)
	s.x = x
	return x >= 24.0 and x <= 600.0 and f >= N_GAP and f <= 1.0 - N_GAP and int(floorf(L / w)) != int(floorf(x))


## A fund drawn on for n years, with money left: the balance and the slip (no interest) are clear.
static func _payout_balance(rng: Seeded, s: Dictionary) -> bool:
	s.r = Q.new(rng.int_in(15, 70), 10)
	s.c = 12
	s.L = Q.new(rng.int_in(20, 500) * 1000)
	s.n = rng.int_in(2, 15)
	s.N = 12 * s.n
	var i := i_of(s)
	var L: float = s.L.to_float()
	var w_max := payment(L, i, s.N)
	s.W = Q.new(int(floorf(w_max * rng.int_in(30, 90) / 100.0 / 50.0)) * 50)
	var w: float = s.W.to_float()
	if w < 100.0:
		return false
	var b := balance(L, i, w, s.N)
	return b > 0.0 and L - s.N * w > 0.0 and all_clear([b, L - s.N * w])


## The largest monthly withdrawal for n years: it and its slips (no interest, N the years) clear.
static func _payout_withdrawal(rng: Seeded, s: Dictionary) -> bool:
	_rate_and_term(rng, s, 5, 30, [12, 12, 4])
	s.r = Q.new(rng.int_in(15, 70), 10)
	s.L = Q.new(rng.int_in(20, 800) * 1000)
	var i := i_of(s)
	var L: float = s.L.to_float()
	return all_clear([payment(L, i, s.N), L / s.N, payment(L, i, s.n)])


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
