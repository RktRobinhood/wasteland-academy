extends "res://tests/test_case.gd"
## The rest of the Quadratics region (FAL-414): the four exam types on the four
## situations that extend `quadratic` or stand beside it are built with every catalogue
## cell, their distractor misconceptions show up as options, and the new answer kinds
## (intervals, k values, two points) mark the way a student would type them. The SymPy
## checker (tools/check-answers) checks the maths.

## Cells per type, counted as tools/pedagogy.mjs counts them.
const CELLS := {"fn-discriminant": 45, "fn-curve-intersection-quadratic": 36, "fn-solve-quadratic": 20, "fn-quadratic-inequality": 19}
const SITUATION := {"fn-discriminant": "quadratic-parameter", "fn-curve-intersection-quadratic": "curve-and-line",
	"fn-solve-quadratic": "quadratic-equation", "fn-quadratic-inequality": "quadratic-inequality"}
## Distractor misconceptions no option can carry yet, and why.
const NOT_BUILT := {
	"SL2.4.intersection#0": "only the x-coordinates: the two-point answer has no place for a bare x pair",
	"SL2.10.solve-analytic#0": "the rational curve y = c + e/(x − r) is not built",
	"SL2.7.solve-equation#2": "only h + √d: the surd-root answer always shows ±",
}


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func test_the_four_types_are_built_with_every_cell() -> void:
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


func test_every_distractor_misconception_is_an_option() -> void:
	for t in CELLS:
		var ty := QuestionEngine.type_of(t)
		for m in ty.misconceptions:
			if m.as != "distractor" or NOT_BUILT.has(m.ref):
				continue
			for u in m.in:
				var found := false
				for c in QuestionEngine.cells(false, [t]).filter(func(x): return x.unknown == u):
					for seed in range(1, 40):
						var q := _make(t, u, c.rep, c.angle, seed, "mcq")
						if q.choices.any(func(o): return o.ref == m.ref):
							found = true
							break
					if found:
						break
				check(found, "%s: %s never appears on %s" % [t, m.ref, u])


func test_the_not_built_misconceptions_are_distractors() -> void:
	var refs := {}
	for t in CELLS:
		for m in QuestionEngine.type_of(t).misconceptions:
			refs[m.ref] = m.as
	for ref in NOT_BUILT:
		check_eq(refs.get(ref, ""), "distractor", ref)


## Writing an interval as one piece when it is two rays is caught as SL2.7.inequality#1.
func test_one_interval_for_two_rays_is_recognised() -> void:
	var done := false
	for seed in range(1, 60):
		var q := _make("fn-quadratic-inequality", "solve-against-zero", "equation", "sketch-roots", seed)
		var v: Dictionary = q.answer.values
		if v.shape != "outside":
			continue
		var r := QuestionEngine.mark(q, {"shape": "between", "lo": v.lo.key(), "hi": v.hi.key(), "ends": v.ends})
		check(not r.correct)
		check_eq(r.misconception, "SL2.7.inequality#1")
		var right := QuestionEngine.mark(q, {"shape": "outside", "lo": v.lo.key(), "hi": v.hi.key(), "ends": v.ends})
		check(right.correct, "the answer typed is right")
		done = true
		break
	check(done, "no two-ray answer in 60 seeds")


func test_two_points_in_either_order() -> void:
	var q := _make("fn-curve-intersection-quadratic", "meeting-points", "equation", "equate-and-solve", 3)
	var v: Dictionary = q.answer.values
	var fwd := {"x1": v.x1.key(), "y1": v.y1.key(), "x2": v.x2.key(), "y2": v.y2.key()}
	var back := {"x1": v.x2.key(), "y1": v.y2.key(), "x2": v.x1.key(), "y2": v.y1.key()}
	var mixed := {"x1": v.x1.key(), "y1": v.y2.key(), "x2": v.x2.key(), "y2": v.y1.key()}
	check(QuestionEngine.mark(q, fwd).correct)
	check(QuestionEngine.mark(q, back).correct, "the points can come in either order")
	check(not QuestionEngine.mark(q, mixed).correct, "but each point stays whole")


func test_a_tangent_touches_on_the_curve_and_the_line() -> void:
	for seed in range(1, 30):
		var q := _make("fn-discriminant", "tangent-contact-point", "equation", "discriminant-condition", seed)
		var g: Dictionary = q.given
		var v: Dictionary = q.answer.values
		var x: Q = v.x
		var on_curve := x.sq().add(Q.of(str(g.p).to_int()).mul(x)).add(str(g.r).to_int())
		var on_line := Q.of(str(g.m).to_int()).mul(x).add(v.k)
		check(on_curve.eq(v.y) and on_line.eq(v.y), "seed %d: the point is not on both" % seed)


func test_k_values_come_in_either_order() -> void:
	for seed in range(1, 40):
		var q := _make("fn-discriminant", "k-for-equal-roots", "equation", "discriminant-condition", seed)
		if q.answer.kind != "kvals":
			continue
		var v: Dictionary = q.answer.values
		check(QuestionEngine.mark(q, {"r1": v.r2.key(), "r2": v.r1.key()}).correct)
		return
	fail("no two-value k in 40 seeds")


func test_paper_two_contexts_need_a_calculator() -> void:
	var p2 := 0
	for seed in range(1, 81):
		var q := _make("fn-solve-quadratic", "solve-in-context", "words", "quadratic-formula", seed)
		check_eq(q.answer.kind == "measure", q.paper == 2, "seed %d: a measure answer is exactly a Paper 2 one" % seed)
		if q.answer.kind == "measure":
			p2 += 1
			check(q.situation.paper == 2, "a measure answer is Paper 2")
	# The exam has 3 Paper 1 parts to 1 Paper 2 part. Six of the type's 20 cells can be
	# Paper 2 (contexts, b^(2x) and logs), so each is Paper 2 five times in six (FAL-419).
	check(p2 >= 45 and p2 <= 75, "%d of 80 are Paper 2" % p2)
	for seed in range(1, 41):
		var q := _make("fn-solve-quadratic", "solve-in-context", "words", "factorise", seed)
		check(q.answer.kind == "number", "a factorising method gets a Paper 1 context")
		check_eq(q.paper, 1, "a factorising context is Paper 1")


## The cells with both papers (FAL-419): asked for Paper 2, the answer needs a
## calculator and is written and marked to 3 s.f., and the working uses the GDC or
## the formula; asked for Paper 1, it stays exact.
func test_forced_papers_are_exact_or_need_a_calculator() -> void:
	for t in CELLS:
		var ty := QuestionEngine.type_of(t)
		for c in QuestionEngine.cells(false, [t]):
			var ps := QuestionEngine.cell_papers(ty, c.unknown, c.rep, c.angle)
			for seed in [1, 2, 3, 4]:
				for p in ps:
					var q := QuestionEngine.make({"type": t, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "paper": p})
					var key := "%s seed %d Paper %d" % [c.key, seed, p]
					check_eq(q.paper, p, key)
					var ans: Dictionary = q.answer
					var nums: Array = Answer.slots(ans).filter(func(i): return i.has("slot")).map(func(i): return ans.values[i.slot])
					var rounded := nums.any(func(v): return v is Q and Answer.needs_rounding(v))
					if p == 1:
						check(ans.get("show", "") != "sf" and ans.kind != "measure", key + ": a Paper 1 answer is written to 3 s.f.")
						continue
					if c.unknown == "largest-integer":
						continue
					check(ans.get("show", "") == "sf" or ans.kind == "measure", key + ": not written to 3 s.f.")
					check(rounded and not ans.get("exact", false), key + ": the answer doesn't need a calculator")
					check("3 significant figures" in q.asked, key + ": doesn't ask for 3 s.f.")
					var r := QuestionEngine.mark(q, _sf_typed(ans))
					check(r.correct, key + ": the answer typed to 3 s.f. is marked wrong")
					var steps := " ".join(q.solutions[0].steps)
					check("GDC" in steps or "formula" in steps or "√" in steps, key + ": the working uses no calculator")


## Each typed number of an answer written to 3 s.f., as a student types it.
func _sf_typed(ans: Dictionary) -> Dictionary:
	var resp := {}
	for item in Answer.slots(ans):
		if item.has("slot"):
			resp[item.slot] = Fmt.sf(ans.values[item.slot]).replace("−", "-")
		else:
			resp[item.pick] = str(ans.values[item.pick])
	return resp


## fn-ext-quadratic-model has no exam counts: its recipe picks its own paper, but a
## view can force one where the cell can make it (a ball, not a pen or a table).
func test_a_quadratic_model_takes_a_forced_paper() -> void:
	var ty := QuestionEngine.type_of("fn-ext-quadratic-model")
	for c in QuestionEngine.cells(false, ["fn-ext-quadratic-model"]):
		var ps := QuestionEngine.cell_papers(ty, c.unknown, c.rep, c.angle)
		check(ps == [1] if c.rep == "table" or c.unknown == "form-area-model" else ps == [1, 2], c.key)
		for seed in [1, 2, 3]:
			for p in ps:
				var q := QuestionEngine.make({"type": ty.id, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "paper": p})
				check_eq(q.paper, p, c.key)
				check_eq(q.situation.a == "-49/10", p == 2, "%s seed %d: Paper %d with a = %s" % [c.key, seed, p, q.situation.a])


## "Another way" (FAL-310) keeps the numbers: a same_angle view of every
## fn-solve-quadratic unknown shows the situation the original angle made, whichever
## angle it switches to, including a switch to factorising on Paper 2 numbers.
func test_another_way_keeps_the_numbers() -> void:
	var t := QuestionEngine.type_of("fn-solve-quadratic")
	var p2_to_factorise := 0
	for c in QuestionEngine.cells(false, ["fn-solve-quadratic"]):
		var angles := QuestionEngine.angles_for(t, c.unknown)
		for from in angles:
			for to in angles:
				if from == to:
					continue
				for seed in range(0, 40):
					var a := _make("fn-solve-quadratic", c.unknown, c.rep, from, seed)
					var b := QuestionEngine.make({"type": "fn-solve-quadratic", "unknown": c.unknown, "rep": c.rep,
						"angle": to, "same_angle": from, "seed": seed})
					var key := "%s %s→%s seed %d" % [c.key, from, to, seed]
					check(not b.has("error"), "%s: %s" % [key, b.get("error")])
					if b.has("error"):
						return
					check_eq(b.lines, a.lines, key)
					check_eq(b.given, a.given, key)
					check_eq(Answer.text(b.answer), Answer.text(a.answer), key)
					check(b.solutions[0].angle == to, key + ": the view's own method comes first")
					if to == "factorise" and a.answer.kind == "measure":
						p2_to_factorise += 1
						check("factorising fails" in " ".join(b.solutions[0].steps), key + ": says factorising fails")
	check(p2_to_factorise > 0, "no Paper 2 context switched to factorising")


func test_count_from_sketch_can_hide_a_point() -> void:
	var hidden := false
	for seed in range(1, 80):
		var q := _make("fn-curve-intersection-quadratic", "count-from-sketch", "graph", "sketch-and-count", seed, "mcq")
		if q.choices.any(func(o): return o.ref == "SL2.4.intersection#1"):
			hidden = true
			break
	check(hidden, "the second point is never off the window")
