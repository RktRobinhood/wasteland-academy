extends "res://tests/test_case.gd"
## The fight screen (FAL-413, FAL-415): plays a run with the card, the HP bars, the timer
## and the lifelines, shows the worked solution after a miss and the summary at the end,
## the floor select, and a boss's parts with the value carried on, and fits a 360 px
## phone, a 390 px phone and a PC window.

const FIGHT := "res://scenes/fight.tscn"
const SAVE := "user://test_fight_save.json"


func _area(window: Vector2i) -> Vector2:
	var base := Vector2(1080, 1920)
	var scale := minf(window.x / base.x, window.y / base.y)
	return Vector2(window) / scale


func _screen(area: Vector2, seed_no: int = 3, select := false, save: Dictionary = {}, fight := 1,
		region := "quadratics") -> Array:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if not save.is_empty():
		SaveData.store(save, SAVE)
	var frame := Control.new()
	frame.size = area
	tree.root.add_child(frame)
	var f: Control = (load(FIGHT) as PackedScene).instantiate()
	f.save_path = SAVE
	f.run_seed = seed_no
	f.select_first = select
	f.first_fight = fight
	f.region = region
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


## Every region's title, the all-regions dungeon's too, leaves Quit on screen, clear
## of the title and of the speaker and gear's strip (FAL-506). A region with no
## questions yet can't start a run, so its title goes on a Quadratics run.
func test_quit_fits_beside_every_region_title() -> void:
	var regions: Array = [Dungeon.ALL]
	for r in QuestionEngine.catalogue().get("regions", []):
		regions.append(r.id)
	check(regions.has("exp-log") and Progress.is_built("exp-log"), "the longest title is in the list, and playable")
	for window in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(1280, 800)]:
		var area := _area(window)
		var screen := Rect2(Vector2.ZERO, area)
		for region in regions:
			var built := Progress.is_built(region)
			var made: Array = await _screen(area, 3, false, {}, 1, region if built else "quadratics")
			var f: Control = made[1]
			if not built:
				f.region = region
				f._update_hud()
			for i in 3:
				await tree.process_frame
			var what := "%s %s" % [window, region]
			check(f.title.text.begins_with(Dungeon.region_name(region)), "%s: title %s" % [what, f.title.text])
			var quit: Rect2 = f.quit_button.get_global_rect()
			var title: Rect2 = f.title.get_global_rect()
			check(f.quit_button.is_visible_in_tree(), "%s: Quit shows" % what)
			check(screen.encloses(quit), "%s: Quit %s outside %s" % [what, quit, screen])
			check(quit.end.x <= area.x - AudioHud.RESERVED_RIGHT + 1, "%s: Quit %s under the speaker and gear" % [what, quit])
			check(title.end.x <= quit.position.x + 1, "%s: the title %s runs into Quit %s" % [what, title, quit])
			check(f.title.get_line_count() <= 2, "%s: the title takes %d lines" % [what, f.title.get_line_count()])
			_done(made)


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


# ── The dungeon (FAL-415) ────────────────────────────────────

func test_the_floor_select_offers_beaten_floors() -> void:
	var save := SaveData.blank()
	var made: Array = await _screen(_area(Vector2i(390, 844)), 3, true, save)
	var f: Control = made[1]
	check(f.floor_box.visible and f.run == null, "it opens on the floor select")
	check(not f.quit_button.visible, "nothing to quit yet")
	var floors: Node = f.floor_box.get_node("Floors")
	check(floors.get_node_or_null("Floor1") is Button, "floor 1")
	check(floors.get_node_or_null("Floor2") == null, "floor 2 is locked")
	check(floors.get_node("Locked").text.contains("Floor 2 · beat the floor 1 boss"), floors.get_node("Locked").text)
	_done(made)
	Dungeon.note_floor(save, "quadratics", 1, true)
	Dungeon.note_floor(save, "quadratics", 2, true)
	Dungeon.note_floor(save, "quadratics", 3, false)
	made = await _screen(_area(Vector2i(390, 844)), 3, true, save)
	f = made[1]
	floors = f.floor_box.get_node("Floors")
	for n in [1, 2, 3]:
		check(floors.get_node_or_null("Floor%d" % n) is Button, "floor %d is open" % n)
	check(floors.get_node_or_null("Floor4") == null, "floor 3's boss isn't beaten")
	check(floors.get_node("Locked").text.contains("Floor 4 · beat the floor 3 boss"), floors.get_node("Locked").text)
	(floors.get_node("Floor3") as Button).pressed.emit()
	await tree.process_frame
	check(f.run != null and f.run.start_floor == 3, "the run starts on floor 3")
	check(not f.floor_box.visible and f.scroll.visible)
	check(f.title.text.contains("Floor 3"), f.title.text)
	_done(made)


func test_a_boss_part_shows_the_value_carried_on() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)), 3, false, {}, 10)
	var f: Control = made[1]
	check_eq(f.run.kind, "boss")
	check(f.card.get_node_or_null("BossPart") != null and f.card.get_node("BossPart").text.begins_with("Boss · part (a)"),
		"the part shows")
	check(f.card.get_node_or_null("Carried") == null, "part (a) carries nothing")
	var a: Dictionary = f.run.question
	f.autoplay(false)
	check(f.feedback.text.contains("carries on from " + a.answer_text), f.feedback.text)
	check_eq(f.next_button.text, "Next part")
	f.next_question()
	await tree.process_frame
	var carried: Node = f.card.get_node_or_null("Carried")
	check(carried != null, "part (b) shows the carried value")
	check(carried.get_child(0).text.contains(a.answer_text), carried.get_child(0).text)
	check(f.card.get_node("PartsDone").get_child(0).text.begins_with("(a) missed"), "part (a) is marked")
	check(f.progress.text.contains("part (b)"), f.progress.text)
	check_eq(f.enemy_hp.text, "%d/%d" % [f.run.boss.parts.size() - 1, f.run.boss.parts.size()], "parts left")
	check(not f.run.records, "a jumped run records nothing")
	_done(made)


func test_the_boss_screens_fit() -> void:
	for window in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(1280, 800)]:
		var area := _area(window)
		var save := SaveData.blank()
		Dungeon.note_floor(save, "quadratics", 1, true)
		Dungeon.note_floor(save, "quadratics", 2, true)
		var made: Array = await _screen(area, 3, true, save)
		var f: Control = made[1]
		for i in 3:
			await tree.process_frame
		_check_inside(f, area, "%s floor select" % window)
		_done(made)
		made = await _screen(area, 3, false, {}, 5)
		f = made[1]
		f.autoplay(false)
		f.next_question()
		for i in 3:
			await tree.process_frame
		_check_inside(f, area, "%s mini-boss part (b)" % window)
		_done(made)


func _check_inside(f: Control, area: Vector2, what: String) -> void:
	var screen := Rect2(Vector2.ZERO, area)
	var col := f.get_node("Margin/Column") as Control
	check(screen.encloses(col.get_global_rect()), "%s: column %s outside %s" % [what, col.get_global_rect(), screen])
	for c in col.find_children("*", "Control", true, false):
		if c.is_visible_in_tree() and not c is ScrollBar:
			var r: Rect2 = c.get_global_rect()
			check(r.end.x <= col.get_global_rect().end.x + 1 and r.position.x >= col.get_global_rect().position.x - 1,
					"%s: %s sticks out (%s)" % [what, c.name, r])


func test_title_screen_has_play() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	check(main.get_node_or_null("Center/Column/Buttons/Play") is Button, "no Play button")
	main.free()
