extends "res://tests/test_case.gd"
## The variable-kind situation (FAL-778): t4-ext-data-type is built with every cell, each answer is
## the one true claim about its variable, a table shows values in the variable's own steps, and every
## tag shows up. The SymPy checker (tools/check-answers) classifies every variable again from its words.

const TYPE := "t4-ext-data-type"
const CELLS := 14
const V := preload("res://engine/situations/variable_kind_views.gd")


func _make(c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": TYPE, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func test_the_type_is_built_with_every_cell() -> void:
	check(TYPE in QuestionEngine.built_types(), "%s is not built" % TYPE)
	check_eq(QuestionEngine.cells(false, [TYPE]).size(), CELLS)
	for c in QuestionEngine.cells(false, [TYPE]):
		for f in ["mcq"] + QuestionEngine.extra_formats(TYPE, c.unknown, c.angle):
			for seed in [1, 2, 3]:
				var q := _make(c, seed, f)
				check(not q.has("error"), "%s %s: %s" % [c.key, f, q.get("error")])
				if not q.has("error"):
					check_eq(q.table != null, c.rep == "table", c.key)


func test_each_variable_is_asked_where_its_trap_belongs() -> void:
	var want := {"classify-variable": [""], "decimal-but-discrete": ["decimal"], "rounded-but-continuous": ["rounded"]}
	for u in want:
		for i in 40:
			var s := VariableKindSituation.generate(Seeded.new("%s|%d" % [u, i]), {"ask": u})
			check(V.VARS[s.v].trap in want[u], "%s draw %d: %s" % [u, i, V.VARS[s.v].what])
	for i in 40:
		var s := VariableKindSituation.generate(Seeded.new("four|%d" % i), {"ask": "which-discrete"})
		check_eq(s.four.map(func(x): return V.VARS[x].kind), ["d", "c", "c", "c"])
		check_eq(V.VARS[s.four[1]].trap, "rounded")


func test_table_values_are_in_their_steps() -> void:
	for i in 40:
		var s := VariableKindSituation.generate(Seeded.new("steps|%d" % i), {"ask": "decimal-but-discrete"})
		for t in s.vals:
			var x := float(t)
			if V.VARS[s.v].dp == 2:
				check(t.split(".")[1].length() == 2, t)
			else:
				check(is_equal_approx(x * 2.0, roundf(x * 2.0)) and not t.ends_with(".0"), t)


func test_every_tag_shows_up_as_an_option() -> void:
	var seen := {}
	for c in QuestionEngine.cells(false, [TYPE]):
		for seed in range(1, 15):
			for o in _make(c, seed).choices:
				if o.ref != "":
					seen[o.ref] = true
	var ms: Array = QuestionEngine.type_of(TYPE).misconceptions
	for i in ms.size():
		var ref: String = ms[i].get("ref", "%s#%d" % [TYPE, i])
		check(seen.has(ref), "%s never shows" % ref)
