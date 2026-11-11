extends "res://tests/test_case.gd"
## The reusable maths engine's interface (#134, FAL-798; docs/MATHS-ENGINE.md): it and
## the study screen reach no game code, and one request and seed give the same maths,
## marking and worked solution on the game's practice screen and on the study screen.

const PRACTICE := "res://scenes/practice.tscn"
const STUDY := "res://scenes/study.tscn"
const SAVE := "user://test_maths_engine_save.json"
const EVIDENCE := "user://test_maths_engine_study.json"

## Engine files that are the game's rules, not maths: combat, the dungeon, rewards, the
## map, art and the save that holds them.
const GAME_ENGINE := ["run.gd", "dungeon.gd", "bazaar.gd", "tuning.gd", "map_link.gd", "art_slots.gd",
	"modifiers.gd", "save_data.gd", "progress.gd", "planner.gd"]

const REQUESTS := [
	{"type": "fn-quadratic-features", "unknown": "vertex-form-from-general", "rep": "equation", "angle": "complete-square", "format": "value", "seed": 2},
	{"type": "t1-arithmetic-sequence", "unknown": "n-from-sum", "rep": "notation", "angle": "quadratic-in-n", "format": "value", "seed": 8},
	{"type": "t4-discrete-distribution", "unknown": "k-from-sum", "rep": "table", "angle": "sum-to-one", "format": "value", "seed": 9},
	{"type": "t4-expected-value", "unknown": "fair-stake", "rep": "words", "angle": "winnings-vs-cost", "format": "mcq", "seed": 11},
	{"type": "t5-stationary-points", "unknown": "nature", "rep": "words", "angle": "second-derivative-test", "format": "mcq", "seed": 10},
	{"type": "fn-quadratic-features", "probe": 2, "format": "probe"},
]


# ── No game code behind the interface ────────────────────────

static func _classes() -> Dictionary:
	var out := {}
	for c in ProjectSettings.get_global_class_list():
		out[c["class"]] = c.path
	return out


## The script's code with its strings and comments taken out.
static func _code(path: String) -> String:
	var text := FileAccess.get_file_as_string(path)
	for pattern in ['"""[\\s\\S]*?"""', '"(?:[^"\\\\\\n]|\\\\.)*"', "'(?:[^'\\\\\\n]|\\\\.)*'", "#[^\\n]*"]:
		var re := RegEx.create_from_string(pattern)
		text = re.sub(text, "\"\"", true)
	return text


## The scripts a script uses: global classes named in its code, and scripts it loads by path.
static func _uses(path: String, classes: Dictionary) -> Array:
	var out: Array = []
	var code := _code(path)
	for m in RegEx.create_from_string("\\b[A-Z][A-Za-z0-9_]*\\b").search_all(code):
		var name := m.get_string()
		if classes.has(name) and not out.has(classes[name]) and classes[name] != path:
			out.append(classes[name])
	for m in RegEx.create_from_string("res://[A-Za-z0-9_/.-]+\\.gd").search_all(FileAccess.get_file_as_string(path)):
		if not out.has(m.get_string()):
			out.append(m.get_string())
	return out


## Every script reachable from `start`, and for each the script that first reached it.
static func _reach(start: String) -> Dictionary:
	var classes := _classes()
	var from := {start: ""}
	var todo := [start]
	while not todo.is_empty():
		var p: String = todo.pop_front()
		for q in _uses(p, classes):
			if not from.has(q):
				from[q] = p
				todo.append(q)
	return from


static func _is_game(path: String) -> bool:
	return not path.begins_with("res://engine/") or path.get_file() in GAME_ENGINE


func test_the_interface_reaches_no_game_code() -> void:
	var reach := _reach("res://engine/maths_engine.gd")
	check(reach.has("res://engine/question_engine.gd"), "the scan follows the engine")
	check(reach.has("res://engine/situations/quadratic.gd"), "the scan follows the situations")
	for p in reach:
		check(not _is_game(p), "%s reaches game code %s (through %s)" % ["maths_engine.gd", p, reach[p]])


func test_the_study_screen_uses_only_the_interface() -> void:
	var reach := _reach("res://ui/study.gd")
	check(reach.has("res://engine/maths_engine.gd"), "the study screen uses MathsEngine")
	for p in reach:
		if p != "res://ui/study.gd":
			check(not _is_game(p), "study.gd reaches game code %s (through %s)" % [p, reach[p]])
	var direct := _uses("res://ui/study.gd", _classes())
	for p in direct:
		check(p in ["res://engine/maths_engine.gd", "res://engine/fmt.gd"],
			"study.gd should ask MathsEngine, not %s" % p)


# ── The interface itself ─────────────────────────────────────

func test_the_same_request_gives_the_same_question() -> void:
	for r in REQUESTS:
		check_eq(_maths(MathsEngine.generate(r)), _maths(MathsEngine.generate(r)), str(r))
	var a := MathsEngine.generate(REQUESTS[0])
	var b := MathsEngine.generate(REQUESTS[0].merged({"seed": 3}, true))
	check(_maths(a) != _maths(b), "another seed, another question")


func test_model_responses_mark_right_and_wrong() -> void:
	for r in REQUESTS:
		var q := MathsEngine.generate(r)
		check(not q.has("error"), str(r))
		var right := MathsEngine.mark(q, MathsEngine.model_response(q, true))
		check(right.complete and right.correct, "%s: right %s" % [r, right])
		var wrong := MathsEngine.mark(q, MathsEngine.model_response(q, false))
		check(wrong.complete and not wrong.correct, "%s: wrong %s" % [r, wrong])
		check(not MathsEngine.worked_solutions(q).is_empty(), "%s: a worked solution" % r)
		check(MathsEngine.worked_solutions(q).all(func(s): return s.steps.all(func(st): return st is String)),
			"%s: steps are text" % r)


func test_incomplete_responses_say_what_is_missing() -> void:
	var q := MathsEngine.generate(REQUESTS[0])
	var m := MathsEngine.mark(q, {})
	check(not m.complete and not m.errors.is_empty(), str(m))
	var p := MathsEngine.generate(REQUESTS[5])
	m = MathsEngine.mark(p, {})
	check(not m.complete and not m.errors.is_empty(), str(m))


func test_learning_results_follow_the_evidence() -> void:
	var ev := MathsEngine.blank_evidence()
	var before := MathsEngine.results(ev, "aa-sl")
	check_eq(before.coverage.checked, 0)
	check(before.coverage.total > 0, "the course has cells")
	check_eq(before.accuracy.percent, -1)
	var q := MathsEngine.generate(REQUESTS[0])
	for right in [true, false, false]:
		MathsEngine.record(ev, q, MathsEngine.mark(q, MathsEngine.model_response(q, right)), 100)
	var after := MathsEngine.results(ev, "aa-sl")
	check_eq(after.coverage.checked, 1)
	check_eq(after.accuracy, {"right": 1, "seen": 3, "percent": 33})
	check(not after.weakest.is_empty(), "three answers make a skill weak or strong")
	check_eq(ev.history.size(), 3)
	check_eq(MathsEngine.results(ev, "aa-sl", false, ["t4-expected-value"]).coverage.checked, 0, "other types")


func test_curriculum_selection_follows_the_course() -> void:
	var ids: Array = MathsEngine.courses().map(func(c): return c.id)
	check_eq(ids, ["aa-sl", "aa-hl", "ai-sl", "ai-hl"])
	var sl: Array = MathsEngine.types("aa-sl").map(func(t): return t.id)
	check(sl.has("fn-quadratic-features"), "AA SL has quadratics")
	for c in MathsEngine.requests("ai-sl"):
		check(c.type in MathsEngine.types("ai-sl").map(func(t): return t.id), "%s is an AI SL type" % c.key)
		break
	check(MathsEngine.types("aa-sl", true).all(func(t): return t.exam), "exam_only keeps exam types")


# ── One request through both presentations ───────────────────

## The maths of a question, as text: what is asked, its answer, its options, its paper and
## its worked solutions.
static func _maths(q: Dictionary) -> Dictionary:
	if q.has("error"):
		return {"error": q.error}
	var options: Array = q.options if q.format == "probe" else q.choices.map(func(c): return c.text)
	return {"cell": q.cell, "prompt": MathsEngine.prompt(q), "lines": q.get("lines", []), "table": q.get("table"),
		"answer": MathsEngine.answer_sentence(q), "options": options, "paper": q.paper, "marks": q.get("marks", 0),
		"solutions": MathsEngine.worked_solutions(q)}


func _screens() -> Array:
	for f in [SAVE, EVIDENCE]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	var frame := Control.new()
	frame.size = Vector2(1080, 1920)
	tree.root.add_child(frame)
	var game: Control = (load(PRACTICE) as PackedScene).instantiate()
	game.save_path = SAVE
	frame.add_child(game)
	var study: Control = (load(STUDY) as PackedScene).instantiate()
	study.evidence_path = EVIDENCE
	frame.add_child(study)
	await tree.process_frame
	return [frame, game, study]


func test_one_request_gives_the_same_maths_on_both_screens() -> void:
	var made: Array = await _screens()
	var game: Control = made[1]
	var study: Control = made[2]
	for r in REQUESTS:
		for right in [true, false]:
			game.show_view(r)
			study.show_request(r)
			await tree.process_frame
			check_eq(_maths(study.question), _maths(game.question), "%s: same maths" % r)
			# Each screen answers through its own controls, then marks it.
			game.autoplay(right)
			study.enter(MathsEngine.model_response(study.question, right))
			study.check_answer()
			await tree.process_frame
			check_eq(study.result.correct, right, "%s: study marks it %s" % [r, right])
			var in_game: Dictionary = game.save.probes if r.format == "probe" else game.save.cells
			var in_study: Dictionary = study.evidence.probes if r.format == "probe" else study.evidence.cells
			var g: Dictionary = in_game.get(game.question.cell, {})
			var s: Dictionary = in_study.get(study.question.cell, {})
			check_eq(s.get("last_result"), g.get("last_result"), "%s: same marking" % r)
			check_eq(s.get("last_misconception"), g.get("last_misconception"), "%s: same misconception" % r)
			check_eq(s.get("seen"), g.get("seen"), "%s: both recorded" % r)
			check(study.solution.get_child_count() > 0, "%s: study shows the worked solution" % r)
	made[0].queue_free()
	await tree.process_frame


func test_the_study_screen_has_no_game_on_it() -> void:
	var made: Array = await _screens()
	var study: Control = made[2]
	var hud := tree.root.get_node_or_null("AudioHud") as CanvasLayer
	if hud != null:
		check(not hud.visible, "the game's sound controls are hidden")
	check(study.course_pick.item_count == 4, "four courses")
	check(study.cell_pick.item_count > 0, "the first type has questions")
	check(not study.question.is_empty() and not study.question.has("error"), "a question is asked at once: %s" % study.question)
	check(study.current_request().rep in study.SHOWN_REPS, "only representations it can show")
	made[0].queue_free()
	await tree.process_frame
	if hud != null:
		check(hud.visible, "the sound controls come back")
