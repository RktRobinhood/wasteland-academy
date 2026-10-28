extends "res://tests/test_case.gd"
## The fight screen (FAL-413): plays a run with the card, the HP bars, the timer and the
## lifelines, shows the worked solution after a miss and the summary at the end, and
## fits a 360 px phone, a 390 px phone and a PC window.

const FIGHT := "res://scenes/fight.tscn"
const SAVE := "user://test_fight_save.json"


func _area(window: Vector2i) -> Vector2:
	var base := Vector2(1080, 1920)
	var scale := minf(window.x / base.x, window.y / base.y)
	return Vector2(window) / scale


func _screen(area: Vector2, seed_no: int = 3) -> Array:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var frame := Control.new()
	frame.size = area
	tree.root.add_child(frame)
	var f: Control = (load(FIGHT) as PackedScene).instantiate()
	f.save_path = SAVE
	f.run_seed = seed_no
	frame.add_child(f)
	await tree.process_frame
	return [frame, f]


func _done(made: Array) -> void:
	made[0].free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_a_wrong_answer_shows_its_worked_solution() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var f: Control = made[1]
	check_eq(f.run.state, "question")
	check(f.card.get_node_or_null("Prompt") != null, "the question card")
	f.autoplay(false)
	await tree.process_frame
	check_eq(f.run.state, "result")
	check_eq(f.result.outcome, "wrong")
	check(f.working.visible, "the worked solution shows")
	check(f.feedback.text.begins_with("Missed"), f.feedback.text)
	check(f.next_button.visible)
	check_eq(int(f.player_bar.value), f.run.hp)
	f.next_question()
	await tree.process_frame
	check_eq(f.run.state, "question")
	f.autoplay(true)
	check(f.result.outcome in ["right", "late"], str(f.result.outcome))
	check(not f.working.visible, "no worked solution after a hit")
	check_eq(int(f.enemy_bar.value), int(f.run.enemy.hp))
	_done(made)


func test_the_timer_drains_into_a_timeout() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var f: Control = made[1]
	f._process(f.run.time_total * 0.6)
	check_eq(f.timer_fill.bg_color, f.ORANGE, "orange past half")
	f._process(f.run.time_total * 0.3)
	check_eq(f.timer_fill.bg_color, f.RED, "red in the late zone")
	f._process(f.run.time_total)
	check_eq(f.result.outcome, "timeout")
	check(f.working.visible, "the worked solution shows after a timeout")
	_done(made)


func test_lifelines_on_the_screen() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var f: Control = made[1]
	f.use_lifeline("hint")
	check(f.hint_label.visible and f.hint_label.text.begins_with("Hint: "), f.hint_label.text)
	check(f.lifeline_buttons.hint.disabled, "used up")
	f.use_lifeline("freeze")
	check(f.run.frozen_left > 0.0)
	var left: float = f.run.time_left
	f._process(5.0)
	check_eq(f.run.time_left, left, "frozen")
	_done(made)


func test_the_run_ends_in_a_summary() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var f: Control = made[1]
	f.lose()
	await tree.process_frame
	check_eq(f.run.state, "ended")
	check(f.summary_box.visible and not f.scroll.visible, "the summary replaces the card")
	check(not f.timer_bar.is_visible_in_tree(), "no timer on the summary")
	check(f.summary_box.get_node_or_null("Missed") != null and f.summary_box.get_node("Missed").get_child_count() > 0, "skills missed")
	var saved := SaveData.load_from(SAVE)
	check_eq(saved.scrap, f.run.summary.scrap, "the Scrap is saved")
	check_eq(saved.runs.played, 1)
	_done(made)


func test_quit_shows_the_summary() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var f: Control = made[1]
	f.autoplay(true)
	f.next_question()
	f.quit_button.pressed.emit()
	check_eq(f.run.summary.reason, "quit")
	check(f.summary_box.visible)
	_done(made)


func test_fits_a_360_phone() -> void:
	await _check_fits(Vector2i(360, 780))


func test_fits_a_390_phone() -> void:
	await _check_fits(Vector2i(390, 844))


func test_fits_a_pc_window() -> void:
	await _check_fits(Vector2i(1280, 800))


## The column, the HUD and the card fit the width (the card scrolls down), with the
## question, a wrong answer's worked solution and the summary.
func _check_fits(window: Vector2i) -> void:
	var area := _area(window)
	var made: Array = await _screen(area, 5)
	var f: Control = made[1]
	for stage in ["question", "wrong", "summary"]:
		match stage:
			"wrong":
				f.autoplay(false)
			"summary":
				f.lose()
		for i in 3:
			await tree.process_frame
		var screen := Rect2(Vector2.ZERO, area)
		var col := f.get_node("Margin/Column") as Control
		check(screen.encloses(col.get_global_rect()), "%s %s: column %s outside %s" % [window, stage, col.get_global_rect(), screen])
		for c in col.find_children("*", "Control", true, false):
			if c.is_visible_in_tree() and not c is ScrollBar:
				var r: Rect2 = c.get_global_rect()
				check(r.end.x <= col.get_global_rect().end.x + 1 and r.position.x >= col.get_global_rect().position.x - 1,
						"%s %s: %s sticks out (%s)" % [window, stage, c.name, r])
		var scroll: ScrollContainer = f.scroll
		if stage != "summary":
			check(scroll.size.y >= 500, "%s %s: room for the card (%s)" % [window, stage, scroll.size.y])
	_done(made)


func test_title_screen_has_play() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	check(main.get_node_or_null("Center/Column/Buttons/Play") is Button, "no Play button")
	main.free()
