class_name ZScoreViews
extends ExtensionViews
## The views on the `z-score` situation: one builder per unknown of t4-ext-z-scores (FAL-777). A
## z-value or an x is exact. An interpretation or a comparison is a pick of four written answers:
## the right one and the slips (the sign of z, the variance, z read in the units of x, a raw
## score, a gap not divided by σ, a time read as if higher were better).
##
## Representations: "equation" (X ~ N(60, 8²)), "words" (a story) and "graph" (the normal curve
## with μ and steps of σ marked on its axis, and x).

const ZS := "SL4.12.z-score#"
const CZ := "SL4.12.compare-z#"
const R_VARIANCE := ZS + "0"
const R_SIGN := ZS + "1"
const R_NEGATIVE := ZS + "2"
const R_RAW := CZ + "0"
const R_GAP := CZ + "1"
const R_TIMES := CZ + "2"
const T := "t4-ext-z-scores#"
const R_PLUS_Z := T + "6"
const R_UNITS := T + "7"
const R_SPOT_VARIANCE := T + "8"
const R_SPOT_SIGN := T + "9"
const R_TIMES_VARIANCE := T + "10"
const UNKNOWNS := ["z-from-x", "x-from-z", "interpret-z", "compare-scores", "compare-times"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = ["true-false-reason"] + (["error-spot"] if u in ["z-from-x", "x-from-z"] else [])
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	return [2] if unknown.begins_with("compare-") else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = ZScoreSituation.export(s)
	if not out.has("fillers"):
		out.fillers = []
	return out


static func ctx(s: Dictionary) -> Dictionary:
	return ZScoreSituation.CONTEXTS[s.ctx]


static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func exact(label: String, v: Q, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	ans.show = "dec"
	ans.exact = true
	ans.unit = unit
	return ans


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func pick(right: String, tagged: Array, fillers: Array = []) -> Dictionary:
	var out := InverseRuleViews.choose(right, tagged, fillers)
	out.fillers = out.get("fillers", []) + out.get("generic", [])
	out.erase("generic")
	return out


static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


static func model_line(rep: String, s: Dictionary) -> String:
	if rep == "words":
		var c := ctx(s)
		return "%s are normally distributed with mean %d%s and standard deviation %d%s." % [c.what, s.mu, c.unit, s.sg, c.unit]
	return "X ~ N(%d, %d²)" % [s.mu, s.sg]


## Whole steps of σ either side of μ, out to the value: [x, label].
static func ticks(s: Dictionary) -> Array:
	var k := maxi(2, ceili(absf(s.z.to_float())))
	var out: Array = []
	for j in range(-k, k + 1):
		out.append(s.mu + j * s.sg)
	return out


## z as a decimal, bracketed when it is negative: "1.5", "(−1.5)".
static func PD(z: Q) -> String:
	return ("(%s)" % D(z)) if z.sign() < 0 else D(z)


static func side(z: Q) -> String:
	return "above" if z.sign() > 0 else "below"


static func steps_text(z: Q) -> String:
	var a := z.abs_q()
	return "1 step" if a.eq(Q.new(1)) else "%s steps" % D(a)


# ── z and x ──────────────────────────────────────────────────

func u_z_from_x(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var x: int = int(s.x.to_float())
	var z: Q = s.z
	var ans := exact("z = ", z)
	var out := {"answer": ans, "lines": [model_line(rep, s)], "asked": "Find the z-value of x = %d." % x}
	if rep == "words":
		out.asked = "Find the z-value of %s of %d%s." % [ctx(s).one, x, ctx(s).unit]
	elif rep == "graph":
		out.lines.append("x = %d is marked on the axis, with μ and steps of σ." % x)
		var marks: Array = ticks(s).map(func(t): return {"at": float(t), "label": str(t)})
		marks.append({"at": float(x), "label": "x"})
		out.graph = NormalUnknownViews.curve(float(s.mu), float(s.sg), [], marks)
	else:
		out.lines.append("x = %d" % x)
	var gap: int = x - s.mu
	out.wrongs = [wrong({"v": z.neg()}, R_SIGN), wrong({"v": Q.new(gap, s.sg * s.sg)}, R_VARIANCE)]
	out.fillers = [{"v": z.add(Q.new(1, 2))}, {"v": z.sub(Q.new(1, 2))}, {"v": Q.new(gap)}].filter(func(f): return not f.v.is_zero())
	out.methods = {
		"z-formula": method(["z = (x − μ)/σ = (%d − %d)/%d." % [x, s.mu, s.sg], "= %s/%d." % [N(gap), s.sg], final_step(ans)], ans.values),
		"count-sds": method(["Mark μ = %d and steps of σ = %d: %s." % [s.mu, s.sg, ", ".join(ticks(s).map(func(t): return str(t)))],
			"%d is %s of %d %s %d." % [x, steps_text(z), s.sg, side(z), s.mu], final_step(ans)], ans.values),
	}
	var lines := ["z = (x − μ)/σ", "= (%d − %d)/%d²" % [x, s.mu, s.sg], "= %s/%d" % [N(gap), s.sg * s.sg], "= " + D(Q.new(gap, s.sg * s.sg))]
	var bad := 1
	if rng.chance(0.5):
		lines = ["x − μ = %d − %d = %s" % [x, s.mu, N(gap)], "σ² = %d" % (s.sg * s.sg), "z = %s ÷ %d" % [N(gap), s.sg * s.sg], "= " + D(Q.new(gap, s.sg * s.sg))]
		bad = 2
	out.spot = {"lines": lines, "bad": bad, "ref": R_SPOT_VARIANCE, "why": "z divides x − μ by the standard deviation, %d, not by the variance, %d" % [s.sg, s.sg * s.sg]}
	return out


func u_x_from_z(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var x: Q = s.x
	var z: Q = s.z
	var c := ctx(s)
	var ans := exact("x = ", x, c.unit if rep == "words" else "")
	var out := {"answer": ans, "lines": [model_line(rep, s)]}
	if rep == "words":
		out.lines.append("%s has a z-value of %s." % [cap(c.one), D(z)])
		out.asked = "Find this %s." % c.noun
	else:
		out.lines.append("z = " + D(z))
		out.asked = "Find the value of x with this z-value."
	var zs: Q = z.mul(Q.new(s.sg))
	var mu := Q.new(s.mu)
	out.wrongs = [wrong({"v": mu.sub(zs)}, R_SIGN), wrong({"v": mu.add(z.mul(Q.new(s.sg * s.sg)))}, R_TIMES_VARIANCE), wrong({"v": mu.add(z)}, R_PLUS_Z)]
	out.fillers = [{"v": x.add(Q.new(s.sg))}, {"v": x.sub(Q.new(s.sg))}]
	out.methods = {
		"z-formula": method(["x = μ + zσ = %d + %s × %d." % [s.mu, PD(z), s.sg], "= %d %s %s." % [s.mu, "+" if zs.sign() > 0 else "−", D(zs.abs_q())], final_step(ans)], ans.values),
		"count-sds": method(["z = %s: %s of σ = %d %s μ = %d." % [D(z), steps_text(z), s.sg, side(z), s.mu],
			"%s × %d = %s, and %d %s %s = %s." % [D(z.abs_q()), s.sg, D(zs.abs_q()), s.mu, "+" if zs.sign() > 0 else "−", D(zs.abs_q()), D(x)], final_step(ans)], ans.values),
	}
	var wrong_x: Q = mu.sub(zs)
	var lines := ["x = μ + zσ", "= %d + %s × %d" % [s.mu, PD(z), s.sg], "= %d %s %s" % [s.mu, "−" if zs.sign() > 0 else "+", D(zs.abs_q())], "= " + D(wrong_x)]
	var bad := 2
	if rng.chance(0.5):
		lines = ["zσ = %s × %d = %s" % [D(z), s.sg, D(zs)], "x = μ + zσ", "= %d %s %s" % [s.mu, "−" if zs.sign() > 0 else "+", D(zs.abs_q())], "= " + D(wrong_x)]
	out.spot = {"lines": lines, "bad": bad, "ref": R_SPOT_SIGN,
		"why": "zσ = %s, so x = %d %s %s, %s the mean" % [D(zs), s.mu, "+" if zs.sign() > 0 else "−", D(zs.abs_q()), side(z)]}
	return out


func u_interpret_z(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var z: Q = s.z
	var a := D(z.abs_q())
	var sds := "1 standard deviation" if z.abs_q().eq(Q.new(1)) else "%s standard deviations" % a
	var right := "%s is %s %s the mean" % [c.subj, sds, side(z)]
	var tagged := [tag("%s is %s %s the mean" % [c.subj, sds, "below" if z.sign() > 0 else "above"], R_SIGN),
		tag("%s is %s%s %s the mean" % [c.subj, a, c.unit, side(z)], R_UNITS)]
	if z.sign() < 0:
		tagged.append(tag("A z-value can't be negative, so there is an error", R_NEGATIVE))
	var out := {"lines": [model_line("words", s), "%s has a z-value of %s." % [cap(c.one), D(z)]],
		"asked": "Which statement is true?"}
	out.merge(pick(right, tagged, ["%s is %s times the mean" % [c.subj, a]]))
	out.methods = {
		"z-formula": method(["z = (x − μ)/σ, so x − μ = zσ.", "Here x − μ = %sσ, so x is %s σ %s μ." % [D(z), a, side(z)], right + "."], {"v": right}),
		"count-sds": method(["A z-value counts standard deviations from the mean, and its sign says which side.",
			"%s is %s of σ, %s the mean." % [D(z), steps_text(z), side(z)], right + "."], {"v": right}),
	}
	return out


# ── Comparing two ────────────────────────────────────────────

## Both workings: the asked method's ends at its answer; the other says it gives the same.
static func compare_methods(zl: Array, pl: Array, right: String, asked: String) -> Dictionary:
	var by_z: bool = asked != "compare-percentiles"
	return {"compare-z-values": method(zl + [(right + ".") if by_z else ("That gives the same answer: %s." % right)], {"v": right}),
		"compare-percentiles": method(pl + [("That gives the same answer: %s." % right) if by_z else (right + ".")], {"v": right})}


static func pct(z: Q) -> String:
	return Fmt.sf(100.0 * ZScoreSituation.phi(z.to_float())) + "%"


static func cdf(x: Q, mu: int, sg: int) -> String:
	return "normalcdf(−10^99, %s, %d, %d)" % [D(x), mu, sg]


static func cap(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1)


func u_compare_scores(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: Dictionary = ZScoreSituation.NAMES[s.ctx]
	var who: String = n.a
	var sub := {1: n.s1, 2: n.s2}
	var line := func(k: int) -> String:
		return "%s's mark in %s was %s. The %s marks had mean %d and standard deviation %d." % [who, sub[k], D(s["x%d" % k]), sub[k], s["mu%d" % k], s["sg%d" % k]]
	var d1: Q = s.x1.sub(Q.new(s.mu1))
	var d2: Q = s.x2.sub(Q.new(s.mu2))
	var right: String
	if angle == "compare-percentiles":
		right = "%s: %s of the class scored below %s there, more than %s in %s" % [cap(sub[1]), pct(s.z1), who, pct(s.z2), sub[2]]
	else:
		right = "%s: %s's z-value there, %s, is higher than %s in %s" % [cap(sub[1]), who, D(s.z1), D(s.z2), sub[2]]
	# The filler names the same measure as the key, so "z-value" or "%" alone doesn't give it away (#193).
	var neither := "Neither: %s's z-values, %s in %s and %s in %s, are both positive, so both marks are equally good" % [who, D(s.z1), sub[1], D(s.z2), sub[2]]
	if angle == "compare-percentiles":
		neither = "Neither: %s scored above %s of the class in %s and above %s in %s, so both marks are equally good" % [who, pct(s.z1), sub[1], pct(s.z2), sub[2]]
	var out := {"lines": [line.call(2), line.call(1)] if s.swap else [line.call(1), line.call(2)],
		"asked": "In which subject did %s do better relative to the class? Give a reason." % who}
	out.merge(pick(right, [tag("%s: %s's mark there, %s, is higher than %s" % [cap(sub[2]), who, D(s.x2), D(s.x1)], R_RAW),
		tag("%s: %s is %s marks above the mean there, more than %s" % [cap(sub[2]), who, D(d2), D(d1)], R_GAP)],
		[neither]))
	var zline := func(k: int) -> String:
		return "%s: z = (%s − %d)/%d = %s." % [cap(sub[k]), D(s["x%d" % k]), s["mu%d" % k], s["sg%d" % k], D(s["z%d" % k])]
	var pline := func(k: int) -> String:
		return "%s: P(X < %s) = %s = %s." % [cap(sub[k]), D(s["x%d" % k]), cdf(s["x%d" % k], s["mu%d" % k], s["sg%d" % k]), Fmt.sf(ZScoreSituation.phi(s["z%d" % k].to_float()))]
	out.methods = compare_methods([zline.call(1), zline.call(2)], [pline.call(1), pline.call(2)], right, angle)
	return out


func u_compare_times(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: Dictionary = ZScoreSituation.NAMES[s.ctx]
	var who := {1: n.a, 2: n.b}
	var grp := {1: n.g1, 2: n.g2}
	var line := func(k: int) -> String:
		return "%s ran the 400 m in %s s. In %s, 400 m times have mean %d s and standard deviation %d s." % [who[k], D(s["x%d" % k]), grp[k], s["mu%d" % k], s["sg%d" % k]]
	var d1: Q = Q.new(s.mu1).sub(s.x1)
	var d2: Q = Q.new(s.mu2).sub(s.x2)
	var right: String
	if angle == "compare-percentiles":
		right = "%s's: only %s of %s were faster than %s, fewer than %s of %s for %s" % [who[1], pct(s.z1), grp[1], who[1], pct(s.z2), grp[2], who[2]]
	else:
		right = "%s's: %s's z-value, %s, is lower than %s's, %s, and a lower time is better" % [who[1], who[1], D(s.z1), who[2], D(s.z2)]
	var out := {"lines": [line.call(2), line.call(1)] if s.swap else [line.call(1), line.call(2)],
		"asked": "Whose time was more exceptional? Give a reason."}
	out.merge(pick(right, [tag("%s's: %s's z-value, %s, is higher than %s's, %s" % [who[2], who[2], D(s.z2), who[1], D(s.z1)], R_TIMES),
		tag("%s's: %s's time, %s s, is lower than %s s" % [who[2], who[2], D(s.x2), D(s.x1)], R_RAW),
		tag("%s's: %s was %s s below the mean, more than %s's %s s" % [who[2], who[2], D(d2), who[1], D(d1)], R_GAP)]))
	var zline := func(k: int) -> String:
		return "%s: z = (%s − %d)/%d = %s." % [who[k], D(s["x%d" % k]), s["mu%d" % k], s["sg%d" % k], D(s["z%d" % k])]
	var pline := func(k: int) -> String:
		return "%s: P(X < %s) = %s = %s." % [who[k], D(s["x%d" % k]), cdf(s["x%d" % k], s["mu%d" % k], s["sg%d" % k]), Fmt.sf(ZScoreSituation.phi(s["z%d" % k].to_float()))]
	out.methods = compare_methods([zline.call(1), zline.call(2)], [pline.call(1), pline.call(2)], right, angle)
	return out
