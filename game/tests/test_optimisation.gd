extends "res://tests/test_case.gd"
## The optimisation situation (FAL-739): t5-optimisation-modelling is built with every catalogue
## cell, every cell makes four options with one right on each paper it can, Paper 1 is exact and
## Paper 2 is to 3 s.f., the GDC and a route are Paper 2 and a closest point Paper 1, a tray's
## second root is outside the sheet, a figure appears only in "diagram", and every misconception
## shows up. The SymPy checker (tools/check-answers) checks the maths.

const TYPE := "t5-optimisation-modelling"
## Cells, counted as tools/pedagogy.mjs counts them.
const CELLS := 39


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "value", paper: int = 0) -> Dictionary:
	var view := {"type": TYPE, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format}
	if paper > 0:
		view.paper = paper
	return QuestionEngine.make(view)


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	var t := QuestionEngine.type_of(TYPE)
	check_eq(t.unknowns.size(), 15)
	var skills := {}
	for u in t.unknowns:
		for s in u.skills:
			skills[s] = true
	check(skills.has("SL5.8.optimisation-modelling"), "the skill has a question")


func test_every_cell_makes_a_question_on_each_of_its_papers() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		check(QuestionEngine.extra_formats(TYPE, c.unknown, c.angle).is_empty(), c.key + " offers an extra format")
		for p in QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle):
			for f in ["value", "mcq"]:
				for seed in [1, 2, 3, 4, 5]:
					var q := _make(c.unknown, c.rep, c.angle, seed, f, p)
					check(not q.has("error"), "%s Paper %d: %s" % [c.key, p, q.get("error")])
					if q.has("error"):
						break
					check_eq(q.paper, p, c.key)
					check_eq(q.choices.size(), 4, c.key)
					check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key)
					var texts := {}
					for o in q.choices:
						texts[o.text] = true
					check_eq(texts.size(), 4, "%s: two options read the same" % c.key)
					check_eq(q.solutions[0].angle, c.angle, c.key)
					check_eq(q.graph != null, c.rep == "diagram", "%s: a figure only in diagram" % c.key)


func test_the_papers_follow_the_bank() -> void:
	var t := QuestionEngine.type_of(TYPE)
	for c in QuestionEngine.cells(false, [TYPE]):
		var ps := QuestionEngine.cell_papers(t, c.unknown, c.rep, c.angle)
		if c.unknown == "closest-point":
			check_eq(ps, [1], c.key)
		elif c.unknown.begins_with("route-") or c.angle == "gdc-graph-optimum":
			check_eq(ps, [2], c.key)
		else:
			check_eq(ps, [1, 2], c.key)


func test_same_seed_same_question_and_seeds_vary() -> void:
	for c in QuestionEngine.cells(false, [TYPE]):
		var a := _make(c.unknown, c.rep, c.angle, 7, "mcq")
		check_eq(a.prompt, _make(c.unknown, c.rep, c.angle, 7, "mcq").prompt, c.key)
		var answers := {}
		for seed in range(1, 13):
			answers[_make(c.unknown, c.rep, c.angle, seed, "mcq").answer_text] = true
		check(answers.size() > 2, "%s: only %d different answers in 12 seeds" % [c.key, answers.size()])


func test_paper_1_is_exact_and_paper_2_is_rounded() -> void:
	for seed in range(1, 21):
		var one := _make("optimum-value", "words", "differentiate-and-test", seed, "value", 1)
		check(one.answer.exact, "Paper 1 is marked exactly")
		var two := _make("optimum-value", "words", "gdc-graph-optimum", seed, "value", 2)
		check(not two.answer.exact, "Paper 2 is to 3 s.f.")


func test_a_trays_second_root_is_outside_the_sheet() -> void:
	for seed in range(1, 31):
		for p in [1, 2]:
			var q := _make("box-best-cut", "words", "differentiate-and-test", seed, "mcq", p)
			var s: Dictionary = q.given
			var bits: PackedStringArray = str(s.other).split("/")
			var other := float(bits[0]) / (float(bits[1]) if bits.size() > 1 else 1.0)
			check(other > mini(s.w, s.h) / 2.0, "the second root %s fits the sheet" % str(other))


func test_hand_values() -> void:
	var s := {"fam": "paddock", "n": 3, "P": 192, "paper": 1}
	check_eq(OptimisationSituation.at_q(OptimisationSituation.terms(s), Q.new(8)).key(), "48")
	var c := {"fam": "can", "paper": 1, "e": 2, "rate_side": 1, "k": 54}
	check_eq(OptimisationSituation.at_q(OptimisationSituation.terms(c), Q.new(3)).key(), "54")
	var b := {"fam": "box", "w": 24, "h": 45}
	check_eq(OptimisationSituation.at_q(OptimisationSituation.terms(b), Q.new(5)).key(), "2450")
	var d := OptimisationSituation.diff(OptimisationSituation.terms(b))
	check(OptimisationSituation.at_q(d, Q.new(5)).is_zero(), "x = 5 is stationary on a 24 by 45 sheet")


func test_every_misconception_shows_up() -> void:
	var t := QuestionEngine.type_of(TYPE)
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 41):
			var q := _make(c.unknown, c.rep, c.angle, seed, "mcq")
			for o in q.choices:
				if o.ref != "":
					seen[o.ref] = true
	for i in t.misconceptions.size():
		var ref: String = t.misconceptions[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never shows up: %s" % [ref, t.misconceptions[i].text])
