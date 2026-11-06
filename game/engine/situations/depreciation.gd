class_name DepreciationSituation
extends RefCounted
## The `depreciation` situation (curriculum/question-types.json): a thing bought at a price P
## that keeps a fixed fraction c of its value each year, month or quarter, so V = P × c^t. Values
## are floats, as a GDC computes them; money answers are whole dollars (a Q) and a rate or a time
## comes from a float root or logarithm, kept clear of a rounding edge. The SymPy checker
## (tools/check_answers.py) finds each one again with exact rationals.
##
## need.ask is the unknown, need.rep the representation:
##   value-after        P, r, n: the value after n years
##   total-loss         the same numbers: P − V
##   loss-in-year       the same numbers: V(n − 1) − V(n), the loss in year n alone
##   original-value     V(n) (or a table of three later years), r, n: the price P
##   find-rate          P, V(n), n: r to 3 s.f.
##   read-rate          c in V = P(c)^t, or a table from year 0: r, exactly
##   two-rate-value     r in the first year, r2 in each later year: the value after n years
##   shortfall          the value after n years less an account's S(1 + i/100)^n
##   years-below        P, r, a target: the least whole number of years to fall below it
##   years-fraction     r, a percentage of the price: the same, with no dollar target
##   years-from-periods a rate per month or quarter: the least whole number of years
##   least-periods      a rate per month or quarter: the least whole number of periods
##
## generate() returns a Dictionary:
##   paper, ask, rep, ctx, item   2; the unknown; who buys it; what is bought
##   p        Q, the price, whole dollars (found, not given, for original-value)
##   r, c     Q, the rate in per cent per period and the fraction kept, 1 − r/100
##   k        the periods in a year: 1, 4 or 12;  n  the years, or the year asked about
##   v        Q, the value given at year n (original-value, find-rate; whole dollars)
##   date     the year V = P(c)^t starts in (value-after in an equation)
##   t0       the first year of a table of later values (original-value)
##   r2, c2   the later rate and what it keeps (two-rate-value)
##   save, i  the account: the sum put in and the % a year it pays (shortfall)
##   target   a dollar target;  pct  a percentage of the price
##   x        the real solution, in periods;  least  the answer to a time
##
## The clean limits below are the numbers behind the catalogue's `clean` text. The SymPy
## checker holds its own copy and fails on any breach.

const TRIES := 8000
const WHO := 6
const ITEMS := 8
## A dollar answer's leftover fraction of a dollar is at least this far from 0.5.
const DOLLAR_EDGE := 0.15
## A rate is at least this far (a fraction of its last place) from a rounding edge.
const EDGE := 0.03
## A time's real solution is at least this far from a whole number.
const GAP := 0.15
const R_MIN := 5
const R_MAX := 30
const N_MIN := 3
const N_MAX := 10
## r × n stays below this, so that the straight-line slip is still a positive value.
const LINEAR_MAX := 90
const PCTS := [10, 20, 25, 30, 40, 50, 60]
## Rates per period, in tenths of a per cent.
const PER_MONTH := [5, 6, 7, 8, 9, 10, 12, 14, 15, 16, 18, 20, 25, 30]
const PER_QUARTER := [15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 75, 80]
const YEARS_MAX := 25
const VALUE_MAX := 1000000.0
const LOSS_MIN := 100.0


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "value-after")
	var rep: String = need.get("rep", "words")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep, "ctx": rng.int_in(0, WHO - 1), "item": rng.int_in(0, ITEMS - 1), "k": 1, "n": 0}
		var ok := false
		match ask:
			"value-after", "total-loss":
				ok = _forward(rng, s)
			"loss-in-year":
				ok = _year(rng, s)
			"original-value":
				ok = _original(rng, s)
			"find-rate":
				ok = _rate(rng, s)
			"read-rate":
				_price(rng, s)
				ok = true
			"two-rate-value":
				ok = _two(rng, s)
			"shortfall":
				ok = _short(rng, s)
			"years-below", "years-fraction":
				ok = _time(rng, s)
			"years-from-periods", "least-periods":
				ok = _periods(rng, s)
		if ok:
			return s
	return {}


## P × c^t
static func value(p: float, c: float, t: float) -> float:
	return p * pow(c, t)


## A money value that rounds to a dollar without doubt.
static func dollars_clear(x: float) -> bool:
	if not is_finite(x) or x <= 0.0 or x > VALUE_MAX:
		return false
	return absf(x - floorf(x) - 0.5) >= DOLLAR_EDGE


static func all_clear(xs: Array) -> bool:
	return xs.all(func(x): return dollars_clear(x))


## P and a whole rate. A multiple of 1000 keeps a table's first three values exact to the cent.
static func _price(rng: Seeded, s: Dictionary) -> void:
	s.p = Q.new(rng.int_in(4, 60) * 1000)
	s.r = Q.new(rng.int_in(R_MIN, R_MAX))
	s.c = Q.new(1).sub(s.r.div(Q.new(100)))


## The same draw for a value and for its total loss. r × n stays below LINEAR_MAX, so the slip of
## taking the same amount off each year still leaves a positive value.
static func _forward(rng: Seeded, s: Dictionary) -> bool:
	_price(rng, s)
	s.n = rng.int_in(N_MIN, N_MAX)
	s.date = 2081 + rng.int_in(0, 30)
	var r: float = s.r.to_float()
	if r * s.n > LINEAR_MAX:
		return false
	var p: float = s.p.to_float()
	var v := value(p, s.c.to_float(), s.n)
	var up := value(p, 1.0 + r / 100.0, s.n)
	var straight: float = p * (1.0 - s.n * r / 100.0)
	return all_clear([v, p - v, up, up - p]) and absf(v - straight) >= 1.0


## The loss in year n alone. n is at least 2: in year 1 it is r % of the price, and the slips agree.
static func _year(rng: Seeded, s: Dictionary) -> bool:
	_price(rng, s)
	s.n = rng.int_in(2, 8)
	var p: float = s.p.to_float()
	var c: float = s.c.to_float()
	var r: float = s.r.to_float()
	var a := value(p, c, s.n - 1)
	var b := value(p, c, s.n)
	return all_clear([a, b, a - b, p - b, b * r / 100.0])


## A round value at year n, and the price that led to it, which is found. In a table the value
## at year n and the next two are shown, exact to the cent.
static func _original(rng: Seeded, s: Dictionary) -> bool:
	var v := rng.int_in(2, 30) * 1000
	s.r = Q.new(rng.int_in(R_MIN, R_MAX))
	s.c = Q.new(1).sub(s.r.div(Q.new(100)))
	s.n = rng.int_in(2, 8)
	s.v = Q.new(v)
	var r: float = s.r.to_float()
	if r * s.n > LINEAR_MAX:
		return false
	var p := float(v) / pow(s.c.to_float(), s.n)
	if not dollars_clear(p):
		return false
	s.p = Q.new(roundi(p))
	var up := v * pow(1.0 + r / 100.0, s.n)
	return all_clear([up, v / (1.0 - s.n * r / 100.0), v * pow(s.c.to_float(), s.n)])


## The rate is any hundredth of a per cent, and is found from V as shown, in whole dollars.
static func _rate(rng: Seeded, s: Dictionary) -> bool:
	s.p = Q.new(rng.int_in(4, 60) * 1000)
	s.n = rng.int_in(N_MIN, N_MAX)
	var hidden := rng.int_in(R_MIN * 100, R_MAX * 100) / 100.0
	var v := value(s.p.to_float(), 1.0 - hidden / 100.0, s.n)
	if not dollars_clear(v):
		return false
	s.v = Q.new(roundi(v))
	var rates := [rate_of(s), kept(s), straight_rate(s), whole_rate(s)]
	var seen := {}
	for x in rates:
		if not Answer.rounds_clearly(x, EDGE):
			return false
		seen[Fmt.sf(x)] = true
	# A 3 s.f. answer that ends in 0 would read the same as its 2 s.f. trap.
	return seen.size() == rates.size() and not Fmt.sf(rates[0]).ends_with("0")


## The fraction kept each year, from V and P as shown.
static func root(s: Dictionary) -> float:
	return pow(s.v.to_float() / s.p.to_float(), 1.0 / s.n)


static func rate_of(s: Dictionary) -> float:
	return 100.0 * (1.0 - root(s))


## The slips: what is kept, the whole fall shared over the years, and the whole fall.
static func kept(s: Dictionary) -> float:
	return 100.0 * root(s)


static func whole_rate(s: Dictionary) -> float:
	return 100.0 * (1.0 - s.v.to_float() / s.p.to_float())


static func straight_rate(s: Dictionary) -> float:
	return whole_rate(s) / s.n


## One rate in the first year and a lower one in each later year.
static func _two(rng: Seeded, s: Dictionary) -> bool:
	s.p = Q.new(rng.int_in(4, 60) * 1000)
	s.r = Q.new(rng.int_in(10, R_MAX))
	s.r2 = Q.new(rng.int_in(R_MIN, int(s.r.to_float()) - 2))
	s.c = Q.new(1).sub(s.r.div(Q.new(100)))
	s.c2 = Q.new(1).sub(s.r2.div(Q.new(100)))
	s.n = rng.int_in(N_MIN, N_MAX)
	var p: float = s.p.to_float()
	var v := two_value(s)
	return all_clear([v, p - v, value(p, s.c2.to_float(), s.n), v * s.c2.to_float()])


static func two_value(s: Dictionary) -> float:
	return s.p.to_float() * s.c.to_float() * pow(s.c2.to_float(), s.n - 1)


## The value after n years, less an account that grew over the same years.
static func _short(rng: Seeded, s: Dictionary) -> bool:
	_price(rng, s)
	s.n = rng.int_in(N_MIN, N_MAX)
	s.save = Q.new(rng.int_in(2, 20) * 500)
	s.i = Q.new(rng.int_in(2, 8))
	var p: float = s.p.to_float()
	var v := value(p, s.c.to_float(), s.n)
	var a := account(s)
	var m := v - a
	var sv: float = s.save.to_float()
	return s.r.to_float() * s.n <= LINEAR_MAX and sv <= 0.7 * p and m >= LOSS_MIN and all_clear([v, a, m, p - a, v - sv])


static func account(s: Dictionary) -> float:
	return s.save.to_float() * pow(1.0 + s.i.to_float() / 100.0, s.n)


## The least whole number of years below a round target, or below a percentage of the price.
static func _time(rng: Seeded, s: Dictionary) -> bool:
	_price(rng, s)
	var p: float = s.p.to_float()
	var t: float
	if s.ask == "years-below":
		s.target = Q.new(rng.int_in(1, 48) * 500)
		t = s.target.to_float()
	else:
		s.pct = int(rng.pick(PCTS))
		s.target = s.p.mul(Q.new(s.pct, 100))
		t = s.target.to_float()
	if t < 0.15 * p or t > 0.8 * p:
		return false
	return _least(s, log(t / p) / log(s.c.to_float()), 1.0, 2, YEARS_MAX)


## The same with a rate per month or per quarter: a table of periods needs a multiple of 10000
## for its third value to be exact to the cent.
static func _periods(rng: Seeded, s: Dictionary) -> bool:
	s.k = 12 if rng.chance(0.5) else 4
	s.r = Q.new(int(rng.pick(PER_MONTH if s.k == 12 else PER_QUARTER)), 10)
	s.c = Q.new(1).sub(s.r.div(Q.new(100)))
	s.p = Q.new(rng.int_in(1, 6) * 10000) if s.rep == "table" else Q.new(rng.int_in(4, 60) * 1000)
	s.target = Q.new(rng.int_in(1, 48) * 500)
	var p: float = s.p.to_float()
	var t: float = s.target.to_float()
	if t < 0.2 * p or t > 0.8 * p:
		return false
	var x := log(t / p) / log(s.c.to_float())
	if s.ask == "years-from-periods":
		return _least(s, x, float(s.k), 2, YEARS_MAX)
	return _least(s, x, 1.0, 3, YEARS_MAX * 12)


## Sets the real solution and the whole answer, x ÷ per rounded up, if it is clear of a whole number.
static func _least(s: Dictionary, x: float, per: float, lo: int, hi: int) -> bool:
	var y := x / per
	var frac := y - floorf(y)
	if frac < GAP or frac > 1.0 - GAP:
		return false
	s.x = x
	s.least = int(ceilf(y))
	s.n = s.least
	return s.least >= lo and s.least <= hi


## The least whole years if the same amount came off each year: the straight-line slip. Exact,
## as a whole rate of a whole price against the target.
static func straight_years(s: Dictionary) -> int:
	var n := 1
	while not Q.new(1).sub(s.r.mul(Q.new(n, 100))).mul(s.p).lt(s.target):
		n += 1
	return n


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
