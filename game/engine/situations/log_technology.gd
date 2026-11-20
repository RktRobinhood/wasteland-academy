class_name LogTechnologySituation
extends RefCounted
## The `log-technology` situation (curriculum/question-types.json): a log to evaluate or an
## exponential equation to solve on the GDC, for t1-ext-logs-with-technology (SL1.5, FAL-999).
## Every question is Paper 2: the skill is using the calculator's log and ln keys.
##
## need.ask is the unknown (see LogTechnologyViews). generate() returns a Dictionary:
##   paper, ask       always 2; the unknown
##   key              "log" (base 10) or "ln" (base e)
##   b                the number whose log is found, or the right-hand side (Q)
##   a                the base of aˣ = b (Q), solve-base
##   form, p, q, r    evaluate-expression: "ln-log" is p ln q − log r, "log-ln" is p log q + ln r
##   x                the answer, as the GDC shows it (float)
##   spot_at          error-spot: 0 or 1, the line the slip is made on

const TRIES := 4000
const EDGE := 0.04
## The bases of aˣ = b, as [numerator, denominator].
const BASES := [[3, 2], [2, 1], [5, 2], [3, 1], [4, 1], [5, 1], [6, 1], [7, 1], [108, 100], [112, 100], [125, 100]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "evaluate-log")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "key": "log" if rng.chance(0.5) else "ln", "spot_at": rng.int_in(0, 1)}
		var ok := false
		match ask:
			"evaluate-log", "solve-ten-or-e":
				ok = _one_log(rng, s)
			"solve-base":
				ok = _base(rng, s)
			"evaluate-expression":
				ok = _expression(rng, s)
		if ok:
			return s
	return {}


static func lg(key: String, v: float) -> float:
	return log(v) / log(10.0) if key == "log" else log(v)


static func other(key: String) -> String:
	return "ln" if key == "log" else "log"


## Every value clear of a 3 s.f. edge, and no two the same to 3 s.f.
static func distinct(xs: Array) -> bool:
	var seen := {}
	for x in xs:
		if not is_finite(x) or x == 0.0 or not Answer.rounds_clearly(x, EDGE):
			return false
		seen[Fmt.sf(x)] = true
	return seen.size() == xs.size()


## b from 2 to 999 with up to one decimal place, not a whole power of 10; log b and ln b differ.
static func _one_log(rng: Seeded, s: Dictionary) -> bool:
	s.b = Q.new(rng.int_in(2, 999)) if rng.chance(0.7) else Q.new(rng.int_in(11, 999), 10)
	var b: float = s.b.to_float()
	if absf(lg("log", b) - roundf(lg("log", b))) < 1e-9:
		return false
	s.x = lg(s.key, b)
	return distinct([s.x, lg(other(s.key), b)])


## aˣ = b: x = log b ÷ log a, with b not a whole power of a. The slips (log(b ÷ a), the logs the
## wrong way round) read differently.
static func _base(rng: Seeded, s: Dictionary) -> bool:
	var ab: Array = rng.pick(BASES)
	s.a = Q.new(ab[0], ab[1])
	s.b = Q.new(rng.int_in(3, 500))
	var a: float = s.a.to_float()
	var b: float = s.b.to_float()
	s.x = log(b) / log(a)
	if absf(s.x - roundf(s.x)) < 1e-6 or b <= a:
		return false
	return distinct([s.x, lg("log", b / a), log(a) / log(b)])


## p ln q − log r or p log q + ln r. The slips (the keys swapped, each log rounded to 3 s.f. first)
## read differently.
static func _expression(rng: Seeded, s: Dictionary) -> bool:
	s.form = "ln-log" if rng.chance(0.5) else "log-ln"
	s.p = rng.int_in(2, 5)
	s.q = rng.int_in(2, 60)
	s.r = rng.int_in(2, 60)
	if s.q == s.r or s.q == 10 or s.r == 10:
		return false
	var v := expression(s, false, false)
	s.x = v
	return v > 0.0 and distinct([v, expression(s, true, false), expression(s, false, true)])


## The expression's value; swapped uses the other key for each log, early rounds each log to
## 3 s.f. first.
static func expression(s: Dictionary, swapped: bool, early: bool) -> float:
	var k1 := "ln" if s.form == "ln-log" else "log"
	var k2 := other(k1)
	if swapped:
		k1 = other(k1)
		k2 = other(k2)
	var l1 := lg(k1, s.q)
	var l2 := lg(k2, s.r)
	if early:
		l1 = float(Fmt.sf(l1))
		l2 = float(Fmt.sf(l2))
	return s.p * l1 - l2 if s.form == "ln-log" else s.p * l1 + l2


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
