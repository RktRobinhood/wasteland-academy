extends SceneTree
## Generates questions headlessly with fixed seeds and writes them as JSON, for the
## SymPy answer checker (tools/check_answers.py). Used by tools/check-answers.
##
##   godot --headless --path game --script res://tools/export_questions.gd -- \
##       --out=/abs/questions.json [--per-cell=50] [--per-type=1000]
##
## Every coverage cell of every built type gets at least --per-cell questions, and
## every type at least --per-type. Seeds run 1, 2, 3, ...; odd seeds are multiple
## choice and even seeds typed values (the numbers don't depend on the format).


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := {"per-cell": "50", "per-type": "1000", "out": "user://questions.json"}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	var per_cell := int(args["per-cell"])
	var per_type := int(args["per-type"])
	var questions: Array = []
	var errors: Array = []
	var types: Array = []
	for id in QuestionEngine.built_types():
		var cells := QuestionEngine.cells(false, [id])
		var n := maxi(per_cell, ceili(float(per_type) / cells.size()))
		types.append({"type": id, "cells": cells.size(), "per_cell": n})
		for c in cells:
			for seed in range(1, n + 1):
				var view := {"type": id, "unknown": c.unknown, "rep": c.rep, "angle": c.angle,
					"format": "mcq" if seed % 2 == 1 else "value", "seed": seed}
				var q := QuestionEngine.make(view)
				if q.has("error"):
					errors.append({"view": view, "error": q.error})
					continue
				questions.append(plain(q))
	var out := {"types": types, "questions": questions, "errors": errors, "cells": QuestionEngine.cells().map(func(c): return c.key)}
	var f := FileAccess.open(args.out, FileAccess.WRITE)
	if f == null:
		printerr("export_questions: can't write %s" % args.out)
		quit(1)
		return
	f.store_string(JSON.stringify(out))
	f.close()
	print("export_questions: %d questions, %d errors -> %s" % [questions.size(), errors.size(), args.out])
	for e in errors.slice(0, 20):
		printerr("  %s: %s" % [e.view, e.error])
	quit(1 if not errors.is_empty() or questions.is_empty() else 0)


## Q -> "3/2", recursively.
static func plain(v: Variant) -> Variant:
	if v is Q:
		return v.key()
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = plain(v[k])
		return d
	if v is Array:
		return v.map(func(e): return plain(e))
	return v
