class_name GeometricContextSituation
extends RefCounted
## The `geometric-context` situation (curriculum/question-types.json): a story that a geometric
## sequence models, with a percentage change or a rebound as its multiplier (FAL-752). It uses
## GeometricSequenceSituation's power(), but its own numbers: Paper 2 powers run far enough that
## an exact Q would overflow, so a value there is a float, as a GDC computes it.
##
## need.ask is the unknown:
##   factor-from-percent   r from a percentage rise or fall (Paper 1)
##   value-after-years     start × r^t, from a value "today"
##   value-in-round        u₁ × r^(n − 1), from a value "in round 1"
##   term-number-after     which term is the value after t rounds, when u₁ is the start (Paper 1)
##   rebound-height        h × r^k after the kth bounce
##   nth-expression        uₙ as an expression in n
##   total-over-rounds     Sₙ with a percentage change
##   total-two-deals       the gap between a flat total and a rising one
##   overtake-first-round  the first round a geometric model passes an arithmetic one
##   scaled-area-term      the area of the nth rectangle, each side scaled by k (Paper 1)
##   mean-of-areas         the mean of those areas, as p(b^a − 1) (Paper 1)
##   least-n-term          the least n for uₙ past a target
##   least-rounds-after    the least whole t for start × r^t past a target, up or down
##   least-n-sum           the least n for Sₙ past a target
##   least-n-two-terms     the same, with r to find from u₁ and a later term
##   first-below           the least n for uₙ below a small value
##   gap-to-limit          the least n for S∞ − Sₙ below a small value
##   count-terms-power     how many terms, when the last is u₁ times an exact power of r
##
## generate() returns a Dictionary:
##   paper, ask, rep, ctx (an index into the story list the unknown uses)
##   sign, p, r   the direction, the percentage and the multiplier (Q)
##   frac         false where Paper 1 writes r as a decimal
##   u1, start    the first term, or the value today (Q);  t, n, k   rounds, a term, a bounce
##   h, hu        a drop height and its unit
##   a, d, b      overtake: A's first value and step, B's first value;  x  the crossing;
##                before_a, before_b, after_a, after_b  both models at n − 1 and n
##   v            the answer where it's a value;  word  doubles, triples or halves
##   total_b, listed  a deal's rising total;  the total of the amounts listed to 2 d.p.
##   target       what is to be passed (Q);  n  the answer of a find-n, with x its real crossing,
##                before, after  the value at n − 1 and at n
##   m, um, r_q   a later term given (u_m), and r^(m − 1)
##   wrong_r, slip_n, arith_n, other_n  what a slip's n would be (0 if it has none)
##   c, sinf, form  the Σ's coefficient, S∞, and "sigma" where the sum is shown as a Σ
##   last, total  count: the last term and r^(n − 1)
##   w, ht, kq, area, b2, parts, p_q  the rectangles: sides, side factor, u₁, r, how many, the mean's p
##
## The clean limits are the numbers behind the catalogue's `clean` text. The SymPy checker
## (tools/check_answers.py) holds its own copy and fails on any breach.

const TRIES := 4000
const RISES := [3, 4, 5, 6, 8, 10, 12, 15, 20, 25]
const FALLS := [5, 8, 10, 12, 15, 20, 25, 30, 40]
## A percentage for Paper 1.
const HAND := [10, 20, 50]
## A graph has few dots, so its change is large.
const STEEP_RISES := [20, 25, 30, 40, 50]
const STEEP_FALLS := [20, 25, 30, 40, 50]
## Falls with 1 − r a short decimal, so that S∞ ends.
const GAP_FALLS := [5, 10, 20, 25, 40, 50]
const SMALL := ["0.5", "0.1", "0.05", "0.02", "0.01", "0.005", "0.002", "0.001"]
const BOUNCE_P1 := [[1, 2], [2, 3], [3, 4], [3, 5], [4, 5]]
const BOUNCE_P2 := [55, 60, 65, 70, 75, 80, 85]
const PLAIN_P1 := [[2, 1], [3, 1], [3, 2], [1, 2]]
const SIDE_FACTORS := [[3, 2], [2, 1], [5, 4], [3, 1], [6, 5], [4, 3]]
const TWO_TERM_R := [105, 110, 120, 125, 130, 140, 150]
const DEAL_ROUNDS := [12, 18, 24, 30, 36, 40]
const EDGE := 0.02
## How far a crossing keeps from a whole number, so a whole n is not in doubt.
const CLEAR := 0.1
const LIMIT := 5000000.0
const P1_LIMIT := 200000
const N_MAX := 60

## A value today. thing, subj: what changes; round: the time step; head: a table's heading.
const STOCKS := [
	{"now": "Glow-moss covers %s m² of a bunker wall today.", "thing": "area of moss", "subj": "The area", "unit": " m²", "round": "month", "head": "Area (m²)", "sign": 1},
	{"now": "The Guild's vault holds %s kg of silver today.", "thing": "mass of silver", "subj": "The mass", "unit": " kg", "round": "year", "head": "Mass (kg)", "sign": 1},
	{"now": "A vat holds %s litres of algae oil today.", "thing": "volume of algae oil", "subj": "The volume", "unit": " litres", "round": "week", "head": "Volume (litres)", "sign": 1},
	{"now": "A scrap heap weighs %s kg today.", "thing": "mass of the heap", "subj": "The mass", "unit": " kg", "round": "year", "head": "Mass (kg)", "sign": 1},
	{"now": "A leaking tank holds %s litres of fuel today.", "thing": "volume of fuel", "subj": "The volume", "unit": " litres", "round": "day", "head": "Volume (litres)", "sign": -1},
	{"now": "The reading at a crater is %s mSv today.", "thing": "reading", "subj": "The reading", "unit": " mSv", "round": "year", "head": "Reading (mSv)", "sign": -1},
	{"now": "A battery bank holds %s kWh today.", "thing": "charge", "subj": "The charge", "unit": " kWh", "round": "day", "head": "Charge (kWh)", "sign": -1},
	{"now": "A silo holds %s kg of grain today.", "thing": "mass of grain", "subj": "The mass", "unit": " kg", "round": "week", "head": "Mass (kg)", "sign": -1},
]
## An amount for each round, from round 1. total: the amounts added up.
const FLOWS := [
	{"first": "A rooftop farm yields %s kg of beans in its first season.", "thing": "yield", "subj": "The yield", "unit": " kg", "round": "season", "head": "Yield (kg)", "total": "total yield", "at": "in", "sign": 1},
	{"first": "A salvage crew hauls %s kg of scrap in its first month.", "thing": "haul", "subj": "The haul", "unit": " kg", "round": "month", "head": "Haul (kg)", "total": "total haul", "at": "in", "sign": 1},
	{"first": "A guard is paid %s tokens in her first year.", "thing": "pay", "subj": "Her pay", "unit": " tokens", "round": "year", "head": "Pay (tokens)", "total": "total pay", "at": "in", "sign": 1},
	{"first": "A copper mine sends out %s kg in its first year.", "thing": "output", "subj": "The output", "unit": " kg", "round": "year", "head": "Output (kg)", "total": "total output", "at": "in", "sign": 1},
	{"first": "A spring gives %s litres of water in its first week.", "thing": "flow", "subj": "The flow", "unit": " litres", "round": "week", "head": "Flow (litres)", "total": "total flow", "at": "in", "sign": -1},
	{"first": "A dig site gives up %s kg of scrap in its first month.", "thing": "find", "subj": "The find", "unit": " kg", "round": "month", "head": "Find (kg)", "total": "total find", "at": "in", "sign": -1},
	{"first": "A solar rig stores %s kWh on its first day.", "thing": "charge stored", "subj": "The charge stored", "unit": " kWh", "round": "day", "head": "Charge stored (kWh)", "total": "total charge stored", "at": "on", "sign": -1},
	{"first": "A trade route brings in %s tokens in its first year.", "thing": "income", "subj": "The income", "unit": " tokens", "round": "year", "head": "Income (tokens)", "total": "total income", "at": "in", "sign": -1},
]
## Things dropped, for a rebound.
const BALLS := ["rubber ball", "steel spring", "scrap tyre", "drone shell"]
## Two ways of being paid. who: the opening; round: the time step; unit: the amount.
const DEALS := [
	{"who": "A scavenger signs on for %d months, paid once a month, and may pick one of two deals.", "round": "month", "unit": " tokens", "head": "tokens", "pay": "payment"},
	{"who": "A settler takes a water ration for %d weeks, once a week, and may pick one of two deals.", "round": "week", "unit": " litres", "head": "litres", "pay": "ration"},
	{"who": "A caravan buys fuel on contract for %d months, with a delivery each month, and may pick one of two deals.", "round": "month", "unit": " litres", "head": "litres", "pay": "delivery"},
	{"who": "A bazaar trader rents a stall out for %d weeks, for one payment a week, and may pick one of two deals.", "round": "week", "unit": " scrap", "head": "scrap", "pay": "payment"},
]
## Two rivals, one growing by steps and one by a percentage.
const RIVALS := [
	{"a": "Yard A", "b": "Yard B", "verb": "turns out", "unit": " kg", "round": "year", "head": "Output (kg)"},
	{"a": "Well A", "b": "Well B", "verb": "gives", "unit": " litres", "round": "month", "head": "Water (litres)"},
	{"a": "Stall A", "b": "Stall B", "verb": "takes", "unit": " tokens", "round": "week", "head": "Takings (tokens)"},
	{"a": "Farm A", "b": "Farm B", "verb": "grows", "unit": " kg", "round": "season", "head": "Crop (kg)"},
]
## A set of rectangles, each with its sides scaled from the last.
const SHEETS := [
	{"maker": "A workshop cuts %d rectangular armour plates, numbered %s to %s.", "L": "P", "item": "plate", "items": "plates"},
	{"maker": "A rigger stitches %d rectangular tarpaulins, numbered %s to %s.", "L": "T", "item": "tarpaulin", "items": "tarpaulins"},
	{"maker": "A signal crew paints %d rectangular flags, numbered %s to %s.", "L": "F", "item": "flag", "items": "flags"},
	{"maker": "A glazier cuts %d rectangular solar panels, numbered %s to %s.", "L": "S", "item": "panel", "items": "panels"},
]
## A count that multiplies each round, up to a last round.
const SPREADS := [
	{"open": "In round 1, %s scouts hear a warning.", "next": "In each round after that, %d times as many scouts hear it as in the round before.", "end": "In the last round, %s scouts hear it.", "ask": "How many rounds are there?", "unit": "rounds"},
	{"open": "A spore patch has %s spores on day 1.", "next": "Each day after that it has %d times as many as the day before.", "end": "On the last day of the count it has %s spores.", "ask": "How many days does the count last?", "unit": "days"},
	{"open": "On the first level of a shaft, a crew finds %s scrap coils.", "next": "On each deeper level it finds %d times as many as on the level before.", "end": "On the lowest level it finds %s coils.", "ask": "How many levels does the shaft have?", "unit": "levels"},
	{"open": "A trader's first shipment is %s cans.", "next": "Each shipment after that is %d times the one before.", "end": "The last shipment is %s cans.", "ask": "How many shipments are there?", "unit": "shipments"},
]

const P1_ONLY := ["factor-from-percent", "term-number-after", "scaled-area-term", "mean-of-areas"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "value-after-years")
	var rep: String = need.get("rep", "words")
	var paper: int = need.get("paper", 0)
	if paper == 0:
		paper = 1 if ask in P1_ONLY else 2
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep}
		if _draw(rng, s):
			return s
	push_error("GeometricContextSituation: no clean situation for %s" % need)
	return {}


# ── Helpers ──────────────────────────────────────────────────

static func term(u1: float, r: float, k: int) -> float:
	return u1 * pow(r, k - 1)


static func sum(u1: float, r: float, k: float) -> float:
	return u1 * (pow(r, k) - 1.0) / (r - 1.0)


## x to n significant figures, as an exact Q: a target as a question writes it.
static func fig(x: float, n: int = 2) -> Q:
	return Answer.parse_number(Fmt.sf(x, n).replace("−", "-")).q


static func _in_list(rng: Seeded, list: Array, sign: int) -> int:
	var ids: Array = []
	for i in list.size():
		if list[i].sign == sign:
			ids.append(i)
	return rng.pick(ids)


static func _rate(rng: Seeded, s: Dictionary, sign: int, rates: Array) -> void:
	s.sign = sign
	s.p = rng.pick(rates)
	s.r = Q.new(100 + sign * s.p, 100)


## Paper 1: a percentage whose powers a hand can do, written as a decimal.
static func _by_hand(rng: Seeded, s: Dictionary) -> void:
	s.p = rng.pick(HAND)
	s.r = Q.new(100 + s.sign * s.p, 100)
	s.frac = false


static func _clear(x: float) -> bool:
	return absf(x) <= LIMIT and Answer.rounds_clearly(x, EDGE)


static func _stock(rng: Seeded, s: Dictionary, sign: int) -> void:
	s.ctx = _in_list(rng, STOCKS, sign)
	_rate(rng, s, sign, RISES if sign > 0 else FALLS)
	s.start = Q.new(rng.int_in(2, 60) * 50)


static func _flow(rng: Seeded, s: Dictionary, sign: int, rates: Array = []) -> void:
	s.ctx = _in_list(rng, FLOWS, sign)
	var list: Array = rates if not rates.is_empty() else (RISES if sign > 0 else FALLS)
	_rate(rng, s, sign, list)
	s.u1 = Q.new(rng.int_in(2, 50) * 10)


## n is the first whole number past the crossing x, with x well clear of a whole number.
static func _crossing(s: Dictionary, x: float, low: int, high: int) -> bool:
	var f: float = x - floorf(x)
	if f < CLEAR or f > 1.0 - CLEAR:
		return false
	s.x = x
	s.n = ceili(x)
	return s.n >= low and s.n <= high


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"factor-from-percent":
			_stock(rng, s, rng.pick([1, -1]))
			return true
		"value-after-years":
			_stock(rng, s, rng.pick([1, -1]))
			if s.paper == 1:
				_by_hand(rng, s)
				s.start = Q.new(rng.int_in(1, 9) * 1000)
				s.t = 3  # The table shows 2 steps on, so asking for that would give the answer.
				s.v = s.start.mul(GeometricSequenceSituation.power(s.r, s.t))
				return true
			s.t = rng.int_in(4, 8)
			s.v = s.start.to_float() * pow(s.r.to_float(), s.t)
			return _clear(s.v)
		"value-in-round":
			_flow(rng, s, rng.pick([1, -1]))
			if s.paper == 1:
				_by_hand(rng, s)
				s.u1 = Q.new(rng.int_in(1, 9) * 1000)
				s.n = 4  # The table shows rounds 1 to 3, so asking for those would give the answer.
				s.v = s.u1.mul(GeometricSequenceSituation.power(s.r, s.n - 1))
				return true
			s.n = rng.int_in(5, 9)
			s.v = term(s.u1.to_float(), s.r.to_float(), s.n)
			return _clear(s.v)
		"term-number-after":
			_stock(rng, s, rng.pick([1, -1]))
			s.t = rng.int_in(4, 15)
			return true
		"rebound-height":
			return _rebound(rng, s)
		"nth-expression":
			return _expression(rng, s)
		"total-over-rounds":
			return _total(rng, s)
		"total-two-deals":
			return _deals(rng, s)
		"overtake-first-round":
			return _overtake(rng, s)
		"scaled-area-term", "mean-of-areas":
			return _sheets(rng, s)
		"least-n-term":
			return _least_term(rng, s)
		"least-rounds-after":
			return _least_after(rng, s)
		"least-n-sum":
			return _least_sum(rng, s)
		"least-n-two-terms":
			return _two_terms(rng, s)
		"first-below":
			return _first_below(rng, s)
		"gap-to-limit":
			return _gap(rng, s)
		"count-terms-power":
			return _count(rng, s)
	push_error("GeometricContextSituation: no draw for %s" % s.ask)
	return false


static func _rebound(rng: Seeded, s: Dictionary) -> bool:
	s.ctx = rng.int_in(0, BALLS.size() - 1)
	if s.paper == 1:
		var pair: Array = rng.pick(BOUNCE_P1)
		s.r = Q.new(pair[0], pair[1])
		s.k = rng.int_in(3, 4)
		s.h = Q.new(int(pow(float(pair[1]), s.k)) * rng.int_in(1, 4))
		s.hu = " cm"
		s.v = s.h.mul(GeometricSequenceSituation.power(s.r, s.k))
		return s.h.to_float() >= 40.0 and s.h.to_float() <= 1000.0
	s.r = Q.new(rng.pick(BOUNCE_P2), 100)
	s.k = rng.int_in(4, 8)
	s.h = Q.new(rng.int_in(4, 40), 2)
	s.hu = " m"
	s.v = s.h.to_float() * pow(s.r.to_float(), s.k)
	return _clear(s.v)


## Doubling, tripling and halving come on both papers; a percentage needs a calculator's power
## only on Paper 2, but uₙ is left as an expression either way.
static func _expression(rng: Seeded, s: Dictionary) -> bool:
	var sign: int = rng.pick([1, 1, -1])
	_flow(rng, s, sign)
	s.word = ""
	if s.paper == 1 or rng.chance(0.3):
		var pair: Array = rng.pick(PLAIN_P1)
		s.r = Q.new(pair[0], pair[1])
		if s.r.to_float() < 1.0:
			if sign > 0:
				return false
			s.word = "halves"
			s.p = 50
		elif sign < 0:
			return false
		elif s.r.eq(2):
			s.word = "doubles"
		elif s.r.eq(3):
			s.word = "triples"
		else:
			s.p = 50
	s.u1 = Q.new(rng.int_in(1, 20) * 100)
	return true


static func _total(rng: Seeded, s: Dictionary) -> bool:
	var sign: int = rng.pick([1, -1])
	_flow(rng, s, sign)
	s.u1 = Q.new(rng.int_in(10, 90) * 10)
	s.n = rng.int_in(5, 9)
	var r: float = s.r.to_float()
	s.v = s.u1.to_float() * (1.0 - pow(r, s.n)) / (1.0 - r)
	# The amounts listed to 2 d.p. add up to the same 3 s.f. answer.
	var listed := 0.0
	for i in range(1, s.n + 1):
		var amount := term(s.u1.to_float(), r, i)
		if absf(fposmod(amount * 100.0, 1.0) - 0.5) < 0.001:
			return false  # A tie to 2 d.p. would round by float noise.
		listed += snappedf(amount, 0.01)
	s.listed = listed
	return _clear(s.v) and Fmt.sf(listed) == Fmt.sf(s.v)


static func _deals(rng: Seeded, s: Dictionary) -> bool:
	s.ctx = rng.int_in(0, DEALS.size() - 1)
	s.sign = 1
	s.p = rng.pick([2, 3, 4, 5, 6, 8])
	s.r = Q.new(100 + s.p, 100)
	s.n = rng.pick(DEAL_ROUNDS)
	s.u1 = Q.new(rng.int_in(4, 40) * 50)
	var ratio: float = rng.int_in(12, 30) / 10.0
	s.a = Q.new(int(snappedf(s.u1.to_float() * ratio, 50.0)))
	var r: float = s.r.to_float()
	var total_b: float = sum(s.u1.to_float(), r, s.n)
	var total_a: float = s.a.to_float() * s.n
	s.total_b = total_b
	s.v = absf(total_b - total_a)
	return s.a.to_float() > s.u1.to_float() and s.v > total_a * 0.03 and _clear(s.v)


## B starts below A and grows by a percentage, so it passes A once and stays ahead.
static func _overtake(rng: Seeded, s: Dictionary) -> bool:
	s.ctx = rng.int_in(0, RIVALS.size() - 1)
	s.sign = 1
	s.p = rng.pick([20, 25, 30, 40, 50]) if s.rep == "graph" else rng.pick([6, 8, 10, 12, 15, 20, 25])
	s.r = Q.new(100 + s.p, 100)
	s.b = Q.new(rng.int_in(2, 16) * 50)
	s.a = Q.new(int(snappedf(s.b.to_float() * rng.int_in(15, 40) / 10.0, 10.0)))
	s.d = Q.new(rng.int_in(2, 30) * 10)
	var a: float = s.a.to_float()
	var d: float = s.d.to_float()
	var b: float = s.b.to_float()
	var r: float = s.r.to_float()
	if a <= b:
		return false
	var gap: Callable = func(x: float) -> float: return b * pow(r, x - 1.0) - (a + (x - 1.0) * d)
	var lo := 1.0
	var hi := 2.0
	while gap.call(hi) < 0.0 and hi < 64.0:
		lo = hi
		hi += 1.0
	if hi >= 64.0:
		return false
	for i in 60:
		var mid := (lo + hi) / 2.0
		if gap.call(mid) < 0.0:
			lo = mid
		else:
			hi = mid
	if not _crossing(s, hi, 5, 12 if s.rep == "graph" else 24):
		return false
	# The percentage read as a fixed step of its first value: its year, or 0 if it never passes A.
	var step: float = b * s.p / 100.0
	s.slip_n = 0
	if step > d:
		var y: float = 1.0 + (a - b) / (step - d)
		var whole: int = floori(y) + 1
		if whole >= 2:
			s.slip_n = whole
	s.before_a = a + (s.n - 2) * d
	s.before_b = term(b, r, s.n - 1)
	s.after_a = a + (s.n - 1) * d
	s.after_b = term(b, r, s.n)
	return s.after_b - s.after_a > 0.5 and s.before_a - s.before_b > 0.5


## Paper 1: every area and factor is exact. kq is the side factor, b2 its square.
static func _sheets(rng: Seeded, s: Dictionary) -> bool:
	s.ctx = rng.int_in(0, SHEETS.size() - 1)
	var pair: Array = rng.pick(SIDE_FACTORS)
	s.kq = Q.new(pair[0], pair[1])
	s.b2 = s.kq.sq()
	s.w = rng.int_in(2, 12)
	s.ht = rng.int_in(3, 15)
	s.parts = rng.pick([6, 8, 9, 10, 12])
	s.area = Q.new(s.w * s.ht)
	if s.w == s.ht:
		return false
	s.p_q = s.area.div(s.b2.sub(1)).div(s.parts)
	# A clean p: a fraction a hand can write.
	return s.p_q.d <= 120


static func _least_term(rng: Seeded, s: Dictionary) -> bool:
	var graph: bool = s.rep == "graph"
	_flow(rng, s, 1, STEEP_RISES if graph else RISES)
	var u: float = s.u1.to_float()
	var r: float = s.r.to_float()
	var want: float = float(rng.int_in(6, 10 if graph else 30)) + 0.5
	s.target = fig(u * pow(r, want - 1.0))
	var x: float = 1.0 + log(s.target.to_float() / u) / log(r)
	if not _crossing(s, x, 5, 11 if graph else N_MAX):
		return false
	s.before = term(u, r, s.n - 1)
	s.after = term(u, r, s.n)
	# The running total reaches the target first: the slip of testing a total.
	s.other_n = _first_sum_past(u, r, s.target.to_float())
	return _clear(s.after)


static func _first_sum_past(u: float, r: float, target: float) -> int:
	for k in range(1, N_MAX + 2):
		if sum(u, r, k) > target:
			return k
	return 0


static func _first_term_past(u: float, r: float, target: float) -> int:
	for k in range(1, 400):
		if term(u, r, k) > target:
			return k
	return 0


static func _least_after(rng: Seeded, s: Dictionary) -> bool:
	var sign: int = rng.pick([1, -1])
	_stock(rng, s, sign)
	var u: float = s.start.to_float()
	var r: float = s.r.to_float()
	var want: float = float(rng.int_in(5, 24)) + 0.5
	s.target = fig(u * pow(r, want))
	var x: float = log(s.target.to_float() / u) / log(r)
	if not _crossing(s, x, 4, N_MAX):
		return false
	s.before = u * pow(r, s.n - 1)
	s.after = u * pow(r, s.n)
	return _clear(s.after) and s.target.to_float() < LIMIT


static func _least_sum(rng: Seeded, s: Dictionary) -> bool:
	var graph: bool = s.rep == "graph"
	_flow(rng, s, 1, STEEP_RISES if graph else RISES)
	var u: float = s.u1.to_float()
	var r: float = s.r.to_float()
	var want: float = float(rng.int_in(5, 9 if graph else 24)) + 0.5
	s.target = fig(sum(u, r, want))
	var x: float = log(1.0 + s.target.to_float() * (r - 1.0) / u) / log(r)
	if not _crossing(s, x, 4, 11 if graph else N_MAX):
		return false
	s.before = sum(u, r, s.n - 1)
	s.after = sum(u, r, s.n)
	# The term alone reaches the target later: the slip of testing a term.
	s.other_n = _first_term_past(u, r, s.target.to_float())
	return _clear(s.after) and s.other_n != s.n


## u₁ and u_m are given, so r comes from an (m − 1)th root first.
static func _two_terms(rng: Seeded, s: Dictionary) -> bool:
	s.ctx = _in_list(rng, FLOWS, 1)
	s.sign = 1
	s.r = Q.new(rng.pick(TWO_TERM_R), 100)
	s.p = roundi(s.r.to_float() * 100.0) - 100
	s.m = rng.pick([3, 4, 5])
	s.u1 = Q.new(rng.int_in(2, 40) * 5)
	s.r_q = GeometricSequenceSituation.power(s.r, s.m - 1)
	s.um = s.u1.mul(s.r_q)
	if not s.um.mul(10000).is_int():
		return false
	var u: float = s.u1.to_float()
	var r: float = s.r.to_float()
	var want: float = float(rng.int_in(6, 24)) + 0.5
	s.target = fig(sum(u, r, want), 3)
	var t: float = s.target.to_float()
	var x: float = log(1.0 + t * (r - 1.0) / u) / log(r)
	if not _crossing(s, x, 5, N_MAX):
		return false
	s.before = sum(u, r, s.n - 1)
	s.after = sum(u, r, s.n)
	# A root one too high, and a common difference, for what those slips make of n.
	var wrong: float = pow(s.r_q.to_float(), 1.0 / s.m)
	s.wrong_r = _first_sum_past(u, wrong, t)
	var diff: float = (s.um.to_float() - u) / (s.m - 1)
	s.arith_n = 0
	for k in range(1, 4000):
		if k * (2.0 * u + (k - 1) * diff) / 2.0 > t:
			s.arith_n = k
			break
	return _clear(s.after) and t < LIMIT


static func _first_below(rng: Seeded, s: Dictionary) -> bool:
	var graph: bool = s.rep == "graph"
	_flow(rng, s, -1, STEEP_FALLS if graph else FALLS)
	var u: float = s.u1.to_float()
	var r: float = s.r.to_float()
	if graph:
		s.target = fig(u * pow(r, rng.int_in(4, 8) + 0.5))
	else:
		s.target = Answer.parse_number(rng.pick(SMALL)).q
	var x: float = 1.0 + log(s.target.to_float() / u) / log(r)
	if not _crossing(s, x, 5, 11 if graph else N_MAX):
		return false
	s.before = term(u, r, s.n - 1)
	s.after = term(u, r, s.n)
	return _clear(s.after)


## S∞ − Sₙ = u₁rⁿ/(1 − r), so the gap is itself geometric.
static func _gap(rng: Seeded, s: Dictionary) -> bool:
	s.form = "sigma" if s.rep == "notation" else "story"
	s.ctx = _in_list(rng, FLOWS, -1)
	s.sign = -1
	s.p = rng.pick(GAP_FALLS)
	s.r = Q.new(100 - s.p, 100)
	if s.rep == "notation":
		s.c = Q.new(rng.int_in(1, 40) * 5)
		s.u1 = s.c.mul(s.r)
	else:
		s.u1 = Q.new(rng.int_in(2, 50) * 10)
	s.sinf = s.u1.div(Q.new(1).sub(s.r))
	s.target = Answer.parse_number(rng.pick(SMALL)).q
	var r: float = s.r.to_float()
	var f: float = s.sinf.to_float()
	var x: float = log(s.target.to_float() / f) / log(r)
	if not _crossing(s, x, 5, N_MAX):
		return false
	s.before = f * pow(r, s.n - 1)
	s.after = f * pow(r, s.n)
	# The term falling past the same small value: the slip of testing a term.
	var u: float = s.u1.to_float()
	s.other_n = ceili(1.0 + log(s.target.to_float() / u) / log(r))
	return _clear(s.after) and s.other_n != s.n


## The last term is u₁ × r^(n − 1) with r whole, so r^(n − 1) can be recognised.
static func _count(rng: Seeded, s: Dictionary) -> bool:
	s.ctx = rng.int_in(0, SPREADS.size() - 1)
	var big: bool = s.paper == 2
	var r: int = rng.pick([2, 3, 4, 5] if not big else [2, 3, 4])
	s.r = Q.new(r)
	s.u1 = Q.new(rng.int_in(2, 9))
	s.n = rng.int_in(8, 15) if big else rng.int_in(5, 9)
	s.last = s.u1.mul(GeometricSequenceSituation.power(s.r, s.n - 1))
	s.total = GeometricSequenceSituation.power(s.r, s.n - 1)
	var top: float = s.last.to_float()
	return top <= (LIMIT if big else float(P1_LIMIT))


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
