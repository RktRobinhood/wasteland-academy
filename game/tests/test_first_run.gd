extends "res://tests/test_case.gd"
## A new student's first minutes (FAL-1041, #186): the course asked once on a blank save,
## the four skippable fight cards, the hidden question explorer, the exam switch and the
## wording that goes with them.

const MAP := "res://scenes/map.tscn"
const MAIN := "res://scenes/main.tscn"
const FIGHT := "res://scenes/fight.tscn"
const SAVE := "user://test_first_run_save.json"


func _forget() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	MapLink.current = {}


func _mount(path: String, save: Dictionary = {}) -> Array:
	_forget()
	if not save.is_empty():
		SaveData.store(save, SAVE)
	var frame := Control.new()
	frame.size = Vector2(1080, 1920)
	tree.root.add_child(frame)
	var s: Control = (load(path) as PackedScene).instantiate()
	s.set("save_path", SAVE)
	frame.add_child(s)
	for i in 3:
		await tree.process_frame
	return [frame, s]


func _unmount(made: Array) -> void:
	made[0].free()
	_forget()


# ── The save ─────────────────────────────────────────────────

func test_a_blank_save_needs_a_course_and_the_cards() -> void:
	var s := SaveData.blank()
	check(SaveData.needs_course(s) and SaveData.needs_cards(s), "a blank save is asked")
	check_eq(Courses.of(s), "aa-sl", "the course still has a fallback")
	check(SaveData.set_course(s, "ai-hl"), "picks")
	check(not SaveData.needs_course(s), "asked once")
	check(SaveData.needs_cards(s), "the cards are separate")
	check_eq(s.settings.exam_only, false, "a new student starts on exam questions plus training")


func test_an_older_save_is_not_asked() -> void:
	var old := SaveData.migrate({"version": 6, "course": "aa-hl", "cells": {}})
	check(not SaveData.needs_course(old) and not SaveData.needs_cards(old), "already plays a course")
	check_eq(old.course, "aa-hl")
	var oldest := SaveData.migrate({"version": 0, "cells": {"k": {"seen": 1}}})
	check(not SaveData.needs_course(oldest), "a version 0 save too")


# ── The course question ──────────────────────────────────────

func test_the_map_asks_for_the_course_once() -> void:
	var made: Array = await _mount(MAP)
	var m: Control = made[1]
	var pick := m.get_node_or_null("CoursePick") as FirstRun
	check(pick != null, "a blank save is asked")
	if pick == null:
		_unmount(made)
		return
	check_eq(pick.picked, "", "nothing is pre-picked")
	check(pick.continue_button.disabled, "Continue waits for a pick")
	check_eq((pick._body.get_node("Heading") as Label).text, FirstRun.COURSE_HEADING)
	for id in Courses.ids():
		check(pick._body.get_node_or_null(id) != null, "a button for " + id)
	check(pick._body.get_node_or_null("aa-slTag") == null, "AA SL is live")
	check(pick._body.get_node_or_null("ai-hlTag") != null, "a course still being built says so")
	(pick._body.get_node("ai-sl") as Button).pressed.emit()
	check(not pick.continue_button.disabled, "a pick opens Continue")
	pick.continue_button.pressed.emit()
	await tree.process_frame
	await tree.process_frame
	check(m.get_node_or_null("CoursePick") == null, "the question closes")
	var stored := SaveData.load_from(SAVE)
	check_eq(stored.course, "ai-sl")
	check(not SaveData.needs_course(stored), "and is not asked again")
	_unmount(made)
	# A second launch on the same save goes straight to the map.
	var again: Array = await _mount(MAP, stored)
	check(again[1].get_node_or_null("CoursePick") == null, "not asked twice")
	_unmount(again)


# ── The cards ────────────────────────────────────────────────

func test_the_cards_step_through_and_skip() -> void:
	var f := FirstRun.fight_cards()
	tree.root.add_child(f)
	var done := []
	f.finished.connect(func(r: String): done.append(r))
	check_eq(FirstRun.CARDS.size(), 4, "four cards")
	for i in 3:
		check_eq((f._body.get_node("Count") as Label).text, "How a fight works · %d of 4" % (i + 1))
		check(f._body.get_node("Buttons/Skip") != null, "card %d can be skipped" % (i + 1))
		(f._body.get_node("Buttons/Next") as Button).pressed.emit()
	check(f._body.get_node_or_null("Buttons/Skip") == null, "the last card has one button")
	check_eq((f._body.get_node("Heading") as Label).text, "Three lifelines")
	(f._body.get_node("Buttons/Done") as Button).pressed.emit()
	check_eq(done, [""], "Got it closes")
	var g := FirstRun.fight_cards()
	tree.root.add_child(g)
	var skipped := []
	g.finished.connect(func(r: String): skipped.append(r))
	(g._body.get_node("Buttons/Skip") as Button).pressed.emit()
	check_eq(skipped, [""], "Skip closes")


func test_the_first_run_opens_on_the_cards_then_never_again() -> void:
	var made: Array = await _mount(MAP)
	made[1].queue_free()
	await tree.process_frame
	_unmount(made)
	var save := SaveData.blank()
	SaveData.set_course(save, "aa-sl")
	preload("res://ui/fight.gd").launch = {"region": "quadratics", "floor": 1}
	var m: Array = await _mount(FIGHT, save)
	var f: Control = m[1]
	var cards := f.get_node_or_null("FightCards") as FirstRun
	check(cards != null, "the first run opens on the cards")
	check(f.run == null, "no question, so no timer, behind them")
	if cards != null:
		(cards._body.get_node("Buttons/Skip") as Button).pressed.emit()
	await tree.process_frame
	check(f.run != null, "Skip starts the run")
	check(not SaveData.needs_cards(SaveData.load_from(SAVE)), "and the cards are not shown again")
	check_eq(f.check_button.text, "Lock in", "one submit verb")
	_unmount(m)
	preload("res://ui/fight.gd").launch = {"region": "quadratics", "floor": 1}
	var again: Array = await _mount(FIGHT, SaveData.migrate(SaveData.blank().merged({"intro": {"course": true, "cards": true}}, true)))
	check(again[1].get_node_or_null("FightCards") == null, "no cards the second time")
	_unmount(again)


# ── The title and the exam switch ────────────────────────────

func test_the_question_explorer_is_hidden_from_students() -> void:
	var made: Array = await _mount(MAIN)
	var engine := made[1].get_node("Center/Column/Engine") as Button
	check(not engine.visible, "no explorer button on the title")
	check_eq(engine.text, "Question explorer")
	check_eq((made[1].get_node("Center/Column/Buttons/Practice") as Button).text, "Practice · no timer, no damage")
	_unmount(made)


func test_the_exam_switch_is_two_choices_with_one_line_of_help() -> void:
	var seen := []
	var s := ExamSwitch.make(false, func(on: bool): seen.append(on))
	tree.root.add_child(s)
	check(s.plus.button_pressed and not s.only.button_pressed, "a new save starts on plus training")
	check_eq(s.only.text, "Exam questions only")
	check_eq(s.plus.text, "Exam questions plus training")
	check_eq((s.get_node("Help") as Label).text, "Training adds concept checks and warm-ups you won't see on a paper.")
	s.only.button_pressed = true
	check_eq(seen, [true])
	check(not s.plus.button_pressed, "the other side lets go")
	s.show_value(false)
	check(s.plus.button_pressed and seen == [true], "show_value doesn't call back")
	s.free()


func test_a_question_header_says_its_kind() -> void:
	var practice := preload("res://ui/practice.gd")
	check_eq(practice.kind_text({"exam": true, "level": 3}), "Exam question")
	check_eq(practice.kind_text({"format": "probe", "level": 2}), "Training · concept check")
	check_eq(practice.kind_text({"level": 0, "view": {"type": "x"}}), "Training · warm-up")
	check_eq(practice.kind_text({"level": 2, "view": {"type": "x"}}), "Training")


func test_the_back_button_names_the_place() -> void:
	var made: Array = await _mount(MAP, _chosen())
	var m: Control = made[1]
	m.show_route({"screen": "island", "island": "functions"})
	check_eq((m.island.get_node("Header").get_child(0).get_node("Back") as Button).text, "◂ The Wasteland")
	m.show_route(MapLink.parse("#functions/quadratics"))
	check_eq((m.region_col.get_node("Head/Back") as Button).text, "◂ Signal Tower")
	check_eq((m.world.get_node("Header").get_child(0).get_node("Back") as Button).text, "◂ Title")
	_unmount(made)


func test_a_place_shows_its_name_on_every_board() -> void:
	var made: Array = await _mount(MAP, _chosen())
	var m: Control = made[1]
	m.show_route({"screen": "island", "island": "functions"})
	var spot := m.island_board.get_node("Spot_quadratics") as Button
	check(spot.get_node_or_null("Banner") != null, "a banner with the topic's name")
	check_eq(((spot.get_node("Banner") as Control).get_node("Name") as Label).text, "QUADRATICS")
	m.touch = true
	m.press(spot)
	check_eq((m.island_board.get_node("Card/Box/Hint") as Label).text, "Tap again to go in")
	check((m.island_board.get_node("Card/Box/Hint") as Label).visible, "the hint shows after the first tap")
	_unmount(made)


func _chosen() -> Dictionary:
	var s := SaveData.blank()
	SaveData.set_course(s, "aa-sl")
	return s
