extends "res://tests/test_case.gd"
## Paper 1 or 2 on every question (FAL-419): each question carries its paper, a type
## the IB asks on both papers makes both in the exam's ratio, and the paper never
## changes a Paper 1 question's numbers.

const PER_TYPE := 1000
const WITHIN := 0.05


## The Paper 2 share of 1,000 questions of a type, across its cells in turn.
func _share(id: String) -> float:
	var cs := QuestionEngine.cells(false, [id])
	var p2 := 0
	for i in PER_TYPE:
		var c: Dictionary = cs[i % cs.size()]
		var q := QuestionEngine.make({"type": id, "unknown": c.unknown, "rep": c.rep, "angle": c.angle,
			"format": "value", "seed": 1 + i / cs.size()})
		if q.has("error"):
			fail("%s: %s" % [c.key, q.error])
			continue
		if q.paper == 2:
			p2 += 1
	return float(p2) / PER_TYPE


func test_every_question_has_a_paper() -> void:
	for id in QuestionEngine.built_types():
		for c in QuestionEngine.cells(false, [id]):
			var q := QuestionEngine.make({"type": id, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": 1})
			check(q.has("error") or q.get("paper") in [1, 2], "%s has no paper" % c.key)
			var forced := QuestionEngine.cell_papers(QuestionEngine.type_of(id), c.unknown, c.rep, c.angle)
			for p in forced:
				var f := QuestionEngine.make({"type": id, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": 2,
					"paper": p})
				check(f.has("error") or f.paper == p, "%s asked for Paper %d gives Paper %s" % [c.key, p, f.get("paper")])


func test_the_paper_ratio_matches_the_exam() -> void:
	for id in QuestionEngine.built_types():
		var t := QuestionEngine.type_of(id)
		var want := QuestionEngine.paper_share(t)
		if want < 0.0:
			continue
		var got := _share(id)
		check(absf(got - want) <= WITHIN, "%s: %d%% Paper 2, the exam has %d%%" % [id, roundi(got * 100), roundi(want * 100)])


func test_a_boss_chain_is_on_one_paper() -> void:
	var t := QuestionEngine.type_of("fn-exponential-model")
	var steps: Array = []
	for u in t.unknowns.slice(0, 2):
		steps.append({"type": t.id, "unknown": u.id})
	var chain := QuestionEngine.make_chain(steps, 4)
	if chain.has("error"):
		return
	for part in chain.parts:
		check_eq(part.paper, 2, "an exponential model is Paper 2")


func test_concept_probes_are_paper_1() -> void:
	var q := QuestionEngine.probe("fn-quadratic-features", 0)
	check(q.has("error") or q.paper == 1)
