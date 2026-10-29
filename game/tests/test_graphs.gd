extends "res://tests/test_case.gd"
## The Graphs and key features region (FAL-420): its types are built with every
## catalogue cell on their situations, their distractor misconceptions show up as
## options, pick the graph plays as four cards (each wrong card one mistake, tagged
## with its misconception), and GDC answers mark to 3 s.f. The SymPy checker
## (tools/check-answers) checks the maths.

## Cells per type, counted as tools/pedagogy.mjs counts them.
const CELLS := {"fn-sketch-gdc": 42, "fn-gdc-features": 36, "fn-gdc-intersection": 29, "fn-gdc-optimise-combined": 27,
	"fn-gdc-solve-equation": 33, "fn-sketch-from-features": 30,
	"fn-concept-solutions-as-intersections": 17, "fn-ext-inequality-graphical": 11}
const SITUATION := {"fn-sketch-gdc": "gdc-curve", "fn-gdc-features": "gdc-curve", "fn-gdc-intersection": "gdc-two-curves",
	"fn-gdc-optimise-combined": "gdc-combined", "fn-gdc-solve-equation": "gdc-context-equation",
	"fn-sketch-from-features": "graph-from-features", "fn-concept-solutions-as-intersections": "gdc-two-curves",
	"fn-ext-inequality-graphical": "gdc-inequality"}
## Distractor misconceptions no option can carry yet ("type|ref"), and why.
const NOT_BUILT := {
	"fn-sketch-gdc|SL2.10.number-of-solutions#2": "counting the asymptote's level needs a curve that levels off; the gdc-curve asymptote is vertical",
	"fn-gdc-optimise-combined|SL2.4.max-min#1": "D's greatest value is always its turning value here (D is concave for the towns, and starts at 0 for the drugs), so no endpoint beats it",
}
## What each wrong graph's mistake is, as a misconception ref ("" for none in the catalogue).
## (fn-sketch-from-features' flipped parabola is SL2.6.sketch#0 only when a < 0, and its
## past-domain is a velocity's, with no misconception: those two are checked by kind.)
const MISTAKES := {"past-domain": "SL2.3.sketch-from-equation#1", "squashed": "SL2.3.sketch-from-equation#2",
	"through-asymptote": "SL2.3.sketch-from-equation#0", "reflected": "", "mirrored": "",
	"pointed": "SL2.6.sketch#1", "vertex-on-axis": "SL2.6.sketch#2", "below-zero": "SL2.3.sketch-from-info#1",
	"below-room": "SL2.3.sketch-from-info#1", "turns-back": "SL2.3.sketch-from-info#2", "doubles-back": "SL2.3.sketch-from-info#0",
	"max-moved": "", "swapped": "", "amplitude": "", "shifted": "", "steady": "", "warming": "",
	"sideways": "SL2.3.sum-difference#0", "difference": "", "constant-lift": ""}


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
				check_eq(q.choices.size(), 4, c.key)
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
				if c.rep == "graph" and q.format != "pick-the-graph":
					check(q.graph != null, c.key + ": no graph")
				if c.rep == "table":
					check(q.table != null, c.key + ": no table")


## The GDC types are Paper 2; sketching from exact features is Paper 1 (stats.paper).
func test_each_type_is_on_its_paper() -> void:
	for t in CELLS.keys().filter(func(id): return QuestionEngine.type_of(id).source == "exam"):
		var want := 1 if t == "fn-sketch-from-features" else 2
		for c in QuestionEngine.cells(false, [t]):
			var q := _make(t, c.unknown, c.rep, c.angle, 4, "mcq")
			check_eq(q.paper, want, c.key)


func test_every_distractor_misconception_is_an_option() -> void:
	for t in CELLS:
		var ty := QuestionEngine.type_of(t)
		for i in ty.misconceptions.size():
			var m: Dictionary = ty.misconceptions[i]
			var ref: String = m.get("ref", "%s#%d" % [t, i])
			if m.as != "distractor" or NOT_BUILT.has("%s|%s" % [t, ref]):
				continue
			for u in m.in:
				var found := false
				for c in QuestionEngine.cells(false, [t]).filter(func(x): return x.unknown == u):
					for seed in range(1, 60):
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
			check_eq(a.prompt + str(a.lines) + a.answer_text, b.prompt + str(b.lines) + b.answer_text, c.key)


## Every unknown whose answer is a sketch, by type.
const SKETCHES := {"fn-sketch-gdc": ["sketch-on-domain", "sketch-with-asymptote", "sketch-from-table"],
	"fn-sketch-from-features": ["sketch-quadratic", "sketch-on-interval", "sketch-with-asymptote", "sketch-trig-on-interval",
		"sketch-from-conditions", "sketch-from-context"],
	"fn-gdc-optimise-combined": ["sum-graph"]}


func test_pick_the_graph_is_four_cards_each_wrong_one_a_mistake() -> void:
	for t in SKETCHES:
		for c in QuestionEngine.cells(false, [t]).filter(func(x): return x.unknown in SKETCHES[t]):
			for seed in range(1, 6):
				# Whatever format is asked, a graph answer plays as pick the graph.
				var q := _make(t, c.unknown, c.rep, c.angle, seed, "value" if seed % 2 == 0 else "mcq")
				check_eq(q.format, "pick-the-graph", c.key)
				check(QuestionEngine.is_choice(q), c.key)
				check_eq(q.graphs.size(), 4, c.key)
				check_eq(q.choices.map(func(o): return o.text), ["Graph A", "Graph B", "Graph C", "Graph D"], c.key)
				check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
				for i in 4:
					var o: Dictionary = q.choices[i]
					check(q.graphs[i].get("card", false), c.key + ": not a card")
					if o.correct:
						check(q.answer_text == o.text, c.key)
						continue
					if t == "fn-sketch-from-features" and o.mistake in ["flipped", "past-domain"]:
						check(o.ref in ["", "SL2.6.sketch#0"], c.key)
					else:
						check(MISTAKES.has(o.mistake), "%s: mistake %s" % [c.key, o.mistake])
						check_eq(o.ref, MISTAKES.get(o.mistake, "?"), c.key)
					check(o.why != "", c.key + ": no why")
					# Picking a wrong graph logs its misconception.
					var r := QuestionEngine.mark(q, {"choice": i})
					check(not r.correct and r.misconception == o.ref, c.key)
				check(q.reason != "", c.key + ": no reason")
				# The dots don't give the answer away: if the right card marks points, so
				# does every wrong one.
				var right_i: int = q.choices.find(q.choices.filter(func(o): return o.correct)[0])
				if not q.graphs[right_i].points.is_empty():
					for i in 4:
						check(not q.graphs[i].points.is_empty(), "%s seed %d: %s has no points" % [c.key, seed, q.choices[i].text])
				check(QuestionEngine.mark(q, {"choice": q.choices.find(q.choices.filter(func(o): return o.correct)[0])}).correct, c.key)


func test_zeros_mark_in_any_order_to_three_figures() -> void:
	var q := _first("fn-gdc-features", "zeros-gdc")
	var v: Dictionary = q.answer.values
	var n := int(v.n)
	var typed := {}
	for i in n:
		typed["x%d" % i] = Fmt.sf(v["x%d" % (n - 1 - i)]).replace("−", "-")
	check(QuestionEngine.mark(q, typed).correct, "%s typed backwards" % q.answer_text)
	var two := {}
	for i in n:
		two["x%d" % i] = Fmt.sf(v["x%d" % i], 2).replace("−", "-")
	var r := QuestionEngine.mark(q, two)
	check(not r.correct and r.glancing, "%s to 2 s.f. is a glancing hit" % q.answer_text)


func test_a_turning_point_to_two_figures_is_the_trap_and_its_misconception() -> void:
	var seen := false
	for seed in range(1, 20):
		var q := _first("fn-gdc-features", "turning-point-coordinates", "mcq", seed)
		for o in q.choices:
			if o.get("trap", false):
				seen = true
				check_eq(o.ref, "SL2.4.max-min#2", q.answer_text)
				var r := QuestionEngine.mark(q, {"choice": q.choices.find(o)})
				check(r.glancing and r.misconception == "SL2.4.max-min#2", o.text)
	check(seen, "no 2 s.f. trap")


func test_the_greatest_value_is_at_an_endpoint() -> void:
	for seed in range(1, 15):
		var q := _first("fn-gdc-features", "greatest-on-domain", "mcq", seed)
		var s: Dictionary = q.situation
		check_eq(s.hi.at, "end", "seed %d" % seed)


func test_the_boss_chains_are_one_situation() -> void:
	for t in CELLS.keys().filter(func(id): return QuestionEngine.type_of(id).source == "exam"):
		var windows := Dungeon.chain_windows(t)
		check(not windows.is_empty(), "%s has no boss chain" % t)
		for steps in windows:
			var c := QuestionEngine.make_chain(steps, 5)
			check(not c.has("error"), str(c.get("error")))


func test_numbers_use_a_true_minus() -> void:
	for t in CELLS:
		for c in QuestionEngine.cells(false, [t]):
			var q := _make(c.type, c.unknown, c.rep, c.angle, 3, "mcq")
			var texts: Array = [q.prompt] + q.lines + q.choices.map(func(o): return o.text)
			for x in texts:
				check(not RegEx.create_from_string("(?<![A-Za-z])-\\d").search(x), "%s: %s" % [c.key, x])
