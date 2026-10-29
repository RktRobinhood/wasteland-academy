class_name DistributionSituation
extends RefCounted
## The `distribution` situation (curriculum/question-types.json): one discrete random
## variable X with 3 to 5 values and their probabilities, or a game with prizes and a
## stake (FAL-396).
##
## Every probability is c / total for a whole number c (mult): c is the multiple of k
## (total is then 1/k) or the number of steps of 0.05 or 0.1 (total is 20 or 10), so
## everything stays exact.
##
## need (what the view shows, and what it asks):
##   probs     "multiples"  each probability a whole multiple of k
##             "formula"    P(X = x) = k f(x), f one of RULES
##             "decimal"    decimals in steps of 0.05 or 0.1
##             "known"      multiples with k known, or decimals (picked at random)
##   k_known   multiples and formulas are shown with k put in (1/total)
##   ask       the unknown: k-from-sum, missing-probability, event-probability,
##             expected-value, probabilities-from-mean, fair-stake, expected-count,
##             trials-for-count
##   event     "range" (X > a, X ≤ b, a < X ≤ b ...) or "count" (also X = a)
##   game      a game: X is the prize, one of them $0, and the stake is asked
##
## generate() returns a Dictionary:
##   style     "multiples", "formula" or "decimal";  k_known as above
##   rule      the formula's key in RULES ("" if none)
##   xs        the values of X (the prizes in a game), in order
##   mult      the whole numbers c;  total  their sum;  ps  c / total as Q
##   k         1 / total (Q)
##   mean      E(X) (Q): the fair stake in a game
##   missing   the index of the missing probability, or -1
##   pq        [i, j]: the indexes of p and q, or []
##   event     {"op", "a", "b"} or {};  inside  bool per value;  pe  P(event) (Q)
##   n         the number of trials (0 if none);  count  n × pe (Q)
##   context   an index into the views' contexts;  sectors  the game's spinner (10 or 20)
##   value     the asked number (Q); for p and q, p
##
##   paper     1 or 2 (FAL-419);  kc  the multiples of k beside decimals (Paper 2 k), or []
##
## Paper 2 (need.paper == 2, FAL-419): the numbers want a calculator. Decimals are
## awkward ones to 3 d.p. (style "calc": 0.137, 0.264, each mult a whole number per
## mille, none a multiple of 0.01); k is found beside such decimals (0.137, k, 2k,
## 0.264) or from a reciprocal formula P(X = x) = k/x, k/(x + 1) or k/x² (k = 60/137),
## and comes out to 3 s.f.; a game is a lucky dip of 1000 tokens with a stake to round
## to the cent; an expected number is n × an awkward probability over a less round n.
## Without need.paper, or with Paper 1, the draws are exactly as before.
##
## The clean limits below are the numbers behind the catalogue's `clean` text. The
## SymPy checker (tools/check_answers.py) holds its own copy and fails on any breach.

const N_MIN := 3
const N_MAX := 5
const X_MAX := 7
const MULT_MAX := 6
const TOTAL_MIN := 6       ## k is at most 1/6
const TOTAL_MAX := 60      ## and at least 1/60
const PRIZE_MAX := 20
const STAKE_MIN := 50      ## cents
const TRIALS := [20, 25, 30, 40, 50, 60, 75, 80, 100, 120, 150, 160, 200, 240, 250, 300, 400, 500, 600]
const EDGE := 0.02
## EDGE with room for float error: the checker rejects a value exactly EDGE from a
## rounding edge (18.648 to 3 s.f.), which Paper 2's 3 d.p. numbers can hit.
const EDGE_SAFE := 0.0201
const CONTEXTS := 5
const TRIES := 4000
## Paper 2: probabilities per mille from 0.05 to 0.6, k's multiples up to 4, the
## lucky dip's tokens, and its numbers of trials.
const MILLE := 1000
const MILLE_MIN := 50
const MILLE_MAX := 600
const K_MULT_MAX := 4
const TRIALS_P2 := [24, 36, 48, 52, 60, 75, 90, 120, 144, 150, 180, 240, 250, 360, 365, 500]

## Formulas P(X = x) = k f(x): text is f(x) as written after k, starts the first values
## of x it can take, n_max the most values it allows.
const RULES := {
	"x": {"text": "x", "starts": [1], "n_max": 5},
	"x+1": {"text": "(x + 1)", "starts": [0, 1], "n_max": 5},
	"x+2": {"text": "(x + 2)", "starts": [0, 1], "n_max": 5},
	"x2": {"text": "x²", "starts": [1], "n_max": 4},
	"2x-1": {"text": "(2x − 1)", "starts": [1], "n_max": 5},
	"6-x": {"text": "(6 − x)", "starts": [1], "n_max": 5},
	# Paper 2: reciprocals, P(X = x) = k/x and so on (text is what follows k).
	"1/x": {"text": "/x", "starts": [1, 2], "n_max": 5, "p2": true},
	"1/(x+1)": {"text": "/(x + 1)", "starts": [0, 1, 2], "n_max": 5, "p2": true},
	"1/x2": {"text": "/x²", "starts": [1, 2], "n_max": 4, "p2": true},
}

const OPS_RANGE := [">", "≥", "<", "≤", "<≤", "≤<", ">", "<"]
const OPS_COUNT := ["=", ">", "≥", "<", "≤"]


## f(x) for a Paper 1 rule; for a Paper 2 (reciprocal) rule, the denominator of f(x).
static func rule_value(rule: String, x: int) -> int:
	match rule:
		"x":
			return x
		"x+1":
			return x + 1
		"x+2":
			return x + 2
		"x2":
			return x * x
		"2x-1":
			return 2 * x - 1
		"6-x":
			return 6 - x
		"1/x":
			return x
		"1/(x+1)":
			return x + 1
		"1/x2":
			return x * x
	push_error("DistributionSituation: unknown rule %s" % rule)
	return 0


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	for i in TRIES:
		var s := _draw(rng, need)
		if s.is_empty() or not _clean(s, need):
			continue
		return s
	push_error("DistributionSituation: no clean situation for %s" % need)
	return {}


## Whether X takes in x for the event.
static func takes_in(event: Dictionary, x: int) -> bool:
	var a: int = event.a
	var b: int = event.b
	match event.op:
		"=":
			return x == a
		">":
			return x > a
		"≥":
			return x >= a
		"<":
			return x < b
		"≤":
			return x <= b
		"<≤":
			return a < x and x <= b
		"≤<":
			return a <= x and x < b
	return false


## The event with its strict ends taken in (X > 2 read as X ≥ 2), or {} if none is strict.
static func with_strict_ends(event: Dictionary) -> Dictionary:
	var e := event.duplicate()
	match event.op:
		">":
			e.op = "≥"
		"<":
			e.op = "≤"
		"<≤", "≤<":
			e.op = "≤≤"
		_:
			return {}
	return e


static func prob_of(s: Dictionary, event: Dictionary) -> Q:
	var out := Q.new(0)
	for i in s.xs.size():
		if event.op == "≤≤":
			if event.a <= s.xs[i] and s.xs[i] <= event.b:
				out = out.add(s.ps[i])
		elif takes_in(event, s.xs[i]):
			out = out.add(s.ps[i])
	return out


static func _draw(rng: Seeded, need: Dictionary) -> Dictionary:
	if int(need.get("paper", 1)) == 2:
		return _draw_p2(rng, need)
	var probs: String = need.get("probs", "decimal")
	var game: bool = need.get("game", false)
	if probs == "known":
		probs = "multiples" if rng.chance(0.5) else "decimal"
	var n := rng.int_in(3, 4) if game else rng.int_in(N_MIN, N_MAX)
	var xs: Array = []
	var mult: Array = []
	var rule := ""
	var sectors := 0
	if game:
		var prizes := rng.shuffled(range(1, PRIZE_MAX + 1)).slice(0, n - 1)
		prizes.sort()
		xs = [0] + prizes
	elif probs == "formula":
		var keys: Array = RULES.keys().filter(func(r): return RULES[r].n_max >= n and not RULES[r].get("p2", false))
		rule = rng.pick(keys)
		var start: int = rng.pick(RULES[rule].starts)
		xs = range(start, start + n)
		for x in xs:
			mult.append(rule_value(rule, x))
	else:
		var start := rng.int_in(0, X_MAX - n + 1)
		xs = range(start, start + n)
	if probs == "multiples":
		for i in n:
			mult.append(rng.int_in(1, MULT_MAX))
		if mult.all(func(c): return c == mult[0]):
			return {}
	elif probs == "decimal":
		sectors = 20 if rng.chance(0.5) else 10
		var most := 12 if sectors == 20 else 6
		var left := sectors
		for i in n - 1:
			var c := rng.int_in(1, most)
			mult.append(c)
			left -= c
		if left < 1 or left > most:
			return {}
		mult.append(left)
	var total := 0
	for c in mult:
		total += c
	var ps: Array = mult.map(func(c): return Q.new(c, total))
	var mean := Q.new(0)
	for i in n:
		mean = mean.add(ps[i].mul(xs[i]))
	var s := {
		"style": probs, "k_known": need.get("k_known", false), "rule": rule, "xs": xs, "mult": mult, "total": total,
		"ps": ps, "k": Q.new(1, total), "mean": mean, "missing": -1, "pq": [], "event": {}, "inside": [],
		"pe": Q.new(0), "n": 0, "count": Q.new(0), "context": rng.int_in(0, CONTEXTS - 1), "sectors": sectors,
		"game": game, "paper": 1, "kc": [],
	}
	match need.get("ask", ""):
		"missing-probability":
			s.missing = rng.int_in(0, n - 1)
		"probabilities-from-mean":
			var idx := rng.shuffled(range(n)).slice(0, 2)
			idx.sort()
			s.pq = idx
	var kind: String = need.get("event", "")
	if kind != "":
		var e := _event(rng, xs, kind)
		if e.is_empty():
			return {}
		s.event = e
		s.inside = xs.map(func(x): return takes_in(e, x))
		s.pe = prob_of(s, e)
	if need.get("ask", "") in ["expected-count", "trials-for-count"]:
		var fits: Array = TRIALS.filter(func(t): return Q.new(t).mul(s.pe).mul(2).is_int())
		if fits.is_empty():
			return {}
		s.n = rng.pick(fits)
		s.count = s.pe.mul(s.n)
	s.value = _value(s, need.get("ask", ""))
	return s


## Paper 2: awkward decimals to 3 d.p., k beside them or in a reciprocal formula, a
## lucky dip of 1000 tokens.
@warning_ignore("integer_division")
static func _draw_p2(rng: Seeded, need: Dictionary) -> Dictionary:
	var probs: String = need.get("probs", "decimal")
	var game: bool = need.get("game", false)
	var ask: String = need.get("ask", "")
	var n := rng.int_in(3, 4) if game else rng.int_in(N_MIN, N_MAX)
	var xs: Array = []
	var mult: Array = []
	var kc: Array = []
	var ps: Array = []
	var rule := ""
	var total := MILLE
	var k := Q.new(1, MILLE)
	if game:
		var prizes := rng.shuffled(range(1, PRIZE_MAX + 1)).slice(0, n - 1)
		prizes.sort()
		xs = [0] + prizes
	elif probs == "formula":
		var keys: Array = RULES.keys().filter(func(r): return RULES[r].n_max >= n and RULES[r].get("p2", false))
		rule = rng.pick(keys)
		var start: int = rng.pick(RULES[rule].starts)
		if start + n - 1 > X_MAX:
			return {}
		xs = range(start, start + n)
		var l := 1
		for x in xs:
			var d := rule_value(rule, x)
			l = l * d / Q.gcd(l, d)
		total = 0
		for x in xs:
			mult.append(l / rule_value(rule, x))
			total += mult[-1]
		k = Q.new(l, total)
		ps = mult.map(func(c): return Q.new(c, total))
	else:
		var start := rng.int_in(0, X_MAX - n + 1)
		xs = range(start, start + n)
	if probs != "formula" or game:
		var hi := mini(MILLE_MAX, 2 * MILLE / n - MILLE_MIN)
		var left := MILLE
		if probs == "multiples":
			# k beside the decimals: 2 or more entries are multiples of k, 1 or more decimals.
			var at := rng.shuffled(range(n)).slice(0, rng.int_in(2, n - 1))
			var csum := 0
			for i in n:
				if i in at:
					kc.append(rng.int_in(1, K_MULT_MAX))
					csum += kc[-1]
					mult.append(0)
				else:
					kc.append(0)
					mult.append(_awkward(rng, hi))
					left -= mult[-1]
			if left <= 0:
				return {}
			k = Q.new(left, MILLE * csum)
			for i in n:
				ps.append(k.mul(kc[i]) if kc[i] > 0 else Q.new(mult[i], MILLE))
		else:
			for i in n - 1:
				mult.append(_awkward(rng, hi))
				left -= mult[-1]
			if left < MILLE_MIN or left > MILLE_MAX or left % 10 == 0:
				return {}
			mult.append(left)
			ps = mult.map(func(c): return Q.new(c, MILLE))
	var mean := Q.new(0)
	for i in n:
		mean = mean.add(ps[i].mul(xs[i]))
	var s := {
		"style": "formula" if rule != "" else "calc", "k_known": need.get("k_known", false), "rule": rule, "xs": xs,
		"mult": mult, "total": total, "ps": ps, "k": k, "mean": mean, "missing": -1, "pq": [], "event": {},
		"inside": [], "pe": Q.new(0), "n": 0, "count": Q.new(0), "context": rng.int_in(0, CONTEXTS - 1),
		"sectors": MILLE if game else 0, "game": game, "paper": 2, "kc": kc,
	}
	match ask:
		"missing-probability":
			s.missing = rng.int_in(0, n - 1)
		"probabilities-from-mean":
			var idx := rng.shuffled(range(n)).slice(0, 2)
			idx.sort()
			s.pq = idx
	var kind: String = need.get("event", "")
	if kind != "":
		var e := _event(rng, xs, kind)
		if e.is_empty():
			return {}
		s.event = e
		s.inside = xs.map(func(x): return takes_in(e, x))
		s.pe = prob_of(s, e)
	if ask == "expected-count":
		# n × an awkward probability: not a whole number, written to 3 s.f.
		var fits: Array = TRIALS_P2.filter(func(t): return not Q.new(t).mul(s.pe).is_int())
		if fits.is_empty():
			return {}
		s.n = rng.pick(fits)
		s.count = s.pe.mul(s.n)
	elif ask == "trials-for-count":
		# The expected number is shown, so it ends within 2 decimal places.
		var fits: Array = TRIALS.filter(func(t): return Q.new(t).mul(s.pe).mul(100).is_int())
		if fits.is_empty():
			return {}
		s.n = rng.pick(fits)
		s.count = s.pe.mul(s.n)
	s.value = _value(s, ask)
	return s


## An awkward probability per mille from 51 to hi − 1, never a multiple of 10 (0.137).
@warning_ignore("integer_division")
static func _awkward(rng: Seeded, hi: int) -> int:
	return rng.int_in(MILLE_MIN / 10, hi / 10 - 1) * 10 + rng.int_in(1, 9)


static func _event(rng: Seeded, xs: Array, kind: String) -> Dictionary:
	var op: String = rng.pick(OPS_COUNT if kind == "count" else OPS_RANGE)
	var n := xs.size()
	var a := 0
	var b := 0
	match op:
		"=":
			a = rng.pick(xs)
		">":
			a = xs[rng.int_in(0, n - 2)]
		"≥":
			a = xs[rng.int_in(1, n - 1)]
		"<":
			b = xs[rng.int_in(1, n - 1)]
		"≤":
			b = xs[rng.int_in(0, n - 2)]
		"<≤", "≤<":
			var i := rng.int_in(0, n - 2)
			var j := rng.int_in(i + 1, n - 1)
			a = xs[i]
			b = xs[j]
	return {"op": op, "a": a, "b": b}


static func _value(s: Dictionary, ask: String) -> Q:
	match ask:
		"k-from-sum":
			return s.k
		"missing-probability":
			return s.ps[s.missing]
		"event-probability":
			return s.pe
		"expected-value", "fair-stake":
			return s.mean
		"probabilities-from-mean":
			return s.ps[s.pq[0]]
		"expected-count":
			return s.count
		"trials-for-count":
			return Q.new(s.n)
	return Q.new(0)


static func _clean(s: Dictionary, need: Dictionary) -> bool:
	if s.paper == 2:
		return _clean_p2(s, need)
	var ask: String = need.get("ask", "")
	if s.style in ["multiples", "formula"] and (s.total < TOTAL_MIN or s.total > TOTAL_MAX):
		return false
	if not s.event.is_empty():
		if not s.inside.has(true) or not s.inside.has(false):
			return false
	if ask == "probabilities-from-mean" and s.ps[s.pq[0]].eq(s.ps[s.pq[1]]):
		return false
	if s.game:
		var cents: Q = s.mean.mul(100)
		if not cents.is_int() or cents.n < STAKE_MIN:
			return false
	if ask in ["expected-count", "trials-for-count"] and s.count.lt(1):
		return false
	if ask == "probabilities-from-mean":
		return true
	return not s.value.is_zero() and Answer.rounds_clearly(s.value.to_float(), EDGE)


## Paper 2's limits: every probability from 0.05 to 0.6, k needing a calculator (not
## exact in 3 s.f.), a stake that needs rounding to the cent and is not on a half cent,
## and the answer clear of 3 s.f. rounding edges.
static func _clean_p2(s: Dictionary, need: Dictionary) -> bool:
	var ask: String = need.get("ask", "")
	for p in s.ps:
		if p.lt(Q.new(MILLE_MIN, MILLE)) or Q.new(MILLE_MAX, MILLE).lt(p):
			return false
	if not s.event.is_empty():
		if not s.inside.has(true) or not s.inside.has(false):
			return false
	if ask == "k-from-sum" and not Answer.needs_rounding(s.k):
		return false
	if s.game:
		var mille: Q = s.mean.mul(MILLE)
		if not mille.is_int() or mille.n % 10 in [0, 5] or s.mean.lt(Q.new(STAKE_MIN, 100)):
			return false
	if ask in ["expected-count", "trials-for-count"] and s.count.lt(1):
		return false
	if ask == "probabilities-from-mean":
		return not s.ps[s.pq[0]].eq(s.ps[s.pq[1]])
	return not s.value.is_zero() and Answer.rounds_clearly(s.value.to_float(), EDGE_SAFE)


## The situation as plain data, for the answer export.
static func export(s: Dictionary) -> Dictionary:
	var out := {}
	for key in s:
		out[key] = _plain(s[key])
	return out


static func _plain(v: Variant) -> Variant:
	if v is Q:
		return v.key()
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _plain(v[k])
		return d
	if v is Array:
		return v.map(func(e): return _plain(e))
	return v
