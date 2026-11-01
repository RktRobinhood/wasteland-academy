class_name CompoundInterestSituation
extends RefCounted
## The `compound-interest` situation (curriculum/question-types.json): money invested at a
## nominal annual rate r %, compounded k times a year for n years (FAL-695). Values are
## floats, as a GDC computes them ((1 + r/100k)^kn overflows a Q); money answers are whole
## cents (a Q of cents / 100) and a rate or a number of years is found from a float root or
## logarithm, kept clear of a rounding edge. The SymPy checker (tools/check_answers.py)
## finds each one again with exact rationals.
##
## need.ask is the unknown:
##   future-value     PV, r, k, n: the value after n years, to the nearest cent
##   interest-earned  the same numbers: FV - PV
##   present-value    FV, r, k, n: the amount to invest now, to the nearest cent
##   interest-rate    PV, FV, k, n: r to 3 s.f.; r is a multiple of a quarter, so the 3 s.f.
##                    answer does not read like its own 2 s.f. trap
##   time-needed      PV, target, r, k: the least whole number of years to exceed the target
##   compare-options  two accounts (r, k) and (rb, kb) over the same n: A's value less B's
##
## generate() returns a Dictionary:
##   paper    2, or 1 for a future value or interest earned by formula (need.paper): annual
##            compounding at a round rate for 2 to 4 years on a round sum, exact by hand
##   ask, ctx the unknown; the story (an index into CompoundInterestViews.WHO)
##   pv, fv   Q, whole dollars where given; fv is the amount shown or the value found
##   r, rb    Q, the annual rates in per cent;  k, kb  compounding periods a year;  n  the years
##   target   the amount to reach (time-needed);  years  the answer to time-needed
##
## The clean limits below are the numbers behind the catalogue's `clean` text. The SymPy
## checker holds its own copy and fails on any breach.

const TRIES := 6000
## A money answer's leftover fraction of a cent is at least this far from 0.5.
const CENT_EDGE := 0.15
## A rate or a number of years is at least this far (a fraction of its last place) from an edge.
const EDGE := 0.03
## A time's real solution is at least this far from a whole number of years.
const YEAR_GAP := 0.15
const KS := [1, 2, 4, 12]
const N_MIN := 2
const N_MAX := 12
const N_TIME_MAX := 40
## The rate in tenths of a per cent, in steps of 0.5, and in quarters for a rate asked for.
const R_TENTHS := [15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80]
const R_QUARTERS := [175, 225, 275, 325, 375, 425, 475, 525, 575, 625, 675, 725]
const WHO := 6
## Paper 1: a round rate and a few years, annually, so the value is a whole number of cents by hand.
const P1_PAIRS := [[10, 2], [10, 3], [10, 4], [20, 2], [20, 3], [5, 2], [50, 2], [25, 2]]
const P1_PVS := [1000, 2000, 4000, 5000, 8000, 10000]
const FV_MAX := 100000.0
const DIFF_MIN := 20.0


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "future-value")
	var paper: int = need.get("paper", 2)
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "ctx": rng.int_in(0, WHO - 1), "k": 1, "n": 0}
		var ok := false
		match ask:
			"future-value", "interest-earned":
				ok = _forward_p1(rng, s) if paper == 1 else _forward(rng, s)
			"present-value":
				ok = _backward(rng, s)
			"interest-rate":
				ok = _rate(rng, s)
			"time-needed":
				ok = _time(rng, s)
			"compare-options":
				ok = _compare(rng, s)
		if ok:
			return s
	return {}


static func _pick_r(rng: Seeded, list: Array, scale: int) -> Q:
	return Q.new(int(list[rng.int_in(0, list.size() - 1)]), scale)


static func _pick_k(rng: Seeded) -> int:
	return int(KS[rng.int_in(0, KS.size() - 1)])


## PV(1 + r/100k)^kn
static func value(pv: float, r: float, k: int, n: int) -> float:
	return pv * pow(1.0 + r / (100.0 * k), k * n)


## A money value that rounds to a cent without doubt: the fraction of a cent it is left with is
## at least CENT_EDGE from 0.5, the edge between rounding down and rounding up. (An exact
## whole number of cents, as simple interest on a round sum is, is at the far end of that.)
static func cents_clear(x: float) -> bool:
	if not is_finite(x) or x <= 0.0 or x > FV_MAX:
		return false
	var c := x * 100.0
	return absf(c - floorf(c) - 0.5) >= CENT_EDGE


## x as whole cents, a Q.
static func money(x: float) -> Q:
	return Q.new(roundi(x * 100.0), 100)


static func _forward(rng: Seeded, s: Dictionary) -> bool:
	s.pv = Q.new(rng.int_in(2, 40) * 500)
	s.r = _pick_r(rng, R_TENTHS, 10)
	s.k = _pick_k(rng)
	s.n = rng.int_in(N_MIN, N_MAX)
	var pv: float = s.pv.to_float()
	var r: float = s.r.to_float()
	var fv := value(pv, r, s.k, s.n)
	# The slips, each offered as an option, so each is clear too: the annual rate over kn periods,
	# and simple interest.
	return cents_clear(fv) and cents_clear(fv - pv) and cents_clear(value(pv, r, 1, s.k * s.n)) and cents_clear(pv * (1.0 + s.n * r / 100.0)) \
			and absf(fv - pv * (1.0 + s.n * r / 100.0)) >= 1.0 and absf(fv - value(pv, r, 1, s.k * s.n)) >= 1.0


## Paper 1: PV on a round sum, r a round rate, compounded annually for a few years. Every value is
## an exact number of cents; simple interest and the total for the interest differ from the answer.
static func _forward_p1(rng: Seeded, s: Dictionary) -> bool:
	var pair: Array = P1_PAIRS[rng.int_in(0, P1_PAIRS.size() - 1)]
	s.pv = Q.new(int(P1_PVS[rng.int_in(0, P1_PVS.size() - 1)]))
	s.r = Q.new(int(pair[0]))
	s.k = 1
	s.n = int(pair[1])
	var pv: float = s.pv.to_float()
	var r: float = s.r.to_float()
	var fv := value(pv, r, 1, s.n)
	var simple: float = pv * (1.0 + s.n * r / 100.0)
	return cents_clear(fv) and cents_clear(fv - pv) and cents_clear(simple) and absf(fv - simple) >= 1.0


## FV is a round number and PV is what to invest now.
static func _backward(rng: Seeded, s: Dictionary) -> bool:
	s.fv = Q.new(rng.int_in(4, 100) * 500)
	s.r = _pick_r(rng, R_TENTHS, 10)
	s.k = _pick_k(rng)
	s.n = rng.int_in(N_MIN, N_MAX)
	var f: float = s.fv.to_float()
	var r: float = s.r.to_float()
	var pv := f / pow(1.0 + r / (100.0 * s.k), s.k * s.n)
	var grown := f * pow(1.0 + r / (100.0 * s.k), s.k * s.n)
	return cents_clear(pv) and pv >= 500.0 and cents_clear(grown) and cents_clear(f / pow(1.0 + r / 100.0, s.k * s.n)) \
			and cents_clear(f / (1.0 + s.n * r / 100.0))


## r is a multiple of a quarter; FV is its value to the cent. The rate found from the shown
## numbers is the answer, and must be clear of a 3 s.f. rounding edge.
static func _rate(rng: Seeded, s: Dictionary) -> bool:
	s.pv = Q.new(rng.int_in(2, 40) * 500)
	s.r = _pick_r(rng, R_QUARTERS, 100)
	s.k = _pick_k(rng)
	s.n = rng.int_in(N_MIN, N_MAX)
	var pv: float = s.pv.to_float()
	var fv_exact := value(pv, s.r.to_float(), s.k, s.n)
	if not cents_clear(fv_exact):
		return false
	s.fv = money(fv_exact)
	var found := rate_of(s)
	# A quarter is on the edge of its own 2 s.f. rounding (7.25 is 7.2 or 7.3), so the rate found
	# from the shown FV, which is a hair off the quarter, decides the trap's side: clear of noise.
	return Answer.rounds_clearly(found, EDGE) and absf(found - s.r.to_float()) >= 1e-6 \
			and Fmt.sf(Q.new(roundi(found * 1000000.0), 1000000)) == Fmt.sf(s.r) and slip_clear(s)


## The rate from PV, FV, k and n as shown: 100k((FV/PV)^(1/kn) - 1).
static func rate_of(s: Dictionary) -> float:
	var ratio: float = s.fv.to_float() / s.pv.to_float()
	return 100.0 * s.k * (pow(ratio, 1.0 / (s.k * s.n)) - 1.0)


## The root without the 1 taken off and the 100 put on, and the total growth shared over n years.
static func slip_root(s: Dictionary) -> float:
	return pow(s.fv.to_float() / s.pv.to_float(), 1.0 / (s.k * s.n))


static func slip_share(s: Dictionary) -> float:
	return (s.fv.to_float() / s.pv.to_float() - 1.0) * 100.0 / s.n


static func slip_clear(s: Dictionary) -> bool:
	var a := slip_root(s)
	var b := slip_share(s)
	var r := rate_of(s)
	return Answer.rounds_clearly(a, EDGE) and Answer.rounds_clearly(b, EDGE) and Fmt.sf(a) != Fmt.sf(r) and Fmt.sf(b) != Fmt.sf(r) and Fmt.sf(a) != Fmt.sf(b)


## The least whole number of years that takes PV past a round target.
static func _time(rng: Seeded, s: Dictionary) -> bool:
	s.pv = Q.new(rng.int_in(2, 40) * 500)
	s.r = _pick_r(rng, R_TENTHS, 10)
	s.k = _pick_k(rng)
	var pv: float = s.pv.to_float()
	var target := int(round(pv * (1.3 + rng.int_in(0, 17) / 10.0) / 500.0)) * 500
	if target <= pv * 1.2:
		return false
	s.target = Q.new(target)
	var x := years_real(pv, target, s.r.to_float(), s.k)
	var frac := x - floorf(x)
	if frac < YEAR_GAP or frac > 1.0 - YEAR_GAP:
		return false
	s.years = int(ceilf(x))
	s.n = s.years
	return s.years >= 3 and s.years <= N_TIME_MAX


## The real number of years: ln(target/PV) / (k ln(1 + r/100k)).
static func years_real(pv: float, target: float, r: float, k: int) -> float:
	return log(target / pv) / (k * log(1.0 + r / (100.0 * k)))


## Two accounts over the same n: A is worth more, by at least DIFF_MIN, and the difference in
## cents is the same whether the two values are rounded first or not.
static func _compare(rng: Seeded, s: Dictionary) -> bool:
	s.pv = Q.new(rng.int_in(1, 20) * 1000)
	s.r = _pick_r(rng, R_TENTHS, 10)
	s.rb = _pick_r(rng, R_TENTHS, 10)
	s.k = _pick_k(rng)
	s.kb = _pick_k(rng)
	s.n = rng.int_in(3, 15)
	if s.r.eq(s.rb) and s.k == s.kb:
		return false
	var pv: float = s.pv.to_float()
	var a := value(pv, s.r.to_float(), s.k, s.n)
	var b := value(pv, s.rb.to_float(), s.kb, s.n)
	var d := a - b
	if d < DIFF_MIN or not cents_clear(a) or not cents_clear(b) or not cents_clear(d):
		return false
	if roundi(a * 100.0) - roundi(b * 100.0) != roundi(d * 100.0):
		return false
	# The slip: compounding both once a year.
	var a1 := value(pv, s.r.to_float(), 1, s.n)
	var b1 := value(pv, s.rb.to_float(), 1, s.n)
	return cents_clear(a1 - b1) and a1 - b1 >= 1.0 and absf(a1 - b1 - d) >= 1.0


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
