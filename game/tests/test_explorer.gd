extends "res://tests/test_case.gd"
## The engine explorer (FAL-391): opens on a live class with no errors, counts the
## catalogue per topic, plays questions from the pickers, keeps the situation when it
## asks another way, works without data/courses.json, and fits a phone and a PC window.

const EXPLORER := "res://scenes/explorer.tscn"
const Boot := preload("res://tests/test_boot.gd")
const Explorer := preload("res://ui/explorer.gd")
const COURSES := "user://test_explorer_courses.json"


func _area(window: Vector2i) -> Vector2:
	var base := Vector2(1080, 1920)
	var scale := minf(window.x / base.x, window.y / base.y)
	return Vector2(window) / scale


func _screen(window: Vector2i = Vector2i(390, 844)) -> Array:
	var frame := Control.new()
	frame.size = _area(window)
	tree.root.add_child(frame)
	var e: Control = (load(EXPLORER) as PackedScene).instantiate()
	frame.add_child(e)
	await tree.process_frame
	return [frame, e]


func test_opens_on_a_live_class_with_no_errors() -> void:
	var errors = Boot.AllErrors.new()
	OS.add_logger(errors)
	var made: Array = await _screen()
	var e: Control = made[1]
	for i in 3:
		await tree.process_frame
	OS.remove_logger(errors)
	check(e.type_id in QuestionEngine.built_types(), "opens on a live class, not %s" % e.type_id)
	check_eq(e.course, "aa-sl")
	check(not e.question.is_empty() and not e.question.has("error"), str(e.question.get("error")))
	check(e.question.get("view", {}).get("shared", false), "the question is made on its family's situation")
	check_eq(errors.seen, PackedStringArray(), "errors logged")
	made[0].free()


func test_topic_counts_come_from_the_catalogue() -> void:
	var made: Array = await _screen()
	var e: Control = made[1]
	var built := QuestionEngine.built_types()
	var total := 0
	for n in range(1, 6):
		var split: Array = e._types_in(n)
		var all: Array = QuestionEngine.catalogue().types.filter(func(t): return int(t.topic) == n)
		check_eq(split[0].size() + split[1].size(), all.size(), "topic %d catalogued" % n)
		check_eq(split[0].size(), all.filter(func(t): return t.id in built).size(), "topic %d live" % n)
		total += all.size()
	check_eq(total, QuestionEngine.catalogue().types.size(), "every type is in a topic 1 to 5")
	var tab := e.choices.find_child("Topic_2", true, false) as Button
	check(tab != null and tab.text.contains("Functions"), "topic tabs carry their names")
	made[0].free()


func test_not_built_classes_are_greyed_out() -> void:
	var made: Array = await _screen()
	var e: Control = made[1]
	e._choose("topic", 2)
	e.show_unbuilt = true
	e._refresh()
	var grey := 0
	for b in e.choices.find_children("*", "Button", true, false):
		if b.text.ends_with("not built yet") and not b.name == "NotBuilt":
			check(b.disabled, b.text + " can be picked")
			grey += 1
	check_eq(grey, e._types_in(2)[1].size())
	for t in e._types_in(2)[0]:
		check(e.choices.find_child("Class_" + t.id, true, false) != null, t.id + " is not listed")
	made[0].free()


func test_new_question_uses_a_fresh_seed() -> void:
	var made: Array = await _screen()
	var e: Control = made[1]
	var seeds := {}
	for i in 6:
		e.new_question()
		seeds[e.seed] = true
		check(not e.question.has("error"), str(e.question.get("error")))
		check_eq(e.question.view.seed, e.seed)
		check(e.seed_label.text.contains(str(e.seed)), "the seed is shown")
	check(seeds.size() >= 5, "seeds repeat: %s" % [seeds.keys()])
	made[0].free()


func test_ask_it_another_way_keeps_the_situation() -> void:
	var made: Array = await _screen()
	var e: Control = made[1]
	e._choose("type", "fn-quadratic-features")
	e._choose("unknown", "roots-from-factorised")
	e._choose("rep", "equation")
	e.seed = 7
	e._show()
	var fam: Array = e.family()
	check(fam.size() >= 10, "a big family on the equation: %s" % [fam])
	var sit: Dictionary = e.question.situation
	var seen := [e.unknown]
	for i in fam.size() - 1:
		e.ask_another_way()
		check(not e.question.has("error"), str(e.question.get("error")))
		check_eq(e.question.situation, sit, "%s keeps the numbers" % e.unknown)
		check(not e.unknown in seen, "%s came round again early" % e.unknown)
		seen.append(e.unknown)
		check_eq(e.seed, 7)
		check(e.situation_label.text.contains("%d of %d" % [i + 2, fam.size()]), e.situation_label.text)
	e.ask_another_way()
	check_eq(e.unknown, seen[0], "goes round to the first again")
	# It plays as on the practice screen, and the card's own button asks again.
	e.autoplay(true)
	check(e.answered and e.feedback.text.begins_with("Right"), e.feedback.text)
	check(e.working.visible, "worked solution shown")
	check_eq(e.next_button.text, "Ask it another way")
	e.next_button.pressed.emit()
	check_eq(e.unknown, seen[1])
	made[0].free()


func test_pickers_set_the_view() -> void:
	var made: Array = await _screen()
	var e: Control = made[1]
	e._choose("type", "fn-quadratic-features")
	e._choose("unknown", "vertex-from-factorised")
	e._choose("rep", "graph")
	check_eq(e.question.rep, "graph")
	check(e.question.graph != null, "a graph is drawn")
	e._choose("angle", "midpoint-of-roots")
	check_eq(e.question.view.angle, "midpoint-of-roots")
	check_eq(e.question.solutions[0].angle, "midpoint-of-roots", "the asked method's working comes first")
	e._choose("format", "mcq")
	check_eq(e.question.format, "mcq")
	e.autoplay(false)
	check(e.feedback.text.begins_with("Not quite"), e.feedback.text)
	# A new unknown keeps the representation if it can, and drops a method that doesn't suit.
	e._choose("unknown", "axis-from-roots")
	check_eq(e.rep, "graph")
	check(e.angle in e._angles_for("axis-from-roots"), e.angle)
	for b in e.choices.find_children("Unknown_*", "Button", true, false):
		check(not b.text.contains("-from-"), "plain words, not ids: " + b.text)
	made[0].free()


func test_class_size_line() -> void:
	var made: Array = await _screen()
	var e: Control = made[1]
	e._choose("type", "fn-quadratic-features")
	var cells := QuestionEngine.cells(false, ["fn-quadratic-features"])
	check(e.progress.text.contains("%d question shapes, new numbers on every seed" % cells.size()), e.progress.text)
	check(e.progress.text.begins_with("20 unknowns × 4 representations × "), e.progress.text)
	made[0].free()


func test_exam_style_switch() -> void:
	var made: Array = await _screen()
	var e: Control = made[1]
	e._choose("type", "fn-quadratic-features")
	e._choose("unknown", "vertex-from-table")   # not exam style
	e.exam_toggle.button_pressed = true
	var exam := QuestionEngine.cells(true, ["fn-quadratic-features"]).map(func(c): return c.unknown)
	check(e.unknown in exam, "moved to an exam-style unknown, not %s" % e.unknown)
	for u in e._unknowns():
		check(u in exam, u + " is not exam style")
	check(e.question.exam, "the question is exam style")
	e._choose("type", "fn-concept-quadratic-forms")   # an extension type: no exam cells
	check(e._unknowns().is_empty(), "extension type has exam cells")
	check(e.new_button.disabled, "nothing to ask")
	e.exam_toggle.button_pressed = false
	check(not e._unknowns().is_empty(), "switching off brings them back")
	made[0].free()


func test_ten_versions() -> void:
	var made: Array = await _screen()
	var e: Control = made[1]
	e._choose("type", "fn-quadratic-features")
	e._choose("unknown", "vertex-from-general")
	e.toggle_versions()
	var list: Node = e.card.find_child("Versions", true, false)
	check(list != null and list.get_child_count() == 10, "ten versions")
	var answers := {}
	for i in 10:
		var v: Dictionary = e.view()
		v.seed = e.seed + i
		answers[QuestionEngine.make(v).answer_text] = true
	check(answers.size() >= 8, "the versions differ: %s" % [answers.keys()])
	e.toggle_versions()
	check(e.card.find_child("Versions", true, false) == null, "back to one question")
	check(not e.answered, "playable again")
	made[0].free()


func test_courses_file_is_optional() -> void:
	var none: Array = Explorer.load_courses("res://data/no-such-courses.json")
	check_eq(none.map(func(c): return c.short), ["AA SL", "AA HL", "AI SL", "AI HL"])
	check_eq(none[0].status, "live")
	for c in none.slice(1):
		check_eq(Explorer.STATUS[c.status], "syllabus mapping in progress")
	var f := FileAccess.open(COURSES, FileAccess.WRITE)
	f.store_string(JSON.stringify({"courses": [
		{"id": "aa-sl", "short": "AA SL", "name": "Analysis and Approaches SL", "status": "live",
			"topics": [{"n": 1, "name": "Number and algebra", "subtopics": 9, "skills": 61, "hours": 19},
				{"n": 2, "name": "Functions", "subtopics": 11, "skills": 62, "hours": 21}]},
		{"id": "mystery-hl", "short": "Mystery HL", "name": "A course the engine doesn't list", "status": "mapped",
			"topics": [{"n": 1, "name": "Number and algebra", "subtopics": 12, "skills": 80, "hours": 39}]}]}))
	f.close()
	var read: Array = Explorer.load_courses(COURSES)
	check_eq(read.size(), 2)
	var made: Array = await _screen()
	var e: Control = made[1]
	e.courses = read
	e._choose("course", "mystery-hl")
	e._choose("topic", 1)
	var note := e.choices.find_child("CourseNote", true, false) as Label
	check(note != null and note.text.contains("syllabus mapped") and note.text.contains("12 subtopics"), note.text if note else "no note")
	check(e.new_button.disabled, "no questions for a course the engine doesn't cover")
	e._choose("course", "aa-sl")
	e._choose("topic", 2)
	check(not e.new_button.disabled, "AA SL plays again")
	check(not e.question.has("error"), str(e.question.get("error")))
	# A broken file falls back too.
	f = FileAccess.open(COURSES, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	check_eq(Explorer.load_courses(COURSES).size(), 4)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(COURSES))
	made[0].free()


func test_every_course_plays_the_classes_it_covers() -> void:
	# The explorer asks the engine (Courses), not the syllabus map's status: AA HL plays all
	# of AA SL's classes, and AI SL and AI HL the ones whose skills they share.
	var made: Array = await _screen()
	var e: Control = made[1]
	var all := QuestionEngine.built_types().size()
	var counts := {}
	for id in Courses.ids():
		e._choose("course", id)
		check(e._live(), "%s is live" % id)
		check_eq(e._live_types(), QuestionEngine.built_types(id), "%s's classes" % id)
		counts[id] = e._live_types().size()
		var keys := {}
		for c in QuestionEngine.cells(false, [], id):
			keys[c.key] = true
		for n in range(1, 6):
			for t in e._types_in(n)[0]:
				check(e._live_types().has(t.id), "%s lists %s" % [id, t.id])
		check(not e.new_button.disabled, "%s can ask a question" % id)
		check(not e.question.is_empty() and not e.question.has("error"), "%s: %s" % [id, e.question.get("error", "")])
		# The explorer's default method is "any", which is no coverage cell: check the unknown.
		var asked: Dictionary = e.question.view
		check(QuestionEngine.covered(id, QuestionEngine.type_of(asked.type), QuestionEngine.unknown_of(QuestionEngine.type_of(asked.type), asked.unknown)),
			"%s asked %s" % [id, e.question.cell])
		for c in e._cells():
			check(keys.has(c.key), "%s's cell %s" % [id, c.key])
	check_eq(counts["aa-sl"], all)
	check_eq(counts["aa-hl"], all, "AA HL has every class AA SL has")
	check(counts["ai-sl"] < all and counts["ai-hl"] >= counts["ai-sl"], "AI SL has %d, AI HL %d" % [counts["ai-sl"], counts["ai-hl"]])
	# A class built for AA that an AI course doesn't cover is greyed out and says so.
	e._choose("course", "ai-sl")
	e._choose("topic", 2)
	e.show_unbuilt = true
	e._refresh()
	var not_in := 0
	for b in e.choices.find_children("*", "Button", true, false):
		if b.text.ends_with("not in AI SL"):
			check(b.disabled, b.text + " can be picked")
			not_in += 1
	check(not_in > 0, "some Functions classes are not in AI SL")
	made[0].free()


func test_deep_link_args() -> void:
	var d: Dictionary = Explorer.view_from({"explore": "", "view": "fn-quadratic-features/axis-from-roots/graph/any/mcq", "seed": "42"})
	check_eq(d.view, {"type": "fn-quadratic-features", "unknown": "axis-from-roots", "rep": "graph", "angle": "any", "format": "mcq", "seed": 42})


func test_fits_on_a_phone() -> void:
	await _check_fits(Vector2i(390, 844))


func test_fits_in_a_pc_window() -> void:
	await _check_fits(Vector2i(1280, 800))


## The column fits the screen, and nothing in it runs off the side: both panes, the
## list of classes not built yet, a graph question answered and ten versions.
func _check_fits(window: Vector2i) -> void:
	var made: Array = await _screen(window)
	var e: Control = made[1]
	var screen := Rect2(Vector2.ZERO, _area(window))
	var col := e.get_node("Margin/Column") as Control
	e.show_unbuilt = true
	e._choose("type", "fn-quadratic-from-conditions")
	e._choose("unknown", "coefficients-from-two-points-and-axis")
	for step in ["choose", "question", "graph", "versions"]:
		match step:
			"choose":
				e._set_pane("choose")
			"question":
				e._choose("rep", "words")
				e._set_pane("question")
				e.autoplay(false)
			"graph":
				e._choose("rep", "graph")
				e._choose("format", "mcq")
				e._set_pane("question")
				e.autoplay(true)
			"versions":
				e.toggle_versions()
		for i in 3:
			await tree.process_frame
		check(screen.encloses(col.get_global_rect()), "%s %s: column %s outside %s" % [window, step, col.get_global_rect(), screen])
		var cr := col.get_global_rect()
		for c in col.find_children("*", "Control", true, false):
			if c.is_visible_in_tree() and not c is ScrollBar:
				var r: Rect2 = c.get_global_rect()
				check(r.end.x <= cr.end.x + 1 and r.position.x >= cr.position.x - 1,
						"%s %s: %s sticks out (%s, column %s)" % [window, step, c.name, r, cr])
	made[0].free()


func test_title_screen_has_engine() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	check(main.get_node_or_null("Center/Column/Engine") is Button, "no Engine button")
	main.free()
