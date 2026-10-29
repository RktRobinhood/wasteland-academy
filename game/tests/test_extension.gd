extends "res://tests/test_case.gd"
## The Quadratics extension types (FAL-459): the four fn-pre-* prior-learning types,
## fn-ext-quadratic-model and the two fn-link-* types are built with every catalogue
## cell, their distractor misconceptions show up as options, and the three extra
## formats (error-spot, method-pick, true-false-reason) keep their rules. The SymPy
## checker (tools/check-answers) checks the maths.

## Cells per type, counted as tools/pedagogy.mjs counts them.
const CELLS := {"fn-ext-quadratic-model": 27, "fn-pre-expand": 17, "fn-pre-factorise": 16, "fn-pre-surds": 8,
	"fn-pre-linear-inequalities": 10, "fn-link-symmetry": 38, "fn-link-equivalent-forms": 28}
## Distractor misconceptions no option carries, and why.
const NOT_BUILT := {
	"SL4.9.symmetry-probability#2": "symmetry about 0 gives no number to offer: σ is not known",
	"SL4.9.central-interval#1": "the question asks for the two ends, not the half-width",
	"SL3.6.double-angle-values#1": "cos 2x = 1 − sin²x gives roots that are not sines of special angles, so no multiples of π",
}


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "value") -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


func test_the_seven_types_are_built_with_every_cell() -> void:
	var built := QuestionEngine.built_types()
	for t in CELLS:
		check(t in built, "%s is not built" % t)
		check_eq(QuestionEngine.cells(false, [t]).size(), CELLS[t], t)


func test_every_cell_makes_a_question_with_its_representation() -> void:
	for t in CELLS:
		for c in QuestionEngine.cells(false, [t]):
			for seed in [1, 2, 3]:
				var q := _make(t, c.unknown, c.rep, c.angle, seed)
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if q.has("error"):
					break
				check_eq(q.situation_id, QuestionEngine.type_of(t).situation, c.key)
				check_eq(q.choices.size(), 4, c.key + " options")
				for sol in q.solutions:
					check(sol.steps.size() >= 2 and sol.steps.size() <= 5, "%s: %d steps" % [c.key, sol.steps.size()])
				if c.angle != "any":
					check_eq(q.solutions[0].angle, c.angle, c.key + ": the asked method comes first")
				if c.rep == "graph":
					check(q.graph != null or q.table != null, c.key + ": no graph")
				if c.rep == "table":
					check(q.table != null, c.key + ": no table")


func test_every_distractor_misconception_is_an_option() -> void:
	for t in CELLS:
		var ty := QuestionEngine.type_of(t)
		var ms: Array = ty.misconceptions
		for i in ms.size():
			var ref: String = ms[i].get("ref", "%s#%d" % [t, i])
			if ms[i].as != "distractor" or NOT_BUILT.has(ref):
				continue
			for u in ms[i].in:
				var found := false
				for c in QuestionEngine.cells(false, [t]).filter(func(x): return x.unknown == u):
					for seed in range(1, 150):
						var q := _make(t, u, c.rep, c.angle, seed, "mcq")
						if q.choices.any(func(o): return o.ref == ref):
							found = true
							break
					if found:
						break
				check(found, "%s: %s never appears on %s" % [t, ref, u])


func test_the_not_built_misconceptions_are_distractors() -> void:
	var refs := {}
	for t in CELLS:
		for m in QuestionEngine.type_of(t).misconceptions:
			if m.has("ref"):
				refs[m.ref] = m.as
	for ref in NOT_BUILT:
		check_eq(refs.get(ref, ""), "distractor", ref)


## A misconception without a catalogue ref is logged as <type id>#<index>.
func test_a_misconception_without_a_ref_has_one() -> void:
	var t := QuestionEngine.type_of("fn-pre-expand")
	check_eq(QuestionEngine.misconception_text(t, "fn-pre-expand#0"), t.misconceptions[0].text)
	check_eq(QuestionEngine.misconception_text(QuestionEngine.type_of("fn-ext-quadratic-model"), "SL2.6.model#1"),
		"Keeps a negative time or length when solving h(t) = 0")
	check_eq(QuestionEngine.misconception_text(t, "nope"), "")


# ── The extra formats ────────────────────────────────────────

## Every extra format a cell offers is in its type's catalogue formats, and exam types
## offer none (their questions are as before).
func test_extra_formats_only_where_the_catalogue_lists_them() -> void:
	for id in QuestionEngine.built_types():
		var t := QuestionEngine.type_of(id)
		for c in QuestionEngine.cells(false, [id]):
			var extra := QuestionEngine.extra_formats(id, c.unknown, c.angle)
			for f in extra:
				check(f in t.formats, "%s offers %s" % [c.key, f])
			if t.source == "exam":
				check(extra.is_empty(), c.key + " is an exam cell with an extra format")


func test_every_extra_format_plays_as_four_options() -> void:
	for t in CELLS:
		for c in QuestionEngine.cells(false, [t]):
			for f in QuestionEngine.extra_formats(t, c.unknown, c.angle):
				for seed in [1, 2, 3, 4]:
					var q := _make(t, c.unknown, c.rep, c.angle, seed, f)
					check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
					if q.has("error"):
						continue
					check_eq(q.format, f)
					check(QuestionEngine.is_choice(q), f + " is a choice")
					check_eq(q.choices.size(), 4, "%s %s options" % [c.key, f])
					check_eq(q.choices.filter(func(o): return o.correct).size(), 1, c.key + " one right option")
					check(q.has("reason") and q.reason != "", c.key + " says why")
					for i in q.choices.size():
						check_eq(QuestionEngine.mark(q, {"choice": i}).correct, q.choices[i].correct, "%s %s option %d" % [c.key, f, i])
					# The view asks for the format again, the same question.
					check_eq(QuestionEngine.make(q.view).prompt, q.prompt, c.key + " the view remakes it")


func test_error_spot_marks_the_first_wrong_line() -> void:
	var n := 0
	for t in CELLS:
		var spots := {}
		for m in QuestionEngine.type_of(t).misconceptions:
			if m.as == "error-spot":
				for u in m.in:
					spots[u] = true
		for c in QuestionEngine.cells(false, [t]):
			var has: bool = "error-spot" in QuestionEngine.extra_formats(t, c.unknown, c.angle)
			if "error-spot" in QuestionEngine.type_of(t).formats:
				check_eq(has, spots.has(c.unknown), c.key + ": error-spot exactly where the catalogue has one")
			if not has:
				continue
			for seed in range(1, 9):
				var q := _make(t, c.unknown, c.rep, c.angle, seed, "error-spot")
				n += 1
				check_eq(q.choices.map(func(o): return o.text), ["Line 1", "Line 2", "Line 3", "Line 4"], c.key)
				check(q.choices[q.spot.bad].correct, c.key + ": the right option is the wrong line")
				check(q.lines.has("Line %d: %s" % [q.spot.bad + 1, q.spot.lines[q.spot.bad]]), c.key + ": the working is shown")
				check(QuestionEngine.misconception_text(QuestionEngine.type_of(t), q.spot.ref) != "", c.key + ": the spot names its misconception")
	check(n > 0, "some error-spot questions")


## method-pick is never asked on a method the catalogue says fails, and never offers a
## method that works as a wrong one.
func test_method_pick_never_marks_a_working_method_wrong() -> void:
	check(not "method-pick" in QuestionEngine.extra_formats("fn-link-equivalent-forms", "same-or-not", "substitute-values"), "substitute-values fails on same-or-not")
	check(not "method-pick" in QuestionEngine.extra_formats("fn-link-equivalent-forms", "cos2x-form", "gdc-graph"), "the GDC graph fails on cos2x-form")
	check("method-pick" in QuestionEngine.extra_formats("fn-link-equivalent-forms", "same-or-not", "combine"))
	for t in CELLS:
		var ty := QuestionEngine.type_of(t)
		for c in QuestionEngine.cells(false, [t]):
			if not "method-pick" in QuestionEngine.extra_formats(t, c.unknown, c.angle):
				continue
			var works: Array = QuestionEngine.angles_for(ty, c.unknown).filter(func(a): return not QuestionEngine.fails(ty, c.unknown, a)) \
				.map(func(a): return QuestionEngine.angle_info(ty, c.unknown, a).name)
			for seed in [1, 2]:
				var q := _make(t, c.unknown, c.rep, c.angle, seed, "method-pick")
				check(not q.prompt.contains("Method:"), c.key + ": the prompt gives the method away")
				for o in q.choices:
					if o.correct:
						check_eq(o.text, QuestionEngine.angle_info(ty, c.unknown, c.angle).name, c.key)
					else:
						check(not o.text in works, "%s: %s works but is a wrong option" % [c.key, o.text])


## A student's answer that is a misconception's: agreeing with it logs that misconception.
func test_true_false_reason_logs_the_misconception_agreed_with() -> void:
	var seen_true := false
	var seen_false := false
	for seed in range(1, 60):
		var q := _make("fn-link-symmetry", "normal-middle", "words", "mirror-tails", seed, "true-false-reason")
		var base: Array = q.base_choices
		var claimed: Dictionary = base.filter(func(o): return o.text == q.claim)[0]
		var agree: Dictionary = q.choices.filter(func(o): return o.text == "True")[0]
		check_eq(agree.correct, claimed.correct, "True is right exactly when the student is")
		if claimed.correct:
			seen_true = true
		else:
			seen_false = true
			check_eq(agree.ref, claimed.ref, "agreeing logs the claim's misconception")
			var i: int = q.choices.find(agree)
			check_eq(QuestionEngine.mark(q, {"choice": i}).misconception, claimed.ref)
	check(seen_true and seen_false, "both right and wrong claims come up")


## The planner and the dungeon ask a cell in one of its extra formats some of the time.
func test_the_planner_asks_the_extra_formats() -> void:
	var save := SaveData.blank()
	var formats := {}
	var cells := QuestionEngine.cells(false, ["fn-pre-factorise"])
	for i in 300:
		var v := Planner.next(save, 1_800_000_000, {"cells": cells, "probes": false})
		formats[v.format] = true
		check(not QuestionEngine.make(v).has("error"), "%s: %s" % [v, QuestionEngine.make(v).get("error")])
	for f in ["value", "mcq", "method-pick", "error-spot"]:
		check(formats.has(f), "the planner never asked " + f)


## The fn-pre-* types are the region's prior learning: floor 1 opens with them now.
func test_warm_ups_play_the_prior_learning() -> void:
	var prior := Dungeon.prior_cells("quadratics")
	check(not prior.is_empty(), "the region has prior-learning cells")
	for c in prior:
		check(c.type.begins_with("fn-pre-"), c.key)
	check_eq(Dungeon.prior_for("quadratics", "fn-quadratic-inequality|solve-against-zero|equation|sketch-roots", "s").begins_with("fn-pre-"), true,
		"a missed inequality brings prior learning")


# ── The answer kinds ─────────────────────────────────────────

func test_two_brackets_in_either_order() -> void:
	var ans := Answer.make("brackets2", {"a1": Q.new(2), "b1": Q.new(1), "a2": Q.new(1), "b2": Q.new(3)})
	check_eq(Answer.text(ans), "(2x + 1)(x + 3)")
	check(Answer.mark(ans, {"a1": "1", "b1": "3", "a2": "2", "b2": "1"}).correct, "swapped brackets")
	check(not Answer.mark(ans, {"a1": "2", "b1": "3", "a2": "1", "b2": "1"}).correct, "constants swapped between brackets")


func test_typed_powers_in_either_order() -> void:
	var ans := Answer.make("poly", {"c0": Q.new(-6), "e0": Q.new(-3), "c1": Q.new(-3, 4), "e1": Q.new(-4)}, {"powers": [0, 0], "typed_powers": true}, "f′(x) = ")
	check_eq(Answer.text(ans), "f′(x) = −6x⁻³ − (3/4)x⁻⁴")
	check(Answer.mark(ans, {"c0": "-3/4", "e0": "-4", "c1": "-6", "e1": "-3"}).correct, "terms swapped")
	check(not Answer.mark(ans, {"c0": "-6", "e0": "-4", "c1": "-3/4", "e1": "-3"}).correct, "powers swapped between terms")


func test_angles_in_any_order() -> void:
	var ans := Answer.make("angles", {"a0": Q.new(1, 6), "a1": Q.new(1, 2), "a2": Q.new(5, 6)}, {"n": 3})
	check_eq(Answer.text(ans), "x = π/6, π/2 or 5π/6")
	check(Answer.mark(ans, {"a0": "5/6", "a1": "1/6", "a2": "1/2"}).correct)
	var rel := Answer.make("related", {"s": Q.new(2, 3), "o1": Q.new(4, 3), "o2": Q.new(5, 3)})
	check_eq(Answer.text(rel), "same value 2π/3; opposite sign 4π/3 and 5π/3")
	check(Answer.mark(rel, {"s": "2/3", "o1": "5/3", "o2": "4/3"}).correct)
	check(not Answer.mark(rel, {"s": "4/3", "o1": "2/3", "o2": "5/3"}).correct, "the same-value angle is not one of the others")


## A value shown to 3 s.f. is one option per text, and takes a 3 s.f. answer.
func test_three_figure_values_are_told_apart_by_their_text() -> void:
	var ans := Answer.make("named", {"v0": Q.new(103551, 1000), "v1": Q.new(136449, 1000)}, {"names": ["a", "b"]})
	ans.show = "sf"
	check_eq(Answer.text(ans), "a = 104, b = 136")
	check_eq(Answer.canon(ans, ans.values), Answer.canon(ans, {"v0": Q.new(1035, 10), "v1": Q.new(1364, 10)}))
	check(Answer.mark(ans, {"v0": "104", "v1": "136"}).correct)
