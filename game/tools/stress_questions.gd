extends SceneTree
## Seed sweep (FAL-322): makes every cell with many seeds beyond the checker's 1 to 50,
## and checks each question is made, has four options, marks its own answer right
## (exact and to 3 s.f.) and marks every wrong option wrong, naming its misconception.
## Used by tools/stress-questions. Exits non-zero on any failure.
##
##   godot --headless --path game --script res://tools/stress_questions.gd -- \
##       [--from=51] [--to=2250]

var fails: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _typed(ans: Dictionary, values: Dictionary) -> Dictionary:
	var resp := {}
	for item in Answer.slots(ans):
		if item.has("slot"):
			resp[item.slot] = (values[item.slot] as Q).key()
		else:
			resp[item.pick] = str(values[item.pick])
	return resp


func _decimal_typed(ans: Dictionary, values: Dictionary) -> Dictionary:
	# 3 s.f. decimal of each number, the way a GDC shows it
	var resp := {}
	for item in Answer.slots(ans):
		if item.has("slot"):
			var f: float = (values[item.slot] as Q).to_float()
			resp[item.slot] = String.num(f, 3) if absf(f) >= 1.0 else String.num(f, 4)
		else:
			resp[item.pick] = str(values[item.pick])
	return resp


func _run() -> void:
	var args := {"from": "51", "to": "2250"}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	var lo := int(args.from)
	var hi := int(args.to)
	var n := 0
	var short_choices := 0
	for c in QuestionEngine.cells():
		for seed in range(lo, hi + 1):
			var view := {"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "format": "value", "seed": seed}
			var q = QuestionEngine.make(view)
			n += 1
			if typeof(q) != TYPE_DICTIONARY or q.is_empty():
				fails.append("%s seed %d: make() returned %s" % [c.key, seed, q])
				continue
			if q.has("error"):
				fails.append("%s seed %d: %s" % [c.key, seed, q.error])
				continue
			if q.choices.size() != 4:
				short_choices += 1
				fails.append("%s seed %d: %d choices" % [c.key, seed, q.choices.size()])
			var ans: Dictionary = q.answer
			if ans.kind in Answer.MC_ONLY:
				continue
			var r := QuestionEngine.mark(q, _typed(ans, ans.values))
			if not r.correct:
				fails.append("%s seed %d: exact typed answer marked wrong: %s" % [c.key, seed, q.answer_text])
			var rd := QuestionEngine.mark(q, _decimal_typed(ans, ans.values))
			if not rd.correct:
				fails.append("%s seed %d: decimal typed answer marked wrong: %s %s" % [c.key, seed, q.answer_text, _decimal_typed(ans, ans.values)])
			for ch in q.choices:
				if ch.correct:
					continue
				var rw := QuestionEngine.mark(q, _typed(ans, ch.values))
				if rw.correct:
					fails.append("%s seed %d: wrong option typed is marked right: %s vs %s" % [c.key, seed, ch.text, q.answer_text])
				elif ch.ref != "" and rw.misconception != ch.ref:
					fails.append("%s seed %d: misconception not detected: %s" % [c.key, seed, ch.ref])
	print("STRESS %d questions, %d failures, %d short-choice" % [n, fails.size(), short_choices])
	for f in fails.slice(0, 60):
		print("FAIL " + f)
	quit(1 if fails.size() > 0 else 0)
