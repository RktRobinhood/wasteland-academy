class_name ApproximationViews
extends ExtensionViews
## The views on the `approximation` situation (FAL-999): one builder per unknown of the AI SL 1.6
## types. t1-ai-percentage-error rounds a value to places or figures, to the accuracy money
## needs and to whole items, finds a percentage error (of an estimate, or of a rounding) and the
## exact values a largest error allows, estimates a calculation to 1 s.f. and picks the answer
## that makes sense. t1-ai-approx-bounds writes the bounds of a rounded value and of what is
## worked out from rounded values: a product, a sum, a quotient and the largest percentage error.
##
## Every question is Paper 2, as every AI paper allows a GDC. Representation: "words", a story.
## `given` holds what the student is shown.

const PE := "AI-SL1.6.percentage-error#"
const RA := "AI-SL1.6.round-accuracy#"
const ER := "AI-SL1.6.estimate-reasonableness#"
const BO := "AI-SL1.6.bounds#"
const MP := "AI-SL1.6.max-percentage-error#"
const TP := "t1-ai-percentage-error#"
const TB := "t1-ai-approx-bounds#"
const R_LEADING := RA + "0"
const R_STAGES := RA + "1"
const R_MONEY_SF := RA + "3"
const R_OVER_APPROX := PE + "0"
const R_NO_HUNDRED := PE + "1"
const R_SIGN := PE + "2"
const R_EXACT_ROUNDED := PE + "3"
const R_TIMES_SMALL := ER + "0"
const R_NEGATIVE := ER + "1"
const R_CUT := TP + "9"
const R_NO_EXTRA := TP + "10"
const R_NEAREST := TP + "11"
const R_APPLY := TP + "12"
const R_OTHER_END := TP + "13"
const R_WHOLE_UNIT := BO + "0"
const R_JUST_BELOW := BO + "1"
const R_SF_UNIT := BO + "2"
const R_SAME_ERROR := MP + "0"
const R_ONE_BOUND := MP + "1"
const R_SAME_BOUND := MP + "2"
const R_MEASURED := TB + "6"
const R_MIXED := TB + "7"

const WHO := ["Kira", "Tomas", "Ines", "Ravi", "Lena", "Odo"]
## [what, plural unit, unit] for a cost.
const GOODS := [["concrete", "m³", "m³"], ["paint", "litres", "litre"], ["fencing", "metres", "metre"],
	["cable", "metres", "metre"], ["fuel", "litres", "litre"], ["gravel", "tonnes", "tonne"]]
const BUY := [["tin of paint", "tins"], ["bag of plaster", "bags"], ["roll of turf", "rolls"], ["box of tiles", "boxes"]]
const FIT := [["tile", "tiles"], ["plank", "planks"], ["panel", "panels"], ["brick", "bricks"]]
## [the quantity, its unit] for an estimate or a measurement.
const THINGS := [["the mass of a crate", "kg"], ["the length of a bridge", "m"], ["the volume of a tank", "litres"],
	["the area of a field", "m²"], ["the height of a tower", "m"], ["the time for a journey", "minutes"]]
const MEASURES := [["The length of a rope", "m"], ["The mass of a bag of grain", "kg"], ["The time for a race", "s"],
	["The length of a plank", "cm"], ["The volume of a water tank", "litres"], ["The width of a door", "m"]]
const COUNTS := ["people at a market", "visitors to a museum", "litres of water in a reservoir", "seeds in a sack",
	"cars on a road in a day", "birds in a flock"]
const NEAREST := {10: "ten", 100: "hundred", 1000: "thousand"}
const PE_UNKNOWNS := ["round-figures", "round-context", "whole-items", "percentage-error", "error-of-rounding",
	"exact-from-error", "estimate-1sf", "reasonable-answer"]
const BOUND_UNKNOWNS := ["measurement-bound", "calc-bound", "quotient-bound", "max-percentage-error"]


func needs() -> Dictionary:
	var out := {}
	for u in PE_UNKNOWNS + BOUND_UNKNOWNS:
		out[u] = {"ask": u}
	return out


## Every AI paper allows a GDC: every cell is Paper 2.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = ApproximationSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A working value: 4 decimal places, or more figures for a small one.
static func F(x: float) -> String:
	return Fmt.work(x, 6) if absf(x) < 1.0 else "%.4f" % x


static func W(x: float) -> String:
	return Fmt.sf(x, 5)


static func qf(x: float) -> Q:
	return GdcKit.qf(x)


static func who(s: Dictionary) -> String:
	return WHO[s.ctx]


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## An answer to 3 s.f.
static func sf_ans(label: String, x: float, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": qf(x)}, {}, label, unit)
	ans.show = "sf"
	return ans


## An exact decimal answer.
static func exact_ans(label: String, v: Q, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label, unit)
	ans.show = "dec"
	ans.exact = true
	return ans


static func sfs(xs: Array) -> Array:
	return xs.filter(func(x): return is_finite(x) and x != 0.0).map(func(x): return {"v": qf(x)})


static func plural(n: int, word: String) -> String:
	return "%d %s%s" % [n, word, "" if n == 1 else "s"]


static func pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {}, "table": null}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


# ── Rounding ─────────────────────────────────────────────────

## The rounding asked for, as the question says it.
static func accuracy(s: Dictionary) -> String:
	if s.mode == "dp":
		return "%s" % plural(s.n, "decimal place")
	return "%s" % plural(s.n, "significant figure")


## r written with the figures it was rounded to: 2.30 to 2 d.p., 0.00730 to 3 s.f.
static func written(r: Q, places: int) -> String:
	return GraphReadingViews.places(r, maxi(places, 0))


static func rounded_values(v: Q, places: int) -> Dictionary:
	var r := ApproximationSituation.round_to(v, places)
	return {"v": r, "text": written(r, places)}


func u_round_figures(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v: Q = s.v
	var keep: int = s.keep
	var r := ApproximationSituation.round_to(v, keep)
	var ans := GraphReadingViews.rounded(r, written(r, keep))
	var wr: Array = []
	if s.mode == "small":
		wr.append(wrong(rounded_values(v, s.n), R_LEADING))
	var st := ApproximationSituation.staged(v, s.from, keep)
	if not st.eq(r):
		wr.append(wrong({"v": st, "text": written(st, keep)}, R_STAGES))
	var cut := ApproximationSituation.cut_to(v, keep)
	if not cut.eq(r):
		wr.append(wrong({"v": cut, "text": written(cut, keep)}, R_CUT))
	var unit := ApproximationSituation.ten(-keep)
	var fill: Array = [rounded_values(v, keep + 1)]
	if keep >= 1:
		fill.append(rounded_values(v, keep - 1))
	for k in [1, -1, 2]:
		var x := r.add(unit.mul(Q.new(k)))
		if x.sign() > 0:
			fill.append({"v": x, "text": written(x, keep)})
	var next := int(floorf(v.mul(ApproximationSituation.ten(keep + 1)).to_float() + 1e-9)) % 10
	var where := "decimal place" if s.mode == "dp" else "significant figure"
	var said: String = ans.values.text
	var steps := {
		"look-at-next-digit": ["Keep %s of %s: the next digit is %d." % [plural(s.n, where), D(v), next],
			("%d is 5 or more, so the last digit kept goes up by one." if next >= 5 else "%d is less than 5, so the digits kept stay as they are.") % next,
			"So it is %s to %s." % [said, accuracy(s)]],
	}
	if s.mode == "dp":
		steps["gdc-fix-mode"] = ["Set the GDC to show %s (Fix %d) and enter %s." % [plural(keep, "decimal place"), keep, D(v)],
			"The screen shows %s." % said, "So it is %s to %s." % [said, accuracy(s)]]
	else:
		steps["gdc-fix-mode"] = ["The first significant figure of %s is in the %s place, so %s means %s." % [D(v), place_name(ApproximationSituation.lead(v)), plural(s.n, where), plural(keep, "decimal place")],
			"Set the GDC to Fix %d and enter %s: the screen shows %s." % [keep, D(v), said], "So it is %s to %s." % [said, accuracy(s)]]
	return pack(["A GDC gives the value %s." % D(v)], "Write this value correct to %s." % accuracy(s), ans, wr, fill, steps)


static func place_name(p: int) -> String:
	match p:
		3:
			return "thousands"
		2:
			return "hundreds"
		1:
			return "tens"
		0:
			return "units"
		-1:
			return "tenths"
		-2:
			return "hundredths"
		-3:
			return "thousandths"
	return "ten-thousandths"


func u_round_context(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var g: Array = GOODS[s.item]
	var bare: float = s.V.to_float() * s.p.to_float()
	var cost: float = bare * (1.0 + s.w / 100.0)
	var ans := CompoundInterestViews.money_ans("cost = $", cost)
	var c := cost * 100.0
	var wr: Array = [wrong({"v": qf(float(Fmt.sf(cost)))}, R_MONEY_SF), wrong({"v": CompoundInterestSituation.money(bare)}, R_NO_EXTRA),
		wrong({"v": Q.new(int(floorf(c)), 100)}, R_CUT)]
	var fill: Array = [{"v": Q.new(roundi(cost))}, {"v": CompoundInterestSituation.money(cost * 1.1)}]
	var factor: float = 1.0 + s.w / 100.0
	var lines: Array = ["%s orders %s %s of %s at $%s per %s, and pays for %d%% extra to allow for waste." % [who(s), D(s.V), g[1], g[0], Fmt.money(s.p), g[2], s.w]]
	return pack(lines, "Find the total cost, correct to the nearest cent.", ans, wr, fill, {
		"match-context": ["Cost = %s × %s × %s = %s" % [D(s.V), Fmt.money(s.p), "%.2f" % factor, F(cost)],
			"Money in dollars is given to the nearest cent, two decimal places.", final_step(ans)],
		"look-at-next-digit": ["Cost = %s × %s × %s = %s" % [D(s.V), Fmt.money(s.p), "%.2f" % factor, F(cost)],
			"To the nearest cent keep two decimal places: the next digit is %d, so round %s." % [int(floorf(c * 10.0)) % 10, "up" if c - floorf(c) >= 0.5 else "down"], final_step(ans)],
	})


func u_whole_items(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := SamplingViews.count_ans("number = ", s.n)
	if s.mode == "buy":
		var b: Array = BUY[s.item]
		var need: float = s.A * (1.0 + s.w / 100.0)
		var x: float = need / s.c
		var wr: Array = [wrong({"v": Q.new(roundi(x))}, R_NEAREST), wrong({"v": Q.new(int(ceilf(float(s.A) / s.c)))}, R_NO_EXTRA)]
		return pack(["Each %s covers %d m². %s needs to cover %d m², and buys %d%% extra to allow for waste." % [b[0], s.c, who(s), s.A, s.w]],
			"Find the number of %s that must be bought." % b[1], ans, wr, [{"v": Q.new(s.n + 1)}, {"v": Q.new(s.n + 2)}], {
			"match-context": ["Area to cover with the extra: %d × %s = %s m²" % [s.A, "%.2f" % (1.0 + s.w / 100.0), D(GdcKit.qf(need))],
				"%s ÷ %d = %s %s, and part of one is no use: round up, as fewer would not cover it." % [D(GdcKit.qf(need)), s.c, F(x), b[1]], final_step(ans)],
		})
	var f: Array = FIT[s.item]
	var y: float = s.L.to_float() * 100.0 / s.a
	var cm: Q = s.L.mul(100)
	var wr2: Array = [wrong({"v": Q.new(roundi(y))}, R_NEAREST)]
	return pack(["Each %s is %d cm long. %s lays them end to end along a wall %s m long, using whole %s only." % [f[0], s.a, who(s), D(s.L), f[1]]],
		"Find the largest number of whole %s that fit along the wall." % f[1], ans, wr2, [{"v": Q.new(s.n - 1)}, {"v": Q.new(s.n + 2)}], {
		"match-context": ["The wall is %s m = %s cm." % [D(s.L), D(cm)],
			"%s ÷ %d = %s %s, and a part of one doesn't count: round down, as one more would not fit." % [D(cm), s.a, F(y), f[1]], final_step(ans)],
	})


# ── Percentage error ─────────────────────────────────────────

## x to 6 places with a real minus sign.
static func signed6(x: float) -> String:
	return ("−" if x < 0.0 else "") + "%.6f" % absf(x)


static func pct_ans(x: float) -> Dictionary:
	return sf_ans("percentage error = ", x, "%")


## The two methods for an error of va against ve: the formula and the ratio.
static func error_steps(va: Q, ve: Q, ve_text: String, ans: Dictionary) -> Dictionary:
	var a := va.to_float()
	var e := ve.to_float()
	var pc := absf(a - e) / e * 100.0
	var ratio := a / e
	return {
		"error-formula": ["ε = |v_A − v_E| ÷ |v_E| × 100%%, with v_A = %s and v_E = %s." % [D(va), ve_text],
			"ε = |%s − %s| ÷ %s × 100%% = %s ÷ %s × 100%%" % [D(va), ve_text, ve_text, F(absf(a - e)), ve_text], "= %s%%" % F(pc), final_step(ans)],
		"ratio": ["v_A ÷ v_E = %s ÷ %s = %s" % [D(va), ve_text, "%.6f" % ratio],
			"%s − 1 = %s, so the estimate is %s%% %s." % ["%.6f" % ratio, signed6(ratio - 1.0), F(absf(ratio - 1.0) * 100.0), "too big" if ratio > 1.0 else "too small"],
			final_step(ans)],
	}


func u_percentage_error(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var th: Array = THINGS[s.item]
	var a: float = s.va.to_float()
	var e: float = s.ve.to_float()
	var pc := absf(a - e) / e * 100.0
	var ans := pct_ans(pc)
	var wr: Array = [wrong({"v": qf(absf(a - e) / a * 100.0)}, R_OVER_APPROX), wrong({"v": qf(absf(a - e) / e)}, R_NO_HUNDRED)]
	if a < e:
		wr.append(wrong({"v": qf(-pc)}, R_SIGN))
	# The rounding trap takes a place, so a question offers two or three of the slips.
	wr = rng.shuffled(wr)
	return pack(["%s estimates %s as %s %s. The exact value is %s %s." % [who(s), th[0], D(s.va), th[1], D(s.ve), th[1]]],
		"Find the percentage error in the estimate.", ans, wr, sfs([pc * 2.0, absf(a - e)]), error_steps(s.va, s.ve, D(s.ve), ans))


static func rounding_words(unit: Q) -> String:
	if unit.eq(1):
		return "the nearest whole number"
	if unit.eq(10):
		return "the nearest ten"
	return "1 decimal place"


func u_error_of_rounding(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var th: Array = THINGS[s.item]
	var a: float = s.va.to_float()
	var e: float = s.ve.to_float()
	var pc := absf(a - e) / e * 100.0
	var ans := pct_ans(pc)
	var ve3 := GraphReadingSituation.sf_q(s.ve, 3)
	var wr: Array = [wrong({"v": qf(absf(a - e) / a * 100.0)}, R_OVER_APPROX),
		wrong({"v": qf(ApproximationSituation.error_of(s.va, ve3))}, R_EXACT_ROUNDED)]
	var steps := error_steps(s.va, s.ve, D(s.ve), ans)
	for m in steps:
		steps[m] = ["Rounded to %s, %s is %s." % [rounding_words(s.unit), D(s.ve), D(s.va)]] + steps[m]
	return pack(["A GDC gives %s as %s %s. %s rounds this value to %s." % [th[0], D(s.ve), th[1], who(s), rounding_words(s.unit)]],
		"Find the percentage error caused by this rounding.", ans, wr, sfs([pc * 10.0, absf(a - e)]), steps)


func u_exact_from_error(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var th: Array = THINGS[s.item]
	var vals := ApproximationSituation.exact_slips(s)
	var big: bool = s.side == "largest"
	var ans := sf_ans("v_E = ", vals[0], " " + th[1])
	var wr: Array = [wrong({"v": qf(vals[1])}, R_APPLY), wrong({"v": qf(vals[2])}, R_OTHER_END)]
	var f: float = 1.0 - s.p / 100.0 if big else 1.0 + s.p / 100.0
	var a: float = s.va.to_float()
	return pack(["%s measures %s as %s %s. The percentage error in this measurement is at most %d%%." % [who(s), th[0], D(s.va), th[1], s.p]],
		"Find the %s possible exact value." % s.side, ans, wr, sfs([a, vals[0] * 1.1]), {
		"error-formula": ["The measurement is v_A = %s, and |v_A − v_E| ÷ v_E × 100%% is at most %d%%." % [D(s.va), s.p],
			("The exact value is largest when the measurement is %d%% too small: v_A = (1 − %s) v_E." if big else "The exact value is smallest when the measurement is %d%% too big: v_A = (1 + %s) v_E.") % [s.p, "%.2f" % (s.p / 100.0)],
			"v_E = %s ÷ %s = %s" % [D(s.va), "%.2f" % f, F(vals[0])], final_step(ans)],
	})


# ── Estimation ───────────────────────────────────────────────

func u_estimate_1sf(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := exact_ans("estimate = ", s.est)
	var wr: Array = []
	if s.C.lt(1):
		wr.append(wrong({"v": s.A.mul(s.B).mul(s.C)}, R_TIMES_SMALL))
	var exact: Q = s.a.mul(s.b).div(s.c)
	var fill: Array = [{"v": GraphReadingSituation.sf_q(exact, 2)}, {"v": s.est.mul(10)}, {"v": s.est.div(10)}]
	var expr := "%s × %s ÷ %s" % [D(s.a), D(s.b), D(s.c)]
	var est := "%s × %s ÷ %s" % [D(s.A), D(s.B), D(s.C)]
	var mags := [ApproximationSituation.lead(s.A), ApproximationSituation.lead(s.B), ApproximationSituation.lead(s.C)]
	return pack(["%s needs a quick estimate of %s." % [who(s), expr]], "Estimate the value by rounding each number to 1 significant figure.", ans, wr, fill, {
		"round-one-sf": ["To 1 significant figure: %s is %s, %s is %s and %s is %s." % [D(s.a), D(s.A), D(s.b), D(s.B), D(s.c), D(s.C)],
			"%s = %s" % [est, D(s.est)], final_step(ans)],
		"order-of-magnitude": ["In standard form: %s = %s, %s = %s and %s = %s." % [D(s.A), sform(s.A), D(s.B), sform(s.B), D(s.C), sform(s.C)],
			"The digits give %s × %s ÷ %s = %s, and the powers of 10 give 10%s × 10%s ÷ 10%s = 10%s." % [digit(s.A), digit(s.B), digit(s.C), D(Q.of(digit_q(s.A)).mul(digit_q(s.B)).div(digit_q(s.C))),
				Fmt.sup(mags[0]), Fmt.sup(mags[1]), Fmt.sup(mags[2]), Fmt.sup(mags[0] + mags[1] - mags[2])],
			"%s × 10%s = %s" % [D(Q.of(digit_q(s.A)).mul(digit_q(s.B)).div(digit_q(s.C))), Fmt.sup(mags[0] + mags[1] - mags[2]), D(s.est)], final_step(ans)],
	})


## The first digit of a 1 s.f. number.
static func digit(v: Q) -> String:
	return D(digit_q(v))


static func digit_q(v: Q) -> Q:
	return v.div(ApproximationSituation.ten(ApproximationSituation.lead(v)))


## A 1 s.f. number in standard form: 5 × 10^1.
static func sform(v: Q) -> String:
	var p := ApproximationSituation.lead(v)
	return "%s × 10%s" % [digit(v), Fmt.sup(p)]


func u_reasonable_answer(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r1 := Fmt.sf(s.r1)
	var r2 := Fmt.sf(s.r2)
	var built := SamplingViews.claims("x = %s: a width must be positive." % r1, [
		["x = %s: it is the other solution of the equation." % r2, R_NEGATIVE],
		["Both: each one solves the equation.", ""],
		["Neither: a width must be a whole number of metres.", ""]])
	return pack(["A rectangular pen is x m wide and (x + %d) m long. Its area is %d m², so x(x + %d) = %d." % [s.d, s.area, s.d, s.area],
		"A GDC solves this equation and gives x = %s or x = %s." % [r1, r2]], "Which value of x is the width of the pen? Give a reason.",
		built.answer, built.wrongs, built.fillers, {
		"context-check": ["Both values solve x(x + %d) = %d, so the equation alone doesn't decide." % [s.d, s.area],
			"x is a width, and a width can't be negative, so x = %s is rejected." % r2, "x = %s: a width must be positive." % r1],
	})


# ── Bounds ───────────────────────────────────────────────────

func u_measurement_bound(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v: Q = s.v
	var u: Q = s.unit
	var lo: bool = s.side == "lower"
	var b := ApproximationSituation.bound(v, u, s.side)
	var line: String
	var unit_text := ""
	match s.mode:
		"dp":
			var m: Array = MEASURES[s.item]
			unit_text = " " + m[1]
			line = "%s is %s %s, correct to %s." % [m[0], D(v), m[1], plural(s.dp, "decimal place")]
		"nearest":
			line = "There are %s %s, correct to the nearest %s." % [D(v), COUNTS[s.item], NEAREST[int(u.n)]]
		_:
			line = "There are %s %s, correct to %s." % [D(v), COUNTS[s.item], plural(s.sf, "significant figure")]
	var ans := exact_ans("%s bound = " % s.side, b, unit_text)
	var wr: Array = [wrong({"v": v.sub(u) if lo else v.add(u)}, R_WHOLE_UNIT)]
	if not lo and s.mode == "dp":
		wr.append(wrong({"v": b.sub(u.div(10))}, R_JUST_BELOW))
	if s.mode == "sf":
		wr.append(wrong({"v": v.sub(Q.new(1, 2)) if lo else v.add(Q.new(1, 2))}, R_SF_UNIT))
	var other := ApproximationSituation.bound(v, u, "upper" if lo else "lower")
	var fill: Array = [{"v": other}, {"v": v}, {"v": b.sub(u.div(4)) if lo else b.add(u.div(4))}]
	var unit_name := "the rounding unit is %s" % D(u)
	if s.mode == "sf":
		unit_name = "the last significant figure is in the %s place, so the rounding unit is %s" % [place_name(ApproximationSituation.lead(u)), D(u)]
	var half := D(u.div(2))
	return pack([line], "Write down the %s bound." % s.side, ans, wr, fill, {
		"half-unit": ["Here %s, and half of it is %s." % [unit_name, half],
			"%s bound = %s %s %s = %s" % ["Lower" if lo else "Upper", D(v), "−" if lo else "+", half, D(b)], final_step(ans)],
		"number-line": ["On a number line the rounded values either side of %s are %s and %s." % [D(v), D(v.sub(u)), D(v.add(u))],
			"Halfway to each is %s and %s: every value from %s up to, not including, %s rounds to %s." % [D(other if not lo else b), D(b if not lo else other), D(v.sub(u.div(2))), D(v.add(u.div(2))), D(v)],
			final_step(ans)],
	})


## How the measurements of a shape are rounded, in words: 1 decimal place, or the nearest metre.
static func to_unit(u: Q, unit: String = "cm") -> String:
	return "1 decimal place" if u.eq(Q.new(1, 10)) else "the nearest " + {"m": "metre", "cm": "centimetre", "g": "gram"}.get(unit, unit)


func u_calc_bound(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var xs: Array = s.xs
	var lo: bool = s.side == "lower"
	var most := "least" if lo else "greatest"
	var vals := ApproximationSituation.calc_slips(s)
	var bs: Array = xs.map(func(x): return ApproximationSituation.bound(x, s.u, s.side))
	var line: String
	var what: String
	var unit: String
	var formula: String
	match s.shape:
		"rectangle":
			line = "A rectangular field is %s m long and %s m wide, each correct to %s." % [D(xs[0]), D(xs[1]), to_unit(s.u, "m")]
			what = "area of the field"
			unit = " m²"
			formula = "%s × %s" % [D(bs[0]), D(bs[1])]
		"circle":
			line = "The radius of a circular pond is %s m, correct to 1 decimal place." % D(xs[0])
			what = "area of the pond"
			unit = " m²"
			formula = "π × %s²" % D(bs[0])
		"sphere":
			line = "The diameter of a ball is %s cm, correct to 1 decimal place. The volume of a sphere of diameter d is πd³ ÷ 6." % D(xs[0])
			what = "volume of the ball"
			unit = " cm³"
			formula = "π × %s³ ÷ 6" % D(bs[0])
		"cylinder":
			line = "A cylindrical tank has radius %s m and height %s m, each correct to %s." % [D(xs[0]), D(xs[1]), to_unit(s.u, "m")]
			what = "volume of the tank"
			unit = " m³"
			formula = "π × %s² × %s" % [D(bs[0]), D(bs[1])]
		_:
			line = "A route has %d stages of %s km, each correct to the nearest km." % [xs.size(), ", ".join(xs.slice(0, -1).map(func(x): return D(x))) + " and " + D(xs[-1])]
			what = "total length of the route"
			unit = " km"
			formula = " + ".join(bs.map(func(x): return D(x)))
	var route: bool = s.shape == "route"
	var ans: Dictionary
	if route:
		ans = exact_ans("length = ", bs.reduce(func(t, x): return t.add(x), Q.new(0)), unit)
	else:
		ans = sf_ans("%s = " % ("area" if unit == " m²" else "volume"), vals[0], unit)
	var wr: Array = []
	if route:
		var whole: Array = xs.map(func(x): return x.sub(s.u) if lo else x.add(s.u))
		wr.append(wrong({"v": whole.reduce(func(t, x): return t.add(x), Q.new(0))}, R_WHOLE_UNIT))
		wr.append(wrong({"v": xs.reduce(func(t, x): return t.add(x), Q.new(0))}, R_MEASURED))
	else:
		wr.append(wrong({"v": qf(vals[1])}, R_WHOLE_UNIT))
		wr.append(wrong({"v": qf(vals[2])}, R_MEASURED))
		if vals.size() > 3:
			wr.append(wrong({"v": qf(vals[3])}, R_MIXED))
		wr = rng.shuffled(wr)
	var fill: Array = sfs([vals[0] * 2.0, vals[0] * 0.5]) if not route else [{"v": ans.values.v.add(1)}, {"v": ans.values.v.sub(1)}]
	var bound_line := "%s bounds: %s." % ["Lower" if lo else "Upper", ", ".join(range(xs.size()).map(func(i): return "%s → %s" % [D(xs[i]), D(bs[i])]))]
	var result_text: String = D(ans.values.v) if route else F(vals[0])
	return pack([line], "Find the %s possible %s." % [most, what], ans, wr, fill, {
		"bound-and-compare": [bound_line,
			"The %s %s uses every %s bound, as a %s length gives a %s %s." % [most, what.split(" ")[0], s.side, "shorter" if lo else "longer", "smaller" if lo else "larger", what.split(" ")[0]],
			"%s = %s" % [formula, result_text], final_step(ans)],
	})


func u_quotient_bound(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var up: bool = s.side == "upper"
	var vals := ApproximationSituation.quotient_slips(s)
	var t_up := ApproximationSituation.bound(s.top, s.ut, "upper")
	var t_lo := ApproximationSituation.bound(s.top, s.ut, "lower")
	var b_up := ApproximationSituation.bound(s.bottom, s.ub, "upper")
	var b_lo := ApproximationSituation.bound(s.bottom, s.ub, "lower")
	var line: String
	var what: String
	var unit: String
	var tn: String
	var bn: String
	if s.kind == "speed":
		line = "%s runs %s m in %s s. The distance is correct to the nearest %s and the time to 1 decimal place." % [who(s), D(s.top), D(s.bottom), "metre" if s.ut.eq(1) else "10 m"]
		what = "average speed"
		unit = " m/s"
		tn = "distance"
		bn = "time"
	else:
		line = "A block of metal has mass %s g and volume %s cm³, the mass correct to the nearest gram and the volume to the nearest cm³." % [D(s.top), D(s.bottom)]
		what = "density"
		unit = " g/cm³"
		tn = "mass"
		bn = "volume"
	var ans := sf_ans("%s = " % ("speed" if s.kind == "speed" else "density"), vals[0], unit)
	var wr: Array = [wrong({"v": qf(vals[1])}, R_SAME_BOUND), wrong({"v": qf(vals[2])}, R_MEASURED)]
	var most := "greatest" if up else "least"
	var top := t_up if up else t_lo
	var bottom := b_lo if up else b_up
	var bounds := "Bounds: the %s is from %s to %s and the %s from %s to %s." % [tn, D(t_lo), D(t_up), bn, D(b_lo), D(b_up)]
	return pack([line], "Find the %s possible %s." % [most, what], ans, wr, sfs([vals[3]]), {
		"choose-bounds": [bounds,
			"A quotient is %s with the %s top and the %s bottom: the %s bound of the %s over the %s bound of the %s." % [most, "largest" if up else "smallest", "smallest" if up else "largest", s.side, tn, "lower" if up else "upper", bn],
			"%s ÷ %s = %s" % [D(top), D(bottom), F(vals[0])], final_step(ans)],
		"bound-and-compare": [bounds,
			"The four quotients: %s ÷ %s = %s, %s ÷ %s = %s, %s ÷ %s = %s and %s ÷ %s = %s." % [D(t_up), D(b_lo), W(t_up.to_float() / b_lo.to_float()), D(t_up), D(b_up), W(t_up.to_float() / b_up.to_float()),
				D(t_lo), D(b_lo), W(t_lo.to_float() / b_lo.to_float()), D(t_lo), D(b_up), W(t_lo.to_float() / b_up.to_float())],
			"The %s of them is %s ÷ %s = %s" % [most, D(top), D(bottom), F(vals[0])], final_step(ans)],
	})


func u_max_percentage_error(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: Q = s.x
	var k: int = ApproximationSituation.POWER_SHAPES[s.shape]
	var vals := ApproximationSituation.max_error_slips(s)
	var lo := ApproximationSituation.bound(x, s.u, "lower")
	var hi := ApproximationSituation.bound(x, s.u, "upper")
	var line: String
	var what: String
	var c := 1.0
	match s.shape:
		"square":
			line = "The side of a square tile is measured as %s cm, correct to %s." % [D(x), to_unit(s.u)]
			what = "area"
		"cube":
			line = "The edge of a cube is measured as %s cm, correct to %s." % [D(x), to_unit(s.u)]
			what = "volume"
		"circle":
			line = "The radius of a circular mat is measured as %s cm, correct to %s." % [D(x), to_unit(s.u)]
			what = "area"
			c = PI
		_:
			line = "The radius of a ball is measured as %s cm, correct to %s." % [D(x), to_unit(s.u)]
			what = "volume"
			c = 4.0 * PI / 3.0
	var ans := sf_ans("maximum error = ", vals[0], "%")
	var wr: Array = [wrong({"v": qf(vals[1])}, R_SAME_ERROR), wrong({"v": qf(vals[2])}, R_ONE_BOUND)]
	var f := x.to_float() / lo.to_float()
	var q := func(v: float) -> float: return c * pow(v, k)
	var qx: float = q.call(x.to_float())
	var qlo: float = q.call(lo.to_float())
	var qhi: float = q.call(hi.to_float())
	var pw := "squared" if k == 2 else "cubed"
	return pack([line, "Its %s is worked out from this measurement." % what], "Find the maximum percentage error in the %s." % what, ans, wr, sfs([vals[0] * 2.0]), {
		"bound-and-compare": ["The length is from %s to %s. The %s from %s is %s, from %s it is %s and from %s it is %s." % [D(lo), D(hi), what, D(x), W(qx), D(lo), W(qlo), D(hi), W(qhi)],
			"Taking each bound's %s as exact: %s ÷ %s × 100%% = %s%% and %s ÷ %s × 100%% = %s%%." % [what, W(absf(qx - qlo)), W(qlo), F(vals[0]), W(absf(qx - qhi)), W(qhi), F(vals[2])],
			"The larger is %s%%." % F(vals[0]), final_step(ans)],
		"scale-factor": ["At most the measured length is %s ÷ %s = %s times the true one." % [D(x), D(lo), "%.6f" % f],
			"The %s is the length %s, so it is at most %s%s = %s times the true %s." % [what, pw, "%.6f" % f, Fmt.sup(k), "%.6f" % pow(f, k), what],
			"(%s − 1) × 100%% = %s%%" % ["%.6f" % pow(f, k), F(vals[0])], final_step(ans)],
	})
