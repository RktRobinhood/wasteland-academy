class_name ConditionalDiagramSituation
extends RefCounted
## The `conditional-diagram` situation (curriculum/question-types.json): a conditional probability
## read off a diagram, for t4-ext-conditional-diagram (FAL-777). Every answer is exact.
##
## generate() returns ask, paper (1) and:
##   from-table, from-venn   a, i, b, o, u: A only, both, B only, neither and the total;
##                           ctx (VennViews.CONTEXTS); given, "B" for P(A | B) or "A" for P(B | A)
##   tree-branch             pa, pba, pbn (Q): P(A), P(B | A), P(B | A′); want, "B|A" or "B′|A′"
##   second-draw             r, g: the counts of the two colours; same, whether the second is
##                           asked to match the first; ctx
##
## The given group holds at least a fifth of the total, and the slips (the grand total, the other
## group's total, the path's product, the starting bag) never give the answer or each other. The
## clean limits are the checker's too (E14CD_*).

const TRIES := 600


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "from-table")
	for i in TRIES:
		var s := _try(ask, rng)
		if not s.is_empty():
			s.ask = ask
			s.paper = 1
			return s
	push_error("ConditionalDiagramSituation: no clean situation for %s" % need)
	return {}


static func _try(ask: String, rng: Seeded) -> Dictionary:
	match ask:
		"from-table", "from-venn":
			var s := {"a": rng.int_in(2, 30), "i": rng.int_in(2, 20), "b": rng.int_in(2, 30), "o": rng.int_in(2, 30),
				"ctx": rng.int_in(0, VennViews.CONTEXTS.size() - 1), "given": rng.pick(["A", "B"])}
			s.u = s.a + s.i + s.b + s.o
			var ng: int = (s.i + s.b) if s.given == "B" else (s.i + s.a)
			var nother: int = (s.i + s.a) if s.given == "B" else (s.i + s.b)
			if ng * 5 < s.u or ng == nother:
				return {}
			var vals := [Q.new(s.i, ng), Q.new(s.i, s.u), Q.new(s.i, nother), Q.new(ng, s.u)]
			return s if distinct(vals) else {}
		"tree-branch":
			var pa := Q.new(rng.int_in(2, 8), 10)
			var pba := Q.new(rng.int_in(1, 19), 20)
			var pbn := Q.new(rng.int_in(1, 19), 20)
			var s := {"pa": pa, "pba": pba, "pbn": pbn, "want": rng.pick(["B|A", "B|A", "B′|A′"])}
			var one := Q.new(1)
			var vals: Array
			if s.want == "B|A":
				vals = [pba, pa.mul(pba), pbn, pa.mul(pba).add(one.sub(pa).mul(pbn))]
			else:
				vals = [one.sub(pbn), one.sub(pa).mul(one.sub(pbn)), one.sub(pba), pa.mul(one.sub(pba)).add(one.sub(pa).mul(one.sub(pbn)))]
			return s if distinct(vals) else {}
		"second-draw":
			var s := {"r": rng.int_in(3, 9), "g": rng.int_in(3, 9), "same": rng.chance(0.5), "ctx": rng.int_in(0, 3)}
			if s.r == s.g:
				return {}
			var n: int = s.r + s.g
			var top: int = s.r - 1 if s.same else s.g
			var vals := [Q.new(top, n - 1), Q.new(s.r * top, n * (n - 1)), Q.new(s.r if s.same else s.g, n)]
			if s.same:
				vals.append(Q.new(top, n))
			return s if distinct(vals) else {}
	return {}


static func distinct(vals: Array) -> bool:
	for x in vals.size():
		for y in range(x + 1, vals.size()):
			if vals[x].eq(vals[y]):
				return false
	return true


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
