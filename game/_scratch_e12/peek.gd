extends SceneTree

func _initialize() -> void:
	var t := "t3-3d-angle"
	var n := 0
	var bad := 0
	for c in QuestionEngine.cells(false, [t]):
		for seed in range(1, 4):
			var q := QuestionEngine.make({"type": t, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": "mcq"})
			n += 1
			if q.has("error"):
				bad += 1
				print("ERR ", c.key, " ", q.error)
				continue
			if seed == 1:
				print("== ", c.key, " paper ", q.paper)
				for l in q.lines:
					print("  L: ", l)
				print("  Q: ", q.asked)
				for o in q.choices:
					print("  O: ", o.text, " ", o.ref, " ", o.correct)
				for s in q.solutions:
					print("  S[", s.angle, "]")
					for st in s.steps:
						print("     ", st)
	print("made ", n, " errors ", bad, " cells ", QuestionEngine.cells(false, [t]).size())
	quit()
