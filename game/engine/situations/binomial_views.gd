class_name BinomialViews
extends ExtensionViews
## The views on the `binomial` situation: one builder per unknown of t4-binomial
## (FAL-695). Every question is Paper 2: probabilities and the standard deviation are
## answered to 3 s.f. (show "sf", with the rounding trap), and E(X), Var(X), n and p are
## exact. The working uses the GDC (binompdf, binomcdf) or the formula.
##
## Representations: "equation" (X ~ B(12, 0.35) and the event as P(X = 4)) and "words"
## (a story, one of CONTEXTS, and the event in words). `given` holds what the student is
## shown, for the SymPy checker: n, p, the event's form and counts, and so on.

const SKILL := "SL4.8."
const R_SWAP := SKILL + "identify#0"
const R_NO_NCR := SKILL + "exact-probability#0"
const R_SWAP_POWERS := SKILL + "exact-probability#1"
const R_CDF_FOR_PDF := SKILL + "exact-probability#2"
const R_AT_LEAST := SKILL + "cumulative-probability#0"
const R_LT_AS_LE := SKILL + "cumulative-probability#1"
const R_BETWEEN := SKILL + "cumulative-probability#2"
const R_VAR_NP := SKILL + "mean-variance#0"
const R_SD_VAR := SKILL + "mean-variance#1"
const R_ROUND_MEAN := SKILL + "mean-variance#2"
const R_ROUND_DOWN := SKILL + "find-n-or-p#1"
const R_P_IS_Q := SKILL + "find-n-or-p#2"
const R_KTH_AS_PDF := SKILL + "binomial-in-context#1"
const R_COND_PRODUCT := SKILL + "binomial-in-context#2"

## The stories. {n} and {p} are put in; `good` is the plural verb phrase ("germinate"),
## `good1` the singular ("germinates"), `x` what X counts.
const CONTEXTS := [
	{"p": "Each seed in a packet germinates with probability {p}, independently of the others.", "n": "{n} seeds are planted.",
		"unit": "seeds", "sing": "seed", "good": "germinate", "good1": "germinates", "x": "the number of seeds that germinate"},
	{"p": "Each water filter works with probability {p}, independently of the others.", "n": "A scavenger tests {n} filters.",
		"unit": "filters", "sing": "filter", "good": "work", "good1": "works", "x": "the number of filters that work"},
	{"p": "Each scan of a radio picks up a signal with probability {p}, independently of the others.", "n": "The radio makes {n} scans.",
		"unit": "scans", "sing": "scan", "good": "pick up a signal", "good1": "picks up a signal", "x": "the number of scans that pick up a signal"},
	{"p": "Each can in a crate goes bad with probability {p}, independently of the others.", "n": "A trader opens {n} cans.",
		"unit": "cans", "sing": "can", "good": "go bad", "good1": "goes bad", "x": "the number of cans that go bad"},
	{"p": "Each arrow a guard fires hits the target with probability {p}, independently of the others.", "n": "The guard fires {n} arrows.",
		"unit": "arrows", "sing": "arrow", "good": "hit the target", "good1": "hits the target", "x": "the number of arrows that hit the target"},
	{"p": "Each old bridge holds a caravan with probability {p}, independently of the others.", "n": "A caravan crosses {n} bridges.",
		"unit": "bridges", "sing": "bridge", "good": "hold", "good1": "holds", "x": "the number of bridges that hold"},
	{"p": "Each trip a drone makes arrives on time with probability {p}, independently of the others.", "n": "The drone makes {n} trips.",
		"unit": "trips", "sing": "trip", "good": "arrive on time", "good1": "arrives on time", "x": "the number of trips that arrive on time"},
	{"p": "Each battery in a bin lasts all night with probability {p}, independently of the others.", "n": "A bin holds {n} batteries.",
		"unit": "batteries", "sing": "battery", "good": "last all night", "good1": "lasts all night", "x": "the number of batteries that last all night"},
]



func needs() -> Dictionary:
	var out := {}
	for u in ["n-and-p-from-words", "exact-probability", "at-most-probability", "at-least-probability", "between-probability",
			"mean-from-parameters", "variance-from-parameters", "std-deviation", "n-and-p-from-mean-variance", "least-trials",
			"kth-success-trial", "conditional-probability"]:
		out[u] = {"ask": u}
	return out


## Every cell is Paper 2: every binomial part in the bank is.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = BinomialSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A float to 6 significant figures with no trailing zeros: a GDC's screen.
static func W(x: float) -> String:
	var t := Fmt.sf(x, 6)
	if t.contains("."):
		t = t.rstrip("0").rstrip(".")
	return t


## A float to 4 significant figures with no trailing zeros, for a sum's terms.
static func W4(x: float) -> String:
	var t := Fmt.sf(x, 4)
	if t.contains("."):
		t = t.rstrip("0").rstrip(".")
	return t


static func successes(k: int) -> String:
	return "%d success" % k if k == 1 else "%d successes" % k


static func ordinal(i: int) -> String:
	var tens := i % 100
	if tens >= 11 and tens <= 13:
		return "%dth" % i
	match i % 10:
		1:
			return "%dst" % i
		2:
			return "%dnd" % i
		3:
			return "%drd" % i
	return "%dth" % i


static func ctx(s: Dictionary) -> Dictionary:
	return CONTEXTS[s.ctx]


## The probability of success as the story writes it.
static func pw(s: Dictionary) -> String:
	return D(s.p)


## The story's opening: the probability of success, then the number of trials.
static func intro(s: Dictionary, with_n: bool = true) -> String:
	var c := ctx(s)
	var text: String = c.p.replace("{p}", pw(s))
	return text + " " + String(c.n).replace("{n}", str(s.n)) if with_n else text


## The event as a probability: P(X = 4), P(2 < X ≤ 6).
static func event(s: Dictionary) -> String:
	match s.form:
		"le":
			return "X ≤ %d" % s.k
		"lt":
			return "X < %d" % s.k
		"ge":
			return "X ≥ %d" % s.k
		"gt":
			return "X > %d" % s.k
		"in":
			return "%d ≤ X ≤ %d" % [s.a, s.b]
		"lo-open":
			return "%d < X ≤ %d" % [s.a, s.b]
	return "X = %d" % s.k


## The event in words, after "the probability that".
static func event_words(s: Dictionary) -> String:
	var c := ctx(s)
	var tail := "of the %d %s %s" % [s.n, c.unit, c.good]
	match s.form:
		"le":
			return "at most %d %s" % [s.k, tail]
		"lt":
			return "fewer than %d %s" % [s.k, tail]
		"ge":
			return "at least %d %s" % [s.k, tail]
		"gt":
			return "more than %d %s" % [s.k, tail]
		"in":
			return "at least %d but at most %d %s" % [s.a, s.b, tail]
		"lo-open":
			return "more than %d but at most %d %s" % [s.a, s.b, tail]
	return "exactly %d %s" % [s.k, tail]


## What the student is shown and asked for a probability of an event.
func _event_question(rep: String, s: Dictionary) -> Dictionary:
	if rep == "equation":
		return {"lines": ["X ~ B(%d, %s)" % [s.n, pw(s)]], "asked": "Find P(%s)." % event(s)}
	return {"lines": [intro(s), "Let X be %s." % ctx(s).x], "asked": "Find the probability that %s." % event_words(s)}


## P(lo <= X <= hi) for the situation, as a float.
static func pr(s: Dictionary) -> float:
	return BinomialSituation.prob(s)


static func qf(x: float) -> Q:
	return GdcKit.qf(x)


## A probability answer to 3 s.f.: "P(X = 4) = 0.237".
static func prob_ans(label: String, x: float) -> Dictionary:
	var ans := Answer.make("number", {"v": qf(x)}, {}, label)
	ans.show = "sf"
	return ans


## An exact decimal answer: "E(X) = 4.2".
static func dec_ans(label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	ans.show = "dec"
	ans.exact = true
	return ans


## A probability that can stand as a wrong option: a 3 s.f. number clear of an edge.
static func ok(x: float) -> bool:
	return x > 0.0 and BinomialSituation.clear(x, 0.001, 0.999)


## {"v": Q} wrong values from floats, for the ones that are fair options.
static func vs(xs: Array) -> Array:
	return xs.filter(func(x): return ok(x)).map(func(x): return {"v": qf(x)})


## Generic wrong options for a probability: the ones given, then scalings of the answer, so
## there are always enough fair ones and the engine never falls back to nudging a
## probability past 1.
static func pad(x: float, xs: Array) -> Array:
	return vs(xs + [x * 0.5, x * 0.7, x * 1.4, x * 1.8, (1.0 + x) / 2.0, x * 0.25])


# ── n and p from a story ─────────────────────────────────────

func u_n_and_p_from_words(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("named", {"v0": Q.new(s.n), "v1": s.p}, {"names": ["n", "p"]})
	ans.show = "dec"
	ans.exact = true
	var c := ctx(s)
	var final := "So %s, and X ~ B(%d, %s)." % [Answer.text(ans), s.n, pw(s)]
	return {"asked": "Write down n and p, so that X ~ B(n, p).", "lines": [intro(s), "Let X be %s." % c.x], "answer": ans,
		"wrongs": [wrong({"v0": s.p, "v1": Q.new(s.n)}, R_SWAP)],
		"generic": [{"v0": Q.new(s.n + 1), "v1": s.p}, {"v0": Q.new(s.n), "v1": s.q}, {"v0": Q.new(s.n - 1), "v1": s.q}],
		"methods": {"four-conditions": method([
			"A fixed number of trials, two outcomes each time, a constant probability and independent trials: all four hold, so X is binomial.",
			"There are %d %s, so n = %d, and each %s %s with probability %s, so p = %s." % [s.n, c.unit, s.n, c.sing, c.good1, pw(s), pw(s)],
			final], ans.values)}}


# ── P(X = k) ─────────────────────────────────────────────────

func u_exact_probability(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var k: int = s.k
	var p: float = s.p.to_float()
	var x := pr(s)
	var out := _event_question(rep, s)
	var ans := prob_ans("P(X = %d) = " % k, x)
	out.answer = ans
	var c := BinomialSituation.comb(n, k)
	var no_ncr := pow(p, k) * pow(1.0 - p, n - k)
	var swapped := c * pow(p, n - k) * pow(1.0 - p, k)
	var cum := BinomialSituation.cdf(n, p, k)
	out.wrongs = vs([no_ncr]).map(func(w): return wrong(w, R_NO_NCR)) + vs([swapped]).map(func(w): return wrong(w, R_SWAP_POWERS)) \
			+ vs([cum]).map(func(w): return wrong(w, R_CDF_FOR_PDF))
	out.generic = pad(x, [BinomialSituation.pmf(n, p, k + 1), BinomialSituation.pmf(n, p, k - 1), 1.0 - x, BinomialSituation.pmf(n, 1.0 - p, k)])
	var final := "So " + Answer.text(ans) + "."
	var ways := D(Q.new(roundi(c)))
	out.methods = {
		"gdc-binompdf": method(["Use binompdf on the GDC with n = %d, p = %s and r = %d." % [n, pw(s), k],
			"binompdf(%d, %s, %d) = %s" % [n, pw(s), k, W(x)], final], ans.values),
		"ncr-formula": method(["P(X = %d) = %dC%d × %s^%d × %s^%d" % [k, n, k, pw(s), k, D(s.q), n - k],
			"%dC%d = %s, %s^%d = %s and %s^%d = %s" % [n, k, ways, pw(s), k, W(pow(p, k)), D(s.q), n - k, W(pow(1.0 - p, n - k))],
			"%s × %s × %s = %s" % [ways, W(pow(p, k)), W(pow(1.0 - p, n - k)), W(x)], final], ans.values),
	}
	return out


# ── Cumulative probabilities ─────────────────────────────────

## "binomcdf(12, 0.35, 4) = 0.xxxxxx" for P(X <= k).
static func cdf_step(s: Dictionary, k: int) -> String:
	return "binomcdf(%d, %s, %d) = %s" % [s.n, pw(s), k, W(BinomialSituation.cdf(s.n, s.p.to_float(), k))]


## The terms P(X = r) for r from lo to hi, to 4 s.f., and their sum to 6.
static func terms_step(s: Dictionary) -> Array:
	var p: float = s.p.to_float()
	var bits: PackedStringArray = []
	for r in range(s.lo, s.hi + 1):
		bits.append(W4(BinomialSituation.pmf(s.n, p, r)))
	return ["Add P(X = r) for r = %d to %d, each from binompdf(%d, %s, r), to 4 s.f." % [s.lo, s.hi, s.n, pw(s)],
		" + ".join(bits) + " = " + W(pr(s))]


func u_at_most_probability(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var p: float = s.p.to_float()
	var x := pr(s)
	var out := _event_question(rep, s)
	var ans := prob_ans("P(%s) = " % event(s), x)
	out.answer = ans
	var le_k := BinomialSituation.cdf(n, p, s.k)
	if s.form == "lt":
		out.wrongs = vs([le_k]).map(func(w): return wrong(w, R_LT_AS_LE))
	out.generic = pad(x, [BinomialSituation.pmf(n, p, s.hi), 1.0 - x, BinomialSituation.cdf(n, p, s.hi - 1), BinomialSituation.cdf(n, p, s.hi + 1)])
	var final := "So " + Answer.text(ans) + "."
	var first: String
	if s.form == "lt":
		first = "'Fewer than %d' stops at %d, so P(%s) = P(X ≤ %d): use binomcdf with upper bound %d." % [s.k, s.hi, event(s), s.hi, s.hi]
	else:
		first = "'At most %d' includes %d, so use binomcdf with upper bound %d." % [s.k, s.k, s.hi]
	var terms := terms_step(s)
	out.methods = {
		"gdc-binomcdf": method([first, cdf_step(s, s.hi), final], ans.values),
		"sum-pdfs": method([terms[0], terms[1], final], ans.values),
	}
	return out


func u_at_least_probability(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var p: float = s.p.to_float()
	var x := pr(s)
	var out := _event_question(rep, s)
	var ans := prob_ans("P(%s) = " % event(s), x)
	out.answer = ans
	var below: int = s.lo - 1
	# The slip: subtracting P(X <= k) for 'at least k', or P(X <= k - 1) for 'more than k'.
	var slip := 1.0 - BinomialSituation.cdf(n, p, s.k) if s.form == "ge" else 1.0 - BinomialSituation.cdf(n, p, s.k - 1)
	out.wrongs = vs([slip]).map(func(w): return wrong(w, R_AT_LEAST))
	out.generic = pad(x, [BinomialSituation.cdf(n, p, below), BinomialSituation.pmf(n, p, s.lo), BinomialSituation.cdf(n, p, s.lo), 1.0 - BinomialSituation.pmf(n, p, s.lo)])
	var final := "So " + Answer.text(ans) + "."
	var why := "'At least %d' starts at %d, so it is everything except X ≤ %d." % [s.k, s.k, below] if s.form == "ge" \
			else "'More than %d' starts at %d, so it is everything except X ≤ %d." % [s.k, s.lo, below]
	var cum_below := BinomialSituation.cdf(n, p, below)
	out.methods = {
		"complement": method([why, "P(%s) = 1 − P(X ≤ %d)" % [event(s), below], cdf_step(s, below), "1 − %s = %s" % [W(cum_below), W(x)], final], ans.values),
		"gdc-binomcdf": method(["The event is %d ≤ X ≤ %d: use the cumulative function from %d up to %d, or subtract two binomcdf values." % [s.lo, n, s.lo, n],
			"P(%s) = binomcdf(%d, %s, %d) − binomcdf(%d, %s, %d) = 1 − %s" % [event(s), n, pw(s), n, n, pw(s), below, W(cum_below)],
			"= %s" % W(x), final], ans.values),
	}
	return out


func u_between_probability(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var p: float = s.p.to_float()
	var x := pr(s)
	var out := _event_question(rep, s)
	var ans := prob_ans("P(%s) = " % event(s), x)
	out.answer = ans
	var below: int = s.lo - 1
	# The slip: subtracting P(X <= a + 1) for a < X <= b, or P(X <= a) for a <= X <= b.
	var slip := BinomialSituation.cdf(n, p, s.b) - BinomialSituation.cdf(n, p, s.lo)
	if s.form == "lo-open":
		out.wrongs = vs([slip]).map(func(w): return wrong(w, R_BETWEEN))
	out.generic = pad(x, [slip, BinomialSituation.cdf(n, p, s.b) - BinomialSituation.cdf(n, p, below - 1), BinomialSituation.cdf(n, p, s.b),
		BinomialSituation.cdf(n, p, s.b - 1) - BinomialSituation.cdf(n, p, below)])
	var final := "So " + Answer.text(ans) + "."
	var start := "%d ≤ X means X starts at %d" % [s.a, s.a] if s.form == "in" else "%d < X means X starts at %d" % [s.a, s.lo]
	var hi_cum := BinomialSituation.cdf(n, p, s.b)
	var lo_cum := BinomialSituation.cdf(n, p, below)
	var terms := terms_step(s)
	out.methods = {
		"gdc-binomcdf": method(["%s, so P(%s) = P(X ≤ %d) − P(X ≤ %d)." % [start, event(s), s.b, below], "%s and %s" % [cdf_step(s, s.b), cdf_step(s, below)],
			"%s − %s = %s" % [W(hi_cum), W(lo_cum), W(x)], final], ans.values),
		"sum-pdfs": method(["%s, so add P(X = r) from r = %d to r = %d." % [start, s.lo, s.hi], terms[1], final], ans.values),
	}
	return out


# ── Mean, variance and standard deviation ────────────────────

func _params_question(rep: String, s: Dictionary, asked_eq: String, asked_words: String) -> Dictionary:
	if rep == "equation":
		return {"lines": ["X ~ B(%d, %s)" % [s.n, pw(s)]], "asked": asked_eq}
	return {"lines": [intro(s), "Let X be %s." % ctx(s).x], "asked": asked_words}


func u_mean_from_parameters(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var mean: Q = s.mean
	var ans := dec_ans("E(X) = ", mean)
	var out := _params_question(rep, s, "Find E(X).", "Find the expected number of %s that %s." % [ctx(s).unit, ctx(s).good])
	out.answer = ans
	out.wrongs = []
	if not mean.is_int():
		out.wrongs.append(wrong({"v": Q.new(roundi(mean.to_float()))}, R_ROUND_MEAN))
	out.generic = [{"v": s.q.mul(Q.new(s.n))}, {"v": s.p.mul(s.q).mul(Q.new(s.n))}, {"v": mean.add(Q.new(1))}, {"v": mean.sub(Q.new(1))}, {"v": mean.mul(Q.new(2))}]
	out.methods = {"np-npq": method(["E(X) = np.", "%d × %s = %s" % [s.n, pw(s), D(mean)], "So " + Answer.text(ans) + "."], ans.values)}
	return out


func u_variance_from_parameters(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var variance: Q = s.variance
	var ans := dec_ans("Var(X) = ", variance)
	var out := _params_question(rep, s, "Find Var(X).", "Find the variance of X.")
	out.answer = ans
	out.wrongs = [wrong({"v": s.mean}, R_VAR_NP)]
	out.generic = [{"v": s.q.mul(Q.new(s.n))}, {"v": s.p.mul(s.p).mul(Q.new(s.n))}, {"v": variance.mul(Q.new(2))}, {"v": s.p.mul(s.q)}]
	out.methods = {"np-npq": method(["Var(X) = np(1 − p).", "%d × %s × %s = %s" % [s.n, pw(s), D(s.q), D(variance)], "So " + Answer.text(ans) + "."], ans.values)}
	return out


func u_std_deviation(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var variance: Q = s.variance
	var sd := sqrt(variance.to_float())
	var ans := prob_ans("standard deviation = ", sd)
	var out := _params_question(rep, s, "Find the standard deviation of X, to 3 s.f.", "Find the standard deviation of X, to 3 s.f.")
	out.answer = ans
	out.wrongs = [wrong({"v": variance}, R_SD_VAR)]
	out.generic = [{"v": qf(sqrt(s.mean.to_float()))}, {"v": s.mean}, {"v": qf(sqrt(s.q.mul(Q.new(s.n)).to_float()))}, {"v": qf(sqrt(variance.to_float() * 2.0))}]
	out.methods = {"np-npq": method(["Var(X) = np(1 − p) = %d × %s × %s = %s." % [s.n, pw(s), D(s.q), D(variance)],
		"The standard deviation is √%s = %s." % [D(variance), W(sd)], "So " + Answer.text(ans) + "."], ans.values)}
	return out


# ── Finding n and p ──────────────────────────────────────────

func u_n_and_p_from_mean_variance(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("named", {"v0": Q.new(s.n), "v1": s.p}, {"names": ["n", "p"]})
	ans.show = "dec"
	ans.exact = true
	var lines: Array
	if rep == "equation":
		lines = ["X ~ B(n, p)", "E(X) = %s and Var(X) = %s" % [D(s.mean), D(s.variance)]]
	else:
		var c := ctx(s)
		lines = ["Let X be %s. X ~ B(n, p), where n is the number of %s and p is the probability that one %s %s." % [c.x, c.unit, c.sing, c.good1],
			"E(X) = %s and Var(X) = %s" % [D(s.mean), D(s.variance)]]
	var final := "So " + Answer.text(ans) + "."
	return {"asked": "Find n and p.", "lines": lines, "answer": ans,
		"wrongs": [wrong({"v0": Q.new(s.n), "v1": s.q}, R_P_IS_Q)],
		"generic": [{"v0": Q.new(s.n + 1), "v1": s.p}, {"v0": s.mean, "v1": s.p}, {"v0": Q.new(s.n), "v1": s.q.mul(s.q)}],
		"methods": {"divide-var-by-mean": method(["E(X) = np and Var(X) = np(1 − p), so Var(X) ÷ E(X) = 1 − p.",
			"1 − p = %s ÷ %s = %s, so p = %s." % [D(s.variance), D(s.mean), D(s.q), D(s.p)],
			"n = E(X) ÷ p = %s ÷ %s = %d." % [D(s.mean), D(s.p), s.n], final], ans.values)}}


func u_least_trials(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var nn: int = s.nn
	var x := BinomialSituation.least_x(s)
	var c := ctx(s)
	var ans := dec_ans("n = ", Q.new(nn))
	var lines: Array
	var asked: String
	if rep == "equation":
		lines = ["X ~ B(n, %s)" % pw(s)]
		asked = "Find the least n such that P(X ≥ 1) > %s." % D(s.c)
	else:
		lines = [String(c.p).replace("{p}", pw(s))]
		asked = "How many %s are needed so that the probability that at least one %s %s is greater than %s?" % [c.unit, c.sing, c.good1, D(s.c)]
	var one_minus: float = 1.0 - s.c.to_float()
	var out := {"asked": asked, "lines": lines, "answer": ans, "wrongs": [],
		"generic": [{"v": Q.new(nn + 1)}, {"v": Q.new(maxi(1, nn - 2))}, {"v": Q.new(nn + 4)}, {"v": Q.new(maxi(1, roundi(x * 2.0)))}]}
	if nn > 1:
		out.wrongs.append(wrong({"v": Q.new(nn - 1)}, R_ROUND_DOWN))
	var fell := 1.0 - pow(s.q.to_float(), nn - 1)
	var rose := 1.0 - pow(s.q.to_float(), nn)
	var final := "So " + Answer.text(ans) + "."
	out.methods = {
		"log-inequality": method(["P(X ≥ 1) = 1 − P(X = 0) = 1 − %s^n > %s, so %s^n < %s." % [D(s.q), D(s.c), D(s.q), W(one_minus)],
			"Take logs: n ln(%s) < ln(%s). ln(%s) is negative, so dividing reverses the inequality: n > %s." % [D(s.q), W(one_minus), D(s.q), W(x)],
			"n is a whole number, so round up: n = %d." % nn, final], ans.values),
		"gdc-table": method(["Enter y = 1 − %s^x in the GDC's table: this is P(X ≥ 1) for x trials." % D(s.q),
			"At x = %d it is %s, not above %s. At x = %d it is %s, above %s." % [nn - 1, W(fell), D(s.c), nn, W(rose), D(s.c)], final], ans.values),
	}
	return out


# ── The kth success, and a conditional ───────────────────────

func u_kth_success_trial(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var m: int = s.m
	var p: float = s.p.to_float()
	var x := BinomialSituation.kth_prob(s)
	var c := ctx(s)
	var ans := prob_ans("probability = ", x)
	var lines: Array
	var asked: String
	if rep == "equation":
		lines = ["Independent trials, each a success with probability %s." % pw(s)]
		asked = "Find the probability that the %s success is on trial %d." % [ordinal(k), m]
	else:
		lines = [String(c.p).replace("{p}", pw(s)), "The %s are used one at a time." % c.unit]
		asked = "Find the probability that the %s %s to %s is the %s %s used." % [ordinal(k), c.sing, c.good, ordinal(m), c.sing]
	var in_m := BinomialSituation.pmf(m, p, k)
	var first := BinomialSituation.pmf(m - 1, p, k - 1)
	var out := {"asked": asked, "lines": lines, "answer": ans,
		"wrongs": vs([in_m]).map(func(w): return wrong(w, R_KTH_AS_PDF)),
		"generic": pad(x, [first, BinomialSituation.pmf(m - 1, p, k), BinomialSituation.pmf(m, p, k - 1), BinomialSituation.pmf(m - 1, p, k - 1) * (1.0 - p)])}
	var final := "So " + Answer.text(ans) + "."
	out.methods = {"split-last-trial": method([
		"The %s success is on trial %d, so the first %d trials have exactly %s, and trial %d is a success." % [ordinal(k), m, m - 1, successes(k - 1), m],
		"P = P(%s in %d trials) × p = binompdf(%d, %s, %d) × %s" % [successes(k - 1), m - 1, m - 1, pw(s), k - 1, pw(s)],
		"%s × %s = %s" % [W(first), pw(s), W(x)], final], ans.values)}
	return out


func u_conditional_probability(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var j: int = s.k
	var p: float = s.p.to_float()
	var c := ctx(s)
	var x := BinomialSituation.cond_prob(s)
	var ans := prob_ans("probability = ", x)
	var lines: Array
	var asked: String
	if rep == "equation":
		lines = ["X ~ B(%d, %s)" % [n, pw(s)]]
		asked = "Find P(X = %d | X ≥ 1)." % j
	else:
		lines = [intro(s), "Let X be %s." % c.x]
		asked = "Given that at least one %s %s, find the probability that exactly %d of the %d %s %s." % [c.sing, c.good1, j, n, c.unit, c.good]
	var at_one := 1.0 - pow(1.0 - p, n)
	var pj := BinomialSituation.pmf(n, p, j)
	var out := {"asked": asked, "lines": lines, "answer": ans,
		"wrongs": vs([pj * at_one]).map(func(w): return wrong(w, R_COND_PRODUCT)),
		"generic": pad(x, [pj, pj / (1.0 - p), at_one, BinomialSituation.pmf(n, p, j) / BinomialSituation.cdf(n, p, j)])}
	var final := "So " + Answer.text(ans) + "."
	out.methods = {"conditional-ratio": method([
		"P(X = %d | X ≥ 1) = P(X = %d and X ≥ 1) ÷ P(X ≥ 1) = P(X = %d) ÷ P(X ≥ 1), since X = %d already has X ≥ 1." % [j, j, j, j],
		"P(X = %d) = binompdf(%d, %s, %d) = %s and P(X ≥ 1) = 1 − %s^%d = %s" % [j, n, pw(s), j, W(pj), D(s.q), n, W(at_one)],
		"%s ÷ %s = %s" % [W(pj), W(at_one), W(x)], final], ans.values)}
	return out
