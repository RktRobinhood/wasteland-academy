extends "res://tests/test_case.gd"
## Touch on the question card (FAL-735), through the engine's real touch events at a
## 390 px phone: a swipe scrolls the card wherever it starts, a tap still picks, a wide
## table still scrolls sideways, and an answer brings the result and Next into view.
## The fight screen reuses the practice card, so each test runs on both.

const SCREENS := ["res://scenes/fight.tscn", "res://scenes/practice.tscn"]
const SAVE := "user://test_swipe_save.json"
const TABLE_VALUE := {"type": "fn-quadratic-features", "unknown": "vertex-from-table", "rep": "table", "angle": "midpoint-of-roots", "format": "value", "seed": 4}
const PICK_GRAPH := {"type": "fn-sketch-gdc", "unknown": "sketch-on-domain", "rep": "equation", "angle": "gdc-transfer", "format": "mcq", "seed": 3}
const MCQ := {"type": "fn-quadratic-features", "unknown": "vertex-from-factorised", "rep": "graph", "angle": "midpoint-of-roots", "format": "mcq", "seed": 3}
## Less than a finger wobbles on a tap, in base units (about 4 px on the phone).
const WOBBLE := 10.0


## Collects the engine's errors: the runner's own logger only fails a test on a script error.
class EngineErrors extends Logger:
	var seen: PackedStringArray = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String,
			_editor_notify: bool, _error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		seen.append(rationale if rationale != "" else code)


func _screen(path: String, view: Dictionary) -> Array:
	Input.emulate_touch_from_mouse = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var base := Vector2(1080, 1920)
	var window := Vector2(390, 844)
	var frame := Control.new()
	frame.size = window / minf(window.x / base.x, window.y / base.y)
	tree.root.add_child(frame)
	var s: Control = (load(path) as PackedScene).instantiate()
	s.save_path = SAVE
	if "run_seed" in s:
		s.run_seed = 3
		s.select_first = false
		s.first_fight = 1
		s.region = "quadratics"
	frame.add_child(s)
	await tree.process_frame
	if "run_seed" in s:
		s.question = QuestionEngine.make(view)
		s.run.question = s.question
		s.render_question()
	else:
		s.show_view(view)
	await _settle()
	return [frame, s]


func _done(made: Array) -> void:
	made[0].free()
	Input.emulate_touch_from_mouse = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _settle() -> void:
	for i in 6:
		await tree.process_frame


## Makes the card too tall for its room, so a swipe has somewhere to go.
func _tall(s: Control) -> void:
	var filler := Control.new()
	filler.custom_minimum_size.y = 3000
	s.card.add_child(filler)
	await _settle()


func _send(e: InputEvent) -> void:
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await tree.process_frame


func _touch(at: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.position = tree.root.get_final_transform() * at
	e.pressed = pressed
	await _send(e)


## A finger's path through `points`, in base units: down on the first, up on the last.
func _finger(points: Array) -> void:
	var xf := tree.root.get_final_transform()
	await _touch(points[0], true)
	for i in range(1, points.size()):
		var e := InputEventScreenDrag.new()
		e.position = xf * (points[i] as Vector2)
		e.relative = xf.basis_xform(points[i] - points[i - 1])
		e.screen_relative = e.relative
		await _send(e)
	await _touch(points[-1], false)
	await _settle()


func _swipe(from: Vector2, by: Vector2) -> void:
	var points := []
	for i in 9:
		points.append(from + by * i / 8.0)
	await _finger(points)


## A tap with the wobble a real finger has.
func _tap(at: Vector2) -> void:
	await _finger([at, at + Vector2(WOBBLE, WOBBLE), at])


func _in_view(s: Control, c: Control) -> void:
	s.scroll.ensure_control_visible(c)
	await _settle()


func _middle(c: Control) -> Vector2:
	return c.get_global_rect().get_center()


func _first_row(s: Control) -> Button:
	return s._choice_buttons[0]


func _shows(s: Control, c: Control) -> bool:
	return s.scroll.get_global_rect().grow(1).encloses(c.get_global_rect())


# ── 1: a vertical swipe scrolls the card wherever it starts ──

func test_a_swipe_scrolls_from_anywhere() -> void:
	for path in SCREENS:
		for spec in [["prompt", MCQ], ["table", TABLE_VALUE], ["row", MCQ], ["keypad", TABLE_VALUE], ["slot", TABLE_VALUE], ["card", PICK_GRAPH]]:
			var made: Array = await _screen(path, spec[1])
			var s: Control = made[1]
			await _tall(s)
			var from: Control
			match spec[0]:
				"prompt": from = s.card.get_node("Prompt")
				"table": from = s.find_child("Table", true, false)
				"row": from = _first_row(s)
				"keypad": from = s.find_child("Key_5", true, false)
				"slot": from = s._slots.values()[0]
				"card": from = s.find_child("Card0", true, false)
			await _in_view(s, from)
			var was: int = s.scroll.scroll_vertical
			await _swipe(_middle(from), Vector2(0, -300))
			check(s.scroll.scroll_vertical - was >= 200, "%s: swipe on %s moved the card %d" % [path, spec[0], s.scroll.scroll_vertical - was])
			_done(made)


## A table that can scroll sideways doesn't trap an upward swipe.
func test_a_swipe_on_a_wide_table_scrolls_the_card() -> void:
	for path in SCREENS:
		var made: Array = await _wide(path)
		var s: Control = made[1]
		var wrap: Control = s.find_child("TableScroll", true, false)
		await _tall(s)
		await _in_view(s, wrap)
		var was: int = s.scroll.scroll_vertical
		await _swipe(_middle(wrap), Vector2(0, -300))
		check(s.scroll.scroll_vertical - was >= 200, "%s: moved the card %d" % [path, s.scroll.scroll_vertical - was])
		_done(made)


# ── 2: a tap picks; a swipe that starts on a row doesn't ─────

func test_a_tap_picks_a_row() -> void:
	for path in SCREENS:
		var made: Array = await _screen(path, MCQ)
		var s: Control = made[1]
		await _in_view(s, _first_row(s))
		await _tap(_middle(_first_row(s)))
		check_eq(s._choice, 0, "%s: tapped row" % path)
		check(_first_row(s).button_pressed, "%s: and it shows as picked" % path)
		_done(made)


func test_a_swipe_from_a_row_picks_nothing() -> void:
	for path in SCREENS:
		var made: Array = await _screen(path, MCQ)
		var s: Control = made[1]
		await _tall(s)
		await _in_view(s, _first_row(s))
		await _swipe(_middle(_first_row(s)), Vector2(0, -300))
		check_eq(s._choice, -1, "%s: swiped row" % path)
		check(not _first_row(s).button_pressed, "%s: nothing shows as picked" % path)
		_done(made)


func test_a_graph_card_picks_on_a_tap_only() -> void:
	for path in SCREENS:
		var made: Array = await _screen(path, PICK_GRAPH)
		var s: Control = made[1]
		var g: Control = s.find_child("Card0", true, false)
		await _tall(s)
		await _in_view(s, g)
		await _swipe(_middle(g), Vector2(0, -300))
		check_eq(s._choice, -1, "%s: swiped card" % path)
		await _in_view(s, g)
		await _tap(_middle(g))
		check_eq(s._choice, 0, "%s: tapped card" % path)
		_done(made)


func test_a_tap_works_the_keypad_and_the_slots() -> void:
	for path in SCREENS:
		var made: Array = await _screen(path, TABLE_VALUE)
		var s: Control = made[1]
		var second: LineEdit = s._slots.values()[-1]
		var key: Control = s.find_child("Key_5", true, false)
		await _tall(s)
		await _in_view(s, key)
		await _swipe(_middle(key), Vector2(0, -300))
		check_eq(second.text, "", "%s: a swipe types nothing" % path)
		await _in_view(s, second)
		await _tap(_middle(second))
		check(second.has_focus(), "%s: a tap focuses the box" % path)
		await _in_view(s, key)
		await _tap(_middle(key))
		check_eq(second.text, "5", "%s: a tap types" % path)
		_done(made)


# ── 3: a wide table still scrolls sideways ───────────────────

func _wide(path: String) -> Array:
	var made: Array = await _screen(path, TABLE_VALUE)
	var s: Control = made[1]
	var xs := []
	for i in 30:
		xs.append(1000 + i)
	s.question.table = {"xs": xs, "ys": xs}
	s.render_question()
	await _settle()
	return made


func test_a_wide_table_scrolls_sideways() -> void:
	for path in SCREENS:
		var made: Array = await _wide(path)
		var s: Control = made[1]
		var wrap: ScrollContainer = s.find_child("TableScroll", true, false)
		await _in_view(s, wrap)
		var was: int = s.scroll.scroll_vertical
		check(wrap.get_h_scroll_bar().max_value > wrap.size.x, "%s: the table is wider than its room" % path)
		await _swipe(_middle(wrap), Vector2(-300, 0))
		check(wrap.scroll_horizontal >= 200, "%s: moved sideways %d" % [path, wrap.scroll_horizontal])
		check_eq(s.scroll.scroll_vertical, was, "%s: and the card stayed" % path)
		_done(made)


# ── 4: an answer brings the result and Next into view ────────

func test_a_right_answer_shows_the_result_and_next() -> void:
	for path in SCREENS:
		var made: Array = await _screen(path, MCQ)
		var s: Control = made[1]
		var filler := Control.new()
		filler.custom_minimum_size.y = 2000
		s.card.add_child(filler)
		s.card.move_child(filler, 0)
		await _settle()
		check(s.check_button.get_global_rect().end.y > s.scroll.get_global_rect().end.y, "%s: the button starts below the fold" % path)
		s.autoplay(true)
		await _settle()
		check(_shows(s, s.feedback), "%s: the result shows (%s in %s)" % [path, s.feedback.get_global_rect(), s.scroll.get_global_rect()])
		check(_shows(s, s.next_button), "%s: Next shows (%s in %s)" % [path, s.next_button.get_global_rect(), s.scroll.get_global_rect()])
		_done(made)


## A long worked solution: the result stays at the top, and a swipe reaches Next.
func test_a_long_solution_keeps_the_result_and_next_is_a_swipe_away() -> void:
	for path in SCREENS:
		var made: Array = await _screen(path, MCQ)
		var s: Control = made[1]
		var filler := Control.new()
		filler.custom_minimum_size.y = 3000
		s.working.add_child(filler)
		s.autoplay(false)
		await _settle()
		check(_shows(s, s.feedback), "%s: the result shows (%s in %s)" % [path, s.feedback.get_global_rect(), s.scroll.get_global_rect()])
		check(not _shows(s, s.next_button), "%s: Next is below the solution" % path)
		for i in 3:
			await _swipe(_middle(s.feedback), Vector2(0, -900))
		check(_shows(s, s.next_button), "%s: a swipe reaches Next (%s)" % [path, s.next_button.get_global_rect()])
		_done(made)


## Attack with nothing filled in, tapped at the fold: the message under it comes into
## view, and Attack stays there to tap again.
func test_an_empty_attack_shows_what_is_missing() -> void:
	for path in SCREENS:
		for spec in [["choice", MCQ, "Choose one."], ["boxes", TABLE_VALUE, "Fill in every box."]]:
			var made: Array = await _screen(path, spec[1])
			var s: Control = made[1]
			var filler := Control.new()
			filler.custom_minimum_size.y = 2000
			s.card.add_child(filler)
			s.card.move_child(filler, 0)
			await _settle()
			s.scroll.scroll_vertical = int(s.check_button.get_rect().end.y - s.scroll.size.y)
			await _settle()
			check(_shows(s, s.check_button), "%s, %s: the button starts in view" % [path, spec[0]])
			await _tap(_middle(s.check_button))
			check_eq(s.feedback.text, spec[2], "%s, %s: the message" % [path, spec[0]])
			check(not s.answered, "%s, %s: it isn't an answer" % [path, spec[0]])
			check(_shows(s, s.feedback), "%s, %s: the message shows (%s in %s)" % [path, spec[0], s.feedback.get_global_rect(), s.scroll.get_global_rect()])
			check(_shows(s, s.check_button), "%s, %s: the button still shows" % [path, spec[0]])
			_done(made)


## Time running out shows its result the same way as Attack.
func test_a_timeout_shows_the_result() -> void:
	var made: Array = await _screen(SCREENS[0], MCQ)
	var f: Control = made[1]
	f.run.time_left = 0.01
	await _settle()
	await tree.create_timer(0.05).timeout
	await _settle()
	if f.answered:
		check(_shows(f, f.feedback), "the result shows")
		check(_shows(f, f.next_button), "Next shows")
	else:
		fail("the clock didn't run out")
	_done(made)


## autoplay=lose answers many questions in one frame, and each one asks for the reveal.
func test_answers_in_one_frame_reveal_once() -> void:
	var made: Array = await _screen(SCREENS[0], MCQ)
	var f: Control = made[1]
	var errors := EngineErrors.new()
	OS.add_logger(errors)
	f.run.question = f.question
	f.lose()
	await _settle()
	OS.remove_logger(errors)
	check_eq(errors.seen, PackedStringArray(), "engine errors")
	_done(made)
