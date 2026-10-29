class_name PercentViews
extends ExtensionViews
## The views on the `fn-pre-percent-multiplier` situation: one builder per unknown of
## fn-pre-percent-multiplier (FAL-418). Multipliers and amounts are written as
## decimals; every answer is exact.

const T := "fn-pre-percent-multiplier"
const REF_DECREASE := T + "#0"
const REF_TEN_TIMES := T + "#1"
const REF_REVERSE := T + "#2"
const REF_ADD_PERCENTS := T + "#3"


func needs() -> Dictionary:
	return {"increase-multiplier": {}, "decrease-multiplier": {}, "apply-change": {}, "multiplier-to-percent": {},
		"reverse-percentage": {}, "repeated-changes": {}, "percent-from-amounts": {}}


func extra() -> Dictionary:
	return {"repeated-changes": ["error-spot"]}


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = PercentSituation.export(s)
	return out


static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func change(r: int, up: bool) -> String:
	return "%s of %d%%" % ["an increase" if up else "a decrease", r]


static func dec_number(label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	ans.show = "dec"
	ans.exact = true
	return ans


func u_increase_multiplier(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: int = s.r
	var m := PercentSituation.mult(r, true)
	var ans := dec_number("multiplier = ", m)
	var said := "A price rises by %d%%." % r if rep == "words" else "An increase of %d%%" % r
	var out := {"asked": "Write down the multiplier for an increase of %d%%." % r, "lines": [said], "answer": ans,
		"wrongs": [], "generic": [{"v": Q.new(r, 100)}, {"v": Q.new(100 - r, 100)}, {"v": Q.new(r)}, {"v": Q.new(100 + 2 * r, 100)}],
		"methods": {"one-multiplier": method(["The new amount is 100%% + %d%% = %d%% of the old one." % [r, 100 + r], "%d%% = %s" % [100 + r, D(m)], "So the " + Answer.text(ans) + "."], {"v": m})}}
	if r < 10:
		out.wrongs.append(wrong({"v": Q.new(10 + r, 10)}, REF_TEN_TIMES))
	return out


func u_decrease_multiplier(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: int = s.r
	var m := PercentSituation.mult(r, false)
	var ans := dec_number("multiplier = ", m)
	var said := "A price falls by %d%%." % r if rep == "words" else "A decrease of %d%%" % r
	return {"asked": "Write down the multiplier for a decrease of %d%%." % r, "lines": [said], "answer": ans,
		"wrongs": [wrong({"v": Q.new(r, 100)}, REF_DECREASE)],
		"generic": [{"v": Q.new(100 + r, 100)}, {"v": Q.new(-r, 100)}, {"v": Q.new(100 - 2 * r, 100)}],
		"methods": {"one-multiplier": method(["The new amount is 100%% − %d%% = %d%% of the old one." % [r, 100 - r], "%d%% = %s" % [100 - r, D(m)], "So the " + Answer.text(ans) + "."], {"v": m})}}


func u_apply_change(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: int = s.r
	var up: bool = s.up
	var P: Q = s.P
	var A: Q = s.A
	var ans := dec_number("new amount = ", A)
	var part := P.mul(Q.new(r, 100))
	var out := {"asked": "Find the amount after %s." % change(r, up), "answer": ans, "wrongs": [],
		"generic": [{"v": P.mul(PercentSituation.mult(r, not up))}, {"v": P.add(Q.new(r if up else -r))}, {"v": part}, {"v": A.add(part if up else part.neg())}]}
	match rep:
		"words":
			out.lines = ["A shop's price of %s changes by %s." % [D(P), change(r, up).trim_prefix("an ").trim_prefix("a ")]]
		"table":
			out.lines = ["The table shows an amount and its percentage change."]
			out.table = {"rows": [["Before", [D(P)]], ["Change", ["%s%d%%" % ["+" if up else "−", r]]], ["After", ["?"]]]}
		_:
			out.lines = ["%s, %s" % [D(P), change(r, up)]]
	if not up:
		out.wrongs.append(wrong({"v": part}, REF_DECREASE))
		out.generic = out.generic.filter(func(g): return not g.v.eq(part))
	var final := "So the " + Answer.text(ans) + "."
	out.methods = {
		"one-multiplier": method(["The multiplier is %s." % D(s.m), "%s × %s = %s" % [D(P), D(s.m), D(A)], final], {"v": A}),
		"find-then-add": method(["%d%% of %s is %s." % [r, D(P), D(part)], "%s %s %s = %s" % [D(P), "+" if up else "−", D(part), D(A)], final], {"v": A}),
	}
	return out


func u_multiplier_to_percent(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var mm: Q = s.mm
	var up: bool = Q.new(1).lt(mm)
	var v := mm.sub(Q.new(1)).abs_q().mul(Q.new(100))
	var ans := Answer.make("pct", {"dir": "rise" if up else "fall", "v": v}, {"per": ""})
	ans.exact = true
	var other := "fall" if up else "rise"
	return {"asked": "What percentage change does multiplying by %s stand for?" % D(mm), "lines": ["× %s" % D(mm)], "answer": ans,
		"generic": [{"dir": other, "v": v}, {"dir": ans.values.dir, "v": mm.mul(Q.new(100))}, {"dir": ans.values.dir, "v": v.div(Q.new(10))}, {"dir": other, "v": mm.mul(Q.new(100))}],
		"methods": {"one-multiplier": method(["%s = %s%% of the amount." % [D(mm), D(mm.mul(Q.new(100)))], "%s%% − 100%% = %s%s%%" % [D(mm.mul(Q.new(100))), "+" if up else "−", D(v)], "So it is " + Answer.text(ans) + "."], ans.values)}}


func u_reverse_percentage(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: int = s.r
	var up: bool = s.up
	var P: Q = s.P
	var A: Q = s.A
	var ans := dec_number("original amount = ", P)
	var back := A.sub(A.mul(Q.new(r, 100))) if up else A.add(A.mul(Q.new(r, 100)))
	var out := {"asked": "Find the amount before the change.", "answer": ans, "wrongs": [wrong({"v": back}, REF_REVERSE)],
		"generic": [{"v": A.mul(s.m)}, {"v": A.sub(Q.new(r)) if up else A.add(Q.new(r))}, {"v": A.div(PercentSituation.mult(r, not up))}]}
	match rep:
		"words":
			out.lines = ["After %s, a price is %s." % [change(r, up), D(A)]]
		"table":
			out.lines = ["The table shows an amount after a percentage change."]
			out.table = {"rows": [["Before", ["?"]], ["Change", ["%s%d%%" % ["+" if up else "−", r]]], ["After", [D(A)]]]}
		_:
			out.lines = ["%s after %s" % [D(A), change(r, up)]]
	var final := "So the " + Answer.text(ans) + "."
	var pc := 100 + (r if up else -r)
	out.methods = {
		"divide-to-reverse": method(["The change multiplied the original by %s." % D(s.m), "%s ÷ %s = %s" % [D(A), D(s.m), D(P)], final], {"v": P}),
		"unitary": method(["%s is %d%% of the original, so 1%% is %s ÷ %d = %s." % [D(A), pc, D(A), pc, D(A.div(Q.new(pc)))], "100%% is %s × 100 = %s" % [D(A.div(Q.new(pc))), D(P)], final], {"v": P}),
	}
	return out


func u_repeated_changes(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var m1: Q = s.m
	var m2: Q = s.m2
	var M := m1.mul(m2)
	var pc := M.sub(Q.new(1)).mul(Q.new(100))
	var ans := Answer.make("named", {"v0": M, "v1": pc}, {"names": ["multiplier", "percentage change"], "units": ["", "%"]})
	ans.show = "dec"
	ans.exact = true
	var c1 := change(s.r, s.up)
	var c2 := change(s.r2, s.up2)
	var added := Q.new((s.r if s.up else -s.r) + (s.r2 if s.up2 else -s.r2))
	var said := ["A price has %s, then %s." % [c1, c2]] if rep == "words" else ["%s, then %s" % [c1, c2]]
	var final := "So " + Answer.text(ans) + "."
	var out := {"asked": "Find the overall multiplier and the overall percentage change.", "lines": said, "answer": ans,
		"generic": [{"v0": Q.new(1).add(added.div(Q.new(100))), "v1": added}, {"v0": m1.add(m2), "v1": m1.add(m2).sub(Q.new(1)).mul(Q.new(100))},
			{"v0": M, "v1": pc.neg()}, {"v0": m1.mul(m1), "v1": m1.mul(m1).sub(Q.new(1)).mul(Q.new(100))}],
		"methods": {"one-multiplier": method([
			"The multipliers are %s and %s." % [D(m1), D(m2)], "%s × %s = %s" % [D(m1), D(m2), D(M)],
			"%s is a change of %s%%." % [D(M), D(pc)], final], ans.values)},
		"spot": {"lines": [
			"1 %s %d/100 = %s" % ["+" if s.up else "−", s.r, D(m1)], "1 %s %d/100 = %s" % ["+" if s.up2 else "−", s.r2, D(m2)],
			"%s × %s = %s" % [D(m1), D(m2), D(Q.new(1).add(added.div(Q.new(100))))], "%s − 1 = %s" % [D(Q.new(1).add(added.div(Q.new(100)))), D(added.div(Q.new(100)))]],
			"bad": 2, "ref": REF_ADD_PERCENTS, "why": "the two changes multiply: %s × %s = %s, not the sum of the percentages" % [D(m1), D(m2), D(M)]}}
	return out


func u_percent_from_amounts(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: int = s.r
	var up: bool = s.up
	var P: Q = s.P
	var A: Q = s.A
	var ans := Answer.make("pct", {"dir": "rise" if up else "fall", "v": Q.new(r)}, {"per": ""})
	ans.exact = true
	var other := "fall" if up else "rise"
	var diff := A.sub(P).abs_q()
	var out := {"asked": "Find the percentage change.", "answer": ans,
		"generic": [{"dir": other, "v": Q.new(r)}, {"dir": ans.values.dir, "v": diff.div(A).mul(Q.new(100))}, {"dir": ans.values.dir, "v": diff},
			{"dir": ans.values.dir, "v": A.div(P).mul(Q.new(100))}]}
	match rep:
		"words":
			out.lines = ["A price changes from %s to %s." % [D(P), D(A)]]
		"table":
			out.lines = ["The table shows an amount before and after a change."]
			out.table = {"rows": [["Before", [D(P)]], ["After", [D(A)]]]}
		_:
			out.lines = ["%s → %s" % [D(P), D(A)]]
	out.methods = {"one-multiplier": method([
		"The multiplier is %s ÷ %s = %s." % [D(A), D(P), D(s.m)], "%s = %d%% of the original: %s%d%%." % [D(s.m), 100 + (r if up else -r), "+" if up else "−", r],
		"So it is " + Answer.text(ans) + "."], ans.values)}
	return out
