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
