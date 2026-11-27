extends "res://tests/test_case.gd"
## Two engine follow-ups from the reading pass (#272, FAL-1606, Refs #193).
##
## 1. A family's shared curve could name a method whose working then said "this method
##    fails here" (fn-sketch-gdc label-zeros with factorised-read, label-turning-point
##    with read-from-form). A view now lists such methods in `fails`, and a shared draw
##    tries again told the method.
## 2. A named answer shown to 3 s.f. padded an exact value ("k = −1.00"). An exact value
##    with 3 s.f. or fewer now shows as it is, beside a GDC's 3 s.f. value.

const SK := "fn-sketch-gdc"
const SEEDS := 300


func _shared_cells() -> Array:
	return QuestionEngine.cells(false, [SK]).filter(func(c):
		return (c.unknown == "label-zeros" and c.angle == "factorised-read") or (c.unknown == "label-turning-point" and c.angle == "read-from-form"))


static func _asked_steps(q: Dictionary) -> String:
	for sol in q.solutions:
		if sol.angle == q.view.angle:
			return " ".join(sol.steps.map(func(st): return Step.text(st)))
	return ""


## No shared question names a method whose own working says it fails here.
func test_a_shared_curve_never_names_a_method_that_fails_on_it() -> void:
	var cs := _shared_cells()
	check(cs.size() >= 2, "fn-sketch-gdc has the factorised-read and read-from-form cells")
	var asked := 0
	for c in cs:
		for seed in range(1, SEEDS + 1):
			var q := QuestionEngine.make({"type": SK, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "shared": true})
			if q.has("error"):
				continue
			asked += 1
			check(q.prompt.contains("Method:"), "%s seed %d names its method" % [c.key, seed])
			check(not _asked_steps(q).contains("fails here"), "%s seed %d names a method that fails: %s" % [c.key, seed, _asked_steps(q)])
	check(asked > 0, "no shared question was made")


## A view's own numbers are drawn for its method, so its working never fails either.
func test_an_own_draw_of_those_methods_works() -> void:
	for c in _shared_cells():
		for seed in range(1, 61):
			var q := QuestionEngine.make({"type": SK, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed})
			check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
			if not q.has("error"):
				check(not _asked_steps(q).contains("fails here"), "%s seed %d" % [c.key, seed])


## The k of fn-gdc-intersection's constant-from-crossing is exact: it shows as it is,
## beside the GDC's x to 3 s.f.
func test_an_exact_value_in_a_named_answer_is_not_padded() -> void:
	var ans := Answer.make("named", {"v0": Q.new(-1), "v1": Q.new(4672113, 1000000)}, {"names": ["k", "x"]})
	ans.show = "sf"
	check_eq(Answer.text(ans), "k = −1, x = 4.67")
	ans.values = {"v0": Q.new(7, 2), "v1": Q.new(2), "v2": Q.new(33)}
	ans.fixed = {"names": ["k", "x", "n"]}
	check_eq(Answer.text(ans), "k = 3.5, x = 2, n = 33")
	# A decimal past 3 s.f., or a fraction that doesn't end, is still to 3 s.f.
	ans.values = {"v0": Q.new(-2345, 1000), "v1": Q.new(1, 3)}
	ans.fixed = {"names": ["k", "x"]}
	check_eq(Answer.text(ans), "k = −2.35, x = 0.333")
	for c in QuestionEngine.cells(false, ["fn-gdc-intersection"]).filter(func(c): return c.unknown == "constant-from-crossing"):
		for seed in range(1, 41):
			var q := QuestionEngine.make({"type": "fn-gdc-intersection", "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed})
			if q.has("error"):
				continue
			var k: Q = q.answer.values.v0
			check(Answer.text(q.answer).begins_with("k = " + Fmt.dec(k) + ","), "%s seed %d: %s" % [c.key, seed, Answer.text(q.answer)])


## Marking is unchanged: "2", "2.00" and "−1.00" are all right for an exact 2 or −1.
func test_typed_marking_of_an_exact_value_is_unchanged() -> void:
	var ans := Answer.make("named", {"v0": Q.new(-1), "v1": Q.new(2)}, {"names": ["k", "x"]})
	ans.show = "sf"
	for typed in [["-1", "2"], ["-1.00", "2.00"], ["−1.0", "2.0"]]:
		check(Answer.mark(ans, {"v0": typed[0], "v1": typed[1]}).correct, "typed %s" % [typed])
	check(not Answer.mark(ans, {"v0": "-1.1", "v1": "2"}).correct, "a wrong k")
	var one := Answer.make("number", {"v": Q.new(2)})
	one.show = "sf"
	check(Answer.mark(one, {"v": "2.00"}).correct and Answer.mark(one, {"v": "2"}).correct, "a number's marking")
	check_eq(Answer.text(one), "2.00")
