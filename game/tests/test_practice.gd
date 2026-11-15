extends "res://tests/test_case.gd"
## The practice screen: plays questions in every representation and format with no
## errors, records answers in the save, and fits on a phone and a PC window.

const PRACTICE := "res://scenes/practice.tscn"
const SAVE := "user://test_practice_save.json"

const VIEWS := [
	{"type": "fn-quadratic-features", "unknown": "vertex-form-from-general", "rep": "equation", "angle": "complete-square", "format": "value", "seed": 2},
	{"type": "fn-quadratic-features", "unknown": "vertex-from-factorised", "rep": "graph", "angle": "midpoint-of-roots", "format": "mcq", "seed": 3},
	{"type": "fn-quadratic-features", "unknown": "vertex-from-table", "rep": "table", "angle": "midpoint-of-roots", "format": "value", "seed": 4},
	{"type": "fn-quadratic-from-conditions", "unknown": "range-after-finding", "rep": "words", "angle": "vertex-or-asymptote", "format": "value", "seed": 5},
	{"type": "fn-concept-quadratic-forms", "unknown": "match-three-forms", "rep": "graph", "angle": "compare-coefficients", "format": "mcq", "seed": 6},
	{"type": "t3-sine-cosine-rule", "unknown": "side-cosine-rule", "rep": "diagram", "angle": "cosine-rule", "format": "value", "seed": 7},
	{"type": "t3-triangle-area", "unknown": "angle-from-area", "rep": "words", "angle": "reverse-two-angles", "format": "mcq", "seed": 8},
	{"type": "t1-arithmetic-sequence", "unknown": "sum-from-u1-d", "rep": "table", "angle": "formula-d", "format": "mcq", "seed": 7},
	{"type": "t1-arithmetic-sequence", "unknown": "n-from-sum", "rep": "notation", "angle": "quadratic-in-n", "format": "value", "seed": 8},
	{"type": "t4-discrete-distribution", "unknown": "k-from-sum", "rep": "table", "angle": "sum-to-one", "format": "value", "seed": 9},
	{"type": "t4-expected-value", "unknown": "probabilities-from-mean", "rep": "table", "angle": "two-equations", "format": "value", "seed": 10},
	{"type": "t4-expected-value", "unknown": "fair-stake", "rep": "words", "angle": "winnings-vs-cost", "format": "mcq", "seed": 11},
	{"type": "t5-stationary-points", "unknown": "stationary-points", "rep": "equation", "angle": "solve-f-prime-zero", "format": "value", "seed": 9},
	{"type": "t5-stationary-points", "unknown": "nature", "rep": "words", "angle": "second-derivative-test", "format": "mcq", "seed": 10},
	{"type": "t5-tangent-normal-equation", "unknown": "normal-at-point", "rep": "equation", "angle": "rearranged-form", "format": "value", "seed": 11},
	{"type": "fn-sketch-gdc", "unknown": "sketch-on-domain", "rep": "equation", "angle": "gdc-transfer", "format": "mcq", "seed": 3},
	{"type": "fn-quadratic-features", "probe": 2, "format": "probe"},
	{"type": "fn-quadratic-features", "probe": 0, "format": "probe"},
]


func _screen(area: Vector2) -> Array:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var frame := Control.new()
	frame.size = area
	tree.root.add_child(frame)
	var p: Control = (load(PRACTICE) as PackedScene).instantiate()
	p.save_path = SAVE
	frame.add_child(p)
	await tree.process_frame
	return [frame, p]


func _area(window: Vector2i) -> Vector2:
	var base := Vector2(1080, 1920)
	var scale := minf(window.x / base.x, window.y / base.y)
	return Vector2(window) / scale


func test_plays_every_representation_and_format() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var p: Control = made[1]
	for v in VIEWS:
		for right in [true, false]:
			p.show_view(v)
			await tree.process_frame
			check(not p.question.has("error"), str(v))
			p.autoplay(right)
			await tree.process_frame
			check(p.answered, "%s: answered" % v)
			check_eq(p.feedback.math.begins_with("Right") or p.feedback.math.begins_with("Good"), right, "%s: feedback %s" % [v, p.feedback.math])
			check(p.working.visible, "%s: working shown" % v)
	var saved := SaveData.load_from(SAVE)
	check(saved.cells.size() >= 5, "answers are saved")
	check(saved.probes.size() >= 2, "probe answers are saved")
	made[0].free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_a_wrong_option_records_its_misconception() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var p: Control = made[1]
	p.show_view({"type": "fn-quadratic-features", "unknown": "vertex-from-vertex-form", "rep": "equation", "angle": "read-vertex-form", "format": "mcq", "seed": 1})
	p.autoplay(false)
	var r: Dictionary = p.save.cells[p.question.cell]
	check_eq(r.last_misconception, "SL2.6.vertex#0")
	check(p.feedback.math.contains("Watch out"), "the misconception is named")
	made[0].free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_an_answer_box_shows_all_it_is_given() -> void:
	# FAL-743: 0.00000842 showed as 000842 in a box of fixed width.
	for window: Vector2i in [Vector2i(360, 800), Vector2i(390, 844), Vector2i(1280, 800)]:
		var made: Array = await _screen(_area(window))
		var p: Control = made[1]
		p.show_view({"type": "t1-standard-form", "unknown": "to-ordinary-small", "rep": "equation", "angle": "place-shift", "format": "value", "seed": 1})
		await tree.process_frame
		var box: LineEdit = p.card.find_children("Slot_*", "LineEdit", true, false)[0]
		var empty: float = box.get_combined_minimum_size().x
		p._focus = box
		for k in "0.00000842":
			p._on_key(k)
		check_eq(box.text, "0.00000842")
		check(box.get_combined_minimum_size().x > empty, "the box grows with its text")
		box.text = "8".repeat(40)
		check_eq(box.text.length(), p.SLOT_CHARS, "a box stops at its limit")
		await tree.process_frame
		await tree.process_frame
		var font := box.get_theme_font("font")
		var wide := font.get_string_size(box.text, HORIZONTAL_ALIGNMENT_LEFT, -1, box.get_theme_font_size("font_size")).x
		check(box.size.x >= wide, "%s: %d of text in a box of %d" % [window, wide, box.size.x])
		var card_rect: Rect2 = p.card.get_global_rect()
		check(box.get_global_rect().end.x <= card_rect.end.x + 0.5, "%s: the box runs off the card" % window)
		check(card_rect.end.x <= made[0].size.x, "%s: the card runs off the screen" % window)
		made[0].free()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_a_power_in_the_question_fits_a_phone() -> void:
	# FAL-743: the prompt, its lines and the worked steps are rich text when they have a power.
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var p: Control = made[1]
	p.show_view({"type": "fn-exponential-model", "unknown": "change-over-period", "rep": "equation", "angle": "repeated-multiplication", "format": "value", "seed": 6})
	p.autoplay(true)
	await tree.process_frame
	await tree.process_frame
	var rich: Array = p.card.find_children("*", "RichTextLabel", true, false)
	check(rich.size() >= 2, "the equation and a worked step")
	for r: RichTextLabel in rich:
		check(r.size.y >= r.get_theme_font_size("normal_font_size"), "%s has no height" % r.get_parsed_text())
		check(r.get_global_rect().end.x <= p.card.get_global_rect().end.x + 0.5, r.get_parsed_text())
	made[0].free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_a_power_in_an_option_is_raised() -> void:
	# FAL-760: the options, the "Not quite" line and the method tabs raised no power.
	for window: Vector2i in [Vector2i(390, 844), Vector2i(1280, 800)]:
		var made: Array = await _screen(_area(window))
		var p: Control = made[1]
		p.show_view({"type": "t1-log-exp-form", "unknown": "to-exponential-form", "rep": "words", "angle": "rewrite-exponential", "format": "mcq", "seed": 1})
		await tree.process_frame
		await tree.process_frame
		var plain := Button.new()
		plain.text = "5"
		plain.add_theme_font_size_override("font_size", UiTheme.BODY)
		p.card.add_child(plain)
		await tree.process_frame
		var line: float = plain.size.y
		plain.free()
		for b: MathButton in p._choice_buttons:
			check_eq(b.text, "", "%s: a power is drawn by the label, not the button" % b.math)
			var shown: String = b.get_node("Math").get_parsed_text()
			check(b.math.contains("^") and not shown.contains("^"), "%s shows %s" % [b.math, shown])
			check(b.size.y >= line - 0.5, "%s: %d tall, under a line's %d" % [b.math, b.size.y, line])
			check(b.get_node("Math").get_global_rect().end.y <= b.get_global_rect().end.y + 0.5, "%s: the label runs out of its button" % b.math)
			check(b.get_global_rect().end.x <= p.card.get_global_rect().end.x + 0.5, "%s: off the card" % b.math)
		p.autoplay(false)
		await tree.process_frame
		check(p.feedback.math.contains("^") and not p.feedback.get_parsed_text().contains("^"), p.feedback.get_parsed_text())
		check(p.feedback.get_parsed_text().begins_with("Not quite"), p.feedback.get_parsed_text())
		var right: MathButton = p._choice_buttons.filter(func(b): return b.math == p.question.answer_text)[0]
		await tree.process_frame
		check_eq(right.get_node("Math").get_theme_color("default_color"), UiTheme.TEAL, "the right option turns teal")
		made[0].free()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_a_long_option_with_a_power_wraps() -> void:
	# FAL-760: a rich option is as tall as its lines, as a plain one is.
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var p: Control = made[1]
	p.show_view({"type": "t1-log-exp-form", "unknown": "to-exponential-form", "rep": "words", "angle": "rewrite-exponential", "format": "mcq", "seed": 1})
	await tree.process_frame
	var b: MathButton = p._choice_buttons[0]
	b.math = "e^(2x) " + "and more words ".repeat(12)
	await tree.process_frame
	await tree.process_frame
	var one: float = b.get_theme_font("font").get_height(b.get_theme_font_size("font_size"))
	check(b.size.y > 2.0 * one, "wrapped onto several lines: %d tall" % b.size.y)
	check(b.get_node("Math").get_global_rect().end.y <= b.get_global_rect().end.y + 0.5, "the label fits its button")
	b.math = "no power"
	check(b.text == "no power" and not b.has_node("Math"), "plain text goes back to the button")
	made[0].free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_a_subscript_in_a_method_tab_is_lowered() -> void:
	# FAL-760: "Substitute into u_n = u_1 r^(n − 1)" showed its underscores.
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var p: Control = made[1]
	p.show_view({"type": "t1-geometric-sequence", "unknown": "r-from-terms", "rep": "terms", "angle": "repeated-multiply", "format": "mcq", "seed": 1})
	p.autoplay(false)
	await tree.process_frame
	var tabs: Array = p.card.find_child("Methods", true, false).get_children()
	check_eq(tabs.size(), 2)
	var other: MathButton = tabs[1]
	check_eq(other.math, "Another way: Substitute into u_n = u_1 r^(n − 1)")
	check_eq(other.get_node("Math").get_parsed_text(), "Another way: Substitute into un = u1 rn − 1")
	other.button_pressed = true
	other.pressed.emit()
	await tree.process_frame
	var title: RichTextLabel = p.card.find_child("Steps", true, false).get_child(0)
	check_eq(title.get_parsed_text(), "Substitute into un = u1 rn − 1")
	made[0].free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_planner_questions_follow_on() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var p: Control = made[1]
	for i in 8:
		check(not p.question.has("error"), str(p.question.get("view")))
		p.autoplay(i % 2 == 0)
		p.next_question()
		await tree.process_frame
	made[0].free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_fits_on_a_phone() -> void:
	await _check_fits(Vector2i(390, 844))


func test_fits_in_a_pc_window() -> void:
	await _check_fits(Vector2i(1280, 800))


## Every view's card fits the screen's width (it scrolls down), with no text
## running off the side.
func _check_fits(window: Vector2i) -> void:
	var area := _area(window)
	var made: Array = await _screen(area)
	var p: Control = made[1]
	for v in VIEWS:
		p.show_view(v)
		p.autoplay(false)
		for i in 3:
			await tree.process_frame
		var screen := Rect2(Vector2.ZERO, area)
		var col := p.get_node("Margin/Column") as Control
		check(screen.encloses(col.get_global_rect()), "%s %s: column %s outside %s" % [window, v.get("unknown", "probe"), col.get_global_rect(), screen])
		var card: VBoxContainer = p.card
		for c in card.find_children("*", "Control", true, false):
			if c.is_visible_in_tree() and not c is ScrollBar:
				var r: Rect2 = c.get_global_rect()
				check(r.end.x <= col.get_global_rect().end.x + 1 and r.position.x >= col.get_global_rect().position.x - 1,
						"%s %s: %s sticks out (%s)" % [window, v.get("unknown", "probe"), c.name, r])
	made[0].free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_title_screen_has_practice() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	check(main.get_node_or_null("Center/Column/Buttons/Practice") is Button, "no Practice button")
	main.free()
