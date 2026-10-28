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
## Each cell also gets --shared questions (default 10) made on its family's shared
## situation (QuestionEngine.families(), the explorer's "Ask it another way").
##
## Then every mini-boss and boss chain (Dungeon.chain_windows) with --per-chain seeds:
## each part is exported as a question too, with "chain" (the chain's id) and "part",
## so the checker solves every boss part and checks the parts carry on from each other.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := {"per-cell": "50", "per-type": "1000", "shared": "10", "per-chain": "50", "out": "user://questions.json"}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	var per_cell := int(args["per-cell"])
	var per_type := int(args["per-type"])
	var shared := int(args["shared"])
	var questions: Array = []
	var errors: Array = []
	var types: Array = []
	for id in QuestionEngine.built_types():
		var cells := QuestionEngine.cells(false, [id])
		var n := maxi(per_cell, ceili(float(per_type) / cells.size()))
		types.append({"type": id, "cells": cells.size(), "per_cell": n})
		for c in cells:
			var views: Array = []
			for seed in range(1, n + 1):
				views.append({"type": id, "unknown": c.unknown, "rep": c.rep, "angle": c.angle,
					"format": "mcq" if seed % 2 == 1 else "value", "seed": seed})
			for seed in range(1, shared + 1):
				views.append({"type": id, "unknown": c.unknown, "rep": c.rep, "angle": c.angle,
					"format": "mcq" if seed % 2 == 1 else "value", "seed": seed, "shared": true})
			for view in views:
				var q := QuestionEngine.make(view)
				if q.has("error"):
					errors.append({"view": view, "error": q.error})
					continue
				questions.append(plain(q))
	var chains := 0
	for id in QuestionEngine.built_types():
		for steps in Dungeon.chain_windows(id):
			var name := "%s: %s" % [id, " > ".join(steps.map(func(st): return st.unknown))]
			for seed in range(1, int(args["per-chain"]) + 1):
				var c := QuestionEngine.make_chain(steps.map(func(st): return st.merged({"format": "mcq" if seed % 2 == 1 else "value"})), seed)
				if c.has("error"):
					errors.append({"view": {"type": id, "chain": name, "seed": seed}, "error": c.error})
					continue
				chains += 1
				for q in c.parts:
					var e: Dictionary = plain(q)
					e.chain = "%s seed %d" % [name, seed]
					questions.append(e)
	var out := {"types": types, "questions": questions, "errors": errors, "chains": chains,
		"cells": QuestionEngine.cells().map(func(c): return c.key)}
	var f := FileAccess.open(args.out, FileAccess.WRITE)
	if f == null:
		printerr("export_questions: can't write %s" % args.out)
		quit(1)
		return
	f.store_string(JSON.stringify(out))
	f.close()
	print("export_questions: %d questions (%d boss chains), %d errors -> %s" % [questions.size(), chains, errors.size(), args.out])
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
