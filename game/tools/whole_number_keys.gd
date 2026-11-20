extends SceneTree
## Lists the typed answers whose key is a whole number of 1,000 or more (#194): such a
## key, unless exact, takes any 3 s.f. rounding (1020 for 1024). Prints one line per
## type and unknown with how it is marked, so each can be set exact or not on purpose.
##
##   godot --headless --path game --script res://tools/whole_number_keys.gd -- [--to=20]

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var to := 20
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--to="):
			to = int(a.substr(5))
	var found := {}
	for c in QuestionEngine.cells():
		for seed in range(1, to + 1):
			var q := QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "format": "value", "seed": seed})
			if q.is_empty() or q.has("error") or QuestionEngine.is_choice(q):
				continue
			var ans: Dictionary = q.answer
			for item in Answer.slots(ans):
				if not item.has("slot"):
					continue
				var v: Variant = ans.values.get(item.slot)
				if v is Q and v.is_int() and absi(v.n) >= 1000:
					var key := "%s|%s|%s" % [c.type, c.unknown, ans.kind]
					if not found.has(key):
						found[key] = {"n": 0, "exact": {}, "show": ans.get("show", ""), "eg": v.key(), "cells": {}}
					found[key].n += 1
					found[key].exact[str(ans.get("exact", false))] = true
					found[key].cells[c.key] = true
	var keys := found.keys()
	keys.sort()
	for k in keys:
		var f: Dictionary = found[k]
		print("KEY %s\texact=%s\tshow=%s\teg=%s\tn=%d\tcells=%d" % [k, ",".join(f.exact.keys()), f.show, f.eg, f.n, f.cells.size()])
	print("KEYS %d" % keys.size())
	quit(0)
