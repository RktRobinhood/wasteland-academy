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
			check_eq(p.feedback.text.begins_with("Right") or p.feedback.text.begins_with("Good"), right, "%s: feedback %s" % [v, p.feedback.text])
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
	check(p.feedback.text.contains("Watch out"), "the misconception is named")
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
