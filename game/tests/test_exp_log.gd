extends "res://tests/test_case.gd"
## The Exponentials and logs region (FAL-418): its exam types are built with every
## catalogue cell on their situations, their distractor misconceptions show up as
## options, and the region's answer kinds (an exact k as m·ln r, a percentage change,
## a model P₀(a)^t, and C, A and k of a limited growth model) mark the way a student
## would type them. The SymPy checker (tools/check-answers) checks the maths.

## Cells per type, counted as tools/pedagogy.mjs counts them.
const CELLS := {"fn-exponential-model": 77, "fn-exp-log-inverse-composite": 49, "fn-log-of-quadratic": 71,
	"fn-log-function-features": 38, "fn-pre-percent-multiplier": 22, "fn-ext-exp-graph": 28,
	"fn-concept-growth-patterns": 17, "fn-link-multiplicative-growth": 53}
const SITUATION := {"fn-exponential-model": "exp-model", "fn-exp-log-inverse-composite": "exp-log-pair",
	"fn-log-of-quadratic": "log-quadratic", "fn-log-function-features": "log-function",
	"fn-pre-percent-multiplier": "fn-pre-percent-multiplier", "fn-ext-exp-graph": "exp-log-pair",
	"fn-concept-growth-patterns": "exp-growth-vs-linear", "fn-link-multiplicative-growth": "fn-link-multiplicative-growth"}
## Distractor misconceptions no option can carry yet ("type|ref"), and why.
const NOT_BUILT := {
	"fn-log-of-quadratic|SL1.5.exp-log-form#1": "reading log_k G = n as n^k = G gives k = ln G/ln n, never a whole number here, so no exact option shows it",
	"fn-log-of-quadratic|SL2.7.solve-equation#2": "only h + √d: the surd-root answer always shows ± (as in fn-solve-quadratic)",
}


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func _first(type: String, unknown: String, format: String = "value", seed: int = 1) -> Dictionary:
	var c: Dictionary = QuestionEngine.cells(false, [type]).filter(func(x): return x.unknown == unknown)[0]
	return _make(type, unknown, c.rep, c.angle, seed, format)


func test_the_types_are_built_with_every_cell() -> void:
	var built := QuestionEngine.built_types()
	for t in CELLS:
		check(t in built, "%s is not built" % t)
		check_eq(QuestionEngine.cells(false, [t]).size(), CELLS[t], t)


func test_every_cell_makes_a_question_on_its_situation() -> void:
	for t in CELLS:
		for c in QuestionEngine.cells(false, [t]):
			for seed in [1, 2, 3]:
				var q := _make(t, c.unknown, c.rep, c.angle, seed)
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, SITUATION[t], c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
				if c.rep == "graph":
					check(q.graph != null, c.key + ": no graph")
				if c.rep == "table":
					check(q.table != null, c.key + ": no table")


func test_every_distractor_misconception_is_an_option() -> void:
	for t in CELLS:
		var ty := QuestionEngine.type_of(t)
		for i in ty.misconceptions.size():
			var m: Dictionary = ty.misconceptions[i]
			# A misconception without a ref of its own is "<type id>#<index>".
			var ref: String = m.get("ref", "%s#%d" % [t, i])
			if m.as != "distractor" or NOT_BUILT.has("%s|%s" % [t, ref]):
				continue
			for u in m.in:
				var found := false
				for c in QuestionEngine.cells(false, [t]).filter(func(x): return x.unknown == u):
					for seed in range(1, 40):
						var q := _make(t, u, c.rep, c.angle, seed, "mcq")
						if q.choices.any(func(o): return o.ref == ref):
							found = true
							break
					if found:
						break
				check(found, "%s never offers %s" % [u, ref])


func test_same_seed_same_question() -> void:
	for t in CELLS:
		for c in QuestionEngine.cells(false, [t]):
			var a := _make(t, c.unknown, c.rep, c.angle, 7)
			var b := _make(t, c.unknown, c.rep, c.angle, 7)
			check_eq(a.prompt + str(a.lines), b.prompt + str(b.lines), c.key)


func test_an_exact_k_is_marked_by_value() -> void:
	var q := _first("fn-exponential-model", "k-from-half-life")
	var v: Dictionary = q.answer.values
	check(QuestionEngine.mark(q, {"m": v.m.key(), "r": "2"}).correct, "the answer itself")
	# −(1/T) ln 2 is (1/T) ln(1/2): the same k, written the other way.
	check(QuestionEngine.mark(q, {"m": v.m.neg().key(), "r": "1/2"}).correct, "(1/T) ln ½ is the same k")
	check(not QuestionEngine.mark(q, {"m": v.m.neg().key(), "r": "2"}).correct, "the sign matters")
	check(not QuestionEngine.mark(q, {"m": v.m.key(), "r": "0"}).correct, "ln 0 is not a number")


func test_a_percentage_change_needs_its_direction() -> void:
	var q := _first("fn-exponential-model", "interpret-factor")
	var v: Dictionary = q.answer.values
	var other := "fall" if v.dir == "rise" else "rise"
	check(QuestionEngine.mark(q, {"dir": v.dir, "v": v.v.key()}).correct)
	check(not QuestionEngine.mark(q, {"dir": other, "v": v.v.key()}).correct, "a rise is not a fall")
	check(q.answer_text.begins_with("a %s of " % v.dir), q.answer_text)


func test_a_model_from_a_table_is_typed_as_decimals() -> void:
	var q := _first("fn-exponential-model", "model-from-table")
	var v: Dictionary = q.answer.values
	check(QuestionEngine.mark(q, {"p0": Fmt.dec(v.p0), "a": Fmt.dec(v.a)}).correct, q.answer_text)
	check(not QuestionEngine.mark(q, {"p0": Fmt.dec(v.a), "a": Fmt.dec(v.p0)}).correct, "start and factor swapped")


func test_a_limited_model_takes_k_to_three_figures() -> void:
	var q := _first("fn-exponential-model", "model-from-graph")
	var v: Dictionary = q.answer.values
	var k3 := Fmt.sf(v.k).replace("−", "-")
	check(QuestionEngine.mark(q, {"C": v.C.key(), "A": v.A.key(), "k": k3}).correct, q.answer_text)
	check(not QuestionEngine.mark(q, {"C": v.C.key(), "A": v.A.neg().key(), "k": k3}).correct, "the sign of A matters")


func test_a_time_is_never_on_a_rounding_edge_and_whole_units_round_up() -> void:
	for seed in range(1, 60):
		var q := _first("fn-exponential-model", "whole-units-inequality", "value", seed)
		var t: float = float(q.situation.tL)
		check_eq(int(q.answer.values.v.n), ceili(t), "seed %d" % seed)


func test_the_boss_chains_are_one_situation() -> void:
	for t in CELLS.keys().filter(func(id): return QuestionEngine.type_of(id).source == "exam"):
		var windows := Dungeon.chain_windows(t)
		check(not windows.is_empty(), "%s has no boss chain" % t)
		for steps in windows:
			var c := QuestionEngine.make_chain(steps, 5)
			check(not c.has("error"), str(c.get("error")))


func test_an_inverse_is_typed_as_its_two_shifts() -> void:
	var q := _first("fn-exp-log-inverse-composite", "inverse-of-log")
	var v: Dictionary = q.answer.values
	check(QuestionEngine.mark(q, {"p": v.p.key(), "q": v.q.key()}).correct, q.answer_text)
	check(not QuestionEngine.mark(q, {"p": v.q.key(), "q": v.p.key()}).correct or v.p.eq(v.q), "the shifts swapped")


func test_an_inverse_offers_one_over_f() -> void:
	var found := false
	for seed in range(1, 20):
		var q := _first("fn-exp-log-inverse-composite", "inverse-of-exponential", "mcq", seed)
		if q.choices.any(func(o): return o.text.contains("= 1/(") and o.ref == "SL2.5.find-inverse#0"):
			found = true
	check(found, "1/f(x) is never offered as f⁻¹")


func test_numbers_use_a_true_minus() -> void:
	for c in QuestionEngine.cells(false, ["fn-exp-log-inverse-composite"]):
		for seed in [1, 2, 3, 4]:
			var q := _make(c.type, c.unknown, c.rep, c.angle, seed, "mcq")
			var texts: Array = [q.prompt] + q.lines + q.choices.map(func(o): return o.text)
			for t in texts:
				check(not RegEx.create_from_string("-\\d").search(t), "%s: %s" % [c.key, t])


func test_a_point_is_named_once_when_the_two_key_points_meet() -> void:
	# FAL-564: with h = 0 the y-intercept is also where the exponent is 0, and with
	# f(0) = 0 the inverse's x-intercept is the origin too.
	var pt := RegEx.create_from_string("\\((−?[\\d/]+), (−?[\\d/]+)\\)")
	var met := {"pick-graph": 0, "inverse-graph": 0}
	for c in QuestionEngine.cells(false, ["fn-ext-exp-graph", "fn-exp-log-inverse-composite"]):
		if not c.unknown in ["pick-graph", "inverse-graph"]:
			continue
		for seed in range(1, 41):
			var q := _make(c.type, c.unknown, c.rep, c.angle, seed, "mcq")
			var texts: Array = q.lines + q.choices.map(func(o): return o.text)
			for sol in q.solutions:
				texts += sol.steps
			for t in texts:
				var seen := {}
				for m in pt.search_all(t):
					check(not seen.has(m.get_string()), "%s seed %d: %s" % [c.key, seed, t])
					seen[m.get_string()] = true
			if (c.unknown == "pick-graph" and q.situation.h == 0) or (c.unknown == "inverse-graph" and texts.any(func(t): return t.contains("origin"))):
				met[c.unknown] += 1
	for u in met:
		check(met[u] > 0, "%s: no seed puts the two key points together" % u)


func test_the_error_spot_is_adding_the_percentages() -> void:
	var c: Dictionary = QuestionEngine.cells(false, ["fn-pre-percent-multiplier"]).filter(func(x): return x.unknown == "repeated-changes")[0]
	for seed in range(1, 10):
		var q := _make(c.type, c.unknown, c.rep, c.angle, seed, "error-spot")
		check(not q.has("error"), str(q.get("error")))
		check_eq(q.spot.bad, 2, "the multiplication of the two multipliers is the first wrong line")


func test_exp_log_pair_paper_2_needs_a_calculator() -> void:
	# FAL-419: four cells of fn-exp-log-inverse-composite have a Paper 2 version, asked
	# to 3 s.f. with the rounding trap; fn-ext-exp-graph is Paper 1 only.
	var t := QuestionEngine.type_of("fn-exp-log-inverse-composite")
	var p2 := 0
	for c in QuestionEngine.cells(false, [t.id]):
		var papers := QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle)
		if papers == [1]:
			continue
		p2 += 1
		check(c.rep == "equation" and c.unknown in ExpLogPairViews.PAPER2, c.key)
		for seed in range(1, 9):
			var q := _make(t.id, c.unknown, c.rep, c.angle, seed, "mcq")
			var f := QuestionEngine.make({"type": t.id, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed,
				"format": "mcq", "paper": 2})
			check_eq(f.paper, 2, c.key)
			check(f.answer.show == "sf" and not f.answer.get("exact", false), "%s: %s is not to 3 s.f." % [c.key, f.answer_text])
			check(Answer.needs_rounding(f.answer.values.v), "%s: %s needs no calculator" % [c.key, f.answer_text])
			check(Answer.rounds_clearly(f.answer.values.v.to_float()), "%s: %s is on a rounding edge" % [c.key, f.answer_text])
			# The 2 s.f. trap, unless it reads as the answer itself (9.9 for 9.90).
			var v: Q = f.answer.values.v
			var two: Q = Answer.parse_number(Fmt.sf(v, 2).replace("−", "-")).q
			var three: Q = Answer.parse_number(Fmt.sf(v).replace("−", "-")).q
			check(two.eq(three) or f.choices.any(func(o): return o.get("trap", false)), "%s: no rounding trap" % c.key)
			check(f.solutions.all(func(sol): return sol.steps.any(func(st): return st.contains("GDC"))), c.key + ": no GDC step")
			# Typed to 3 s.f., right; typed to 2 s.f. (where that rounds), a glancing hit.
			var typed := QuestionEngine.make({"type": t.id, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed,
				"paper": 2})
			check(QuestionEngine.mark(typed, {"v": three.key()}).correct, "%s: %s typed is wrong" % [c.key, Fmt.sf(v)])
			# (Answer.number_glancing: only a coarser decimal, so 120 for 124 is a plain miss.)
			if not two.eq(three) and not two.is_int():
				var r := QuestionEngine.mark(typed, {"v": two.key()})
				check(not r.correct and r.glancing, "%s: %s typed is not glancing" % [c.key, Fmt.sf(v, 2)])
			var p1 := QuestionEngine.make({"type": t.id, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed,
				"format": "mcq", "paper": 1})
			check(p1.paper == 1 and p1.answer.get("exact", false), "%s: Paper 1 is not exact" % c.key)
			if q.paper == 1:
				check_eq(q.prompt + str(q.lines), p1.prompt + str(p1.lines), c.key + ": Paper 1 changed")
	check_eq(p2, 11)
	var ext := QuestionEngine.type_of("fn-ext-exp-graph")
	for c in QuestionEngine.cells(false, [ext.id]):
		check_eq(QuestionEngine.cell_papers(ext, c.unknown, c.rep, c.angle), [1], c.key)


func test_exp_log_pair_paper_1_numbers_do_not_change() -> void:
	for mode in ["log", "esolve", "exp", "family", "ineq", "expgraph"]:
		for seed in range(1, 21):
			var a := ExpLogPairSituation.generate(Seeded.new("p|%d" % seed), {"mode": mode})
			var b := ExpLogPairSituation.generate(Seeded.new("p|%d" % seed), {"mode": mode, "paper": 1})
			check_eq(b.paper, 1)
			b.erase("paper")
			check_eq(str(ExpLogPairSituation.export(a)), str(ExpLogPairSituation.export(b)), mode)
