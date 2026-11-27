extends "res://tests/test_case.gd"

const ID := "t4-ai-spearman-midranks"
const CELL := {"type": ID, "unknown": "ranks-with-a-tie", "rep": "table", "angle": "order-and-average"}

func test_only_ai_can_receive_tied_rank_training() -> void:
	for course in ["aa-sl", "aa-hl", "ai-sl", "ai-hl"]:
		var eligible: bool = course.begins_with("ai")
		check_eq(ID in QuestionEngine.built_types(course), eligible, course)
		check_eq(not MathsEngine.requests(course, false, [ID]).is_empty(), eligible, course)
		check(MathsEngine.requests(course, true, [ID]).is_empty(), "not advertised as exam-style")

func test_exact_midrank_and_misconceptions_over_seeded_cases() -> void:
	var aerials := {}
	var top_positions := {}
	for seed in range(1, 301):
		var req := CELL.duplicate()
		req.seed = seed
		req.format = "value"
		var q := MathsEngine.generate(req)
		if q.has("error"):
			fail(str(q.error))
			return
		var scores: Array = q.given.scores
		var index: int = q.given.asked_index
		var value: int = scores[index]
		var higher := 0
		for score in scores:
			if score > value:
				higher += 1
		check_eq(scores.count(value), 2, "exactly one requested tie")
		check_eq(q.table.rows[1][1], scores.map(func(x): return str(x)))
		check(q.lines[0].contains("highest signal score gets rank 1"), "ranking direction visible")
		check(MathsEngine.mark(q, {"v": str(higher + 1.5)}).correct, "half rank marked exactly")
		check(not MathsEngine.mark(q, {"v": str(higher + 1)}).correct, "one occupied position not the tie answer")
		check_eq(MathsEngine.mark(q, {"v": str(higher + 2)}).get("misconception"),
			"AI-SL4.10.rank-with-ties#0", "consecutive whole ranks diagnosed")
		top_positions[higher] = true
		aerials[index] = true
		req.format = "mcq"
		var mcq := MathsEngine.generate(req)
		check(not mcq.has("error"), "choices generate")
		if not mcq.has("error"):
			check_eq(mcq.choices.size(), 4)
			check_eq(mcq.choices.filter(func(choice): return choice.correct).size(), 1)
			check(MathsEngine.mark(mcq, MathsEngine.model_response(mcq)).correct)
	check_eq(top_positions.size(), 5)
	check_eq(aerials.size(), 6)


func test_study_picker_and_student_table_show_the_tied_rank_problem() -> void:
	var frame := Control.new()
	frame.size = Vector2(1080, 2100)
	tree.root.add_child(frame)
	var screen = (load("res://scenes/study.tscn") as PackedScene).instantiate()
	screen.evidence_path = "user://test-ai-midranks-study.json"
	frame.add_child(screen)
	for c in screen.course_pick.item_count:
		screen.course_pick.select(c)
		screen._on_course(c)
		var course: String = screen.course
		for t in screen.topic_pick.item_count:
			if int(screen.topic_pick.get_item_metadata(t)) == 4:
				screen._on_topic(t)
				break
		var found := false
		for i in screen.type_pick.item_count:
			if screen.type_pick.get_item_metadata(i) == ID:
				found = true
				break
		check_eq(found, course.begins_with("ai"), course)
		if not found:
			continue
		var req := CELL.duplicate()
		req.seed = 7
		screen.select_request(req)
		var table := screen.body.get_node_or_null("Table") as GridContainer
		check(table != null and table.columns == 7 and table.get_child_count() == 14, "all six visible scores and labels")
		check(screen.solution.get_child_count() == 0, "no solution disclosed before checking")
		screen.enter(MathsEngine.model_response(screen.question))
		screen.check_answer()
		check_eq(screen.feedback.text, "Correct.")
		check(screen.solution.get_child_count() > 1)
	frame.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test-ai-midranks-study.json"))
