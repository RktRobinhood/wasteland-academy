class_name LinkGrowthViews
extends ExtensionViews
## The views on the `fn-link-multiplicative-growth` situation: one builder per unknown
## of fn-link-multiplicative-growth (FAL-418), linking geometric sequences, exponential
## functions, compound interest and series. Values a calculator gives are to 3 s.f.
##
## compounding-factor asks for the value after N years rather than the two factors: a
## factor per year to 3 s.f. (1.0406 shows as 1.04) would lose the point; the working
## gives both factors.

const T := "fn-link-multiplicative-growth"


func needs() -> Dictionary:
	return {"percent-to-factor": {}, "sequence-vs-function": {}, "first-below": {}, "factor-from-two-values": {},
		"graph-from-factor": {}, "sum-to-infinity-link": {}, "depreciation-two-ways": {"decay": true}, "continuous-factor": {},
		"compounding-factor": {}}


func extra() -> Dictionary:
	var tfr := ["true-false-reason"]
	return {"percent-to-factor": tfr, "sequence-vs-function": tfr, "first-below": ["true-false-reason", "method-pick"],
		"factor-from-two-values": tfr, "graph-from-factor": tfr, "sum-to-infinity-link": tfr,
		"depreciation-two-ways": ["true-false-reason", "method-pick"], "continuous-factor": tfr, "compounding-factor": ["true-false-reason", "method-pick"]}


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = LinkGrowthSituation.export(s)
	for key in ["asked"]:
		out[key] = ExpLogPairViews.M(out[key])
	return out


static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func W(x: float) -> String:
	return Fmt.sf(x, 6)


static func measure(label: String, x: float, unit: String = "") -> Dictionary:
	return ExpModelViews.measure(label, x, unit)


static func wrong_x(out: Dictionary, x: float, ref: String = "") -> void:
	ExpModelViews.wrong_x(out, x, ref)


static func rate_text(s: Dictionary) -> String:
	return "%s by %d%% a year" % ["rises" if s.up else "falls", s.r]


func u_percent_to_factor(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Q = s.f
	var r: int = s.r
	var say := func(v: Q) -> String: return "r = %s: the graph %s" % [D(v), "rises" if Q.new(1).lt(v) else "falls"]
	var right: String = say.call(f)
	var w0: String = say.call(Q.new(r, 100))
	var w1: String = say.call(Q.new(100 + r, 100)) if not s.up else say.call(Q.new(100 - r, 100))
	var opts := [right, w0, w1, say.call(Q.new(r, 10).add(Q.new(1)))]
	var ans := Answer.make("choice", {"v": right}, {"options": opts})
	var out := {"asked": "Write down the factor r of the model V = V₀r^t, and whether its graph rises or falls.",
		"lines": ["A value %s." % rate_text(s)], "answer": ans,
		"wrongs": [wrong({"v": w0}, "SL2.9.exp-model#0")] + ([wrong({"v": w1}, "SL1.3.model#1")] if not s.up else []),
		"generic": [{"v": opts[3]}] + ([{"v": w1}] if s.up else []),
		"methods": {
			"multiplier": method(["%s by %d%% leaves 100%% %s %d%% = %d%% each year." % ["Rising" if s.up else "Falling", r, "+" if s.up else "−", r, 100 + (r if s.up else -r)], "So r = %s." % D(f), "So " + right + "."], ans.values),
			"repeated-multiplication": method(["After one year V = V₀ × %s, after two V₀ × %s², and so on." % [D(f), D(f)], "The factor is %s, %s 1." % [D(f), "above" if s.up else "below"], "So " + right + "."], ans.values),
			"base-comparison": method(["r = %s." % D(f), "A base %s 1 makes the graph %s." % ["above" if s.up else "between 0 and", "rise" if s.up else "fall"], "So " + right + "."], ans.values),
		}}
	return out


func u_sequence_vs_function(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var P0: Q = s.P0
	var f: Q = s.f
	var n: int = s.n
	var x := P0.to_float() * pow(f.to_float(), n)
	var out := {"asked": "Find the value after %d years." % n, "answer": measure("V = ", x), "wrongs": [], "generic": []}
	out.lines = ["V(t) = %s(%s)^t, and u₁ = %s is the value at the start." % [D(P0), D(f), D(P0)]] if rep == "equation" \
		else ["An investment of %s %s." % [D(P0), rate_text(s)]]
	var less := P0.to_float() * pow(f.to_float(), n - 1)
	var tagged := [[P0.to_float() * f.to_float() * n, "SL2.9.exp-model#1"], [less, "SL2.9.exp-model#2"], [less, "SL1.3.model#2"],
		[P0.to_float() * pow(f.to_float(), n + 1), "SL1.3.nth-term#0"]]
	# Two refs give r^(n − 1); which one the option is logged as is the stream's choice.
	for t in rng.shuffled(tagged):
		wrong_x(out, t[0], t[1])
	ExpModelViews.generic_x(out, [P0.to_float() + P0.to_float() * (f.to_float() - 1.0) * n, x * 1.1, x * 0.9,
		P0.to_float() * pow(f.to_float(), n + 2)])
	var final := "So " + Answer.text(out.answer) + "."
	var v: Dictionary = out.answer.values
	out.methods = {
		"substitute-model": method(["V(%d) = %s × %s^%d" % [n, D(P0), D(f), n], "= %s" % W(x), final], v),
		"nth-formula": method(["As a sequence u₁ = %s is year 0, so after %d years is u_%d = u₁r^%d." % [D(P0), n, n + 1, n], "The exponents differ by one because u₁ is t = 0: u_%d = %s × %s^%d = %s" % [n + 1, D(P0), D(f), n, W(x)], final], v),
		"exponential-form": method(["V = V₀r^t with V₀ = %s, r = %s, t = %d." % [D(P0), D(f), n], "V = %s" % W(x), final], v),
		"compound-formula": method(["FV = PV(1 %s %d/100)^n" % ["+" if s.up else "−", s.r], "= %s × %s^%d = %s" % [D(P0), D(f), n, W(x)], final], v),
		"tvm": method(["TVM: N = %d, I%% = %s%d, PV = −%s, PMT = 0, P/Y = C/Y = 1." % [n, "" if s.up else "−", s.r, D(P0)], "FV = %s" % W(x), final], v),
	}
	return out


func u_first_below(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var P0: Q = s.P0
	var fd := Q.new(100 - s.r, 100)
	var T_: Q = s.T
	var nb: int = s.nb
	var nx: float = s.nx
	var ans := Answer.make("number", {"v": Q.new(nb)}, {}, "n = ")
	ans.exact = true
	var out := {"asked": "Find the first whole number of years n after which the value is below %s." % D(T_), "answer": ans,
		"generic": [{"v": Q.new(nb - 1)}, {"v": Q.new(nb + 1)}, {"v": Q.new(nb + 2)}, {"v": Q.new(roundi(nx * 2))}],
		"pick_wrongs": [{"name": "Divide the gap by the yearly loss", "why": "the loss shrinks each year, so the gap isn't closed at a steady rate"},
			{"name": "Round the crossing to the nearest year", "why": "the value is still above it at the year before"},
			{"name": "Solve a linear equation", "why": "the model is a power, not a line"}]}
	match rep:
		"table":
			out.lines = ["The table shows a value that falls by %d%% a year." % s.r]
			out.table = {"rows": [["n", range(nb - 2, nb + 2).map(func(t): return str(t))], ["value", range(nb - 2, nb + 2).map(func(t): return Fmt.sf(P0.to_float() * pow(fd.to_float(), t), 6))]]}
		"words":
			out.lines = ["A car bought for %s loses %d%% of its value each year." % [D(P0), s.r]]
		_:
			out.lines = ["V(n) = %s(%s)^n" % [D(P0), D(fd)]]
	var lo := P0.to_float() * pow(fd.to_float(), nb - 1)
	var hi := P0.to_float() * pow(fd.to_float(), nb)
	var check := "V(%d) = %s and V(%d) = %s, so n = %d is the first below %s." % [nb - 1, W(lo), nb, W(hi), nb, D(T_)]
	var final := "So " + Answer.text(ans) + "."
	var v: Dictionary = ans.values
	out.methods = {
		"multiplier": method(["Each year multiplies the value by %s." % D(fd), check, final], v),
		"tabulate": method(["List %s × %s^n for n = 1, 2, 3, …" % [D(P0), D(fd)], check, final], v),
		"gdc-table-compare": method(["Table y = %s × %s^x on the GDC and scan for the first value below %s." % [D(P0), D(fd), D(T_)], check, final], v),
		"graph-intersect": method(["Graph y = %s × %s^x and y = %s: they cross at x = %s." % [D(P0), D(fd), D(T_), W(nx)], "Round up: " + check, final], v),
		"logs-for-unknown": method(["%s × %s^n < %s, so n > ln(%s)/ln(%s) = %s (ln %s is negative, so the sign turns round)." % [D(P0), D(fd), D(T_), D(T_.div(P0)), D(fd), W(nx), D(fd)], check, final], v),
		"gdc-intersect": method(["The graphs cross at n ≈ %s." % W(nx), "A whole year is needed, so round up: " + check, final], v),
	}
	return out


func u_factor_from_two_values(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Q = s.f
	var gap: int = s.t2 - s.t1
	var pc := f.sub(Q.new(1)).mul(Q.new(100))
	var ans := Answer.make("named", {"v0": f, "v1": pc}, {"names": ["factor", "rate"], "units": ["", "%"]})
	ans.show = "dec"
	ans.exact = true
	var out := {"asked": "Find the factor per year and the percentage rate.", "answer": ans,
		"generic": [{"v0": f.sub(Q.new(1)), "v1": pc}, {"v0": f, "v1": pc.neg()}, {"v0": s.V2.div(s.V1), "v1": s.V2.div(s.V1).sub(Q.new(1)).mul(Q.new(100))},
			{"v0": Q.new(1).add(s.V2.sub(s.V1).div(s.V1).div(Q.new(gap))), "v1": s.V2.sub(s.V1).div(s.V1).div(Q.new(gap)).mul(Q.new(100))}]}
	if rep == "table":
		out.lines = ["The table shows a value that changes by the same factor each year."]
		out.table = {"rows": [["year", [str(s.t1), str(s.t2)]], ["value", [D(s.V1), D(s.V2)]]]}
	else:
		out.lines = ["A value is %s after %d years and %s after %d years, changing by the same factor each year." % [D(s.V1), s.t1, D(s.V2), s.t2]]
	out.methods = {"substitute-model": method([
		"%s × r^%d = %s, so r^%d = %s" % [D(s.V1), gap, D(s.V2), gap, D(s.V2.div(s.V1))],
		"r = %s, a change of %s%% a year." % [D(f), D(pc)], "So " + Answer.text(ans) + "."], ans.values)}
	return out


func u_graph_from_factor(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var P0: Q = s.P0
	var f: Q = s.f
	var say := func(y0: String, how: String) -> String: return "starts at (0, %s) and %s towards y = 0" % [y0, how]
	var grows: bool = s.up
	var right: String = "starts at (0, %s) and rises, with y = 0 as its asymptote on the left" % D(P0) if grows else say.call(D(P0), "falls")
	var w2 := ExpLogPairViews.M("starts at (0, −%s) and falls, the growth graph reflected in the x-axis" % D(P0))
	var opts := [right, w2, say.call(D(P0), "rises" if not grows else "falls"), "starts at (0, 0) and %s" % ("rises" if grows else "falls")]
	var ans := Answer.make("choice", {"v": right}, {"options": opts})
	var out := {"asked": "Which describes the graph of y = %s(%s)^x?" % [D(P0), D(f)], "lines": ["y = %s(%s)^x" % [D(P0), D(f)]], "answer": ans,
		"wrongs": [wrong({"v": w2}, "SL2.9.exp-graph#2")] if not grows else [], "generic": opts.slice(1).map(func(o): return {"v": o}),
		"methods": {
			"base-comparison": method(["The base %s is %s 1, so the graph %s." % [D(f), "above" if grows else "between 0 and", "rises" if grows else "falls"], "A positive start keeps every value above 0: y = 0 is the asymptote.", "So it " + right + "."], ans.values),
			"key-points": method(["At x = 0, y = %s." % D(P0), "At x = 1, y = %s; far %s, y → 0." % [D(P0.mul(f)), "left" if grows else "right"], "So it " + right + "."], ans.values),
		}}
	if rep == "graph":
		var fn := func(x: float) -> float: return P0.to_float() * pow(f.to_float(), x)
		out.graph = Plot.spec([Plot.sample(fn, -10.0, 10.0)], [[0, P0.to_float(), Fmt.point(0, P0)]], -10, 10, 0, Plot.nice_top(maxf(fn.call(-10.0), fn.call(10.0))))
		out.lines = ["The graph of y = %s(%s)^x is shown." % [D(P0), D(f)]]
	return out


const CONVERGES := "yes: |r| < 1, so r^n dies away to 0"
const DIVERGES := "no: |r| ≥ 1, so r^n does not die away"


func u_sum_to_infinity_link(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var q: Q = s.q
	var conv := q.abs_q().lt(Q.new(1))
	var right := CONVERGES if conv else DIVERGES
	var opts := [right, DIVERGES if conv else CONVERGES, "yes: r < 1 is enough", "yes: |r| ≤ 1 is enough"]
	var ans := Answer.make("choice", {"v": right}, {"options": opts})
	var wrongs: Array = []
	if not conv and q.lt(Q.new(1)) and not q.eq(Q.new(-1)):
		wrongs.append(wrong({"v": opts[2]}, "SL1.8.convergence#0"))
	if q.abs_q().eq(Q.new(1)):
		wrongs.append(wrong({"v": opts[3]}, "SL1.8.convergence#2"))
	var series := "8" + Answer.plus_q(Q.new(8).mul(q)).replace(" + ", " + ") + Answer.plus_q(Q.new(8).mul(q).mul(q)) + " + …"
	var lines := ["A geometric series has first term 8 and common ratio %s." % D(q)] if rep == "words" else [ExpLogPairViews.M(series)]
	var parts: Array = range(1, 6).map(func(m): return D(Q.new(8).mul(Q.new(1).sub(ExpModelSituation.pow_q(q, m))).div(Q.new(1).sub(q))) if not q.eq(Q.new(1)) else D(Q.new(8 * m)))
	return {"asked": "Does the series have a sum to infinity?", "lines": lines, "answer": ans, "wrongs": wrongs,
		"generic": opts.slice(1).filter(func(o): return not wrongs.any(func(w): return w.values.v == o)).map(func(o): return {"v": o}),
		"methods": {
			"test-ratio": method(["r = %s, so |r| = %s." % [D(q), D(q.abs_q())], "r^n → 0 exactly when |r| < 1; then S∞ = u₁/(1 − r).", "So " + right + "."], ans.values),
			"partial-sums": method([ExpLogPairViews.M("Partial sums: %s, …" % ", ".join(parts)), "They can look settled, so test the ratio: |r| = %s." % D(q.abs_q()), "So " + right + "."], ans.values),
		}}


func u_depreciation_two_ways(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var P0: Q = s.P0
	var r: int = s.r
	var n: int = s.n
	var fd: Q = s.f
	var x := P0.to_float() * pow(fd.to_float(), n)
	var out := {"asked": "Find the value after %d years." % n, "answer": measure("V = ", x), "wrongs": [], "generic": [],
		"pick_wrongs": [{"name": "Subtract %d%% of the price each year" % r, "why": "that treats the loss as linear: each year's loss is %d%% of a smaller value" % r},
			{"name": "Multiply by %s" % D(Q.new(100 + r, 100)), "why": "a loss multiplies by less than 1"},
			{"name": "Multiply by %s" % D(Q.new(r, 100)), "why": "%s keeps only %d%% each year" % [D(Q.new(r, 100)), r]}]}
	if rep == "table":
		out.lines = ["A machine bought for %s loses %d%% of its value each year." % [D(P0), r]]
		out.table = {"rows": [["year", ["0", "1", "2"]], ["value", [D(P0), D(P0.mul(fd)), D(P0.mul(fd).mul(fd))]]]}
	else:
		out.lines = ["A machine bought for %s loses %d%% of its value each year." % [D(P0), r]]
	var lin := P0.to_float() * (1.0 - r * n / 100.0)
	var lin_ref: String = ["SL1.4.depreciation#1", "SL1.3.model#1"][rng.int_in(0, 1)]
	wrong_x(out, lin, lin_ref)
	wrong_x(out, P0.to_float() * pow(1.0 + r / 100.0, n), "SL1.4.depreciation#0")
	if P0.to_float() * pow(r / 100.0, n) >= 1.0:
		wrong_x(out, P0.to_float() * pow(r / 100.0, n), "SL1.4.depreciation#0")
	ExpModelViews.generic_x(out, [P0.to_float() * pow(fd.to_float(), n - 1), x * 1.2, x * 0.8])
	var final := "So " + Answer.text(out.answer) + "."
	var v: Dictionary = out.answer.values
	out.methods = {
		"multiplier": method(["Losing %d%% leaves %s of the value each year." % [r, D(fd)], "%s × %s^%d = %s" % [D(P0), D(fd), n, W(x)], final], v),
		"tabulate": method(["Year 1: %s, year 2: %s, …: each is %s × the one before." % [D(P0.mul(fd)), D(P0.mul(fd).mul(fd)), D(fd)], "After %d years: %s × %s^%d = %s" % [n, D(P0), D(fd), n, W(x)], final], v),
		"repeated-multiplication": method(["As a sequence u₁ = %s (year 0), so year %d is u_%d = %s × %s^%d." % [D(P0), n, n + 1, D(P0), D(fd), n], "= %s" % W(x), final], v),
		"decay-multiplier": method(["As a function V(t) = %s × %s^t." % [D(P0), D(fd)], "V(%d) = %s" % [n, W(x)], final], v),
		"year-by-year": method(["Multiply by %s once a year, %d times." % [D(fd), n], "%s × %s^%d = %s" % [D(P0), D(fd), n, W(x)], final], v),
	}
	return out


func u_continuous_factor(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var kc: Q = s.kc
	var e := exp(kc.to_float())
	var ans := Answer.make("named", {"v0": TriangleViews.qf(e), "v1": TriangleViews.qf((e - 1.0) * 100.0)}, {"names": ["factor", "rate"], "units": ["", "%"]})
	ans.show = "sf"
	var out := {"asked": "Find the factor per year and the equivalent percentage rate.", "lines": ["P = 500e^(%st), t in years" % D(kc)], "answer": ans,
		"generic": [{"v0": TriangleViews.qf(1.0 + kc.to_float()), "v1": kc.mul(Q.new(100))}, {"v0": TriangleViews.qf(e), "v1": kc.mul(Q.new(100))},
			{"v0": TriangleViews.qf(exp(-kc.to_float())), "v1": TriangleViews.qf((exp(-kc.to_float()) - 1.0) * 100.0)}],
		"methods": {"substitute-model": method(["Each year P is multiplied by e^(%s) = %s." % [D(kc), W(e)], "%s − 1 = %s: %s%%." % [W(e), W(e - 1.0), W((e - 1.0) * 100.0)], "So " + Answer.text(ans) + "."], ans.values)}}
	return out


func u_compounding_factor(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var P0: Q = s.P0
	var R: int = s.R
	var k: int = s.k
	var N: int = s.N
	var per := 1.0 + R / (100.0 * k)
	var x := P0.to_float() * pow(per, k * N)
	var how: String = {2: "half-yearly", 4: "quarterly", 12: "monthly"}[k]
	var out := {"asked": "Find the value after %d years." % N, "answer": measure("V = ", x), "wrongs": [], "generic": [],
		"lines": ["%s is invested at %d%% a year, compounded %s." % [D(P0), R, how]],
		"pick_wrongs": [{"name": "Use the annual rate %d times" % (k * N), "why": "each period earns %d%%/%d, not %d%%" % [R, k, R]},
			{"name": "Simple interest", "why": "interest is added to the balance and earns interest itself"}]}
	wrong_x(out, P0.to_float() * pow(1.0 + R / 100.0, k * N), "SL1.4.future-value#0")
	wrong_x(out, P0.to_float() * (1.0 + R * N / 100.0), "SL1.4.future-value#1")
	ExpModelViews.generic_x(out, [P0.to_float() * pow(1.0 + R / 100.0, N), P0.to_float() * pow(per, N), x * 1.1, x * 0.9,
		P0.to_float() * pow(per, k * (N + 1))])
	var final := "So " + Answer.text(out.answer) + "."
	var v: Dictionary = out.answer.values
	out.methods = {
		"compound-formula": method(["Factor per period: 1 + %d/(100 × %d) = %s; per year: %s^%d = %s." % [R, k, W(per), W(per), k, W(pow(per, k))],
			"FV = %s × %s^(%d × %d) = %s" % [D(P0), W(per), k, N, W(x)], final], v),
		"tvm": method(["TVM: N = %d, I%% = %d, PV = −%s, PMT = 0, P/Y = C/Y = %d." % [k * N, R, D(P0), k], "FV = %s" % W(x), final], v),
	}
	return out
