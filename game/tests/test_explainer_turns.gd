extends "res://tests/test_case.gd"
## The explainer scripts' turns (writing/explainers/, format 2, FAL-1043, GitHub #188).
## A turn served by the engine pins one cell: type, unknown, representation and method.
## Its lines are heard with every question that cell can make, so this makes the cell's
## questions and checks they have the shape the lines assume: made without an error, one
## part, asked with the turn's command term, and offering every misconception a not-yet
## line is keyed to. tools/explainer-scripts.mjs checks the rest of the format.
##
## The scripts live outside game/, so this reads them from the checkout. The web build
## doesn't run tests, so it never needs them.

const SEEDS := 40


func _scripts_dir() -> String:
	return ProjectSettings.globalize_path("res://").path_join("../writing/explainers").simplify_path()


func _engine_turns() -> Array:
	var out: Array = []
	var dir := DirAccess.open(_scripts_dir())
	if dir == null:
		return out
	for f in dir.get_files():
		if not (f.begins_with("ex.") and f.ends_with(".json")):
			continue
		var script: Variant = JSON.parse_string(FileAccess.get_file_as_string(_scripts_dir().path_join(f)))
		if not script is Dictionary:
			fail("%s does not parse" % f)
			continue
		for s in script.get("sections", []):
			var turn: Dictionary = s.get("turn", {})
			if turn.get("serve", "") == "engine":
				out.append({"where": "%s %s" % [f, s.id], "turn": turn})
	return out


func test_the_scripts_are_found_and_some_turns_use_the_engine() -> void:
	check(DirAccess.dir_exists_absolute(_scripts_dir()), "no %s" % _scripts_dir())
	check(_engine_turns().size() >= 5, "only %d engine turns" % _engine_turns().size())


func test_every_engine_turn_is_served_with_the_shape_its_lines_assume() -> void:
	for t in _engine_turns():
		var turn: Dictionary = t.turn
		var cell: Dictionary = turn.cell
		var formats: Array = [cell.format] if cell.has("format") else ["mcq", "value"]
		var offered := {}
		var made := 0
		var wrong := {}
		for seed in range(1, SEEDS + 1):
			var view := {"type": cell.type, "unknown": cell.unknown, "rep": cell.rep, "format": formats[seed % formats.size()], "seed": seed}
			if cell.has("angle"):
				view.angle = cell.angle
			var q := QuestionEngine.make(view)
			if q.has("error"):
				fail("%s: the engine can't serve %s: %s" % [t.where, view, q.error])
				break
			made += 1
			var asked: String = q.get("asked", q.prompt)
			if not asked.begins_with(turn.command + " ") and not wrong.has(asked):
				wrong[asked] = seed
			for c in q.choices:
				if not c.correct and c.get("ref", "") != "":
					offered[c.ref] = true
		if not wrong.is_empty():
			fail("%s: the turn's lines assume \"%s\", but the cell asks %s" % [t.where, turn.command,
				", ".join(wrong.keys().map(func(k): return "\"%s\" (seed %d)" % [k, wrong[k]]))])
		if made < SEEDS:
			continue
		for line in turn.get("not_yet", []):
			if line.has("misconception"):
				check(offered.has(line.misconception),
					"%s: a not-yet line is keyed to %s, which the cell never offers in %d questions" % [t.where, line.misconception, SEEDS])
