class_name StratifiedSampleViews
extends ExtensionViews
## The views on the `stratified-sample` situation: one builder per unknown of
## t4-ext-stratified-numbers (FAL-778). Every answer is a whole number, marked exactly. Wrong options
## are SL4.1.stratified-numbers' two misconceptions (an equal split, rounded shares that no longer add
## to the sample) and the type's own (a share rounded down, the percentage taken as the number).
## Error-spot shows a student's working with an equal split, or with the sample size where the
## population belongs.
##
## Representations: "words" (the groups in a sentence) and "table" (the groups with a sample column).

const SK := "SL4.1.stratified-numbers#"
const R_EQUAL := SK + "0"
const R_NOT_ADDING := SK + "1"
const R_ROUND_DOWN := "t4-ext-stratified-numbers#2"
const R_PERCENT := "t4-ext-stratified-numbers#3"
const R_SPOT_EQUAL := "t4-ext-stratified-numbers#4"
const R_SPOT_SAMPLE := "t4-ext-stratified-numbers#5"
const UNKNOWNS := ["stratum-count", "stratum-count-rounded", "last-stratum", "sample-size-from-stratum", "stratum-from-percent"]
const S := preload("res://engine/situations/stratified_sample.gd")


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	return {"stratum-count": ["error-spot"], "stratum-count-rounded": ["error-spot"]}


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1, 2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


static func ctx(s: Dictionary) -> Dictionary:
	return SamplingViews.CONTEXTS[s.ctx]


static func group(s: Dictionary, i: int) -> String:
	return ctx(s).a[i]


## A share as the working writes it: exact where it ends within two places, else to 2 d.p.
static func share_text(x: Q) -> String:
	var t := Fmt.dec(x)
	if not t.contains("/") and (not t.contains(".") or t.split(".")[1].length() <= 2):
		return t
	return "%.2f (to 2 d.p.)" % x.to_float()


## The groups: in a sentence, or as a table with the sample column ("?" where it is asked, and the
## numbers already chosen where they are given).
static func shown(rep: String, s: Dictionary, sample: Array = ["", "", ""], total: String = "") -> Dictionary:
	var c := ctx(s)
	if rep == "table":
		var rows: Array = [["group", ["number", "in sample"]]]
		for i in 3:
			rows.append([group(s, i), [str(s.G[i]), sample[i]]])
		rows.append(["Total", [str(s.N), total]])
		return {"lines": ["The table shows the %d %s in a %s, by group." % [s.N, c.who, c.place]], "table": {"rows": rows}}
	return {"lines": [SamplingViews.camp_line(s)], "table": null}


## "farmers'", "day crew's".
static func owner(name: String) -> String:
	return name + ("'" if name.ends_with("s") else "'s")


static func n_line(s: Dictionary) -> String:
	return "A stratified sample of %d %s is taken, by group." % [s.n, ctx(s).who]


## The equal split's option, where it isn't the answer: n ÷ 3, rounded.
static func equal_split(s: Dictionary) -> int:
	return floori(s.n / 3.0 + 0.5)


static func count(v: int) -> Dictionary:
	return {"v": Q.new(v)}


## The two methods' working for one group's share, ending with `last`.
static func share_methods(s: Dictionary, i: int, last: String, rounding: bool) -> Dictionary:
	var c := ctx(s)
	var x := S.share(s, i)
	var tail := ", which rounds to %d" % S.rounded(x) if rounding else ""
	var others: Array = [0, 1, 2].map(func(j): return S.rounded(S.share(s, j)))
	return {
		"proportion-formula": ["The %s are %d of the %d %s." % [group(s, i), s.G[i], s.N, c.who],
			"%d/%d × %d = %s%s" % [s.G[i], s.N, s.n, share_text(x), tail], last],
		"scale-factor": ["Every group is scaled by the same factor: %d/%d." % [s.n, s.N],
			"%d × %d/%d = %s%s" % [s.G[i], s.n, s.N, share_text(x), tail],
			"Check: the groups give %d, %d and %d, which add to %d." % [others[0], others[1], others[2], others[0] + others[1] + others[2]], last],
	}


func _pack(lines_table: Dictionary, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary) -> Dictionary:
	var out := lines_table.duplicate()
	out.merge({"asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {}})
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


func u_stratum_count(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var g: int = s.g
	var v := S.rounded(S.share(s, g))
	var ans := SamplingViews.count_ans("number = ", v)
	var sh := shown(rep, s, _marks(g), "%d" % s.n)
	if rep != "table":
		sh.lines.append(n_line(s))
	var wr: Array = []
	if equal_split(s) != v:
		wr.append(wrong(count(equal_split(s)), R_EQUAL))
	var fill: Array = [count(v + 1), count(v - 1), count(v + 2), count(2 * v)]
	var out := _pack(sh, "Find how many %s go in the sample." % group(s, g), ans, wr, fill.filter(func(f): return f.v.to_float() > 0), share_methods(s, g, "So number = %d." % v, false))
	out.spot = _spot(s, g, rng, false)
	return out


## The sample column: "?" for the asked group, blank for the rest.
static func _marks(g: int) -> Array:
	var out: Array = []
	for i in 3:
		out.append("?" if i == g else "")
	return out


func u_stratum_count_rounded(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var g: int = s.g
	var x := S.share(s, g)
	var v := S.rounded(x)
	var ans := SamplingViews.count_ans("number = ", v)
	var sh := shown(rep, s, _marks(g), "%d" % s.n)
	if rep != "table":
		sh.lines.append(n_line(s))
	var wr: Array = []
	if equal_split(s) != v:
		wr.append(wrong(count(equal_split(s)), R_EQUAL))
	var down := floori(x.to_float())
	if down != v:
		wr.append(wrong(count(down), R_ROUND_DOWN))
	var fill: Array = [count(v + 1), count(v + 2), count(v - 2), count(2 * v)]
	var out := _pack(sh, "Find how many %s go in the sample, to the nearest whole number." % group(s, g), ans, wr,
		fill.filter(func(f): return f.v.to_float() > 0), share_methods(s, g, "So number = %d." % v, true))
	out.spot = _spot(s, g, rng, true)
	return out


func u_last_stratum(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: Array = [0, 1, 2].map(func(i): return S.rounded(S.share(s, i)))
	var v: int = s.n - r[0] - r[1]
	var ans := SamplingViews.count_ans("number = ", v)
	var sh := shown("table", s, [str(r[0]), str(r[1]), "?"], "%d" % s.n)
	sh.lines.append("A surveyor takes a stratified sample of %d. She has rounded the %s and the %s to the nearest whole number." % [s.n, group(s, 0), group(s, 1)])
	var x := S.share(s, 2)
	var steps := {"scale-factor": [
		"Scaled by %d/%d, the %s give %d × %d/%d = %s, which rounds to %d." % [s.n, s.N, group(s, 2), s.G[2], s.n, s.N, share_text(x), r[2]],
		"Check: %d + %d + %d = %d, not %d, so the rounded numbers don't add to the sample." % [r[0], r[1], r[2], r[0] + r[1] + r[2], s.n],
		"The sample must hold exactly %d: %d − %d − %d = %d." % [s.n, s.n, r[0], r[1], v],
		"So number = %d." % v]}
	return _pack(sh, "Find how many %s she must take so that the sample has exactly %d." % [group(s, 2), s.n], ans,
		[wrong(count(r[2]), R_NOT_ADDING)], [count(v + 2), count(v - 2), count(v + 3)].filter(func(f): return f.v.to_float() > 0), steps)


func u_sample_size_from_stratum(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var g: int = s.g
	var qg := S.rounded(S.share(s, g))
	var ans := SamplingViews.count_ans("sample size = ", s.n)
	var sh := shown(rep, s, _marks(g).map(func(m): return str(qg) if m == "?" else ""), "?")
	sh.lines.append("In a stratified sample, %d %s are chosen." % [qg, group(s, g)])
	var wr: Array = []
	if 3 * qg != s.n:
		wr.append(wrong(count(3 * qg), R_EQUAL))
	var steps := {
		"proportion-formula": ["The %s share of the sample equals their share of the %s: %d/%d." % [owner(group(s, g)), c.place, s.G[g], s.N],
			"%d ÷ (%d/%d) = %d × %d/%d = %d" % [qg, s.G[g], s.N, qg, s.N, s.G[g], s.n], "So sample size = %d." % s.n],
		"scale-factor": ["The %s are scaled from %d to %d, so the factor is %d/%d." % [group(s, g), s.G[g], qg, qg, s.G[g]],
			"The whole %s is scaled by the same factor: %d × %d/%d = %d." % [c.place, s.N, qg, s.G[g], s.n], "So sample size = %d." % s.n],
	}
	var fill: Array = [count(s.n + qg), count(s.n - qg), count(2 * s.n), count(s.N / qg if s.N / qg != s.n else s.n + 1)]
	return _pack(sh, "Find the size of the sample.", ans, wr, fill.filter(func(f): return f.v.to_float() > 0), steps)


func u_stratum_from_percent(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var g: int = s.g
	var p: Array = s.pct
	var v: int = p[g] * s.n / 100
	var ans := SamplingViews.count_ans("number = ", v)
	var lines := ["The %s of a %s are %d%% %s, %d%% %s and %d%% %s." % [c.who, c.place, p[0], group(s, 0), p[1], group(s, 1), p[2], group(s, 2)],
		"A stratified sample of %d %s is taken, by group." % [s.n, c.who]]
	var wr: Array = [wrong(count(p[g]), R_PERCENT)]
	if equal_split(s) != v:
		wr.append(wrong(count(equal_split(s)), R_EQUAL))
	var steps := {
		"proportion-formula": ["The %s are %d%% of the %s, so %d%% of the sample." % [group(s, g), p[g], c.who, p[g]],
			"%d%% of %d = %d/100 × %d = %d" % [p[g], s.n, p[g], s.n, v], "So number = %d." % v],
		"scale-factor": ["Each percentage is scaled to the sample by the same factor: %d/100." % s.n,
			"%d × %d/100 = %d" % [p[g], s.n, v], "So number = %d." % v],
	}
	return _pack({"lines": lines, "table": null}, "Find how many %s go in the sample." % group(s, g), ans, wr,
		[count(v + 1), count(v + 2), count(2 * v)], steps)


## A student's working with one slip: an equal split, or (for a whole share) the sample size where
## the population belongs. The share line comes first or second, after the line adding the groups.
func _spot(s: Dictionary, g: int, rng: Seeded, rounding: bool) -> Dictionary:
	var name := group(s, g)
	var add := "The groups add to %d: %d + %d + %d." % [s.N, s.G[0], s.G[1], s.G[2]]
	var lines: Array
	var ref: String
	var why: String
	if rounding or rng.chance(0.5):
		var x := Q.new(s.n, 3)
		var r := S.rounded(x)
		lines = ["Each group's share is 1/3.", "1/3 × %d = %s%s" % [s.n, share_text(x), ", which rounds to %d" % r if not x.is_int() else ""],
			"So %d %s go in the sample." % [r, name]]
		ref = R_SPOT_EQUAL
		why = "a stratified sample shares the sample in proportion to the groups' sizes, not equally"
	else:
		lines = ["The %s share is %d/%d." % [owner(name), s.G[g], s.n], "%d/%d × %d = %d" % [s.G[g], s.n, s.n, s.G[g]],
			"So %d %s go in the sample." % [s.G[g], name]]
		ref = R_SPOT_SAMPLE
		why = "the %s share is of the whole %s, %d/%d, not of the sample" % [owner(name), ctx(s).place, s.G[g], s.N]
	var bad := 0
	if rng.chance(0.5):
		lines.push_front(add)
		bad = 1
	else:
		lines.insert(1, add)
	return {"lines": lines, "bad": bad, "ref": ref, "why": why}
