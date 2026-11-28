extends "res://tests/test_case.gd"

func test_settled_answer_and_earned_scrap_survive_reopening_without_replaying() -> void:
	var path := "user://test_settled_%s.json" % str(Time.get_ticks_usec())
	var frame := Control.new()
	frame.size = Vector2(1080, 1920)
	tree.root.add_child(frame)
	var fight: Control = (load("res://scenes/fight.tscn") as PackedScene).instantiate()
	fight.save_path = path
	fight.run_seed = 3
	fight.select_first = false
	fight.region = "quadratics"
	frame.add_child(fight)
	for _frame: int in 12:
		await tree.process_frame
	fight.use_lifeline("hint")
	fight.autoplay(true)
	check(fight.result.get("outcome", "") in ["right", "late"], "the real fight awarded a correct result")
	var shown_answer: Dictionary = {}
	for id in fight._slots:
		shown_answer[id] = fight._slots[id].text
	var shown_choice: int = fight._choice
	check(not shown_answer.is_empty() or shown_choice >= 0, "the fixture has a visible submitted entry")
	var label: String = str(fight.job.get("label", ""))
	var scene_kind: String = str(fight.strip.encounter.get("kind", ""))
	var scene_prop: String = str(fight.strip.encounter.get("prop", ""))
	check(fight.strip.active and not scene_kind.is_empty(), "real Journey art fixture is present")
	var feedback: String = fight.feedback.text
	var run: Run = fight.run
	var cell: String = run.question.cell
	var health: int = run.hp
	var prompt := MathsEngine.prompt(run.question)
	var clock: float = run.time_left
	var reward: int = int(fight.save.scrap)
	check(reward > 0, "the first real answer pays Scrap")
	frame.free()

	var reopened_screen: Control = (load("res://scenes/fight.tscn") as PackedScene).instantiate()
	reopened_screen.save_path = path
	reopened_screen.run_seed = 123
	reopened_screen.select_first = false
	reopened_screen.region = "quadratics"
	var reopened_frame := Control.new()
	reopened_frame.size = Vector2(1080, 1920)
	tree.root.add_child(reopened_frame)
	reopened_frame.add_child(reopened_screen)
	for _frame: int in 12:
		await tree.process_frame
	check_eq(reopened_screen.run.state, "result", "reopening the actual fight shows the settled result")
	check(reopened_screen.strip.active and reopened_screen.strip.visible, "restore the actual Journey stage, not a fallback portrait")
	check_eq(str(reopened_screen.strip.encounter.get("kind", "")), scene_kind)
	check_eq(str(reopened_screen.strip.encounter.get("prop", "")), scene_prop)
	check(not reopened_screen.strip.question_open, "already-settled question does not reopen as active")
	check(reopened_screen.strip.flashes.is_empty(), "restoration never replays a hit")
	check_eq(MathsEngine.prompt(reopened_screen.run.question), prompt)
	check_eq(reopened_screen.run.lifelines.hint, 0)
	check_eq(reopened_screen._choice, shown_choice)
	check_eq(str(reopened_screen.job.get("label", "")), label, "restore the same encounter with packaged Journey assets")
	check_eq(reopened_screen.feedback.text, feedback, "restore the original result wording")
	for id in shown_answer:
		check_eq(reopened_screen._slots[id].text, shown_answer[id], "restore the recorded entry alongside feedback")
	check_eq(int(reopened_screen.save.scrap), reward)
	reopened_frame.free()

	var saved := SaveData.load_from(path)
	var saved_before := JSON.stringify(saved, "", true, true)
	var checkpoint: Dictionary = saved.get("settled_run", {})
	check(not checkpoint.is_empty(), "the answer and run must be written together")
	if not checkpoint.is_empty():
		var script: Script = load("res://engine/run.gd")
		for _attempt: int in 2:
			var reopened: Variant = script.call("restore_settled", saved, checkpoint)
			check(reopened is Run, "reopening can reconstruct the run")
			if not reopened is Run:
				break
			check_eq(reopened.state, "result", "show the original result, not a new question")
			check_eq(reopened.question.cell, cell)
			check_eq(reopened.lifelines.hint, 0)
			check_eq(reopened.hp, health)
			check(absf(reopened.time_left - clock) < 0.000001, "the stopped timer is unchanged")
			check_eq(MathsEngine.prompt(reopened.question), prompt)
			reopened.answer(MathsEngine.model_response(reopened.question))
			check_eq(int(saved.scrap), reward)
			check_eq(JSON.stringify(saved, "", true, true), saved_before, "restore does not mutate progress")
		var corrupt := checkpoint.duplicate(true)
		corrupt.prompt = "not the original question"
		check(script.call("restore_settled", saved, corrupt) == null, "reject a changed question without touching earned progress")
		check_eq(JSON.stringify(saved, "", true, true), saved_before)
	for file: String in [path, SaveData.backup_path(path), SaveData.temp_path(path)]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))



func test_continue_then_reopen_does_not_return_to_the_previous_result() -> void:
	var path := "user://test_resume_next_%s.json" % str(Time.get_ticks_usec())
	var frame := Control.new()
	frame.size = Vector2(1080, 1920)
	tree.root.add_child(frame)
	var fight: Control = (load("res://scenes/fight.tscn") as PackedScene).instantiate()
	fight.save_path = path
	fight.run_seed = 3
	fight.select_first = false
	fight.region = "quadratics"
	frame.add_child(fight)
	for _frame: int in 12:
		await tree.process_frame
	fight.use_lifeline("hint")
	fight.autoplay(true)
	var earned := int(fight.save.scrap)
	var old_number: int = fight.run.question_no
	fight.next_question()
	check_eq(fight.run.state, "question", "the player continued to another prompt")
	var new_number: int = fight.run.question_no
	var prompt: String = MathsEngine.prompt(fight.run.question)
	check(new_number > old_number, "the checkpoint must be newer than the previous result")
	frame.free()

	frame = Control.new()
	frame.size = Vector2(1080, 1920)
	tree.root.add_child(frame)
	var restored: Control = (load("res://scenes/fight.tscn") as PackedScene).instantiate()
	restored.save_path = path
	restored.run_seed = 123
	restored.select_first = false
	restored.region = "quadratics"
	frame.add_child(restored)
	for _frame: int in 12:
		await tree.process_frame
	check_eq(restored.run.state, "question", "the newer unanswered prompt takes priority")
	check(restored.strip.active and restored.strip.visible and restored.strip.question_open, "continued question opens the same Journey stage")
	check_eq(restored.run.question_no, new_number)
	check_eq(MathsEngine.prompt(restored.run.question), prompt)
	check_eq(restored.run.lifelines.hint, 0, "spent aids stay spent")
	check_eq(int(restored.save.scrap), earned, "opening the new question doesn't pay again")
	frame.free()
	for file: String in [path, SaveData.backup_path(path), SaveData.temp_path(path)]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))



func test_background_checkpoint_preserves_the_first_input_clock_and_assist() -> void:
	await _check_open_question_resume(false)


func test_browser_back_preserves_the_first_input_clock_and_assist() -> void:
	await _check_open_question_resume(true)


func _check_open_question_resume(browser_back: bool) -> void:
	var path := "user://test_resume_background_%s.json" % str(Time.get_ticks_usec())
	var frame := Control.new()
	frame.size = Vector2(1080, 1920)
	tree.root.add_child(frame)
	var original: Control = (load("res://scenes/fight.tscn") as PackedScene).instantiate()
	original.save_path = path
	original.run_seed = 3
	original.select_first = false
	original.region = "quadratics"
	frame.add_child(original)
	for _frame: int in 12:
		await tree.process_frame
	original.set_process(false)
	original.set_away(false)
	original.run.tick(11.0)
	var prompt: String = MathsEngine.prompt(original.run.question)
	var remaining: float = original.run.time_left
	var bank := int(original.save.scrap)
	check(remaining < original.run.time_total, "fixture actually spends time before going away")
	if not original._choice_buttons.is_empty():
		original._choice_buttons[0].pressed.emit()
	else:
		var slot: String = original._slots.keys()[0]
		original._slots[slot].text = "3"
	var staged: Dictionary = original._capture_entry()
	original.use_lifeline("freeze")
	var freeze: float = original.run.frozen_left
	check(freeze > 0.0)
	if browser_back:
		original.leave_run()
		check_eq(original.run.state, "question", "navigation is not an explicit quit")
		check(not SaveData.load_from(path).get("settled_run", {}).is_empty(), "navigation keeps the checkpoint")
	else:
		original.set_away(true)
		original._process(30.0)
	check_eq(original.run.time_left, remaining, "hidden time cannot run down the clock")
	frame.free()

	frame = Control.new()
	frame.size = Vector2(1080, 1920)
	tree.root.add_child(frame)
	var restored: Control = (load("res://scenes/fight.tscn") as PackedScene).instantiate()
	restored.save_path = path
	restored.run_seed = 123
	restored.select_first = false
	restored.region = "quadratics"
	restored.set_away(true)
	frame.add_child(restored)
	for _frame: int in 12:
		await tree.process_frame
	check_eq(restored.run.state, "question")
	check_eq(restored.run.run_seed, 3, "even an unanswered first question resumes")
	check_eq(MathsEngine.prompt(restored.run.question), prompt)
	check(absf(restored.run.time_left - remaining) < 0.000001, "elapsed time is saved before suspension")
	check(absf(restored.run.frozen_left - freeze) < 0.000001, "active Freeze time survives")
	check_eq(restored.run.lifelines.freeze, 0, "the charge is not reissued")
	check_eq(restored._capture_entry(), staged, "a partially selected or typed answer survives")
	check_eq(int(restored.save.scrap), bank)
	frame.free()
	for file: String in [path, SaveData.backup_path(path), SaveData.temp_path(path)]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func test_another_region_requires_resuming_or_leaving_the_saved_run() -> void:
	var path := "user://test_resume_other_%s.json" % str(Time.get_ticks_usec())
	var scene := load("res://scenes/fight.tscn") as PackedScene
	var frame := Control.new()
	frame.size = Vector2(1080, 1920)
	tree.root.add_child(frame)
	var original: Control = scene.instantiate()
	original.save_path = path
	original.select_first = false
	original.region = "quadratics"
	original.run_seed = 3
	frame.add_child(original)
	for _frame: int in 12:
		await tree.process_frame
	original.autoplay(true)
	var before := JSON.stringify(SaveData.load_from(path), "", true, true)
	var earned := int(original.save.scrap)
	var course_attempt := SaveData.load_from(path)
	check(not SaveData.set_course(course_attempt, "ai-sl"), "another course cannot replace the course of an active run")
	check_eq(JSON.stringify(course_attempt, "", true, true), before, "blocked course change leaves all progress unchanged")
	var damaged := course_attempt.duplicate(true)
	damaged.settled_run.prompt = "wrong fingerprint"
	check(SaveData.set_course(damaged, "ai-sl"), "a damaged checkpoint cannot lock the student out of course selection")
	var prompt := MathsEngine.prompt(original.run.question)
	original.leave_run()
	original.free()
	var other: Control = scene.instantiate()
	other.save_path = path
	other.select_first = false
	other.region = "sequences"
	other.run_seed = 99
	frame.add_child(other)
	for _frame: int in 12:
		await tree.process_frame
	check(other.run == null, "another route cannot silently start over an active run")
	check_eq(JSON.stringify(SaveData.load_from(path), "", true, true), before, "other route leaves the full saved record intact")
	var resume := other.find_child("ContinueSavedRun", true, false) as Button
	check(resume != null and resume.is_visible_in_tree(), "a student can see how to resume")
	if resume != null:
		resume.pressed.emit()
		check_eq(other.run.region, "quadratics")
		check_eq(other.run.run_seed, 3)
		check_eq(other.run.state, "result")
		check_eq(MathsEngine.prompt(other.run.question), prompt)
		check_eq(int(other.save.scrap), earned)
		other.quit_button.pressed.emit()
		check_eq(other.run.state, "ended")
		var after_quit := SaveData.load_from(path)
		check(not after_quit.has("settled_run"), "explicit quit clears the active checkpoint")
		check_eq(int(after_quit.scrap), earned)
		check_eq(int(after_quit.runs.played), 1, "explicit quit records exactly one run")
		check(SaveData.set_course(after_quit, "ai-sl"), "course can change again after ending the run")
		check_eq(int(after_quit.scrap), earned)
	frame.free()
	for file: String in [path, SaveData.backup_path(path), SaveData.temp_path(path)]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func test_start_new_replaces_the_only_run_even_on_the_same_route() -> void:
	var path := "user://test_resume_replace_%s.json" % str(Time.get_ticks_usec())
	var scene := load("res://scenes/fight.tscn") as PackedScene
	var frame := Control.new()
	frame.size = Vector2(1080, 1920)
	tree.root.add_child(frame)
	var original: Control = scene.instantiate()
	original.save_path = path
	original.select_first = false
	original.region = "quadratics"
	original.run_seed = 3
	frame.add_child(original)
	for _frame: int in 12:
		await tree.process_frame
	original.autoplay(true)
	var before := SaveData.load_from(path)
	var earned := int(before.scrap)
	check(earned > 0, "fixture must earn Scrap")
	original.free()
	var replacement: Control = scene.instantiate()
	replacement.save_path = path
	replacement.region = "quadratics"
	replacement.run_seed = 99
	replacement.launch = {"region": "quadratics", "floor": 1}
	frame.add_child(replacement)
	for _frame: int in 12:
		await tree.process_frame
	var fresh := replacement.find_child("StartNewRun", true, false) as Button
	check(fresh != null and fresh.is_visible_in_tree(), "starting the same route offers a fresh run")
	check(replacement.run == null, "the choice neither resumes nor replaces automatically")
	check_eq(SaveData.load_from(path), before, "the choice alone changes nothing")
	if fresh != null:
		fresh.pressed.emit()
		check_eq(replacement.run.run_seed, 99, "new seed replaces the old one")
		check_eq(replacement.run.state, "question")
		check_eq(replacement.run.question_no, 1)
		var after := SaveData.load_from(path)
		check_eq(int(after.scrap), earned, "keep already-earned Scrap, without crediting it twice")
		check_eq(int(after.runs.played), 1, "abandon the original exactly once")
		var restored := Run.restore_settled(after, after.get("settled_run", {}))
		check(restored != null, "the new run occupies the sole slot")
		if restored != null:
			check_eq(restored.run_seed, 99, "the previous run cannot be restored again")
	frame.free()
	for file: String in [path, SaveData.backup_path(path), SaveData.temp_path(path)]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func test_recorded_boss_reopens_the_exact_part_and_carries_forward() -> void:
	var path := "user://test_resume_boss_%s.json" % str(Time.get_ticks_usec())
	var scene := load("res://scenes/fight.tscn") as PackedScene
	var frame := Control.new()
	frame.size = Vector2(1080, 1920)
	tree.root.add_child(frame)
	var original: Control = scene.instantiate()
	original.save_path = path
	original.select_first = false
	original.region = "quadratics"
	original.run_seed = 3
	frame.add_child(original)
	for _frame: int in 12:
		await tree.process_frame
	for _step: int in 45:
		if original.run.kind == "boss" or original.run.state == "ended":
			break
		original.autoplay(true)
		original.next_question()
		await tree.process_frame
	check_eq(original.run.kind, "boss", "real recorded run reaches its mile boss")
	check(original.run.records and original.run.boss.get("parts", []).size() > 1, "fixture uses an actual multipart boss, not a screenshot jump")
	if original.run.boss.get("parts", []).size() < 2:
		frame.free()
		return
	original.autoplay(false)
	check_eq(original.run.state, "result")
	check_eq(original.run.boss.part, 1)
	var hp: int = original.run.hp
	var won: int = int(original.save.scrap)
	var question := MathsEngine.prompt(original.run.question)
	var next := MathsEngine.prompt(original.run.boss.parts[1])
	var carry: String = original.run.boss.parts[1].get("carried", {}).get("text", "")
	var feedback: String = original.feedback.text
	var prior_answers: int = original.run.answers.size()
	check(not carry.is_empty(), "fixture carries an actual value")
	await tree.create_timer(0.30).timeout
	original.free()
	var saved := SaveData.load_from(path)
	var checkpoint: Dictionary = saved.get("settled_run", {})
	check_eq(String(checkpoint.get("values", {}).get("kind", "")), "boss", "boss part replaces the prior ordinary checkpoint")
	var resumed: Control = scene.instantiate()
	resumed.save_path = path
	resumed.select_first = false
	resumed.region = "quadratics"
	resumed.run_seed = 99
	frame.add_child(resumed)
	for _frame: int in 12:
		await tree.process_frame
	if resumed.run.kind == "boss":
		check_eq(resumed.run.state, "result")
		check_eq(resumed.run.boss.part, 1, "do not advance or re-mark on restore")
		check_eq(resumed.run.hp, hp)
		check_eq(resumed.run.answers.size(), prior_answers)
		check_eq(int(resumed.save.scrap), won)
		check_eq(MathsEngine.prompt(resumed.run.question), question)
		check_eq(resumed.feedback.text, feedback, "the settled result keeps its feedback")
		check(not resumed.result.solution.is_empty(), "restore the worked solution without serializing engine objects")
		resumed.next_question()
		check_eq(MathsEngine.prompt(resumed.run.question), next)
		check_eq(resumed.run.question.get("carried", {}).get("text", ""), carry)
		check(resumed.card.find_child("Carried", true, false) != null, "next part displays its carried value")
		resumed.set_away(false)
		resumed.run.tick(7.0)
		if not resumed._choice_buttons.is_empty():
			resumed._choice_buttons[0].pressed.emit()
		else:
			var slot: String = resumed._slots.keys()[0]
			resumed._slots[slot].text = "-2"
		var staged: Dictionary = resumed._capture_entry()
		resumed.use_lifeline("freeze")
		var left: float = resumed.run.time_left
		var freeze_left: float = resumed.run.frozen_left
		check(freeze_left > 0.0, "actual Freeze is applied")
		resumed.leave_run()
		await tree.process_frame
		resumed.free()
		var reopened: Control = scene.instantiate()
		reopened.save_path = path
		reopened.select_first = false
		reopened.region = "quadratics"
		reopened.run_seed = 100
		reopened.set_away(true)
		frame.add_child(reopened)
		for _frame: int in 12:
			await tree.process_frame
		check_eq(reopened.run.state, "question")
		check_eq(reopened.run.kind, "boss")
		check_eq(reopened.run.boss.part, 1)
		check_eq(MathsEngine.prompt(reopened.run.question), next)
		check_eq(reopened.run.question.get("carried", {}).get("text", ""), carry)
		check_eq(reopened._capture_entry(), staged)
		check(is_equal_approx(reopened.run.time_left, left))
		check(is_equal_approx(reopened.run.frozen_left, freeze_left))
		check_eq(reopened.run.lifelines.freeze, 0)
		check_eq(reopened.run.answers.size(), prior_answers)
		check_eq(int(reopened.save.scrap), won)
	else:
		fail("a boss result must restore into the boss")
	await tree.create_timer(0.30).timeout
	frame.free()
	await tree.process_frame
	for file: String in [path, SaveData.backup_path(path), SaveData.temp_path(path)]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
