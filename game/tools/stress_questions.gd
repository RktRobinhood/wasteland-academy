extends SceneTree
## Seed sweep (FAL-322): makes every cell with many seeds beyond the checker's 1 to 50,
## and checks each question is made, has four options, marks its own answer right
## (exact and to 3 s.f.) and marks every wrong option wrong, naming its misconception.
## Every fourth seed is also made on the cell's shared situation (the explorer's
## "Ask it another way", QuestionEngine.families()), and every fourth in each extra
## format the cell offers (error-spot, method-pick, true-false-reason): four options,
## the right one marked right and the rest wrong. Then the same for every boss chain
## (Dungeon.chain_windows) with CHAIN_SEEDS of those seeds: each part made on one
## situation, and each carried value the part before's answer. Used by
## tools/stress-questions. Exits non-zero on any failure.
##
##   godot --headless --path game --script res://tools/stress_questions.gd -- \
##       [--from=51] [--to=2250] [--types=id,id]

## Seeds per boss chain, from --from: there are a few dozen chains, each several parts.
const CHAIN_SEEDS := 1000

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
	var only: Array = Array(str(args.get("types", "")).split(",", false))
	for c in QuestionEngine.cells(false, only):
		var views: Array = []
		for seed in range(lo, hi + 1):
			views.append({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "format": "value", "seed": seed})
			if seed % 4 == 0:
				views.append({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "format": "value", "seed": seed, "shared": true})
				for f in QuestionEngine.extra_formats(c.type, c.unknown, c.angle):
					views.append({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "format": f, "seed": seed})
		for view in views:
			var seed: int = view.seed
			var key: String = c.key + (" shared" if view.has("shared") else "") + (" " + view.format if view.format != "value" else "")
			var q = QuestionEngine.make(view)
			n += 1
			if typeof(q) != TYPE_DICTIONARY or q.is_empty():
				fails.append("%s seed %d: make() returned %s" % [key, seed, q])
				continue
			if q.has("error"):
				fails.append("%s seed %d: %s" % [key, seed, q.error])
				continue
			short_choices += _check(q, "%s seed %d" % [key, seed])
	var chains := 0
	for id in QuestionEngine.built_types():
		if not only.is_empty() and not id in only:
			continue
		for steps in Dungeon.chain_windows(id):
			var name := "chain %s" % "+".join(steps.map(func(st): return st.unknown))
			for seed in range(lo, mini(hi, lo + CHAIN_SEEDS - 1) + 1):
				var c := QuestionEngine.make_chain(steps.map(func(st): return st.merged({"format": "value"})), seed)
				chains += 1
				if c.has("error"):
					fails.append("%s seed %d: %s" % [name, seed, c.error])
					continue
				for i in c.parts.size():
					var q: Dictionary = c.parts[i]
					n += 1
					short_choices += _check(q, "%s part %d seed %d" % [name, i, seed])
					if q.situation != c.situation:
						fails.append("%s part %d seed %d: another situation" % [name, i, seed])
					if i > 0 and q.carried.values != c.parts[i - 1].answer.values:
						fails.append("%s part %d seed %d: carries %s, not the answer %s" % [name, i, seed, q.carried.text, c.parts[i - 1].answer_text])
	print("STRESS %d boss chains" % chains)
	print("STRESS %d questions, %d failures, %d short-choice" % [n, fails.size(), short_choices])
	for f in fails.slice(0, 60):
		print("FAIL " + f)
	quit(1 if fails.size() > 0 else 0)


## Checks one made question; returns 1 if it has fewer than four options.
func _check(q: Dictionary, name: String) -> int:
	var short := 0
	if q.choices.size() != 4:
		short = 1
		fails.append("%s: %d choices" % [name, q.choices.size()])
	if q.format in QuestionEngine.EXTRA_FORMATS:
		for i in q.choices.size():
			var r := QuestionEngine.mark(q, {"choice": i})
			if r.correct != q.choices[i].correct:
				fails.append("%s: option %s is marked %s" % [name, q.choices[i].text, "right" if r.correct else "wrong"])
		return short
	var ans: Dictionary = q.answer
	if ans.kind in Answer.MC_ONLY:
		return short
	var r := QuestionEngine.mark(q, _typed(ans, ans.values))
	if not r.correct:
		fails.append("%s: exact typed answer marked wrong: %s" % [name, q.answer_text])
	# An exact answer (an exact k, −(ln 2)/3) is only right exactly, so its 3 s.f.
	# decimal is checked only where that decimal is the exact value.
	var rounded := Answer.slots(ans).any(func(item): return item.has("slot") and Answer.needs_rounding(ans.values[item.slot]))
	var rd := QuestionEngine.mark(q, _decimal_typed(ans, ans.values))
	if not rd.correct and not (ans.get("exact", false) and rounded):
		fails.append("%s: decimal typed answer marked wrong: %s %s" % [name, q.answer_text, _decimal_typed(ans, ans.values)])
	for ch in q.choices:
		# A wrong option in another form (1/f(x) for a log) can't be typed at all.
		if ch.correct or not Answer.typable(ans, ch.values):
			continue
		var rw := QuestionEngine.mark(q, _typed(ans, ch.values))
		if rw.correct:
			fails.append("%s: wrong option typed is marked right: %s vs %s" % [name, ch.text, q.answer_text])
		elif ch.ref != "" and rw.misconception != ch.ref:
			fails.append("%s: misconception not detected: %s" % [name, ch.ref])
	return short
